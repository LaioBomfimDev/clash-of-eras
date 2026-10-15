# Publicação da pasta Godot — 2026-10-15

Pedido confirmado: procurar commits ainda não lançados e publicar tudo, deixando a produção equivalente ao projeto Godot atual.

## Estado encontrado

- `main` e `origin/main` em `24a7aa7`, sem commits locais à frente nem branches locais com commits exclusivos fora de main.
- Status Vercel do commit24a7aa7: sucesso, mas `release.json` público ainda identificava `web-fx-audio-20261014`, PCK SHA-256 `038807539094d151fc72497f8c7bcdb0a35fe702d6caec582894efe34e2ce31d`.
- Sete commits posteriores à última exportação runtime `c05588f`: `3cbfac3`, `0949122`, `49c3059`, `a7f5433`, `4ed253a`, `278af0a`, `24a7aa7`. Os commits tinham sido enviados, mas o deploy estático reutilizava a dist antiga.
- Além disso, havia alterações locais do painel DEV/transparência, restauração do mapa clássico, teste smoke e arquivos de animação Boss/Snoop não versionados, além de metadados de importação e UID.

## Entrega em preparação

Preservar o estado atual e gerar nova exportação Web pelo helper, incluindo F6 modernizado, mapa clássico aprovado, barra ornamental do Boss, movimentos Boss/Snoop e animações de16quadros. Corrigidos bloqueios reais do DEV detectados durante validação; ver histórico de bugs.

Exportador registra um manifesto de hashes de todos os arquivos de fonte/dados/arte, além de PCK, WASM, JS e mídia do lobby. Compara a fonte antes/depois e rejeita a exportação se algum arquivo mudar durante o processo. Nenhuma arte foi gerada e nenhum crédito foi consumido.

## Validação já executada

- Godot4.7.2: DEV79/0, smoke486/0, quatro partidas completas1036/0.
- Publicação, igualdade de arquivos públicos e teste do navegador ainda pendentes nesta versão do registro.

Os assets e regras do Godot serão iguais; diferenças de plataforma permanecem: vídeoMP4 no navegador, OGV no nativo, armazenamento de feedbacks local de cada plataforma. Atlas é ferramenta Python separada e não faz parte do runtime Godot exportado.
