# Personagens — lote 04 (sprites maiores, corpo real, objeto-marca exagerado)

Criado em 2026-10-12. **Estado: Zumbi feito e no jogo (ver Execução, no fim); demais personagens ainda não gerados.** Registro original deste parágrafo: Saldo PixelLab consultado pelo MCP do Claude Code em 2026-10-12: **0 gerações, US$ 0, trial** (usadas 39, total 40). A conexão do MCP foi confirmada (lista dos 21 personagens existentes e saldo responderam). O lote 03 (48 px) continua ativo no jogo até este lote ser gerado, inspecionado e aprovado.

## Decisão do usuário (2026-10-12) — substitui o "sem caricatura" do lote 03

- O usuário gosta das artes atuais, mas **ainda não são o caminho**. Quer os personagens **maiores, com mais pixels e muito mais detalhe**, "bem completo", parecidos com a pessoa real.
- **Corpo e proporções continuam reais.** O exagero caricato vai no **objeto/traço pelo qual a pessoa é conhecida**, que funciona como "arma" chamativa de cada herói.
- Pedidos específicos:

| Personagem | O que o usuário pediu |
| --- | --- |
| Michael | Reformular com a **roupa branca clássica e chapéu**; manter o **rosto escondido** (gostou disso). |
| Neymar | Manter a **camisa do Brasil**; **camisa 10**, **moicano** e **sorriso bem grande**. |
| Caramelo | **Menos fofinho, mais engraçadinho e sequinho** (magro). |
| Obama | Melhorar detalhe e semelhança junto com Lula e Neymar. |
| Zumbi dos Palmares | Atual "muito feio". **Forte**, roupa de escravizado **branca e suja**, **correntes quebradas nas mãos e nos pés**. |
| Elon Musk | Não parece com ele; com mais pixels, **mais detalhe até ficar parecido**. |
| Snoop Dogg | **Charutão** saindo **fumaça com efeito legal**. |
| Lula | Ficou legal, mas deve **melhorar muito** em detalhe/semelhança. |
| Bob Marley | **Cara de chapado, olhos vermelhos**, **dreads muito bonitos**, **cores da Jamaica**, **ícone de folha de maconha no violão**. |
| Rapunzel | Cabelo **até o chão e ainda enrolando no chão**, porque a habilidade dela é o cabelo. |
| Barbie, Ken | Sem pedido específico nesta mensagem. |

### Retorno do usuário na mesma data (decisões)

- **Exagero no rosto só quando funciona** e é traço pessoal conhecido (o sorriso do Neymar, por exemplo). **Nunca exagerar feições negras.** O exagero vai na **história e na marca** de cada um: Zumbi forte, o "cabelão" da Rapunzel, o charutão do Snoop. Isso confirma e substitui a diretriz que era só proposta abaixo.
- **Quer que os personagens mexam braços e pernas**: andar e atacar entram no lote 04 como animações de verdade, não só as oito poses paradas.
- **A chave do PixelLab será trocada pelo usuário.** Não gerar personagens até ele avisar que o acesso novo está ativo; consultar o saldo nesse momento.
- Começar já as **animações das habilidades** (fumaça do Snoop, foguete do Elon com explosões). Feito no editor gratuito; registro em [assets/vfx](../RelicArena/assets/vfx/README.md).
- Nota histórica para a futura descrição do herói (não é regra): Zumbi nasceu livre em Palmares, foi capturado ainda criança e fugiu de volta por volta dos 15 anos. As correntes quebradas contam essa história.

## Propostas do assistente (não aprovadas)

**Objeto-marca** para quem ainda não tem um definido pelo usuário. Todos combinam com o kit atual:

| Personagem | Proposta |
| --- | --- |
| Obama | Maleta preta **gigante** usada como escudo (o kit já é tanque com mala). |
| Elon | Lança-foguetes **enorme** no ombro, foguete branco e preto quase do tamanho dele (o kit atira foguetes). |
| Lula | Faixa presidencial verde-amarela e **microfone de comício gigante**. Evitar símbolos de partido. |
| Zumbi | Manter a **lança** do kit (estocadas) junto das correntes quebradas. |
| Neymar | Bola de futebol um pouco maior que o normal, sempre nos pés. |
| Caramelo | Sem objeto: o exagero fica na cara (língua de fora, uma orelha em pé e outra caída) e no corpo magrelo. |
| Barbie | Bolsa ou espelho de mão **gigante** rosa como escudo (tanque). |
| Ken | **Prancha de surfe** grande como escudo (ele puxa os ataques). |

Diretrizes técnicas propostas:

