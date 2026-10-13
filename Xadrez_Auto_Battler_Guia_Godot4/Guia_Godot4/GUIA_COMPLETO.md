# Xadrez Auto Battler — especificação completa para Godot 4

**Data:** 09/10/2026. **Base consultada:** lógica própria da versão 0.10.1.
**Destino:** projeto novo em Godot 4. **Plataforma inicial:** PC. **Modo:** offline.

Este documento preserva o jogo criado em conjunto, não a engenharia do patch
antigo. Foi conferido contra `tft-core.mjs`, `tft-hud.mjs`, `tft-save.mjs`,
o controlador de campanha e a geometria do HUD. O código consultado acompanha
o pacote quando é independente do cliente antigo.

**BASE EXISTENTE** identifica comportamento presente no código. **REQUISITO**
identifica pedidos do usuário. **PROPOSTA GODOT** identifica uma solução sugerida
para o projeto novo. **PENDENTE** identifica decisões ainda abertas. A existência
de código/testes não certifica sua aparência ou desempenho em hardware real.

## Índice

1. Visão e decisões de produto
2. Ciclo da campanha e estados
3. Chão, casas, formação e alcance
4. Personagens e atributos
5. Habilidades exatas
6. Sinergias
7. Equipamentos e bolsa
8. Loja e raridades
9. Cópias, fusão e venda
10. Economia, resultados e prêmios
11. Campanha e adversários
12. Combate automático
13. Arraste, clique e validação
14. Layout, cores e legibilidade
15. Salvamento e retomada
16. Desempenho e apresentação
17. Personagem futuro: Michael Jackson
18. Arquitetura proposta para Godot 4
19. Dados, ações e eventos
20. Etapas, testes e aceite
21. Pendências e aprendizados
22. Referências transportáveis

## 1. Visão e decisões de produto

**REQUISITO.** Auto battler próprio inspirado na experiência de organizar uma
equipe e assistir ao combate do TFT. O prazer vem de comprar cópias, administrar
moedas, formar sinergias, posicionar peças, equipar e evoluir a equipe.

O usuário decidiu abandonar o projeto baseado no cliente compilado e criar
um projeto editável no Godot 4. As regras descritas aqui são o ponto de partida.
O novo executável deve poder funcionar offline, sem autenticação ou serviço
externo para uma partida local.

Preferências expressas:

- Nome de trabalho: **Xadrez Auto Battler**; um único modo principal.
- Bots e mobs, inicialmente sem multiplayer.
- Campo de seis peças e reserva com oito lugares fixos.
- Combate devagar o suficiente para acompanhar ataques, cura e números de dano.
- Tabuleiro com casas exclusivas, sem amontoar cinco personagens no mesmo lugar.
- Loja, reserva, equipe e sinergias visíveis ao mesmo tempo.
- Arrastar para campo, reserva e venda; clique continua disponível.
- Ícones, cores e informação curta; eliminar narrador/NPC e balões de instrução.
- Cenário leve, com água/fogo desativados ou estáticos; personagens animados.
- Salvamento local e recuperação da campanha.
- Mobile foi expressamente adiado. Não adicionar trabalho de exportação mobile agora.

**PROPOSTA GODOT.** 2D com sprites e sensação de profundidade/2.5D reduz a
necessidade de modelagem e rigging. Pixel art e PixelLab foram discutidos;
não existe estilo final, resolução de sprite ou conjunto de animações aprovado.
Não bloquear o protótipo por falta de arte definitiva.

TFT é referência de fluxo e organização visual. Nossas regras registradas usam
casas **quadradas**, não uma grade hexagonal. Também não reproduzem todos os
sistemas comerciais do TFT. Não introduzir esses sistemas por associação.

## 2. Ciclo da campanha e estados

**BASE EXISTENTE.** Jogador começa com 100 de vida, 12 moedas, equipe vazia,
oito vagas vazias de reserva, uma Lâmina e uma Couraça na bolsa. A primeira
loja já está disponível. Não existe contagem regressiva de preparação.
O jogador decide quando clicar **Lutar**, desde que tenha pelo menos uma peça.

Fluxo de uma campanha:

```text
MENU INICIAL
  Jogar/Continuar → carregar campanha válida ou criar uma nova
      ↓
PREPARAÇÃO: comprar, renovar, travar, equipar, posicionar, guardar, vender
      ↓ Lutar (campo não vazio)
COMBATE AUTOMÁTICO: bloquear alterações da equipe e da economia
      ↓ término
RESULTADO: liquidar renda/vida uma única vez e avançar o encontro
      ├─ vitória contra mobs → ESCOLHA DE PRÊMIO → próximo encontro
      ├─ vida zerou ou encontro 15 acabou → CAMPANHA ENCERRADA
      └─ demais resultados → PREPARAÇÃO do próximo encontro
```

Estados lógicos antigos: `prepare`, `combat`, `reward`, `finished`.
Havia ainda um estado transitório `settling` para impedir entrada duplicada.
O menu é uma camada sobre o estado, não uma segunda cópia da partida.

Menu da partida: Continuar; Voltar ao início → Salvar e sair; Nova partida →
confirmar Recomeçar; letras normais/grandes; gráficos equilibrados/econômicos.
O menu antigo **não pausava** o combate. Pausar ao abrir o menu no Godot é uma
possível melhoria, ainda **PENDENTE**, e não deve mudar silenciosamente as regras.

Termina ao chegar a zero de vida ou concluir os 15 encontros. O registro mostra
campanha concluída/equipe eliminada e total de vitórias. Reabrir uma campanha
já encerrada inicia outra, preservando preferências.

## 3. Chão, casas, formação e alcance

### 3.1 Grade lógica

**BASE EXISTENTE.** Sete colunas por oito linhas: 56 casas. Colunas A–G;
linhas visuais 1–8. Internamente, `col = 0..6`, `row = 0..7`:

```text
cell = row * 7 + col
col = cell % 7
row = floor(cell / 7)
distância(a,b) = max(abs(colA-colB), abs(rowA-rowB))
```

As casas `0..27`, linhas 1–4, são a metade do jogador durante a preparação.
As casas `28..55`, linhas 5–8, recebem os adversários. No combate, todas as
casas são navegáveis. A linha central é referência visual, não parede.

```text
                    ADVERSÁRIO / FUNDO
        A     B     C     D     E     F     G
  8    [49]  [50]  [51]  [52]  [53]  [54]  [55]
  7    [42]  [43]  [44]  [45]  [46]  [47]  [48]
  6    [35]  [36]  [37]  [38]  [39]  [40]  [41]
  5    [28]  [29]  [30]  [31]  [32]  [33]  [34]
       -----------------------------------------
  4    [21]  [22]  [23]  [24]  [25]  [26]  [27]  frente
  3    [14]  [15]  [16]  [17]  [18]  [19]  [20]
  2    [ 7]  [ 8]  [ 9]  [10]  [11]  [12]  [13]
  1    [ 0]  [ 1]  [ 2]  [ 3]  [ 4]  [ 5]  [ 6]  retaguarda
                      JOGADOR / RESERVA
```

**PROPOSTA GODOT.** Guardar sempre coordenadas lógicas inteiras. A transformação
para a tela fica em `BoardView`; mudar a inclinação ou a arte não muda alcance,
ocupação, economia ou salvamento. Em vista ortogonal, mostrar a linha 1 na parte
de baixo exige inverter o eixo vertical. Não confundir coordenadas da tela com
as coordenadas do tabuleiro.

Um chão com perspectiva/diamantes desenhados pode continuar representando
essas mesmas casas quadradas. A forma projetada não transforma a regra em hexágonos.
O tamanho antigo de casa, 280 unidades de mundo, é uma escala histórica, não
um tamanho em pixels obrigatório no Godot.

### 3.2 Camadas visuais do chão

**REQUISITO + PROPOSTA GODOT.** Arena central desobstruída, com piso de areia,
pedra ou tiles coerentes, bordas de pedra/vegetação como decoração estática.
Não há um mapa novo desenhado e aprovado. A referência antiga era uma arena
em ilha, com água/fogueiras nas bordas; essas animações foram desativadas.

