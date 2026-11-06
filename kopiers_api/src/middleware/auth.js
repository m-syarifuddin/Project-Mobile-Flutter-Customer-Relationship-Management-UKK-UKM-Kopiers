const jwt = require('jsonwebtoken');
const pool = require('../config/database');

async function authenticate(req, res, next) {
  const header = req.get('authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Token autentikasi diperlukan.' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const [rows] = await pool.execute(
      'SELECT id, role, is_active, token_version FROM users WHERE id = ? LIMIT 1',
      [payload.sub]
    );
    const user = rows[0];
    if (!user || !user.is_active || user.token_version !== payload.ver) {
      return res.status(401).json({ error: 'Sesi tidak berlaku. Silakan login kembali.' });
    }
    req.user = { id: user.id, role: user.role };
    return next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token tidak valid atau sudah kedaluwarsa.' });
    }
    return next(error);
  }
}

function authorize(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Anda tidak memiliki izin untuk tindakan ini.' });
    }
    return next();
  };
}

module.exports = { authenticate, authorize };
