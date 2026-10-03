@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Deshacer lo perjudicial del script original
:: =========================================================================
::  DESHACER PERJUDICIALES
::  Deshace SOLO lo que el script original "Optimizador Extremo" (v1) hacia
::  mal en PCs con 2 GB de RAM y disco mecanico. Lo que estaba bien se deja:
::  telemetria, Xbox, Bluetooth y los ajustes de NTFS siguen como estaban.
::
::  No hace falta correrlo si vas a usar OptimizarPC.bat: ya lo incluye.
::  Detalle y fuentes de cada punto en README.md.
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

set "_mm=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

cls
echo ==========================================================================
echo   DESHACER LO PERJUDICIAL DEL SCRIPT ORIGINAL
echo ==========================================================================
echo.
echo   Esto va a:
echo    1. Volver a activar SysMain y la compresion de memoria.
echo    2. Devolver el teclado tactil: sin el no se puede escribir en el Inicio.
echo    3. Reparar Delivery Optimization para no romper Windows Update, y
echo       apagar su P2P de la forma correcta.
echo    4. Volver DisablePagingExecutive a 0.
echo    5. Volver la biometria a Manual, por si la PC tiene lector de huellas.
echo    6. Borrar los placebos IOPageLockLimit y DontVerifyRandomDrivers.
echo.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 exit /b 0
echo.

:: 1. SysMain: maneja la compresion de memoria. Con 2 GB de RAM, comprimir en
::    RAM es mucho mas rapido que paginar a un disco mecanico.
sc config SysMain start= auto >nul 2>&1
sc start SysMain >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue" >nul 2>&1
echo   [OK] SysMain en Automatico y compresion de memoria activada.

:: 2. TabletInputService: en Windows 10 actual, de el depende escribir en el
::    menu Inicio, en Configuracion y en las apps UWP. Valor de fabrica: Manual.
sc config TabletInputService start= demand >nul 2>&1
sc start TabletInputService >nul 2>&1
echo   [OK] Servicio de teclado tactil en Manual, su valor de fabrica.

:: 3. Delivery Optimization: deshabilitado puede romper Windows Update. Vuelve
::    a su valor de fabrica, Automatico retrasado, y el P2P se apaga con la
::    politica oficial, que era lo que buscaba el script original.
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DoSvc" /v DelayedAutostart /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
echo   [OK] Delivery Optimization reparado, sin compartir actualizaciones por P2P.

:: 4. DisablePagingExecutive=1 fija el kernel en RAM; con poca memoria eso
::    empuja a tus programas al disco. Valor de fabrica: 0.
reg add "%_mm%" /v DisablePagingExecutive /t REG_DWORD /d 0 /f >nul 2>&1
echo   [OK] DisablePagingExecutive en 0.

:: 5. Biometria: deshabilitada rompe Windows Hello con huella. En Manual no
::    gasta nada si no hay lector.
sc config WbioSrvc start= demand >nul 2>&1
echo   [OK] Biometria en Manual, su valor de fabrica.

:: 6. Placebos: Windows los ignora. Se borran para no dejar basura.
reg delete "%_mm%" /v IOPageLockLimit /f >nul 2>&1
reg delete "%_mm%" /v DontVerifyRandomDrivers /f >nul 2>&1
echo   [OK] IOPageLockLimit y DontVerifyRandomDrivers borrados.

echo.
echo   Se dejan como estaban, porque estaban bien: telemetria, Xbox, Bluetooth,
echo   mapas, ubicacion, Retail Demo, NTFS y CompactOS desactivado.
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC. Usa "Reiniciar", no "Apagar".
echo ==========================================================================
choice /c SN /n /m "  Reiniciar ahora? [S/N]: "
if errorlevel 2 goto :fin
shutdown /r /t 10 /c "Reiniciando para aplicar las correcciones"
exit /b 0
:fin
pause
exit /b 0
