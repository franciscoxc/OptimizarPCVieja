@echo off
setlocal EnableExtensions DisableDelayedExpansion
:: La ruta de este archivo, para PowerShell. Por variable de entorno, y no pegada
:: en el comando, para que una carpeta con apostrofo o & en el nombre no rompa nada.
set "OPT_RUTA=%~f0"
title Optimizar PC Vieja v2
:: =========================================================================
::  OPTIMIZAR PC VIEJA v2
::  Para Windows 10 con disco mecanico (HDD) y 2 GB de RAM.
::
::  Un solo archivo, con menu:
::    1. Optimizar la PC.
::    2. Limpiar restos de Windows Update (DISM /ResetBase, irreversible).
::    3. Desfragmentar a fondo.
::    4. Instalar Chrome, WinRAR y VLC (con winget).
::    5. Chrome de aula: cerrar sesiones y borrar perfiles.
::    6. Revertir la optimizacion (deshace la opcion 1).
::    7. Verificar el estado: solo mira, no cambia nada.
::
::  - Se ejecuta con doble clic: si no tiene permisos, los pide.
::  - Los ajustes de usuario se aplican al usuario que tiene la sesion
::    abierta, aunque el script se eleve con OTRA cuenta de administrador.
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:OPT_RUTA -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }"
if not errorlevel 1 exit /b
echo.
echo  No se obtuvieron permisos de administrador.
echo  Hace clic derecho en el archivo y elegi "Ejecutar como administrador".
echo.
pause
exit /b 1
:es_admin

:: =========================================================================
::  MENU
:: =========================================================================
set "REINICIO_PENDIENTE=0"
cls
:menu
title Optimizar PC Vieja v2
echo.
echo ==========================================================================
echo   OPTIMIZAR PC VIEJA v2 - Windows 10, disco mecanico, 2 GB de RAM
echo ==========================================================================
if "%REINICIO_PENDIENTE%"=="1" echo   Falta REINICIAR para que se apliquen los cambios.
echo.
echo     1. Optimizar la PC
echo     2. Limpiar restos de Windows Update (avanzado, irreversible, hasta 1 h)
echo     3. Desfragmentar a fondo (de vez en cuando, puede tardar horas)
echo     4. Instalar Chrome, WinRAR y VLC
echo     5. Chrome de aula: cerrar sesiones y borrar perfiles
echo     6. Revertir la optimizacion (deshace la opcion 1)
echo     7. Verificar el estado (solo mira, no cambia nada)
echo     0. Salir
echo.
:: choice responde a una sola tecla, sin Enter, e ignora cualquier otra.
choice /c 12345670 /n /m "  Toca un numero: "
if errorlevel 8 goto :salir
if errorlevel 7 goto :op_verificar
if errorlevel 6 goto :op_revertir
if errorlevel 5 goto :op_chrome_aula
if errorlevel 4 goto :op_instalar
if errorlevel 3 goto :op_desfragmentar
if errorlevel 2 goto :op_limpiar_wu
if errorlevel 1 goto :op_optimizar
goto :menu

:: Final de las opciones que cambian el sistema: ofrecer reiniciar. Si no,
:: se vuelve al menu y se recuerda que falta reiniciar.
:fin_con_reinicio
set "REINICIO_PENDIENTE=1"
choice /c SN /n /m "  Reiniciar ahora? [S/N]: "
if errorlevel 2 goto :menu
shutdown /r /t 10 /c "Reiniciando para aplicar los cambios de OptimizarPC"
exit /b 0

:salir
if not "%REINICIO_PENDIENTE%"=="1" exit /b 0
echo.
echo   Hay cambios que recien se aplican al reiniciar.
choice /c SN /n /m "  Reiniciar ahora? [S/N]: "
if errorlevel 2 exit /b 0
shutdown /r /t 10 /c "Reiniciando para aplicar los cambios de OptimizarPC"
exit /b 0

:: =========================================================================
::  1. OPTIMIZAR
:: =========================================================================
:op_optimizar
title Optimizar PC Vieja v2 - Optimizar
:: Usuario de la sesion, version de Windows y hardware (seccion EQUIPO).
call :detectar
:: Perfiles segun el hardware:
::  - RAM instalada de 4 GB o mas (se suman los modulos: Windows de 32 bits ve
::    unos 3,2 GB y el video se queda con un pedazo): suspension a la hora,
::    tapa que suspende, Suspender en el menu y Bluetooth en Manual;
::  - eso y placa de video con driver: efectos visuales en "mejor apariencia";
::  - disco del sistema SSD: indexador de busqueda de fabrica.
set "PERFIL_4GB=0"
if %RAM_INST% GEQ 3584 set "PERFIL_4GB=1"
set "EFECTOS=0"
if "%PERFIL_4GB%"=="1" if not "%GPU_BASICA%"=="1" set "EFECTOS=1"
set "SSD=0"
if /i "%DISCO_TIPO%"=="SSD" set "SSD=1"

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
echo   Procesador: %CPU_NOMBRE%
if not "%RAM_MB%"=="9999" echo   RAM: %RAM_MB% MB visibles, %RAM_INST% MB instalados. Disco del sistema: %DISCO_TIPO%.
if "%PERFIL_4GB%"=="1" echo   Perfil 4 GB o mas: suspende a la hora y con la tapa, Bluetooth en Manual.
if "%EFECTOS%"=="1" echo   Video con driver: efectos visuales en "mejor apariencia".
if "%SSD%"=="1" echo   Disco SSD: indexador de busqueda como de fabrica.
if %RAM_MB% GEQ 1500 goto :ram_ok
echo   AVISO: tiene menos de 2 GB de RAM. Windows 10 de 64 bits pide 2 GB como minimo.
echo          Estos Atom aceptan hasta 2 GB: ampliarla es la mejora mas barata que hay.
:ram_ok
if not "%GPU_BASICA%"=="1" goto :gpu_ok
echo   AVISO: la placa de video anda con el driver basico de Microsoft, sin aceleracion.
echo          Es lo tipico de los Atom N2600 y N2800 (GMA 3600): Intel no hizo driver para
echo          Windows 10. En muchas netbooks anda el de Windows 7: si falla, se vuelve atras
echo          desde el Administrador de dispositivos. Sin driver, los videos van lentos.
:gpu_ok
if not "%ANTIRROBO%"=="1" goto :antirrobo_ok
echo   AVISO: se detecto el antirrobo de Conectar Igualdad (Theft Deterrent).
echo          Este script NO lo toca. Si la netbook no esta liberada, no lo saques del
echo          inicio de Windows: sin el, la netbook se bloquea.
:antirrobo_ok
set "_aqui=%~dp0"
if /i "%_aqui:\AppData\Local\Temp\=%"=="%_aqui%" goto :zip_ok
echo   AVISO: parece que lo estas abriendo desde adentro de un ZIP. Funciona igual,
echo          pero conviene descomprimir la carpeta primero.
:zip_ok
echo.
echo   - No crea punto de restauracion: Restaurar sistema se desactiva. Si algo
echo     sale mal, la vuelta atras es la opcion 6 del menu.
echo   - En un disco mecanico puede tardar entre 10 y 20 minutos. La primera vez,
echo     bastante mas: quitar las caracteristicas opcionales es lento.
echo   - Al terminar hay que REINICIAR la PC.
echo.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 goto :menu

echo.
echo   Unas preguntas antes de empezar. Despues no molesta mas.
echo.
choice /c SN /n /m "  1. Usas OneDrive? [S/N]: "
if errorlevel 2 (set "ONEDRIVE=N") else (set "ONEDRIVE=S")
echo.
echo   2. Quitar apps preinstaladas: Xbox, Solitario, Candy Crush, Noticias, Skype,
echo      Enlace Movil, Obtener ayuda, Sugerencias, Contactos, Mapas, Correo y
echo      Calendario, Outlook nuevo, OneNote, Notas rapidas, Alarmas, Groove,
echo      Peliculas y TV, Paint 3D, Cortana, Copilot y similares. Quedan: Store,
echo      Calculadora, Camara, Grabadora de sonidos, Clima y Recortes y anotacion.
echo      Todo se reinstala de la Store.
choice /c SN /n /m "     Quitarlas? [S/N]: "
if errorlevel 2 (set "QUITARAPPS=N") else (set "QUITARAPPS=S")

:: =========================================================================
call :titulo "1/11  Seguridad: reparando lo que otra herramienta pudo apagar"
:: =========================================================================
:: Servicios esenciales: solo se tocan si estan DESHABILITADOS, y vuelven a
:: su valor de fabrica de Windows 10. Formato servicio:tipo.
for %%s in (WinDefend:auto WdNisSvc:demand SecurityHealthService:demand wscsvc:delayed-auto mpssvc:auto BFE:auto) do call :asegurar_par %%s
for %%s in (wuauserv:demand UsoSvc:delayed-auto WaaSMedicSvc:demand BITS:delayed-auto DoSvc:delayed-auto CryptSvc:auto TrustedInstaller:demand) do call :asegurar_par %%s
for %%s in (AppXSvc:demand ClipSVC:demand InstallService:demand LicenseManager:demand TokenBroker:demand wlidsvc:demand TimeBrokerSvc:demand) do call :asegurar_par %%s
for %%s in (VSS:demand swprv:demand Appinfo:demand EventLog:auto Schedule:auto W32Time:demand KeyIso:demand VaultSvc:demand seclogon:demand SamSs:auto Winmgmt:auto) do call :asegurar_par %%s
for %%s in (Dhcp:auto Dnscache:auto NlaSvc:auto nsi:auto Audiosrv:auto AudioEndpointBuilder:auto Themes:auto ProfSvc:auto) do call :asegurar_par %%s

:: Defender: quitar politicas que lo apagan (las ponen algunos "debloaters")
set "_wd=HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
for %%v in (DisableAntiSpyware DisableAntiVirus DisableRoutinelyTakingAction ServiceKeepAlive) do call :quitar_politica "%_wd%" %%v "Defender"
for %%v in (DisableRealtimeMonitoring DisableBehaviorMonitoring DisableOnAccessProtection DisableScanOnRealtimeEnable DisableIOAVProtection) do call :quitar_politica "%_wd%\Real-Time Protection" %%v "Defender en tiempo real"
for %%v in (SpynetReporting SubmitSamplesConsent DisableBlockAtFirstSeen) do call :quitar_politica "%_wd%\Spynet" %%v "proteccion en la nube"
echo   [OK] Defender: politicas revisadas.

:: Firewall
for %%p in (DomainProfile StandardProfile PublicProfile) do call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\%%p" EnableFirewall 0x0 "Una politica apagaba el firewall"
netsh advfirewall set allprofiles state on >nul 2>&1
echo   [OK] Firewall encendido en todos los perfiles.

:: SmartScreen
call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" EnableSmartScreen 0x0 "Una politica apagaba SmartScreen"
call :quitar_si_vale "HKLM\SOFTWARE\Policies\Microsoft\Edge" SmartScreenEnabled 0x0 "Una politica apagaba SmartScreen en Edge"
call :quitar_si_vale "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\AppHost" EnableWebContentEvaluation 0x0 "SmartScreen para apps de la Store estaba apagado"
call :leer "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" SmartScreenEnabled
if /i "%_r%"=="Off" call :sz "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" SmartScreenEnabled Warn "SmartScreen para apps y archivos estaba apagado"

:: UAC: solo se repara si estaba apagado o en "no notificar nunca"
set "_uac=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
call :leer "%_uac%" EnableLUA
if "%_r%"=="0x0" call :dword "%_uac%" EnableLUA 1 "UAC estaba desactivado"
call :leer "%_uac%" ConsentPromptBehaviorAdmin
if "%_r%"=="0x0" call :dword "%_uac%" ConsentPromptBehaviorAdmin 5 "UAC estaba en no notificar nunca"
call :leer "%_uac%" PromptOnSecureDesktop
if "%_r%"=="0x0" call :dword "%_uac%" PromptOnSecureDesktop 1 "UAC no usaba el escritorio seguro"

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

