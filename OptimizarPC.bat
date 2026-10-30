@echo off
setlocal EnableExtensions DisableDelayedExpansion
:: La ruta de este archivo, para PowerShell. Por variable de entorno, y no pegada
:: en el comando, para que una carpeta con apostrofo o & en el nombre no rompa nada.
set "OPT_RUTA=%~f0"
:: "/actualizar N": la opcion 2 se vuelve a abrir sola despues de cada reinicio, en
:: la ronda N. Se guarda antes de elevar: al elevar, los argumentos hay que pasarlos.
set "OPT_ARG=%~1"
set "OPT_RONDA=%~2"
title Optimizar PC Vieja v2
:: =========================================================================
::  OPTIMIZAR PC VIEJA v2
::  Para Windows 10 con disco mecanico (HDD) y 2 GB de RAM.
::
::  Un solo archivo, con menu:
::    A. PC apestada: cierra todos los programas y sigue con la opcion 1.
::    1. Optimizar la PC.
::    2. Actualizar Windows a fondo y limpiar restos (DISM /ResetBase, irreversible).
::    3. Desfragmentar a fondo.
::    4. Instalar Chrome, WinRAR, VLC y Everything (con winget).
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
"%SystemRoot%\Sysnative\cmd.exe" /c ""%~f0" %*"
exit /b
:arquitectura_ok

:: -------------------------------------------------------------------------
:: Permisos de administrador (si faltan, se piden con el cartel de UAC)
:: -------------------------------------------------------------------------
fltmc >nul 2>&1
if not errorlevel 1 goto :es_admin
echo Pidiendo permisos de administrador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { if ($env:OPT_ARG) { Start-Process -FilePath $env:OPT_RUTA -ArgumentList ($env:OPT_ARG + ' ' + $env:OPT_RONDA) -Verb RunAs -ErrorAction Stop } else { Start-Process -FilePath $env:OPT_RUTA -Verb RunAs -ErrorAction Stop }; exit 0 } catch { exit 1 }"
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
:: Tareas de telemetria y de avisos: el paso 4 las desactiva y la opcion 6 las reactiva.
:: Una sola lista, asi deshacer no se queda atras cuando se agrega una. Las ultimas:
:: censo del equipo (devicecensus), PushToInstall (instalar apps desde la web de la
:: Store), modelos de voz, el escaneo
:: de apps de inicio, MareBackup (inventario con compattelrunner), SQM y la telemetria
:: de Office 2016. Las que no existen en esa version de Windows se saltean solas.
:: RUXIM\PLUGScheduler (los avisos de "pasate a Windows 11") no esta: es de
:: TrustedInstaller y schtasks responde "Acceso denegado" aun como administrador.
set "_tareas="\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" "\Microsoft\Windows\Application Experience\ProgramDataUpdater" "\Microsoft\Windows\Autochk\Proxy" "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" "\Microsoft\Windows\Feedback\Siuf\DmClient" "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" "\Microsoft\Windows\Maps\MapsUpdateTask" "\Microsoft\Windows\Maps\MapsToastTask" "\Microsoft\Windows\Windows Error Reporting\QueueReporting" "\Microsoft\Windows\Maintenance\WinSAT" "\Microsoft\XblGameSave\XblGameSaveTask" "\Microsoft\Windows\Device Information\Device" "\Microsoft\Windows\Device Information\Device User" "\Microsoft\Windows\PushToInstall\LoginCheck" "\Microsoft\Windows\PushToInstall\Registration" "\Microsoft\Windows\Speech\SpeechModelDownloadTask" "\Microsoft\Windows\Application Experience\StartupAppTask" "\Microsoft\Windows\Application Experience\MareBackup" "\Microsoft\Windows\PI\Sqm-Tasks" "\Microsoft\Windows\Diagnosis\RecommendedTroubleshootingScanner" "\Microsoft\Windows\NetTrace\GatherNetworkInfo" "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" "\Microsoft\Windows\Customer Experience Improvement Program\BthSQM" "\Microsoft\Office\OfficeTelemetryAgentLogOn2016" "\Microsoft\Office\OfficeTelemetryAgentFallBack2016""
:: Vuelta de un reinicio de la opcion 2: sigue con la ronda que toca, sin menu.
if /i "%OPT_ARG%"=="/actualizar" goto :op_limpiar_wu
:menu
title Optimizar PC Vieja v2
echo.
echo ==========================================================================
echo   OPTIMIZAR PC VIEJA v2 - Windows 10, disco mecanico, 2 GB de RAM
echo ==========================================================================
if "%REINICIO_PENDIENTE%"=="1" echo   Falta REINICIAR para que se apliquen los cambios.
echo.
echo     A. PC apestada: cerrar todo y optimizar
echo     1. Optimizar la PC
echo     2. Actualizar Windows a fondo y limpiar restos (horas; la limpieza es irreversible)
echo     3. Desfragmentar a fondo (de vez en cuando, puede tardar horas)
echo     4. Instalar Chrome, WinRAR, VLC y Everything
echo     5. Chrome de aula: cerrar sesiones y borrar perfiles
echo     6. Revertir la optimizacion (deshace la opcion 1)
echo     7. Verificar el estado (solo mira, no cambia nada)
echo     0. Salir
echo.
:: choice responde a una sola tecla, sin Enter, e ignora cualquier otra.
choice /c A12345670 /n /m "  Toca un numero o la A: "
if errorlevel 9 goto :salir
if errorlevel 8 goto :op_verificar
if errorlevel 7 goto :op_revertir
if errorlevel 6 goto :op_chrome_aula
if errorlevel 5 goto :op_instalar
if errorlevel 4 goto :op_desfragmentar
if errorlevel 3 goto :op_limpiar_wu
if errorlevel 2 goto :op_optimizar
if errorlevel 1 goto :op_apestada
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
::  A. PC APESTADA
::  Para una PC tan trabada que el script mismo tardaria horas: cierra todos los
::  programas de la sesion (seccion CERRAR) y sigue con la opcion 1 sin volver a
::  preguntar. Lo hace solo si se toca la A: quien la toca sabe lo que hace.
:: =========================================================================
:op_apestada
title Optimizar PC Vieja v2 - PC apestada
echo ==========================================================================
echo   PC APESTADA: CERRAR TODO Y OPTIMIZAR
echo ==========================================================================
echo.
echo   Cierra TODOS los programas abiertos, tambien los que corren escondidos:
echo   impresoras, actualizadores, mensajeros. Frena Windows Update mientras corre
echo   el script (si esta instalando una actualizacion, espera a que termine) y
echo   despues sigue sola con la opcion 1. Windows y el acceso remoto no se tocan.
echo.
echo   LO QUE NO ESTE GUARDADO SE PIERDE.
echo.
choice /c SN /n /m "  CERRAR TODO Y OPTIMIZAR? [S/N]: "
if errorlevel 2 goto :menu
:: Antes de cerrar nada: :detectar reconoce al usuario de la sesion por su Explorer.
call :detectar
echo.
call :ps CERRAR
echo.
echo   A terminado.
set "SIN_CONFIRMAR=1"
goto :op_optimizar

:: =========================================================================
::  1. OPTIMIZAR
:: =========================================================================
:op_optimizar
title Optimizar PC Vieja v2 - Optimizar
:: Usuario de la sesion, version de Windows y hardware (seccion EQUIPO).
call :detectar
:: Perfiles segun el hardware (los fija :detectar, y la opcion 7 los muestra):
::  - RAM instalada de 4 GB o mas (se suman los modulos: Windows de 32 bits ve
::    unos 3,2 GB y el video se queda con un pedazo): suspension a la hora,
::    tapa que suspende, Suspender en el menu y Bluetooth en Manual;
::  - eso y placa de video con driver: efectos visuales en "mejor apariencia";
::  - disco del sistema SSD y 4 GB o mas: indexador de busqueda de fabrica.

:: -------------------------------------------------------------------------
:: Presentacion
:: -------------------------------------------------------------------------
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
if "%BUSQUEDA%"=="1" echo   SSD y 4 GB o mas: indexador de busqueda como de fabrica.
if "%OUTLOOK%"=="S" echo   Outlook nuevo: se uso en el ultimo ano, queda instalado.
if "%ONEDRIVE%"=="S" (echo   OneDrive: en uso, queda como esta.) else (echo   OneDrive: sin cuenta o casi vacio, deja de arrancar con Windows.)
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
:: La A ya pregunto una vez: no se pregunta de nuevo.
if "%SIN_CONFIRMAR%"=="1" goto :confirmado
choice /c SN /n /m "  Continuar? [S/N]: "
if errorlevel 2 goto :menu
:confirmado
set "SIN_CONFIRMAR="

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
:: Precarga del arranque y de los programas: en disco mecanico junta muchas
:: lecturas sueltas en una sola en bloque. 3 es el valor de fabrica; otros
:: optimizadores la apagan con 0 y cada programa tarda mas en abrir.
:: Se escriben sin leerlos antes: el resultado es el mismo y es un reg menos.
call :dword "%_mm%" DisablePagingExecutive 0
call :dword "%_mm%\PrefetchParameters" EnablePrefetcher 3
call :dword "%_mm%\PrefetchParameters" EnableSuperfetch 3
:: Vaciar la paginacion al apagar lo activan algunos scripts de "privacidad": con
:: 4 GB de paginacion, cada apagado escribe 4 GB en el disco.
call :dword "%_mm%" ClearPageFileAtShutdown 0
if "%_reparado%"=="0" echo   [OK] Nada perjudicial del v1: SysMain, teclado tactil, biometria y ubicacion.
echo   [OK] DisablePagingExecutive y la precarga en sus valores de fabrica; la
echo        paginacion no se vacia al apagar.
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
:: Indexador de busqueda: en un disco mecanico lee y relee el disco, y su proceso
:: se queda con 50 a 100 MB. Queda como de fabrica solo con SSD y 4 GB o mas.
set "_ws=disabled"
if "%BUSQUEDA%"=="1" set "_ws=delayed-auto"
call :servicio WSearch %_ws%
if "%BUSQUEDA%"=="1" (echo   [OK] Indexador de busqueda: como de fabrica, hay SSD y 4 GB o mas.) else (echo   [OK] Indexador de busqueda: deshabilitado; castiga al disco mecanico o gasta RAM que no sobra.)
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
for %%t in (%_tareas%) do schtasks /change /tn %%t /disable >nul 2>&1
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
:: Copilot y la IA de Windows, apagados por politica en Windows 10 y 11. Recall y
:: Click to Do solo existen en algunas PCs con Windows 11; en el resto no hacen nada.
:: La app y el programa de Copilot se quitan en el paso 10, siempre.
call :dword "%_pol%\WindowsCopilot" TurnOffWindowsCopilot 1
call :dword "%UHIVE%\Software\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot 1
:: El programa de Copilot lo maneja el actualizador de Edge, y esta es su politica para
:: no instalar una app. Sin comprobar: no se encontro como pedirle que lo reinstale.
call :dword "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" Install{C50565E9-CCCF-44B4-BA15-5AC5C6569197} 0
call :dword "%_pol%\WindowsAI" DisableAIDataAnalysis 1
call :dword "%_pol%\WindowsAI" AllowRecallEnablement 0
call :dword "%_pol%\WindowsAI" DisableClickToDo 1
:: Widgets de Windows 11, el equivalente de Noticias e intereses (EnableFeeds).
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests 0
:: Recoleccion de compatibilidad (CompatTelRunner, el que deja el disco al tope): el paso 4
:: desactiva su tarea, pero Windows Update la vuelve a activar. Con estas politicas,
:: aunque corra, no tiene nada que recolectar.
call :dword "%_pol%\AppCompat" DisableInventory 1
call :dword "%_pol%\AppCompat" AITEnable 0
:: Experiencias compartidas y Vincular al telefono (en Windows 11, CrossDeviceService):
:: buscan celulares por Bluetooth y por la red todo el tiempo.
call :dword "%_pol%\System" EnableCdp 0
call :dword "%_pol%\System" EnableMmx 0
echo   [OK] Telemetria al minimo, sin Noticias e intereses, sin Cortana ni destacados,
echo        sin barra de juegos, sin P2P de actualizaciones ni informe de errores.
echo   [OK] Copilot y la IA de Windows apagados por politica (Recall y Click to Do incluidos).
echo   [OK] Sin recoleccion de compatibilidad ni busqueda de celulares (Vincular al telefono).

