-- ParkEase Database Schema
-- PostgreSQL Database Schema for Railway Deployment

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    is_active BOOLEAN DEFAULT true,
    is_guest BOOLEAN DEFAULT false,
    trial_start_date TIMESTAMP,
    trial_end_date TIMESTAMP,
    is_paid BOOLEAN DEFAULT false,
    subscription_id VARCHAR(255),
    subscription_end_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table (for device tracking)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    device_id VARCHAR(255) NOT NULL,
    device_name VARCHAR(255),
    device_platform VARCHAR(100),
    token VARCHAR(500) NOT NULL,
    ip_address VARCHAR(45),
    is_active BOOLEAN DEFAULT true,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    UNIQUE(user_id, device_id)
);

-- Vehicles table
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id VARCHAR(100) UNIQUE NOT NULL,
    vehicle_number VARCHAR(50),
    vehicle_type VARCHAR(50) NOT NULL,
    entry_time TIMESTAMP NOT NULL,
    exit_time TIMESTAMP,
    rate DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2),
    is_paid BOOLEAN DEFAULT false,
    payment_method VARCHAR(50),
    owner_name VARCHAR(255),
    phone_number VARCHAR(20),
    location_id VARCHAR(100),
    operator_id UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Settings table
CREATE TABLE settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    key VARCHAR(100) NOT NULL,
    value JSONB NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, key)
);

-- Audit log table
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(100),
    details JSONB,
    ip_address VARCHAR(45),
    device_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_sessions_user_device ON sessions(user_id, device_id);
CREATE INDEX idx_sessions_active ON sessions(is_active, user_id);
CREATE INDEX idx_vehicles_entry_time ON vehicles(entry_time DESC);
CREATE INDEX idx_vehicles_exit_time ON vehicles(exit_time);
CREATE INDEX idx_vehicles_operator ON vehicles(operator_id);
CREATE INDEX idx_vehicles_ticket ON vehicles(ticket_id);
CREATE INDEX idx_vehicles_active ON vehicles(exit_time) WHERE exit_time IS NULL;
CREATE INDEX idx_settings_user_key ON settings(user_id, key);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

-- Create update trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (password: admin123)
-- Password hash for 'admin123' using bcrypt
INSERT INTO users (username, password_hash, full_name, role, is_paid)
VALUES (
    'admin',
    '$2a$10$YourHashHere', -- Replace with actual bcrypt hash
    'Administrator',
    'admin',
    true
);

-- Insert demo user (password: demo123)
INSERT INTO users (username, password_hash, full_name, role, trial_start_date, trial_end_date)
VALUES (
    'demo',
    '$2a$10$YourHashHere', -- Replace with actual bcrypt hash
    'Demo User',
    'operator',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '30 days'
);