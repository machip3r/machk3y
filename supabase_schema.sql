-- MachK3y Password Manager Database Schema
-- Run this SQL in your Supabase SQL editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User settings table
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    user_id UUID REFERENCES auth.users (id) UNIQUE,
    salt TEXT NOT NULL,
    encrypted_recovery_key TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Encrypted credentials table
CREATE TABLE encrypted_credentials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  encrypted_data TEXT NOT NULL,
  nonce TEXT NOT NULL,
  mac TEXT NOT NULL,
  credential_type TEXT NOT NULL,
  title TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  favicon_url TEXT,
  is_starred BOOLEAN DEFAULT FALSE,
  is_shared BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Shared credentials table
CREATE TABLE shared_credentials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    credential_id UUID REFERENCES encrypted_credentials (id),
    shared_by UUID REFERENCES auth.users (id),
    shared_with UUID REFERENCES auth.users (id),
    encrypted_for_recipient TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS on all tables
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

ALTER TABLE encrypted_credentials ENABLE ROW LEVEL SECURITY;

ALTER TABLE shared_credentials ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_settings
CREATE POLICY "Users manage own settings" ON user_settings FOR ALL USING (auth.uid () = user_id);

-- RLS Policies for encrypted_credentials
CREATE POLICY "Users manage own credentials" ON encrypted_credentials FOR ALL USING (auth.uid () = user_id);

-- RLS Policies for shared_credentials
CREATE POLICY "Users see shared credentials" ON shared_credentials FOR
SELECT USING (
        auth.uid () = shared_with
        OR auth.uid () = shared_by
    );

CREATE POLICY "Users can share credentials" ON shared_credentials FOR
INSERT
WITH
    CHECK (auth.uid () = shared_by);

CREATE POLICY "Users can revoke shared credentials" ON shared_credentials FOR DELETE USING (auth.uid () = shared_by);

-- Indexes for better performance
CREATE INDEX idx_encrypted_credentials_user_id ON encrypted_credentials (user_id);

CREATE INDEX idx_encrypted_credentials_type ON encrypted_credentials (credential_type);

CREATE INDEX idx_encrypted_credentials_updated_at ON encrypted_credentials (updated_at);

CREATE INDEX idx_shared_credentials_shared_with ON shared_credentials (shared_with);

CREATE INDEX idx_shared_credentials_shared_by ON shared_credentials (shared_by);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
CREATE TRIGGER encrypted_credentials_handle_updated_at
    BEFORE UPDATE ON encrypted_credentials
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();