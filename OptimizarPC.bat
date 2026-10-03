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

:: Hardware: RAM, placa de video sin driver y antirrobo de Conectar Igualdad
:: (Theft Deterrent). El driver basico de Microsoft se instala como display.inf.
set "RAM_MB=9999"
set "GPU_BASICA=0"
set "ANTIRROBO=0"
set "CPU_NOMBRE=desconocido"
for /f "usebackq tokens=1-3,* delims=|" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$r=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB); $g=0; Get-CimInstance Win32_VideoController | ForEach-Object { if ($_.InfFilename -eq 'display.inf' -or $_.Name -match 'Basic Display') { $g=1 } }; $t=0; foreach ($d in $env:ProgramFiles, ${env:ProgramFiles(x86)}) { if ($d -and (Test-Path -LiteralPath (Join-Path $d 'Intel Learning Series\Theft Deterrent'))) { $t=1 } }; if (Get-Service | Where-Object { ($_.Name + ' ' + $_.DisplayName) -match 'Theft|Deterrent|TDAgent' }) { $t=1 }; foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') { $i=Get-Item -LiteralPath $k -ErrorAction SilentlyContinue; if ($i -and ($i.Property -match 'Theft|Deterrent|TDAgent')) { $t=1 } }; $c=(Get-CimInstance Win32_Processor | Select-Object -First 1).Name -replace '\s+',' '; [string]$r + '|' + $g + '|' + $t + '|' + $c.Trim()"`) do (
    set "RAM_MB=%%a"
    set "GPU_BASICA=%%b"
    set "ANTIRROBO=%%c"
    set "CPU_NOMBRE=%%d"
)

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
if not "%RAM_MB%"=="9999" echo   RAM: %RAM_MB% MB
if %RAM_MB% GEQ 1500 goto :ram_ok
echo   AVISO: tiene menos de 2 GB de RAM. Windows 10 de 64 bits pide 2 GB como minimo.
echo          Estos Atom aceptan hasta 2 GB: ampliarla es la mejora mas barata que hay.
:ram_ok
if not "%GPU_BASICA%"=="1" goto :gpu_ok
echo   AVISO: la placa de video anda con el driver basico de Microsoft, sin aceleracion.
echo          Es lo tipico de los Atom N2600 y N2800 (GMA 3600): Intel no hizo driver para
echo          Windows 10. En muchas netbooks anda el de Windows 7: probalo con un punto de
echo          restauracion hecho. Sin driver, videos y animaciones van lentos. Ver README.md.
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
echo   4. Quitar apps preinstaladas: Xbox, Solitario, Candy Crush, Noticias, Tu Telefono,
echo      Skype, Contactos, Mapas, Correo y Calendario, Outlook nuevo, OneNote, Notas
echo      rapidas, Alarmas, Groove, Peliculas y TV, Paint 3D, Cortana, Copilot y
echo      similares. Quedan: Store, Calculadora, Camara, Grabadora de sonidos, Clima y
echo      Recortes y anotacion. Fotos va en la pregunta 5. Todo se reinstala de la Store.
choice /c SN /n /m "     Quitarlas? [S/N]: "
if errorlevel 2 (set "QUITARAPPS=N") else (set "QUITARAPPS=S")
echo.
echo   5. Volver a los clasicos de Windows 7 que siguen escondidos en Windows 10:
echo      el Visualizador de fotos en vez de la app Fotos, que en PCs lentas tarda
echo      en abrir, y el Alt+Tab clasico, sin miniaturas.
choice /c SN /n /m "     Usarlos? [S/N]: "
if errorlevel 2 (set "CLASICOS=N") else (set "CLASICOS=S")
echo.
echo   6. Restaurar sistema guarda puntos para volver atras. Desactivarlo libera hasta
echo      un 10%% del disco y saca escrituras de fondo, pero borra TODOS los puntos,
echo      incluido el que crearia este script. La vuelta atras queda en manos de
echo      RevertirOptimizacion.bat o de reinstalar.
choice /c SN /n /m "     Desactivarlo? [S/N]: "
if errorlevel 2 (set "SINRESTAURAR=N") else (set "SINRESTAURAR=S")

:: =========================================================================
call :titulo "1/12  Punto de restauracion"
:: =========================================================================
if "%SINRESTAURAR%"=="S" goto :punto_salteado
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
goto :punto_listo
:punto_salteado
echo   Salteado: elegiste desactivar Restaurar sistema, que lo borraria igual.
echo   Si algo sale mal, la vuelta atras es RevertirOptimizacion.bat.
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

