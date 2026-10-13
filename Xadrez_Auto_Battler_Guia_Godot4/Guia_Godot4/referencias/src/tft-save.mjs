import { ROSTER, PLAYABLE, ITEMS, ENCOUNTERS, FIELD_LIMIT, BENCH_LIMIT, HOME_CELLS, makeRandom, normalizeFormation } from './tft-core.mjs';

export const SAVE_KEYS = ['xadrez_auto_battler_v1_a','xadrez_auto_battler_v1_b'];
const SAVE_MAX = 60000;
const integer = (n,lo,hi) => Number.isInteger(n) && n >= lo && n <= hi;
export function saveChecksum(text) {
  let hash=2166136261;
  for(let i=0;i<text.length;i++) hash=Math.imul(hash^text.charCodeAt(i),16777619);
  return (hash>>>0).toString(16).padStart(8,'0');
}
export function checkpointBody(run,hud) {
  const piece = u => u && ({uid:u.uid,kind:u.kind,star:u.star,items:[...(u.items||[])],...(Number.isInteger(u.cell)?{cell:u.cell}:{})});
  const ended = run.round >= ENCOUNTERS.length || run.hp<=0;
  return {version:1,run:{gold:run.gold,hp:run.hp,round:run.round,wins:run.wins,streak:run.streak,nextId:run.nextId,
    team:run.team.map(piece),bench:run.bench.map(piece),bag:{...run.bag},shop:[...run.shop],locked:run.locked,rng:run.random.getState()},
    hud:{selected:hud.selected,phase:ended?'finished':hud.reward?'reward':hud.phase==='combat'?'combat':'prepare',
      reward:!ended&&!!hud.reward,quality:hud.quality||0,font:hud.font||0}};
}
export function encodeCheckpoint(body, sequence) {
  const payload=JSON.stringify({...body,sequence});
  return JSON.stringify({payload,checksum:saveChecksum(payload)});
}
export function decodeCheckpoint(text) {
  try {
    if(typeof text!=='string'||!text||text.length>SAVE_MAX)return null;
    const envelope=JSON.parse(text);
    if(typeof envelope.payload!=='string'||saveChecksum(envelope.payload)!==envelope.checksum)return null;
    const data=JSON.parse(envelope.payload),r=data.run,h=data.hud;
    if(data.version!==1||!integer(data.sequence,1,Number.MAX_SAFE_INTEGER)||!r||!h)return null;
    if(!integer(r.gold,0,1e9)||!integer(r.hp,0,100)||!integer(r.round,0,15)||!integer(r.wins,0,r.round)||
      !integer(r.streak,-r.round,r.round)||!integer(r.nextId,1,1e9)||!integer(r.rng,0,0xffffffff)||typeof r.locked!=='boolean')return null;
    if(!Array.isArray(r.team)||r.team.length>FIELD_LIMIT||!Array.isArray(r.bench)||r.bench.length!==BENCH_LIMIT||
      !Array.isArray(r.shop)||r.shop.length!==5||r.shop.some(k=>k!==null&&!PLAYABLE.includes(k)))return null;
    if(!r.bag||Object.keys(r.bag).length!==Object.keys(ITEMS).length||Object.keys(ITEMS).some(k=>!integer(r.bag[k],0,1e6)))return null;
    const ids=new Set(),cells=new Set();
    for(const [field,list] of [[true,r.team],[false,r.bench]])for(const u of list){
      if(!u&&!field)continue;
      if(!u||!PLAYABLE.includes(u.kind)||!integer(u.uid,1,r.nextId-1)||ids.has(u.uid)||!integer(u.star,1,3)||
        !Array.isArray(u.items)||u.items.length>3||u.items.some(k=>!Object.keys(ITEMS).includes(k)))return null;
      ids.add(u.uid);
      if(field){if(!integer(u.cell,0,HOME_CELLS-1)||cells.has(u.cell))return null;cells.add(u.cell);}
      else if(u.cell!==undefined&&!integer(u.cell,0,HOME_CELLS-1))return null;
    }
    if(!['prepare','combat','reward','finished'].includes(h.phase)||typeof h.reward!=='boolean'||
      !integer(h.quality,0,1)||!integer(h.font,0,1)||(h.selected!==null&&!ids.has(h.selected)))return null;
    if(h.reward!==(h.phase==='reward')||(h.reward&&(!r.round||!r.wins||r.streak<=0||ENCOUNTERS[r.round-1].kind!=='mobs'))||
      (h.phase==='combat'&&(!r.team.length||!r.hp||r.round>=15))||
      ((r.hp===0||r.round===15)!==(h.phase==='finished')))return null;
    return data;
  } catch {return null;}
}
export function newestCheckpoint(slots) {
  return slots.map(decodeCheckpoint).filter(Boolean).sort((a,b)=>b.sequence-a.sequence)[0]||null;
}
export function restoreCheckpoint(data) {
  // Only whitelisted piece/state fields survive. Native entity IDs and replay
  // buffers are reconstructed; interrupted battles resume before settlement.
  const r=data.run,h=data.hud;
  const piece=u=>u&&({uid:u.uid,kind:u.kind,star:u.star,items:[...u.items],...(Number.isInteger(u.cell)?{cell:u.cell}:{})});
  const run={gold:r.gold,hp:r.hp,round:r.round,wins:r.wins,streak:r.streak,nextId:r.nextId,
    team:r.team.map(piece),bench:r.bench.map(piece),bag:{...r.bag},shop:[...r.shop],locked:r.locked,random:makeRandom(r.rng)};
  normalizeFormation(run.team);
  return {run,hud:{selected:h.selected,phase:h.phase==='combat'?'prepare':h.phase,reward:h.reward,quality:h.quality,font:h.font,
    menu:null,exiting:false,saveSequence:data.sequence,saveStatus:'saved',
    notice:h.phase==='combat'?'Confronto retomado na preparação':'Partida retomada'}};
}
