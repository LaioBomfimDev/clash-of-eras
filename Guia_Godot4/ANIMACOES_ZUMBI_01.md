# Animações do Zumbi — produção 01

## Entrega atual — 2026-10-13

**Piloto jogável para leste:** caminhada (9 quadros,30FPS), estocada (6 posições de reprodução,20FPS) e inspiração (10 posições,14FPS), mais pose com os pés no chão entre ações. São **19 PNGs distintos** no manifesto; retornos reaproveitam os quadros originais na ordem reversa. O tamanho de tela do Zumbi N1 é76px e o dos demais humanos68–70px, sem reduzir os arquivos. As oito direções e lâminas animadas N2/N3 ainda não estão concluídas.

Estocada v3 usa braços estendidos e joelhos flexionados, com uma ponta à direita. A sequência curta chega ao contato em50ms e retorna à pose; não altera o instante do dano da simulação. O quadro de contato recebeu deslocamento de4px no editor gratuito do PixelLab para manter a base em143: comparação confirmou os pixels originais intactos no novo canvas. Inspiração v2 mantém uma lança vertical enquanto o punho sobe; volta pelos mesmos cinco PNGs. Durante esse gesto sem alvo o personagem pode virar para a plateia usando o clip leste real, mesmo se o adversário estiver noutra direção. Ataques continuam exigindo a direção exata.

Gerações novas concluídas e inspecionadas quadro a quadro nesta retomada:

| Ação | Job | Cobrança | Exportação |
| --- | --- | --- | --- |
| Pose de contato | `50d9f0c5-0f79-4304-8c0b-58847ea22a0b` |1| `pose_estocada_contato.png` |
| Extensão v3 | `c8740275-d0f4-471c-9504-58b41f91fbdf` |3| `exports/attack_east_03`, ZIP86arquivos/0divergências |
| Pose do punho erguido | `8fdd25ac-7bf7-43e8-a0e1-8523765e4cd8` |1| `pose_inspiracao_fim.png` |
| Inspiração v2 | `515e8d45-026c-4080-b810-a0a55008ece7` |2| `exports/skill_east_02`, ZIP91arquivos/0divergências |

Os ZIPs incluem estudos rejeitados e vistas oeste adicionadas em paralelo, ainda fora deste manifesto. Inspecionar essas vistas antes de gastar em novas gerações. Não há job pendente desta fila. Saldo final consultado: **12 restantes,27 usadas,total40,US$0,trial**.

Verificado: banco122/0, controlador97/0, integração30/0, cliente444/0 headless e444/0 OpenGL, VFX237/0. Três capturas reais do cliente mostram skill, caminhada e estocada por eventos da simulação numa sessão isolada; não são teste de rede ou balanceamento. Capturas e recibo em `RelicArena/captures/zumbi_game_*_2026-10-13.png` e `zumbi_animation_game_evidence.json`. A vitrine ampliada está em `tools/preview_zumbi_animations.gd`; iniciar por `RelicArena/Testar_animacoes_Zumbi.cmd`.

**Limite da verificação:** outra IA alterou `main.gd` durante a janela dos testes finais. Banco, controlador, loader, animações e manifesto VFX ficaram estáveis nos hashes antes/depois. As contagens registram execuções reais, mas não congelam toda a versão do cliente atual. Logs/hashes em `revisoes/animacoes_2026-10-13/`; novas mudanças da outra IA precisam da própria validação. As seções abaixo preservam o histórico da produção e suas correções.

## Revisão independente — 2026-10-13, prevalece sobre a fila anterior

Somente **walk leste v2** permanece ativo. A revisão de todos os 16 quadros novos rejeitou `spear_thrust_v2` como estocada (ele caminha segurando a lança, cuja ponta recua 7 px), e `skill_rally_v1` por lâmina ausente no 003 e duplicada no 005. Foram retirados do manifesto, preservados nos diretórios e no ZIP oficial; os rótulos "concluída e integrada" da tabela abaixo são registros anteriores corrigidos por esta seção. Recibo: `revisoes/animacoes_2026-10-13/review_attack_skill.json`. Não confundir carregamento técnico com aprovação visual.