:: Tareas que tienen que estar activas: desfragmentacion (clave en HDD), limpieza
:: automatica de actualizaciones viejas, aviso de disco por fallar, analisis de
:: Defender y puntos de restauracion.
for %%t in ("\Microsoft\Windows\Defrag\ScheduledDefrag" "\Microsoft\Windows\Servicing\StartComponentCleanup" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver" "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup" "\Microsoft\Windows\Windows Defender\Windows Defender Verification" "\Microsoft\Windows\WindowsUpdate\Scheduled Start") do schtasks /change /tn %%t /enable >nul 2>&1
if not "%SINRESTAURAR%"=="S" schtasks /change /tn "\Microsoft\Windows\SystemRestore\SR" /enable >nul 2>&1
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
:: alarmas, reproductores y Recortes y anotacion. Fotos si se apaga: es de las
:: que mas consume.
:: El interruptor general rompe la busqueda del Inicio.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b='%UPS%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; $keep='Microsoft.Windows.*','MicrosoftWindows.*','windows.*','Microsoft.AAD.BrokerPlugin*','Microsoft.AccountsControl*','Microsoft.CredDialogHost*','Microsoft.ECApp*','Microsoft.AsyncTextService*','Microsoft.BioEnrollment*','Microsoft.LockApp*','Microsoft.Win32WebViewHost*','Microsoft.WindowsStore*','Microsoft.DesktopAppInstaller*','Microsoft.ScreenSketch*','Microsoft.WindowsAlarms*','Microsoft.ZuneMusic*','Microsoft.ZuneVideo*','SpotifyAB.SpotifyMusic*'; $force='Microsoft.Windows.Photos*'; $n=0; Get-ChildItem -LiteralPath $b -ErrorAction SilentlyContinue | ForEach-Object { $app=$_.PSChildName; if (($app -like $force) -or -not ($keep | Where-Object { $app -like $_ })) { Set-ItemProperty -LiteralPath $_.PSPath -Name Disabled -Value 1 -Type DWord; Set-ItemProperty -LiteralPath $_.PSPath -Name DisabledByUser -Value 1 -Type DWord; $n++ } }; Write-Output ('  [OK] Apps en segundo plano desactivadas: ' + $n)"

:: =========================================================================
call :titulo "8/12  Interfaz y Explorador"
:: =========================================================================
set "_desk=%UHIVE%\Control Panel\Desktop"
set "_adv=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
:: Efectos visuales en "mejor rendimiento", salvo:
::  - el suavizado de fuentes: no es un efecto, es lo que hace legible el texto;
::  - mostrar el contenido de la ventana mientras se arrastra;
::  - la animacion al minimizar y maximizar, solo si la placa de video tiene
::    driver: con el adaptador basico la dibuja el procesador y va a los saltos.
reg add "%_desk%" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
call :sz "%_desk%" DragFullWindows 1
call :sz "%_desk%" MenuShowDelay 100
call :sz "%_desk%" FontSmoothing 2
call :dword "%_desk%" FontSmoothingType 2
set "_minanim=1"
if "%GPU_BASICA%"=="1" set "_minanim=0"
call :sz "%_desk%\WindowMetrics" MinAnimate %_minanim%
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" VisualFXSetting 3
call :dword "%_adv%" ListviewAlphaSelect 0
call :dword "%_adv%" ListviewShadow 0
call :dword "%_adv%" TaskbarAnimations 0
:: Iconos en vez de miniaturas: en un disco mecanico, abrir una carpeta con fotos
:: o videos obliga a leer cada archivo para dibujar su miniatura.
call :dword "%_adv%" IconsOnly 1
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 0
:: Sin el desenfoque "acrilico" de la pantalla de inicio de sesion: otro efecto de
:: transparencia, y sin aceleracion de video lo calcula el procesador.
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon 1
:: El Explorador abre en "Este equipo" y no rastrea los programas abiertos.
call :dword "%_adv%" LaunchTo 1
call :dword "%_adv%" Start_TrackProgs 0
:: Sin deteccion automatica del tipo de carpeta (tweak de WinUtil).
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
call :sz "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell" FolderType NotSpecified
echo   [OK] Efectos visuales al minimo. Quedan el suavizado de fuentes y el contenido
echo        de la ventana al arrastrar.
if "%_minanim%"=="1" echo   [OK] Animacion al minimizar y maximizar: activada, el video tiene driver.
if "%_minanim%"=="0" echo   [OK] Animacion al minimizar y maximizar: apagada, el video no tiene driver.
echo   [OK] Menus mas rapidos, sin transparencias, animaciones ni desenfoque al iniciar sesion.
echo   [OK] Explorador: abre en Este equipo, muestra iconos en vez de miniaturas y no
echo        adivina el tipo de cada carpeta.

:: =========================================================================
call :titulo "9/12  Memoria, disco y energia"
:: =========================================================================
fsutil behavior set DisableLastAccess 1 >nul 2>&1
fsutil behavior set Disable8dot3 1 >nul 2>&1
echo   [OK] NTFS sin registro de ultimo acceso ni nombres cortos 8.3.

:: Archivo de paginacion con tamano propio. El automatico arranca chico y crece
:: cuando hace falta: en un disco lento, mientras crece, los programas pueden
:: fallar por falta de memoria (Microsoft), y cada crecimiento lo fragmenta.
:: Inicial: 1,5 veces la RAM, lo que recomienda Microsoft. Maximo: 3 veces la RAM
:: o 4 GB, como el automatico. Solo si estaba en automatico: si alguien lo
:: configuro a mano, se respeta. Se aplica al reiniciar.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cs=Get-CimInstance Win32_ComputerSystem; if (-not $cs.AutomaticManagedPagefile) { Write-Output '  [OK] Archivo de paginacion configurado a mano: se respeta como esta.'; exit 0 }; $ram=[math]::Round($cs.TotalPhysicalMemory / 1MB); $ini=[int][math]::Round($ram * 1.5); $max=[int][math]::Max($ram * 3, 4096); $libre=[math]::Floor((Get-PSDrive -Name $env:SystemDrive.Substring(0,1)).Free / 1MB); if ($libre -lt ($ini + 2048)) { Write-Output '  [AVISO] Poco espacio libre: el archivo de paginacion sigue en automatico.'; exit 0 }; try { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop; $nombre=$env:SystemDrive + '\pagefile.sys'; $pf=Get-CimInstance Win32_PageFileSetting | Where-Object { $_.Name -eq $nombre } | Select-Object -First 1; if ($pf) { Set-CimInstance -InputObject $pf -Property @{InitialSize=[uint32]$ini; MaximumSize=[uint32]$max} -ErrorAction Stop } else { New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name=$nombre; InitialSize=[uint32]$ini; MaximumSize=[uint32]$max} -ErrorAction Stop | Out-Null }; Write-Output ('  [OK] Archivo de paginacion: ' + $ini + ' MB desde el arranque, hasta ' + $max + ' MB. Ya no crece de a pedazos.') } catch { Set-CimInstance -InputObject $cs -Property @{AutomaticManagedPagefile=$true} -ErrorAction SilentlyContinue; Write-Output '  [AVISO] No se pudo configurar el archivo de paginacion: sigue en automatico.' }"

