# Biblioteca de efeitos PixelLab — 2026-10-12

Seis efeitos criados no editor determinístico gratuito `vfx_workbench`, exportados pelo PixelLab e revisados quadro a quadro. Não houve geração por IA, compra ou alteração de assinatura. Os originais foram preservados. **Integrados ao cliente V1.4 e conferidos em combate.** Os recibos/reviews originais registram o estado na exportação; o inventário desta pasta registra o estado atual.

| Efeito | Clip sem personagem | Quadros empacotados | FPS | Tamanho de cada quadro | Offset | Loop |
| --- | --- | --- | --- | --- | --- | --- |
| Escudo dourado da dança | `escudo_danca_01/original/part-bubble_shield.png` | 12 | 10 | 43 × 43 | (-21, -43) | Sim |
| Cura discreta | `cura_01/game_pack/part-cura.png` | 11 | 16 | 19 × 23 | (-9, -20) | Não |
| Estocada metálica | `estocada_01/part-estocada.png` | 7 | 24 | 24 × 6 | (-1, -3) | Não |
| Impacto de foguete | `foguete_01/game_pack/part-fire_blast.png` | 11 | 24 | 26 × 26 | (-13, -13) | Não |
| Fumaça baixa | `fumaca_01/original/part-fumaca.png` | 16 | 10 | 29 × 7 | (-13, -3) | Sim |
| Nó de corda | `laco_01/game_pack/part-laco.png` | 11 | 16 | 24 × 15 | (-12, -8) | Não |

### Efeitos de habilidade 02 (Claude, 2026-10-12)

Pedido do usuário: começar as animações das habilidades (fumaça do Snoop, foguete do Elon causando explosões). Cinco efeitos novos no mesmo editor gratuito, **zero geração por IA**, desenhados para o tamanho real das áreas (raio 1 = hexágono central + seis vizinhos, ~3 hexágonos de largura) e já pensando nos sprites maiores do [lote 04](../../../Guia_Godot4/PERSONAGENS_LOTE_04.md). Os seis efeitos acima continuam no manifesto como reserva; nada foi apagado. Clip `whole` sem personagem (o efeito não tem sujeito). Recibo com IDs, link e SHA-256 em cada `ORIGEM.json`.

| Efeito | Pasta | Quadros | FPS | Quadro | Offset | Loop | Uso |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Explosão do foguete (clarão, bola de fogo, onda no chão, poeira, destroços, fumaça) | `explosao_02/game_pack/whole.png` | 14 | 18 | 131 × 103 | (-75, -68) | Não | Impacto primário do Elon; origem no **chão** do alvo. |
| Foguete em voo (corpo pixelado, chama, rastro) | `foguete_02/game_pack/whole.png` | 8 | 16 | 70 × 12 | (-58, -5) | Sim | Projétil do Elon; direção base +x, girar para o alvo. |
| Nuvem de fumaça lilás | `fumaca_02/game_pack/whole.png` | 16 | 10 | 222 × 131 | (-110, -62) | Sim | Zona do Snoop; origem no centro do hexágono central. |
| Anel de fumaça | `anel_fumaca_01/game_pack/whole.png` | 8 | 16 | 49 × 30 | (-38, -15) | Sim | Tiro básico do Snoop; direção base +x. |
| Brasa e fumaça do charuto | `charuto_01/game_pack/whole.png` | 12 | 10 | 15 × 46 | (-4, -42) | Sim | **Reservado** para a ponta do charutão do Snoop do lote 04; não integrado. |

### Explosão grande 03 e estilhaços (Claude, 2026-10-12)

Pedido do usuário: aumentar visualmente as explosões do Elon para ver todo o impacto real. Dois efeitos novos no mesmo editor gratuito (zero geração por IA). **Integrados ao cliente** junto com os quatro clips 02 acima (patch `tools/vfx_habilidades_02.patch` aplicado). Validação em [VALIDACAO_VFX_03.json](../../VALIDACAO_VFX_03.json).

