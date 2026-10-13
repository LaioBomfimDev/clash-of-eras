import assert from 'node:assert/strict';
import {newRun, ROSTER, PLAYABLE, cellPosition, cellDistance, normalizeFormation, movePiece, simulate, sellValue} from '../src/tft-core.mjs';
import {createHudState, hudOptions, actHud} from '../src/tft-hud.mjs';

const run = newRun(), hud = createHudState(); run.gold = 100;
run.team = ['Tank','Ranger','Caster','Ninja','David','Genie'].map((kind,i)=>({kind,uid:i+1,star:1,items:[],x:0,y:-300}));
normalizeFormation(run.team);
assert.equal(new Set(run.team.map(u=>u.cell)).size,6,'Repeated spawn positions are separated');
run.bench[0] = {kind:'Witch',uid:20,star:2,items:['heart']};
const tank = run.team[0], ranger = run.team[1], tankCell=tank.cell, rangerCell=ranger.cell;
assert(movePiece(run,tank.uid,{type:'field',cell:rangerCell}));
assert.equal(ranger.cell,tankCell); assert.equal(tank.cell,rangerCell);
assert(movePiece(run,20,{type:'field',cell:tank.cell}));
assert.equal(run.team.length,6); assert.equal(run.bench[0],tank);
assert.equal(run.team.find(u=>u.uid===20).cell,rangerCell);
assert(movePiece(run,20,{type:'bench',slot:0}));
assert.equal(run.bench[0].uid,20); assert.equal(run.team.find(u=>u.uid===tank.uid).cell,rangerCell);
assert(movePiece(run,20,{type:'bench',slot:7})); assert.equal(run.bench[7].uid,20);
const snapshot=JSON.stringify(run);
assert.equal(movePiece(run,20,{type:'bench',slot:7}),false,'Same-slot drop is a no-op');
for(const target of [{type:'field',cell:28},{type:'field',cell:1.5},{type:'bench',slot:8},{type:'bench',slot:-1},{type:'field',cell:NaN}])assert.equal(movePiece(run,20,target),false);
assert.equal(JSON.stringify(run),snapshot,'Invalid/full drops are atomic');
const broken = {...run,team:run.team.map(u=>({...u,cell:0})),bench:run.bench.slice()};
const brokenSnapshot=JSON.stringify(broken);
assert.equal(movePiece(broken,20,{type:'field',cell:27}),false);
assert.equal(JSON.stringify(broken),brokenSnapshot,'Rejected full-board drop never mutates an inconsistent formation');
actHud(run,hud,115); assert.equal(hud.selected,20,'Drag selection never swaps an earlier selection');
assert(hudOptions(run,hud)[32].label.includes('ARRASTE'));
const gold=run.gold, heart=run.bag.heart, refund=sellValue(run.bench[7]);
assert(actHud(run,hud,130).changed);assert.equal(run.gold,gold+refund);assert.equal(run.bag.heart,heart+1);
assert.equal(actHud(run,hud,130).changed,false,'A sale is paid once');
actHud(run,hud,116); const beforeCombat=JSON.stringify(run);hud.phase='combat';
for(const id of [51,78,108,116,122,130,32])assert.equal(actHud(run,hud,id).changed,false);
assert.equal(JSON.stringify(run),beforeCombat);
assert.equal(ROSTER.Tank.tiles,1);assert.equal(ROSTER.Caster.tiles,2);assert.equal(ROSTER.Ranger.tiles,Infinity);

let steps=0,attacks=0,jumps=0,deaths=0;
export function audit(sim) {
  const occupied=new Map(), reserved=new Map(), units=new Map();
  for(const frame of sim.frames) {
    for(const e of frame.events) {
      const u=units.get(e.id);
      if(e.type==='spawn') {const s=e.unit;assert(!occupied.has(s.cell),'Unique spawn square');occupied.set(s.cell,s.id);units.set(s.id,{cell:s.cell,x:s.x,y:s.y,alive:true});}
      if(e.type==='step') {
        assert.equal(u.cell,e.from);assert(!occupied.has(e.to)&&!reserved.has(e.to),'Destination must be vacant and not reserved');
        assert.equal(Math.abs(e.from%7-e.to%7)+Math.abs(Math.floor(e.from/7)-Math.floor(e.to/7)),1,'One orthogonal step');
        reserved.set(e.to,e.id);u.to=e.to;steps++;
      }
      if(e.type==='arrive') {assert.equal(reserved.get(e.cell),e.id);occupied.delete(u.cell);reserved.delete(e.cell);assert(!occupied.has(e.cell));occupied.set(e.cell,e.id);u.cell=e.cell;delete u.to;}
      if(e.type==='move') {assert(u.alive&&u.to!==undefined);u.x=e.x;u.y=e.y;}
      if(e.type==='blink') {assert(!occupied.has(e.cell)&&!reserved.has(e.cell),'Assassin lands on a free square');occupied.delete(u.cell);occupied.set(e.cell,e.id);u.cell=e.cell;u.x=e.x;u.y=e.y;jumps++;}
      if(e.type==='attack') {assert(u.to===undefined,'No attacking while walking');assert(cellDistance(e.cell,e.targetCell)<=e.range,'Attack is within declared range');assert.equal(u.cell,e.cell);attacks++;}
      if(e.type==='death') {assert(u.alive);occupied.delete(u.cell);if(u.to!==undefined)reserved.delete(u.to);u.alive=false;deaths++;}
    }
    const alive=[...units.values()].filter(u=>u.alive);
    for(let i=0;i<alive.length;i++)for(let j=i+1;j<alive.length;j++)assert(Math.hypot(alive[i].x-alive[j].x,alive[i].y-alive[j].y)>=139,'Models never collapse into a cluster');
    assert.equal(occupied.size,alive.length,'Every living unit owns exactly one square');
  }
}
for(let seed=0;seed<60;seed++) {
  const left=Array.from({length:6},(_,i)=>({kind:PLAYABLE[(seed+i)%12],id:i+1,star:seed%3+1,x:0,y:-300,items:i===0?['blade']:[]}));
  const right=Array.from({length:6},(_,i)=>({kind:PLAYABLE[(seed*3+i)%12],id:i+100,star:(seed+1)%3+1,x:0,y:-300,items:[]}));
  const before=JSON.stringify([left,right]),sim=simulate(left,right);audit(sim);
  assert.equal(JSON.stringify([left,right]),before,'Combat preserves persistent formation');
  assert(sim.duration<98&&sim.frames.length>30);
  if(seed<3)assert.deepEqual(simulate(left,right),sim,'Deterministic grid and arbitration');
}
assert(steps>0&&attacks>0&&jumps>0&&deaths>0);
console.log(`PASS: atomic drag/swap/sale, 8 bench slots, range 1/2/infinity; 60 crowded combats, ${steps} exclusive steps, ${attacks} attacks, ${jumps} safe jumps, ${deaths} released squares. Game never opened.`);
