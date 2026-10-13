import assert from 'node:assert/strict';
import fs from 'node:fs';
import { createHash } from 'node:crypto';
import { simulate } from '../src/tft-core.mjs';
import { combatSignature } from './combat-signature.mjs';
// v0.7 continuous timelines are preserved separately. Movement intentionally
// changes in v0.8; lock the new grid after the independent occupancy audit.
const { cases } = JSON.parse(fs.readFileSync(new URL('./combat-grid-baseline.json', import.meta.url)));
for (const test of cases) {
  const before = JSON.stringify([test.left, test.right]);
  const actual = createHash('sha256').update(combatSignature(simulate(test.left, test.right))).digest('hex');
  assert.equal(actual, test.combatSHA256, `Combat changed: round ${test.round + 1}, profile ${test.profile}`);
  assert.equal(JSON.stringify([test.left, test.right]), before, 'Persistent pieces must remain unchanged');
}
assert.throws(() => simulate([{ kind: 'Tank' }], [{ kind: 'Rat', id: 2 }]), /unique integers/);
assert.throws(() => simulate([{ kind: 'Tank', id: 2 }], [{ kind: 'Rat', id: 2 }]), /unique integers/);
console.log(`PASS: ${cases.length} grid timelines remain deterministic, including every reservation, position, range, hit, heal, death and outcome; persistent formations unchanged.`);