:: Tareas que tienen que estar activas: desfragmentacion (clave en HDD), limpieza
:: automatica de actualizaciones viejas, aviso de disco por fallar y analisis de
:: Defender.
for %%t in ("\Microsoft\Windows\Defrag\ScheduledDefrag" "\Microsoft\Windows\Servicing\StartComponentCleanup" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup" "\Microsoft\Windows\Windows Defender\Windows Defender Verification" "\Microsoft\Windows\WindowsUpdate\Scheduled Start") do schtasks /change /tn %%t /enable >nul 2>&1
echo   [OK] Tareas de mantenimiento y seguridad activas.

:: =========================================================================
call :titulo "2/11  Script original v1: revisando lo perjudicial"
:: =========================================================================
:: Solo se repara lo que quedo en un estado perjudicial; lo que esta bien no
:: se toca. Delivery Optimization ya se reviso en el paso 1. Los placebos
:: IOPageLockLimit y DontVerifyRandomDrivers no hacen dano: se dejan.
set "_reparado=0"
:: SysMain: compresion de memoria. Teclado tactil: escritura en el Inicio,
:: Configuracion y apps UWP. Biometria: huella. Ubicacion: luz nocturna.
call :asegurar SysMain auto
call :asegurar TabletInputService demand
call :asegurar WbioSrvc demand
call :asegurar lfsvc demand
:: Con poca RAM, fijar el kernel en memoria le saca RAM a los programas.
call :leer "%_mm%" DisablePagingExecutive
if /i "%_r%"=="0x1" (
    call :dword "%_mm%" DisablePagingExecutive 0
    set "_reparado=1"
    echo   [REPARADO] DisablePagingExecutive estaba en 1: vuelve a 0.
)
if "%_reparado%"=="0" echo   [OK] Nada perjudicial del v1: SysMain, teclado tactil, biometria, ubicacion
if "%_reparado%"=="0" echo        y DisablePagingExecutive estan bien.
:: Compresion de memoria activa y sin precarga de apps UWP en RAM.
sc start SysMain >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue; Disable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue" >nul 2>&1
echo   [OK] Compresion de memoria activa.

:: =========================================================================
call :titulo "3/11  Servicios: Manual siempre que se pueda"
:: =========================================================================
:: Deshabilitados: telemetria, Xbox y Registro remoto.
for %%s in (DiagTrack dmwappushservice RemoteRegistry) do call :servicio %%s disabled
for %%s in (XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc xbgm) do call :servicio %%s disabled
echo   [OK] Deshabilitados: telemetria, Xbox y Registro remoto.
:: Indexador de busqueda: en un disco mecanico lee y relee el disco; en un SSD
:: no molesta y queda como de fabrica.
if "%SSD%"=="1" (call :servicio WSearch delayed-auto) else (call :servicio WSearch disabled)
if "%SSD%"=="1" (echo   [OK] Indexador de busqueda: como de fabrica, el disco es SSD.) else (echo   [OK] Indexador de busqueda: deshabilitado, castiga al disco mecanico.)
:: Bluetooth: con 4 GB o mas queda en Manual, su valor de fabrica (sin adaptador
:: no gasta nada); con menos, deshabilitado.
set "_bt=disabled"
if "%PERFIL_4GB%"=="1" set "_bt=demand"
for %%s in (bthserv BTAGService BthAvctpSvc) do call :servicio %%s %_bt%
if "%PERFIL_4GB%"=="1" (echo   [OK] Bluetooth: Manual, su valor de fabrica.) else (echo   [OK] Bluetooth: deshabilitado.)
:: Manual: arrancan solo cuando algo los necesita.
for %%s in (PcaSvc TrkWks iphlpsvc DPS CDPSvc MapsBroker edgeupdate lfsvc WbioSrvc RetailDemo) do call :servicio %%s demand
echo   [OK] En Manual: PcaSvc, TrkWks, iphlpsvc, DPS, CDPSvc, MapsBroker, edgeupdate,
echo        lfsvc, WbioSrvc y RetailDemo.
:: Automatico retrasado: tienen que correr solos, pero pueden esperar al arranque.
for %%s in (BITS WpnService) do call :servicio %%s delayed-auto
echo   [OK] Automatico retrasado: BITS y WpnService.
:: Impresion y compartir en red, siempre activos: una impresora o una carpeta
:: compartida que dejan de andar sin aviso cuestan mas que los pocos MB que ahorran.
call :servicio Spooler delayed-auto
call :servicio LanmanServer auto
echo   [OK] Impresion: Automatico retrasado. Compartir en red: Automatico.

:: =========================================================================
call :titulo "4/11  Tareas programadas de telemetria"
:: =========================================================================
for %%t in ("\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "\Microsoft\Windows\Autochk\Proxy" "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Maps\MapsUpdateTask" "\Microsoft\Windows\Maps\MapsToastTask" "\Microsoft\Windows\Windows Error Reporting\QueueReporting" "\Microsoft\Windows\Maintenance\WinSAT" "\Microsoft\XblGameSave\XblGameSaveTask") do schtasks /change /tn %%t /disable >nul 2>&1
echo   [OK] Desactivadas: Compatibility Appraiser, CEIP, comentarios, mapas,
echo        informe de errores, WinSAT y Xbox.

:: =========================================================================
call :titulo "5/11  Defender: solo lo imprescindible"
:: =========================================================================
:: Se queda: tiempo real, comportamiento, nube, descargas, firmas, SmartScreen.
:: Se suma el bloqueo de aplicaciones potencialmente no deseadas: adware, toolbars,
:: "optimizadores". Se recortan los analisis programados y lo que no protege.
:: Un Set-MpPreference por ajuste: si esta version de Windows no conoce uno, los
:: demas se aplican igual.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue; Set-MpPreference -EnableLowCpuPriority $true -ErrorAction SilentlyContinue; Set-MpPreference -ScanAvgCPULoadFactor 20 -ErrorAction SilentlyContinue; Set-MpPreference -ScanOnlyIfIdleEnabled $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableCatchupFullScan $true -ErrorAction SilentlyContinue; Set-MpPreference -DisableCatchupQuickScan $true -ErrorAction SilentlyContinue" >nul 2>&1
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" DisableEnhancedNotifications 1
:: El icono de la bandeja se queda: es la forma de ver de un vistazo que Defender
:: anda. Si una version anterior de este script lo oculto, vuelve.
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray" HideSystray
call :dword "HKLM\SOFTWARE\Policies\Microsoft\MRT" DontOfferThroughWUAU 1
echo   [OK] Bloqueo de aplicaciones potencialmente no deseadas (PUA) activado.
echo   [OK] Analisis programados: prioridad baja, maximo 20%% de CPU, solo con la PC inactiva.
echo   [OK] Sin notificaciones no criticas. El icono de la bandeja queda visible.
echo   [OK] Sin la herramienta MRT mensual, redundante con Defender en tiempo real.

:: =========================================================================
call :titulo "6/11  Telemetria, publicidad y procesos en segundo plano"
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

:: Apps en segundo plano: todas apagadas con el interruptor general. Contra: la
:: busqueda del Inicio puede tardar en encontrar las apps recien instaladas.
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" GlobalUserDisabled 1
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" BackgroundAppGlobalToggle 0
echo   [OK] Apps en segundo plano: todas apagadas con el interruptor general.
:: Microsoft Store: las apps se actualizan a mano, abriendola. Desde 2025 la Store
:: solo deja pausar de 1 a 5 semanas; la politica de equipo "Desactivar la descarga
:: e instalacion automatica de actualizaciones" sigue mandando. Va tambien el valor
:: que escribia el viejo interruptor de la Store, para Stores sin actualizar.
call :dword "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" AutoDownload 2
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" AutoDownload 2
echo   [OK] Microsoft Store: las apps ya no se actualizan solas. Para actualizarlas,
echo        abri la Store: Biblioteca, Obtener actualizaciones.

:: =========================================================================
call :titulo "7/11  Interfaz y Explorador"
:: =========================================================================
set "_desk=%UHIVE%\Control Panel\Desktop"
set "_adv=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
call :sz "%_desk%" DragFullWindows 1
call :sz "%_desk%" MenuShowDelay 100
call :sz "%_desk%" FontSmoothing 2
call :dword "%_desk%" FontSmoothingType 2
if "%EFECTOS%"=="1" goto :visual_apariencia
:: Efectos visuales en "mejor rendimiento", salvo:
::  - el suavizado de fuentes: no es un efecto, es lo que hace legible el texto;
::  - mostrar el contenido de la ventana mientras se arrastra;
::  - la animacion al minimizar y maximizar, solo si la placa de video tiene
::    driver: con el adaptador basico la dibuja el procesador y va a los saltos.
reg add "%_desk%" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
set "_minanim=1"
if "%GPU_BASICA%"=="1" set "_minanim=0"
call :sz "%_desk%\WindowMetrics" MinAnimate %_minanim%
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting 3
call :dword "%_adv%" ListviewAlphaSelect 0
call :dword "%_adv%" ListviewShadow 0
call :dword "%_adv%" TaskbarAnimations 0
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 0
:: Sin el desenfoque "acrilico" de la pantalla de inicio de sesion: otro efecto de
:: transparencia, y sin aceleracion de video lo calcula el procesador.
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon 1
echo   [OK] Efectos visuales al minimo. Quedan el suavizado de fuentes y el contenido
echo        de la ventana al arrastrar.
if "%_minanim%"=="1" echo   [OK] Animacion al minimizar y maximizar: activada, el video tiene driver.
if "%_minanim%"=="0" echo   [OK] Animacion al minimizar y maximizar: apagada, el video no tiene driver.
echo   [OK] Menus mas rapidos, sin transparencias, animaciones ni desenfoque al iniciar sesion.
goto :visual_listo
:visual_apariencia
:: 4 GB o mas y video con driver: "mejor apariencia", con todos los efectos,
:: transparencias y el desenfoque del inicio de sesion. Los menus siguen rapidos.
reg add "%_desk%" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f >nul 2>&1
call :sz "%_desk%\WindowMetrics" MinAnimate 1
call :dword "%_adv%" ListviewAlphaSelect 1
call :dword "%_adv%" ListviewShadow 1
call :dword "%_adv%" TaskbarAnimations 1
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 1
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 1
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon
:: Las miniaturas van siempre, asi que es "mejor apariencia" completa.
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting 1
echo   [OK] Efectos visuales en "mejor apariencia": hay 4 GB o mas y el video tiene driver.
echo   [OK] Menus rapidos (100 ms en vez de 400).
:visual_listo
:: Miniaturas siempre, aun en disco mecanico: sin la vista previa no se
:: encuentran las fotos, y eso pesa mas que la lectura extra al abrir la carpeta.
:: Se escribe 0 para que tambien vuelvan en una PC donde una version anterior las apago.
call :dword "%_adv%" IconsOnly 0
:: El Explorador abre en "Este equipo" y no rastrea los programas abiertos.
call :dword "%_adv%" LaunchTo 1
call :dword "%_adv%" Start_TrackProgs 0
:: Sin deteccion automatica del tipo de carpeta (tweak de WinUtil).
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
call :sz "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" FolderType NotSpecified
echo   [OK] Explorador: abre en Este equipo, muestra miniaturas y no
echo        adivina el tipo de cada carpeta.
:: Ubicacion: la luz nocturna la usa para saber a que hora anochece. Se borran
:: las politicas que la apagan y se permite para el equipo y para el usuario.
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" DisableLocation
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" DisableLocationScripting
call :sz "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" Value Allow
call :sz "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" Value Allow
echo   [OK] Ubicacion activada: la luz nocturna la usa para el horario del sol.
:: Luz nocturna del anochecer al amanecer (seccion LUZ, al final del archivo).
call :ps LUZ
if "%GPU_BASICA%"=="1" echo        Con el adaptador de video basico, Windows no ofrece la luz nocturna.

:: =========================================================================
call :titulo "8/11  Memoria, disco y energia"
:: =========================================================================
fsutil behavior set DisableLastAccess 1 >nul 2>&1
fsutil behavior set Disable8dot3 1 >nul 2>&1
echo   [OK] NTFS sin registro de ultimo acceso ni nombres cortos 8.3.

:: Archivo de paginacion, cache de escritura del disco, CompactOS y Restaurar
:: sistema, en la seccion DISCO.
call :ps DISCO

:: Energia: la prioridad es la velocidad, no el ahorro. Se aplica a los tres
:: planes de Windows, por si alguien cambia de plan despues:
::  - el disco nunca se apaga solo: despertarlo congela la PC varios segundos;
::  - la pantalla se apaga a los 15 minutos sin uso, en cualquier equipo, con
::    cargador y con bateria;
::  - suspende sola a las 4 horas sin uso: le da tiempo de sobra al mantenimiento
::    automatico de Windows, que corre con la PC prendida y sin uso. Con 4 GB o
::    mas, a la hora: esas PCs lo terminan antes. Nunca hiberna;
::  - boton de encendido: apagado completo; tapa: apagado completo, o suspender
::    con 4 GB o mas; boton de suspension: nada;
::  - bateria critica: apagado completo, la unica salida prolija sin hibernacion.
set "_susp=14400"
set "_tapa=3"
if "%PERFIL_4GB%"=="1" set "_susp=3600"
if "%PERFIL_4GB%"=="1" set "_tapa=1"
for %%p in (381b4222-f694-41f0-9685-ff5bb260df2e 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c a1841308-3541-4fab-bc81-f71556f20b4a) do call :energia_plan %%p
:: Plan de Alto rendimiento en todas las PCs, notebooks incluidas. Si el plan no
:: existe, se crea a partir del original de Windows. Si tampoco se puede, queda
:: el plan que estaba, con los mismos ajustes.
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
if errorlevel 1 goto :energia_alto_listo
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo   [OK] Plan de energia: Alto rendimiento, tambien en notebooks.
:energia_alto_listo
:: Los ajustes van tambien al plan activo, sea cual sea (por ejemplo, uno del
:: fabricante), y se reactiva para que rijan desde ahora.
call :energia_plan SCHEME_CURRENT
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo   [OK] El disco nunca se apaga solo y la PC nunca hiberna.
echo   [OK] La pantalla se apaga a los 15 minutos sin uso.
if "%PERFIL_4GB%"=="1" (echo   [OK] Suspension a la hora sin uso.) else (echo   [OK] Suspension a las 4 horas sin uso: da tiempo al mantenimiento de Windows.)
if "%PERFIL_4GB%"=="1" (echo   [OK] Tapa: suspende. Boton de encendido: apagado completo. Boton de suspension: nada.) else (echo   [OK] Boton de encendido y tapa: apagado completo. Boton de suspension: nada.)
echo   [OK] Bateria critica: apagado completo.
:: Sin hibernacion ni inicio rapido: cada apagado es completo, cada arranque es
:: limpio y se borra hiberfil.sys: el 40% de la RAM, unos 800 MB con 2 GB.
powercfg /hibernate off >nul 2>&1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled 0
:: Hibernar, fuera del menu de apagado. Suspender tambien, salvo con 4 GB o mas.
set "_menususp=0"
if "%PERFIL_4GB%"=="1" set "_menususp=1"
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowSleepOption %_menususp%
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowHibernateOption 0
echo   [OK] Sin hibernacion ni inicio rapido: cada apagado es completo.
if "%PERFIL_4GB%"=="1" (echo   [OK] Menu de apagado: Suspender queda, Hibernar no aparece.) else (echo   [OK] Suspender e Hibernar ya no aparecen en el menu de apagado.)

:: =========================================================================
call :titulo "9/11  Navegadores"
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
call :titulo "10/11  Opcionales, clasicos de Windows 7 y Adobe Reader"
:: =========================================================================
if "%ONEDRIVE%"=="S" goto :onedrive_listo
reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
echo   [OK] OneDrive ya no arranca con Windows. No se desinstalo.
:onedrive_listo
:: Visualizador de fotos de Windows, el de Windows 7: sigue instalado, pero
:: Windows 10 le saco las fotos comunes. Se le devuelven con su nombre y su
:: icono de siempre, y se registra en "Abrir con" y en Aplicaciones predeterminadas.
call :visor_tipo Jpeg jpegfile "Imagen JPEG" .jpg .jpeg .jpe .jfif
call :visor_tipo Png pngfile "Imagen PNG" .png
call :visor_tipo Gif giffile "Imagen GIF" .gif
call :visor_tipo Bitmap Paint.Picture "Imagen de mapa de bits" .bmp .dib
:: Formatos nuevos: el visualizador los abre con los codecs de las extensiones
:: de la Store. WebP viene con Windows 10; HEIC y HEIF piden HEIF (gratis) y
:: HEVC; AVIF pide AV1 (gratis). No tienen tipo clasico: usan el icono de JPEG.
call :visor_tipo Webp jpegfile "Imagen WebP" .webp
call :visor_tipo Heic jpegfile "Imagen HEIC" .heic .heif
call :visor_tipo Avif jpegfile "Imagen AVIF" .avif
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /t REG_SZ /d "Software\Microsoft\Windows Photo Viewer\Capabilities" /f >nul 2>&1
set "_app=HKLM\SOFTWARE\Classes\Applications\photoviewer.dll"
reg add "%_app%\shell\open" /v MuiVerb /t REG_SZ /d "@photoviewer.dll,-3043" /f >nul 2>&1
reg add "%_app%\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul 2>&1
reg add "%_app%\shell\open\DropTarget" /v Clsid /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul 2>&1
for %%e in (.jpg .jpeg .jpe .jfif .png .gif .bmp .dib .tif .tiff .webp .heic .heif .avif) do reg add "%_app%\SupportedTypes" /v %%e /t REG_SZ /d "" /f >nul 2>&1
echo   [OK] Visualizador de fotos de Windows para JPG (JPEG, JFIF), PNG, GIF, BMP,
echo        WebP, HEIC y AVIF. HEIC y AVIF necesitan extensiones de la Store.
:: Alt+Tab clasico: iconos en vez de miniaturas en vivo de cada ventana. Con
:: 4 GB y video con driver queda el moderno: las miniaturas las dibuja la placa.
if "%EFECTOS%"=="1" (call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer" AltTabSettings) else (call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer" AltTabSettings 1)
if "%EFECTOS%"=="1" (echo   [OK] Alt+Tab moderno, con miniaturas: el video tiene driver.) else (echo   [OK] Alt+Tab clasico activado.)
:: Apps preinstaladas (si se eligio), app Fotos, caracteristicas opcionales y
:: Adobe Reader, en la seccion QUITAR. Sale con 2 si Adobe Reader esta instalado.
set "ADOBE=N"
call :ps QUITAR
if errorlevel 2 set "ADOBE=S"
if "%QUITARAPPS%"=="N" goto :apps_listo
:: Sin Correo, Calendario ni Contactos, sus servicios de sincronizacion no tienen
:: nada que hacer. Son servicios por usuario: se deshabilita la plantilla y rige
:: desde el proximo inicio de sesion.
for %%s in (OneSyncSvc PimIndexMaintenanceSvc UnistoreSvc UserDataSvc MessagingService) do call :servicio %%s disabled
echo   [OK] Deshabilitados sus servicios de sincronizacion: OneSyncSvc,
echo        PimIndexMaintenanceSvc, UnistoreSvc, UserDataSvc y MessagingService.
:apps_listo

:: =========================================================================
call :titulo "11/11  Limpieza de temporales"
:: =========================================================================
:: Vaciado de todas las carpetas temporales de Windows. El codigo esta en la
:: seccion LIMPIEZA al final de este archivo. Lo que esta en uso se saltea, y la
:: carpeta desde la que corre el script tambien, por si se abrio desde un ZIP.
:: Los navegadores no se cierran: perder lo que la persona tenia abierto cuesta mas
:: que la cache que queda sin vaciar. Con Chrome o Edge abiertos, lo que tienen en
:: uso se saltea como cualquier otro archivo y el resto se borra.
echo   Vaciando temporales. Lo que Windows tiene en uso se saltea solo.
set "OPT_SELF=%~dp0"
call :ps LIMPIEZA
echo   [OK] Limpieza terminada.
:: Papelera: el Sensor de almacenamiento borra solo lo que tenga mas de 30 dias.
:: Corre una vez por semana; tambien limpia temporales que las apps no usan.
:: Descargas nunca se toca (32 = 0).
set "_ss=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
call :dword "%_ss%" 01 1
call :dword "%_ss%" 08 1
call :dword "%_ss%" 256 30
call :dword "%_ss%" 04 1
call :dword "%_ss%" 32 0
call :dword "%_ss%" 2048 7
call :dword "%_ss%" StoragePoliciesNotified 1
echo   [OK] Papelera: se vacia sola lo que tenga mas de 30 dias (revision semanal).

:: =========================================================================
call :titulo "Ultimos pasos"
:: =========================================================================
:: Estado de Defender y programas que arrancan con Windows (seccion FINAL).
call :ps FINAL
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC para aplicar todo.
echo.
if "%SSD%"=="1" goto :fin_busqueda_listo
echo   Para buscar archivos: Windows Search queda apagado porque castiga el disco.
echo   Everything, de voidtools.com, encuentra cualquier archivo al instante.
echo.
:fin_busqueda_listo
if "%PERFIL_4GB%"=="1" (echo   Energia: el boton de encendido ahora APAGA la PC; cerrar la tapa la suspende.) else (echo   Energia: cerrar la tapa o apretar el boton de encendido ahora APAGA la PC,)
if not "%PERFIL_4GB%"=="1" echo   sin suspender. Guarda lo que estes haciendo antes.
echo.
echo   Seguridad: Windows 10 recibe parches gratis hasta el 12/10/2027 si la PC
echo   esta inscripta en ESU. Revisalo en Configuracion, Windows Update.
echo.
echo   Fotos: despues de reiniciar, en Configuracion, Aplicaciones, Aplicaciones
echo   predeterminadas, Visor de fotos, elegi "Visualizador de fotos de Windows".
echo   O abri una foto y, cuando pregunte con que, elegilo y marca "Usar siempre".
if not "%ADOBE%"=="S" goto :final_sin_adobe
echo.
echo   PDF: para abrirlos con Edge o Chrome en vez de Adobe Reader, en Configuracion,
echo   Aplicaciones, Aplicaciones predeterminadas, Elegir aplicaciones predeterminadas
echo   por tipo de archivo, busca .pdf y elegi el navegador. Como Reader ya no se
echo   actualiza solo, si no lo usas para nada conviene desinstalarlo.
:final_sin_adobe
echo ==========================================================================
goto :fin_con_reinicio

:: =========================================================================
::  2. VERIFICAR ESTADO (solo lectura). El reporte esta en PowerShell, en la
::  seccion VERIFICAR al final de este archivo, y se guarda en un .txt al lado.
:: =========================================================================
:op_verificar
title Optimizar PC Vieja v2 - Verificar estado
cls
call :ps VERIFICAR
goto :menu

:: =========================================================================
::  3. LIMPIAR RESTOS DE WINDOWS UPDATE
::  Cada actualizacion guarda la version anterior de lo que reemplaza, en
::  C:\Windows\WinSxS. Windows las borra solo recien a los 30 dias y con una
::  tarea que se corta a la hora. Aca se hace completo con DISM:
::  /StartComponentCleanup /ResetBase. Opcion avanzada: pide confirmacion.
::  No usa /SPSuperseded: limpia restos de Service Packs, y Windows 10 no tiene.
:: =========================================================================
:op_limpiar_wu
title Optimizar PC Vieja v2 - Limpiar restos de Windows Update
cls
echo ==========================================================================
echo   LIMPIAR RESTOS DE WINDOWS UPDATE
echo ==========================================================================
echo.
echo   DISM /StartComponentCleanup /ResetBase: las actualizaciones instaladas ya
echo   no se podran desinstalar. Puede tardar mas de una hora: no apagues la PC.
echo.
:: Pregunta antes de empezar: el menu responde a una sola tecla, sin Enter, y
:: esta opcion es la 2, pegada a la 1. Sin esto, un 2 por error arrancaba una
:: hora de DISM que no se puede deshacer.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 goto :menu
echo.

:: DISM trabaja con el Instalador de modulos de Windows. Si otra herramienta
:: lo deshabilito, vuelve a su valor de fabrica: Manual.
reg query "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v Start 2>nul | find "0x4" >nul
if errorlevel 1 goto :wu_instalador_ok
sc config TrustedInstaller start= demand >nul 2>&1
if errorlevel 1 reg add "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo   [REPARADO] El Instalador de modulos de Windows estaba deshabilitado: vuelve a Manual.
:wu_instalador_ok

if not exist "%SystemRoot%\WinSxS\pending.xml" goto :wu_sin_pendientes
echo   [!] Hay cambios de Windows esperando un reinicio: DISM no puede limpiar.
echo       Reinicia la PC y volve a elegir esta opcion.
goto :menu
:wu_sin_pendientes

:: Windows 10 trae DisableResetbase en 1: asi /ResetBase no rebasa, solo
:: comprime. Durante la limpieza va en 0, con SupersededActions en 3 (1 antes
:: de 1903), como hace W10UI de abbodi1406. Al terminar se restauran los
:: valores originales: el mantenimiento automatico sigue como de fabrica. Se
:: detiene el Instalador de modulos para que tome la configuracion nueva.
set "_sxs=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
set "_bld=0"
for /f "tokens=3" %%b in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "_bld=%%b"
set "_sa_nuevo=3"
if %_bld% LSS 18362 set "_sa_nuevo=1"
call :leer "%_sxs%" DisableResetbase
set "_drb=%_r%"
call :leer "%_sxs%" SupersededActions
set "_sa=%_r%"
net stop wuauserv >nul 2>&1
net stop trustedinstaller >nul 2>&1
reg add "%_sxs%" /v DisableResetbase /t REG_DWORD /d 0 /f >nul 2>&1
reg add "%_sxs%" /v SupersededActions /t REG_DWORD /d %_sa_nuevo% /f >nul 2>&1

call :titulo "1/2  Limpieza de las versiones viejas (WinSxS)"
call :libre LIBRE_ANTES
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
set "DISM_RC=%errorlevel%"
if defined _drb (reg add "%_sxs%" /v DisableResetbase /t REG_DWORD /d %_drb% /f >nul 2>&1) else (reg delete "%_sxs%" /v DisableResetbase /f >nul 2>&1)
if defined _sa (reg add "%_sxs%" /v SupersededActions /t REG_DWORD /d %_sa% /f >nul 2>&1) else (reg delete "%_sxs%" /v SupersededActions /f >nul 2>&1)
if not "%DISM_RC%"=="0" goto :wu_error
call :libre LIBRE_DESPUES

call :titulo "2/2  Resultado"
set /a LIBERADO=LIBRE_DESPUES-LIBRE_ANTES
if %LIBERADO% LSS 0 set "LIBERADO=0"
echo   Espacio liberado: %LIBERADO% MB.
echo   La limpieza automatica de Windows sigue activa y se encarga del resto.
echo   Si vas a desfragmentar (opcion 3), ahora es el momento: hay menos que mover.
goto :menu

:wu_error
call :a_hex %DISM_RC%
echo.
echo   [!] DISM termino con el error %_hex%.
if /i "%_hex%"=="0x800F0806" echo       Hay una actualizacion esperando un reinicio.
echo       Lo mas comun: una actualizacion a medio instalar. Reinicia la PC, deja
echo       que Windows Update termine y volve a elegir esta opcion.
echo       El detalle queda en C:\Windows\Logs\DISM\dism.log.
goto :menu

:: =========================================================================
::  4. DESFRAGMENTAR A FONDO (para discos mecanicos)
::  El desfragmentador automatico trabaja "por encima" a proposito: ignora los
::  fragmentos de mas de 64 MB y no junta el espacio libre. Aca se le pide el
::  trabajo completo: analisis, desfragmentacion completa (/W, o /D si Windows
::  no la acepta), consolidar el espacio libre (/X), optimizar el arranque (/B)
::  y analisis final. En un SSD no desfragmenta: solo manda TRIM (/L).
:: =========================================================================
:op_desfragmentar
title Optimizar PC Vieja v2 - Desfragmentar a fondo
set "DISCO=%SystemDrive%"
set "MEDIO=desconocido"
for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$n=(Get-Partition -DriveLetter $env:SystemDrive.Substring(0,1)).DiskNumber; $d=Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$n } | Select-Object -First 1; if ($d) { [string]$d.MediaType } else { 'desconocido' }"`) do set "MEDIO=%%m"

:: Con menos de 15% libre, defrag solo desfragmenta en parte: usa ese espacio
:: para acomodar los pedazos.
set "LIBRE_PCT=100"
for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$v=Get-Volume -DriveLetter $env:SystemDrive.Substring(0,1); [string][math]::Floor(100 * $v.SizeRemaining / $v.Size)"`) do set "LIBRE_PCT=%%m"

cls
echo ==========================================================================
echo   DESFRAGMENTAR A FONDO - disco %DISCO%
echo ==========================================================================
echo.
echo   Tipo de disco detectado: %MEDIO%
echo   Espacio libre: %LIBRE_PCT%%%
if %LIBRE_PCT% LSS 15 echo   AVISO: con menos de 15%% libre, Windows solo desfragmenta en parte. Antes,
if %LIBRE_PCT% LSS 15 echo   libera espacio: Papelera, opcion 2 del menu o el Liberador de espacio.
if /i "%MEDIO%"=="SSD" goto :desfrag_ssd
if /i not "%MEDIO%"=="HDD" echo   AVISO: no se pudo confirmar que sea un disco mecanico. Si es un SSD, cancela.
echo.
echo   Pasos: analisis, desfragmentacion completa, consolidar el espacio libre,
echo   optimizar el arranque y analisis final.
echo.
echo   - En un Atom con disco lento puede tardar VARIAS HORAS. Dejala enchufada.
echo   - Mientras tanto la PC va a andar lenta: mejor no usarla.
echo   - Se puede cortar en cualquier momento con Ctrl+C. No se rompe nada.
echo   - Conviene hacer antes las opciones 1 y 2: borran temporales y restos de
echo     actualizaciones, y hay menos que mover.
echo.
choice /c SN /n /m "  Empezar? [S/N]: "
if errorlevel 2 goto :menu

call :titulo "1/5  Analisis inicial"
defrag %DISCO% /A /V

call :titulo "2/5  Desfragmentacion completa, incluidos los fragmentos grandes"
defrag %DISCO% /W /H /U /V
if "%errorlevel%"=="0" goto :desfrag_completa_ok
echo.
echo   Esta version de Windows no acepta la desfragmentacion completa (/W).
echo   Se hace la normal, que deja los fragmentos de mas de 64 MB como estan.
defrag %DISCO% /D /H /U /V
:desfrag_completa_ok

call :titulo "3/5  Consolidar el espacio libre"
defrag %DISCO% /X /H /U /V

call :titulo "4/5  Optimizar el arranque"
:: Usa el mapa de arranque de la carpeta Prefetch (Layout.ini). La opcion 1 lo
:: conserva al limpiar; si alguien vacio la carpeta entera, Windows tarda unos
:: dias en rehacerlo y este paso no tiene con que trabajar.
defrag %DISCO% /B /H /U /V

call :titulo "5/5  Analisis final"
defrag %DISCO% /A /V

echo.
echo ==========================================================================
echo   LISTO. Compara el porcentaje de fragmentacion del analisis inicial y del
echo   final. La optimizacion semanal automatica de Windows sigue activa.
echo ==========================================================================
goto :menu

:desfrag_ssd
echo.
echo   Es un SSD: desfragmentarlo no lo acelera y le gasta escrituras.
echo   Lo que necesita es TRIM, que avisa al disco que bloques estan libres.
choice /c SN /n /m "  Mandar TRIM ahora? [S/N]: "
if errorlevel 2 goto :menu
defrag %DISCO% /L /U /V
goto :menu

:: =========================================================================
::  5. REVERTIR LA OPTIMIZACION
::  Vuelve a los valores de fabrica de Windows 10 lo que la opcion 1 cambia y
::  que podria molestar. A proposito NO revierte la seguridad reparada, las
::  correcciones del v1, la telemetria apagada ni las apps quitadas (se
::  reinstalan desde la Store).
:: =========================================================================
:op_revertir
title Optimizar PC Vieja v2 - Revertir
call :detectar
cls
echo ==========================================================================
echo   REVERTIR LA OPTIMIZACION
echo ==========================================================================
echo.
echo   Usuario: "%UNAME%"
echo.
echo   Vuelve a fabrica: servicios, apps en segundo plano, efectos visuales,
echo   Explorador, energia, navegadores, recortes de Defender, tareas, cache de
echo   escritura del disco y el actualizador de Adobe Reader.
echo   NO apaga la seguridad ni vuelve a encender la telemetria.
echo.
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 goto :menu

call :titulo "Servicios: valores de fabrica de Windows 10"
for %%s in (DiagTrack PcaSvc TrkWks iphlpsvc DPS WpnService Spooler LanmanServer SysMain) do call :servicio %%s auto
for %%s in (WSearch CDPSvc MapsBroker edgeupdate BITS DoSvc) do call :servicio %%s delayed-auto
for %%s in (dmwappushservice XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc xbgm bthserv BTAGService BthAvctpSvc lfsvc WbioSrvc RetailDemo TabletInputService) do call :servicio %%s demand
:: Los de Correo, Calendario y Contactos: vuelven a fabrica por si las apps vuelven.
call :servicio OneSyncSvc delayed-auto
for %%s in (PimIndexMaintenanceSvc UnistoreSvc UserDataSvc MessagingService) do call :servicio %%s demand
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -ApplicationPreLaunch -ErrorAction SilentlyContinue; $b='%UPS%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Get-ChildItem -LiteralPath $b -ErrorAction SilentlyContinue | ForEach-Object { Remove-ItemProperty -LiteralPath $_.PSPath -Name Disabled,DisabledByUser -ErrorAction SilentlyContinue }" >nul 2>&1
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" GlobalUserDisabled
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" BackgroundAppGlobalToggle
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" AutoDownload
call :borrar "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" AutoDownload
reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings" /f >nul 2>&1
for %%v in (01 04 08 32 256 2048 StoragePoliciesNotified) do call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" %%v
echo   [OK] Noticias e intereses, Cortana, destacados, informe de errores, precarga,
echo        apps en segundo plano, actualizacion de la Store, luz nocturna y Sensor
echo        de almacenamiento como de fabrica. La ubicacion queda activada.

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
call :dword "%_adv%" IconsOnly 0
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

call :titulo "Cache de escritura del disco"
:: Sin PowerShell: el disco ya lo identifico EQUIPO. Fuera de un bloque con
:: parentesis, por si el identificador del disco trajera alguno.
if defined DISCO_PNP reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%DISCO_PNP%\Device Parameters\Disk" /v CacheIsPowerProtected /f >nul 2>&1
if defined DISCO_PNP echo   [OK] El vaciado del bufer de escritura vuelve a estar activo, como de fabrica.
if not defined DISCO_PNP echo   No se encontro el disco del sistema: nada que revertir.

call :titulo "Archivo de paginacion"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cs=Get-CimInstance Win32_ComputerSystem; if ($cs.AutomaticManagedPagefile) { Write-Output '  [OK] El archivo de paginacion ya es automatico.'; exit 0 }; $ram=[int]$env:RAM_INST; $mb=[int][math]::Min($ram * 2, 8192); $nombre=$env:SystemDrive + '\pagefile.sys'; $pf=Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -eq $nombre } | Select-Object -First 1; if ($pf -and (@($mb, [int]($ram * 2)) -contains [int]$pf.InitialSize) -and $pf.MaximumSize -eq $pf.InitialSize) { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true}; Write-Output '  [OK] El archivo de paginacion vuelve a ser automatico, como de fabrica.' } else { Write-Output '  [OK] El archivo de paginacion lo configuro alguien a mano: se deja como esta.' }"

