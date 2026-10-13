# Publicação de desempenho Web 01 — 2026-10-13

Publicação autorizada diretamente pelo usuário: “sim, pode, atualize o jogo!”. A entrega usa a fonte congelada que produziu a build revisada, mantendo cliente e servidor com o mesmo conjunto de regras. Mudanças posteriores da outra IA permanecem no workspace original para validação separada.

- Caches GPU de arena, grade, reserva, moedas e cartas; personagens/projéteis/VFX continuam por quadro. PNGs originais preservados.
- Atualização de UI por snapshot novo; recepção em lotes, cache negociado dos catálogos e snapshots agrupados por sala/quadro. Eventos/privacidade preservados.
- Buffer Web até1280×720 sem multiplicar por DPR. Diagnóstico Configurações/F3 com FPS, tempo de quadro e RTT; sem promessa de60FPS.
- Polling dedicado limitado a60Hz; simulação20Hz, snapshots10Hz. Inicialização humana não recebe compras/ready do bot.

Baseline local controlada:8–12FPS/105,48ms; versão revisada29–38FPS/31,40ms, mediana das oito janelas. Outra execução32–42FPS. Não é FPS público nem de celular físico. Dois renderizadores no mesmoPC ficaram14/15FPS: otimização ainda tem limites.

Validação da fonte congelada: cliente20/0, drag18/0, smoke488/0 headless e488/0 OpenGL, cache gráfico10/0; rede71/0 +21/0 +13/0 na investigação; landing/resizeDPR1/2:8/0. Logs/ZIPs completos preservados no workspace original. Recibo de hashes: `RelicArena/VALIDACAO_PERFORMANCE_WEB_01.json`.

A publicação mantém Vercel estático e Render Free/Oregon. Não altera plano/região nem consome PixelLab. `.dockerignore` exclui arte, cliente e ferramentas do contexto dedicado; seu entrypoint é `server/dedicated_server.gd`.

Pós-publicação: verificar SHA-256 do PCK e shell públicos, status do deploy Vercel, boot/handshakeWebSocket e pong com nonce sem entrar na fila pública. Não afirmar atualização só pelo push Git ouHTTP200.