:: Ajustes del usuario de la sesion
set "_cdm=%UHIVE%\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%v in (ContentDeliveryAllowed OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SoftLandingEnabled SystemPaneSuggestionsEnabled SubscribedContentEnabled) do call :dword "%_cdm%" %%v 0
for %%v in (SubscribedContent-310093Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled) do call :dword "%_cdm%" %%v 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" ScoobeSystemSettingEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" Enabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Privacy" TailoredExperiencesWithDiagnosticDataEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Siuf\Rules" NumberOfSIUFInPeriod 0
:: Los avisos de "haz una copia de seguridad en tu cuenta de Microsoft" y parecidos:
:: en Configuracion, en el menu Inicio (24H2) y como notificacion. Y la pagina de
:: inicio de Configuracion (desde 23H2), donde viven esas tarjetas: se abre en Sistema.
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" EnableAccountNotifications 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" Start_AccountNotifications 0
call :dword "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\AccountNotifications" DisableAccountNotifications 1
for %%v in (BackupReminder Suggested WindowsTip) do call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.%%v" Enabled 0
if %BUILD% GEQ 22631 call :sz "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" SettingsPageVisibility hide:home
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" CortanaConsent 0
call :dword "%UHIVE%\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions 1
call :dword "%UHIVE%\System\GameConfigStore" GameDVR_Enabled 0
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\GameDVR" AppCaptureEnabled 0
echo   [OK] Sin apps sugeridas, instalaciones silenciosas, consejos ni resultados web.

:: Apps en segundo plano: con menos de 4 GB, todas apagadas con el interruptor
:: general. Contras: los avisos de las apps cerradas (WhatsApp de la Store) no
:: llegan, y el Inicio puede tardar en encontrar las apps recien instaladas. Con
:: 4 GB o mas, como de fabrica: ahi pesan mas los avisos que esos MB.
set "_bg=1"
set "_bgt=0"
if "%PERFIL_4GB%"=="1" set "_bg=0"
if "%PERFIL_4GB%"=="1" set "_bgt=1"
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" GlobalUserDisabled %_bg%
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" BackgroundAppGlobalToggle %_bgt%
if "%_bg%"=="1" (echo   [OK] Apps en segundo plano: todas apagadas con el interruptor general.) else (echo   [OK] Apps en segundo plano: como de fabrica, hay 4 GB o mas.)
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
:: Barra de tareas: sin caja ni lupa de busqueda (abriendo el Inicio y escribiendo
:: se busca igual), sin los botones de Cortana, Copilot y Vista de tareas, y con el
:: nombre de cada ventana: los botones se agrupan recien cuando la barra se llena.
:: Los Widgets de Windows 11 ya los apaga la politica del paso 6.
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" SearchboxTaskbarMode 0
call :dword "%_adv%" ShowCortanaButton 0
call :dword "%_adv%" ShowCopilotButton 0
call :dword "%_adv%" ShowTaskViewButton 0
call :dword "%_adv%" TaskbarGlomLevel 1
:: Windows 11: sin el boton de "Reanudar" (seguir en la PC lo que se usaba en el
:: celular). El nombre del valor es generico, pero es este: lo documenta Shawn Brink
:: en elevenforum.
call :dword "%_adv%" IsEnabled 0
echo   [OK] Barra de tareas: sin busqueda, Cortana, Copilot, Vista de tareas ni Reanudar;
echo        muestra el nombre de cada ventana hasta que se llena.
:: Windows 11 con 2 GB: el menu del boton derecho nuevo lo dibuja XAML y tarda en
:: aparecer; vuelve el clasico, completo. Con mas RAM queda el nuevo.
if %BUILD% LSS 22000 goto :menu_clasico_listo
if %RAM_INST% GTR 2048 goto :menu_clasico_listo
reg add "%UCLS%\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo   [OK] Windows 11 con 2 GB: menu del boton derecho clasico, sin "Mostrar mas opciones".
:menu_clasico_listo
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

:: VBS e integridad de memoria (HVCI): Windows corre adentro de un hipervisor y
:: cada acceso a memoria paga ese peaje. Sin MBEC en el procesador (Intel anterior
:: a Kaby Lake, AMD anterior a Zen 2) se emula y cuesta mucho mas. Microsoft solo
:: lo enciende de fabrica con MBEC, 8 GB y SSD: la misma regla, al reves. Si la PC
:: no la cumple, se apaga; si la cumple, queda, porque es seguridad real.
if not "%VBS%"=="1" goto :vbs_listo
set "_vbs=0"
if not "%MBEC%"=="1" set "_vbs=1"
if %RAM_INST% LSS 8192 set "_vbs=1"
if not "%SSD%"=="1" set "_vbs=1"
if "%_vbs%"=="0" echo   [OK] VBS e integridad de memoria: quedan, la PC tiene MBEC, 8 GB y SSD.
if "%_vbs%"=="0" goto :vbs_listo
if "%VBS_LOCK%"=="1" echo   [AVISO] VBS corriendo y bloqueada desde UEFI: no se puede apagar desde aca.
if "%VBS_LOCK%"=="1" goto :vbs_listo
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" Enabled 0
call :dword "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" EnableVirtualizationBasedSecurity 0
echo   [OK] VBS e integridad de memoria apagadas, rige al reiniciar: sin MBEC, con menos
echo        de 8 GB o con disco mecanico, Microsoft tampoco las enciende de fabrica.
:vbs_listo

:: Archivo de paginacion, cache de escritura del disco, CompactOS, Restaurar
:: sistema, BitLocker y almacenamiento reservado, en la seccion DISCO.
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
for %%v in (StartupBoostEnabled BackgroundModeEnabled HubsSidebarEnabled WebWidgetAllowed ShowRecommendationsEnabled EdgeShoppingAssistantEnabled ShowMicrosoftRewards PersonalizationReportingEnabled DiagnosticData UserFeedbackAllowed DefaultBrowserSettingEnabled) do call :dword "%_edge%" %%v 0
call :dword "%_edge%" HideFirstRunExperience 1
call :dword "%_edge%\Recommended" SleepingTabsEnabled 1
:: Pestanas en suspension: a los 5 minutos con menos de 4 GB; con 4 GB o mas, a la
:: media hora, que despertarlas en un procesador lento tambien cuesta.
set "_tabs=300"
if "%PERFIL_4GB%"=="1" set "_tabs=1800"
call :dword "%_edge%\Recommended" SleepingTabsTimeout %_tabs%
call :dword "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" CreateDesktopShortcutDefault 0
call :dword "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled 0
:: Sin pestanas de bienvenida tras cada actualizacion, sin el aviso de Privacy Sandbox y
:: sin pedir ser el navegador predeterminado: eso se elige en Configuracion, Aplicaciones
:: predeterminadas. Edge, lo mismo (DefaultBrowserSettingEnabled, en su lista).
for %%v in (PromotionalTabsEnabled PrivacySandboxPromptEnabled DefaultBrowserSettingEnabled) do call :dword "HKLM\SOFTWARE\Policies\Google\Chrome" %%v 0
:: Con StartupBoostEnabled en 0, Edge se saca solo del inicio, pero recien la proxima
:: vez que arranca: el script terminaba mostrandolo todavia en el inicio.
for /f %%v in ('reg query "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /i /c:"MicrosoftEdgeAutoLaunch_"') do reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" /v %%v /f >nul 2>&1
echo   [OK] Edge: sin precarga, sin quedar de fondo, sin barra lateral; pestanas en
echo        suspension a los 5 minutos (media hora con 4 GB o mas). Chrome: sin quedar de fondo.
echo        Van a decir "Administrado por tu organizacion": es normal.
:: uBlock Origin Lite en Chrome y en Edge, forzada por politica: en un Atom, lo que
:: traba una pagina es el JavaScript de los avisos. Si el navegador no esta, la
:: politica queda esperando a que se instale.
call :politica_ublock

:: =========================================================================
call :titulo "10/11  Inicio de Windows, apps, clasicos de Windows 7 y Adobe Reader"
:: =========================================================================
if "%ONEDRIVE%"=="S" goto :onedrive_listo
reg delete "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
:: Aunque no se use, sus tareas lo actualizan y mandan reportes todos los dias.
for %%t in ("OneDrive Reporting Task" "OneDrive Standalone Update Task") do schtasks /change /tn "%%~t-%USID%" /disable >nul 2>&1
echo   [OK] OneDrive ya no arranca con Windows ni se actualiza solo. No se desinstalo.
:onedrive_listo
:: Lo que arranca solo sin que nadie lo pida: actualizadores, bandejas de drivers,
:: "optimizadores", torrents, lanzadores de juegos, mensajeros, nubes vacias y
:: servicios de fabricante (seccion ARRANQUE). Se desactivan como en el
:: Administrador de tareas: siguen instalados y abren a mano.
set "ARRANQUE_MODO="
call :ps ARRANQUE
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
:: Apps preinstaladas, app Fotos, caracteristicas opcionales y
:: Adobe Reader, en la seccion QUITAR. Sale con 2 si Adobe Reader esta instalado.
set "ADOBE=N"
call :ps QUITAR
if errorlevel 2 set "ADOBE=S"
:: Sin Correo, Calendario ni Contactos, sus servicios de sincronizacion no tienen
:: nada que hacer. Son servicios por usuario: se deshabilita la plantilla y rige
:: desde el proximo inicio de sesion.
for %%s in (OneSyncSvc PimIndexMaintenanceSvc UnistoreSvc UserDataSvc MessagingService) do call :servicio %%s disabled
echo   [OK] Deshabilitados sus servicios de sincronizacion: OneSyncSvc,
echo        PimIndexMaintenanceSvc, UnistoreSvc, UserDataSvc y MessagingService.

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
if "%BUSQUEDA%"=="1" goto :fin_busqueda_listo
echo   Para buscar archivos: Windows Search queda apagado (castiga el disco mecanico
echo   o gasta RAM que no sobra).
echo   La opcion 4 instala Everything, que encuentra cualquier archivo al instante.
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
echo.
echo   1 terminado.
goto :fin_con_reinicio

:: =========================================================================
::  7. VERIFICAR ESTADO (solo lectura). El reporte esta en PowerShell, en la
::  seccion VERIFICAR al final de este archivo, y se guarda en un .txt al lado.
:: =========================================================================
:op_verificar
title Optimizar PC Vieja v2 - Verificar estado
call :detectar
call :ps VERIFICAR
echo.
echo   7 terminado.
goto :menu

:: =========================================================================
::  2. LIMPIAR RESTOS DE WINDOWS UPDATE
::  Cada actualizacion guarda la version anterior de lo que reemplaza, en
::  C:\Windows\WinSxS. Windows las borra solo recien a los 30 dias y con una
::  tarea que se corta a la hora. Aca se hace completo con DISM:
::  /StartComponentCleanup /ResetBase. Opcion avanzada: pide confirmacion.
::  No usa /SPSuperseded: limpia restos de Service Packs, y Windows 10 no tiene.
:: =========================================================================
:op_limpiar_wu
title Optimizar PC Vieja v2 - Actualizar Windows a fondo y limpiar restos
if not defined OPT_RONDA set "OPT_RONDA=1"
:: Vuelta de un reinicio: la tarea que reabrio el script ya cumplio.
schtasks /delete /tn "OptimizarPC actualizar" /f >nul 2>&1
set "OPT_ARG="
echo ==========================================================================
echo   ACTUALIZAR WINDOWS A FONDO Y LIMPIAR RESTOS
echo ==========================================================================
echo.
echo   1. Vacia la cache de descargas de Windows Update e instala TODO lo
echo      pendiente (calidad, drivers, version), reinicia las veces que haga
echo      falta y sigue sola al iniciar sesion, hasta que no quede nada.
echo      Horas en un disco mecanico.
echo   2. Actualiza los programas con winget.
echo   3. DISM /ResetBase: las actualizaciones instaladas ya no se podran
echo      desinstalar. Hasta una hora mas. No apagues la PC.
echo.

