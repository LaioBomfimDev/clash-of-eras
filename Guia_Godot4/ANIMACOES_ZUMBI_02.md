# Zumbi — expansão de direções, 2026-10-13

## Entrega atual

**Caminhada e estocada integradas em quatro direções: leste, oeste, nordeste e noroeste.** Inspiração tem dois clips, leste/oeste. A escala de exibição anterior continua: Zumbi N1 a76px de referência, humanos a68–70px; nenhum PNG reduzido. São64 PNGs únicos ativos,45 a mais que o piloto leste. Original, exportação e rejeições preservados.

| Ação | Direções reais | Reprodução / registro |
| --- | --- | --- |
| Caminhada | E, W, NE, NW | E/W9quadros30FPS; NE/NW7quadros24FPS; ciclos de ~0,3s |
| Estocada | E, W, NE, NW | Seis posições20FPS; contato visual50ms após evento, recuperação sem mudar dano/cadência |
| Inspiração | E, W | Cinco originais em dez posições14FPS, ergue punho e volta |
| Pose de combate | E, W, NE, NW | Sem pedra/chão; não reaparece o retrato estático entre ações |

Nas diagonais, o gesto coletivo sem mira pode virar deliberadamente para leste. **Isso não é um clip de habilidade NE/NW.** Ataques usam somente a direção realmente disponível. Continuam faltando SE/SW/N/S e lâminas animadas específicas N2/N3. A vitrine mostra essas lacunas em vez de inventar frames.

- **Oeste:** 15 PNGs novos nativos e seis receitas exportados gratuitamente. Todos15 são espelhos RGBA exatos dos originais; os quatro quadros restantes da estocada oeste já estavam no ZIP oficial e também são espelhos exatos. Importados, integrados e capturados por eventos reais; três ações verificadas.
- **Caminhada NE/NW:** job `d4dfef86-99bb-4b44-9d47-426db6edeb9f`, grupo `f6b1fec6-9ed4-4dac-a2c5-23777e66afa6`, sete quadros, custo3. Todos originais vistos: braços/pernas alternam e não há pedra. Os pés derivavam de144 a153px; o editor gratuito registrou os sete na base145 e criou NW por espelho.14/14 comparações RGBA confirmam todos os pixels visíveis preservados. Âncora fixa `[64,145]`, sem correção variável em runtime. Integrados e capturados no cliente.
- **Pose NE de combate:** `31328260-9b6d-4172-bdcc-2c8e506a9c9a`, custo1. Editor gratuito removeu610pixels de chão dourado com cores/posições guardadas, preservando pés/correntes. Imagem limpa `6c291d95-70ee-4924-ae2b-d5846abebab7`; cópia NE e espelho NW integrados com âncora `[64,118]`.
- **Estocada NE/NW:** job `5ca53ce7-5004-4c9e-8eca-d733e1fc681d`, grupo `625c3f1b-30d0-4bfe-ae89-aec1b9394679`, custo3; cinco originais176×196 vistos individualmente, uma lança diagonal, braço direito estende de verdade. Todos cinco espelhos NW também vistos e conferidos RGBA. Pose inicial é idêntica à pose limpa colada em `[8,50]`; âncoras NE`[72,168]`, NW`[104,168]`. Contato no quadro003; ordem de reprodução`[2,3,4,2,1,0]`. Exportados/importados e ambos ataques capturados por eventos reais.

## Estudos de pose e decisões de produção

Contato NE v1 `5140cbfc-3c1b-4082-bd21-31ea3193500f` (custo1) rejeitado: pouca extensão, ponta desce em vez de avançar. O editor ampliou só o canvas128→160, colando a mesma pose em`[0,32]`, sem escalar o corpo. Contato v2 `90d0bd9b-dc94-4911-b6e0-0ba9a167b698` (custo1) rejeitado: braço estende, mas a lança vira horizontal. Contato v3 `bf4febf4-4601-4fc0-87bf-bab20e913d1f` (custo1) inspecionado e usado: braço/lança para o alto à direita, pés plantados. Não gerar de novo essas três poses nem usar as duas rejeitadas.