:: Cache de escritura del disco: viene activada y en un disco mecanico es clave.
:: Si alguien la apago, se avisa. Tambien se avisa si alguien desactivo el vaciado
:: del bufer, que ante un corte de luz puede corromper archivos.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$n=(Get-Partition -DriveLetter $env:SystemDrive.Substring(0,1) -ErrorAction SilentlyContinue).DiskNumber; $d=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq [string]$n } | Select-Object -First 1; $p=$null; if ($d) { $p=$d | Get-StorageAdvancedProperty -ErrorAction SilentlyContinue }; if (-not $p) { Write-Output '  [OK] Cache de escritura del disco: Windows no informa su estado, queda como esta.'; exit 0 }; if ($p.IsDeviceCacheEnabled) { Write-Output '  [OK] Cache de escritura del disco: activada.' } else { Write-Output '  [AVISO] La cache de escritura del disco esta APAGADA: escribir es mucho mas lento.'; Write-Output '          Activala en Administrador de dispositivos, Unidades de disco, tu disco,'; Write-Output '          Directivas: Habilitar cache de escritura en el dispositivo.' }; if ($p.IsPowerProtected -and [string]$d.MediaType -eq 'HDD') { Write-Output '  [AVISO] Alguien desactivo el vaciado del bufer de escritura: ante un corte de luz'; Write-Output '          se pueden corromper archivos. Destilda esa opcion en el mismo lugar.' }"

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