:: -------------------------------------------------------------------------
:: 1. Windows Update hasta el final. La seccion ACTUALIZAR sale con 0 si no queda
:: nada, 2 si instalo y hay que volver a buscar, 3 si hay que reiniciar, 1 si no
:: pudo buscar (sin internet): se sigue igual con winget y DISM.
:: -------------------------------------------------------------------------
:wu_ronda
call :titulo "1/3  Windows Update, ronda %OPT_RONDA% de 5"
call :ps ACTUALIZAR
set "_wu=%errorlevel%"
if "%_wu%"=="0" goto :wu_al_dia
if "%_wu%"=="1" goto :wu_al_dia
if %OPT_RONDA% GEQ 5 goto :wu_tope
set /a OPT_RONDA+=1
if "%_wu%"=="2" goto :wu_ronda
:: Reinicio: una tarea reabre este script al iniciar sesion, en la ronda que sigue,
:: con los permisos ya dados y sin volver a pasar por el menu. Sin /ru, corre como
:: el usuario que esta elevando; si elevo otra cuenta, sigue cuando entre esa.
schtasks /create /tn "OptimizarPC actualizar" /sc onlogon /it /rl highest /tr "\"%OPT_RUTA%\" /actualizar %OPT_RONDA%" /f >nul 2>&1
if errorlevel 1 goto :wu_sin_tarea
echo.
echo   Hay que reiniciar para seguir. Reinicia en 15 segundos y, al iniciar sesion,
echo   este script se abre solo y continua con la ronda %OPT_RONDA%.
shutdown /r /t 15 /c "OptimizarPC: reiniciando para seguir instalando actualizaciones"
exit /b 0
:wu_sin_tarea
set "OPT_RONDA="
echo.
echo   [AVISO] No se pudo programar la vuelta automatica. Reinicia la PC y volve a
echo           elegir la opcion 2.
echo.
echo   2 terminado.
goto :menu
:wu_tope
echo   [AVISO] Cinco rondas y Windows Update sigue ofreciendo cosas: se sigue con el resto.
:wu_al_dia
set "OPT_RONDA="

:: -------------------------------------------------------------------------
:: 2. Programas, con winget. --include-unknown: los VLC y WinRAR viejos no
:: declaran bien su version y sin eso winget los saltea.
:: -------------------------------------------------------------------------
call :titulo "2/3  Programas, con winget"
call :buscar_winget
if errorlevel 1 goto :wu_sin_winget
echo   Actualizaciones disponibles:
%WINGET% upgrade --include-unknown --source winget --accept-source-agreements
echo.
%WINGET% upgrade --all --include-unknown --source winget --silent --accept-package-agreements --accept-source-agreements
echo   [OK] Programas actualizados con winget.
:wu_sin_winget

:: -------------------------------------------------------------------------
:: 3. Restos de Windows Update.
:: -------------------------------------------------------------------------
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
echo.
echo   2 terminado.
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

call :titulo "3/3  Limpieza de las versiones viejas (WinSxS)"
call :libre LIBRE_ANTES
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
set "DISM_RC=%errorlevel%"
if defined _drb (reg add "%_sxs%" /v DisableResetbase /t REG_DWORD /d %_drb% /f >nul 2>&1) else (reg delete "%_sxs%" /v DisableResetbase /f >nul 2>&1)
if defined _sa (reg add "%_sxs%" /v SupersededActions /t REG_DWORD /d %_sa% /f >nul 2>&1) else (reg delete "%_sxs%" /v SupersededActions /f >nul 2>&1)
if not "%DISM_RC%"=="0" goto :wu_error
call :libre LIBRE_DESPUES

set /a LIBERADO=LIBRE_DESPUES-LIBRE_ANTES
if %LIBERADO% LSS 0 set "LIBERADO=0"
echo.
echo   Espacio liberado: %LIBERADO% MB.
echo   La limpieza automatica de Windows sigue activa y se encarga del resto.
echo   Si vas a desfragmentar (opcion 3), ahora es el momento: hay menos que mover.
echo.
echo   2 terminado.
goto :menu

:wu_error
call :a_hex %DISM_RC%
echo.
echo   [!] DISM termino con el error %_hex%.
if /i "%_hex%"=="0x800F0806" echo       Hay una actualizacion esperando un reinicio.
echo       Lo mas comun: una actualizacion a medio instalar. Reinicia la PC, deja
echo       que Windows Update termine y volve a elegir esta opcion.
echo       El detalle queda en C:\Windows\Logs\DISM\dism.log.
echo.
echo   2 terminado.
goto :menu

:: =========================================================================
::  3. DESFRAGMENTAR A FONDO (para discos mecanicos)
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
echo   - Se puede cortar en cualquier momento con Ctrl+C o cerrando la ventana.
echo   - Conviene hacer antes las opciones 1 y 2: borran temporales y restos de
echo     actualizaciones, y hay menos que mover.

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
echo.
echo   3 terminado.
goto :menu

:desfrag_ssd
echo.
echo   Es un SSD: desfragmentarlo no lo acelera y le gasta escrituras.
echo   Lo que necesita es TRIM, que avisa al disco que bloques estan libres.
defrag %DISCO% /L /U /V
echo.
echo   3 terminado.
goto :menu

:: =========================================================================
::  6. REVERTIR LA OPTIMIZACION
::  Vuelve a los valores de fabrica de Windows 10 lo que la opcion 1 cambia y
::  que podria molestar. A proposito NO revierte la seguridad reparada, las
::  correcciones del v1, la telemetria apagada ni las apps quitadas (se
::  reinstalan desde la Store).
:: =========================================================================
:op_revertir
title Optimizar PC Vieja v2 - Revertir
call :detectar
echo ==========================================================================
echo   REVERTIR LA OPTIMIZACION
echo ==========================================================================
echo.
echo   Usuario: "%UNAME%"
echo.
echo   Vuelve a fabrica: servicios, apps en segundo plano, efectos visuales,
echo   Explorador, energia, navegadores, recortes de Defender, tareas, cache de
echo   escritura del disco y el actualizador de Adobe Reader.
echo   NO apaga la seguridad, no enciende la telemetria ni vuelve a cifrar con BitLocker.
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
for %%t in (%_tareas%) do schtasks /change /tn %%t /enable >nul 2>&1
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
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Dsh" AllowNewsAndInterests
call :borrar "%_pol%\WindowsCopilot" TurnOffWindowsCopilot
call :borrar "%UHIVE%\Software\Policies\Microsoft\Windows\WindowsCopilot" TurnOffWindowsCopilot
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" Install{C50565E9-CCCF-44B4-BA15-5AC5C6569197}
for %%v in (DisableAIDataAnalysis AllowRecallEnablement DisableClickToDo) do call :borrar "%_pol%\WindowsAI" %%v
call :borrar "%_pol%\Windows Search" AllowCortana
call :borrar "%_pol%\Windows Search" EnableDynamicContentInWSB
call :borrar "%_pol%\GameDVR" AllowGameDVR
call :borrar "%_pol%\Windows Error Reporting" Disabled
call :borrar "%_pol%\DeliveryOptimization" DODownloadMode
call :borrar "%_pol%\Device Metadata" PreventDeviceMetadataFromNetwork
call :borrar "%UHIVE%\Software\Policies\Microsoft\Windows\Explorer" DisableSearchBoxSuggestions
for %%v in (DisableInventory AITEnable) do call :borrar "%_pol%\AppCompat" %%v
for %%v in (EnableCdp EnableMmx) do call :borrar "%_pol%\System" %%v
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
:: Sin estos valores, Windows vuelve a su barra de fabrica.
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Search" SearchboxTaskbarMode
for %%v in (ShowCortanaButton ShowCopilotButton ShowTaskViewButton TaskbarGlomLevel IsEnabled) do call :borrar "%_adv%" %%v
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications" EnableAccountNotifications
call :borrar "%_adv%" Start_AccountNotifications
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\AccountNotifications" DisableAccountNotifications
for %%v in (BackupReminder Suggested WindowsTip) do call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.%%v" Enabled
call :borrar "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" SettingsPageVisibility
call :dword "%UHIVE%\Software\Microsoft\Windows\DWM" EnableAeroPeek 1
call :dword "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" EnableTransparency 1
call :borrar "%UHIVE%\Software\Microsoft\Windows\CurrentVersion\Explorer" AltTabSettings
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" DisableAcrylicBackgroundOnLogon
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" /f >nul 2>&1
reg delete "%UCLS%\Local Settings\Software\Microsoft\Windows\Shell\Bags" /f >nul 2>&1
reg delete "%UCLS%\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
echo   [OK] Efectos visuales, desenfoque al iniciar sesion, menus, animaciones, Alt+Tab,
echo        Explorador y menu del boton derecho como de fabrica.

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
for %%v in (StartupBoostEnabled BackgroundModeEnabled HubsSidebarEnabled WebWidgetAllowed ShowRecommendationsEnabled EdgeShoppingAssistantEnabled ShowMicrosoftRewards PersonalizationReportingEnabled DiagnosticData UserFeedbackAllowed HideFirstRunExperience DefaultBrowserSettingEnabled) do call :borrar "%_edge%" %%v
call :borrar "%_edge%\Recommended" SleepingTabsEnabled
call :borrar "%_edge%\Recommended" SleepingTabsTimeout
call :borrar "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" CreateDesktopShortcutDefault
call :borrar "HKLM\SOFTWARE\Policies\Google\Chrome" BackgroundModeEnabled
for %%v in (BrowserSignin BrowserAddPersonEnabled PromotionalTabsEnabled PrivacySandboxPromptEnabled DefaultBrowserSettingEnabled) do call :borrar "HKLM\SOFTWARE\Policies\Google\Chrome" %%v
:: uBlock Origin Lite deja de ser obligatoria: queda instalada y cada uno la quita.
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($p in @(@('HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist','ddkjiahejlhfcafbddmgiahcphecmpfh'), @('HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist','cimighlppcgcoapaliogpjjdehbnofhn'))) { $i=Get-Item -LiteralPath $p[0] -ErrorAction SilentlyContinue; if ($i) { foreach ($v in $i.Property) { if ([string]$i.GetValue($v) -like ($p[1] + '*')) { Remove-ItemProperty -LiteralPath $p[0] -Name $v -ErrorAction SilentlyContinue } } } }" >nul 2>&1
echo   [OK] Politicas de Edge y Chrome quitadas, incluidas las de Chrome de aula y la que
echo        obliga a tener uBlock Origin Lite (queda instalada; se quita desde Extensiones).

call :titulo "Adobe Reader"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Service -Name AdobeARMservice -ErrorAction SilentlyContinue)) { Write-Output '  Adobe Reader no esta instalado: nada que revertir.'; exit 0 }; Set-Service -Name AdobeARMservice -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service -Name AdobeARMservice -ErrorAction SilentlyContinue; Get-ScheduledTask -TaskName 'Adobe Acrobat Update Task*' -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null; Write-Output '  [OK] Adobe Reader: actualizacion automatica activada otra vez.'; Write-Output '       Las entradas de inicio viejas no vuelven: Reader no las necesita.'"

call :titulo "Programas de inicio"
:: Vuelven a arrancar los que la opcion 1 saco (seccion ARRANQUE, al reves).
set "ARRANQUE_MODO=volver"
call :ps ARRANQUE
set "ARRANQUE_MODO="

:: OneDrive vuelve al inicio recien cuando se lo abre; sus tareas, ya.
for %%t in ("OneDrive Reporting Task" "OneDrive Standalone Update Task") do schtasks /change /tn "%%~t-%USID%" /enable >nul 2>&1

echo.
echo   Para recuperar lo que no se revierte solo:
echo    - OneDrive: abrilo una vez y vuelve a arrancar con Windows.
echo    - BitLocker: no se vuelve a cifrar. Si hace falta, Panel de control, Cifrado de
echo      unidad BitLocker, y guardar la clave de recuperacion en un lugar seguro.
echo    - VBS e integridad de memoria: Seguridad de Windows, Seguridad del dispositivo,
echo      Aislamiento del nucleo.
echo    - Apps quitadas: se reinstalan gratis desde la Microsoft Store.
echo    - Caracteristicas opcionales: Configuracion, Aplicaciones, Caracteristicas
echo      opcionales, Agregar una caracteristica.
echo    - Conexion a Escritorio remoto: Panel de control, Programas, Activar o
echo      desactivar las caracteristicas de Windows.
echo    - App Fotos: buscala en la Store como "Microsoft Fotos". El Visualizador de
echo      fotos clasico queda disponible: no molesta y no ocupa nada.
echo.
echo ==========================================================================
echo   LISTO. Hay que REINICIAR la PC. Usa "Reiniciar", no "Apagar".
echo ==========================================================================
echo.
echo   6 terminado.
goto :fin_con_reinicio

