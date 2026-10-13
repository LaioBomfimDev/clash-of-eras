# Núcleo do primeiro laboratório

Código GDScript independente de cenas. O cliente representa o estado; este núcleo decide movimento, dano, projéteis, mortes, resultado e vidas. O laboratório é **contra um bot local automático**. A `Session` controla recrutamento, reserva, economia, equipamentos e benefícios. Cliente/servidor WebSocket ficam em `net/`; coleção persistente e balanceamento validado continuam pendentes.

## API para o cliente

```gdscript
const Simulation = preload("res://simulation/arena_simulation.gd")
var simulation = Simulation.new()
simulation.reset(20261011) # catálogo no elenco, quatro ativos por lado, quatro vidas
simulation.place_unit(1, Vector2i(0, 7)) # preparação, célula vazia na própria metade
simulation.start_combat()
simulation.step(delta) # subpassos fixos de 0,05 s; não depende da animação
var events = simulation.drain_events()
var snapshot = simulation.snapshot()
simulation.next_round() # somente após resolução e antes de acabar a partida
```

- Coordenadas públicas: `Vector2i(coluna, fileira)`, 8 × 8, hexágonos pointy odd-r, fileiras ímpares deslocadas para a direita. Jogador/team 0 começa nas fileiras 4–7; bot/team 1, nas 0–3.
- IDs padrão 1/101 Neymar, 2/102 Caramelo, 3/103 Obama, 4/104 Zumbi, 5/105 Michael. O elenco pode ser substituído pela Session; somente personagens **ativos e vivos** ocupam células, recebem efeitos ou contam no resultado.
- `units`, `projectiles`, `phase`, `elapsed`, `accelerated`, `team_lives`, `round_index`, `match_winner` e `round_result` podem ser lidos pelo cliente. Não modificar HP ou aplicar dano na apresentação.
- `UnitState` inclui `cell`, `previous_cell`, `hp`, `max_hp`, `shield`, `alive`, `active`, `last_action`, `target_id`, `crit_growth`, `attack_count`, `attack_damage`, `armor`, `resist`, `damage_type` e `spec` com os atributos originais. Estatísticas por rodada: `damage_dealt`, `healing_done`, `shield_absorbed`, `kills`.
- `BallProjectile` inclui `from_cell`, `to_cell`, `flight_left`, `flight_duration`, `target_id` e `impacts`. Fração visual do trecho: `1 - flight_left / flight_duration`.
- Eventos têm `type`, `tick`, `time` e, conforme o evento, `source_id`, `target_id`, `amount`, `absorbed`, `critical`, `projectile_id`. A fila mantém os últimos 2048 eventos; drenar a cada atualização evita perder observações antigas. O resultado não depende dessa fila.
- `round_result.winner` é 0, 1 ou -1; `reason` é `elimination`, `survivors`, `damage` ou `draw` (e `timeout` na falha PvE). Resolução normal desconta uma vida exatamente uma vez; PvE não desconta vidas de nenhum lado. `reset` reinicia toda a partida; `next_round` restaura vida, escudo, efeitos e posições escolhidas na preparação, preservando as vidas restantes.
- `preparation_setup(roster)` aceita um `Array[Dictionary]` com `{id, key, team, cell: Vector2i, active}` e valida tudo antes de substituir o elenco. Não exige todos os personagens do catálogo. Reservas podem ter `cell = Vector2i(-100, -100)`; ativos precisam de célula vazia na própria metade. `reset_round(roster=[])` limpa estado de preparação, preservando vidas e índice da rodada. Ambos são rejeitados durante combate ou após resolução; usar `next_round()` primeiro.
- `set_active(id, enabled, destination=Vector2i(-100,-100))` ativa/reserva; `place_unit` reposiciona ativos. A Session valida capacidade e propriedade dos personagens.
- `apply_equipment(id, modifiers)` substitui os modificadores runtime, sem alterar `spec`: `hp_mult`, `attack_mult`, `armor_mult`, `resist_mult`, `attack_speed_mult`, `crit_bonus`. Também aceita `hp_bonus`, `attack_bonus`, `armor_bonus`, `resist_bonus`. Modificadores são finitos, limitados e podem mudar na preparação ou por equipagem autorizada durante combate. Reaplicar o mesmo conjunto não acumula. Cada rodada cria estado limpo; a Session reaplica seus equipamentos após `next_round()`/`preparation_setup()`.
- `unit_summaries()` retorna as estatísticas individuais; o resultado mantém uma cópia em `round_result.units_summary`. `preview_synergies(team)` informa contagens/patamares da formação sem modificar atributos. `synergy_enabled` começa falso no laboratório isolado; a Session pode habilitar os grupos funcionais de teste. `synergy_snapshot` congela o resultado aplicado no começo do combate.

