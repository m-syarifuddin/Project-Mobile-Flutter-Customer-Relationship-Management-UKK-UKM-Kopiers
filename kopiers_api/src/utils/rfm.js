const RFM_SEGMENTS = [
  'no_purchase',
  'champions',
  'loyal_customers',
  'potential_loyalists',
  'new_customers',
  'need_attention',
  'at_risk',
  'cant_lose_them',
  'hibernating',
  'regular',
];

const DAY_IN_MS = 24 * 60 * 60 * 1000;
const RFM_WINDOW_DAYS = 365;
const RFM_WINDOW_MS = RFM_WINDOW_DAYS * DAY_IN_MS;
const CANT_LOSE_MIN_LIFETIME_TRANSACTIONS = 6;
const CANT_LOSE_MIN_LIFETIME_VALUE = 750000;
const AT_RISK_MIN_LIFETIME_TRANSACTIONS = 4;

function scoreRecency(recencyDays) {
  if (recencyDays <= 14) return 5;
  if (recencyDays <= 30) return 4;
  if (recencyDays <= 60) return 3;
  if (recencyDays <= 90) return 2;
  return 1;
}

function scoreQuintiles(customers, metric, higherIsBetter) {
  const values = customers
    .filter((customer) => customer.rfm_transaction_count > 0)
    .map((customer) => customer[metric])
    .sort((left, right) => left - right);

  const valueCounts = new Map();
  for (const value of values) {
    valueCounts.set(value, (valueCounts.get(value) || 0) + 1);
  }

  const scores = new Map();
  let lowerCount = 0;

  for (const [value, equalCount] of valueCounts) {
    const averageRank = lowerCount + (equalCount + 1) / 2;
    const percentile = (averageRank - 0.5) / values.length;
    const ascendingScore = Math.min(5, Math.floor(percentile * 5) + 1);
    scores.set(value, higherIsBetter ? ascendingScore : 6 - ascendingScore);
    lowerCount += equalCount;
  }

  return customers.map((customer) => ({
    ...customer,
    [metric === 'rfm_transaction_count'
      ? 'rfm_frequency_score'
      : 'rfm_monetary_score']: customer.rfm_transaction_count > 0
      ? scores.get(customer[metric])
      : 1,
  }));
}

function scoreRfmCohort(customers) {
  const frequencyScored = scoreQuintiles(
    customers,
    'rfm_transaction_count',
    true
  );
  return scoreQuintiles(
    frequencyScored,
    'rfm_monetary_value',
    true
  );
}

function classifyRfmSegment(
  recency,
  frequency,
  monetary,
  hasPurchases,
  periodTransactionCount,
  lifetimeTransactionCount,
  lifetimeValue
) {
  if (!hasPurchases) return 'no_purchase';

  if (recency >= 4 && frequency >= 4 && monetary >= 4) {
    return 'champions';
  }

  if (recency >= 3 && frequency >= 4) {
    return 'loyal_customers';
  }

  if (recency <= 2 &&
      lifetimeTransactionCount >= CANT_LOSE_MIN_LIFETIME_TRANSACTIONS &&
      lifetimeValue >= CANT_LOSE_MIN_LIFETIME_VALUE) {
    return 'cant_lose_them';
  }

  if (recency <= 2 &&
      lifetimeTransactionCount >= AT_RISK_MIN_LIFETIME_TRANSACTIONS) {
    return 'at_risk';
  }

  if (recency <= 2) {
    return 'hibernating';
  }

  if (recency >= 4 &&
      periodTransactionCount >= 2 &&
      frequency <= 3) {
    return 'potential_loyalists';
  }

  if (recency >= 4 && periodTransactionCount === 1) {
    if (lifetimeTransactionCount === 1) {
      return 'new_customers';
    }
  }

  if (recency === 3 && frequency >= 2) {
    return 'need_attention';
  }

  return 'regular';
}

function toNonnegativeNumber(value, fieldName) {
  const number = Number(value ?? 0);
  if (!Number.isFinite(number) || number < 0) {
    throw new TypeError(`Invalid RFM ${fieldName}.`);
  }
  return number;
}

function calculateRfm(customers, now = new Date()) {
  const currentTime = now.getTime();
  if (!Number.isFinite(currentTime)) {
    throw new TypeError('Invalid RFM reference date.');
  }

  const normalized = customers.map((customer) => {
    const transactionCount = toNonnegativeNumber(
      customer.transaction_count,
      'transaction count'
    );
    const lifetimeValue = toNonnegativeNumber(
      customer.lifetime_value,
      'lifetime value'
    );
    const rfmTransactionCount = toNonnegativeNumber(
      customer.rfm_transaction_count,
      'period transaction count'
    );
    const rfmMonetaryValue = toNonnegativeNumber(
      customer.rfm_monetary_value,
      'period monetary value'
    );
    const lastPurchase = customer.last_purchase == null
      ? null
      : new Date(customer.last_purchase);

    if (lastPurchase && !Number.isFinite(lastPurchase.getTime())) {
      throw new TypeError('Invalid RFM purchase date.');
    }

    if (!Number.isInteger(transactionCount) ||
        !Number.isInteger(rfmTransactionCount)) {
      throw new TypeError('Invalid RFM transaction count.');
    }

    if ((transactionCount > 0) !== (lastPurchase != null)) {
      throw new TypeError('Inconsistent RFM purchase history.');
    }

    if (rfmTransactionCount > transactionCount ||
        rfmMonetaryValue > lifetimeValue ||
        (transactionCount === 0 && lifetimeValue !== 0) ||
        (rfmTransactionCount === 0 && rfmMonetaryValue !== 0)) {
      throw new TypeError('Inconsistent RFM period metrics.');
    }

    const recencyDays = lastPurchase
      ? Math.max(0, Math.floor(
        (currentTime - lastPurchase.getTime()) / DAY_IN_MS
      ))
      : null;

    return {
      ...customer,
      transaction_count: transactionCount,
      lifetime_value: lifetimeValue,
      rfm_transaction_count: rfmTransactionCount,
      rfm_monetary_value: rfmMonetaryValue,
      recency_days: recencyDays,
      _recencyScore: recencyDays == null ? 1 : scoreRecency(recencyDays),
    };
  });

  let scored = scoreRfmCohort(normalized);

  return scored.map((customer) => {
    const hasPurchases = customer.transaction_count > 0;
    const recency = hasPurchases ? customer._recencyScore : 1;
    const frequency = hasPurchases ? customer.rfm_frequency_score : 1;
    const monetary = hasPurchases ? customer.rfm_monetary_score : 1;
    const rfmSegment = classifyRfmSegment(
      recency,
      frequency,
      monetary,
      hasPurchases,
      customer.rfm_transaction_count,
      customer.transaction_count,
      customer.lifetime_value
    );

    const {
      _recencyScore,
      ...result
    } = customer;

    return {
      ...result,
      rfm_scores: { recency, frequency, monetary },
      rfm_score: `${recency}${frequency}${monetary}`,
      rfm_segment: rfmSegment,
    };
  });
}

module.exports = {
  RFM_SEGMENTS,
  RFM_WINDOW_DAYS,
  RFM_WINDOW_MS,
  calculateRfm,
};
