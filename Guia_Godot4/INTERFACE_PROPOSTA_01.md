# Interface de preparação — proposta 01

Data: 2026-10-11, America/Sao_Paulo.
Estado: proposta de fluxo e estudo técnico, atualizada para loja conjunta; não é implementação Godot nem arte final.

Referência principal: [layout enviado pelo usuário](visuais/referencias/arena_interface_referencia_usuario_04.png).
Fonte de decisões: [CEREBRO.md](CEREBRO.md).
Estudo navegável local: [interface_estudo_01.html](visuais/interface_estudo_01.html).

## Decisão confirmada nesta conversa

Personagens são gratuitos desde o início. O jogador usa moedas para itens e capacidade da equipe; na atualização mais recente, também escolheu renovar a loja por cerca de 2 moedas como valor inicial de teste. Isso substitui a intenção anterior de pagar personagens na primeira preparação e a hipótese de renovação por 3 moedas.

O usuário esclareceu que começa escolhendo três ou quatro heróis para construir a base da equipe e das sinergias; o número exato segue aberto. Ao renovar a loja, vêm itens e personagens do deck juntos. O jogador decide se incorpora algum herói oferecido ou ignora a oferta. Essa loja conjunta substitui a proposta inicial de abas separadas.

Gratuito define o custo; não significa acesso imediato aos dez personagens, escolha ilimitada ou recrutamento ilimitado. A origem das escolhas iniciais e a quantidade recrutável por renovação/rodada precisam ser definidas. O antigo limite de um herói por rodada não foi confirmado para este novo fluxo. Crescer a formação não confirma evolução individual por estrelas ou duplicatas.

O preço inicial de renovação é cerca de 2 moedas, a ajustar depois de observar o jogo funcionando. Personagem gratuito não significa renovação gratuita. Disponibilidade, limite de renovações e quantidade de personagens recrutáveis continuam pendentes; não tratar o preço de teste como balanceamento concluído.

## Organização da tela

| Área | Conteúdo | Estado |
| --- | --- | --- |
| Superior esquerdo | Própria equipe e quatro corações de vida. | Direção escolhida |
| Superior direito | Adversário e quatro corações de vida; acesso ao histórico autorizado. | Direção escolhida; acesso por toque proposto |
| Superior central | Rodada, preparação/combate e relógio. | Direção escolhida; tempo inicial exato pendente |
| Lateral esquerda | Sinergias com contagem e patamar; detalhes por toque. | Direção escolhida; interação proposta |
| Centro | Campo hexagonal 8 × 8, quatro fileiras por lado. | Confirmado |
| Inferior esquerdo | Bolsa de itens. | Direção escolhida; tamanho pendente |
| Inferior, ao lado da bolsa | Atualizar a loja conjunta e ampliar equipe. | Renovação conjunta confirmada; posição proposta |
| Inferior, faixa principal | Ofertas de itens com preços e heróis marcados “Grátis”, visíveis juntos. | Loja conjunta confirmada; distribuição visual a refinar |
| Acima das ofertas | Moedas e equipe em campo/capacidade. | Proposta de conteúdo |

O botão “Ampliar equipe” aumenta o limite de unidades em campo. Não altera o nível da carta fora da partida. “Comprar XP”, juros e progressão de TFT não foram incorporados.

## Fluxo proposto da loja

### Recrutamento gratuito

1. Na primeira preparação, escolher três ou quatro heróis gratuitos para iniciar a formação, conforme a regra inicial que vier a ser fechada.
2. Depois, consultar as cartas de heróis que aparecem junto dos itens a cada renovação da loja.
3. Tocar numa carta abre função e sinergias; decidir se quer incorporar o herói, sem pagar moedas pelo personagem.
4. Respeitar o limite de recrutamento que vier a ser definido e a capacidade de campo. A oferta pode ser ignorada.

Origem das escolhas iniciais, repetição, acesso ao carry, quantidade de recrutamentos e destino de uma unidade com o campo cheio estão pendentes. Não descartar, vender ou substituir automaticamente. Renovar intencionalmente atualiza itens e heróis; ainda é preciso decidir quantos heróis podem ser escolhidos antes/depois de cada renovação.

