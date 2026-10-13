import assert from 'node:assert/strict';
import { ROSTER, RARITIES, PLAYABLE, newRun, rollShop, shopOdds, recruit, canRecruit, makeRandom, equipItem, unequipItems, reservePiece, deployPiece,
  copyValue, sellValue, sell, interestIncome, settleRound, movePiece } from '../src/tft-core.mjs';
import { createHudState, hudOptions, actHud } from '../src/tft-hud.mjs';

assert.deepEqual(Object.values(RARITIES).map(r => r.cost), [1,3,5]);
assert.deepEqual(Object.values(RARITIES).map(r => r.kinds.length), [4,5,3]);
assert.deepEqual(Object.values(RARITIES).flatMap(r => r.kinds).sort(), [...PLAYABLE].sort());
for (const [key, rule] of Object.entries(RARITIES)) for (const kind of rule.kinds) {
  assert.equal(ROSTER[kind].rarity, key); assert.equal(ROSTER[kind].cost, rule.cost);
}
for (let seed = 1; seed <= 64; seed++) {
  const run = newRun(seed);
  assert(run.shop.includes('Tank'));
  assert(run.shop.filter(kind => ROSTER[kind].role === 'dps').length >= 2);
  assert(run.shop.every(kind => ROSTER[kind].rarity !== 'epic'));
  assert.equal(run.shop.length, 5);
}
const distribution = [];
for (const round of [0,5,10]) {
  const run = newRun(712 + round); run.round = round;
  const counts = {normal:0,rare:0,epic:0};
  for (let sample = 0; sample < 10000; sample++) {
    assert(rollShop(run,true));
    const repeats = {};
    for (const kind of run.shop) {
      counts[ROSTER[kind].rarity]++; repeats[kind] = (repeats[kind] || 0) + 1;
      assert(repeats[kind] <= 2, 'At most two identical offers');
    }
  }
  for (const key of Object.keys(counts)) assert(Math.abs(counts[key]/500 - shopOdds(round)[key]) < 1, `${round}/${key}: rarity probability`);
  distribution.push({round:round+1,percent:Object.fromEntries(Object.entries(counts).map(([k,v])=>[k,+(v/500).toFixed(2)]))});
}
assert.deepEqual(shopOdds(4), {normal:75,rare:25,epic:0});
assert.deepEqual(shopOdds(9), {normal:55,rare:35,epic:10});
assert.deepEqual(shopOdds(14), {normal:30,rare:50,epic:20});
const buy = (run, kind, preferred) => { run.shop = [kind]; assert(recruit(run,0,preferred)); };
const run = newRun(17); run.gold = 100;
buy(run,'Tank'); const main = run.team[0]; assert(movePiece(run,main.uid,{type:'field',cell:8}));
buy(run,'Tank'); assert.equal(run.team.length,2);
buy(run,'Tank',main.uid);
assert.equal(run.team.length,1); assert.equal(run.team[0],main); assert.equal(main.star,2);
assert.equal(main.x,-560); assert.equal(main.y,-700); assert.equal(main.cell,8); assert.equal(run.gold,97);
for (let copy = 3; copy < 9; copy++) buy(run,'Tank',main.uid);
assert.equal(main.star,3); assert.equal(run.team.length,1); assert.equal(copyValue(main),9);
assert.equal(sellValue(main),9); assert.equal(run.gold,91);
buy(run,'Tank'); assert.equal(main.star,3); assert.equal(run.team.length,2, 'Max-star unit does not absorb additional copies');
const poor = newRun(17), control = newRun(17); poor.gold = 1;
const before = JSON.stringify(poor); assert.equal(rollShop(poor),false); assert.equal(JSON.stringify(poor),before);
rollShop(poor,true); rollShop(control,true); assert.deepEqual(poor.shop,control.shop, 'Failed refresh does not consume RNG');

const piece = (kind,uid,star=1,items=[]) => ({kind,uid,star,items});
const full = newRun(); full.gold = 100; full.nextId = 15;
full.team = [piece('Tank',1),piece('Tank',2),...['Ranger','Caster','Assassin','Gorilla'].map((k,i)=>piece(k,i+3,2))];
full.bench = ['Cowboy','Witch','Ninja','Genie','RatKing','Cobra','David','Ranger'].map((k,i)=>piece(k,i+7,2));
full.shop = ['Witch','Tank'];
const fullBefore = JSON.stringify(full); assert.equal(canRecruit(full,0),false); assert.equal(recruit(full,0),false); assert.equal(JSON.stringify(full),fullBefore);
assert(canRecruit(full,1), 'Third copy remains buyable at full capacity');
assert(recruit(full,1,1)); assert.equal(full.team[0].star,2); assert.equal(full.team.length,5);
assert.equal(full.bench.filter(Boolean).length,8); assert.equal(full.gold,99);
assert(!Object.hasOwn(full.bench,'-1'));
const benchOnly = newRun(); benchOnly.gold = 100; benchOnly.nextId = 9;
benchOnly.team = ['Tank','Ranger','Caster','Assassin','Gorilla','Cowboy'].map((k,i)=>piece(k,i+1));
benchOnly.bench[2] = piece('Witch',7); benchOnly.bench[6] = piece('Witch',8);
buy(benchOnly,'Witch'); assert.equal(benchOnly.bench[2].star,2); assert.equal(benchOnly.bench[6],null);
assert.equal(benchOnly.lastRecruit.board,false, 'Bench-only merge does not rebuild field');
assert.equal(benchOnly.bench.length,8);

