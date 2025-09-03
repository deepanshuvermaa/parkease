const jwt = require('jsonwebtoken');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

exports.initializeWebSocket = (io) => {
  // Middleware for socket authentication
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error'));
      }
      
      const decoded = jwt.verify(token, JWT_SECRET);
      
      // Get user details
      const userResult = await db.query(
        'SELECT id, username, role FROM users WHERE id = $1 AND is_active = true',
        [decoded.userId]
      );
      
      if (userResult.rows.length === 0) {
        return next(new Error('User not found'));
      }
      
      socket.userId = decoded.userId;
      socket.userRole = userResult.rows[0].role;
      next();
    } catch (err) {
      next(new Error('Authentication error'));
    }
  });
  
  io.on('connection', (socket) => {
    console.log(`User ${socket.userId} connected via WebSocket`);
    
    // Join user's room
    socket.join(`user_${socket.userId}`);
    
    // Join role-based room
    if (socket.userRole === 'admin') {
      socket.join('admins');
    }
    
    // Handle device authentication
    socket.on('authenticate_device', async (data) => {
      const { deviceId } = data;
      
      try {
        // Check for other active sessions
        const sessions = await db.query(
          'SELECT * FROM sessions WHERE user_id = $1 AND device_id != $2 AND is_active = true',
          [socket.userId, deviceId]
        );
        
        if (sessions.rows.length > 0) {
          // Notify other devices
          socket.to(`user_${socket.userId}`).emit('force_logout', {
            message: 'Logged in from another device',
            deviceId: deviceId
          });
          
          // Deactivate other sessions
          await db.query(
            'UPDATE sessions SET is_active = false WHERE user_id = $1 AND device_id != $2',
            [socket.userId, deviceId]
          );
        }
        
        socket.deviceId = deviceId;
        socket.emit('authenticated', { success: true });
      } catch (error) {
        console.error('Device authentication error:', error);
        socket.emit('authenticated', { success: false, error: 'Authentication failed' });
      }
    });
    
    // Handle vehicle updates
    socket.on('vehicle_update', async (data) => {
      try {
        // Broadcast to all devices of the same user
        io.to(`user_${socket.userId}`).emit('sync_vehicle', data);
        
        // If admin, broadcast to admin room for dashboard
        if (socket.userRole === 'admin') {
          io.to('admins').emit('dashboard_update', {
            type: 'vehicle',
            data: data
          });
        }
      } catch (error) {
        console.error('Vehicle update error:', error);
      }
    });
    
    // Handle real-time statistics request (admin only)
    socket.on('request_stats', async () => {
      if (socket.userRole !== 'admin') {
        return socket.emit('error', { message: 'Unauthorized' });
      }
      
      try {
        // Get real-time statistics
        const stats = await getRealtimeStats();
        socket.emit('stats_update', stats);
      } catch (error) {
        console.error('Stats request error:', error);
        socket.emit('error', { message: 'Failed to fetch stats' });
      }
    });
    
    // Handle admin force logout
    socket.on('admin_force_logout', async (data) => {
      if (socket.userRole !== 'admin') {
        return socket.emit('error', { message: 'Unauthorized' });
      }
      
      const { targetUserId, targetDeviceId } = data;
      
      try {
        // Update session in database
        await db.query(
          'UPDATE sessions SET is_active = false WHERE user_id = $1 AND device_id = $2',
          [targetUserId, targetDeviceId]
        );
        
        // Emit force logout to target user
        io.to(`user_${targetUserId}`).emit('force_logout', {
          message: 'Administrator logged you out',
          deviceId: targetDeviceId
        });
        
        socket.emit('force_logout_success', { targetUserId, targetDeviceId });
      } catch (error) {
        console.error('Force logout error:', error);
        socket.emit('error', { message: 'Force logout failed' });
      }
    });
    
    // Handle disconnection
    socket.on('disconnect', () => {
      console.log(`User ${socket.userId} disconnected`);
    });
  });
  
  // Broadcast stats to admins every 30 seconds
  setInterval(async () => {
    try {
      const stats = await getRealtimeStats();
      io.to('admins').emit('stats_update', stats);
    } catch (error) {
      console.error('Stats broadcast error:', error);
    }
  }, 30000);
};