| Efeito | Pasta | Quadros | FPS | Quadro | Offset | Loop | Uso |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Explosão grande: clarão, bola de fogo, cogumelo de fumaça, onda de fogo e poeira até a borda dos vizinhos, estouros nos seis vizinhos, destroços, marca queimada | `explosao_03/game_pack/whole.png` | 17 | 18 | 240 × 207 | (-120, -132) | Não | Impacto do foguete; origem no chão do hexágono central. |
| Estilhaço no vizinho | `estilhaco_01/game_pack/whole.png` | 10 | 18 | 65 × 67 | (-33, -52) | Não | Cada inimigo atingido pelo `splash`; origem nos pés. |

Papel de cada efeito no campo `runtime_role` do manifesto: `active`, `fallback` (`foguete_01`, `explosao_02`, `fumaca_01`, usados só se o preferido faltar) ou `reserved` (`charuto_01`).

`client/vfx_library.gd` lê `manifest.json` nesta pasta e seleciona os clips dos manifestos originais, fontes dos recortes, posição e tempo. Cura e impacto têm 12 quadros no canvas original; o game pack omite o último quadro transparente. Não usar a quantidade do GIF para inferir a quantidade de quadros da folha PNG.

Contratos de integração:

- Extrair os quadros na ordem esquerda → direita, de cima para baixo, usando as dimensões e colunas do manifesto original. Aplicar `offset` em relação aos pés/origem do efeito; não recalcular a âncora a cada quadro.
- Usar filtro nearest. Começar em escala 1× e avaliar a legibilidade com várias unidades, sem ampliar a área aparente de dano.
- Escudo: `whole-with-sprite.png` contém o Michael e serve apenas de referência. Usar o clip sem personagem, com duração controlada pelo estado real do escudo.
- Estocada: direção base +x. Girar o clip completo em direção ao alvo; não alterar a folha original.
- Cura e explosão: executar a partir do evento real da simulação. A imagem não decide alcance, dano, cura ou duração da regra.
- Cura: somente eventos com cura efetiva; um clip por alvo, acompanhando seu deslocamento, removido quando morre/sai do campo. Estocada: somente impacto do Zumbi. Foguete (**contrato mudado pelo usuário em 2026-10-12**, antes era "sem repetir em cada alvo vizinho"): uma `explosao_03` por impacto primário, no chão do alvo, **na frente dos corpos** com alfa 0,88; cada `splash` mostra só o `estilhaco_01` nos pés daquele vizinho, nunca outra explosão grande; o evento `explosion` acende por 0,9 s exatamente os hexágonos do raio recebido; o mundo treme 0,3 s (até 5 px inteiros), o HUD não. Em voo, `foguete_02` girado na direção do alvo. Sem os pacotes, volta ao `foguete_01` atrás dos corpos ou ao desenho procedural.
- Textos de escudo aparecem somente na unidade inspecionada; barras e bolhas mostram a proteção de toda a equipe. Animações transitórias são limpas ao mudar de rodada/menu.
- Fumaça: com `fumaca_02`, um clip por zona na escala de perspectiva da célula central, alfa 0,85, atrás dos corpos (sem ele, `fumaca_01` a 2×); tiro básico do Snoop em voo é o `anel_fumaca_01`. Em ambos os casos, com relógio `duration - remaining`. A grade indica o raio real; a névoa baixa não define dano/alcance. Morte do Snoop não cancela uma zona existente; expiração, substituição e fim da rodada removem o desenho. O original tem alfa binário, com buracos transparentes.
- Laço: nó sem personagem a 1× no alvo, somente no evento de puxão, sem duplicar no dano. Segue o chão interpolado e para na morte, saída, fim do atordoamento ou do clip. O fio permanece procedural e usa as posições visuais das duas extremidades, com ondulação apenas no interior (BUG-017). Fumaça/nó não aparecem fora do combate.

IDs, URLs oficiais e hashes ficam nos recibos de cada pasta e no inventário. A conferência dos quatro primeiros ZIPs está em `INTEGRIDADE.json`; a dos dois novos em `INTEGRIDADE_V1_4.json` (196 verificações, oito arquivos extraídos idênticos e 54 recortes RGBA). Laço tem 12 quadros no atlas original e 11 no pacote, que omite o último transparente. Verificação da V1.4: 88 verificações de recortes/tempo, 370 de cliente tanto headless quanto OpenGL, zero falhas; duas capturas reais inspecionadas. Regras/economia não foram alteradas. Não há aprovação visual final do usuário, teste de aparelho ou medição de desempenho no celular.