call :titulo "Energia"
:: Herramienta oficial: vuelve los planes de Windows a fabrica, con sus botones,
:: tapa, suspension y tiempos de disco, y deja activo el plan Equilibrado.
powercfg -restoredefaultschemes >nul 2>&1
powercfg /hibernate on >nul 2>&1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled 1
call :borrar "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowSleepOption
call :borrar "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowHibernateOption
echo   [OK] Planes de energia de fabrica: Equilibrado, botones, tapa y suspension.
echo   [OK] Hibernacion e inicio rapido activados; Suspender vuelve al menu de apagado.

call :titulo "Restaurar sistema"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction SilentlyContinue" >nul 2>&1
schtasks /change /tn "\Microsoft\Windows\SystemRestore\SR" /enable >nul 2>&1
echo   [OK] Restaurar sistema activado, como viene de fabrica.
echo        Los puntos de restauracion borrados no vuelven: empiezan de cero.

call :titulo "Navegadores"
set "_edge=HKLM\SOFTWARE\Policies\Microsoft\Edge"
for %%v in (StartupBoostEnabled BackgroundModeEnabled HubsSidebarEnabled WebWidgetAllowed ShowRecommendationsEnabled EdgeShoppingAssistantEnabled ShowMicrosoftRewards PersonalizationReportingEnabled DiagnosticData UserFeedbackAllowed HideFirstRunExperience) do call :borrar "%_edge%" %%v
call :borrar "%_edge%\Recommended" SleepingTabsEnabled
call :borrar "%_edge%\Recommended" SleepingTabsTimeout
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" CreateDesktopShortcutDefault
call :borrar "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled
for %%v in (BrowserSignin BrowserAddPersonEnabled PromotionalTabsEnabled PrivacySandboxPromptEnabled DefaultBrowserSettingEnabled) do call :borrar "HKLM\SOFTWARE\Policies\Google\Chrome" %%v
echo   [OK] Politicas de Edge y Chrome quitadas, incluidas las de Chrome de aula.

