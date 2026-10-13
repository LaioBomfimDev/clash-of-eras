@echo off
setlocal
set "GAME_GODOT_EXE=C:\Users\m\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
if not exist "%GAME_GODOT_EXE%" (
  echo Godot nao encontrado no caminho usado neste PC.
  echo Abra project.godot pelo Godot e pressione F5.
  pause
  exit /b 1
)
start "" "%GAME_GODOT_EXE%" --path "%~dp0."
exit /b 0
