# Personagens — lote 03 (deck de 10, proporção realista)

Atualizado em 2026-10-12. **Estado: nove personagens produzidos pelo PixelLab conectado ao Codex, exportados e integrados.** Neymar, Obama, Barbie, Ken, Elon, Snoop, Lula, Bob Marley e Rapunzel têm oito direções cada (72 PNGs novos), com inspeção visual. Braseiro32 × 48 também integrado. Saldo MCP esgotado; **Caramelo e Zumbi realistas pendentes**. Diário canônico: `visuais/personagens_lote_03_execucao.json`. Consultar antes de repetir geração. A lista atual é a tabela "Elenco confirmado"; a proposta anterior permanece como histórico.

## Decisão de estilo (usuário, 2026-10-11)

- **Sem caricatura.** O usuário não gostou do estilo caricato/chibi e prefere **proporção realista**, como o Michael existente.
- Personagens continuam **reconhecíveis** (figuras reais e de ficção da lista do usuário), com nomes e visuais fáceis de trocar.
- **Proposta do assistente, a confirmar:** acessório característico continua visível para leitura no tabuleiro (bola, mala, lança), mas em tamanho plausível, sem exagero cômico.

## Configuração técnica (igual ao Michael)

| Parâmetro | Valor | Motivo |
| --- | --- | --- |
| Tamanho pedido | 48 × 48 | Mesmo do Michael; 68 × 68 veio nos pedidos chibi anteriores. |
| Modelo | `mannequin`, preset explícito `realistic_male` / `realistic_female` | O chibi era a origem do visual caricato. Cachorro usa corpo quadrúpede e template `dog`. |
| Câmera | `low top-down`, 8 direções | Compatível com o tabuleiro inclinado e com o manifesto de direções do Godot. |
| Fundo | transparente, sem cenário, sem brilho | O jogo desenha sombra, aura e efeitos por cima. |
| Luz | superior esquerda, contorno escuro seletivo | Mesma leitura dos sprites atuais. |

Depois de cada geração: inspecionar as 8 direções, conferir altura visível (Michael ≈ 43 px), exportar pelo endpoint oficial para `RelicArena/assets/characters/<chave>/realista_03/original/`, atualizar o manifesto e o README de origem. Não substituir os PNGs antigos. O modo standard adiciona padding: pedido de 48 px devolve canvas 68×68; as versões realistas de Neymar/Obama têm altura visível de cerca de 49–53 px. A apresentação deve comparar o corpo e alinhar os pés, sem esticar cada canvas.

## Orçamento de créditos

Saldo inicial registrado: 10 gerações. **Saldo final MCP: 0 gerações e $0, trial**, após nove personagens e um objeto. Caramelo foi recusado por falta de saldo. O possível bônus diário não foi confirmado como utilizável pelo MCP. Retomada condicionada a saldo disponível; não comprar créditos nem trocar plano. As estimativas antigas abaixo são histórico, não saldo atual. Animações novas ficam para depois; Michael mantém suas 72 imagens existentes.

| Etapa | Gerações estimadas |
| --- | --- |
| Refazer em proporção realista: Neymar, Caramelo, Obama, Zumbi | 4 |
| Cinco novos para completar o deck de 10 | 5 |
| **Total** | **9** (sobra ~1; sem margem para refazer) |

Se o saldo for menor, priorizar os 5 novos ou os 4 refeitos conforme escolha do usuário. Não comprar créditos nem trocar de plano sem pedido explícito.

## Elenco confirmado pelo usuário (2026-10-12)

Ordem: **criar os novos primeiro**, depois refazer os 4 antigos em proporção realista. Escolhidos: **Barbie (+ Ken invocado), Elon Musk, Snoop Dogg, Lula, Bob Marley e Rapunzel**. Cleópatra e Jack saíram. Kits no [cérebro](CEREBRO.md) e já implementados na simulação com bonecos provisórios.

Orçamento revisado: 7 gerações para os novos (6 heróis + Ken). Com o último saldo registrado (10), sobrariam 3 para refazer 4 antigos; reconsultar o saldo antes.