Organizar em camadas: fundo estático → piso → linhas/destaques das casas →
peças/sombras de apoio → efeitos curtos → barras/números. Decoração não ocupa
casas lógicas. Não criar obstáculos de mapa como nova mecânica sem decisão.

Marcar a casa pelo pé/centro de apoio da peça. A célula selecionada fica dourada;
metade do jogador em ciano discreto; metade adversária em vermelho discreto;
alcance em verde. Mostrar destino válido/troca durante o arraste e rejeição
clara em destino inválido. A grade deve ajudar a ler o combate, sem cobrir os sprites.

### 3.3 Ocupação e movimento

Invariantes obrigatórios:

1. Cada unidade viva possui exatamente uma casa lógica.
2. Dois vivos nunca possuem a mesma casa.
3. Ao iniciar um passo, a unidade mantém a origem ocupada e reserva o destino.
4. Ninguém pode entrar na origem ocupada nem no destino reservado por outra peça.
5. Ao chegar, libera a origem, converte a reserva em ocupação e atualiza a casa.
6. Morte libera origem e eventual reserva; cancela movimento.
7. Não atacar enquanto caminha. Atordoamento também suspende o avanço do passo.
8. Movimento normal é horizontal/vertical: quatro vizinhos; sem diagonal e sem
   atravessar outras unidades.
9. Não resolver colisão empurrando sprites com física. Ocupação é autoridade lógica.

Navegação usa BFS até uma casa livre dentro do alcance do alvo. Ordena vizinhos
por proximidade ao alvo e depois pelo índice da casa. Se o inimigo mais próximo
estiver cercado, tenta outros inimigos vivos. Se nenhum caminho existir,
aguarda 0,2 segundo de simulação antes de tentar de novo.

### 3.4 Alcance e formação

Distância de ataque é Chebyshev: diagonal conta como uma casa. Exemplo: D4→E5
tem distância 1; D4→F6, distância 2. Isso é diferente da navegação ortogonal.

| Alcance | Personagens |
|---|---|
| 1 casa | Sumô, Duelista, Gorila, Ninja, Davi de Pedra, Rato |
| 2 casas | Arcanista, Bruxa, Rei dos Ratos, Cobra Real, Serpente |
| Campo inteiro | Mosqueteiro, Pistoleiro, Gênio |

Campo inteiro dispensa caminhar para entrar em alcance. Não há linha de visão
bloqueada por peças. O alcance verifica a **iniciação** da ação; efeitos de área
e ataques já lançados têm regras próprias descritas adiante.

Compra põe a peça no campo primeiro, enquanto houver menos de seis; depois,
na primeira vaga vazia da reserva. Posicionamento automático de uma peça sem
coordenadas: corpo a corpo em D4/casa 24; demais em D2/casa 10. Em conflito,
escolher casa livre mais próxima, depois mais próxima do centro horizontal,
depois maior índice. Nunca manter spawn sobreposto.

Adversários são montados como uma formação local e espelhados verticalmente:
`row_adversário = 7 - row_local`, preservando a coluna. Salvar a formação do
jogador; movimento do combate ocorre em uma cópia e não altera suas posições
para a próxima preparação.

## 4. Personagens e atributos

**BASE EXISTENTE.** Doze personagens jogáveis e dois mobs. IDs abaixo permitem
consultar o código/JSON; nomes/arte podem ser adaptados conscientemente no projeto novo.
`Rat` e `Serpent` não entram na loja.

| ID | Personagem | Função | Raridade / preço | HP base | Alcance | Intervalo | Sinergias |
|---|---|---|---|---:|---|---:|---|
| Tank | Sumô | Tanque | Normal / 1 | 80 | 1 | 2,6s | Guardiões |
| Ranger | Mosqueteiro | Dano | Normal / 1 | 50 | ∞ | 2,3s | Atiradores |
| Caster | Arcanista | Dano | Normal / 1 | 50 | 2 | 2,3s | Místicos |
| Assassin | Duelista | Dano | Normal / 1 | 50 | 1 | 2,3s | Assassinos |
| Gorilla | Gorila | Tanque | Raro / 3 | 80 | 1 | 2,6s | Guardiões, Selvagens |
| Cowboy | Pistoleiro | Dano | Raro / 3 | 50 | ∞ | 2,3s | Atiradores |
| Witch | Bruxa | Dano | Raro / 3 | 50 | 2 | 2,3s | Místicos |
| Ninja | Ninja | Dano | Raro / 3 | 50 | 1 | 2,0s | Assassinos |
| Genie | Gênio | Cura | Épico / 5 | 50 | ∞ | 2,4s | Místicos, Ancestrais |
| RatKing | Rei dos Ratos | Dano | Épico / 5 | 50 | 2 | 2,3s | Selvagens |
| Cobra | Cobra Real | Dano | Raro / 3 | 50 | 2 | 2,3s | Selvagens, Ancestrais |
| David | Davi de Pedra | Tanque | Épico / 5 | 80 | 1 | 2,6s | Guardiões, Ancestrais |
| Rat | Rato | Mob | Fora da loja | 20 | 1 | 2,3s | Nenhuma |
| Serpent | Serpente | Mob | Fora da loja | 30 | 2 | 2,3s | Nenhuma |

Todos começam com armadura base zero. Dano básico é 1/2/4 conforme ★/★★/★★★,
mais Lâminas. Mana máxima 100; mana e regeneração passiva iniciam em zero.
Não existe mana regenerada automaticamente por segundo.

Fórmulas exatas, com `s` = estrelas 1–3:

```text
fator_HP_estrela = [1, 1.5, 2][s-1]
fator_Guardiões = [1, 1.18, 1.30][nível_Guardiões]
HPmáx = round((HPbase * fator_HP_estrela * power + 10 * Couraças) * fator_Guardiões)
ataque = [1, 2, 4][s-1] + quantidade_de_Lâminas
cura_base = s + 2 * quantidade_de_Tomos
armadura = armadura_base + 15 * nível_Ancestrais
poder_habilidade = 1 + 0.25 * nível_Místicos
intervalo = intervalo_base * (0.75 se Atirador e sinergia ativa; senão 1)
roubo_de_vida = [0, 0.12, 0.22][nível_Selvagens], apenas em Selvagens
```

`power` é 1 normalmente; mobs usam progressão de capítulo. Equipamentos somam
depois da multiplicação da estrela/power e antes do bônus de Guardiões.
HP é inteiro, arredondado ao mais próximo; para valores positivos, empate em
0,5 sobe. No port, manter a mesma regra explícita.

Velocidade histórica: assassinos 290, demais 220 para casa de tamanho 280.
Equivale a aproximadamente **1,036 casa/s** e **0,786 casa/s**. No Godot, usar
essa velocidade em casas/s e só depois converter para pixels.

Exemplos sem sinergias: DPS ★=50 HP, ★★=75, ★★★=100; tanque ★=80, ★★=120,
★★★=160. Uma Lâmina em DPS ★★ dá ataque 3. Uma Couraça em tanque ★★ dá 130 HP;
com Guardiões nível 1: round(130×1,18)=153 HP.

## 5. Habilidades exatas

Definir `P = ataque × poder_habilidade`, `H = cura_base` e `S = poder_habilidade`.
Os números abaixo são quantidades antes da mitigação/arredondamento do dano.
As habilidades disparam na ação de ataque quando a unidade já tem 100 de mana.

