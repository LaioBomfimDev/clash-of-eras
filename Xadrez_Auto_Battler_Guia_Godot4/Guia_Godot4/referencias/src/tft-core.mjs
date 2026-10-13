// Xadrez Auto Battler v0.10. Exclusive squares; checkpointable RNG and audited rules.
export const ROSTER = {
  Tank: { role: 'tank', label: 'Sumô', hero: 'Tank', hp: 80, damage: 1, range: 165, period: 2.6, armor: 0, traits: ['guardian'], skill: 'fortify', skillName: 'Fôlego: recupera vida e reduz dano' },
  Ranger: { role: 'dps', label: 'Mosqueteiro', hero: 'Ranger', hp: 50, damage: 1, range: 760, period: 2.3, armor: 0, traits: ['marksman'], skill: 'volley', skillName: 'Rajada: acerta até 3 alvos' },
  Caster: { role: 'dps', label: 'Arcanista', hero: 'Caster', hp: 50, damage: 1, range: 650, period: 2.3, armor: 0, traits: ['mystic'], skill: 'nova', skillName: 'Nova: explosão em área' },
  Assassin: { role: 'dps', label: 'Duelista', hero: 'Assassin', hp: 50, damage: 1, range: 170, period: 2.3, armor: 0, traits: ['assassin'], skill: 'execute', skillName: 'Execução: golpe forte em alvo ferido' },
  Gorilla: { role: 'tank', label: 'Gorila', body: 'TankGorilla', hp: 80, damage: 1, range: 185, period: 2.6, armor: 0, traits: ['guardian', 'wild'], skill: 'slam', skillName: 'Impacto: dano em área e atordoamento' },
  Cowboy: { role: 'dps', label: 'Pistoleiro', body: 'RangerCowboy', hp: 50, damage: 1, range: 820, period: 2.3, armor: 0, traits: ['marksman'], skill: 'aimed', skillName: 'Tiro preciso: alto dano à distância' },
  Witch: { role: 'dps', label: 'Bruxa', body: 'CasterWitch', hp: 50, damage: 1, range: 650, period: 2.3, armor: 0, traits: ['mystic'], skill: 'drain', skillName: 'Drenagem: dano e recuperação de vida' },
  Ninja: { role: 'dps', label: 'Ninja', body: 'AssassinNinja', hp: 50, damage: 1, range: 170, period: 2, armor: 0, traits: ['assassin'], skill: 'execute', skillName: 'Emboscada: salta para a retaguarda' },
  Genie: { role: 'healer', label: 'Gênio', body: 'OilLampGenie', hp: 50, damage: 1, range: 600, period: 2.4, armor: 0, traits: ['mystic', 'ancient'], skill: 'mend', skillName: 'Curandeiro: cura aliados; Desejo cura até 2' },
  RatKing: { role: 'dps', label: 'Rei dos Ratos', body: 'PlagueDoctorMaskRatKing', hp: 50, damage: 1, range: 430, period: 2.3, armor: 0, traits: ['wild'], skill: 'plague', skillName: 'Praga: envenena até 3 inimigos' },
  Cobra: { role: 'dps', label: 'Cobra Real', body: 'CleopatraCobra', hp: 50, damage: 1, range: 420, period: 2.3, armor: 0, traits: ['wild', 'ancient'], skill: 'venom', skillName: 'Veneno: dano contínuo por 3 segundos' },
  David: { role: 'tank', label: 'Davi de Pedra', body: 'StatueOfDavid', hp: 80, damage: 1, range: 180, period: 2.6, armor: 0, traits: ['guardian', 'ancient'], skill: 'stone', skillName: 'Pele de pedra: reduz dano e recupera vida' },
  Rat: { role: 'mob', label: 'Rato', body: 'PlagueDoctorCloakRatBaby', cost: 0, hp: 20, damage: 1, range: 135, period: 2.3, armor: 0, traits: [], skill: 'aimed', skillName: 'Mordida' },
  Serpent: { role: 'mob', label: 'Serpente', body: 'CleopatraCobra', cost: 0, hp: 30, damage: 1, range: 380, period: 2.3, armor: 0, traits: [], skill: 'venom', skillName: 'Veneno' }
};
export const PLAYABLE = Object.keys(ROSTER).filter(key => ROSTER[key].role !== 'mob');
export const FIELD_LIMIT = 6;
export const BENCH_LIMIT = 8;
export const SHOP_REFRESH_COST = 2;
export const GRID_COLS = 7, GRID_ROWS = 8, CELL_SIZE = 280, HOME_CELLS = 28;
export const GRID_CELLS = GRID_COLS * GRID_ROWS;
const CELL_POSITIONS = Array.from({length:GRID_CELLS}, (_,cell) => ({x:(cell%7-3)*CELL_SIZE,y:(Math.floor(cell/7)-3.5)*CELL_SIZE}));
const NEIGHBORS = Array.from({length:GRID_CELLS}, (_,cell) => {
  const col=cell%7,row=Math.floor(cell/7), cells=[];
  if(col>0)cells.push(cell-1);if(col<6)cells.push(cell+1);
  if(row>0)cells.push(cell-7);if(row<7)cells.push(cell+7);
  return cells;
});
// Distance follows square chess boards: diagonals count as one square.
const TILE_RANGES = { Tank: 1, Assassin: 1, Gorilla: 1, Ninja: 1, David: 1, Rat: 1,
  Caster: 2, Witch: 2, RatKing: 2, Cobra: 2, Serpent: 2, Ranger: Infinity, Cowboy: Infinity, Genie: Infinity };
