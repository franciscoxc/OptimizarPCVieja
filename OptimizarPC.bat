@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Optimizar PC Vieja v2
:: =========================================================================
::  OPTIMIZAR PC VIEJA v2
::  Para Windows 10 de 64 bits con disco mecanico (HDD) y 2 GB de RAM.
::
::  - Se ejecuta con doble clic: si no tiene permisos, los pide.
::  - Los ajustes de usuario se aplican al usuario que tiene la sesion
::    abierta, aunque el script se eleve con OTRA cuenta de administrador.
::  - Crea un punto de restauracion antes de tocar nada.
::  - Repara la seguridad que otras herramientas pudieron haber apagado.
::  - Corrige lo que el script original (v1) hacia mal.
::  - Cada cambio esta explicado en README.md.
:: =========================================================================

:: Si se lanzo desde un proceso de 32 bits, reabrir con el cmd de 64 bits:
:: si no, Windows redirige el registro y los cambios caen en otro lugar.
if not defined PROCESSOR_ARCHITEW6432 goto :arquitectura_ok
"%SystemRoot%\Sysnative\cmd.exe" /c ""%~f0""
exit /b
:arquitectura_ok

:: -------------------------------------------------------------------------
:: Permisos de administrador (si faltan, se piden con el cartel de UAC)
:: -------------------------------------------------------------------------
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

:: -------------------------------------------------------------------------
:: Usuario de la sesion abierta (dueno del explorer.exe de esta sesion)
:: -------------------------------------------------------------------------
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
set "UPROFILE=%USERPROFILE%"
goto :usuario_listo
:usuario_detectado
set "UHIVE=HKU\%USID%"
:: Las clases del usuario viven en su propia colmena; si no estuviera cargada,
:: Software\Classes del usuario es un enlace de Windows a esa misma colmena.
set "UCLS=HKU\%USID%_Classes"
reg query "%UCLS%" >nul 2>&1
if errorlevel 1 set "UCLS=HKU\%USID%\Software\Classes"
set "UPS=Registry::HKEY_USERS\%USID%"
set "UPROFILE="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\%USID%" /v ProfileImagePath 2^>nul ^| findstr /i "ProfileImagePath"') do call set "UPROFILE=%%b"
:usuario_listo

:: Version de Windows
set "BUILD=0"
for /f "tokens=3" %%b in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "BUILD=%%b"

:: -------------------------------------------------------------------------
:: Presentacion y preguntas
:: -------------------------------------------------------------------------
cls
echo ==========================================================================
echo   OPTIMIZAR PC VIEJA v2 - Windows 10, disco mecanico, 2 GB de RAM
echo ==========================================================================
echo.
echo   Usuario al que se le aplican los ajustes: "%UNAME%"
if not defined USID echo   AVISO: no se detecto la sesion abierta; se usa la cuenta que ejecuta el script.
echo   Compilacion de Windows: %BUILD%
if %BUILD% GEQ 22000 echo   AVISO: esto parece Windows 11. El script esta pensado para Windows 10.
if %BUILD% LSS 19041 echo   AVISO: Windows 10 muy viejo. Conviene actualizar a 22H2 primero.
set "_aqui=%~dp0"
if /i "%_aqui:\AppData\Local\Temp\=%"=="%_aqui%" goto :zip_ok
echo   AVISO: parece que lo estas abriendo desde adentro de un ZIP. Funciona igual,
echo          pero conviene descomprimir la carpeta primero.
:zip_ok
echo.
echo   - Antes de tocar nada se crea un punto de restauracion.
echo   - En un disco mecanico puede tardar entre 10 y 20 minutos.
echo   - Al terminar hay que REINICIAR la PC.
echo.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 exit /b 0

