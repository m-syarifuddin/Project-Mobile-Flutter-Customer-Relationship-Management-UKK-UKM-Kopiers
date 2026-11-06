const express = require('express');
const { randomBytes } = require('node:crypto');
const { z } = require('zod');

const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { parseJsonValue } = require('../utils/json');

const router = express.Router();

router.use(authenticate);

// ==========================================
// KONFIGURASI SEGMENTASI
// ==========================================

const TARGET_DIMENSIONS = {
  activity: ['new', 'active', 'inactive'],
  loyalty: ['none', 'bronze', 'silver', 'gold', 'platinum'],
  customer_value: ['low', 'medium', 'high'],
};

const DEFAULT_RULES = {
  active_days: 30,
  new_customer_days: 30,
  loyal_min_transactions: 10,
  high_value_amount: 500000,
};

// ==========================================
// MENGAMBIL ATURAN SEGMENTASI
// ==========================================

async function getSegmentationRules(connection) {
  const [settings] = await connection.execute(
    `SELECT setting_value
     FROM application_settings
     WHERE setting_key = ?`,
    ['segmentation']
  );

  const storedRules = parseJsonValue(
    settings[0]?.setting_value,
    DEFAULT_RULES
  );

  return {
    active_days: Number(
      storedRules.active_days ?? DEFAULT_RULES.active_days
    ),

    new_customer_days: Number(
      storedRules.new_customer_days ??
      DEFAULT_RULES.new_customer_days
    ),

    loyal_min_transactions: Number(
      storedRules.loyal_min_transactions ??
      DEFAULT_RULES.loyal_min_transactions
    ),

    high_value_amount: Number(
      storedRules.high_value_amount ??
      DEFAULT_RULES.high_value_amount
    ),
  };
}

// ==========================================
// KONDISI SQL BERDASARKAN DIMENSI
// ==========================================

function getTargetCondition(dimension, value, rules) {
  if (!TARGET_DIMENSIONS[dimension]?.includes(value)) {
    throw new Error('Target segmentasi tidak valid.');
  }

  // ----------------------------------------
  // 1. ACTIVITY
  // ----------------------------------------

  if (dimension === 'activity') {
    if (value === 'new') {
      return {
        sql: `
          c.joined_at >= DATE_SUB(
            NOW(), INTERVAL ? DAY
          )
        `,
        params: [rules.new_customer_days],
      };
    }

    if (value === 'active') {
      return {
        sql: `
          c.joined_at < DATE_SUB(
            NOW(), INTERVAL ? DAY
          )
          AND stats.last_purchase >= DATE_SUB(
            NOW(), INTERVAL ? DAY
          )
        `,
        params: [
          rules.new_customer_days,
          rules.active_days,
        ],
      };
    }

    return {
      sql: `
        c.joined_at < DATE_SUB(
          NOW(), INTERVAL ? DAY
        )
        AND (
          stats.last_purchase IS NULL
          OR stats.last_purchase < DATE_SUB(
            NOW(), INTERVAL ? DAY
          )
        )
      `,
      params: [
        rules.new_customer_days,
        rules.active_days,
      ],
    };
  }

  // ----------------------------------------
  // 2. LOYALTY
  // ----------------------------------------

  if (dimension === 'loyalty') {
    const ranges = {
      none: {
        min: 0,
        max: 0,
      },
      bronze: {
        min: 1,
        max: 4,
      },
      silver: {
        min: 5,
        max: 9,
      },
      gold: {
        min: 10,
        max: 19,
      },
      platinum: {
        min: 20,
        max: null,
      },
    };

    const range = ranges[value];

    if (range.max === null) {
      return {
        sql: `
          COALESCE(stats.purchase_count, 0) >= ?
        `,
        params: [range.min],
      };
    }

    return {
      sql: `
        COALESCE(stats.purchase_count, 0) >= ?
        AND COALESCE(stats.purchase_count, 0) <= ?
      `,
      params: [range.min, range.max],
    };
  }

  // ----------------------------------------
  // 3. CUSTOMER VALUE
  // ----------------------------------------

  const valueRanges = {
    low: {
      min: 0,
      max: 249999.99,
    },
    medium: {
      min: 250000,
      max: 499999.99,
    },
    high: {
      min: 500000,
      max: null,
    },
  };

  const range = valueRanges[value];

  if (range.max === null) {
    return {
      sql: `
        COALESCE(stats.lifetime_value, 0) >= ?
      `,
      params: [range.min],
    };
  }

  return {
    sql: `
      COALESCE(stats.lifetime_value, 0) >= ?
      AND COALESCE(stats.lifetime_value, 0) <= ?
    `,
    params: [range.min, range.max],
  };
}

