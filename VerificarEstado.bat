@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Verificar estado - solo lectura
:: =========================================================================
::  VERIFICAR ESTADO  (SOLO LECTURA: NO CAMBIA NADA)
::  Muestra el estado de todo lo que tocan los scripts de este repo y lo
::  guarda en un .txt al lado del script, para comparar antes y despues.
::  El reporte esta escrito en PowerShell, al final de este mismo archivo.
:: =========================================================================

if not defined PROCESSOR_ARCHITEW6432 goto :arquitectura_ok
"%SystemRoot%\Sysnative\cmd.exe" /c ""%~f0""
exit /b
:arquitectura_ok

fltmc >nul 2>&1
if not errorlevel 1 goto :es_admin
echo Pidiendo permisos de administrador para poder leer todo...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }"
if not errorlevel 1 exit /b
echo No se obtuvieron permisos. Hace clic derecho y "Ejecutar como administrador".
pause
exit /b 1
:es_admin

powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:VE_RUTA='%~f0'; $t=[IO.File]::ReadAllText($env:VE_RUTA); $i=$t.IndexOf('#PS-' + 'INICIO#'); Invoke-Expression $t.Substring($i)"
echo.
pause
exit /b 0

#PS-INICIO#
# ---------------------------------------------------------------------------
# Reporte en PowerShell. cmd nunca llega aca: corta en el "exit /b" de arriba.
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
L ('RAM:              ' + [Math]::Round($cs.TotalPhysicalMemory / 1GB, 1) + ' GB')
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
Get-CimInstance Win32_PageFileUsage | ForEach-Object { L ('Archivo de paginacion:          ' + $_.Name + ' - ' + $_.AllocatedBaseSize + ' MB (en uso ' + $_.CurrentUsage + ' MB)') }

# --- Servicios ----------------------------------------------------------------
Titulo 'Servicios (inicio / estado / lo que espera la v2)'
$espera = [ordered]@{
    'SysMain' = 'Automatico'; 'TabletInputService' = 'Manual'; 'DoSvc' = 'Auto retrasado'
    'DiagTrack' = 'DESHABILITADO'; 'dmwappushservice' = 'DESHABILITADO'; 'WSearch' = 'DESHABILITADO'; 'RemoteRegistry' = 'DESHABILITADO'
    'XblAuthManager' = 'DESHABILITADO'; 'XblGameSave' = 'DESHABILITADO'; 'XboxNetApiSvc' = 'DESHABILITADO'; 'XboxGipSvc' = 'DESHABILITADO'; 'xbgm' = 'DESHABILITADO'
    'bthserv' = 'DESHABILITADO'; 'BTAGService' = 'DESHABILITADO'; 'BthAvctpSvc' = 'DESHABILITADO'
    'PcaSvc' = 'Manual'; 'TrkWks' = 'Manual'; 'iphlpsvc' = 'Manual'; 'DPS' = 'Manual'; 'CDPSvc' = 'Manual'; 'MapsBroker' = 'Manual'; 'edgeupdate' = 'Manual'
    'lfsvc' = 'Manual'; 'WbioSrvc' = 'Manual'; 'RetailDemo' = 'Manual'
    'BITS' = 'Auto retrasado'; 'WpnService' = 'Auto retrasado'
    'Spooler' = 'segun respuesta'; 'LanmanServer' = 'segun respuesta'
    'WinDefend' = 'Automatico'; 'WdNisSvc' = 'Manual'; 'SecurityHealthService' = 'Manual'; 'wscsvc' = 'Auto retrasado'; 'mpssvc' = 'Automatico'; 'BFE' = 'Automatico'
    'wuauserv' = 'Manual'; 'UsoSvc' = 'Auto retrasado'; 'WaaSMedicSvc' = 'Manual'; 'CryptSvc' = 'Automatico'; 'TrustedInstaller' = 'Manual'
    'AppXSvc' = 'Manual'; 'ClipSVC' = 'Manual'; 'InstallService' = 'Manual'; 'Appinfo' = 'Manual'; 'VSS' = 'Manual'; 'swprv' = 'Manual'; 'W32Time' = 'Manual'
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
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver',
    '\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan',
    '\Microsoft\Windows\SystemRestore\SR',
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Maintenance\WinSAT',
    '\Microsoft\Windows\Windows Error Reporting\QueueReporting'
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
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray', 'HideSystray'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications', 'DisableEnhancedNotifications'),
    @('HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MRT', 'DontOfferThroughWUAU'),
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
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'), 'VisualFXSetting'),
    @(($U + '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'), 'EnableTransparency'),
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

