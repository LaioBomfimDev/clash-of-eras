# Origem das imagens do laboratório

Registro cumulativo. As seções antigas abaixo descrevem as entregas anteriores; **o lote03 de 2026-10-12 gerou novas artes**, documentadas ao final. ZIPs e PNGs originais são preservados.

Cópias locais de imagens já produzidas/observadas pelo PixelLab. Nenhuma geração nova nesta entrega. O manifesto e a inspeção de arte permanecem em `Guia_Godot4/visuais/personagens_lote_02.json` e arquivos relacionados.

| Arquivo | Origem dentro de `Guia_Godot4/visuais/` |
| --- | --- |
| `neymar.png` | `personagens/neydrama/revisao_02/south.png` |
| `caramelo.png` | `personagens/caramelo/south.png` |
| `obama.png` | `personagens/obamuralha/revisao_02/south.png` |
| `zumbi.png` | `personagens/zumbalhao/revisao_02/rotacoes/south.png` |
| `heart.png` | `ui/vida_coracao.png` |

Os quatro personagens anteriores usam frentes estáticas a 1×, filtro nearest e alinhamento dos pés pela área alfa. A uniformização final das proporções continua pendente.

## Michael — exportação original, 2026-10-11

O usuário pediu aproveitar todas as imagens existentes e escolheu cura de aliados próximos com pulsos de dança. O pacote foi obtido pela ferramenta nativa `get_character` e pelo URL de exportação oficial devolvido por ela, sem gerar imagens, sem chave nos arquivos e sem consumir créditos de geração.

- Personagem: `8e001e18-9617-4a67-a326-32af26dc4f24`; estado adicional: `c0d687db-d402-46a8-a2a8-500635e56329`.
- `michael/pixellab_original.zip`: exportação PixelLab 3.1, 137305 bytes; SHA-256 `78EBE8A8936F3991DE869963765E85E1B5EA5DAE29F2E62BDFAED08573643555`.
- `michael/original/`: 88 PNGs intactos e `metadata.json`. São **72 quadros de moonwalk, nove em cada uma das oito direções**, mais oito rotações de cada um dos dois estados.
- Os quadros de dança têm canvas 60 × 60 ou 64 × 64, conforme direção; o personagem visível continua aproximadamente na escala dos sprites anteriores. Não esticar cada canvas até um tamanho comum.
- `michael/manifest.json`: caminhos originais, 10 quadros/s como teste e âncora fixa por direção. A âncora é calculada uma vez usando todos os quadros daquela direção, preservando a oscilação da dança; não realinhar a cada quadro pela área alfa.

O ZIP e os PNGs não foram editados. O manifesto é configuração de apresentação, não uma animação gerada nova nem evidência de qualidade final. O arquivo anterior em `Guia_Godot4/visuais/personagens/michael_existente/` foi preservado.

O chão, a grade, as linhas de ataque e os indicadores desenhados pelo código são instrumentos temporários de teste, não arte final do jogo. IDs técnicos e nomes exibidos são separados, para facilitar a troca de referências e assets.

## V1.1 — arena, retratos e ícones, 2026-10-11

- `arena/coliseu_estudo_02.png`: cópia byte a byte de `Guia_Godot4/visuais/arena_referencia_limpa_02.png` (SHA-256 `0230386C5CA0ADFF21B3C2AE2BCA72A7F23C1902729EAA822009F94BB995469F`, 351 × 195). É o fundo limpo derivado da referência 02 enviada pelo usuário, editado gratuitamente no PixelLab; continua **estudo não aprovado como arte final**. O jogo o desenha a 4× inteiro e recorta a moldura original das bordas.
- Retratos da loja, do cartão e do resultado são recortes em tempo de execução (`AtlasTexture`) das frentes já existentes. Nenhum PNG novo de personagem foi gravado.
- `ui/icons/*.png`: 21 ícones 16 × 16 desenhados por código (inclui a bola `fx_ball`, desenhada pixel a pixel, e a estrela `ui_star` tingida por nível) em `tools/gerar_icones.py` (sinergias de teste, itens do laboratório e interface). São provisórios, sem PixelLab e sem créditos; a arte final da interface continua prevista no PixelLab.
- Tabuleiro, reserva no chão, barras, anéis, ondas de escudo e painéis translúcidos são desenhados pelo código e também são provisórios.