### Itens

1. Na mesma loja, selecionar uma oferta de item para consultar preço, efeito e receitas conhecidas.
2. Selecionar uma oferta para ver detalhes; comprar somente com saldo e espaço válidos.
3. O item entra na bolsa; selecionar o item e a unidade mostra a aplicação pretendida.
4. Confirmar ou cancelar a aplicação. Capacidade de itens e incompatibilidades devem aparecer antes de confirmar.

Compras não são executadas no estudo HTML. Quantidade de ofertas e espaços da bolsa nele são marcadores visuais.

### Capacidade

Mostrar “Equipe: unidades em campo / capacidade”, próximo ao saldo. Ao tocar em “Ampliar equipe”, informar custo e novo limite antes da compra. Custos 12, 14 e 16 são hipóteses anteriores; nenhum preço final foi escolhido.

## Toque e informações de combate — propostas

Na loja, diferenciar ofertas pelo rótulo “Item” com preço e “Herói · grátis”, além de forma/ícone. A renovação é única para ambos. A proporção de ofertas não foi decidida; os dois itens e dois heróis do HTML são exemplos, não uma regra.

- Selecionar unidade, destacar casas permitidas e tocar no destino. Arrastar pode ser alternativa; nenhuma ação essencial deve depender apenas de mouse sobre um elemento.
- Seleção visível e cancelamento simples. Comportamento de casas ocupadas e troca entre unidades ainda precisam ser definidos.
- Sinergias abrem uma ficha com efeito, membros e próximo patamar. Um grupo de exemplo não atribui automaticamente uma sinergia a alguém.
- Adversário abre “Formação da rodada anterior”, identificando a rodada. Na primeira rodada, indicar ausência de histórico. Não mostrar mudanças atuais da preparação nem presumir acesso aos itens privados.
- Proposta para combate: recolher compras e recrutamento para ampliar a leitura da arena. Manter vidas, relógio e sinergias visíveis. A disponibilidade de compras durante combate ainda não foi decidida.
- Espaço para benefício/habilidade ativa depende da regra que vier a ser escolhida. Não adicionar botão de intervenção funcional por antecipação.

## Celular em paisagem

O estudo permite comparar molduras 16:9 e 20:9. São proporções ilustrativas, não resoluções finais ou prova de compatibilidade. A moldura não simula tamanho físico, recortes da tela ou área segura de um aparelho real.

Propostas: textos curtos, detalhes por toque, lista lateral recolhível, alvos amplos, indicação de seleção por texto e forma além da cor. O conjunto deve ser medido com sprites, fontes e controles reais antes de fechar tamanhos.

## Limites do estudo entregue

- HTML independente, sem Godot, rede, sorteio real, economia ou persistência.
- Usa o fundo já editado no PixelLab, o ícone de coração e as prévias sul de Michael, Zumbi, Caramelo, Obama e Neymar; PNGs originais permanecem intactos. A [galeria dos personagens](visuais/personagens_lote_01.html) permite comparar os refinamentos frontais de Zumbi/Obama/Neymar. Os dois últimos ainda precisam desses acessórios nas demais direções.
- Painéis HTML/CSS e polígonos são marcações técnicas de layout. A arte final da interface continua prevista no PixelLab.
- A seleção de painéis e a troca de fase servem para revisar a proposta. “Atualizar loja” alterna entre três conjuntos fixos de exemplos, sem sorteio real ou cobrança. Selecionar uma carta mostra uma explicação; não concede personagens ou itens.
- Quatro cartões e seis espaços de bolsa são exemplos de distribuição, não regras aprovadas.
- Sintaxe e arquivos locais serão conferidos. Renderização, toque e interação em navegador/dispositivo ainda não estão validados.

## Próximas decisões que alteram a tela

1. Fechar três ou quatro heróis iniciais e a origem das escolhas; definir frequência/limite de recrutamento na loja conjunta, respeitando o deck de dez.
2. Campo cheio: existência de reserva, acesso às unidades fora de campo e descarte.
3. Renovação conjunta: mistura de ofertas, disponibilidade e limites; testar o custo inicial de 2 moedas e ajustar conforme os resultados.