| Personagem / habilidade | Comportamento existente |
|---|---|
| Sumô / Fôlego (`fortify`) | Cura própria `(2+H)×S`; proteção por 1,5s; golpe `1,3×P` no foco, se houver |
| Mosqueteiro / Rajada (`volley`) | Até três inimigos, ordenados por distância; `1×P` físico em cada |
| Arcanista / Nova (`nova`) | Todos os inimigos a distância ≤1 casa do foco; `1,5×P` mágico em cada |
| Duelista / Execução (`execute`) | `1,5×P` físico; se alvo está abaixo de 50% HP, `2,5×P`; somar 0,5 ao multiplicador com sinergia Assassinos |
| Gorila / Impacto (`slam`) | Inimigos a ≤1 casa do próprio Gorila; `1,5×P` físico e atordoamento de 0,8s |
| Pistoleiro / Tiro preciso (`aimed`) | `2,5×P` físico no foco |
| Bruxa / Drenagem (`drain`) | `1,5×P` mágico no foco; cura própria de 80% do dano efetivamente causado |
| Ninja / Execução (`execute`) | Mesma execução do Duelista; pode saltar no início mesmo sem sinergia |
| Gênio / Desejo (`mend`) | Até dois aliados vivos com menor fração de HP, incluindo si mesmo; cura `(3+H)×S` em cada |
| Rei dos Ratos / Praga (`plague`) | Até três inimigos dentro do alcance 2, incluindo o foco; `1,5×P` mágico em cada e três pulsos de veneno |
| Cobra Real / Veneno (`venom`) | `1,5×P` mágico no foco e três pulsos de veneno |
| Davi / Pele de pedra (`stone`) | Cura própria `(2+H)×S`; proteção por 3s; golpe `1,3×P` no foco, se houver |
| Rato / Mordida (`aimed`) | Usa multiplicador físico 2,5 da mesma implementação de tiro preciso, apesar do nome |
| Serpente / Veneno (`venom`) | Mesmo veneno, com alcance 2 e atributos de mob |

Proteção multiplica dano recebido por **0,55**, redução de 45%. É um modificador
temporário, não uma barra de escudo. Os golpes de Fôlego/Pele de pedra usam o
caminho físico da implementação.

Veneno: pulsos em +1s, +2s e +3s após o impacto. Quantidade de cada pulso:
`max(1, 0,25×P)`, tratada como dano mágico. Pulsos já aplicados continuam se a
fonte morrer. Cada aplicação agenda seus próprios pulsos; a base não substitui
um veneno anterior por uma duração única compartilhada.

**Ataque normal do Gênio:** quando o impacto é resolvido, procura aliado vivo
ferido com menor `HP_atual/HPmáx`; cura `1+H`. Se ninguém estiver ferido,
causa seu ataque normal no inimigo. Portanto, o Gênio atual **ainda pode atacar**.
O futuro Michael Jackson terá comportamento diferente e ataque desabilitado.

### Salto de assassinos

Uma vez por combate, a partir de 0,4s. Ninja sempre pode; Duelista exige
sinergia Assassinos ativa. Escolher adversário com maior alcance, depois maior
distância, depois menor ID. Procurar casa vazia e não reservada a exatamente
uma casa dele. Para o lado do jogador, preferir maior índice; para o rival,
menor índice. Sem espaço, não teletransportar nem sobrepor. A tentativa é única,
inclusive quando não encontra destino. O salto não é caminhada e não empurra peças.

## 6. Sinergias

**BASE EXISTENTE.** Contar **tipos distintos de personagem em campo**. Três
Sumôs contam como um Guardião. Reserva não participa. Estrelas não multiplicam
o contador. Personagem com duas sinergias contribui uma vez para cada uma.

| Sinergia | Ativação | Efeito |
|---|---|---|
| Guardiões | 2 / 3 tipos | +18% / +30% HPmáx da equipe inteira |
| Atiradores | 2 tipos | Intervalo de ataque dos Atiradores ×0,75 |
| Místicos | 2 / 3 tipos | Poder de habilidades da equipe ×1,25 / ×1,50 |
| Assassinos | 2 tipos | Salto inicial para assassinos; +0,5 no multiplicador de execução |
| Selvagens | 2 / 3 tipos | Selvagens curam 12% / 22% do dano causado |
| Ancestrais | 2 / 3 tipos | +15 / +30 armadura para a equipe inteira |

Aplicar o nível mais alto alcançado, não somar os dois patamares. Três Guardiões
dão +30%, não +48%. Atiradores reduz intervalo, o que corresponde a mais ataques;
não interpretar como apenas +25% na taxa de ataques.

Roubo de vida acumula frações em uma conta interna por unidade. Ao acumular
pelo menos 1, cura a parte inteira e conserva a fração. Isso evita que dano
básico 1 arredonde sempre 12% para zero. Cura nunca ultrapassa HPmáx.

No painel, mostrar ícone, nome, quantidade/patamar e efeito curto. Sinergia
inativa discreta; ativa em verde; níveis mais altos devem ser reconhecíveis
também por símbolo/texto, não somente por cor.

## 7. Equipamentos e bolsa

**BASE EXISTENTE.** Três itens; até três por personagem, em campo ou reserva.
Repetições são permitidas e seus bônus somam. Não há receitas de combinação.

| ID | Nome | Efeito | Quantidade inicial |
|---|---|---|---:|
| blade | Lâmina | +1 ataque | 1 |
| heart | Couraça | +10 HP | 1 |
| tome | Tomo | +2 na cura_base | 0 |

Bolsa guarda contagens, não ocupa a reserva de personagens. Equipar exige
item disponível, personagem válido, fase de preparação e menos de três itens.
Retirar devolve todos os itens da peça à bolsa, sem custo. Venda devolve todos.
Fusão conserva até três no resultado; qualquer excedente volta à bolsa.

Tomo melhora as curas que usam `H`, incluindo Gênio e autocuras de habilidades.
Não aumenta dano mágico e não aumenta diretamente o roubo de vida percentual.
O efeito do Tomo no personagem percentual futuro ainda precisa ser definido.

**PROPOSTA GODOT.** Pode haver arraste de item como melhoria posterior, mas o
fluxo existente era selecionar personagem e clicar no item da bolsa.
Não registrar arraste de equipamentos como funcionalidade já entregue.

## 8. Loja e raridades

**BASE EXISTENTE.** Cinco ofertas simultâneas. Cada oferta entrega uma peça ★.
Ao comprar, a oferta fica vazia/comprada; as outras não se deslocam nem renovam.

| Raridade | Preço | Personagens | Cor de referência |
|---|---:|---|---|
| Normal | 1 | Sumô, Mosqueteiro, Arcanista, Duelista | `#bcc6cc` |
| Raro | 3 | Gorila, Pistoleiro, Bruxa, Ninja, Cobra Real | `#79c4ff` |
| Épico | 5 | Gênio, Rei dos Ratos, Davi de Pedra | `#d99bff` |

| Rodadas visíveis | Normais | Raros | Épicos |
|---|---:|---:|---:|
| 1–5 | 75% | 25% | 0% |
| 6–10 | 55% | 35% | 10% |
| 11–15 | 30% | 50% | 20% |

Algoritmo: sortear raridade com esses pesos; depois sortear uniformemente um
tipo dessa raridade que ainda não apareceu duas vezes nas ofertas atuais.
Máximo de duas ofertas do mesmo tipo por loja. Não existe estoque compartilhado
ou quantidade limitada de cópias no mundo.

Primeira loja garante Sumô e dois DPS normais distintos, sorteados entre
Mosqueteiro/Arcanista/Duelista. Completar as duas ofertas restantes pelas
chances normais. Essa garantia não se repete nas renovações seguintes.

Renovar custa **2 moedas**, exige saldo e gera cinco ofertas novas. Travar é
gratuito e alterna o estado. Ao liquidar um encontro, renovar gratuitamente
para o próximo se estiver destravada e a campanha continuar. Se travada,
preservar exatamente as ofertas restantes, inclusive espaços já comprados.
Renovação manual é permitida com a loja travada e mantém a trava.

Compra exige saldo e espaço **ou** possibilidade de completar uma fusão ★
com duas cópias já possuídas. Não cobrar nem remover a oferta numa compra
rejeitada. Mobs nunca aparecem como oferta.

## 9. Cópias, fusão e venda

