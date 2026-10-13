# Inspeção do novo fundo — 2026-10-13

Escopo desta inspeção: somente leitura dos originais, extração de quadros para evidência e consulta técnica. Não houve modificação de código, asset do jogo, compra ou publicação.

## Arquivos recebidos

| Arquivo | Evidência |
| --- | --- |
| `C:/Users/m/Downloads/Reduzir_fogos_e_estrelas_no_20261013201616.mp4` | 3.782.948 bytes; 1280×720; 8,000 segundos; 24 FPS constantes; 192 quadros; H.264 High nível 3.1; pixel format yuv420p; bitrate de vídeo 3.632.703 bit/s. |
| Pista de áudio do MP4 | AAC LC, estéreo, 48 kHz, 128.402 bit/s. Existe som: volumedetect média −24,5 dB e pico −0,9 dB. Conteúdo sonoro não foi ouvido/classificado. |
| `C:/Users/m/AppData/Local/Temp/codex-clipboard-416af70e-a1c6-46f7-8529-c3f34c939e3d.png` | 3.372.083 bytes; 1672×941, próximo de 16:9. |

Metadados completos: `video_probe.json`. Quadros inspecionados: 0, 48, 96, 144 e 191 (0 s, 2 s, 4 s, 6 s e 7,958 s), em `video_contact_sheet.jpg`. Primeiro/último: `frame_first.png` / `frame_last.png`.

## Observação visual

- O vídeo mostra a mesma direção temática do PNG: coliseu dourado/roxo, logo central alto, céu estrelado, fogo e vórtice no chão.
- O PNG não é o primeiro quadro do vídeo. A imagem possui enquadramento diferente e logo proporcionalmente maior. A transição direta do PNG para o vídeo muda a composição; uma dissolução pode suavizar, mas não torna os enquadramentos idênticos.
- O clipe não é um ciclo visual perfeito: o vórtice do último quadro está mais largo e há deslocamento de enquadramento em relação ao início. `loop` simples traz um corte perceptível. A comparação global SSIM entre os extremos foi 0,231706; isso é um indicador de diferença, não nota de qualidade ou prova isolada de defeito.
- Não foram alterados o vídeo nem o PNG para corrigir essas diferenças.

## Recomendação técnica para avaliação

Na Web, usar o MP4 em um elemento HTML `<video>` atrás do canvas com transparência apenas no lobby. Isso permite ao navegador selecionar seu decodificador, inclusive aceleração quando disponível; não garante aceleração em todo aparelho. Proposta: `muted`, `playsinline`, `loop`, `pointer-events:none`, dimensões fixas e `object-fit:cover`, mantendo imagem estática independente atrás como fallback. Capturar rejeição de `play()` e erros de mídia. `preload` é apenas sugestão; iniciar o carregamento do vídeo quando o lobby realmente estiver ativo. [MDN video](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/video), [autoplay](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Autoplay).

Pausar explicitamente ao sair do lobby, na preparação e durante combate; só ocultar com CSS não estabelece que a mídia deixou de decodificar. Também pausar com `visibilitychange` quando a aba ficar escondida e retomar apenas se o lobby ainda estiver ativo. Não pausar a conexão multiplayer por causa do fundo. [Page Visibility API](https://developer.mozilla.org/en-US/docs/Web/API/Page_Visibility_API).

Godot 4.7 suporta Ogg Theora no núcleo, não MP4/H.264. `VideoStreamPlayer` teria de receber derivado `.ogv` no nativo. Theora é decodificado na CPU; a documentação alerta desempenho ruim desse nó na Web e recomenda até 720p/30 FPS ou menos em plataformas móveis/web. Por isso, não recomendo OGV dentro do WASM para este fundo. A opção nativa com OGV precisa ser medida separadamente e ficar restrita ao lobby. Não foi feita conversão OGV nesta inspeção. [Vídeos no Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/animation/playing_videos.html), [VideoStreamPlayer 4.7](https://docs.godotengine.org/en/4.7/classes/class_videostreamplayer.html).

A shell HTML pode ser personalizada; `Viewport.transparent_bg` existe para renderizar o fundo como transparente. A composição real precisa ser confirmada numa exportação, incluindo o fundo CSS do canvas/shell e saída do lobby. [Shell HTML Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/platform/web/customizing_html5_shell.html), [Viewport](https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-property-transparent-bg).

Uma dissolução de loop usando dois vídeos evita o corte, mas aumenta temporariamente o custo de decodificação. Alternativa inicial: manter um único vídeo e aceitar o corte, ou gerar posteriormente um derivado com a dissolução incorporada, preservando o original. Essa escolha ainda não é decisão do usuário.

Para desempenho, medir `getVideoPlaybackQuality()` / quadros descartados, FPS do jogo e pausa fora do lobby. `MediaCapabilities.decodingInfo()` pode auxiliar, mas seus resultados são estimativas e não substituem o teste real. [MDN Media Capabilities](https://developer.mozilla.org/en-US/docs/Web/API/MediaCapabilities/decodingInfo).

## Limites desta evidência

Não testei autoplay em aparelhos reais, compatibilidade móvel, FPS integrado, continuidade de áudio, decode por hardware nem exportação neste subtrabalho. Preservar os originais. Para o fundo silencioso, um derivado sem pista de áudio é uma possibilidade; não há decisão para substituir a música existente do lobby.
