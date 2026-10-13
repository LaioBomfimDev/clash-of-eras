# Animações do Zumbi — produção 01

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
