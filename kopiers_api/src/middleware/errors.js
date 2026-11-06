function notFound(req, res) {
  res.status(404).json({ error: 'Endpoint tidak ditemukan.' });
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);

  if (error.name === 'ZodError') {
    return res.status(400).json({
      error: 'Input tidak valid.',
      details: error.issues.map(({ path, message }) => ({ field: path.join('.'), message }))
    });
  }
  if (error.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'Data dengan nilai tersebut sudah terdaftar.' });
  }
  if (error.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({ error: 'Referensi data tidak ditemukan.' });
  }
  if (error.type === 'entity.too.large') {
    return res.status(413).json({ error: 'Ukuran gambar maksimal 5 MB.' });
  }

  console.error(error);
  return res.status(500).json({
    error: process.env.NODE_ENV === 'production' ? 'Terjadi kesalahan pada server.' : error.message
  });
}

module.exports = { notFound, errorHandler };
