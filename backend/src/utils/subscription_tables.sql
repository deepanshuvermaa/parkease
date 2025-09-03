-- Create subscription_history table
CREATE TABLE IF NOT EXISTS subscription_history (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    extended_by_admin_id VARCHAR(36) NOT NULL,
    days_added INTEGER NOT NULL,
    extension_type VARCHAR(20) DEFAULT 'manual', -- 'manual', 'payment', 'promotional'
    new_end_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (extended_by_admin_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create user_backups table
CREATE TABLE IF NOT EXISTS user_backups (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    backup_data JSONB NOT NULL,
    created_by_admin_id VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    restored_at TIMESTAMP NULL,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_admin_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create notification_queue table for push notifications
CREATE TABLE IF NOT EXISTS notification_queue (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    notification_type VARCHAR(50) NOT NULL, -- 'TRIAL_EXPIRING', 'SUBSCRIPTION_EXTENDED', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    sent BOOLEAN DEFAULT FALSE,
    scheduled_for TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_subscription_history_user_id ON subscription_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_backups_user_id ON user_backups(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_user_id ON notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_queue_scheduled ON notification_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_notification_queue_sent ON notification_queue(sent);

-- Add subscription columns to users table if they don't exist
DO $$ 
BEGIN
    -- Check if subscription_end_date column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'subscription_end_date') THEN
        ALTER TABLE users ADD COLUMN subscription_end_date TIMESTAMP NULL;
    END IF;
    
    -- Check if is_paid column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'is_paid') THEN
        ALTER TABLE users ADD COLUMN is_paid BOOLEAN DEFAULT FALSE;
    END IF;
END $$;