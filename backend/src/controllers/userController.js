const bcrypt = require('bcryptjs');
const db = require('../config/database');

// Get user profile
exports.getProfile = async (req, res) => {
  try {
    const { userId } = req.user;
    
    const result = await db.query(
      `SELECT id, username, full_name, role, is_guest, 
              trial_start_date, trial_end_date, is_paid, 
              subscription_end_date, created_at
       FROM users WHERE id = $1`,
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update profile
exports.updateProfile = async (req, res) => {
  try {
    const { userId } = req.user;
    const { fullName } = req.body;
    
    if (!fullName) {
      return res.status(400).json({ error: 'Full name is required' });
    }
    
    const result = await db.query(
      `UPDATE users 
       SET full_name = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id, username, full_name, role`,
      [fullName, userId]
    );
    
    res.json({
      success: true,
      user: result.rows[0],
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Change password
exports.changePassword = async (req, res) => {
  try {
    const { userId } = req.user;
    const { currentPassword, newPassword } = req.body;
    
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ error: 'Both current and new passwords are required' });
    }
    
    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'New password must be at least 6 characters' });
    }
    
    // Get current password hash
    const userResult = await db.query(
      'SELECT password_hash FROM users WHERE id = $1',
      [userId]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Verify current password
    const isValid = await bcrypt.compare(currentPassword, userResult.rows[0].password_hash);
    if (!isValid) {
      return res.status(401).json({ error: 'Current password is incorrect' });
    }
    
    // Hash new password
    const newPasswordHash = await bcrypt.hash(newPassword, 10);
    
    // Update password
    await db.query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newPasswordHash, userId]
    );
    
    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get subscription details
exports.getSubscription = async (req, res) => {
  try {
    const { userId } = req.user;
    
    const result = await db.query(
      `SELECT is_guest, trial_start_date, trial_end_date, 
              is_paid, subscription_id, subscription_end_date
       FROM users WHERE id = $1`,
      [userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const user = result.rows[0];
    const now = new Date();
    
    let status = 'active';
    let daysRemaining = null;
    
    if (user.is_guest && user.trial_end_date) {
      const trialEnd = new Date(user.trial_end_date);
      daysRemaining = Math.ceil((trialEnd - now) / (1000 * 60 * 60 * 24));
      
      if (daysRemaining <= 0) {
        status = 'expired';
        daysRemaining = 0;
      } else {
        status = 'trial';
      }
    } else if (user.is_paid && user.subscription_end_date) {
      const subEnd = new Date(user.subscription_end_date);
      daysRemaining = Math.ceil((subEnd - now) / (1000 * 60 * 60 * 24));
      
      if (daysRemaining <= 0) {
        status = 'expired';
        daysRemaining = 0;
      }
    }
    
    res.json({
      success: true,
      subscription: {
        status,
        isGuest: user.is_guest,
        isPaid: user.is_paid,
        trialStartDate: user.trial_start_date,
        trialEndDate: user.trial_end_date,
        subscriptionEndDate: user.subscription_end_date,
        daysRemaining
      }
    });
  } catch (error) {
    console.error('Get subscription error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Upgrade subscription (placeholder for payment integration)
exports.upgradeSubscription = async (req, res) => {
  try {
    const { userId } = req.user;
    const { plan, duration } = req.body;
    
    // This is a placeholder for actual payment processing
    // In production, integrate with payment gateway (Razorpay/Stripe)
    
    const subscriptionEndDate = new Date();
    if (duration === 'monthly') {
      subscriptionEndDate.setMonth(subscriptionEndDate.getMonth() + 1);
    } else if (duration === 'yearly') {
      subscriptionEndDate.setFullYear(subscriptionEndDate.getFullYear() + 1);
    }
    
    await db.query(
      `UPDATE users 
       SET is_paid = true, 
           subscription_end_date = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2`,
      [subscriptionEndDate, userId]
    );
    
    res.json({
      success: true,
      message: 'Subscription upgraded successfully',
      subscriptionEndDate
    });
  } catch (error) {
    console.error('Upgrade subscription error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};