# Cérebro do projeto — Relic Arena (nome de trabalho)

Atualização: 2026-10-11, America/Sao_Paulo.

Este documento reúne a direção do jogo, as decisões do usuário, as hipóteses e os assuntos que ainda precisamos resolver. Deve ser consultado antes de planejar ou alterar o projeto e atualizado quando uma decisão mudar. Ele é uma referência persistente, não uma prova de que o jogo foi implementado ou balanceado.

**Estágio atual:** documentação, estudo de interface, produção inicial de personagens pelo PixelLab e planejamento do primeiro protótipo jogável. Em 2026-10-11, o usuário definiu os primeiros kits e pediu um plano para começar a programar. Nenhum projeto Godot, partida multiplayer ou sistema novo de combate foi validado nesta etapa. O usuário aprenderá Godot com ajuda do assistente.

## 1. Como ler e atualizar

### Precedência

1. Pedido direto mais recente do usuário.
2. Decisões confirmadas neste cérebro, desde que não contrariem um pedido posterior.
3. Hipóteses e propostas, que precisam continuar identificadas como tais.
4. Guias, dados e código históricos, usados como referência, sem aprovação automática das regras antigas.

**Confirmado** significa que o usuário escolheu uma direção; não significa implementado. **Hipótese** é um valor ou comportamento para estudar. **Proposta** é uma sugestão do assistente. **Pendente** exige uma decisão. **Verificado** depende de evidência técnica descrita. **Descartado** não deve voltar como requisito sem nova escolha do usuário.

Ao mudar uma regra, atualizar sua seção, registrar a mudança no final e apontar dúvidas afetadas. Evitar duas regras atuais contraditórias. Investigações e correções técnicas ficam em [HISTORICO_DE_BUGS.md](HISTORICO_DE_BUGS.md).

### Vocabulário para evitar confusão

| Termo | Significado neste projeto |
| --- | --- |
| Partida | Confronto completo, composto por várias rodadas. |
| Rodada | Preparação, combate e resolução de uma perda de vida. |
| Deck | Os 10 personagens selecionados no lobby para aquela partida. |
| Capacidade da equipe | Quantidade máxima de personagens que o jogador pode colocar em campo; comprada com moedas da partida. |
| Nível da carta | Progressão fora da partida, do nível 1 ao 10. |
| Evolução na partida | Possível sistema adicional, ainda pendente; não confundir com nível da carta. |
| Patamar de sinergia | Bônus ativado pela quantidade exigida de membros na formação. |
| Carry | Personagem em torno do qual se concentra a principal fonte de dano da composição. |
| Benefício | Escolha entre três opções aleatórias em momentos da partida; nome final e efeitos ainda abertos. |

## 2. Identidade e limites já escolhidos

- Estratégia de composição e posicionamento inspirada em TFT, com partidas rápidas como referência de ritmo do Clash Royale.
- PC e celular. **No celular, tela deitada (paisagem), confirmada pelo usuário.** Multiplayer com servidor dedicado; primeiro ambiente de desenvolvimento no PC local do usuário.
- Personagens reconhecíveis como caricaturas de figuras reais, principalmente do Brasil e também do mundo. Nomes alterados, exagero visual e humor; não substituir por uma história de mundo ou personalidades inteiramente inventadas.
- Também existem referências de personagens conhecidos de ficção no elenco proposto pelo usuário.
- Acessórios característicos enormes, silhuetas diferentes, poses de vitória e de derrota/morte. Alguns personagens podem ser imponentes; outros ridículos, feios ou engraçados.
- **O jogo inteiro será em pixel art pelo PixelLab**, reafirmado pelo usuário em 2026-10-11; isso inclui cenário, personagens e elementos gráficos da interface. Efeitos e auras devem manter os ataques e a leitura da batalha claros; exagero visual dos acessórios não exige excesso de partículas.
- Arena medieval com aparência de coliseu, **piso de areia clara confirmado pelo usuário** e arquibancadas de pedra. Inicialmente vazia; público animado torcendo é uma possibilidade futura.
- Perspectiva inclinada, com referência visual de TFT e Clash Royale. **Direção refinada pelas imagens do usuário:** câmera próxima do interior do coliseu, com profundidade visível no piso e arquibancadas altas em níveis ultrapassando as bordas da tela. A versão em miniatura vista por fora foi rejeitada.
- **Clima como mecânica foi descartado pelo usuário.**

O primeiro resultado visual desejado é uma demonstração do mapa e de alguns personagens. Em 2026-10-11, o usuário gostou da base da prévia e pediu a versão pelo PixelLab. Isso autorizou o primeiro estudo visual do cenário em pixel art; naquele pedido, escala final e posição da loja ainda estavam abertas. Posteriormente, escolheu como direção inicial a organização de interface semelhante ao TFT, com loja inferior, descrita na seção 12. Escala final e refinamentos continuam abertos; não há autorização para uma sequência ilimitada de gerações. Implementação de gameplay ainda não foi iniciada.

## 3. Tabuleiro, formação e informação

| Assunto | Direção atual | Estado |
| --- | --- | --- |
| Dimensão | 8 colunas × 8 fileiras = 64 casas hexagonais. | Confirmado |
| Área de preparação | 4 fileiras para cada jogador. | Confirmado |
| Deck | 10 personagens, escolhidos antes da partida. | Confirmado |
| Unidades iniciais | Escolher 3 ou 4 heróis gratuitos para iniciar a build e as sinergias. | Faixa reafirmada pelo usuário; número exato aberto |
| Equipe maior | Aproximadamente 5–7 unidades. | Hipótese; definir teto |
| Trocas na preparação | Remover, trocar e reposicionar livremente. | Confirmado como intenção |
| Reserva | Existência, tamanho e relação com recrutamento/itens. | Pendente |
| Visão do oponente | Mostrar a formação da rodada anterior, sem revelar mudanças atuais durante a preparação. | Confirmado |
| Inventário visível do oponente | O que aparece além dos personagens e posições anteriores. | Pendente |

O posicionamento começa em hexágonos. No combate, os personagens se movimentam e atacam automaticamente, com projéteis e ataques visíveis. Distância de ataque, ocupação, colisões, caminhos, alcance de habilidades e trocas de alvo precisam ser definidos. Não importar a movimentação quadrada dos guias antigos.

## 4. Partida e resolução das rodadas

### Vidas e duração

- Cada jogador começa com **4 vidas**; quem perde uma rodada perde 1 vida; chegar a 0 encerra a partida.
- **Representação visual confirmada:** usar corações em vez de bolinhas coloridas. O estudo HTML já usa quatro ícones de coração por lado; isso não implementa perda de vida.
- O usuário quer a possibilidade de ganhar uma vida extra como benefício para permitir reviravoltas. Limite de vidas, repetição e momento da concessão estão pendentes.
- Objetivo aproximado: **5–6 minutos por partida**.
- Preparação: referência inicial de **30–45 segundos**. A primeira preparação pode precisar de tempo diferente por incluir compras iniciais; ainda não foi decidido.
- Sem empates ou vidas extras, um confronto com quatro vidas dura de 4 a 7 rodadas. Vidas extras e empates podem ampliar isso; precisamos medir o tempo completo, incluindo transições e escolhas.

### Combate e desempate

1. O combate tem limite de **30 segundos**.
2. Aos **15 segundos**, entra um bônus de velocidade pelos 15 segundos restantes.
3. No limite de tempo, vence quem tiver mais tropas ativas.
4. Com a mesma quantidade de tropas ativas, vence quem tiver causado mais dano total.

O multiplicador da aceleração e quais ações ele afeta estão pendentes. O limite deve ser definido em tempo real ou tempo de simulação de forma explícita antes da implementação.