:: Energia: la prioridad es la velocidad, no el ahorro. Se aplica a los tres
:: planes de Windows, por si alguien cambia de plan despues:
::  - el disco nunca se apaga solo: despertarlo congela la PC varios segundos;
::  - suspende sola a las 4 horas sin uso: le da tiempo de sobra al mantenimiento
::    automatico de Windows, que corre con la PC prendida y sin uso. Nunca hiberna;
::  - boton de encendido y tapa: apagado completo; boton de suspension: nada;
::  - bateria critica: apagado completo, la unica salida prolija sin hibernacion.
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
echo   [OK] Suspension a las 4 horas sin uso: da tiempo al mantenimiento de Windows.
echo   [OK] Boton de encendido y tapa: apagado completo. Boton de suspension: nada.
echo   [OK] Bateria critica: apagado completo.
:: Sin hibernacion ni inicio rapido: cada apagado es completo, cada arranque es
:: limpio y se borra hiberfil.sys: el 40% de la RAM, unos 800 MB con 2 GB.
powercfg /hibernate off >nul 2>&1
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" HiberbootEnabled 0
:: Suspender e Hibernar, fuera del menu de apagado.
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowSleepOption 0
call :dword "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" ShowHibernateOption 0
echo   [OK] Sin hibernacion ni inicio rapido: cada apagado es completo.
echo   [OK] Suspender e Hibernar ya no aparecen en el menu de apagado.
:: Restaurar sistema, segun la pregunta 6. Lo desactiva con la herramienta oficial,
:: que borra sus puntos de restauracion y libera su espacio.
if not "%SINRESTAURAR%"=="S" goto :restaurar_listo
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Disable-ComputerRestore -Drive ($env:SystemDrive + '\') -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 goto :restaurar_error
schtasks /change /tn "\Microsoft\Windows\SystemRestore\SR" /disable >nul 2>&1
echo   [OK] Restaurar sistema desactivado: se borraron sus puntos y se libero su espacio.
goto :restaurar_listo
:restaurar_error
echo   [AVISO] No se pudo desactivar Restaurar sistema. Se puede a mano en Propiedades
echo           del sistema, Proteccion del sistema, Configurar.
:restaurar_listo

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
call :titulo "11/12  Opcionales y Adobe Reader"
:: =========================================================================
if "%ONEDRIVE%"=="S" goto :onedrive_listo
reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
echo   [OK] OneDrive ya no arranca con Windows. No se desinstalo.
:onedrive_listo
if "%QUITARAPPS%"=="N" goto :apps_listo
echo   Quitando apps preinstaladas para todos los usuarios, puede tardar...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$apps='Microsoft.549981C3F5F10','Microsoft.BingNews','Microsoft.BingSearch','Microsoft.Copilot','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.Messaging','Microsoft.Microsoft3DViewer','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MicrosoftStickyNotes','Microsoft.MixedReality.Portal','Microsoft.MSPaint','Microsoft.Office.OneNote','Microsoft.OneConnect','Microsoft.OutlookForWindows','Microsoft.People','Microsoft.PowerAutomateDesktop','Microsoft.Print3D','Microsoft.SkypeApp','Microsoft.Todos','Microsoft.Wallet','Microsoft.WindowsAlarms','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','microsoft.windowscommunicationsapps','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.GamingApp','Microsoft.XboxApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Clipchamp.Clipchamp','MicrosoftTeams','king.com.*'; $prov=Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue | Sort-Object PackageFullName -Unique | ForEach-Object { Write-Output ('    - ' + $_.Name); Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }; $prov | Where-Object { $_.DisplayName -like $a } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null } }"
echo   [OK] Apps preinstaladas quitadas.
:apps_listo
if "%CLASICOS%"=="N" goto :clasicos_listo
:: Visualizador de fotos de Windows, el de Windows 7: sigue instalado, pero
:: Windows 10 le saco las fotos comunes. Se le devuelven con su nombre y su
:: icono de siempre, y se registra en "Abrir con" y en Aplicaciones predeterminadas.
call :visor_tipo Jpeg jpegfile "Imagen JPEG" .jpg .jpeg .jpe .jfif
call :visor_tipo Png pngfile "Imagen PNG" .png
call :visor_tipo Gif giffile "Imagen GIF" .gif
call :visor_tipo Bitmap Paint.Picture "Imagen de mapa de bits" .bmp .dib
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "Windows Photo Viewer" /t REG_SZ /d "Software\Microsoft\Windows Photo Viewer\Capabilities" /f >nul 2>&1
set "_app=HKLM\SOFTWARE\Classes\Applications\photoviewer.dll"
reg add "%_app%\shell\open" /v MuiVerb /t REG_SZ /d "@photoviewer.dll,-3043" /f >nul 2>&1
reg add "%_app%\shell\open\command" /ve /t REG_EXPAND_SZ /d "%%SystemRoot%%\System32\rundll32.exe \"%%ProgramFiles%%\Windows Photo Viewer\PhotoViewer.dll\", ImageView_Fullscreen %%1" /f >nul 2>&1
reg add "%_app%\shell\open\DropTarget" /v Clsid /t REG_SZ /d "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}" /f >nul 2>&1
for %%e in (.jpg .jpeg .jpe .jfif .png .gif .bmp .dib .tif .tiff) do reg add "%_app%\SupportedTypes" /v %%e /t REG_SZ /d "" /f >nul 2>&1
echo   [OK] Visualizador de fotos de Windows recuperado para JPG, PNG, GIF y BMP.
:: La app Fotos nueva, para todos los usuarios.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers -Name Microsoft.Windows.Photos -ErrorAction SilentlyContinue | ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }; Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Microsoft.Windows.Photos' } | ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }"
echo   [OK] App Fotos quitada. Si algun dia hace falta, se reinstala desde la Store.
:: Alt+Tab clasico: iconos en vez de miniaturas en vivo de cada ventana.
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer" AltTabSettings 1
echo   [OK] Alt+Tab clasico activado.
:clasicos_listo
:: Adobe Reader, si esta instalado: fuera todo lo que arranca solo con Windows,
:: incluido su actualizador automatico (tarea y servicio). Los PDF quedan para
:: Edge o Chrome. Reader sigue andando si alguien lo abre.
set "ADOBE=N"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$n=0; $ks='%UPS%\Software\Microsoft\Windows\CurrentVersion\Run','%UPS%\Software\Microsoft\Windows\CurrentVersion\RunOnce','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'; foreach ($k in $ks) { $i=Get-Item -LiteralPath $k -ErrorAction SilentlyContinue; if ($i) { foreach ($v in $i.Property) { $d=[string]$i.GetValue($v); if (($v + ' ' + $d) -match 'AdobeARM|Adobe ARM|reader_sl|Speed Launcher|acrotray|Acrobat Assistant|AdobeCollabSync|\\Adobe\\(Acrobat|Reader)') { Remove-ItemProperty -LiteralPath $k -Name $v -ErrorAction SilentlyContinue; Write-Output ('  [OK] Adobe: fuera del inicio: ' + $v); $n++ } } } }; Get-ScheduledTask -TaskName 'Adobe Acrobat Update Task*' -ErrorAction SilentlyContinue | Where-Object { [string]$_.State -ne 'Disabled' } | ForEach-Object { $_ | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null; Write-Output ('  [OK] Adobe: tarea desactivada: ' + $_.TaskName); $n++ }; if (Get-Service -Name AdobeARMservice -ErrorAction SilentlyContinue) { Stop-Service -Name AdobeARMservice -Force -ErrorAction SilentlyContinue; Set-Service -Name AdobeARMservice -StartupType Disabled -ErrorAction SilentlyContinue; Write-Output '  [OK] Adobe: servicio de actualizacion automatica deshabilitado.'; $n++ }; $u='Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; $r=Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'Acrobat|Adobe Reader' } | Select-Object -First 1; if ($r) { Write-Output ('  [OK] Adobe Reader instalado: ' + $r.DisplayName + '. Sigue andando si alguien lo abre.'); exit 2 }; if ($n) { exit 1 }; exit 0"
if errorlevel 2 set "ADOBE=S"
if errorlevel 1 goto :adobe_listo
echo   [OK] Adobe Reader no esta instalado: nada que limpiar.
:adobe_listo

