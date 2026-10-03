@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Limpiar restos de Windows Update
:: =========================================================================
::  LIMPIAR RESTOS DE WINDOWS UPDATE (opcional, de vez en cuando)
::
::  Cada actualizacion guarda la version anterior de lo que reemplaza, en
::  C:\Windows\WinSxS, por si hay que desinstalarla. Windows borra esas
::  versiones solo, pero recien a los 30 dias y con una tarea que se corta a
::  la hora de trabajo. Este script hace la limpieza completa con DISM, la
::  herramienta oficial:
::    1. Analiza el almacen de componentes (WinSxS) y dice si conviene limpiar.
::    2. Borra las versiones viejas (/StartComponentCleanup). Opcional:
::       /ResetBase, que libera mas, pero las actualizaciones ya instaladas no
::       se pueden desinstalar nunca mas.
::    3. Dice cuanto espacio libero.
::  No usa /SPSuperseded: limpia restos de Service Packs, y Windows 10 no tiene.
::  Libera espacio, no acelera la PC. En un Atom con disco mecanico puede
::  tardar mas de una hora.
:: =========================================================================

if not defined PROCESSOR_ARCHITEW6432 goto :arquitectura_ok
"%SystemRoot%\Sysnative\cmd.exe" /c ""%~f0""
exit /b
:arquitectura_ok

fltmc >nul 2>&1
if not errorlevel 1 goto :es_admin
echo Pidiendo permisos de administrador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }"
if not errorlevel 1 exit /b
echo.
echo  No se obtuvieron permisos de administrador.
echo  Hace clic derecho en el archivo y elegi "Ejecutar como administrador".
echo.
pause
exit /b 1
:es_admin

cls
echo ==========================================================================
echo   LIMPIAR RESTOS DE WINDOWS UPDATE
echo ==========================================================================
echo.
echo   Cada actualizacion guarda la version anterior de lo que reemplaza, por si
echo   hay que desinstalarla. Windows las borra solo recien a los 30 dias; este
echo   script lo hace ahora y completo, con DISM, la herramienta de Microsoft.
echo.
echo   - Libera espacio en el disco. No acelera la PC.
echo   - En un Atom con disco mecanico puede tardar MAS DE UNA HORA. Enchufala.
echo   - Mientras trabaja, NO la apagues ni la reinicies.
echo   - Si Windows pide reiniciar por una actualizacion, reinicia antes.
echo.
choice /c SN /n /m "  Empezar con el analisis? [S/N]: "
if errorlevel 2 exit /b 0

:: DISM trabaja con el Instalador de modulos de Windows. Si otra herramienta
:: lo deshabilito, vuelve a su valor de fabrica: Manual.
reg query "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v Start 2>nul | find "0x4" >nul
if errorlevel 1 goto :instalador_ok
sc config TrustedInstaller start= demand >nul 2>&1
if errorlevel 1 reg add "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo   [REPARADO] El Instalador de modulos de Windows estaba deshabilitado: vuelve a Manual.
:instalador_ok

call :paso "1/3  Analisis del almacen de componentes (WinSxS)"
Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore
if not "%errorlevel%"=="0" goto :error_dism
echo.
echo   Fijate en la linea que dice si se recomienda limpiar: si dice que no, no
echo   hay nada que valga la pena borrar.
choice /c SN /n /m "  Limpiar ahora? [S/N]: "
if errorlevel 2 exit /b 0
echo.
echo   /ResetBase libera mas espacio, pero las actualizaciones que ya estan
echo   instaladas no se van a poder desinstalar nunca mas. Las proximas, si.
echo   Si cuando hay problemas reinstalas Windows, no perdes nada.
set "RESETBASE="
choice /c SN /n /m "  Usar tambien /ResetBase? [S/N]: "
if not errorlevel 2 set "RESETBASE=/ResetBase"

call :paso "2/3  Limpieza de las versiones viejas"
call :libre LIBRE_ANTES
Dism.exe /Online /Cleanup-Image /StartComponentCleanup %RESETBASE%
if not "%errorlevel%"=="0" goto :error_dism
call :libre LIBRE_DESPUES

call :paso "3/3  Resultado"
set /a LIBERADO=LIBRE_DESPUES-LIBRE_ANTES
if %LIBERADO% LSS 0 set "LIBERADO=0"
echo   Espacio liberado: %LIBERADO% MB.
echo   La limpieza automatica de Windows sigue activa y se encarga del resto.
echo   Si vas a desfragmentar, ahora es el momento: hay menos que mover.
echo.
pause
exit /b 0

:error_dism
set "DISM_RC=%errorlevel%"
set "DISM_HEX=%DISM_RC%"
for /f "usebackq delims=" %%h in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "'0x{0:X8}' -f [int]$env:DISM_RC"`) do set "DISM_HEX=%%h"
echo.
echo   [!] DISM termino con el error %DISM_HEX%.
if /i "%DISM_HEX%"=="0x800F0806" echo       Hay una actualizacion esperando un reinicio.
echo       Lo mas comun: una actualizacion a medio instalar. Reinicia la PC, deja
echo       que Windows Update termine y volve a correr este script.
echo       El detalle queda en C:\Windows\Logs\DISM\dism.log.
echo.
pause
exit /b 1

:paso
echo.
echo --------------------------------------------------------------------------
echo   %~1
echo --------------------------------------------------------------------------
goto :eof

:: Espacio libre en el disco del sistema, en MB. Uso: call :libre VARIABLE
:libre
set "%~1=0"
for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[string][math]::Floor((Get-PSDrive -Name $env:SystemDrive.Substring(0,1)).Free / 1MB)"`) do set "%~1=%%m"
goto :eof