echo.
echo   Unas preguntas antes de empezar. Despues no molesta mas.
echo.
choice /c SN /n /m "  1. Usas impresora en esta PC? [S/N]: "
if errorlevel 2 (set "IMPRESORA=N") else (set "IMPRESORA=S")
choice /c SN /n /m "  2. Compartis carpetas o impresora con otras PCs de tu red? [S/N]: "
if errorlevel 2 (set "COMPARTIR=N") else (set "COMPARTIR=S")
choice /c SN /n /m "  3. Usas OneDrive? [S/N]: "
if errorlevel 2 (set "ONEDRIVE=N") else (set "ONEDRIVE=S")
echo.
echo   4. Quitar apps preinstaladas que no se usan: Xbox, Solitario, Candy Crush,
echo      Noticias, Clima, Tu Telefono, Skype, Personas, Mapas, Correo y Calendario,
echo      Paint 3D, OneNote para Win10, Cortana, Copilot y similares.
echo      NO se tocan: Store, Calculadora, Fotos, Camara, Recortes, Notas, Alarmas,
echo      Grabadora ni los reproductores. Todo se puede reinstalar desde la Store.
choice /c SN /n /m "     Quitarlas? [S/N]: "
if errorlevel 2 (set "QUITARAPPS=N") else (set "QUITARAPPS=S")

:: =========================================================================
call :titulo "1/12  Punto de restauracion"
:: =========================================================================
call :asegurar VSS demand
call :asegurar swprv demand
echo   Creando punto de restauracion, puede tardar unos minutos...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop; Checkpoint-Computer -Description 'Antes de OptimizarPC v2' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; exit 0 } catch { exit 1 }"
set "RP_ERR=%errorlevel%"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f >nul 2>&1
if "%RP_ERR%"=="0" goto :punto_ok
echo   [!] No se pudo crear el punto de restauracion.
choice /c SN /n /m "      Continuar igual? [S/N]: "
if errorlevel 2 exit /b 1
goto :punto_listo
:punto_ok
echo   [OK] Punto de restauracion "Antes de OptimizarPC v2" creado.
:punto_listo

:: =========================================================================
call :titulo "2/12  Seguridad: reparando lo que otra herramienta pudo apagar"
:: =========================================================================
:: Servicios esenciales: solo se tocan si estan DESHABILITADOS, y vuelven a
:: su valor de fabrica de Windows 10. Formato servicio:tipo.
for %%s in (WinDefend:auto WdNisSvc:demand SecurityHealthService:demand wscsvc:delayed-auto mpssvc:auto BFE:auto) do call :asegurar_par %%s
for %%s in (wuauserv:demand UsoSvc:delayed-auto WaaSMedicSvc:demand BITS:delayed-auto DoSvc:delayed-auto CryptSvc:auto TrustedInstaller:demand) do call :asegurar_par %%s
for %%s in (AppXSvc:demand ClipSVC:demand InstallService:demand LicenseManager:demand TokenBroker:demand wlidsvc:demand TimeBrokerSvc:demand) do call :asegurar_par %%s
for %%s in (Appinfo:demand EventLog:auto Schedule:auto W32Time:demand KeyIso:demand VaultSvc:demand seclogon:demand SamSs:auto Winmgmt:auto) do call :asegurar_par %%s
for %%s in (Dhcp:auto Dnscache:auto NlaSvc:auto nsi:auto Audiosrv:auto AudioEndpointBuilder:auto Themes:auto ProfSvc:auto) do call :asegurar_par %%s

:: Defender: quitar politicas que lo apagan (las ponen algunos "debloaters")
set "_wd=HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
for %%v in (DisableAntiSpyware DisableAntiVirus DisableRoutinelyTakingAction ServiceKeepAlive) do call :quitar_politica "%_wd%" %%v "Defender"
for %%v in (DisableRealtimeMonitoring DisableBehaviorMonitoring DisableOnAccessProtection DisableScanOnRealtimeEnable DisableIOAVProtection) do call :quitar_politica "%_wd%\Real-Time Protection" %%v "Defender en tiempo real"
for %%v in (SpynetReporting SubmitSamplesConsent DisableBlockAtFirstSeen) do call :quitar_politica "%_wd%\Spynet" %%v "proteccion en la nube"
:: Bloqueo de aplicaciones potencialmente no deseadas: adware, toolbars, "optimizadores"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue" >nul 2>&1
echo   [OK] Defender: politicas revisadas y bloqueo de PUA activado.

:: Firewall
for %%p in (DomainProfile StandardProfile PublicProfile) do call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\%%p" EnableFirewall 0x0 "Una politica apagaba el firewall"
netsh advfirewall set allprofiles state on >nul 2>&1
echo   [OK] Firewall encendido en todos los perfiles.

