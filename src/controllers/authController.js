const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';

// Generate tokens
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId, type: 'access' },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
  
  const refreshToken = jwt.sign(
    { userId, type: 'refresh' },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );
  
  return { accessToken, refreshToken };
};

// Login
exports.login = async (req, res) => {
  try {
    const { username, password, deviceId, deviceName, devicePlatform } = req.body;
    
    // Get user
    const userResult = await db.query(
      'SELECT * FROM users WHERE username = $1 AND is_active = true',
      [username]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = userResult.rows[0];
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    // Check subscription status
    const now = new Date();
    if (user.trial_end_date && new Date(user.trial_end_date) < now && !user.is_paid) {
      return res.status(403).json({ 
        error: 'Trial expired', 
        message: 'Your trial period has ended. Please subscribe to continue.'
      });
    }
    
    // Check for existing sessions and enforce single device
    const existingSession = await db.query(
      'SELECT * FROM sessions WHERE user_id = $1 AND device_id != $2 AND is_active = true',
      [user.id, deviceId]
    );
    
    if (existingSession.rows.length > 0) {
      // Deactivate other sessions
      await db.query(
        'UPDATE sessions SET is_active = false, logout_time = CURRENT_TIMESTAMP WHERE user_id = $1 AND device_id != $2',
        [user.id, deviceId]
      );
    }
    
    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id);
    
    // Create or update session
    await db.query(
      `INSERT INTO sessions (id, user_id, device_id, device_name, device_platform, token, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (user_id, device_id)
       DO UPDATE SET 
         token = $6,
         is_active = true,
         last_activity = CURRENT_TIMESTAMP,
         login_time = CURRENT_TIMESTAMP,
         logout_time = NULL`,
      [uuidv4(), user.id, deviceId, deviceName, devicePlatform, refreshToken, req.ip]
    );
    
    // Remove password from response
    delete user.password_hash;
    
    res.json({
      success: true,
      user,
      accessToken,
      refreshToken,
      message: existingSession.rows.length > 0 ? 'Logged in from new device. Other devices have been logged out.' : 'Login successful'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Logout
exports.logout = async (req, res) => {
  try {
    const { userId } = req.user;
    const { deviceId } = req.body;
    
    await db.query(
      `UPDATE sessions 
       SET is_active = false, logout_time = CURRENT_TIMESTAMP 
       WHERE user_id = $1 AND device_id = $2`,
      [userId, deviceId]
    );
    
    res.json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Refresh token
exports.refresh = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(401).json({ error: 'Refresh token required' });
    }
    
    // Verify refresh token
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    
    if (decoded.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid token type' });
    }
    
    // Check if session exists and is active
    const sessionResult = await db.query(
      'SELECT * FROM sessions WHERE user_id = $1 AND token = $2 AND is_active = true',
      [decoded.userId, refreshToken]
    );
    
    if (sessionResult.rows.length === 0) {
      return res.status(401).json({ error: 'Session not found or inactive' });
    }
    
    // Generate new tokens
    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);
    
    // Update session with new refresh token
    await db.query(
      'UPDATE sessions SET token = $1, last_activity = CURRENT_TIMESTAMP WHERE user_id = $2 AND token = $3',
      [newRefreshToken, decoded.userId, refreshToken]
    );
    
    res.json({
      success: true,
      accessToken,
      refreshToken: newRefreshToken
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

// Guest signup
exports.guestSignup = async (req, res) => {
  try {
    const { deviceId, deviceName, devicePlatform } = req.body;
    
    // Generate guest credentials
    const guestUsername = `guest_${Date.now()}`;
    const guestPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(guestPassword, 10);
    
    // Calculate trial dates
    const trialStartDate = new Date();
    const trialEndDate = new Date();
    trialEndDate.setDate(trialEndDate.getDate() + 3);
    
    // Create guest user
    const userResult = await db.query(
      `INSERT INTO users (id, username, password_hash, full_name, role, is_guest, trial_start_date, trial_end_date)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        uuidv4(),
        guestUsername,
        hashedPassword,
        'Guest User',
        'operator',
        true,
        trialStartDate,
        trialEndDate
      ]
    );
    
    const user = userResult.rows[0];
    
    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id);
    
    // Create session
    await db.query(
      `INSERT INTO sessions (id, user_id, device_id, device_name, device_platform, token, ip_address)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [uuidv4(), user.id, deviceId, deviceName, devicePlatform, refreshToken, req.ip]
    );
    
    // Remove password from response
    delete user.password_hash;
    
    res.json({
      success: true,
      user,
      accessToken,
      refreshToken,
      credentials: {
        username: guestUsername,
        password: guestPassword
      },
      message: 'Guest account created with 3-day trial'
    });
  } catch (error) {
    console.error('Guest signup error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get active sessions
exports.getSessions = async (req, res) => {
  try {
    const { userId } = req.user;
    
    const sessions = await db.query(
      `SELECT id, device_id, device_name, device_platform, ip_address, 
              login_time, last_activity, is_active
       FROM sessions 
       WHERE user_id = $1 AND is_active = true
       ORDER BY last_activity DESC`,
      [userId]
    );
    
    res.json({
      success: true,
      sessions: sessions.rows
    });
  } catch (error) {
    console.error('Get sessions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Force logout specific device
exports.forceLogout = async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { userId } = req.user;
    
    await db.query(
      `UPDATE sessions 
       SET is_active = false, logout_time = CURRENT_TIMESTAMP 
       WHERE id = $1 AND user_id = $2`,
      [sessionId, userId]
    );
    
    res.json({ success: true, message: 'Device logged out successfully' });
  } catch (error) {
    console.error('Force logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};