Checkpoint oficial completo: `RelicArena/assets/characters/zumbi/animacoes_01/exports/checkpoint_2026-10-13/`; 51 arquivos, 42 quadros de animação incluindo rejeitados, zero divergências entre ZIP e extração, oito vistas iguais aos inputs. SHA-256 do ZIP: `4892feb2c6e6763443edf0723710299fee5093a214a19065e33cb484625aeabe`.

Correção em produção: pose final de estocada `50d9f0c5-0f79-4304-8c0b-58847ea22a0b` (1 geração) mostra braços estendidos, joelho flexionado e ponta à direita. O editor gratuito acolchoou a pose inicial de 160×128 para 200×128, sem alterar seus pixels (comparação RGBA confirmou igualdade no recorte x20..179). Novo job `c8740275-d0f4-471c-9504-58b41f91fbdf`, grupo `713a8133-fc86-4c50-a510-51b8965b6418`, **3 gerações**, cinco quadros incluindo referência: interpolação apenas da extensão; retorno proposto por ordem reversa dos mesmos PNGs, sem redesenhar. Ainda aguarda inspeção. A primeira solicitação foi recusada por dimensões diferentes; não iniciou geração.

Saldo consultado antes dessa correção: **19 restantes, 20 usadas, total40, US$0, trial**. Transcrever os campos de nova consulta após conclusão; não inferir saldo por subtração. Não gerar outra ação enquanto o job está pendente.

Código de apresentação e escala: cliente **444/0 headless e 444/0 OpenGL**, VFX **209/0**, banco **122/0**, controlador **89/0**, integração **29/0**. Os três últimos usam fixtures, não aprovam os PNGs. Evidências/hashes em `revisoes/animacoes_2026-10-13/`; testes finais do cliente usam somente walk leste. Smoke foi atualizado para moeda32×32 e início explícito do bot: outra IA mudou JOGAR para matchmaking gráfico, preservado. Nenhuma regra de combate foi alterada por essa correção de testes.

Cobertura ainda parcial: uma direção de caminhada; as outras sete usam a arte anterior. Clips animados usam arte N1 com multiplicador de tamanho por nível; a lâmina extra de N2/N3 permanece nas poses estáticas, ainda não foi produzida para os clips. Escala intermediária é teste visual, não aprovação final.

## Pedido confirmado em 2026-10-12

O usuário atualizou a chave e autorizou começar pelo Zumbi do lote 04: animações reais de braços/pernas, caminhada, ataque e habilidade, com efeitos próprios. Reduzir somente a escala de exibição do Zumbi, preservando os pixels detalhados; aumentar os demais para encontrar um tamanho intermediário no tabuleiro. A escala escolhida para a primeira captura é teste visual, não aprovação final de tamanho.

O kit continua sendo estocadas, bônus de crítico/velocidade à equipe e crescimento dos próprios críticos. Animações não concedem dano nem alteram cadência, economia ou sorteios. Não acrescentar veneno. Proposta visual: gesto de inspiração no começo do combate para representar o bônus passivo já existente; os críticos destacam a mesma estocada.

## Conexão e originais

- A conexão nativa desta sessão ainda respondeu com a conta antiga (0 gerações). A configuração salva pelo usuário foi consultada pelo **mesmo endpoint oficial MCP**, sem expor a chave: nova conta confirmou **40 gerações**, US$ 0, trial, bônus diário 5 informado pelo serviço.
- O personagem do lote 04 `47e44cf4-8365-4c14-8d6f-15ff0fbc4498` não existe nessa nova conta. Foram importadas suas oito imagens locais: frente aprovada `juncao_DE.png` e as sete rotações originais. Nenhum redesenho solicitado; resposta cobrou **0,25 geração**, modo `v3 import`.
- Personagem importado: **`6a5ec045-5930-4955-a684-ef864e5607b9`**. Grupo `b05314cd-22bf-43f1-9c8d-b91da1ec9a9f`. O manifesto jogável continua selecionando os originais anteriores enquanto os clips são produzidos e inspecionados.
- Chamadas oficiais e respostas sem credenciais: `visuais/animacoes_zumbi_01/`. O helper `RelicArena/tools/pixellab_mcp_request.ps1` lê a configuração do usuário e não registra a chave.