:: SmartScreen
call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableSmartScreen 0x0 "Una politica apagaba SmartScreen"
call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\Edge" SmartScreenEnabled 0x0 "Una politica apagaba SmartScreen en Edge"
call :quitar_si_vale "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\AppHost" EnableWebContentEvaluation 0x0 "SmartScreen para apps de la Store estaba apagado"
call :leer "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" SmartScreenEnabled
if /i "%_r%"=="Off" call :fijar_sz "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" SmartScreenEnabled Warn "SmartScreen para apps y archivos estaba apagado"

:: UAC: solo se repara si estaba apagado o en "no notificar nunca"
set "_uac=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
call :leer "%_uac%" EnableLUA
if "%_r%"=="0x0" call :fijar_dword "%_uac%" EnableLUA 1 "UAC estaba desactivado"
call :leer "%_uac%" ConsentPromptBehaviorAdmin
if "%_r%"=="0x0" call :fijar_dword "%_uac%" ConsentPromptBehaviorAdmin 5 "UAC estaba en no notificar nunca"
call :leer "%_uac%" PromptOnSecureDesktop
if "%_r%"=="0x0" call :fijar_dword "%_uac%" PromptOnSecureDesktop 1 "UAC no usaba el escritorio seguro"

:: DEP: AlwaysOff -> OptIn (valor de fabrica). Si hay BitLocker, se suspende
:: por un reinicio para que el cambio en el arranque no pida la clave.
bcdedit /enum {current} 2>nul | findstr /i /c:"AlwaysOff" >nul
if errorlevel 1 goto :dep_ok
manage-bde -protectors -disable %SystemDrive% -RebootCount 1 >nul 2>&1
bcdedit /set {current} nx OptIn >nul 2>&1
echo   [REPARADO] DEP estaba en AlwaysOff: vuelve a OptIn.
:dep_ok

:: Mitigaciones de Spectre y Meltdown: si alguien las apago, se vuelven a encender
set "_mm=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
call :leer "%_mm%" FeatureSettingsOverride
if not "%_r%"=="0x3" goto :spectre_ok
reg delete "%_mm%" /v FeatureSettingsOverride /f >nul 2>&1
reg delete "%_mm%" /v FeatureSettingsOverrideMask /f >nul 2>&1
echo   [REPARADO] Las mitigaciones de Spectre y Meltdown estaban apagadas.
:spectre_ok

:: Windows Update: quitar politicas que lo bloquean
set "_wu=HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
call :quitar_si_vale "%_wu%\AU" NoAutoUpdate 0x1 "Una politica bloqueaba las actualizaciones automaticas"
call :quitar_si_vale "%_wu%" DisableWindowsUpdateAccess 0x1 "Una politica bloqueaba Windows Update"
call :quitar_si_vale "%_wu%" SetDisableUXWUAccess 0x1 "Una politica ocultaba Windows Update"
call :quitar_si_vale "%_wu%" DoNotConnectToWindowsUpdateInternetLocations 0x1 "Una politica cortaba Windows Update de internet"

:: Reproduccion automatica apagada en todas las unidades: clasica via de virus por pendrive
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" NoDriveTypeAutoRun 255
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" NoAutorun 1
echo   [OK] Reproduccion automatica desactivada.

:: Tareas que tienen que estar activas: desfragmentacion (clave en HDD), aviso
:: de disco por fallar, analisis de Defender y puntos de restauracion.
for %%t in ("\Microsoft\Windows\Defrag\ScheduledDefrag" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup" "\Microsoft\Windows\Windows Defender\Windows Defender Verification" "\Microsoft\Windows\WindowsUpdate\Scheduled Start" "\Microsoft\Windows\SystemRestore\SR") do schtasks /change /tn %%t /enable >nul 2>&1
echo   [OK] Tareas de mantenimiento y seguridad activas.

:: Archivo de paginacion: con 2 GB de RAM es obligatorio
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cs=Get-CimInstance Win32_ComputerSystem; if (-not $cs.AutomaticManagedPagefile -and -not (Get-CimInstance Win32_PageFileSetting)) { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true}; Write-Output '  [REPARADO] No habia archivo de paginacion: ahora lo administra Windows.' }"

