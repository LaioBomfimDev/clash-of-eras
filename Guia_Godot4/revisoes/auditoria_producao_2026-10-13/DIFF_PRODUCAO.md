# Diff Vercel × pasta Godot — 2026-10-14

Auditoria iniciada em13/10 e concluída em14/10, por solicitação do usuário: procurar mudanças que ficaram fora da produção e fazer commit de tudo. Automação contínua permanece pausada.

## Comparação comprovada

O HTML, PCK e release.json públicos conferiram byte a byte com a dist anterior de `8f52072`: [Vercel antes](vercel_before.json). O diretório PCK foi parseado e todos os hashes MD5 de suas2139entradas conferidos. Os métodos compilados e os17clips VFX foram carregados num projeto vazio, sem recorrer à pasta original: [runtime](exportacao/runtime_library_pack.json).

| Conteúdo | Estado encontrado | Entrega desta revisão |
| --- | --- | --- |
| Bob: notas, impacto reggae, buff/debuff e aura | Já presente no PCK público e conectado ao desenho | Preservado; arte detalhada existente64px passa a ser usada |
| Snoop: charuto, fumaça verde de cintura, folhas e atmosfera | Já presente no PCK público | Preservado; folha detalhada existente64px passa a ser usada |
| Prévia do Snoop no compêndio | Ainda desenhava fumaça lilás e deixava o efeito sair do palco | Tom verde unificado e recorte ao palco; capturas antes/depois preservadas |
| Lula: asas, auréola e descida; Boss: fogo, aura e teleporte | Já presentes na fonte e PCK | Preservados; corrigida triangulação da asa esquerda do Lula |
| Seis músicas Bob/Snoop de35s | MP3 importados presentes no pacote, mas loader procurava arquivos fonte ausentes | Loader corrigido; seis faixas carregam no export |
| Michael sem faixa | Flag de cantor ativada mesmo sem música, suprimindo SFX | Sem faixa, os efeitos sonoros continuam elegíveis |
| Compêndio Galeria/Ficha, pesquisa e cards | Mudança paralela ainda sem commit, posterior a8f52072 | Preservada, testada e incluída; quatro técnicas e maestria marcadas como estudo |
| Biblioteca `referencias_futuras/` e atalho | Referências locais sem commit | Versionadas como referências; não são novos personagens/regras do runtime |
| Seis WAV duplicados |7.483.920bytes de samples sem uso pelos loaders | Excluídos apenas da exportação Web; originais preservados |

Não foi encontrada omissão de campos no transporte de zonas/unidades de Bob/Snoop. A presença de um efeito no pacote não garante que apareça em toda fase/posição; os gatilhos normais continuam valendo. Não foi inventada uma causa de rede para efeitos ausentes.

## Diff do pacote candidato

PCK anterior24.365.580bytes; candidato final16.894.828bytes: **7.470.752bytes a menos (30,7%)**. Isso é redução do PCK, não do tamanho total de WASM+mídia.

[Diff por entrada](pack_diff.json):2123entradas idênticas,4alteradas (main/audio compilados, cena compilada e cache deUID),12removidas (seis samplesWAV e seis metadados). Nenhum PNG original, MP3 importado, regra de economia, simulação ou transporte removido/alterado no PCK nesta revisão. Os dois PNG64 já estavam no pacote; agora têm referência ativa. [Propagação para pasta original](propagacao.json).

O helper `tools/export_web.py` passa a gerar release.json com hashes reais da fonte, HTML/PCK e mídia externa. O campo de servidor continua apontando para `net/online_server.gd`; o entrypoint dedicado tem campo próprio. A referência de simulação do manifesto antigo estava desatualizada. A comparação inicial do registro do lobby com o entrypoint errado foi corrigida na documentação, preservando a evidência bruta.

## Testes executados nesta revisão

- Regressão no PCK público anterior:10aprovadas/19falhas esperadas; no PCK candidato final: **29/0**, incluindo seis faixas carregadas/loop35s, faixa inexistente, controle de áudio e texturas64. [Baseline](exported_baseline.json), [candidato final](exported_final.json).
- Fonte:23/0 para recursos exportáveis; áudio106/0, desempenho do cliente20/0 e VFX237/0. [Logs](testes/runners.json).
- Smoke **488/0 headless e488/0 OpenGL**, cache gráfico10/0 OpenGL; logs finais sem erros. [Regressões finais](testes_finais/runners.json). O runner de cache não suporta headless; a tentativa inicial foi rejeitada por sua guarda e foi repetida com renderizador real.
- Lobby Galeria/Ficha31/0 após incorporar a atualização paralela do runner; **32/0** após verificar também o recorte da prévia: [log final](testes_finais/lobby_refined_out.txt). Falhas iniciais de dimensões antigas/preview em galeria e rótulo do botão eram expectativas antigas, preservadas nos logs.
- Chrome real:8/0 para lobby, ECO, saída/retorno de partida contra bot, redução de movimento e fallback de mídia: [browser](browser/browser.json). Novas telas de compêndio têm capturas e console sem erros em `compendio_final/`; capturas anteriores em `compendio/` mostram a fumaça lilás/fora do palco, posteriormente corrigida.

Testes de pacote comprovam carregamento de recursos, não reprodução audível por alto-falantes, equilíbrio ou experiência em aparelho físico. Não foram geradas artes nem consumidos créditos PixelLab. Fonte anterior e dist foram preservadas em `checkpoints/producao_2026-10-13/` antes das alterações. Logs brutos também preservados em ZIP nesse checkpoint; quebras de linha dos logs textuais foram normalizadas para revisão no Git.

## Commit e publicação

Usuário autorizou commit geral e já havia autorizado atualizar o jogo. **Commit geral `c05588f9cf9b237a77a1ab9677602632dfbc7b79` publicado e conferido na Vercel.** Inclui fonte validada, build, documentação, testes e referências locais; caches/ZIPs/checkpoints ignorados continuam locais. HTML/PCK/release/JS/MP4/WebP públicos iguais à dist; galeria e fichas Bob/Snoop abriram no Chrome público sem erros. Render respondeu pong (RTT384ms, handshake11.687ms), sem entrar na fila. [Recibo final](PUBLICACAO.json). O commit posterior do recibo/documentação não muda o runtime validado.
