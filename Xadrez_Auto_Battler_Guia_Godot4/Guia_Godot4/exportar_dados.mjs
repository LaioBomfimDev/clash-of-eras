// Regenerates documentation data from the portable rules. Never starts a game.
import fs from 'node:fs';
import {
  ROSTER, PLAYABLE, RARITIES, ITEMS, TRAITS, ENCOUNTERS,
  FIELD_LIMIT, BENCH_LIMIT, GRID_COLS, GRID_ROWS, GRID_CELLS, HOME_CELLS,
  CELL_SIZE, SHOP_REFRESH_COST, newRun, enemyTeam, normalizeFormation,
  stats, shopOdds, interestIncome, sellValue
} from './referencias/src/tft-core.mjs';

const calculated = (piece, team) => {
  const s = stats(piece, team);
  return { hpMax:s.hp, attack:s.damage, healingBase:s.healing, armor:s.armor,
    attackIntervalSeconds:s.period, spellMultiplier:s.spell,
    movementCellsPerSecond:s.speed/CELL_SIZE, executionBonus:s.executeBonus,
    lifesteal:s.lifesteal, canInitialJump:s.jump };
};
const run = newRun(17);
const data = {
  schema:'xadrez-auto-battler-design', schemaVersion:1, sourceVersion:'0.10.1', date:'2026-10-09',
  scope:'Existing gameplay data only. Godot architecture and the future dancer are documented separately.',
  board:{columns:GRID_COLS, rows:GRID_ROWS, totalCells:GRID_CELLS, homeCells:HOME_CELLS,
    fieldLimit:FIELD_LIMIT, benchSlots:BENCH_LIMIT, indexFormula:'row * 7 + col',
    homeRowsZeroBased:[0,1,2,3], displayRow1:'player back edge at bottom',
    attackDistance:'Chebyshev', walkingNeighbors:'four orthogonal',
    defaultMeleeHomeCell:24, defaultRangedHomeCell:10},
  initialState:{playerHp:run.hp, gold:run.gold, encounterIndex:run.round, wins:run.wins,
    streak:run.streak, team:run.team, bench:run.bench, bag:run.bag,
    nextUid:run.nextId, shopLocked:run.locked},
  shop:{offerCount:5, refreshCost:SHOP_REFRESH_COST, maxOffersPerCharacter:2,
    copyStars:1, sharedPool:false, firstGuarantee:['Tank','two distinct of Ranger/Caster/Assassin'],
    odds:[0,5,10].map(round=>({fromVisibleRound:round+1,toVisibleRound:round+5,...shopOdds(round)})),
    seed17OpeningExample:{seed:17,offers:run.shop,rngStateAfterGeneration:run.random.getState()}},
  rarities:RARITIES, equipment:ITEMS, synergies:TRAITS,
  characters:Object.fromEntries(Object.entries(ROSTER).map(([id,d])=>[id,{
    id,label:d.label,playable:PLAYABLE.includes(id),role:d.role,
    rarity:d.rarity??null,cost:d.cost,baseHp:d.hp,baseArmor:d.armor,
    attackRangeCells:Number.isFinite(d.tiles)?d.tiles:'unlimited',
    attackIntervalSeconds:d.period,traits:d.traits,skillId:d.skill,skillDescription:d.skillName,
    starExamples:[1,2,3].map(star=>({star,...calculated({kind:id,star,items:[]},[{kind:id,star,items:[]}])}))
  }])),
  economy:{initialGold:run.gold,baseIncome:5,winBonus:1,mobWinExtra:3,rewardGoldChoice:4,
    interestRule:'floor(gold_before_settlement / 10), uncapped',
    interestExamples:[0,9,10,19,20,30,50,60,100].map(gold=>({gold,interest:interestIncome(gold)})),
    streakRule:'min(3, floor(abs(updated_signed_streak)/2))',
    saleValues:Object.fromEntries(Object.keys(RARITIES).map(rarity=>[rarity,[1,2,3].map(star=>({star,gold:sellValue({kind:RARITIES[rarity].kinds[0],star})}))]))},
  encounters:ENCOUNTERS.map((e,index)=>{
    const team=normalizeFormation(enemyTeam(index));
    return {visibleRound:index+1,encounterIndex:index,label:e.label,type:e.kind,
      chapter:e.chapter+1,chapterIndex:e.chapter,
      enemyUnits:team.map((u,slot)=>({slot,characterId:u.kind,stars:u.star,items:u.items,
        hpPower:u.power,localHomeCell:u.cell,
        combatCell:(7-Math.floor(u.cell/7))*7+u.cell%7,
        initialStatsWithTeamSynergies:calculated(u,team)}))};
  }),
  futureDancer:{implemented:false,nameRequested:'Michael Jackson',
    canAttack:false,pulseSeconds:2,healFractionOfOwnMaxHp:0.1,shieldFractionOfOwnMaxHp:0.1,
    moonwalkCells:[3,4],healingAmplification:'undecided',shieldStackingAndDuration:'undecided'}
};
fs.writeFileSync(new URL('./DADOS_DO_JOGO.json',import.meta.url),JSON.stringify(data,null,2)+'\n');
console.log(`Exported ${PLAYABLE.length} playable characters, ${Object.keys(ROSTER).length-PLAYABLE.length} mobs and ${data.encounters.length} encounters. Only portable JS rules loaded.`);