Também faltam as definições de eliminação antes do limite, empate de dano, mortes simultâneas, dano em escudos, excesso de dano além da vida restante, invocações e tropas revividas. **Proposta para testar:** contar dano efetivo retirado da vida, evitando que excesso de dano infle o desempate; decidir separadamente o tratamento de escudos.

**Risco de design, não bug comprovado:** priorizar sobreviventes pode favorecer equipes numerosas ou de muita cura mesmo com pouca pressão ofensiva. Testar essas composições antes de confirmar o critério final. Invocações ainda não são uma mecânica aprovada.

## 5. Recrutamento, lojas e economia

### Aquisição de personagens: gratuitos desde o início

**Decisão mais recente, confirmada em 2026-10-11:** personagens gratuitos desde o início; itens e aumento de capacidade usam moedas. O usuário acrescentou renovação da loja por cerca de **2 moedas**, como valor inicial para testar e ajustar ao ver o protótipo funcionando. Essa escolha substitui o pedido anterior de comprar personagens na primeira preparação e a hipótese de renovação por 3 moedas. O deck permanece com 10 personagens.

**Esclarecimento mais recente:** escolher 3 ou 4 heróis gratuitos no início para formar a base da build e das sinergias; o número exato será decidido depois. Nas preparações seguintes, renovar uma loja conjunta com itens e personagens do deck. O jogador pode escolher incorporar um herói oferecido ou ignorá-lo, desenvolvendo a formação ao longo da partida.

A proposta do assistente de abas separadas “Itens” e “Recrutar” foi substituída pelo esclarecimento de loja conjunta: uma renovação apresenta ambos os tipos de oferta. O antigo modelo de escolher um personagem por rodada não deve ser mantido como limite aprovado deste novo fluxo. Gratuidade não define acesso imediato aos dez nem quantidade ilimitada de escolhas; limites por renovação/rodada continuam pendentes.

**Renovação:** cerca de 2 moedas por atualização conjunta de itens e personagens, como hipótese de teste expressamente escolhida pelo usuário. Quantidade de renovações, limites de recrutamento e custo final ainda precisam ser medidos. Não tratar 2 como preço balanceado definitivo nem concluir que personagens passam a custar moedas por aparecerem numa renovação paga.

Faltam regras para a origem das escolhas iniciais, proporção de itens/heróis na loja, número de ofertas, quantidade de heróis recrutáveis por renovação/rodada, repetição, personagens já recrutados, garantia de acesso ao carry, descarte, reserva e reposição. Um herói novo só pode entrar em campo respeitando a capacidade; o destino quando não houver vaga precisa ser definido, sem remoção automática de uma unidade existente. Crescer a formação não confirma evolução individual, estrelas ou duplicatas. Uma rotação ruim não pode ser avaliada sem conhecer essas regras.

### Valores para experimentar, sem compromisso de balanceamento

| Recurso/custo | Referência atual | Estado |
| --- | --- | --- |
| Moedas iniciais | Quantidade considerada boa para montar a equipe e comprar itens. | Valor pendente |
| Renda por rodada | 15–20 moedas. | Hipótese |
| Atualizar loja | Cerca de 2 moedas por renovação conjunta; substitui a antiga hipótese de 3. | Valor inicial escolhido para testar; limites e balanceamento pendentes |
| Item | 2–10 moedas, conforme força/tipo. | Hipótese |
| Aumentar capacidade | Exemplo de sequência 12, 14, 16… | Hipótese |
| Guardar saldo | Moedas não gastas continuam entre rodadas. | Confirmado |
| Juros/premiação por sequência | Nenhuma regra atual aprovada. | Pendente; não herdar juros antigos |

Uma expansão por 12 custa entre 60% e 80% de uma renda de 15–20. Isso descreve o custo relativo; **não comprova equilíbrio**. Uma unidade adicional pode trazer dano, vida, controle e vários patamares de sinergia, enquanto um item pode multiplicar a força de um carry existente.

### Estudo da economia proposto

- Comparar equipes com o mesmo orçamento: expansão, equipamento do carry, equipamento defensivo, renovação da loja e reserva de moedas.
- Medir quando uma compra ativa duas sinergias simultâneas. O ganho dessa compra pode ser muito maior que o atributo básico da unidade.
- Simular o acesso ao carry e aos itens com várias sementes, sem presumir que todos receberam a melhor loja.
- Testar gastar tudo cedo, economizar, concentrar tudo num carry e distribuir em dois carries.
- Observar se a derrota cria uma desvantagem irreversível ou se recompensas de recuperação passam a recompensar perder de propósito.
- Definir depois os custos finais e a renda. Não fixar preços antes das regras de aquisição e capacidade.

## 6. Itens e fusões

- Itens e sinergias são as fontes de fortalecimento dentro da partida já escolhidas.
- Referência de **4–5 itens por personagem**, com número exato pendente.
- Fusões usam **receitas conhecidas**, não resultados aleatórios.
- O usuário quer explorar ferramentas que removem itens para a bolsa, transformam os itens removidos em outros aleatórios e desfazem fusões em componentes.
- Essas ferramentas podem ser itens ou benefícios de escolha; formato, preço, uso e duração ainda não foram definidos.

**Pontos pendentes:** tamanho da bolsa, consumo da ferramenta, quais itens podem ser desmontados, conservação de componentes, receitas reversíveis, tier dos resultados aleatórios, empilhamento e comportamento de equipamento ao retirar ou descartar um personagem.

Se trocar uma unidade devolver todos os itens gratuitamente, o removedor pode perder seu propósito. **Proposta a avaliar:** a unidade fora de campo mantém seus itens; um removedor permite transferi-los. Descarte definitivo precisará de regra própria. Essa proposta não é uma decisão aprovada.

## 7. Benefícios e intervenção do jogador

- Antes de entrar na partida, o jogador escolhe apenas o deck.
- Durante a partida, recebe **3 opções aleatórias** para escolher um benefício.
- Momentos pretendidos: início da partida e uma segunda escolha na **quarta rodada**. Confirmar se acontece antes ou depois do combate dessa rodada; a expressão original foi “quarta partida”.
- Exemplos desejados: vida extra, moedas, item, conjunto de itens ou habilidade adicional.
- Efeitos permanentes ou com duração em rodadas ainda serão estudados.

A ideia inicial de intervir durante o combate continua como possibilidade, mas não existe regra final de duas habilidades ativas por partida. Não confundir benefício escolhido na preparação com botão utilizável durante o combate.

## 8. Progressão das cartas fora da partida

### Correção mais recente — 2026-10-10

O nível da carta vai de **1 até 10**. O aumento desejado é gradual, aproximadamente **5–6% por nível fora da partida**. O entendimento anterior de 40% foi corrigido pelo usuário e está descartado.

O percentual exato, os atributos afetados e a fórmula ainda não foram escolhidos. Do nível 1 ao 10 existem **9 aumentos**:

| Hipótese de cálculo | Multiplicador no nível 10 | Aumento total aproximado |
| --- | --- | --- |
| Composto, 5% sobre o nível anterior | 1,05^9 = 1,5513 | 55,1% |
| Composto, 6% sobre o nível anterior | 1,06^9 = 1,6895 | 68,9% |
| Linear, 5% do atributo inicial por nível | 1 + 9 × 0,05 = 1,45 | 45% |
| Linear, 6% do atributo inicial por nível | 1 + 9 × 0,06 = 1,54 | 54% |

Essas contas ilustram alternativas, não escolhem uma delas. Vida, dano, velocidade, cura e resistências não precisam necessariamente crescer juntos. Aumentar vários atributos ao mesmo tempo altera mais que um único número de dano.

### Coleção e raridades