**BASE EXISTENTE.** Três cópias do mesmo personagem **e da mesma estrela**
fundem automaticamente: `3×★ → ★★`, `3×★★ → ★★★`. Uma peça ★★★ representa
nove cópias básicas. Não há botão de pagar para evoluir. Limite de três estrelas.

Campo e reserva contam juntos, sem exigir proximidade física. Fusões em cadeia
resolvem na mesma compra. Exemplo: duas peças ★ e duas ★★; comprar uma ★
gera a terceira ★★ e, imediatamente, uma ★★★.

Preservação:

- Priorizar resultado em uma peça já em campo, mantendo sua casa/UID.
- Entre candidatas de campo, preferir a selecionada; depois primeira da ordem.
- Se nenhuma está em campo, preferir selecionada da reserva, senão primeira candidata.
- Consumir exatamente duas doadoras por etapa. Não consumir cópias excedentes.
- Conservar os itens, com limite três e devolução de excedentes à bolsa.
- Atualizar seleção para a sobrevivente; nunca manter referência a peça consumida.
- Compra que completa fusão pode funcionar mesmo com seis no campo e oito na reserva.
- Uma compra isolada sem fusão usa campo primeiro; fusão ancorada na reserva
  permanece ali, mesmo que a operação libere lugares no campo.

`uid` é identidade persistente; não usar índice da lista como identidade.
Peças remanescentes preservam seus IDs e visuais entre operações.

Valor de venda: `preço_da_raridade × 3^(estrelas−1)`.

| Raridade | ★ | ★★ | ★★★ |
|---|---:|---:|---:|
| Normal | 1 | 3 | 9 |
| Raro | 3 | 9 | 27 |
| Épico | 5 | 15 | 45 |

Venda remove a peça uma vez, paga uma vez e devolve seus itens. Não há taxa
nem desconto na evolução. Oferecer botão **Vender** e zona vermelha de soltura.
Pequeno movimento ao clicar não deve disparar venda acidental.

## 10. Economia, resultados e prêmios

**BASE EXISTENTE.** Juros medidos sobre o saldo **antes** de pagar o resultado:

```text
juros = floor(moedas_guardadas / 10)             # sem teto de cinco
sequência = vitória ? max(0, sequência)+1 : min(0, sequência)-1
bônus_sequência = min(3, floor(abs(sequência)/2))
renda = 5 + juros + bônus_sequência + (vitória ? 1 : 0)
        + (vitória_contra_mobs ? 3 : 0)
```

Portanto, exatamente 10 moedas já dão +1; 20 dão +2; 30 dão +3; 50 dão +5;
60 dão +6. Não limitar a cinco por suposição sobre TFT. O saldo recebido agora
só conta nos juros do próximo resultado.

Bônus de sequência usa a sequência **já atualizada** pelo resultado atual:
uma vitória/derrota = +0; duas ou três consecutivas = +1; quatro ou cinco = +2;
seis ou mais = +3. Trocar de vitória para derrota, ou vice-versa, reinicia
na primeira ocorrência do novo tipo. Derrota também paga juros e renda base.

Exemplo: começar o resultado com 20 moedas, vencer equipe e atingir a segunda
vitória consecutiva rende `5+2+1+1=9`, total 29. Com 30 moedas, vencer mobs e
atingir quarta vitória rende `5+3+2+1+3=14`, total 44, mais um prêmio à escolha.

Dano à vida do jogador em derrota/empate, com capítulo interno `0,1,2`:

```text
mobs:   6 + 2 * capítulo
equipe: 8 + 3 * capítulo + min(6, sobreviventes_adversários)
```

Vida nunca abaixo de zero. Vitória incrementa total de vitórias. Empate é
tratado como encontro falhado: renda de derrota e perda de vida correspondente.
Ambos os lados morrerem também produz empate, sem vitória do jogador.

Prêmio somente após vitória contra mobs: escolher **uma** Lâmina, **uma**
Couraça, **um** Tomo **ou +4 moedas**. Os três itens são opções fixas, não
uma rolagem aleatória. Essas quatro opções aparecem juntas e a escolha paga
uma vez. A renda já foi paga antes de abrir o prêmio.

Fechar a fase de combate antes de liquidar; fechar prêmio antes de entregar
seu efeito. No protótipo, a proteção contra duplicação ficava no controlador
da fase. A função pura de resultado não é, sozinha, uma proteção contra chamadas
repetidas. No Godot, proteger por `encounter_id`/estado liquidado além da UI.

## 11. Campanha e adversários

**BASE EXISTENTE.** Três capítulos de cinco encontros. Em cada capítulo,
a ordem é **equipe, mobs, equipe, mobs, equipe**. Total: nove equipes rivais
e seis encontros de mobs. “Bot jogador” significa uma formação rival programada;
não existe outro jogador persistente comprando em uma loja própria.

| Rodada | Encontro | Formação rival | Estrelas |
|---:|---|---|---|
| 1 | 1-1 Equipe | Sumô, Mosqueteiro | 1, 1 |
| 2 | 1-2 Ratos | Rato, Rato, Rato | 1, 1, 1 |
| 3 | 1-3 Equipe | Sumô, Bruxa, Duelista | 1, 1, 1 |
| 4 | 1-4 Serpentes | Serpente, Serpente, Rato | 1, 1, 1 |
| 5 | 1-5 Equipe | Sumô, Pistoleiro, Arcanista, Duelista | 1, 1, 1, 1 |
| 6 | 2-1 Equipe | Gorila, Sumô, Mosqueteiro, Pistoleiro | 2, 2, 1, 1 |
| 7 | 2-2 Ratos | Rato ×4 | Todas 1 |
| 8 | 2-3 Equipe | Gorila, Rei dos Ratos, Cobra Real, Bruxa, Sumô | 2, 2, 1, 1, 1 |
| 9 | 2-4 Serpentes | Serpente ×2, Rato ×2 | Todas 1 |
| 10 | 2-5 Equipe | Davi, Gênio, Arcanista, Bruxa, Mosqueteiro | 2, 2, 1, 1, 1 |
| 11 | 3-1 Equipe | Gorila, Davi, Sumô, Pistoleiro, Mosqueteiro, Gênio | Todas 2 |
| 12 | 3-2 Ratos | Rato ×5 | Todas 1 |
| 13 | 3-3 Equipe | Ninja, Duelista, Bruxa, Arcanista, Gênio, Sumô | Todas 2 |
| 14 | 3-4 Serpentes | Serpente ×2, Rato ×3 | Todas 1 |
| 15 | 3-5 Guardiões finais | Davi, Gorila, Gênio, Rei dos Ratos, Cobra Real, Pistoleiro | Todas 2 |

Mobs têm `power = 1 + 0,4×capítulo`, aplicado ao HP base. Rato: 20/28/36 HP;
Serpente: 30/42/54 HP. Todos permanecem ★ e dano base 1. Não aplicar power
também ao ataque por interpretação; o código só o aplica ao HP.

Equipamentos das equipes rivais: capítulo 1 sem itens; capítulo 2 primeira
unidade com Couraça; capítulo 3 primeira com Couraça e segunda com Lâmina.
Mobs não têm itens. Sinergias adversárias funcionam pelos mesmos critérios.

Posições exatas normalizadas e atributos iniciais calculados estão em
`DADOS_DO_JOGO.json`. A formação antiga distribuía colunas em torno do centro,
com ranged mais atrás e melee à frente. Não copiar coordenadas do mapa Unity
como pixels do novo chão; portar casas/identidades.

## 12. Combate automático

### 12.1 Relógio e ordem

**BASE EXISTENTE.** Simulação fixa de **0,033 segundo por passo**. Não usar
FPS visual para decidir dano ou velocidade. Estado de combate é cópia profunda
do necessário da formação; os itens e a formação persistente não são consumidos
ou movidos pela batalha.

Cada unidade começa com vida cheia, mana 0 e espera inicial `1 + índice×0,1s`.
Alternar a ordem de atualização por passo: normal/reversa. A intenção é reduzir
vantagem permanente de um lado sem inserir aleatoriedade no combate.
Pendências com impacto vencido resolvem antes das ações das unidades no passo.
Na implementação JS, pendências simultâneas são percorridas do fim para o início;
port de paridade exata precisa preservar esse desempate.