- ~~Exagerar o objeto, não traços étnicos.~~ **Confirmado pelo usuário** (ver acima): exagero na história/marca; rosto exagerado só em traço pessoal que funcione; nunca feições negras.
- **Fumaça do Snoop como efeito animado separado** (`vfx_workbench`, gratuito), preso à ponta do charuto em cada direção. O charuto vai desenhado no sprite. Assim a fumaça se mexe e não custa geração. **Já criado:** `assets/vfx/charuto_01` (brasa + fio de fumaça, loop 12 quadros), aguardando o sprite novo para definir o ponto da ponta em cada direção.
- **Folha no violão do Bob e "10" na camisa do Neymar desenhados à mão** depois, no `pixelart_workbench` (gratuito). Geradores costumam deformar números/símbolos pequenos e podem recusar referência a droga.
- Bob Marley: bandeira da Jamaica é verde, amarelo e preto; vermelho, amarelo e verde são as cores rastafári associadas a ele. Proposta: gorro rasta + roupa com as duas paletas. **Dúvida para o usuário.**
- Alerta de loja: maconha/drogas visíveis costumam elevar a classificação etária em lojas de celular. Proposta: manter como está no protótipo e decidir antes do lançamento (eventual skin alternativa).

## Tamanho e escala (proposta a testar)

- Gerar em **canvas 128 × 128**, corpo visível de ~95–110 px (hoje ~43–53 px em canvas 68). A cabeça passa de ~6 px para ~13–15 px de largura, o que permite semelhança real.
- Na tela 1280 × 720 o hexágono da frente tem 76 px (`client/board_projection.gd`). Personagem de ~100 px fica perto da proporção do TFT; nível 3 (×1,44) chega a ~145 px. **Testar um personagem no jogo antes do lote inteiro**; se ficar grande demais, decidir entre exibir a 0,75× ou aumentar a resolução base.
- Retratos da loja/compêndio (`portrait_for`) e o recorte do Michael vão precisar de ajuste depois da troca de tamanho.

## Pipeline e custo (confirmado pela ajuda oficial do PixelLab em 2026-10-12)

1. `create_image_pixen` 128 × 128, frente (south), fundo transparente — **1 geração** por tentativa. Ver o conceito antes de pagar as rotações.
2. Conceito aprovado → `create_character(mode="v3", reference_image_url=...)` — **3 gerações** a 128 px, 8 direções. Caramelo com `body_type="quadruped"`, `template="dog"`. A referência precisa estar **de frente**, ou as oito direções saem rotuladas erradas.
3. Exportar ao lado dos antigos em `assets/characters/<chave>/grande_04/original/`, inspecionar as 8 direções e só então trocar o manifesto.

Estimativa: **~4 gerações por personagem**, ~48 para os 12 (11 heróis + Ken), **~60–70 com rerrolagens de conceito**. Animações depois: modelo (template) de 8 quadros ≈ **8 gerações por animação** nas 8 direções; animação personalizada v3 ≈ 16–24. A dança do Michael (72 quadros a 48 px) não serve no tamanho novo e precisaria ser refeita.

Planos pagos segundo a ajuda do PixelLab: Tier 1 2.000/mês, Tier 2 5.000/mês, Tier 3 10.000/mês. Preço não consultado. **Comprar créditos ou assinar é decisão e ação do usuário**; o assistente não compra.

Ordem proposta: **Snoop primeiro como teste** (semelhança + objeto exagerado + ponto da fumaça), depois Rapunzel (cabelo exige canvas largo), depois os demais.

## Pedidos para o PixelLab (rascunho em inglês)

Base comum: `full body, realistic adult human proportions, natural head size, NOT chibi, strong recognizable likeness, highly detailed pixel art, standing straight facing the viewer (south), both feet on the ground, centered on a 128x128 canvas, low top-down 3/4 RPG camera, selective dark outline, detailed shading, light from upper left, transparent background, no scenery, no text, no logos, no glow. Body and face stay realistic; only the signature prop is deliberately oversized for comic effect.`

