function parseJsonValue(value, fallback) {
  if (value === null || value === undefined) return fallback;
  if (Buffer.isBuffer(value)) value = value.toString('utf8');
  if (typeof value !== 'string') return value;

  try {
    return JSON.parse(value);
  } catch (error) {
    throw new Error('Nilai JSON di database tidak valid.', { cause: error });
  }
}

module.exports = { parseJsonValue };
