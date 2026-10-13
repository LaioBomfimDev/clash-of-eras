// Rarity and price describe shopping, and cannot affect combat regression.
export const combatSignature = simulation => JSON.stringify(simulation,
  (key,value) => key === 'cost' || key === 'rarity' ? undefined : value);
