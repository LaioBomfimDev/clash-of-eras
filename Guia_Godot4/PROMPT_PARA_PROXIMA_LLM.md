# Copie esta mensagem para a próxima LLM

Quero criar **Xadrez Auto Battler**, um jogo próprio em **Godot 4**, começando
um projeto editável do zero. Encerramos uma tentativa anterior de modificar
um cliente compilado de Relic Arena. Agora quero aproveitar nossas regras e
decisões, com uma arquitetura limpa dentro do Godot.

Leia `GUIA_COMPLETO.md`, `DADOS_DO_JOGO.json` e `LAYOUT_REFERENCIA.svg`.
Se precisar de precisão, consulte `referencias/src/` e os testes correspondentes.
Há distinções explícitas entre regras existentes, pedidos, propostas e pendências;
não apresente uma ideia discutida como uma funcionalidade já implementada.

É um auto battler offline contra bots, inspirado na dinâmica do TFT: loja aberta
com cinco ofertas, economia, cópias/fusão automática, sinergias, equipamentos,
preparação por arraste e combate automático. Campanha inicial de 15 encontros,
em três capítulos com três equipes rivais e dois encontros de mobs em cada um.
Jogador começa com 100 de vida e 12 moedas. Campo de até seis peças; reserva
fixa de oito vagas. Chão quadrado de sete colunas por oito linhas. Uma casa
por unidade viva, com reserva do destino ao caminhar. Alcances 1, 2 ou campo inteiro.
Vida base 50 para dano/cura, 80 para tanque; ataque começa em 1 e sobe por
estrelas/itens. Juros de uma moeda por dez guardadas, sem teto de cinco.

Quero o HUD aberto: sinergias/itens à esquerda, tabuleiro no centro, atributos
e venda à direita, reserva e loja embaixo, rodada/vida/ouro em cima. Não quero
abas para recrutar/equipe/sinergias, NPC ditando ações, balões longos nem UI
antiga por trás. Prefiro arrastar peças entre campo, reserva e venda, com
clique como alternativa. Ícones, cores e textos legíveis; animações e números
de dano claros. O cenário deve ser leve: chão/decoração estáticos, sem água
animada ou fogo/partículas contínuas, mantendo os personagens animados.

O caminho visual discutido foi 2D com sensação de profundidade/2.5D e possível
pixel art. Trate isso como ponto de partida sugerido, não arte final já aprovada.
Comece com formas/sprites provisórios coerentes, separando arte das regras.
PixelLab é uma opção futura; não exige serviço de IA durante o jogo.

Existe um personagem futuro pedido: Michael Jackson, suporte que não ataca,
dança e faz moonwalk para esquerda/direita por três a quatro casas livres.
A cada dois segundos fornece escudo e cura de 10% da **própria vida máxima**
a todos os aliados vivos, além de aumentar curas de outras fontes. O percentual
desse aumento e as regras de empilhamento/duração do escudo estão pendentes.
Não invente esses valores como aprovados. Preserve a ideia no backlog e use
flags/componentes que comportem suporte sem ataque.

Implemente por etapas verificáveis: estado e grade → loja/equipe/arraste/venda
→ fusão/economia/itens/sinergias → combate → campanha → save → polimento.
O primeiro marco deve ser jogável com arte provisória; não entregue somente
um menu ou um cenário bonito. Preserve os números da base até registrar
uma mudança deliberada. Não invente XP, estoque compartilhado, carrossel,
sete rivais persistentes, multiplayer ou mobile como requisitos atuais.

Use uma única fonte de estado, dados de personagens separados, ações atômicas,
IDs estáveis, simulação determinística independente da interface e testes das
regras. Não use física para empurrar os personagens para as casas. Salve a
campanha localmente com recuperação de arquivo; não dependa de rede/conta.
Não transporte offsets, DLLs, protocolos de diálogo nem o launcher antigo.

Quero economizar tokens e focar em mudanças concretas. Faça escolhas rotineiras
sem pedir confirmação toda hora, documente as suposições e só pergunte sobre
decisões que alterem o produto. Até nova orientação, não abra o jogo antigo
nem inicie partidas para confirmar; prefira inspeção e testes automatizados.
Não afirme validação visual ou desempenho real quando só houver testes de lógica.

Antes de escrever arquivos, identifique a pasta do **novo projeto Godot** e a
versão 4.x instalada. Se isso não estiver disponível, peça somente essa informação.
Não continue editando a instalação antiga. Esta mensagem é um prompt para o
próximo trabalho; o pacote atual ainda não contém um projeto Godot.