:: =========================================================================
call :titulo "3/12  Corrigiendo el script original v1"
:: =========================================================================
:: SysMain maneja la compresion de memoria: con 2 GB de RAM es clave.
call :servicio SysMain auto
sc start SysMain >nul 2>&1
:: Sin este servicio no se puede escribir en el Inicio, Configuracion ni apps UWP.
call :servicio TabletInputService demand
sc start TabletInputService >nul 2>&1
:: Con poca RAM, fijar el kernel en memoria le saca RAM a los programas.
call :dword "%_mm%" DisablePagingExecutive 0
:: Placebos que Windows ignora: se borran.
reg delete "%_mm%" /v IOPageLockLimit /f >nul 2>&1
reg delete "%_mm%" /v DontVerifyRandomDrivers /f >nul 2>&1
:: Compresion de memoria activa y sin precarga de apps UWP en RAM.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue; Disable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue" >nul 2>&1
echo   [OK] SysMain y compresion de memoria activos.
echo   [OK] Teclado tactil y escritura en el Inicio restaurados.
echo   [OK] DisablePagingExecutive en 0; placebos IOPageLockLimit y DontVerifyRandomDrivers borrados.
echo   [OK] Delivery Optimization habilitado; su P2P se apaga con la politica oficial en el paso 7.

:: =========================================================================
call :titulo "4/12  Servicios: Manual siempre que se pueda"
:: =========================================================================
:: Deshabilitados: telemetria, indexador, Xbox, Bluetooth y Registro remoto.
for %%s in (DiagTrack dmwappushservice WSearch RemoteRegistry) do call :servicio %%s disabled
for %%s in (XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc xbgm) do call :servicio %%s disabled
for %%s in (bthserv BTAGService BthAvctpSvc) do call :servicio %%s disabled
echo   [OK] Deshabilitados: telemetria, indexador de busqueda, Xbox, Bluetooth y Registro remoto.
:: Manual: arrancan solo cuando algo los necesita.
for %%s in (PcaSvc TrkWks iphlpsvc DPS CDPSvc MapsBroker edgeupdate lfsvc WbioSrvc RetailDemo) do call :servicio %%s demand
echo   [OK] En Manual: PcaSvc, TrkWks, iphlpsvc, DPS, CDPSvc, MapsBroker, edgeupdate,
echo        lfsvc, WbioSrvc y RetailDemo.
:: Automatico retrasado: tienen que correr solos, pero pueden esperar al arranque.
for %%s in (BITS WpnService) do call :servicio %%s delayed-auto
echo   [OK] Automatico retrasado: BITS y WpnService.
if "%IMPRESORA%"=="S" (call :servicio Spooler delayed-auto) else (call :servicio Spooler demand)
if "%IMPRESORA%"=="S" (echo   [OK] Impresion: Automatico retrasado.) else (echo   [OK] Impresion: Manual.)
if "%COMPARTIR%"=="S" (call :servicio LanmanServer auto) else (call :servicio LanmanServer demand)
if "%COMPARTIR%"=="S" (echo   [OK] Compartir en red: Automatico.) else (echo   [OK] Compartir en red: Manual.)

