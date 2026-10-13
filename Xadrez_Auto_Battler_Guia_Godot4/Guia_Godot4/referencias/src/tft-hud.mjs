import { ROSTER, PLAYABLE, ITEMS, TRAITS, ENCOUNTERS, FIELD_LIMIT, BENCH_LIMIT, RARITIES, SHOP_REFRESH_COST, GRID_CELLS, HOME_CELLS, cellDistance, rangeLabel, normalizeFormation, movePiece, shopOdds, interestIncome, fusionCount, canRecruit, stats, synergies, findPiece, recruit, rollShop, sellValue, sell, reservePiece, deployPiece, equipItem, unequipItems, grantItem } from './tft-core.mjs';

export const HUD_COUNT = 139;
export function createHudState() {
  return { selected: null, phase: 'prepare', notice: 'Escolha seus heróis na loja', reward: false, menu: null, exiting: false, quality:0, font:0, saveStatus:'saved',saveSequence:0 };
}
const portrait = unit => unit ? PLAYABLE.indexOf(unit.kind) : 99;
const stars = u => '★'.repeat(u.star);
const ITEM_KEYS = Object.keys(ITEMS);
const TRAIT_ICONS = [0, 1, 2, 3, 4, 8];
const TRAIT_BONUSES = { guardian: ['+18% vida', '+30% vida'], marksman: ['Intervalo de ataque -25%'], mystic: ['+25% habilidades', '+50% habilidades'], assassin: ['Salto e execução +0,5x'], wild: ['12% roubo de vida', '22% roubo de vida'], ancient: ['+15 armadura', '+30 armadura'] };
export function hudOptions(run, hud) {
  const options = Array.from({ length: HUD_COUNT }, (_, id) => ({ id, icon: 99, enabled: false, label: '' }));
  const put = (id, label, enabled = false, icon = 99) => Object.assign(options[id], { label, enabled, icon });
  const active = hud.phase === 'prepare' && !hud.menu, selected = findPiece(run, hud.selected), onField = selected && run.team.includes(selected);
  const encounter = ENCOUNTERS[Math.min(run.round, ENCOUNTERS.length - 1)];
  put(0, `<b>RODADA ${Math.min(run.round + 1, ENCOUNTERS.length)}/${ENCOUNTERS.length}</b>`);
  put(43, `<color=#80e5a3>${run.hp}</color> VIDA`, false, 13);
  put(44, `<color=#ffd578>${run.gold}</color> OURO`, false, 12);
  put(45, `${run.team.length}/${FIELD_LIMIT} CAMPO`, false, 0);
  put(1, hud.phase === 'combat' ? `COMBATE • ${encounter.label}` : hud.phase === 'reward' ? 'ESCOLHA SEU PRÊMIO' : active ? `${encounter.label}  •  ${hud.notice}` : hud.notice);
  for (let i = 0; i < 5; i++) {
    const kind = run.shop[i], def = ROSTER[kind];
    const rarity = def && RARITIES[def.rarity];
    put(2 + i, rarity ? `<b>${def.label}</b>\n<color=${rarity.color}>${rarity.label} · ${def.cost} ouro</color>\n<color=#8de0e8>◎ ${rangeLabel(kind)}</color>` : '<color=#83929c>Comprado</color>', active && canRecruit(run, i), rarity ? PLAYABLE.indexOf(kind) : 99);
  }
  put(7, `RENOVAR  •  ${SHOP_REFRESH_COST} ouro`, active && run.gold >= SHOP_REFRESH_COST, 17);
  put(8, run.locked ? 'LOJA TRAVADA' : 'TRAVAR LOJA', active, 18);
  put(9, hud.phase === 'finished' ? 'VOLTAR AO MENU' : hud.phase === 'combat' ? 'EM COMBATE' : 'LUTAR', !hud.menu && ((active && run.team.length > 0) || hud.phase === 'finished'), 19);
  for (let i = 0; i < BENCH_LIMIT; i++) {
    const unit = run.bench[i], isSelected = unit?.uid === hud.selected;
    put(10 + i, unit ? `<link="${10+i},${unit.uid}">${isSelected ? '› ' : ''}${ROSTER[unit.kind].label}</link>\n<color=#ffd578>${stars(unit)}</color>` : `<color=#83929c>VAGA ${i + 1}</color>`, active && (!!unit || !!selected), portrait(unit));
  }
  for (let i = 0; i < FIELD_LIMIT; i++) {
    const unit = run.team[i];
    put(18 + i, unit ? `<link="${18+i},${unit.uid}">${unit.uid === hud.selected ? '› ' : ''}${ROSTER[unit.kind].label}</link>  <color=#ffd578>${stars(unit)}</color>` : `<color=#83929c>CAMPO ${i + 1}</color>`, active && (!!unit || (!!selected && !onField)), portrait(unit));
  }
  const syn = synergies(run.team);
  Object.entries(TRAITS).forEach(([key, trait], i) => {
    const value = syn[key], target = trait.thresholds[Math.min(value.level, trait.thresholds.length - 1)];
    put(24 + i, `<color=${value.level ? '#80e5a3' : '#bcc6cc'}>${trait.label}  ${value.count}/${target}</color>\n${value.level ? TRAIT_BONUSES[key][value.level - 1] : 'Inativa'}`, false, TRAIT_ICONS[i]);
  });
  if (selected) {
    const def = ROSTER[selected.kind], st = stats(selected, onField ? run.team : [selected], onField ? syn : undefined);
    const items = selected.items || [], role = def.role === 'tank' ? 'TANQUE' : def.role === 'healer' ? 'CURA' : 'DANO', rarity = RARITIES[def.rarity];
    put(30, `<b>${def.label} ${stars(selected)}</b>\n<color=${rarity.color}>${rarity.label}</color> • ${role} • ${onField ? 'CAMPO' : 'RESERVA'}\n<color=#80e5a3>♥ ${st.hp}</color>  •  <color=#ffbd7d>⚔ ${st.damage}</color>\n<color=#8de0e8>◎ ${rangeLabel(selected.kind)}</color> • ${st.period.toFixed(1)}s\nITENS ${items.length}/3\n${items.length ? items.map(key => ITEMS[key].label).join(' · ') : 'Sem equipamento'}`);
    put(31, selected.star < 3 ? `CÓPIAS ${fusionCount(run, selected)}/3\n${stars(selected)} → ${'★'.repeat(selected.star + 1)}` : 'MÁXIMO ★★★');
    put(33, onField ? run.bench.includes(null) ? 'GUARDAR NA RESERVA' : 'RESERVA CHEIA' : run.team.length < FIELD_LIMIT ? 'COLOCAR NO CAMPO' : 'ARRASTE PARA TROCAR', active && (onField ? run.bench.includes(null) : run.team.length < FIELD_LIMIT));
  } else put(30, 'ATRIBUTOS\nSelecione uma peça do campo ou da reserva');
  put(32, selected ? `VENDER • +${sellValue(selected)} OURO\nARRASTE A PEÇA AQUI` : 'VENDER\nARRASTE A PEÇA AQUI', active && !!selected, 12);
  Object.entries(ITEMS).forEach(([key, item], i) => put(34 + i, `${item.label} ×${run.bag[key]}\n${item.detail}`, active && !!selected && run.bag[key] > 0 && (selected.items?.length || 0) < 3, 14 + i));
  put(37, 'RETIRAR ITENS', active && !!selected && !!selected.items?.length);
  const odds = shopOdds(run.round);
  put(38, `RESERVA ${run.bench.filter(Boolean).length}/${BENCH_LIMIT}`);
  put(135, `<color=#ffd578>JUROS +${interestIncome(run.gold)}</color> / BATALHA`, false,12);
  put(136, `LOJA <color=#bcc6cc>${odds.normal}%</color> / <color=#79c4ff>${odds.rare}%</color> / <color=#d99bff>${odds.epic}%</color>`);
  put(137, `<color=#ffd578>SEQUÊNCIA +${Math.min(3, Math.floor(Math.abs(run.streak) / 2))}</color>`, false,19);
  put(138, hud.saveStatus==='error'?'<color=#ff9292>SAVE INDISPONÍVEL</color>':'<color=#80e5a3>SALVO NO PC</color>');
  // Icon codes 98/99 carry the persistent preferences even when menu rows are hidden.
  put(133,'',false,hud.quality?98:99);put(134,'',false,hud.font?98:99);
  if (hud.phase === 'reward' && !hud.menu) {
    Object.entries(ITEMS).forEach(([key, item], i) => put(39 + i, `<b>${item.label}</b>\n${item.detail}`, true, 14 + i));
    put(42, '<b>+4 OURO</b>\nReceber moedas', true, 12);
  }
  put(46, hud.menu ? 'FECHAR MENU' : 'MENU', !hud.exiting);
  // Extra protocol slots carry atomic drag destinations and stable identities.
  // Hidden source actions always select; they never trigger a previous selection's swap.
  for (let i = 0; i < 14; i++) put(108+i, '', active && !!(i < 8 ? run.bench[i] : run.team[i-8]));
  for (let i = 0; i < 8; i++) put(122+i, '', active && !!selected);
  put(130, '', active && !!selected);
  put(107, String(selected?.uid || 0), active);
  put(131, '<color=#8de0e8>◎ 1 CASA · 2 CASAS · ∞</color>  •  SELECIONE OU ARRASTE A PEÇA');
  for (let cell = 0; cell < GRID_CELLS; cell++) {
    const unit = run.team.find(u => u.cell === cell), index = unit ? run.team.indexOf(unit) : -1;
    const reachable = onField && cellDistance(selected.cell, cell) <= ROSTER[selected.kind].tiles;
    const color = unit?.uid === hud.selected ? '#ffd578' : reachable ? '#80e5a3' : cell < HOME_CELLS ? '#56cbd7' : '#ed7f85';
    const marker = `${String.fromCharCode(65+cell%7)}${Math.floor(cell/7)+1}`;
    put(51+cell, hud.menu ? '' : hud.phase === 'prepare' && unit ? `<link="${18+index},${unit.uid}"><color=${color}>${marker}</color></link>` : `<color=${color}>${marker}</color>`, active && cell < HOME_CELLS && (!!unit || (!!selected && (onField || run.team.length < FIELD_LIMIT))), hud.phase === 'prepare' ? portrait(unit) : 99);
  }
  if (hud.menu) {
    const confirm = hud.menu === 'confirm'||hud.menu==='new-confirm';
    put(47, confirm ? 'VOLTAR' : 'CONTINUAR', true);
    if (confirm) {
      put(49, hud.menu==='new-confirm'?'RECOMEÇAR':'SALVAR E SAIR', true);
      put(50, hud.menu==='new-confirm'?'<b>COMEÇAR DE NOVO?</b>\nO progresso salvo será apagado.':'<b>VOLTAR AO INÍCIO?</b>\nA partida fica salva para continuar ao jogar.');
    } else {
      put(48, 'VOLTAR AO INÍCIO', true);
      put(50, '<b>XADREZ AUTO BATTLER</b>\nMENU DA PARTIDA');
      put(132,'NOVA PARTIDA',true);
      put(133,hud.quality?'GRÁFICOS: ECONÔMICO · 30 FPS':'GRÁFICOS: EQUILIBRADO · 60 FPS',true,hud.quality?98:99);
      put(134,hud.font?'LETRAS: GRANDES':'LETRAS: NORMAL',true,hud.font?98:99);
    }
  }
  return options;
}
export function hudWireOptions(run, hud) {
  // RawString carries literal text. LocalizedString is a lookup key in Unity;
  // passing the wire prefix as a localization key discards the whole panel.
  return hudOptions(run, hud).map(o => ({ id: o.id, text: { tag: 'RawString', val: `${String(o.icon < 0 ? 99 : o.icon).padStart(2, '0')}|${o.enabled ? 1 : 0}|${o.label}` } }));
}
export function actHud(run, hud, id) {
  if (id === 107) return { changed: false }; // Renderer metadata, never an input.
  const option = Number.isInteger(id) ? hudOptions(run, hud)[id] : undefined;
  if (!option?.enabled) return { changed: false };
  // Navigation stays available during combat and prize selection. It cannot
  // buy pieces, award prizes or charge gold while the match menu is open.
  if (id === 46) { hud.menu = hud.menu ? null : 'open'; return { changed: true, navigation: true }; }
  if (id === 47) { hud.menu = ['confirm','new-confirm'].includes(hud.menu) ? 'open' : null; return { changed: true, navigation: true }; }
  if (id === 48) { hud.menu = 'confirm'; return { changed: true, navigation: true }; }
  if (id === 49) { hud.discard= hud.menu==='new-confirm';hud.exiting = true; return { changed: true, navigation: true, exit: true }; }
  if (id === 132) { hud.menu='new-confirm';return {changed:true,navigation:true}; }
  if (id === 133) { hud.quality=1-hud.quality;return {changed:true,navigation:true}; }
  if (id === 134) { hud.font=1-hud.font;return {changed:true,navigation:true}; }
  let board = false;
  const unit = findPiece(run, hud.selected);
  const onField = !!unit && run.team.includes(unit);
  if (id >= 108 && id <= 121) {
    const piece = id < 116 ? run.bench[id-108] : run.team[id-116];
    if (!piece) return {changed:false};
    hud.selected = piece.uid; return {changed:true};
  }
  if ((id >= 51 && id < 79) || (id >= 122 && id <= 130)) {
    if (!unit) return {changed:false};
    const destination = id === 130 ? {type:'sell'} : id >= 122 ? {type:'bench',slot:id-122} : {type:'field',cell:id-51};
    const wasField = onField, before = run.team.map(u=>u.uid).join(','), changed = movePiece(run,unit.uid,destination);
    if (changed) { if (id === 130) hud.selected = null; hud.notice = id === 130 ? 'Peça vendida; itens devolvidos' : 'Posição atualizada'; }
    return {changed,board:changed && (wasField || destination.type === 'field' || before !== run.team.map(u=>u.uid).join(','))};
  }
  if (hud.phase === 'finished') return { changed: true, exit: true };
  if (hud.phase === 'reward') {
    if (id === 42) run.gold += 4;
    else grantItem(run, ITEM_KEYS[id - 39]);
    hud.phase = 'prepare'; hud.reward = false; hud.notice = 'Prêmio recebido';
    return { changed: true, reward: true };
  }
  if (id >= 2 && id <= 6) {
    if (!recruit(run, id - 2, hud.selected)) return { changed: false };
    const result = run.lastRecruit;
    board = result.board;
    const piece = findPiece(run, result.uid);
    hud.selected = !result.merges.length && unit?.kind === piece.kind && unit.star === piece.star ? unit.uid : result.uid;
    hud.notice = result.merges.length ? `${ROSTER[result.kind].label} ${stars(piece)} • FUSÃO AUTOMÁTICA` :
      run.team.includes(piece) ? 'Herói colocado no campo' : 'Herói guardado na reserva';
  } else if (id === 7) { rollShop(run); hud.notice = 'Novas ofertas'; }
  else if (id === 8) run.locked = !run.locked;
  else if (id === 9) return { changed: true, fight: true };
  else if (id >= 10 && id <= 17) {
    const slot = id - 10;
    if (!run.bench[slot] && unit) {
      board = run.team.includes(unit);
      if (!movePiece(run, unit.uid, {type:'bench',slot})) return {changed:false};
    } else if (run.bench[slot]) hud.selected = run.bench[slot].uid;
  } else if (id >= 18 && id <= 23) {
    const target = run.team[id - 18], slot = run.bench.findIndex(u => u?.uid === hud.selected);
    if (slot >= 0) { board = deployPiece(run, slot, target?.uid); }
    else if (target) hud.selected = target.uid;
  } else if (id === 32) { board = sell(run, unit.uid) && onField; hud.selected = null; hud.notice = 'Peça vendida; itens devolvidos'; }
  else if (id === 33) {
    board = run.team.includes(unit) ? reservePiece(run, unit.uid) : deployPiece(run, run.bench.indexOf(unit));
  } else if (id >= 34 && id <= 36) { board = equipItem(run, unit.uid, ITEM_KEYS[id - 34]) && onField; hud.notice = 'Item equipado'; }
  else if (id === 37) { board = unequipItems(run, unit.uid) && onField; hud.notice = 'Itens devolvidos ao estoque'; }
  return { changed: true, board };
}
