import assert from 'node:assert/strict';
import * as core from '../src/tft-core.mjs';
import { createHudState } from '../src/tft-hud.mjs';
import { checkpointBody, encodeCheckpoint, decodeCheckpoint, newestCheckpoint, restoreCheckpoint } from '../src/tft-save.mjs';
const run=core.newRun(17),hud=createHudState();run.gold=100;
for(const kind of ['Tank','Tank','Ranger','Caster','Tank','Genie']){run.shop=[kind,null,null,null,null];assert(core.recruit(run,0));}
const unit=run.team[0];hud.selected=unit.uid;assert.equal(unit.star,2);
assert(core.equipItem(run,unit.uid,'blade'));assert(core.equipItem(run,unit.uid,'heart'));
assert(core.movePiece(run,unit.uid,{type:'field',cell:0}));
assert(core.reservePiece(run,run.team[1].uid));core.rollShop(run);run.locked=true;hud.quality=hud.font=1;
unit.id=900;unit.body=8;run.replay={frames:['must not persist']};
const body=checkpointBody(run,hud),text=encodeCheckpoint(body,7),decoded=decodeCheckpoint(text);
assert(decoded);assert(text.length<4000);assert(!text.includes('"id":')&&!text.includes('body')&&!text.includes('replay'));
const restored=restoreCheckpoint(decoded);
assert.equal(JSON.stringify(checkpointBody(restored.run,restored.hud)),JSON.stringify(body));
assert(restored.run.team.every(u=>!('id' in u)&&!('body' in u)));
for(let i=0;i<20;i++){core.rollShop(run,true);core.rollShop(restored.run,true);assert.deepEqual(restored.run.shop,run.shop);}
for(const value of [null,undefined,'','{','{}',text.slice(0,-5),text.replace('Tank','Witch'),'x'.repeat(60001)])assert.equal(decodeCheckpoint(value),null);
assert.equal(newestCheckpoint([encodeCheckpoint(body,2),text]).sequence,7);
assert.equal(newestCheckpoint([text.slice(0,-2),encodeCheckpoint(body,2)]).sequence,2);
assert.equal(newestCheckpoint(['','garbage']),null);
const mutations=[
  d=>d.version=2,d=>d.run.gold=-1,d=>d.run.hp=101,d=>d.run.round=16,d=>d.run.rng=-1,
  d=>d.run.bench.pop(),d=>d.run.team.push(d.run.team[0]),d=>d.run.team[1].cell=d.run.team[0].cell,
  d=>d.run.bench[0].cell=999,
  d=>d.run.team[0].uid=d.run.nextId,d=>d.run.team[0].kind='Rat',d=>d.run.team[0].star=4,
  d=>d.run.team[0].items=['invalid'],d=>d.run.team[0].items=Array(4).fill('blade'),
  d=>d.run.bag.tome=-1,d=>d.run.shop[0]='Serpent',d=>d.hud.selected=999,
  d=>d.hud.quality=2,d=>d.hud.font=-1,d=>d.hud.phase='settling',d=>d.hud.reward=true,
  d=>d.hud.phase='reward',d=>d.hud.phase='finished',d=>d.run.hp=0,
];
for(const mutate of mutations){const bad=structuredClone(body);mutate(bad);assert.equal(decodeCheckpoint(encodeCheckpoint(bad,8)),null);}
assert.equal(decodeCheckpoint(encodeCheckpoint(body,0)),null);
hud.phase='combat';const interrupted=checkpointBody(run,hud),resumed=restoreCheckpoint(decodeCheckpoint(encodeCheckpoint(interrupted,8)));
assert.equal(resumed.hud.phase,'prepare');assert.equal(resumed.run.gold,run.gold);assert.equal(resumed.run.round,run.round);
run.round=2;run.wins=2;run.streak=2;hud.phase='reward';hud.reward=true;
const prize=decodeCheckpoint(encodeCheckpoint(checkpointBody(run,hud),9));assert(prize);assert(restoreCheckpoint(prize).hud.reward);
run.round=15;run.wins=15;run.streak=15;hud.reward=false;hud.phase='finished';
assert.equal(decodeCheckpoint(encodeCheckpoint(checkpointBody(run,hud),10)).hud.phase,'finished');
// Current payload remains bounded even at maximum field/reserve/item capacity.
const full=core.newRun();full.round=10;full.wins=5;full.gold=999;
full.team=core.PLAYABLE.slice(0,6).map((kind,i)=>({uid:i+1,kind,star:3,items:['blade','heart','tome']}));
full.bench=Array.from({length:8},(_,i)=>({uid:i+7,kind:core.PLAYABLE[i],star:3,items:['blade','heart','tome']}));full.nextId=15;core.normalizeFormation(full.team);
const max=encodeCheckpoint(checkpointBody(full,createHudState()),100);assert(max.length<4000&&decodeCheckpoint(max));
console.log('PASS: local checkpoints, exact RNG, two-slot corruption fallback, schema/capacity/UID/cell/items validation, no native IDs/replay, combat rollback and pending reward, payload <4 KB.');
