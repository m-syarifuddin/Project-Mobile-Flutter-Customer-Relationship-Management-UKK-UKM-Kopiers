
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { notFound, errorHandler } = require('./middleware/errors');

const app = express();

app.disable('x-powered-by');
app.use(helmet());

// CORS untuk Flutter Web di lingkungan pengembangan lokal.
app.use(cors({
  origin(origin, callback) {
    if (!origin) {
      return callback(null, true);
    }

    let parsedOrigin;

    try {
      parsedOrigin = new URL(origin);
    } catch {
      return callback(new Error(`Origin tidak valid: ${origin}`));
    }

    const isLocalhost =
      ['localhost', '127.0.0.1'].includes(parsedOrigin.hostname) &&
      ['http:', 'https:'].includes(parsedOrigin.protocol);

    if (isLocalhost) {
      return callback(null, true);
    }

    return callback(new Error(`Origin tidak diizinkan: ${origin}`));
  },
  methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));

app.use(express.json({ limit: '1mb' }));

app.use(
  '/api/auth',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 100,
  })
);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', require('./routes/auth'));
app.use('/api/dashboard', require('./routes/dashboard'));
app.use('/api/customers', require('./routes/customers'));
app.use('/api/products', require('./routes/products'));
app.use('/api/transactions', require('./routes/transactions'));
app.use('/api/complaints', require('./routes/complaints'));
app.use('/api/segments', require('./routes/segments'));
app.use('/api/loyalty', require('./routes/loyalty'));
app.use('/api/campaigns', require('./routes/campaigns'));
app.use('/api/vouchers', require('./routes/vouchers'));

app.use(notFound);
app.use(errorHandler);

module.exports = app;
