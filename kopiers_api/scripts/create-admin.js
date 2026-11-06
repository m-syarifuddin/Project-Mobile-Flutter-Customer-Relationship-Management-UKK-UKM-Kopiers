require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../src/config/database');

async function main() {
  const [name, phone, email, password] = process.argv.slice(2);
  if (!name || !phone || !password) {
    throw new Error('Usage: npm run create-admin -- "Admin Name" 08123456789 admin@example.com "strong-password"');
  }
  if (password.length < 12) {
    throw new Error('Password admin harus minimal 12 karakter.');
  }
  const hash = await bcrypt.hash(password, Number(process.env.BCRYPT_ROUNDS || 12));
  await pool.execute(
    `INSERT INTO users (name, phone, email, password_hash, role)
     VALUES (?, ?, ?, ?, 'admin')`,
    [name, phone, email || null, hash]
  );
  console.log(`Admin ${phone} berhasil dibuat.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
}).finally(() => pool.end());
