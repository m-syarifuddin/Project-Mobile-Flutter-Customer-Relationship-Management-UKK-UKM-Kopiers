const express = require('express');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { parseJsonValue } = require('../utils/json');
const { getRfmCustomers } = require('../services/rfm-customers');
const { RFM_SEGMENTS, RFM_WINDOW_DAYS } = require('../utils/rfm');

const router = express.Router();
router.use(authenticate, authorize('admin'));

router.get('/', async (req, res, next) => {
  try {
    const [[customers]] = await pool.execute(
      `SELECT COUNT(*) AS total,
              SUM(u.is_active = TRUE) AS enabled_accounts,
              SUM(u.is_active = FALSE) AS disabled_accounts,
              SUM(c.points_balance > 0) AS with_points
       FROM customers c JOIN users u ON u.id = c.user_id`
    );
    const [[sales]] = await pool.execute(
      `SELECT COUNT(*) AS transaction_count, COALESCE(SUM(total_amount), 0) AS total_sales
       FROM transactions WHERE status = 'completed'
       AND created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)`
    );
    const [[complaints]] = await pool.execute(
      `SELECT COUNT(*) AS open_count FROM complaints WHERE status != 'resolved'`
    );
    const [[loyalty]] = await pool.execute(
      `SELECT COALESCE(SUM(points_balance), 0) AS points_outstanding FROM customers`
    );
    const [[campaigns]] = await pool.execute(
      `SELECT COUNT(*) AS active_count FROM campaigns
       WHERE is_active = TRUE AND starts_at <= NOW() AND ends_at >= NOW()`
    );
    const [[programs]] = await pool.execute(
      `SELECT
         (SELECT COUNT(*) FROM rewards WHERE is_active = TRUE) AS active_rewards,
         (SELECT COUNT(*) FROM vouchers
          WHERE redeemed_at IS NULL AND starts_at <= NOW() AND expires_at >= NOW()) AS available_vouchers,
         (SELECT COUNT(*) FROM vouchers WHERE redeemed_at IS NOT NULL) AS redeemed_vouchers`
    );
    const [activity] = await pool.execute(
      `SELECT DATE(created_at) AS date, COUNT(*) AS transaction_count,
              COALESCE(SUM(total_amount), 0) AS sales
       FROM transactions
       WHERE status = 'completed' AND created_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
       GROUP BY DATE(created_at) ORDER BY date`
    );
    const [customerGrowth] = await pool.execute(
      `SELECT DATE(joined_at) AS date, COUNT(*) AS customer_count
       FROM customers
       WHERE joined_at >= DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY)
       GROUP BY DATE(joined_at) ORDER BY date`
    );
    const [settings] = await pool.execute(
      'SELECT setting_value FROM application_settings WHERE setting_key = ?',
      ['segmentation']
    );
    const evaluatedAt = new Date();
    const rfmCustomers = await getRfmCustomers(evaluatedAt);
    const rfmSummary = Object.fromEntries(
      RFM_SEGMENTS.map((segment) => [segment, 0])
    );
    for (const customer of rfmCustomers) {
      rfmSummary[customer.rfm_segment]++;
    }

    const rules = parseJsonValue(settings[0]?.setting_value, {});
    const [segmentRows] = await pool.execute(
      `SELECT
         SUM(stats.last_purchase >= DATE_SUB(NOW(), INTERVAL ? DAY)) AS active,
         SUM(stats.last_purchase < DATE_SUB(NOW(), INTERVAL ? DAY) OR stats.last_purchase IS NULL) AS inactive,
         SUM(stats.purchase_count >= ?) AS loyal,
         SUM(stats.lifetime_value >= ?) AS high_value
       FROM (
         SELECT c.id, MAX(CASE WHEN t.status = 'completed' THEN t.created_at END) AS last_purchase,
                COUNT(CASE WHEN t.status = 'completed' THEN t.id END) AS purchase_count,
                COALESCE(SUM(CASE WHEN t.status = 'completed' THEN t.total_amount ELSE 0 END), 0) AS lifetime_value
         FROM customers c LEFT JOIN transactions t ON t.customer_id = c.id
         GROUP BY c.id
       ) stats`,
      [
        Number(rules.active_days || 30),
        Number(rules.active_days || 30),
        Number(rules.loyal_min_transactions || 10),
        Number(rules.high_value_amount || 500000)
      ]
    );
    return res.json({
      customers: {
        ...customers,
        active: segmentRows[0].active || 0,
        inactive: segmentRows[0].inactive || 0,
        loyal: segmentRows[0].loyal || 0,
        high_value: segmentRows[0].high_value || 0
      },
      sales,
      complaints,
      loyalty,
      campaigns,
      programs,
      activity,
      customer_growth: customerGrowth,
      rfm: {
        evaluated_at: evaluatedAt.toISOString(),
        window_days: RFM_WINDOW_DAYS,
        scoring_method: 'cohort_quintile',
        segments: rfmSummary,
        total: rfmCustomers.length
      }
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