:: =========================================================================
call :titulo "12/12  Limpieza de temporales"
:: =========================================================================
:: Vaciado de todas las carpetas temporales de Windows. El codigo esta en la
:: seccion LIMPIEZA al final de este archivo. Lo que esta en uso se saltea, y la
:: carpeta desde la que corre el script tambien, por si se abrio desde un ZIP.
echo   Vaciando temporales. Lo que Windows tiene en uso se saltea solo.
set "OPT_SELF=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText('%~f0'); $i=$t.IndexOf('#LIMPIEZA-' + 'INICIO#'); $j=$t.IndexOf('#LIMPIEZA-' + 'FIN#'); if ($i -ge 0 -and $j -gt $i) { Invoke-Expression $t.Substring($i, $j - $i) }"
echo   [OK] Limpieza terminada.

:: =========================================================================
call :titulo "Ultimos pasos"
:: =========================================================================
echo   Actualizando las firmas de Defender...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Update-MpSignature -ErrorAction SilentlyContinue; $s=Get-MpComputerStatus -ErrorAction SilentlyContinue; if ($s) { $rt='INACTIVO, hay otro antivirus?'; if ($s.RealTimeProtectionEnabled) { $rt='ACTIVO' }; $tp='inactiva'; if ($s.IsTamperProtected) { $tp='ACTIVA' }; Write-Output ('  Defender en tiempo real: ' + $rt); Write-Output ('  Proteccion contra alteraciones: ' + $tp); Write-Output ('  Firmas de virus del: ' + $s.AntivirusSignatureLastUpdated) } else { Write-Output '  No se pudo leer el estado de Defender. Hay otro antivirus instalado?' }"
echo.
echo   Programas que arrancan con Windows. Desactiva los que no uses en
echo   Administrador de tareas, pestana Inicio, desde la sesion del usuario:
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ks='%UPS%\Software\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; foreach ($k in $ks) { $i=Get-Item -LiteralPath $k -ErrorAction SilentlyContinue; if ($i) { $i.Property | ForEach-Object { $m=''; if ($_ -match 'Theft|Deterrent|TDAgent') { $m='   <-- antirrobo de Conectar Igualdad: NO lo desactives' }; Write-Output ('    - ' + $_ + $m) } } }"
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC para aplicar todo.
echo.
echo   Para buscar archivos: Windows Search queda apagado porque castiga el disco.
echo   Everything, de voidtools.com, encuentra cualquier archivo al instante.
echo.
echo   Energia: cerrar la tapa o apretar el boton de encendido ahora APAGA la PC,
echo   sin suspender. Guarda lo que estes haciendo antes.
echo.
echo   Seguridad: Windows 10 recibe parches gratis hasta el 12/10/2027 si la PC
echo   esta inscripta en ESU. Revisalo en Configuracion, Windows Update.
if "%CLASICOS%"=="N" goto :final_sin_clasicos
echo.
echo   Fotos: despues de reiniciar, en Configuracion, Aplicaciones, Aplicaciones
echo   predeterminadas, Visor de fotos, elegi "Visualizador de fotos de Windows".
echo   O abri una foto y, cuando pregunte con que, elegilo y marca "Usar siempre".
:final_sin_clasicos
if not "%ADOBE%"=="S" goto :final_sin_adobe
echo.
echo   PDF: para abrirlos con Edge o Chrome en vez de Adobe Reader, en Configuracion,
echo   Aplicaciones, Aplicaciones predeterminadas, Elegir aplicaciones predeterminadas
echo   por tipo de archivo, busca .pdf y elegi el navegador. Como Reader ya no se
echo   actualiza solo, si no lo usas para nada conviene desinstalarlo.
:final_sin_adobe
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
:: Tiempos en segundos: 0 es nunca.
:energia_plan
powercfg /setacvalueindex %1 SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_DISK DISKIDLE 0 >nul 2>&1
powercfg /setacvalueindex %1 SUB_SLEEP STANDBYIDLE 14400 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_SLEEP STANDBYIDLE 14400 >nul 2>&1
powercfg /setacvalueindex %1 SUB_SLEEP HIBERNATEIDLE 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_SLEEP HIBERNATEIDLE 0 >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS PBUTTONACTION 3 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS PBUTTONACTION 3 >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS LIDACTION 3 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS LIDACTION 3 >nul 2>&1
powercfg /setacvalueindex %1 SUB_BUTTONS SBUTTONACTION 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BUTTONS SBUTTONACTION 0 >nul 2>&1
powercfg /setdcvalueindex %1 SUB_BATTERY BATACTIONCRIT 3 >nul 2>&1
goto :eof