| Chave | Descrição específica |
| --- | --- |
| `michael` | Slim pop dancer resembling Michael Jackson in the classic all-white outfit: white fedora with black band tilted low so the face is hidden in shadow, white double-breasted suit, blue shirt, white tie, white armband, white socks, black loafers; one sparkling white glove. Signature prop: the oversized white fedora. |
| `neymar` | Slim athletic Brazilian footballer resembling Neymar Jr., yellow Brazil-style jersey with green trim and a large number 10 on the chest, blue shorts, white socks, mohawk with bleached blond top and shaved sides, huge wide toothy grin, slightly oversized football at his feet. |
| `caramelo` | Scrawny skinny Brazilian caramel street mutt (vira-lata caramelo), short thin coat, lanky legs, slim waist, goofy mischievous face with tongue out, one ear up and one ear floppy, worn red bandana. Funny, not fluffy, not cute puppy. (quadruped, template dog) |
| `obama` | Tall slim man resembling Barack Obama, short grey hair, dark navy suit, white shirt, blue tie, small flag pin, calm confident smile. Signature prop: a giant black leather briefcase held in front like a shield. |
| `zumbi` | Strong muscular Afro-Brazilian warrior resembling Zumbi dos Palmares, determined proud face, rough off-white cotton shirt and trousers torn and dirty with earth stains, iron shackles on both wrists and both ankles with broken heavy chain links hanging, long wooden spear with wide iron blade. Signature prop: the oversized broken chains. |
| `elon` | Tall broad-shouldered man in his fifties resembling Elon Musk, short dark brown hair swept back, receding at the temples, strong square jaw, slight smirk, black t-shirt, black jacket, dark jeans. Signature prop: a huge white and black rocket launcher on his shoulder, the rocket almost as long as he is. |
| `snoop` | Very tall lanky rapper resembling Snoop Dogg, long black braids, dark sunglasses, thin mustache and goatee, loose blue tracksuit with white stripes, gold chain. Signature prop: a giant oversized cigar in his mouth with a glowing orange ember tip. |
| `lula` | Older stocky Brazilian politician resembling Lula da Silva, white-grey hair and full grey beard, dark suit, white shirt, red tie, green and yellow presidential sash, warm wide smile. Signature prop: a giant rally microphone in his hand. |
| `bob_marley` | Slim reggae musician resembling Bob Marley, long thick neat dreadlocks down to mid-back, relaxed sleepy half-closed red eyes, easy smile, red-yellow-green knitted rasta cap, shirt in green, yellow and black, worn jeans. Signature prop: an oversized acoustic guitar held in front. (folha desenhada à mão depois) |
| `rapunzel` | Fairy-tale princess Rapunzel (Grimm tale, not the Disney design), realistic young woman, extremely long golden braid that falls to the floor and coils in big loops on the ground around her feet, simple pale green medieval dress, small flowers in the hair. Signature prop: the enormous hair. |
| `barbie` | Fashion doll woman resembling Barbie, long straight platinum blonde hair, bright pink dress, pink heels, confident smile. Signature prop: a giant pink handbag held like a shield. |
| `ken` | Man resembling Ken doll, tanned, short blond hair, athletic, blue swim briefs (sunga) and sandals. Signature prop: a big surfboard held like a shield. |

Os objetos marcados como proposta só entram no pedido final depois da escolha do usuário.

## Execução

- **2026-10-12 — chave nova ativa.** Usuário avisou que trocou a chave e pediu começar pelo **Zumbi** (não pelo Snoop da ordem proposta). Saldo antes de gerar: 40 gerações (trial), US$ 0, bônus diário de 5. Plano gratuito: uma geração por vez.
- **Zumbi, conceitos de frente** (`create_image_pixen`, 128 × 128, fundo transparente, 1 geração cada; mesmo pedido da tabela, com lança porque o kit aprovado usa estocadas):
  - A — seed 1695, job `aa7095ab-0984-4504-9f4c-16bdb5b10c65`: correntes **quebradas** penduradas nos pulsos e tornozelos, rosto sereno; correntes de tamanho normal, não exageradas.
  - B — seed 4207, job `ae5edc06-99fd-43b8-b48f-9a975f219238`: mais musculoso e correntes mais grossas, porém **ainda ligadas** pulso–tornozelo e entre os pés (não parecem quebradas).
  - Arquivos em `RelicArena/assets/characters/zumbi/grande_04/conceitos/`; comparação com o atual em `RelicArena/captures/lote_04_zumbi_conceitos.png`.
- **Pedido do usuário depois dos conceitos (2026-10-12):** gostou; enviou foto de uma estátua do Zumbi como referência de **pose**: pé erguido sobre uma pedra com o joelho dobrado, apoiado na **lança grande** e no próprio joelho, segurando o **facão** (lâmina grande tipo adaga) na cintura; **sem camisa**, **cicatrizes bem visíveis**, **correntes só nos pés**. Também pediu que **a lança fique um pouco maior ao subir para os níveis 2 e 3** (além do crescimento de 20% do sprite inteiro). A foto foi usada só como descrição em texto; não foi enviada ao PixelLab.
- **Conceitos da pose** (`create_image_pixen`, 1 geração cada):
  - C — seed 1695, job `276309d2-ca03-49cd-8235-e15050ee79b3`: correntes quebradas separadas em cada tornozelo; facão na mão; cicatrizes parecem marcas brancas em X; pele mais clara; uma lâmina extra na cintura.
  - D — seed 8812, job `128e5809-6590-4c38-bf33-247ad3e7af35`: mão apoiada no joelho erguido, cicatrizes com aparência de cicatriz, lança alta; **corrente liga os dois tornozelos**; lâmina na cintura parece espada; pele mais clara.
  - E — seed 8812, pedido reforçado (pele bem escura, tornozelos não ligados, facão), job `518b3543-6496-4f24-abad-89eda4acc39a`: pele mais escura e cicatrizes visíveis; **corrente ainda liga os tornozelos**; espada na mão e lâmina extra na cintura.
  - Comparação em `RelicArena/captures/lote_04_zumbi_pose.png`. Saldo depois: 35 gerações. O gerador ignorou duas vezes "pernas não acorrentadas"; proposta: corrigir a corrente/lâmina à mão no editor gratuito antes das rotações. A pedra faz parte do sprite e acompanha o personagem em todas as direções e animações — ponto a decidir.