Alvo: manter o atual se vivo e em alcance. Caso contrário, buscar inimigo vivo
mais próximo; empate por menor ID. Sem alcance, navegar até uma casa válida;
não caminhar para cima de uma unidade. Não há acerto crítico aleatório,
esquiva, chance de erro ou rolagem de dano na base.

### 12.2 Ataque e mana

Quando parado, não atordoado, alvo em alcance e cooldown ≤0:

1. Repor cooldown com seu intervalo de ataque.
2. Se já tinha mana ≥100, executar habilidade e consumir mana para zero.
3. Caso contrário, iniciar ataque normal e ganhar 20 mana, limitado a 100.
4. Agendar impacto normal em +0,5s; habilidade em +0,65s.
5. Emitir evento de animação/direção; não aplicar dano novamente pela animação.

Ganhar os 20 que completam 100 não transforma aquele ataque em habilidade;
a habilidade sai na ação seguinte. Receber cada golpe/pulso de dano dá +4 mana.
Cura não dá mana. Unidade que morre antes de resolver ataque/habilidade normal
perde essa ação; venenos já aplicados seguem independentes da vida da fonte.

Alcance é verificado no lançamento. O impacto já agendado pode alcançar alvo
que se moveu, desde que ainda esteja vivo; não reinterpretar como projétil físico
que erra ao sair da casa sem registrar uma mudança de design.

### 12.3 Mitigação, cura e morte

```text
armadura_efetiva = armadura × (0.45 se mágico; senão 1)
fator_proteção = 0.55 se proteção ativa; senão 1
dano = min(HP_atual_alvo,
           max(1, round(quantidade × 100/(100+armadura_efetiva) × fator_proteção)))
cura_efetiva = min(HPmáx − HP_atual, round(quantidade_de_cura))
```

Mínimo de dano 1, limitado à vida restante. Cura de morto não ressuscita.
Remover ocupação e reserva ao morrer; emitir morte uma vez. Número flutuante
deve usar o dano/cura **efetivos**, sem alterar HP por uma segunda via.

**Ponto de balanceamento conhecido:** ataques de 1 continuam causando 1 mesmo
com armadura/proteção, devido a arredondamento e mínimo. Isso foi preservado
nos testes; não prometer que armadura sempre reduz visualmente um ataque de 1.

### 12.4 Limite de duração

Limite principal aproximadamente 95s. Após 75s, a cada 60 passos (≈1,98s),
todos os vivos recebem dano mágico de fadiga:
`1 + floor((tempo−75)/5)`, sujeito à mesma mitigação/mínimo. Ajuda a encerrar
duelos de cura/proteção. Fadiga não é ataque de um personagem.

Se nenhum lado foi eliminado no limite: somar `HP_atual/HPmáx` de todos os vivos
de cada lado. Maior soma vence. Diferença menor que 0,001 dá empate. Não usar
soma bruta de HP, número de sobreviventes ou percentual médio como substitutos.
Depois há cerca de dois segundos de apresentação do resultado/vitória.

**PROPOSTA GODOT.** Simular em tempo fixo e interpolar os sprites entre casas.
Pode produzir eventos em blocos/tempo real; não é obrigatório armazenar uma
lista de milhares de frames como exigia o cliente antigo.

## 13. Arraste, clique e validação

**REQUISITO.** Manipulação direta de peça no chão e de cartões da reserva/equipe.
Arrastar para casa própria, reserva ou Vender. Clique/toque é alternativa.

**BASE EXISTENTE.** Mouse só vira arraste após 6 pixels de referência; toque
primário após 12, escalados pelo HUD. Antes disso, é seleção. Usar preview leve
sob o cursor, sem criar outra peça lógica. Cancelar ao perder foco, mudar
fase/sessão, abrir menu ou soltar fora de um destino válido.

Destino e transação:

| Origem → destino | Resultado |
|---|---|
| Campo → casa própria vazia | Mover e encaixar na casa |
| Campo → casa própria ocupada | Trocar as duas posições |
| Campo → reserva vazia | Guardar na vaga escolhida |
| Campo → reserva ocupada | Trocar: reservada assume a casa da origem |
| Reserva → casa vazia | Entrar no campo se houver menos de seis |
| Reserva → casa ocupada | Trocar, inclusive com campo cheio |
| Reserva → outra vaga | Mover ou trocar as vagas |
| Qualquer peça → Vender | Remover uma vez, pagar e devolver itens |
| Própria casa/vaga | Sem efeito; não emitir mudança/save desnecessário |
| Casa adversária, fora da grade, fase bloqueada | Rejeitar; preservar tudo |

Não admitir sétima peça no campo nem nona vaga de reserva. Validar **antes**
de modificar arrays, ouro, bolsa ou células. Soltura inválida não deve “corrigir”
a formação como efeito colateral.

Payload de arraste carrega `uid` estável e origem. Na soltura, confirmar que
a peça ainda existe, que a fase é a mesma e que o comando se refere ao UID
capturado. Uma fusão ou seleção nova não deve fazer vender outra peça por engano.
No protótipo havia confirmação de seleção entre UI e controlador; no Godot
local a validação pode ser direta, sem transportar o protocolo antigo.

Clique: selecionar peça; clicar casa válida move/troca. Clicar vaga vazia da
reserva coloca a selecionada naquela vaga exata. Botões Guardar/Colocar e Vender
continuam disponíveis para quem não quiser arrastar. Interações da loja/equipe
ficam desabilitadas durante combate, prêmio, encerramento ou menu aberto.
O menu permanece acessível durante combate e prêmio.

O cliente antigo só permitia arrastar o corpo para posicionar no campo; a
transferência para reserva/venda era pelo cartão/marcador. **No Godot, o pedido
é que o próprio sprite também participe do mesmo fluxo completo.** Não preservar
essa limitação técnica como se fosse a preferência do usuário.

## 14. Layout, cores e legibilidade

**REQUISITO.** Tudo aberto no mesmo campo visual. Não esconder sistemas atrás
das abas “Recrutar / Minha equipe / Sinergias / Posicionar e lutar”. Não usar
NPC narrando ouro/vida/equipe em um balão. Mensagens locais curtas de resultado
são aceitáveis, sem cobrir o tabuleiro.

```text
┌────────────┬─────────────────────────────────────────────────────┬───────────┐
│ MENU       │ RODADA | VIDA | OURO | CAMPO 0/6 | STATUS SAVE       │           │
├────────────┼─────────────────────────────────────────────────────┼───────────┤
│ SINERGIAS  │ fase / adversário / resultado curto                 │ ATRIBUTOS │
│ ícone      │                                                     │ selecion. │
│ contador   │               TABULEIRO 7×8                         │ estrela   │
│ bônus      │               adversário acima                      │ alcance   │
│            │               jogador abaixo                        │ itens 0/3 │
│ ITENS      │                                                     │ EQUIPE    │
│ estoque    │                                                     │ 6 cartões │
│ retirar    │ legenda de alcance                                  │ CÓPIAS    │
├────────────┼─────────────────────────────────────────────────────┼───────────┤
│            │ reserva n/8 | juros | sequência | chances da loja    │ VENDER    │
│            │ [1] [2] [3] [4] [5] [6] [7] [8]                    │ zona drop │
├────────────┼─────────────────────────────────────────────────────┼───────────┤
│ RENOVAR 2  │ [OFERTA 1][OFERTA 2][OFERTA 3][OFERTA 4][OFERTA 5]   │ LUTAR     │
│ TRAVAR     │ retrato + nome + raridade/custo + alcance            │           │
└────────────┴─────────────────────────────────────────────────────┴───────────┘
```

Diagrama visual adicional: [LAYOUT_REFERENCIA.svg](LAYOUT_REFERENCIA.svg).
É organização funcional, não arte final nem certificação de todos os tamanhos.

