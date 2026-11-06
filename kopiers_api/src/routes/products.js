const express = require('express');
const { randomUUID } = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const { z } = require('zod');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();
const productImageDirectory = path.resolve(__dirname, '../../uploads/products');
const imagePathSchema = z.string().regex(/^\/products\/images\/[0-9a-f-]{36}\.(jpg|png|webp)$/i);
const imageTypes = {
  'image/jpeg': {
    extension: 'jpg',
    matches: (image) => image[0] === 0xff && image[1] === 0xd8 && image[2] === 0xff
  },
  'image/png': {
    extension: 'png',
    matches: (image) => image.subarray(0, 8).equals(
      Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    )
  },
  'image/webp': {
    extension: 'webp',
    matches: (image) => image.toString('ascii', 0, 4) === 'RIFF'
      && image.toString('ascii', 8, 12) === 'WEBP'
  }
};
const productSchema = z.object({
  name: z.string().trim().min(1).max(140),
  description: z.string().trim().max(500).optional().nullable(),
  price: z.number().finite().nonnegative(),
  image_url: imagePathSchema.optional().nullable()
});

router.use(authenticate);
router.get('/', async (req, res, next) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, name, description, price, image_url, is_active, created_at
       FROM products WHERE is_active = TRUE ORDER BY name`
    );
    return res.json({ data: rows });
  } catch (error) {
    return next(error);
  }
});

router.post(
  '/images',
  authorize('admin'),
  express.raw({ type: Object.keys(imageTypes), limit: '5mb' }),
  async (req, res, next) => {
    try {
      const image = imageTypes[req.get('content-type')];
      if (!Buffer.isBuffer(req.body) || req.body.length === 0 || !image?.matches(req.body)) {
        return res.status(400).json({ error: 'Pilih gambar JPG, PNG, atau WebP yang valid.' });
      }
      const filename = `${randomUUID()}.${image.extension}`;
      await fs.mkdir(productImageDirectory, { recursive: true });
      await fs.writeFile(path.join(productImageDirectory, filename), req.body, { flag: 'wx' });
      return res.status(201).json({ image_url: `/products/images/${filename}` });
    } catch (error) {
      return next(error);
    }
  }
);

router.get('/images/:filename', async (req, res, next) => {
  try {
    const filename = z.string().regex(/^[0-9a-f-]{36}\.(jpg|png|webp)$/i).parse(req.params.filename);
    const imageUrl = `/products/images/${filename}`;
    const [products] = await pool.execute(
      'SELECT id FROM products WHERE image_url = ? LIMIT 1',
      [imageUrl]
    );
    if (!products[0]) return res.status(404).json({ error: 'Foto produk tidak ditemukan.' });
    const filePath = path.join(productImageDirectory, filename);
    await fs.access(filePath);
    res.set('Cache-Control', 'private, max-age=3600');
    return res.sendFile(filePath);
  } catch (error) {
    if (error.code === 'ENOENT') return res.status(404).json({ error: 'Foto produk tidak ditemukan.' });
    return next(error);
  }
});

router.post('/', authorize('admin'), async (req, res, next) => {
  try {
    const input = productSchema.parse(req.body);
    const [result] = await pool.execute(
      'INSERT INTO products (name, description, price, image_url) VALUES (?, ?, ?, ?)',
      [input.name, input.description || null, input.price, input.image_url || null]
    );
    return res.status(201).json({ id: result.insertId, message: 'Produk berhasil dibuat.' });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:id', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const input = productSchema.partial().parse(req.body);
    if (!Object.keys(input).length) return res.status(400).json({ error: 'Tidak ada perubahan yang dikirim.' });
    const fields = Object.keys(input);
    const values = fields.map((field) => input[field] === '' ? null : input[field]);
    const [result] = await pool.execute(
      `UPDATE products SET ${fields.map((field) => `${field} = ?`).join(', ')} WHERE id = ?`,
      [...values, id]
    );
    if (!result.affectedRows) return res.status(404).json({ error: 'Produk tidak ditemukan.' });
    return res.json({ message: 'Produk berhasil diperbarui.' });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:id', authorize('admin'), async (req, res, next) => {
  try {
    const id = z.coerce.number().int().positive().parse(req.params.id);
    const [result] = await pool.execute('UPDATE products SET is_active = FALSE WHERE id = ?', [id]);
    if (!result.affectedRows) return res.status(404).json({ error: 'Produk tidak ditemukan.' });
    return res.json({ message: 'Produk dinonaktifkan.' });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;
