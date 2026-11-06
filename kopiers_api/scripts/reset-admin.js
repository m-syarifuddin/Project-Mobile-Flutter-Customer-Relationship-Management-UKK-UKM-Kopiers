require('dotenv').config();
const bcrypt = require('bcryptjs');
const readline = require('node:readline');
const pool = require('../src/config/database');

async function promptHidden(prompt) {
  if (!process.stdin.isTTY || typeof process.stdin.setRawMode !== 'function') {
    throw new Error('Jalankan perintah ini dari terminal interaktif.');
  }

  readline.emitKeypressEvents(process.stdin);
  process.stdin.setRawMode(true);
  process.stdin.resume();
  process.stdout.write(prompt);

  return new Promise((resolve, reject) => {
    let value = '';
    const finish = (error) => {
      process.stdin.removeListener('keypress', onKeypress);
      process.stdin.setRawMode(false);
      process.stdin.pause();
      process.stdout.write('\n');
      if (error) reject(error);
      else resolve(value);
    };

    const onKeypress = (character, key = {}) => {
      if (key.ctrl && key.name === 'c') {
        finish(new Error('Reset password dibatalkan.'));
      } else if (key.name === 'return' || key.name === 'enter') {
        finish();
      } else if (key.name === 'backspace') {
        if (value.length > 0) {
          value = value.slice(0, -1);
          process.stdout.write('\b \b');
        }
      } else if (!key.ctrl && !key.meta && character) {
        value += character;
        process.stdout.write('*');
      }
    };

    process.stdin.on('keypress', onKeypress);
  });
}

async function main() {
  const identifier = process.argv[2]?.trim();
  if (!identifier) {
    throw new Error('Usage: npm run reset-admin -- admin@example.com');
  }

  const [rows] = await pool.execute(
    'SELECT id FROM users WHERE (phone = ? OR email = ?) AND role = ? LIMIT 1',
    [identifier, identifier, 'admin']
  );
  if (!rows[0]) {
    throw new Error('Akun admin tidak ditemukan untuk identifier tersebut.');
  }

  const password = await promptHidden('Password baru (minimal 12 karakter): ');
  if (password.length < 12 || password.length > 72) {
    throw new Error('Password harus terdiri dari 12 sampai 72 karakter.');
  }

  const confirmation = await promptHidden('Ulangi password baru: ');
  if (password !== confirmation) {
    throw new Error('Konfirmasi password tidak cocok. Password tidak diubah.');
  }

  const hash = await bcrypt.hash(password, Number(process.env.BCRYPT_ROUNDS || 12));
  await pool.execute(
    'UPDATE users SET password_hash = ?, token_version = token_version + 1 WHERE id = ?',
    [hash, rows[0].id]
  );
  console.log('Password admin berhasil diubah. Silakan login kembali.');
}

main()
  .catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
