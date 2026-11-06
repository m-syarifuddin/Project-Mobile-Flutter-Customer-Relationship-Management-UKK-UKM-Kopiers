const express = require('express');
const bcrypt = require('bcryptjs');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');
const { listTransactionsForUser } = require('../services/customer-transactions');
const { parseJsonValue } = require('../utils/json');
const { classifyLoyalty } = require('../utils/loyalty');

const router = express.Router();
router.use(authenticate);

router.get('/me', authorize('customer'), async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT u.id AS user_id, u.name, u.email, u.phone, c.id AS customer_id,
              c.joined_at, c.points_balance,
              (SELECT COUNT(*)
               FROM transactions t
               WHERE t.customer_id = c.id
                 AND t.status = 'completed') AS transaction_count
       FROM users u JOIN customers c ON c.user_id = u.id WHERE u.id = ?`,
      [req.user.id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Profil customer tidak ditemukan.' });
    const transactionCount = Number(rows[0].transaction_count || 0);
    return res.json({
      customer: {
        ...rows[0],
        transaction_count: transactionCount,
        loyalty_tier: classifyLoyalty(transactionCount),
      },
    });
  } catch (error) {
    return next(error);
  }
});

router.patch('/me', authorize('customer'), async (req, res, next) => {
  try {
    const input = z.object({
      name: z.string().trim().min(2).max(120).optional(),
      email: z.string().trim().email().max(190).optional().or(z.literal('')),
      phone: z.string().trim().min(8).max(32).optional()
    }).refine((data) => Object.keys(data).length > 0, 'Isi minimal satu data yang ingin diperbarui.')
      .parse(req.body);
    const fields = Object.keys(input);
    await pool.execute(
      `UPDATE users SET ${fields.map((field) => `${field} = ?`).join(', ')} WHERE id = ?`,
      [...fields.map((field) => input[field] === '' ? null : input[field]), req.user.id]
    );
    return res.json({ message: 'Profil berhasil diperbarui.' });
  } catch (error) {
    return next(error);
  }
});

router.get('/', authorize('admin'), async (req, res, next) => {
  try {
    const page = z.coerce.number().int().min(1).default(1).parse(req.query.page);
    const limit = z.coerce.number().int().min(1).max(100).default(20).parse(req.query.limit);
    const search = String(req.query.search || '').trim();
    const status = z.enum(['active', 'inactive', 'all']).default('active').parse(req.query.status || 'active');
    const segment = z.enum(['new', 'active', 'loyal', 'inactive', 'high_value']).optional().parse(req.query.segment);
    const [settings] = await pool.execute(
      'SELECT setting_value FROM application_settings WHERE setting_key = ?',
      ['segmentation']
    );
    const rules = parseJsonValue(settings[0]?.setting_value, {
      active_days: 30, new_customer_days: 30, loyal_min_transactions: 10, high_value_amount: 500000
    });
    const where = [];
    const values = [
      rules.new_customer_days,
      rules.high_value_amount,
      rules.loyal_min_transactions,
      rules.active_days
    ];
    if (search) {
      where.push('(u.name LIKE ? OR u.phone LIKE ? OR u.email LIKE ?)');
      values.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    if (status !== 'all') {
      where.push('u.is_active = ?');
      values.push(status === 'active');
    }
    const clause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    const having = segment ? 'HAVING segment = ?' : '';
    if (segment) values.push(segment);
    const [rows] = await pool.execute(
      `SELECT c.id, u.name, u.phone, u.email, u.is_active, c.joined_at, c.points_balance,
              COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) AS transaction_count,
              COALESCE(SUM(CASE WHEN t.status = 'completed' THEN t.total_amount ELSE 0 END), 0) AS lifetime_value,
              CASE
                WHEN c.joined_at >= DATE_SUB(NOW(), INTERVAL ? DAY) THEN 'new'
                WHEN COALESCE(SUM(CASE WHEN t.status = 'completed' THEN t.total_amount ELSE 0 END), 0) >= ? THEN 'high_value'
                WHEN COUNT(CASE WHEN t.status = 'completed' THEN t.id END) >= ? THEN 'loyal'
                WHEN MAX(CASE WHEN t.status = 'completed' THEN t.created_at END) >= DATE_SUB(NOW(), INTERVAL ? DAY) THEN 'active'
                ELSE 'inactive'
              END AS segment
       FROM customers c JOIN users u ON u.id = c.user_id
       LEFT JOIN transactions t ON t.customer_id = c.id
       ${clause}
       GROUP BY c.id, u.id
       ${having}
       ORDER BY c.joined_at DESC LIMIT ? OFFSET ?`,
      [...values, limit, (page - 1) * limit]
    );
    return res.json({ data: rows, page, limit });
  } catch (error) {
    return next(error);
  }
});

router.post('/', authorize('admin'), async (req, res, next) => {
  let connection;
  let transactionStarted = false;
  try {
    const input = z.object({
      name: z.string().trim().min(2).max(120),
      phone: z.string().trim().min(8).max(32),
      email: z.string().trim().email().max(190).optional().or(z.literal('')),
      password: z.string().min(8).max(72)
    }).parse(req.body);
    const passwordHash = await bcrypt.hash(input.password, Number(process.env.BCRYPT_ROUNDS || 12));
    connection = await pool.getConnection();
    await connection.beginTransaction();
    transactionStarted = true;
    const [user] = await connection.execute(
      'INSERT INTO users (name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [input.name, input.email || null, input.phone, passwordHash, 'customer']
    );
    const [customer] = await connection.execute(
      'INSERT INTO customers (user_id) VALUES (?)',
      [user.insertId]
    );
    await connection.commit();
    transactionStarted = false;
    return res.status(201).json({ id: customer.insertId, message: 'Customer berhasil ditambahkan.' });
  } catch (error) {
    if (connection && transactionStarted) await connection.rollback();
    return next(error);
  } finally {
    if (connection) connection.release();
  }
});

router.get('/:id', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const [rows] = await pool.execute(
      `SELECT c.id, u.name, u.phone, u.email, u.is_active, c.joined_at, c.points_balance,
              COUNT(DISTINCT CASE WHEN t.status = 'completed' THEN t.id END) AS transaction_count,
              COALESCE(SUM(CASE WHEN t.status = 'completed' THEN t.total_amount ELSE 0 END), 0) AS lifetime_value
       FROM customers c JOIN users u ON u.id = c.user_id
       LEFT JOIN transactions t ON t.customer_id = c.id
       WHERE c.id = ? GROUP BY c.id, u.id`,
      [id]
    );
    if (!rows[0]) return res.status(404).json({ error: 'Customer tidak ditemukan.' });
    rows[0].loyalty_tier = classifyLoyalty(Number(rows[0].transaction_count));
    const [transactions] = await pool.execute(
      `SELECT id, total_amount, status, created_at FROM transactions
       WHERE customer_id = ? ORDER BY created_at DESC LIMIT 100`,
      [id]
    );
    return res.json({ customer: rows[0], transactions });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:id', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const input = z.object({
      name: z.string().trim().min(2).max(120).optional(),
      email: z.string().trim().email().max(190).optional().or(z.literal('')),
      phone: z.string().trim().min(8).max(32).optional()
    }).refine((data) => Object.keys(data).length > 0, 'Kirim minimal satu nilai untuk diperbarui.')
      .parse(req.body);
    const fields = Object.keys(input);
    const [result] = await pool.execute(
      `UPDATE users u JOIN customers c ON c.user_id = u.id
       SET ${fields.map((field) => `u.${field} = ?`).join(', ')}
       WHERE c.id = ?`,
      [...fields.map((field) => input[field] === '' ? null : input[field]), id]
    );
    if (!result.affectedRows) return res.status(404).json({ error: 'Customer tidak ditemukan.' });
    return res.json({ message: 'Data customer berhasil diperbarui.' });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:id/status', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const { is_active: isActive } = z.object({ is_active: z.boolean() }).parse(req.body);
    const [result] = await pool.execute(
      `UPDATE users u JOIN customers c ON c.user_id = u.id
       SET u.is_active = ?, u.token_version = u.token_version + IF(? = 0, 1, 0)
       WHERE c.id = ?`,
      [isActive, Number(isActive), id]
    );
    if (!result.affectedRows) return res.status(404).json({ error: 'Customer tidak ditemukan.' });
    return res.json({ message: isActive ? 'Customer diaktifkan.' : 'Customer dinonaktifkan.' });
  } catch (error) {
    return next(error);
  }
});

router.get('/me/transactions', authorize('customer'), async (req, res, next) => {
  try {
    return res.json({ data: await listTransactionsForUser(req.user.id) });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