:: Igual que :asegurar, pero recibe "servicio:tipo".
:asegurar_par
for /f "tokens=1,2 delims=:" %%a in ("%~1") do call :asegurar %%a %%b
goto :eof
:: =========================================================================
::  LIMPIEZA DE TEMPORALES (PowerShell). La ejecuta el paso 12. cmd nunca
::  llega hasta aca: todo termina antes con "exit /b" o "goto :eof".
:: =========================================================================
#LIMPIEZA-INICIO#
$ErrorActionPreference = 'SilentlyContinue'
$self = $env:OPT_SELF
$totalBytes = 0
$totalSalteados = 0

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
function Vaciar([string]$Nombre, [string]$Carpeta, [string]$Patron = '*', [string]$Excepto = '') {
    if (-not $Carpeta -or -not [IO.Directory]::Exists($Carpeta)) { return }
    if ($prohibidas -contains $Carpeta.TrimEnd('\')) { return }
    $borrados = 0; $salteados = 0; $bytes = 0
    $pendientes = New-Object System.Collections.Stack
    $subcarpetas = New-Object System.Collections.Generic.List[string]
    $pendientes.Push($Carpeta)
    while ($pendientes.Count -gt 0) {
        $dir = $pendientes.Pop()
        $filtro = '*'
        if ($dir -eq $Carpeta) { $filtro = $Patron }
        try { $entradas = [IO.Directory]::GetFileSystemEntries($dir, $filtro) } catch { $salteados++; continue }
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
            } catch { $salteados++ }
        }
    }
    # Las subcarpetas que quedaron vacias, de la mas profunda a la mas cercana.
    foreach ($d in ($subcarpetas | Sort-Object Length -Descending)) { try { [IO.Directory]::Delete($d, $false) } catch { } }
    $script:totalBytes += $bytes
    $script:totalSalteados += $salteados
    $linea = '    ' + $Nombre.PadRight(44) + ([string][Math]::Round($bytes / 1MB, 1)).PadLeft(8) + ' MB'
    if ($salteados) { $linea += '   (' + $salteados + ' en uso, salteados)' }
    Write-Output $linea
}

