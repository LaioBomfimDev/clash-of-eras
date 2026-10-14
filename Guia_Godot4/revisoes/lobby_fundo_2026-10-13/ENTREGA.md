# Novo fundo do lobby — entrega de 2026-10-13

## Decisão e implementação

O usuário forneceu PNG e MP4 e confirmou **lobby/menu inicial** como destino. A arena de combate continua com sua arte própria. Os originais foram preservados byte a byte; recibo em [ORIGEM.json](../../visuais/lobby_fundo_02/ORIGEM.json).

- Navegador: MP4 em camada HTML atrás do canvas transparente somente no lobby, sem áudio. Reprodução começa quando necessária e pausa ao entrar na partida, no modo econômico ou ao ocultar a aba. Retoma ao voltar ao menu. Preferência de movimento reduzido/economia de dados usa imagem estática; rejeição de autoplay ou erro de mídia também mantém a imagem e os controles.
- Godot nativo: VideoStreamPlayer com OGV separado, silencioso, pausado/oculto durante a partida; no modo econômico fica a imagem. Não há player de vídeo nos testes headless.
- Menu: logo da própria arte exposto, navegação inferior mantida, dicas em “Como jogar”. Removidas as partículas e brilhos extras do fundo antigo. Nenhuma regra de combate/economia foi alterada por esta integração.

Derivados: MP4 1280×720/24 FPS sem áudio, 2.256.893 bytes; poster WebP 536.628 bytes; OGV nativo 960×540/24 FPS, 2.695.324 bytes. Uma dissolução de 0,5 s foi incorporada ao derivado para suavizar o loop, usando um único decodificador durante a reprodução. PNG original 1672×941 intacto. A imagem tem enquadramento diferente do vídeo; ambos vieram do usuário.

## Validação executada

| Contexto | Resultado | Evidência |
| --- | --- | --- |
| Módulo DOM, Node/mock | 40 aprovadas, 0 falhas | [module_lifecycle.json](module_lifecycle.json) |
| Godot nativo, cópia isolada baseada em 999a37d | 10 aprovadas, 0 falhas; vídeo avançando, mudo e pausado ao jogar | [native_final_out.txt](native_final_out.txt), stderr vazio, [captura](native_lobby.png) |
| Regressão de desempenho do cliente, mesma cópia | 20 aprovadas, 0 falhas | [client_out.txt](client_out.txt), stderr vazio |
| Smoke do cliente, mesma cópia | 488 aprovadas, 0 falhas | [smoke_out.txt](smoke_out.txt), stderr vazio |
| Chrome real, Web da cópia isolada | 8 aprovadas, 0 falhas | [browser_delivery/browser.json](browser_delivery/browser.json) |
| Godot headless, pasta atual após publicação paralela 8f52072 | 7 aprovadas, 0 falhas | [current_headless_out.txt](current_headless_out.txt), stderr vazio |
| Chrome real, link público | 8 aprovadas, 0 falhas, sem erros de script | [public_browser/browser.json](public_browser/browser.json) |

Chrome público: vídeo mudo decodifica/avança; ECO pausa; sair do ECO retoma; entrar em partida local pausa/oculta; retornar ao menu retoma; movimento reduzido não solicita MP4; erro 404 induzido no MP4 mantém poster e controles. A comparação visual confirmou arena separada. Teste com viewport 1280×720/DPR2 e caso paisagem 844×390; **não é teste em celular físico**.

A amostra pública após aquecimento registrou 60 FPS, média 16,93 ms e p95 19,09 ms; ao retornar ao menu, 60 FPS/16,62 ms. O aquecimento inicial também está registrado (36 FPS nessa execução). Isso mede o lobby deste PC, não combate online, hardware decode nem todos os dispositivos. A preparação usada no teste foi contra bot local, com WebSocket redirecionado para localhost; não entrou na fila pública.

## Publicação observada

Enquanto a integração era validada numa cópia isolada, a outra IA publicou `8f5207276876213470e9bf3bf7938a0a26e9358c`, incluindo este fundo e mudanças anteriores de Boss/VFX. Essa publicação foi preservada; esta revisão não reenviou a cópia antiga nem atribui a si as mudanças paralelas de gameplay.

Vercel retornou **success** para esse commit. HTML, PCK, JS, MP4, WebP e release.json públicos foram comparados byte a byte com `dist/`: **todos iguais**. [Integridade](public_integrity.json), [script de conferência](verificar_publicacao.py). Render respondeu pong/nonce, RTT220 ms/handshake654 ms, sem entrar em fila: [probe](public_websocket.json). Isso verifica disponibilidade, não carga ou fluidez de combate.

**Limite do manifesto encontrado, com correção da auditoria de 2026-10-14:** `simulation_sha256` ainda era referência da entrega anterior. `server_sha256` identifica `net/online_server.gd` e estava correto; a comparação inicial com `server/dedicated_server.gd` usou o arquivo errado. A conferência de HTML/PCK/mídia é independente desses campos. Não usar o rótulo antigo `validated-frozen-runtime` como prova de que as novas mudanças paralelas passaram pela suíte anterior. O registro bruto inicial em `public_integrity.json` permanece preservado; a comparação incorreta do campo de servidor é explicada aqui. Não houve alteração desses metadados públicos na entrega do lobby.

## Repetição e retomada

Para exportar, usar `RelicArena/tools/export_web.py --godot CAMINHO_DO_GODOT --output CAMINHO_ABSOLUTO/index.html`; o helper inclui JS e mídia externa. O editor sozinho não copia esses arquivos. OGV excluído da Web; originais e fundo antigo permanecem preservados.

Testes: `RelicArena/tests/test_lobby_background.gd`, `RelicArena/tools/test_lobby_video_module.cjs` e `RelicArena/tools/test_lobby_browser.cjs`. Este último aceita pasta de evidências e URL; requer Playwright/Chrome configurados e usa somente bot local.

Automação contínua permanece pausada. Nenhum crédito PixelLab, compra, nova arte por IA, alteração de plano/hospedagem ou teste de aparelho físico nesta entrega.
