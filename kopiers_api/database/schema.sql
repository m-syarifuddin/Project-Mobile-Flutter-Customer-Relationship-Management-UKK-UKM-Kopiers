CREATE DATABASE IF NOT EXISTS db_crm_kopiers_v2
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE db_crm_kopiers_v2;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NULL,
  phone VARCHAR(32) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'customer') NOT NULL DEFAULT 'customer',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  token_version INT UNSIGNED NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_phone (phone),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS customers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  points_balance INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_customers_user (user_id),
  CONSTRAINT fk_customers_user FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(140) NOT NULL,
  description VARCHAR(500) NULL,
  price DECIMAL(12,2) NOT NULL,
  image_url VARCHAR(500) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_products_active_name (is_active, name),
  CONSTRAINT chk_products_price CHECK (price >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS campaigns (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(140) NOT NULL,
  description TEXT NULL,
  campaign_type ENUM('new_customer', 'loyal', 'reengagement', 'personalized') NOT NULL,
  discount_percent DECIMAL(5,2) NULL,
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NOT NULL,
  conditions JSON NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_campaigns_active_dates (is_active, starts_at, ends_at),
  CONSTRAINT fk_campaigns_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT chk_campaigns_dates CHECK (ends_at > starts_at),
  CONSTRAINT chk_campaigns_discount CHECK (discount_percent IS NULL OR (discount_percent >= 0 AND discount_percent <= 100))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  campaign_id BIGINT UNSIGNED NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  status ENUM('completed', 'void') NOT NULL DEFAULT 'completed',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_transactions_customer_date (customer_id, created_at),
  KEY ix_transactions_date (created_at),
  CONSTRAINT fk_transactions_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_transactions_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_transactions_campaign FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
  CONSTRAINT chk_transactions_amount CHECK (total_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transaction_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  transaction_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_name VARCHAR(140) NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  quantity SMALLINT UNSIGNED NOT NULL,
  line_total DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (id),
  KEY ix_transaction_items_transaction (transaction_id),
  CONSTRAINT fk_items_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT chk_items_quantity CHECK (quantity > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS complaints (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  category VARCHAR(80) NOT NULL,
  description TEXT NOT NULL,
  image_url VARCHAR(500) NULL,
  status ENUM('waiting', 'in_progress', 'resolved') NOT NULL DEFAULT 'waiting',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_complaints_status_date (status, created_at),
  KEY ix_complaints_customer_date (customer_id, created_at),
  CONSTRAINT fk_complaints_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS complaint_histories (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  complaint_id BIGINT UNSIGNED NOT NULL,
  changed_by BIGINT UNSIGNED NOT NULL,
  status ENUM('waiting', 'in_progress', 'resolved') NOT NULL,
  response TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_complaint_histories_complaint (complaint_id, created_at),
  CONSTRAINT fk_history_complaint FOREIGN KEY (complaint_id) REFERENCES complaints(id),
  CONSTRAINT fk_history_user FOREIGN KEY (changed_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS point_transactions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  transaction_id BIGINT UNSIGNED NULL,
  entry_type ENUM('earned', 'redeemed', 'adjustment') NOT NULL,
  points INT NOT NULL,
  description VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_points_transaction_type (transaction_id, entry_type),
  KEY ix_points_customer_date (customer_id, created_at),
  CONSTRAINT fk_points_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_points_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rewards (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(140) NOT NULL,
  description VARCHAR(500) NULL,
  points_cost INT UNSIGNED NOT NULL,
  stock INT UNSIGNED NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_rewards_active (is_active),
  CONSTRAINT chk_rewards_points CHECK (points_cost > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reward_redemptions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  reward_id BIGINT UNSIGNED NOT NULL,
  points_spent INT UNSIGNED NOT NULL,
  redemption_code VARCHAR(32) NOT NULL,
  status ENUM('pending', 'claimed') NOT NULL DEFAULT 'pending',
  redeemed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  claimed_at TIMESTAMP NULL,
  claimed_by BIGINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_redemptions_code (redemption_code),
  KEY ix_redemptions_customer_date (customer_id, redeemed_at),
  CONSTRAINT fk_redemptions_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_redemptions_reward FOREIGN KEY (reward_id) REFERENCES rewards(id),
  CONSTRAINT fk_redemptions_claimed_by FOREIGN KEY (claimed_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS campaign_audiences (
  campaign_id BIGINT UNSIGNED NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (campaign_id, customer_id),
  CONSTRAINT fk_audience_campaign FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
  CONSTRAINT fk_audience_customer FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS vouchers (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  campaign_id BIGINT UNSIGNED NULL,
  code VARCHAR(40) NOT NULL,
  starts_at DATETIME NOT NULL,
  expires_at DATETIME NOT NULL,
  redeemed_at DATETIME NULL,
  transaction_id BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_vouchers_code (code),
  KEY ix_vouchers_customer_expiry (customer_id, expires_at),
  CONSTRAINT fk_vouchers_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_vouchers_campaign FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
  CONSTRAINT fk_vouchers_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  CONSTRAINT chk_vouchers_dates CHECK (expires_at > starts_at)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS application_settings (
  setting_key VARCHAR(80) NOT NULL,
  setting_value JSON NOT NULL,
  updated_by BIGINT UNSIGNED NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key),
  CONSTRAINT fk_settings_user FOREIGN KEY (updated_by) REFERENCES users(id)
) ENGINE=InnoDB;

INSERT INTO application_settings (setting_key, setting_value) VALUES
  ('segmentation', JSON_OBJECT('active_days', 30, 'new_customer_days', 30, 'loyal_min_transactions', 10, 'high_value_amount', 500000)),
  ('loyalty', JSON_OBJECT('points_per_10000', 1))
ON DUPLICATE KEY UPDATE setting_key = VALUES(setting_key);
