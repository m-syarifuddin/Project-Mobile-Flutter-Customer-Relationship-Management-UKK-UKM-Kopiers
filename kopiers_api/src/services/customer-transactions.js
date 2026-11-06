const pool = require('../config/database');

async function listTransactionsForUser(userId) {
  const [transactions] = await pool.execute(
    `SELECT t.id, t.total_amount, t.status, t.created_at
     FROM customers c JOIN transactions t ON t.customer_id = c.id
     WHERE c.user_id = ? ORDER BY t.created_at DESC`,
    [userId]
  );
  if (!transactions.length) return transactions;

  const placeholders = transactions.map(() => '?').join(',');
  const [items] = await pool.execute(
    `SELECT ti.transaction_id, ti.product_name, ti.quantity, ti.line_total,
            p.image_url
     FROM transaction_items ti
     LEFT JOIN products p ON p.id = ti.product_id
     WHERE ti.transaction_id IN (${placeholders})
     ORDER BY ti.id`,
    transactions.map((transaction) => transaction.id)
  );
  const itemsByTransaction = new Map();
  for (const item of items) {
    const transactionItems = itemsByTransaction.get(Number(item.transaction_id)) || [];
    transactionItems.push({
      product: item.product_name,
      quantity: item.quantity,
      line_total: item.line_total,
      image_url: item.image_url
    });
    itemsByTransaction.set(Number(item.transaction_id), transactionItems);
  }
  return transactions.map((transaction) => ({
    ...transaction,
    items: itemsByTransaction.get(Number(transaction.id)) || []
  }));
}

module.exports = { listTransactionsForUser };