// Get real-time statistics
async function getRealtimeStats() {
  try {
    const [
      totalVehicles,
      activeVehicles,
      todayRevenue,
      activeUsers,
      todayEntries
    ] = await Promise.all([
      db.query('SELECT COUNT(*) as count FROM vehicles'),
      db.query('SELECT COUNT(*) as count FROM vehicles WHERE exit_time IS NULL'),
      db.query(
        `SELECT COALESCE(SUM(total_amount), 0) as total 
         FROM vehicles 
         WHERE DATE(exit_time) = CURRENT_DATE AND is_paid = true`
      ),
      db.query('SELECT COUNT(*) as count FROM sessions WHERE is_active = true'),
      db.query(
        'SELECT COUNT(*) as count FROM vehicles WHERE DATE(entry_time) = CURRENT_DATE'
      )
    ]);
    
    return {
      totalVehicles: parseInt(totalVehicles.rows[0].count),
      activeVehicles: parseInt(activeVehicles.rows[0].count),
      todayRevenue: parseFloat(todayRevenue.rows[0].total),
      activeUsers: parseInt(activeUsers.rows[0].count),
      todayEntries: parseInt(todayEntries.rows[0].count),
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('Get stats error:', error);
    return {
      totalVehicles: 0,
      activeVehicles: 0,
      todayRevenue: 0,
      activeUsers: 0,
      todayEntries: 0,
      timestamp: new Date().toISOString()
    };
  }
}

// Export function to send notifications to specific users
exports.notifyUser = (userId, notification) => {
  const io = global.io;
  if (io) {
    io.to(`user_${userId}`).emit('notification', notification);
    console.log(`Notification sent to user ${userId}:`, notification.type);
  }
};

// Export function to notify all admins
exports.notifyAdmins = (notification) => {
  const io = global.io;
  if (io) {
    io.to('admins').emit('admin_notification', notification);
    console.log('Admin notification sent:', notification.type);
  }
};

// Queue and process notifications
exports.queueNotification = async (userId, type, title, message, data = {}) => {
  try {
    await db.query(
      `INSERT INTO notification_queue 
       (user_id, notification_type, title, message, data)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, type, title, message, JSON.stringify(data)]
    );
    
    // Try to send immediately if user is online
    const io = global.io;
    if (io) {
      const notification = { type, title, message, data };
      io.to(`user_${userId}`).emit('notification', notification);
    }
    
    return true;
  } catch (error) {
    console.error('Queue notification error:', error);
    return false;
  }
};

// Process pending notifications (call this periodically)
exports.processPendingNotifications = async () => {
  try {
    const pendingNotifications = await db.query(
      `SELECT * FROM notification_queue 
       WHERE sent = false AND scheduled_for <= CURRENT_TIMESTAMP
       ORDER BY scheduled_for ASC
       LIMIT 100`
    );
    
    const io = global.io;
    if (!io) return;
    
    for (const notification of pendingNotifications.rows) {
      try {
        // Send notification
        io.to(`user_${notification.user_id}`).emit('notification', {
          type: notification.notification_type,
          title: notification.title,
          message: notification.message,
          data: notification.data
        });
        
        // Mark as sent
        await db.query(
          'UPDATE notification_queue SET sent = true, sent_at = CURRENT_TIMESTAMP WHERE id = $1',
          [notification.id]
        );
        
        console.log(`Sent notification ${notification.id} to user ${notification.user_id}`);
      } catch (error) {
        console.error(`Failed to send notification ${notification.id}:`, error);
      }
    }
  } catch (error) {
    console.error('Process notifications error:', error);
  }
};