call :titulo "Adobe Reader"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Service -Name AdobeARMservice -ErrorAction SilentlyContinue)) { Write-Output '  Adobe Reader no esta instalado: nada que revertir.'; exit 0 }; Set-Service -Name AdobeARMservice -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name AdobeARMservice -ErrorAction SilentlyContinue; Get-ScheduledTask -TaskName 'Adobe Acrobat Update Task*' -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null; Write-Output '  [OK] Adobe Reader: actualizacion automatica activada otra vez.'; Write-Output '       Las entradas de inicio viejas no vuelven: Reader no las necesita.'"

echo.
echo   Para recuperar lo que no se revierte solo:
echo    - OneDrive: abrilo una vez y vuelve a arrancar con Windows.
echo    - Apps quitadas: se reinstalan gratis desde la Microsoft Store.
echo    - Caracteristicas opcionales: Configuracion, Aplicaciones, Caracteristicas
echo      opcionales, Agregar una caracteristica.
echo    - App Fotos: buscala en la Store como "Microsoft Fotos". El Visualizador de
echo      fotos clasico queda disponible: no molesta y no ocupa nada.
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC. Usa "Reiniciar", no "Apagar".
echo ==========================================================================
goto :fin_con_reinicio

:: =========================================================================
::  6. INSTALAR CHROME, WINRAR Y VLC
::  Con winget, el instalador de programas que trae Windows 10, en silencio y
::  sin preguntas. Del mas chico al mas grande: WinRAR, VLC y Chrome. A Chrome
::  se le agrega uBlock Origin Lite con la politica oficial de instalacion
::  forzada (ExtensionInstallForcelist): Chrome la baja sola de la Web Store.
:: =========================================================================
:op_instalar
title Optimizar PC Vieja v2 - Instalar Chrome, WinRAR y VLC
cls
echo ==========================================================================
echo   INSTALAR WINRAR, VLC Y CHROME
echo ==========================================================================
echo.
echo   Se instalan con winget, en silencio y uno por uno. Hace falta internet.
echo   Si alguno ya esta instalado, se saltea.
call :buscar_winget
if errorlevel 1 goto :menu
call :instalar RARLab.WinRAR "WinRAR"
call :instalar VideoLAN.VLC "VLC"
:: La politica va antes que Chrome: asi la primera vez que se abre ya la encuentra.
call :politica_ublock
call :instalar Google.Chrome "Google Chrome"
echo.
echo   LISTO. uBlock Origin Lite aparece en Chrome al minuto de abrirlo por primera
echo   vez. Queda fija: desde Chrome no se puede quitar, por eso Chrome muestra
echo   que lo administra tu organizacion. WinRAR queda en ingles: winget no ofrece
echo   otro idioma.
goto :menu

:: =========================================================================
::  7. CHROME DE AULA
::  Para PCs compartidas, como las de un colegio: cierra Chrome en todas las
::  sesiones y borra todos sus perfiles en todos los usuarios de Windows
::  (cuentas, sesiones abiertas, contrasenas, historial y favoritos). Chrome
::  arranca limpio: sin pedir iniciar sesion, sin bienvenidas y con uBlock
::  Origin Lite. La seccion AULA, al final del archivo, hace el borrado.
:: =========================================================================
:op_chrome_aula
title Optimizar PC Vieja v2 - Chrome de aula
cls
echo ==========================================================================
echo   CHROME DE AULA: CERRAR SESIONES Y BORRAR PERFILES
echo ==========================================================================
echo.
echo   Cierra Chrome y borra TODOS sus perfiles, en todos los usuarios de Windows:
echo   cuentas, sesiones abiertas, contrasenas, historial y favoritos. Chrome
echo   vuelve a arrancar limpio, sin pedir iniciar sesion y con uBlock Origin Lite.
echo.
choice /c SN /n /m "  Borrar todo? [S/N]: "
if errorlevel 2 goto :menu
echo.
:: Sin iniciar sesion en Chrome (en las paginas web si se puede), sin agregar
:: personas, sin pestanas de bienvenida, sin el aviso de privacidad de anuncios
:: y sin preguntar si es el navegador predeterminado.
set "_chr=HKLM\SOFTWARE\Policies\Google\Chrome"
call :dword "%_chr%" BrowserSignin 0
call :dword "%_chr%" BrowserAddPersonEnabled 0
call :dword "%_chr%" PromotionalTabsEnabled 0
call :dword "%_chr%" PrivacySandboxPromptEnabled 0
call :dword "%_chr%" DefaultBrowserSettingEnabled 0
echo   [OK] Chrome ya no pide iniciar sesion ni muestra pantallas de bienvenida.
call :politica_ublock
call :ps AULA
echo.
echo   LISTO. Al abrir Chrome va directo al navegador; uBlock Origin Lite aparece
echo   al minuto (hace falta internet).
goto :menu

:: =========================================================================
::  SUBRUTINAS
:: =========================================================================

:: uBlock Origin Lite forzada en Chrome (ExtensionInstallForcelist): Chrome la
:: instala sola desde la Chrome Web Store. Si ya esta en la lista, no la repite.
:politica_ublock
powershell -NoProfile -ExecutionPolicy Bypass -Command "$k='HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'; $id='ddkjiahejlhfcafbddmgiahcphecmpfh'; if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }; $ya=$false; $n=1; foreach ($v in (Get-ItemProperty -LiteralPath $k).PSObject.Properties) { if ($v.Name -match '^[0-9]+$') { if ([string]$v.Value -like ($id + '*')) { $ya=$true }; if ([int]$v.Name -ge $n) { $n=[int]$v.Name + 1 } } }; if (-not $ya) { New-ItemProperty -LiteralPath $k -Name ([string]$n) -Value ($id + ';https://clients2.google.com/service/update2/crx') -PropertyType String -Force | Out-Null }; Write-Output '  [OK] uBlock Origin Lite: Chrome la instala sola desde la Chrome Web Store.'"
goto :eof

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

:: Escribe un DWORD. Uso: call :dword "clave" valor dato ["aviso de reparado"]
:dword
reg add "%~1" /v %~2 /t REG_DWORD /d %~3 /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
if not errorlevel 1 if not "%~4"=="" echo   [REPARADO] %~4
goto :eof

:: Escribe un texto. Uso: call :sz "clave" valor dato ["aviso de reparado"]
:sz
reg add "%~1" /v %~2 /t REG_SZ /d "%~3" /f >nul 2>&1
if errorlevel 1 echo   [AVISO] No se pudo escribir %~2
if not errorlevel 1 if not "%~4"=="" echo   [REPARADO] %~4
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
set "_reparado=1"
call :servicio %~1 %~2
goto :eof

:: Registra un tipo de imagen para el Visualizador de fotos de Windows.
:: Uso: call :visor_tipo Tipo ProgIdOriginal "Nombre" .ext1 .ext2 ...
:: El icono se copia tal cual del tipo original de Windows, asi no se ve como TIFF.
:visor_tipo
set "_dst=HKLM\SOFTWARE\Classes\PhotoViewer.FileAssoc.%~1"
set "_tipo=%~1"
reg add "%_dst%" /v FriendlyTypeName /t REG_SZ /d "%~3" /f >nul 2>&1
reg add "%_dst%\shell\open" /v MuiVerb /t REG_SZ /d "@photoviewer.dll,-3043" /f >nul 2>&1
reg add "%_dst%\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul 2>&1
reg add "%_dst%\shell\open\DropTarget" /v Clsid /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul 2>&1
reg copy "HKCR\%~2\DefaultIcon" "%_dst%\DefaultIcon" /f >nul 2>&1
:visor_extension
if "%~4"=="" goto :eof
reg add "HKLM\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v %~4 /t REG_SZ /d "PhotoViewer.FileAssoc.%_tipo%" /f >nul 2>&1
shift /4
goto :visor_extension

:: Aplica los ajustes de energia a un plan. Uso: call :energia_plan GUID
:: (o SCHEME_CURRENT, el plan activo).
:: Valores de botones y tapa: 0 nada, 1 suspender, 2 hibernar, 3 apagar.
:: Suspension y tapa salen de _susp y _tapa (por defecto, 4 h y apagar).
:: Tiempos en segundos: 0 es nunca.
:energia_plan
powercfg /setacvalueindex %1 SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setacvalueindex %1 SUB_VIDEO VIDEOIDLE 900 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_VIDEO VIDEOIDLE 900 >nul 2>&1
if not defined _susp set "_susp=14400"
if not defined _tapa set "_tapa=3"
powercfg /setacvalueindex %1 SUB_SLEEP STANDBYIDLE %_susp% >nul 2>&1
powercfg /setdcvalueindex %1 SUB_SLEEP STANDBYIDLE %_susp% >nul 2>&1
powercfg /setacvalueindex %1 SUB_SLEEP HIBERNATEIDLE 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_SLEEP HIBERNATEIDLE 0 >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS PBUTTONACTION 3 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS PBUTTONACTION 3 >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS LIDACTION %_tapa% >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS LIDACTION %_tapa% >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS SBUTTONACTION 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS SBUTTONACTION 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BATTERY BATACTIONCRIT 3 >nul 2>&1
goto :eof

:: Igual que :asegurar, pero recibe "servicio:tipo".
:asegurar_par
for /f "tokens=1,2 delims=:" %%a in ("%~1") do call :asegurar %%a %%b
goto :eof

:: Corre una seccion de PowerShell de este archivo (ver SECCIONES EN POWERSHELL,
:: al final). El errorlevel queda con el exit de la seccion. Uso: call :ps NOMBRE
:ps
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:OPT_RUTA); $i=$t.IndexOf('#%~1-INICIO#'); $j=$t.IndexOf('#%~1-FIN#'); if ($i -ge 0 -and $j -gt $i) { Invoke-Expression $t.Substring($i, $j - $i) }"
goto :eof

:: Usuario de la sesion abierta y datos del equipo, de la seccion EQUIPO. Si
:: PowerShell no responde, quedan los valores de abajo: la cuenta que ejecuta el
:: script y un equipo sin datos. Se calcula una sola vez.
:detectar
if defined UHIVE goto :eof
echo   Revisando el equipo...
set "USID="
set "UNAME=%USERDOMAIN%\%USERNAME%"
set "UHIVE=HKCU"
set "UCLS=HKCU\Software\Classes"
set "UPS=Registry::HKEY_CURRENT_USER"
set "BUILD=0"
set "RAM_MB=9999"
set "RAM_INST=0"
set "GPU_BASICA=0"
set "ANTIRROBO=0"
set "DISCO_TIPO=desconocido"
set "DISCO_PNP="
set "CPU_NOMBRE=desconocido"
:: Cada linea de EQUIPO es VARIABLE=valor. Esta lee la salida, asi que no puede
:: usar :ps; los marcadores van partidos para que IndexOf no la encuentre a ella.
for /f "usebackq delims=" %%l in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:OPT_RUTA); $i=$t.IndexOf('#EQUIPO-' + 'INICIO#'); $j=$t.IndexOf('#EQUIPO-' + 'FIN#'); if ($i -ge 0 -and $j -gt $i) { Invoke-Expression $t.Substring($i, $j - $i) }"`) do set "%%l"
goto :eof

:: Busca winget y deja como llamarlo en WINGET. Prueba que responda, no solo que
:: exista. Si no esta registrado para esta cuenta (pasa al elevar con otro
:: administrador), lo registra. Si no hay forma, avisa.
:buscar_winget
set "WINGET=winget"
winget --version >nul 2>&1
if not errorlevel 1 exit /b 0
echo   Preparando winget...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue" >nul 2>&1
winget --version >nul 2>&1
if not errorlevel 1 exit /b 0
set "WINGET="%LOCALAPPDATA%\Microsoft\WindowsApps\winget.exe""
%WINGET% --version >nul 2>&1
if not errorlevel 1 exit /b 0
echo   [AVISO] winget no esta disponible. Viene con el "Instalador de aplicacion" de
echo           la Microsoft Store: actualizalo ahi y volve a elegir esta opcion.
start "" "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
exit /b 1

:: Instala un programa con winget, en silencio y sin preguntas. Si ya estaba, lo
:: actualiza: install lo hace solo cuando sabe que version hay; si no puede
:: saberlo, se sigue con upgrade --include-unknown, que actualiza igual.
:: Uso: call :instalar Id.Exacto "Nombre"
:instalar
echo.
echo   Instalando %~2...
%WINGET% install --id %~1 -e --source winget --silent --accept-package-agreements --accept-source-agreements
set "_rc=%errorlevel%"
if "%_rc%"=="0" goto :instalar_ok
:: 0x8A15002B: no hay actualizacion aplicable. 0x8A150061: ya estaba instalado.
if "%_rc%"=="-1978335189" goto :instalar_actualizar
if "%_rc%"=="-1978335135" goto :instalar_actualizar
call :a_hex %_rc%
echo   [AVISO] %~2 no se pudo instalar (error %_hex%). Revisa la conexion a internet.
goto :eof
:instalar_ok
echo   [OK] %~2 instalado.
goto :eof
:instalar_actualizar
echo   %~2 ya estaba instalado: buscando actualizacion, aunque no se sepa su version...
%WINGET% upgrade --id %~1 -e --source winget --include-unknown --silent --accept-package-agreements --accept-source-agreements
set "_rc=%errorlevel%"
if "%_rc%"=="0" echo   [OK] %~2 actualizado a la ultima version.
if "%_rc%"=="0" goto :eof
if "%_rc%"=="-1978335189" echo   [OK] %~2 ya estaba en la ultima version.
if "%_rc%"=="-1978335189" goto :eof
call :a_hex %_rc%
echo   [AVISO] %~2 ya estaba instalado, pero no se pudo actualizar (error %_hex%).
goto :eof

:: Pasa un codigo de error a hexadecimal, como lo publica Microsoft. Deja _hex.
:a_hex
:: Sin PowerShell: cmd deja el ultimo codigo de salida en hexa en =ExitCode, y en
:: una PC de 2 GB con disco mecanico abrir PowerShell solo para esto tarda segundos.
cmd /c exit %~1
set "_hex=0x%=ExitCode%"
goto :eof

:: Borra un valor si existe. Uso: call :borrar "clave" valor
:borrar
reg delete "%~1" /v %~2 /f >nul 2>&1
goto :eof

:: Espacio libre en el disco del sistema, en MB. Uso: call :libre VARIABLE
:libre
set "%~1=0"
for /f "usebackq delims=" %%m in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[string][math]::Floor((Get-PSDrive -Name $env:SystemDrive.Substring(0,1)).Free / 1MB)"`) do set "%~1=%%m"
goto :eof

