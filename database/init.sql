-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('buyer', 'seller', 'rider')),
    full_name VARCHAR(255) NOT NULL,
    wallet_balance DECIMAL(15, 2) DEFAULT 0.00,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_type ON users(user_type);

-- Insert test user
INSERT INTO users (phone_number, email, user_type, full_name, wallet_balance)
VALUES ('+233244000000', 'test@safepay.gh', 'buyer', 'Test User', 100.00)
ON CONFLICT (phone_number) DO NOTHING;

SELECT 'Database initialized successfully' AS status;
