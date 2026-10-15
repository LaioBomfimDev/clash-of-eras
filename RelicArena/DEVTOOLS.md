# Ferramenta de desenvolvimento — F6

Implementação local e reformulação visual entregues em 2026-10-15. Abra `Abrir Ferramenta DEV.cmd` na pasta principal ou execute o projeto com **F5** no Godot e pressione **F6 dentro da janela do jogo**. O botão HUD **🛠️ F6 · DEV** no canto superior esquerdo também abre/fecha o painel; F6 ou Esc fecha instantaneamente sem perder o rascunho de texto e sem alterar a pausa.

## Novidades da reformulação visual e controles (2026-10-15)

1. **Controle de Transparência / Opacidade (20% a 100%):**
   - Slider no topo (`👁️`) com exibição percentual em tempo real e chips rápidos `[50%]`, `[75%]`, `[90%]`, `[100%]`.
   - Permite enxergar a arena, personagens, projéteis e barras de vida por trás do painel enquanto você edita dados em combate.
   - Preferência salva automaticamente no computador em `user://devtools/devtools_prefs.json`.

2. **Botões Modernizados com Identidade Visual e Ícones:**
   - Padronização em estilo flat/glass com bordas neon, cantos arredondados, margens confortáveis e feedback tátil de hover e clique.
   - Categorização por variantes:
     - **Primário (Verde Esmeralda):** Ações principais de fluxo (`⚔️ Iniciar Combate`, `🎬 Criar Cenário`, `💾 Salvar Feedback`, `➕ Adicionar Herói`).
     - **Ação / Destaque (Ciano Neon):** Passos de tempo, simulação até resultado, aplicação de equipe.
     - **Alerta / Relógio (Âmbar Dourado):** `⏸️ Pausar`, atalhos de Boss, congelar cronômetro.
     - **Perigo / Reset (Carmesim):** `✖ Fechar · F6`, `🗑️ Dispensar`, `💀 Eliminar Combatente`, derrota forçada.
     - **Secundário & Chips (Ardósia Escura):** Atalhos numéricos rápidos (+10 ouro, 100% cura, seletores de semente).

3. **Novas Configurações e Dados que Podem Ser Alterados:**
   - **Controle de Rodada e Combate:**
     - `💥 Vitória Rápida (Kill Bot)` e `🏳️ Derrota Rápida (Kill Player)` para acelerar testes de progressão.
     - Atalhos diretos de round: `[R1 Início]`, `[R2 Normal]`, `[R3 Avançado]`, `[👹 R4 BOSS DEV]`, `[R5 Endgame]`.
     - Chips de velocidade rápida: `[0.5×]`, `[1.0×]`, `[2.0×]`, `[4.0×]` além do dropdown completo.
     - Passos manuais calibrados: `⏱️ +0,05 s` (1 tick), `⏯️ +0,25 s`, `⏭️ +1,0 s`.
   - **Economia e Equipe:**
     - Chips rápidos de ouro: `[+10]`, `[+50]`, `[+100]`, `[Max 999]`, `[Zerar 0]`.
     - Chips rápidos de vida: `[❤️ +1]`, `[💔 -1]`, `[Max 5]`, `[1 Vida (Crítico)]`.
     - Chips rápidos de capacidade: `[4 Vagas]`, `[6 Vagas]`, `[8 Vagas (Máx)]`.
     - Gestão instantânea: `🎲 Renovar Loja Grátis`, `🗑️ Limpar Bolsa`, `📦 Kit Itens Básicos`, `👥 Preencher Equipe N2`.
   - **Inspetor e Modificador de Combatentes:**
     - Telemetria expandida: HP atual/máx, Escudo, Mana (0-100), Dano de Ataque, Armadura, Resistência Mágica, Velocidade de Ataque, Crítico, Hex `(X, Y)`, Alvo atual `#ID`, dano total causado, cura e abates.
     - Novos atributos editáveis diretamente:
       - **Escudo de absorção:** campo numérico + chips rápidos `[🛡️ +300]`, `[🛡️ +600]`, `[Zerar 0]`.
       - **Mana:** campo numérico + chips `[⚡ 100 Mana (Ult)]`, `[Zerar 0]`.
       - **Velocidade de ataque:** multiplicador (0.1× a 10.0×).
       - **Chance de crítico:** porcentagem (0% a 100%).
     - Ações rápidas de combate no combatente selecionado:
       - `❤️ 100% Full HP`, `🩹 50% HP`, `⚠️ 1 HP`.
       - `💫 Stun 2s` (atordoa a unidade) e `✨ Limpar Stun`.
       - `💀 Eliminar Combatente` (executa a unidade selecionada).
     - **Controles Especiais para o Boss Desenvolvedor (Round 4):**
       - Ativação condicional quando o Boss está selecionado:
       - `🔥 Forçar Teleporte do Boss` (zera o cooldown de teleporte).
       - `😡 Ativar Modo Fúria` (dispara a transição de fúria com onda de choque e buffs).

4. **Feedbacks com Avaliação em Estrelas:**
   - Botões de estrelas interativos `[1 ⭐]` a `[5 ⭐]`.
   - Categorias com ícones temáticos e exportação completa com metadados de reprodução.

## Tabela de Áreas e Controles

| Área | O que controla |
|---|---|
| Cabeçalho | Transparência do painel (slider 20%–100% e presets), telemetria da sessão (Modo, Round, Fase, Semente, FPS) e atalho de fechar. |
| Relógio | Pausa/Continuar (com indicador visual no HUD e botão), passos (+0,05s, +0,25s, +1s) e seletor/chips de velocidade (0,1× a 8×). |
| Partida | Iniciar combate, simular até resultado, próximo round, vitória/derrota instantânea, congelar cronômetro, tempos e novos cenários. |
| Equipes | Jogador ou bot: ouro, vidas (1–5), vagas (4–8), renovação de loja, limpeza de bolsa, kit de itens, preenchimento rápido de time, adição de heróis e itens. |
| Combatentes | Inspeção completa de telemetria, edição de HP, escudo, mana, ataque, defesas, velocidade, crítico, stun, cura, kill e ações exclusivas do Boss. |
| Dados | Snapshot local estruturado, cópia para clipboard, exportação de relatório JSON e abertura da pasta de registros. |
| Feedbacks | Avaliação interativa em estrelas (1 a 5), categorias com ícones, assunto, comentário e histórico com cartões dos últimos 30 registros. |

## Registros e persistência

Os arquivos JSON continuam organizados em `user://devtools` (`C:/Users/m/AppData/Roaming/Godot/app_userdata/Clash of Eras - protótipo local/devtools`):
- `devtools_prefs.json`: preferência de opacidade do usuário.
- `feedback_*.json`: feedbacks registrados com semente, round, equipes e eventos.
- `round_*.json`: relatório automático gravado ao final de cada rodada local.
- `relatorio_*.json`: relatórios exportados manualmente pelo usuário.

## Validação

Testado e aprovado com 74/74 verificações verdes no Godot 4.7.2 (`tests/test_dev_lab.gd`), além de zero regressões em `test_lobby_ui.gd` (32/32), `test_hero_skills_menu_16f.gd` (18/18) e `test_simulation.gd` (326/326).
