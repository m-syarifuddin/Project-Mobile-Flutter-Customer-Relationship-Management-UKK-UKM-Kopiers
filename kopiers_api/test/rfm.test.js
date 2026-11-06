const { test } = require('node:test');
const assert = require('node:assert/strict');
const { calculateRfm } = require('../src/utils/rfm');
const { RFM_CUSTOMERS_QUERY } = require('../src/services/rfm-customers');

const DAY_IN_MS = 24 * 60 * 60 * 1000;
const now = new Date('2026-11-06T00:00:00.000Z');

function customer({
  id = 1,
  ageDays = 0,
  transactionCount = 1,
  lifetimeValue = 100000,
  periodTransactionCount = transactionCount,
  periodValue = lifetimeValue,
} = {}) {
  return {
    id,
    transaction_count: transactionCount,
    lifetime_value: lifetimeValue,
    rfm_transaction_count: periodTransactionCount,
    rfm_monetary_value: periodValue,
    last_purchase: transactionCount > 0
      ? new Date(now.getTime() - ageDays * DAY_IN_MS)
      : null,
  };
}

test('customers without completed purchases have no-purchase scores', () => {
  const [result] = calculateRfm([
    customer({
      transactionCount: 0,
      lifetimeValue: 0,
      periodTransactionCount: 0,
      periodValue: 0,
    }),
  ], now);

  assert.equal(result.rfm_score, '111');
  assert.deepEqual(result.rfm_scores, {
    recency: 1,
    frequency: 1,
    monetary: 1,
  });
  assert.equal(result.rfm_segment, 'no_purchase');
  assert.equal(result.recency_days, null);
});

test('recency boundaries use the existing 14, 30, 60, and 90 day rules', () => {
  const cases = [
    [0, 5],
    [14, 5],
    [15, 4],
    [30, 4],
    [31, 3],
    [60, 3],
    [61, 2],
    [90, 2],
    [91, 1],
  ];

  for (const [ageDays, expectedScore] of cases) {
    const [result] = calculateRfm([customer({ ageDays })], now);
    assert.equal(result.rfm_scores.recency, expectedScore, `${ageDays} days`);
  }
});

test('future transaction dates are clamped to zero recency days', () => {
  const [result] = calculateRfm([
    customer({ ageDays: -2 }),
  ], now);

  assert.equal(result.recency_days, 0);
  assert.equal(result.rfm_scores.recency, 5);
});

test('frequency and monetary receive ascending-cohort quintile scores', () => {
  const customers = [1, 2, 3, 4, 5].map((value) => customer({
    id: value,
    transactionCount: value,
    lifetimeValue: value * 100000,
    periodTransactionCount: value,
    periodValue: value * 100000,
  }));
  const result = calculateRfm(customers, now);

  assert.deepEqual(
    result.map((row) => row.rfm_scores.frequency),
    [1, 2, 3, 4, 5]
  );
  assert.deepEqual(
    result.map((row) => row.rfm_scores.monetary),
    [1, 2, 3, 4, 5]
  );
});

test('equal values share the neutral quintile score', () => {
  const result = calculateRfm([
    customer({ id: 1 }),
    customer({ id: 2 }),
    customer({ id: 3 }),
  ], now);

  for (const row of result) {
    assert.equal(row.rfm_scores.frequency, 3);
    assert.equal(row.rfm_scores.monetary, 3);
  }
});

test('a first recent purchase is a new customer even in a small cohort', () => {
  const [result] = calculateRfm([
    customer(),
  ], now);

  assert.equal(result.rfm_segment, 'new_customers');
});

test('customers with a few recent purchases are potential loyalists', () => {
  const [result] = calculateRfm([
    customer({
      transactionCount: 2,
      lifetimeValue: 200000,
      periodTransactionCount: 2,
      periodValue: 200000,
    }),
  ], now);

  assert.equal(result.rfm_segment, 'potential_loyalists');
});

test('champions have recent activity and top cohort frequency and monetary scores', () => {
  const customers = [1, 2, 3, 4, 5].map((value) => customer({
    id: value,
    transactionCount: value,
    lifetimeValue: value * 100000,
    periodTransactionCount: value,
    periodValue: value * 100000,
  }));
  const [champion] = calculateRfm(customers, now).slice(-1);

  assert.equal(champion.rfm_score, '555');
  assert.equal(champion.rfm_segment, 'champions');
});

test('loyal customers have recent activity and high cohort frequency', () => {
  const customers = [1, 2, 3, 4, 5].map((value) => customer({
    id: value,
    ageDays: value === 5 ? 31 : 0,
    transactionCount: value,
    lifetimeValue: value * 100000,
    periodTransactionCount: value,
    periodValue: value * 100000,
  }));
  const [loyal] = calculateRfm(customers, now).slice(-1);

  assert.equal(loyal.rfm_scores.recency, 3);
  assert.equal(loyal.rfm_scores.frequency, 5);
  assert.equal(loyal.rfm_segment, 'loyal_customers');
});

test('lapsed high-value customers are cant_lose_them before at_risk', () => {
  const [result] = calculateRfm([
    customer({
      ageDays: 120,
      transactionCount: 6,
      lifetimeValue: 750000,
      periodTransactionCount: 0,
      periodValue: 0,
    }),
  ], now);

  assert.equal(result.rfm_segment, 'cant_lose_them');
});

test('lapsed previously active customers are at_risk', () => {
  const [result] = calculateRfm([
    customer({
      ageDays: 91,
      transactionCount: 4,
      lifetimeValue: 500000,
      periodTransactionCount: 0,
      periodValue: 0,
    }),
  ], now);

  assert.equal(result.rfm_segment, 'at_risk');
});

test('lapsed customers with low historical activity are hibernating', () => {
  const [result] = calculateRfm([
    customer({
      ageDays: 120,
      transactionCount: 3,
      lifetimeValue: 250000,
      periodTransactionCount: 0,
      periodValue: 0,
    }),
  ], now);

  assert.equal(result.rfm_segment, 'hibernating');
});

test('RFM aggregation only uses distinct completed transactions within the UTC window', () => {
  assert.match(RFM_CUSTOMERS_QUERY, /WHERE status = 'completed'/);
  assert.match(RFM_CUSTOMERS_QUERY, /COUNT\(DISTINCT id\) AS transaction_count/);
  assert.match(RFM_CUSTOMERS_QUERY, /COUNT\(DISTINCT CASE/);
  assert.match(RFM_CUSTOMERS_QUERY, /created_at >= \?/);
  assert.match(RFM_CUSTOMERS_QUERY, /created_at <= \?/);
});

test('rejects invalid RFM metrics and inconsistent transaction history', () => {
  assert.throws(
    () => calculateRfm([customer({ transactionCount: -1 })], now),
    /Invalid RFM transaction count/
  );
  assert.throws(
    () => calculateRfm([customer({
      transactionCount: 1,
      periodTransactionCount: 2,
    })], now),
    /Inconsistent RFM period metrics/
  );
});

test('returns an empty result for an empty customer list', () => {
  assert.deepEqual(calculateRfm([], now), []);
});
