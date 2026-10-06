# Optimizar PC Vieja

[![Descargar OptimizarPC.bat](https://img.shields.io/badge/Descargar-OptimizarPC.bat-2ea44f?style=for-the-badge)](https://github.com/franciscoxc/OptimizarPCVieja/releases/latest/download/OptimizarPC.bat)

Script batch para Windows 10 22H2 (32 y 64 bits) en equipos con HDD y 2 GB de RAM, incluidas las netbooks Conectar
Igualdad con Atom. Objetivo: máxima velocidad y mínimo uso de RAM sin desactivar la protección (Defender, Firewall,
UAC, SmartScreen, Windows Update).

## Uso

1. Ejecutar `OptimizarPC.bat`. Se autoeleva (UAC) y se relanza en 64 bits si hace falta. Requiere solo `cmd` y
   PowerShell 5.1.
2. Opción `1`. El menú responde a una tecla, sin Enter.
3. Dos preguntas: OneDrive y apps preinstaladas. El resto es desatendido:
   10-20 min en HDD, más la primera vez (características opcionales).
4. Reiniciar.

Descarga: el navegador puede pedir confirmación para un `.bat`, y SmartScreen avisa al ejecutarlo (*Más información >
Ejecutar de todas formas*). *Propiedades > Desbloquear* quita la marca de internet.

Después de la opción 1, el botón de encendido apaga el equipo. La tapa también, salvo con 4 GB o más de RAM: ahí
suspende (ver [Perfiles](#perfiles-según-el-hardware)).

## Menú

| Tecla | Opción | Modifica |
|---|---|---|
| `1` | Optimizar. Incluye la revisión del script v1. | Sí |
| `2` | Limpiar WinSxS con DISM `/ResetBase`. Avanzado, irreversible. Pide confirmación. Hasta 1 h. | Sí |
| `3` | Desfragmentación completa. Horas. | Sí |
| `4` | Instalar WinRAR, VLC y Chrome con winget. | Sí |
| `5` | Chrome de aula: cierra Chrome y borra todos sus perfiles; arranca sin pedir iniciar sesión. Pide confirmación. | Sí |
| `6` | Revertir la opción 1 a valores de fábrica. | Sí |
| `7` | Verificar: hardware, antirrobo CI, estado de cada ajuste. Reporte `.txt` junto al script. | No |
| `0` | Salir. | |

Cada opción vuelve al menú. `1` y `6` ofrecen reiniciar; si se pospone, el menú lo recuerda y lo ofrece al salir.
Secuencia habitual: `1`, `4`.

**Usuario destino.** Los ajustes de usuario se escriben en `HKEY_USERS\<SID>` del dueño del `explorer.exe` de la
sesión, no en `HKCU`, que al elevar con otra cuenta apunta al administrador. La opción 1 muestra el usuario detectado.

## Opción 1: Optimizar

Criterios:

- Cada cambio tiene motivo y, si existe, fuente.
- La protección se verifica y se repara; nunca se apaga.
- Servicios: Manual siempre que se pueda; Automático (retrasado) si tienen que arrancar solos; Deshabilitado solo lo
  inútil en este hardware.
- Nada residente que no aporte (ver [Caché de disco](#caché-de-disco-y-optimizaciones-de-windows)).
- Sin puntos de restauración. La reversión es la opción 6.

Avisos de hardware al empezar: RAM baja, video sin driver (*Adaptador de pantalla básico*), antirrobo de Conectar
Igualdad.

### Perfiles según el hardware

Cada ajuste depende del recurso que realmente cuesta: la RAM, la placa de video o el disco. La RAM se mide instalada
(suma de módulos, `Win32_PhysicalMemory`): la visible puede dar 3,9 GB porque el video reserva una parte, y Windows de
32 bits ve unos 3,2 GB. Umbral: 3,5 GB.

| Condición | Ajuste | Base (2 GB, HDD, sin driver) | Con la condición |
|---|---|---|---|
| RAM ≥ 4 GB | Suspensión automática | 4 h | 1 h |
| RAM ≥ 4 GB | Tapa | Apagar | Suspender |
| RAM ≥ 4 GB | *Suspender* en el menú de apagado | Oculto | Visible |
| RAM ≥ 4 GB | Bluetooth (`bthserv`, `BTAGService`, `BthAvctpSvc`) | Deshabilitado | Manual (fábrica) |
| RAM ≥ 4 GB y video con driver | Efectos visuales | Mejor rendimiento | Mejor apariencia (`UserPreferencesMask=9E3E078012000000`), transparencias, desenfoque del inicio de sesión, Alt+Tab moderno |
| Disco del sistema SSD | Indexador (`WSearch`) | Deshabilitado | Automático (retrasado), fábrica |

Fijo en todos: botón de encendido apaga, botón de suspensión no hace nada, sin hibernación, `MenuShowDelay` en 100 ms,
paginación en 2 × RAM con tope de 8 GB. Sin video con driver, los efectos los dibuja el procesador, así que quedan al
mínimo aunque haya RAM. La opción 7 muestra el perfil detectado.

### 1. Seguridad (solo repara)

| Elemento | Acción |
|---|---|
| Servicios esenciales | Si están deshabilitados, vuelven a su valor de fábrica: Defender, Centro de seguridad, Firewall, Windows Update (`BITS`, `UsoSvc`, `WaaSMedicSvc`, `DoSvc`), Store y licencias, `Appinfo` (UAC), `VSS`, `swprv`, `W32Time`, red, audio, temas. |
| Defender | Borra políticas que lo desactivan. El bloqueo de PUA se activa en el [paso 5](#5-defender). |
| Firewall | Encendido en los 3 perfiles; borra políticas que lo apagan. |
| SmartScreen | Borra políticas que lo apagan (Windows y Edge). |
| UAC | Si está apagado o en "no notificar nunca", vuelve al valor de fábrica. |
| DEP | `AlwaysOff` pasa a `OptIn`. |
| Spectre/Meltdown | Reactiva las mitigaciones desactivadas. |
| Windows Update | Borra políticas que lo bloquean. |
| Reproducción automática | Desactivada en todas las unidades. |
| Tareas | Asegura activas: `ScheduledDefrag`, `StartComponentCleanup`, `DiskDiagnosticResolver`, análisis de Defender. |

### 2. Revisión del script v1

Se lee el estado de cada cambio del v1 y se repara solo lo que está en un valor perjudicial (`[REPARADO]` en
pantalla); si no hay nada, lo informa. Lo correcto o inocuo no se toca.

| Ajuste del v1 | Veredicto | Si se encuentra |
|---|---|---|
| `SysMain` deshabilitado | Perjudicial: gestiona la compresión de memoria y el prefetch de arranque. | Automático. |
| `TabletInputService` deshabilitado | Perjudicial: rompe la escritura en Inicio, Configuración y apps UWP. | Manual (fábrica). |
| `WbioSrvc` deshabilitado | Perjudicial: rompe la huella. | Manual (fábrica). |
| `lfsvc` deshabilitado | Perjudicial: rompe la luz nocturna del anochecer al amanecer. | Manual (fábrica). |
| `DisablePagingExecutive=1` | Perjudicial con poca RAM: fija el kernel en memoria. | `0`. |
| `DoSvc` con `Start=4` | Perjudicial: puede romper Windows Update. | Fábrica (paso 1) + `DODownloadMode=0` (sin P2P). |
| `IOPageLockLimit`, `DontVerifyRandomDrivers` | Placebos: Windows los ignora. | Sin cambios. |
| `compact /CompactOS:never` | Correcto en HDD. | Se mantiene; descomprime solo si estaba comprimido y hay 6 GB libres. |
| `DisableLastAccess`, `Disable8dot3` | Correctos. | Sin cambios. |
| Telemetría, Xbox, Bluetooth, Mapas, Retail Demo | Correctos. | Sin cambios (la opción 1 aplica su propia configuración de servicios). |

La compresión de memoria se activa siempre (paso 8).

### 3. Servicios

| Inicio | Servicios | Motivo |
|---|---|---|
| Deshabilitado | `DiagTrack`, `dmwappushservice` | Telemetría. |
| Deshabilitado (HDD) | `WSearch` | Indexa leyendo el disco; con SSD queda de fábrica. El Inicio sigue encontrando apps (20H2+); se pierde la búsqueda instantánea de archivos. Alternativa: [Everything](https://www.voidtools.com/) (lee la MFT). |
| Deshabilitado | `XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `xbgm` | Xbox. |
| Deshabilitado (< 4 GB) | `bthserv`, `BTAGService`, `BthAvctpSvc` | Bluetooth. Con 4 GB o más, Manual (fábrica): sin adaptador no consume nada. |
| Deshabilitado | `RemoteRegistry` | Fábrica; se asegura. |
| Deshabilitado | `AdobeARMservice` | Actualizador de Adobe Reader, si está. |
| Manual | `PcaSvc`, `TrkWks`, `iphlpsvc`, `DPS`, `CDPSvc`, `MapsBroker`, `edgeupdate` | No necesitan arrancar con Windows. Edge se actualiza por tareas programadas. Con `DPS` en Manual, los solucionadores de problemas no andan hasta que el servicio se inicia. |
| Manual | `lfsvc`, `WbioSrvc`, `RetailDemo`, `TabletInputService` | Fábrica. `lfsvc` es la ubicación: la usa la luz nocturna. |
| Automático (retrasado) | `BITS`, `WpnService` | Necesarios, pero no en el arranque. |
| Automático (retrasado) | `Spooler` | Siempre: una impresora que deja de andar sin aviso cuesta más que lo que ahorra. |
| Automático | `LanmanServer` | Siempre, para compartir carpetas e impresoras en la red. |
| Según respuesta | `OneSyncSvc`, `PimIndexMaintenanceSvc`, `UnistoreSvc`, `UserDataSvc`, `MessagingService` | Sincronizan Correo, Calendario, Contactos y Mensajes. Deshabilitados si se quitan las apps. Son servicios por usuario: rigen desde el próximo inicio de sesión. |
| Automático | `SysMain` | Compresión de memoria desde el arranque. |

Sin "todo a Manual": el *Set Services to Manual* de WinUtil (~190 servicios) rompió Windows Update
([#1098](https://github.com/ChrisTitusTech/winutil/issues/1098)), la hora
([#1412](https://github.com/ChrisTitusTech/winutil/issues/1412)) y el Bluetooth
([#2685](https://github.com/ChrisTitusTech/winutil/issues/2685), [#2877](https://github.com/ChrisTitusTech/winutil/issues/2877));
en abril de 2026 lo redujeron a 5. Quedan en Automático: audio, red (`Dhcp`, `Dnscache`, `NlaSvc`, Wi-Fi), Firewall,
Defender, registro de eventos, `Themes`, `FontCache`, notificaciones de usuario.

### 4. Tareas programadas

Desactivadas: *Microsoft Compatibility Appraiser* (`CompatTelRunner`, disco al 100%), *ProgramDataUpdater*,
*Autochk Proxy*, CEIP (*Consolidator*, *UsbCeip*), *DiskDiagnosticDataCollector*, Feedback (*DmClient*,
*DmClientOnScenarioDownload*), Mapas (*MapsUpdateTask*, *MapsToastTask*), WER *QueueReporting*, WinSAT,
*XblGameSaveTask*.

### 5. Defender

| Se mantiene | Se recorta |
|---|---|
| Tiempo real, comportamiento, nube, descargas y adjuntos | Análisis programados: prioridad baja, máx. 20% de CPU (fábrica 50%), solo en inactividad |
| Firmas (vía Windows Update) | Análisis de recuperación al arrancar: desactivados (fábrica) |
| SmartScreen, Firewall, Protección contra alteraciones | Notificaciones no críticas: ocultas |
| Ícono de la bandeja | MRT mensual (`DontOfferThroughWUAU`): redundante con el tiempo real |
| Bloqueo de PUA (nuevo) | |

Sin exclusiones.

### 6. Telemetría y procesos en segundo plano

| Ajuste | Estado |
|---|---|
| Telemetría | Mínimo permitido; sin encuestas ni ID de publicidad. |
| Contenido sugerido, instalaciones silenciosas, consejos, "terminá de configurar tu PC" | Apagado. |
| Noticias e intereses (`EnableFeeds`) | Apagado. |
| Cortana, Bing y destacados en la búsqueda | Apagado. |
| Barra de juegos y Game DVR | Apagado. |
| Historial de actividad | No se publica ni se sube. |
| Informe de errores (WER) | Apagado. |
| Apps en segundo plano | Interruptor general apagado (`GlobalUserDisabled=1`, `BackgroundAppGlobalToggle=0`). Contras: el Inicio puede tardar en encontrar apps nuevas de la Store ([PR #42](https://github.com/Disassembler0/Win10-Initial-Setup-Script/pull/42)); alarmas y avisos de apps cerradas no funcionan. No afecta programas Win32. |
| Actualización automática de la Store | Apagada: política `HKLM\SOFTWARE\Policies\Microsoft\WindowsStore` `AutoDownload=2` (más el valor del interruptor viejo). Desde 2025 la Store solo permite pausar 1-5 semanas ([Tom's Hardware](https://www.tomshardware.com/software/windows/microsoft-store-change-removes-the-ability-to-stop-app-updates-pausing-automatic-updates-now-limited-to-a-5-week-duration)); la política sigue vigente ([The Windows Club](https://www.thewindowsclub.com/disable-automatic-microsoft-store-updates)). Actualizar a mano: *Store > Biblioteca > Obtener actualizaciones* (incluye winget). |
| Precarga de apps (`ApplicationPreLaunch`) | Apagada. |
| WPBT y apps acompañantes de dispositivos | Apagado (WinUtil). |

### 7. Interfaz y Explorador

- Efectos visuales en "mejor rendimiento", excepto: contenido de ventana al arrastrar; suavizado de fuentes;
  animación al minimizar y maximizar, solo con driver de video. Con 4 GB y driver: "mejor apariencia" (ver
  [Perfiles](#perfiles-según-el-hardware)).
- Miniaturas siempre (`IconsOnly=0`), también en HDD: sin vista previa no se encuentran las fotos. Si una versión
  anterior las había apagado, vuelven.
- Sin transparencias, animaciones de menús y barra de tareas, Aero Peek ni desenfoque acrílico del inicio de sesión
  (`DisableAcrylicBackgroundOnLogon`), salvo en "mejor apariencia".
- `MenuShowDelay`: 400 a 100 ms.
- El Explorador abre en *Este equipo* (Acceso rápido calcula recientes en disco).
- Sin detección automática del tipo de carpeta (WinUtil). Efecto secundario: se reinician las vistas guardadas.
- **Luz nocturna programada del anochecer al amanecer.** Se escribe el blob `windows.data.bluelightreduction.settings`
  de CloudStore (Bond CompactBinary v1, sin documentar; formato según
  [win-nightlight-cli](https://github.com/kvnxiao/win-nightlight-cli/blob/main/docs/nightlight-registry-format.md)),
  en el mismo envoltorio que ya tenga el usuario. Conserva temperatura y horarios existentes; si no había, 4000 K.
  Con el *Adaptador de pantalla básico* Windows no la ofrece. La opción 6 la devuelve a fábrica.
- **Ubicación activada** para el equipo y el usuario (`ConsentStore\location` = `Allow`; se borran `DisableLocation` y
  `DisableLocationScripting`): la luz nocturna la necesita para calcular la puesta y la salida del sol. La opción 6
  no la apaga.

### 8. Memoria, disco y energía

- Compresión de memoria activada.
- Archivo de paginación: si alguien lo quitó, vuelve a administrarlo Windows. Después, fijo en 2 × RAM con tope de
  8 GB (2 GB: 4096 MB; 8 GB: 8192 MB). Sin espacio suficiente, queda como estaba.
- Caché de escritura activada y vaciado del búfer desactivado (`UserWriteCacheSetting=1`,
  `CacheIsPowerProtected=1`), salvo en SSD. Riesgo asumido: pérdida de datos ante un corte de luz.
- NTFS: `DisableLastAccess`, `Disable8dot3`.
- Restaurar sistema desactivado; se borran todos los puntos.

Energía, aplicada a Equilibrado, Alto rendimiento, Economizador y al plan activo:

| Ajuste | Valor | Motivo |
|---|---|---|
| Plan | Alto rendimiento, también en notebooks | Sin limitación de CPU. Menos autonomía. |
| Apagar disco | Nunca | Despertar un HDD tarda segundos. |
| Apagar pantalla | A los 15 min, con cargador y con batería | El mismo valor en todos los equipos. |
| Suspender | A las 4 h (1 h con 4 GB o más), con cargador y con batería | Margen para el mantenimiento automático. |
| Hibernar | Nunca | Hibernación desactivada. |
| Botón de encendido | Apagar | |
| Tapa | Apagar (suspender con 4 GB o más) | |
| Botón de suspensión | Nada | Panel de control no ofrece "Apagar" para ese botón. |
| Batería crítica | Apagar | Sin hibernación, apagar es la salida limpia. |
| Hibernación e inicio rápido | Desactivados | Borra `hiberfil.sys` (40% de la RAM). |
| Menú de apagado | Sin *Hibernar*; sin *Suspender* salvo con 4 GB o más | Se reactivan en *Opciones de energía > Elegir el comportamiento de los botones*. |

Inicio rápido: acelera el arranque en HDD, pero el kernel nunca se reinicia; con drivers viejos arrastra errores
(caso de `ntoskrnl.exe` al 10-15% de CPU: [HP Community](https://h30434.www3.hp.com/t5/Notebook-Boot-and-Lockup/Fast-startup-causing-high-cpu-usage/td-p/7888113)).
Sin él, *Apagar* es un apagado completo.

### 9. Navegadores

- Edge: sin arranque acelerado, sin modo de fondo, sin barra lateral ni Edge bar, sin recomendaciones ni compras;
  pestañas en suspensión a los 5 min (fábrica: 2 h).
- Chrome: sin modo de fondo.
- Ambos muestran "Administrado por tu organización" (políticas).

### 10. Preguntas

| Pregunta | Sí | No |
|---|---|---|
| OneDrive | Sin cambios | Fuera del inicio (no se desinstala) |
| Quitar apps | Ver abajo; además se deshabilitan sus servicios de sincronización | Sin cambios |

Apps quitadas (todos los usuarios): Xbox, Solitario, Candy Crush, Noticias, Skype, Enlace Móvil (`Microsoft.YourPhone`),
Obtener ayuda (`Microsoft.GetHelp`), Sugerencias (`Microsoft.Getstarted`), Contactos, Mapas, Correo y Calendario,
Outlook nuevo, OneNote para Win10, Notas rápidas, Alarmas, Groove, Películas y TV, Paint 3D, Visor 3D, Portal de
realidad mixta, Centro de comentarios, To Do, Cortana, Copilot. Quedan: Store, Calculadora, Cámara, Grabadora de
sonidos, Clima, Recortes y anotación. Se reinstalan desde la Store.

Sin preguntar: [clásicos de Windows 7](#clásicos-de-windows-7), características opcionales y Restaurar sistema
desactivado.

### 11. Características opcionales

*Configuración > Aplicaciones > Características opcionales*, vía `Remove-WindowsCapability`:

| Característica | Capability | Acción |
|---|---|---|
| Grabación de acciones de usuario | `App.StepsRecorder` | Quitar |
| Reconocedor matemático | `MathRecognizer` | Quitar |
| WordPad | `Microsoft.Windows.WordPad` | Quitar |
| Reproductor de Windows Media | `Media.WindowsMediaPlayer` | Quitar (VLC, opción 4) |
| Internet Explorer 11 | `Browser.InternetExplorer` | Quitar (el modo IE de Edge puede dejar de funcionar) |
| Asistencia rápida integrada | `App.Support.QuickAssist` | Quitar (reemplazada por la versión de la Store) |
| Cliente OpenSSH | `OpenSSH.Client` | Quitar |
| Windows Hello: reconocimiento facial | `Hello.Face.*` | Quitar: requiere cámara IR. PIN y huella no dependen de esto. |
| Visor de XPS | `XPS.Viewer` | Quitar, si está |
| Paint, Bloc de notas, PowerShell ISE, Fax y Escáner, Administración de impresión | | Se conservan |
| Idiomas (`Language.*`) y demás | | No se tocan |

No consumen RAM ni CPU en reposo: la ganancia es espacio en disco. La primera ejecución tarda varios minutos (DISM).
Reinstalar: *Características opcionales > Agregar una característica*.

### 12. Limpieza de temporales

| Carpeta | Contenido |
|---|---|
| `C:\Windows\Temp` | Temporales del sistema. |
| `%TEMP%` de cada usuario | Incluye la cuenta que elevó el script. |
| Temp de `SYSTEM` (32/64 bits), `LocalService`, `NetworkService` | Servicios e instaladores. |
| `C:\Windows\SystemTemp` | Temp de los procesos del sistema desde 2024 (`GetTempPath2`). Se vacía el contenido; la carpeta y sus permisos quedan ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/3922760/files-in-c-windows-systemtemp)). |
| `INetCache` de cada usuario y de `SYSTEM`, `LocalService`, `NetworkService` | Archivos temporales de Internet (WinINet: Office, componentes de Windows). `INetCookies` no se toca. |
| `CrashDumps`, `D3DSCache`, caché de Escritorio remoto de cada usuario | Volcados de programas colgados y cachés que se regeneran. |
| `Program Files [(x86)]\Microsoft\Temp`, `Microsoft\Edge\Temp`, `Google\Temp` | Restos de los instaladores de Edge y de Google ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/4134915/what-is-c-program-files-x86-microsofttemp-it-is-ta)). |
| `System32\DriverStore\Temp` | Temporales de instalación de drivers. `FileRepository` no se toca. |
| WER de sistema y de usuarios | Informes de errores. |
| `MEMORY.DMP`, `Minidump`, `LiveKernelReports` | Volcados; el primero puede pesar como la RAM. |
| `C:\Windows\Logs\CBS\CbsPersist_*` | Registros viejos de CBS (el actual no se toca). |
| Caché de Delivery Optimization | Actualizaciones ya instaladas. |
| `C:\Windows\Prefetch\*.pf` | Solo las de programas que no se abren hace más de 30 días (ver abajo). |
| Caché y descargas de Adobe Reader | Si está instalado. |
| Caché de Chrome y Edge, todos los usuarios y perfiles | `Cache`, `Code Cache`, `GPUCache`, `Media Cache`, `Dawn*Cache`; en la raíz, `ShaderCache`, `GrShaderCache`, `GraphiteDawnCache`. No se tocan cookies, contraseñas, autocompletar, historial, favoritos ni datos de sitios (Local Storage, IndexedDB, Service Workers): las sesiones siguen abiertas. Antes se cierran ambos navegadores como con la X. |

Lo bloqueado se saltea y se cuenta, separando "en uso" de "sin permiso". Al final muestra lo liberado por carpeta. Salvaguardas: no sigue junctions ni
symlinks, no vacía raíces protegidas (`C:\Windows`, perfiles) y saltea la carpeta del script.

Prefetch: vaciarlo entero agrega 4-15 s al arranque siguiente
([Microsoft](https://learn.microsoft.com/en-us/archive/blogs/ryanmy/misinformation-and-the-the-prefetch-flag),
[Ed Bott](https://edbott.com/2005/06/01/one-more-time-do-not-clean-out-your-prefetch-folder/)). Por eso se borran
solo las entradas de programas que no se abren hace más de 30 días: Windows reescribe el `.pf` de un programa cada
vez que arranca, así que su fecha es la última vez que se usó. Se van las de programas abandonados; las de lo que se
usa a diario se quedan y siguen acelerando su arranque. Se conservan siempre `NTOSBOOT-B00DFAAD.pf`, `Layout.ini`,
`ReadyBoot` y `Ag*.db`.

Papelera: no se vacía, pero se activa el *Sensor de almacenamiento* para borrar lo que tenga más de 30 días
(`StoragePolicy`: `01=1`, `08=1`, `256=30`, revisión semanal `2048=7`). También borra temporales que las apps no usan
(`04=1`). Descargas nunca (`32=0`). Valores según
[TenForums](https://www.tenforums.com/tutorials/122318-enable-disable-storage-sense-windows-10-a.html) y
[Stealthpuppy](https://stealthpuppy.com/windows-10-storage-sense-intune/).

No se tocan: caché de miniaturas, `SoftwareDistribution\Download`, `System32\spool\PRINTERS` (trabajos de impresión) y
`WinSxS\Temp` / `WinSxS\InstallTemp`: guardan operaciones pendientes de reinicio (`PendingRenames`, `PendingDeletes`);
borrarlas puede dejar una actualización a medias, y son de `TrustedInstaller`. Las limpia DISM (opción 2). `Windows.old`: *Liberador de espacio en
disco > Limpiar archivos del sistema*.

### 13. Adobe Reader (si está instalado)

| Elemento | Acción |
|---|---|
| Inicio | Quita *Adobe ARM*, *Speed Launcher* (`reader_sl.exe`) y *Acrobat Assistant* (`acrotray.exe`), también de `RunOnce`. |
| *Adobe Acrobat Update Task* | Desactivada. |
| `AdobeARMservice` | Detenido y deshabilitado. |
| `AppData\LocalLow\Adobe\AcroCef\DC\Acrobat\Cache` | Vaciada en cada usuario. |
| `C:\ProgramData\Adobe\ARM` | Vaciada (instaladores acumulados). |

Reader deja de recibir parches: asignar `.pdf` a Edge o Chrome, o desinstalarlo. Solo los formularios XFA lo requieren.

Al final: estado de Defender, programas de inicio y reinicio.

## Opción 4: Chrome, WinRAR y VLC

Orden: WinRAR, VLC, Chrome.

```
winget install --id <ID> -e --source winget --silent --accept-package-agreements --accept-source-agreements
```

- IDs exactos (`RARLab.WinRAR`, `VideoLAN.VLC`, `Google.Chrome`) con `-e`: un nombre suelto puede ser ambiguo.
- `--source winget`: evita la fuente `msstore` y su aceptación aparte.
- Si ya está instalado y winget no conoce la versión: `winget upgrade --include-unknown` (opción exclusiva de
  `upgrade`).
- Sin winget: lo registra para la cuenta; si no está, abre la Store en *Instalador de aplicación*.
- WinRAR queda en inglés (único idioma del paquete).

uBlock Origin Lite (`ddkjiahejlhfcafbddmgiahcphecmpfh`) se fuerza con la política
[`ExtensionInstallForcelist`](https://chromeenterprise.google/policies/extension-install-forcelist/) antes de instalar
Chrome. No se puede quitar desde Chrome; se quita borrando su valor en
`HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist`.

## Opción 5: Chrome de aula

Para PCs compartidas (colegio), donde quedan cuentas y sesiones abiertas. Pide confirmación (`S`).

1. Cierra Chrome en todas las sesiones de Windows (`Stop-Process -Force`).
2. Borra `AppData\Local\Google\Chrome\User Data` en cada usuario de Windows: todos los perfiles, con sus cuentas,
   cookies, contraseñas, historial y favoritos. Se usa `rd /s /q`, que no sigue junctions.
3. Crea `User Data\First Run` vacío: Chrome arranca sin la pantalla de primer uso.
4. Políticas en `HKLM\SOFTWARE\Policies\Google\Chrome`:

| Política | Valor | Efecto |
|---|---|---|
| [`BrowserSignin`](https://chromeenterprise.google/policies/browser-signin/) | `0` | No se puede iniciar sesión en Chrome. En los sitios web (Gmail, etc.) sí. |
| `BrowserAddPersonEnabled` | `0` | No se pueden crear perfiles nuevos. |
| `PromotionalTabsEnabled` | `0` | Sin pestañas de bienvenida ni promociones. |
| `PrivacySandboxPromptEnabled` | `0` | Sin el aviso de privacidad de anuncios. |
| `DefaultBrowserSettingEnabled` | `0` | No pregunta si es el navegador predeterminado. |
| `ExtensionInstallForcelist` | uBlock Origin Lite | Se instala sola al abrir Chrome (con internet). |

Resultado: Chrome abre directo en una pestaña nueva, sin perfiles ni cuentas. La opción 6 quita estas políticas
(salvo uBlock); la opción 7 muestra `BrowserSignin`.

## Clásicos de Windows 7

| Clásico | Acción |
|---|---|
| Visualizador de fotos | Se reasocia a JPG (`.jpg`, `.jpeg`, `.jpe`, `.jfif`), PNG, GIF y BMP con nombre e ícono originales, y se registra para WebP, HEIC/HEIF y AVIF. Aparece en *Abrir con* y *Aplicaciones predeterminadas*. Se desinstala la app Fotos. |
| Alt+Tab clásico | Íconos en lugar de miniaturas en vivo. Con 4 GB y driver de video queda el moderno. |

Paso manual: *Aplicaciones predeterminadas > Visor de fotos > Visualizador de fotos de Windows* (Windows 10 no permite
fijarlo por script). Paint, Bloc de notas y la Herramienta Recortes clásica se conservan.

Los formatos nuevos se decodifican con los códecs WIC de las extensiones de la Store
([How-To Geek](https://www.howtogeek.com/345504/how-to-open-heic-files-on-windows-or-convert-them-to-jpeg/)); la opción 7
muestra cuáles están instaladas:

| Formato | Extensiones necesarias |
|---|---|
| WebP | *Extensiones de imagen WebP* (incluida en Windows 10). |
| HEIC/HEIF | *Extensiones de imagen HEIF* (gratis) y *Extensiones de vídeo HEVC* (paga; existe una versión gratuita "del fabricante del dispositivo"). En Atom se decodifica por software: segundos por foto. |
| AVIF | *Extensión de vídeo AV1* (gratis). |

Alternativa para fotos de iPhone: *Ajustes > Fotos > Transferir a Mac o PC > Automático* (llegan como JPG).

Descartados: calculadora de Windows 7 (no incluida en Windows 10) y flyouts clásicos de batería, reloj y volumen
(sin evidencia de que funcionen en 22H2).

## Netbooks Conectar Igualdad

| Gen. | CPU | RAM | Video | Driver en Windows 10 |
|---|---|---|---|---|
| G1 | Atom N450 | 1 GB DDR2 | GMA 3150 | Windows Update |
| G2 | Atom N455 | 1 GB DDR3 | GMA 3150 | Windows Update |
| G3/G4 | Atom N2600 | 2 GB DDR3 | GMA 3600 | **No existe** (32 ni 64 bits) |
| G5 | Celeron N2806/N2807 | 2 GB | Intel HD | Sí |

- GMA 3600 sin driver: *Adaptador de pantalla básico*, todo por CPU. El driver de Windows 7 funciona en muchas
  (mejor en 32 bits) pero hay casos de `VIDEO_TDR_FAILURE`. Combinado con inicio rápido, peor: por eso se desactiva.
- RAM: 2 GB es el máximo del Atom. G1/G2 con 1 GB: ampliar es la mejora más barata.
- 32 bits con 2 GB: ~10% menos RAM y ~3,5 GB menos de disco. Requiere reinstalar.
- Antirrobo (*Theft Deterrent Agent*): si la netbook no está liberada, no quitar el agente. El script no lo toca;
  lo detecta, avisa y lo marca en la lista de inicio.
- Sin driver de video y sin necesidad de Windows: Linux liviano (Lubuntu, Linux Mint XFCE).

## Opción 3: desfragmentación completa

La pasada automática ignora fragmentos de más de 64 MB y no consolida el espacio libre
([Microsoft](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921)).
La opción 3 usa [`defrag`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/defrag)
con prioridad normal (`/H`) y progreso (`/U`):

| Paso | Parámetro | Acción |
|---|---|---|
| 1 | `/A /V` | Análisis. |
| 2 | `/W` (o `/D` si no se acepta) | Desfragmentación completa, incluidos fragmentos > 64 MB. |
| 3 | `/X` | Consolidación del espacio libre. |
| 4 | `/B` | Optimización del arranque (`Layout.ini`). |
| 5 | `/A /V` | Análisis final. |

En SSD solo envía TRIM. Avisa si hay menos de 15% libre. No mueve archivos en uso (paginación, partes de la MFT):
para eso, desfragmentación en el arranque con [UltraDefrag](https://en.wikipedia.org/wiki/UltraDefrag) (7.1.4, última
versión libre).

## Opción 2: limpieza de WinSxS

`Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase`
([Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder)).
Pide confirmación antes de empezar: el menú responde a una tecla y esta opción está pegada a la 1.

- Borra las versiones reemplazadas de los componentes ya, sin esperar los 30 días de la tarea automática.
- `/ResetBase`: las actualizaciones instaladas pasan a ser la base y **no se pueden desinstalar**. Las siguientes sí.
- Windows 10 trae `DisableResetbase=1` en `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SideBySide\Configuration`:
  con ese valor, `/ResetBase` se ignora y solo se comprime. Durante la limpieza se usan `DisableResetbase=0` y
  `SupersededActions=3` (1 antes de 1903), los valores de [W10UI](https://github.com/abbodi1406/BatUtil/tree/master/W10UI)
  de abbodi1406; al terminar se restauran los originales. Se detienen `wuauserv` y `TrustedInstaller` para que tome
  la configuración. Valores sin documentación de Microsoft.
- Si existe `WinSxS\pending.xml` (cambios esperando reinicio), no ejecuta DISM y pide reiniciar.
- Una segunda pasada es rápida: ya no queda qué borrar.
- Libera espacio; no acelera. En Atom con HDD, hasta 1 h con el disco al 100%.
- Error `0x800F0806`: hay una operación pendiente de reinicio
  ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/2192270/dism-startcomponentcleanup-give-error-0x800f0806-t)).
- `/SPSuperseded` no se usa: es para Service Packs, que Windows 10 no tiene.

Mantenimiento periódico: opción 2 y luego 3.

## Caché de disco y optimizaciones de Windows

| Mecanismo | Función | Estado |
|---|---|---|
| Prefetch | Lee en bloque lo que un programa usó la vez anterior. | Activo (solo actúa al abrir programas). |
| ReadyBoot | Precarga los archivos de arranque. | Activo (solo en el arranque). |
| Compresión de memoria (SysMain) | Comprime en RAM en vez de paginar. | Activa: la más importante con 2 GB. |
| SuperFetch (SysMain) | Llena la RAM libre con programas frecuentes. | Activo (mismo servicio); con 2 GB casi no actúa. |
| PreLaunch | Precarga apps de la Store. | Apagado. |
| Inicio rápido | Hiberna el kernel al apagar. | Apagado. |
| Indexador | Indexa leyendo el disco. | Apagado. |
| ReadyBoost | Caché de lecturas en flash. | Manual, opcional (ver abajo). |

La caché de archivos ya usa toda la RAM libre. Tweaks evaluados:

| Tweak | Veredicto |
|---|---|
| `LargeSystemCache=1` | No: prioriza caché sobre programas; pensado para servidores ([TweakHound](https://www.tweakhound.com/2011/09/20/bad-tweaks/)). |
| `fsutil behavior set memoryusage 2` | No: solo útil con memoria de sobra ([Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior)). |
| `fsutil behavior set mftzone` | No: útil solo con muchísimos archivos chicos. |
| `IoPageLockLimit` | Ignorado por Windows. |
| Caché de escritura | Sí (fábrica; se asegura). |
| Sin vaciado del búfer de escritura | Sí, por decisión: menos espera por escritura a cambio de riesgo ante cortes de luz ([Raymond Chen](https://devblogs.microsoft.com/oldnewthing/20130416-00/?p=4643)). No en SSD; la opción 6 lo revierte. |
| Paginación fija en 2 × RAM, tope 8 GB | Sí: el tamaño automático crece en caliente, provoca fallos de asignación en discos lentos ([Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/slow-page-file-growth-memory-allocation-errors)) y fragmenta. Supera el 1,5 × RAM que Microsoft usa como mínimo. |

**ReadyBoost.** Caché de lecturas chicas y dispersas en flash, justo lo que peor hace un HDD
([Wikipedia](https://en.wikipedia.org/wiki/ReadyBoost), [Microsoft](https://learn.microsoft.com/en-us/archive/blogs/tomarcher/readyboost-qa)).
Ayuda con 1 GB o menos; con 2 GB la diferencia medida va de +2% a -1%
([Digital Citizen](https://www.digitalcitizen.life/does-readyboost-work-does-it-improve-performance-slower-pcs/),
[How-To Geek](https://www.howtogeek.com/123780/htg-explains-is-readyboost-worth-using/)). Cifra todo y estos Atom no
tienen [AES-NI](https://en.wikipedia.org/wiki/AES_instruction_set). No se automatiza. Prueba: tarjeta SD clase 10/A1
de 4-16 GB, *Propiedades > ReadyBoost > Dedicar este dispositivo*; si en una semana no hay diferencia, quitarla.

**Fragmentación, en orden de impacto:** desfragmentación semanal (activa) y opción 3; 15% libre como mínimo; paginación
fija; revisar *Load/Unload Cycle Count* con [CrystalDiskInfo](https://crystalmark.info/en/software/crystaldiskinfo/)
(si sube miles por día, el cabezal se estaciona; APM 254 corrige, pero requiere un programa residente:
[detalle](https://commonemitter.blogspot.com/2019/09/disabling-hdd-apm.html)); SSD.

## Descartado

| Tweak | Motivo |
|---|---|
| Deshabilitar `SysMain` | Elimina la compresión de memoria. |
| `DisablePagingExecutive`, `LargeSystemCache` | Con poca RAM, quitan memoria a los programas. |
| `IOPageLockLimit`, `DontVerifyRandomDrivers` | Ignorados por Windows. |
| `SvcHostSplitThresholdInKB` | Con menos de 3,5 GB, Windows ya agrupa los `svchost`. |
| `Win32PrioritySeparation=0x26` | Equivale al valor de fábrica en escritorio. |
| `NetworkThrottlingIndex`, `SystemResponsiveness` | Tweaks de gaming; sin efecto aquí. |
| `StartupDelayInMSec=0` | Todos los programas de inicio a la vez: peor en HDD. |
| Sin archivo de paginación | Cuelgues con 2 GB. |
| Deshabilitar la desfragmentación | Necesaria en HDD. |
| Limpiadores de RAM | Fuerzan relecturas del disco. |
| Vaciar Prefetch entero | Arranques más lentos. |
| `Dism /SPSuperseded` | Solo Service Packs. |
| `msconfig`: procesadores y memoria máxima | Solo limitan. |
| Deshabilitar Windows Update o Defender | Inseguro; la Protección contra alteraciones lo revierte. |
| Deshabilitar `TabletInputService` | Rompe la escritura en Inicio, Configuración y UWP. |
| Deshabilitar `DoSvc` | Puede romper Windows Update; se usa `DODownloadMode=0`. |
| *Set Services to Manual* masivo | Rompió Windows Update, la hora y el Bluetooth en WinUtil. |
| Desactivar mitigaciones Spectre/Meltdown | Expone el equipo. |
| Desinstalar OneDrive o Edge | Rompe más de lo que arregla; Edge y WebView2 los usan otras apps. |
| Idiomas de *Características opcionales* | Pueden romper la configuración regional y Windows los reinstala. |

## Límites de software

1. SSD: la mejora más grande, incluso un SATA de 120 GB.
2. RAM: de 2 a 4 GB (DDR3 usada) cuando la placa lo admite.
3. Pocas pestañas abiertas.
4. Parches: ESU gratuito hasta el **12/10/2027**, previa inscripción en *Configuración > Windows Update*
   ([BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-quietly-extends-free-windows-10-esu-support-to-october-2027/),
   [Help Net Security](https://www.helpnetsecurity.com/2026/06/26/microsoft-windows-10-free-security-updates-esu-program/)).
   Después: Linux liviano.

## Validación

- **Wine (`cmd.exe`):** las 7 opciones de punta a punta con distintas combinaciones de respuestas; estado del v1
  simulado (incluidas políticas que apagan Defender y Windows Update), con verificación en el registro de cada valor en
  `HKEY_USERS\<SID>`; ciclo optimizar, revertir y verificar; opción 4 con winget simulado (instalación nueva, al día,
  actualizado, sin winget). Con el estado del v1, la opción 1 repara los 5 valores y en la pasada siguiente informa
  que no hay nada; en la opción 2, DISM corre con `DisableResetbase=0` y `SupersededActions=3`, y después vuelven los
  valores originales. Perfiles: la opción 1 corrió como PC de 2 GB con HDD y sin driver, y como PC de 8 GB con SSD y
  driver; en cada caso se verificaron los servicios, los efectos visuales, las miniaturas, el menú de apagado y los
  valores de `powercfg` (suspensión, tapa y botones).
- **VM con Windows 11 (UTM, ARM):** la versión anterior del script y la actual corrieron, cada una desde el mismo
  disco, las opciones 6, 1, 7, 5 y 6 con respuestas fijas. Después de cada paso se guardó el estado de Windows:
  registro que toca el script, servicios, tareas, planes de energía, Defender, compresión de memoria, paginación, apps
  y características. Después de la opción 1 el estado es idéntico, y la opción 1 abre PowerShell 8 veces en lugar de
  18 (contado con `Win32_ProcessStartTrace`). Con la versión anterior, la opción 6 dejaba apagada la precarga de
  apps (`ApplicationPreLaunch`); con la actual vuelve a fábrica. La VM ya venía optimizada: no quedaban apps ni
  características que quitar, y con SSD la caché de escritura se saltea.
- **PowerShell:** las secciones de las opciones 1, 5, 6 y 7 corren en la VM; los bloques de las opciones 2, 3 y 4
  pasan el parser oficial. La quita de características opcionales se ejecutó contra una lista simulada de 22H2.
- **Luz nocturna:** los blobs generados se decodificaron con un parser Bond independiente, partiendo de la referencia
  de win-nightlight-cli (envoltorio Bond), de un blob de Windows 10 (envoltorio viejo) y de ninguno. Con el blob
  viejo, el resultado coincide byte a byte con el *AutoOn* de Windows 10, salvo el FILETIME.
- **Limpieza:** ejecutada sobre un árbol simulado con junctions, solo lectura, archivos bloqueados, la carpeta del
  script, un intento de vaciar `C:\Windows` y una Prefetch de prueba. Caché de navegadores: con perfiles simulados de
  Chrome y Edge se vacían solo las cachés; cookies, `Login Data`, `Web Data`, historial, favoritos, Local Storage,
  IndexedDB y Service Workers quedan intactos.
- **Chrome de aula:** con dos usuarios simulados (uno con tres perfiles, otro sin Chrome) queda solo `First Run`;
  también se probaron "sin Chrome" y "archivos en uso". En Wine, las cinco políticas quedan escritas.
- **Netbook simulada:** G4 (N2600, 1 GB, sin driver, con antirrobo): tres avisos. Visualizador de fotos verificado
  contra el `.reg` de referencia.
- **Formato:** ASCII y CRLF.
- **Menú:** [`pruebas/menu.py`](pruebas/menu.py) compara el menú en pantalla, la cabecera del script, el despacho
  de `choice` y la tabla de este README. Corre en la Action antes de publicar: si no coinciden, la release no se toca.
- **Secciones:** [`pruebas/secciones.py`](pruebas/secciones.py) comprueba que cada `call :ps` tenga su sección de
  PowerShell y que cada marcador aparezca una sola vez: un nombre mal escrito saltearía el paso sin avisar. También
  corre antes de publicar.

Sin probar en Windows real: la caché de escritura en un disco mecánico, la quita de apps y características
opcionales cuando todavía están, y las opciones 2, 3 y 4.

## Prueba en VM (UTM)

1. VM Windows 10 x64 22H2, 2 GB de RAM, 2 núcleos, actualizada.
2. Opción 7; guardar el reporte. Snapshot.
3. (Opcional) Script v1 y opción 7; luego la opción 1 tiene que mostrar `[REPARADO]` en el paso 2.
4. Volver al snapshot, opción 1, reiniciar, opción 7.
5. Checklist:
   - [ ] Búsqueda del Inicio encuentra apps ("calc").
   - [ ] Escritura en Configuración y en Calculadora.
   - [ ] Windows Update busca actualizaciones.
   - [ ] La Store abre y descarga.
   - [ ] *Seguridad de Windows*: tiempo real activo y firmas al día.
   - [ ] Sonido, red, hora, portapapeles.
   - [ ] Edge navega.
   - [ ] JPG con Visualizador de fotos (tras elegirlo); Alt+Tab con íconos.
   - [ ] `.webp` abre con el Visualizador; `.heic` también, con HEIF y HEVC instaladas.
   - [ ] Resumen de limpieza por carpeta.
   - [ ] Prefetch conserva `Layout.ini`, `NTOSBOOT-B00DFAAD.pf`, `ReadyBoot`.
   - [ ] Win+Shift+S funciona.
   - [ ] Ventana visible al arrastrar; carpetas de fotos con íconos.
   - [ ] Adobe Reader: fuera del inicio; *Adobe Acrobat Update Service* deshabilitado.
   - [ ] Opción 2 pide confirmación, termina y muestra lo liberado; `DisableResetbase` queda como estaba.
   - [ ] Menú de apagado sin *Hibernar*; *Suspender* solo con 4 GB o más.
   - [ ] Opción 7: la línea "Perfil opción 1" coincide con la RAM, el video y el disco de la PC.
   - [ ] Botón de encendido apaga (en UTM: apagado normal de la VM). Tapa: en la netbook real.
   - [ ] *Protección del sistema*: desactivada.
   - [ ] Opción 7: paginación 2 × RAM (tope 8 GB), caché de escritura activa, vaciado desactivado.
   - [ ] Menú responde a una tecla; otras teclas se ignoran.
   - [ ] Apps en segundo plano: interruptor general apagado.
   - [ ] Store: actualizaciones automáticas apagadas y administradas; *Obtener actualizaciones* funciona.
   - [ ] *Características opcionales*: quedan Paint, Bloc de notas, PowerShell ISE e idiomas.
   - [ ] *Pantalla > Configuración de luz nocturna*: programada, *Del atardecer al amanecer*. Opción 7: "del anochecer
     al amanecer" y ubicación `Allow / Allow`.
   - [ ] Opción 4: WinRAR, VLC y Chrome sin preguntas; uBlock Origin Lite en Chrome.
   - [ ] Tras la opción 1, Chrome y Edge siguen con las sesiones abiertas y las contraseñas guardadas.
   - [ ] *Configuración > Sistema > Almacenamiento*: Sensor activado, Papelera a 30 días, Descargas en "Nunca".
   - [ ] Opción 5: Chrome abre sin perfiles, sin pedir iniciar sesión, con uBlock Origin Lite.
6. Opción 6 y verificar la vuelta a fábrica.

## Fuentes

- **WinUtil (Chris Titus Tech):** [repositorio](https://github.com/ChrisTitusTech/winutil), `config/tweaks.json`;
  recorte de servicios (commit `87a5779`, 21/04/2026); issues
  [#1098](https://github.com/ChrisTitusTech/winutil/issues/1098), [#1412](https://github.com/ChrisTitusTech/winutil/issues/1412),
  [#2685](https://github.com/ChrisTitusTech/winutil/issues/2685), [#2877](https://github.com/ChrisTitusTech/winutil/issues/2877).
- **Black Viper (servicios de Windows 10):** [BlackViperScript](https://github.com/madbomb122/BlackViperScript) (`BlackViper.csv`).
- **Win10-Initial-Setup-Script (Disassembler0):** [repositorio](https://github.com/Disassembler0/Win10-Initial-Setup-Script)
  (incluye los nombres de capabilities), [PR #42](https://github.com/Disassembler0/Win10-Initial-Setup-Script/pull/42).
- **SysMain y compresión de memoria:** [WOSHub](https://woshub.com/memory-compression-process-high-usage-windows-10/), [ElevenForum](https://www.elevenforum.com/t/what-service-is-responsible-for-memory-compression.2953/), [TenForums](https://www.tenforums.com/tutorials/99821-enable-disable-superfetch-sysmain-windows.html).
- **IOPageLockLimit:** [MSFN, "Registry Myths #1"](https://msfn.org/board/topic/25684-registry-myths-1-iopagelocklimit/).
- **DontVerifyRandomDrivers:** [NTLite](https://ntlite.com/community/threads/are-the-listed-registry-settings-relevant.3221/).
- **DisablePagingExecutive:** [How-To Geek](https://www.howtogeek.com/173648/10-windows-tweaking-myths-debunked/).
- **DoSvc:** [privacy.sexy #223](https://github.com/undergroundwires/privacy.sexy/issues/223).
- **TabletInputService:** [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/1321908/not-possible-to-disable-the-service-tabletinputser), [WindowsForum](https://windowsforum.com/threads/how-to-fix-touch-input-by-re-enabling-tabletinputservice-in-windows-11.386273/).
- **Búsqueda sin Windows Search (20H2+):** [Winaero](https://winaero.com/how-to-search-in-windows-10-start-menu-with-search-box-disabled/).
- **`DisableSearchBoxSuggestions`:** [BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/windows-10-ignores-method-to-disable-bing-in-start-menu-fix-found/).
- **`EnableFeeds`:** [TenForums](https://www.tenforums.com/tutorials/178178-how-enable-disable-news-interests-taskbar-windows-10-a.html).
- **Store:** fin del apagado permanente ([Tom's Hardware](https://www.tomshardware.com/software/windows/microsoft-store-change-removes-the-ability-to-stop-app-updates-pausing-automatic-updates-now-limited-to-a-5-week-duration)), política `AutoDownload` ([The Windows Club](https://www.thewindowsclub.com/disable-automatic-microsoft-store-updates)).
- **Edge:** [BackgroundModeEnabled](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled), [SleepingTabsTimeout](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/sleepingtabstimeout).
- **Defender:** CPU de análisis ([TenForums](https://www.tenforums.com/tutorials/142728-set-windows-defender-antivirus-max-cpu-usage-scan-windows-10-a.html)),
  análisis de recuperación ([Microsoft Learn](https://learn.microsoft.com/en-us/defender-endpoint/schedule-antivirus-scans-powershell)),
  notificaciones ([Microsoft Learn](https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/windows-defender-security-center/wdsc-hide-notifications)),
  Protección contra alteraciones ([Cloudbrothers](https://cloudbrothers.info/en/current-limits-defender-av-tamper-protection/)).
- **WpnService:** [batcmd](https://batcmd.com/windows/10/services/wpnservice/).
- **CompactOS en HDD:** [TenForums](https://www.tenforums.com/performance-maintenance/131696-compression-os-experiment.html).
- **Prefetch:** [Ryan Myers, Microsoft](https://learn.microsoft.com/en-us/archive/blogs/ryanmy/misinformation-and-the-the-prefetch-flag), [Ed Bott](https://edbott.com/2005/06/01/one-more-time-do-not-clean-out-your-prefetch-folder/), [Prefetcher](https://en.wikipedia.org/wiki/Prefetcher), [ReadyBoot y SuperFetch](https://en.wikipedia.org/wiki/Windows_Vista_I/O_technologies).
- **Inicio rápido:** [Winbuzzer](https://winbuzzer.com/2020/05/19/how-to-disable-windows-10-fast-startup-hiberboot-hybrid-boot-hybrid-shutdown-xcxwbt/), [HP Community](https://h30434.www3.hp.com/t5/Notebook-Boot-and-Lockup/Fast-startup-causing-high-cpu-usage/td-p/7888113).
- **Energía:** [botones y tapa](https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings),
  [batería crítica](https://learn.microsoft.com/en-us/answers/questions/823581/powercfg-command-line-for-editing-the-existing-val) (0 nada, 1 suspender, 2 hibernar, 3 apagar),
  [`powercfg`](https://learn.microsoft.com/windows-hardware/design/device-experiences/powercfg-command-line-options),
  [`hiberfil.sys`](https://www.elevenforum.com/t/specify-hibernation-file-type-as-full-or-reduced-in-windows-11.1955/),
  [`FlyoutMenuSettings`](https://www.tenforums.com/tutorials/7456-add-remove-sleep-power-menu-windows-10-a.html).
- **Adobe Reader:** [Techdows](https://techdows.com/2014/06/how-to-disable-or-stop-armsvc-exe-of-adobe-reader.html),
  [gHacks](https://www.ghacks.net/2010/04/09/adobearm-exe-and-reader_sl-exe/),
  [Dell Community (RunOnce)](https://www.dell.com/community/en/conversations/virus-spyware/adobe-reader-11010-update-adds-run-once-entry-for-speed-launcher/647f4d26f4ccf8a8de5e0bee?commentId=647f4d60f4ccf8a8de61d495&page=2),
  [Adobe Community (ARM)](https://community.adobe.com/t5/acrobat-discussions/multiple-acrordrdcupd-msi-files-taking-up-space/td-p/13858757),
  [Adobe Community (AcroCef)](https://community.adobe.com/t5/acrobat-discussions/when-open-a-pdf-file-a-file-created-quot-debug-log-quot/m-p/12466171).
- **WinSxS:** [Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder),
  [`/SPSuperseded`](https://learn.microsoft.com/en-us/archive/blogs/joscon/how-to-reclaim-space-after-applying-windows-72008-r2-service-pack-1),
  [`0x800F0806`](https://learn.microsoft.com/en-us/answers/questions/2192270/dism-startcomponentcleanup-give-error-0x800f0806-t).
- **Caché y paginación:** [crecimiento de la paginación](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/slow-page-file-growth-memory-allocation-errors),
  [tamaños](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/how-to-determine-the-appropriate-page-file-size-for-64-bit-versions-of-windows),
  [fragmentación](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921),
  [`fsutil behavior`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior),
  [vaciado del búfer](https://devblogs.microsoft.com/oldnewthing/20130416-00/?p=4643),
  [`Get-StorageAdvancedProperty`](https://learn.microsoft.com/en-us/powershell/module/storage/get-storageadvancedproperty),
  [`LargeSystemCache`](https://www.tweakhound.com/2011/09/20/bad-tweaks/).
- **ReadyBoost:** [Wikipedia](https://en.wikipedia.org/wiki/ReadyBoost), [Microsoft](https://learn.microsoft.com/en-us/archive/blogs/tomarcher/readyboost-qa),
  [Digital Citizen](https://www.digitalcitizen.life/does-readyboost-work-does-it-improve-performance-slower-pcs/), [How-To Geek](https://www.howtogeek.com/123780/htg-explains-is-readyboost-worth-using/), [APM](https://commonemitter.blogspot.com/2019/09/disabling-hdd-apm.html).
- **winget:** [`install`](https://learn.microsoft.com/en-us/windows/package-manager/winget/install), [`upgrade`](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade),
  [códigos de salida](https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md),
  [`ExtensionInstallForcelist`](https://chromeenterprise.google/policies/extension-install-forcelist/).
- **Restaurar sistema:** [TenForums](https://www.tenforums.com/tutorials/99782-enable-disable-system-restore-windows-3.html).
- **Luz nocturna:** formato en [win-nightlight-cli](https://github.com/kvnxiao/win-nightlight-cli/blob/main/docs/nightlight-registry-format.md);
  blobs de Windows 10 en [Set-BlueLight (Jaap Brasser)](https://github.com/jaapbrasser/SharedScripts/tree/master/Set-BlueLight).
  Ubicación: `EnableLocation` de [Win10-Initial-Setup-Script](https://github.com/Disassembler0/Win10-Initial-Setup-Script).
- **Desfragmentador:** [64 MB](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921), [`defrag`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/defrag), [UltraDefrag](https://en.wikipedia.org/wiki/UltraDefrag).
- **`DisableAcrylicBackgroundOnLogon`:** tweak *Logon Screen Acrylic Blur* de WinUtil.
- **MMAgent:** [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/mmagent/disable-mmagent).
- **Conectar Igualdad:** [netbookdelgobierno.com](https://www.netbookdelgobierno.com/2015/08/modelos-de-netbook-de-conectar-igualdad.html), [Utiltecnico](https://www.utiltecnico.com/2021/08/todo-sobre-las-netbooks-conectar-igualdad-del-gobierno-argentino/), [Underc0de](https://underc0de.org/foro/dudas-generales-121/problemas-netbook-conectar-igualdad/).
- **GMA 3600 / 3150:** [Intel Community](https://community.intel.com/t5/Graphics/Intel-GMA-3600-amp-Windows-10/m-p/460312), [Intel Community (32 bits)](https://community.intel.com/t5/Graphics/Windows-10-Intel-Graphics-Adapter-3600/m-p/486688), [GMA 3150](https://community.intel.com/t5/Graphics/Intel-GMA-3150-drivers-for-Windows-8-1-10/m-p/398142).
- **N2600 y 32 bits:** [Intel](https://www.intel.com/content/www/us/en/products/sku/58916/intel-atom-processor-n2600-1m-cache-1-6-ghz/specifications.html), [TenForums](https://www.tenforums.com/general-support/71501-32bit-vs-64bit-2gb-ram.html).
- **Theft Deterrent:** [manual del referente](https://educaciondigital.neuquen.gov.ar/wp-content/uploads/2018/04/ManualdelReferente2016-1.pdf), [instalador para Windows 10](https://groups.google.com/g/tecnicosconectar/c/24jhzaqOYKA), [configuración del agente](http://itibonzi.blogspot.com/2014/05/como-activar-y-configurar-el-agente-tda.html).
- **Visualizador de fotos:** [`.reg` de CharLS](https://github.com/team-charls/jpegls-wic-codec/blob/main/restore-windows-photo-viewer.reg), [gist](https://gist.github.com/ebrasha/02e5c6fa895e0e3f8c65103c89440092). Alt+Tab clásico: [Winaero](https://winaero.com/how-to-get-the-old-alt-tab-dialog-in-windows-10/).
- **ESU 2027:** [BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-quietly-extends-free-windows-10-esu-support-to-october-2027/), [Help Net Security](https://www.helpnetsecurity.com/2026/06/26/microsoft-windows-10-free-security-updates-esu-program/).

## Licencia

[MIT](LICENSE). Se puede usar, copiar, modificar y redistribuir, también en colegios y talleres, manteniendo el aviso de copyright.
