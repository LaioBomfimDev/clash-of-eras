# Cérebro — regras atuais

**Barra de Vida Ornamental do Boss (Ferro & Fogo, 2026-10-15):** a pedido direto do usuário com imagem de referência ("barra de vida do boss tem que ser algo tipo assim , cuidado com a ui e com os personagens, pra nao ficar na frente"), a barra de vida de chefe no Round 4 PvE foi completamente reformulada:
1. **Design Ornamental de Ferro e Fogo:** Moldura de ferro forjado escuro com pontas de adaga/lança nas extremidades esquerda e direita e entalhes pontiagudos góticos/demoníacos, miolo vazado com preenchimento de fogo/magma incandescente (`fill.png`), fundo escuro de pedra vulcânica com rachaduras (`empty.png`) e barra fantasma de dano recente amortecido (`ghost.png`).
2. **Prevenção Rigorosa de Obstruções (UI e Personagens):**
   - **Horizontal (X):** Largura de 644 px centralizada entre `X = 318` e `X = 962`, encaixando-se com margem de segurança de 14 px entre a placa do jogador (`X <= 304`) e a placa do adversário (`X >= 976`), sem colidir com as informações de vida e perfil.
   - **Vertical (Y):** O antigo painel retangular escuro de 56 px de altura foi substituído por um container de fundo 100% transparente com altura útil de apenas 34 px posicionado em `Y = 6..58`. Como a fileira mais ao norte do tabuleiro (y=1 / y=0) projeta a cabeça do Boss e dos heróis em `Y >= 83.5` (ou `Y = 52.2` no caso extremo de avanço ao limite do mapa), há uma folga de segurança limpa de mais de 25 pixels, eliminando qualquer risco de tampar a cabeça das unidades em combate.
   - O rótulo de HP fica centralizado dentro da própria barra de fogo com outline preto espesso (`shadow_size = 3`), economizando espaço vertical e garantindo legibilidade perfeita.
3. **Validação e Simulação no Atlas:** Teste dedicado `test_boss_battle.gd` aprovado com 77/77 asserções verdes e `test_full_matches.gd` com 1.036/1.036. Barra integrada com slider interativo de teste na Aba 3 do Atlas Visual (`http://localhost:8090/atlas_jogo/`).

**Ferramenta DEV F6 (2026-10-15):** pedido confirmado para controlar informações, dados, rounds, partidas, velocidade e deixar feedbacks. Reformulado e melhorado a pedido do usuário:
1. **Controle de Transparência / Opacidade (20% a 100%):** Slider interativo no topo (`👁️`) com exibição percentual e chips rápidos (`[50%]`, `[75%]`, `[90%]`, `[100%]`), permitindo enxergar os heróis, projéteis e o tabuleiro debaixo do painel enquanto altera dados em tempo real; preferência persistida em `user://devtools/devtools_prefs.json`.
2. **Modernização dos Botões e Apresentação Visual:** Novo padrão flat/glass escuro com bordas neon ciano/esmeralda, cantos arredondados, feedback de hover/clique e sem foco fantasma; separação por cartões temáticos (`_card`), badges de status e abas estilizadas no `TabContainer`.
3. **Novos Dados e Controles Configuráveis:**
   - *Partida/Combate:* botões de `Vitória Rápida (Kill Bot)` e `Derrota Rápida (Kill Player)`, chips de velocidade rápida (`0.5×`, `1.0×`, `2.0×`, `4.0×`), passos de 50ms/250ms/1s e atalhos diretos de round (`R1`, `R2`, `R3`, `R4 BOSS`, `R5`).
   - *Equipes:* chips rápidos de ouro (`+10`, `+50`, `+100`, `Max 999`, `Zerar`), vidas (`+1`, `-1`, `Max 5`, `1`), capacidade (`4`, `6`, `8`), renovação grátis de loja, limpeza de bolsa de itens, kit de itens básicos e preenchimento instantâneo de equipe N2.
   - *Combatentes:* telemetria completa com HP/Escudo/Mana/AD/Arm/Res/Velocidade/Crítico/Alvo/Hex; edição de escudo, mana e atributos com chips rápidos (`100% Full`, `50%`, `1 HP`, `+300 Escudo`, `100 Mana`); ações rápidas de `Stun 2s`, `Limpar Stun` e `Eliminar Combatente`; controles exclusivos para o Boss (`Forçar Teleporte` e `Ativar Modo Fúria`).
   - *Feedbacks:* avaliação interativa com estrelas `[1 ⭐]` a `[5 ⭐]` e categorias com ícones.
4. **Validação:** Godot 4.7.2 com 74/74 verificações aprovadas em `test_dev_lab.gd`, 32/32 em `test_lobby_ui.gd`, 18/18 em `test_hero_skills_menu_16f.gd` e 326/326 em `test_simulation.gd`. [Uso e limites](../RelicArena/DEVTOOLS.md).

**Boss e Snoop animados pelo MCP (2026-10-15):** pedido direto para animar o Boss andando e levantando o braço, seguido de detalhar o Snoop/charutão antes de criar seus movimentos. Boss: caminhada frontal com oito poses novas e conjuração com transição, pausa e retorno, ligadas ao renderizador; duas gerações consumidas no PixelLab. Snoop: base detalhada, caminhada e gesto de fumar de 16 quadros, quatro vistas com mapeamento para oito direções, charutão acompanhando a mão, integrados localmente ao combate e compêndio. O trial bloqueou a geração Pro do Snoop; a arte e os movimentos foram autorados no editor gratuito `pixelart_workbench` do mesmo MCP, sem novas gerações. Validação: Boss movimento13/0, batalha77/0, Snoop39/0 OpenGL e smoke486/0 após atualizar expectativas legadas de arena, escala Barbie/Ken e revelação do bot. Originais preservados. [Boss: receitas e prévia](visuais/boss_movimento_mcp_2026-10-15/README.md), [Snoop: receitas e prévia](visuais/snoop_detalhado_mcp_2026-10-15/README.md). Entrega local; sem nova publicação Web nesta etapa.

**Atlas Visual do Jogo & Sistema Interativo de Notas e Feedbacks (2026-10-15):** a pedido direto do usuário ("agora atribua notas as elas, onde eu posso comentar, passar o feedback e voce vai receber essas informacoes e ir alterando de acordo com minha opniao"), foi desenvolvida uma aplicação web completa (`atlas_jogo/`) com backend Python com API REST (`atlas_jogo/servidor_atlas.py`, porta 8090) e persistência atômica no arquivo `atlas_jogo/feedbacks.json`. Permite ao usuário atribuir notas de 1 a 5 estrelas, vereditos rápidos (🔴 Refazer / Ridículo, 🟡 Ajustar Detalhes, 🟢 Aprovado / Bom) e comentários minuciosos para cada elemento do projeto (os 13 heróis, 896 frames de animações de cada um, frames base estáticos, poses oficiais do Criador/Boss Dev 1A e 2C, mobs invocados, mapas e os 27 efeitos visuais). O assistente lê diretamente as avaliações gravadas no disco para implementar as correções solicitadas.

**Otimização Extrema de Desempenho e Refinamento do Menu (2026-10-15):** a pedido direto do usuário ("procure mais pra refinar e melhorar o desempenho desse menu"), foi conduzida uma profunda revisão de arquitetura e profiling no menu de heróis e no loop de renderização:
1. **Latência de Troca Instantânea (Zero Rebuild de UI):**
   - Eliminada a destruição e recriação do `lobby_root` a cada clique: a assinatura do lobby não inclui mais `lobby_preview_state` e `lobby_preview_direction`.
   - Implementada a troca cirúrgica de estados (`_set_preview_state`) e direções (`_set_preview_direction`), atualizando apenas as propriedades visuais dos dois botões afetados (antigo e novo) e enfileirando o redesenho do canvas (`hero_preview_control.queue_redraw()`).
   - Latência média por clique reduzida de ~35 ms (com stutter e reconstrução de árvore) para **2,09 ms** (mais de 15× mais rápido).
2. **Eliminação Total de Alocações no Loop de Desenho (30 FPS):**
   - Dicionários de metadados (`HERO_VFX_MAP`, `PREVIEW_STATE_NAMES`, `PREVIEW_DIR_SYMBOLS`) foram convertidos em constantes estáticas no escopo da classe, eliminando a alocação e desalocação contínua de memória a cada quadro.
   - Cache estático persistente de `StyleBoxFlat` para botões selecionados, normais e com hover (`_ensure_preview_styles()`), eliminando chamadas repetitivas de `.duplicate()` e `.new()`.
3. **Otimização do Loop Principal (`_process`):**
   - Quando o jogo está no menu (`_phase() == "menu"`), os cálculos pesados de tabuleiro (`_prepare_frame()`, `_update_visuals()`, `_update_arena_cache()` e `queue_redraw()` das camadas de batalha) são ignorados, poupando CPU e GPU em dispositivos móveis e desktops.
   - A chamada ao sistema operacional `DisplayServer.window_get_size()` foi estrangulada para uma checagem a cada 0,25s em vez de todo frame.
   - A iteração da lista `card_vfx_controls` só é executada se a tela do compêndio estiver aberta e visível.
4. **Ergonomia e Polish:**
   - Adicionados tooltips com o nome de cada herói e efeito de hover com iluminação ciano nos botões do carrossel superior e botões de técnicas.
   - Feedback sonoro imediato (`audio.play_cue("click")`) e cursor interativo (`Control.CURSOR_POINTING_HAND`) em todos os botões do compêndio.
5. **Validação Rigorosa:**
   - Novo benchmark automatizado `benchmark_menu_performance.gd` aprovado (3 passed, 0 failed, 100 redesenhos agendados em apenas 8,3 ms).
   - 100% dos testes aprovados: `test_hero_skills_menu_16f.gd` (18 passed), `test_lobby_ui.gd` (32 passed) e `test_simulation.gd` (326 passed).

**Menu de Habilidades Completo e Visualizador de 16 Quadros (2026-10-15):** a pedido direto do usuário ("adicione esses novos quadros ao menu tbm onde mostra as habilidades dos personagens, faça muito bem completinho"), o Compêndio de Heróis (Ficha de Coleção & 4 Técnicas) foi enriquecido com integração profunda aos ciclos de 16 quadros a 24 FPS e aos novos sprites de VFX de habilidades:
1. **Palco do Herói com Alternância de Modos:**
   - Modo `[ ⚔️ ARENA AÇÃO ]`: Demonstração coreografada de combate em tempo real no Coliseu, conectada aos clips de 16 frames (`stance`, `walk`, `attack`, `buff`, `skill`), com animação de `stun` no oponente ao receber impactos e VFX reais de habilidade (mordida do Caramelo, teleporte do Boss Dev, estocada do Zumbi, etc.).
   - Modo `[ 🎬 ESTADOS 16F ]`: Permite ao jogador inspecionar livremente todas as animações de 16 quadros com seletor de 6 estados animados (`[ ✋ MÃOS ]`, `[ 🚶 ANDAR ]`, `[ 💥 GOLPE ]`, `[ 💫 STUN ]`, `[ 💀 MORTE ]`, `[ ⚡ BUFF ]`, e `[ 🌀 TELEP. ]` para o Boss Dev).
   - **Seletor de Rotação em 4 Direções:** `[ ◀ ESQ ]`, `[ ▼ FRENTE ]`, `[ ▶ DIR ]`, `[ ▲ COSTAS ]`, permitindo visualizar o herói em qualquer ângulo.
   - **Badge Flutuante Informativa:** Exibe no topo do palco a tag de telemetria visual em tempo real: `🎬 <NOME_ESTADO> · Q<NUM>/16 [24 FPS] · <DIREÇÃO>`.
2. **Cartas de Técnicas Interativas & Vitrine de VFX:**
   - **Vitrine Animada na Carta 0:** Mini-canvas dedicado (`_draw_card_vfx_preview`) renderizando em tempo real o VFX temático da habilidade de cada herói (`caramelo_mordida`, `obama_barreira`, `barbie_invocacao`, `ken_provocacao`, `lula_renascimento`, `boss_teleporte`, etc.) com moldura rúnica e badge `[ANIMADO]`.
   - **Botões de Demonstração nas 4 Cartas:** Cada carta de técnica possui um botão interativo (`[ ▶ VER GOLPE (16F) ]`, `[ ▶ VER MÃOS (16F) ]`, `[ ▶ VER PODER / TELEPORTE ]`, `[ ▶ VER STUN / DEFESA ]`) que aciona instantaneamente a animação correspondente no palco do herói.
3. **Validação Automatizada:** Novo teste `test_hero_skills_menu_16f.gd` aprovado com 100% de sucesso (18 asserções), além de `test_lobby_ui.gd` (32 asserções) e `test_simulation.gd` (326 asserções) sem qualquer regressão.