// ==========================================
// REFRESH AUDIENS KAMPANYE
// ==========================================

async function refreshCampaignAudience(
  connection,
  campaignId,
  targetDimension,
  targetSegment,
  rules
) {
  const condition = getTargetCondition(
    targetDimension,
    targetSegment,
    rules
  );

  // Hapus snapshot audiens lama.
  // Riwayat voucher dan transaksi tetap aman.
  await connection.execute(
    `DELETE FROM campaign_audiences
     WHERE campaign_id = ?`,
    [campaignId]
  );

  // Masukkan pelanggan sesuai target kampanye.
  const [result] = await connection.execute(
    `INSERT IGNORE INTO campaign_audiences
       (campaign_id, customer_id)
     SELECT ?, c.id
     FROM customers c
     INNER JOIN users u
       ON u.id = c.user_id
     LEFT JOIN (
       SELECT
         customer_id,
         COUNT(*) AS purchase_count,
         COALESCE(SUM(total_amount), 0) AS lifetime_value,
         MAX(created_at) AS last_purchase
       FROM transactions
       WHERE status = 'completed'
       GROUP BY customer_id
     ) stats
       ON stats.customer_id = c.id
     WHERE u.is_active = TRUE
       AND (${condition.sql})`,
    [
      campaignId,
      ...condition.params,
    ]
  );

  const [countRows] = await connection.execute(
    `SELECT COUNT(*) AS audience_count
     FROM campaign_audiences
     WHERE campaign_id = ?`,
    [campaignId]
  );

  return {
    audience_count: Number(countRows[0].audience_count),
    inserted_count: result.affectedRows,
  };
}

// ==========================================
// DAFTAR KAMPANYE
// ==========================================

router.get('/', async (req, res, next) => {
  try {
    let rows;

    if (req.user.role === 'admin') {
      [rows] = await pool.execute(
        `SELECT
           id,
           name,
           description,
           campaign_type,
           target_dimension,
           target_segment,
           discount_percent,
           starts_at,
           ends_at,
           conditions,
           is_active
         FROM campaigns
         ORDER BY created_at DESC`
      );
    } else {
      [rows] = await pool.execute(
        `SELECT DISTINCT
           ca.id,
           ca.name,
           ca.description,
           ca.campaign_type,
           ca.target_dimension,
           ca.target_segment,
           ca.discount_percent,
           ca.starts_at,
           ca.ends_at,
           ca.conditions
         FROM campaigns ca
         INNER JOIN campaign_audiences a
           ON a.campaign_id = ca.id
         INNER JOIN customers c
           ON c.id = a.customer_id
         WHERE c.user_id = ?
           AND ca.is_active = TRUE
           AND ca.starts_at <= NOW()
           AND ca.ends_at >= NOW()
         ORDER BY ca.ends_at ASC`,
        [req.user.id]
      );
    }

    return res.json({
      data: rows,
    });
  } catch (error) {
    return next(error);
  }
});

// ==========================================
// MEMBUAT KAMPANYE
// ==========================================

