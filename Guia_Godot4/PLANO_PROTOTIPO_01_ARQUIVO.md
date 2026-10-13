# Plano do primeiro protótipo jogável

Atualização: 2026-10-11, America/Sao_Paulo.

**Estado:** plano solicitado pelo usuário, sem implementação ou testes de gameplay executados. A referência de decisões permanece [CEREBRO.md](CEREBRO.md). As etapas, organização de código e detalhes marcados como proposta são recomendações para começar, não regras finais aprovadas.

## 1. Primeiro resultado que queremos jogar

Dois jogadores no mesmo PC, cada um em sua janela, conectados a um terceiro processo que funciona como servidor dedicado local. Cada jogador posiciona uma equipe de teste na arena inclinada de 64 hexágonos; o servidor começa o combate automático, calcula os quatro kits, encerra a rodada e informa o resultado aos dois clientes.

**Proposta de recorte inicial:** Neymar, Caramelo, Obama e Zumbi, com quatro unidades por lado em uma formação de teste espelhada. Isso permite comparar posicionamento e habilidades. Não decide definitivamente entre três ou quatro heróis iniciais, não reduz o deck final de dez e não estabelece a capacidade máxima do jogo.

Usar as imagens já disponíveis do PixelLab, inicialmente estáticas, com pés alinhados e escala revisável. Bola, indicadores de sangramento, escudo e crítico devem ser legíveis. Animações completas e refinamento das demais direções virão depois; esta proposta não exige consumir novas gerações para testar regras.

**Proposta:** criar uma base nova e pequena em `RelicArena/`, dentro do workspace. O repositório sugerido anteriormente não foi adotado nem avaliado nesta etapa; não há conclusão sobre sua qualidade. Os guias e manifests históricos permanecem preservados.

## 2. O que está definido nos quatro kits

| Personagem | Decisão do usuário | Identidade que vamos testar |
| --- | --- | --- |
| Neymar | Chutes repetidos à distância, velocidade de ataque como foco; ricochete entre dois inimigos próximos. **Testar três impactos: A → B → A.** | Carry que pune agrupamento; separar a equipe adversária é uma resposta candidata. |
| Caramelo | Mordidas, sangramento por segundo e supermordida para eliminar alvo com 10% de vida. | Assassino que finaliza alvos feridos; proteger a retaguarda deve importar. |
| Obama | Tanque usando a mala grande para se proteger; funcionamento aberto. | Frente que compra tempo para os carries; absorção é a primeira proposta de teste. |
| Zumbi | Estocadas; bônus de crítico e velocidade de ataque para a equipe; críticos fortalecem o próximo crítico. **Somente seus próprios críticos alimentam esse aumento.** | DPS corpo a corpo que fortalece aliados e cresce durante a luta. |

Essas identidades e respostas são hipóteses de balanceamento, não evidência de que o time esteja equilibrado. Bônus de personagem e sinergias de composição são sistemas separados.

### Contratos propostos para programar os kits

**Neymar**

- Cada ataque cria uma bola identificável, com intervalo de ataque, velocidade de voo e dano configuráveis.
- Ao atingir A, escolher B entre inimigos próximos de A; depois tentar retornar a A. No máximo três impactos. Sem vizinho elegível, somente A recebe o golpe.
- Proposta: manter esse par por bola, sem procurar um terceiro inimigo. Validar vida e distância antes de cada ricochete; encerrar se a condição deixar de existir.
- Como há movimento livre, proposta de medir a distância atual entre unidades no chão lógico, usando a distância entre centros de hexágonos como referência ajustável. A inclinação visual não altera o alcance.
- Ricochete é continuação do projétil, não um novo ataque. Cada impacto ocorre após tempo de voo positivo; todas as bolas são encerradas no fim da rodada.
- Pendentes: dano igual ou reduzido nos retornos, alcance, voo, críticos por chute ou por impacto e comportamento se Neymar morrer enquanto a bola voa.

**Caramelo**