- Caixas/prêmios concedem fichas de cartas; ao alcançar a quantidade exigida, a carta sobe de nível.
- Raridades pretendidas: comum, rara, épica e lendária.
- Limite de **até 2 lendários por deck** é uma proposta do usuário, ainda a fechar. Não significa obrigação de usar 2.
- Quantidades de fichas, taxas, fontes de caixas, personagens de cada raridade e desbloqueios ainda não foram definidos.
- Monetização desejada: skins e cartas para acelerar a progressão fora da partida.
- Objetivo declarado: sem pay to win, com progresso mais rápido para quem paga.

Precisamos conciliar esse objetivo com qualquer vantagem de atributos e acesso a cartas no PvP. Alternativas para decidir incluem níveis normalizados no competitivo, limites por ambiente competitivo ou outra regra de equivalência. **Nenhuma dessas alternativas foi aprovada.** Começar a partida com condições iguais é uma intenção já expressa; sua relação com os níveis precisa ser resolvida.

Limitar lendários não garante justiça por si só. **Proposta de design:** raridades oferecem funções e situações distintas, com composições comuns viáveis; confirmar com testes e acesso real à coleção.

### Evolução dentro da partida

Primeiro foi definido que os personagens permanecem os mesmos, recebendo apenas buffs de itens e sinergias. Depois o usuário reabriu a possibilidade de evoluções dentro da partida, inclusive para liberar efeitos de sinergia.

**Estado: pendente.** Não presumir duplicatas, estrelas, fusão de personagens ou uso da progressão de cartas como evolução de combate. O crescimento de 5–6% se refere às cartas **fora** da partida.

## 9. Sinergias e combate

### Regras de sinergia escolhidas

- A maioria dos personagens terá **2 ou 3 sinergias**; poucos terão somente 1.
- Usar grupos reconhecíveis do cotidiano: profissões, LGBT, técnicos de TI/hackers, estrelas do pop, presidentes e outros grupos escolhidos em conjunto.
- **Não separar “Governantes” de “Presidentes”**. O usuário rejeitou essa divisão.
- Cada grupo pode ter seus próprios patamares. Exemplo: 2 membros dão um bônus e 5 um bônus maior; outros grupos podem completar com 2, e casos raros podem funcionar com 1.
- O bônus do maior patamar substitui o menor, em vez de somar ambos.
- Morrer durante o combate não remove o bônus de sinergia daquela rodada.
- Interações podem trazer vantagem e contrapartida, inclusive rivalidade entre grupos ou, futuramente, entre personagens específicos.

**Proposta de execução:** calcular os patamares com a formação validada ao começar a rodada e manter esse resultado até o final. Ainda definir contagem de personagens repetidos, formas alternativas, unidades temporárias e eventuais evoluções.

Exemplo de rivalidade desejado pelo usuário: presidentes em lados opostos podem priorizar atacar uns aos outros. Efeitos internos de dois presidentes também podem ter perda em um aspecto e grande ganho em outro. Regras de alcance, tempo, troca de alvo e resistência ao controle ainda estão abertas.

### Papéis e atributos

Queremos distinguir dano físico e mágico, defesa física e resistência mágica, além de alcance, mobilidade, ataque, cura e controle. Um tanque pode ser melhor contra uma fonte de dano e vulnerável a outra. Valores, fórmulas, crítico, redução de dano e limite de controle não estão definidos.

O papel de combate não precisa virar uma sinergia obrigatória. Identidade social/profissional, função de combate e raridade são dimensões diferentes.

### Elenco inicial solicitado

Nomes abaixo são referências do usuário, não nomes finais das cartas. Raridades, rótulos de sinergia, atributos e tipos de dano ainda serão escolhidos. Os primeiros kits foram parcialmente definidos pelo usuário, conforme a subseção seguinte.

| Referência | Papel solicitado |
| --- | --- |
| Vira-lata Caramelo | Assassino, DPS |
| Michael Jackson | Suporte |
| Zumbi dos Palmares | DPS corpo a corpo |
| Elon Musk | DPS à distância |
| Barbie | Tanque corpo a corpo |
| Rapunzel | Suporte |
| Neymar Jr. | DPS à distância |
| Snoop Dogg | DPS à distância |
| Barack Obama | Tanque |
| Lula | Tanque |
| Bob Marley | Suporte |
| Jack, o Estripador | Assassino |
| Cleópatra | DPS; alcance ainda aberto |
| Júlio César | Tanque |

As listas anteriores de figuras históricas são banco de ideias, não elenco completo confirmado. Não atribuir sinergias de identidade pessoal sem pesquisar e discutir os casos necessários; uma sugestão antiga não é evidência biográfica nem aprovação final.

### Primeiros kits — decisões de 2026-10-11

| Referência | Mecânica confirmada | Parâmetros e dúvidas restantes |
| --- | --- | --- |
| Neymar | DPS à distância baseado em velocidade de ataque. Chuta bolas repetidamente; dois inimigos em casas vizinhas permitem alternância de impactos. O usuário escolheu **testar até 3 impactos por chute: primeiro → vizinho → primeiro**. | Dano por impacto, alcance, velocidade da bola, crítico no ricochete e definição de vizinhança durante o movimento livre. |
| Caramelo | Assassino que morde canelas, causa dano e sangramento por segundo; supermordida elimina alvo com 10% de vida. | Momento de verificar o limiar, tratamento de vida abaixo de 10%, duração/acúmulo de sangramento, interação com escudo e forma de alcançar a retaguarda. |
| Barack Obama | Tanque; direção visual de se proteger com a mala grande como escudo. O usuário deixou outras formas de proteção abertas. | Absorção, redução, bloqueio frontal, duração e recarga ainda não foram escolhidos. |
| Zumbi dos Palmares | DPS corpo a corpo com estocadas de lança. Concede crítico e velocidade de ataque a todos os membros da equipe. Cada crítico aumenta o dano do próximo crítico; o usuário esclareceu que **somente os críticos do próprio Zumbi alimentam esse aumento**. | Intensidade/duração do bônus coletivo, persistência após morte, fórmula, limite e reinício do crescimento dos críticos pessoais. |

As habilidades de personagem não atribuem automaticamente grupos de sinergia. O bônus coletivo do Zumbi é parte de seu kit; a regra de sinergias persistirem após morte não decide, por si só, se esse bônus também persiste.

**Propostas técnicas para o primeiro teste, não regras finais:** cada chute terá um projétil com ID próprio; ricochetes não geram novos chutes. Selecionar um único par de alvos, verificar a distância atual no chão lógico do combate e encerrar a bola se um deles morrer ou sair da distância permitida. Representar a proteção de Obama inicialmente com um escudo de absorção. Verificar a execução do Caramelo somente em uma mordida válida contra vida menor ou igual a 10%, com momento exato a fechar. Crescimento pessoal do Zumbi parametrizado e reiniciado por rodada. Valores e detalhes constam como propostas no [plano do protótipo 01](PLANO_PROTOTIPO_01.md).

### Como projetar as sinergias

1. Definir o papel, a contribuição e a fraqueza de cada personagem sem bônus de composição.
2. Escolher rótulos reconhecíveis e montar uma tabela de quem pertence a cada grupo.
3. Definir patamares segundo o tamanho de equipe realmente disponível.
4. Calcular os cruzamentos: com 7 unidades em campo, ativar dois grupos de 5 exige pelo menos 3 personagens compartilhados entre eles.
5. Identificar unidades que ativam vários patamares de uma vez. Sua força não está apenas no dano individual.
6. Criar composições candidatas com carry, frente, suporte, alternativa de itens e resposta adversária.
7. Testar as candidatas contra variações, posições, orçamento e lojas ruins antes de declarar uma composição forte ou equilibrada.

Sinergias com 1 membro precisam de custo de oportunidade ou limitação clara para não se tornarem uma inclusão obrigatória em qualquer deck. Contrapartidas devem ser compreensíveis na interface.

## 10. Composições para estudar

