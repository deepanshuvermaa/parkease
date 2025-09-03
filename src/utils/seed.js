const bcrypt = require('bcryptjs');
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? {
    rejectUnauthorized: false
  } : false
});

async function seed() {
  try {
    console.log('🌱 Starting database seed...');
    
    // Create admin user
    const adminPassword = 'admin123';
    const adminHash = await bcrypt.hash(adminPassword, 10);
    
    await pool.query(
      `INSERT INTO users (username, password_hash, full_name, role, is_paid)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (username) DO NOTHING`,
      ['admin', adminHash, 'Administrator', 'admin', true]
    );
    console.log('✅ Admin user created (username: admin, password: admin123)');
    
    // Create demo user
    const demoPassword = 'demo123';
    const demoHash = await bcrypt.hash(demoPassword, 10);
    
    const trialStart = new Date();
    const trialEnd = new Date();
    trialEnd.setDate(trialEnd.getDate() + 30);
    
    await pool.query(
      `INSERT INTO users (username, password_hash, full_name, role, trial_start_date, trial_end_date)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (username) DO NOTHING`,
      ['demo', demoHash, 'Demo User', 'operator', trialStart, trialEnd]
    );
    console.log('✅ Demo user created (username: demo, password: demo123)');
    
    // Add default system settings
    const defaultSettings = {
      'system.name': 'ParkEase Parking Management',
      'system.version': '1.0.0',
      'system.currency': 'INR',
      'system.timezone': 'Asia/Kolkata',
      'parking.default_rate': 20,
      'parking.grace_period_minutes': 15,
      'parking.minimum_charge_minutes': 30
    };
    
    for (const [key, value] of Object.entries(defaultSettings)) {
      await pool.query(
        `INSERT INTO settings (user_id, key, value)
         VALUES (NULL, $1, $2)
         ON CONFLICT (user_id, key) DO NOTHING`,
        [key, JSON.stringify(value)]
      );
    }
    console.log('✅ Default settings added');
    
    console.log('🎉 Database seed completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed error:', error);
    process.exit(1);
  }
}

// Export for use in server.js or run directly
if (require.main === module) {
  seed();
}

module.exports = seed;