:: =========================================================================
::  SECCIONES EN POWERSHELL. cmd nunca llega hasta aca: todo termina antes
::  con "exit /b", "goto :menu" o "goto :eof". Se corren con call :ps NOMBRE.
::  Una seccion por paso y no un PowerShell por ajuste: en una PC de 2 GB con
::  disco mecanico, cada PowerShell que arranca cuesta varios segundos.
::   - EQUIPO: usuario de la sesion y hardware (opciones 1 y 6, via :detectar).
::   - DISCO: paginacion, cache de escritura, CompactOS y Restaurar sistema
::     (paso 8 de la opcion 1).
::   - QUITAR: apps, app Fotos, caracteristicas opcionales y Adobe Reader
::     (paso 10 de la opcion 1).
::   - LIMPIEZA: vaciado de temporales (paso 11 de la opcion 1).
::   - FINAL: estado de Defender e inicio de Windows (final de la opcion 1).
::   - VERIFICAR: el reporte de la opcion 7.
::   - LUZ: luz nocturna del anochecer al amanecer (paso 7 de la opcion 1).
::   - AULA: borrado de perfiles de Chrome (opcion 5).
:: =========================================================================
#EQUIPO-INICIO#
# Lo que cmd necesita saber del equipo, una linea VARIABLE=valor por dato:
# :detectar hace set con cada una, asi que nada mas puede escribir en la salida.
$ErrorActionPreference = 'SilentlyContinue'
# Usuario de la sesion abierta: el dueno del explorer.exe de esta sesion, aunque
# el script se haya elevado con otra cuenta de administrador.
$s = (Get-Process -Id $PID).SessionId
$ex = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" | Where-Object { $_.SessionId -eq $s } | Select-Object -First 1
if ($ex) {
    $sid = [string](Invoke-CimMethod -InputObject $ex -MethodName GetOwnerSid).Sid
    $o = Invoke-CimMethod -InputObject $ex -MethodName GetOwner
    if ($sid -like 'S-1-*' -and (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $sid))) {
        'USID=' + $sid
        'UNAME=' + $o.Domain + '\' + $o.User
        'UHIVE=HKU\' + $sid
        'UPS=Registry::HKEY_USERS\' + $sid
        # Las clases del usuario viven en su propia colmena; si no estuviera cargada,
        # Software\Classes del usuario es un enlace de Windows a esa misma colmena.
        if (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $sid + '_Classes')) { 'UCLS=HKU\' + $sid + '_Classes' } else { 'UCLS=HKU\' + $sid + '\Software\Classes' }
    }
}
# Solo si hay dato: cmd compara BUILD con GEQ, y vacio seria un error de sintaxis.
$b = (Get-ItemProperty -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuildNumber
if ($b) { 'BUILD=' + $b }
$cs = Get-CimInstance Win32_ComputerSystem
'RAM_MB=' + [math]::Round($cs.TotalPhysicalMemory / 1MB)
# RAM instalada: la suma de los modulos, porque Windows de 32 bits ve unos 3,2 GB
# de 4 y el video se queda con un pedazo. Si no se pueden leer, la visible
# redondeada a 512 MB. La usan el perfil de 4 GB y el archivo de paginacion.
$ri = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1MB)
if ($ri -lt 256) { $ri = [math]::Ceiling($cs.TotalPhysicalMemory / 512MB) * 512 }
'RAM_INST=' + $ri
# El driver basico de Microsoft se instala como display.inf.
$g = 0
Get-CimInstance Win32_VideoController | ForEach-Object { if ($_.InfFilename -eq 'display.inf' -or $_.Name -match 'Basic Display') { $g = 1 } }
'GPU_BASICA=' + $g
# Antirrobo de Conectar Igualdad (Theft Deterrent): carpeta, servicio o inicio.
$a = 0
foreach ($d in $env:ProgramFiles, ${env:ProgramFiles(x86)}) { if ($d -and (Test-Path -LiteralPath (Join-Path $d 'Intel Learning Series\Theft Deterrent'))) { $a = 1 } }
if (Get-Service | Where-Object { ($_.Name + ' ' + $_.DisplayName) -match 'Theft|Deterrent|TDAgent' }) { $a = 1 }
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
    $it = Get-Item -LiteralPath $k
    if ($it -and ($it.Property -match 'Theft|Deterrent|TDAgent')) { $a = 1 }
}
'ANTIRROBO=' + $a
# Disco del sistema: tipo (SSD o HDD) e identificador, para la cache de escritura.
$n = (Get-Partition -DriveLetter $env:SystemDrive[0]).DiskNumber
if ($null -ne $n) {
    $d = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$n } | Select-Object -First 1
    if ([string]$d.MediaType -eq 'SSD' -or [string]$d.MediaType -eq 'HDD') { 'DISCO_TIPO=' + [string]$d.MediaType }
    $w = Get-CimInstance Win32_DiskDrive | Where-Object { $_.Index -eq $n } | Select-Object -First 1
    if ($w.PNPDeviceID) { 'DISCO_PNP=' + $w.PNPDeviceID }
}
'CPU_NOMBRE=' + ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+', ' ').Trim()
#EQUIPO-FIN#
#DISCO-INICIO#
# Paso 8 de la opcion 1. Usa RAM_INST, DISCO_TIPO y DISCO_PNP de la seccion EQUIPO.
$cs = Get-CimInstance Win32_ComputerSystem
$nombre = $env:SystemDrive + '\pagefile.sys'
# Sin archivo de paginacion, con 2 GB de RAM los programas se cuelgan: si alguien
# lo quito, vuelve a administrarlo Windows.
if (-not $cs.AutomaticManagedPagefile -and -not (Get-CimInstance Win32_PageFileSetting)) {
    Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true}
    Write-Output '  [REPARADO] No habia archivo de paginacion: ahora lo administra Windows.'
    $cs = Get-CimInstance Win32_ComputerSystem
}
# Archivo de paginacion fijo en el doble de la RAM instalada (con 2 GB, 4096 MB),
# con tope de 8 GB: con 8 GB de RAM, el doble serian 16 GB de disco sin uso.
# El automatico arranca chico y crece cuando hace falta: en un disco lento,
# mientras crece, los programas pueden fallar por falta de memoria (Microsoft),
# y crecer y achicarse lo fragmenta. Fijo, nunca cambia de tamano. Rige al reiniciar.
$mb = [int][math]::Min([int]$env:RAM_INST * 2, 8192)
$pf = Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -eq $nombre } | Select-Object -First 1
if ($mb -le 0) {
    Write-Output '  [AVISO] No se pudo leer la RAM: el archivo de paginacion queda como esta.'
} elseif (-not $cs.AutomaticManagedPagefile -and $pf -and $pf.InitialSize -eq $mb -and $pf.MaximumSize -eq $mb) {
    Write-Output ('  [OK] Archivo de paginacion: ya estaba fijo en ' + $mb + ' MB.')
} else {
    $actual = 0
    Get-CimInstance Win32_PageFileUsage | Where-Object { $_.Name -eq $nombre } | ForEach-Object { $actual = [int]$_.AllocatedBaseSize }
    $libre = [math]::Floor((Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)).Free / 1MB) + $actual
    if ($libre -lt ($mb + 2048)) {
        Write-Output '  [AVISO] Poco espacio libre: el archivo de paginacion queda como esta.'
    } else {
        try {
            Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop
            $pf = Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -eq $nombre } | Select-Object -First 1
            if ($pf) { Set-CimInstance -InputObject $pf -Property @{InitialSize=[uint32]$mb; MaximumSize=[uint32]$mb} -ErrorAction Stop }
            else { New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name=$nombre; InitialSize=[uint32]$mb; MaximumSize=[uint32]$mb} -ErrorAction Stop | Out-Null }
            Write-Output ('  [OK] Archivo de paginacion fijo en ' + $mb + ' MB, el doble de la RAM con tope de 8 GB: no crece ni se fragmenta.')
        } catch {
            Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true} -ErrorAction SilentlyContinue
            Write-Output '  [AVISO] No se pudo configurar el archivo de paginacion: queda automatico.'
        }
    }
}
# Cache de escritura del disco: activada y SIN vaciado del bufer. Asi Windows no
# espera a que el disco confirme cada escritura: se gana tiempo. El costo: ante
# un corte de luz se pueden perder o corromper los ultimos cambios. Decision
# tomada: aca importa el tiempo. En un SSD no se toca. Rige al reiniciar.
if ($env:DISCO_TIPO -eq 'SSD') {
    Write-Output '  [OK] Cache de escritura: el disco es un SSD, queda como esta.'
} elseif (-not $env:DISCO_PNP) {
    Write-Output '  [AVISO] No se encontro el disco del sistema: la cache de escritura queda como esta.'
} else {
    $k = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\' + $env:DISCO_PNP + '\Device Parameters\Disk'
    try {
        if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force -ErrorAction Stop | Out-Null }
        Set-ItemProperty -LiteralPath $k -Name UserWriteCacheSetting -Value 1 -Type DWord -ErrorAction Stop
        Set-ItemProperty -LiteralPath $k -Name CacheIsPowerProtected -Value 1 -Type DWord -ErrorAction Stop
        Write-Output '  [OK] Cache de escritura del disco activada y sin vaciado del bufer: rige al reiniciar.'
    } catch {
        Write-Output '  [AVISO] No se pudo configurar la cache de escritura del disco.'
    }
}
# CompactOS: en HDD conviene el sistema sin comprimir. Solo se descomprime si
# estaba comprimido y hay espacio; si no, se saltea: tarda varios minutos igual.
$comprimido = $false
foreach ($f in 'System32\shell32.dll', 'System32\mshtml.dll', 'explorer.exe') {
    $p = Join-Path $env:windir $f
    if ((Test-Path -LiteralPath $p) -and ((Get-Item -LiteralPath $p -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { $comprimido = $true }
}
if (-not $comprimido) {
    Write-Output '  [OK] El sistema no esta comprimido con CompactOS: nada que hacer.'
} elseif ((Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)).Free -lt 6GB) {
    Write-Output '  [AVISO] El sistema esta comprimido pero quedan menos de 6 GB libres: se deja asi.'
} else {
    Write-Output '  El sistema esta comprimido con CompactOS: descomprimiendo, puede tardar...'
    compact.exe /CompactOS:never 2>&1 | Out-Null
    Write-Output '  [OK] Sistema descomprimido.'
}
# Restaurar sistema: desactivado. Cada punto cuesta escrituras de fondo y espacio
# en el disco, y en la practica se reinstala. La herramienta oficial borra sus
# puntos y libera el espacio. La vuelta atras es la opcion 6 del menu.
try {
    Disable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop
    schtasks.exe /change /tn '\Microsoft\Windows\SystemRestore\SR' /disable 2>&1 | Out-Null
    Write-Output '  [OK] Restaurar sistema desactivado: se borraron sus puntos y se libero su espacio.'
} catch {
    Write-Output '  [AVISO] No se pudo desactivar Restaurar sistema. Se puede a mano en Propiedades'
    Write-Output '          del sistema, Proteccion del sistema, Configurar.'
}
#DISCO-FIN#
#QUITAR-INICIO#
# Paso 10 de la opcion 1: lo que se quita. Sale con 2 si Adobe Reader esta
# instalado, para el aviso final sobre los PDF.
if ($env:QUITARAPPS -eq 'S') {
    Write-Output '  Quitando apps preinstaladas para todos los usuarios, puede tardar...'
    $apps = 'Microsoft.549981C3F5F10','Microsoft.BingNews','Microsoft.BingSearch','Microsoft.Copilot','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.Messaging','Microsoft.Microsoft3DViewer','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MicrosoftStickyNotes','Microsoft.MixedReality.Portal','Microsoft.MSPaint','Microsoft.Office.OneNote','Microsoft.OneConnect','Microsoft.OutlookForWindows','Microsoft.People','Microsoft.PowerAutomateDesktop','Microsoft.Print3D','Microsoft.SkypeApp','Microsoft.Todos','Microsoft.Wallet','Microsoft.WindowsAlarms','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','microsoft.windowscommunicationsapps','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.GamingApp','Microsoft.XboxApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Clipchamp.Clipchamp','MicrosoftTeams','king.com.*'
    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    foreach ($a in $apps) {
        Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue | Sort-Object PackageFullName -Unique | ForEach-Object {
            Write-Output ('    - ' + $_.Name)
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        }
        $prov | Where-Object { $_.DisplayName -like $a } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
    }
    Write-Output '  [OK] Apps preinstaladas quitadas.'
}
# La app Fotos nueva, para todos los usuarios: el Visualizador de fotos clasico
# ya quedo registrado en el paso anterior.
Get-AppxPackage -AllUsers -Name Microsoft.Windows.Photos -ErrorAction SilentlyContinue | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }
Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Microsoft.Windows.Photos' } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
Write-Output '  [OK] App Fotos quitada. Si algun dia hace falta, se reinstala desde la Store.'
# Caracteristicas opcionales (Configuracion > Aplicaciones > Caracteristicas
# opcionales): no corren de fondo, pero ocupan disco. Quedan Paint, Bloc de
# notas, PowerShell ISE, los idiomas, Fax y Escaner y la Administracion de
# impresion. Windows Hello facial necesita camara infrarroja;
# el PIN y la huella no dependen de el.
Write-Output '  Quitando caracteristicas opcionales, puede tardar varios minutos...'
$q = [ordered]@{'App.StepsRecorder'='Grabacion de acciones de usuario'; 'MathRecognizer'='Reconocedor matematico'; 'Microsoft.Windows.WordPad'='WordPad'; 'Media.WindowsMediaPlayer'='Reproductor de Windows Media'; 'Browser.InternetExplorer'='Internet Explorer 11'; 'App.Support.QuickAssist'='Asistencia rapida (la vieja)'; 'OpenSSH.Client'='Cliente OpenSSH'; 'Hello.Face.*'='Windows Hello: reconocimiento facial'; 'XPS.Viewer'='Visor de XPS'}
$todas = @(Get-WindowsCapability -Online -ErrorAction SilentlyContinue)
if (-not $todas.Count) {
    Write-Output '    (Windows no devolvio la lista: se saltea)'
} else {
    $n = 0; $vistas = @()
    foreach ($c in @($todas | Where-Object { $_.State -eq 'Installed' })) {
        $base = $c.Name.Split('~')[0]
        foreach ($k in $q.Keys) {
            if ($base -like $k) {
                if ($vistas -notcontains $k) { Write-Output ('    - ' + $q[$k]); $vistas += $k }
                Remove-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue | Out-Null
                $n++
                break
            }
        }
    }
    if ($n -eq 0) { Write-Output '    (ya no quedaba ninguna)' }
}
Write-Output '  [OK] Caracteristicas opcionales: quedan Paint, Bloc de notas, PowerShell ISE,'
Write-Output '       los idiomas y las de impresion.'
# Adobe Reader, si esta instalado: fuera todo lo que arranca solo con Windows,
# incluido su actualizador automatico (tarea y servicio). Los PDF quedan para
# Edge o Chrome. Reader sigue andando si alguien lo abre.
$n = 0
$ks = ($env:UPS + '\Software\Microsoft\Windows\CurrentVersion\Run'), ($env:UPS + '\Software\Microsoft\Windows\CurrentVersion\RunOnce'),
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
foreach ($k in $ks) {
    $it = Get-Item -LiteralPath $k -ErrorAction SilentlyContinue
    if ($it) {
        foreach ($v in $it.Property) {
            $d = [string]$it.GetValue($v)
            if (($v + ' ' + $d) -match 'AdobeARM|Adobe ARM|reader_sl|Speed Launcher|acrotray|Acrobat Assistant|AdobeCollabSync|\\Adobe\\(Acrobat|Reader)') {
                Remove-ItemProperty -LiteralPath $k -Name $v -ErrorAction SilentlyContinue
                Write-Output ('  [OK] Adobe: fuera del inicio: ' + $v)
                $n++
            }
        }
    }
}
Get-ScheduledTask -TaskName 'Adobe Acrobat Update Task*' -ErrorAction SilentlyContinue | Where-Object { [string]$_.State -ne 'Disabled' } | ForEach-Object {
    $_ | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
    Write-Output ('  [OK] Adobe: tarea desactivada: ' + $_.TaskName)
    $n++
}
if (Get-Service -Name AdobeARMservice -ErrorAction SilentlyContinue) {
    Stop-Service -Name AdobeARMservice -Force -ErrorAction SilentlyContinue
    Set-Service -Name AdobeARMservice -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Output '  [OK] Adobe: servicio de actualizacion automatica deshabilitado.'
    $n++
}
$u = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$r = Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Acrobat|Adobe Reader' } | Select-Object -First 1
if ($r) {
    Write-Output ('  [OK] Adobe Reader instalado: ' + $r.DisplayName + '. Sigue andando si alguien lo abre.')
    exit 2
}
if ($n -eq 0) { Write-Output '  [OK] Adobe Reader no esta instalado: nada que limpiar.' }
#QUITAR-FIN#
#FINAL-INICIO#
# Ultimos pasos de la opcion 1. Las firmas de Defender no se actualizan aca: lo
# hace Windows Update, y en un disco mecanico tarda varios minutos.
$s = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($s) {
    $rt = 'INACTIVO, hay otro antivirus?'
    if ($s.RealTimeProtectionEnabled) { $rt = 'ACTIVO' }
    $tp = 'inactiva'
    if ($s.IsTamperProtected) { $tp = 'ACTIVA' }
    Write-Output ('  Defender en tiempo real: ' + $rt)
    Write-Output ('  Proteccion contra alteraciones: ' + $tp)
    Write-Output ('  Firmas de virus del: ' + $s.AntivirusSignatureLastUpdated)
} else {
    Write-Output '  No se pudo leer el estado de Defender. Hay otro antivirus instalado?'
}
Write-Output ''
Write-Output '  Programas que arrancan con Windows. Desactiva los que no uses en'
Write-Output '  Administrador de tareas, pestana Inicio, desde la sesion del usuario:'
$ks = ($env:UPS + '\Software\Microsoft\Windows\CurrentVersion\Run'), 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
foreach ($k in $ks) {
    $it = Get-Item -LiteralPath $k -ErrorAction SilentlyContinue
    if ($it) {
        $it.Property | ForEach-Object {
            $m = ''
            if ($_ -match 'Theft|Deterrent|TDAgent') { $m = '   <-- antirrobo de Conectar Igualdad: NO lo desactives' }
            Write-Output ('    - ' + $_ + $m)
        }
    }
}
#FINAL-FIN#
#LIMPIEZA-INICIO#
$ErrorActionPreference = 'SilentlyContinue'
$self = $env:OPT_SELF
$totalBytes = 0
$totalSalteados = 0
$totalSinPermiso = 0

# Carpetas que jamas se vacian enteras, aunque alguien edite mal la lista.
$disco = $env:SystemDrive + '\'
$prohibidas = @($disco, $env:SystemRoot, (Join-Path $env:SystemRoot 'System32'), $env:ProgramData,
    $env:ProgramFiles, ${env:ProgramFiles(x86)}, (Join-Path $disco 'Users'), $env:USERPROFILE) |
    Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\') }
$perfiles = @(Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LocalPath -and [IO.Directory]::Exists($_.LocalPath) })
$prohibidas += $perfiles | ForEach-Object { $_.LocalPath.TrimEnd('\') }

# Borra el contenido de una carpeta: todo, o en la carpeta principal solo lo que
# coincide con $Patron y no con $Excepto. Saltea lo que esta en uso, nunca sigue
# enlaces (junctions ni symlinks) y nunca toca la carpeta del script.
function Vaciar([string]$Nombre, [string]$Carpeta, [string]$Patron = '*', [string]$Excepto = '', [switch]$Callado) {
    $script:ultBytes = 0; $script:ultSalteados = 0; $script:ultSinPermiso = 0
    if (-not $Carpeta -or -not [IO.Directory]::Exists($Carpeta)) { return }
    if ($prohibidas -contains $Carpeta.TrimEnd('\')) { return }
    $borrados = 0; $salteados = 0; $sinPermiso = 0; $bytes = 0
    $pendientes = New-Object System.Collections.Stack
    $subcarpetas = New-Object System.Collections.Generic.List[string]
    $pendientes.Push($Carpeta)
    while ($pendientes.Count -gt 0) {
        $dir = $pendientes.Pop()
        $filtro = '*'
        if ($dir -eq $Carpeta) { $filtro = $Patron }
        try { $entradas = [IO.Directory]::GetFileSystemEntries($dir, $filtro) } catch [UnauthorizedAccessException] { $sinPermiso++; continue } catch { $salteados++; continue }
        foreach ($e in $entradas) {
            if ($self -and $e.StartsWith($self.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) { continue }
            if ($Excepto -and $dir -eq $Carpeta -and ([IO.Path]::GetFileName($e) -like $Excepto)) { continue }
            try { $attr = [IO.File]::GetAttributes($e) } catch { continue }
            if ($attr -band [IO.FileAttributes]::ReparsePoint) { continue }
            if ($attr -band [IO.FileAttributes]::Directory) { $pendientes.Push($e); $subcarpetas.Add($e); continue }
            if ($attr -band [IO.FileAttributes]::ReadOnly) { try { [IO.File]::SetAttributes($e, [IO.FileAttributes]::Normal) } catch { } }
            try {
                $largo = (New-Object IO.FileInfo($e)).Length
                [IO.File]::Delete($e)
                $borrados++; $bytes += $largo
            } catch [UnauthorizedAccessException] { $sinPermiso++ } catch { $salteados++ }
        }
    }
    # Las subcarpetas que quedaron vacias, de la mas profunda a la mas cercana.
    foreach ($d in ($subcarpetas | Sort-Object Length -Descending)) { try { [IO.Directory]::Delete($d, $false) } catch { } }
    $script:totalBytes += $bytes
    $script:totalSalteados += $salteados
    $script:totalSinPermiso += $sinPermiso
    $script:ultBytes = $bytes; $script:ultSalteados = $salteados; $script:ultSinPermiso = $sinPermiso
    if (-not $Callado) { Linea $Nombre $bytes $salteados $sinPermiso }
}

function Linea([string]$Nombre, [double]$Bytes, [int]$Salteados, [int]$SinPermiso) {
    $linea = '    ' + $Nombre.PadRight(44) + ([string][Math]::Round($Bytes / 1MB, 1)).PadLeft(8) + ' MB'
    if ($Salteados) { $linea += '   (' + $Salteados + ' en uso, salteados)' }
    if ($SinPermiso) { $linea += '   (' + $SinPermiso + ' sin permiso)' }
    Write-Output $linea
}

# Vacia varias carpetas y muestra una sola linea con el total. Si no existe
# ninguna, no muestra nada.
function VaciarVarias([string]$Nombre, [string[]]$Carpetas) {
    $hay = @($Carpetas | Where-Object { $_ -and [IO.Directory]::Exists($_) })
    if (-not $hay.Count) { return }
    $b = 0; $s = 0; $np = 0
    foreach ($c in $hay) { Vaciar $Nombre $c -Callado; $b += $script:ultBytes; $s += $script:ultSalteados; $np += $script:ultSinPermiso }
    Linea $Nombre $b $s $np
}

Vaciar 'temp (Temp de Windows)' (Join-Path $env:SystemRoot 'Temp')
foreach ($p in $perfiles) {
    $quien = Split-Path $p.LocalPath -Leaf
    Vaciar ('%temp% de ' + $quien) (Join-Path $p.LocalPath 'AppData\Local\Temp')
    Vaciar ('Informes de errores de ' + $quien) (Join-Path $p.LocalPath 'AppData\Local\Microsoft\Windows\WER')
    Vaciar ('Cache de Adobe Reader de ' + $quien) (Join-Path $p.LocalPath 'AppData\LocalLow\Adobe\AcroCef\DC\Acrobat\Cache')
    Vaciar ('Archivos temporales de Internet de ' + $quien) (Join-Path $p.LocalPath 'AppData\Local\Microsoft\Windows\INetCache')
    # Volcados de programas que se colgaron, cache de sombreadores de DirectX y
    # cache de Escritorio remoto: todo se regenera solo.
    VaciarVarias ('Volcados y caches de Windows de ' + $quien) @((Join-Path $p.LocalPath 'AppData\Local\CrashDumps'),
        (Join-Path $p.LocalPath 'AppData\Local\D3DSCache'), (Join-Path $p.LocalPath 'AppData\Local\Microsoft\Terminal Server Client\Cache'))
    # Chrome y Edge: solo la cache, lo que el navegador vuelve a bajar o generar,
    # en todos sus perfiles. Cookies, contrasenas, autocompletar, historial y datos
    # de sitios (incluida la cache de Service Workers) no se tocan.
    foreach ($nav in @(@('Chrome', 'AppData\Local\Google\Chrome\User Data'), @('Edge', 'AppData\Local\Microsoft\Edge\User Data'))) {
        $ud = Join-Path $p.LocalPath $nav[1]
        if (-not [IO.Directory]::Exists($ud)) { continue }
        $carpetas = @('ShaderCache', 'GrShaderCache', 'GraphiteDawnCache') | ForEach-Object { Join-Path $ud $_ }
        foreach ($perfil in @([IO.Directory]::GetDirectories($ud) | Where-Object { [IO.File]::Exists((Join-Path $_ 'Preferences')) })) {
            $carpetas += @('Cache', 'Code Cache', 'GPUCache', 'Media Cache', 'DawnGraphiteCache', 'DawnWebGPUCache') | ForEach-Object { Join-Path $perfil $_ }
        }
        VaciarVarias ('Cache de ' + $nav[0] + ' de ' + $quien) $carpetas
    }
}
Vaciar 'Temp de la cuenta del sistema' (Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\Temp')
Vaciar 'Temp de la cuenta del sistema, 32 bits' (Join-Path $env:SystemRoot 'SysWOW64\config\systemprofile\AppData\Local\Temp')
Vaciar 'Temp de LocalService' (Join-Path $env:SystemRoot 'ServiceProfiles\LocalService\AppData\Local\Temp')
Vaciar 'Temp de NetworkService' (Join-Path $env:SystemRoot 'ServiceProfiles\NetworkService\AppData\Local\Temp')
# Temp de los procesos del sistema desde 2024 (GetTempPath2): se vacia el
# contenido, la carpeta queda con sus permisos.
Vaciar 'SystemTemp (Temp de procesos del sistema)' (Join-Path $env:SystemRoot 'SystemTemp')
VaciarVarias 'Archivos temporales de Internet del sistema' @(
    (Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache'),
    (Join-Path $env:SystemRoot 'SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache'),
    (Join-Path $env:SystemRoot 'ServiceProfiles\LocalService\AppData\Local\Microsoft\Windows\INetCache'),
    (Join-Path $env:SystemRoot 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\INetCache'))
# Restos de los instaladores de Edge (Microsoft\Temp, Edge\Temp) y de Google.
$pf = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ } | Select-Object -Unique
VaciarVarias 'Temp de instaladores de Microsoft y Google' @($pf | ForEach-Object { (Join-Path $_ 'Microsoft\Temp'), (Join-Path $_ 'Microsoft\Edge\Temp'), (Join-Path $_ 'Google\Temp') })
Vaciar 'Temp del almacen de drivers' (Join-Path $env:SystemRoot 'System32\DriverStore\Temp')
Vaciar 'Informes de errores de Windows' (Join-Path $env:ProgramData 'Microsoft\Windows\WER')
Vaciar 'Volcados de pantallas azules (Minidump)' (Join-Path $env:SystemRoot 'Minidump')
Vaciar 'Volcados de cuelgues de video' (Join-Path $env:SystemRoot 'LiveKernelReports')
Vaciar 'Registros viejos de actualizaciones' (Join-Path $env:SystemRoot 'Logs\CBS') 'CbsPersist_*'
Vaciar 'Descargas del actualizador de Adobe' (Join-Path $env:ProgramData 'Adobe\ARM')
$dmp = Join-Path $env:SystemRoot 'MEMORY.DMP'
if ([IO.File]::Exists($dmp)) {
    try { $largo = (New-Object IO.FileInfo($dmp)).Length; [IO.File]::Delete($dmp); $totalBytes += $largo
          Write-Output ('    ' + 'Volcado de memoria completo'.PadRight(44) + ([string][Math]::Round($largo / 1MB, 1)).PadLeft(8) + ' MB') }
    catch { $totalSalteados++ }
}
# Prefetch: las entradas de programas (*.pf) se vacian solo si el script no lo
# hizo hace poco: con el .pf mas viejo de menos de una semana, la carpeta ya se
# vacio en esa semana, y vaciarla de nuevo solo haria mas lento abrir cada
# programa mientras Windows la rearma. Quedan siempre el rastro de arranque
# (NTOSBOOT), el mapa del desfragmentador (Layout.ini), ReadyBoot y las bases de
# SysMain (Ag*.db).
$prefetch = Join-Path $env:SystemRoot 'Prefetch'
$masViejo = [IO.Directory]::GetFiles($prefetch, '*.pf') | Where-Object { [IO.Path]::GetFileName($_) -notlike 'NTOSBOOT-*' } | ForEach-Object { [IO.File]::GetLastWriteTime($_) } | Sort-Object | Select-Object -First 1
if ($masViejo -and $masViejo -lt (Get-Date).AddDays(-7)) {
    Vaciar 'Prefetch: entradas de programas' $prefetch '*.pf' 'NTOSBOOT-*'
} else {
    Write-Output ('    ' + 'Prefetch: vaciado hace menos de una semana'.PadRight(44) + '   se deja')
}
if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
    Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Output ('    ' + 'Cache de Delivery Optimization'.PadRight(44) + '   vaciada')
}
$fin = '  TOTAL liberado: ' + [Math]::Round($totalBytes / 1MB, 1) + ' MB. Salteados por estar en uso: ' + $totalSalteados + '.'
if ($totalSinPermiso) { $fin += ' Sin permiso: ' + $totalSinPermiso + '.' }
Write-Output $fin
#LIMPIEZA-FIN#
#VERIFICAR-INICIO#
# ---------------------------------------------------------------------------
# Reporte de la opcion 7, en PowerShell. cmd nunca llega aca.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'SilentlyContinue'
$lineas = New-Object System.Collections.Generic.List[string]
function L([string]$texto = '') { $lineas.Add($texto); Write-Host $texto }
function Titulo([string]$texto) { L ''; L ('=== ' + $texto + ' ' + ('=' * [Math]::Max(3, 70 - $texto.Length))) }

function Leer([string]$clave, [string]$valor) {
    $item = Get-ItemProperty -LiteralPath ('Registry::' + $clave) -Name $valor -ErrorAction SilentlyContinue
    if ($null -eq $item) { return '(no existe)' }
    $dato = $item.$valor
    if ($dato -is [byte[]]) { return (($dato | ForEach-Object { $_.ToString('X2') }) -join '') }
    return [string]$dato
}

function InicioServicio([string]$nombre) {
    $k = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\' + $nombre
    $p = Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue
    if ($null -eq $p) { return 'no existe' }
    switch ([int]$p.Start) {
        0 { 'Boot' }
        1 { 'Sistema' }
        2 { if ($p.DelayedAutostart -eq 1) { 'Auto retrasado' } else { 'Automatico' } }
        3 { 'Manual' }
        4 { 'DESHABILITADO' }
        default { [string]$p.Start }
    }
}

# --- Equipo -----------------------------------------------------------------
Titulo 'Equipo'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$ver = Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'DisplayVersion'
L ('Fecha:            ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
L ('Equipo:           ' + $env:COMPUTERNAME)
L ('Windows:          ' + $os.Caption + ' ' + $ver + ' (compilacion ' + $os.BuildNumber + ', ' + $os.OSArchitecture + ')')
$ramInst = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1MB)
L ('RAM:              ' + [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1) + ' GB visibles, ' + $ramInst + ' MB instalados')
$nd0 = (Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1)).DiskNumber
$md0 = [string](Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$nd0 } | Select-Object -First 1).MediaType
$basica = [bool](Get-CimInstance Win32_VideoController | Where-Object { $_.InfFilename -eq 'display.inf' -or $_.Name -match 'Basic Display' })
$p4 = $ramInst -ge 3584
L ('Perfil opcion 1:  4 GB o mas: ' + $p4 + ' | mejor apariencia: ' + ($p4 -and -not $basica) + ' | disco del sistema: ' + $md0)
Get-PhysicalDisk | ForEach-Object { L ('Disco:            ' + $_.FriendlyName + ' - ' + $_.MediaType + ' - ' + [Math]::Round($_.Size / 1GB) + ' GB') }
$c = Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)
L ('Libre en ' + $env:SystemDrive + '       ' + [Math]::Round($c.Free / 1GB, 1) + ' GB')
if (Get-CimInstance Win32_Battery) { L 'Tipo:             Notebook (tiene bateria)' } else { L 'Tipo:             Escritorio' }
L ('Procesador:       ' + ((Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+', ' ').Trim())
Get-CimInstance Win32_VideoController | ForEach-Object {
    $basica = ($_.InfFilename -eq 'display.inf' -or $_.Name -match 'Basic Display')
    $nota = if ($basica) { '  <-- driver basico de Microsoft: sin aceleracion (tipico de GMA 3600)' } else { '' }
    L ('Video:            ' + $_.Name + ' (' + $_.InfFilename + ', ' + $_.CurrentHorizontalResolution + 'x' + $_.CurrentVerticalResolution + ')' + $nota)
}

# --- Usuario de la sesion -----------------------------------------------------
Titulo 'Usuario de la sesion'
$s = (Get-Process -Id $PID).SessionId
$ex = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" | Where-Object { $_.SessionId -eq $s } | Select-Object -First 1
$sid = $null
if ($ex) {
    $o = Invoke-CimMethod -InputObject $ex -MethodName GetOwner
    $sid = (Invoke-CimMethod -InputObject $ex -MethodName GetOwnerSid).Sid
    L ('Sesion abierta:   ' + $o.Domain + '\' + $o.User + '  (' + $sid + ')')
} else {
    L 'Sesion abierta:   no detectada; se lee la cuenta actual'
}
L ('Ejecutado por:    ' + [Security.Principal.WindowsIdentity]::GetCurrent().Name)
if ($sid -and (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $sid))) { $U = 'HKEY_USERS\' + $sid } else { $U = 'HKEY_CURRENT_USER' }

# --- Antirrobo de Conectar Igualdad -------------------------------------------
Titulo 'Antirrobo de Conectar Igualdad (Theft Deterrent)'
$tda = @()
foreach ($d in $env:ProgramFiles, ${env:ProgramFiles(x86)}) { if ($d) { $r = Join-Path $d 'Intel Learning Series\Theft Deterrent'; if (Test-Path -LiteralPath $r) { $tda += ('carpeta ' + $r) } } }
Get-Service | Where-Object { ($_.Name + ' ' + $_.DisplayName) -match 'Theft|Deterrent|TDAgent' } | ForEach-Object { $tda += ('servicio ' + $_.Name + ' (' + $_.Status + ')') }
foreach ($k in 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
    $i = Get-Item -LiteralPath ('Registry::' + $k)
    if ($i) { $i.Property | Where-Object { $_ -match 'Theft|Deterrent|TDAgent' } | ForEach-Object { $tda += ('inicio ' + $_) } }
}
if ($tda) { $tda | ForEach-Object { L ('Detectado: ' + $_) }; L 'Si la netbook no esta liberada, NO lo desactives: sin el agente se bloquea.' } else { L 'No detectado.' }

# --- Seguridad ----------------------------------------------------------------
Titulo 'Seguridad'
$mp = Get-MpComputerStatus
if ($mp) {
    L ('Defender servicio / antivirus:  ' + $mp.AMServiceEnabled + ' / ' + $mp.AntivirusEnabled)
    L ('Tiempo real / comportamiento:   ' + $mp.RealTimeProtectionEnabled + ' / ' + $mp.BehaviorMonitorEnabled)
    L ('Descargas (IOAV):               ' + $mp.IoavProtectionEnabled)
    L ('Proteccion contra alteraciones: ' + $mp.IsTamperProtected)
    L ('Firmas del:                     ' + $mp.AntivirusSignatureLastUpdated)
} else { L 'Defender: no se pudo leer el estado' }
$av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
if ($av) { L ('Antivirus registrados:          ' + (($av | ForEach-Object { $_.displayName }) -join ', ')) }
$pref = Get-MpPreference
if ($pref) {
    L ('PUA / nube (MAPS) / muestras:   ' + $pref.PUAProtection + ' / ' + $pref.MAPSReporting + ' / ' + $pref.SubmitSamplesConsent)
    L ('Analisis: CPU max / prioridad baja / solo inactiva: ' + $pref.ScanAvgCPULoadFactor + ' / ' + $pref.EnableLowCpuPriority + ' / ' + $pref.ScanOnlyIfIdleEnabled)
    L ('Analisis de recuperacion desactivados (rapido / completo): ' + $pref.DisableCatchupQuickScan + ' / ' + $pref.DisableCatchupFullScan)
}
Get-NetFirewallProfile | ForEach-Object { L ('Firewall ' + $_.Name + ':' + (' ' * (22 - $_.Name.Length)) + $_.Enabled) }
$uac = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
L ('UAC EnableLUA / ConsentPromptBehaviorAdmin / PromptOnSecureDesktop: ' + (Leer $uac 'EnableLUA') + ' / ' + (Leer $uac 'ConsentPromptBehaviorAdmin') + ' / ' + (Leer $uac 'PromptOnSecureDesktop'))
L ('SmartScreen (Explorer):         ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'SmartScreenEnabled'))
L ('SmartScreen (politica):         ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableSmartScreen'))
$dep = @{0 = 'AlwaysOff'; 1 = 'AlwaysOn'; 2 = 'OptIn'; 3 = 'OptOut'}[[int]$os.DataExecutionPrevention_SupportPolicy]
L ('DEP:                            ' + $dep)
$mm = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
L ('Spectre/Meltdown override:      ' + (Leer $mm 'FeatureSettingsOverride') + '  (3 = mitigaciones apagadas)')
$wd = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender'
foreach ($par in @(@($wd, 'DisableAntiSpyware'), @($wd, 'DisableAntiVirus'), @(($wd + '\Real-Time Protection'), 'DisableRealtimeMonitoring'), @(($wd + '\Spynet'), 'SpynetReporting'))) {
    L ('Politica Defender ' + $par[1] + ': ' + (Leer $par[0] $par[1]))
}
$wu = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
L ('Politica WU NoAutoUpdate / DisableWindowsUpdateAccess: ' + (Leer ($wu + '\AU') 'NoAutoUpdate') + ' / ' + (Leer $wu 'DisableWindowsUpdateAccess'))
L ('Reproduccion automatica NoDriveTypeAutoRun: ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'NoDriveTypeAutoRun'))

# --- Memoria ------------------------------------------------------------------
Titulo 'Memoria'
$mma = Get-MMAgent
if ($mma) { L ('Compresion de memoria / precarga de apps / combinacion de paginas: ' + $mma.MemoryCompression + ' / ' + $mma.ApplicationPreLaunch + ' / ' + $mma.PageCombining) }
L ('Proceso de compresion activo:   ' + [bool](Get-Process -Name 'Memory Compression'))
foreach ($v in 'DisablePagingExecutive', 'IOPageLockLimit', 'DontVerifyRandomDrivers', 'LargeSystemCache') { L ($v + ': ' + (Leer $mm $v)) }
L ('Paginacion administrada por Windows: ' + $cs.AutomaticManagedPagefile)
Get-CimInstance Win32_PageFileSetting | ForEach-Object { L ('Paginacion configurada:         ' + $_.Name + ' - inicial ' + $_.InitialSize + ' MB, maximo ' + $_.MaximumSize + ' MB   (la v2: fijo en el doble de la RAM)') }
Get-CimInstance Win32_PageFileUsage | ForEach-Object { L ('Archivo de paginacion:          ' + $_.Name + ' - ' + $_.AllocatedBaseSize + ' MB (en uso ' + $_.CurrentUsage + ' MB, pico ' + $_.PeakUsage + ' MB)') }

# --- Servicios ----------------------------------------------------------------
Titulo 'Servicios (inicio / estado / lo que espera la v2)'
$espera = [ordered]@{
    'SysMain' = 'Automatico'; 'TabletInputService' = 'Manual'; 'DoSvc' = 'Auto retrasado'
    'DiagTrack' = 'DESHABILITADO'; 'dmwappushservice' = 'DESHABILITADO'; 'WSearch' = 'segun disco'; 'RemoteRegistry' = 'DESHABILITADO'
    'XblAuthManager' = 'DESHABILITADO'; 'XblGameSave' = 'DESHABILITADO'; 'XboxNetApiSvc' = 'DESHABILITADO'; 'XboxGipSvc' = 'DESHABILITADO'; 'xbgm' = 'DESHABILITADO'
    'bthserv' = 'segun RAM'; 'BTAGService' = 'segun RAM'; 'BthAvctpSvc' = 'segun RAM'
    'PcaSvc' = 'Manual'; 'TrkWks' = 'Manual'; 'iphlpsvc' = 'Manual'; 'DPS' = 'Manual'; 'CDPSvc' = 'Manual'; 'MapsBroker' = 'Manual'; 'edgeupdate' = 'Manual'
    'lfsvc' = 'Manual'; 'WbioSrvc' = 'Manual'; 'RetailDemo' = 'Manual'
    'BITS' = 'Auto retrasado'; 'WpnService' = 'Auto retrasado'
    'Spooler' = 'Auto retrasado'; 'LanmanServer' = 'Automatico'
    'WinDefend' = 'Automatico'; 'WdNisSvc' = 'Manual'; 'SecurityHealthService' = 'Manual'; 'wscsvc' = 'Auto retrasado'; 'mpssvc' = 'Automatico'; 'BFE' = 'Automatico'
    'wuauserv' = 'Manual'; 'UsoSvc' = 'Auto retrasado'; 'WaaSMedicSvc' = 'Manual'; 'CryptSvc' = 'Automatico'; 'TrustedInstaller' = 'Manual'
    'AppXSvc' = 'Manual'; 'ClipSVC' = 'Manual'; 'InstallService' = 'Manual'; 'Appinfo' = 'Manual'; 'VSS' = 'Manual'; 'swprv' = 'Manual'; 'W32Time' = 'Manual'
    'AdobeARMservice' = 'DESHABILITADO'
    'OneSyncSvc' = 'segun respuesta'; 'PimIndexMaintenanceSvc' = 'segun respuesta'; 'UnistoreSvc' = 'segun respuesta'; 'UserDataSvc' = 'segun respuesta'; 'MessagingService' = 'segun respuesta'
    'EventLog' = 'Automatico'; 'Schedule' = 'Automatico'; 'Winmgmt' = 'Automatico'; 'Audiosrv' = 'Automatico'; 'Dhcp' = 'Automatico'; 'Dnscache' = 'Automatico'; 'Themes' = 'Automatico'
}
foreach ($n in $espera.Keys) {
    $ini = InicioServicio $n
    if ($ini -eq 'no existe') { continue }
    $sv = Get-Service -Name $n
    $est = if ($sv) { [string]$sv.Status } else { '?' }
    $marca = if ($espera[$n] -eq 'segun respuesta' -or $espera[$n] -eq $ini) { ' ' } else { '*' }
    L ($marca + ' ' + $n.PadRight(22) + $ini.PadRight(16) + $est.PadRight(10) + $espera[$n])
}
L '  (* = distinto de lo que deja la v2. Antes de correrla, es normal que haya varios.)'

# --- Tareas programadas ---------------------------------------------------------
Titulo 'Tareas programadas'
$tareas = @(
    '\Microsoft\Windows\Defrag\ScheduledDefrag',
    '\Microsoft\Windows\Servicing\StartComponentCleanup',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver',
    '\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan',
    '\Microsoft\Windows\SystemRestore\SR',
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Maintenance\WinSAT',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting',
    '\Adobe Acrobat Update Task'
)
foreach ($t in $tareas) {
    $ruta = $t.Substring(0, $t.LastIndexOf('\') + 1)
    $nom = $t.Substring($t.LastIndexOf('\') + 1)
    $st = Get-ScheduledTask -TaskPath $ruta -TaskName $nom
    $estado = if ($st) { [string]$st.State } else { 'no existe' }
    L ($estado.PadRight(10) + $t)
}

# --- Politicas del equipo -------------------------------------------------------
Titulo 'Politicas del equipo'
$pol = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
$lista = @(
    @(($pol + '\DataCollection'), 'AllowTelemetry'),
    @(($pol + '\Windows Feeds'), 'EnableFeeds'),
    @(($pol + '\Windows Search'), 'AllowCortana'),
    @(($pol + '\Windows Search'), 'EnableDynamicContentInWSB'),
    @(($pol + '\GameDVR'), 'AllowGameDVR'),
    @(($pol + '\DeliveryOptimization'), 'DODownloadMode'),
    @(($pol + '\Windows Error Reporting'), 'Disabled'),
    @(($pol + '\CloudContent'), 'DisableWindowsConsumerFeatures'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System', 'DisableAcrylicBackgroundOnLogon'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray', 'HideSystray'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications', 'DisableEnhancedNotifications'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MRT', 'DontOfferThroughWUAU'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore', 'AutoDownload'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge', 'StartupBoostEnabled'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge', 'BackgroundModeEnabled'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended', 'SleepingTabsTimeout'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome', 'BackgroundModeEnabled')
)
foreach ($par in $lista) { L ($par[1].PadRight(32) + (Leer $par[0] $par[1]).PadRight(12) + $par[0].Replace('HKEY_LOCAL_MACHINE', 'HKLM')) }

# --- Ajustes del usuario --------------------------------------------------------
Titulo 'Ajustes del usuario de la sesion'
$lista = @(
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'), 'SilentInstalledAppsEnabled'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'), 'SubscribedContent-338389Enabled'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'), 'Enabled'),
    @(($U + '\Software\Policies\Microsoft\Windows\Explorer'), 'DisableSearchBoxSuggestions'),
    @(($U + '\Control Panel\Desktop'), 'UserPreferencesMask'),
    @(($U + '\Control Panel\Desktop'), 'MenuShowDelay'),
    @(($U + '\Control Panel\Desktop'), 'FontSmoothing'),
    @(($U + '\Control Panel\Desktop'), 'DragFullWindows'),
    @(($U + '\Control Panel\Desktop\WindowMetrics'), 'MinAnimate'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'IconsOnly'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'), 'VisualFXSetting'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'), 'EnableTransparency'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Search'), 'BackgroundAppGlobalToggle'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate', 'AutoDownload'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'LaunchTo'),
    @(($U + '\System\GameConfigStore'), 'GameDVR_Enabled')
)
foreach ($par in $lista) { L ($par[1].PadRight(32) + (Leer $par[0] $par[1])) }
$bg = Get-ChildItem -LiteralPath ('Registry::' + $U + '\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications')
$apagadas = @($bg | Where-Object { (Get-ItemProperty -LiteralPath $_.PSPath).Disabled -eq 1 }).Count
L ('Apps en segundo plano apagadas: ' + $apagadas + ' de ' + @($bg).Count + '  (interruptor general GlobalUserDisabled: ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications') 'GlobalUserDisabled') + ')')
$cls = if ($U -eq 'HKEY_CURRENT_USER') { 'HKEY_CURRENT_USER\Software\Classes' } else { $U + '_Classes' }
L ('Tipo de carpeta generico:       ' + (Leer ($cls + '\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell') 'FolderType'))
L ('OneDrive al inicio:             ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Run') 'OneDrive'))
$cam = '\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
L ('Ubicacion (equipo / usuario):   ' + (Leer ('HKEY_LOCAL_MACHINE' + $cam) 'Value') + ' / ' + (Leer ($U + $cam) 'Value'))
$nl = $null
try { $nl = [byte[]](Get-ItemProperty -LiteralPath ('Registry::' + $U + '\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings') -Name Data -ErrorAction Stop).Data } catch { }
$modo = 'sin configurar'
if ($nl) {
    $p = -1
    for ($k = $nl.Length - 4; $k -ge 0; $k--) { if ($nl[$k] -eq 0x43 -and $nl[$k + 1] -eq 0x42 -and $nl[$k + 2] -eq 1 -and $nl[$k + 3] -eq 0) { $p = $k + 4; break } }
    $modo = 'sin programar'
    if ($p -ge 0 -and $nl[$p] -eq 2 -and $nl[$p + 1] -eq 1) { $modo = if ($nl[$p + 2] -eq 0xC2 -and $nl[$p + 3] -eq 0x0A) { 'horario fijo' } else { 'del anochecer al amanecer' } }
}
L ('Luz nocturna:                   ' + $modo)
$ss = $U + '\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
L ('Sensor de almacenamiento:       activo ' + (Leer $ss '01') + ' | papelera ' + (Leer $ss '08') + ', ' + (Leer $ss '256') + ' dias | descargas ' + (Leer $ss '32') + ' | cada ' + (Leer $ss '2048') + ' dias')

# --- Disco y energia ----------------------------------------------------------
Titulo 'Disco y energia'
L ((fsutil behavior query DisableLastAccess) -join ' ')
L ((fsutil behavior query Disable8dot3) -join ' ')
$nd = (Get-Partition -DriveLetter $env:SystemDrive.Substring(0, 1)).DiskNumber
$dd = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq [string]$nd } | Select-Object -First 1
$ca = $null
if ($dd) { $ca = $dd | Get-StorageAdvancedProperty }
if ($ca) { L ('Cache de escritura del disco:   ' + $ca.IsDeviceCacheEnabled + '   (vaciado de bufer desactivado: ' + $ca.IsPowerProtected + '; la v2 lo deja en True si el disco es mecanico)') } else { L 'Cache de escritura del disco:   Windows no informa su estado' }
$rb = @(Get-PSDrive -PSProvider FileSystem | ForEach-Object { Join-Path $_.Root 'ReadyBoost.sfcache' } | Where-Object { Test-Path -LiteralPath $_ })
$rbTexto = 'no'
if ($rb.Count) { $rbTexto = $rb -join ', ' }
L ('ReadyBoost en uso:              ' + $rbTexto)
$compacto = $false
foreach ($f in 'System32\shell32.dll', 'System32\mshtml.dll', 'explorer.exe') {
    $ruta = Join-Path $env:windir $f
    if ((Test-Path -LiteralPath $ruta) -and ((Get-Item -LiteralPath $ruta -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { $compacto = $true }
}
L ('Sistema comprimido (CompactOS): ' + $compacto)
L ('Plan de energia:                ' + ((powercfg /getactivescheme) -join ' '))
L ('Inicio rapido (HiberbootEnabled): ' + (Leer 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'))
L ('Hibernacion habilitada:         ' + (Leer 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled'))
# Lee los valores actuales (enchufada / bateria) de un ajuste del plan activo.
function Energia([string]$sub, [string]$ajuste) {
    $v = powercfg /query SCHEME_CURRENT $sub $ajuste | Where-Object { $_ -match '0x[0-9a-fA-F]{8}\s*$' } | Select-Object -Last 2 | ForEach-Object { [Convert]::ToInt32(([regex]::Match($_, '0x[0-9a-fA-F]{8}')).Value, 16) }
    if ($v) { ($v -join ' / ') } else { '?' }
}
L 'Valores enchufada / bateria. Botones y tapa: 0 nada, 1 suspender, 2 hibernar, 3 apagar.'
L ('Boton de encendido:             ' + (Energia SUB_BUTTONS PBUTTONACTION))
L ('Cerrar la tapa:                 ' + (Energia SUB_BUTTONS LIDACTION))
L ('Boton de suspension:            ' + (Energia SUB_BUTTONS SBUTTONACTION))
L ('Bateria critica:                ' + (Energia SUB_BATTERY BATACTIONCRIT))
L ('Suspender tras (seg, 14400 = 4 h, 3600 = 1 h): ' + (Energia SUB_SLEEP STANDBYIDLE))
L ('Hibernar tras (seg, 0 nunca):   ' + (Energia SUB_SLEEP HIBERNATEIDLE))
L ('Apagar disco tras (seg, 0 nunca): ' + (Energia SUB_DISK DISKIDLE))
L ('Apagar pantalla tras (seg, 900 = 15 min): ' + (Energia SUB_VIDEO VIDEOIDLE))
$fm = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'
L ('Menu de apagado: Suspender / Hibernar visibles: ' + (Leer $fm 'ShowSleepOption') + ' / ' + (Leer $fm 'ShowHibernateOption') + '   (0 = ocultos)')

# --- Temporales y Prefetch ----------------------------------------------------
Titulo 'Temporales y Prefetch (tamano actual)'
# Mide sin seguir enlaces (junctions ni symlinks), igual que la limpieza.
function Medir([string]$carpeta) {
    if (-not [IO.Directory]::Exists($carpeta)) { return $null }
    $total = 0; $archivos = 0
    $pila = New-Object System.Collections.Stack; $pila.Push($carpeta)
    while ($pila.Count -gt 0) {
        $d = $pila.Pop()
        try { $entradas = [IO.Directory]::GetFileSystemEntries($d) } catch { continue }
        foreach ($e in $entradas) {
            try { $a = [IO.File]::GetAttributes($e) } catch { continue }
            if ($a -band [IO.FileAttributes]::ReparsePoint) { continue }
            if ($a -band [IO.FileAttributes]::Directory) { $pila.Push($e) } else { $archivos++; try { $total += (New-Object IO.FileInfo($e)).Length } catch { } }
        }
    }
    return ([string][Math]::Round($total / 1MB, 1)).PadLeft(8) + ' MB en ' + $archivos + ' archivos'
}
$carpetasTemp = @(@('temp (Temp de Windows)', (Join-Path $env:SystemRoot 'Temp')))
Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LocalPath } | ForEach-Object {
    $quien = Split-Path $_.LocalPath -Leaf
    $carpetasTemp += ,@(('%temp% de ' + $quien), (Join-Path $_.LocalPath 'AppData\Local\Temp'))
    $carpetasTemp += ,@(('Cache de Adobe Reader de ' + $quien), (Join-Path $_.LocalPath 'AppData\LocalLow\Adobe\AcroCef\DC\Acrobat\Cache'))
}
$carpetasTemp += ,@('Temp de la cuenta del sistema', (Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\Temp'))
$carpetasTemp += ,@('Informes de errores de Windows', (Join-Path $env:ProgramData 'Microsoft\Windows\WER'))
$carpetasTemp += ,@('Volcados de cuelgues de video', (Join-Path $env:SystemRoot 'LiveKernelReports'))
$carpetasTemp += ,@('Descargas del actualizador de Adobe', (Join-Path $env:ProgramData 'Adobe\ARM'))
$carpetasTemp += ,@('Prefetch', (Join-Path $env:SystemRoot 'Prefetch'))
foreach ($par in $carpetasTemp) { $m = Medir $par[1]; if ($null -ne $m) { L ($par[0].PadRight(40) + $m) } }
$pf = Join-Path $env:SystemRoot 'Prefetch'
L ('Prefetch: entradas de programas (.pf): ' + @(Get-ChildItem -LiteralPath $pf -Filter '*.pf' -Force).Count + '   rastro de arranque (NTOSBOOT): ' + [bool](Get-ChildItem -LiteralPath $pf -Filter 'NTOSBOOT-*' -Force) + '   Layout.ini: ' + (Test-Path -LiteralPath (Join-Path $pf 'Layout.ini')))

# --- Puntos de restauracion ---------------------------------------------------
Titulo 'Puntos de restauracion (ultimos 3)'
L ('Restaurar sistema (RPSessionInterval, 1 = activado): ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' 'RPSessionInterval'))
$rp = Get-ComputerRestorePoint | Select-Object -Last 3
if ($rp) { $rp | ForEach-Object { L ([Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime).ToString('yyyy-MM-dd HH:mm') + '  ' + $_.Description) } } else { L '(ninguno)' }

# --- Clasicos de Windows 7 -----------------------------------------------------
Titulo 'Clasicos de Windows 7'
$fotos = Get-AppxPackage -AllUsers -Name Microsoft.Windows.Photos
L ('App Fotos nueva instalada:      ' + [bool]$fotos)
$fa = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'
L ('Visualizador clasico registrado para: ' + ((@('.jpg', '.jpeg', '.jfif', '.png', '.gif', '.bmp', '.webp', '.heic', '.heif', '.avif') | Where-Object { (Leer $fa $_) -ne '(no existe)' }) -join ' '))
$cod = foreach ($par in @(@('HEIF', 'Microsoft.HEIFImageExtension'), @('HEVC', 'Microsoft.HEVCVideoExtension*'), @('WebP', 'Microsoft.WebpImageExtension'), @('AV1', 'Microsoft.AV1VideoExtension'))) { $par[0] + ' ' + [bool](Get-AppxPackage -AllUsers -Name $par[1]) }
L ('Codecs de la Store:             ' + ($cod -join ' | ') + '  (HEIC: HEIF y HEVC; AVIF: AV1)')
L ('Programa predeterminado del usuario para .jpg: ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice') 'ProgId'))
L ('Alt+Tab clasico (AltTabSettings): ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer') 'AltTabSettings'))

# --- Adobe Reader --------------------------------------------------------------
Titulo 'Adobe Reader'
$u = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$r = Get-ItemProperty -Path $u | Where-Object { $_.DisplayName -match 'Acrobat|Adobe Reader' } | Select-Object -First 1
if ($r) {
    L ('Instalado:                      ' + $r.DisplayName + ' ' + $r.DisplayVersion)
    L ('Servicio de actualizacion:      ' + (InicioServicio 'AdobeARMservice') + '   (la v2 lo deja DESHABILITADO)')
    $ta = @(Get-ScheduledTask -TaskName 'Adobe Acrobat Update Task*')
    $estadoTarea = 'no existe'
    if ($ta.Count) { $estadoTarea = [string]$ta[0].State }
    L ('Tarea de actualizacion:         ' + $estadoTarea + '   (la v2 la deja Disabled)')
} else { L 'No esta instalado.' }
L ('Programa predeterminado para .pdf: ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice') 'ProgId'))

# --- Programas de la opcion 4 ---------------------------------------------------
Titulo 'Programas de la opcion 4'
foreach ($prog in 'WinRAR', 'VLC media player', 'Google Chrome') {
    $r = Get-ItemProperty -Path $u | Where-Object { $_.DisplayName -like ($prog + '*') } | Select-Object -First 1
    $ver = 'no instalado'
    if ($r) { $ver = [string]$r.DisplayVersion }
    L (($prog + ':').PadRight(32) + $ver)
}
$fl = Get-ItemProperty -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'
$ub = $false
if ($fl) { $ub = [bool]($fl.PSObject.Properties | Where-Object { [string]$_.Value -like 'ddkjiahejlhfcafbddmgiahcphecmpfh*' }) }
L ('uBlock Origin Lite (politica):  ' + $ub)
L ('Chrome de aula (BrowserSignin): ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome' 'BrowserSignin') + '  (0 = sin iniciar sesion en Chrome)')

# --- Apps preinstaladas -------------------------------------------------------
Titulo 'Apps preinstaladas que la v2 puede quitar (presentes)'
$apps = 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.Office.OneNote', 'Microsoft.OutlookForWindows', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.WindowsAlarms', 'Microsoft.WindowsMaps', 'microsoft.windowscommunicationsapps', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo', 'Microsoft.XboxApp', 'Microsoft.XboxGamingOverlay', 'king.com.*'
$hay = foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a | Select-Object -ExpandProperty Name -Unique }
if ($hay) { L (($hay | Sort-Object -Unique) -join ', ') } else { L '(ninguna)' }

# --- Caracteristicas opcionales -----------------------------------------------
Titulo 'Caracteristicas opcionales instaladas'
$caps = @(Get-WindowsCapability -Online -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Installed' } | ForEach-Object { $_.Name.Split('~')[0] })
if ($caps.Count) { L (($caps | Sort-Object -Unique) -join ', ') } else { L '(no se pudo leer)' }

# --- Inicio de Windows --------------------------------------------------------
Titulo 'Programas que arrancan con Windows'
foreach ($k in @(($U + '\Software\Microsoft\Windows\CurrentVersion\Run'), 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run')) {
    $i = Get-Item -LiteralPath ('Registry::' + $k)
    if ($i) { $i.Property | ForEach-Object { L ('  - ' + $_) } }
}

# --- Guardar --------------------------------------------------------------------
$nombre = 'estado-' + $env:COMPUTERNAME + '-' + (Get-Date -Format 'yyyyMMdd-HHmm') + '.txt'
$destino = Join-Path (Split-Path -Parent $env:OPT_RUTA) $nombre
try { [IO.File]::WriteAllLines($destino, $lineas) } catch { $destino = Join-Path $env:TEMP $nombre; [IO.File]::WriteAllLines($destino, $lineas) }
Write-Host ''
Write-Host ('Reporte guardado en: ' + $destino) -ForegroundColor Green
#VERIFICAR-FIN#
#LUZ-INICIO#
# Luz nocturna programada "del anochecer al amanecer". Windows la guarda en un
# blob binario de CloudStore (Bond CompactBinary v1, sin documentar). Hay dos
# envoltorios: el viejo (02 00 00 00 + FILETIME + 4 ceros) y el Bond (43 42 01 00
# ...); se escribe en el que ya tenga el usuario, y si no hay ninguno, en el Bond.
# Contenido: campo 0 = programacion activa; campo 10 presente = horario fijo
# (ausente = anochecer a amanecer); 20/30 = horario fijo; 40 = temperatura (K);
# 50/60 = puesta y salida del sol que calcula Windows.
$ErrorActionPreference = 'Stop'
$clave = $env:UPS + '\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings'
function Varint([UInt64]$v) {
    $r = @()
    do { $b = [int]($v -band 0x7F); $v = $v -shr 7; if ($v -gt 0) { $b = $b -bor 0x80 }; $r += $b } while ($v -gt 0)
    , $r
}
function Hora([int]$id, [int[]]$hm) {
    $r = @(0xCA, $id)
    if ($hm[0] -gt 0) { $r += 0x0E, $hm[0] }
    if ($hm[1] -gt 0) { $r += 0x2E, $hm[1] }
    , ($r + 0x00)
}
# Valores por defecto; si ya hay configuracion, se conservan los del usuario.
$temp = 4000; $ini = @(21, 0); $fin = @(7, 0); $ocaso = @(19, 0); $alba = @(7, 0)
$viejo = $null
try { $viejo = [byte[]](Get-ItemProperty -LiteralPath $clave -Name Data).Data } catch { }
$formato = 'bond'
if ($viejo -and $viejo.Length -gt 20) {
    if ($viejo[0] -eq 2) { $formato = 'viejo' }
    # El contenido empieza en la ultima cabecera "CB" 01 00.
    $p = -1
    for ($k = $viejo.Length - 4; $k -ge 0; $k--) {
        if ($viejo[$k] -eq 0x43 -and $viejo[$k + 1] -eq 0x42 -and $viejo[$k + 2] -eq 1 -and $viejo[$k + 3] -eq 0) { $p = $k + 4; break }
    }
    $k = $p
    while ($p -ge 0 -and $k -lt $viejo.Length - 1) {
        $c = $viejo[$k]
        if ($c -eq 0) { break }
        if (($c -band 0xE0) -eq 0xC0) { $id = $viejo[$k + 1]; $k += 2 } else { $id = $c -shr 5; $k += 1 }
        $tipo = $c -band 0x1F
        if ($tipo -eq 2) { $k += 1 }
        elseif ($tipo -eq 15) {
            $n = 0; $s = 0
            do { $b = $viejo[$k]; $n = $n -bor (($b -band 0x7F) -shl $s); $s += 7; $k++ } while ($b -band 0x80)
            if ($id -eq 40 -and ($n -shr 1) -ge 1200 -and ($n -shr 1) -le 6500) { $temp = $n -shr 1 }
        }
        elseif ($tipo -eq 10) {
            $hm = @(0, 0)
            while ($viejo[$k] -ne 0) {
                if ($viejo[$k] -eq 0x0E) { $hm[0] = $viejo[$k + 1] } elseif ($viejo[$k] -eq 0x2E) { $hm[1] = $viejo[$k + 1] }
                $k += 2
            }
            $k++
            if ($id -eq 20) { $ini = $hm } elseif ($id -eq 30) { $fin = $hm } elseif ($id -eq 50) { $ocaso = $hm } elseif ($id -eq 60) { $alba = $hm }
        }
        else { break }
    }
}
$dentro = @(0x43, 0x42, 0x01, 0x00, 0x02, 0x01) + (Hora 0x14 $ini) + (Hora 0x1E $fin) + @(0xCF, 0x28) + (Varint ([UInt64]($temp * 2))) + (Hora 0x32 $ocaso) + (Hora 0x3C $alba) + @(0x00)
if ($formato -eq 'viejo') {
    $blob = @(2, 0, 0, 0) + [BitConverter]::GetBytes([DateTime]::UtcNow.ToFileTimeUtc()) + @(0, 0, 0, 0) + $dentro
} else {
    $ts = [UInt64][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $blob = @(0x43, 0x42, 0x01, 0x00, 0x0A, 0x02, 0x01, 0x00, 0x2A, 0x06) + (Varint $ts) + @(0x2A, 0x2B, 0x0E) + (Varint ([UInt64]$dentro.Count)) + $dentro + @(0, 0, 0)
}
try {
    if (-not (Test-Path -LiteralPath $clave)) { New-Item -Path $clave -Force | Out-Null }
    Set-ItemProperty -LiteralPath $clave -Name Data -Value ([byte[]]$blob) -Type Binary
    Write-Output ('  [OK] Luz nocturna: del anochecer al amanecer, a ' + $temp + ' K.')
} catch {
    Write-Output '  [AVISO] No se pudo programar la luz nocturna: hacelo en Configuracion, Pantalla.'
}
#LUZ-FIN#
#AULA-INICIO#
# Cierra Chrome en todas las sesiones y borra su carpeta de datos (User Data)
# en cada usuario de Windows. Despues deja el archivo "First Run", asi Chrome
# arranca sin la pantalla de primer uso. rd no sigue enlaces (junctions).
$ErrorActionPreference = 'SilentlyContinue'
for ($k = 0; $k -lt 10 -and (Get-Process -Name chrome); $k++) { Get-Process -Name chrome | Stop-Process -Force; Start-Sleep -Milliseconds 500 }
$perfiles = @(Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special -and $_.LocalPath -and [IO.Directory]::Exists($_.LocalPath) })
$total = 0; $usuarios = 0; $fallas = 0
foreach ($p in $perfiles) {
    $ud = Join-Path $p.LocalPath 'AppData\Local\Google\Chrome\User Data'
    if (-not [IO.Directory]::Exists($ud)) { continue }
    $n = @([IO.Directory]::GetDirectories($ud) | Where-Object { [IO.File]::Exists((Join-Path $_ 'Preferences')) }).Count
    for ($k = 0; $k -lt 3 -and [IO.Directory]::Exists($ud); $k++) { & cmd.exe /c rd /s /q "$ud" 2>$null; if ([IO.Directory]::Exists($ud)) { Start-Sleep -Seconds 2 } }
    if ([IO.Directory]::Exists($ud)) { $fallas++ }
    [IO.Directory]::CreateDirectory($ud) | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $ud 'First Run'), [byte[]]@())
    $total += $n; $usuarios++
    Write-Output ('    ' + (Split-Path $p.LocalPath -Leaf) + ': ' + $n + ' perfil(es) de Chrome borrado(s)')
}
if ($usuarios -eq 0) { Write-Output '  Chrome no tiene datos en ningun usuario de Windows: nada que borrar.' }
else { Write-Output ('  [OK] Chrome: ' + $total + ' perfil(es) borrado(s) en ' + $usuarios + ' usuario(s) de Windows.') }
if ($fallas) { Write-Output ('  [AVISO] En ' + $fallas + ' usuario(s) quedaron archivos en uso: reinicia y repeti la opcion 5.') }
#AULA-FIN#