São **hipóteses de teste**, não times balanceados nem atribuições finais de habilidades ou sinergias. Os 10 integrantes do deck completo serão definidos depois da tabela de grupos; abaixo estão núcleos de campo possíveis.

| Ideia de composição | Núcleo a experimentar | Força pretendida | Resposta a estudar |
| --- | --- | --- | --- |
| Mage Carry One Shot | Um carry mágico a definir, tanque e suporte; avaliar Elon ou Cleópatra somente se o kit escolhido for mágico. | Explosão concentrada após preparar o carry. | Resistência mágica, interrupção, acesso ao carry. |
| Dois carries à distância | Elon + Snoop, Michael como suporte e frente com Obama ou Júlio César. | Duas ameaças, menor dependência de um único alvo. | Itens divididos e custo de proteger os dois. |
| Assassino com crítico | Caramelo ou Jack, suporte a definir e frente capaz de segurar o adversário. | Pressão sobre a retaguarda. | Posicionamento, proteção e controle. |
| Carry corpo a corpo sustentado | Zumbi, Bob Marley ou Michael e um tanque como Barbie. | Dano continuado com apoio. | Dano concentrado e controle sobre o carry. |
| Resistir e contra-atacar | Neymar como carry, Rapunzel e frente orientada ao dano inimigo. | Sobreviver ao pico adversário. | Pressão prolongada e acesso ao suporte. |
| Controle e dano em área | Personagens e kits ainda a escolher. | Ganhar tempo e punir agrupamento. | Formação espalhada e interrupção. |

“Apelão” é uma meta de sensação de uma composição funcionando bem, não licença para não haver resposta. Precisamos documentar por que ela ganha, contra o que perde e quanto depende de loja, nível, itens e posicionamento.

### Método de validação futuro

- Comparar primeiro níveis, orçamento e capacidade equivalentes; depois estudar diferenças de progressão separadamente.
- Repetir com sementes registradas, lados trocados e posições alternativas.
- Medir vitórias, sobreviventes, dano efetivo, cura, tempo vivo do carry, controle e custo total.
- Separar erro de regra, erro de implementação e desequilíbrio. Só o erro de implementação reproduzido vira bug confirmado.
- Escolher metas e quantidade de amostras antes de concluir que pequenas diferenças de vitória são significativas.

Nenhuma dessas simulações foi executada nesta etapa.

## 11. Direção técnica e servidor local

### Verificações reais