## Escolhas confirmadas e hipóteses do experimento

Confirmado: movimento por hexágonos; Neymar atira à distância e ricocheteia até três impactos A→B→A; Caramelo sangra e executa em 10%; Obama usa a mala para proteção; Zumbi dá crítico/velocidade à equipe e alimenta o próprio crescimento somente com seus críticos. **Michael percorre três hexágonos aleatórios de costas (moonwalk); ao parar, dá um escudo forte à equipe; enquanto vivo, mantém uma cura pequena periódica**, pedido mais recente do usuário, que substitui o kit anterior de pulsos de cura. Combate tem 30 s, aceleração aos 15 s e desempate por sobreviventes/dano. Quatro vidas por jogador.

**Propostas temporárias implementadas para poder observar os kits:**

- Atributos em `data/debug_characters.json` são editáveis e deliberadamente provisórios. Níveis fora da partida não são aplicados neste laboratório; ambos usam o mesmo catálogo.
- A perseguição normal escolhe o inimigo mais próximo, com empate por ID. O Caramelo tem a caça inicial de teste descrita abaixo; Michael conserva o moonwalk. BFS busca uma casa livre dentro do alcance; não há empurrão, troca de casas, bloqueio de linha de visão ou ataque através de caminho físico do projétil.
- Uma ação resolve por vez em ordem estável de unidades. Isso permite reprodução, mas não demonstra justiça de iniciativa no PvP nem implementa mortes simultâneas. Essa ordem precisa ser revisada antes do multiplayer competitivo.
- Aceleração inicial 2× afeta cadência de ataque, movimento e voo. O relógio da rodada e sangramento permanecem em segundos de simulação normais. Não multiplicar `delta` no cliente.
- Dano físico: `dano × 100 / (100 + armadura)`; mágico usa a mesma fórmula com resistência mágica. Crítico sorteado pelo gerador local com semente. Michael está com ataque 0 nos dados de teste e não emite golpes vazios; se receber ataque > 0, ataca sem perseguir. Fumaça pode causar erro, e Rapunzel aplica controle; são regras do laboratório.
- Neymar escolhe o segundo inimigo adjacente de menor ID no chute. O par fica fixo, é revalidado na saída e na chegada de cada ricochete e nunca busca um terceiro alvo. Sem vizinho, há só o primeiro impacto. Se alguém morrer ou se afastar, a sequência acaba. Uma bola existente continua se Neymar morrer. Cada trecho tem tempo de voo; o alvo é seguido até o impacto. Um crítico é sorteado no chute e vale para seus impactos, com multiplicadores de dano100%/80%/50% por impacto. Ricochete nunca gera ataques novos.
- Caramelo verifica **antes da mordida** se a vida atual é menor ou igual a 10% da máxima; a execução ignora escudo/armadura e exige alcance. Não executa automaticamente pelo sangramento à distância. Sangramento é físico, sem crítico, um efeito por atacante; mordidas renovam a duração sem adiar o próximo tick. O efeito já aplicado continua se o Caramelo morrer. Esses detalhes não foram aprovados como regra final.
- Obama começa cada rodada com escudo de absorção da mala e agora testa a renovação própria descrita abaixo; não há orientação frontal. Escudo absorve dano após armadura. Dano excedente atinge HP. A execução proposta ignora o escudo.
- Bônus de equipe do Zumbi é capturado no começo da rodada, inclusive nele mesmo, e persiste se ele morrer neste experimento. O incremento pessoal é aditivo ao multiplicador crítico: o crítico atual usa o valor anterior, depois acrescenta o incremento limitado pelo teto. Ataques normais, aliados, sangramento e projéteis alheios não alimentam esse contador. Crescimento reinicia por rodada. Não confundir este bônus de personagem com o sistema futuro de sinergias.
- Michael, moonwalk: não persegue alvos. A cada passo escolhe, pelo gerador com semente, um hexágono vizinho livre, evitando voltar ao anterior quando houver outra opção; a casa é reservada no início do passo e ele fica de costas para o movimento (`facing_axial`). Sem vizinho livre, o passo é dançado no lugar (`blocked`) e conta para o ciclo, para nunca travar. Após `moonwalk_steps` passos, concede `dance_shield_amount` a todos os aliados ativos e vivos e pausa por `moonwalk_pause_duration`. Passos usam o tempo acelerado do combate; duração do escudo não acelera. `moonwalk_steps = 0` desliga o moonwalk (usado em fixtures).
- Escudo da dança: absorve antes do escudo da mala, depois da armadura. Uma nova concessão **renova sem acumular**: cada aliado fica com o maior valor entre o atual e o novo, e a duração recomeça. Some ao expirar ou na morte. Eventos: `moonwalk_step` (`from`, `to`, `step`, `blocked`) e `dance_shield` (`amount`, `duration`, `targets`); `hit` informa `absorbed_dance` e `absorbed_base`.
- Michael, cura contínua: pulso `heal_pulse` a cada `heal_interval` segundos normais (teste:10HP por segundo, todos os aliados ativos/vivos, autocura incluída). Não revive, não afeta reservas e não concede cura excedente; cada cura efetiva emite `heal`. Alcance global escolhido pelo usuário; valor/intervalo são hipóteses configuráveis no JSON.
- Nível na partida (decisão do usuário): a Session soma cópias grátis do mesmo herói; `copies_for_level` = [1, 2, 4] e `power_multiplier` = [1,0; 1,5; 2,25] em `data/debug_characters.json`. `set_unit_level(id, nível)` só vale na preparação e persiste no elenco entre rodadas; `preparation_setup` aceita `level` opcional (1–3). O multiplicador vale para vida e dano base (antes dos itens e sinergias), com curva própria de HP para Barbie[600,900,1200] e Ken[1200,1600,2300] e, como **proposta de teste**, para escudo inicial da mala, cura e escudo da dança e sangramento. Cópias se juntam na hora: não ocupam a reserva. Nível máximo 3; a quinta cópia é rejeitada (`max_level`) e o herói sai do sorteio da loja.
- **Lote 03 (decisões do usuário; números em `debug_characters.json`, todos de teste):**
  - Barbie: no início do combate invoca o Ken (`summons.ken`) no hexágono livre mais próximo, preferindo à frente. ID do Ken = ID da Barbie + 80. Quem escolheria a Barbie como alvo passa a mirar o Ken enquanto ele vive (`guardian_id`). Barbie causa +50% de dano enquanto o Ken vive. Ken herda o nível dela, não ocupa capacidade, não aparece na formação pública e **não conta como tropa** no desempate (proposta).
  - Elon: três minifoguetes diretos, quarto ataque super foguete com dano1,5×, splash60% nos vizinhos e profundidade adicional2 na retaguarda. Sem ricochete.
  - Snoop: nuvem de dano mágico no raio2,3s, ticks0,5s,30% de erro inimigo e25% velocidade aliada dentro. Uma nuvem por Snoop; nova substitui anterior.
  - Lula: primeiro retorno40% da vida máxima; no N3 um segundo retorno30%. `revive_count` limita as voltas e reinicia por rodada; cada volta limpa sangramento/atordoamento, inclusive sangramentos retidos durante o segundo retorno.
  - Bob Marley: aliados×1,3 e inimigos×0,7 na velocidade de ataque; raios por nível[4,5,6] como teste de área ampliada. Dano inimigo não diminui.
  - Rapunzel: mana confirmada por ataques, alvo mais distante. Teste100mana/+25porataque iniciado, inclusive erro; não recebe mana por tempo/dano recebido. Ao encher, gasta a carga e puxa/atordoa1s; sem alvo ou atordoada conserva a carga. Snapshot envia `mana`/`max_mana`. Demais personagens mantêm gatilhos próprios.
