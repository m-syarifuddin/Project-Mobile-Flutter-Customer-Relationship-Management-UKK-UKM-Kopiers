function classifyLoyalty(transactionCount) {
  if (transactionCount >= 20) return 'platinum';
  if (transactionCount >= 10) return 'gold';
  if (transactionCount >= 5) return 'silver';
  if (transactionCount >= 1) return 'bronze';
  return 'none';
}

module.exports = { classifyLoyalty };