- O executável local respondeu a `--headless --version` com **4.7.2.stable.official.ed1daf0bf**, saída 0, em 2026-10-10.
- Caminho verificado: `C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
- O nome externo terminado em `.exe` é uma pasta; o executável está dentro dela.
- Não foi encontrado `project.godot` no workspace nesta verificação. Nenhum servidor ou partida foi iniciado.

A documentação oficial confirma que Godot 4 pode funcionar sem interface com `--headless`, sem exigir um binário especial de servidor: [exportação para servidores dedicados](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html).

### Arquitetura proposta, ainda não implementada

- Servidor como processo separado e autoridade sobre sorteio, saldo, compras, inventário, formação válida, combate, relógio e resultado.
- Clientes apresentam o estado recebido e enviam intenções; não decidem preços, dano ou vencedor.
- Regras separadas de animações e cenas visuais, com identificadores estáveis e dados de personagens/itens/sinergias em recursos próprios.
- Registrar versão de regras, semente e eventos suficientes para reproduzir uma rodada.
- Validar fase, jogador, saldo, limites e identificador de comando para impedir compras duplicadas na retransmissão.
- Guardar o estado atual privado da preparação no servidor; o adversário recebe somente a informação autorizada da rodada anterior até a revelação.
- Definir comportamento de desconexão, prazo de reconexão e abandono. Não existem regras finais para essas situações.

Referência oficial: [multiplayer de alto nível do Godot](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html). ENet é uma opção a avaliar para o protótipo, não uma escolha de infraestrutura já instalada.

Etapas de rede previstas: primeiro dois clientes e servidor no mesmo PC; depois dispositivos na rede local; depois acesso pela internet. “Servidor dedicado no PC local” não significa que o jogo já esteja acessível pela internet. Portas, firewall e hospedagem ainda não foram configurados.

## 12. PixelLab e direção dos assets

O navegador permitiu observar o personagem inspirado em Michael Jackson na página correta de Characters: imagem de 48 × 48 pixels com 8 direções. Isso confirma a presença do personagem observado, não que suas animações estejam prontas ou importadas no Godot.

Também foram observados uma geração em andamento e um erro de geração de moonwalk com indicação de que não houve cobrança. Não foi feita nova geração, exclusão ou correção nessa etapa.

**Ferramentas nativas PixelLab disponíveis neste chat em 2026-10-11.** get_balance, create_image_pixen, create_image_pixflux e get_image foram utilizados diretamente; os três estudos iniciais foram salvos na galeria. A revisão com referências também utilizou unzoom_image, pixelart_workbench e save_to_asset; resultados e limites estão abaixo. Em 2026-10-10, o acesso de leitura havia sido validado por um cliente MCP de diagnóstico por Streamable HTTP/JSON-RPC no endpoint configurado, lendo a credencial local sem exibi-la. Acesso à página no navegador, consulta autenticada ao MCP e exposição automática das ferramentas neste chat são verificações diferentes. Chaves devem ficar fora dos documentos do projeto.

Na consulta inicial de 2026-10-10, não havia ferramentas PixelLab disponíveis neste chat nem entrada correspondente pelo nome/host no arquivo de configuração local consultado.

Depois, o usuário cadastrou o servidor `pixellabs` com a URL esperada e um cabeçalho Authorization. Uma captura e a leitura local identificaram `streamable HTTP` preenchido incorretamente em `bearer_token_env_var`, campo que espera um nome de variável de ambiente. O assistente removeu somente esse campo inválido de `C:/Users/m/.codex/config.toml`, preservou as demais configurações e verificou a leitura do TOML. Nenhum token foi exibido ou alterado.

Após o usuário informar que estava pronto, o cliente MCP de diagnóstico recebeu initialize HTTP 200, initialized HTTP 202 e tools/list com 101 ferramentas. As chamadas list_characters e get_character retornaram sem erro e permitiram consultar os assets da conta. Os logs locais também registraram `pixellabs` como ready, sem erro, às 18:03:29 de Brasília. **As ferramentas ainda não estavam expostas automaticamente no catálogo deste chat nessa consulta.** Isso não invalida a inicialização local e o acesso autenticado comprovados. Ver [INC-003 no histórico](HISTORICO_DE_BUGS.md#inc-003--tipo-de-transporte-preenchido-no-campo-de-variável-do-token).

### Assets Michael localizados por consulta MCP

| Identificador | Estado verificado | Características |
| --- | --- | --- |
| 43442f6d-97c5-42f8-8f08-563db168a66a | completed | 48 × 48, 8 direções, low top-down, sem animações cadastradas. |
| 8e001e18-9617-4a67-a326-32af26dc4f24 | completed, estado Idle | 48 × 48, 8 direções, low top-down; um grupo de animação personalizada em 8 direções, 9 quadros por direção. Prévia sul retornada pelo MCP e observada. |
| c0d687db-d402-46a8-a2a8-500635e56329 | completed, conforme grupo retornado | Outro estado do personagem anterior; nome do estado começa com dancer in a white vi. |
| 49bf1207-465d-4697-a47c-6202a7404c80 | failed | Tentativa de 64 × 64 associada à descrição de moonwalker; mensagem genérica Generation failed, causa específica desconhecida. |

Consulta pelo termo Michael retornou quatro registros. A indicação 8anim corresponde a oito direções de **um** grupo de animação, não a oito ações diferentes. Metadados e uma prévia foram consultados; a qualidade visual de todos os quadros não foi inspecionada nessa etapa. Nenhuma geração, repetição, exclusão ou importação foi realizada. Preservar os assets existentes antes de decidir qual versão será referência.

Com a tela deitada definida, antes de gerar o mapa precisamos decidir área útil da interface, escala dos personagens, tamanho dos hexágonos, alinhamento dos pés e camadas de cenário. Os 48 × 48 do personagem existente são uma referência observada, não resolução final aprovada para todo o elenco.

**Piso definido:** areia clara. Foi preparado o [estudo de layout 01](visuais/arena_areia_estudo_01.html), um HTML local e independente de Godot/PixelLab. Ele apresenta 64 hexágonos, quatro fileiras por lado, arquibancadas vazias e marcadores abstratos de escala. Permite comparar formatos de tela em paisagem, altura da visão, tamanho dos marcadores, grade, coordenadas e área de loja inferior ou lateral. Posições e áreas de interface são propostas; quantidade de marcadores não define equipe inicial, capacidade ou reserva. Não há compras, combate ou geração de assets.

Também foi criada uma [prévia estática em PNG](visuais/arena_areia_estudo_01.png), com 1600 × 1080 pixels, desenhada diretamente a partir das mesmas fórmulas de projeção do estudo. A imagem foi aberta e inspecionada; a contagem calculada confirmou 64 casas e 32 por lado. Não é uma captura do HTML. A política do navegador recusou a abertura automática da página local; por isso a interação e a renderização do HTML no navegador ainda não foram verificadas. O servidor temporário foi encerrado, sem tentativa de contornar o bloqueio. Ver [INC-004](HISTORICO_DE_BUGS.md#inc-004--abertura-da-prévia-local-recusada-pelo-navegador).

Revisão sem navegador: sintaxe JavaScript aceita pelo Node; fonte executada com DOM simulado confirmou 64 IDs únicos de A1 a H8, 32 casas por lado e alinhamento dos pés aos centros. Nos 101 valores do controle de altura da visão, todos os vértices ficaram dentro da elipse de areia. A linha tracejada central é uma referência visual reta, não a fronteira geométrica em zigue-zague nem uma parede; a pertença das casas é determinada pela fileira. Essa revisão não substitui testar os controles e a legibilidade numa tela real.

Ordem de produção desejada: mapa primeiro; depois personagens e suas animações. Rascunho de layout pode ajudar a validar a leitura antes de consumir créditos.

### Primeiros estudos de cenário no PixelLab — 2026-10-11

O usuário aprovou a direção geral da prévia e pediu a versão pelo PixelLab, reafirmando o jogo inteiro em pixel art. A aprovação da base não fecha posição da loja, escala dos personagens ou resolução final. Para esta produção, cenário sem grade/interface é uma escolha técnica proposta: os hexágonos e os elementos gráficos da interface também devem parecer pixel art, mas ficar em camadas próprias para manter geometria e controles ajustáveis.

| Estudo | Resultado observado | Registro |
| --- | --- | --- |
| [01 — Pixen, 768 × 324](visuais/arena_pixellab_01.png) | Dois coliseus lado a lado; não selecionado para o cenário. | [Briefing, IDs e seed](visuais/arena_pixellab_01.json) |
| [02 — Pixen, 640 × 360](visuais/arena_pixellab_02.png) | Repetiu a duplicação mesmo após mudar descrição/proporção; não selecionado. | [Briefing, IDs e seed](visuais/arena_pixellab_02.json) |
| [03 — Pixflux, 384 × 216](visuais/arena_pixellab_03.png) | Uma arena oval, areia clara e centro livre; rejeitada pelo usuário pelo enquadramento e qualidade visual. | [Briefing, IDs e seed](visuais/arena_pixellab_03.json) |

As três chamadas terminaram, cada uma com cobrança informada de 1 geração; custo total dessa etapa: 3 gerações. PNGs originais preservados sem redimensionamento e sem substituir assets anteriores. Michael e suas animações não foram modificados. **O usuário rejeitou a terceira arte**, forneceu referências mais detalhadas e pediu refazer a câmera/arquitetura como nelas. Não há integração Godot, teste de 64 casas sobre o cenário, validação de oclusão ou definição da resolução final. Ver [ART-001](HISTORICO_DE_BUGS.md#art-001--geração-de-cenário-trouxe-dois-coliseus).

### Correção da direção visual pelas referências do usuário

Referências preservadas: [01 — profundidade e luz](visuais/referencias/arena_referencia_usuario_01.png), [02 — câmera e arquibancadas vazias](visuais/referencias/arena_referencia_usuario_02.png), [03 — enquadramento com interface](visuais/referencias/arena_referencia_usuario_03.png). A segunda é a principal referência para o novo cenário. As imagens guiam aparência e composição; sua contagem de casas, personagens, textos e elementos de interface não altera automaticamente as regras do jogo.

**Escolha confirmada pelo pedido atual:** ambiente imersivo visto de dentro, câmera elevada e inclinada, arquibancadas com assentos largos e faces verticais sombreadas, portais de pedra, camadas de arquitetura e iluminação mais rica. O cenário deve preencher a tela; a borda frontal pode ser cortada pelo enquadramento. Manter areia clara e arquibancadas vazias nesta fase.

O estudo 04 usou a imagem 02 como referência real no PixelLab. unzoom_image recuperou uma imagem de 351 × 195; para o modelo aceitar dimensões múltiplas de quatro, foi preparada uma tela de 352 × 196 adicionando somente uma coluna e uma linha transparentes, sem reescalar ou alterar os 68.445 pixels originais. Essa preparação de formato não é pintura local da arte. A tentativa nativa de preparar a tela com pixelart_workbench retornou limite de memória; a preparação foi feita com System.Drawing e conferida pixel a pixel.

| Revisão | Evidência e resultado |
| --- | --- |
| [04 — Pixflux com referência](visuais/arena_pixellab_04.png) | Interior mais próximo do pedido, mas reteve personagens, grade e textos. Não selecionada; [metadados](visuais/arena_pixellab_04.json). |
| [05 — Pixflux com menor preservação](visuais/arena_pixellab_05.png) | O serviço informou completed, saved e cobrança de 1 geração, mas o PNG é inteiramente preto. Causa desconhecida; [metadados](visuais/arena_pixellab_05.json). |
| Edição Pro | Recusada por limite da conta de teste; nenhum job criado. get_balance ainda indicou 15 gerações restantes e 2 diárias. Não foi determinada a causa da discrepância. |
| [Fundo limpo da referência](visuais/arena_referencia_limpa_02.png) | Edição exata gratuita no PixelLab: retirou HUD, unidades e grade, preservou a arquitetura existente e acrescentou textura leve na areia. |
| [Prévia com 64 hexágonos](visuais/arena_referencia_previa_02.png) | Edição gratuita separada, com 8 colunas × 8 fileiras e quatro fileiras por lado. Sem personagens ou interface; é estudo estático de composição. |

**Natureza da entrega atual:** edição da referência enviada pelo usuário, não uma geração nova da arquitetura. O cenário vazio e a prévia estão em arquivos separados e foram adicionados como novas imagens na galeria PixelLab, preservando os originais. [Registro reproduzível](visuais/arena_referencia_estudo_02.json) inclui origem, operações, polígonos, IDs e custos. A primeira limpeza por cópia de uma faixa inteira produziu degraus repetidos; foi substituída por remendos localizados sobre a fonte. Ainda há pequenas emendas superiores, e o acabamento da grade é provisório. **Não aprovada como arte final pelo usuário.**

Custo adicional informado nesta revisão: **2,1 gerações** — 0,1 para recuperar a referência e 1 para cada tentativa 04/05. Edições exatas e salvamentos na galeria foram gratuitos conforme as ferramentas. Não continuar gerando enquanto o limite da conta estiver recusando as operações. PNGs entregues têm 351 × 195 pixels nativos; resolução final, legibilidade no celular, encaixe de sprites e oclusão ainda não foram validados no Godot. Ver [ART-002](HISTORICO_DE_BUGS.md#art-002--revisão-da-arena-com-referência-e-limites-do-pixellab).

### Referência inicial da interface semelhante ao TFT — 2026-10-11

**Confirmado como direção visual inicial, sujeita a refinamento:** o usuário enviou a [referência 04 de interface](visuais/referencias/arena_interface_referencia_usuario_04.png) e pediu “esse layout dos botões se parecendo muito com o tft”, para editar e refinar depois. Preservar sua organização geral, hierarquia dos painéis e aparência medieval em pixel art. Esta imagem passa a ser a referência principal da distribuição da interface; a referência 02 continua orientando câmera e arquitetura do cenário.

| Região | Organização escolhida como referência |
| --- | --- |
| Canto superior esquerdo | Painel da própria equipe e indicador de vidas. |
| Canto superior direito | Painel do adversário e indicador de vidas. |
| Centro superior | Identificação da arena, rodada/fase e estado de preparação/combate com tempo visível. |
| Lateral esquerda | Lista vertical de sinergias, com ícones e contagens para os patamares. |
| Centro | Tabuleiro inclinado e personagens, mantendo área de combate legível. |
| Canto inferior esquerdo | Bolsa de itens em espaços visuais, próxima dos controles da loja. |
| Faixa inferior | Ofertas em cartas lado a lado; botões de atualizar loja e progressão/capacidade ao lado. |
| Acima da loja | Saldo de moedas e informações de capacidade/progressão. O conteúdo exato permanece aberto. |

**Separar visual de regras:** a imagem não confirma juros/interesse, compra de XP, nível dentro da partida, cinco ofertas, valores de ouro, preços, raridades, tempo de 15 segundos, numeração “2-3” ou grupos de sinergia nela escritos. Posteriormente, o usuário confirmou personagens gratuitos desde o início; formação inicial e sorteios estão pendentes na seção 5. Vidas continuam sendo quatro e o tabuleiro continua 8 × 8, independentemente dos exemplos desenhados. O foco deste pedido é a distribuição dos botões e painéis; não aprova automaticamente público animado ou os personagens ilustrados.

**Proposta de adaptação, ainda não aprovada:** o espaço visual de “Comprar XP” pode receber a ação de ampliar a capacidade da equipe, conforme a regra que vier a ser definida; a área de ofertas pode acomodar os itens e o recrutamento escolhido. Manter funções compreensíveis, sem herdar economia ou regras de TFT apenas pela aparência.

**Refinamentos pendentes:** tamanho de botões e textos para toque em celular deitado, quantidade de ofertas, expansão/recolhimento da lista de sinergias, área de reserva, acesso a detalhes e comportamento da loja durante combate. Cenário, grade, personagens e controles devem continuar ajustáveis separadamente; a imagem de referência não é uma interface funcional. Nenhum asset foi gerado e nenhum crédito foi consumido para este registro.

**Continuação documentada:** [INTERFACE_PROPOSTA_01.md](INTERFACE_PROPOSTA_01.md) descreve funções e fluxos; [interface_estudo_01.html](visuais/interface_estudo_01.html) é um estudo técnico independente com o fundo existente do PixelLab, loja conjunta de itens e heróis gratuitos, painéis selecionáveis, 64 casas e comparação de molduras. As abas iniciais foram removidas após o esclarecimento do usuário. Atualizar loja alterna exemplos fixos de ofertas, sem sorteio real, cobrança ou recrutamento. Painéis CSS são marcações provisórias, não assets finais. Quatro ofertas, divisão de dois itens/dois heróis e seis espaços de bolsa são exemplos visuais; compras, economia e combate não são executados. Recolher a loja no combate e usar “Ampliar equipe” no espaço de “Comprar XP” continuam propostas. Não foi consumido crédito nem implementado projeto Godot. Sintaxe e referências locais conferidas; interação e renderização no navegador/dispositivo ainda não verificadas.

**Atualização da interface:** ícone [vida_coracao.png](visuais/ui/vida_coracao.png), 16 × 16 com transparência, desenhado e salvo gratuitamente no PixelLab; [receita e metadados](visuais/ui/vida_coracao.json). Galeria 81b2beb0-d35a-4c2f-8d22-9529393b19b2. Quatro corações por lado substituem as bolinhas; botão informa “Atualizar loja · 2 moedas” como valor de teste, sem débito real neste HTML.

**Produção de personagens autorizada:** o usuário pediu começar a criar os personagens principais no PixelLab. Primeiro núcleo de produção: Michael existente (suporte), Caramelo (assassino), Zumbi (dano corpo a corpo) e Obama (tanque). Os três novos têm nomes de trabalho, não aprovados como nomes finais. Ponto de partida técnico: 48 × 48, oito direções, low top-down, modo standard; isso não fecha resolução final ou sinergias. Consultar resultados antes de produzir animações ou ampliar o lote. Michael e suas animações devem ser preservados.

### Resultado do primeiro núcleo — 2026-10-11 (registro anterior)

[Galeria local para comparar os personagens](visuais/personagens_lote_01.html) · [briefings, IDs, falhas e saldo](visuais/personagens_lote_01.json).

| Referência / nome de trabalho | Resultado observado | Arquivo local |
| --- | --- | --- |
| Michael Jackson / nome final pendente | Existente preservado: 48 × 48, oito direções e uma animação na conta. Nenhuma geração nova para ele. | [Prévia sul](visuais/personagens/michael_existente/south.png), [metadados](visuais/personagens/michael_existente/character.json). |
| Zumbi dos Palmares / Zumbalhão | Nova base concluída em oito direções. Solicitado 48 × 48, retornado 68 × 68; nenhuma animação criada. Nome e aparência ainda não aprovados. | [Prévia sul](visuais/personagens/zumbalhao/south.png), [metadados](visuais/personagens/zumbalhao/character.json). |
| Vira-lata Caramelo / Caramelo Relâmpago | Primeira tentativa falhou por conexão interna. Uma nova tentativa terminou com limitação temporária da conta gratuita por alta demanda. | Sem PNG; briefing preservado no manifesto. |
| Barack Obama / Obamuralha | Pedido aceito e depois encerrado pela mesma limitação temporária da conta gratuita. | Sem PNG; briefing preservado no manifesto. |

**Limites da entrega:** somente as prévias sul estão salvas e inspecionadas localmente. As oito direções foram informadas pela API, não conferidas individualmente. Download público de rotações retornou HTTP 403 e foi interrompido, sem contornar; os PNGs locais vieram dos bytes já entregues pelo MCP. Novas tentativas de geração foram encerradas após a recusa por alta demanda. Ver [INC-005](HISTORICO_DE_BUGS.md#inc-005--primeiro-núcleo-de-personagens-e-limitações-do-pixellab).

**Revisão visual inicial, proposta do assistente:** Zumbi ainda está próximo de um guerreiro genérico, com exagero moderado e arma fina; avaliar identificação e acessório antes de aprovar ou animar. Não reduzir automaticamente a tela de 68 para 48: a área visível tem 24 × 48 pixels, enquanto Michael ocupa 28 × 43. A galeria amplia por fatores inteiros e alinha os pés sem editar os PNGs. As miniaturas nas ofertas da interface são apenas prévias; o tabuleiro ainda não tem unidades jogáveis.

**Custo observado:** modo standard anunciou 1 geração por personagem. O saldo passou de 15 restantes / 24 usadas para 14 restantes / 25 usadas, com assinatura trial e créditos US$ 0. Cobrança ou reembolso de cada tentativa falha não foram confirmados. O coração foi desenhado e salvo gratuitamente. Não comprar plano ou créditos nem trocar modelos para contornar a recusa.

**Verificação executada:** PNGs válidos com transparência, dimensões e áreas visíveis conferidas; sintaxe JavaScript, referências locais, 64 casas e quatro corações por lado conferidos. [Registro de validação](visuais/personagens_lote_01_validacao.json). Não houve teste em navegador, dispositivo ou Godot; somente as prévias sul foram inspecionadas.

Referências do serviço: [MCP do PixelLab](https://www.pixellab.ai/mcp) e [documentação das ferramentas](https://api.pixellab.ai/mcp/docs).

### Refinamento e ampliação do elenco — situação atual, 2026-10-11

**Autorização mais recente:** o usuário pediu corrigir/refinar o que foi feito e depois começar a fazer mais. Não houve alteração de regras, aprovação de nomes finais ou autorização implícita para implementar o jogo inteiro.

| Referência | Resultado atual |
| --- | --- |
| Michael | Base e animação existentes preservadas, sem mudanças de pixels. Pose de dança já tem silhueta distinta. |
| Zumbi / Zumbalhão | Frente revisada gratuitamente no editor PixelLab: corpo mais largo, lança com lâmina/cabo maiores e nó vermelho destacado. Nova base em oito direções, ID 7129a655-427d-4ca9-84bb-13ad3ddd4682; lâmina oeste corrigida após inspeção. Original preservado. |
| Caramelo / Caramelo Relâmpago | Nova geração standard concluída, ID 82eace58-7128-4f15-97ce-1944a5702428. Oito direções inspecionadas no editor nativo; somente sul salvo localmente. As duas orelhas ficaram erguidas e o acessório ainda discreto; não cumpre integralmente o briefing. |
| Barack Obama / Obamuralha | Nova base standard concluída, ID 9a2a0a13-3fca-4dd6-a685-94d312c75bb2. Frente refinada gratuitamente com ombreiras maiores e pasta-escudo enorme. As outras sete direções da base ainda não incluem esse refinamento. |
| Neymar / Neydrama | Nova base standard concluída, ID fcc05054-6672-4efb-b417-f49cffcc7b7f. Frente refinada no editor gratuito para destacar bola e chuteira dourada. As outras sete direções da base ainda não incluem esse refinamento. |

As três novas bases standard retornaram 68 × 68 após pedidos de 48 × 48; o motivo não foi determinado. A rotação do Zumbi usou a referência nativa de 68 × 68. Comparação confirmou os pixels visíveis e o alfa da frente preservados pelo v3; diferenças de RGB ocorreram somente sob transparência total. Isso não equivale a conferir todas as direções ou animações.

**Arquivos para revisão:** [galeria com cinco personagens e comparação das frentes](visuais/personagens_lote_01.html), [registro desta etapa](visuais/personagens_lote_02.json). Os originais e o manifesto do lote 01 continuam preservados. O estudo da interface apresenta essas prévias nas ofertas, alternando três conjuntos fixos; não concede personagens, cobra moedas, executa sorteios ou combate.

**Custos observados nesta etapa:** três pedidos standard anunciaram 1 geração cada; a ajuda estimou 2 para rotação v3 com referência, mas a criação nativa informou 1. Saldo passou de 14 restantes / 25 usadas para 10 restantes / 29 usadas (trial, créditos US$ 0), variação de quatro gerações compatível com os quatro pedidos concluídos. Os refinamentos exatos e salvamentos na galeria informaram custo zero. Usar os retornos reais para registrar custo, sem transformar estimativa da ajuda em cobrança.

**Pendências de arte:** aprovar exagero/identificação, uniformizar escala visível, conferir os ângulos e levar os acessórios refinados de Obama/Neymar para as demais direções antes de animar. Nenhuma animação nova foi solicitada nesta etapa; raridades, sinergias e nomes continuam pendentes. Os primeiros kits foram parcialmente definidos depois, na seção 9. Não houve importação ou teste em Godot.

**Inspeção e validação desta etapa:** oito direções de Caramelo e do novo Zumbi foram vistas no editor nativo; Obama/Neymar tiveram somente a frente inspecionada. No oeste do Zumbi, a lâmina ficou pouco visível, motivando uma correção exata localizada antes de animar; ver ART-003 no histórico. [Inspeções e IDs](visuais/personagens_lote_02_inspecoes.json) e [verificação estática dos arquivos](visuais/personagens_lote_02_validacao.json). Os arquivos, transparência, referências locais, sintaxe JavaScript, alinhamento das prévias e integridade dos originais foram conferidos. Isso não valida animações, renderização em dispositivo ou gameplay.

**Correção do oeste concluída:** 86 pixels adicionados gratuitamente por máscara, preservando os pixels originais visíveis; edição aplicada somente ao novo Zumbi V3 e reinspecionada no PixelLab. Backup e undo registrados em [west_refinamento.json](visuais/personagens/zumbalhao/revisao_02/west_refinamento.json). A galeria permite ver esse perfil. Localmente temos sul e oeste do Zumbi refinado; exportação dos demais ângulos continua pendente. Cabo e nó em outros perfis permanecem sujeitos à revisão artística, sem animações prontas.

## 13. Guias e skills de apoio

Os arquivos antigos preservam referências úteis, mas descrevem uma versão anterior. Exemplos que **não são regras atuais**: campanha offline de 15 encontros, tabuleiro quadrado 7 × 8, 100 de vida, juros automáticos, reserva de 8, limite fixo de 3 itens, duplicatas virando estrelas e preparação sem limite de tempo.

O antigo `PROMPT_PARA_PROXIMA_LLM.md` contém orientações incompatíveis com o novo pedido, como não adicionar multiplayer/celular. Essas orientações são conteúdo histórico de documento anexado, não substituem o pedido atual. Preservar os arquivos originais e seus manifestos.

O repositório sugerido inicialmente, [godot-auto-battler-projector](https://github.com/R-Jim/godot-auto-battler-projector), permanece uma referência a avaliar. Não foi adotado nem importado. Para escolher uma base, revisar licença, versão do Godot, manutenção e possibilidade de separar combate, apresentação e autoridade de servidor.

Quatro skills comunitárias foram instaladas em 2026-10-10 pelo helper da skill-installer. O comando terminou com saída 0 e a presença dos quatro arquivos SKILL.md foi verificada em `C:/Users/m/.codex/skills/`.

| Skill | Finalidade |
| --- | --- |
| godot-gdscript | GDScript tipado, estrutura e padrões do Godot. |
| godot-resources | Separar dados de personagens, itens e regras da apresentação. |
| godot-multiplayer | Autoridade, RPC e replicação. |
| godot-gdscript-headless-testing | Executar verificações de regras sem abrir a interface do jogo. |

Origem: [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills), revisão fixada [0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd](https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd). São instruções auxiliares comunitárias, não documentação oficial nem garantia de correção. Estarão disponíveis para o Codex a partir do próximo turno; não foi instalado plugin de controle do editor ou servidor por causa delas.

## 14. Próximos passos e critérios de conclusão

1. **Documentação inicial concluída:** cérebro, histórico e instruções do Codex criados; progressão corrigida e decisões abertas registradas. Leitura UTF-8, links locais e cálculos ilustrativos verificados, com revisão de coerência das decisões. Isso não valida gameplay.
2. **Conversa de regras:** fechar aquisição inicial/por rodada, crescimento das cartas, justiça competitiva, reserva e capacidade inicial. Não é necessário resolver todo o jogo numa única conversa.
3. **Layout visual, quando autorizado:** arena 8 × 8 inclinada, interface legível no celular/PC e personagens de referência na escala desejada. Sem público animado nesta primeira etapa.
4. **Primeiro protótipo jogável:** [plano 01 documentado](PLANO_PROTOTIPO_01.md), a pedido do usuário. Proposta: projeto Godot novo e pequeno, arena/posicionamento, servidor local separado de dois clientes, combate e kits de Neymar, Caramelo, Obama e Zumbi; depois ciclo de rodadas e loja. Implementação ainda não iniciada. Coleção, pagamentos e elenco completo ficam para etapas posteriores.
5. **Composições e balanceamento:** tabela de sinergias, primeiros itens/receitas, composições candidatas e simulação reproduzível. Dados medidos passam a orientar números.

### Decisões abertas para as próximas conversas

| ID | Assunto a decidir |
| --- | --- |
| D01 | Loja conjunta confirmada, renovação inicial por cerca de 2 moedas: fechar 3 ou 4 heróis iniciais, origem das escolhas, mistura de ofertas, limites e quantidade recrutável por renovação/rodada. |
| D02 | Começar com 3 ou 4 unidades, terminar com qual capacidade, e quanto ouro inicial? |
| D03 | Reserva, descarte e itens equipados ao trocar de personagem. |
| D04 | Crescimento das cartas: 5% ou 6%, linear ou composto, e quais atributos? |
| D05 | Como aplicar níveis/coleção no PvP mantendo a justiça pretendida? |
| D06 | Haverá evolução de personagem dentro da partida? Qual recurso e efeito? |
| D07 | Primeiras sinergias, membros, patamares e rivalidades; depois raridades. |
| D08 | Quando chegam os benefícios, duração, vida extra e eventual intervenção no combate? |
| D09 | Aceleração dos 15 segundos, dano de desempate e empate completo. |
| D10 | Slots/bolsa de itens, primeiras receitas e ferramentas de remoção. |
| D11 | Resolução/escala e adaptação da interface ao toque; distribuição inicial escolhida pela referência 04, com loja inferior, sinergias à esquerda e status no topo. |
| D12 | Informação pública do adversário e regras de desconexão/reconexão. |
| D13 | Neymar: alcance/vizinhança em movimento livre, dano por impacto e crítico. Limite inicial escolhido para teste: 3 impactos por chute. |
| D14 | Caramelo: limiar/momento da execução, sangramento e acesso à retaguarda; Obama: tipo de escudo; Zumbi: números/duração do bônus coletivo e fórmula/limite do crescimento dos críticos pessoais. |

## 15. Registro de decisões e manutenção

| Data | Registro |
| --- | --- |
| 2026-10-10 | Consolidação das escolhas já discutidas; antigos guias identificados como históricos. |
| 2026-10-10 | Usuário corrigiu progressão fora da partida para aproximadamente 5–6% por nível, até 10. Os 40% eram um entendimento incorreto e foram descartados. |
| 2026-10-10 | Compra inicial de personagens e itens registrada como atualização; aquisição nas demais rodadas permanece aberta. |
| 2026-10-10 | Possível evolução dentro da partida registrada como assunto reaberto, sem importar estrelas/duplicatas antigas. |
| 2026-10-10 | Instalação do Godot verificada pelo comando de versão; sem validação de jogo ou rede. |
| 2026-10-10 | Quatro skills de apoio ao Godot instaladas e arquivos verificados; revisão de origem registrada acima. |
| 2026-10-10 | Próximos passos propostos: conectar PixelLab, decidir orientação do celular e validar layout antes da arte final. Orientação ainda não escolhida. |
| 2026-10-10 | Usuário confirmou tela deitada (paisagem) no celular. Escala, resolução e distribuição da interface permanecem abertas. |
| 2026-10-10 | Corrigido campo de variável de token no servidor pixellabs, preservando Authorization. Conexão e autenticação aguardam validação após reinício. |
| 2026-10-10 | Inicialização local pixellabs ready e acesso MCP autenticado validados por cliente de diagnóstico; quatro registros Michael localizados e uma prévia observada. Exposição automática das ferramentas no catálogo deste chat ainda não confirmada. |
| 2026-10-10 | Usuário confirmou piso de areia clara. Estudo de layout 01 preparado para avaliar enquadramento e espaço da interface, sem arte final ou regras de gameplay implementadas. |
| 2026-10-10 | Prévia estática do layout criada e inspecionada. Abertura automática do HTML bloqueada pela política do navegador; nenhuma validação visual/interativa desse HTML foi alegada. |
| 2026-10-11 | Usuário gostou da base da prévia e pediu a arena pelo PixelLab; reafirmou que o jogo inteiro será em pixel art. |
| 2026-10-11 | Ferramentas nativas PixelLab disponíveis e utilizadas diretamente. Três estudos gerados e preservados; terceiro entregue para revisão, com arquibancadas ainda a ajustar. Custo informado: 3 gerações. |
| 2026-10-11 | Usuário rejeitou a arena 03 e enviou três referências: câmera inclinada dentro de um coliseu detalhado. Referência 02 adotada como principal para refazer o cenário pelo PixelLab. |
| 2026-10-11 | Tentativas 04/05 não selecionadas; edição Pro recusada por limite. Entregues estudo derivado da referência 02 e prévia separada de 64 hexágonos pelo editor exato gratuito do PixelLab. Sem aprovação final, implementação ou teste no Godot. |
| 2026-10-11 | Usuário escolheu direção inicial de interface semelhante ao TFT pela referência 04: loja e itens na faixa inferior, sinergias à esquerda, vidas nos cantos superiores e fase/tempo no centro. Organização a refinar; textos, valores, juros, XP e regras da loja da imagem não foram adotados automaticamente. Referência preservada, sem geração ou implementação. |
| 2026-10-11 | Usuário confirmou personagens gratuitos desde o início, com ouro apenas para itens e capacidade. A compra inicial de personagens foi substituída; recrutamento inicial, reserva e renovação de ofertas precisam de regras. Documentados proposta de interface e estudo HTML técnico, sem novas gerações ou implementação Godot. |
| 2026-10-11 | Usuário reafirmou escolher 3–4 heróis iniciais, com número a decidir. Esclareceu loja conjunta: renovar traz itens e heróis gratuitos que podem ser incorporados ou ignorados. Proposta de abas removida; limite antigo de um recrutamento por rodada não adotado automaticamente neste fluxo. Custos, quantidades e reserva continuam pendentes. |
| 2026-10-11 | Usuário escolheu corações para vidas, cerca de 2 moedas para renovar a loja como valor de teste e autorizou criar personagens principais no PixelLab. Começado primeiro núcleo com Michael preservado, Caramelo, Zumbi e Obama; sem aprovação visual final ou gameplay implementado. |
| 2026-10-11 | Coração 16 × 16 criado gratuitamente no PixelLab e aplicado quatro vezes por lado. Zumbi novo concluído; Michael preservado. Caramelo e Obama bloqueados por falhas registradas, sem PNG. Entregues galeria e manifesto do núcleo; inspeção das demais direções, aprovação artística e gameplay continuam pendentes. |
| 2026-10-11 | Após pedido de refinamento/ampliação, Caramelo, Obama e Neymar foram gerados com sucesso. Zumbi ganhou frente refinada e nova base de oito direções por referência; Obama/Neymar receberam frentes com acessórios maiores. Galeria atualizada, originais preservados; ainda sem animações novas ou gameplay. |
| 2026-10-11 | Usuário definiu bola com ricochete do Neymar, mordida/sangramento/execução do Caramelo, direção de mala-escudo do Obama e lança/bônus coletivo/crescimento de críticos do Zumbi. Em resposta às perguntas, escolheu testar 3 impactos por chute e acúmulo alimentado somente pelos críticos do próprio Zumbi. Plano do primeiro protótipo documentado, com propostas técnicas separadas das regras escolhidas; nenhum jogo implementado nesta etapa. |

Nas próximas sessões: ler este arquivo, localizar a decisão relevante, executar somente o escopo autorizado, registrar mudanças reais e atualizar evidências. Não apagar dúvidas por conveniência nem apresentar hipóteses como escolhas do usuário.
