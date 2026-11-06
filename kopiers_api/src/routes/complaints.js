const express = require('express');
const { randomUUID } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
const statuses = ['waiting', 'in_progress', 'resolved'];
const complaintImageDirectory = path.resolve(__dirname, '../../uploads/complaints');
router.use(authenticate);

router.post(
  '/images',
  authorize('customer'),
  express.raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: '5mb' }),
  async (req, res, next) => {
    try {
      if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
        return res.status(400).json({ error: 'Pilih gambar JPG, PNG, atau WebP.' });
      }

      const mimeType = req.get('content-type');
      const signatures = {
        'image/jpeg': req.body[0] === 0xff && req.body[1] === 0xd8 && req.body[2] === 0xff,
        'image/png': req.body.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
        'image/webp': req.body.toString('ascii', 0, 4) === 'RIFF'
          && req.body.toString('ascii', 8, 12) === 'WEBP'
      };
      if (!signatures[mimeType]) {
        return res.status(400).json({ error: 'Format gambar tidak sesuai atau file rusak.' });
      }

      const extension = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' }[mimeType];
      const filename = `${randomUUID()}.${extension}`;
      await fs.mkdir(complaintImageDirectory, { recursive: true });
      await fs.writeFile(path.join(complaintImageDirectory, filename), req.body, { flag: 'wx' });
      return res.status(201).json({ image_url: `/complaints/images/${filename}` });
    } catch (error) {
      return next(error);
    }
  }
);

router.post('/', authorize('customer'), async (req, res, next) => {
  let connection;
  let transactionStarted = false;
  try {
    const input = z.object({
      category: z.string().trim().min(2).max(80),
      description: z.string().trim().min(10).max(5000),
      image_url: z.string().max(500).refine(
        (value) => value.startsWith('/complaints/images/')
          || z.string().url().safeParse(value).success,
        'Lampiran gambar tidak valid.'
      ).optional().nullable()
    }).parse(req.body);
    connection = await pool.getConnection();
    const [customers] = await connection.execute('SELECT id FROM customers WHERE user_id = ?', [req.user.id]);
    if (!customers[0]) return res.status(404).json({ error: 'Profil customer tidak ditemukan.' });
    await connection.beginTransaction();
    transactionStarted = true;
    const [result] = await connection.execute(
      'INSERT INTO complaints (customer_id, category, description, image_url) VALUES (?, ?, ?, ?)',
      [customers[0].id, input.category, input.description, input.image_url || null]
    );
    await connection.execute(
      `INSERT INTO complaint_histories (complaint_id, changed_by, status, response)
       VALUES (?, ?, 'waiting', ?)`,
      [result.insertId, req.user.id, 'Keluhan diterima.']
    );
    await connection.commit();
    transactionStarted = false;
    return res.status(201).json({ id: result.insertId, message: 'Keluhan berhasil dikirim.' });
  } catch (error) {
    if (connection && transactionStarted) await connection.rollback();
    return next(error);
  } finally {
    if (connection) connection.release();
  }
});

router.get('/images/:filename', async (req, res, next) => {
  try {
    const filename = z.string().regex(/^[0-9a-f-]{36}\.(jpg|png|webp)$/i).parse(req.params.filename);
    const imageUrl = `/complaints/images/${filename}`;
    const values = [imageUrl];
    const customerClause = req.user.role === 'customer' ? 'AND c.user_id = ?' : '';
    if (req.user.role === 'customer') values.push(req.user.id);
    const [rows] = await pool.execute(
      `SELECT co.image_url FROM complaints co
       JOIN customers c ON c.id = co.customer_id
       WHERE co.image_url = ? ${customerClause}`,
      values
    );
    if (!rows[0]) return res.status(404).json({ error: 'Lampiran tidak ditemukan.' });

    const filePath = path.join(complaintImageDirectory, filename);
    await fs.access(filePath);
    res.set('Cache-Control', 'private, no-store');
    return res.sendFile(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') return res.status(404).json({ error: 'Lampiran tidak ditemukan.' });
    return next(error);
  }
});

router.get('/', async (req, res, next) => {
  try {
    const filters = [];
    const values = [];
    if (req.user.role === 'customer') {
      filters.push('c.user_id = ?');
      values.push(req.user.id);
    } else {
      if (req.query.status) {
        filters.push('co.status = ?');
        values.push(z.enum(statuses).parse(req.query.status));
      }
      if (req.query.from) {
        filters.push('co.created_at >= ?');
        values.push(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).parse(req.query.from));
      }
      if (req.query.to) {
        filters.push('co.created_at < DATE_ADD(?, INTERVAL 1 DAY)');
        values.push(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).parse(req.query.to));
      }
    }
    const [rows] = await pool.execute(
      `SELECT co.id, co.category, co.description, co.image_url, co.status, co.created_at, co.updated_at,
              u.name AS customer_name
       FROM complaints co JOIN customers c ON c.id = co.customer_id
       JOIN users u ON u.id = c.user_id
       ${filters.length ? `WHERE ${filters.join(' AND ')}` : ''}
       ORDER BY co.created_at DESC`,
      values
    );
    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

router.get('/:id', async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const values = [id];
    const customerClause = req.user.role === 'customer' ? 'AND c.user_id = ?' : '';
    if (req.user.role === 'customer') values.push(req.user.id);
    const [rows] = await pool.execute(
      `SELECT co.id, co.category, co.description, co.image_url, co.status, co.created_at, co.updated_at,
              u.name AS customer_name
       FROM complaints co JOIN customers c ON c.id = co.customer_id
       JOIN users u ON u.id = c.user_id WHERE co.id = ? ${customerClause}`,
      values
    );
    if (!rows[0]) return res.status(404).json({ error: 'Keluhan tidak ditemukan.' });
    const [history] = await pool.execute(
      `SELECT h.status, h.response, h.created_at, u.name AS changed_by
       FROM complaint_histories h JOIN users u ON u.id = h.changed_by
       WHERE h.complaint_id = ? ORDER BY h.created_at`,
      [id]
    );
    return res.json({ complaint: rows[0], history });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:id/status', authorize('admin'), async (req, res, next) => {
  let connection;
  let transactionStarted = false;
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const input = z.object({
      status: z.enum(statuses),
      response: z.string().trim().min(1).max(5000)
    }).parse(req.body);
    connection = await pool.getConnection();
    await connection.beginTransaction();
    transactionStarted = true;
    const [result] = await connection.execute(
      'UPDATE complaints SET status = ? WHERE id = ?',
      [input.status, id]
    );
    if (!result.affectedRows) {
      await connection.rollback();
      return res.status(404).json({ error: 'Keluhan tidak ditemukan.' });
    }
    await connection.execute(
      `INSERT INTO complaint_histories (complaint_id, changed_by, status, response)
       VALUES (?, ?, ?, ?)`,
      [id, req.user.id, input.status, input.response]
    );
    await connection.commit();
    transactionStarted = false;
    return res.json({ message: 'Status keluhan berhasil diperbarui.' });
  } catch (error) {
    if (connection && transactionStarted) await connection.rollback();
    return next(error);
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;
