@echo off
setlocal
set "RELIC_DEV_GODOT=%USERPROFILE%\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%RELIC_DEV_GODOT%" (
  echo Godot nao encontrado no caminho configurado.
  echo Abra RelicArena\project.godot no Godot, execute o projeto com F5 e pressione F6 dentro do jogo.
  pause
  exit /b 1
)
start "Clash - Laboratorio DEV" "%RELIC_DEV_GODOT%" --path "%~dp0RelicArena" -- --devtools