Vaciar 'temp (Temp de Windows)' (Join-Path $env:SystemRoot 'Temp')
foreach ($p in $perfiles) {
    $quien = Split-Path $p.LocalPath -Leaf
    Vaciar ('%temp% de ' + $quien) (Join-Path $p.LocalPath 'AppData\Local\Temp')
    Vaciar ('Informes de errores de ' + $quien) (Join-Path $p.LocalPath 'AppData\Local\Microsoft\Windows\WER')
    Vaciar ('Cache de Adobe Reader de ' + $quien) (Join-Path $p.LocalPath 'AppData\LocalLow\Adobe\AcroCef\DC\Acrobat\Cache')
}
Vaciar 'Temp de la cuenta del sistema' (Join-Path $env:SystemRoot 'System32\config\systemprofile\AppData\Local\Temp')
Vaciar 'Temp de la cuenta del sistema, 32 bits' (Join-Path $env:SystemRoot 'SysWOW64\config\systemprofile\AppData\Local\Temp')
Vaciar 'Temp de LocalService' (Join-Path $env:SystemRoot 'ServiceProfiles\LocalService\AppData\Local\Temp')
Vaciar 'Temp de NetworkService' (Join-Path $env:SystemRoot 'ServiceProfiles\NetworkService\AppData\Local\Temp')
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
# Prefetch: solo las entradas de programas (*.pf), donde se acumula lo de programas
# que ya no se usan. Quedan el rastro de arranque de Windows (NTOSBOOT), el mapa
# del desfragmentador (Layout.ini), ReadyBoot y las bases de SysMain (Ag*.db):
# asi el arranque no se resiente. Cada programa rehace su entrada al abrirlo.
Vaciar 'Prefetch: entradas de programas' (Join-Path $env:SystemRoot 'Prefetch') '*.pf' 'NTOSBOOT-*'
if (Get-Command Delete-DeliveryOptimizationCache -ErrorAction SilentlyContinue) {
    Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue | Out-Null
    Write-Output ('    ' + 'Cache de Delivery Optimization'.PadRight(44) + '   vaciada')
}
Write-Output ('  TOTAL liberado: ' + [Math]::Round($totalBytes / 1MB, 1) + ' MB. Salteados por estar en uso: ' + $totalSalteados + '.')
#LIMPIEZA-FIN#
