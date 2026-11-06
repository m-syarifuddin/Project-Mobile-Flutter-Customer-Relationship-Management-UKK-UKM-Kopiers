
const express = require('express');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Semua endpoint voucher wajib login sebagai admin.
router.use(authenticate, authorize('admin'));

// Memeriksa status voucher tanpa menukarkannya.
router.post('/validate', async (req, res, next) => {
  try {
    const code =
      typeof req.body.code === 'string'
        ? req.body.code.trim()
        : '';

    if (!code || code.length > 40) {
      return res.status(400).json({
        valid: false,
        error: 'Kode voucher tidak valid.',
      });
    }

    const [rows] = await pool.execute(
      `SELECT
          id,
          customer_id,
          campaign_id,
          code,
          starts_at,
          expires_at,
          redeemed_at,
          transaction_id,
          CASE
            WHEN redeemed_at IS NOT NULL THEN 'used'
            WHEN UTC_TIMESTAMP() < starts_at THEN 'not_started'
            WHEN UTC_TIMESTAMP() > expires_at THEN 'expired'
            ELSE 'valid'
          END AS voucher_status
       FROM vouchers
       WHERE code = ?
       LIMIT 1`,
      [code]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        valid: false,
        status: 'not_found',
        error: 'Voucher tidak ditemukan.',
      });
    }

    const voucher = rows[0];
    const valid = voucher.voucher_status === 'valid';

    return res.status(200).json({
      valid,
      status: voucher.voucher_status,
      message: {
        valid: 'Voucher valid dan siap ditukarkan.',
        used: 'Voucher sudah pernah digunakan.',
        expired: 'Voucher sudah kedaluwarsa.',
        not_started: 'Voucher belum memasuki masa berlaku.',
      }[voucher.voucher_status],
      voucher: {
        id: voucher.id,
        customer_id: voucher.customer_id,
        campaign_id: voucher.campaign_id,
        code: voucher.code,
        starts_at: voucher.starts_at,
        expires_at: voucher.expires_at,
        redeemed_at: voucher.redeemed_at,
        transaction_id: voucher.transaction_id,
      },
    });
  } catch (error) {
    next(error);
  }
});

// Menukarkan voucher satu kali menggunakan transaksi database.
router.post('/redeem', async (req, res, next) => {
  let connection;

  try {
    const code =
      typeof req.body.code === 'string'
        ? req.body.code.trim()
        : '';

    if (!code || code.length > 40) {
      return res.status(400).json({
        success: false,
        error: 'Kode voucher tidak valid.',
      });
    }

    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Mengunci baris agar dua permintaan bersamaan tidak
    // bisa menukarkan voucher yang sama.
    const [rows] = await connection.execute(
      `SELECT
          id,
          customer_id,
          campaign_id,
          code,
          starts_at,
          expires_at,
          redeemed_at,
          transaction_id
       FROM vouchers
       WHERE code = ?
       LIMIT 1
       FOR UPDATE`,
      [code]
    );

    if (rows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        success: false,
        error: 'Voucher tidak ditemukan.',
      });
    }

    const voucher = rows[0];

    if (voucher.redeemed_at !== null) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        status: 'used',
        error: 'Voucher sudah pernah digunakan.',
      });
    }

    // Periksa waktu berdasarkan jam database.
    const [timeRows] = await connection.query(
      'SELECT UTC_TIMESTAMP() AS now_utc'
    );

    const now = new Date(timeRows[0].now_utc);
    const startsAt = new Date(voucher.starts_at);
    const expiresAt = new Date(voucher.expires_at);

    if (now < startsAt) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        status: 'not_started',
        error: 'Voucher belum memasuki masa berlaku.',
      });
    }

    if (now > expiresAt) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        status: 'expired',
        error: 'Voucher sudah kedaluwarsa.',
      });
    }

    // Kondisi redeemed_at IS NULL menjadi perlindungan tambahan.
    const [updateResult] = await connection.execute(
      `UPDATE vouchers
       SET redeemed_at = UTC_TIMESTAMP()
       WHERE id = ?
         AND redeemed_at IS NULL`,
      [voucher.id]
    );

    if (updateResult.affectedRows !== 1) {
      await connection.rollback();

      return res.status(409).json({
        success: false,
        error: 'Voucher sudah ditukarkan atau tidak dapat digunakan.',
      });
    }

    await connection.commit();

    return res.status(200).json({
      success: true,
      status: 'redeemed',
      message: 'Voucher berhasil ditukarkan.',
      voucher: {
        id: voucher.id,
        code: voucher.code,
        customer_id: voucher.customer_id,
        campaign_id: voucher.campaign_id,
      },
    });
  } catch (error) {
    if (connection) {
      try {
        await connection.rollback();
      } catch (_) {}
    }

    next(error);
  } finally {
    if (connection) connection.release();
  }
});

module.exports = router;