### Conteúdo por área

- Topo: rodada n/15, vida, moedas, campo n/6, salvo/erro; ícones de apoio.
- Faixa curta: preparação/combate/prêmio/resultado e nome do encontro.
- Esquerda: seis sinergias com contador e efeito; estoque dos três itens;
  retirar itens da selecionada.
- Centro: chão e personagens, barra de vida/mana, direção/animação de ataque,
  números subindo; grade/destaques no mesmo plano do chão.
- Direita: nome/raridade/função, estrelas, HPmáx, ataque, alcance e intervalo,
  três slots de equipamento; seis cartões da equipe; cópias para evolução;
  área de venda e opção de guardar/colocar.
- Inferior central: oito vagas numeradas de reserva, mantendo lugares vazios;
  cinco ofertas fixas da loja.
- Economia separada: juros previstos por batalha, bônus da sequência e chances
  atuais N/R/E. Não juntar tudo em uma frase longa.
- Recompensa: quatro cartões visíveis, sem NPC; bloquear preparo até escolher.
- Menu: camada central explícita, com voltar/cancelar; nenhuma UI antiga por trás.

### Referência de medidas e cores

O HUD antigo usava canvas lógico **1600×900**, escalado uniformemente e centralizado.
Faixa esquerda x20–232; centro x252–1347; direita x1380–1580. Cartões da loja
211×122, reserva 128×76. Esses valores explicam a composição; no Godot, usar
âncoras/containers e mínimos legíveis, em vez de depender somente de escala.
Quatro resoluções foram simuladas: 1920×1080, 1366×768, 2560×1440 e 1024×768;
isso não substituiu uma avaliação visual real de texto em cada tela.

| Significado | Cor de referência |
|---|---|
| Texto principal | `#e8f2fa` aproximadamente |
| Ouro / seleção / estrelas | `#ffd578` |
| Vida / ativo / alcance | `#80e5a3` |
| Casa própria / alcance como informação | `#56cbd7` / `#8de0e8` |
| Inimigo / erro / venda | `#ed7f85` / vermelho com contraste |
| Normal / raro / épico | `#bcc6cc` / `#79c4ff` / `#d99bff` |
| Painel | Azul petróleo escuro opaco ou quase opaco |

Ícones mínimos: coração, moeda, peças/campo, alcance/alvo, espada, escudo,
livro, renovar, cadeado, lutar, salvar e seis símbolos de sinergia. Usar os
mesmos símbolos no catálogo, loja e atributos. Emojis não são arte final confiável.
Não depender de cor sozinha para raridade, ação desabilitada ou estado do save.

Letras normais/grandes: opção grande +15% na base. Fonte da UI precisa manter
acentos portugueses e leitura; pixel art nos personagens não obriga uma fonte
pequena/serrilhada em todos os textos. Evitar retrato sobre o nome, ícone cobrindo
preço, números na borda e placas transparentes ilegíveis sobre o cenário.

## 15. Salvamento e retomada

**BASE EXISTENTE.** Checkpoint após mudança aceita ou de fase. Não gravar por
quadro; seleção ou preferência alterada também pode atualizar o checkpoint.
Abrir/fechar menu sem mudança no corpo salvo não exige nova gravação.

Salvar: vida/moedas/rodada/vitórias/sequência, próximo UID, equipe e suas casas,
oito vagas da reserva, estrelas e itens, bolsa, cinco ofertas e trava, estado
do RNG, seleção válida, fase/prêmio pendente e preferências gráficas/fonte.
Não salvar objetos de cena, ponteiros, IDs de apresentação, animação corrente
ou buffers de replay.

| Interrupção | Retomada existente |
|---|---|
| Preparação | Mesmo encontro e estado da equipe/economia/loja |
| Combate | Preparação do mesmo encontro, sem renda antecipada |
| Prêmio pendente | Mesma escolha pendente; renda anterior já consolidada |
| Encerrada | Nova campanha, preservando preferências |

Combate não retoma no frame exato. Checkpoint antes/depois das transições evita
dependência de um último callback ao fechar. Suspensão do processo antigo não
tinha pausa controlada. **PROPOSTA GODOT:** tratar perda de foco/suspensão para
cancelar arraste e salvar quando possível, mantendo checkpoints antecipados.
Pausar a simulação ao suspender é uma decisão de produto a registrar.

Dois arquivos alternados, sequência crescente, versão do schema e checksum.
Ler os dois, validar, escolher maior sequência válida. Arquivo parcial/corrompido
usa o outro; pode perder a última ação, não garante recuperar dois arquivos danificados.
Gravar e confirmar antes de mostrar “Salvo”. Erro deve aparecer e manter a
opção de continuar/tentar novamente. Não sair alegando save concluído se falhou.

Nova partida pede confirmação. Se limpar apenas um arquivo e falhar no outro,
preservar a campanha em memória e regravar o checkpoint atual, sem reset parcial.
**PROPOSTA GODOT:** escrita temporária, verificação e troca do arquivo ajudam
a diminuir o risco, além da alternância.

Schema antigo: versão 1; envelope até 60.000 caracteres; arquivo até 240 KB;
ouro validado até 1 bilhão; HP 0–100; rodada 0–15; estrelas 1–3; UID único;
campo ≤6; reserva exatamente oito; loja exatamente cinco; três itens por peça;
IDs e casas válidos; seleção deve existir; fase e prêmio devem ser coerentes.
São limites defensivos de arquivo, não recursos extras do jogo.

Checksum era FNV-1a de 32 bits sobre os códigos UTF-16 do payload JSON. É detecção
de corrupção acidental, não assinatura de segurança. Se mudar para outro formato
no Godot, versionar e não prometer importar o save antigo automaticamente.
Para reproduzir o antigo checksum, tratar UTF-16/surrogate pairs corretamente;
não trocar por bytes UTF-8 mantendo a mesma versão.

O RNG da loja é um LCG de 32 bits:

```text
estado = (1664525 * estado + 1013904223) & 0xffffffff
aleatório = estado / 4294967296.0
```

Salvar o estado **atual**, não somente a semente inicial. O combate existente
é determinístico sem sorteios. No Godot, usar esse LCG para paridade ou registrar
troca deliberada de RNG; um RNG diferente muda a sequência de ofertas.

## 16. Desempenho e apresentação

**REQUISITO.** Priorizar PC modesto e menos custo de desenvolvimento. Cenário
estático, sem água animada, chamas contínuas, reflexos ou partículas ambientais.
Manter animações dos personagens. Não excluir recursos para fingir otimização;
desativar efeitos e expor configuração quando fizer sentido.

**BASE EXISTENTE.** Perfis equilibrado 60 FPS, econômico 30, sem foco 10.
O antigo adapter reduzia AA, LOD e luzes e restaurava ajustes ao fechar o HUD.
Esses números eram limites configurados, não FPS ou bateria medidos.

**PROPOSTA GODOT 2D:**

- Perfil equilibrado/econômico com 60/30 FPS; reduzir atividade sem foco.
- Simulação fixa desacoplada, para economia gráfica não mudar resultados.
- Ativar/desativar processamento dos efeitos; esconder um sprite não deve
  deixar um emissor ou script caro trabalhando invisível.
- Texturas/atlases compartilhados e sprites dimensionados para o campo real.
- Atualizar labels/cartões quando o estado muda, não reconstruir a árvore por frame.
- Reutilizar visuais e IDs de peças que não mudaram; limpar os removidos.
- Buffers de ocupação/BFS limitados às 56 casas; reutilizar arrays de trabalho.
- Números/efeitos de curta duração, com limite de objetos simultâneos.
- Streaming de eventos ou buffers curtos; evitar duas linhas do tempo completas.
- Reter somente recursos necessários à campanha; liberar referências ao trocar cenas.
- Não criar shaders/luzes/3D para resolver uma grade lógica de 56 células.

Os sprites podem se sobrepor um pouco por altura artística, mas suas bases
devem permanecer separadas e o alvo deve continuar legível. Ordenar desenho
pelo pé/profundidade e limitar efeitos que encobrem barras.