# --- Disco y energia ----------------------------------------------------------
Titulo 'Disco y energia'
L ((fsutil behavior query DisableLastAccess) -join ' ')
L ((fsutil behavior query Disable8dot3) -join ' ')
$compacto = $false
foreach ($f in 'System32\shell32.dll', 'System32\mshtml.dll', 'explorer.exe') {
    $ruta = Join-Path $env:windir $f
    if ((Test-Path -LiteralPath $ruta) -and ((Get-Item -LiteralPath $ruta -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { $compacto = $true }
}
L ('Sistema comprimido (CompactOS): ' + $compacto)
L ('Plan de energia:                ' + ((powercfg /getactivescheme) -join ' '))
L ('Inicio rapido (HiberbootEnabled): ' + (Leer 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled'))
L ('Hibernacion habilitada:         ' + (Leer 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled'))
L 'Apagar el disco tras (indices CA y CC, 0x0 = nunca):'
powercfg /query SCHEME_CURRENT SUB_DISK DISKIDLE | Select-Object -Last 3 | Where-Object { $_.Trim() } | ForEach-Object { L ('  ' + $_.Trim()) }

# --- Puntos de restauracion ---------------------------------------------------
Titulo 'Puntos de restauracion (ultimos 3)'
$rp = Get-ComputerRestorePoint | Select-Object -Last 3
if ($rp) { $rp | ForEach-Object { L ([Management.ManagementDateTimeConverter]::ToDateTime($_.CreationTime).ToString('yyyy-MM-dd HH:mm') + '  ' + $_.Description) } } else { L '(ninguno)' }

# --- Clasicos de Windows 7 -----------------------------------------------------
Titulo 'Clasicos de Windows 7'
$fotos = Get-AppxPackage -AllUsers -Name Microsoft.Windows.Photos
L ('App Fotos nueva instalada:      ' + [bool]$fotos)
$fa = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations'
L ('Visualizador clasico para .jpg / .png / .gif / .bmp: ' + (Leer $fa '.jpg') + ' / ' + (Leer $fa '.png') + ' / ' + (Leer $fa '.gif') + ' / ' + (Leer $fa '.bmp'))
L ('Programa predeterminado del usuario para .jpg: ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.jpg\UserChoice') 'ProgId'))
L ('Alt+Tab clasico (AltTabSettings): ' + (Leer ($U + '\Software\Microsoft\Windows\CurrentVersion\Explorer') 'AltTabSettings'))

# --- Apps preinstaladas -------------------------------------------------------
Titulo 'Apps preinstaladas que la v2 puede quitar (presentes)'
$apps = 'Microsoft.549981C3F5F10', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People', 'Microsoft.SkypeApp', 'Microsoft.WindowsMaps', 'microsoft.windowscommunicationsapps', 'Microsoft.YourPhone', 'Microsoft.XboxApp', 'Microsoft.XboxGamingOverlay', 'king.com.*'
$hay = foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a | Select-Object -ExpandProperty Name -Unique }
if ($hay) { L (($hay | Sort-Object -Unique) -join ', ') } else { L '(ninguna)' }

# --- Inicio de Windows --------------------------------------------------------
Titulo 'Programas que arrancan con Windows'
foreach ($k in @(($U + '\Software\Microsoft\Windows\CurrentVersion\Run'), 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run')) {
    $i = Get-Item -LiteralPath ('Registry::' + $k)
    if ($i) { $i.Property | ForEach-Object { L ('  - ' + $_) } }
}

# --- Guardar --------------------------------------------------------------------
$nombre = 'estado-' + $env:COMPUTERNAME + '-' + (Get-Date -Format 'yyyyMMdd-HHmm') + '.txt'
$destino = Join-Path (Split-Path -Parent $env:VE_RUTA) $nombre
try { [IO.File]::WriteAllLines($destino, $lineas) } catch { $destino = Join-Path $env:TEMP $nombre; [IO.File]::WriteAllLines($destino, $lineas) }
Write-Host ''
Write-Host ('Reporte guardado en: ' + $destino) -ForegroundColor Green