| Chave | Descrição para o PixelLab (substitui as linhas antigas abaixo quando divergirem) |
| --- | --- |
| `barbie` | Fashion doll woman resembling Barbie, realistic adult proportions, long straight platinum blonde hair, bright pink dress, pink heels, confident tank stance. |
| `ken` | Man resembling Ken doll, realistic proportions, tanned, short blond hair, athletic, wearing only blue swim briefs (sunga) and sandals, protective stance. |
| `snoop` | Tall slim rapper resembling Snoop Dogg, long black braids, sunglasses, blue tracksuit with white stripes, microphone, light smoke wisp from hand. |
| `rapunzel` | Fairy-tale princess Rapunzel (Grimm tale, **not** the Disney design), extremely long golden braid reaching the floor, simple pale green medieval dress, small flowers in hair. |

## Proposta anterior (histórico)

Papéis vêm da lista do usuário. A escolha dos 5 e os kits abaixo são **propostas do assistente**, não regras aprovadas.

| Referência | Papel do usuário | Por que entra agora | Kit proposto (rascunho para discutir) |
| --- | --- | --- | --- |
| Lula | Tanque | Segunda frente; figura brasileira central | Discurso: provoca inimigos próximos por alguns segundos e reduz o dano recebido. |
| Elon Musk | DPS à distância | Segundo atirador, abre a composição de dois carries | A cada 4º ataque lança um foguete que explode em área (dano mágico). |
| Bob Marley | Suporte | Segundo suporte, diferente do Michael | Música: aura que reduz a velocidade de ataque dos inimigos próximos. |
| Cleópatra | DPS (alcance aberto) | Carry **mágico** que falta para a composição "Mage Carry One Shot" | Encanto: periodicamente atordoa o alvo e causa dano mágico alto. |
| Jack, o Estripador | Assassino | Assassino que alcança a retaguarda (o Caramelo não tem salto) | Some da formação no início e reaparece atrás do inimigo mais distante. |

Ficam para depois: Barbie (tanque), Rapunzel (suporte), Snoop Dogg (DPS à distância) e Júlio César (tanque).

## Pedidos para o PixelLab (rascunho em inglês, como os anteriores)

Base comum: `realistic adult proportions, NOT chibi, NOT caricature, natural head size, recognizable likeness, full body standing, both feet grounded, centered in 48x48, low top-down elevated arena camera, crisp pixel art, selective dark outline, medium shading, upper-left light, transparent background, no scenery, no text or logos, no glow`.

| Chave | Descrição específica |
| --- | --- |
| `neymar` | Brazilian football star resembling Neymar Jr., slim athletic build, bleached blond crest hair with dark sides, short beard, green and yellow football kit, golden boots, a football at his feet. |
| `caramelo` | Brazilian stray "vira-lata caramelo" dog, realistic medium-size mutt, caramel coat, one ear folded, red bandana collar with small medal (template dog). |
| `obama` | Tall slim man resembling Barack Obama, short grey hair, dark navy suit, white shirt, red tie, holding a large dark briefcase in front like a shield. |
| `zumbi` | Afro-Brazilian quilombo warrior resembling Zumbi dos Palmares, strong realistic build, red headband, bare chest, red cloth wraps, long spear with wide steel blade. |
| `lula` | Older Brazilian politician resembling Lula, stocky build, grey hair and grey beard, dark suit with red tie, presidential sash optional, confident open-arms stance. |
| `elon` | Tech billionaire resembling Elon Musk, tall, short dark hair, black t-shirt and dark jacket, holding a small handheld rocket launcher shaped like a toy rocket. |
| `bob_marley` | Reggae musician resembling Bob Marley, long dreadlocks, red-yellow-green knitted cap, denim jacket, acoustic guitar on his back. |
| `cleopatra` | Egyptian queen resembling Cleopatra, black bob hair with gold headdress and cobra crown, white linen dress, gold collar, holding a golden staff with a snake. |
| `jack` | Victorian London figure Jack the Ripper, tall thin silhouette, black top hat, long dark coat with cape, face half in shadow, small knife in hand. |

## Depois da arte

1. Kits e números definidos com o usuário, dados em `debug_characters.json`, testes de regra antes da interface.
2. Retratos da loja e do cartão saem automaticamente das frentes (`portrait_for`).
3. Sinergias cotidianas finais definidas para os 10, substituindo os grupos TESTE.

