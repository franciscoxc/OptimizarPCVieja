@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Desfragmentar a fondo
:: =========================================================================
::  DESFRAGMENTAR A FONDO (opcional, para discos mecanicos)
::
::  El desfragmentador automatico de Windows trabaja "por encima" a
::  proposito: ignora los fragmentos de mas de 64 MB, porque Microsoft midio
::  que juntarlos casi no mejora la velocidad, y no junta el espacio libre.
::  Este script le pide el trabajo completo:
::    1. Analisis inicial.
::    2. Desfragmentacion completa (/W). Si Windows no la acepta, la normal (/D).
::    3. Consolidar el espacio libre (/X): los archivos nuevos se fragmentan menos.
::    4. Optimizar el arranque (/B): junta los archivos que Windows lee al prender.
::    5. Analisis final.
::  En un SSD no desfragmenta: solo manda TRIM (/L), que es su mantenimiento.
::  Puede tardar varias horas en un Atom con disco de 5400 rpm.
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

set "DISCO=%SystemDrive%"
set "MEDIO=desconocido"
for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$n=(Get-Partition -DriveLetter $env:SystemDrive.Substring(0,1)).DiskNumber; $d=Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$n } | Select-Object -First 1; if ($d) { [string]$d.MediaType } else { 'desconocido' }"`) do set "MEDIO=%%m"

cls
echo ==========================================================================
echo   DESFRAGMENTAR A FONDO - disco %DISCO%
echo ==========================================================================
echo.
echo   Tipo de disco detectado: %MEDIO%
if /i "%MEDIO%"=="SSD" goto :ssd
if /i not "%MEDIO%"=="HDD" echo   AVISO: no se pudo confirmar que sea un disco mecanico. Si es un SSD, cancela.
echo.
echo   Pasos: analisis, desfragmentacion completa, consolidar el espacio libre,
echo   optimizar el arranque y analisis final.
echo.
echo   - En un Atom con disco lento puede tardar VARIAS HORAS. Dejala enchufada.
echo   - Mientras tanto la PC va a andar lenta: mejor no usarla.
echo   - Se puede cortar en cualquier momento con Ctrl+C. No se rompe nada.
echo   - Conviene correr antes OptimizarPC.bat: vacia temporales y hay menos que mover.
echo.
choice /c SN /n /m "  Empezar? [S/N]: "
if errorlevel 2 exit /b 0

call :paso "1/5  Analisis inicial"
defrag %DISCO% /A /V

call :paso "2/5  Desfragmentacion completa, incluidos los fragmentos grandes"
defrag %DISCO% /W /H /U /V
if "%errorlevel%"=="0" goto :completa_ok
echo.
echo   Esta version de Windows no acepta la desfragmentacion completa (/W).
echo   Se hace la normal, que deja los fragmentos de mas de 64 MB como estan.
defrag %DISCO% /D /H /U /V
:completa_ok

call :paso "3/5  Consolidar el espacio libre"
defrag %DISCO% /X /H /U /V

call :paso "4/5  Optimizar el arranque"
:: Usa el mapa de arranque de la carpeta Prefetch. Si se vacio, Windows
:: tarda unos dias en rehacerlo y este paso no tiene con que trabajar.
defrag %DISCO% /B /H /U /V

call :paso "5/5  Analisis final"
defrag %DISCO% /A /V

echo.
echo ==========================================================================
echo   LISTO. Compara el porcentaje de fragmentacion del analisis inicial y del
echo   final. La optimizacion semanal automatica de Windows sigue activa.
echo ==========================================================================
pause
exit /b 0

:ssd
echo.
echo   Es un SSD: desfragmentarlo no lo acelera y le gasta escrituras.
echo   Lo que necesita es TRIM, que avisa al disco que bloques estan libres.
choice /c SN /n /m "  Mandar TRIM ahora? [S/N]: "
if errorlevel 2 exit /b 0
defrag %DISCO% /L /U /V
pause
exit /b 0

:paso
echo.
echo --------------------------------------------------------------------------
echo   %~1
echo --------------------------------------------------------------------------
goto :eof