## Fila real

| Trabalho | Estado | Evidência |
| --- | --- | --- |
| Importação das oito vistas | Concluída | `importar_personagem_resultado.json` |
| Caminhada leste v1, 8 quadros v3 | Exportada e rejeitada; **fora do jogo** | job `992af6cf-b971-404b-891c-8c3bd22a78a0`, grupo `432c8443-eea7-4ccc-afce-cec74ebf1228`, cobrança real **4 gerações**; pedra acompanha primeiros passos e ciclo não fecha |
| Pose de combate leste, sem pedra | Inspecionada e limpa | edição Pixen `ee1735f5-1b75-4b9a-802e-b1040c49582c`, **1 geração**; editor gratuito removeu 682 pixels da faixa de chão opaca acrescentada pelo gerador, imagem `2a6325bf-ac24-49c7-881a-24e47b7a3adb` |
| Caminhada leste v2 | Concluída e integrada | job `f789806a-20c2-4b68-b2b2-edaaf9f21316`, grupo `5145ab56-6a4d-41be-8dbd-794779858625`, **3 gerações**, 9 quadros; âncora [64, 149]; integrada no manifesto oficial |
| Estocada frontal v2 | Concluída e integrada | job `03489e7e-80b1-4cab-a0c7-cb2ea85ade13`, grupo `17a8c667-bd7b-4cda-8924-2e69ad58fa4b`, **5 gerações**, 9 quadros (160x128); âncora [107, 143]; estocada perfurando para o Leste sem inversão da lança |
| Gesto de inspiração v1 | Concluído e integrado | job `6828b770-06dd-4ec7-9400-de3e06abfc0a`, grupo `ccfe3127-876a-42c1-833f-59811be39e89`, **3 gerações**, 7 quadros (128x128); âncora [84, 151]; gesto de liderança e grito de guerra erguendo a lança para o buff da equipe |
| Demais direções/personagens | Fila futura | Saldo restante atual: **19 gerações** (uso consciente mantido) |

A caminhada pede passos alternados, joelhos e braços articulados, lança rígida e ausência da pedra durante deslocamento. O gerador pode ignorar isso; inspecionar todos os quadros antes de integrar. A pose de apresentação original continua preservada.

Diário atual legível por máquina: `visuais/animacoes_zumbi_01/diario.json`. Exportação v1: 17 arquivos conferidos contra ZIP, zero divergências; oito vistas importadas são pixel a pixel iguais aos **inputs enviados** (frente = conceito aprovado `juncao_DE.png`, outras sete = exportação anterior). Isso não afirma que o conceito de frente seja byte a byte igual à rotação sul da exportação anterior.

Escala intermediária implementada e capturada: Zumbi 123→76 px totais no N1 (~70 px de corpo), outros humanos ~68 px, Obama/Lula70, Caramelo56. N2/N3 do Zumbi preservam crescimento de sprite e lâmina (95,6/119,2 px). PNGs intactos; compêndio não mudou. Testes da escala: cliente 440/0 headless e 440/0 OpenGL, arrasto18/0; hashes/medidas em `RelicArena/captures/lote_04_escala_medidas.json`. A outra IA continua podendo editar o projeto; vincular validações aos hashes registrados.

Uma chamada inicial foi recusada por usar `initial_pose`/`subject_description`, campos aceitos apenas em `pixminimax`. A chamada foi corrigida removendo esses campos; o job acima é a única geração de caminhada efetivamente enviada até este registro. Isso não é um bug do jogo.

## Verificação realizada

Banco opcional de animações: runner isolado **82 verificações, 0 falhas**, Godot 4.7.2, saída 0, stderr vazio. Esse resultado verifica fixtures e contrato do banco, **não** comprova animações reais ou integração. Logs em `revisoes/animacoes_2026-10-12/`.

Ampliação posterior: banco agora aceita `skill` sem repetição, **122/0**; controlador separado de tempo local/deduplicação/interrupção **89/0**. Ainda são testes de contrato sem aprovação de frames reais.

Os dois estudos manuais anteriores do Neymar foram rejeitados visualmente e permanecem fora do jogo em `visuais/animacoes_personagens_01/`; não confundir com animações aprovadas.