:: =========================================================================
call :titulo "5/12  Tareas programadas de telemetria"
:: =========================================================================
for %%t in ("\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "\Microsoft\Windows\Autochk\Proxy" "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Maps\MapsUpdateTask" "\Microsoft\Windows\Maps\MapsToastTask" "\Microsoft\Windows\Windows Error Reporting\QueueReporting" "\Microsoft\Windows\Maintenance\WinSAT" "\Microsoft\XblGameSave\XblGameSaveTask") do schtasks /change /tn %%t /disable >nul 2>&1
echo   [OK] Desactivadas: Compatibility Appraiser, CEIP, comentarios, mapas,
echo        informe de errores, WinSAT y Xbox.

:: =========================================================================
call :titulo "6/12  Defender: solo lo imprescindible"
:: =========================================================================
:: Se queda: tiempo real, comportamiento, nube, descargas, firmas, SmartScreen.
:: Se recortan los analisis programados y lo que no protege.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -EnableLowCpuPriority $true -ErrorAction SilentlyContinue; Set-MpPreference -ScanAvgCPULoadFactor 20 -ErrorAction SilentlyContinue; Set-MpPreference -ScanOnlyIfIdleEnabled $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableCatchupFullScan $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableCatchupQuickScan $true -ErrorAction SilentlyContinue" >nul 2>&1
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" DisableEnhancedNotifications 1
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" HideSystray 1
call :dword "HKLM\SOFTWARE\Policies\Microsoft\MRT" DontOfferThroughWUAU 1
echo   [OK] Analisis programados: prioridad baja, maximo 20%% de CPU, solo con la PC inactiva.
echo   [OK] Sin notificaciones no criticas ni icono en la bandeja.
echo   [OK] Sin la herramienta MRT mensual, redundante con Defender en tiempo real.

:: =========================================================================
call :titulo "7/12  Telemetria, publicidad y procesos en segundo plano"
:: =========================================================================
set "_pol=HKLM\SOFTWARE\Policies\Microsoft\Windows"
call :dword "%_pol%\DataCollection" AllowTelemetry 0
call :dword "%_pol%\DataCollection" DoNotShowFeedbackNotifications 1
call :dword "%_pol%\CloudContent" DisableWindowsConsumerFeatures 1
call :dword "%_pol%\CloudContent" DisableSoftLanding 1
call :dword "%_pol%\AdvertisingInfo" DisabledByGroupPolicy 1
call :dword "%_pol%\System" PublishUserActivities 0
call :dword "%_pol%\System" UploadUserActivities 0
call :dword "%_pol%\Windows Feeds" EnableFeeds 0
call :dword "%_pol%\Windows Search" AllowCortana 0
call :dword "%_pol%\Windows Search" EnableDynamicContentInWSB 0
call :dword "%_pol%\GameDVR" AllowGameDVR 0
call :dword "%_pol%\DeliveryOptimization" DODownloadMode 0
call :dword "%_pol%\Windows Error Reporting" Disabled 1
call :dword "%_pol%\Device Metadata" PreventDeviceMetadataFromNetwork 1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" DisableWpbtExecution 1
call :dword "HKLM\SYSTEM\Maps" AutoUpdateEnabled 0
echo   [OK] Telemetria al minimo, sin Noticias e intereses, sin Cortana ni destacados,
echo        sin barra de juegos, sin P2P de actualizaciones ni informe de errores.

:: Ajustes del usuario de la sesion
set "_cdm=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%v in (ContentDeliveryAllowed OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SoftLandingEnabled SystemPaneSuggestionsEnabled SubscribedContentEnabled) do call :dword "%_cdm%" %%v 0
for %%v in (SubscribedContent-310093Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled) do call :dword "%_cdm%" %%v 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" ScoobeSystemSettingEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Siuf\Rules" NumberOfSIUFInPeriod 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" CortanaConsent 0
call :dword "%UHIVE%\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions 1
call :dword "%UHIVE%\System\GameConfigStore" GameDVR_Enabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled 0
echo   [OK] Sin apps sugeridas, instalaciones silenciosas, consejos ni resultados web.

:: Apps en segundo plano: una por una, salvo componentes de Windows, Store,
:: alarmas y reproductores. Fotos si se apaga: es de las que mas consume.
:: El interruptor general rompe la busqueda del Inicio.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b='%UPS%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; $keep='Microsoft.Windows.*','MicrosoftWindows.*','windows.*','Microsoft.AAD.BrokerPlugin*','Microsoft.AccountsControl*','Microsoft.CredDialogHost*','Microsoft.ECApp*','Microsoft.AsyncTextService*','Microsoft.BioEnrollment*','Microsoft.LockApp*','Microsoft.Win32WebViewHost*','Microsoft.WindowsStore*','Microsoft.DesktopAppInstaller*','Microsoft.WindowsAlarms*','Microsoft.ZuneMusic*','Microsoft.ZuneVideo*','SpotifyAB.SpotifyMusic*'; $force='Microsoft.Windows.Photos*'; $n=0; Get-ChildItem -LiteralPath $b -ErrorAction SilentlyContinue | ForEach-Object { $app=$_.PSChildName; if (($app -like $force) -or -not ($keep | Where-Object { $app -like $_ })) { Set-ItemProperty -LiteralPath $_.PSPath -Name Disabled -Value 1 -Type DWord; Set-ItemProperty -LiteralPath $_.PSPath -Name DisabledByUser -Value 1 -Type DWord; $n++ } }; Write-Output ('  [OK] Apps en segundo plano desactivadas: ' + $n)"

:: =========================================================================
call :titulo "8/12  Interfaz y Explorador"
:: =========================================================================
set "_desk=%UHIVE%\Control Panel\Desktop"
set "_adv=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
:: Efectos visuales en "mejor rendimiento", conservando el suavizado de fuentes.
reg add "%_desk%" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
call :sz "%_desk%" DragFullWindows 0
call :sz "%_desk%" MenuShowDelay 100
call :sz "%_desk%" FontSmoothing 2
call :dword "%_desk%" FontSmoothingType 2
call :sz "%_desk%\WindowMetrics" MinAnimate 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting 3
call :dword "%_adv%" ListviewAlphaSelect 0
call :dword "%_adv%" ListviewShadow 0
call :dword "%_adv%" TaskbarAnimations 0
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 0
:: El Explorador abre en "Este equipo" y no rastrea los programas abiertos.
call :dword "%_adv%" LaunchTo 1
call :dword "%_adv%" Start_TrackProgs 0
:: Sin deteccion automatica del tipo de carpeta (tweak de WinUtil).
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
call :sz "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" FolderType NotSpecified
echo   [OK] Efectos visuales al minimo, conservando el suavizado de fuentes y las miniaturas.
echo   [OK] Menus mas rapidos, sin transparencias ni animaciones.
echo   [OK] Explorador: abre en Este equipo y no adivina el tipo de cada carpeta.

:: =========================================================================
call :titulo "9/12  Memoria, disco y energia"
:: =========================================================================
fsutil behavior set DisableLastAccess 1 >nul 2>&1
fsutil behavior set Disable8dot3 1 >nul 2>&1
echo   [OK] NTFS sin registro de ultimo acceso ni nombres cortos 8.3.

:: CompactOS: en HDD conviene el sistema sin comprimir. Solo se descomprime si
:: estaba comprimido y hay espacio; si no, se saltea: tarda varios minutos igual.
set "COMPACTO=0"
set "LIBRE_GB=0"
for /f "usebackq tokens=1,2" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$c=0; foreach ($f in 'System32\shell32.dll','System32\mshtml.dll','explorer.exe') { $p=Join-Path $env:windir $f; if ((Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { $c=1 } }; $d=Get-PSDrive -Name $env:SystemDrive.Substring(0,1); [string]$c + ' ' + [string][math]::Floor($d.Free/1GB)"`) do (
    set "COMPACTO=%%a"
    set "LIBRE_GB=%%b"
)
if not "%COMPACTO%"=="1" goto :compact_no
if %LIBRE_GB% LSS 6 goto :compact_sin_espacio
echo   El sistema esta comprimido con CompactOS: descomprimiendo, puede tardar...
compact /CompactOS:never >nul 2>&1
echo   [OK] Sistema descomprimido.
goto :compact_listo
:compact_sin_espacio
echo   [AVISO] El sistema esta comprimido pero quedan menos de 6 GB libres: se deja asi.
goto :compact_listo
:compact_no
echo   [OK] El sistema no esta comprimido con CompactOS: nada que hacer.
:compact_listo

:: Energia. Notebook: se respeta el plan para cuidar la bateria.
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Get-CimInstance Win32_Battery) { exit 1 } else { exit 0 }" >nul 2>&1
if errorlevel 1 goto :energia_notebook
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 goto :energia_comun
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo   [OK] Plan de energia: Alto rendimiento.
goto :energia_comun
:energia_notebook
echo   Notebook detectada: se mantiene el plan de energia para cuidar la bateria.
:energia_comun
:: El HDD nunca se apaga enchufado: despertarlo congela la PC varios segundos.
powercfg /change disk-timeout-ac 0 >nul 2>&1
echo   [OK] El disco no se apaga mientras la PC esta enchufada.
:: Inicio rapido: en HDD es la mayor mejora de arranque.
powercfg /hibernate on >nul 2>&1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled 1
echo   [OK] Inicio rapido activado.

:: =========================================================================
call :titulo "10/12  Navegadores"
:: =========================================================================
set "_edge=HKLM\SOFTWARE\Policies\Microsoft\Edge"
for %%v in (StartupBoostEnabled BackgroundModeEnabled HubsSidebarEnabled WebWidgetAllowed ShowRecommendationsEnabled EdgeShoppingAssistantEnabled ShowMicrosoftRewards PersonalizationReportingEnabled DiagnosticData UserFeedbackAllowed) do call :dword "%_edge%" %%v 0
call :dword "%_edge%" HideFirstRunExperience 1
call :dword "%_edge%\Recommended" SleepingTabsEnabled 1
call :dword "%_edge%\Recommended" SleepingTabsTimeout 300
call :dword "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" CreateDesktopShortcutDefault 0
call :dword "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled 0
echo   [OK] Edge: sin precarga, sin quedar de fondo, sin barra lateral; pestanas
echo        en suspension a los 5 minutos. Chrome: sin quedar de fondo.
echo        Van a decir "Administrado por tu organizacion": es normal.

:: =========================================================================
call :titulo "11/12  Opcionales"
:: =========================================================================
if "%ONEDRIVE%"=="S" goto :onedrive_listo
reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
echo   [OK] OneDrive ya no arranca con Windows. No se desinstalo.
:onedrive_listo
if "%QUITARAPPS%"=="N" goto :apps_listo
echo   Quitando apps preinstaladas para todos los usuarios, puede tardar...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$apps='Microsoft.549981C3F5F10','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.Copilot','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.Messaging','Microsoft.Microsoft3DViewer','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.MSPaint','Microsoft.Office.OneNote','Microsoft.OneConnect','Microsoft.People','Microsoft.Print3D','Microsoft.SkypeApp','Microsoft.Wallet','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','microsoft.windowscommunicationsapps','Microsoft.YourPhone','Microsoft.GamingApp','Microsoft.XboxApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Clipchamp.Clipchamp','MicrosoftTeams','king.com.*'; $prov=Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue | Sort-Object PackageFullName -Unique | ForEach-Object { Write-Output ('    - ' + $_.Name); Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }; $prov | Where-Object { $_.DisplayName -like $a } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null } }"
echo   [OK] Apps preinstaladas quitadas.
:apps_listo