Animações mínimas dos 12 heróis: idle, caminhada, ataque, habilidade, morte;
vitória pode vir depois. Não ligar dano a um sinal visual que pode disparar duas
vezes. A simulação emite evento; visual representa. Cura/dano usam números
pequenos subindo, com cor e tempo suficientes para ler.

## 17. Personagem futuro: Michael Jackson

### 17.1 O que o usuário pediu

**REQUISITO, AINDA NÃO IMPLEMENTADO.** Personagem de suporte que:

- Não faz ataques normais e não causa dano.
- Fica dançando; contagia a equipe com efeitos positivos.
- Dá escudo de 10% da **própria vida máxima** a cada dois segundos para o grupo.
- Cura 10% da **própria vida máxima** a cada dois segundos para o grupo.
- Aumenta a cura recebida de outras fontes.
- Alterna dança e moonwalk para casas adjacentes à esquerda/direita, percorrendo
  três a quatro casas, andando de costas, parando para dançar e repetindo.

Não existe modelo, sprite, animação ou inclusão na loja já produzidos. Não
substituir o pedido por um herói que ataca com animação de dança.

### 17.2 Estrutura proposta

**PROPOSTA GODOT.** Separar dois sistemas:

1. `dance_aura`: relógio de dois segundos, aplicado aos aliados vivos em campo,
   independente da caminhada; morrendo, deixa de emitir novos pulsos.
2. `dance_motion`: dançar → escolher direção/caminho lateral livre → moonwalk
   casa a casa → dançar → repetir.

`can_attack = false`, ação de suporte própria. Apenas definir dano base zero
no catálogo antigo não bastaria: a função de atributos antiga calculava 1/2/4
independentemente do campo de dano base. O modelo novo precisa representar
explicitamente unidades que não atacam.

Pulsos de exemplo antes de arredondar: HPmáx 50 → 5 de cura e 5 de escudo;
HPmáx 80 → 8 e 8; HPmáx 100 → 10 e 10, **para cada aliado**. Não calcular 10%
da vida de cada alvo. Escudo absorve antes do HP; cura limita em HPmáx.

Moonwalk respeita ocupação/reservas, limites e morte. Nunca mover quatro casas
de uma vez atravessando aliados. Contar casas realmente percorridas; se bloqueado,
parar/dançar/tentar outra direção. Dar prioridade a espaço livre lateral,
sem empurrar a equipe. Não precisa buscar inimigo nem entrar em alcance de ataque.

### 17.3 Pendências que exigem decisão

| Tema | Estado |
|---|---|
| Percentual de amplificação de cura | Não definido; 20% foi uma sugestão, não aprovação |
| HP inicial | 50 como curandeiro é compatível com a base; ainda não houve inclusão aprovada no catálogo |
| Raridade/preço/sinergias | Não definidos |
| Cura/escudo inclui o próprio Michael? | “Todo o grupo” sugere sim; registrar escolha explicitamente |
| Primeiro pulso imediato ou após 2s | Não definido |
| Duração e empilhamento do escudo | Não definidos |
| Mais de um Michael empilha aura? | Não definido |
| Amplificação atua na própria cura, Tomo e roubo de vida? | Não definido; pedido cita outras fontes |
| Pulsos durante atordoamento | Não definido |
| Arredondamento de valores como 7,5 | Definir; sugestão é seguir arredondamento da base |
| Tempo de dança/moonwalk e escolha entre três/quatro casas | Não definido |

Sugestão de protótipo: escudo por fonte que renova sem acumular infinitamente,
com duração/limite claros e sem apagar escudos de outras fontes. Isso é uma
proposta de balanceamento, não a regra entregue. Com dano básico 1, cura/escudo
global de 5 a cada dois segundos pode dominar a partida; testar antes de fixar.

Arte sugerida: roupa/chapéu/luva reconhecíveis, animação de dança em loop,
moonwalk nos dois sentidos, impacto/morte. Arte 2D/sprites pode cumprir a ideia
sem modelo 3D. PixelLab/Blender foram discutidos como ferramentas, não conectados
nem obrigatórios para a primeira versão.

## 18. Arquitetura proposta para Godot 4

**PROPOSTA GODOT, não projeto já criado.** Usar Godot 4.x instalado, GDScript,
2D inicialmente e renderer Compatibility como ponto de partida para hardware
mais simples. É uma recomendação coerente com as opções descritas na
[documentação oficial de renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html).
Registrar a versão menor utilizada; não supor APIs de qualquer Godot 4.x.

Separar regras, estado e apresentação:

```text
res://
  project.godot
  scenes/
    main.tscn
    main_menu.tscn
    match.tscn
    board.tscn
    unit_view.tscn
    hud.tscn
    shop_card.tscn
    bench_slot.tscn
  scripts/
    domain/       # dados/estado/regras puros, sem depender de Node2D
    systems/      # loja, fusão, itens, sinergias, combate, campanha
    presentation/ # board_view, unit_view, hud, drag_controller, efeitos
    persistence/  # schema, validação, save_repository
  data/           # personagens, itens, sinergias, encontros
  assets/         # sprites/atlases/fonts/sons separados da lógica
  tests/          # testes headless das regras e integração de cenas
```

Árvore de cena sugerida:

```text
Match (Node)
  MatchController
  BoardView (Node2D)
    Background
    Ground
    GridOverlay
    Units (Node2D, ordenação por profundidade)
    Effects
  HUDLayer (CanvasLayer)
    HUD (Control)
      TopBar
      SynergyPanel
      ItemBag
      SelectedUnitPanel
      TeamCards
      EconomyStrip
      Bench
      Shop
      SellZone
      FightButton
      RewardPanel
      MenuPanel
```

As 56 casas podem ser desenhadas por um Node2D/overlay simples. Se usar tiles,
nas versões recentes usar `TileMapLayer`, conferindo a versão instalada; a
documentação atual marca `TileMap` como obsoleto. `map_to_local`/`local_to_map`
fazem a conversão do mapa; coordenada global deve ser convertida para local
antes da seleção. [Referência oficial de TileMapLayer](https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html).

O TileMap desenha; o `BoardState` decide ocupação. Não delegar a navegação
dinâmica das peças ao navmesh do cenário. Para 56 casas, BFS com ocupação e
reservas explícitas é suficiente e reproduz a base.

