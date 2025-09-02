const jwt = require('jsonwebtoken');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

exports.authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const token = authHeader.substring(7);
    
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      
      if (decoded.type !== 'access') {
        return res.status(401).json({ error: 'Invalid token type' });
      }
      
      // Get user details
      const userResult = await db.query(
        'SELECT id, username, full_name, role, is_active, is_guest, trial_end_date, is_paid FROM users WHERE id = $1',
        [decoded.userId]
      );
      
      if (userResult.rows.length === 0) {
        return res.status(401).json({ error: 'User not found' });
      }
      
      const user = userResult.rows[0];
      
      if (!user.is_active) {
        return res.status(403).json({ error: 'Account disabled' });
      }
      
      // Check trial expiry
      if (user.trial_end_date && !user.is_paid) {
        const trialEndDate = new Date(user.trial_end_date);
        if (trialEndDate < new Date()) {
          return res.status(403).json({ 
            error: 'Trial expired',
            message: 'Your trial period has ended. Please subscribe to continue.'
          });
        }
      }
      
      req.user = user;
      next();
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Token expired' });
      }
      return res.status(401).json({ error: 'Invalid token' });
    }
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

exports.requireAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

exports.requireOperator = (req, res, next) => {
  if (req.user.role !== 'operator' && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Operator access required' });
  }
  next();
};