for (const [kind, range] of Object.entries(TILE_RANGES)) ROSTER[kind].tiles = range;
export const rangeLabel = kind => ROSTER[kind].tiles === Infinity ? '∞ CAMPO INTEIRO' : `${ROSTER[kind].tiles} ${ROSTER[kind].tiles === 1 ? 'CASA' : 'CASAS'}`;
export function cellPosition(cell) { return { x: (cell % GRID_COLS - 3) * CELL_SIZE, y: (Math.floor(cell / GRID_COLS) - 3.5) * CELL_SIZE }; }
export function nearestCell(x, y, home = false) {
  const col = Math.max(0, Math.min(6, Math.round(x / CELL_SIZE + 3)));
  const row = Math.max(0, Math.min(home ? 3 : 7, Math.round(y / CELL_SIZE + 3.5)));
  return row * GRID_COLS + col;
}
export function cellDistance(a, b) { return Math.max(Math.abs(a % 7 - b % 7), Math.abs(Math.floor(a / 7) - Math.floor(b / 7))); }
export function normalizeFormation(team) {
  const occupied = new Set();
  for (const unit of team) {
    let cell = Number.isInteger(unit.cell) && unit.cell >= 0 && unit.cell < HOME_CELLS ? unit.cell :
      Number.isFinite(unit.x) && Number.isFinite(unit.y) ? nearestCell(unit.x, unit.y, true) :
      (ROSTER[unit.kind].tiles === 1 ? 21 : 7) + 3;
    if (occupied.has(cell)) cell = Array.from({length: HOME_CELLS}, (_,i) => i).filter(c => !occupied.has(c)).sort((a,b) => cellDistance(a,cell)-cellDistance(b,cell) || Math.abs(a%7-3)-Math.abs(b%7-3) || b-a)[0];
    if (cell === undefined) throw new Error('Formation exceeds available squares');
    occupied.add(cell); unit.cell = cell; Object.assign(unit, cellPosition(cell));
  }
  return team;
}
// One atomic transaction: placement, bench reorder/swap or sale. No stale UID
// can sell a replacement, and an invalid drop never changes gold/items/pieces.
export function movePiece(run, uid, destination) {
  const unit = findPiece(run, uid); if (!unit || !destination) return false;
  const field = run.team.indexOf(unit), bench = run.bench.indexOf(unit);
  if (destination.type === 'sell') return sell(run, uid);
  if (destination.type === 'bench') {
    const slot = destination.slot;
    if (!Number.isInteger(slot) || slot < 0 || slot >= BENCH_LIMIT) return false;
    if (bench === slot) return false;
    const other = run.bench[slot];
    if (bench >= 0) [run.bench[bench], run.bench[slot]] = [other, unit];
    else if (other) {
      other.cell = unit.cell; Object.assign(other, cellPosition(unit.cell));
      run.team[field] = other; run.bench[slot] = unit;
    } else { run.team.splice(field, 1); run.bench[slot] = unit; }
    return true;
  }
  const cell = destination.cell;
  if (destination.type !== 'field' || !Number.isInteger(cell) || cell < 0 || cell >= HOME_CELLS) return false;
  // Validate against a normalized copy before committing. Rejected drops must
  // not repair/mutate an inconsistent formation as an accidental side effect.
  const formation = normalizeFormation(run.team.map(u=>({...u})));
  if (field < 0 && run.team.length >= FIELD_LIMIT && !formation.some(u=>u.cell===cell)) return false;
  if (field >= 0 && formation[field].cell === cell) return false;
  for (let i=0;i<run.team.length;i++) Object.assign(run.team[i], {cell:formation[i].cell,x:formation[i].x,y:formation[i].y});
  const other = run.team.find(u => u.cell === cell && u !== unit);
  if (other) {
    if (field >= 0) { other.cell = unit.cell; Object.assign(other, cellPosition(other.cell)); }
    else { run.team[run.team.indexOf(other)] = unit; run.bench[bench] = other; }
  } else if (field < 0) { run.team.push(unit); run.bench[bench] = null; }
  unit.cell = cell; Object.assign(unit, cellPosition(cell)); return true;
}
export const RARITIES = {
  normal: { label: 'Normal', cost: 1, color: '#bcc6cc', kinds: ['Tank', 'Ranger', 'Caster', 'Assassin'] },
  rare: { label: 'Raro', cost: 3, color: '#79c4ff', kinds: ['Gorilla', 'Cowboy', 'Witch', 'Ninja', 'Cobra'] },
  epic: { label: 'Épico', cost: 5, color: '#d99bff', kinds: ['Genie', 'RatKing', 'David'] }
};
for (const [rarity, rule] of Object.entries(RARITIES)) for (const kind of rule.kinds) {
  ROSTER[kind].rarity = rarity; ROSTER[kind].cost = rule.cost;
}
const SHOP_ODDS = [
  { normal: 75, rare: 25, epic: 0 },
  { normal: 55, rare: 35, epic: 10 },
  { normal: 30, rare: 50, epic: 20 }
];
export function shopOdds(round) { return SHOP_ODDS[Math.max(0, Math.min(2, Math.floor(round / 5)))]; }
export function interestIncome(gold) { return Math.max(0, Math.floor(gold / 10)); }
export function copyValue(unit) { return 3 ** ((unit.star || 1) - 1); }
export function fusionCount(run, unit) {
  return run.team.concat(run.bench.filter(Boolean)).filter(u => u.kind === unit.kind && u.star === unit.star).length;
}
function generateShop(run, initial = false) {
  const offers = [], counts = {};
  const add = kind => { offers.push(kind); counts[kind] = (counts[kind] || 0) + 1; };
  if (initial) {
    add('Tank');
    const damage = ['Ranger', 'Caster', 'Assassin'];
    for (let i = 0; i < 2; i++) add(damage.splice(Math.floor(run.random() * damage.length), 1)[0]);
  }
  const odds = shopOdds(run.round);
  while (offers.length < 5) {
    const roll = run.random() * 100;
    const rarity = roll < odds.normal ? 'normal' : roll < odds.normal + odds.rare ? 'rare' : 'epic';
    const available = RARITIES[rarity].kinds.filter(kind => (counts[kind] || 0) < 2);
    add(available[Math.floor(run.random() * available.length)]);
  }
  return offers;
}
export const ITEMS = {
  blade: { label: 'Lâmina', detail: '+1 ataque', damage: 1 },
  heart: { label: 'Couraça', detail: '+10 vida', hp: 10 },
  tome: { label: 'Tomo', detail: '+2 de cura', healing: 2 }
};
export const TRAITS = {
  guardian: { label: 'Guardiões', thresholds: [2, 3], bonus: ['+18% vida da equipe', '+30% vida da equipe'] },
  marksman: { label: 'Atiradores', thresholds: [2], bonus: ['Atiradores: intervalo de ataque -25%'] },
  mystic: { label: 'Místicos', thresholds: [2, 3], bonus: ['+25% poder das habilidades', '+50% poder das habilidades'] },
  assassin: { label: 'Assassinos', thresholds: [2], bonus: ['Execução: +0,5x multiplicador e salto inicial'] },
  wild: { label: 'Selvagens', thresholds: [2, 3], bonus: ['Selvagens: curam 12% do dano', 'Selvagens: curam 22% do dano'] },
  ancient: { label: 'Ancestrais', thresholds: [2, 3], bonus: ['+15 armadura para a equipe', '+30 armadura para a equipe'] }
};
const TEAM_SETS = [
  ['Tank', 'Ranger'], ['Tank', 'Witch', 'Assassin'], ['Tank', 'Cowboy', 'Caster', 'Assassin'],
  ['Gorilla', 'Tank', 'Ranger', 'Cowboy'], ['Gorilla', 'RatKing', 'Cobra', 'Witch', 'Tank'], ['David', 'Genie', 'Caster', 'Witch', 'Ranger'],
  ['Gorilla', 'David', 'Tank', 'Cowboy', 'Ranger', 'Genie'], ['Ninja', 'Assassin', 'Witch', 'Caster', 'Genie', 'Tank'], ['David', 'Gorilla', 'Genie', 'RatKing', 'Cobra', 'Cowboy']
];
export const ENCOUNTERS = Array.from({ length: 15 }, (_, index) => {
  const chapter = Math.floor(index / 5), slot = index % 5, mobs = slot === 1 || slot === 3;
  return { label: mobs ? `${chapter + 1}-${slot + 1} • ${slot === 1 ? 'Ninho de ratos' : 'Covil das serpentes'}` : `${chapter + 1}-${slot + 1} • ${index === 14 ? 'Guardiões finais' : 'Equipe rival'}`,
    kind: mobs ? 'mobs' : 'team', chapter, units: mobs ? (slot === 1 ? Array(3 + chapter).fill('Rat') : ['Serpent', 'Serpent', ...Array(1 + chapter).fill('Rat')]) : TEAM_SETS[chapter * 3 + (slot === 0 ? 0 : slot === 2 ? 1 : 2)] };
});
export function makeRandom(seed) {
  let value = seed >>> 0;
  const random = () => { value = (Math.imul(value, 1664525) + 1013904223) >>> 0; return value / 4294967296; };
  random.getState = () => value;
  return random;
}
export function newRun(seed = 17) {
  const run = { gold: 12, hp: 100, round: 0, wins: 0, streak: 0, team: [], bench: Array(BENCH_LIMIT).fill(null), bag: { blade: 1, heart: 1, tome: 0 }, nextId: 1, shop: [], locked: false, random: makeRandom(seed) };
  run.shop = generateShop(run, true);
  return run;
}
export function rollShop(run, free = false) {
  if (!free && run.gold < SHOP_REFRESH_COST) return false;
  if (!free) run.gold -= SHOP_REFRESH_COST;
  run.shop = generateShop(run);
  return true;
}
export function canRecruit(run, index) {
  if (!Number.isInteger(index) || index < 0 || index >= 5) return false;
  const kind = run.shop[index], def = ROSTER[kind];
  return !!def && def.cost > 0 && run.gold >= def.cost && (hasRoom(run) ||
    run.team.concat(run.bench.filter(Boolean)).filter(u => u.kind === kind && u.star === 1).length >= 2);
}
function removePiece(run, unit) {
  const field = run.team.indexOf(unit), bench = run.bench.indexOf(unit);
  if (field >= 0) run.team.splice(field, 1);
  else if (bench >= 0) run.bench[bench] = null;
}
function mergePurchased(run, purchased, preferredUid) {
  let piece = purchased;
  const merges = [];
  for (let star = 1; star < 3; star++) {
    const matches = run.team.concat(run.bench.filter(Boolean)).filter(u => u !== piece && u.kind === piece.kind && u.star === star);
    if (matches.length < 2) break;
    const group = [piece, ...matches], field = group.filter(u => run.team.includes(u));
    const anchor = field.find(u => u.uid === preferredUid) || field[0] ||
      matches.find(u => u.uid === preferredUid) || matches[0];
    const donors = anchor === piece ? matches.slice(0, 2) : [piece, matches.find(u => u !== anchor)];
    anchor.items ??= [];
    for (const donor of donors) {
      for (const item of donor.items || []) {
        if (anchor.items.length < 3) anchor.items.push(item);
        else run.bag[item] = (run.bag[item] || 0) + 1;
      }
      donor.items = []; removePiece(run, donor);
    }
    anchor.star = star + 1;
    merges.push({ uid: anchor.uid, kind: anchor.kind, star: anchor.star, consumed: donors.map(u => u.uid) });
    piece = anchor;
  }
  return { piece, merges };
}
const fieldState = run => run.team.map(u => `${u.uid}:${u.star}:${(u.items || []).join(',')}`).join(';');
export function recruit(run, index, preferredUid) {
  if (!canRecruit(run, index)) return false;
  const kind = run.shop[index], before = fieldState(run);
  run.gold -= ROSTER[kind].cost;
  const unit = { uid: run.nextId++, kind, star: 1, items: [] };
  const { piece, merges } = mergePurchased(run, unit, preferredUid);
  if (!merges.length) {
    if (run.team.length < FIELD_LIMIT) run.team.push(unit);
    else run.bench[run.bench.indexOf(null)] = unit;
  }
  normalizeFormation(run.team);
  run.shop[index] = null;
  run.lastRecruit = { uid: piece.uid, kind, merges, board: before !== fieldState(run) };
  return true;
}
export function sellValue(unit) { return ROSTER[unit.kind].cost * copyValue(unit); }
export function hasRoom(run) { return run.team.length < FIELD_LIMIT || run.bench.includes(null); }
export function findPiece(run, uid) { return run.team.find(u => u.uid === uid) || run.bench.find(u => u?.uid === uid); }
export function reservePiece(run, uid) {
  const from = run.team.findIndex(u => u.uid === uid), slot = run.bench.indexOf(null);
  if (from < 0 || slot < 0) return false;
  run.bench[slot] = run.team.splice(from, 1)[0];
  return true;
}
export function deployPiece(run, slot, swapUid) {
  if (!Number.isInteger(slot) || slot < 0 || slot >= BENCH_LIMIT || !run.bench[slot]) return false;
  if (swapUid !== undefined) {
    const index = run.team.findIndex(u => u.uid === swapUid);
    if (index < 0) return false;
    // A replacement takes the selected field position, including dragged units.
    run.bench[slot].cell = run.team[index].cell;
    run.bench[slot].x = run.team[index].x;
    run.bench[slot].y = run.team[index].y;
    [run.team[index], run.bench[slot]] = [run.bench[slot], run.team[index]];
  } else {
    if (run.team.length >= FIELD_LIMIT) return false;
    run.bench[slot].cell = undefined; run.bench[slot].x = undefined; run.bench[slot].y = undefined;
    run.team.push(run.bench[slot]); run.bench[slot] = null;
  }
  normalizeFormation(run.team);
  return true;
}
export function equipItem(run, uid, item) {
  const unit = findPiece(run, uid);
  if (!unit || !ITEMS[item] || !(run.bag[item] > 0) || (unit.items?.length || 0) >= 3) return false;
  unit.items ??= []; unit.items.push(item); run.bag[item]--;
  return true;
}
export function unequipItems(run, uid) {
  const unit = findPiece(run, uid);
  if (!unit) return false;
  for (const item of unit.items || []) run.bag[item] = (run.bag[item] || 0) + 1;
  unit.items = [];
  return true;
}
export function grantItem(run, item) {
  if (!ITEMS[item]) return false;
  run.bag[item] = (run.bag[item] || 0) + 1; return true;
}
export function sell(run, uid) {
  const unit = findPiece(run, uid);
  if (!unit) return false;
  unequipItems(run, uid);
  const index = run.team.findIndex(u => u.uid === uid);
  if (index >= 0) run.team.splice(index, 1);
  else run.bench[run.bench.findIndex(u => u?.uid === uid)] = null;
  run.gold += sellValue(unit);
  return true;
}
export function synergies(team) {
  const counts = Object.fromEntries(Object.keys(TRAITS).map(key => [key, 0]));
  for (const kind of new Set(team.map(unit => unit.kind))) for (const trait of ROSTER[kind].traits) counts[trait]++;
  return Object.fromEntries(Object.entries(TRAITS).map(([key, rule]) => [key, { count: counts[key], level: rule.thresholds.filter(t => counts[key] >= t).length }]));
}
export function stats(unit, team, syn = synergies(team)) {
  const base = ROSTER[unit.kind], star = unit.star || 1;
  const equipment = { hp: 0, damage: 0, healing: 0 };
  for (const key of unit.items || []) {
    const item = ITEMS[key];
    equipment.hp += item?.hp || 0; equipment.damage += item?.damage || 0; equipment.healing += item?.healing || 0;
  }
  return { ...base, hp: Math.round((base.hp * [1, 1.5, 2][star - 1] * (unit.power || 1) + equipment.hp) * [1, 1.18, 1.3][syn.guardian.level]),
    damage: [1, 2, 4][star - 1] + equipment.damage,
    healing: star + equipment.healing,
    armor: base.armor + syn.ancient.level * 15,
    period: base.period * (syn.marksman.level && base.traits.includes('marksman') ? 0.75 : 1),
    spell: 1 + syn.mystic.level * 0.25, speed: base.traits.includes('assassin') ? 290 : 220,
    executeBonus: syn.assassin.level ? 0.5 : 0,
    lifesteal: base.traits.includes('wild') ? [0, 0.12, 0.22][syn.wild.level] : 0,
    jump: base.traits.includes('assassin') && (syn.assassin.level > 0 || unit.kind === 'Ninja') };
}
export function enemyTeam(round) {
  const encounter = ENCOUNTERS[round];
  return encounter.units.map((kind, i) => ({ kind, uid: 100 + i, star: encounter.kind === 'mobs' ? 1 : round >= 10 ? 2 : round >= 5 && i < 2 ? 2 : 1,
    power: encounter.kind === 'mobs' ? 1 + encounter.chapter * 0.4 : 1,
    items: encounter.kind === 'team' && round >= 5 && i < encounter.chapter ? [i === 0 ? 'heart' : 'blade'] : [],
    x: (i % 3 - 1) * 360, y: ROSTER[kind].range > 300 ? -880 + (i % 2) * 60 : -330 - Math.floor(i / 3) * 230 }));
}
export function settleRound(run, won, survivors = 0) {
  if (run.round >= ENCOUNTERS.length || run.hp <= 0) throw new Error('Partida encerrada');
  const encounter = ENCOUNTERS[run.round], interest = interestIncome(run.gold);
  run.streak = won ? Math.max(0, run.streak) + 1 : Math.min(0, run.streak) - 1;
  const streakGold = Math.min(3, Math.floor(Math.abs(run.streak) / 2));
  const gold = 5 + interest + streakGold + (won ? 1 : 0) + (won && encounter.kind === 'mobs' ? 3 : 0);
  const lostHp = won ? 0 : encounter.kind === 'mobs' ? 6 + encounter.chapter * 2 : 8 + encounter.chapter * 3 + Math.min(6, survivors);
  run.gold += gold;
  if (won) run.wins++;
  run.hp = Math.max(0, run.hp - lostHp);
  const reward = won && encounter.kind === 'mobs';
  run.round++;
  if (!run.locked && run.round < ENCOUNTERS.length && run.hp > 0) rollShop(run, true);
  const payout = { gold, reward, interest, streakGold, lostHp };
  run.lastPayout = payout;
  return payout;
}
export function simulate(left, right) {
  if (!left.length || !right.length) throw new Error('As duas equipes precisam de unidades');
  const dt = 0.033;
  const teams = [left, right].map(team => normalizeFormation(team.map(u => ({...u})))), bonuses = teams.map(synergies);
  const units = teams.flatMap((team, side) => team.map((u, i) => {
    const st = stats(u, team, bonuses[side]);
    return { ...u, ...st, side, health: st.hp, mana: 0, cooldown: 1 + i * 0.1, stunnedUntil: 0, protectedUntil: 0, lifeBank: 0,
      target: undefined, jumped: false, moving: null, navigationAt: 0, cell: side === 0 ? u.cell : (7 - Math.floor(u.cell / 7)) * 7 + u.cell % 7, x: u.x, y: u.y * (side === 0 ? 1 : -1) };
  }));
  const byId = new Map(units.map(u => [u.id, u]));
  if (byId.size !== units.length || units.some(u => !Number.isInteger(u.id))) throw new Error('Combat unit IDs must be unique integers');
  const sides = [units.slice(0, left.length), units.slice(left.length)], reverseOrder = [...units].reverse();
  const frames = [{ events: units.map(unit => ({ type: 'spawn', unit: { ...unit } })) }];
  const pending = [];
  let winner = null, time = 0;
  const distance = (a, b) => cellDistance(a.cell, b.cell);
  const occupied = new Map(units.map(u => [u.cell, u.id]));
  const reserved = new Map();
  const free = cell => !occupied.has(cell) && !reserved.has(cell);
  // Per-combat BFS scratch buffers replace a Map/queue per navigation attempt.
  const pathQueue = new Int16Array(GRID_CELLS), pathFirst = new Int16Array(GRID_CELLS);
  function pathToRange(unit, target) {
    pathFirst.fill(-1); pathFirst[unit.cell]=-2;pathQueue[0]=unit.cell;let length=1;
    for (let at = 0; at < length; at++) {
      const cell = pathQueue[at];
      if (cell !== unit.cell && cellDistance(cell, target.cell) <= unit.tiles) return pathFirst[cell];
      const next = NEIGHBORS[cell].slice().sort((a,b) => cellDistance(a,target.cell)-cellDistance(b,target.cell) || a-b);
      for (const step of next) if (free(step) && pathFirst[step] === -1) { pathFirst[step] = cell === unit.cell ? step : pathFirst[cell];pathQueue[length++]=step; }
    }
    return undefined;
  }
  const living = side => sides[side].filter(u => u.health > 0);
  function heal(unit, amount, events) {
    if (unit.health <= 0) return;
    const actual = Math.min(unit.hp - unit.health, Math.round(amount));
    if (actual > 0) { unit.health += actual; events.push({ type: 'heal', id: unit.id, health: unit.health, amount: actual }); }
  }
  function hit(source, target, amount, events, magic = false) {
    if (target.health <= 0) return 0;
    const armor = magic ? target.armor * 0.45 : target.armor;
    const damage = Math.min(target.health, Math.max(1, Math.round(amount * 100 / (100 + armor) * (target.protectedUntil > time ? 0.55 : 1))));
    target.health = Math.max(0, target.health - damage);
    target.mana = Math.min(100, target.mana + 4);
    events.push({ type: 'hit', id: target.id, health: target.health, damage, magic, mana: target.mana });
    if (target.health === 0) { occupied.delete(target.cell); if (target.moving) reserved.delete(target.moving.to); target.moving = null; events.push({ type: 'death', id: target.id }); }
    if (source.lifesteal) {
      source.lifeBank += damage * source.lifesteal;
      const healing = Math.floor(source.lifeBank);
      if (healing > 0) { source.lifeBank -= healing; heal(source, healing, events); }
    }
    return damage;
  }
  function resolve(action, events) {
    const source = byId.get(action.source), target = byId.get(action.target);
    if (action.dot) { if (target) hit(source, target, action.dot, events, true); return; }
    if (!source || source.health <= 0) return;
    if (!action.spell) {
      const patient = source.role === 'healer' ? living(source.side).filter(u => u.health < u.hp).sort((a,b) => a.health/a.hp - b.health/b.hp)[0] : undefined;
      if (patient) heal(patient, 1 + source.healing, events);
      else if (target) hit(source, target, source.damage, events);
      return;
    }
    const enemies = living(1 - source.side).sort((a, b) => distance(source, a) - distance(source, b));
    const focus = target?.health > 0 ? target : enemies[0];
    const power = source.damage * source.spell;
    if (source.skill === 'mend') {
      for (const ally of living(source.side).sort((a, b) => a.health / a.hp - b.health / b.hp).slice(0, 2)) heal(ally, (3 + source.healing) * source.spell, events);
    } else if (source.skill === 'fortify' || source.skill === 'stone') {
      heal(source, (2 + source.healing) * source.spell, events);
      source.protectedUntil = time + (source.skill === 'stone' ? 3 : 1.5);
      if (focus) hit(source, focus, power * 1.3, events);
    } else if (focus) {
      const victims = source.skill === 'volley' || source.skill === 'plague' ? enemies.filter(u => u.id === focus.id || distance(source,u) <= source.tiles).slice(0, 3)
        : source.skill === 'nova' ? enemies.filter(u => distance(focus, u) <= 1)
        : source.skill === 'slam' ? enemies.filter(u => distance(source, u) <= 1) : [focus];
      for (const victim of victims) {
        const multiplier = source.skill === 'execute' ? (victim.health / victim.hp < 0.5 ? 2.5 : 1.5) + source.executeBonus : source.skill === 'aimed' ? 2.5 : source.skill === 'volley' ? 1 : 1.5;
        const damage = hit(source, victim, power * multiplier, events, !['execute', 'aimed', 'volley', 'slam'].includes(source.skill));
        if (source.skill === 'drain') heal(source, damage * 0.8, events);
        if (source.skill === 'slam') victim.stunnedUntil = time + 0.8;
        if (source.skill === 'venom' || source.skill === 'plague') for (let i = 1; i <= 3; i++) pending.push({ at: time + i, source: source.id, target: victim.id, dot: Math.max(1, power * 0.25) });
      }
    }
  }
  for (let tick = 1; tick <= Math.ceil(95 / dt); tick++) {
    time = tick * dt;
    const events = [];
    for (let i = pending.length - 1; i >= 0; i--) if (pending[i].at <= time) resolve(pending.splice(i, 1)[0], events);
    const order = tick % 2 ? units : reverseOrder;
    for (const unit of order) {
      if (unit.health <= 0 || unit.stunnedUntil > time) continue;
      unit.cooldown -= dt;
      if (unit.moving) {
        const move = unit.moving, from = CELL_POSITIONS[unit.cell], to = CELL_POSITIONS[move.to];
        move.progress = Math.min(1, move.progress + dt * unit.speed / CELL_SIZE);
        unit.x = from.x + (to.x - from.x) * move.progress; unit.y = from.y + (to.y - from.y) * move.progress;
        events.push({ type: 'move', id: unit.id, x: unit.x, y: unit.y, angle: Math.atan2(to.y-from.y, to.x-from.x) });
        if (move.progress === 1) {
          occupied.delete(unit.cell); reserved.delete(move.to); occupied.set(move.to, unit.id);
          unit.cell = move.to; unit.moving = null;
          events.push({ type: 'arrive', id: unit.id, cell: unit.cell });
        }
        continue;
      }
      const opponents = sides[1-unit.side];
      let nearest, nearestDistance = Infinity;
      for (const candidate of opponents) {
        if (candidate.health <= 0) continue;
        const d = distance(unit,candidate);
        if (!nearest || d < nearestDistance || (d === nearestDistance && candidate.id < nearest.id)) {nearest = candidate; nearestDistance = d;}
      }
      if (!nearest) break;
      if (unit.jump && !unit.jumped && time >= 0.4) {
        const rear = opponents.filter(u=>u.health>0).sort((a,b) => b.tiles-a.tiles || distance(unit,b)-distance(unit,a) || a.id-b.id)[0];
        const landing = Array.from({length: GRID_CELLS}, (_,i)=>i).filter(c => free(c) && cellDistance(c,rear.cell) === 1)
          .sort((a,b) => (unit.side === 0 ? b-a : a-b))[0];
        unit.jumped = true;
        if (landing !== undefined) { occupied.delete(unit.cell); unit.cell = landing; occupied.set(landing,unit.id); Object.assign(unit,cellPosition(landing)); unit.target = rear.id; events.push({type:'blink',id:unit.id,x:unit.x,y:unit.y,cell:unit.cell}); }
      }
      let target = byId.get(unit.target);
      if (!target || target.health <= 0 || distance(unit,target) > unit.tiles) target = nearest;
      unit.target = target.id;
      if (distance(unit,target) > unit.tiles) {
        if (time < unit.navigationAt) continue;
        // If the closest foe is enclosed, route to another reachable foe.
        const enemies = opponents.filter(u=>u.health>0).sort((a,b)=>distance(unit,a)-distance(unit,b) || a.id-b.id);
        let step;
        for (const candidate of enemies) { step = pathToRange(unit,candidate); if (step !== undefined) { target = candidate; unit.target = target.id; break; } }
        if (step !== undefined) { reserved.set(step,unit.id); unit.moving = {to:step,progress:0}; events.push({type:'step',id:unit.id,from:unit.cell,to:step}); }
        else unit.navigationAt = time+0.2;
      } else if (unit.cooldown <= 0) {
        unit.cooldown = unit.period;
        const spell = unit.mana >= 100; unit.mana = spell ? 0 : Math.min(100, unit.mana+20);
        events.push({type:'attack',id:unit.id,target:target.id,cell:unit.cell,targetCell:target.cell,range:unit.tiles,spell,mana:unit.mana,angle:Math.atan2(target.y-unit.y,target.x-unit.x)});
        pending.push({at:time+(spell?0.65:0.5),source:unit.id,target:target.id,spell});
      }
    }
    if (time > 75 && tick % 60 === 0) for (const u of units) if (u.health > 0) hit({ lifesteal: 0 }, u, 1 + Math.floor((time - 75) / 5), events, true);
    frames.push({ events });
    const leftAlive = sides[0].some(u => u.health > 0), rightAlive = sides[1].some(u => u.health > 0);
    if (!leftAlive || !rightAlive) { winner = leftAlive ? 0 : rightAlive ? 1 : -1; break; }
  }
  if (winner === null) {
    const total = side => living(side).reduce((sum, u) => sum + u.health / u.hp, 0);
    winner = Math.abs(total(0) - total(1)) < 0.001 ? -1 : total(0) > total(1) ? 0 : 1;
  }
  const mainDuration = frames.length * dt;
  frames.push({ events: units.filter(u => u.side === winner && u.health > 0).map(u => ({ type: 'victory', id: u.id })) });
  for (let i = 0; i < 60; i++) frames.push({ events: [] });
  return { frames, winner, mainDuration, duration: frames.length * dt, survivors: [0, 1].map(side => living(side).length) };
}
