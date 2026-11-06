
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

const registerSchema = z.object({
  name: z.string().trim().min(2).max(120),
  phone: z.string().trim().min(8).max(32),
  email: z.string().trim().email().max(190).optional().or(z.literal('')),
  password: z.string().min(8).max(72),
});

const loginSchema = z.object({
  identifier: z.string().trim().min(1),
  password: z.string().min(1).max(72),
});

const changePasswordSchema = z.object({
  current_password: z.string().min(1, 'Password lama wajib diisi.'),
  new_password: z
    .string()
    .min(8, 'Password baru minimal 8 karakter.')
    .max(72, 'Password baru maksimal 72 karakter.'),
});

function issueToken(user) {
  return jwt.sign(
    {
      sub: String(user.id),
      role: user.role,
      ver: user.token_version,
    },
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '12h',
      issuer: 'kopiers-api',
      audience: 'kopiers-apps',
    },
  );
}

// REGISTER
router.post('/register', async (req, res, next) => {
  let connection;
  let transactionStarted = false;

  try {
    const input = registerSchema.parse(req.body);

    connection = await pool.getConnection();

    const passwordHash = await bcrypt.hash(
      input.password,
      Number(process.env.BCRYPT_ROUNDS || 12),
    );

    await connection.beginTransaction();
    transactionStarted = true;

    const [result] = await connection.execute(
      `INSERT INTO users
        (name, email, phone, password_hash, role)
       VALUES (?, ?, ?, ?, ?)`,
      [
        input.name,
        input.email || null,
        input.phone,
        passwordHash,
        'customer',
      ],
    );

    await connection.execute(
      'INSERT INTO customers (user_id) VALUES (?)',
      [result.insertId],
    );

    await connection.commit();
    transactionStarted = false;

    return res.status(201).json({
      message: 'Akun customer berhasil dibuat.',
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

// LOGIN
router.post('/login', async (req, res, next) => {
  try {
    const input = loginSchema.parse(req.body);

    const [rows] = await pool.execute(
      `SELECT
         id, name, email, phone, password_hash,
         role, is_active, token_version
       FROM users
       WHERE phone = ? OR email = ?
       LIMIT 1`,
      [input.identifier, input.identifier],
    );

    const user = rows[0];

    if (
      !user ||
      !user.is_active ||
      !(await bcrypt.compare(input.password, user.password_hash))
    ) {
      return res.status(401).json({
        error: 'Nomor telepon/email atau kata sandi salah.',
      });
    }

    return res.json({
      token: issueToken(user),
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (error) {
    return next(error);
  }
});

// LOGOUT
router.post('/logout', authenticate, async (req, res, next) => {
  try {
    await pool.execute(
      `UPDATE users
       SET token_version = token_version + 1
       WHERE id = ?`,
      [req.user.id],
    );

    return res.json({
      message: 'Logout berhasil.',
    });
  } catch (error) {
    return next(error);
  }
});

// GET PROFIL LOGIN
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, email, phone, role, created_at
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id],
    );

    if (!rows[0]) {
      return res.status(404).json({
        error: 'Akun tidak ditemukan.',
      });
    }

    return res.json({ user: rows[0] });
  } catch (error) {
    return next(error);
  }
});

// UPDATE PROFIL
router.patch('/me', authenticate, async (req, res, next) => {
  try {
    const input = z.object({
      name: z.string().trim().min(2).max(120).optional(),
      email: z
        .string()
        .trim()
        .email()
        .max(190)
        .optional()
        .or(z.literal('')),
      phone: z.string().trim().min(8).max(32).optional(),
    })
      .refine(
        (data) => Object.keys(data).length > 0,
        'Isi minimal satu data yang ingin diperbarui.',
      )
      .parse(req.body);

    const fields = Object.keys(input);

    const assignments = fields
      .map((field) => `${field} = ?`)
      .join(', ');

    const values = fields.map((field) =>
      input[field] === '' ? null : input[field],
    );

    await pool.execute(
      `UPDATE users SET ${assignments} WHERE id = ?`,
      [...values, req.user.id],
    );

    const [rows] = await pool.execute(
      `SELECT id, name, email, phone, role, created_at
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id],
    );

    if (!rows[0]) {
      return res.status(404).json({
        error: 'Akun tidak ditemukan.',
      });
    }

    return res.json({
      user: rows[0],
      message: 'Profil berhasil diperbarui.',
    });
  } catch (error) {
    return next(error);
  }
});

// GANTI PASSWORD
router.post('/change-password', authenticate, async (req, res, next) => {
  try {
    const input = changePasswordSchema.parse(req.body);

    if (input.current_password === input.new_password) {
      return res.status(400).json({
        error: 'Password baru harus berbeda dari password lama.',
      });
    }

    const [rows] = await pool.execute(
      `SELECT id, password_hash
       FROM users
       WHERE id = ?
       LIMIT 1`,
      [req.user.id],
    );

    const user = rows[0];

    if (!user) {
      return res.status(404).json({
        error: 'Akun tidak ditemukan.',
      });
    }

    const isPasswordValid = await bcrypt.compare(
      input.current_password,
      user.password_hash,
    );

    if (!isPasswordValid) {
      return res.status(400).json({
        error: 'Password lama tidak benar.',
      });
    }

    const passwordHash = await bcrypt.hash(
      input.new_password,
      Number(process.env.BCRYPT_ROUNDS || 12),
    );

    const [result] = await pool.execute(
      `UPDATE users
       SET password_hash = ?,
           token_version = token_version + 1
       WHERE id = ?`,
      [passwordHash, user.id],
    );

    if (result.affectedRows !== 1) {
      return res.status(500).json({
        error: 'Password gagal diperbarui.',
      });
    }

    return res.json({
      message: 'Password berhasil diubah. Silakan login kembali.',
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: error.issues[0]?.message || 'Data password tidak valid.',
      });
    }

    return next(error);
  }
});

module.exports = router;