## Lote03 realista — 2026-10-12

Pedido explícito do usuário: continuar artes no PixelLab em proporções reais como Michael, sem caricatura. Foram criadas **nove bases, oito direções cada: 72 PNGs novos**. Não são animações de ataque/caminhada. O Michael mantém 72 quadros de dança e 16 rotações, sem nova geração.

| Chave | ID PixelLab |
| --- | --- |
| Neymar | `291232c3-888e-4f25-89c4-c81820353189` |
| Obama | `d0c3bcfa-e7ee-4f64-aa3c-ce5e72a3fe78` |
| Barbie | `8cce0cc9-9e8f-4a0c-bddf-69fa85fabbdd` |
| Ken | `6ee036bc-198c-42dc-93a5-f2083142861f` |
| Elon | `8634c766-2b2f-4166-961b-1ea182b56419` |
| Snoop | `80bd8c1a-4f93-4fa7-a4e6-a85eeb8dc556` |
| Lula | `2436503e-0400-44cf-9edf-4f16366eb29e` |
| Bob Marley | `b7d93d38-f6e1-44e1-b663-746f0b01ac88` |
| Rapunzel | `6820ab38-635e-4d0d-8e78-231af6cf37ec` |

Parâmetros standard: tamanho pedido 48, oito direções, `low top-down`, detalhe alto, sombra média, contorno seletivo e preset `realistic_male` ou `realistic_female`. A API adicionou padding: canvas 68 × 68. Corpos visíveis têm em geral49–54px; a arma do Elon amplia o limite em algumas direções. Michael inclinado tem aproximadamente 41–43px. Âncoras usam os pés; PNGs não foram esticados nem recortados em disco.

Cada pasta `characters/<chave>/realista_03/` contém ZIP oficial, `original/` e `exportacao.json` com ID, URL oficial, SHA-256 do ZIP e quantidade de PNGs. `characters/manifest.json` seleciona essas versões; antigos arquivos continuam preservados. As 96 poses da galeria de direções incluem as nove bases novas, Caramelo/Zumbi antigos e a referência Michael.

**Integridade executada:** `tools/verificar_originais.ps1` comparou nove ZIPs com seus recibos e todos os 81 arquivos extraídos (72 PNGs + nove metadados) com as entradas ZIP: zero alterações. Relatório `captures/integridade_lote_03.json`. Inspeção visual das oito direções e galeria renderizada pelo Godot em `captures/lote_03_direcoes.png` e `captures/lote_03_elenco.png`.

**Mapa:** `arena/braseiro.png`32 × 48 transparente, objeto PixelLab `f9e42bec-c4b1-45ee-8299-a080200c0f1b`, download oficial `/mcp/map-objects/<id>/download`. SHA-256 `AC68112E711BAE4F84989FFAD8475E62CAF4E3E3D9CD0C288AAB16E4B612C446`. O mesmo original aparece em quatro pontos definidos em `arena/props.json`, fora da grade. Não é uma arena inteira nova; fundo anterior preservado.

**Limite real:** saldo MCP final 0 gerações/$0. Tentativa de Caramelo natural recusada sem ID; Caramelo e Zumbi continuam provisórios até saldo disponível. Nenhum crédito comprado ou plano alterado. Fila em `Guia_Godot4/EXECUCAO_CONTINUA.md`, diário em `Guia_Godot4/visuais/personagens_lote_03_execucao.json`.

## Efeitos no editor gratuito — 2026-10-12

Criados pelo `vfx_workbench` determinístico do PixelLab, documentado pelo serviço como gratuito, sem geração por IA. Quatro game packs oficiais preservados; não houve compra, alteração de plano ou nova geração de personagens. Inventário completo em `vfx/manifest.json`, com IDs de edição/exportação, FPS, recortes e SHA-256.