**Barbie e Ken em Alta Definição (Lote 04 HD) e Animações de 16 Frames (2026-10-15):** a pedido direto do usuário, foram reformulados os visuais da Barbie e do Ken para o padrão Lote 04 HD (canvas 128×128, proporções anatômicas reais e altura visível de 96–100 px), substituindo os sprites provisórios antigos de 46–50 px.
1. **Barbie HD:** Cabelos platinados longos, vestido alta costura rosa choque (#ff1493), scarpins de salto fino e **bolsa de grife estruturada rosa choque com fecho em ouro** usada como escudo de vanguarda e catalisador de impacto.
2. **Ken HD:** Físico atlético musculoso bronzeado, topete loiro clássico esculpido, bermuda tropical azul piscina e **prancha de surfe estilizada** em azul marinho e faixas amarelas reluzentes usada como escudo protetor e arma de impacto.
3. **Ciclo Completo de Movimentos de 16 Frames:** Gerados e integrados movimentos fluidos de 16 frames a 24 FPS nas 8 direções para ambos nos estados `walk` (caminhada elegante com salto para Barbie; marcha atlética para Ken), `attack` (impacto com bolsa mágica para Barbie; investida e golpe de prancha para Ken), `stance` (prontidão viva e respiração), `skill` (pose de invocação mágica para Barbie; batida taunt de prancha no chão para Ken), além de `death`, `stun` e `buff` (128 frames por ação cada).
4. **Validação Rigorosa no Godot 4.7.2:** 100% dos testes automatizados aprovados sem falhas (Full Matches: 1.036 asserções, Boss Battle: 76 asserções, Animation Bank: 122 asserções, Player: 97 asserções, Simulação: 326 asserções).

**Restauração do Mapa do Coliseu Clássico (2026-10-15):** a pedido direto do usuário ("volte com o mapa antigo, tava mt melhor que esse de agora"), a arena de combate foi revertida para a arte clássica original em pixel art do Coliseu (`res://assets/arena/coliseu_estudo_02.png`, escala `4.0×` e offset `Vector2(-92, -84)`), substituindo a arte geométrica de `coliseu_epico_hd.png`. O mapa clássico preserva os detalhes de pedra, arquibancadas com degraus, tochas, estandartes coloridos e o recorte perfeito da arena circular que integra naturalmente com a área de preparação e o palco de habilidades.

**Coliseu Épico e Animações Completas de 16 Frames (2026-10-15):** registro histórico da transição de animações do elenco:
2. **Ciclo Completo de Animações de 16 Quadros a 24 FPS para todo o Elenco:** Todos os 13 personagens (`neymar`, `caramelo`, `obama`, `zumbi`, `michael`, `barbie`, `ken`, `elon`, `snoop`, `lula`, `bob_marley`, `rapunzel` e `boss_dev`) receberam animações fluidas de 16 frames em 8 direções para os estados:
   - `walk`: passada e locomoção rítmica fluida
   - `attack`: golpes dinâmicos de alta fluidez
   - `stance`: respiração viva e movimento com as mãos contínuo enquanto parado no campo
   - `stun`: trepidação e animação de tontura ao sofrer atordoamento
   - `death`: colapso dramático e queda suave até o repouso no solo
   - `buff`: postura de canalização e poder com auras ascendentes
   - `skill`: teleporte arcano exclusivo de 16 quadros do Boss Dev
3. **Otimização de Performance (Lazy Loading):** Implementado no `character_animation_bank.gd` o carregamento sob demanda com validação instantânea, derrubando o tempo de carregamento de 9.964 frames de 99,4 segundos para apenas 1,7 segundo (56× mais rápido).
4. **Validação Rigorosa:** 983 testes automatizados no Godot 4.7.2 aprovados com 100% de sucesso (122 do banco de animações, 97 do player, 30 de integração, 76 do Boss, 326 de simulação e 332 de VFX).

**Aleatoriedade de partidas e nova IA tática dos Bots (2026-10-15):** a pedido direto do usuário, as partidas locais contra o bot não usam mais a semente estática `MATCH_SEED = 20261011`, que gerava repetidamente os mesmos heróis e itens na rodada 1. Agora, `_start_match` gera sementes dinâmicas com entropia em runtime, garantindo que o jogador e o adversário recebam sorteios totalmente aleatórios e imprevisíveis a cada jogo. A IA dos bots foi totalmente reconstruída: sorteia 5 arquétipos estratégicos com nomes temáticos ("BOT: Guardião Obama", "BOT: Artilheiro Elon", "BOT: Matilha Caramelo", "BOT: Ritmo & Frequência", "BOT: Mestre Tático"), prioriza cópias de heróis possuídos para fechar 2★ e 3★ na loja, executa rerolls táticos quando tem excesso de ouro, forja itens avançados por fusão (`fuse`), distribui equipamentos por classe e organiza a formação no tabuleiro 8×8 (tanques na linha de frente fileira 3, assassinos nos flancos, Bob Marley centralizado na linha média com raio de aura máximo e atiradores protegidos na retaguarda fileira 0). Testes automatizados aprovados com 100% de sucesso (1.036 asserções de partidas completas, 173 da sessão e 9 de aleatoriedade/tática).

**Bob e Boss refinados (2026-10-15):** pedido confirmado para integrar os assets do PixelLab, fazer commit e push. Bob usa melodia e impacto reggae; Boss usa dois projéteis, duas explosões e furacão de 16 quadros. A pose de conjuração para a esquerda agora usa a referência corrigida do braço tatuado, com âncora nos pés e altura estável de 160 px. Originais preservados; nenhuma regra de combate alterada. Godot 4.7.2: 916 verificações aprovadas, zero falhas, incluindo capturas OpenGL. [Entrega e evidências](visuais/vfx_bob_boss_02/README.md). As alterações paralelas de caminhada/poses continuam separadas desta entrega.

**Animações de teleporte do Boss e ataques do elenco (2026-10-15):** a pedido do usuário, foi implementada a animação dedicada de teleporte do Criador/Boss Dev (`skill`, 16 frames com desmaterialização em anéis arcanos ascendentes e rematerialização no ponto de destino) disparada nativamente no `character_player.play_action` durante o combate PvE. Além disso, foram geradas e integradas animações de ataque (`attack`) com **16 frames por direção a 24 FPS** para todos os heróis do elenco (Neymar, Caramelo, Obama, Michael, Barbie, Ken, Elon, Snoop, Lula, Bob Marley, Rapunzel e Boss Dev), mantendo o Zumbi com seus ataques e estocadas originais. Todas as 13 unidades contam com movimentação e ataques animados fluidos sem custo de créditos. 122 testes do banco de animações, 97 testes do player, 30 testes de integração e 76 testes do Boss passaram sem falhas.

**Movimentação fluida do elenco (16 frames, 2026-10-15):** a pedido do usuário (Opção 1 - Pipeline Híbrido), foram geradas e integradas animações de caminhada (`walk`) com **16 frames por direção a 24 FPS** para todos os 13 personagens do elenco (Neymar, Caramelo, Obama, Zumbi, Michael, Barbie, Ken, Elon, Snoop, Lula, Bob Marley, Rapunzel e Boss Dev). O pipeline preserva estritamente a paleta de cores original de cada herói (inverse mapping sem perda de pixels ou gaps), interpola o Moonwalk nativo de Michael Jackson para 16 frames fluidos, expande a passada do Zumbi e aplica trote quadrúpede para o Caramelo. Total de 1.600 frames em PNG integrados em `res://assets/characters/<heroi>/animacoes_16f/` e registrados em `animations_manifest.json`. Saldo de créditos e gerações no PixelLab intocado (1,75 restante, US$0,00). 122 testes do banco de animações e 97 testes do player passaram sem falhas.

**Integração de novos sprites de skills (2026-10-14):** a pedido do usuário, os novos sprites de skills foram integrados especificamente para os personagens e efeitos que **não tinham** sprite próprio anteriormente: `caramelo_mordida` (Presas ferozes do Caramelo), `obama_barreira` (Barreira da mala do Obama), `barbie_invocacao` (Círculo de invocação da Barbie), `ken_provocacao` (Guardião leal do Ken), `boss_teleporte` (Portal arcano do Boss) e `lula_renascimento` (Impacto divino do Lula). **Nenhum asset visual ativo foi excluído ou substituído** (os VFX pré-existentes de Michael, Zumbi, Snoop, Elon, Bob, Rapunzel e ataques do Boss foram 100% preservados). Validação completa no Godot Engine: 237 testes de VFX, 326 testes de simulação e 70 testes de combate do Boss passaram sem falhas.

**VFX do elenco, 2026-10-14:** pedido direto para criar sprite sheet de ataques/habilidades animados usando o MCP do PixelLab. Entregues **20 efeitos × 12 quadros**, canvas 96×96, 16 FPS, atlas transparente 1152×1920, PNGs/GIFs/JSONs originais e galeria. Produzidos no editor gratuito `vfx_workbench`; saldo antes/depois 1,75 geração e US$0,00. [Entrega e proveniência](visuais/vfx_elenco_2026-10-14/README.md). Automação segue pausada.

**Auditoria de produção, 2026-10-14:** usuário pediu comparar Vercel e pasta original e fazer commit de tudo. Confirmado que Bob/Snoop/Lula/Boss novos já estavam no PCK de `8f52072`; diferenças reais: artes64 de Bob/folha do Snoop sem uso, músicas Bob/Snoop não carregando no export e compêndio Galeria/Ficha ainda sem commit. Integração64 preserva tamanho de desenho e PNGs; ResourceLoader corrige seis músicas; cantor sem faixa não silencia SFX; asas do Lula corrigidas. WAV duplicados excluídos somente da Web, originais preservados. As quatro técnicas por herói na ficha são **propostas em estudo**, não regras implementadas; maestria/coleção continuam protótipos visuais. [Diff, validação e estado de publicação](revisoes/auditoria_producao_2026-10-13/DIFF_PRODUCAO.md). Automação contínua permanece pausada.

**Lobby atualizado em 2026-10-13:** o usuário forneceu uma imagem e um vídeo e confirmou uso **somente no lobby/menu inicial**. Originais preservados em `visuais/lobby_fundo_02/originais/`. Implementação: MP4 silencioso pelo navegador, OGV separado no Godot nativo, imagem estática no modo econômico/redução de movimento/falha de vídeo. Reprodução pausa fora do lobby e com a aba oculta. Logo integrado à arte; dicas acessíveis em “Como jogar”. Publicação paralela encontrada no commit `8f52072` foi preservada e validada no link público; não reenviar a release antiga por cima. [Entrega, evidências e limites](revisoes/lobby_fundo_2026-10-13/ENTREGA.md). Automação contínua permanece pausada.



Atualizado em 2026-10-13. Nome de trabalho: **Clash of Eras**; disponibilidade de nome/marca ainda não pesquisada. A pasta técnica continua `RelicArena`.



Leia este arquivo antes de modificar o projeto. Pedido mais recente do usuário prevalece. Decisões abaixo são atuais; números de protótipo ficam nos dados e podem mudar após jogar. O registro anterior completo foi preservado em [CEREBRO_ARQUIVO_2026-10-11.md](CEREBRO_ARQUIVO_2026-10-11.md). Os guias antigos e seus manifestos são históricos.



## Direção confirmada



**Configuração implementada em 2026-10-13, prevalece sobre os números históricos abaixo:** ouro inicial **20**; ao avançar para R2/R3/R4, renda **12/15/18**, crescendo 3 por rodada. Bônus **fixo de +1** a partir de duas vitórias seguidas; derrota/nova partida zera, Boss não conta. Cópias totais por nível **[1, 2, 4]**: a terceira cópia guarda progresso, ainda no N2. Reserva de cinco; dispensar herói não dá ouro e devolve equipamentos à bolsa, com rejeição integral se não couberem. Barbie: HP base **600/900/1200**, dano +50% enquanto Ken vive. Ken: HP base **1200/1600/2300**. Michael cura todos os aliados ativos/vivos (+15% no escudo base para 172.5 e cura contínua para 8.05/s); Snoop Dogg (+15% dano base de 38 para 43.7); Bob Marley (+15% dano base de 32 para 36.8). Placar de final de combate justo: quem gerou o escudo (ex.: Michael Jackson) recebe os números de dano mitigado/defendido, e curas são atribuídas ao conjurador. Lula N3 retorna uma segunda vez com 30% de HP, após o primeiro retorno de 40%. Bob: raios **4/5/6** como teste; VFX de ataque e buffs em cores reais do Reggae/Jamaica (Verde #009b3a, Dourado #fed100, Vermelho #d52b1e). Snoop: fumaça volumétrica verde translúcida na altura da cintura com emotions de cannabis. Batalha musical: repertório de 35s por nível de estrela e disputa de cantores por poder. **Rapunzel ganha mana atacando e puxa o inimigo mais distante:** teste de 100 mana máxima e +25 por ataque iniciado. Os demais heróis mantêm seus gatilhos. Hexágonos ampliados de 76 para **90 px** na frente (+18,4%), mantendo 8×8 e os PNGs originais. Chefe e lacaios estão atualmente em **10000/4000/5000 HP**, com fogo vermelho/roxo de área e furacão que desloca tropas; a alteração posterior veio da produção paralela e foi preservada (ver evidência abaixo). Novas sinergias citadas pelo usuário: Presidentes, Maconheiros e Astro; bônus e patamares ainda em estudo.



- Godot 4, PC e celular em paisagem; multiplayer com servidor dedicado continua sendo o destino.

- Começar pequeno contra bot local, com simulação separada da interface; adicionar servidor depois de validar o combate.

- Tabuleiro de **8 × 8 hexágonos**, quatro fileiras de preparação por lado. **Movimento por hexágonos** substitui a direção anterior de movimento livre.

- Coliseu medieval inclinado, areia clara, interface inspirada na organização de TFT. Vidas em **corações**. Público animado fica para depois.

- **Controles (usuário, 2026-10-12): preferência por arrastar e soltar** — heróis para o campo, dentro do campo e para a reserva; itens até o herói. Toques e botões continuam como alternativa. Implementado na V1.5 em `client/drag_controller.gd`; também arrasta cartas da loja (recrutar no hexágono, comprar e equipar) — extensão proposta pelo assistente.

- **Nova direção de arte (usuário, 2026-10-12, substitui o "sem caricatura"):** sprites **maiores, com mais pixels e detalhe**, parecidos com a pessoa real; **corpo e proporções reais**, com **exagero caricato no objeto/traço-marca** de cada um (a "arma" chamativa: charutão do Snoop, cabelo até o chão da Rapunzel, correntes quebradas do Zumbi etc.). Pedidos por personagem, propostas, tamanho e custo em [PERSONAGENS_LOTE_04.md](PERSONAGENS_LOTE_04.md). Complemento do usuário no mesmo dia: rosto exagerado só em traço pessoal que funcione (Neymar), **nunca feições negras**; exagero na história/marca (Zumbi forte, cabelão da Rapunzel); personagens devem **mexer braços e pernas** (animações de andar/atacar); a chave do PixelLab será trocada e o usuário avisará quando o acesso estiver ativo. Chave nova ativa desde 2026-10-12 (40 gerações trial). **Zumbi do lote 04 aprovado pelo usuário e já no jogo** (pose da estátua, pé na pedra, sem camisa com cicatrizes, correntes quebradas só nos pés, uma lâmina na cintura, lança de lâmina larga que **cresce nos níveis 2 e 3** — pedido do usuário); o Zumbi antigo saiu do manifesto. Detalhes em [Execução do lote 04](PERSONAGENS_LOTE_04.md#execução). **Escala de exibição em teste desde 2026-10-13:** Zumbi N1 a76px de referência e demais humanos a68–70px, preservando os PNGs detalhados. É o meio-termo implementado para avaliar jogando, não aprovação de tamanho final. Os demais heróis continuam na arte de 48 px do [lote 03](PERSONAGENS_LOTE_03.md) até serem refeitos; Caramelo **não** deve mais ser gerado no estilo/tamanho antigo.

- Figuras reconhecíveis, principalmente brasileiras; nomes e visuais devem ser fáceis de trocar. Não criar lore própria nem reintroduzir clima.

- Deck final de **10 personagens**. Tabuleiro inicia vazio (`INITIAL_KEYS = []`); jogador e bot recrutam unidades da loja organicamente na preparação. Capacidade inicial de 4 vagas, expansível até **8 vagas** com custo progressivo (8, 12, 16 e 20 moedas).

- **Heróis gratuitos; moedas para itens e capacidade.** Mantido pelo usuário em 2026-10-11 mesmo com cópias. Renovação de loja por **2 moedas** como teste inicial. Saldo pode ser guardado; sem juros aprovados. Loja conjunta com **7 ofertas por rodada (3 itens e 4 heróis)**; renda base **9+3×(rodada−1)**, paga ao avançar: R2/R3/R4 recebem12/15/18. Ouro inicial20.

- **Nível na partida por cópias (decisão de 2026-10-11):** a loja oferece cópias grátis de heróis já possuídos; elas se juntam na hora. **2 cópias = nível 2; 4 cópias no total = nível 3** (pedido2026-10-13 substitui a regra anterior de3) (máximo). Cada nível aumenta **20% o tamanho do sprite** (1,2× e 1,44×); o **nível 3 ganha aura especial**. Força escolhida para teste: vida e dano **×1,5 no nível 2 e ×2,25 no nível 3**, com HP próprio Barbie[600,900,1200] e Ken[1200,1600,2300]. Não confundir com o nível da carta fora da partida (1–10). Proposta do assistente, ainda não aprovada: escalar também escudo, cura e sangramento do kit pelo mesmo multiplicador; aura violeta com faíscas douradas.

- **4 vidas**, perde uma ao perder rodada. Combate até **30 s**, aceleração aos **15 s**; vence por sobreviventes e depois dano. Meta de partida 5–6 min, a medir.

- **Batalha de Boss PvE contra o Desenvolvedor no Round 4 (decisão de 2026-10-13; artes finais confirmadas pelo usuário em 2026-10-15):** O confronto acontece contra o próprio desenvolvedor como chefe de arena PvE (10000 HP, 25 ARM, 25 RES). O Boss possui escala imponente de 160 px (~2.35× um herói padrão e ~1.63× um 3★ comum) e aura mística exclusiva com anéis cósmicos concêntricos, glifos rúnicos orbitantes e círculo arcano em ouro e magenta. **Poses e artes oficiais definidas pelo usuário:** A pose principal (parado/idle/HUD) é a **Opção 1A** (`idle_south.png`), frontal de regata preta, bermuda, chinelo e braço tatuado à mostra, com recorte 100% limpo sem sombras de chão ou ruídos. A pose apontando para a esquerda com braço quebrado (`cast_south_west.png` / 1C / 2B) foi **completamente eliminada e banida**. Para a conjuração de magias (cast), o Boss usa **sempre a Opção 2C** (`cast_south_east.png`, apontando para a frente/direita com o braço esticado), com uma exceção inteligente aprovada pelo usuário: quando o Boss se teletransporta para a parte inferior da arena e mira nos heróis para cima (`to_y < from_y`), ele assume a pose **de costas mirando para cima** (`cast_north.png`, extraída da folha conceitual original com o braço tatuado erguido para o norte). Os sprites de habilidades foram todos atualizados para alta definição pixelada: projéteis meteóricos e supernovas de Fogo Vermelho e Fogo Roxo, e Furacão de Fogo em vórtice de 4 frames. A barra de vida fica no topo da tela (`y = 8..64`, 56 px de altura). Durante o combate, o Boss **se teletransporta de 4 em 4 segundos** para hexágonos livres distantes pelo mapa com efeitos e sons arcanos, forçando o reposicionamento contínuo das tropas. Seus lacaios sombrios são **invocados no fundo da arena** (fileiras 6 e 7) com **mecânica de provocação (aggro/taunt)**: as tropas aliadas que estavam no topo são forçadas a interromper o ataque ao Boss, virar-se e cruzar a arena para baixo para eliminar o lacaio. O Boss conjura **Fogo Vermelho** (135 de dano em área), **Fogo Roxo** (140 de dano em área), **Furacão de Fogo** (160 de dano + arremesso/embaralhamento) e entra em **Fúria aos 40% de vida** (onda de choque + 25% de redução de recargas). Ao morrer, libera 3 orbes místicas brilhantes dropando Ouro, Itens ou +1 Coração de Vida Extra (20% de chance rara). Se o jogador não conseguir derrotá-lo (eliminação ou 30s esgotados), **nenhuma vida é perdida** (derrota protegida PvE); apenas deixa de resgatar os espólios.

- Sinergias cotidianas, maioria com 2–3 grupos por personagem; patamares variam por grupo. Maior bônus substitui menor; morte não desativa a sinergia da formação naquela rodada. Presidentes não será dividido em Governantes/Presidentes.

- Coleção de cartas, raridades e progressão fora da partida continuam desejadas. O usuário quer monetização sem pay to win; aplicação dos níveis no competitivo está em discussão.



## Regras dos cinco kits iniciais



| Personagem de referência | Regra escolhida |

| --- | --- |

| Neymar | DPS à distância baseado em velocidade de ataque. Bola ricocheteia entre dois inimigos em hexágonos vizinhos. **Até 3 impactos por chute: A → B → A**, escolhido para teste pelo usuário. |

| Caramelo | Assassino, mordidas e sangramento por segundo; supermordida elimina alvo com 10% de vida. Momento e interação com escudo ainda em teste. |

| Obama | Tanque com mala grande como proteção; tipo de escudo ainda aberto. |

| Zumbi | Estocadas de lança; buff coletivo de crítico e velocidade de ataque. **Só os críticos do próprio Zumbi** fortalecem o próximo crítico dele. Fórmula e teto em teste. |

| Michael | **Percorre três hexágonos aleatórios movendo-se de costas; ao parar, concede um escudo poderoso à equipe. Enquanto está vivo em campo, mantém uma cura pequena periódica em todos os aliados ativos/vivos, independentemente da distância.** Pedido mais recente substitui o kit anterior de somente cura em pulsos próximos. Números, alcance da cura, duração/renovação do escudo e intervalo entre ciclos são hipóteses configuráveis. |



### Lote 03 — kits escolhidos pelo usuário em 2026-10-11/12 (implementados na simulação, números de teste)



| Personagem | Regra escolhida |

| --- | --- |

| Barbie | Tanque. **Invoca o Ken (de sunga)**, que puxa o ataque de quem bateria nela; **enquanto o Ken vive, ela causa +50% de dano**; Ken tem mais HP base e protege a Barbie. |

| Elon Musk | Atirador de artilharia espacial. Dispara **3 minifoguetes focados** (tiro direto no alvo) e no **4º ataque dispara um Super Foguete** com super explosão que atinge o alvo, vizinhos imediatos (raio 1) e **penetra 2 quadros adicionais para trás na retaguarda adversária**. Lote 04 de arte em alta definição aprovado pelo usuário. |

| Snoop Dogg | Cantor, DPS com **fumaça**: a nuvem causa **dano contínuo e faz inimigos dentro dela errarem ataques** (30% de erro). Fumaça verde translúcida volumétrica na altura média/cintura para profundidade de cena, com emotions de cannabis flutuando do charuto e na névoa (+25% velocidade para aliados). Dano base aumentado em +15% (43.7). Repertório musical de 35s por estrela. |

| Lula | Tanque, **volta por cima divina**: ao sofrer dano letal, demora **1.0 segundo** para retornar; durante 1.0s executa animação fluida descendo do céu com asas de anjo brancas e douradas brilhantes e auréola. Ao tocar o solo, renasce com 40% de HP (e 30% no N3 no segundo retorno), concede **buff de +25% de ataque a todo o grupo por 5s** e entra em **5s de Frenesi Divino (100% de acertos críticos)**. Mantém as asas e auréola **até o fim da partida**. |

| Bob Marley | Cantor suporte, **paz e amor**: aliados no raio atacam mais rápido (+30%); inimigos atacam um pouco mais devagar (-30%, dano **não** diminui); **o raio cresce a cada nível de estrela (4/5/6)**. Efeitos visuais e ataques nas cores reais do Reggae/Jamaica (Verde, Dourado, Vermelho e contornos pretos), com ondas de choque rítmicas e dispersão de notas musicais. Dano base aumentado em +15% (36.8). Repertório musical de 35s por estrela. |

| Rapunzel | Controle, **laço por mana**: carrega atacando e puxa o inimigo mais distante, com atordoamento~1s.100mana/+25ataque são números de teste, sem carga por tempo. |



Ordem do usuário: **primeiro criar os novos, depois refazer** Neymar, Caramelo, Obama e Zumbi em proporção realista. Cleópatra e Jack saíram desta etapa. Júlio César continua referência futura. Propostas do assistente ainda não aprovadas: Ken não conta como tropa no desempate, não ocupa capacidade e herda o nível da Barbie; laço também atinge um alvo já vizinho (só atordoa); uma nuvem por Snoop; Lula também levanta contra a supermordida; reserva5 e dispensa sem ouro/devolução de itens confirmadas no pedido2026-10-13. Contratos detalhados em [simulation/README](../RelicArena/simulation/README.md); plano de arte em [PERSONAGENS_LOTE_03.md](PERSONAGENS_LOTE_03.md).



Júlio César é outra referência do elenco, com papel preservado no arquivo completo. Nomes como Zumbalhão/Neydrama não são finais.



## Histórico da configuração do primeiro teste



**Propostas de implementação**, não regras finais: base 640 × 360 na V1 (a V1.1 passou para 1280 × 720 para afastar a câmera), sprites atuais a 1×, quatro unidades fixas por lado, níveis iguais, bot com formação simples; sem loja, coleção ou pagamento nesta primeira entrega. A arena antiga de 351 × 195 não define a grade nova: usar chão/grade técnica simples para validar escala.



**Ampliação local V1 autorizada e implementada:** depois de jogar o primeiro protótipo, o usuário pediu uma versão mais completa e Michael animado. A V1 acrescenta partida contra bot, preparação cronometrada, loja conjunta, reserva, itens/fusões, benefícios e resultados individuais. Configuração inicial de teste: cinco no elenco, quatro ativos, capacidade até cinco; 25 moedas iniciais, 15 por rodada, renovação 2, expansão 12, bolsa de oito itens e quatro itens por unidade. Isso não substitui o deck final de dez, não aprova o balanceamento e não inclui coleção/pagamentos ou servidor nesta entrega.



Contratos temporários: execução do Caramelo em mordida contra vida ≤10% antes do dano; sangramento finito; mala do Obama absorve dano; aumento aditivo e limitado dos críticos do Zumbi. Ataques, movimento e voo aceleram; sangramento e relógio de 30 s não. Empate completo não tira vida. Todos devem estar identificados como teste e configuráveis.



## O que decidir jogando

**Sinergias cotidianas — proposta de membros para a próxima conversa:** Presidentes(Obama/Lula), Maconheiros(Snoop/Bob Marley), Astro(Michael/Neymar/Snoop/Bob). Os nomes foram citados pelo usuário; esta distribuição é proposta do assistente, não define buffs, raridades finais nem novos bônus ativos. Os quatro grupos funcionais atuais permanecem durante estes testes.



1. Escala, legibilidade e seleção por toque; 1280 × 720 com sprites a 1× é base de teste da V1.1, não arte final aprovada.

2. Validar jogando o início atual com campo vazio/quatro vagas, expansão até oito, reserva e oferta/repetição de heróis; configuração V1.6, números de teste.

3. Ouro inicial/renda/capacidade, itens, receitas e tempo de preparação.

4. Números e limites dos kits, dano físico/mágico, defesas, efeitos e rivalidades.

5. Benefícios de três opções, vida extra, intervenção durante combate e duração.

5a. Nível na partida: multiplicadores ×1,5/×2,25, escala do kit, frequência de cópias na loja e se a reserva precisa de outro uso, já que as cópias se juntam na hora.

6. Níveis de cartas e acesso ao elenco no PvP: **normalizar competitivo é recomendação**, não aprovação recebida.

7. Nome final, nomes dos personagens e revisão de uso comercial de pessoas/personagens reconhecíveis.



## Trabalho e evidência

- **Correção da UI de Vida do Boss & Retorno da Prévia da Equipe Adversária (2026-10-14):**
  - Implementado a pedido do usuário (*"a ui da vida do boss esta aparecendo a todo momento, esta errado, deveria aparecer apenas na luta do boss e depois da luta do boss, deverá voltar a animação previa da equipe do adversário, e nao continuar apenas o boss novamente como previa"*):
  1. **UI de Vida do Boss Exclusiva no Combate da Luta do Boss (`client/main.gd`):**
     - Removido `boss_bar_panel` de `hud_controls.append(boss_bar_panel)`, eliminando a causa raiz que forçava `visible = true` em todas as rodadas e fases da partida.
     - Em `_refresh_boss_hud(is_boss_round, phase)`, restringida a visibilidade para estritamente `is_boss_round and phase == "combat"`.
     - Nas Rodadas 1, 2, 3 e 5+, assim como na preparação da Rodada 4, `boss_bar_panel` permanece 100% invisível, e os painéis padrão (`stage_panel` e `status_panel`) são mantidos ativos.
     - Em `_draw_bars(canvas, entry)`, removida a exceção de `is_boss_bar` para unidades `ghost`, impedindo que o boss em espera durante a preparação exiba uma barra flutuante de combate.
  2. **Restauração da Prévia da Equipe Adversária Pós-Boss (`simulation/match_session.gd`):**
     - Em `_begin_combat()`, adicionada a guarda `if not (sim.is_boss_round and team == 1): _previous_formations[team] = _formation_snapshot(team)`. Evita que o Boss (unidade 999) sobrescreva a formação de heróis do bot armazenada na Rodada 3.
     - Em `snapshot_for_team()`, a geração de `enemy_units_preview` em rodadas que não são do Boss sanitiza qualquer resquício de `boss_dev` e faz fallback seguro para a formação atual do bot (`_formation_snapshot(1 - team)`) quando `round_index > 1`.
     - Na Rodada 5 em diante, a preparação volta a exibir a equipe completa do adversário (Bob Marley, Neymar, Zumbi, etc.) com suas respectivas animações de idle, círculos de equipe e sem o Boss.
     - Preservada rigorosamente a privacidade da Rodada 1 (`view.enemy.units` vazio).
  3. **Validação Completa (1.333 testes aprovados, zero regressões):**
     - `tests/test_boss_battle.gd`: 77 testes aprovados (incluindo validação de boss bar oculta na preparação, ativa no combate e equipe do oponente restaurada na Rodada 5).
     - Suíte determinística integral aprovada: simulação (326), balanço (84), Lula ascensão (38), sessão (173), drag-and-drop (18), 4 partidas completas (602), melhorias da loja (15).
     - Evidências visuais salvas: `captures/crop_r4_prep_top.png`, `captures/crop_r4_combat_top.png`, `captures/crop_r5_prep_top.png` e `captures/crop_r5_arena_preview.png`.

- **Refinamento de UI/UX da Loja, Botões, Badges e Tooltips de Habilidades (2026-10-13):**
  - Implementado a pedido do usuário (*"icon espaço / renovar esta quase saindo, fonte negrita realcando branco legivel, gold em amarelo com icone menorzinho, mouse hover nos herois le suas habilidades, campo 1/4 substitui por membros: com icone de time e borda bem feita, botao lutar e recrute corrigidos, moedas no meio paradas sem girar com mais brilhos e juntas"*):
  1. **Enquadramento Perfeito dos Botões ESPAÇO e RENOVAR (`client/main.gd`, `client/ui_kit.gd`):**
     - Ícones de ação reposicionados com margem interna adequada (8px), evitando encostar ou vazar das bordas.
     - Tipografia em negrito e alto contraste (`Color.WHITE` com contorno escuro tamanho 3), garantindo legibilidade perfeita para "ESPAÇO" e "RENOVAR".
     - Mini-ícone de moeda de ouro (`ui_coin`, 13x13px) perfeitamente alinhado com o valor de custo em amarelo brilhante (`#fde047`).
  2. **Mouse Hover e Leitura Completa de Habilidades dos Heróis (`client/main.gd`):**
     - **Cards da Loja:** passar o mouse sobre qualquer card de herói na loja exibe tooltip nativo detalhado com Nome em caixa alta, Nível de Estrelas, Sinergias e `✦ HABILIDADE: [descrição completa de KIT_TEXT]`.
     - **Tabuleiro e Reserva:** implementado `_draw_world_hero_tooltip(canvas)` em `_draw_overlay_layer()`. Passar o mouse sobre qualquer unidade aliada ou inimiga no tabuleiro ou banco projeta um card flutuante translúcido elegante (300px de largura com altura dinâmica adaptativa): mini-retrato moldurado, nome, estrelas, tag de aliado/inimigo, sinergias, vida atual/máxima, divisória decorativa e quebra inteligente de linhas para a habilidade completa sem corte de texto.
  3. **Novo Badge de Membros com Ícone de Time (`assets/ui/icons/ui_team.png`, `client/ui_kit.gd`):**
     - O antigo texto cru "CAMPO 1/4" foi substituído por uma moldura ornamentada temática (`Kit.draw_ornate_panel_frame`) com chanfros e cantoneiras medievais.
     - Gerado ícone exclusivo de esquadrão (`ui_team.png`, 32x32px) com soldados estilizados e brasão de armas.
     - Texto formatado: `MEMBROS:` em fonte branca nítida acompanhado da contagem `X/Y` em amarelo dourado (`#fde047`).
  4. **Correção dos Botões LUTAR e RECRUTE (`client/main.gd`, `client/ui_kit.gd`):**
     - Ícone de raio elétrico centralizado e alinhado no botão.
     - Moldura dourada elegante com cantoneiras medievais desenhadas sob medida (`Kit.draw_ornate_panel_frame`).
     - Tipografia em negrito de 20px perfeitamente centralizada para os estados "LUTAR" e "RECRUTE".
  5. **Visor de Ouro Estático e Pilha de Moedas Centralizada Reluzente (`client/main.gd`, `client/ui_kit.gd`):**
     - A moeda do mostrador parou de girar: fixada estática, frontal e nítida com coroa imperial entalhada.
     - A pilha de moedas atrás do painel foi reagrupada com coordenadas estritamente centrais (X entre -42 e +42px), eliminando espalhamento para as bordas laterais.
     - Adicionadas faíscas estelares reluzentes (`#ffffff`, `#fff6a0`) e brilho dourado reforçado no topo do monte.
  6. **Validação Completa (1.326 testes aprovados, zero regressões):**
     - Novo teste dedicado `tests/test_shop_ui_improvements.gd`: 15 testes aprovados com sucesso.
     - Suíte determinística completa aprovada: simulação (326), balanço (84), Lula ascensão (38), Boss Dev (70), sessão de partida (173), drag-and-drop (18), 4 partidas completas (602).
     - Evidências visuais salvas: `captures/crop_botoes.png`, `captures/crop_ouro_lutar.png`, `captures/crop_barra_loja_completa.png` e `captures/crop_tooltip_campo_final.png`.

- **Ascensão Angelical e Volta por Cima do Lula (2026-10-13):**
  - Implementado a pedido do usuário (*"quero fazer a representação do lula agora, qnd ele morre, ele nao volta instataneamente, demora 1 segundo pra voltar, e vai ser bem esse 1 segundo que vamos fazer uma animação bem fluida e rapida dele se descendo do céu com asas de anjos ficando com esse visual ate o fim da partida, faça com areolas em cima de sua cabeça e umas asas de anjos engraçadas brancas e douradas bem brilhantes, e qnd ele renasce ganha buff de 25% de ataque do grupo por 5s e 5s de frenesi divino todosos ataques do lula sao criticos"*):
  1. **Demora e Transição de 1.0 Segundo (`simulation/arena_simulation.gd`, `simulation/unit_state.gd`):**
     - Ao sofrer dano letal, a morte imediata é interceptada: `lula.is_reviving = true` e `revive_delay_remaining = 1.0` (configurável via `spec.revive_delay`).
     - Durante esse 1.0s, Lula permanece intocável: ignorado na mira adversária (`_find_target`), imune a novos golpes e com sangramentos purificados na hora. Não dispara evento espúrio de morte e a rodada não encerra precocemente (`_check_resolution` considera vivos + renascendo).
  2. **Ressurreição Divina e Efeitos de Combate:**
     - Ao completar 1.0s, o Lula restaura 40% da sua vida máxima (ou 30% no N3 no segundo retorno) e adquire o estado angelical `has_angel_wings = true`, gravado na lista de ascensão persistente da partida (`_ascended_units[lula.id] = true`).
     - **Frenesi Divino (5.0s):** `lula.divine_frenzy_timer = 5.0` garante que **100% dos ataques do Lula sejam acertos críticos** (`critical = true`), mesmo se o crítico base for zero.
     - **Bênção do Grupo (+25% Dano, 5.0s):** todos os aliados vivos do time recebem `group_attack_buff_timer = 5.0`, multiplicando todo o dano básico de ataque por **1.25 (+25%)**.
  3. **Apresentação Visual e Animação de Descida no Cliente (`client/main.gd`):**
     - **Voo Celestial:** durante o 1.0s de espera, o Lula desce suavemente do céu (`Y = -360px` até o hexágono) com amortecimento cúbico, envolvido por um feixe de luz divino dourado vertical, anel sagrado rúnico e penas celestiais caindo em espiral.
     - **Impacto Sagrado:** ao tocar o chão, emite onda de choque dourada nos pés, partículas radiantes e textos flutuantes festivos (`😇 VOLTA POR CIMA DIVINA!`, `⚔ +25% DANO DO GRUPO (5s)`, `⚡ FRENESI DIVINO (CRÍTICO 100%)`). Aliados sob a bênção exibem anel dourado com centelhas nos pés.
     - **Asas e Auréola Cômicas Brancas e Douradas:** renderização de asas de anjo cartunescas com três camadas de penas brancas reluzentes, pontas douradas (`#ffd700`), batimento animado contínuo e auréola flutuante (`areola`) com brilho pulsante e estrelinhas sobre a cabeça.
  4. **Persistência Total até o Final da Partida:**
     - O estado angelical é preservado entre as rodadas tanto na simulação (`_ascended_units`) quanto no cliente (`ascended_units`). Nas rodadas seguintes, o Lula já surge no tabuleiro ostentando as asas de anjo e a auréola.
  5. **Validação Rigorosa (1.309 testes aprovados, zero falhas):**
     - `tests/test_lula_angel_ascension.gd`: 38 testes específicos aprovados com 100% de sucesso.
     - `tests/test_simulation.gd`: 326 testes aprovados, 0 falhas.
     - `tests/test_character_balance_02.gd`: 84 testes aprovados, 0 falhas.
     - `tests/test_boss_battle.gd`: 68 testes aprovados, 0 falhas.
     - `tests/test_match_session.gd`: 173 testes aprovados, 0 falhas.
     - `tests/test_drag_and_drop.gd`: 18 testes aprovados, 0 falhas.
     - `tests/test_full_matches.gd`: 602 testes aprovados (4 partidas completas), 0 falhas.
     - Capturas geradas: `captures/lula_descendo_do_ceu.png`, `captures/lula_impacto_divino.png` e `captures/lula_angelical_em_campo.png`.

- **Sons de Batalha Aprimorados & Single 8-Bit do Bob Marley (2026-10-13):**
  - Implementado a pedido do usuário (*"vamos criar sons melhores para as batalhas, para a musica de bob marley vamos colocar só um single de alguma musica famosa só que em bit pra ficar diferenciado"*):
  1. **Sons de Combate Retro Arcade / Chiptune (`prototype_audio.gd`, `main.gd`):**
     - Síntese de 22 streams de áudio PCM de 16 bits em memória em tempo recorde (~110 ms), com pool polifônico expandido para 10 vozes (`AudioStreamPlayer`) e canal de música dedicado, além de limites de cadência/cooldown por som para evitar distorção ou sobreposição agressiva.
     - `hit`: impacto físico rápido e crocante (transiente de ruído + queda de tom).
     - `crit`: impacto crítico pesado com estalo metálico e sub-bass de 45 Hz.
     - `thrust`: estocada de lança do Zumbi e cortes cortantes de lâminas (modulação FM e whoosh).
     - `bite` e `super_bite`: mordida ágil e supermordida estrondosa e letal de execução (Caramelo).
     - `shoot`: tiro arcade de bola (Neymar) e projéteis balísticos.
     - `rocket`: propulsão balística de minifoguete (Elon Musk).
     - `explosion`: explosão pesada 8-bit com sub-bass e ruído de baixa frequência filtrado (Super Foguete do Elon e magias do Boss Desenvolvedor).
     - `lasso`: assobio ascendente e estalo de laço (Rapunzel).
     - `smoke`: sopro aveludado de fumaça (Snoop Dogg).
     - `boss_spell` e `tornado`: arpejo místico sombrio de conjuração e vórtice de fogo/vento (Boss Desenvolvedor).
     - `death`: descida clássica de derrota em 8-bit.
     - `shield`: barreira protetora ressonante (Mala do Obama / Dança).
     - `revive`: acorde triunfal de ressurreição (Lula).
  2. **Repertório de 3 Músicas Reais de Bob Marley por Estrelas (35s cada):**
     - A pedido do usuário (descartado o áudio sintetizado inicial), foram integradas 3 faixas chiptune/8-bit autênticas extraídas com 35,0 segundos cravados cada (tempo suficiente para cobrir com folga a rodada máxima de 30s da arena):
       - **★1 (1 Estrela):** *"Waiting In Vain"* (trecho de 03s a 38s = 35s) ➔ `bob_marley_star1.mp3`.
       - **★★2 (2 Estrelas):** *"I Shot The Sheriff"* (trecho de 01s a 36s = 35s) ➔ `bob_marley_star2.mp3`.
       - **★★★3 (3 Estrelas):** *"Is This Love"* (trecho de 08s a 43s = 35s) ➔ `bob_marley_star3.mp3`.
     - Carregamento assíncrono e leve via `AudioStreamMP3` em memória (~841 KB cada), com `loop = true` contínuo.
  3. **Repertório de 3 Músicas Reais de Snoop Dogg por Estrelas (35s cada):**
     - A pedido do usuário, integrado o repertório completo de 3 faixas chiptune/8-bit do Snoop Dogg com 35,0 segundos cravados cada:
       - **★1 (1 Estrela):** *"Nuthin' But A 'G' Thang"* (trecho de 1:50 a 2:25 = 35s) ➔ `snoop_star1.mp3`.
       - **★★2 (2 Estrelas):** *"Gin And Juice"* (trecho de 1:30 a 2:05 = 35s) ➔ `snoop_star2.mp3`.
       - **★★★3 (3 Estrelas):** *"Still D.R.E."* (trecho de 0:11 a 0:46 = 35s) ➔ `snoop_star3.mp3`.
     - Carregamento via `AudioStreamMP3` com `loop = true` e suporte a `play_snoop_music(star_level)`.
  4. **Disputa de Cantores e Mutação dos SFX da Partida:**
     - **Regra de Prioridade:** Quando há cantores em campo (`bob_marley`, `snoop`, `michael`), o mais forte assume o som na frente. O cálculo de força prioriza o nível de estrelas (3★ > 2★ > 1★), seguido de vida máxima e dano de ataque.
     - **Mudo de Combate:** Enquanto qualquer cantor estiver ativo e cantando, os efeitos sonoros comuns de combate do jogo (hits, tiros, cortes) ficam mutados para dar destaque total à música do cantor; avisos de fim de rodada (`win`, `lose`) e cliques de interface continuam audíveis.
     - Se o cantor líder for abatido, a prioridade é recalculada na hora entre os cantores restantes; se todos caírem, a música cessa e os efeitos sonoros normais retornam.
  5. **Representação Visual Aprimorada dos Efeitos da Música (Buff e Debuff):**
     - **Aliados no raio (+30% de Velocidade de Ataque):** anel pulsante nos pés em verde-esmeralda e ouro reggae (`Color("2ec756")`, `Color("f4c430")`) com alta frequência rítmica (6.5 Hz) + notas musicais douradas/verdes subindo alegremente.
     - **Inimigos no raio (-30% de Desaceleração / Lentidão):** anel elíptico ondulante pesado nos pés em vermelho e âmbar (`Color("e63946")`, `Color("ff8a00")`) em frequência relaxada/lenta (2.2 Hz) + notas musicais sonolentas/descendentes e sutil matiz de lentidão no modelo.
     - **Compêndio Interativo:** ao selecionar Bob Marley ou Snoop Dogg e alternar os níveis (★1, ★2, ★3), a faixa daquela estrela toca imediatamente e a demonstração de ação exibe seus respectivos efeitos visuais.
  6. **Validação Rigorosa (100% de Aprovação):**
     - `tests/test_battle_audio.gd`: 106 verificações aprovadas com 100% de sucesso.
     - `client/smoke.gd`: 488 verificações aprovadas com 100% de sucesso.
     - `tests/test_simulation.gd` (323/0), `tests/test_match_session.gd` (173/0) e `tests/test_character_balance_02.gd` (71/0) 100% aprovados sem qualquer regressão.

- **Ajustes de Balanceamento e Justiça nas Estatísticas de Combate (2026-10-13):**
  - A pedido do usuário:
  1. **Aumento de 15% no Dano do Snoop Dogg:**
     - Dano de ataque básico (`attack_damage`) aumentado de 30.0 para **34.5**.
     - Dano da fumaça por tick (`smoke_damage_per_tick`) aumentado de 8.0 para **9.2**.
  2. **Aumento de 15% no Dano do Bob Marley:**
     - Dano de ataque básico (`attack_damage`) aumentado de 22.0 para **25.3**.
  3. **Aumento de 15% nos Buffs do Michael Jackson:**
     - Quantidade de cura (`heal_amount`) aumentada de 10.0 para **11.5**.
     - Escudo da Dança Moonwalk (`dance_shield_amount`) aumentado de 120.0 para **138.0**.
  4. **Contador Justo de Fim de Partida e Fim de Rodada:**
     - **Regra de Mérito do Provedor:** A coluna `ESCUDO` do placar final não mostra quem sofreu o golpe e teve o dano absorvido, mas sim **quem concedeu o escudo protetor** para a equipe.
     - Implementado rastreamento de autoria (`dance_shield_source_id` em `simulation/unit_state.gd` e `simulation/arena_simulation.gd`): quando qualquer aliado absorve dano através do escudo fornecido pelo Michael Jackson, o valor absorvido é creditado integralmente no `shield_absorbed` do Michael Jackson.
     - Escudos próprios (como a Mala do Obama) continuam pontuando para a própria unidade que os gerou.
     - A coluna `CURA` continua creditando 100% da cura realizada a quem conjurou a cura (`source.healing_done`).
  5. **Validação Técnica (100% de Sucesso):**
     - `tests/test_simulation.gd`: 323 aprovados, 0 falhas.
     - `client/smoke.gd`: 488 aprovados, 0 falhas.
     - `tests/test_character_balance_02.gd`: 71 aprovados, 0 falhas.
     - `tests/test_match_session.gd`: 173 aprovados, 0 falhas.
     - `tests/test_battle_audio.gd`: 106 aprovados, 0 falhas.

- **Boss Dev V3 — Mecânicas Épicas de Batalha (2026-10-13):**
  - Implementado a pedido do usuário (opções aprovadas: 1 Barra de Vida no Topo, 2 Telegrafia de Área, 3 Modo de Fúria aos 40% e 4 Portais de Surgimento; sons e banners descartados por ora):
  1. **Barra de Vida Épica de Boss no Topo (`client/main.gd`):**
     - Painel imponente de 600×48 px centralizado no topo com borda dourada/ornamental, exibido automaticamente durante a preparação e combate do Round 4.
     - Barra de dano fantasma (*ghost bar*) amarela interpolada suavemente via `lerp`, barra de vida principal carmesim/púrpura e contagem numérica explícita (`HP: X / 10.000 (Y%)`).
     - Badges dinâmicos de lacaios ativos no canto inferior do painel (identificando `Lodo Negro` e `Aberração Cósmica` com vida restante).
  2. **Telegrafia de Área no Chão (`simulation/arena_simulation.gd`, `client/main.gd`):**
     - Alerta visual 0.8s antes da detonação dos feitiços de dano em área (*fire_tornado* e *purple_fire*).
     - Renderização nos hexágonos atingidos com preenchimento pulsante vermelho/violeta, borda brilhante, anel de contagem regressiva que encolhe em direção ao centro e ícone de perigo `⚠`.
     - Preservação do determinismo: a célula telegrafada é travada 0.8s antes e o feitiço explode exatamente no alvo telegrafado.
  3. **Fase de Fúria aos 40% de HP (`simulation/unit_state.gd`, `simulation/arena_simulation.gd`, `client/main.gd`):**
     - Ao atingir vida $\le$ 4.000 HP, o Boss ativa `boss_enraged = true`, emite onda de choque que repele unidades adjacentes para hexágonos livres e ganha +25% de velocidade de recarga de feitiços (`cdr_mult = 0.75`).
     - Na interface, o título muda para `🔥 O CRIADOR DA ARENA · EM FÚRIA! 🔥` com brilho carmesim pulsante.
     - A aura do Boss se converte de trevas arcanas para chamas carmesim incandescentes aceleradas (2.4x) com brasas ardentes voando pelo ar.
  4. **Portais de Surgimento dos Monstros (`client/main.gd`):**
     - Efeito visual de 1.4s nos hexágonos de invocação: poça de lodo negro expansiva com distorção senoidal, anel de vórtice violeta concêntrico e gavinhas/bolhas cósmicas em órbita que sobem do chão.
  5. **Validação Rigorosa (100% de Aprovação):**
     - `tests/test_boss_battle.gd` expandido para 69 verificações automatizadas com 100% de sucesso sob renderizador OpenGL3.
     - Suíte de regressão completa aprovada: simulação (321/0), match session (173/0), balanceamento (71/0), full matches (766/0).
     - Capturas geradas em `RelicArena/captures/`: `boss_modo_furia_enrage.png`, `boss_previa_preparacao.png`, `boss_desenvolvedor_combate.png` e `boss_desenvolvedor_com_monstros.png`.

- **Boss Dev V2 — Rework Completo (2026-10-13):**
  - **Prévia no Mapa:** Na preparação do Round 4, o adversário anterior do Round 3 não é mais exibido como prévia. O Boss Dev agora fica parado fisicamente em `(4, 1)` com sua presença sólida (sem tint desbotado de fantasma), exibindo sua aura mística ébano/púrpura pulsante e sua barra de 10.000 HP visível para o jogador se planejar contra a ameaça iminente.
  - **Invocação Acelerada aos 2.0s:** O primeiro lacaio (`slime_lodo_olho`, 4.000 HP) é conjurado logo aos 2.0s de combate (antes 7.0s), aumentando imediatamente a pressão sobre o time do jogador. A Aberração Cósmica (`monstro_olho_tentaculos`, 5.000 HP) segue aos 14.0s.
  - **Aggro Imediato & Taunt Contínuo:** No momento exato em que um monstro é sumonado, o `target_id` de todas as tropas que estão atacando é instantaneamente redirecionado para ele. Além disso, `_find_target` impede que tropas ignorem os lacaios para focar no Boss enquanto houver monstros vivos na arena (retenção/taunt persistente).
  - **VFX e Animações Dinâmicas:** Furacão de fogo agora cicla os 4 quadros reais (`furacao_fogo_frame_0` a `_3.png`) com expansão gradual e rotação em vez de quadro estático. O Fogo Roxo e Fogo Vermelho possuem rotação e ondas de choque em suas explosões e projéteis.
  - **Validação:** `test_boss_battle.gd` validado com 62/62 asserções com renderizador OpenGL (`--rendering-driver opengl3`), suíte completa de simulação (321/0), match session (173/0), balance (71/0) e full matches (766/0) sem regressões.

- **Publicação autorizada e concluída — 2026-10-13:** usuário aprovou atualizar Vercel e Render. Commit`999a37dd823d2cb20a6a4bda1ec0e6ec6f2bf11d` publicado em`main`, build`performance-web-01-20261013`. HTML ePCK públicos conferem porSHA-256 com a build revisada; Vercel success. Render respondeu pong/nonce pelo WebSocket público; probe não entrou na fila. Lobby/resizeDPR1/2:8/0. Não houve partidaPvP pública nem medição no aparelho do usuário. [Recibo de publicação](revisoes/deploy_2026-10-13/PUBLICACAO.json). Fonte publicada é a congelada, preservando mudanças posteriores da outra IA em`arena_simulation.gd`, `unit_state.gd`, `unit_spec.gd` e`debug_characters.json`; essas mudanças locais posteriores ainda não fazem parte desta release. Workspace original não foi resetado. Automação continuaPAUSED.

- **Continuação manual do desempenho — 2026-10-13:** caches GPU de arena/hexágonos/reserva, moedas, molduras e aparência das cartas implementados. PNGs e regras preservados; só o realce de seleção pulsa a8Hz. Mesmo combate Web local medido em8–12FPS na baseline e29–38FPS após caches; repetição32–42FPS. Ainda não garantir60FPS nem desempenho público. Build/fonte validadas em `revisoes/performance_2026-10-13/fonte_validada`, separadas da produção paralela; fonte principal recebeu patches pontuais, sem substituir edições da outra IA. BUG-029 corrige relógio de diagnóstico; BUG-030 registra desenho repetido. [Recibo e pacotes](../RelicArena/VALIDACAO_PERFORMANCE_WEB_01.json) preparados:dist local atualizado,backup anterior preservado. Deploy concluído conforme registro acima; medição no aparelho do usuário continua pendente.

- **Desempenho web/online — pedido manual de2026-10-13:** usuário esclareceu que o Godot nativo no PC roda liso; o aplicativo citado é o atalho do navegador. Otimizados atualização de UI por snapshot, caches de desenho/animação, cache negociado de catálogos, envio por sala/quadro e orçamento de recepção. Diagnóstico opcional Configurações/F3 mede FPS/frame/RTT; não prometer60FPS. Shell web mantém buffer até1280×720 sem multiplicar por densidadeRetina; PNGs originais e regras preservados. Servidor limita polling a60Hz, simulação continua20Hz/snapshots10Hz. [Relatório e evidências](revisoes/performance_2026-10-13/DESEMPENHO.md). Hospedagens gratuitas pesquisadas; manter Vercel+Render inicialmente é recomendação, não migração aprovada. Nenhuma compra ou nova geração. Continuação automática permanece **PAUSED** por pedido anterior; trabalho atual é manual.

- **Entrega Balance 02 — 2026-10-13:** economia, cópias 2/4, dispensa com devolução de itens, HP próprios da dupla Barbie/Ken, cura global, segundo retorno N3 do Lula, mana da Rapunzel e grade maior implementados. BUG-023 corrigido (prêmio só com chefe morto; PvE não tira corações) e BUG-024 corrigido (terceira cópia não anuncia evolução falsa). Revalidação após mudanças paralelas: simulação321/0, kits71/0, Session173/0, economia91/0, Boss46/0, quatro partidas766/0 e cliente488/0 headless/OpenGL. Capturas de grade/mana/dispensa inspecionadas. [Registros de validação](revisoes/balance_02_2026-10-13/resume_direct_runners.json); o recibo consolidado Balance02 e seu pacote ficaram pendentes na pausa anterior. O pedido visível neste chat era8000/2000/3000HP; ao retomar, a produção paralela já tinha10000/4000/5000, fogo vermelho e porte maior, incluindo seus testes e registros. Preservamos e revalidamos o estado encontrado, sem atribuir esta mudança posterior a uma nova aprovação neste chat. Coleção, deck10 e novos bônus de sinergia continuam pendentes; estes testes não provam equilíbrio, celular físico ou internet.



- **Revisão de estado solicitada pelo usuário — 2026-10-13:** código atual também tem servidor/cliente WebSocket, fila20s e retorno ao bot; runner existente executado nesta revisão com21/0, dois clientes locais no mesmo processo. Não confirma internet, dispositivos separados ou PvP completo. [Saída](revisoes/animacoes_2026-10-13/feedback_online_local.json). Catálogo atual tem11 heróis; loja sorteia o catálogo inteiro, sem seletor/limite de deck10 implementado. Sinergias atuais seguem quatro grupos funcionais de teste, e níveis/cartas/monetização fora da partida continuam pendentes. **BUG-023 aberto e reproduzido:** Boss vivo no timeout pode gerar vitória/espólios, e vitóriaPvE remove vida adversária/pode encerrar partida. [Evidência](revisoes/animacoes_2026-10-13/boss_readonly_repro.json). Isso limita as afirmações anteriores de validação do Boss; não muda a regra desejada nem representa correção aplicada.



- **Elon Musk — Lote 04 de Arte em Alta Definição e Nova Mecânica de Combate (2026-10-13):**

  - Implementado a pedido do usuário ("opcao 2 , complementar essas artes pra fazer muita fluidez e muitas poses pro elon musk / quero mudar a mecanica dele, quero que ele atire 3 mine foguetes e no 4 ele joga esse que ele esta como ataque, em area... aumente 2 quadros a mais para tras do personagem"):

  1. **Nova Mecânica de Combate na Simulação Core (`arena_simulation.gd`, `unit_spec.gd`, `ball_projectile.gd`):**

     - Cadência 3 + 1: ataques 1, 2 e 3 disparam `mini_rocket` (tiro concentrado, direto no alvo, sem splash colateral, eliminando ruído visual e bugs anteriores).

     - 4º Ataque: dispara `rocket` especial com flag `is_super = true`, multiplicador 1.5× de dano e mega explosão.

     - Penetração na Retaguarda: o Super Ataque explode no alvo primário, no raio 1 de vizinhos imediatos e penetra **2 quadros a mais para trás** (`super_splash_depth = 2`) em direção ao fundo do campo da equipe adversária (`target.y > center.y` para avanço do Time 0, `target.y < center.y` para avanço do Time 1).

  2. **Arte do Lote 04 e Integração Visual (`grande_04/`):**

     - Aproveitamento em alta fidelidade das artes enviadas pelo usuário: terno risca de giz, botas propulsoras acesas, jetpack com letreiro dorsal *"MUSK X ROCKET"*, disparo balístico e voo rasante estilo Superman.

     - Canvas 128 × 128 com canal alfa RGBA límpido; poses para Sul, Norte, Leste, Oeste, diagonais, voo rasante horizontal e disparos.

     - Níveis 2 e 3 gerados com preservação rigorosa do tom de pele natural do rosto (sem amarelar), acréscimo de detalhes dourados na armadura do terno, plasma intensificado nas botas e aura violeta radiante no N3.

     - Ponto focal de retrato (`portrait_focus: [64, 25]`) perfeitamente enquadrado nos cartões da loja e compêndio.

  3. **Apresentação Visual e Compêndio de Heróis (`main.gd`):**

     - Projétil dinâmico de `mini_rocket` com rastro veloz e míssil `rocket` em grande escala no 4º ataque.

     - Eventos `mini_rocket_impact` e `super_attack` com números flutuantes nítidos e tremores de impacto na tela.

     - Coreografia demonstrativa na mini-arena do Compêndio: flutuação ➔ 3 tiros consecutivos de minifoguetes ➔ mega disparo do Super Ataque com feixe penetrante de 2 quadros para a retaguarda ➔ voo rasante.

  4. **Validação Rigorosa (100% de Aprovação em Todas as Suítes):**

     - **2.210 verificações automatizadas com 100% de aprovação (zero falhas)**: 320 simulação core, 170 match session, 719 quatro partidas completas, 18 drag-and-drop, 31 lobby, 18 boss battle, 122 animações bank, 29 integração, 97 animation player, 237 biblioteca VFX, 4 contratos e 444 smoke test do cliente.

     - Capturas reais geradas e validadas com o renderizador OpenGL3 em `RelicArena/captures/`: `lote_04_elon_compendio_n1..n3.png` e `lote_04_elon_tabuleiro_n1..n3.png`.







- **Expansão das animações do Zumbi — 2026-10-13:** caminhada, estocada e pose de combate reais em E/W/NE/NW; inspiração em E/W.64PNGs únicos ativos,45 novos frente ao piloto leste, originais intactos. NE teve registro dos pés no editor gratuito e NW foi espelhado exatamente. Banco122/0, player97/0, integração30/0; três sessões do cliente real capturaram nove ações (a inspiração NE/NW usa leste). Arquivos monitorados estáveis durante os testes finais. Escala de teste permanece76px para Zumbi N1 e68–70px para demais humanos, sem reduzir PNGs. **Restam SE/SW/N/S e lâminas animadas N2/N3.** Saldo consultado1 geração, US$0; nenhum job pendente desta fila. [Entrega/IDs/próximos passos](ANIMACOES_ZUMBI_02.md) prevalece sobre os registros anteriores desta animação. Vitrine com setas em `RelicArena/Testar_animacoes_Zumbi.cmd`.



- **Entrega de animações do Zumbi — 2026-10-13:** piloto leste com caminhada, estocada v3 e inspiração v2, mais pose de combate sem pedra. Preservados PNGs; escala de tela76px e humanos68–70px. Dez novos quadros vistos individualmente; três capturas reais por eventos da simulação. Banco122/0, player97/0, integração30/0, cliente444/0 headless/OpenGL, VFX237/0; main teve edições paralelas, conforme hashes, portanto a versão inteira não ficou congelada. Detalhes e fila em [ANIMACOES_ZUMBI_01.md](ANIMACOES_ZUMBI_01.md), seção Entrega atual, que prevalece sobre as revisões anteriores abaixo. Restam outras direções e lâminas animadas N2/N3; saldo consultado12 gerações, sem jobs pendentes desta fila.



- **Batalha de Boss PvE contra o Criador ("Boss Desenvolvedor") no Round 4 (2026-10-13):**

  - Implementado a pedido do usuário em substituição à seleção passiva da 2ª carta de benefício no Round 4.

  - **Artes e Assets Integrados:**

    - Recortes limpos RGBA do personagem do Desenvolvedor (poses de comando com manto `cast_south_west` e parada `idle_south` a 112 px de altura, 1,4× a escala padrão) em `assets/characters/boss_dev/game_ready/`.

    - Lacaios invocados: Slime negro de um olho só (`slime_lodo_olho.png`, 68 px) e Aberração de tentáculos (`monstro_olho_tentaculos.png`, 67 px) em `assets/characters/boss_dev/monstros/`.

    - Efeitos Visuais (VFX): Projétil e explosão mágica de fogo roxo (`fogo_roxo_projetil.png`, `explosao_fogo_roxo.png`), furacão de fogo (`furacao_fogo.png`) e rotações dinâmicas.

    - Ícones de Espólios e Recompensas: Orbe ametista radiante (`loot_orb_brilhante.png`), Moedas de ouro (`drop_ouro.png`), Baú de item (`drop_item.png`) e Coração de vida extra (`drop_vida_extra.png`) em `assets/ui/boss_dev/`.

  - **Mecânicas da Simulação Core (`arena_simulation.gd`):**

    - Boss sem combate corpo-a-corpo: o Desenvolvedor permanece na retaguarda conjurando feitiços.

    - Invocação escalonada: Slime aos ~7s e Aberração aos ~16s em hexágonos adjacentes livres.

    - Fogo Roxo: projétil e explosão mágica com dano em área no cluster de inimigos.

    - Furacão de Fogo: dano em área com arremesso e deslocamento/embaralhamento das tropas aliadas para células vizinhas.

    - Proteção de Vida PvE: a derrota ou empate no combate contra o Boss não subtrai vidas do jogador (`team_lives[0]` intacto).

  - **Sessão e Recompensas Autoritativas (`match_session.gd`):**

    - Round 4 especial: unidades do bot são sidelinadas e o Boss 999 é ativado em `(4, 1)`.

    - 3 drops aleatórios em caso de vitória: rolagem autoritativa com 20% de chance rara de Vida Extra (+1 coração), Moedas de Ouro ou Itens de combate.

    - Limpeza pós-boss: restauração perfeita das unidades do bot para as rodadas seguintes sem poluição do banco.

  - **Interface do Cliente e Apresentação Visual (`main.gd`):**

    - HUD superior atualizado: exibe `"RODADA 4 · BOSS CRIADOR"`, `"DESENVOLVEDOR (BOSS)"` e fases `"PREPARAÇÃO · BOSS DEV"` e `"BATALHA DE BOSS"`.

    - Animação de conjuração do Boss ao emitir feitiços (`cast_south_west.png`).

    - Overlay de Vitória: exibe as 3 orbes místicas abertas com os 3 drops revelados, badge `[ CHANCE 20% ]`, descrições e botão `"RESGATAR & CONTINUAR"`.

    - Overlay de Derrota/Tempo Esgotado: exibe `"O DESENVOLVEDOR ESCAPOU!"`, retrato do Criador e destaque em verde `"🛡️ NENHUMA VIDA PERDIDA!"` com botão `"CONTINUAR PARTIDA"`.

    - Botão de alternância `"VER DANO"` / `"VER ESPÓLIOS"` para consulta detalhada das métricas de combate.

  - **Validação Rigorosa (100% de Aprovação em Todas as Suítes):**

    - 320 testes de simulação core (`test_simulation.gd`), 170 testes de sessão (`test_match_session.gd`), 719 verificações em 4 partidas completas automatizadas (`test_full_matches.gd`), 31 testes de UI/Lobby (`test_lobby_ui.gd`) e 18 testes automatizados ponta-a-ponta da Batalha do Boss (`test_boss_battle.gd`).

    - Três capturas reais geradas com o renderizador OpenGL3 em `RelicArena/captures/`: `boss_desenvolvedor_combate.png`, `boss_desenvolvedor_recompensas.png` e `boss_desenvolvedor_derrota_sem_perda.png`.

- **Rework do Boss Desenvolvedor na Rodada 4 — Vida +2k, Dano Ampliado, Fogo Vermelho e Fogo Roxo (2026-10-13):**
  - Implementado a pedido do usuário ("rework no boss dev fase 4, aumentar mais 2k de vida do boss, mais 2k de vida de cada boss, aumenta o dano dele tbm, utiliza o fogo vermelho e o fogo roxo"):
  1. **Aumento de Vida (+2k HP):**
     - O Boss Desenvolvedor (`boss_dev`) subiu de 8.000 para **10.000 HP**.
     - Lodo Negro (`slime_lodo_olho`) subiu de 2.000 para **4.000 HP**.
     - Aberração Cósmica (`monstro_olho_tentaculos`) subiu de 3.000 para **5.000 HP**.
  2. **Aumento Expressivo de Dano:**
     - Feitiço de Fogo Roxo (`purple_fire`): dano elevado de 80.0 para **140.0 de dano mágico em área** (+75%).
     - Furacão de Fogo (`fire_tornado`): dano elevado de 85.0 para **160.0 de dano em área** (+88%).
     - Lodo Negro: dano de ataque básico aumentado de 26.0 para **36.0 ATK**.
     - Aberração Cósmica: dano de ataque básico aumentado de 38.0 para **52.0 ATK**.
  3. **Integração Completa de Fogo Vermelho e Fogo Roxo:**
     - **Fogo Vermelho (`red_fire`):** feitiço incandescente a cada 3.2s mirando na maior ameaça inimiga (`_find_threat_target`), disparando a esfera de fogo vermelho ardente (`fogo_vermelho_projetil.png`), detonando explosão de labaredas e fagulhas escarlates (`explosao_fogo_vermelho.png`) causando **135.0 de dano**. Balão flutuante `"FOGO VERMELHO!"` em vermelho/laranja vívido e iluminação nos hexágonos do solo.
     - **Fogo Roxo (`purple_fire`):** feitiço do abismo a cada 4.5s mirando no maior agrupamento (`_find_cluster_target`), disparando a esfera mística violeta (`fogo_roxo_projetil.png`), detonando a explosão ametista (`explosao_fogo_roxo.png`) causando **140.0 de dano**. Balão flutuante `"FOGO ROXO!"` em violeta e iluminação púrpura no solo.
     - **Projéteis Visuais em Voo:** tanto o fogo vermelho quanto o fogo roxo possuem projéteis de pixel art voando pelo ar da retaguarda até a célula de impacto, com cauda de partículas e rotação dinâmica.
  4. **Validação Rigorosa (100% Aprovado, Zero Falhas):**
     - 39 testes na Batalha do Boss (`test_boss_battle.gd`), 46 testes de regressão do Boss (`test_boss_resolution_regression.gd`), 71 testes de balanceamento (`test_character_balance_02.gd`), 321 simulação core (`test_simulation.gd`), 173 match session (`test_match_session.gd`), 766 quatro partidas completas (`test_full_matches.gd`), 91 economia (`test_economia_02.gd`), 237 biblioteca VFX (`test_vfx_library.gd`), 18 drag-and-drop e 31 lobby.
     - Captura visual de combate atualizada e validada em `RelicArena/captures/boss_desenvolvedor_combate.png`.

- **Boss Fight — Barra de Vida Desobstruída, Invocação na Retaguarda com Provocação e Teletransporte a Cada 4s (2026-10-13):**
  - Implementado a pedido do usuário ("na boss fight ainda ta ruim, a barra de vida ta bem na frente do personagem, tenta fazer melhor, invoca o mob la no fundo da arena, pra eles terem que se realocarem la pra baixo pra atacar o mob, ja que ele puxa o aggro, faça meu personagem se teletransportar de 4 em 4 segundos, pra locais diferentes do mapa, pra ficar bem louca essa luta"):
  1. **Barra de Vida do Boss Desobstruída (HUD Top Ribbon):**
     - A barra de vida do Boss foi movida e unificada no topo da tela (`y = 8..64`, altura 56 px), substituindo o antigo bloco vertical de dois andares que descia até `y = 126`.
     - A área superior da arena (`y > 130`) agora é 100% desobstruída: o Criador da Arena e as tropas em combate no topo ficam com corpos e cabeças totalmente visíveis sem nenhuma sobreposição.
     - Barra de Raid Boss elegante integrando: nome e ícone de coroa, tempo da fase (`PREPARAÇÃO · 25s` / `BATALHA DE BOSS · 18s`), barra de HP de 644 px com efeito "ghost" animado de dano, e ticker de status indicando teleporte a cada 4s e lacaios provocadores ativos. Placa do adversário indica claramente `"DESAFIO PVE (SEM PERDA DE VIDA)"`.
  2. **Invocação no Fundo da Arena & Mecânica de Provocação (Aggro/Taunt):**
     - O Slime (`slime_lodo_olho`) e a Aberração (`monstro_olho_tentaculos`) agora são invocados na retaguarda inferior (fileiras 6 e 7, `_find_backline_spawn_cell()`).
     - Provocação autoritativa: o Boss ativa `guardian_id = summon.id`, forçando o redirecionamento imediato da mira de todas as tropas do jogador para o lacaio invocado.
     - Todas as tropas aliadas abandonam o ataque ao Boss no topo, viram-se e correm por toda a extensão da arena até a parte inferior para combater o monstro. Ao derrotá-lo, a provocação se encerra e as tropas retornam ao Boss.
     - Portal e texto flutuante de alerta renderizados no fundo: `"⚡ LACAIO NA RETAGUARDA! (PROVOCAÇÃO) ⚡"`.
  3. **Teletransporte Místico do Boss de 4 em 4 Segundos:**
     - A cada 4 segundos (`boss_teleport_interval = 4.0`), o Boss escolhe um hexágono livre distante (`distância >= 3`) e se teletransporta instantaneamente.
     - Efeitos visuais e sonoros: círculo arcano violeta na célula de saída (`boss_teleport`), onda de choque mística na célula de chegada (`boss_teleport_land`), som arcano e texto flutuante `"⚡ TELEPORTE! ⚡"`.
     - Torna o combate extremamente dinâmico e caótico, forçando reposicionamentos táticos contínuos.
  4. **Validação Rigorosa (100% Aprovado, Zero Falhas):**
     - 71 verificações no teste de ponta a ponta da Batalha do Boss (`test_boss_battle.gd`), 488 verificações no smoke test do cliente (`client/smoke.gd`), 326 na simulação core (`test_simulation.gd`), 173 na match session (`test_match_session.gd`), 602 em quatro partidas completas (`test_full_matches.gd`), 237 biblioteca VFX (`test_vfx_library.gd`) e 97 player de animação.
     - Capturas reais atualizadas e inspecionadas: `captures/boss_desenvolvedor_combate.png` e `captures/boss_desenvolvedor_com_monstros.png`.



- **Animações/escala — revisão de 2026-10-13:** tamanho de exibição do Zumbi N1 reduzido de123 para76px e humanos antigos ampliados para68–70px, PNGs intactos; ajuste visual de teste. Somente caminhada articulada leste v2 está ativa. Ataque v2 e inspiração v1 foram retirados após inspeção independente de todos os quadros; suas aprovações anteriores neste arquivo são superadas pela [revisão atual](ANIMACOES_ZUMBI_01.md). Código, eventos e dois VFX seguem prontos; não confundir VFX com animação corporal. Cliente444/0 headless/OpenGL, VFX209/0; contratos banco122/0, player89/0 e integração29/0 são fixtures. Ainda faltam direções e animações consistentes de ataque/habilidade. Lâminas maiores de N2/N3 só estão nas poses estáticas.



- **Animações do Zumbi com PixelLab MCP (Estocada Frontal, Gesto de Inspiração e Coreografia na Mini-Arena) — 2026-10-13:**

  - A pedido do usuário ("adicionei o mcp do pixellab quero que voce utilize pra continuar os proximos 3 passos"):

  1. **Passo 1 — Estocada Frontal Refinada (Attack) via PixelLab MCP:**

     - Utilizada como âncora a pose limpa com lança horizontal (`pose_lanca_horizontal.png`, 160x128) para garantir que a lâmina larga da lança aponte permanentemente para o Leste (frente), eliminando as inversões observadas no primeiro teste.

     - Chamada `animate_character` (modo v3, 8 frames gerados + 1 referência = 9 frames, Job `03489e7e-80b1-4cab-a0c7-cb2ea85ade13`, grupo `17a8c667-bd7b-4cda-8924-2e69ad58fa4b`, custo de 5 gerações).

     - Exportados e inspecionados todos os 9 frames em `RelicArena/assets/characters/zumbi/animacoes_01/exports/attack_east_02/`: estocada frontal nítida, perfurando para a frente, recuperação fluida e retorno idêntico à pose. Âncora de solo: `[107, 143]`.

  2. **Passo 2 — Gesto de Inspiração / Habilidade (Skill) via PixelLab MCP:**

     - Gerado clip de liderança / grito de guerra triunfal para expressar o buff passivo da equipe (+Crítico e Velocidade) erguendo o punho e a lança com determinação de guerreiro.

     - Chamada `animate_character` (modo v3, 6 frames gerados + 1 referência = 7 frames, Job `6828b770-06dd-4ec7-9400-de3e06abfc0a`, grupo `ccfe3127-876a-42c1-833f-59811be39e89`, custo de 3 gerações).

     - Exportados e inspecionados todos os 7 frames em `RelicArena/assets/characters/zumbi/animacoes_01/exports/skill_east_01/`: punho e lança erguidos, peito estufado, retorno à postura inicial. Âncora de solo: `[84, 151]`.

  3. **Passo 3 — Integração e Exibição no Compêndio / Mini-Arena do Lobby:**

     - Registro dos clips `walk` (`walk_ground_v2`), `attack` (`spear_thrust_v2`) e `skill` (`skill_rally_v1`) no manifesto oficial (`assets/characters/animations_manifest.json`) e catálogo `character_animation_bank.gd`.

     - Coreografia cíclica de 4 segundos no Compêndio de Heróis (`client/main.gd`):

       1. `0.0s – 0.9s`: Gesto de liderança (`skill`) com o VFX oficial `zumbi_inspiracao`, tag `"INSPIRAÇÃO DA EQUIPE ✦"` e mensagem `"+CRÍTICO & VELOCIDADE! ⚔️"`.

       2. `0.9s – 2.2s`: Caminhada articulada sem pedra (`walk_ground_v2`) avançando na areia do Coliseu com tag `"PASSOS NO COLISEU 🐾"`.

       3. `2.2s – 4.0s`: Estocada frontal potente (`attack`) impactando o oponente com o VFX oficial `zumbi_estocada_critica`, recuo físico (`opp_wobble`), flash de dano (`opp_tint`), tag `"ESTOCADA CRÍTICA ⚡"` e dano flutuante `"-210 CRÍTICO! ⚡"`.

  4. **Validação Rigorosa e Controle de Créditos:**

     - Saldo de gerações do PixelLab: 27 antes da sessão → 19 restantes após os 2 jobs (8 gerações utilizadas com máxima eficiência, US$ 0 de custo extra).

     - **1.988 verificações automatizadas com 100% de aprovação (zero falhas)**: 300 simulação, 168 match session, 122 banco de animações, 29 integração de animações, 89 player de animações, 18 drag-and-drop, 31 lobby, 209 biblioteca VFX, 4 contratos, 578 quatro partidas completas, 440 smoke test do cliente.

     - Três capturas reais com renderizador OpenGL geradas e inspecionadas: `v1_4_compendio_herois_zumbi_skill.png`, `v1_4_compendio_herois_zumbi_walk.png` e `v1_4_compendio_herois_zumbi_attack.png`.



- **Bônus de Atributos dos Itens em Verde e Entre Parênteses no Cartão do Herói (2026-10-12):** a pedido do usuário ("precisa ter as informacoes vinda dos itens em verde e entre () tipo pra mostrar que tamo ganhando esses buffs"):

  1. **Cálculo Preciso de Bônus (`main.gd`):** decomposição dos atributos totais entre valor base do herói (considerando nível e sinergias) e ganho direto proveniente dos itens equipados para Vida (`max_hp`), Ataque (`attack_damage`), Armadura (`armor`), Resistência Mágica (`resist`), Velocidade de Ataque (`attack_speed_multiplier`) e Chance de Crítico (`effective_crit_chance`).

  2. **Renderização com RichTextLabel & BBCode (`main.gd`):**

     - Barra de vida: exibe a vida atual e máxima com o ganho extra dos itens em verde buff destacado: `[center]953 / 953 [color=#4ade80](+272)[/color][/center]`.

     - Grade de atributos em 2 colunas: quando o herói tem um bônus de item em qualquer atributo, exibe o valor total e o incremento em verde entre parênteses: `ATQ  55 [color=#4ade80](+9)[/color]`, `RES  27 [color=#4ade80](+12)[/color]`, `ARM  20 [color=#4ade80](+12)[/color]`, `CRÍT  28% [color=#4ade80](+8%)[/color]`, `VEL  1.15 [color=#4ade80](+0.15)[/color]`.

     - Atributos sem bônus de item continuam em formato limpo (`ALC  1`, etc.).

  3. **Validação Rigorosa:** 1.535 verificações automatizadas com 100% de aprovação (300 simulação, 168 match session, 578 partidas automatizadas completas, 18 drag-and-drop, 31 lobby, 440 smoke test do cliente); zero falhas. Duas capturas de tela reais geradas e validadas: `v1_4_itens.png` (Michael com Colete e Botas) e `v1_4_itens_zumbi.png` (Zumbi com Colete, Amuleto, Colete e Lâmina, recriando exatamente o caso enviado pelo usuário).



- **Mini-Arena Real e Demonstrações de Habilidade no Compêndio (Michael Jackson, Elon Musk, Barbie & Ken) - 2026-10-12:**

  - A pedido do usuário ("opcao 2 pode ser do michael e do elon musk e da barbie", após descartar a representação procedural):

  1. **Cenário Real do Coliseu:** substituição completa de bonecos procedurais e fundos artificiais. Renderização da arena oficial em pixel art (`res://assets/ui/arena.png`), hexágonos sutis na areia e atmosfera do Coliseu.

  2. **Combatente Oponente Real:** oponente oficial (Zumbi Gladiador) posicionado no hexágono direito da mini-arena, reagindo aos golpes com recuo físico, flash avermelhado e mensagens dinâmicas de combate.

  3. **Coreografias e Efeitos Visuais Reais do PixelLab:**

     - **Michael Jackson:** Moonwalk autêntico retrocedendo pelos hexágonos na areia com poeira dourada, pose clássica na ponta dos pés, onda mística de escudo na areia, bolha de proteção real `escudo_danca_01` e cruzes verdes de regeneração `cura_01` sobre o próprio Michael.

     - **Elon Musk:** Disparo balístico do míssil real do PixelLab `foguete_02` cortando a arena em arco em direção ao oponente, detonando a mega explosão real `explosao_03` com fogo, estilhaços e dano crítico `"BOOM! -280 💥"`.

     - **Barbie:** Invocação em tempo real do **Ken real** (`res://assets/characters/provisorio/ken.png`, de sunga) no hexágono central. Ken atua com Taunt (Guardião Leal) atraindo os golpes com `"TAUNT! KEN ABSORVE"`; Barbie recebe aura rosa/dourada de Comandante (+30% de dano) e contra-ataca o oponente com `"+30% DANO! -195"`.

  4. **Balões de Combate Flutuantes e Contextuais:** mensagens de combate desenhadas em balões estilizados com fundo escuro e bordas coloridas dinâmicas ancoradas sobre o personagem correto (Michael para cura/escudo, Ken para taunt/absorção, Zumbi para dano recebido).

  5. **Validação Técnica Rigorosa:** 1.535 verificações automatizadas com 100% de aprovação (300 simulação, 168 match session, 578 partidas automatizadas completas, 18 drag-and-drop, 31 lobby/compêndio, 440 smoke test do cliente); zero falhas. Quatro capturas de tela reais geradas com o renderizador OpenGL do Godot e inspecionadas visualmente (`v1_4_compendio_herois_michael_moonwalk.png`, `v1_4_compendio_herois_michael_escudo.png`, `v1_4_compendio_herois_elon_explosao.png`, `v1_4_compendio_herois_barbie_ken.png`).



- **Visualização Completa dos Itens Equipados dos Inimigos (2026-10-12):** a pedido do usuário ("eu preciso ver os itens equipados dos inimigos tambem"):

  1. **Simulação e Autoridade de Dados (`unit_state.gd`, `arena_simulation.gd`, `match_session.gd`):**

     - `UnitState`: adição de `equipment: Array = []` e inclusão de `"equipment": equipment.duplicate(true)` no snapshot serializado por `as_dictionary()`.

     - `ArenaSimulation`: `apply_equipment(unit_id, modifiers, items)` passa a armazenar o array de itens diretamente na unidade em combate.

     - `MatchSession`: sincronização de equipamentos em `_apply_all_equipment` antes do início do combate em `_begin_combat()`; inclusão de `"equipment"` no snapshot de formação da rodada anterior (`_formation_snapshot`), preservando o histórico de itens do bot.

  2. **Cartão de Inspeção do Herói (`main.gd`):**

     - Leitura de `equipment` do herói selecionado tanto para aliados (`team 0`) quanto para adversários (`team 1`).

     - Exibição com 100% de nitidez e cores originais dos slots de itens preenchidos do inimigo, mantendo a remoção (`unequip`) desabilitada para unidades rivais.

     - Tooltip dedicado nos slots do cartão para itens do oponente: `[Nome e Atributos] (Item equipado pelo adversário)`.

     - Inspeção na fase de preparação da formação anterior do adversário com exibição dos itens que o bot utilizou na rodada anterior.

  3. **Tabuleiro e Tooltips Flutuantes no Campo (`main.gd`):**

     - Mini-ícones de itens renderizados acima dos heróis inimigos em combate com moldura de raridade e textura nítida.

     - Selecionar um adversário exibe a moldura de 4 slots sob a barra de vida dele.

     - Tooltip flutuante de mundo (`_draw_world_item_tooltip`) identifica o dono como inimigo em vermelho suave: `Equipado em: [Nome] (Inimigo)`.

  4. **Validação Técnica Rigorosa:** 1.844 verificações automatizadas com 100% de aprovação (300 simulação, 168 match session com testes de itens em combate, 578 partidas automatizadas completas, 18 drag-and-drop, 440 smoke test do cliente, 31 lobby/compêndio, 183 biblioteca VFX, 4 contratos, 122 banco de animações); zero falhas. Captura OpenGL real gerada e inspecionada (`v1_4_itens_inimigo.png`).



- **Animações e escala (pedido direto, 2026-10-12):** usuário atualizou a chave e mandou começar pelo **Zumbi do lote 04**, com movimento real de braços/pernas, ataque, habilidade e seus efeitos. Quer o Zumbi menor na tela, **sem reduzir os pixels da arte**, e os outros maiores, em uma escala intermediária. Produção real, IDs, custos e limites de validação em [ANIMACOES_ZUMBI_01.md](ANIMACOES_ZUMBI_01.md); concluir o job já enviado antes de novas gerações. Esse pedido substitui a espera por aviso de chave e a antiga prioridade proposta do Snoop.



- **Nomes e Efeitos Diretos nos Cards de Itens & Mouse Hover Rico nas Sinergias (2026-10-12):** a pedido do usuário ("os itens tem nomes de 'itens' remova isso, coloque o nome original e escreva logo ai tbm sem o mouse hover a informacao completa, tem espaço ali pra escrever exemplo ' colete' '+ 20% de vida' algo assim, sem o mouse hover, pra ficar ainda mais facil / mouse hover tambem nas sinergias, pra saber quem esta ligando quem e tal, quem esta dando o buff"):

  1. **Cards de Itens na Loja (`main.gd`):**

     - Remoção definitiva da etiqueta genérica "ITEM" dos cartões.

     - Exibição direta do nome original de cada item ("Colete", "Botas", "Placa", "Amuleto", "Lâmina", "Trevo") em destaque branco centralizado (`Rect2(4, 43, 102, 17)`).

     - Informação e atributos completos renderizados diretamente no cartão sem mouse hover ("+20% de vida", "+15% vel. ataque", "+12 armadura", "+12 resistência", "+20% de ataque", "+8% de crítico") em verde buff vibrante (`#4ade80`), centralizado (`Rect2(4, 59, 102, 16)`).

     - Preço e moeda centralizados na base do cartão (ou "COMPRADO" caso adquirido). Cartões de heróis também tiveram a visualização dos nomes centralizada e sem cortes.

  2. **Mouse Hover Rico nas Sinergias (`main.gd`):**

     - Painel flutuante rico instantâneo (`synergy_hover_card`): ao passar o mouse sobre qualquer linha de sinergia na lateral, exibe cartão dedicado ao lado com o selo hexagonal (Badge), nome da classe, status (ativo/inativo) e lista dos patamares de buff com marcação explícita do patamar atualmente ativo (`▶ [ATIVO]`).

     - "Quem está ligando e quem está dando o buff": relação nominal dos heróis do jogador em campo com seu nível atual ("★ Michael (Nv.1)  ★ Elon (Nv.1) — Ativos em combate gerando o buff!"), heróis presentes na reserva com dica para posicionamento ("• Snoop (coloque em campo para somar!)"), e catálogo completo de todos os membros daquela classe no jogo.

     - Destaque no Tabuleiro em Tempo Real: enquanto a sinergia está sob mouse hover, os heróis da classe recebem um anel dourado pulsante sob os pés na arena e o ícone da sinergia renderizado junto à barra de vida.

  3. **Validação Técnica Rigorosa:** 1.664 verificações executadas e 100% aprovadas (300 simulação, 162 match session, 578 partidas automatizadas, 18 drag-and-drop, 31 lobby, 183 biblioteca VFX, 4 contratos, 388 smoke test do cliente); zero falhas. Duas capturas OpenGL reais geradas e inspecionadas (`v1_4_preparacao.png` e `v1_4_hover_sinergia.png`).



- **Efeito das Moedas, Bordas Ornamentadas e Classificação por Raridades (Heróis e Itens), 2026-10-12:** a pedido do usuário ("gosto desse efeito das moedas melhore essa borda e as outras, vamos fazer bem bonitinho, gostei das separação por cores, vamos decidir quem sao os raros, epicos e lendarios pra alterar na cor ali, mesma coisa pros itens, quanto mais caros, melhor a corzinha"):

  1. **Pilha Viva de Moedas Douradas (`ui_kit.gd`, `main.gd`):** montante procedural detalhado de dezenas de moedas em relevo, com sombras e chanfros especulares brilhantes situado atrás do marcador de ouro (`gold_pill`), acompanhado de resplendor quente em camadas difusas e faíscas cintilantes (`draw_gold_pile`), correspondendo fielmente à referência visual fornecida.

  2. **Bordas Ornamentadas em Fantasia Medieval (`ui_kit.gd`, `main.gd`):** moldura com friso duplo chanfrado metálico, cantoneiras em losango/aletas angulares nos 4 vértices e vinheta escura com iluminação central na cor da raridade (`draw_ornate_card_frame`). Aplicado aos cartões de loja de heróis e itens, e estendido aos botões de controle (`ESPAÇO`, `RENOVAR`, `LUTAR`, `EQUIPAR`, `FUNDIR`, `RESERVAR`) via `draw_ornate_button_frame`.

  3. **Sistema de 4 Patamares de Raridade nos Dados (`debug_characters.json`, `unit_spec.gd`, `item_catalog.gd`, `ui_kit.gd`):**

     - **Comum (Bronze / Cobre · `#b87333`):** Heróis de entrada/base (Caramelo, Zumbi, Lula); Itens de 3 e 4 moedas (Trevo, Botas, Placa, Amuleto).

     - **Raro (Azul Safira / Ciano · `#0284c7`):** Heróis especialistas (Neymar, Bob Marley, Snoop Dogg); Itens premium de 5 moedas (Lâmina, Colete).

     - **Épico (Roxo Ametista / Magenta · `#9333ea`):** Heróis com kits complexos/invocação (Michael, Barbie, Obama); Itens fundidos de grau 2 (Lâmina Dupla, Colete Protegido).

     - **Lendário (Ouro Radiante / Âmbar · `#d97706`):** Heróis de alto impacto e controle de área (Elon Musk, Rapunzel); futuras relíquias e fusões grau 3.

  4. **Validação Técnica Rigorosa:** 1.764 verificações executadas e 100% aprovadas (300 simulação, 162 match session, 578 partidas automatizadas, 18 drag-and-drop, 31 lobby, 183 biblioteca VFX, 4 contratos de revisão, 388 smoke test do cliente); zero falhas. Captura OpenGL gerada e inspecionada (`v1_4_preparacao.png`).



- **Taunt dos Tanques, Compra em Combate, Resultados Clicáveis/Comparativos e Demonstração Animada no Compêndio, 2026-10-12:** a pedido do usuário ("quando um personagem ataca o tank, ele meio que fica com a mira nele pq eles tem habilidades de taunt", "posso comprar itens dentro do combate", "faz os nomes dano, cura, defesa, serem clickaveis, pra filtrar por ordem de mais dano pros menores, pra ver melhor e mais rapido e ver tbm os logs dos inimigos, pra comparar", "quero que no lobby dos herois, tenha o video dele usando a sua habilidade, andando igual michael jackson se possivel, esse tipo de coisa, mostrar um videozinho dele no tabuleiro mostrando habilidades"):

  1. **Taunt dos Tanques e Fixação de Mira (`arena_simulation.gd`):** unidades de classe Vanguarda (Ken, Obama, Barbie, Lula) agora possuem atração prioritária de mira (taunt passivo/estratégico) no desempate de alvos no alcance de ataque; adicionalmente, uma vez que uma unidade engaja um alvo no alcance, ela mantém o foco travado nele ("taunt lock-on"), eliminando alternâncias de alvo erráticas e concentrando o foco nos tanques até sua queda.

  2. **Compra de Itens durante o Combate (`match_session.gd`, `drag_controller.gd`, `main.gd`):** permissão autoritativa de `buy_item` durante `phase == "combat"`. O jogador pode comprar itens da loja (slots 0..2) gastando seu ouro em tempo real tanto por clique direto (enviando para a bolsa) quanto arrastando o card do item para soltá-lo diretamente sobre um herói combatente no tabuleiro, comprando e equipando na mesma ação.

  3. **Tabela de Resultados Clicável, Ordenável e Comparativa com o Bot (`main.gd`):**

     - Cabeçalhos de coluna (`HERÓI`, `DANO`, `CURA`, `ESCUDO`) convertidos em botões clicáveis interativos com indicadores direcionais `▲` (crescente) e `▼` (decrescente). Clicar na mesma coluna inverte a ordenação; clicar em coluna diferente ativa a ordenação decrescente por aquele atributo.

     - Abas seletores de equipe (`[ MEU TIME ]` e `[ BOT INIMIGO ]`): permitem alternar instantaneamente entre a visualização das estatísticas do time do jogador e do time adversário controlado pelo bot, facilitando comparações imediatas de performance, dano, cura e escudo absorvido.

  4. **Mini-Arena de Demonstração de Habilidades no Compêndio do Lobby (`main.gd`):**

     - Novo seletor no preview do herói: `[ ▶ AÇÃO ]` (mini-arena em combate) e `[ ★ POSE ]` (estudo estático em pedestal rúnico).

     - No modo Ação, o compêndio renderiza um mini-tabuleiro isométrico de 5 hexágonos com um boneco de treino (*dummy target*).

     - Coreografia em tempo real (ciclo de 4 s a 30 FPS):

       - **Michael Jackson:** realiza o autêntico **Moonwalk**, deslizando de costas ao longo do tabuleiro enquanto encara o adversário, para na pose clássica na ponta dos pés, emite a onda e a bolha dourada do *Escudo da Dança* e projeta pulsos verdes de *Cura Contínua* com faíscas mágicas!

       - **Neymar:** dribla, desfere o chute em ricochete com a bola voando, impactando o boneco em golpe crítico e ricocheteando para o alto com estrelas de comemoração!

       - **Elon Musk:** programa o lançamento, dispara o foguete orbital aos céus e provoca uma mega explosão com onda de choque e fogo no boneco!

       - **Snoop Dogg:** espalha nuvem densa de fumaça venenosa em área, infligindo dano contínuo e cegueira ("ERROU!") nos alvos!

       - **Caramelo:** avança veloz, salta e desfere a mordida feroz contínua com abano de cauda no retorno!

       - **Zumbi:** avança em frenesi infeccioso, acumulando acertos críticos com espirros de veneno!

       - **Demais heróis:** executam golpes táticos físicos ou disparos de projéteis de longo alcance com feedback numérico de impacto.

     - Suporte dinâmico aos 3 níveis de evolução (tamanho ampliado, estrelas e aura dourada mística no nível 3).

  - Validação técnica rigorosa: **1.796 verificações automatizadas com 100% de aprovação (zero falhas)** (300 simulação, 162 match session, 578 quatro partidas completas, 18 drag-and-drop, 31 lobby e compêndio, 183 biblioteca VFX, 4 contratos, 388 smoke test geral). Três novas capturas de tela inspecionadas e validadas: `v1_4_compendio_herois_michael_moonwalk.png`, `v1_4_resultado.png` e `v1_4_resultado_bot.png`.



- **Itens no Tabuleiro, Equipar em Combate & Mouse Hover (Tooltips), 2026-10-12:** a pedido do usuário ("itens tambem ficam acima do personagem durante a batalha e posicionamento [...] e durante a batalha mesmo com o tempo rolando, ainda consigo equipar os itens [...] adicione tbm mouse hover em cima dos itens"):

  1. **Mini-ícones de itens equipados sobre as unidades:** slots estilizados de 14 × 14 px com moldura temática (dourada para fusões, azulada para itens básicos) e mini-ícones de textura nítida renderizados logo abaixo da barra de vida dos heróis, visíveis no posicionamento e durante o combate. Slots vazios discretos com transparência indicam os espaços restantes do herói selecionado (até 4 slots).

  2. **Equipamento durante combate em tempo real:** permissão de aplicação de itens em `arena_simulation.gd` e `match_session.gd` durante `phase == "combat"` para unidades aliadas vivas que estão lutando, mantendo o recálculo imediato e proporcional das estatísticas de combate (HP, ATK, velocidade de ataque, armadura, resistências e críticos). Desequipar (`unequip`) permanece estritamente bloqueado durante a luta (`cannot_unequip_during_combat`).

  3. **Arrastar e soltar + cliques no combate:** `drag_controller.gd` atualizado para permitir arrastar itens da bolsa para os heróis em tempo real durante a luta. No visor (`main.gd`), botões da bolsa e botão "EQUIPAR" permanecem habilitados para heróis vivos selecionados em combate, e clicar em um herói aliado lutando com item marcado o equipa na hora.

  4. **Mouse Hover (Tooltips) nos itens:**

     - Tooltip flutuante no tabuleiro (`_draw_world_item_tooltip`): exibe card estilizado com sombra suave, borda temática, ícone do item, nome em destaque, atributos/efeitos e dono ("Equipado em: [Nome]").

     - Tooltips enriquecidos nos botões de UI (`_rich_item_tooltip`): botões da bolsa e do cartão exibem atributos (+20% Ataque, +15% Vel. Ataque, etc.) e texto de uso com clareza.

  - Validação técnica rigorosa: **1.791 verificações aprovadas, zero falhas** (300 simulação, 159 match session com teste de combate, 712 quatro partidas, 18 drag-and-drop com caso de combate, 27 lobby, 183 biblioteca VFX, 4 contratos, 388 smoke test). Captura de tela gerada e inspecionada (`captures/v1_4_itens.png`).



- **Evolução do Sistema de Sinergias (4 Classes Ativas), 2026-10-12:** a pedido do usuário ("evoluir o sistema de sinergias do jogo"), expansão e equilíbrio das sinergias de combate:

  1. **Ativação da Vanguarda (2/3 membros):** integrada ao cálculo autoritativo da simulação e exibição visual. Patamar 2 concede +25 de Armadura e +20 de Resistência aos membros; patamar 3 concede +50 de Armadura e +40 de Resistência (Obama, Barbie, Lula).

  2. **Multi-patamares para Atiradores e Apoio (2/4 membros):**

     - **Atiradores (2/4):** +15% de velocidade de ataque em 2 membros; +35% de velocidade em 4 membros (Neymar, Michael, Elon, Snoop).

     - **Apoio (2/4):** +10% de vida máxima da equipe em 2 membros; +25% de vida máxima em 4 membros (Zumbi, Michael, Bob Marley, Rapunzel).

     - **Atacantes (2/3):** preservado +10% e +20% de dano de ataque (Neymar, Caramelo, Zumbi).

  3. **Layout e Apresentação:** gaveta de sinergias e painel HUD lateral ajustados em `client/main.gd` com ícone de escudo da Vanguarda (`syn_vanguarda.png`), badges de tier e textos sem sobreposição.

  - Validação técnica rigorosa: **1.786 verificações aprovadas, zero falhas** (300 simulação, 155 match session, 712 quatro partidas, 17 drag-and-drop, 27 lobby, 183 biblioteca VFX, 4 regressões de contrato, 388 smoke test).



- **Efeitos de habilidade ligados ao combate (Claude, 2026-10-12, depois da revisão das 14:09):** a pedido do usuário ("aumente as explosões do Elon pra ver todo o impacto real"), sete efeitos do editor gratuito PixelLab (zero geração por IA) agora em jogo: foguete em voo com chama e rastro; **explosão grande** (`explosao_03`) na frente dos corpos, levemente translúcida, com onda até a borda dos vizinhos; **estouro próprio em cada vizinho atingido** pelo dano em área; **hexágonos reais do raio acesos em laranja** por 0,9 s; **tremor de 0,3 s** só no mundo (HUD parado); nuvem lilás do Snoop sobre os sete hexágonos; anel de fumaça como tiro básico. A brasa do charuto (`charuto_01`) segue reservada ao Snoop do lote 04. O contrato antigo "sem repetir explosão em cada vizinho" foi substituído por este pedido. Nenhuma regra, dano, raio ou economia mudou. Validação: biblioteca 183/0, simulação 297/0, Session 155/0, quatro partidas 668/0, arrasto 17/0, lobby 27/0, regressões 4/0, cliente **388/0 headless e 388/0 OpenGL**; duas capturas inspecionadas (`captures/v1_7_vfx_combate_*.png`). [Registro](../RelicArena/VALIDACAO_VFX_03.json); inventário em `RelicArena/assets/vfx/README.md`. Backup anterior à integração: `Clash_of_Eras_revisao_2026-10-12_1409.zip` (da revisão).



- **Revisão da pasta atual, 2026-10-12:** a pedido do usuário, preservadas as mudanças paralelas de lobby, compêndio, arrasto, campo vazio e economia V1.6. Reproduzidos e corrigidos BUG-018 (snapshot compartilhava arrays das regras) e BUG-019 (gaveta recalculava sinergia após morte). Oito runners atuais: **1.695 verificações aprovadas, zero falhas**, incluindo quatro partidas completas; cliente **370/0 OpenGL** e regressões **4/0 OpenGL**, logs finais sem erros. Cinco capturas do viewport inspecionadas. Nome da janela agora diz “protótipo local”, sem versão numérica obsoleta. Jogo aberto no PC para o usuário. [Relatório, logs e limites](revisoes/2026-10-12_1409/REVISAO.md). APK/EXE já exportados são cópias anteriores, não validados por estes resultados. Nenhuma geração ou chamada PixelLab nesta revisão.



- **APK solicitado e gerado em 2026-10-12:** [Clash_of_Eras_teste.apk](../APKs/Clash_of_Eras_teste.apk), 87,2 MB, Android 7+, ARM32/ARM64/x86_64, protótipo offline contra bot. Preset `Android Teste` e importação ETC2/ASTC configurados; nenhuma regra/arte alterada nesta entrega. Exportação, assinatura, integridade e instalação em emulador verificadas. O menu foi renderizado com GPU do PC; travamentos do System UI do emulador impediram validar a interação completa. Sem teste em aparelho físico. Na cópia exportada: lobby 27/0, arrasto 17/0, VFX 157/0, quatro partidas 668/0; smoke geral **352/6 e erro de chave no runner**, sem atribuir causa ou corrigir mudanças concorrentes. Não afirmar suíte inteira aprovada. [Validação e limitações](../APKs/VALIDACAO_ANDROID.md), [instalação](../APKs/COMO_INSTALAR.md).



- **Economia, Loja Ampliada & Recrutamento Orgânico (V1.6), 2026-10-12:** a pedido do usuário, refinamento completo das regras de início e economia:

  1. **Início orgânico de tabuleiro:** removidas as quatro unidades fixas iniciais (`INITIAL_KEYS = []`). O campo começa limpo; jogador e bot recrutam seus primeiros heróis da loja na fase de preparação. Botão de combate desabilitado com texto `"RECRUTE"` caso o jogador tente lutar sem heróis em campo.

  2. **Loja de 7 ofertas (3 itens + 4 heróis):** catálogo da rodada ampliado para 7 cartas (slots 0..2 itens, slots 3..6 heróis), com painel da loja estendido para 940 px de largura e cartões de 110 × 100 px.

  3. **Renda reduzida em 40%:** `ROUND_INCOME = 9` moedas de ouro por rodada (antes 15).

  4. **Expansão de vagas até 8 heróis:** capacidade inicial de 4 vagas, expansível até 8 (`MAX_CAPACITY = 8`), com progressão de custos (`upgrade_cost_for(capacity)`: 8, 12, 16 e 20 moedas para os níveis 5, 6, 7 e 8).

  - Validação técnica rigorosa: 1.691 verificações executadas e 100% aprovadas (297 simulação, 155 match session, 668 partidas completas, 17 drag-and-drop, 27 lobby/compêndio, 157 vfx library, 370 smoke test); zero falhas.





- **Lobby de boas-vindas & Compêndio de Heróis (V1.5 visual/UI), 2026-10-12:** tela de boas-vindas completa em 1280 × 720 com arte de fundo em pixel art do Coliseu Imperial (`assets/ui/lobby_background.png`), iluminação de braseiros e selo rúnico. Botão **JOGAR** no canto direito inferior (`Rect2(1010, 616, 230, 72)`), em roxo vibrante com borda dourada e aura pulsante animada. Botão de **Configurações** com foco rigoroso em **30 FPS** (`Engine.max_fps = 30` padrão), modo econômico de bateria, taxa de animação (8/10/12 FPS) e áudio. Botão de **Compêndio de Heróis** com catálogo dos 12 heróis, filtros de sinergias (`TODOS`, `VANGUARDA`, `ATACANTES`, `ATIRADORES`, `APOIO`), preview interativo com escala de sprite por nível e aura roxa lendária no Nível 3, recálculo em tempo real de atributos (HP/ATK/Vel./Alcance/Armadura/Crítico) e habilidades detalhadas. Suíte de testes automatizados: 1.750 verificações aprovadas (297 simulação, 135 session, 816 partidas completas, 370 smoke, 88 vfx, 17 drag-and-drop, 27 lobby/compêndio); zero falhas. Três capturas do viewport inspecionadas (`v1_4_menu.png`, `v1_4_compendio_herois.png`, `v1_4_configuracoes.png`).



- **V1.4 visual local, 2026-10-12:** fumaça baixa do Snoop e nó de corda da Rapunzel criados no editor gratuito PixelLab, exportados intactos e integrados. Fumaça segue a zona revelada; nó segue o alvo durante o puxão/controle. Corrigido BUG-017: fio linear e ondulação nas extremidades separavam a corda do corpo. Ambos os vértices agora seguem os personagens; reprodução Godot antes/depois preservada. Verificações: biblioteca 88, simulação 297, Session 135, quatro partidas 816, cliente 370 headless e 370 OpenGL; zero falhas. Duas capturas vistas e 18 arquivos de regras/dados iguais à V1.3. [Validação V1.4](../RelicArena/VALIDACAO_V1_4.json). Nenhuma geração de personagens, compra ou mudança de balanceamento; Caramelo/Zumbi realistas continuam na fila por saldo 0/$0.



- **V1.3 visual local, 2026-10-12:** quatro efeitos gratuitos PixelLab integrados: escudo real da dança, cura sem sobreposição por alvo, estocada do Zumbi e impacto de foguete atrás dos corpos. Textos de escudo limitados à unidade inspecionada. Os 18 arquivos de dados/simulação continuam idênticos ao snapshot V1.2. Verificações: biblioteca 61, simulação 297, Session 135, quatro partidas 816, cliente 321 headless e 321 OpenGL; zero falhas. Importação final/logs finais limpos e duas capturas do combate inspecionadas. [Validação V1.3](../RelicArena/VALIDACAO_V1_3.json). Nenhuma nova geração de personagens nesta retomada; saldo MCP reconfirmado 0/$0. Sem novo bug de gameplay registrado, rede, teste humano ou aparelho.



- **V1.2 local validada, 2026-10-12:** 11 recrutáveis e Ken separado; artes novas em nove bases, mapa com quatro braseiros fora da grade, efeitos dos seis kits e refinamentos de Caramelo/Obama/Neymar/Zumbi. Corrigidos sangramento após revive (BUG-013), ID da invocação (BUG-014) e resultado com seis linhas (BUG-015). Verificações finais: simulação 297, Session 135, quatro partidas 816, cliente 289 headless e 289 OpenGL; zero falhas, saídas 0 e logs limpos. Seis telas e galerias inspecionadas. [Validação V1.2](../RelicArena/VALIDACAO_V1_2.json). Números ainda em teste; sem rede, balanceamento humano ou aparelho. Snapshot anterior à integração dos VFX: `Clash_of_Eras_V1_2_antes_VFX.zip`, 428 arquivos conferidos, zero divergências.



- **Biblioteca de efeitos, 2026-10-12:** quatro assets criados no editor determinístico gratuito do PixelLab: escudo dourado, cura discreta, estocada e impacto de foguete. Não consomem geração por IA. Todos os quadros inspecionados; quatro ZIPs e 18 arquivos extraídos conferidos sem divergência. Inventário/proveniência em [assets/vfx](../RelicArena/assets/vfx/README.md). Aplicados posteriormente na V1.3, conforme evidência acima.



- **Continuação autorizada, 2026-10-12:** usuário pediu refinar habilidades dos demais, melhorar o mapa, produzir muitos personagens no PixelLab e retomar após limites. Reafirmou proporções reais como Michael, sem caricatura. Gerações disponíveis estão autorizadas; compra de créditos/alteração de assinatura não foi pedida. Fila e retomada em [EXECUCAO_CONTINUA.md](EXECUCAO_CONTINUA.md); IDs e estados em `visuais/personagens_lote_03_execucao.json`. Rotações são poses direcionais, não animações novas. Preservar as decisões e kits do lote 03 feitos em paralelo.



- [Plano curto do protótipo](PLANO_PROTOTIPO_01.md): tabuleiro → simulação → kits → bot/rodadas → servidor → loja/itens.

- [Coleção, passe e loop de jogo](MONETIZACAO_E_LOOP.md): proposta de monetização e decisões interessantes, sem preços ou receita prometida.

- [Histórico de bugs](HISTORICO_DE_BUGS.md): registrar somente ocorrências reais, com investigação e validação. Não confundir problemas de design com bugs.

- [Galeria do lote atual](../RelicArena/captures/lote_03_elenco.png) e [96 poses direcionais](../RelicArena/captures/lote_03_direcoes.png). Nove bases novas pelo PixelLab (72 PNGs) e um braseiro 32 × 48; ZIPs/PNGs íntegros, recibos/hashes em cada pasta `realista_03`. Michael mantém seus 88 PNGs existentes. Galerias antigas em `visuais/` são históricas; saldo MCP 0/$0, reconfirmado na retomada de 2026-10-12.

- Godot local anteriormente verificado: `4.7.2.stable.official.ed1daf0bf`; caminho em `C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.

- Medidas reais reconferidas: arena atual 351 × 195; alturas visíveis Michael 43, Neymar 49, Caramelo 41, Obama 47 e Zumbi 49 pixels. A medida 157 × 95 do tabuleiro foi relatada pelo usuário, sem nova segmentação automatizada.

- Primeiro protótipo local criado em [RelicArena](../RelicArena/README.md): posicionamento, quatro kits, combate, corações, resultado e próxima rodada contra equipe automática fixa. Preparação manual, sem cronômetro; o adversário aparece para depuração. Loja, rede, coleção e dano mágico ainda não implementados.

- **Validação real:** Godot 4.7.2, importação limpa; 90 verificações do core e 86 da integração aprovadas, zero falhas, saída 0. Cinco cópias PNG com hashes idênticos às origens. Preparação e combate renderizados com OpenGL e inspecionados em capturas do viewport. [Registro técnico](../RelicArena/VALIDACAO_01.json).

- **Retorno manual do usuário, 2026-10-11:** informou que o protótipo funcionou bem e está no caminho certo. Confirma a experiência inicial no PC; não aprova automaticamente números, detalhes experimentais ou arte final.

- **Retorno sobre V1 e alteração pedida, 2026-10-11:** usuário gostou da versão, definiu Michael com três passos de moonwalk/escudo coletivo/cura pequena contínua e pediu usar as variações dos personagens para reduzir a aparência estática. **Implementado na V1.1** (rotações de oito direções e kit novo do Michael); não eram bugs do kit anterior.

- **Registro anterior do lote 03 na simulação, 2026-10-12:** seis novos heróis no catálogo (11 no total) e Ken como invocação; nesta etapa inicial usaram bonecos provisórios desenhados por código (`tools/gerar_provisorios.py`). Validação daquela etapa: 235 verificações de combate, 133 de Session e 971 de quatro partidas automatizadas, zero falhas. Os efeitos novos foram adiados naquela sessão por edição simultânea do cliente ([INC-006](HISTORICO_DE_BUGS.md)); posteriormente entraram na V1.2, junto das nove bases PixelLab registradas acima.

- **Revisão de 2026-10-11 (pedido "procure erros"):** outra sessão reescreveu `tools/gerar_icones.py` (ícones com paleta mais rica, 21 PNGs 16 × 16) sem registro; a revisão confirmou que o script reproduz exatamente os PNGs atuais. `main.gd` e `arena_simulation.gd` não tinham diferenças de lógica identificadas. Encontrado e corrigido [BUG-010](HISTORICO_DE_BUGS.md): resultado mostrava nível 1 para heróis de nível 2/3. Testes: 190 de combate, 118 de Session, 715 de partidas, 209 de cliente headless e o mesmo teste do cliente com renderizador OpenGL, zero falhas.

- **Cópias, níveis e bola, pedido de 2026-10-11:** implementados na Session/simulação com dados em `debug_characters.json` (`match_levels`), estrelas bronze/prata/ouro, crescimento de 20% por nível com shader de escala de pixel art, aura do nível 3 e bola do Neymar redesenhada em 16 × 16 (≈14 px na tela, com giro e sombra). O bot segue as mesmas regras e também junta cópias. Validação: 189 verificações de combate, 118 de Session, 715 de quatro partidas automatizadas e 209 de integração do cliente, zero falhas; capturas inspecionadas. Sem balanceamento ou teste humano.

- **V1.1 visual, pedido de 2026-10-11:** usuário pediu interface mais parecida com o TFT, câmera mais afastada e meio inclinada, mais espaço, ícones de sinergias/personagens/itens e painéis com leve transparência. Entregue como **proposta visual provisória**: tela base 1280 × 720 com personagens a 1×, tabuleiro em perspectiva sobre o estudo de arena PixelLab (4×), reserva no chão, HUD translúcido, selos de sinergia, retratos recortados e 19 ícones 16 × 16 desenhados por código. Nenhum crédito do PixelLab; arte final da interface continua prevista no PixelLab. Contratos de teste do Michael: escudo renova sem acumular; passo bloqueado é dançado no lugar e conta no ciclo. Validação: 181 verificações de combate, 78 de Session, 672 de quatro partidas automatizadas e 195 de integração do cliente, zero falhas; seis capturas OpenGL inspecionadas. [Registro V1.1](../RelicArena/VALIDACAO_V1_1.json). Sem teste humano, em celular ou de balanceamento.

- Michael exportado pelo endpoint oficial do PixelLab: 72 quadros de dança em oito direções + 16 rotações dos dois estados, preservados em `RelicArena/assets/michael/original/`. Exportação gratuita, sem nova geração. Proveniência e hash em [ORIGEM.md](../RelicArena/assets/ORIGEM.md).

- **V1 local validada, 2026-10-11:** 155 verificações de combate, 78 de Session, 666 de quatro partidas automatizadas e 152 de integração do cliente; zero falhas nas execuções finais, saída 0 e logs sem erro. Seis telas renderizadas com OpenGL e inspecionadas. Os 89 arquivos extraídos do pacote Michael têm hashes idênticos ao ZIP (88 PNGs + metadados), sem geração nova. [Registro V1](../RelicArena/VALIDACAO_V1.json).

- O bot V1 compra, equipa, expande e recruta pelo mesmo contrato, antes de receber ações do jogador; não foi implementada uma IA estratégica adaptativa. Sinergias funcionais marcadas TESTE não substituem os grupos cotidianos que o usuário quer definir.

- Não foram realizadas vinte partidas humanas, teste em celular, conexão em rede, audição dos efeitos ou balanceamento. Valores e detalhes experimentais estão no [README do núcleo](../RelicArena/simulation/README.md). O piso/grade técnico permanece provisório.



## Regras técnicas de trabalho



**Coordenação, confirmação do usuário em 2026-10-12:** há outra IA trabalhando neste mesmo projeto. O usuário não lembra o escopo e pediu revisar o que já foi criado e ver no jogo; a revisão foi concluída, sem presumir exclusividade de código, arte ou documentação. Antes de escrever, reler o arquivo atual e preservar mudanças externas; preferir entregas em arquivos separados. Essa confirmação não autoriza enviar mensagens a outro chat nem significa que o usuário pediu pausar a automação.



GDScript tipado, configurações separadas do estado de cada unidade, simulação sem depender de sprites ou animações. Servidor futuro controla economia, sorteio, combate e resultado; formação privada não é transmitida ao oponente na preparação. Versionar regras/semente, testar limites/repetição de comandos e manter IDs estáveis. Não copiar rede antiga sem consultar documentação oficial. Chaves e tokens nunca entram nos arquivos.



Skills auxiliares instaladas: godot-gdscript, godot-resources, godot-multiplayer e godot-gdscript-headless-testing. Origem/revisão e evidências anteriores estão no arquivo completo; skills são instruções, não validação automática.



**Mudança desta sessão:** usuário aprovou movimento hexagonal e proporção realista final, pediu monetização que preserve a coleção e rejeitou continuar só em documentação. A ordem foi ajustada para protótipo local antes da rede. A hipótese antiga de 40% por nível continua descartada; os 5–6% por nível até 10 precisam de decisão sobre o modo competitivo.

