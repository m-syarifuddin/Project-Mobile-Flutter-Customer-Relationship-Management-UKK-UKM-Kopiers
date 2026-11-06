ALTER TABLE reward_redemptions
  ADD COLUMN redemption_code VARCHAR(32) NULL,
  ADD COLUMN status ENUM('pending', 'claimed') NOT NULL DEFAULT 'pending',
  ADD COLUMN claimed_at TIMESTAMP NULL,
  ADD COLUMN claimed_by BIGINT UNSIGNED NULL;

UPDATE reward_redemptions
SET redemption_code = CONCAT('RWD-', LPAD(id, 20, '0'))
WHERE redemption_code IS NULL;

ALTER TABLE reward_redemptions
  MODIFY COLUMN redemption_code VARCHAR(32) NOT NULL,
  ADD UNIQUE KEY uq_redemptions_code (redemption_code),
  ADD CONSTRAINT fk_redemptions_claimed_by
    FOREIGN KEY (claimed_by) REFERENCES users(id);