router.post(
  '/',
  authorize('admin'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const input = z.object({
        name: z.string().trim().min(1).max(140),

        description: z.string()
          .trim()
          .max(5000)
          .optional()
          .nullable(),

        campaign_type: z.enum([
          'new_customer',
          'loyal',
          'reengagement',
          'personalized',
        ]),

        target_dimension: z.enum([
          'activity',
          'loyalty',
          'customer_value',
        ]),

        target_segment: z.string().min(1),

        discount_percent: z.number()
          .min(0)
          .max(100)
          .optional()
          .nullable(),

        starts_at: z.string().datetime(),
        ends_at: z.string().datetime(),

        conditions: z.record(
          z.string(),
          z.unknown()
        ).optional(),
      }).refine(
        (data) =>
          new Date(data.ends_at) > new Date(data.starts_at),
        {
          message: 'Tanggal berakhir harus setelah tanggal mulai.',
          path: ['ends_at'],
        }
      ).parse(req.body);

      if (
        !TARGET_DIMENSIONS[input.target_dimension]
          ?.includes(input.target_segment)
      ) {
        return res.status(400).json({
          error: 'Target segmentasi tidak valid.',
        });
      }

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [result] = await connection.execute(
        `INSERT INTO campaigns (
           name,
           description,
           campaign_type,
           target_dimension,
           target_segment,
           discount_percent,
           starts_at,
           ends_at,
           conditions,
           created_by
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          input.name,
          input.description || null,
          input.campaign_type,
          input.target_dimension,
          input.target_segment,
          input.discount_percent ?? null,
          input.starts_at,
          input.ends_at,
          JSON.stringify(input.conditions || {}),
          req.user.id,
        ]
      );

      const rules = await getSegmentationRules(connection);

      const audience = await refreshCampaignAudience(
        connection,
        result.insertId,
        input.target_dimension,
        input.target_segment,
        rules
      );

      await connection.commit();
      transactionStarted = false;

      return res.status(201).json({
        id: result.insertId,
        target_dimension: input.target_dimension,
        target_segment: input.target_segment,
        audience_count: audience.audience_count,
        message: 'Kampanye berhasil dibuat.',
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) {
        connection.release();
      }
    }
  }
);

// ==========================================
// REFRESH AUDIENS MANUAL
// ==========================================

router.post(
  '/:id/refresh-audience',
  authorize('admin'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const id = z.coerce.number()
        .int()
        .positive()
        .parse(req.params.id);

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [campaigns] = await connection.execute(
        `SELECT
           id,
           target_dimension,
           target_segment
         FROM campaigns
         WHERE id = ?
         FOR UPDATE`,
        [id]
      );

      if (!campaigns[0]) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(404).json({
          error: 'Kampanye tidak ditemukan.',
        });
      }

      const rules = await getSegmentationRules(connection);

      const audience = await refreshCampaignAudience(
        connection,
        id,
        campaigns[0].target_dimension,
        campaigns[0].target_segment,
        rules
      );

      await connection.commit();
      transactionStarted = false;

      return res.json({
        target_dimension: campaigns[0].target_dimension,
        target_segment: campaigns[0].target_segment,
        audience_count: audience.audience_count,
        message: 'Audiens kampanye berhasil diperbarui.',
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) {
        connection.release();
      }
    }
  }
);

// ==========================================
// TERBITKAN VOUCHER KAMPANYE
// ==========================================

router.post(
  '/:id/vouchers',
  authorize('admin'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const id = z.coerce.number()
        .int()
        .positive()
        .parse(req.params.id);

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [campaigns] = await connection.execute(
        `SELECT
           id,
           starts_at,
           ends_at,
           target_dimension,
           target_segment
         FROM campaigns
         WHERE id = ?
           AND is_active = TRUE
           AND starts_at <= NOW()
           AND ends_at >= NOW()
         FOR UPDATE`,
        [id]
      );

      if (!campaigns[0]) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(404).json({
          error:
            'Kampanye tidak ditemukan, belum berlaku, atau tidak aktif.',
        });
      }

      const rules = await getSegmentationRules(connection);

      const audienceResult = await refreshCampaignAudience(
        connection,
        id,
        campaigns[0].target_dimension,
        campaigns[0].target_segment,
        rules
      );

      // Ambil customer yang belum mempunyai voucher.
      const [audience] = await connection.execute(
        `SELECT a.customer_id
         FROM campaign_audiences a
         LEFT JOIN vouchers v
           ON v.campaign_id = a.campaign_id
          AND v.customer_id = a.customer_id
         WHERE a.campaign_id = ?
           AND v.customer_id IS NULL`,
        [id]
      );

      let voucherCount = 0;

      for (const customer of audience) {
        const code =
          `KOP-${randomBytes(8).toString('hex').toUpperCase()}`;

        await connection.execute(
          `INSERT INTO vouchers (
             customer_id,
             campaign_id,
             code,
             starts_at,
             expires_at
           ) VALUES (?, ?, ?, ?, ?)`,
          [
            customer.customer_id,
            id,
            code,
            campaigns[0].starts_at,
            campaigns[0].ends_at,
          ]
        );

        voucherCount++;
      }

      await connection.commit();
      transactionStarted = false;

      return res.status(201).json({
        audience_count: audienceResult.audience_count,
        voucher_count: voucherCount,
        message: `${voucherCount} voucher baru berhasil diterbitkan.`,
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) {
        connection.release();
      }
    }
  }
);

// ==========================================
// LAPORAN KAMPANYE
// ==========================================

router.get(
  '/:id/report',
  authorize('admin'),
  async (req, res, next) => {
    try {
      const id = z.coerce.number()
        .int()
        .positive()
        .parse(req.params.id);

      const [rows] = await pool.execute(
        `SELECT
           (
             SELECT COUNT(*)
             FROM campaign_audiences
             WHERE campaign_id = ?
           ) AS audience_count,

           (
             SELECT COUNT(*)
             FROM vouchers
             WHERE campaign_id = ?
           ) AS voucher_count,

           (
             SELECT COUNT(*)
             FROM vouchers
             WHERE campaign_id = ?
               AND redeemed_at IS NOT NULL
           ) AS redeemed_count,

           (
             SELECT COUNT(DISTINCT transaction_id)
             FROM vouchers
             WHERE campaign_id = ?
               AND transaction_id IS NOT NULL
           ) AS transaction_count,

           (
             SELECT COALESCE(SUM(total_amount), 0)
             FROM transactions
             WHERE campaign_id = ?
               AND status = 'completed'
           ) AS sales_amount`,
        [id, id, id, id, id]
      );

      return res.json({
        report: rows[0],
      });
    } catch (error) {
      return next(error);
    }
  }
);

// ==========================================
// EDIT KAMPANYE
// ==========================================

router.patch(
  '/:id',
  authorize('admin'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const id = z.coerce.number()
        .int()
        .positive()
        .parse(req.params.id);

      const input = z.object({
        name: z.string()
          .trim()
          .min(1)
          .max(140)
          .optional(),

        description: z.string()
          .trim()
          .max(5000)
          .nullable()
          .optional(),

        campaign_type: z.enum([
          'new_customer',
          'loyal',
          'reengagement',
          'personalized',
        ]).optional(),

        target_dimension: z.enum([
          'activity',
          'loyalty',
          'customer_value',
        ]).optional(),

        target_segment: z.string()
          .min(1)
          .optional(),

        discount_percent: z.number()
          .min(0)
          .max(100)
          .nullable()
          .optional(),

        starts_at: z.string()
          .datetime()
          .optional(),

        ends_at: z.string()
          .datetime()
          .optional(),

        conditions: z.record(
          z.string(),
          z.unknown()
        ).optional(),
      }).refine(
        (data) => Object.keys(data).length > 0,
        'Kirim minimal satu nilai untuk diperbarui.'
      ).parse(req.body);

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [currentRows] = await connection.execute(
        `SELECT
           id,
           starts_at,
           ends_at,
           target_dimension,
           target_segment
         FROM campaigns
         WHERE id = ?
         FOR UPDATE`,
        [id]
      );

      if (!currentRows[0]) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(404).json({
          error: 'Kampanye tidak ditemukan.',
        });
      }

      const current = currentRows[0];

      const startsAt =
        input.starts_at || current.starts_at;

      const endsAt =
        input.ends_at || current.ends_at;

      if (new Date(endsAt) <= new Date(startsAt)) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(400).json({
          error: 'Tanggal berakhir harus setelah tanggal mulai.',
        });
      }

      const targetDimension =
        input.target_dimension || current.target_dimension;

      const targetSegment =
        input.target_segment || current.target_segment;

      if (
        !TARGET_DIMENSIONS[targetDimension]
          ?.includes(targetSegment)
      ) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(400).json({
          error: 'Target segmentasi tidak valid.',
        });
      }

      const fields = Object.keys(input);

      const values = fields.map((field) =>
        field === 'conditions'
          ? JSON.stringify(input[field])
          : input[field]
      );

      await connection.execute(
        `UPDATE campaigns
         SET ${fields
           .map((field) => `${field} = ?`)
           .join(', ')}
         WHERE id = ?`,
        [...values, id]
      );

      const targetChanged =
        targetDimension !== current.target_dimension ||
        targetSegment !== current.target_segment;

      let audienceCount;

      if (targetChanged) {
        const rules = await getSegmentationRules(connection);

        const audience = await refreshCampaignAudience(
          connection,
          id,
          targetDimension,
          targetSegment,
          rules
        );

        audienceCount = audience.audience_count;
      }

      await connection.commit();
      transactionStarted = false;

      return res.json({
        message: 'Kampanye berhasil diperbarui.',
        target_dimension: targetDimension,
        target_segment: targetSegment,

        ...(audienceCount !== undefined
          ? { audience_count: audienceCount }
          : {}),
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) {
        connection.release();
      }
    }
  }
);

// ==========================================
// AKTIFKAN / NONAKTIFKAN KAMPANYE
// ==========================================

router.patch(
  '/:id/status',
  authorize('admin'),
  async (req, res, next) => {
    try {
      const id = z.coerce.number()
        .int()
        .positive()
        .parse(req.params.id);

      const { is_active: isActive } = z.object({
        is_active: z.boolean(),
      }).parse(req.body);

      const [result] = await pool.execute(
        `UPDATE campaigns
         SET is_active = ?
         WHERE id = ?`,
        [isActive, id]
      );

      if (!result.affectedRows) {
        return res.status(404).json({
          error: 'Kampanye tidak ditemukan.',
        });
      }

      return res.json({
        message: 'Status kampanye diperbarui.',
      });
    } catch (error) {
      return next(error);
    }
  }
);

module.exports = router;