- Proposta: dano direto de mordida e sangramento de duração finita. Mordidas do mesmo Caramelo renovam a duração sem acumular dano indefinidamente; múltiplas fontes precisam de política própria.
- Proposta de execução inicial: ao acertar uma mordida válida, verificar a vida atual **antes do dano normal**; com vida maior que zero e menor ou igual a 10% da vida máxima, aplicar a supermordida. Sangramento isolado não executa à distância.
- Isso é uma interpretação de teste do limiar mencionado, ainda não uma regra fechada. Se uma mordida baixar o alvo de 11% para 9%, nessa proposta ele só será executado pela próxima mordida válida.
- Pendentes: interação com escudo/invulnerabilidade, duração e dano do sangramento, permanência após morte da fonte e como o assassino alcança o alvo. Acesso à retaguarda não implica teleporte aprovado.

**Obama**

- Proposta inicial: mala gera escudo temporário de absorção; o escudo recebe o dano antes da vida, e dano excedente passa para a vida. Capacidade, duração e recarga ficam em dados editáveis.
- Bloqueio frontal, provocação e reflexão são alternativas futuras, sem aprovação. Primeiro verificar se absorção produz uma frente interessante.
- Pendentes: momento de ativação, proteção contra dano físico/mágico, escudo próprio ou coletivo e números. Não interpretar automaticamente a mala como imunidade.

**Zumbi**

- Separar o bônus coletivo de crítico/velocidade do crescimento de seus próprios críticos. O bônus coletivo inclui o próprio Zumbi.
- Proposta de crescimento inicial: incremento aditivo sobre o multiplicador base de crítico, com teto configurável. O crítico atual usa o bônus acumulado e só depois aumenta o bônus do próximo crítico elegível. Ataques normais não alimentam nem zeram o contador.
- Reiniciar o contador por rodada é proposta de teste. Críticos de aliados, sangramento e eventos visuais não o aumentam.
- Pendentes: valor e teto do incremento, duração do bônus coletivo, acumulação com outra cópia do Zumbi e persistência após sua morte. A permanência das sinergias após mortes não resolve automaticamente essa última dúvida.

## 3. Ordem de implementação e entregas verificáveis

| Etapa | O que construir | Como saber que terminou |
| --- | --- | --- |
| 1 — Arena no Godot | Projeto mínimo, apresentação 2D inclinada, 8 × 8 hexágonos, quatro fileiras por lado, imagens existentes, vida e quatro corações por jogador. Seleção e reposicionamento na preparação. | Abrir a cena e reposicionar uma unidade somente em casa válida do próprio lado; pés, seleção e grade correspondem. A mesma unidade não ocupa duas casas. |
| 2 — Servidor e dois clientes | Processo dedicado local, conexão de dois jogadores, comandos de formação e estado filtrado para cada cliente. | Duas janelas recebem as mesmas fases públicas; servidor não ocupa vaga de jogador. Alterações atuais do adversário não chegam ao cliente durante a preparação. |
| 3 — Combate básico | Movimento automático, aquisição de alvo, alcance, intervalo de ataque, dano físico/mágico, defesas, vida, crítico e morte. | Servidor executa uma rodada sem depender de sprites; os dois clientes representam os mesmos eventos e resultado. FPS da janela não define velocidade de ataque. |
| 4 — Quatro kits | Bola A → B → A, mordida/sangramento/execução, mala-escudo experimental e bônus/críticos pessoais do Zumbi. | Cenários controlados abaixo demonstram cada mecânica e seus limites; valores mudam pelos dados, sem reescrever a habilidade. |
| 5 — Ciclo de partida | Preparação → combate → resultado; limite de 30 s, aceleração aos 15 s, quatro vidas e reinício limpo por rodada. | Os dois clientes veem a mesma perda de coração e fim de partida. Projéteis, sangramento, escudos e acúmulos antigos não vazam para a nova rodada. |
| 6 — Loja e composição | Loja conjunta com heróis gratuitos e itens pagos, renovação inicial por 2 moedas, capacidade paga, saldo guardado e primeiros itens/sinergias. | Compra nunca deixa saldo negativo; comando repetido não cobra/concede duas vezes. Escolhas de capacidade, itens e formação produzem efeitos observáveis. |

