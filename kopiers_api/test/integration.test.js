const { randomBytes } = require('node:crypto');
const { after, before, test } = require('node:test');
const assert = require('node:assert/strict');
const bcrypt = require('bcryptjs');
const fs = require('node:fs/promises');
const path = require('node:path');
const app = require('../src/app');
const pool = require('../src/config/database');

const enabled = process.env.RUN_DB_INTEGRATION === '1';
const tag = randomBytes(6).toString('hex');
const ids = { users: [], customers: [], products: [], rewards: [], campaigns: [], complaints: [] };
const uploadedProductFiles = [];
const uploadedComplaintFiles = [];
let server;
let baseUrl;

before(async () => {
  if (!enabled) return;
  server = app.listen(0);
  await new Promise((resolve, reject) => {
    server.once('listening', resolve);
    server.once('error', reject);
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (!enabled) return;
  if (server) await new Promise((resolve, reject) => server.close((error) => error ? reject(error) : resolve()));
  if (ids.complaints.length) {
    await pool.query(`DELETE FROM complaint_histories WHERE complaint_id IN (?)`, [ids.complaints]);
    await pool.query(`DELETE FROM complaints WHERE id IN (?)`, [ids.complaints]);
  }
  await Promise.all([...uploadedProductFiles, ...uploadedComplaintFiles].map((filename) =>
    fs.unlink(path.resolve(__dirname, '../uploads', filename.directory, filename.name))
  ));
  if (ids.campaigns.length) {
    await pool.query('DELETE FROM vouchers WHERE campaign_id IN (?)', [ids.campaigns]);
    await pool.query('DELETE FROM campaign_audiences WHERE campaign_id IN (?)', [ids.campaigns]);
  }
  if (ids.customers.length) {
    await pool.query('DELETE FROM reward_redemptions WHERE customer_id IN (?)', [ids.customers]);
    await pool.query('DELETE FROM point_transactions WHERE customer_id IN (?)', [ids.customers]);
    const [transactions] = await pool.query('SELECT id FROM transactions WHERE customer_id IN (?)', [ids.customers]);
    const transactionIds = transactions.map((row) => row.id);
    if (transactionIds.length) {
      await pool.query('DELETE FROM vouchers WHERE transaction_id IN (?)', [transactionIds]);
      await pool.query('DELETE FROM transaction_items WHERE transaction_id IN (?)', [transactionIds]);
      await pool.query('DELETE FROM point_transactions WHERE transaction_id IN (?)', [transactionIds]);
      await pool.query('DELETE FROM transactions WHERE id IN (?)', [transactionIds]);
    }
    await pool.query('DELETE FROM customers WHERE id IN (?)', [ids.customers]);
  }
  if (ids.campaigns.length) await pool.query('DELETE FROM campaigns WHERE id IN (?)', [ids.campaigns]);
  if (ids.rewards.length) await pool.query('DELETE FROM rewards WHERE id IN (?)', [ids.rewards]);
  if (ids.products.length) await pool.query('DELETE FROM products WHERE id IN (?)', [ids.products]);
  if (ids.users.length) await pool.query('DELETE FROM users WHERE id IN (?)', [ids.users]);
  await pool.end();
});

test('CRM API integrates authentication, transactions, complaints, campaigns, vouchers, and rewards', {
  skip: !enabled ? 'Set RUN_DB_INTEGRATION=1 to run against the configured isolated test database.' : false
}, async () => {
  const password = 'Integration-Test-Password-1!';
  const passwordHash = await bcrypt.hash(password, 4);
  for (const [index, role] of ['admin', 'customer', 'customer'].entries()) {
    const phone = `089${tag.slice(0, 9)}${index}`;
    const email = `${role}${index}-${tag}@example.test`;
    const [userResult] = await pool.execute(
      'INSERT INTO users (name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?)',
      [`Integration ${role} ${index}`, email, phone, passwordHash, role]
    );
    ids.users.push(userResult.insertId);
    if (role === 'customer') {
      const [customerResult] = await pool.execute(
        'INSERT INTO customers (user_id) VALUES (?)', [userResult.insertId]
      );
      ids.customers.push(customerResult.insertId);
    }
  }
  const [productResult] = await pool.execute(
    'INSERT INTO products (name, price) VALUES (?, ?)', [`Integration product ${tag}`, 10000]
  );
  ids.products.push(productResult.insertId);
  const [rewardResult] = await pool.execute(
    'INSERT INTO rewards (name, points_cost, stock) VALUES (?, ?, ?)',
    [`Integration reward ${tag}`, 3, 1]
  );
  ids.rewards.push(rewardResult.insertId);

  async function request(path, { token, method = 'GET', body } = {}) {
    const headers = {};
    if (token) headers.authorization = `Bearer ${token}`;
    if (body !== undefined) headers['content-type'] = 'application/json';
    return fetch(`${baseUrl}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body)
    });
  }

  async function login(identifier) {
    const response = await request('/api/auth/login', {
      method: 'POST', body: { identifier, password }
    });
    assert.equal(response.status, 200);
    return (await response.json()).token;
  }

  const adminToken = await login(`089${tag.slice(0, 9)}0`);
  const customerToken = await login(`089${tag.slice(0, 9)}1`);
  const otherCustomerToken = await login(`089${tag.slice(0, 9)}2`);

  const productImageBytes = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const productImageUpload = await fetch(`${baseUrl}/api/products/images`, {
    method: 'POST',
    headers: { authorization: `Bearer ${adminToken}`, 'content-type': 'image/png' },
    body: productImageBytes
  });
  assert.equal(productImageUpload.status, 201);
  const productImageUrl = (await productImageUpload.json()).image_url;
  uploadedProductFiles.push({ directory: 'products', name: path.basename(productImageUrl) });
  await pool.execute('UPDATE products SET image_url = ? WHERE id = ?', [productImageUrl, ids.products[0]]);

  const productImageResponse = await fetch(`${baseUrl}/api${productImageUrl}`, {
    headers: { authorization: `Bearer ${customerToken}` }
  });
  assert.equal(productImageResponse.status, 200);
  assert.deepEqual(Buffer.from(await productImageResponse.arrayBuffer()), productImageBytes);
  const customerProducts = await request('/api/products', { token: customerToken });
  const listedProducts = (await customerProducts.json()).data;
  assert.equal(
    listedProducts.find((product) => product.id === ids.products[0]).image_url,
    productImageUrl
  );

  const customerList = await request(
    `/api/customers?search=Integration%20customer%201&status=all&segment=new&page=1&limit=20`,
    { token: adminToken }
  );
  assert.equal(customerList.status, 200);
  assert.equal((await customerList.json()).data[0].id, ids.customers[0]);

  const dashboardResponse = await request('/api/dashboard', { token: adminToken });
  assert.equal(dashboardResponse.status, 200);
  const dashboard = await dashboardResponse.json();
  assert.ok(Array.isArray(dashboard.customer_growth));
  assert.equal(typeof dashboard.programs.active_rewards, 'number');

  const firstSale = await request('/api/transactions', {
    token: adminToken,
    method: 'POST',
    body: { customer_id: ids.customers[0], items: [{ product_id: ids.products[0], quantity: 2 }] }
  });
  assert.equal(firstSale.status, 201);
  const firstSaleData = await firstSale.json();
  assert.equal(firstSaleData.points_earned, 2);
  assert.equal(firstSaleData.status, 'completed');

  const segmentsResponse = await request('/api/segments', { token: adminToken });
  const segments = await segmentsResponse.json();
  const rfmCustomer = segments.data.find((row) => row.id === ids.customers[0]);
  assert.equal(rfmCustomer.rfm_transaction_count, 1);
  assert.equal(rfmCustomer.rfm_segment, 'new_customers');

  const updatedDashboardResponse = await request('/api/dashboard', {
    token: adminToken
  });
  const updatedDashboard = await updatedDashboardResponse.json();
  assert.equal(updatedDashboard.rfm.total, segments.summary.total);
  assert.deepEqual(updatedDashboard.rfm.segments, segments.summary.rfm);

  const balanceResponse = await request('/api/loyalty/points/me', { token: customerToken });
  const memberData = await balanceResponse.json();
  assert.equal(memberData.balance, 2);
  assert.equal(memberData.loyalty_card.customer_name, 'Integration customer 1');
  assert.equal(memberData.loyalty_card.member_id, ids.customers[0]);

  const memberDetailsResponse = await request(
    `/api/customers/${ids.customers[0]}`,
    { token: adminToken }
  );
  const memberDetails = await memberDetailsResponse.json();
  assert.equal(memberDetails.customer.loyalty_tier, 'bronze');

  const customerTransactions = await request('/api/transactions/me', { token: customerToken });
  assert.equal((await customerTransactions.json()).data[0].items[0].image_url, productImageUrl);

  const imageBytes = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const imageUpload = await fetch(`${baseUrl}/api/complaints/images`, {
    method: 'POST',
    headers: { authorization: `Bearer ${customerToken}`, 'content-type': 'image/png' },
    body: imageBytes
  });
  assert.equal(imageUpload.status, 201);
  const imageUrl = (await imageUpload.json()).image_url;
  uploadedComplaintFiles.push({ directory: 'complaints', name: path.basename(imageUrl) });

  const complaintResponse = await request('/api/complaints', {
    token: customerToken,
    method: 'POST',
    body: {
      category: 'Produk',
      description: 'Keluhan integrasi pengujian.',
      image_url: imageUrl
    }
  });
  assert.equal(complaintResponse.status, 201);
  const complaintId = (await complaintResponse.json()).id;
  ids.complaints.push(complaintId);
  const statusResponse = await request(`/api/complaints/${complaintId}/status`, {
    token: adminToken,
    method: 'PATCH',
    body: { status: 'resolved', response: 'Keluhan telah ditangani.' }
  });
  assert.equal(statusResponse.status, 200);
  const privateComplaint = await request(`/api/complaints/${complaintId}`, { token: otherCustomerToken });
  assert.equal(privateComplaint.status, 404);
  const imageResponse = await fetch(`${baseUrl}/api${imageUrl}`, {
    headers: { authorization: `Bearer ${customerToken}` }
  });
  assert.equal(imageResponse.status, 200);
  assert.deepEqual(Buffer.from(await imageResponse.arrayBuffer()), imageBytes);
  const privateImageResponse = await fetch(`${baseUrl}/api${imageUrl}`, {
    headers: { authorization: `Bearer ${otherCustomerToken}` }
  });
  assert.equal(privateImageResponse.status, 404);

  const now = new Date();
  const campaignResponse = await request('/api/campaigns', {
    token: adminToken,
    method: 'POST',
    body: {
      name: `Integration campaign ${tag}`,
      campaign_type: 'new_customer',
      discount_percent: 10,
      starts_at: new Date(now.getTime() - 60000).toISOString(),
      ends_at: new Date(now.getTime() + 86400000).toISOString(),
      target_segment: 'new'
    }
  });
  assert.equal(campaignResponse.status, 201);
  const campaignId = (await campaignResponse.json()).id;
  ids.campaigns.push(campaignId);
  const issued = await request(`/api/campaigns/${campaignId}/vouchers`, {
    token: adminToken,
    method: 'POST'
  });
  assert.equal(issued.status, 201);
  assert.ok((await issued.json()).voucher_count >= 1);
  const customerVouchers = await request('/api/loyalty/vouchers/me', { token: customerToken });
  const voucher = (await customerVouchers.json()).data[0];
  assert.equal(voucher.status, 'available');

  const discountedSale = await request('/api/transactions', {
    token: adminToken,
    method: 'POST',
    body: {
      customer_id: ids.customers[0],
      voucher_code: voucher.code,
      items: [{ product_id: ids.products[0], quantity: 2 }]
    }
  });
  assert.equal(discountedSale.status, 201);
  const sale = await discountedSale.json();
  assert.equal(sale.discount_amount, 2000);
  assert.equal(sale.total_amount, 18000);
  const reportResponse = await request(`/api/campaigns/${campaignId}/report`, { token: adminToken });
  const report = (await reportResponse.json()).report;
  assert.equal(report.redeemed_count, 1);
  assert.equal(report.sales_amount, 18000);

  const redeemResponse = await request(`/api/loyalty/rewards/${ids.rewards[0]}/redeem`, {
    token: customerToken,
    method: 'POST'
  });
  assert.equal(redeemResponse.status, 201);
  const redemption = (await redeemResponse.json()).redemption;
  assert.match(redemption.code, /^RW-[A-F0-9]{12}$/);
  assert.equal(redemption.status, 'pending');
  const customerRedemptions = await request('/api/loyalty/redemptions/me', {
    token: customerToken
  });
  assert.equal((await customerRedemptions.json()).data[0].redemption_code, redemption.code);
  const adminRedemptions = await request('/api/loyalty/redemptions', { token: adminToken });
  const adminRedemption = (await adminRedemptions.json()).data.find(
    (row) => row.redemption_code === redemption.code
  );
  assert.equal(adminRedemption.customer_name, 'Integration customer 1');
  assert.equal(adminRedemption.reward_name, `Integration reward ${tag}`);
  const claimResponse = await request(`/api/loyalty/redemptions/${adminRedemption.id}/claim`, {
    token: adminToken,
    method: 'PATCH'
  });
  assert.equal(claimResponse.status, 200);
  const claimedRedemptions = await request('/api/loyalty/redemptions/me', {
    token: customerToken
  });
  assert.equal((await claimedRedemptions.json()).data[0].status, 'claimed');
  const finalBalance = await request('/api/loyalty/points/me', { token: customerToken });
  assert.equal((await finalBalance.json()).balance, 0);

  const isolatedTransactions = await request('/api/transactions/me', { token: otherCustomerToken });
  assert.deepEqual((await isolatedTransactions.json()).data, []);
  assert.equal((await request('/api/auth/logout', {
    token: customerToken, method: 'POST'
  })).status, 200);
  assert.equal((await request('/api/auth/me', { token: customerToken })).status, 401);
});
