**Release Web Performance01 (2026-10-13):** caches gráficos, transporte e diagnóstico revisados; conjunto cliente/servidor congelado e testado. Consulte [nota de publicação](../Guia_Godot4/RELEASE_PERFORMANCE_WEB_01.md).

# Clash of Eras — protótipo local jogável

**Estado revisado em 2026-10-12:** lobby/compêndio e controles da V1.5, economia da V1.6, campo vazio para recrutar, loja com sete ofertas e capacidade até oito. Corrigidos compartilhamento de regras pelo snapshot e contagem da gaveta de sinergias durante combate. [Revisão e evidências](../Guia_Godot4/revisoes/2026-10-12_1409/REVISAO.md).

**V1.5 (controles):** arrastar e soltar para heróis, reserva, itens e loja (`client/drag_controller.gd`), sem remover toques e botões. Teste próprio: `tests/test_drag_and_drop.gd` (17 verificações com eventos reais de mouse).

Godot 4.7.2. Uma partida completa contra bot, com preparação, loja, equipamentos, combate, resultados e reinício. Nome, números e arte são provisórios.

**V1.4 visual:** fumaça baixa do Snoop e nó de corda da Rapunzel feitos no editor gratuito do PixelLab. A fumaça acompanha a zona real, mantendo os hexágonos de alcance; o nó acompanha o puxão e desaparece ao terminar o controle. Corrigido o fio que se separava do corpo: suas duas extremidades agora seguem os personagens. Os quatro efeitos anteriores continuam ativos; regras e economia permanecem iguais à V1.3.

**V1.3 visual:** quatro efeitos animados do PixelLab aplicados ao combate: escudo dourado da dança, cura discreta, estocada do Zumbi e impacto de foguete. Os clips preservam recortes e tempo dos pacotes originais. A cura acompanha o alvo e evita sobreposição; o escudo acompanha a proteção real; a explosão aparece uma vez por impacto, atrás dos corpos. Regras e dados continuam idênticos à V1.2.

**V1.2:** elenco de teste com **11 heróis recrutáveis**, mais Ken como invocação da Barbie. Entraram Barbie, Elon, Snoop, Lula, Bob Marley e Rapunzel. Nove bases do PixelLab em proporção adulta foram integradas (72 PNGs em oito direções): os sete novos visuais incluindo Ken, mais Neymar/Obama refeitos. Caramelo e Zumbi continuam provisórios porque o saldo MCP terminou. Michael mantém seus 72 quadros de dança. Galeria em `captures/lote_03_elenco.png`.

A câmera inclinada, base 1280×720, reserva no chão, corações e HUD translúcido continuam. Mapa ganhou quatro braseiros PixelLab fora da grade e contorno do tabuleiro; os kits têm efeitos próprios. O deck final de dez e a seleção desse deck continuam por implementar: o catálogo de teste ampliado não é um deck final aprovado.

## Abrir e jogar

Neste PC, dê dois cliques em **INICIAR_JOGO.cmd**. O atalho usa o Godot já instalado em Downloads; não é um executável exportado independente.

Pelo editor: abra o Godot → **Importar** → selecione **project.godot** desta pasta → **Importar e editar** → aguarde importar → pressione **F5**. F5 executa o projeto inteiro; F6 executa somente a cena aberta.

1. No lobby, escolha **JOGAR** e um dos três benefícios. O lobby também oferece compêndio e configurações de som, limite de FPS e velocidade visual da dança.
2. Você começa com o **campo vazio e quatro vagas**. Recrute heróis grátis da loja, por toque ou arrastando até um hexágono da sua metade. **Arraste** um herói já recrutado para movê-lo, até a **reserva** para guardá-lo, ou sobre outro herói para trocar os dois de lugar. Também funciona por toque: toque no herói (abre o cartão à direita) e depois no destino. Tocar no mesmo herói desfaz a seleção.
   - **Itens:** arraste da bolsa até um herói para equipar, sobre outro item para fundir; do cartão do herói para a bolsa (devolver) ou para outro herói (trocar de dono).
   - **Loja:** arraste um herói da loja até um hexágono ou a reserva para recrutar ali; arraste um item da loja até um herói para comprar e equipar de uma vez. Tocar nas cartas continua funcionando.
