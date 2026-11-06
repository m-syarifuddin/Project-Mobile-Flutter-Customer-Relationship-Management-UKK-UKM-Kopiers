
require('dotenv').config();

const app = require('./app');
const pool = require('./config/database');

const port = Number(process.env.PORT || 3000);

const server = app.listen(port, '0.0.0.0', async () => {
  console.log(`Kopiers API berjalan di port ${port}.`);

  try {
    await pool.query('SELECT 1');
    console.log('Koneksi database MySQL berhasil.');
  } catch (error) {
    console.error('Koneksi database gagal:', error.message);
  }
});

async function shutdown() {
  server.close(async () => {
    try {
      await pool.end();
    } finally {
      process.exit(0);
    }
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);