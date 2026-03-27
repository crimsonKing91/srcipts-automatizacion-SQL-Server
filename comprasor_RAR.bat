@echo off
setlocal enabledelayedexpansion

:: Ruta de WinRAR (ajústala si es necesario)
set "winrar=C:\Program Files\WinRAR\WinRAR.exe"

:: Directorio donde está el script
set "sourceDir=%~dp0"

:: Verificar si WinRAR existe
if not exist "%winrar%" (
    echo Error: WinRAR no está instalado o la ruta es incorrecta.
    pause
    exit /b
)

:: Comprimir cada archivo .bak en un .rar separado
for %%F in ("%sourceDir%*.bak") do (
    set "fileName=%%~nF"
    "%winrar%" a -ep -r "%sourceDir%!fileName!.rar" "%%F"
    echo Archivo %%F comprimido en !fileName!.rar
)

echo Proceso terminado.
pause
