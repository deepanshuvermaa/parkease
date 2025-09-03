const db = require('../config/database');
const { queueNotification } = require('./websocket');

// Check for users with expiring subscriptions and send notifications
exports.checkExpiringSubscriptions = async () => {
  try {
    console.log('🔔 Checking for expiring subscriptions...');
    
    // Get users expiring in 1 day (final warning)
    const expiring1Day = await db.query(`
      SELECT u.*, 
             CASE 
               WHEN u.trial_end_date > CURRENT_DATE THEN 
                 EXTRACT(DAY FROM (u.trial_end_date - CURRENT_DATE))
               WHEN u.subscription_end_date > CURRENT_DATE THEN 
                 EXTRACT(DAY FROM (u.subscription_end_date - CURRENT_DATE))
               ELSE 0
             END as days_remaining
      FROM users u
      WHERE u.role = 'guest' 
      AND u.is_active = true
      AND (
        (u.trial_end_date = CURRENT_DATE + INTERVAL '1 day')
        OR 
        (u.subscription_end_date = CURRENT_DATE + INTERVAL '1 day')
      )
    `);
    
    // Get users expiring in 3 days (early warning)
    const expiring3Days = await db.query(`
      SELECT u.*, 
             CASE 
               WHEN u.trial_end_date > CURRENT_DATE THEN 
                 EXTRACT(DAY FROM (u.trial_end_date - CURRENT_DATE))
               WHEN u.subscription_end_date > CURRENT_DATE THEN 
                 EXTRACT(DAY FROM (u.subscription_end_date - CURRENT_DATE))
               ELSE 0
             END as days_remaining
      FROM users u
      WHERE u.role = 'guest' 
      AND u.is_active = true
      AND (
        (u.trial_end_date = CURRENT_DATE + INTERVAL '3 days')
        OR 
        (u.subscription_end_date = CURRENT_DATE + INTERVAL '3 days')
      )
    `);
    
    // Process 1-day warnings
    for (const user of expiring1Day.rows) {
      await sendExpirationWarning(user, 1, true);
    }
    
    // Process 3-day warnings  
    for (const user of expiring3Days.rows) {
      await sendExpirationWarning(user, 3, false);
    }
    
    console.log(`📨 Sent expiration warnings to ${expiring1Day.rows.length + expiring3Days.rows.length} users`);
    
  } catch (error) {
    console.error('❌ Check expiring subscriptions error:', error);
  }
};

// Send expiration warning with data backup information
async function sendExpirationWarning(user, daysRemaining, isFinalWarning) {
  const title = isFinalWarning ? 
    '⚠️ Final Notice: Trial Expires Tomorrow' : 
    '📅 Trial Expiring Soon';
    
  const message = isFinalWarning ?
    `Your free trial expires tomorrow! Your parking data is safely backed up and will be restored when you extend your subscription. Contact your administrator to continue using ParkEase.` :
    `Your free trial expires in ${daysRemaining} days. Don't worry - your parking data is automatically backed up and will be restored when your subscription is extended.`;
  
  const notificationData = {
    userId: user.id,
    daysRemaining: daysRemaining,
    expirationDate: user.trial_end_date || user.subscription_end_date,
    isFinalWarning: isFinalWarning,
    backupInfo: {
      dataBackedUp: true,
      restoreAvailable: true,
      backupDate: new Date().toISOString()
    }
  };
  
  // Queue the notification
  await queueNotification(
    user.id,
    isFinalWarning ? 'TRIAL_EXPIRING_FINAL' : 'TRIAL_EXPIRING_SOON',
    title,
    message,
    notificationData
  );
  
  // Also create a backup of user's current data
  await createUserDataBackup(user.id, 'auto_expiration_backup');
  
  console.log(`📤 Queued ${isFinalWarning ? 'final' : 'early'} expiration warning for user: ${user.username}`);
}

// Create automatic backup of user data
async function createUserDataBackup(userId, backupType = 'scheduled') {
  try {
    // Get user data
    const userData = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
    if (userData.rows.length === 0) return;
    
    // Get user's vehicles
    const vehicles = await db.query('SELECT * FROM vehicles WHERE operator_id = $1', [userId]);
    
    // Get user's settings
    const settings = await db.query('SELECT * FROM settings WHERE user_id = $1', [userId]);
    
    const backupData = {
      user: userData.rows[0],
      vehicles: vehicles.rows,
      settings: settings.rows,
      backupDate: new Date().toISOString(),
      backupType: backupType
    };
    
    // Store backup
    await db.query(
      `INSERT INTO user_backups (user_id, backup_data, created_by_admin_id)
       VALUES ($1, $2, NULL)`,
      [userId, JSON.stringify(backupData)]
    );
    
    console.log(`💾 Created automatic backup for user: ${userId}`);
    return true;
  } catch (error) {
    console.error(`❌ Backup creation failed for user ${userId}:`, error);
    return false;
  }
}