:: =========================================================================
::  4. INSTALAR CHROME, WINRAR, VLC Y EVERYTHING
::  Con winget, el instalador de programas que trae Windows 10, en silencio y
::  sin preguntas. Del mas chico al mas grande: WinRAR, Everything, VLC y Chrome.
::  winget elige solo la version de 32 o de 64 bits segun Windows. A Chrome
::  se le agrega uBlock Origin Lite con la politica oficial de instalacion
::  forzada (ExtensionInstallForcelist): Chrome la baja sola de la Web Store.
:: =========================================================================
:op_instalar
title Optimizar PC Vieja v2 - Instalar Chrome, WinRAR, VLC y Everything
echo ==========================================================================
echo   INSTALAR WINRAR, EVERYTHING, VLC Y CHROME
echo ==========================================================================
echo.
echo   Se instalan con winget, en silencio y uno por uno. Hace falta internet.
echo   Si alguno ya esta instalado, se saltea.
call :buscar_winget
if errorlevel 1 goto :menu
call :instalar RARLab.WinRAR "WinRAR"
:: Everything reemplaza la busqueda de archivos de Windows, que la opcion 1 apaga.
call :instalar voidtools.Everything "Everything"
call :instalar VideoLAN.VLC "VLC"
:: La politica va antes que Chrome: asi la primera vez que se abre ya la encuentra.
call :politica_ublock
call :instalar Google.Chrome "Google Chrome"
echo.
echo   LISTO. uBlock Origin Lite aparece en Chrome al minuto de abrirlo por primera
echo   vez. Queda fija: desde Chrome no se puede quitar, por eso Chrome muestra
echo   que lo administra tu organizacion.
echo.
echo   4 terminado.
goto :menu

:: =========================================================================
::  5. CHROME DE AULA
::  Para PCs compartidas, como las de un colegio: cierra Chrome en todas las
::  sesiones y borra todos sus perfiles en todos los usuarios de Windows
::  (cuentas, sesiones abiertas, contrasenas, historial y favoritos). Chrome
::  arranca limpio: sin pedir iniciar sesion, sin bienvenidas y con uBlock
::  Origin Lite. La seccion AULA, al final del archivo, hace el borrado.
:: =========================================================================
:op_chrome_aula
title Optimizar PC Vieja v2 - Chrome de aula
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
echo.
echo   5 terminado.
goto :menu

:: =========================================================================
::  SUBRUTINAS
:: =========================================================================

