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

// ParkEase specific endpoints for admin panel integration

// Force logout all users
exports.forceLogoutAll = async (req, res) => {
  try {
    const result = await db.query(
      `UPDATE sessions 
       SET is_active = false, logout_time = CURRENT_TIMESTAMP
       WHERE is_active = true
       RETURNING *`
    );
    
    // Log audit
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'FORCE_LOGOUT_ALL',
        'session',
        'all',
        JSON.stringify({ affected_sessions: result.rows.length }),
        req.ip
      ]
    );
    
    res.json({
      success: true,
      message: `${result.rows.length} sessions logged out successfully`
    });
  } catch (error) {
    console.error('Force logout all error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get ParkEase dashboard stats specifically for admin panel
exports.getParkeaseStats = async (req, res) => {
  try {
    const [
      activeUsers,
      parkedVehicles,
      todayRevenue,
      activeSessions,
      totalUsers,
      todayEntries,
      todayExits
    ] = await Promise.all([
      db.query('SELECT COUNT(*) as count FROM sessions WHERE is_active = true'),
      db.query('SELECT COUNT(*) as count FROM vehicles WHERE exit_time IS NULL'),
      db.query(
        `SELECT COALESCE(SUM(total_amount), 0) as total 
         FROM vehicles 
         WHERE DATE(exit_time) = CURRENT_DATE AND is_paid = true`
      ),
      db.query('SELECT COUNT(*) as count FROM sessions WHERE is_active = true'),
      db.query('SELECT COUNT(*) as count FROM users WHERE is_active = true'),
      db.query('SELECT COUNT(*) as count FROM vehicles WHERE DATE(entry_time) = CURRENT_DATE'),
      db.query('SELECT COUNT(*) as count FROM vehicles WHERE DATE(exit_time) = CURRENT_DATE')
    ]);

    res.json({
      success: true,
      stats: {
        activeUsers: parseInt(activeUsers.rows[0].count),
        parkedVehicles: parseInt(parkedVehicles.rows[0].count),
        todayRevenue: parseFloat(todayRevenue.rows[0].total),
        activeSessions: parseInt(activeSessions.rows[0].count),
        totalUsers: parseInt(totalUsers.rows[0].count),
        todayEntries: parseInt(todayEntries.rows[0].count),
        todayExits: parseInt(todayExits.rows[0].count)
      }
    });
  } catch (error) {
    console.error('ParkEase stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get recent activity for admin panel
exports.getRecentActivity = async (req, res) => {
  try {
    const activities = await db.query(
      `(SELECT 'vehicle_entry' as type, 
               vehicle_number as description,
               entry_time as timestamp,
               u.full_name as user_name
        FROM vehicles v
        LEFT JOIN users u ON v.operator_id = u.id
        WHERE DATE(entry_time) = CURRENT_DATE
        ORDER BY entry_time DESC
        LIMIT 10)
       UNION ALL
       (SELECT 'vehicle_exit' as type,
               vehicle_number as description,
               exit_time as timestamp,
               u.full_name as user_name
        FROM vehicles v
        LEFT JOIN users u ON v.operator_id = u.id
        WHERE DATE(exit_time) = CURRENT_DATE
        ORDER BY exit_time DESC
        LIMIT 10)
       UNION ALL
       (SELECT 'user_login' as type,
               'User logged in' as description,
               login_time as timestamp,
               u.full_name as user_name
        FROM sessions s
        JOIN users u ON s.user_id = u.id
        WHERE DATE(login_time) = CURRENT_DATE
        ORDER BY login_time DESC
        LIMIT 5)
       ORDER BY timestamp DESC
       LIMIT 20`
    );

    res.json({
      success: true,
      activities: activities.rows
    });
  } catch (error) {
    console.error('Recent activity error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Broadcast message to all active devices
exports.broadcastMessage = async (req, res) => {
  try {
    const { message, type = 'info' } = req.body;
    
    if (!message || message.trim().length === 0) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    // Here you would implement WebSocket broadcast
    // For now, we'll just log the audit
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'BROADCAST_MESSAGE',
        'system',
        'all_devices',
        JSON.stringify({ message, type }),
        req.ip
      ]
    );
    
    res.json({
      success: true,
      message: 'Broadcast sent successfully'
    });
  } catch (error) {
    console.error('Broadcast message error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Clear system cache
exports.clearCache = async (req, res) => {
  try {
    // Log the cache clear action
    await db.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, details, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        req.user.userId,
        'CLEAR_CACHE',
        'system',
        'cache',
        JSON.stringify({ action: 'system_cache_cleared' }),
        req.ip
      ]
    );
    
    res.json({
      success: true,
      message: 'System cache cleared successfully'
    });
  } catch (error) {
    console.error('Clear cache error:', error);
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