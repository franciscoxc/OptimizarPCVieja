@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Revertir OptimizarPC v2
:: =========================================================================
::  REVERTIR OPTIMIZARPC v2
::  Vuelve a los valores de fabrica de Windows 10 todo lo que OptimizarPC.bat
::  cambia y que podria molestar: servicios, apps en segundo plano, efectos
::  visuales, Explorador, energia, navegadores, recortes de Defender y tareas.
::
::  A proposito NO revierte:
::   - La seguridad reparada: firewall, UAC, DEP, SmartScreen, Defender,
::     Windows Update y reproduccion automatica apagada.
::   - Las correcciones del script original: SysMain, teclado tactil, etc.
::   - Telemetria, publicidad y sugerencias: no rompen nada.
::   - Las apps desinstaladas: se reinstalan desde la Store.
::  Para volver EXACTAMENTE a como estaba todo, usa el punto de restauracion
::  "Antes de OptimizarPC v2" con rstrui.exe.
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

:: Usuario de la sesion abierta (dueno del explorer.exe de esta sesion)
set "USID="
set "UNAME="
for /f "usebackq tokens=1,2 delims=|" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(Get-Process -Id $PID).SessionId; $p=Get-CimInstance Win32_Process -Filter 'Name=''explorer.exe''' | Where-Object { $_.SessionId -eq $s } | Select-Object -First 1; if ($p) { $o=Invoke-CimMethod -InputObject $p -MethodName GetOwner; $i=Invoke-CimMethod -InputObject $p -MethodName GetOwnerSid; $i.Sid + '|' + $o.Domain + '\' + $o.User }"`) do (
    set "USID=%%a"
    set "UNAME=%%b"
)
if defined USID if not "%USID:~0,4%"=="S-1-" set "USID="
if not defined USID goto :usid_validado
reg query "HKU\%USID%" >nul 2>&1
if errorlevel 1 set "USID="
:usid_validado
if defined USID goto :usuario_detectado
set "UHIVE=HKCU"
set "UCLS=HKCU\Software\Classes"
set "UPS=Registry::HKEY_CURRENT_USER"
set "UNAME=%USERDOMAIN%\%USERNAME%"
goto :usuario_listo
:usuario_detectado
set "UHIVE=HKU\%USID%"
:: Las clases del usuario viven en su propia colmena; si no estuviera cargada,
:: Software\Classes del usuario es un enlace de Windows a esa misma colmena.
set "UCLS=HKU\%USID%_Classes"
reg query "%UCLS%" >nul 2>&1
if errorlevel 1 set "UCLS=HKU\%USID%\Software\Classes"
set "UPS=Registry::HKEY_USERS\%USID%"
:usuario_listo

cls
echo ==========================================================================
echo   REVERTIR OPTIMIZARPC v2
echo ==========================================================================
echo.
echo   Usuario: "%UNAME%"
echo.
echo   Vuelve a fabrica: servicios, apps en segundo plano, efectos visuales,
echo   Explorador, energia, navegadores, recortes de Defender y tareas.
echo   NO apaga la seguridad ni vuelve a encender la telemetria.
echo   Para volver todo exactamente como estaba: punto de restauracion.
echo.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 exit /b 0

call :titulo "Servicios: valores de fabrica de Windows 10"
for %%s in (DiagTrack PcaSvc TrkWks iphlpsvc DPS WpnService Spooler LanmanServer SysMain) do call :servicio %%s auto
for %%s in (WSearch CDPSvc MapsBroker edgeupdate BITS DoSvc) do call :servicio %%s delayed-auto
for %%s in (dmwappushservice XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc xbgm bthserv BTAGService BthAvctpSvc lfsvc WbioSrvc RetailDemo TabletInputService) do call :servicio %%s demand
echo   [OK] Servicios en sus valores de fabrica.

