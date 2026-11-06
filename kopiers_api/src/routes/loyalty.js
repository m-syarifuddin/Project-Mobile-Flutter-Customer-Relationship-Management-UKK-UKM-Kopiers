const express = require('express');
const { randomBytes } = require('node:crypto');
const { z } = require('zod');

const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { parseJsonValue } = require('../utils/json');
const { classifyLoyalty } = require('../utils/loyalty');

const router = express.Router();

router.use(authenticate);

// ======================================================
// LOYALTY CUSTOMER: POIN DAN KARTU MEMBER
// ======================================================

router.get('/points/me', authorize('customer'), async (req, res, next) => {
  try {
    // Ambil profil customer yang sedang login.
    const [customers] = await pool.execute(
      `SELECT c.id, c.points_balance, u.name AS customer_name
       FROM customers c
       INNER JOIN users u ON u.id = c.user_id
       WHERE c.user_id = ?
       LIMIT 1`,
      [req.user.id]
    );

    const customer = customers[0];

    if (!customer) {
      return res.status(404).json({
        error: 'Profil customer tidak ditemukan.',
      });
    }

    // Ambil riwayat poin.
    const [history] = await pool.execute(
      `SELECT id, entry_type, points, description, created_at
       FROM point_transactions
       WHERE customer_id = ?
       ORDER BY created_at DESC
       LIMIT 100`,
      [customer.id]
    );

    // Hitung transaksi customer yang benar-benar selesai.
    const [countRows] = await pool.execute(
      `SELECT COUNT(*) AS purchase_count
       FROM transactions
       WHERE customer_id = ?
         AND status = 'completed'`,
      [customer.id]
    );

    const purchaseCount = Number(countRows[0]?.purchase_count ?? 0);

    // Tentukan tier berdasarkan jumlah transaksi selesai.
    const loyaltyTier = classifyLoyalty(purchaseCount);

    const target = 10;

    // Jika tepat kelipatan 10, tampilkan 10/10 agar reward terlihat.
    const remainder = purchaseCount % target;

    const stamps =
      purchaseCount > 0 && remainder === 0 ? target : remainder;

    return res.json({
      balance: Number(customer.points_balance ?? 0),

      history,

      loyalty_card: {
        member_id: customer.id,
        customer_id: customer.id,
        customer_name: customer.customer_name,

        purchase_count: purchaseCount,

        // Tier member untuk ditampilkan pada kartu customer.
        loyalty_tier: loyaltyTier,

        purchases_in_cycle: stamps,
        target_purchases: target,
        reward_ready: stamps === target,
        purchases_remaining: Math.max(0, target - stamps),
      },
    });
  } catch (error) {
    return next(error);
  }
});

// ======================================================
// PENGATURAN LOYALTY
// ======================================================

router.get('/settings', authorize('admin'), async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      'SELECT setting_value FROM application_settings WHERE setting_key = ?',
      ['loyalty']
    );

    return res.json({
      rules: parseJsonValue(rows[0]?.setting_value, {
        points_per_10000: 1,
      }),
    });
  } catch (error) {
    return next(error);
  }
});

router.post(
  '/points/:customerId/adjustment',
  authorize('admin'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const customerId = z.coerce
        .number()
        .int()
        .positive()
        .parse(req.params.customerId);

      const input = z.object({
        points: z.number().int().refine(
          (value) => value !== 0,
          'Poin tidak boleh nol.'
        ),
        description: z.string().trim().min(3).max(255),
      }).parse(req.body);

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [customers] = await connection.execute(
        'SELECT id, points_balance FROM customers WHERE id = ? FOR UPDATE',
        [customerId]
      );

      const customer = customers[0];

      if (!customer) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(404).json({
          error: 'Customer tidak ditemukan.',
        });
      }

      if (Number(customer.points_balance) + input.points < 0) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(400).json({
          error: 'Saldo poin tidak dapat menjadi negatif.',
        });
      }

      await connection.execute(
        'UPDATE customers SET points_balance = points_balance + ? WHERE id = ?',
        [input.points, customerId]
      );

      await connection.execute(
        `INSERT INTO point_transactions
          (customer_id, entry_type, points, description)
         VALUES (?, 'adjustment', ?, ?)`,
        [customerId, input.points, input.description]
      );

      await connection.commit();
      transactionStarted = false;

      return res.status(201).json({
        message: 'Saldo poin berhasil disesuaikan.',
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) connection.release();
    }
  }
);

