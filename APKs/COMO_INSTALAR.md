# Clash of Eras — APK de teste

Arquivo: **Clash_of_Eras_teste.apk**, gerado em 12/10/2026.

1. Envie o arquivo `.apk` para o celular por cabo USB ou como documento pelo aplicativo que você usa.
2. Abra o arquivo no celular. Se o Android pedir, permita que esse aplicativo instale aplicativos desconhecidos e toque em **Instalar**.
3. Abra **Clash of Eras**, use o celular deitado e toque em **JOGAR**.

É o protótipo local contra bot. Não precisa do Godot instalado no celular nem de internet para jogar. Requer Android 7 ou superior; o desempenho depende do aparelho. Contém ARM 32 bits, ARM 64 bits e x86_64 (emuladores). O ícone ainda é o padrão do Godot.

Pacote: `com.clashoferas.prototipo`; versão `0.1.5-teste` (código 1). Assinado para depuração, destinado a teste por instalação direta.

## Reproduzir a exportação neste PC

O preset **Android Teste** está em `RelicArena/export_presets.cfg`. A configuração inclui os JSONs usados em tempo de execução e exclui testes, ferramentas e capturas. `project.godot` habilita a importação ETC2/ASTC exigida pelo exportador.

```powershell
& 'C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:/Users/m/Documents/Relic Arena MY/RelicArena' --export-debug 'Android Teste' 'C:/Users/m/Documents/Relic Arena MY/APKs/Clash_of_Eras_teste.apk'
```

O modelo Android de depuração 4.7.2 está instalado em `%APPDATA%/Godot/export_templates/4.7.2.stable`. Foi extraído do pacote oficial via HTTPS e conferido por tamanho e CRC32. JDK 17 e SDK Android locais estão configurados nas preferências do editor; nenhuma chave de assinatura foi copiada para o projeto.

Referência: [exportação Android na documentação oficial do Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

O APK entregue foi gerado de uma cópia congelada em `%LOCALAPPDATA%/ClashOfErasBuild/source-20261012`, para evitar misturar alterações simultâneas. Uma nova exportação do projeto atual pode conter mudanças feitas posteriormente por outras sessões.