call :titulo "Tareas programadas"
for %%t in ("\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "\Microsoft\Windows\Autochk\Proxy" "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Maps\MapsUpdateTask" "\Microsoft\Windows\Maps\MapsToastTask" "\Microsoft\Windows\Windows Error Reporting\QueueReporting" "\Microsoft\Windows\Maintenance\WinSAT" "\Microsoft\XblGameSave\XblGameSaveTask") do schtasks /change /tn %%t /enable >nul 2>&1
echo   [OK] Tareas reactivadas.

call :titulo "Defender"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -EnableLowCpuPriority $false -ErrorAction SilentlyContinue; Set-MpPreference -ScanAvgCPULoadFactor 50 -ErrorAction SilentlyContinue" >nul 2>&1
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" DisableEnhancedNotifications
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" HideSystray
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\MRT" DontOfferThroughWUAU
echo   [OK] Analisis, notificaciones, icono y MRT como de fabrica. El bloqueo de PUA queda.

call :titulo "Procesos en segundo plano y busqueda"
set "_pol=HKLM\SOFTWARE\Policies\Microsoft\Windows"
call :borrar "%_pol%\Windows Feeds" EnableFeeds
call :borrar "%_pol%\Windows Search" AllowCortana
call :borrar "%_pol%\Windows Search" EnableDynamicContentInWSB
call :borrar "%_pol%\GameDVR" AllowGameDVR
call :borrar "%_pol%\Windows Error Reporting" Disabled
call :borrar "%_pol%\DeliveryOptimization" DODownloadMode
call :borrar "%_pol%\Device Metadata" PreventDeviceMetadataFromNetwork
call :borrar "%UHIVE%\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b='%UPS%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Get-ChildItem -LiteralPath $b -ErrorAction SilentlyContinue | ForEach-Object { Remove-ItemProperty -LiteralPath $_.PSPath -Name Disabled,DisabledByUser -ErrorAction SilentlyContinue }"
echo   [OK] Noticias e intereses, Cortana, destacados, informe de errores, precarga
echo        y apps en segundo plano como de fabrica.

call :titulo "Interfaz y Explorador"
set "_desk=%UHIVE%\Control Panel\Desktop"
set "_adv=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
reg add "%_desk%" /v UserPreferencesMask /t REG_BINARY /d 9E1E078012000000 /f >nul 2>&1
call :sz "%_desk%" DragFullWindows 1
call :sz "%_desk%" MenuShowDelay 400
call :sz "%_desk%\WindowMetrics" MinAnimate 1
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting 0
call :dword "%_adv%" ListviewAlphaSelect 1
call :dword "%_adv%" ListviewShadow 1
call :dword "%_adv%" TaskbarAnimations 1
call :dword "%_adv%" Start_TrackProgs 1
call :borrar "%_adv%" LaunchTo
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 1
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 1
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer" AltTabSettings
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
echo   [OK] Efectos visuales, desenfoque al iniciar sesion, menus, animaciones, Alt+Tab
echo        y Explorador como de fabrica.

call :titulo "Energia"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-CimInstance Win32_Battery) { exit 1 } else { exit 0 }" >nul 2>&1
if errorlevel 1 goto :energia_comun
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo   [OK] Plan de energia: Equilibrado.
:energia_comun
powercfg /change disk-timeout-ac 20 >nul 2>&1
echo   [OK] El disco vuelve a apagarse a los 20 minutos de inactividad.

call :titulo "Restaurar sistema e inicio rapido"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction SilentlyContinue" >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\SystemRestore\SR" /enable >nul 2>&1
powercfg /hibernate on >nul 2>&1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled 1
echo   [OK] Restaurar sistema e inicio rapido activados, como vienen de fabrica.
echo        Los puntos de restauracion borrados no vuelven: empiezan de cero.

call :titulo "Navegadores"
set "_edge=HKLM\SOFTWARE\Policies\Microsoft\Edge"
for %%v in (StartupBoostEnabled BackgroundModeEnabled HubsSidebarEnabled WebWidgetAllowed ShowRecommendationsEnabled EdgeShoppingAssistantEnabled ShowMicrosoftRewards PersonalizationReportingEnabled DiagnosticData UserFeedbackAllowed HideFirstRunExperience) do call :borrar "%_edge%" %%v
call :borrar "%_edge%\Recommended" SleepingTabsEnabled
call :borrar "%_edge%\Recommended" SleepingTabsTimeout
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" CreateDesktopShortcutDefault
call :borrar "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled
echo   [OK] Politicas de Edge y Chrome quitadas.

echo.
echo   Para recuperar lo que no se revierte solo:
echo    - OneDrive: abrilo una vez y vuelve a arrancar con Windows.
echo    - Apps quitadas: se reinstalan gratis desde la Microsoft Store.
echo    - App Fotos: buscala en la Store como "Microsoft Fotos". El Visualizador de
echo      fotos clasico queda disponible: no molesta y no ocupa nada.
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC. Usa "Reiniciar", no "Apagar".
echo ==========================================================================
choice /c SN /n /m "  Reiniciar ahora? [S/N]: "
if errorlevel 2 goto :fin
shutdown /r /t 10 /c "Reiniciando para revertir OptimizarPC v2"
exit /b 0
:fin
pause
exit /b 0


:: =========================================================================
::  SUBRUTINAS
:: =========================================================================

:titulo
echo.
echo --------------------------------------------------------------------------
echo   %~1
echo --------------------------------------------------------------------------
goto :eof

:dword
reg add "%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
goto :eof

:sz
reg add "%~1" /v %~2 /t REG_SZ /d "%~3" /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
goto :eof

:: Borra un valor si existe. Uso: call :borrar "clave" valor
:borrar
reg delete "%~1" /v %~2 /f >nul 2>&1
goto :eof

:: Cambia el inicio de un servicio. Tipos: auto, delayed-auto, demand, disabled.
:servicio
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1
if errorlevel 1 goto :eof
sc config "%~1" start= %~2 >nul 2>&1
if errorlevel 1 call :servicio_reg %~1 %~2
goto :eof

:servicio_reg
set "_k=HKLM\SYSTEM\CurrentControlSet\Services\%~1"
set "_v="
set "_d=0"
if /i "%~2"=="auto" set "_v=2"
if /i "%~2"=="delayed-auto" set "_v=2"
if /i "%~2"=="delayed-auto" set "_d=1"
if /i "%~2"=="demand" set "_v=3"
if /i "%~2"=="disabled" set "_v=4"
if not defined _v goto :eof
reg add "%_k%" /v Start /t REG_DWORD /d %_v% /f >nul 2>&1
if errorlevel 1 goto :servicio_reg_error
if "%_v%"=="2" reg add "%_k%" /v DelayedAutostart /t REG_DWORD /d %_d% /f >nul 2>&1
goto :eof
:servicio_reg_error
echo   [AVISO] No se pudo cambiar %~1: Windows lo protege.
goto :eof