A preparação de 30–45 s continua como referência. Multiplicador de aceleração, efeitos acelerados e desempate completo precisam de regra explícita na etapa 5. Proposta: relógio de encerramento em tempo real do servidor, mesmo com ataques acelerados; dano efetivo retirado da vida para desempate, excluindo excesso. Isso ainda não é decisão final sobre escudos ou empate exato.

Antes da etapa 6, fechar limites de recrutamento por oferta/renovação, repetição de heróis, descarte, reserva e destino dos itens equipados. Número de ofertas, ouro inicial, renda, custos de expansão, atributos e receitas permanecem hipóteses. Não importar juros, XP ou compra de personagens da referência visual de TFT.

O primeiro teste visual pode acontecer na etapa 1; o primeiro combate dos quatro kits exige concluir a etapa 4. Não precisamos de coleção, pagamentos ou todas as animações para chegar lá.

## 4. Estrutura técnica proposta

| Parte | Responsabilidade |
| --- | --- |
| `data/` | Resources tipados de personagens, habilidades, itens, sinergias e regras de teste. Dados base não são alterados durante o combate. |
| `simulation/` | Estado por unidade, posições, relógios, alvos, projéteis, efeitos, dano e resultado. Regras executáveis sem interface. |
| `server/` | Sessão, autoridade, validação de comandos, privacidade e envio dos estados/eventos. |
| `client/` | Arena, sprites, interface, toque/mouse e apresentação dos eventos recebidos. |
| `tests/` | Cenários de regras, reprodução por semente e verificações de rede pertinentes a cada etapa. |

Escolhas recomendadas: GDScript tipado, Resources para configurações estáticas, estado separado para cada unidade e ENet para o primeiro teste local. Recursos carregados podem ser compartilhados pelo Godot; vida, escudo e acúmulos não devem ficar no Resource base compartilhado. [Documentação oficial de Resources](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html).

O servidor calcula movimento, alcance, ataques, críticos, sangramento, escudos, economia e resultado. O cliente envia intenções como posicionar, comprar ou renovar; não envia dano ou saldo como verdade. A API de multiplayer do Godot oferece ENet e RPCs; seus exemplos de lobby precisam de adaptação porque o servidor dedicado não é jogador. [Multiplayer oficial](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html).

O mesmo projeto pode ter entradas separadas para cliente e servidor. Para testes locais, o executável Godot 4 pode rodar sem janela com `--headless`; um binário especial de servidor não é necessário. A inicialização do modo servidor deve ser explícita para não confundir testes headless com servidor de partida. [Servidores dedicados](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html).

### Contratos de simulação e rede

- Proposta: passo fixo de simulação, inicialmente 30 atualizações por segundo, independente da taxa de desenho. Medir antes de decidir frequência de transmissão ou limite de carga.
- Movimento calculado no chão lógico e depois projetado na tela. Hexágonos definem a preparação; combate com movimento livre não implica caminhos obrigatoriamente presos a casas.
- Cada comando recebe ID e validação de remetente, jogador, fase e limites. Repetição não repete seu efeito.
- Cada ataque, projétil e efeito recebe ID. Resolver eventos simultâneos em ordem estável e registrar essa ordem; morte ocorre uma única vez por unidade.
- Gerar acerto, crítico e escolhas aleatórias no servidor com semente registrada. Guardar versão de regras e entradas; reprodução é critério a verificar no ambiente fixado, não promessa de igualdade de floats entre todas as plataformas.
- Separar mensagens públicas e privadas. Na preparação, enviar ao adversário apenas a formação anterior autorizada; ocultar elementos na interface não basta se o estado atual já foi transmitido.
- No protótipo, desconexão pode suspender/encerrar a sessão de teste com aviso explícito. Punição competitiva e reconexão não são regras aprovadas.

## 5. Validação a executar durante a programação

Os casos abaixo estão **planejados, não executados**. Importar o projeto e conferir erros de scripts antes de rodar verificações headless; o executor de testes precisa encerrar com código de falha explícito quando um critério falhar.