| Efeito | ID salvo em My effects | Clip empacotado |
| --- | --- | --- |
| Escudo da dança | `23968870-beb2-442e-bbea-1cc8593fc21a` | 12 quadros, 43 × 43, 10 FPS, loop |
| Cura | `bdb4529f-f006-4df7-aa7f-b8257d577e08` | 11 quadros, 19 × 23, 16 FPS |
| Estocada | `38643174-7945-4ff4-811e-6ff0cb4be9ca` | 7 quadros, 24 × 6, 24 FPS |
| Impacto de foguete | `2476a6cd-b5d9-4a04-8deb-9b9458d1465d` | 11 quadros, 26 × 26, 24 FPS |

Todos os quadros foram revisados. `vfx/INTEGRIDADE.json`: quatro ZIPs (23.920 bytes), CRC/caminhos seguros e hashes válidos; 18 arquivos extraídos (27.167 bytes) idênticos às entradas dos ZIPs, zero divergências. Cura/foguete têm 12 quadros no canvas original; o pacote omite o último transparente e recorta a margem. Quarenta e quatro recortes RGBA desses dois efeitos correspondem ao original.

Os clips selecionados contêm somente o efeito. `escudo_danca_01/original/whole-with-sprite.png` inclui Michael para referência e não deve ser usado como efeito no jogo. Preservar os PNGs e respeitar os offsets dos manifestos. Preparar a biblioteca e testar sua aplicação ao cliente são evidências separadas; estado da integração em `vfx/manifest.json` e `Guia_Godot4/EXECUCAO_CONTINUA.md`.

**Integração posterior concluída na V1.3:** os quatro clips são lidos por `client/vfx_library.gd`, sem modificar seus originais. Biblioteca com 61 verificações aprovadas; cliente com 321 headless e 321 OpenGL, zero falhas. Duas capturas reais inspecionadas; regras de dados/simulação preservadas. Registro em `VALIDACAO_V1_3.json`.

## Segundo lote de efeitos gratuitos — 2026-10-12

Fumaça do Snoop e nó do laço da Rapunzel feitos no mesmo editor determinístico gratuito, sem geração por IA. Exportados pelos URLs oficiais retornados pelo PixelLab, com ZIPs e atlas originais preservados. Todos os quadros foram inspecionados pelo produtor; as duas folhas exportadas também foram vistas na revisão de integração. Arte aceita para teste local, sem aprovação final do usuário.

| Efeito | ID salvo em My effects | Clip empacotado | Recibo |
| --- | --- | --- | --- |
| Névoa baixa | `76cb7b84-c9d2-484f-8847-c1e56b6a166b` | `part-fumaca`, 16 quadros, 29 × 7, 10 FPS, loop | `vfx/fumaca_01/ORIGEM.json` |
| Nó de corda | `40e143b2-5dac-43ed-8c68-b8892fccfb69` | `part-laco`, 11 quadros, 24 × 15, 16 FPS, sem loop | `vfx/laco_01/exportacao.json` |

A fumaça tem pixels opacos e buracos transparentes; não possui alfa parcial. Seu canvas original é 37 × 16, com offset empacotado (-13, -3). O laço tem canvas 32 × 28/12 quadros; o pacote omite o último transparente, preservando os 11 restantes e offset (-12, -8). A corda longa que liga Rapunzel ao alvo continua sendo apresentação dinâmica no Godot. Os originais não foram redimensionados ou pintados fora do PixelLab. Integração e testes são registrados separadamente no manifesto/checkpoint.

**Integração V1.4 concluída:** os dois efeitos acompanham zonas/alvos reais, com limpeza e privacidade verificadas; fio alinhado após BUG-017. Auditoria separada `vfx/INTEGRIDADE_V1_4.json`: 196 verificações, zero falhas, oito arquivos extraídos idênticos e 54 recortes RGBA. Biblioteca 88/0, cliente 370/0 headless e OpenGL; duas capturas vistas. Dados/simulação iguais à V1.3; originais intactos. `VALIDACAO_V1_4.json` reúne a evidência final.