:: uBlock Origin Lite forzada en Chrome y en Edge (ExtensionInstallForcelist): cada
:: navegador la instala solo desde su tienda (Chrome, con la URL de la Web Store; Edge,
:: con su ID en la tienda de Edge y sin URL). Si ya esta en la lista, no la repite.
:politica_ublock
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($p in @(@('HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist','ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx'), @('HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist','cimighlppcgcoapaliogpjjdehbnofhn'))) { $k=$p[0]; $id=$p[1].Split(';')[0]; if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }; $ya=$false; $n=1; foreach ($v in (Get-ItemProperty -LiteralPath $k).PSObject.Properties) { if ($v.Name -match '^[0-9]+$') { if ([string]$v.Value -like ($id + '*')) { $ya=$true }; if ([int]$v.Name -ge $n) { $n=[int]$v.Name + 1 } } }; if (-not $ya) { New-ItemProperty -LiteralPath $k -Name ([string]$n) -Value $p[1] -PropertyType String -Force | Out-Null } }; Write-Output '  [OK] uBlock Origin Lite: Chrome y Edge la instalan solos desde sus tiendas.'"
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
:: al final), con la seccion COMUN pegada adelante: las funciones que usan varias
:: viven una sola vez. El errorlevel queda con el exit de la seccion. Uso: call :ps NOMBRE
:ps
:: El marcador se arma por partes: escrito entero en esta linea, IndexOf lo encontraria
:: aca primero y correria basura.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:OPT_RUTA); $code=''; foreach ($n in 'COMUN', '%~1') { $i=$t.IndexOf('#' + $n + '-INICIO#'); $j=$t.IndexOf('#' + $n + '-FIN#'); if ($i -ge 0 -and $j -gt $i) { $code += $t.Substring($i, $j - $i) } }; Invoke-Expression $code"
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
set "ONEDRIVE=S"
set "OUTLOOK=S"
set "VBS=0"
set "HVCI=0"
set "MBEC=0"
set "VBS_LOCK=0"
:: Cada linea de EQUIPO es VARIABLE=valor. Esta lee la salida, asi que no puede
:: usar :ps; los marcadores van partidos para que IndexOf no la encuentre a ella.
for /f "usebackq delims=" %%l in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:OPT_RUTA); $i=$t.IndexOf('#EQUIPO-' + 'INICIO#'); $j=$t.IndexOf('#EQUIPO-' + 'FIN#'); if ($i -ge 0 -and $j -gt $i) { Invoke-Expression $t.Substring($i, $j - $i) }"`) do set "%%l"
:: Perfiles: ver la opcion 1.
set "PERFIL_4GB=0"
if %RAM_INST% GEQ 3584 set "PERFIL_4GB=1"
set "EFECTOS=0"
if "%PERFIL_4GB%"=="1" if not "%GPU_BASICA%"=="1" set "EFECTOS=1"
set "SSD=0"
if /i "%DISCO_TIPO%"=="SSD" set "SSD=1"
set "BUSQUEDA=0"
if "%SSD%"=="1" if "%PERFIL_4GB%"=="1" set "BUSQUEDA=1"
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
echo   [AVISO] %~2 no se pudo instalar (error %_hex%). Lo mas comun es la conexion: proba de nuevo.
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
::   - COMUN: funciones que usan varias secciones; :ps la pega adelante de cada una.
::   - EQUIPO: usuario de la sesion y hardware (opciones 1 y 6, via :detectar).
::   - DISCO: paginacion, cache de escritura, CompactOS y Restaurar sistema
::     (paso 8 de la opcion 1).
::   - QUITAR: apps, app Fotos, caracteristicas opcionales y Adobe Reader
::     (paso 10 de la opcion 1).
::   - LIMPIEZA: vaciado de temporales (paso 11 de la opcion 1).
::   - FINAL: estado de Defender e inicio de Windows (final de la opcion 1).
::   - ARRANQUE: lo que arranca solo con Windows (paso 10 de la opcion 1 y opcion 6).
::   - ACTUALIZAR: todo lo pendiente de Windows Update (opcion 2).
::   - VERIFICAR: el reporte de la opcion 7.
::   - LUZ: luz nocturna del anochecer al amanecer (paso 7 de la opcion 1).
::   - AULA: borrado de perfiles de Chrome (opcion 5).
:: =========================================================================
#COMUN-INICIO#
# Funciones que usan varias secciones. :ps pega esta seccion adelante de la que corre;
# :detectar corre EQUIPO por su cuenta y no la recibe.
# Windows instalando una actualizacion: se espera. Cortarla la deja a medias y la
# rehace entera despues, y DISM falla mientras tanto. Primero lo que Windows Update
# sabe de si mismo (IsBusy); si esa COM no responde, se mira TiWorker. TiWorker queda
# unos minutos sin hacer nada al terminar: por eso se mide y no solo que exista.
function TiWorkerMedida {
    $ps = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='TiWorker.exe'" -ErrorAction SilentlyContinue)
    if (-not $ps.Count) { return $null }
    $cpu = 0; $io = 0
    foreach ($x in $ps) { $cpu += ($x.KernelModeTime + $x.UserModeTime) / 1e7; $io += $x.ReadTransferCount + $x.WriteTransferCount }
    return @{ cpu = $cpu; io = $io }
}
function TiWorkerOcupado {
    try { if ((New-Object -ComObject Microsoft.Update.Installer).IsBusy) { return $true } } catch { }
    $a = TiWorkerMedida
    if (-not $a) { return $false }
    Start-Sleep -Seconds 10
    $b = TiWorkerMedida
    if (-not $b) { return $false }
    # Preparando una actualizacion grande en disco mecanico TiWorker casi no usa CPU: con
    # 0,36 s cada 10 s, el umbral de 0,5 s lo dio por ocioso y el reinicio cancelo un
    # 26H2 al 52%. Por eso tambien los bytes de disco.
    return (($b.cpu - $a.cpu) -gt 0.5 -or ($b.io - $a.io) -gt 1MB)
}
function EsperarTiWorker {
    $t0 = Get-Date
    while (TiWorkerOcupado) {
        $min = [int]((Get-Date) - $t0).TotalMinutes
        if ($min -eq 0) { Write-Output '  Windows esta instalando una actualizacion. Se espera a que termine: cortarla'; Write-Output '  la deja a medias y la rehace entera despues.' }
        Write-Output ('    ... ' + $min + ' min')
        Start-Sleep -Seconds 50
    }
}
# Windows Update o el servicio de componentes dejaron algo que se termina al reiniciar.
function ReinicioPendiente {
    return ((Test-Path -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') -or (Test-Path -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'))
}
#COMUN-FIN#
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
# OneDrive en uso: una cuenta iniciada con mas de 3 archivos. Windows obliga a
# entrar con cuenta Microsoft y deja OneDrive configurado aunque nadie lo use;
# hasta 3 son los de bienvenida. Se cuenta hasta 4: si OneDrive guarda el Escritorio
# y los Documentos, la carpeta puede tener miles.
$od = 'N'
$hive = 'Registry::HKEY_CURRENT_USER'
if ($sid -like 'S-1-*' -and (Test-Path -LiteralPath ('Registry::HKEY_USERS\' + $sid))) { $hive = 'Registry::HKEY_USERS\' + $sid }
foreach ($a in @(Get-ChildItem -LiteralPath ($hive + '\Software\Microsoft\OneDrive\Accounts'))) {
    $carpeta = [string]$a.GetValue('UserFolder')
    if (-not $carpeta -or -not [IO.Directory]::Exists($carpeta)) { continue }
    $archivos = 0
    try { foreach ($f in [IO.Directory]::EnumerateFiles($carpeta, '*', 'AllDirectories')) { if ([IO.Path]::GetFileName($f) -ne 'desktop.ini') { $archivos++; if ($archivos -gt 3) { break } } } } catch { }
    if ($archivos -gt 3) { $od = 'S' }
}
'ONEDRIVE=' + $od
# Outlook nuevo en uso: guarda las cuentas y su copia del correo en
# AppData\Local\Microsoft\Olk (borrarla obliga a cargar las cuentas de nuevo).
# Usado en el ultimo ano: algo escrito ahi en 365 dias. Los correos enviados no
# se pueden contar desde aca: viven en el servidor.
$perfil = $env:USERPROFILE
if ($sid -like 'S-1-*') { $lp = (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid }).LocalPath; if ($lp) { $perfil = $lp } }
$olk = Join-Path $perfil 'AppData\Local\Microsoft\Olk'
$ol = 'N'
if ([IO.Directory]::Exists($olk)) {
    $hace = (Get-Date).AddDays(-365)
    try { foreach ($f in [IO.Directory]::EnumerateFiles($olk, '*', 'AllDirectories')) { if ([IO.File]::GetLastWriteTime($f) -gt $hace) { $ol = 'S'; break } } } catch { }
}
'OUTLOOK=' + $ol
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
# VBS e integridad de memoria (HVCI): si corren, si el procesador tiene MBEC (7 en
# las propiedades disponibles; es lo que las hace baratas) y si UEFI las bloquea.
$vbs = 0; $hvci = 0; $mbec = 0; $lock = 0
$dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
if ($dg) {
    if ($dg.VirtualizationBasedSecurityStatus -eq 2) { $vbs = 1 }
    if (@($dg.SecurityServicesRunning) -contains 2) { $hvci = 1 }
    if (@($dg.AvailableSecurityProperties) -contains 7) { $mbec = 1 }
}
foreach ($k in 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard', 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity') {
    if ((Get-ItemProperty -LiteralPath $k).Locked -eq 1) { $lock = 1 }
}
'VBS=' + $vbs
'HVCI=' + $hvci
'MBEC=' + $mbec
'VBS_LOCK=' + $lock
#EQUIPO-FIN#
#DISCO-INICIO#
# Paso 8 de la opcion 1: paginacion, cache de escritura, CompactOS, Restaurar sistema,
# BitLocker y almacenamiento reservado. Usa RAM_INST, DISCO_TIPO y DISCO_PNP de EQUIPO.
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
# BitLocker: siempre apagado. Windows 11 lo enciende solo al entrar con cuenta
# Microsoft, sin que nadie guarde la clave de recuperacion: cuando el disco falla o
# se cambia de PC, los datos se pierden. Y sin AES-NI (Atom, Core 2, Pentium y
# Celeron hasta 2016) cifra por software cada lectura y escritura. Descifrar tarda
# horas en un disco grande, sigue solo en segundo plano y continua tras reiniciar.
# Primero los discos de datos: el del sistema guarda las claves de los otros y no
# se deja descifrar antes.
$ns = 'root\CIMV2\Security\MicrosoftVolumeEncryption'
$vols = @(Get-CimInstance -Namespace $ns -ClassName Win32_EncryptableVolume | Where-Object { $_.DriveLetter -and $_.ConversionStatus -ne 0 } | Sort-Object { $_.DriveLetter -eq $env:SystemDrive })
if (-not $vols.Count) { Write-Output '  [OK] BitLocker: ningun disco cifrado.' }
foreach ($v in $vols) {
    # ConversionStatus: 0 descifrado, 1 cifrado, 2 cifrando, 3 descifrando, 4 y 5 en pausa.
    if ($v.ConversionStatus -eq 3) { Write-Output ('  BitLocker en ' + $v.DriveLetter + ' ya se esta descifrando.'); continue }
    manage-bde.exe -off $v.DriveLetter 2>&1 | Out-Null
    $v2 = Get-CimInstance -Namespace $ns -ClassName Win32_EncryptableVolume | Where-Object { $_.DriveLetter -eq $v.DriveLetter }
    if ($v2.ConversionStatus -eq 0 -or $v2.ConversionStatus -eq 3) {
        Write-Output ('  [OK] BitLocker en ' + $v.DriveLetter + ': descifrando en segundo plano. Horas en un disco grande; sigue solo aunque se reinicie.')
    } else {
        Write-Output ('  [AVISO] BitLocker en ' + $v.DriveLetter + ' no se pudo apagar: "manage-bde -status ' + $v.DriveLetter + '" dice por que.')
    }
}
# Que Windows no vuelva a cifrar solo: es lo que hace al entrar con cuenta Microsoft.
$kb = 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\BitLocker'
if (-not (Test-Path -LiteralPath $kb)) { New-Item -Path $kb -Force | Out-Null }
Set-ItemProperty -LiteralPath $kb -Name PreventDeviceEncryption -Value 1 -Type DWord
Write-Output '  [OK] Windows ya no cifra el disco solo al entrar con cuenta Microsoft.'
# Almacenamiento reservado: 7 GB que Windows guarda para sus actualizaciones. Con
# menos del 15 % libre el disco se fragmenta y la paginacion no entra: se liberan.
$vol = Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)
if ($vol -and ($vol.Free + $vol.Used) -gt 0 -and ($vol.Free * 100 / ($vol.Free + $vol.Used)) -lt 15) {
    DISM.exe /Online /Set-ReservedStorageState /State:Disabled 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Output '  [OK] Menos del 15 % libre: almacenamiento reservado de Windows desactivado, libera hasta 7 GB.' }
    else { Write-Output '  [AVISO] Menos del 15 % libre, pero el almacenamiento reservado no se pudo desactivar (hay una actualizacion pendiente?).' }
}
#DISCO-FIN#
#QUITAR-INICIO#
# Paso 10 de la opcion 1: lo que se quita. Sale con 2 si Adobe Reader esta
# instalado, para el aviso final sobre los PDF.
# Los paquetes provisionados se leen una sola vez: en una PC vieja, cada consulta
# a DISM tarda varios segundos.
$prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
# Quita una app para todos los usuarios y para los que se creen despues. Devuelve
# el nombre de cada paquete que quito.
function QuitarApp([string]$Nombre) {
    # ponytail-keep: primero fuera de los provisionados. Con la app todavia provisionada,
    # Remove-AppxPackage -AllUsers falla con 0x80070002 y la app queda instalada: asi
    # quedaron 28 apps en una netbook con Windows 10 recien instalado.
    $prov | Where-Object { $_.DisplayName -like $Nombre } | ForEach-Object {
        try { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop | Out-Null } catch {}
    }
    Get-AppxPackage -AllUsers -Name $Nombre -ErrorAction SilentlyContinue | Sort-Object PackageFullName -Unique | ForEach-Object {
        $p = $_; $ok = $true
        # Los errores de Appx cortan aunque se pida SilentlyContinue: sin try salen en
        # rojo. Si para todos los usuarios no se puede, al menos para esta cuenta.
        try { Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction Stop }
        catch { try { Remove-AppxPackage -Package $p.PackageFullName -ErrorAction Stop } catch { $ok = $false } }
        if ($ok) { $p.Name }
    }
}
Write-Output '  Quitando apps preinstaladas para todos los usuarios, puede tardar...'
$apps = 'Microsoft.549981C3F5F10','Microsoft.BingNews','Microsoft.BingSearch','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.Messaging','Microsoft.Microsoft3DViewer','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.MicrosoftStickyNotes','Microsoft.MixedReality.Portal','Microsoft.MSPaint','Microsoft.Office.OneNote','Microsoft.OneConnect','Microsoft.OutlookForWindows','Microsoft.People','Microsoft.PowerAutomateDesktop','Microsoft.Print3D','Microsoft.SkypeApp','Microsoft.Todos','Microsoft.Wallet','Microsoft.WindowsAlarms','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','microsoft.windowscommunicationsapps','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.GamingApp','Microsoft.XboxApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.XboxSpeechToTextOverlay','Clipchamp.Clipchamp','MicrosoftTeams','MSTeams','king.com.*','Microsoft.Windows.DevHome','MicrosoftCorporationII.MicrosoftFamily','MicrosoftCorporationII.QuickAssist','Microsoft.Edge.GameAssist','*StartExperiencesApp'
foreach ($a in $apps) {
    if ($a -eq 'Microsoft.OutlookForWindows' -and $env:OUTLOOK -eq 'S') { Write-Output '    (Outlook nuevo queda: se uso en el ultimo ano)'; continue }
    QuitarApp $a | ForEach-Object { Write-Output ('    - ' + $_) }
}
# El complemento de Teams para Office y el instalador de Teams para todas las
# cuentas son MSI. Sin Teams no sirven, y el complemento se carga con cada Outlook.
$u = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', ($env:UPS + '\Software\Microsoft\Windows\CurrentVersion\Uninstall\*')
Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'Microsoft Teams Meeting Add-in*' -or $_.DisplayName -eq 'Teams Machine-Wide Installer' } | ForEach-Object {
    if ($_.UninstallString -match '\{[0-9A-Fa-f-]{36}\}') {
        # ponytail-keep: sin leer Handle antes de esperar, PowerShell 5.1 deja ExitCode vacio.
        $m = Start-Process msiexec.exe -ArgumentList ('/x ' + $Matches[0] + ' /qn /norestart') -PassThru
        [void]$m.Handle; $m.WaitForExit()
        if ($m.ExitCode -in 0, 3010) { Write-Output ('    - ' + $_.DisplayName) }
    }
}
Write-Output '  [OK] Apps preinstaladas quitadas.'
# Copilot: lo que no es una app (el boton, Recall, Click to Do) lo apagan las
# politicas del paso 6.
[void](QuitarApp 'Microsoft.Copilot')
# Copilot tambien llega como programa, con el instalador de Edge: --force-uninstall
# lo quita sin preguntar, en unos 10 s. Para que no vuelva esta la politica del paso 6.
$c = Get-ItemProperty -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Copilot', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Copilot' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($c.UninstallString -match '^"([^"]+)"\s*(.*)$') { Start-Process -FilePath $Matches[1] -ArgumentList ($Matches[2] + ' --force-uninstall') -Wait -WindowStyle Hidden }
Write-Output '  [OK] Copilot quitado; el resto de la IA de Windows queda apagado por politica.'
# La app Fotos nueva, para todos los usuarios: el Visualizador de fotos clasico
# ya quedo registrado en el paso anterior.
[void](QuitarApp 'Microsoft.Windows.Photos')
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
# Conexion a Escritorio remoto no es una opcional sino una caracteristica de Windows.
# Sale en unos 25 s, sin reiniciar.
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-RemoteDesktopConnection -ErrorAction SilentlyContinue).State -eq 'Enabled') {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-RemoteDesktopConnection -NoRestart -ErrorAction Stop | Out-Null
        Write-Output '  [OK] Conexion a Escritorio remoto quitada.'
    } catch {}
}
# Avast, AVG y CCleaner: fuera siempre. Defender ya cubre lo que prometen, y en 2 GB
# un antivirus de terceros es medio giga de RAM; el limpiador de registro de CCleaner
# rompe mas de lo que arregla. Desinstalacion silenciosa con el desinstalador de cada
# uno: Instup.exe (Avast y AVG) con /instop:uninstall /silent, uninst.exe (CCleaner,
# NSIS) con /S. Puede pedir reiniciar.
$u = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$patronAv = '^Avast (Free |Premium )?(Antivirus|Security|One)|^AVG (AntiVirus|Internet Security)|^CCleaner|^McAfee (Security Scan|WebAdvisor)'
foreach ($p in @(Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $patronAv })) {
    # El -match va adentro del bucle: $Matches guarda solo el ultimo del Where-Object.
    if ($p.UninstallString -notmatch '^"?([A-Za-z]:\\[^"]+?\.exe)') { continue }
    $exe = $Matches[1]
    if ($exe -match 'Instup\.exe$') { $arg = '/instop:uninstall /silent' } else { $arg = '/S' }
    if (-not (Test-Path -LiteralPath $exe)) { continue }
    Write-Output ('  Desinstalando ' + $p.DisplayName + '...')
    $pr = Start-Process -FilePath $exe -ArgumentList $arg -PassThru -WindowStyle Hidden
    if ($pr -and $pr.WaitForExit(600000)) { Write-Output ('  [OK] ' + $p.DisplayName + ' desinstalado.') }
    else { Write-Output ('  [AVISO] ' + $p.DisplayName + ': el desinstalador no termino; desinstalalo desde Configuracion.') }
}
# McAfee (LiveSafe, Total Protection, el de fabrica): redundante con Defender y pide
# plata. Su desinstalador no se puede correr en silencio (hasta MCPR pide un captcha):
# se abre y el script sigue; el tecnico toca Quitar. Defender se activa solo al irse.
foreach ($p in @(Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^McAfee' -and $_.DisplayName -notmatch '^McAfee (Security Scan|WebAdvisor)' })) {
    if ($p.UninstallString -notmatch '^"?([A-Za-z]:\\[^"]+?\.exe)"?\s*(.*)$') { continue }
    if (-not (Test-Path -LiteralPath $Matches[1])) { continue }
    if ($Matches[2]) { Start-Process -FilePath $Matches[1] -ArgumentList $Matches[2] } else { Start-Process -FilePath $Matches[1] }
    Write-Output ('  [AVISO] ' + $p.DisplayName + ': se abrio su desinstalador, que no sabe correr en silencio. Toca Quitar; el script sigue.')
}
# Lo que dejan atras, con producto o sin el: la tarea Overseer, que cada 3 horas y
# media se actualiza sola y puede volver a instalar Avast. En la laptop de prueba
# estaba de fabrica, en C:\Windows\OEM, sin ningun Avast instalado.
if (-not @(Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^(Avast|AVG) ' }).Count) {
    foreach ($st in @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskPath -match '^\\(Avast Software|AVG)\\' })) {
        Stop-Process -Name Overseer -Force -ErrorAction SilentlyContinue
        $st | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue
        foreach ($a in $st.Actions) {
            $exe = [string]$a.Execute -replace '"', ''
            if ($exe -match 'Overseer\.exe$' -and (Test-Path -LiteralPath $exe)) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue }
        }
        Write-Output ('  [OK] Resto de Avast quitado: tarea ' + $st.TaskPath + $st.TaskName)
    }
}
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
Write-Output ''
Write-Output '  Corriendo ahora fuera de C:\Windows, en MB privados: lo que arranca solo o'
Write-Output '  quedo abierto. Si algo sobra: Administrador de tareas, pestana Inicio.'
$win = $env:SystemRoot.TrimEnd('\') + '\'
Get-Process | Where-Object { $_.Path -and -not $_.Path.StartsWith($win, [StringComparison]::OrdinalIgnoreCase) } | Group-Object Name | ForEach-Object {
    New-Object psobject -Property @{ N = $_.Name; MB = [math]::Round(($_.Group | Measure-Object PrivateMemorySize64 -Sum).Sum / 1MB); C = $_.Count }
} | Sort-Object MB -Descending | Select-Object -First 15 | ForEach-Object {
    $x = ''; if ($_.C -gt 1) { $x = ' (x' + $_.C + ')' }
    Write-Output ('    ' + ([string]$_.MB).PadLeft(5) + ' MB  ' + $_.N + $x)
}
# Una actualizacion a medias se termina al reiniciar, y en un disco mecanico tarda:
# que no apaguen la PC apenas vuelve.
$u = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
foreach ($p in @(Get-ItemProperty -Path $u -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match '^McAfee' -and $_.DisplayName -notmatch '^McAfee (Security Scan|WebAdvisor)' })) {
    Write-Output ''
    Write-Output ('  AVISO: ' + $p.DisplayName + ' sigue instalado. Pide plata y mientras este, Defender')
    Write-Output '  queda apagado. Sacalo en Configuracion, Aplicaciones; Defender se activa solo.'
}
if (ReinicioPendiente) {
    Write-Output ''
    Write-Output '  Windows Update tiene una actualizacion a medias: la termina al reiniciar. Deja'
    Write-Output '  la PC prendida y enchufada hasta que el disco se calme, aunque tarde media hora.'
}
# BitLocker en marcha (3 descifrando, 5 en pausa): que se sepa que sigue solo.
Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume | Where-Object { $_.DriveLetter -and $_.ConversionStatus -ne 0 } | ForEach-Object {
    $c = Invoke-CimMethod -InputObject $_ -MethodName GetConversionStatus
    if ($_.ConversionStatus -eq 3 -or $_.ConversionStatus -eq 5) { Write-Output ('  BitLocker en ' + $_.DriveLetter + ': descifrando en segundo plano, queda el ' + $c.EncryptionPercentage + ' %. Se puede reiniciar: sigue solo.') }
    else { Write-Output ('  AVISO: BitLocker en ' + $_.DriveLetter + ' sigue cifrado. "manage-bde -status ' + $_.DriveLetter + '" dice por que no se apago.') }
}
#FINAL-FIN#
#ACTUALIZAR-INICIO#
# Opcion 2, paso 1: todo lo pendiente de Windows Update con la API COM de Windows
# (anda en Home, sin modulos): calidad, drivers, versiones nuevas. Van de a una, para
# que se vea avanzar; las de version se instalan solas igual. Quedan afuera solo las
# optativas que no son drivers (las acumulativas "preview" se instalarian dos veces).
# Sale con 0 si no queda nada, 2 si instalo y hay que volver a buscar, 3 si hay que
# reiniciar, 1 si no pudo buscar.
$ErrorActionPreference = 'SilentlyContinue'
EsperarTiWorker
# Con un reinicio pendiente las instalaciones nuevas fallan: primero se reinicia. Solo
# en la ronda 1: si despues del reinicio sigue marcado, es una marca vieja y se sigue.
if ($env:OPT_RONDA -eq '1' -and (ReinicioPendiente)) { Write-Output '  Hay una actualizacion a medias que se termina al reiniciar.'; exit 3 }
# Descarga rota (0x80240034, 0x8024200D): Windows la reintenta cada dia, una hora con
# el disco al 100%, y vuelve a fallar; la laptop de prueba llevaba siete intentos.
# Vaciar la carpeta de descargas es el remedio exacto, y lo pendiente se baja de
# nuevo. Solo Download: DataStore es el historial y el catalogo. Recien aca, con
# TiWorker quieto y sin reinicio pendiente: vaciarla con una instalacion en curso la
# rompe, que es justo lo que se quiere arreglar.
$dl = Join-Path $env:SystemRoot 'SoftwareDistribution\Download'
Stop-Service -Name BITS -Force
# Stop-Service wuauserv se queda esperando sin fin si Windows Update esta bajando algo
# (en la laptop de prueba, 12 minutos de "Esperando a que se detenga el servicio" y
# seguia): se le pide parar y se le da un minuto. Si no para, se sigue sin vaciar la
# cache: la busqueda y la descarga de abajo esperan a la que ya esta en curso.
$svc = Get-Service -Name wuauserv
try { $svc.Stop() } catch { }
try { $svc.WaitForStatus('Stopped', '00:01:00') } catch { }
# Se renombra y se borra aparte: medir o borrar miles de archivos en un disco mecanico
# tarda minutos (3,6 GB de 26H2 en la laptop de prueba: mas de diez), y mientras tanto
# la busqueda ya puede correr. Windows Update crea Download de nuevo al arrancar.
$viejo = $dl + '.viejo' + (Get-Date -Format 'HHmmss')
if ((Get-Service -Name wuauserv).Status -eq 'Stopped') { Rename-Item -Path $dl -NewName (Split-Path -Leaf $viejo) }
if (Test-Path -LiteralPath $viejo) {
    Write-Output '  Cache de descargas de Windows Update apartada; se borra de fondo.'
} else {
    Write-Output '  [AVISO] Windows Update esta ocupado y no suelta la cache de descargas; se sigue sin vaciarla.'
}
foreach ($v in @(Get-ChildItem -Path (Split-Path -Parent $dl) -Directory -Filter 'Download.viejo*')) {
    Start-Process -FilePath cmd.exe -ArgumentList ('/c rd /s /q "' + $v.FullName + '"') -WindowStyle Hidden
}
Delete-DeliveryOptimizationCache -Force
Start-Service -Name wuauserv
$ses = New-Object -ComObject Microsoft.Update.Session
$ses.ClientApplicationID = 'OptimizarPC'
Write-Output '  Buscando actualizaciones, puede tardar varios minutos...'
$r = $null
try { $r = $ses.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0') } catch { }
if (-not $r) { Write-Output '  [AVISO] No se pudo buscar actualizaciones. Hay internet? Se sigue con el resto.'; exit 1 }
# Type 2 = driver. BrowseOnly = optativa.
$pend = @($r.Updates | Where-Object { -not $_.BrowseOnly -or $_.Type -eq 2 })
if (-not $pend.Count) { Write-Output '  [OK] Windows esta al dia: no queda nada pendiente.'; exit 0 }
Write-Output ('  ' + $pend.Count + ' pendientes:')
foreach ($u in $pend) { Write-Output ('    - ' + $u.Title + ' (' + [math]::Round($u.MaxDownloadSize / 1MB) + ' MB)') }
$reiniciar = $false; $ok = 0
foreach ($u in $pend) {
    if (-not $u.EulaAccepted) { $u.AcceptEula() }
    $col = New-Object -ComObject Microsoft.Update.UpdateColl
    [void]$col.Add($u)
    # Siempre se descarga: con la cache recien vaciada IsDownloaded puede seguir en True,
    # y con los archivos ya ahi la descarga vuelve enseguida.
    Write-Output ('  Descargando ' + $u.Title + '...')
    $d = $ses.CreateUpdateDownloader(); $d.Updates = $col
    $dr = $null; $hr = ''
    try { $dr = $d.Download() } catch { $hr = ' (' + $_.Exception.Message + ')' }
    # ResultCode 2 = bien, 3 = bien con errores.
    if ($dr -and $dr.ResultCode -gt 3) { $hr = ' (0x' + $dr.HResult.ToString('X8') + ')' }
    if (-not $dr -or $dr.ResultCode -gt 3) { Write-Output ('    [AVISO] no se pudo descargar' + $hr + '; se saltea.'); continue }
    Write-Output ('  Instalando ' + $u.Title + '... (en disco mecanico, una acumulativa tarda mas de media hora)')
    # ForceQuiet: las que declaran que podrian preguntar algo (los drivers, casi siempre)
    # se instalan calladas igual; si una falla por eso, se sigue con la siguiente.
    $i = $ses.CreateUpdateInstaller(); $i.Updates = $col; $i.ForceQuiet = $true; $i.AllowSourcePrompts = $false
    $ir = $null
    try { $ir = $i.Install() } catch { }
    if ($ir -and $ir.ResultCode -le 3) {
        $ok++
        if ($ir.RebootRequired) { $reiniciar = $true; Write-Output '    [OK] instalada; pide reiniciar.' } else { Write-Output '    [OK] instalada.' }
    } else {
        $hr = ''
        if ($ir) { $hr = ' (0x' + $ir.HResult.ToString('X8') + ')' }
        Write-Output ('    [AVISO] no se pudo instalar' + $hr + '; se sigue con la siguiente.')
    }
}
if ($reiniciar) { exit 3 }
if ($ok) { exit 2 }
Write-Output '  [AVISO] No se pudo instalar ninguna: se sigue con el resto.'
exit 1
#ACTUALIZAR-FIN#
#ARRANQUE-INICIO#
# Paso 10 de la opcion 1; con ARRANQUE_MODO=volver, la opcion 6. Lo que arranca con
# Windows sin que nadie lo pida. Se desactiva igual que en el Administrador de
# tareas (StartupApproved, primer byte 03): el programa sigue instalado, abre a mano
# y en Administrador de tareas > Inicio se reactiva con un clic. No se borra nada.
$ErrorActionPreference = 'SilentlyContinue'
$volver = ($env:ARRANQUE_MODO -eq 'volver')
$perfil = $env:USERPROFILE
if ($env:USID) { $lp = (Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $env:USID }).LocalPath; if ($lp) { $perfil = $lp } }
# Actualizadores, bandejas de drivers, "optimizadores", torrents, lanzadores de
# juegos y mensajeros: ninguno hace falta al iniciar sesion. Que Spotify o WhatsApp
# arranquen solos no lo pidio nadie: se abren cuando se usan. Fuera de la lista: el
# acceso remoto, los monitores de impresora, los antivirus y las nubes en uso. McAfee
# tampoco, ni su bandeja: no se puede matar (Defender queda apagado mientras este, y
# su autoproteccion no deja parar los servicios), y escondido se olvida que corre.
$patron = 'jusched|SunJavaUpdateSched|iTunesHelper|QuickTime Task|APSDaemon|igfxtray|hkcmd|igfxpers|HotKeysCmds|\bPersistence\b|RTHDVCPL|RtHDVBg|RAVCpl64|RtkNGUI|CCleaner|IObit|Driver Booster|Advanced SystemCare|uTorrent|BitTorrent|EpsonCustomerParticipation|EPSON Customer Research|Logitech Download Assistant|KiesTrayAgent|Wondershare|\bSteam\b|EpicGamesLauncher|\bSpotify\b|\bSkype\b|\bDiscord\b|\bWhatsApp\b|\bTelegram\b|\bZoom\b'
# Nubes: se quedan si se usan. Dropbox, con el criterio de OneDrive: mas de 3 archivos
# en su carpeta (sin su cache). Google Drive no guarda los archivos en una carpeta que
# se pueda contar: se queda si hay una cuenta iniciada (carpeta numerica en DriveFS).
$dbx = 0
foreach ($r in 'AppData\Roaming\Dropbox\info.json', 'AppData\Local\Dropbox\info.json') {
    $j = Join-Path $perfil $r
    if (-not [IO.File]::Exists($j)) { continue }
    $info = Get-Content -LiteralPath $j -Raw | ConvertFrom-Json
    foreach ($cuenta in 'personal', 'business') {
        $c = [string]$info.$cuenta.path
        if (-not $c -or -not [IO.Directory]::Exists($c)) { continue }
        try { foreach ($f in [IO.Directory]::EnumerateFiles($c, '*', 'AllDirectories')) { if ($f -notmatch '\\\.dropbox' -and [IO.Path]::GetFileName($f) -ne 'desktop.ini') { $dbx++; if ($dbx -gt 3) { break } } } } catch { }
    }
}
$drive = @(Get-ChildItem -LiteralPath (Join-Path $perfil 'AppData\Local\Google\DriveFS') -Directory | Where-Object { $_.Name -match '^\d+$' }).Count
if ($dbx -le 3) { $patron += '|\bDropbox\b' }
if (-not $drive) { $patron += '|GoogleDriveFS|Google Drive' }
function Nota([string]$texto) {
    if ($volver) { return '' }
    if ($texto -match 'Dropbox') { return ' (3 archivos o menos en su carpeta: no se usa)' }
    if ($texto -match 'GoogleDriveFS|Google Drive') { return ' (sin cuenta iniciada)' }
    return ''
}
# Primer byte 02 activo, 03 desactivado; los otros 8 son la fecha (FILETIME).
function Estado([string]$clave, [string]$valor) {
    $it = Get-Item -LiteralPath $clave
    if (-not $it) { return 2 }
    $d = $it.GetValue($valor)
    if ($d -is [byte[]] -and $d.Length) { return [int]$d[0] }
    return 2
}
function Marcar([string]$clave, [string]$valor) {
    $b = New-Object byte[] 12
    if ($volver) { $b[0] = 2 } else { $b[0] = 3; [BitConverter]::GetBytes([DateTime]::Now.ToFileTime()).CopyTo($b, 4) }
    if (-not (Test-Path -LiteralPath $clave)) { New-Item -Path $clave -Force | Out-Null }
    Set-ItemProperty -LiteralPath $clave -Name $valor -Value $b -Type Binary
}
# Con volver: solo lo que esta en 03 vuelve a 02; al desactivar, lo que ya esta en 03 se saltea.
function Toca([int]$estado) { if ($volver) { return ($estado -eq 3) } else { return ($estado -ne 3) } }
if ($volver) { Write-Output '  Vuelven al inicio de Windows los programas que saco la opcion 1...' }
else { Write-Output '  Sacando del inicio de Windows lo que arranca solo sin que nadie lo pida...' }
$n = 0
$apr = 'Microsoft\Windows\CurrentVersion\Explorer\StartupApproved'
$hklm = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\'
$fuentes = @(
    @(($hklm + 'Microsoft\Windows\CurrentVersion\Run'), ($hklm + $apr + '\Run')),
    @(($hklm + 'WOW6432Node\Microsoft\Windows\CurrentVersion\Run'), ($hklm + $apr + '\Run32')),
    @(($env:UPS + '\Software\Microsoft\Windows\CurrentVersion\Run'), ($env:UPS + '\Software\' + $apr + '\Run'))
)
foreach ($par in $fuentes) {
    $it = Get-Item -LiteralPath $par[0]
    if (-not $it) { continue }
    foreach ($v in $it.Property) {
        $texto = $v + ' ' + [string]$it.GetValue($v)
        if ($texto -notmatch $patron) { continue }
        if (-not (Toca (Estado $par[1] $v))) { continue }
        Marcar $par[1] $v
        Write-Output ('    - ' + $v + (Nota $texto)); $n++
    }
}
# Accesos directos de la carpeta Inicio, la del usuario y la de todos.
$sh = New-Object -ComObject WScript.Shell
$carpetas = @(
    @((Join-Path $perfil 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'), ($env:UPS + '\Software\' + $apr + '\StartupFolder')),
    @((Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\StartUp'), ($hklm + $apr + '\StartupFolder'))
)
foreach ($par in $carpetas) {
    if (-not [IO.Directory]::Exists($par[0])) { continue }
    foreach ($f in [IO.Directory]::GetFiles($par[0])) {
        $nombre = [IO.Path]::GetFileName($f)
        if ($nombre -eq 'desktop.ini') { continue }
        $texto = $nombre
        if ($nombre -like '*.lnk') { $texto += ' ' + [string]$sh.CreateShortcut($f).TargetPath }
        if ($texto -notmatch $patron) { continue }
        if (-not (Toca (Estado $par[1] $nombre))) { continue }
        Marcar $par[1] $nombre
        Write-Output ('    - ' + $nombre + ' (carpeta Inicio)' + (Nota $texto)); $n++
    }
}
# Las apps de la Store (WhatsApp, Spotify, Telegram) arrancan por una tarea de inicio
# propia: State 2 = activa, 1 = desactivada por el usuario, lo mismo que escribe el
# Administrador de tareas.
$ucls = $env:UCLS -replace '^HKU\\', 'Registry::HKEY_USERS\' -replace '^HKCU\\', 'Registry::HKEY_CURRENT_USER\'
foreach ($paq in @(Get-ChildItem -LiteralPath ($ucls + '\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData'))) {
    if ($paq.PSChildName -notmatch 'WhatsApp|Spotify|Telegram|Skype|Discord|Zoom') { continue }
    foreach ($t in @(Get-ChildItem -LiteralPath $paq.PSPath)) {
        $e = (Get-ItemProperty -LiteralPath $t.PSPath).State
        if ($null -eq $e) { continue }
        $esperado = 2; $nuevo = 1
        if ($volver) { $esperado = 1; $nuevo = 2 }
        if ([int]$e -ne $esperado) { continue }
        Set-ItemProperty -LiteralPath $t.PSPath -Name State -Value $nuevo -Type DWord
        Write-Output ('    - ' + $paq.PSChildName.Split('_')[0] + ' (app de la Store)'); $n++
    }
}
# Servicios de fabricante y de actualizadores que arrancan con Windows: a Manual (los
# levanta el programa que los necesita) y detenidos ahora. Con volver, a Automatico.
$patronServ = 'AGSService|AGMService|AdobeUpdateService|Bonjour|HPSupportSolutionsFrameworkService|HPTouchpointAnalytics|HP Analytics|^HP\w+Cap$|SupportAssist|DellClientManagement|DellDigitalDelivery|DellTechHub|^DDV|LenovoVantage|ImControllerService|LenovoSystemUpdate|ArmouryCrate|ASUSSystemAnalysis|ASUSSystemDiagnosis|^DSAService$|DSAUpdateService|NvTelemetryContainer|LGHUBUpdaterService|IObit|AdvancedSystemCare|LiveUpdateSvc|DriverBooster|Wondershare|WsAppService|WebAdvisor'
foreach ($s in @(Get-Service | Where-Object { $_.Name -match $patronServ -or $_.DisplayName -match $patronServ })) {
    if (-not $volver -and $s.StartType -eq 'Automatic') {
        Set-Service -Name $s.Name -StartupType Manual
        Stop-Service -Name $s.Name -Force
        Write-Output ('    - servicio ' + $s.DisplayName); $n++
    } elseif ($volver -and $s.StartType -eq 'Manual') {
        Set-Service -Name $s.Name -StartupType Automatic
        Write-Output ('    - servicio ' + $s.DisplayName); $n++
    }
}
# Tareas programadas fuera de \Microsoft: actualizadores, telemetria y "asistentes" de
# fabricantes (HP, Dell, Lenovo, NVIDIA, Avast). Se desactivan todas salvo los
# actualizadores de navegadores, Office, OneDrive y Dropbox, que son seguridad. Lo que
# se desactiva queda anotado para que la opcion 6 lo devuelva; lo que ya estaba
# desactivado no se anota, asi no se reactiva lo que apago otro.
# GoogleUpdate y GoogleSystem son el actualizador de Chrome; GoogleUserPEH (Platform
# Experience Helper) son metricas y se desactiva.
# McAfee queda: sus tareas son las firmas y los analisis mientras sea el antivirus.
$quedan = 'GoogleUpdate|GoogleSystem|MicrosoftEdgeUpdate|Office|OneDrive|Dropbox|Brave|Opera|Vivaldi|OptimizarPC|CreateExplorerShellUnelevatedTask|McAfee'
$anot = Join-Path $env:ProgramData 'OptimizarPC\tareas-desactivadas.txt'
if ($volver) {
    foreach ($t in @(Get-Content -LiteralPath $anot)) {
        $i = $t.LastIndexOf('\')
        if ($i -lt 0) { continue }
        $st = Get-ScheduledTask -TaskPath $t.Substring(0, $i + 1) -TaskName $t.Substring($i + 1)
        if ($st -and [string]$st.State -eq 'Disabled') { $st | Enable-ScheduledTask | Out-Null; Write-Output ('    - tarea ' + $t); $n++ }
    }
    Remove-Item -LiteralPath $anot -Force
} else {
    $lista = @(Get-Content -LiteralPath $anot)
    foreach ($st in @(Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' -and [string]$_.State -ne 'Disabled' -and $_.TaskName -notmatch ('^(' + $quedan + ')') -and $_.TaskPath -notmatch ('^\\(' + $quedan + ')') })) {
        $st | Disable-ScheduledTask | Out-Null
        $lista += ($st.TaskPath + $st.TaskName)
        Write-Output ('    - tarea ' + $st.TaskPath + $st.TaskName); $n++
    }
    if ($lista.Count) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $anot) -Force | Out-Null
        Set-Content -LiteralPath $anot -Value ($lista | Select-Object -Unique)
    }
}
if ($n -eq 0) { Write-Output '    (nada que tocar)' }
elseif ($volver) { Write-Output ('  [OK] ' + $n + ' vuelven a arrancar con Windows.') }
else {
    Write-Output ('  [OK] ' + $n + ' ya no arrancan con Windows. Siguen instalados y abren a mano; se')
    Write-Output '       reactivan en Administrador de tareas, pestana Inicio (las tareas, en el'
    Write-Output '       Programador de tareas).'
}
#ARRANQUE-FIN#
#CERRAR-INICIO#
# Opcion A, como Onyx en Mac: cierra todos los programas de la sesion de la
# pantalla. El criterio es donde estan instalados y no una lista de nombres: todo
# lo que esta fuera de la carpeta de Windows se cierra (lo que la persona abrio y
# lo que arranca solo: impresoras, actualizadores, mensajeros). Lo de Windows
# queda: sin eso la sesion se cierra o se cuelga, y ahi estan este cmd, Explorer
# y PowerShell. El acceso remoto tambien queda, por si alguien ayuda a distancia.
$ErrorActionPreference = 'SilentlyContinue'
# Con una actualizacion instalandose se espera (COMUN): cortarla la deja a medias y
# el paso 10 usa DISM, que falla mientras tanto.
EsperarTiWorker
# Windows Update, descargas y el orquestador, parados mientras corre el script. Solo
# parados: al reiniciar vuelven solos, y el paso 1 solo repara lo deshabilitado.
foreach ($s in 'wuauserv', 'UsoSvc', 'BITS', 'DoSvc') { Stop-Service -Name $s -Force }
Write-Output '  [OK] Windows Update frenado hasta el reinicio.'
$antes = [int64](Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
$sesion = (Get-Process -Id $PID).SessionId
$win = $env:SystemRoot.TrimEnd('\') + '\'
function Objetivos {
    Get-Process | Where-Object { $_.SessionId -eq $sesion -and $_.Path -and -not $_.Path.StartsWith($win, [StringComparison]::OrdinalIgnoreCase) -and $_.Name -notmatch 'anydesk|rustdesk|hoptodesk|teamviewer|screenconnect|splashtop' }
}
$nombres = @(Objetivos | ForEach-Object Name | Sort-Object -Unique)
if (-not $nombres.Count) { Write-Output '  [OK] No habia programas abiertos.'; exit 0 }
Write-Output ('  Cerrando ' + $nombres.Count + ' programas: ' + ($nombres -join ', '))
# Primero se les pide cerrar, como con la X, y se esperan hasta 10 s. Despues se
# fuerza todo lo que quede, incluidos los que corren sin ventana.
Objetivos | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object { [void]$_.CloseMainWindow() }
for ($k = 0; $k -lt 10 -and @(Objetivos | Where-Object { $_.MainWindowHandle -ne 0 }).Count; $k++) { Start-Sleep -Seconds 1 }
Objetivos | Stop-Process -Force
Start-Sleep -Seconds 2
$quedan = @(Objetivos | ForEach-Object Name | Sort-Object -Unique)
$despues = [int64](Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory
Write-Output ('  [OK] RAM libre: ' + [math]::Round($antes / 1KB) + ' MB antes, ' + [math]::Round($despues / 1KB) + ' MB ahora.')
if ($quedan.Count) { Write-Output ('  No se dejaron cerrar: ' + ($quedan -join ', ') + '. Suelen ser antivirus.') }
#CERRAR-FIN#
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
            # Con el script en la raiz de un disco ("C:\") todo empezaria igual y no se
            # borraria nada; y ahi nunca esta dentro de un Temp, asi que no hace falta.
            if ($self -and $self.Length -gt 3 -and $e.StartsWith($self.TrimEnd('\'), [StringComparison]::OrdinalIgnoreCase)) { continue }
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
} elseif ($masViejo) {
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
# El perfil sale de :detectar, el mismo calculo que usa la opcion 1.
L ('RAM:              ' + [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1) + ' GB visibles, ' + $env:RAM_INST + ' MB instalados')
L ('Perfil opcion 1:  4 GB o mas: ' + ($env:PERFIL_4GB -eq '1') + ' | mejor apariencia: ' + ($env:EFECTOS -eq '1') + ' | disco del sistema: ' + $env:DISCO_TIPO + ' | indexador de fabrica: ' + ($env:BUSQUEDA -eq '1') + ' | OneDrive en uso: ' + ($env:ONEDRIVE -eq 'S') + ' | Outlook en uso: ' + ($env:OUTLOOK -eq 'S'))
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
if ($env:USID) { L ('Sesion abierta:   ' + $env:UNAME + '  (' + $env:USID + ')'); $U = 'HKEY_USERS\' + $env:USID }
else { L 'Sesion abierta:   no detectada; se lee la cuenta actual'; $U = 'HKEY_CURRENT_USER' }
L ('Ejecutado por:    ' + [Security.Principal.WindowsIdentity]::GetCurrent().Name)

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
L ('VBS / integridad de memoria / MBEC en el procesador / bloqueo UEFI: ' + ($env:VBS -eq '1') + ' / ' + ($env:HVCI -eq '1') + ' / ' + ($env:MBEC -eq '1') + ' / ' + ($env:VBS_LOCK -eq '1'))
L '  (la v2 apaga VBS si corre sin MBEC, con menos de 8 GB o con disco mecanico)'

# --- Memoria ------------------------------------------------------------------
Titulo 'Memoria'
$mma = Get-MMAgent
if ($mma) { L ('Compresion de memoria / precarga de apps / combinacion de paginas: ' + $mma.MemoryCompression + ' / ' + $mma.ApplicationPreLaunch + ' / ' + $mma.PageCombining) }
L ('Proceso de compresion activo:   ' + [bool](Get-Process -Name 'Memory Compression'))
foreach ($v in 'DisablePagingExecutive', 'IOPageLockLimit', 'DontVerifyRandomDrivers', 'LargeSystemCache') { L ($v + ': ' + (Leer $mm $v)) }
L ('Precarga EnablePrefetcher / EnableSuperfetch: ' + (Leer ($mm + '\PrefetchParameters') 'EnablePrefetcher') + ' / ' + (Leer ($mm + '\PrefetchParameters') 'EnableSuperfetch') + '   (3 = arranque y programas, el de fabrica)')
L ('Paginacion administrada por Windows: ' + $cs.AutomaticManagedPagefile)
Get-CimInstance Win32_PageFileSetting | ForEach-Object { L ('Paginacion configurada:         ' + $_.Name + ' - inicial ' + $_.InitialSize + ' MB, maximo ' + $_.MaximumSize + ' MB   (la v2: fijo en el doble de la RAM)') }
Get-CimInstance Win32_PageFileUsage | ForEach-Object { L ('Archivo de paginacion:          ' + $_.Name + ' - ' + $_.AllocatedBaseSize + ' MB (en uso ' + $_.CurrentUsage + ' MB, pico ' + $_.PeakUsage + ' MB)') }

# --- Servicios ----------------------------------------------------------------
Titulo 'Servicios (inicio / estado / lo que espera la v2)'
$espera = [ordered]@{
    'SysMain' = 'Automatico'; 'TabletInputService' = 'Manual'; 'DoSvc' = 'Auto retrasado'
    'DiagTrack' = 'DESHABILITADO'; 'dmwappushservice' = 'DESHABILITADO'; 'WSearch' = 'segun disco y RAM'; 'RemoteRegistry' = 'DESHABILITADO'
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
Titulo 'Windows Update'
$au = $null
try { $au = (New-Object -ComObject Microsoft.Update.AutoUpdate).Results } catch { }
if ($au) {
    L ('Ultima busqueda / ultima instalacion: ' + $au.LastSearchSuccessDate + ' / ' + $au.LastInstallationSuccessDate + '  (hora UTC)')
}
L ('Reinicio pendiente de una actualizacion: ' + (ReinicioPendiente))
L ('Instalador de modulos (TiWorker) corriendo ahora: ' + [bool](Get-Process -Name TiWorker))

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
L 'Fuera de \Microsoft (la v2 desactiva todas salvo actualizadores de navegadores, Office, OneDrive y Dropbox):'
foreach ($st in @(Get-ScheduledTask | Where-Object { $_.TaskPath -notlike '\Microsoft\*' } | Sort-Object TaskPath, TaskName)) {
    L (([string]$st.State).PadRight(10) + $st.TaskPath + $st.TaskName)
}

# --- Politicas del equipo -------------------------------------------------------
Titulo 'Politicas del equipo'
$pol = 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows'
$lista = @(
    @(($pol + '\DataCollection'), 'AllowTelemetry'),
    @(($pol + '\Windows Feeds'), 'EnableFeeds'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer', 'SettingsPageVisibility'),
    @(($pol + '\Windows Search'), 'AllowCortana'),
    @(($pol + '\Windows Search'), 'EnableDynamicContentInWSB'),
    @(($pol + '\GameDVR'), 'AllowGameDVR'),
    @(($pol + '\DeliveryOptimization'), 'DODownloadMode'),
    @(($pol + '\Windows Error Reporting'), 'Disabled'),
    @(($pol + '\CloudContent'), 'DisableWindowsConsumerFeatures'),
    @(($pol + '\AppCompat'), 'DisableInventory'),
    @(($pol + '\System'), 'EnableMmx'),
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
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\SystemSettings\AccountNotifications'), 'EnableAccountNotifications'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'Start_AccountNotifications'),
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
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Search'), 'SearchboxTaskbarMode'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'TaskbarGlomLevel'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'ShowCopilotButton'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'), 'ShowTaskViewButton'),
    @(($U + '\System\GameConfigStore'), 'GameDVR_Enabled')
)
foreach ($par in $lista) { L ($par[1].PadRight(32) + (Leer $par[0] $par[1])) }
$bg = Get-ChildItem -LiteralPath ('Registry::' + $U + '\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications')
$apagadas = @($bg | Where-Object { (Get-ItemProperty -LiteralPath $_.PSPath).Disabled -eq 1 }).Count
L ('Apps en segundo plano apagadas: ' + $apagadas + ' de ' + @($bg).Count + '  (interruptor general GlobalUserDisabled: ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications') 'GlobalUserDisabled') + ')')
$cls = if ($U -eq 'HKEY_CURRENT_USER') { 'HKEY_CURRENT_USER\Software\Classes' } else { $U + '_Classes' }
L ('Tipo de carpeta generico:       ' + (Leer ($cls + '\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell') 'FolderType'))
L ('Menu del boton derecho clasico (Windows 11): ' + (Test-Path -LiteralPath ('Registry::' + $cls + '\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32')) + '   (la v2 lo pone solo con 2 GB)')
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
# Horas encendido y ciclos de cabezal (SMART): muchos ciclos por hora es un disco que
# estaciona el cabezal cada pocos segundos, y la PC se congela segundos al despertarlo.
$src = $null
if ($dd) { $src = $dd | Get-StorageReliabilityCounter }
if ($src -and $src.PowerOnHours) {
    $horas = [int64]$src.PowerOnHours; $ciclos = [int64]$src.LoadUnloadCycleCount
    L ('Disco: horas encendido / ciclos de cabezal: ' + $horas + ' / ' + $ciclos + '  (' + [Math]::Round($ciclos / $horas, 1) + ' por hora; mas de 30 = estaciona el cabezal a cada rato)')
    if ($src.Temperature) { L ('Disco: temperatura:             ' + $src.Temperature + ' C') }
} else { L 'Disco: horas y ciclos de cabezal: el disco no los informa' }
$bl = @(Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume | Where-Object { $_.DriveLetter })
if ($bl.Count) {
    foreach ($v in $bl) {
        $conv = Invoke-CimMethod -InputObject $v -MethodName GetConversionStatus
        $est = @{0 = 'descifrado'; 1 = 'CIFRADO'; 2 = 'cifrando'; 3 = 'descifrando'; 4 = 'cifrado en pausa'; 5 = 'descifrado en pausa'}[[int]$v.ConversionStatus]
        $pct = ''
        if ($conv -and $v.ConversionStatus -ge 2) { $pct = ', ' + $conv.EncryptionPercentage + ' % cifrado' }
        L ('BitLocker en ' + $v.DriveLetter + ':                 ' + $est + $pct + '  (proteccion ' + @{0 = 'apagada'; 1 = 'ACTIVA'; 2 = '?'}[[int]$v.ProtectionStatus] + '; la v2 descifra todo)')
    }
} else { L 'BitLocker:                      sin discos cifrables, o Windows no lo informa' }
L ('Cifrado automatico (PreventDeviceEncryption): ' + (Leer 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption') + '   (1 = Windows no cifra solo)')
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
$ub = @()
foreach ($par in @(@('Chrome', 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist', 'ddkjiahejlhfcafbddmgiahcphecmpfh'), @('Edge', 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist', 'cimighlppcgcoapaliogpjjdehbnofhn'))) {
    $fl = Get-ItemProperty -LiteralPath ('Registry::' + $par[1])
    $hay = $false
    if ($fl) { $hay = [bool]($fl.PSObject.Properties | Where-Object { [string]$_.Value -like ($par[2] + '*') }) }
    $ub += ($par[0] + ' ' + $hay)
}
L ('uBlock Origin Lite (politica):  ' + ($ub -join ' | '))
L ('Chrome de aula (BrowserSignin): ' + (Leer 'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome' 'BrowserSignin') + '  (0 = sin iniciar sesion en Chrome)')

# --- Apps preinstaladas -------------------------------------------------------
Titulo 'Apps preinstaladas que la v2 puede quitar (presentes)'
$apps = 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.Copilot', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes', 'Microsoft.Office.OneNote', 'Microsoft.OutlookForWindows', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.WindowsAlarms', 'Microsoft.WindowsMaps', 'microsoft.windowscommunicationsapps', 'Microsoft.YourPhone', 'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo', 'Microsoft.XboxApp', 'Microsoft.XboxGamingOverlay', 'king.com.*', 'MSTeams', 'Microsoft.Windows.DevHome', 'MicrosoftCorporationII.MicrosoftFamily', 'MicrosoftCorporationII.QuickAssist', 'Microsoft.Edge.GameAssist'
$hay = foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a | Select-Object -ExpandProperty Name -Unique }
if ($hay) { L (($hay | Sort-Object -Unique) -join ', ') } else { L '(ninguna)' }
$cp = (Test-Path -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Copilot') -or (Test-Path -LiteralPath 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Copilot')
L ('Copilot (programa) instalado:   ' + $cp)

# --- Caracteristicas opcionales -----------------------------------------------
Titulo 'Caracteristicas opcionales instaladas'
$caps = @(Get-WindowsCapability -Online -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Installed' } | ForEach-Object { $_.Name.Split('~')[0] })
if ($caps.Count) { L (($caps | Sort-Object -Unique) -join ', ') } else { L '(no se pudo leer)' }
L ('Conexion a Escritorio remoto:   ' + (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-RemoteDesktopConnection -ErrorAction SilentlyContinue).State)

# --- Inicio de Windows --------------------------------------------------------
Titulo 'Programas que arrancan con Windows'
# Lo desactivado en el Administrador de tareas (o por la v2) empieza con 03 en StartupApproved.
$apr = '\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\'
foreach ($par in @(@(($U + '\Software\Microsoft\Windows\CurrentVersion\Run'), ($U + $apr + 'Run')), @('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', ('HKEY_LOCAL_MACHINE' + $apr + 'Run')), @('HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run', ('HKEY_LOCAL_MACHINE' + $apr + 'Run32')))) {
    $i = Get-Item -LiteralPath ('Registry::' + $par[0])
    if ($i) { $i.Property | ForEach-Object { $m = ''; if ((Leer $par[1] $_) -like '03*') { $m = '   (desactivado)' }; L ('  - ' + $_ + $m) } }
}
L ''
L 'Corriendo ahora fuera de C:\Windows, en MB privados: lo que arranca solo o quedo abierto.'
$win = $env:SystemRoot.TrimEnd('\') + '\'
Get-Process | Where-Object { $_.Path -and -not $_.Path.StartsWith($win, [StringComparison]::OrdinalIgnoreCase) } | Group-Object Name | ForEach-Object {
    New-Object psobject -Property @{ N = $_.Name; MB = [math]::Round(($_.Group | Measure-Object PrivateMemorySize64 -Sum).Sum / 1MB); C = $_.Count }
} | Sort-Object MB -Descending | Select-Object -First 20 | ForEach-Object {
    $x = ''; if ($_.C -gt 1) { $x = ' (x' + $_.C + ')' }
    L ('  ' + ([string]$_.MB).PadLeft(5) + ' MB  ' + $_.N + $x)
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