- Grupos funcionais provisórios **TESTE**: Atacantes2/3 (+10%/20% ataque membros); Atiradores2/4 (+15%/35% velocidade membros); Apoio2/4 (+10%/25%HP equipe); Vanguarda2/3 (+25/50armadura e+20/40resistência membros). Maior patamar substitui menor; formação congela bônus antes do combate. Presidentes/Maconheiros/Astro estão em estudo, sem efeitos novos aprovados.
- Desempate conta somente HP efetivamente perdido, sem escudo ou excesso de dano. Empate completo não remove vida. Esses detalhes permanecem propostas a avaliar.

## Refinamentos dos quatro kits — TESTE, 2026-10-12

São duas mudanças experimentais de gameplay; os números são editáveis em `debug_characters.json`, sem aprovação de balanceamento. Michael, níveis por cópias e os kits existentes do lote 03 foram preservados.

- **Caramelo, caça inicial:** no começo do combate, escolhe um único inimigo ativo e vivo com alcance ≥2 e dano >0. Prioriza maior dano de ataque runtime; empate por distância e ID. `assassin_opening_duration` = 5 s limita a perseguição. Segue o mesmo caminho BFS de hexágonos livres, sem teleporte. A primeira mordida acertada, a morte/inativação da presa ou o tempo esgotado encerram a caça; erro por fumaça não a encerra. Depois volta à seleção normal e não inicia outra caça naquela rodada. Sem alvo elegível, usa a seleção normal desde o início. Bloqueio de caminho espera e pode consumir o prazo. Reservas não participam. Zero no parâmetro desliga a proposta.
- **Obama, reforço da mala:** `briefcase_guard_amount` = 120 e `briefcase_guard_interval` = 5 s. Renova só seu escudo base para `max(escudo_atual, valor × multiplicador_do_nível)`, preservando um escudo inicial maior. Não soma indefinidamente, não cura HP e não altera o escudo da dança. O intervalo usa segundos normais, sem acelerar com velocidade de ataque ou o modo aos15 s; atordoamento pausa a contagem. Morte e reserva impedem a ativação. Valor zero desliga a proposta. Escalar pelo nível continua hipótese do kit.
- **Zumbi, leitura do crescimento:** nenhuma nova regra de crítico garantido. `crit_growth_hits` conta seus próprios ataques críticos acertados, inclusive depois de alcançar o teto; `crit_damage_multiplier` informa o multiplicador do próximo crítico. O golpe atual usa o valor anterior, como antes. Os dois campos reiniciam por rodada.
- **Neymar, leitura do chute:** `kick` ocorre uma vez por ataque lançado, com `source_id`, `target_id`, `projectile_id`, `flight_duration` e `critical`. É complementar ao evento existente `ball_launched`. Velocidade de ataque muda a cadência dos chutes; os ricochetes não geram novos chutes. O encerramento emite `ball_expired` com `source_id`, `projectile_id`, `kind`, `impacts` e `reason`: `max_impacts`, `no_pair`, `pair_dead`, `pair_separated` ou `target_dead`; remoção externa de objetos tem razões defensivas `source_missing`/`target_missing`. Mantidos voo com duração, par fixo A→B→A e cancelamentos.