Para cartões de UI, Godot oferece `_get_drag_data`, `_can_drop_data`,
`_drop_data` e preview em `Control`. O chão/sprite Node2D precisa compartilhar
a validação por UID com esses controles; não assumir que recebe os mesmos
callbacks automaticamente. [Referência oficial de Control](https://docs.godotengine.org/en/stable/classes/class_control.html).

Dados estáticos podem ser `Resource` ou JSON carregado e validado. Instâncias
mutáveis são separadas: alterar HP de uma peça não pode alterar o recurso que
define todas as peças daquele tipo. Não duplicar regras dentro de cada cena.

Persistência nova em `user://` usando `FileAccess`, com validação e alternância
dos arquivos acima. Esse destino é próprio dos dados do usuário no Godot;
não escrever ao lado do executável como fazia a adaptação antiga.
[Guia oficial de salvamento](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html).

Não exige MCP do Godot/Blender. Uma IA pode escrever `.gd`, `.tscn` e dados
textuais no projeto, com testes headless; MCP pode ajudar depois, sem ser
pré-requisito para criar loja, combate e tabuleiro.

## 19. Dados, ações e eventos

**PROPOSTA GODOT.** Uma única fonte de estado. Forma conceitual:

```text
RunState
  gold, player_hp, encounter_index, wins, signed_streak, next_uid, rng_state
  team: PieceState[até 6]
  bench: PieceState?[exatamente 8]
  bag: { blade, heart, tome }
  shop: character_id?[exatamente 5]
  shop_locked
  phase, pending_reward, settled_encounter_id
  preferences: graphics_profile, font_scale

PieceState
  uid, character_id, stars, item_ids[até 3], home_cell

CombatUnitState (temporário)
  uid_combate, side, cell, reserved_cell, move_progress
  hp, hp_max, mana, cooldown, target_uid
  stun_until, protection_until, poison_events, lifesteal_fraction
  stats calculados, jump_attempted

SelectionState (UI)
  selected_uid, drag_uid, drag_origin, drag_session_id, menu_state
```

Unidades de combate precisam de IDs únicos entre os dois lados. O protótipo
tinha UID persistente separado de ID nativo; no Godot, pode haver um namespace
único ou um ID de combate derivado, desde que nunca colida.

Ações de domínio: `buy_offer`, `reroll_shop`, `toggle_shop_lock`, `move_piece`,
`sell_piece`, `equip_item`, `unequip_items`, `start_combat`, `settle_encounter`,
`claim_reward`, `restart_run`, `save_and_exit`. Retornar sucesso/erro e efeito
concreto; uma ação rejeitada não muda o estado nem dispara atualização cara.

Eventos para apresentação: spawn, seleção, início de passo, avanço/chegada,
salto, ataque/habilidade, dano efetivo, cura efetiva, morte, vitória, resultado,
fusão, compra/venda, atualização de ouro/bolsa e status de save. Evento de
animação não é uma segunda operação de domínio.

Ao aceitar Lutar, mudar fase antes de processar outro input. Ao escolher
prêmio, retirar o estado pendente antes de aplicar outra entrada. Callbacks
antigos de uma sessão encerrada não devem manipular a campanha nova.

Não transportar os 139 IDs/strings do HUD antigo como API pública: eram uma
forma de atravessar o protocolo do cliente compilado. Portar os conceitos
e validações, usando sinais/ações nomeadas do projeto novo.

## 20. Etapas, testes e aceite

**PROPOSTA GODOT.** Trabalhar em marcos pequenos que o usuário possa revisar.
Não substituir implementação por sucessivas explicações nem consumir tokens
abrindo o cliente antigo. Testes novos precisam detectar risco real, não
apenas repetir cada linha de implementação.

| Marco | Entrega verificável |
|---|---|
| 1 | Projeto abre no editor; grade 7×8 e HUD aberto com sprites provisórios; estado inicial correto |
| 2 | Cinco ofertas, compra, campo/reserva, clique/arraste/troca/venda; capacidades e atomicidade |
| 3 | Cópias/fusão em cadeia, itens, sinergias, juros/sequência/renda |
| 4 | Combate por casas, alcance, habilidades, dano/cura visíveis e morte liberando casa |
| 5 | Quinze encontros, resultados/prêmios únicos, eliminação/conclusão |
| 6 | Save/retomada/falhas, menu, legibilidade e perfis leves |
| 7 | Arte/animações consistentes e, após decidir pendências, dançarino de suporte |

Aceite de regras:

- Nova campanha: 100 HP, 12 moedas, bolsa 1/1/0, 0 peças, 8 vagas, 5 ofertas.
- Campo nunca passa de 6; reserva nunca muda de 8 slots.
- Loja respeita 1/3/5, chances por capítulo e limite de duas ofertas por tipo.
- Comprar uma oferta duas vezes não cobra duas vezes.
- Três cópias fundem, inclusive em cadeia e com ocupação máxima; itens conservados.
- Sinergias contam tipos de campo, não reserva nem duplicatas.
- Juros em 9/10/19/20/50/60 = 0/1/1/2/5/6.
- Resultado e prêmio repetidos não duplicam pagamento nem pulam encontro.
- Nenhuma sobreposição de casas ou reserva concorrente durante combate.
- Ataque inicia no alcance declarado; não ataca andando ou atordoado.
- Unidade morta libera casa/reserva e não ressuscita pela cura.
- Arraste inválido e UID antigo preservam ouro/itens/formação.
- Troca campo/reserva mantém estrelas/itens e posição correta.
- Save preserva próximas rolagens; corrupção do último arquivo usa anterior.
- Retomar combate não paga antecipadamente; prêmio retomado continua único.
- Mesmo estado inicial gera o mesmo resultado; FPS 30/60 não muda regras.

Aceite de apresentação, **a conferir no Godot quando autorizado**:

- Todos os sistemas principais visíveis sem abas.
- Tabuleiro utilizável sem HUD em cima das casas necessárias.
- Letras, preço, estrelas, alcance e oito vagas legíveis.
- Venda evidente e sem disparo por tremor de clique.
- Barras, dano e cura acompanham a peça correta; sprites com pés separados.
- Não há água/fogo animados por padrão nem NPC dando ordens.
- Menu/prêmio não deixa clicar nos controles da preparação por baixo.

As referências incluem 45 cronologias de combate e 60 combates congestionados
auditados, além de 1.500 ações mistas de loja/fusão. Esses são testes JS da base,
não testes Godot já existentes. Durante o port, comparar eventos/resultados;
hashes JSON podem mudar por serialização e não devem ser vendidos como paridade
sem conferir significado, arredondamento e desempates.

## 21. Pendências e aprendizados

Não estavam implementados: nível/XP, aumentar capacidade por nível, estoque
compartilhado, sete bots persistentes, carrossel, multiplayer, mobile,
craft de itens, Michael Jackson e reserva com oito modelos 3D no chão.
Não adicionar esses sistemas como obrigatórios no primeiro marco.

Decisões ainda abertas: arte definitiva 2D/2.5D/3D; resolução/direções dos
sprites; novos nomes/visual dos heróis; pausar menu/suspensão; quantidade de
rodadas além das 15 atuais; balanceamento do dançarino; evolução de itens.
Pode usar arte provisória e avançar nas regras sem resolver todas agora.

Aprendizados do cliente antigo:

- A UI original sobreposta atrapalhava leitura e clique; criar um HUD único.
- Métodos/endereço nativos errados causaram crash ao entrar na partida.
  A nova arquitetura não precisa de offsets nem patch de DLL.
- Um mock que aceitava qualquer metadado deixou passar esse crash. Teste de
  lógica não prova integração, aparência ou estabilidade do executável.
- Compra/fusão, resultado e prêmio precisam de identidade e transações claras.
- Renderizar e simular por caminhos diferentes evita dano duplicado por efeitos.
- Animação de mapa não é mais importante que leitura e desempenho da partida.

O pedido atual foi documentar para a próxima LLM. Não foi autorizado continuar
o patch antigo, apagar a pasta, restaurar instalação, instalar Godot ou já
criar o novo projeto nesta entrega. Nenhuma dessas ações faz parte do pacote.

## 22. Referências transportáveis

| Arquivo | Uso |
|---|---|
| `DADOS_DO_JOGO.json` | Personagens sem bindings de modelo, raridades, itens, sinergias, chances e encontros com casas/atributos |
| `referencias/src/tft-core.mjs` | Fonte executável de todas as regras puras |
| `referencias/src/tft-hud.mjs` | Composição semântica e validação das ações do HUD; ignorar formato de transporte antigo |
| `referencias/src/tft-save.mjs` | Checkpoint, validação, RNG e retomada |
| `referencias/tests/` | Testes portáveis das regras, persistência, grade, loja e regressões |
| `LAYOUT_REFERENCIA.svg` | Esquema visual para explicar posição e hierarquia do HUD/chão |
| `PROMPT_PARA_PROXIMA_LLM.md` | Mensagem pronta para iniciar o próximo trabalho |
| `VERIFICACAO.json` | O que foi conferido nesta entrega e limites |
| `MANIFESTO_SHA256.json` | Integridade dos arquivos transportados |

O código de referência ainda contém nomes de skins/hero/body e distâncias de
apresentação históricas. Não depende de executáveis para executar as regras,
mas esses nomes não são recursos presentes no novo Godot. O JSON exportado
remove esses vínculos e trata alcance infinito explicitamente como `unlimited`.

Use o código para esclarecer valores e desempates, o guia para preservar as
intenções e o novo projeto para construir apresentação e integração próprias.
