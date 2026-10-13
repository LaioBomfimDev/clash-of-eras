# Revisão da pasta atual — 12/10/2026

Pedido: revisar o trabalho criado hoje, preservar alterações da outra IA e mostrar o estado no jogo. A comparação inicial das 11h30 com a V1.4 ficou desatualizada durante o trabalho. Esta revisão usa a pasta das 14h09 em diante, com controles/lobby V1.5 e economia V1.6; não restaura o ZIP antigo.

## Estado visto no Godot

- Lobby com JOGAR, compêndio e configurações. Catálogo mostra 12 entradas: 11 recrutáveis e Ken invocado.
- Campo vazio, quatro vagas iniciais, três itens pagos e quatro ofertas de heróis grátis. Renovação 2; renda 9; expansão até oito por 8/12/16/20. Números de teste preservados.
- Movimento por hexágonos, arrasto, cópias/níveis, itens, bot, combate, resultados e próxima rodada continuam ativos.
- Michael mantém dança, moonwalk, escudo e cura. As demais bases têm poses direcionais, sem novos ciclos de caminhada/ataque; Caramelo/Zumbi continuam provisórios.

## Correções desta revisão

**BUG-018:** `snapshot_for_team()` compartilhava os arrays `copies_for_level`/`power_multiplier` com a autoridade. A reprodução mudou o multiplicador interno de 1,5 para 9 e o limite de cópias de 3 para 99 por meio do snapshot. Agora os arrays são cópias profundas.

**BUG-019:** após a morte do Elon numa formação Neymar+Elon, a gaveta dizia “Atiradores · 1 membros”, enquanto a barra e o bônus preservavam a formação de dois. Gaveta e assinatura de atualização agora usam o mesmo snapshot congelado da barra. A fixture altera a morte de uma sessão descartável para isolar esse contrato; não representa uma partida humana.

`repro_antes.log/.stderr.log`: 2 aprovadas/2 falhas, saída 1. `repro_depois.log`: 4/0, saída 0 e stderr vazio. A regressão permanente está em `RelicArena/tests/test_review_contracts.gd`. Cópias anteriores dos arquivos em `antes/`.

Nome do projeto/janela corrigido para “Clash of Eras - protótipo local”, evitando anunciar V1.3/V1.4 para uma pasta já ampliada. README/cérebro/checkpoint atualizados. O manifesto de VFX antecipava quatro integrações inexistentes; seus indicadores agora registram pendência. Nenhum PNG/ZIP original alterado, patch VFX aplicado ou regra de balanceamento modificada.

## Validação executada nesta pasta

Godot `4.7.2.stable.official.ed1daf0bf`, importação saída 0 e stderr vazio. Logs individuais e recibo `testes.json` nesta pasta.

| Runner headless | Aprovadas | Falhas |
| --- | ---: | ---: |
| Simulação | 297 | 0 |
| Session | 155 | 0 |
| Quatro partidas completas por sementes | 668 | 0 |
| Biblioteca VFX | 157 | 0 |
| Arrastar e soltar | 17 | 0 |
| Lobby/compêndio | 27 | 0 |
| Regressões desta revisão | 4 | 0 |
| Cliente geral | 370 | 0 |
| Total | 1.695 | 0 |

Todos com saída 0 e stderr vazio. Renderizador OpenGL: cliente geral 370/0 e regressões 4/0, saídas 0/stderr vazio. O total headless não soma novamente essas repetições. A biblioteca foi reconferida após a correção somente de metadados do manifesto, 157/0.

Capturas do viewport inspecionadas, todas 1280×720: [lobby](capturas/revisao_menu.png), [compêndio](capturas/revisao_compendio_herois.png), [preparação real com campo vazio](capturas/revisao_preparacao.png), [combate](capturas/revisao_support_combate.png) e [resultado](capturas/revisao_support_resultado.png). Combate/resultado usam formações de diagnóstico recrutadas por comandos legais; não representam a formação inicial do jogador. JSONs registram fase/nome do projeto. As primeiras tentativas menu/heroes passaram flags escalares incorretamente no wrapper PowerShell e capturaram preparação; logs `*_tentativa1.log` preservados, capturas finais foram refeitas com argumentos explícitos. Nenhuma captura histórica V1.4 sobrescrita.

Jogo aberto pelo executável Godot instalado, com este projeto: processo/janela responsiva e `CLIENT_READY` confirmados em `jogo_aberto.json/.log`. Não foi controlado por captura do sistema operacional. O atalho `RelicArena/INICIAR_JOGO.cmd` abre o mesmo projeto; EXE/PCK e APK anteriormente exportados não incorporam estas correções automaticamente.

## Pendências preservadas

- Cinco pacotes VFX novos existem e foram conferidos pela revisão de arquivos. `explosao_02`, `foguete_02`, `fumaca_02` e `anel_fumaca_01` aguardam `tools/vfx_habilidades_02.patch`; `charuto_01` reservado ao lote 04. Os seis clips anteriores continuam em combate. Esta entrega não integra o patch.
- O gerador de capturas antigo presume heróis iniciais em `--levels`, `--items`, `--combat` sem elenco; `capture_drag.gd` também presume IDs recrutados. Não usar esses modos como evidência de gameplay sem atualizar a fixture. A cópia externa desta revisão preserva o original e usa apenas modos adequados.
- Novo lote de personagens segue `PERSONAGENS_LOTE_04.md` e aguarda aviso de acesso atualizado. Nenhuma ferramenta PixelLab chamada, geração enviada, compra ou tentativa de contornar quota nesta revisão.
- APK tem validação própria e limitações em `APKs/VALIDACAO_ANDROID.md`; suas seis falhas de smoke são da cópia congelada anterior. Os resultados acima são da pasta atual no PC e não substituem testes Android.
- Não houve partida humana, balanceamento, desempenho medido, celular físico ou rede. A concentração/clareza de efeitos e a escala da nova arte ainda precisam ser avaliadas jogando.