Contrato visual adicional: snapshots incluem `assassin_target_id`, `assassin_opening_remaining`, `assassin_opening_finished` e `briefcase_cooldown`. Eventos `assassin_hunt` incluem alvo/prazo; `assassin_hunt_ended` inclui alvo e motivo (`first_bite`, `target_dead`, `timeout`, `no_carry`). `briefcase_guard.amount` é o escudo final e `added` é o ganho real. `crit_growth` inclui `stacks` (contagem pessoal), `cap` (teto do incremento) e `multiplier` (próximo crítico). A interface apenas representa esses dados.

## Verificação sem interface

```text
Godot_v4.7.2-stable_win64_console.exe --headless --path RelicArena --import
Godot_v4.7.2-stable_win64_console.exe --headless --path RelicArena --script res://tests/test_simulation.gd
```

O runner contabiliza falhas e chama `quit(1)` quando necessário. Fixtures cobrem fronteiras da execução, ricochete finito, perda da vizinhança, sangramento, absorção, crítico pessoal, relógio, vidas, ocupação, reprodução por semente, cura contínua, moonwalk/escudo da dança (passos, bloqueio, renovação e expiração), reserva, elenco dinâmico, tipos de dano, equipamentos isolados/idempotentes e estatísticas. Não validam renderização, rede ou equilíbrio entre personagens.

## Revisão de2026-10-13 — economia, dispensa e PvE

Ouro inicial20; ao avançarR2/R3/R4 recebe12/15/18, fórmula9+3×(rodada−1). Sequência de vitórias normais paga bônusfixo1 a partir da segunda, zera na derrota/nova partida; empate e Boss preservam sequência sem pagar bônus. Reserva5. `dismiss` aceita herói próprio na preparação: nenhum ouro, equipamentos voltam à bolsa e cópias/nível reiniciam. Se não couber tudo na bolsa, rejeita antes de mutar estado.

Round4 da Session ativa PvE explicitamente; número da rodada isolado não ativa esse modo no core. HP inicialmente8000/2000/3000; produção paralela posterior deixouBoss10000 e lacaios4000/5000, preservados/revalidados. Fogo vermelho/roxo atingem área; furacão desloca tropas. Só a morte do Boss concede vitória/3drops, mesmo com lacaios vivos; eliminação/30s com Boss vivo falha. Nenhum resultado PvE retira corações. Guardas de prêmio único e presença de Boss morto previnem recompensa repetida ou por desempate. `boss_defeated()` é consulta pura de Boss inimigo ativo existente e morto.