- **Pedido seguinte do usuário (2026-10-12):** "junção" de D e E; **lâmina da lança maior**; **uma só faca, a da cintura**; correntes **quebradas e só nos pés**. Gostou do visual dos dois com a pedra (mantida).
- **Junção D + E feita à mão, sem geração** (`grande_04/conceitos/juncao_DE.png`, scripts `juncao.py` e `retoque.py` na mesma pasta): base D (pose com a mão no joelho e uma lâmina na cintura); pele trocada pela rampa mais escura do E, fora da haste e da amarração da lança; lâmina redesenhada em folha larga (12 × 22 px, antes 8 × 20), com crista iluminada à esquerda; corrente entre os pés apagada, deixando uma ponta curta pendurada em cada tornozelo; faixa opaca de sombra do chão removida, porque o jogo desenha a própria sombra elíptica. Cicatrizes e faixa da cintura sem alteração. Comparação em `RelicArena/captures/lote_04_zumbi_juncao.png`. Aprovada pelo usuário ("é isso aí, pode fazer"), com o pedido de remover o Zumbi atual e colocar este no jogo.
- **Rotações v3** (`create_character`, referência = junção enviada por upload; **2 gerações**): personagem `47e44cf4-8365-4c14-8d6f-15ff0fbc4498`, 8 direções 128 × 128, todas inspecionadas e coerentes (no leste a lança fica atrás da cabeça). ZIP e extração conferidos (SHA-256 em `grande_04/exportacao.json`; extração idêntica ao ZIP). Arquivos em `RelicArena/assets/characters/zumbi/grande_04/original/`; galeria em `RelicArena/captures/lote_04_zumbi_8_direcoes.png`. Saldo depois das rotações: **33 gerações** (7 usadas: 5 conceitos + 2 rotações). Observação: durante a espera terminou na conta um job de animação que este assistente não criou (provavelmente da outra sessão de IA).
- **Lança maior por nível (sem geração):** `grande_04/niveis/lanca_nivel.py` gera `nivel_2` e `nivel_3` nas 8 direções; só a lâmina cresce (×1,25 e ×1,5) para cima a partir do encaixe; o quadro ganha altura em cima, os pés ficam no mesmo lugar. No leste a lâmina usa a do oeste espelhada e é pintada só atrás da cabeça. Somado ao crescimento de 20% por nível do sprite inteiro.
- **Integração:** manifesto aponta o Zumbi para `grande_04` com estados `idle`, `idle_n2`, `idle_n3` e `portrait_focus` [62, 7] (retrato da loja recorta o rosto, não a ponta da lança). `client/character_visuals.gd`: `texture_for(..., level)` usa o estado do nível quando existe; `portrait_for` respeita `portrait_focus`; `preview_factor` reduz só arte com mais de 64 px nas vitrines do compêndio. `client/main.gd`: cinco chamadas passam o nível (tabuleiro, clique e compêndio). Arquivos antigos do Zumbi (`zumbi/original`, `provisorio/zumbi.png`) ficaram no disco como reserva, fora do manifesto.
- **Validação (2026-10-12):** importação sem erros; simulação 300/0, Session 162/0, quatro partidas 578/0, VFX 183/0, arrasto 18/0, lobby 31/0, regressões 4/0, cliente 388/0 headless e 388/0 OpenGL — 1.664 verificações, zero falhas. Capturas do viewport inspecionadas: `captures/lote_04_zumbi_tabuleiro_n1..n3.png`, `lote_04_zumbi_niveis_tabuleiro.png`, `lote_04_zumbi_compendio_n1/n3.png` (ferramenta `tools/capture_zumbi_lote04.gd`). Sem teste humano, em celular ou de animação.
- **Em aberto:** a 1× no tabuleiro ele fica ~2,5× mais alto que os heróis de 48 px (nível 3 ocupa quase dois hexágonos). Opções a decidir com o usuário: manter até todos serem refeitos, exibir menor ou ajustar a câmera. Animações de andar/atacar ainda não feitas; a pedra faz parte do sprite.
