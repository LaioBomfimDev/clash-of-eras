@echo off
rem Vitrine local e interativa; ESC fecha a janela. Nao inicia rede nem gera arte.
start "" "C:\Users\m\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe" --path "%~dp0." --script res://tools/preview_zumbi_animations.gd