Pose inicial NE `f7ac1531-0985-4c85-ab27-a76553d400e1` custou1. Removeu a pedra mas manteve uma perna erguida: serve como referência de passada, não como pose neutra.

Exportação oficial da caminhada NE: `RelicArena/assets/characters/zumbi/animacoes_02/exports/walk_ne_01`; ZIP98arquivos/0divergências, oito vistas iguais aos inputs; SHA256 `67c9cc6d5e2ff6d59cb3c714c4ae22ba380b9ad10c3c52c7428c748f7639d1ff`. Outros clips no ZIP incluem estudos históricos.

Exportação oficial da estocada NE: `RelicArena/assets/characters/zumbi/animacoes_02/exports/attack_ne_01`; ZIP103arquivos/0divergências, oito vistas iguais aos inputs; SHA256 `0f6ecb9ecd6fb40c367ae5979c25f2bdca22a1a5708b63ac83c30db13d80362f`.

Recibos: `visuais/animacoes_zumbi_01/west_free_exports.json`, `west_rgba_audit.json`, `ne_walk_register_exports.json`, `ne_walk_rgba_audit_final.json`, `ne_attack_rgba_audit.json`. Credenciais pelo helper oficial, sem chaves nos arquivos. Limite do editor retornado: oito vistas por chamada, respeitado em lotes; validações recusadas não iniciaram IA. Desenhos NW ataque: `a19cc967-6528-4a62-92ac-bc0a7562ad99` e`6f433dda-d59d-4152-a176-6a683ce0acb5`.

## Validação e próximo lote

Godot4.7.2: importação com saída0; banco122/0, player97/0 e integração30/0. São fixtures do sistema de apresentação, não provas de balanceamento. Três sessões isoladas do cliente real (W/NE/NW) capturaram caminhada, estocada e inspiração via eventos reais da simulação; NE/NW inspiração usam o clip leste já existente. Nove capturas de ação, mais vitrines W/NE, saídas0; imagens inspecionadas. Nenhuma mudança nos sete arquivos monitorados durante os testes finais. Desde a janela oeste/NE anterior, somente o manifesto mudou nesses arquivos. Não executado teste de celular físico/rede nesta entrega.

[Registro e hashes](../RelicArena/VALIDACAO_ANIMACOES_ZUMBI_02.json). [Saídas dos comandos](revisoes/animacoes_2026-10-13/lote02_test_outputs.json). Um erro de indentação na ampliação da vitrine foi corrigido/retestado, BUG-022 no histórico. Abrir `RelicArena/Testar_animacoes_Zumbi.cmd`; setas trocam direção, P pausa,1–3 inspecionam escala por nível. Esta vitrine é uma ferramenta; os clips também estão ligados ao jogo.

Checkpoint em `checkpoints/Zumbi_animacoes_02_2026-10-13.zip`, com recibo SHA256/inventário ao lado: dados, PNGs ativos, ZIPs oficiais, código de apresentação e evidências desta entrega. É um snapshot parcial para recuperação/revisão, não uma distribuição independente do jogo. Nenhuma restauração automática sobre arquivos de outra IA.

**Nenhum job pendente desta fila. Saldo consultado final:1 restante/38 usadas/total40/US$0/trial**, recibo`saldo_lote02_final.json`; esta expansão consumiu11 gerações retornadas pelo serviço. Não comprar créditos nem tentar gerar clips que exigem mais que o saldo. Próximo: preparar SE/SW e lâminas N2/N3, completar direções conforme capacidade; depois animações dos demais heróis existentes. Não redesenhar Zumbi aprovado nem restaurar estocadas v1/v2 e inspiração v1 rejeitadas.