3. A **reserva fica no chão**, à frente do tabuleiro. Com um herói selecionado, toque num espaço vazio da reserva para guardá-lo; toque em outro herói para trocar campo ↔ reserva. O botão **RESERVAR** do cartão faz o mesmo.
4. A loja inferior tem **três itens pagos e quatro ofertas de heróis gratuitos**. Renovar custa **2 moedas**. Com o campo cheio, um novo herói vai para a reserva se houver vaga. **ESPAÇO** amplia o limite de quatro até oito, com custos sucessivos de **8, 12, 16 e 20 moedas** neste teste.
5. **Cópias:** a loja também oferece heróis que você já tem. A cópia é grátis e se junta na hora: 2 cópias = **nível 2**, 3 cópias = **nível 3** (máximo). O herói cresce 20% por nível, ganha estrelas (bronze, prata, ouro) e, no nível 3, uma aura especial. Valores de teste: vida e dano ×1,5 e ×2,25.
6. Os **ITENS** ficam sempre visíveis à esquerda. Marque um item e toque num herói (ou use **EQUIPAR** com o herói selecionado). Toque num item do cartão para devolvê-lo à bolsa. Marque dois itens compatíveis para **FUNDIR**.
7. **LUTAR** inicia o combate; ele também começa ao terminar a preparação de 30 segundos. Durante o combate, toque em qualquer herói (inclusive inimigo) para inspecionar. As sinergias mostram o patamar congelado no início da rodada.
8. Veja dano, cura e absorção por personagem no resultado e use **PRÓXIMA RODADA**. Quem perder quatro corações perde a partida; o benefício de vida extra pode acrescentar um coração uma vez.

**Receitas desta versão:** lâmina + lâmina → lâmina dupla; colete + amuleto → colete protegido. Para fundir, os dois componentes precisam estar na bolsa.

## O que já funciona

- Movimento lógico por hexágonos 8 × 8, com deslocamento visual interpolado.
- Neymar chuta bolas de futebol em pixel art (maiores, girando, com sombra) com até três impactos A → B → A entre dois inimigos vizinhos.
- Caramelo caça um atirador na abertura por até 5 s, andando por hexágonos; depois usa seleção normal. Morde, sangra e executa em mordida contra vida≤10% antes do dano. Caça/prazo são testes configuráveis.
- Obama começa com escudo da mala e renova a própria proteção até 120 a cada 5 s, sem acumular nem alterar escudo da dança (teste).
- Zumbi dá crítico/velocidade à equipe; seus próprios críticos aumentam o próximo crítico, com teto temporário e multiplicador visível.
- Michael dança usando **72 quadros originais, em oito direções**: anda três hexágonos aleatórios de costas, para e dá escudo dourado à equipe (teste: 120 por 4 s, renova sem acumular); enquanto vivo, cura 10 HP por segundo em raio de dois hexágonos.
- Barbie invoca Ken, que protege a dupla; ela causa +30% de dano enquanto ele vive. Ken não é comprado e não conta no desempate (contrato de teste).
- Elon dispara foguetes com explosão vizinha; Snoop cria fumaça com dano contínuo e chance de erro.
- Lula revive uma única vez por rodada com 40% da vida; Bob acelera aliados e desacelera inimigos no raio, crescente por nível.
- Rapunzel puxa o inimigo mais distante com a trança e atordoa. Valores de recarga/raio/erro são experimentais.
- Dano físico e mágico, armadura/resistência, equipamentos e três sinergias funcionais provisórias identificadas como **TESTE**.
- Ouro guardado entre rodadas, renovação por duas moedas, expansão, bolsa, reserva, fusões e benefícios no início e na quarta rodada.
- Bot compra/equipa/expande com o mesmo orçamento inicial e regras. Ele prepara antes das ações do jogador, sem consultar sua nova formação para contra-atacar.
- Preparação mostra somente a formação inimiga da rodada anterior; a formação atual aparece ao começar a luta.
- Combate até 30 segundos, aceleração de ataques/movimento/voo aos 15; resultado por sobreviventes e depois dano efetivo. Empate completo preserva vidas.
- Efeitos sonoros simples sintetizados por código, com controle de som; nenhuma música comercial. Arte nova foi gerada no PixelLab, preservando ZIPs/PNGs originais.

## Valores de teste e próximos limites

25 moedas iniciais, **9 de renda por rodada**, expansão progressiva por 8/12/16/20, reserva de cinco, bolsa de oito itens e quatro equipamentos por unidade. Bônus e atributos são ajustáveis; não foram balanceados. Sinergias cotidianas, seleção do deck, intervenções, coleção/passe e níveis fora da partida ainda precisam de desenvolvimento. Nova produção de personagens aguarda a atualização de acesso registrada no [lote 04](../Guia_Godot4/PERSONAGENS_LOTE_04.md); as artes atuais continuam provisórias.

Esta versão roda **localmente contra bot**. Servidor dedicado, conexão entre jogadores e publicação continuam etapas futuras. Há um [APK de teste separado](../APKs/VALIDACAO_ANDROID.md), exportado antes das correções desta revisão e com limitações próprias; não foi testado em aparelho físico. A janela usa paisagem e aceita emulação de mouse por toque. O fundo da batalha é o estudo de arena do PixelLab (não aprovado como arte final); tabuleiro, ícones e painéis são provisórios.