:: =========================================================================
call :titulo "12/12  Limpieza de temporales"
:: =========================================================================
:: Si el script corre desde una carpeta temporal (por ejemplo, abierto adentro
:: de un ZIP), esa carpeta se saltea para no borrarse a si mismo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$self='%~dp0'; $dirs=@($env:SystemRoot + '\Temp'); $u='%UPROFILE%'; if ($u) { $dirs += (Join-Path $u 'AppData\Local\Temp') }; foreach ($t in $dirs) { if (Test-Path -LiteralPath $t) { Get-ChildItem -LiteralPath $t -Force -ErrorAction SilentlyContinue | Where-Object { -not $self.StartsWith($_.FullName, [StringComparison]::OrdinalIgnoreCase) } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } }"
echo   [OK] Temporales del usuario y de Windows borrados. Los que estaban en uso quedan.

:: =========================================================================
call :titulo "Ultimos pasos"
:: =========================================================================
echo   Actualizando las firmas de Defender...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Update-MpSignature -ErrorAction SilentlyContinue; $s=Get-MpComputerStatus -ErrorAction SilentlyContinue; if ($s) { $rt='INACTIVO, hay otro antivirus?'; if ($s.RealTimeProtectionEnabled) { $rt='ACTIVO' }; $tp='inactiva'; if ($s.IsTamperProtected) { $tp='ACTIVA' }; Write-Output ('  Defender en tiempo real: ' + $rt); Write-Output ('  Proteccion contra alteraciones: ' + $tp); Write-Output ('  Firmas de virus del: ' + $s.AntivirusSignatureLastUpdated) } else { Write-Output '  No se pudo leer el estado de Defender. Hay otro antivirus instalado?' }"
echo.
echo   Programas que arrancan con Windows. Desactiva los que no uses en
echo   Administrador de tareas, pestana Inicio, desde la sesion del usuario:
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ks='%UPS%\Software\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; foreach ($k in $ks) { $i=Get-Item -LiteralPath $k -ErrorAction SilentlyContinue; if ($i) { $i.Property | ForEach-Object { Write-Output ('    - ' + $_) } } }"
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC para aplicar todo.
echo   Usa "Reiniciar", no "Apagar": con el inicio rapido, apagar no recarga todo.
echo.
echo   Seguridad: Windows 10 recibe parches gratis hasta el 12/10/2027 si la PC
echo   esta inscripta en ESU. Revisalo en Configuracion, Windows Update.
echo ==========================================================================
choice /c SN /n /m "  Reiniciar ahora? [S/N]: "
if errorlevel 2 goto :fin
shutdown /r /t 10 /c "Reiniciando para aplicar OptimizarPC v2"
exit /b 0
:fin
echo.
echo   Acordate de reiniciar antes de usar la PC.
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