// Check and disable expired users
exports.processExpiredUsers = async () => {
  try {
    console.log('🔍 Processing expired users...');
    
    const expiredUsers = await db.query(`
      SELECT u.*
      FROM users u
      WHERE u.role = 'guest' 
      AND u.is_active = true
      AND (
        (u.trial_end_date < CURRENT_DATE)
        OR 
        (u.subscription_end_date < CURRENT_DATE AND u.trial_end_date IS NULL)
      )
    `);
    
    for (const user of expiredUsers.rows) {
      // Create final backup before deactivation
      await createUserDataBackup(user.id, 'final_backup_before_expiration');
      
      // Deactivate user
      await db.query(
        'UPDATE users SET is_active = false, updated_at = CURRENT_TIMESTAMP WHERE id = $1',
        [user.id]
      );
      
      // Send expiration notification
      await queueNotification(
        user.id,
        'TRIAL_EXPIRED',
        '🚫 Trial Expired',
        'Your free trial has ended. Your data is safely backed up and will be restored when your subscription is renewed. Contact your administrator to continue using ParkEase.',
        {
          userId: user.id,
          expiredDate: new Date().toISOString(),
          dataBackedUp: true
        }
      );
      
      console.log(`🔒 Deactivated expired user: ${user.username}`);
    }
    
    if (expiredUsers.rows.length > 0) {
      console.log(`🚫 Processed ${expiredUsers.rows.length} expired users`);
    }
    
  } catch (error) {
    console.error('❌ Process expired users error:', error);
  }
};

// Restore user data after subscription extension
exports.restoreUserData = async (userId, adminId) => {
  try {
    console.log(`🔄 Restoring data for user: ${userId}`);
    
    // Get the most recent backup
    const backup = await db.query(
      `SELECT * FROM user_backups 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT 1`,
      [userId]
    );
    
    if (backup.rows.length === 0) {
      console.log(`⚠️ No backup found for user: ${userId}`);
      return { success: false, message: 'No backup data found' };
    }
    
    const backupData = backup.rows[0].backup_data;
    let restoredItems = {
      vehicles: 0,
      settings: 0
    };
    
    // Restore vehicles (only if they don't already exist)
    if (backupData.vehicles && backupData.vehicles.length > 0) {
      for (const vehicle of backupData.vehicles) {
        try {
          // Check if vehicle already exists
          const existingVehicle = await db.query(
            'SELECT id FROM vehicles WHERE id = $1',
            [vehicle.id]
          );
          
          if (existingVehicle.rows.length === 0) {
            // Insert vehicle
            await db.query(
              `INSERT INTO vehicles (
                id, license_plate, vehicle_type, operator_id, entry_time,
                exit_time, total_amount, is_paid, notes, created_at, updated_at
              ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
              [
                vehicle.id, vehicle.license_plate, vehicle.vehicle_type,
                vehicle.operator_id, vehicle.entry_time, vehicle.exit_time,
                vehicle.total_amount, vehicle.is_paid, vehicle.notes,
                vehicle.created_at, vehicle.updated_at
              ]
            );
            restoredItems.vehicles++;
          }
        } catch (vehicleError) {
          console.error(`Error restoring vehicle ${vehicle.id}:`, vehicleError);
        }
      }
    }
    
    // Restore settings
    if (backupData.settings && backupData.settings.length > 0) {
      for (const setting of backupData.settings) {
        try {
          await db.query(
            `INSERT INTO settings (user_id, key, value, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (user_id, key)
             DO UPDATE SET value = $3, updated_at = $5`,
            [
              setting.user_id, setting.key, setting.value,
              setting.created_at, setting.updated_at
            ]
          );
          restoredItems.settings++;
        } catch (settingError) {
          console.error(`Error restoring setting ${setting.key}:`, settingError);
        }
      }
    }
    
    // Mark backup as restored
    await db.query(
      'UPDATE user_backups SET restored_at = CURRENT_TIMESTAMP WHERE id = $1',
      [backup.rows[0].id]
    );
    
    // Log the restoration
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        adminId,
        'RESTORE_USER_DATA',
        'user',
        userId,
        JSON.stringify({ 
          backupId: backup.rows[0].id,
          restoredItems: restoredItems 
        }),
        '127.0.0.1'
      ]
    );
    
    console.log(`✅ Data restored for user ${userId}: ${restoredItems.vehicles} vehicles, ${restoredItems.settings} settings`);
    
    return {
      success: true,
      message: 'Data restored successfully',
      restoredItems: restoredItems,
      backupDate: backup.rows[0].created_at
    };
    
  } catch (error) {
    console.error(`❌ Restore user data error for user ${userId}:`, error);
    return { success: false, message: 'Restore failed', error: error.message };
  }
};