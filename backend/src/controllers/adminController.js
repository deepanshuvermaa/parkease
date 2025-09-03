const db = require('../config/database');

// Get dashboard data
exports.getDashboard = async (req, res) => {
  try {
    const [
      totalUsers,
      activeUsers,
      totalVehicles,
      activeVehicles,
      todayRevenue,
      monthlyRevenue,
      todayEntries,
      todayExits
    ] = await Promise.all([
      db.query('SELECT COUNT(*) as count FROM users WHERE is_active = true'),
      db.query('SELECT COUNT(*) as count FROM sessions WHERE is_active = true'),
      db.query('SELECT COUNT(*) as count FROM vehicles'),
      db.query('SELECT COUNT(*) as count FROM vehicles WHERE exit_time IS NULL'),
      db.query(
        `SELECT COALESCE(SUM(total_amount), 0) as total 
         FROM vehicles 
         WHERE DATE(exit_time) = CURRENT_DATE AND is_paid = true`
      ),
      db.query(
        `SELECT COALESCE(SUM(total_amount), 0) as total 
         FROM vehicles 
         WHERE DATE_TRUNC('month', exit_time) = DATE_TRUNC('month', CURRENT_DATE) 
         AND is_paid = true`
      ),
      db.query(
        'SELECT COUNT(*) as count FROM vehicles WHERE DATE(entry_time) = CURRENT_DATE'
      ),
      db.query(
        'SELECT COUNT(*) as count FROM vehicles WHERE DATE(exit_time) = CURRENT_DATE'
      )
    ]);
    
    // Get recent vehicles
    const recentVehicles = await db.query(
      `SELECT v.*, u.full_name as operator_name 
       FROM vehicles v
       LEFT JOIN users u ON v.operator_id = u.id
       ORDER BY v.entry_time DESC
       LIMIT 10`
    );
    
    res.json({
      success: true,
      dashboard: {
        totalUsers: parseInt(totalUsers.rows[0].count),
        activeUsers: parseInt(activeUsers.rows[0].count),
        totalVehicles: parseInt(totalVehicles.rows[0].count),
        activeVehicles: parseInt(activeVehicles.rows[0].count),
        todayRevenue: parseFloat(todayRevenue.rows[0].total),
        monthlyRevenue: parseFloat(monthlyRevenue.rows[0].total),
        todayEntries: parseInt(todayEntries.rows[0].count),
        todayExits: parseInt(todayExits.rows[0].count),
        recentVehicles: recentVehicles.rows
      }
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get detailed statistics
exports.getStatistics = async (req, res) => {
  try {
    const { from, to } = req.query;
    const params = [];
    let dateFilter = '';
    
    if (from && to) {
      dateFilter = ' WHERE entry_time BETWEEN $1 AND $2';
      params.push(from, to);
    } else if (from) {
      dateFilter = ' WHERE entry_time >= $1';
      params.push(from);
    } else if (to) {
      dateFilter = ' WHERE entry_time <= $1';
      params.push(to);
    }
    
    // Vehicle type distribution
    const vehicleTypes = await db.query(
      `SELECT vehicle_type, COUNT(*) as count, 
              COALESCE(SUM(total_amount), 0) as revenue
       FROM vehicles ${dateFilter}
       GROUP BY vehicle_type
       ORDER BY count DESC`,
      params
    );
    
    // Hourly distribution
    const hourlyDistribution = await db.query(
      `SELECT EXTRACT(HOUR FROM entry_time) as hour, 
              COUNT(*) as count
       FROM vehicles ${dateFilter}
       GROUP BY hour
       ORDER BY hour`,
      params
    );
    
    // Operator performance
    const operatorPerformance = await db.query(
      `SELECT u.full_name, COUNT(v.*) as vehicle_count,
              COALESCE(SUM(v.total_amount), 0) as total_revenue
       FROM users u
       LEFT JOIN vehicles v ON u.id = v.operator_id ${dateFilter ? 'AND v.' + dateFilter.substring(7) : ''}
       WHERE u.role = 'operator'
       GROUP BY u.id, u.full_name
       ORDER BY total_revenue DESC`,
      params
    );
    
    res.json({
      success: true,
      statistics: {
        vehicleTypes: vehicleTypes.rows,
        hourlyDistribution: hourlyDistribution.rows,
        operatorPerformance: operatorPerformance.rows
      }
    });
  } catch (error) {
    console.error('Statistics error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get all users
exports.getUsers = async (req, res) => {
  try {
    const users = await db.query(
      `SELECT u.*, 
              COUNT(DISTINCT s.id) as active_sessions,
              COUNT(DISTINCT v.id) as total_vehicles
       FROM users u
       LEFT JOIN sessions s ON u.id = s.user_id AND s.is_active = true
       LEFT JOIN vehicles v ON u.id = v.operator_id
       GROUP BY u.id
       ORDER BY u.created_at DESC`
    );
    
    res.json({
      success: true,
      users: users.rows
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update user status
exports.updateUserStatus = async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive, isPaid, subscriptionEndDate } = req.body;
    
    let updateQuery = 'UPDATE users SET updated_at = CURRENT_TIMESTAMP';
    const params = [];
    let paramIndex = 1;
    
    if (isActive !== undefined) {
      updateQuery += `, is_active = $${paramIndex++}`;
      params.push(isActive);
    }
    
    if (isPaid !== undefined) {
      updateQuery += `, is_paid = $${paramIndex++}`;
      params.push(isPaid);
    }
    
    if (subscriptionEndDate !== undefined) {
      updateQuery += `, subscription_end_date = $${paramIndex++}`;
      params.push(subscriptionEndDate);
    }
    
    updateQuery += ` WHERE id = $${paramIndex} RETURNING *`;
    params.push(userId);
    
    const result = await db.query(updateQuery, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Log audit
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'UPDATE_USER_STATUS',
        'user',
        userId,
        JSON.stringify({ isActive, isPaid, subscriptionEndDate }),
        req.ip
      ]
    );
    
    res.json({
      success: true,
      user: result.rows[0],
      message: 'User status updated successfully'
    });
  } catch (error) {
    console.error('Update user status error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get active devices
exports.getActiveDevices = async (req, res) => {
  try {
    const devices = await db.query(
      `SELECT s.*, u.username, u.full_name, u.role
       FROM sessions s
       JOIN users u ON s.user_id = u.id
       WHERE s.is_active = true
       ORDER BY s.last_activity DESC`
    );
    
    res.json({
      success: true,
      devices: devices.rows
    });
  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Force logout
exports.forceLogout = async (req, res) => {
  try {
    const { userId, deviceId } = req.body;
    
    await db.query(
      `UPDATE sessions 
       SET is_active = false, logout_time = CURRENT_TIMESTAMP
       WHERE user_id = $1 AND device_id = $2`,
      [userId, deviceId]
    );
    
    // Log audit
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'FORCE_LOGOUT',
        'session',
        userId,
        JSON.stringify({ deviceId }),
        req.ip
      ]
    );
    
    res.json({
      success: true,
      message: 'Device logged out successfully'
    });
  } catch (error) {
    console.error('Force logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Generate report
exports.generateReport = async (req, res) => {
  try {
    const { type, from, to } = req.query;
    
    let reportData;
    
    switch (type) {
      case 'daily':
        reportData = await generateDailyReport(from || new Date());
        break;
      case 'monthly':
        reportData = await generateMonthlyReport(from || new Date());
        break;
      case 'custom':
        reportData = await generateCustomReport(from, to);
        break;
      default:
        reportData = await generateDailyReport(new Date());
    }
    
    res.json({
      success: true,
      report: reportData
    });
  } catch (error) {
    console.error('Generate report error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get settings
exports.getSettings = async (req, res) => {
  try {
    const settings = await db.query(
      'SELECT key, value FROM settings WHERE user_id IS NULL'
    );
    
    const settingsObject = {};
    settings.rows.forEach(row => {
      settingsObject[row.key] = row.value;
    });
    
    res.json({
      success: true,
      settings: settingsObject
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update settings
exports.updateSettings = async (req, res) => {
  try {
    const { settings } = req.body;
    
    for (const [key, value] of Object.entries(settings)) {
      await db.query(
        `INSERT INTO settings (user_id, key, value)
         VALUES (NULL, $1, $2)
         ON CONFLICT (user_id, key)
         DO UPDATE SET value = $2, updated_at = CURRENT_TIMESTAMP`,
        [key, JSON.stringify(value)]
      );
    }
    
    res.json({
      success: true,
      message: 'Settings updated successfully'
    });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get audit logs
exports.getAuditLogs = async (req, res) => {
  try {
    const { limit = 100, offset = 0 } = req.query;
    
    const logs = await db.query(
      `SELECT a.*, u.username, u.full_name
       FROM audit_logs a
       LEFT JOIN users u ON a.user_id = u.id
       ORDER BY a.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    
    res.json({
      success: true,
      logs: logs.rows
    });
  } catch (error) {
    console.error('Get audit logs error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Extend subscription
exports.extendSubscription = async (req, res) => {
  try {
    const { userId } = req.params;
    const { days, type = 'manual' } = req.body;
    
    if (!days || days <= 0) {
      return res.status(400).json({ error: 'Invalid number of days' });
    }
    
    // Get user current status
    const userResult = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = userResult.rows[0];
    let newEndDate;
    
    // Calculate new subscription end date
    if (user.trial_end_date && user.trial_end_date > new Date()) {
      // Extend from current trial end date
      newEndDate = new Date(user.trial_end_date);
    } else if (user.subscription_end_date && user.subscription_end_date > new Date()) {
      // Extend from current subscription end date
      newEndDate = new Date(user.subscription_end_date);
    } else {
      // Start from today
      newEndDate = new Date();
    }
    
    newEndDate.setDate(newEndDate.getDate() + parseInt(days));
    
    // Update user subscription
    await db.query(
      `UPDATE users SET 
        subscription_end_date = $1,
        is_paid = true,
        is_active = true,
        updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [newEndDate, userId]
    );
    
    // Create subscription history record
    await db.query(
      `INSERT INTO subscription_history 
       (user_id, extended_by_admin_id, days_added, extension_type, new_end_date)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, req.user.userId, days, type, newEndDate]
    );
    
    // Log audit
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'EXTEND_SUBSCRIPTION',
        'user',
        userId,
        JSON.stringify({ days, newEndDate: newEndDate.toISOString(), type }),
        req.ip
      ]
    );
    
    // Restore user data if they were previously expired
    const { restoreUserData } = require('../services/notificationScheduler');
    const restoreResult = await restoreUserData(userId, req.user.userId);
    
    // Notify user via WebSocket if they're online
    const websocketService = require('../services/websocket');
    websocketService.notifyUser(userId, {
      type: 'SUBSCRIPTION_EXTENDED',
      message: `Your subscription has been extended by ${days} days until ${newEndDate.toDateString()}. ${restoreResult.success ? 'Your data has been restored!' : ''}`,
      newEndDate: newEndDate.toISOString(),
      dataRestored: restoreResult.success,
      restoredItems: restoreResult.restoredItems || null
    });
    
    res.json({
      success: true,
      message: `Subscription extended by ${days} days`,
      newEndDate: newEndDate.toISOString(),
      user: {
        id: userId,
        subscriptionEndDate: newEndDate,
        isPaid: true,
        isActive: true
      },
      dataRestoration: restoreResult
    });
  } catch (error) {
    console.error('Extend subscription error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get subscription history
exports.getSubscriptionHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    
    const history = await db.query(
      `SELECT sh.*, 
              u.username, u.full_name,
              a.full_name as admin_name
       FROM subscription_history sh
       JOIN users u ON sh.user_id = u.id
       LEFT JOIN users a ON sh.extended_by_admin_id = a.id
       WHERE sh.user_id = $1
       ORDER BY sh.created_at DESC`,
      [userId]
    );
    
    res.json({
      success: true,
      history: history.rows
    });
  } catch (error) {
    console.error('Get subscription history error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Backup user data
exports.backupUserData = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Get user data
    const userData = await db.query(
      'SELECT * FROM users WHERE id = $1',
      [userId]
    );
    
    if (userData.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Get user's vehicles
    const vehicles = await db.query(
      'SELECT * FROM vehicles WHERE operator_id = $1',
      [userId]
    );
    
    // Get user's settings
    const settings = await db.query(
      'SELECT * FROM settings WHERE user_id = $1',
      [userId]
    );
    
    const backupData = {
      user: userData.rows[0],
      vehicles: vehicles.rows,
      settings: settings.rows,
      backupDate: new Date().toISOString()
    };
    
    // Store backup
    await db.query(
      `INSERT INTO user_backups (user_id, backup_data, created_by_admin_id)
       VALUES ($1, $2, $3)`,
      [userId, JSON.stringify(backupData), req.user.userId]
    );
    
    res.json({
      success: true,
      message: 'User data backed up successfully',
      backup: backupData
    });
  } catch (error) {
    console.error('Backup user data error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get users with expiring subscriptions
exports.getExpiringSubscriptions = async (req, res) => {
  try {
    const { days = 3 } = req.query;
    
    const expiringSoon = await db.query(
      `SELECT u.*, 
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
         (u.trial_end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '${days} days')
         OR 
         (u.subscription_end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '${days} days')
       )
       ORDER BY 
         LEAST(
           COALESCE(u.trial_end_date, '2099-12-31'::date), 
           COALESCE(u.subscription_end_date, '2099-12-31'::date)
         ) ASC`
    );
    
    res.json({
      success: true,
      users: expiringSoon.rows
    });
  } catch (error) {
    console.error('Get expiring subscriptions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Delete user
exports.deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Don't allow deleting admin users
    const userCheck = await db.query(
      'SELECT role FROM users WHERE id = $1',
      [userId]
    );
    
    if (userCheck.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    if (userCheck.rows[0].role === 'admin') {
      return res.status(403).json({ error: 'Cannot delete admin users' });
    }
    
    await db.query('DELETE FROM users WHERE id = $1', [userId]);
    
    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Helper functions for reports
async function generateDailyReport(date) {
  const result = await db.query(
    `SELECT 
      COUNT(*) as total_vehicles,
      COUNT(CASE WHEN exit_time IS NOT NULL THEN 1 END) as completed,
      COUNT(CASE WHEN exit_time IS NULL THEN 1 END) as active,
      COALESCE(SUM(total_amount), 0) as total_revenue,
      COUNT(DISTINCT operator_id) as operators
     FROM vehicles
     WHERE DATE(entry_time) = DATE($1)`,
    [date]
  );
  
  return result.rows[0];
}

async function generateMonthlyReport(date) {
  const result = await db.query(
    `SELECT 
      DATE(entry_time) as date,
      COUNT(*) as vehicles,
      COALESCE(SUM(total_amount), 0) as revenue
     FROM vehicles
     WHERE DATE_TRUNC('month', entry_time) = DATE_TRUNC('month', $1::date)
     GROUP BY DATE(entry_time)
     ORDER BY date`,
    [date]
  );
  
  return result.rows;
}

async function generateCustomReport(from, to) {
  const result = await db.query(
    `SELECT 
      vehicle_type,
      COUNT(*) as count,
      COALESCE(SUM(total_amount), 0) as revenue,
      AVG(EXTRACT(EPOCH FROM (exit_time - entry_time))/3600) as avg_duration_hours
     FROM vehicles
     WHERE entry_time BETWEEN $1 AND $2
     GROUP BY vehicle_type`,
    [from, to]
  );
  
  return result.rows;
}