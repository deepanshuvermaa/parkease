const db = require('../config/database');

// Get all user settings
exports.getSettings = async (req, res) => {
  try {
    const { userId } = req.user;
    
    const result = await db.query(
      'SELECT key, value FROM settings WHERE user_id = $1',
      [userId]
    );
    
    const settings = {};
    result.rows.forEach(row => {
      settings[row.key] = row.value;
    });
    
    res.json({
      success: true,
      settings
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update settings
exports.updateSettings = async (req, res) => {
  try {
    const { userId } = req.user;
    const { settings } = req.body;
    
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ error: 'Invalid settings format' });
    }
    
    // Start transaction
    await db.query('BEGIN');
    
    try {
      for (const [key, value] of Object.entries(settings)) {
        await db.query(
          `INSERT INTO settings (user_id, key, value)
           VALUES ($1, $2, $3)
           ON CONFLICT (user_id, key)
           DO UPDATE SET value = $3, updated_at = CURRENT_TIMESTAMP`,
          [userId, key, JSON.stringify(value)]
        );
      }
      
      await db.query('COMMIT');
      
      res.json({
        success: true,
        message: 'Settings updated successfully'
      });
    } catch (error) {
      await db.query('ROLLBACK');
      throw error;
    }
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Get single setting
exports.getSetting = async (req, res) => {
  try {
    const { userId } = req.user;
    const { key } = req.params;
    
    const result = await db.query(
      'SELECT value FROM settings WHERE user_id = $1 AND key = $2',
      [userId, key]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Setting not found' });
    }
    
    res.json({
      success: true,
      key,
      value: result.rows[0].value
    });
  } catch (error) {
    console.error('Get setting error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Update single setting
exports.updateSetting = async (req, res) => {
  try {
    const { userId } = req.user;
    const { key } = req.params;
    const { value } = req.body;
    
    if (value === undefined) {
      return res.status(400).json({ error: 'Value is required' });
    }
    
    await db.query(
      `INSERT INTO settings (user_id, key, value)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, key)
       DO UPDATE SET value = $3, updated_at = CURRENT_TIMESTAMP`,
      [userId, key, JSON.stringify(value)]
    );
    
    res.json({
      success: true,
      message: 'Setting updated successfully',
      key,
      value
    });
  } catch (error) {
    console.error('Update setting error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};