| Cenário | Evidência esperada |
| --- | --- |
| Neymar contra A e B vizinhos; depois separados | Sequência A → B → A com no máximo três impactos; sem terceiro alvo; condições de distância verificadas durante o ricochete. |
| Neymar com velocidade de ataque elevada | Cada chute tem um único projétil; ricochetes não geram ataques extras; fila encerra ao terminar a rodada. |
| Caramelo contra alvos com 100 de vida máxima e 11, 10 ou 9 atuais | Execução segue exatamente a fronteira e o momento escolhidos; na proposta, 10 e 9 executam, 11 recebe dano normal. |
| Sangramento renovado e alvo morto | Duração/acúmulo respeitam a regra escolhida; sem execução duplicada nem dano efetivo atribuído após morte. |
| Obama com escudo 20 recebe dano 30 | Na proposta de absorção, escudo zera e vida perde 10; escudo e vida não ficam negativos. Valores são fixture, não atributos finais. |
| Zumbi com sequência controlada de crítico/normal/crítico | Somente seus críticos aumentam o contador; ataque normal preserva; segundo crítico usa incremento esperado. Crítico de aliado não alimenta. |
| Fim e reinício de rodada | Sem projétil ou efeito residual; contadores reiniciam conforme contrato; sinergias da formação mantidas durante a rodada apesar de mortes. |
| Comandos repetidos ou inválidos | Sem compra, renovação ou movimento duplicado; nenhuma ação fora da fase ou do jogador autorizado. |
| Preparação privada | Inspecionar payloads: cliente adversário não recebeu a formação atual, mesmo que sua interface pudesse ocultá-la. |
| Reprodução de rodada e troca de lados | Mesma versão, semente e entradas reproduzem eventos; lados trocados ajudam a detectar favorecimento de ordem. |
| Servidor e dois clientes | Resultado, vida e eventos relevantes coincidem; queda de FPS em uma janela não altera o relógio do servidor. |

Registrar bugs reais em [HISTORICO_DE_BUGS.md](HISTORICO_DE_BUGS.md) com reprodução, investigação, causa sustentada, mudança e validação. Dúvidas e fraquezas de balanceamento continuam como decisões/hipóteses, sem inventar defeitos.

## 6. Balanceamento depois do combate funcionar

Testar primeiro níveis iguais e configurações conhecidas; isso é controle do experimento, não decisão de normalizar todo o PvP final. Progressão das cartas fora da partida continua em aproximadamente 5–6% por nível até 10, com fórmula e aplicação competitiva abertas.

Primeiras comparações propostas: Neymar com inimigos agrupados/espalhados; Caramelo com acesso livre/protegido ao carry; Obama contra dano concentrado/prolongado; Zumbi em lutas curtas/longas. Depois comparar uma composição de carry único e suportes com uma de dois carries dividindo recursos.

Medir dano efetivo, absorção, tempo vivo dos carries, tempo para primeira morte, sobreviventes e duração da luta. Só então adicionar primeiros grupos de sinergia e itens que alterem velocidade, crítico, defesa física ou resistência mágica. Patamares de sinergia variam por grupo, o maior substitui o menor e a morte não remove o bônus daquela rodada, conforme decisões do cérebro.

Uma composição forte precisa de uma resposta acessível por posição, equipamento ou composição. Não declarar equilíbrio a partir de uma partida nem assumir que vender progressão se torna justo sem definir como os níveis participam do PvP.

## 7. Primeiro passo prático para a próxima implementação

Criar `RelicArena/project.godot` e a cena inicial da arena; importar cópias dos PNGs existentes, configurar exibição em paisagem e seleção/reposicionamento em hexágonos. O guia para o usuário deve explicar como importar o projeto no gerenciador do Godot e executá-lo com F6 (cena) ou F5 (projeto), com uma ação verificável por vez.

Ao concluir essa entrega, adicionar a entrada do servidor e conectar duas janelas de cliente. Não é necessário que o usuário instale outra engine ou aprenda todo o editor antes desse primeiro teste.

**Evidência desta etapa de planejamento:** cérebro e histórico consultados, skills de GDScript/Resources/Multiplayer/testes headless lidas e documentação oficial consultada. A busca atual por `project.godot`, `.gd` e `.tscn` no workspace não encontrou um projeto novo. Nenhuma arte foi gerada, nenhum crédito do PixelLab foi consumido, nenhum servidor foi iniciado e nenhum teste de combate foi executado para produzir este plano.