:: Lee un valor del registro. Deja el dato en _r, o vacio si no existe.
:: Uso: call :leer "clave" valor
:leer
set "_r="
for /f "tokens=3" %%v in ('reg query "%~1" /v %~2 2^>nul ^| findstr /i /c:"%~2"') do set "_r=%%v"
goto :eof

:: Escribe un DWORD. Uso: call :dword "clave" valor dato
:dword
reg add "%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
goto :eof

:: Escribe un texto. Uso: call :sz "clave" valor dato
:sz
reg add "%~1" /v %~2 /t REG_SZ /d "%~3" /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
goto :eof

:: Escribe un DWORD y avisa que se reparo algo. Uso: call :fijar_dword "clave" valor dato "aviso"
:fijar_dword
reg add "%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul 2>&1
echo   [REPARADO] %~4
goto :eof

:: Escribe un texto y avisa que se reparo algo. Uso: call :fijar_sz "clave" valor dato "aviso"
:fijar_sz
reg add "%~1" /v %~2 /t REG_SZ /d "%~3" /f >nul 2>&1
echo   [REPARADO] %~4
goto :eof

:: Borra una politica si existe y avisa. Uso: call :quitar_politica "clave" valor "que afectaba"
:quitar_politica
reg query "%~1" /v %~2 >nul 2>&1
if errorlevel 1 goto :eof
reg delete "%~1" /v %~2 /f >nul 2>&1
echo   [REPARADO] Se quito la politica %~2, que afectaba: %~3
goto :eof