router.put('/settings', authorize('admin'), async (req, res, next) => {
  try {
    const rules = z.object({
      points_per_10000: z.number().int().min(0).max(10000),
    }).parse(req.body);

    await pool.execute(
      `INSERT INTO application_settings
        (setting_key, setting_value, updated_by)
       VALUES ('loyalty', ?, ?)
       ON DUPLICATE KEY UPDATE
        setting_value = VALUES(setting_value),
        updated_by = VALUES(updated_by)`,
      [JSON.stringify(rules), req.user.id]
    );

    return res.json({ rules });
  } catch (error) {
    return next(error);
  }
});

// ======================================================
// REWARDS
// ======================================================

router.get('/rewards', async (req, res, next) => {
  try {
    const admin = req.user.role === 'admin';

    const [rows] = await pool.execute(
      `SELECT id, name, description, points_cost, stock, is_active
       FROM rewards
       ${admin ? '' : 'WHERE is_active = TRUE AND (stock IS NULL OR stock > 0)'}
       ORDER BY points_cost`
    );

    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

router.post('/rewards', authorize('admin'), async (req, res, next) => {
  try {
    const input = z.object({
      name: z.string().trim().min(1).max(140),
      description: z.string().trim().max(500).optional().nullable(),
      points_cost: z.number().int().positive(),
      stock: z.number().int().nonnegative().optional().nullable(),
    }).parse(req.body);

    const [result] = await pool.execute(
      `INSERT INTO rewards
        (name, description, points_cost, stock)
       VALUES (?, ?, ?, ?)`,
      [
        input.name,
        input.description || null,
        input.points_cost,
        input.stock ?? null,
      ]
    );

    return res.status(201).json({
      id: result.insertId,
      message: 'Reward berhasil dibuat.',
    });
  } catch (error) {
    return next(error);
  }
});

router.patch('/rewards/:id', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);

    const input = z.object({
      name: z.string().trim().min(1).max(140).optional(),
      description: z.string().trim().max(500).nullable().optional(),
      points_cost: z.number().int().positive().optional(),
      stock: z.number().int().nonnegative().nullable().optional(),
      is_active: z.boolean().optional(),
    }).refine(
      (data) => Object.keys(data).length > 0,
      'Kirim minimal satu nilai untuk diperbarui.'
    ).parse(req.body);

    const fields = Object.keys(input);

    const [result] = await pool.execute(
      `UPDATE rewards
       SET ${fields.map((field) => `${field} = ?`).join(', ')}
       WHERE id = ?`,
      [...fields.map((field) => input[field]), id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({
        error: 'Reward tidak ditemukan.',
      });
    }

    return res.json({
      message: 'Reward berhasil diperbarui.',
    });
  } catch (error) {
    return next(error);
  }
});

// ======================================================
// RIWAYAT PENUKARAN REWARD CUSTOMER
// ======================================================

router.get('/redemptions/me', authorize('customer'), async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT
         rr.id,
         rr.redemption_code,
         rr.points_spent,
         rr.status,
         rr.redeemed_at,
         rr.claimed_at,
         r.name AS reward_name
       FROM reward_redemptions rr
       JOIN rewards r ON r.id = rr.reward_id
       JOIN customers c ON c.id = rr.customer_id
       WHERE c.user_id = ?
       ORDER BY rr.redeemed_at DESC`,
      [req.user.id]
    );

    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

// ======================================================
// RIWAYAT PENUKARAN REWARD ADMIN
// ======================================================

router.get('/redemptions', authorize('admin'), async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT
         rr.id,
         rr.redemption_code,
         rr.points_spent,
         rr.status,
         rr.redeemed_at,
         rr.claimed_at,
         r.name AS reward_name,
         u.name AS customer_name,
         u.phone AS customer_phone
       FROM reward_redemptions rr
       JOIN rewards r ON r.id = rr.reward_id
       JOIN customers c ON c.id = rr.customer_id
       JOIN users u ON u.id = c.user_id
       ORDER BY rr.redeemed_at DESC`
    );

    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

// ======================================================
// ADMIN MENANDAI REWARD SUDAH DISERAHKAN
// ======================================================

router.patch(
  '/redemptions/:id/claim',
  authorize('admin'),
  async (req, res, next) => {
    try {
      const id = z.coerce.number().int().positive().parse(req.params.id);

      const [result] = await pool.execute(
        `UPDATE reward_redemptions
         SET
           status = 'claimed',
           claimed_at = CURRENT_TIMESTAMP,
           claimed_by = ?
         WHERE id = ?
           AND status = 'pending'`,
        [req.user.id, id]
      );

      if (!result.affectedRows) {
        return res.status(409).json({
          error: 'Penukaran tidak ditemukan atau reward sudah diserahkan.',
        });
      }

      return res.json({
        message: 'Reward ditandai sudah diserahkan.',
      });
    } catch (error) {
      return next(error);
    }
  }
);

// ======================================================
// CUSTOMER MENUKAR REWARD
// ======================================================

router.post(
  '/rewards/:id/redeem',
  authorize('customer'),
  async (req, res, next) => {
    let connection;
    let transactionStarted = false;

    try {
      const rewardId = z.coerce
        .number()
        .int()
        .positive()
        .parse(req.params.id);

      connection = await pool.getConnection();

      await connection.beginTransaction();
      transactionStarted = true;

      const [customers] = await connection.execute(
        'SELECT id, points_balance FROM customers WHERE user_id = ? FOR UPDATE',
        [req.user.id]
      );

      const customer = customers[0];

      const [rewards] = await connection.execute(
        `SELECT id, name, points_cost, stock
         FROM rewards
         WHERE id = ?
           AND is_active = TRUE
         FOR UPDATE`,
        [rewardId]
      );

      const reward = rewards[0];

      if (
        !customer ||
        !reward ||
        (reward.stock !== null && reward.stock < 1)
      ) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(404).json({
          error: 'Reward tidak ditemukan atau stok habis.',
        });
      }

      if (customer.points_balance < reward.points_cost) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(400).json({
          error: 'Saldo poin tidak mencukupi.',
        });
      }

      await connection.execute(
        'UPDATE customers SET points_balance = points_balance - ? WHERE id = ?',
        [reward.points_cost, customer.id]
      );

      if (reward.stock !== null) {
        await connection.execute(
          'UPDATE rewards SET stock = stock - 1 WHERE id = ?',
          [reward.id]
        );
      }

      const redemptionCode =
        `RW-${randomBytes(6).toString('hex').toUpperCase()}`;

      await connection.execute(
        `INSERT INTO reward_redemptions
          (customer_id, reward_id, points_spent, redemption_code)
         VALUES (?, ?, ?, ?)`,
        [
          customer.id,
          reward.id,
          reward.points_cost,
          redemptionCode,
        ]
      );

      await connection.execute(
        `INSERT INTO point_transactions
          (customer_id, entry_type, points, description)
         VALUES (?, 'redeemed', ?, ?)`,
        [
          customer.id,
          -reward.points_cost,
          `Penukaran reward: ${reward.name}`,
        ]
      );

      await connection.commit();
      transactionStarted = false;

      return res.status(201).json({
        message: 'Reward berhasil ditukar. Tunjukkan kode klaim kepada admin.',
        redemption: {
          code: redemptionCode,
          reward_name: reward.name,
          status: 'pending',
        },
      });
    } catch (error) {
      if (connection && transactionStarted) {
        await connection.rollback();
      }

      return next(error);
    } finally {
      if (connection) connection.release();
    }
  }
);

// ======================================================
// VOUCHER CUSTOMER
// ======================================================

router.get('/vouchers/me', authorize('customer'), async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT
         v.id,
         v.code,
         v.starts_at,
         v.expires_at,
         v.redeemed_at,
         c.name AS campaign_name,
         CASE
           WHEN v.redeemed_at IS NOT NULL THEN 'used'
           WHEN v.starts_at > NOW() THEN 'upcoming'
           WHEN v.expires_at < NOW() THEN 'expired'
           ELSE 'available'
         END AS status
       FROM vouchers v
       LEFT JOIN campaigns c ON c.id = v.campaign_id
       JOIN customers cu ON cu.id = v.customer_id
       WHERE cu.user_id = ?
       ORDER BY v.expires_at DESC`,
      [req.user.id]
    );

    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;