const chain = newRun(); chain.gold = 100; chain.nextId = 5; chain.bag = {blade:0,heart:0,tome:0};
chain.team = [piece('Tank',1,1,['blade','heart','tome']),piece('Tank',2,1,['blade','heart','tome'])];
chain.bench[0] = piece('Tank',3,2,['blade','heart','tome']); chain.bench[7] = piece('Tank',4,2,['blade','heart','tome']);
buy(chain,'Tank',1);
assert.equal(chain.team[0].star,3); assert.equal(chain.team.length,1); assert.equal(chain.lastRecruit.merges.length,2);
assert.deepEqual(chain.team[0].items,['blade','heart','tome']); assert.deepEqual(chain.bag,{blade:3,heart:3,tome:3});
assert.equal(chain.bench.filter(Boolean).length,0); assert.equal(chain.gold,99);
assert(sell(chain,1)); assert.equal(chain.gold,108); assert.deepEqual(chain.bag,{blade:4,heart:4,tome:4});

const hudRun = newRun(); hudRun.gold = 100; const hud = createHudState();
for (let i = 0; i < 3; i++) { hudRun.shop = ['Ranger']; assert(actHud(hudRun,hud,2).changed); }
assert.equal(hud.selected,hudRun.team[0].uid); assert.equal(hudRun.team[0].star,2);
assert(hud.notice.includes('FUSÃO AUTOMÁTICA')); assert(hudOptions(hudRun,hud)[31].label.includes('CÓPIAS 1/3'));
const manualBefore = JSON.stringify(hudRun); assert.equal(actHud(hudRun,hud,31).changed,false); assert.equal(JSON.stringify(hudRun),manualBefore);
for (const [gold, expected] of [[0,0],[9,0],[10,1],[19,1],[20,2],[29,2],[30,3],[49,4],[50,5],[60,6],[100,10]]) {
  assert.equal(interestIncome(gold),expected);
  for (const won of [true,false]) {
    const economy = newRun(); economy.gold = gold;
    const payout = settleRound(economy,won,2);
    assert.equal(payout.interest,expected); assert.equal(payout.gold,5+expected+(won?1:0));
    assert.equal(economy.gold,gold+payout.gold);
  }
  hudRun.gold = gold;
  assert(hudOptions(hudRun,hud)[135].label.includes(`JUROS +${expected}`));
}
const locked = newRun(); locked.locked = true; locked.gold = 10;
const savedShop = [...locked.shop]; const payout = settleRound(locked,true);
assert.deepEqual(locked.shop,savedShop); assert.equal(payout.interest,1);
const paidGold = locked.gold; assert(rollShop(locked)); assert.equal(locked.gold,paidGold-2); assert(locked.locked);
const mixed = newRun(61), random = makeRandom(198); mixed.gold = 10000;
const owned = () => mixed.team.concat(mixed.bench.filter(Boolean));
const mass = () => owned().reduce((n,u)=>n+copyValue(u),0);
const itemCount = () => Object.values(mixed.bag).reduce((a,b)=>a+b,0)+owned().reduce((n,u)=>n+u.items.length,0);
for (let step=0;step<1500;step++) {
  mixed.round = step % 15; rollShop(mixed,true);
  const index = Math.floor(random()*5), previousMass = mass(), previousGold=mixed.gold, previousItems=itemCount();
  const kind = mixed.shop[index], ok = recruit(mixed,index);
  assert.equal(mass(),previousMass+(ok?1:0)); assert.equal(mixed.gold,previousGold-(ok?ROSTER[kind].cost:0));
  assert.equal(itemCount(),previousItems,'Fusion conserves every item');
  const pieces = owned(), selected = pieces[Math.floor(random()*pieces.length)];
  if (selected) {
    if (step%5===0) equipItem(mixed,selected.uid,['blade','heart','tome'][step%3]);
    if (step%7===0) unequipItems(mixed,selected.uid);
    if (step%11===0) {
      const oldMass=mass(), oldGold=mixed.gold, oldItems=itemCount();
      sell(mixed,selected.uid);
      assert.equal(mass(),oldMass-copyValue(selected)); assert.equal(mixed.gold,oldGold+sellValue(selected)); assert.equal(itemCount(),oldItems);
    } else if (step%3===0) reservePiece(mixed,selected.uid);
    else if (step%3===1) deployPiece(mixed,Math.floor(random()*8),mixed.team[0]?.uid);
  }
  assert(mixed.team.length<=6&&mixed.bench.length===8);
  const live=owned(); assert.equal(new Set(live.map(u=>u.uid)).size,live.length);
  const groups={};
  for (const u of live) {
    assert(u.star>=1&&u.star<=3&&u.items.length<=3);
    const key=`${u.kind}:${u.star}`;groups[key]=(groups[key]||0)+1;
    if(u.star<3)assert(groups[key]<3,'No eligible trio can remain unmerged');
  }
}
console.log(JSON.stringify({passed:true,distribution,mixedActions:1500,checks:'Rarities/prices, opening/refresh/lock, full-capacity purchase, automatic/cascading fusions, positions, selection, conserved copies/items, sales and uncapped interest.'},null,2));