:: Borra un valor solo si tiene el dato peligroso indicado. Uso:
:: call :quitar_si_vale "clave" valor dato "aviso"
:quitar_si_vale
call :leer "%~1" %~2
if /i not "%_r%"=="%~3" goto :eof
reg delete "%~1" /v %~2 /f >nul 2>&1
echo   [REPARADO] %~4
goto :eof

:: Cambia el inicio de un servicio. Tipos: auto, delayed-auto, demand, disabled.
:: Si sc no puede, por ejemplo con DoSvc, prueba directo en el registro.
:servicio
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1
if errorlevel 1 goto :eof
sc config "%~1" start= %~2 >nul 2>&1
if errorlevel 1 call :servicio_reg %~1 %~2
if /i "%~2"=="disabled" sc stop "%~1" >nul 2>&1
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

:: Si el servicio esta DESHABILITADO, lo vuelve al tipo indicado.
:: Uso: call :asegurar servicio tipo
:asegurar
call :leer "HKLM\SYSTEM\CurrentControlSet\Services\%~1" Start
if /i not "%_r%"=="0x4" goto :eof
set "_t=%~2"
if /i "%~2"=="auto" set "_t=Automatico"
if /i "%~2"=="delayed-auto" set "_t=Automatico retrasado"
if /i "%~2"=="demand" set "_t=Manual"
echo   [REPARADO] %~1 estaba deshabilitado: vuelve a %_t%
call :servicio %~1 %~2
goto :eof

:: Igual que :asegurar, pero recibe "servicio:tipo".
:asegurar_par
for /f "tokens=1,2 delims=:" %%a in ("%~1") do call :asegurar %%a %%b
goto :eof

