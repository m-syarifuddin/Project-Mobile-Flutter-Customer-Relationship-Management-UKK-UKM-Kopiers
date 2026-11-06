const pool = require('../config/database');
const {
  calculateRfm,
  RFM_WINDOW_MS,
} = require('../utils/rfm');

const RFM_CUSTOMERS_QUERY = `SELECT
  c.id,
  u.name,
  u.phone,
  u.email,
  u.is_active,
  c.joined_at,
  c.points_balance,
  COALESCE(t.transaction_count, 0) AS transaction_count,
  COALESCE(t.lifetime_value, 0) AS lifetime_value,
  COALESCE(t.rfm_transaction_count, 0) AS rfm_transaction_count,
  COALESCE(t.rfm_monetary_value, 0) AS rfm_monetary_value,
  t.last_purchase
FROM customers c
INNER JOIN users u ON u.id = c.user_id
LEFT JOIN (
  SELECT
    customer_id,
    COUNT(DISTINCT id) AS transaction_count,
    COALESCE(SUM(total_amount), 0) AS lifetime_value,
    MAX(created_at) AS last_purchase,
    COUNT(DISTINCT CASE
      WHEN created_at >= ? THEN id
    END) AS rfm_transaction_count,
    COALESCE(SUM(CASE
      WHEN created_at >= ? THEN total_amount
      ELSE 0
    END), 0) AS rfm_monetary_value
  FROM transactions
  WHERE status = 'completed'
    AND created_at <= ?
  GROUP BY customer_id
) t ON t.customer_id = c.id
ORDER BY lifetime_value DESC, transaction_count DESC`;

async function getRfmCustomers(now = new Date()) {
  if (!Number.isFinite(now.getTime())) {
    throw new TypeError('Invalid RFM reference date.');
  }

  const windowStart = new Date(now.getTime() - RFM_WINDOW_MS);
  const [rows] = await pool.execute(
    RFM_CUSTOMERS_QUERY,
    [windowStart, windowStart, now]
  );

  return calculateRfm(rows.map((row) => ({
    ...row,
    transaction_count: Number(row.transaction_count),
    lifetime_value: Number(row.lifetime_value),
    rfm_transaction_count: Number(row.rfm_transaction_count),
    rfm_monetary_value: Number(row.rfm_monetary_value),
  })), now);
}

module.exports = { getRfmCustomers, RFM_CUSTOMERS_QUERY };
