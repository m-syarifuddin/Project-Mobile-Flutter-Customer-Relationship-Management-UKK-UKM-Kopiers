
const express = require('express');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { parseJsonValue } = require('../utils/json');
const { classifyLoyalty } = require('../utils/loyalty');
const { getRfmCustomers } = require('../services/rfm-customers');
const { RFM_SEGMENTS } = require('../utils/rfm');

const router = express.Router();

router.use(authenticate, authorize('admin'));

const DEFAULT_RULES = {
  active_days: 30,
  new_customer_days: 30,
  loyal_min_transactions: 10,
  high_value_amount: 500000,
};

const LOYALTY_RULES = {
  bronze: { min: 1, max: 4 },
  silver: { min: 5, max: 9 },
  gold: { min: 10, max: 19 },
  platinum: { min: 20, max: null },
};

const VALUE_RULES = {
  low: { min: 0, max: 249999 },
  medium: { min: 250000, max: 499999 },
  high: { min: 500000, max: null },
};

async function getRules() {
  const [rows] = await pool.execute(
    `SELECT setting_value
     FROM application_settings
     WHERE setting_key = ?`,
    ['segmentation']
  );

  const stored = parseJsonValue(
    rows[0]?.setting_value,
    DEFAULT_RULES
  );

  return {
    ...DEFAULT_RULES,
    ...stored,
  };
}

function classifyActivity(joinedAt, lastPurchase, rules, now) {
  const joined = joinedAt ? new Date(joinedAt) : null;
  const last = lastPurchase ? new Date(lastPurchase) : null;
  const currentTime = now.getTime();

  const newLimit =
    rules.new_customer_days * 24 * 60 * 60 * 1000;

  const activeLimit =
    rules.active_days * 24 * 60 * 60 * 1000;

  if (joined && currentTime - joined.getTime() <= newLimit) {
    return 'new';
  }

  if (last && currentTime - last.getTime() <= activeLimit) {
    return 'active';
  }

  return 'inactive';
}

function classifyCustomerValue(lifetimeValue) {
  if (lifetimeValue >= 500000) return 'high';
  if (lifetimeValue >= 250000) return 'medium';

  return 'low';
}

// Mengambil aturan segmentasi.
router.get('/rules', async (req, res, next) => {
  try {
    return res.json({
      rules: await getRules(),
      loyalty_rules: LOYALTY_RULES,
      value_rules: VALUE_RULES,
    });
  } catch (error) {
    return next(error);
  }
});

// Memperbarui aturan segmentasi.
router.put('/rules', async (req, res, next) => {
  try {
    const input = z.object({
      active_days: z.number().int().min(1).max(365),
      new_customer_days: z.number().int().min(1).max(365),
      loyal_min_transactions: z.number().int().min(1).max(1000),
      high_value_amount: z.number().nonnegative(),
    }).parse(req.body);

    await pool.execute(
      `INSERT INTO application_settings
        (setting_key, setting_value, updated_by)
       VALUES ('segmentation', ?, ?)
       ON DUPLICATE KEY UPDATE
        setting_value = VALUES(setting_value),
        updated_by = VALUES(updated_by)`,
      [JSON.stringify(input), req.user.id]
    );

    return res.json({
      rules: input,
      loyalty_rules: LOYALTY_RULES,
      value_rules: VALUE_RULES,
      message: 'Aturan segmentasi berhasil diperbarui.',
    });
  } catch (error) {
    return next(error);
  }
});

// Daftar pelanggan dengan segmen aktivitas, loyalitas, nilai, dan RFM.
router.get('/', async (req, res, next) => {
  try {
    const filters = z.object({
      segment: z.enum([
        'new',
        'active',
        'inactive',
      ]).optional(),

      loyalty: z.enum([
        'none',
        'bronze',
        'silver',
        'gold',
        'platinum',
      ]).optional(),

      customer_value: z.enum([
        'low',
        'medium',
        'high',
      ]).optional(),
    }).parse(req.query);

    const rules = await getRules();

    const now = new Date();
    const data = (await getRfmCustomers(now)).map((row) => {
      const activitySegment = classifyActivity(
        row.joined_at,
        row.last_purchase,
        rules,
        now
      );

      const loyaltyTier =
        classifyLoyalty(row.transaction_count);

      const customerValue =
        classifyCustomerValue(row.lifetime_value);

      return {
        ...row,
        // Kompatibilitas dengan kode lama.
        segment: activitySegment,

        // Klasifikasi baru.
        activity_segment: activitySegment,
        loyalty_tier: loyaltyTier,
        customer_value: customerValue,
      };
    });

    const filtered = data.filter((row) => {
      if (
        filters.segment &&
        row.activity_segment !== filters.segment
      ) return false;

      if (
        filters.loyalty &&
        row.loyalty_tier !== filters.loyalty
      ) return false;

      if (
        filters.customer_value &&
        row.customer_value !== filters.customer_value
      ) return false;

      return true;
    });

    const summary = {
      activity: {
        new: 0,
        active: 0,
        inactive: 0,
      },

      loyalty: {
        none: 0,
        bronze: 0,
        silver: 0,
        gold: 0,
        platinum: 0,
      },

      customer_value: {
        low: 0,
        medium: 0,
        high: 0,
      },

      rfm: Object.fromEntries(
        RFM_SEGMENTS.map((segment) => [segment, 0])
      ),

      total: data.length,
    };

    for (const customer of data) {
      summary.activity[customer.activity_segment]++;
      summary.loyalty[customer.loyalty_tier]++;
      summary.customer_value[customer.customer_value]++;
      summary.rfm[customer.rfm_segment]++;
    }

    return res.json({
      summary,
      rules,
      data: filtered,
    });

  } catch (error) {
    return next(error);
  }
});

module.exports = router;
