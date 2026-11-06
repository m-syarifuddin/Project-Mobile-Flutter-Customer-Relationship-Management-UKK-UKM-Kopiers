const { test } = require('node:test');
const assert = require('node:assert/strict');
const { classifyLoyalty } = require('../src/utils/loyalty');

test('classifies loyalty tiers using completed transaction thresholds', () => {
  assert.equal(classifyLoyalty(0), 'none');
  assert.equal(classifyLoyalty(1), 'bronze');
  assert.equal(classifyLoyalty(4), 'bronze');
  assert.equal(classifyLoyalty(5), 'silver');
  assert.equal(classifyLoyalty(9), 'silver');
  assert.equal(classifyLoyalty(10), 'gold');
  assert.equal(classifyLoyalty(19), 'gold');
  assert.equal(classifyLoyalty(20), 'platinum');
});