Os seis efeitos foram produzidos no editor determinístico gratuito do PixelLab, sem consumir gerações por IA. Estão na [biblioteca de VFX](assets/vfx/README.md), com folhas, manifestos, originais e conferência de integridade. Os demais efeitos provisórios continuam por código; não foram geradas animações novas de caminhada/ataque dos personagens.

## Arquivos e validação

- data/debug_characters.json: atributos e nomes provisórios.
- client/main.gd: tela, toque e efeitos; client/board_projection.gd: câmera em perspectiva; client/ui_kit.gd: tema translúcido, ícones e selos.
- tools/gerar_icones.py: recria os ícones16×16 provisórios; tools/capture_preview.gd: capturas do viewport (`-- --menu|--benefit|--items|--combat|--result`, com `--levels`, `--ball` ou `--kits` para o lote novo); client/pixel_scale.gdshader: escala de pixel art.
- tools/capture_art_batch.gd e capture_roster.gd: galeria de originais pelo viewport. tools/verificar_originais.ps1: compara extrações com ZIPs/recibos.
- client/vfx_library.gd: lê os clips originais de efeitos; tests/test_vfx_library.gd verifica quadros, offsets e fim/loop.
- data/item_catalog.gd: itens, preços e receitas de teste.
- simulation/match_session.gd: economia, comandos, informações privadas e ciclo da partida.
- simulation/arena_simulation.gd: regras de combate sem interface.
- client/: interface, apresentação e sons; não decide gastos ou dano.
- assets/ORIGEM.md: origem e integridade dos PNGs, incluindo exportação original de Michael.
- [Cérebro](../Guia_Godot4/CEREBRO.md), [histórico de bugs](../Guia_Godot4/HISTORICO_DE_BUGS.md), [validação V1](VALIDACAO_V1.json), [V1.1](VALIDACAO_V1_1.json), [V1.2](VALIDACAO_V1_2.json), [V1.3](VALIDACAO_V1_3.json) e [V1.4](VALIDACAO_V1_4.json).
- [Fila e retomada](../Guia_Godot4/EXECUCAO_CONTINUA.md), [elenco e propostas](../Guia_Godot4/ELENCO_E_KITS_V2.md). Artes/nomes finais não são aprovados automaticamente pela integração.

O protótipo anterior foi preservado em `Guia_Godot4/RelicArena_prototipo_01.zip` e a V1 em `Guia_Godot4/Clash_of_Eras_V1_local.zip`. O snapshot anterior aos efeitos está em `Guia_Godot4/Clash_of_Eras_V1_2_antes_VFX.zip`, com recibo de 428 arquivos verificados.

Snapshots posteriores: `Guia_Godot4/Clash_of_Eras_V1_3_local.zip` e `Guia_Godot4/Clash_of_Eras_V1_4_local.zip`. Cada recibo `.zip.json` informa o SHA-256 e a comparação de todos os arquivos empacotados; a pasta atual continua sendo usada pelo atalho de jogar.

Validação V1.4: simulação 297, Session 135, quatro partidas 816, biblioteca de efeitos 88 e cliente 370 tanto headless quanto OpenGL; zero falhas. Duas capturas reais em `captures/v1_4_support_*.png`, sem ler a tela do computador. BUG-017: seis amostras antes/depois do puxão, com extremidades alinhadas após correção. Os 18 arquivos de dados/simulação permanecem idênticos ao snapshot V1.3. Para repetir os testes no PowerShell:

~~~powershell
$gameGodotConsole = 'C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe'
$gameProjectRoot = 'C:/Users/m/Documents/Relic Arena MY/RelicArena'
& $gameGodotConsole --headless --path $gameProjectRoot --import
& $gameGodotConsole --headless --path $gameProjectRoot --script res://tests/test_simulation.gd
& $gameGodotConsole --headless --path $gameProjectRoot --script res://tests/test_match_session.gd
& $gameGodotConsole --headless --path $gameProjectRoot --script res://tests/test_full_matches.gd
& $gameGodotConsole --headless --path $gameProjectRoot --script res://tests/test_vfx_library.gd
& $gameGodotConsole --headless --path $gameProjectRoot --script res://client/smoke.gd
~~~

Os runners retornam saída 1 ao registrar falha; sempre confira também o log, pois erro de script pode aparecer mesmo com saída 0 do motor. Os testes verificam contratos de regras e integração; não demonstram balanceamento, experiência em celular ou qualidade final da arte.


