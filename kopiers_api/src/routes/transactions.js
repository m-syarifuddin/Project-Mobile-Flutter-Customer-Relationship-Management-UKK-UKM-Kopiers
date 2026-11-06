
const express = require('express');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { parseJsonValue } = require('../utils/json');
const { listTransactionsForUser } = require('../services/customer-transactions');

const router = express.Router();

const createSchema = z.object({
  customer_id: z.number().int().positive(),
  voucher_code: z.string().trim().min(1).max(40).optional(),
  items: z.array(
    z.object({
      product_id: z.number().int().positive(),
      quantity: z.number().int().min(1).max(100),
    })
  ).min(1),
});

router.use(authenticate);

// POST /api/transactions
// Membuat transaksi baru oleh admin.
router.post('/', authorize('admin'), async (req, res, next) => {
  let connection;
  let transactionStarted = false;

  try {
    const input = createSchema.parse(req.body);

    connection = await pool.getConnection();
    await connection.beginTransaction();
    transactionStarted = true;

    const [customerRows] = await connection.execute(
      `SELECT id
       FROM customers
       WHERE id = ?
       FOR UPDATE`,
      [input.customer_id]
    );

    if (!customerRows.length) {
      await connection.rollback();
      transactionStarted = false;

      return res.status(404).json({
        error: 'Customer tidak ditemukan.',
      });
    }

    const productIds = [
      ...new Set(input.items.map((item) => item.product_id)),
    ];

    const placeholders = productIds.map(() => '?').join(',');

    const [products] = await connection.execute(
      `SELECT id, name, price
       FROM products
       WHERE is_active = TRUE
         AND id IN (${placeholders})`,
      productIds
    );

    const productMap = new Map(
      products.map((product) => [Number(product.id), product])
    );

    if (productMap.size !== productIds.length) {
      await connection.rollback();
      transactionStarted = false;

      return res.status(400).json({
        error: 'Satu atau lebih produk tidak tersedia.',
      });
    }

    let voucher = null;

    if (input.voucher_code) {
      const [vouchers] = await connection.execute(
        `SELECT v.id, v.campaign_id, ca.discount_percent
         FROM vouchers v
         JOIN campaigns ca ON ca.id = v.campaign_id
         WHERE v.code = ?
           AND v.customer_id = ?
           AND v.redeemed_at IS NULL
           AND v.starts_at <= NOW()
           AND v.expires_at >= NOW()
           AND ca.is_active = TRUE
           AND ca.starts_at <= NOW()
           AND ca.ends_at >= NOW()
         FOR UPDATE`,
        [input.voucher_code, input.customer_id]
      );

      voucher = vouchers[0] || null;

      if (!voucher) {
        await connection.rollback();
        transactionStarted = false;

        return res.status(400).json({
          error: 'Voucher tidak valid, bukan milik customer, atau sudah tidak berlaku.',
        });
      }
    }

    const items = input.items.map((item) => {
      const product = productMap.get(item.product_id);
      const unitPriceCents = Math.round(Number(product.price) * 100);
      const lineCents = unitPriceCents * item.quantity;

      return {
        ...item,
        product,
        lineTotal: lineCents / 100,
        lineCents,
      };
    });

    const subtotalCents = items.reduce(
      (sum, item) => sum + item.lineCents,
      0
    );

    const discountPercent = Number(voucher?.discount_percent || 0);

    const discountCents = Math.round(
      subtotalCents * discountPercent / 100
    );

    const totalCents = subtotalCents - discountCents;
    const total = totalCents / 100;

    // Transaksi yang dicatat admin adalah transaksi selesai.
    const [result] = await connection.execute(
      `INSERT INTO transactions
         (customer_id, created_by, campaign_id, total_amount, status)
       VALUES (?, ?, ?, ?, 'completed')`,
      [
        input.customer_id,
        req.user.id,
        voucher?.campaign_id || null,
        total,
      ]
    );

    for (const item of items) {
      await connection.execute(
        `INSERT INTO transaction_items
           (transaction_id, product_id, product_name,
            unit_price, quantity, line_total)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          result.insertId,
          item.product.id,
          item.product.name,
          item.product.price,
          item.quantity,
          item.lineTotal,
        ]
      );
    }

    if (voucher) {
      await connection.execute(
        `UPDATE vouchers
         SET redeemed_at = NOW(), transaction_id = ?
         WHERE id = ?`,
        [result.insertId, voucher.id]
      );
    }

    // Hitung poin berdasarkan pengaturan loyalitas.
    const [settingsRows] = await connection.execute(
      `SELECT setting_value
       FROM application_settings
       WHERE setting_key = ?`,
      ['loyalty']
    );

    const loyalty = parseJsonValue(
      settingsRows[0]?.setting_value,
      { points_per_10000: 1 }
    );

    const pointsPer10000 = Number(
      loyalty.points_per_10000 ?? 1
    );

    const points = Math.floor(totalCents / 1000000)
      * pointsPer10000;

    if (points > 0) {
      await connection.execute(
        `UPDATE customers
         SET points_balance = points_balance + ?
         WHERE id = ?`,
        [points, input.customer_id]
      );

      await connection.execute(
        `INSERT INTO point_transactions
           (customer_id, transaction_id, entry_type,
            points, description)
         VALUES (?, ?, 'earned', ?, ?)`,
        [
          input.customer_id,
          result.insertId,
          points,
          `Poin dari transaksi #${result.insertId}`,
        ]
      );
    }

    await connection.commit();
    transactionStarted = false;

    return res.status(201).json({
      id: result.insertId,
      customer_id: input.customer_id,
      subtotal_amount: subtotalCents / 100,
      discount_amount: discountCents / 100,
      total_amount: total,
      points_earned: points,
      status: 'completed',
      message: 'Transaksi berhasil dicatat.',
    });
  } catch (error) {
    if (connection && transactionStarted) {
      await connection.rollback();
    }

    return next(error);
  } finally {
    if (connection) connection.release();
  }
});

// GET /api/transactions
// Daftar transaksi untuk admin.
router.get('/', authorize('admin'), async (req, res, next) => {
  try {
    const page = z.coerce.number()
      .int().min(1).default(1)
      .parse(req.query.page);

    const limit = z.coerce.number()
      .int().min(1).max(100).default(20)
      .parse(req.query.limit);

    const [rows] = await pool.execute(
      `SELECT
         t.id,
         t.customer_id,
         u.name AS customer_name,
         t.total_amount,
         t.status,
         t.created_at
       FROM transactions t
       JOIN customers c ON c.id = t.customer_id
       JOIN users u ON u.id = c.user_id
       ORDER BY t.created_at DESC
       LIMIT ? OFFSET ?`,
      [limit, (page - 1) * limit]
    );

    return res.json({
      data: rows,
      page,
      limit,
    });
  } catch (error) {
    return next(error);
  }
});

// GET /api/transactions/me
// Riwayat transaksi customer yang sedang login.
router.get('/me', authorize('customer'), async (req, res, next) => {
  try {
    const data = await listTransactionsForUser(req.user.id);

    return res.json({ data });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
