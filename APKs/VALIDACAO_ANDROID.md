# Validação do APK — 12/10/2026

**Entregue:** `Clash_of_Eras_teste.apk`, 87.240.679 bytes (87,2 MB), Godot `4.7.2.stable.official.ed1daf0bf`. SHA-256: `3E91A9E2AD7697F61DF7218772B01A7082743F7A9748530935D6803C7EB743C9`.

## Evidência confirmada

- Exportação de depuração terminou com saída 0. Assinatura Android verificada por `apksigner`: esquemas v2 e v3 válidos. Integridade ZIP conferida: 710 entradas, nenhuma entrada corrompida.
- Manifesto: pacote `com.clashoferas.prototipo`, versão `0.1.5-teste`/1, SDK mínimo 24 (Android 7), alvo 36, bibliotecas ARM32, ARM64 e x86_64; sem permissão de internet.
- JSONs de atributos, personagens, Michael, cenário e todos os efeitos presentes no pacote. Testes e ferramentas não foram empacotados.
- Instalação no emulador Android API 36.1 concluída com `Success`, tanto usando SwiftShader quanto GPU do PC. Abertura pelo alias `com.godot.game.GodotAppLauncher` retornou `Status: ok` e o jogo registrou `CLIENT_READY` e fase `menu`.
- A tela inicial foi renderizada no emulador com GPU do PC, visível atrás de uma janela de erro do **System UI do Android**. Isso não confirma interação jogável completa.
- Na cópia congelada do código: lobby 27/0, arrastar 17/0, efeitos 157/0 e quatro partidas automáticas 668/0 (aprovadas/falhas). Esses testes rodam no PC, não no Android.

## Limitações e problemas observados

- O teste geral existente do cliente (`client/smoke.gd`) registrou **352 aprovadas e 6 falhas**, além de um erro de acesso a chave no próprio runner. Falhas: posição do nó da corda; capacidade/moedas; compra de capacidade máxima; custo de renovação; inspeção de inimigo; renda. Não foi investigado se cada divergência é bug de gameplay ou teste desatualizado durante as alterações simultâneas. Nenhuma dessas falhas foi corrigida nesta exportação; não afirmar suíte integralmente aprovada.
- No emulador com SwiftShader, shaders excederam o limite de uniforms do renderizador. Com GPU do PC, o menu renderizou, mas o Android apresentou repetidos travamentos do **System UI**, limitando os toques e capturas. O emulador foi iniciado sem áudio; Godot também registrou erro do driver OpenSL. Não houve validação de som, desempenho, arrasto, combate ou partida completa em Android.
- Exportador informou ausência de ícone próprio e utilizou o padrão do Godot. Isso não impediu exportação, assinatura ou instalação.
- Nenhum celular físico foi conectado/testado. O APK é para o teste manual solicitado, não uma versão qualificada para publicação.

## Alterações desta entrega

Preset Android em `RelicArena/export_presets.cfg` e importação ETC2/ASTC em `RelicArena/project.godot`; configuração do JDK 17 no editor e instalação do modelo oficial Android de depuração. Nenhuma regra, arte ou script do jogo alterado nesta entrega.

Snapshot usado: `%LOCALAPPDATA%/ClashOfErasBuild/source-20261012`. Hashes de fontes e logs selecionados em `validacao/`. O snapshot não incorpora edições posteriores de outras sessões. Comando de reprodução e instalação em `COMO_INSTALAR.md`.
