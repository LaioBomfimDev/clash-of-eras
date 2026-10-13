import assert from 'node:assert/strict';
import * as core from '../src/tft-core.mjs';

for (const kind of core.PLAYABLE) {
  const unit = { kind, star: 1, items: [] }, base = core.ROSTER[kind];
  const st = core.stats(unit, [unit]);
  assert.equal(st.hp, base.role === 'tank' ? 80 : 50, `${kind}: exact base health`);
  assert.equal(st.damage, 1, `${kind}: first attack stat`);
  assert(st.period >= 2, `${kind}: readable attack interval`);
  assert.equal(core.stats({ ...unit, star: 2 }, [unit]).damage, 2);
  assert.equal(core.stats({ ...unit, star: 3, items: ['blade', 'blade'] }, [unit]).damage, 6);
}

const run = core.newRun(11);
run.gold = 200;
// A full roster of already evolved pieces cannot accidentally merge as these
// capacity/movement tests arrange it. Fusion itself has a dedicated suite.
run.team = Array.from({length:6}, () => ({uid:run.nextId++,kind:'Tank',star:3,items:[]}));
run.bench = Array.from({length:8}, (_,i) => ({uid:run.nextId++,kind:i===0?'Gorilla':'Genie',star:i===0?2:3,items:[]}));
assert.equal(run.team.length, 6);
assert.equal(run.bench.length, 8);
assert.equal(run.bench.filter(Boolean).length, 8);
const beforeFailedBuy = JSON.stringify({ gold: run.gold, team: run.team, bench: run.bench });
run.shop = ['Tank'];
assert.equal(core.recruit(run, 0), false);
assert.equal(JSON.stringify({ gold: run.gold, team: run.team, bench: run.bench }), beforeFailedBuy);
assert.equal(core.synergies(run.team).guardian.level, 0, 'Bench Gorilla must not trigger a field synergy');
assert.equal(core.reservePiece(run, run.team[0].uid), false, 'Full bench must reject a move');
assert.equal(core.deployPiece(run, 0), false, 'Full field must require a swap');
const fromBench = run.bench[0], fromField = run.team[0];
assert.equal(core.upgrade,undefined, 'No paid star upgrade remains');
assert(core.equipItem(run, fromBench.uid, 'blade'));
assert.equal(core.equipItem(run, fromBench.uid, 'blade'), false, 'No free item duplication');
assert(core.deployPiece(run, 0, fromField.uid));
assert.equal(run.team[0], fromBench);
assert.equal(run.bench[0], fromField);
assert.equal(fromBench.star, 2);
assert.deepEqual(fromBench.items, ['blade']);
assert.equal(core.synergies(run.team).guardian.level, 1);
const allIds = [...run.team, ...run.bench.filter(Boolean)].map(u => u.uid);
assert.equal(new Set(allIds).size, 14, 'Swap must preserve exactly fourteen distinct pieces');
assert(core.sell(run, fromField.uid));
assert.equal(run.bench[0], null);
assert(core.reservePiece(run, fromBench.uid));
assert.equal(core.synergies(run.team).guardian.level, 0);
assert(core.deployPiece(run, 0));
assert.equal(run.team.at(-1), fromBench);
assert(core.equipItem(run, fromBench.uid, 'heart'));
assert(core.grantItem(run, 'tome')); assert(core.equipItem(run, fromBench.uid, 'tome'));
core.grantItem(run, 'blade');
assert.equal(core.equipItem(run, fromBench.uid, 'blade'), false, 'Three equipment slots maximum');
assert(core.unequipItems(run, fromBench.uid));
assert.deepEqual(fromBench.items, []);
assert.equal(run.bag.blade, 2); assert.equal(run.bag.heart, 1); assert.equal(run.bag.tome, 1);
assert(core.equipItem(run, fromBench.uid, 'heart'));
assert(core.sell(run, fromBench.uid)); assert.equal(run.bag.heart, 1, 'Sale returns equipment');
assert.equal(core.deployPiece(run, 8), false);
assert.equal(core.deployPiece(run, -1), false);
assert.equal(core.grantItem(run, 'missing'), false);

const left = [{ kind: 'Ranger', star: 1, id: 1, x: 0, y: -300 }];
const right = [{ kind: 'Tank', star: 1, id: 2, x: 0, y: -300 }];
const sim = core.simulate(left, right);
assert.equal(sim.frames.flatMap(f => f.events).find(e => e.type === 'hit').damage, 1);
const attacks = sim.frames.flatMap((f, index) => f.events.filter(e => e.type === 'attack' && e.id === 1).map(() => index * 0.033));
assert(attacks[1] - attacks[0] >= 2.29, 'Attack cooldown cannot be skipped');
const firstAttack = sim.frames.findIndex(f => f.events.some(e => e.type === 'attack'));
const firstHit = sim.frames.findIndex(f => f.events.some(e => e.type === 'hit'));
assert((firstHit - firstAttack) * 0.033 >= 0.49, 'Damage lands after animation windup');
assert(sim.duration <= 98, 'Combat remains bounded');
assert.equal(left[0].health, undefined, 'Simulation must not mutate persistent roster');
const healer = core.simulate([{kind:'Tank', id:10}, {kind:'Genie', id:11, items:['tome']}], [{kind:'Ranger', id:20, star:2}, {kind:'Cowboy', id:21}]);
assert(healer.frames.some(f => f.events.some(e => e.type === 'heal' && e.id === 10)), 'Healer must heal an injured ally');
console.log('PASS: 12 base-health/damage profiles, star/item growth, all 8 reserve slots, full-capacity swaps, item conservation, field-only synergies, healer, attack cadence and delayed floating-damage input.');
