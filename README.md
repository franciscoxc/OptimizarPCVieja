# Optimizar PC Vieja

Scripts para exprimir PCs viejas con **Windows 10, disco mecánico (HDD) y 2 GB de RAM**, incluidas las
netbooks de Conectar Igualdad con procesador Atom (ver [su sección](#netbooks-de-conectar-igualdad-con-atom)).
Funcionan en Windows 10 de 64 y de 32 bits.
Objetivo: la mayor velocidad posible y el menor consumo de RAM, **sin apagar la seguridad**.

> Advertencia honesta: ningún script convierte una PC de 2 GB con disco mecánico en una gamer.
> Lo que sí se puede lograr es que deje de arrastrarse. El resto lo hacen un SSD y otro módulo de RAM
> (ver [Lo que ningún script puede hacer](#lo-que-ningún-script-puede-hacer)).

## Archivos

| Archivo | Qué hace | Cambia algo |
|---|---|---|
| `OptimizarPC.bat` | La optimización (v2). Ya incluye las correcciones del script original. | Sí |
| `DeshacerPerjudiciales.bat` | Deshace **solo** lo dañino del script original (v1), para PCs donde ya lo corriste. | Sí, poco |
| `RevertirOptimizacion.bat` | Vuelve a los valores de fábrica lo que cambia `OptimizarPC.bat` (por si algo sale mal). | Sí |
| `VerificarEstado.bat` | Muestra el hardware (procesador, video, RAM), el antirrobo de Conectar Igualdad si lo hay, y el estado de todo lo que tocan los scripts. Ideal para comparar antes/después. | **No** (solo lee) |

## Cómo usarlo

1. Copiá la carpeta a la PC (pendrive, red, lo que sea). Si la bajaste como ZIP, **descomprimila primero**:
   el script funciona igual desde adentro del ZIP, pero avisa, porque Windows lo corre desde una carpeta temporal.
2. Doble clic en `OptimizarPC.bat`. Si no tiene permisos, los pide solo (aparece el cartel de UAC).
3. Leé los avisos de hardware si aparece alguno (poca RAM, video sin driver, antirrobo de Conectar Igualdad)
   y respondé las 5 preguntas: impresora, compartir en red, OneDrive, apps preinstaladas y clásicos de Windows 7.
4. Esperá. En un disco mecánico puede tardar 10 a 20 minutos. Paciencia, mate y facturas.
5. **Reiniciá** con *Reiniciar*, no con *Apagar* y prender.
   Con el inicio rápido activado, "Apagar" no recarga todo y algunos cambios no se aplican.

Si en esa PC ya habías corrido el script original, no hace falta nada más: `OptimizarPC.bat` corrige lo que el original hizo mal.
Si solo querés reparar el daño sin optimizar nada más, usá `DeshacerPerjudiciales.bat`.

### ¿A qué usuario se le aplican los cambios?

Al que tiene la **sesión abierta**, aunque el script se ejecute "como administrador" con **otra** cuenta.
Esto es típico cuando la PC tiene un usuario común y el técnico pone la clave de administrador.

Windows guarda la configuración de cada usuario en `HKEY_CURRENT_USER`. Si elevás con otra cuenta,
`HKEY_CURRENT_USER` pasa a ser el del administrador y los cambios caen en el usuario equivocado.
El script lo evita así: busca el `explorer.exe` de la sesión actual, obtiene el SID de su dueño y
escribe directo en `HKEY_USERS\<SID>`. Al arrancar te muestra el nombre del usuario detectado para que lo confirmes.

---

## Qué hace `OptimizarPC.bat` (y por qué)

Criterio general:

- **Cada cambio tiene una razón y, si existe, una fuente.** Lo que no tiene evidencia, no entra.
- **La seguridad no se negocia.** Lo que debería estar encendido se verifica y se repara, por si otra herramienta lo apagó.
- **Servicios: Manual siempre que se pueda.** Si un servicio tiene que arrancar solo, va en *Automático (retrasado)*.
  Se *deshabilita* solo lo inútil para esta PC: telemetría, Xbox, Bluetooth y el indexador.
- **Antes de tocar nada, crea un punto de restauración.**

### 0. Red de seguridad

- Punto de restauración ("Antes de OptimizarPC v2"). Si no se puede crear, pregunta antes de seguir.
- Verifica que el archivo de paginación exista. Con 2 GB de RAM, sin paginación Windows se cuelga y cierra programas.

### 1. Seguridad: asegurar que lo importante esté encendido

Solo **repara** lo que encuentra apagado; lo que ya está bien no se toca.

| Qué | Qué hace el script |
|---|---|
| Servicios esenciales | Si alguno está **deshabilitado**, lo vuelve a su valor de fábrica: Defender, Centro de seguridad, Firewall, Windows Update (y sus ayudantes BITS, Orquestador, Medic, Delivery Optimization), Store y licencias de apps, UAC (`Appinfo`), puntos de restauración (`VSS`, `swprv`), hora (`W32Time`), red, audio y temas. |
| Defender | Borra las políticas que lo desactivan (puestas por "debloaters"). Activa el bloqueo de PUA (adware y "optimizadores" truchos, justo lo que llena de basura una PC vieja). Actualiza las firmas. |
| Firewall | Lo enciende en los 3 perfiles y borra políticas que lo apaguen. |
| SmartScreen | Borra políticas que lo apaguen (Windows y Edge). |
| UAC | Si estaba apagado o en "no notificar nunca", lo vuelve al valor de fábrica. |
| DEP | Si estaba en `AlwaysOff`, lo vuelve a `OptIn` (el valor por defecto). |
| Mitigaciones Spectre/Meltdown | Si alguien las apagó "para ganar rendimiento", las vuelve a encender. |
| Windows Update | Borra políticas que lo bloquean. Windows 10 tiene parches gratis hasta el **12/10/2027** si la PC está inscripta en ESU (ver más abajo). |
| Reproducción automática | La desactiva en todas las unidades (vía clásica de virus por pendrive). |
| Tareas importantes | Se asegura de que estén activas la desfragmentación programada (clave en HDD), el aviso de disco por fallar, los análisis de Defender y la creación de puntos de restauración. |

### 2. Correcciones al script original (v1)

| Línea del v1 | Veredicto | Qué hace la v2 |
|---|---|---|
| Deshabilitar `SysMain` | ❌ **Perjudicial.** SysMain maneja la **compresión de memoria**: con 2 GB de RAM, comprimir en RAM es muchísimo más rápido que paginar al disco mecánico. También hace el prefetch del arranque. | Lo vuelve a *Automático* y reactiva la compresión de memoria. |
| Deshabilitar `TabletInputService` | ❌ **Perjudicial.** En Windows 10 actual, de este servicio depende la escritura en el menú Inicio, en Configuración y en las apps UWP. El consejo viene de guías viejas (Black Viper, 2018) anteriores a ese cambio. | Lo vuelve a *Manual* (su valor de fábrica, arranca solo cuando hace falta). |
| `dosvc` con `Start=4` | ❌ **Perjudicial.** Windows Update lo usa para descargar; deshabilitarlo puede romper las actualizaciones (y el servicio Medic lo vuelve a prender igual). | Lo vuelve a su valor de fábrica y apaga solo el P2P con la política oficial `DODownloadMode=0`, que es lo que buscabas. |
| `DisablePagingExecutive=1` | ❌ **Perjudicial con poca RAM.** Fija el kernel en memoria y le deja menos RAM a tus programas, que terminan paginando al disco. | Lo vuelve a `0`. |
| `IOPageLockLimit` | 💊 Placebo. Windows lo ignora desde Windows 2000 SP1. Nunca fue un "buffer para el HDD". | Lo borra (limpieza). |
| `DontVerifyRandomDrivers` | 💊 Placebo. No existe ninguna "verificación de drivers al azar en segundo plano": Driver Verifier solo corre si lo activás a mano. | Lo borra (limpieza). |
| `compact /CompactOS:never` | ✅ Estaba bien, me equivoqué al principio. En HDD se recomienda **no** comprimir el sistema (fragmenta y el beneficio es mínimo). | Lo mantiene, pero solo descomprime si el sistema estaba comprimido **y** hay al menos 6 GB libres. |
| `DisableLastAccess` y `Disable8dot3` | ✅ Correctos e inofensivos. | Los mantiene. |
| Telemetría, Xbox, Bluetooth, Mapas, Retail Demo | ✅ Bien (no usás juegos ni Bluetooth). | Los mantiene. Biometría, ubicación y Retail Demo vuelven a *Manual* (su valor de fábrica): no ocupan RAM y así no rompen nada si algún día hacen falta. |

### 3. Servicios

| Inicio | Servicios | Por qué |
|---|---|---|
| **Deshabilitado** | `DiagTrack`, `dmwappushservice` | Telemetría. No aportan nada a la PC. |
| **Deshabilitado** | `WSearch` (indexador) | Su único trabajo es leer y releer el disco para indexarlo, justo lo que un HDD no aguanta. La búsqueda del Inicio sigue encontrando apps (Win10 20H2 en adelante); lo que se pierde es la búsqueda *instantánea* de contenido de archivos. |
| **Deshabilitado** | Xbox (`XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `xbgm`) | No usás juegos. |
| **Deshabilitado** | Bluetooth (`bthserv`, `BTAGService`, `BthAvctpSvc`) | No usás Bluetooth. |
| **Deshabilitado** | `RemoteRegistry` | Ya viene así de fábrica; se asegura por seguridad. |
| **Manual** | `PcaSvc`, `TrkWks`, `iphlpsvc`, `DPS`, `CDPSvc`, `MapsBroker`, `edgeupdate` | No hace falta que arranquen con Windows. Edge se sigue actualizando con sus tareas programadas. Contra: con `DPS` en Manual, los solucionadores de problemas de Windows (y probablemente el aviso de "memoria baja") no andan hasta que el servicio se inicie. |
| **Manual** | `lfsvc`, `WbioSrvc`, `RetailDemo`, `TabletInputService` | Su valor de fábrica: arrancan solo cuando alguien los necesita. |
| **Automático (retrasado)** | `BITS`, `WpnService` | Tienen que correr solos, pero pueden esperar a que termine el arranque. |
| **Según tu respuesta** | `Spooler` (impresión) | Con impresora: *Automático (retrasado)*. Sin impresora: *Manual*. |
| **Según tu respuesta** | `LanmanServer` (compartir) | Si compartís carpetas o impresora en red: *Automático*. Si no: *Manual*. |
| **Automático** (a propósito) | `SysMain` | Compresión de memoria. Tiene que estar desde el arranque, que es cuando más se llena la RAM. |

**Por qué no "todo a Manual" de una:** WinUtil (Chris Titus) tuvo durante años un "Set Services to Manual"
con ~190 servicios. Rompió Windows Update ([#1098](https://github.com/ChrisTitusTech/winutil/issues/1098)),
la hora del sistema ([#1412](https://github.com/ChrisTitusTech/winutil/issues/1412)) y el Bluetooth
([#2685](https://github.com/ChrisTitusTech/winutil/issues/2685), [#2877](https://github.com/ChrisTitusTech/winutil/issues/2877)).
En abril de 2026 lo recortaron a 5 servicios. Y de los ~190, solo 16 cambiaban algo: el resto ya estaba en Manual de fábrica.
Por eso acá se mueven solo los que tienen evidencia de que no rompen nada.

Se dejan en *Automático* a propósito, además de los protegidos por Windows: audio, red (`Dhcp`, `Dnscache`, `NlaSvc`, Wi-Fi),
firewall, Defender, registro de eventos, `Themes`, `FontCache` y los avisos de notificaciones del usuario.

### 4. Defender: solo lo imprescindible

Defender es el único antivirus de la PC, así que no se apaga. Además, con la *Protección contra alteraciones* encendida,
Windows ignora los intentos de apagarlo por script. Se recorta todo lo que no protege.

| Se queda (es lo que te protege) | Se recorta |
|---|---|
| Protección en tiempo real | Análisis programados: prioridad baja, máximo 20% de CPU (de fábrica 50%) y solo con la PC inactiva |
| Monitoreo de comportamiento | Análisis "de recuperación" al prender la PC: desactivados (es el valor de fábrica, se asegura) |
| Protección en la nube | Notificaciones no críticas ("Analizamos tu PC y no encontramos nada"): ocultas |
| Análisis de descargas y adjuntos | Ícono de la bandeja: oculto (los avisos críticos siguen apareciendo) |
| SmartScreen, Firewall y Protección contra alteraciones | Herramienta de eliminación de software malintencionado (MRT) mensual: desactivada, porque es redundante con Defender en tiempo real y en HDD tarda minutos cada mes |
| Actualización de firmas | |
| **Nuevo:** bloqueo de PUA (aplicaciones potencialmente no deseadas) | |

No se agregan exclusiones: son lo primero que buscan los virus.

### 5. Telemetría, publicidad y procesos en segundo plano

- Telemetría al mínimo permitido, sin encuestas de comentarios y sin ID de publicidad.
- Sin apps sugeridas, sin instalaciones silenciosas (Candy Crush y compañía), sin "consejos" y sin la pantalla de "terminá de configurar tu PC".
- **Noticias e intereses** de la barra de tareas: apagado. Es un navegador escondido que come RAM.
- Cortana, resultados web y "destacados" en la búsqueda: apagados (la búsqueda se vuelve local y más rápida).
- Barra de juegos y grabación de juegos: apagadas.
- Historial de actividad: no se publica ni se sube.
- Informe de errores: apagado (escribía volcados al disco después de cada cuelgue).
- **Apps en segundo plano:** se apagan una por una, **excepto** los componentes de Windows (búsqueda, Inicio, notificaciones y seguridad), la Store, las alarmas y los reproductores de música.
  **Fotos sí se apaga**: es de las que más RAM y disco usan de fondo, y se puede reactivar desde *Configuración > Privacidad > Aplicaciones en segundo plano*.
  No se usa el interruptor general porque rompe la búsqueda de apps recién instaladas en el Inicio ([detalle](https://github.com/Disassembler0/Win10-Initial-Setup-Script/pull/42)).
- Precarga de apps UWP (`ApplicationPreLaunch`): apagada. Windows ya no carga en RAM apps "por si las abrís".
- Tareas programadas de telemetría apagadas, entre ellas el *Compatibility Appraiser* (`CompatTelRunner`), famoso por dejar el disco al 100%. También WinSAT, que hace benchmarks de disco en el mantenimiento.
- Otras dos de WinUtil, inofensivas: no ejecutar el software que el fabricante esconde en el BIOS (WPBT) y no bajar "apps acompañantes" al conectar dispositivos.

### 6. Interfaz y Explorador

- Efectos visuales en "mejor rendimiento", pero **conservando el suavizado de fuentes** (si no, el texto se ve horrible) y las miniaturas.
- Sin transparencias, sin animaciones de ventanas ni de la barra de tareas, y sin Aero Peek.
- Menús más rápidos (`MenuShowDelay` de 400 a 100 ms).
- El Explorador abre en "Este equipo" en vez de "Acceso rápido", que en un HDD tarda en calcular los archivos recientes.
- **Sin detección automática del tipo de carpeta.** Explorer deja de leer el contenido de cada carpeta para adivinar si es de fotos o de música (tweak de WinUtil).
  Efecto secundario: se resetean las vistas guardadas de las carpetas.

### 7. Memoria, disco y energía

- Compresión de memoria: activada (requiere SysMain).
- NTFS: sin registro de último acceso y sin nombres cortos 8.3 (como en el v1).
- **Inicio rápido: activado.** En un disco mecánico es la mayor mejora de arranque que hay: Windows lee una sola "foto" del sistema en vez de cientos de archivos sueltos. (WinUtil desactiva la hibernación; acá no, a propósito.)
- PC de escritorio: plan de *Alto rendimiento*. Notebook: se mantiene el plan, para no matar la batería.
- **El disco nunca se apaga enchufado.** El HDD dormido tarda varios segundos en despertar, y esa es la típica "congelada" al volver a la PC.

### 8. Navegadores

- **Edge:** sin "arranque acelerado" (Edge precargado al iniciar Windows), sin quedar corriendo de fondo al cerrarlo, sin barra lateral, sin la "Edge bar" y sin recomendaciones ni compras.
  **Pestañas en suspensión a los 5 minutos** (de fábrica, 2 horas): esto es oro con 2 GB de RAM.
- **Chrome:** sin quedar corriendo de fondo al cerrarlo.
- Nota: Edge y Chrome van a mostrar "Administrado por tu organización". Es normal: así se ven las políticas.

### 9. Preguntas opcionales

| Pregunta | Si respondés "No" |
|---|---|
| ¿Usás impresora? | `Spooler` en Manual |
| ¿Compartís carpetas o impresora en red? | `LanmanServer` en Manual |
| ¿Usás OneDrive? | Se saca OneDrive del inicio (no se desinstala; si lo abrís, vuelve) |
| ¿Quitar apps preinstaladas? (si respondés "Sí") | Se desinstalan para todos los usuarios: Xbox, Solitario, Candy Crush, Noticias, Clima, Tu Teléfono, Skype, Personas, Mapas, Correo y Calendario (Microsoft los discontinuó en 2024), Paint 3D, Visor 3D, Portal de realidad mixta, OneNote para Win10, Obtener ayuda, Sugerencias, Centro de comentarios, Cortana y Copilot. **No** se tocan la Store, Calculadora, Fotos, Cámara, Recortes, Notas rápidas, Alarmas, Grabadora ni los reproductores. Todo se puede reinstalar desde la Store. |
| ¿Usar los clásicos de Windows 7? (si respondés "Sí") | Vuelve el **Visualizador de fotos de Windows** en lugar de la app Fotos, y el **Alt+Tab clásico**. Ver [Clásicos de Windows 7](#clásicos-de-windows-7). |

### 10. Limpieza

- Archivos temporales del usuario y de Windows. Si el script corre desde una carpeta temporal (abierto adentro de un ZIP), esa carpeta se saltea para no borrarse a sí mismo.

Al final muestra el estado de Defender y los programas que arrancan con Windows (revisalos en *Administrador de tareas > Inicio*), y ofrece reiniciar.

---

## Clásicos de Windows 7

Windows 10 todavía trae escondidas algunas piezas de Windows 7 que en una PC lenta andan mucho más rápido.

| Clásico | Qué hace el script |
|---|---|
| **Visualizador de fotos de Windows** | Sigue instalado, pero Windows 10 le sacó las fotos comunes y solo lo dejó para TIFF. El script se las devuelve (JPG, PNG, GIF y BMP), cada una con su nombre y su ícono de siempre, y lo registra en "Abrir con" y en Aplicaciones predeterminadas. Además desinstala la app Fotos nueva, que en un Atom tarda varios segundos en abrir una imagen. |
| **Alt+Tab clásico** | Muestra íconos en lugar de miniaturas en vivo de cada ventana. Si la placa de video no tiene driver, cada miniatura la dibuja el procesador. |

**El único paso manual:** Windows 10 no deja que un programa elija las aplicaciones predeterminadas por vos.
Después de reiniciar, andá a *Configuración > Aplicaciones > Aplicaciones predeterminadas > Visor de fotos* y elegí
*Visualizador de fotos de Windows*. O abrí una foto y, cuando pregunte con qué abrirla, elegilo y marcá *Usar siempre esta aplicación*.

Otros clásicos que ya están y no hace falta tocar:

- **Reproductor de Windows Media**, para música y video: elegilo en el mismo lugar de *Aplicaciones predeterminadas*.
- Paint, Bloc de notas, WordPad y la Herramienta Recortes de siempre: en Windows 10 siguen siendo los de Windows 7.

Lo que **no** se puede:

- **La calculadora de Windows 7** no viene en Windows 10. Las que circulan son de terceros.
- **Batería, reloj y volumen "clásicos"** (`UseWin32BatteryFlyout`, `UseWin32TrayClockExperience`, `EnableMtcUvc`): las guías son de 2015 a 2017
  y no hay evidencia de que sigan funcionando en Windows 10 22H2, así que no entran.

## Netbooks de Conectar Igualdad con Atom

Lo que dicen los foros y la documentación sobre estas máquinas, generación por generación:

| Generación | Procesador | RAM de fábrica | Video | Windows 10 |
|---|---|---|---|---|
| G1 | Atom N450 (1 núcleo + HT) | 1 GB DDR2 | GMA 3150 | Windows Update instala un driver que anda bien. |
| G2 | Atom N455 | 1 GB DDR3 | GMA 3150 | Igual que G1. |
| G3 / G4 | Atom N2600 (2 núcleos) | 2 GB DDR3 | **GMA 3600** | **Sin driver.** Intel nunca lo hizo para Windows 10, ni de 32 ni de 64 bits. |
| G5 | Celeron N2806 / N2807 | 2 GB | Intel HD | Tiene drivers. |

**1. El video de las G3/G4 es el verdadero cuello de botella.** Sin driver, Windows usa el *Adaptador de pantalla
básico de Microsoft*: no hay aceleración, puede no estar la resolución nativa y no se controla el brillo.
Todo lo dibuja el procesador. Por eso en estas netbooks apagar efectos visuales y transparencias no es un lujo:
es lo que más se nota. Aun así, los videos (YouTube) van a ir mal. El driver de Windows 7 instalado a la fuerza
suele terminar en pantalla negra o pantalla azul (`VIDEO_TDR_FAILURE`). No lo recomiendo.
El script detecta esta situación y te avisa.

**2. RAM.** Las G1 y G2 traen 1 GB, y Windows 10 de 64 bits pide 2 GB como mínimo. Intel especifica 2 GB como
máximo para estos Atom: un módulo de 2 GB (DDR2 en la G1, DDR3 en las demás) es la mejora más barata que hay.

**3. ¿32 o 64 bits?** Con 2 GB o menos, Windows 10 de 32 bits usa alrededor de un 10% menos de RAM y unos 3,5 GB
menos de disco. Cambiar implica reinstalar, así que ningún script lo puede hacer. Si vas a reinstalar una
netbook, conviene la de 32 bits.

**4. El antirrobo (Theft Deterrent).** Las netbooks del programa traen un sistema de bloqueo de ANSES/Intel:
el agente (*Theft Deterrent Agent*) renueva un certificado con el servidor de la escuela, y si no lo hace se
bloquea en una fecha o tras una cantidad de arranques. Si la netbook **no está liberada**:
- No desinstales ni saques del inicio el agente: sin él, la netbook se bloquea.
- Si la formateaste, perdiste el agente; existe un instalador para Windows 10, pero lo tiene que gestionar la escuela.

El script **no toca** el agente (no modifica servicios ni programas de terceros). Si lo detecta, avisa al
empezar, y en la lista final de programas de inicio lo marca con "NO lo desactives".

**5. Disco.** Un SSD SATA barato le cambia la vida a cualquiera de estas netbooks, más que todo lo demás junto.

**6. Alternativa.** Para las G3/G4 sin driver de video, los foros recomiendan un Linux liviano (Lubuntu, Linux Mint XFCE)
si no hace falta Windows sí o sí.

## Lo que NO hace (mitos y tweaks descartados)

| Tweak | Por qué no |
|---|---|
| Deshabilitar `SysMain`/Superfetch | Mata la compresión de memoria. Ver arriba. |
| `DisablePagingExecutive`, `LargeSystemCache` | Con poca RAM empeoran: le sacan memoria a tus programas. |
| `IOPageLockLimit`, `DontVerifyRandomDrivers` | Windows los ignora. Son mitos de la era XP. |
| `SvcHostSplitThresholdInKB` | Con menos de 3,5 GB de RAM, Windows ya agrupa los servicios en pocos `svchost`. No cambia nada. |
| `Win32PrioritySeparation = 0x26` | En Windows de escritorio es equivalente al valor de fábrica (cuantos cortos, variables y prioridad 3:1 a la ventana activa). |
| `NetworkThrottlingIndex`, `SystemResponsiveness` | Tweaks de gaming y multimedia. Acá no hacen nada útil. |
| `StartupDelayInMSec = 0` | Hace que los programas de inicio arranquen todos juntos con el escritorio. En HDD eso empeora el arranque. |
| Deshabilitar el archivo de paginación | Con 2 GB de RAM: cuelgues y programas que se cierran solos. |
| Deshabilitar hibernación | Mata el inicio rápido, que en HDD es la mayor mejora de arranque. |
| Deshabilitar la desfragmentación | En HDD es necesaria. El script se asegura de que esté **activa**. |
| "Limpiadores de RAM" y vaciar la carpeta `Prefetch` | Contraproducentes: Windows vuelve a cargar todo desde el disco lento. |
| `msconfig` > número de procesadores / memoria máxima | Solo sirven para **limitar**. Windows ya usa todo. |
| Deshabilitar Windows Update o Defender | Inseguro. Además, la Protección contra alteraciones lo revierte. |
| Deshabilitar `TabletInputService` | Rompe escribir en el Inicio, Configuración y apps UWP. |
| Deshabilitar `DoSvc` | Puede romper Windows Update. Lo correcto es `DODownloadMode=0`. |
| Interruptor general de "apps en segundo plano" | Rompe la búsqueda de apps nuevas en el Inicio. Se hace app por app. |
| "Set Services to Manual" masivo | Rompió Windows Update, la hora y el Bluetooth en WinUtil, y lo recortaron. |
| Apagar las mitigaciones de Spectre/Meltdown | En CPUs viejas dan rendimiento, pero dejan la PC expuesta. Pediste seguridad: se dejan encendidas. |
| Desinstalar OneDrive o Edge | Rompe más de lo que arregla. Se saca OneDrive del inicio y se dejan Edge y su motor (WebView2), que usan otras apps. |

## Lo que ningún script puede hacer

1. **Un SSD.** Aunque sea un SATA de 120 GB, de los más baratos. Es la mejora más grande, lejos: mayor que todo este repo junto.
2. **Más RAM.** Pasar de 2 GB a 4 GB (DDR3 usada se consigue regalada) cambia la experiencia por completo.
3. **Navegador con disciplina.** Con 2 GB, cada pestaña cuenta. Instalá uBlock Origin y no abras 30 pestañas.
4. **Seguridad a futuro.** Windows 10 dejó de tener soporte general en octubre de 2025, pero Microsoft extendió las
   actualizaciones de seguridad gratuitas para usuarios particulares (**ESU**) hasta el **12 de octubre de 2027**
   ([BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-quietly-extends-free-windows-10-esu-support-to-october-2027/),
   [Help Net Security](https://www.helpnetsecurity.com/2026/06/26/microsoft-windows-10-free-security-updates-esu-program/)).
   Hay que inscribir la PC en *Configuración > Windows Update*. Después de esa fecha, para estas PCs conviene un Linux liviano (Linux Mint XFCE, Lubuntu).

---

## Cómo se probó

Desde acá no hay un Windows real, así que se validó todo lo que se puede validar sin uno:

- **Wine (el `cmd.exe` de Wine):** los cuatro scripts corren de punta a punta con distintas combinaciones de respuestas.
  Se simuló el estado que deja el script original (y políticas que apagan Defender y Windows Update)
  y se verificó en el registro que cada valor quedara corregido y escrito en `HKEY_USERS\<SID>` del usuario.
  También se probó el ciclo completo optimizar, revertir y verificar.
- **PowerShell:** los 27 bloques de PowerShell pasan el parser oficial. La lógica de apps en segundo plano y la de
  limpieza de temporales se probaron con datos simulados.
- **Netbook simulada:** una G4 (Atom N2600, 1 GB, video sin driver, con antirrobo) muestra los tres avisos.
  El registro del Visualizador de fotos se verificó valor por valor contra el `.reg` de referencia, incluidos los
  íconos con `%SystemRoot%`, con comillas o inexistentes.
- **Formato:** ASCII puro y fin de línea CRLF (con LF, `cmd` puede fallar al saltar a etiquetas).

Lo que **no** se pudo probar acá: los servicios, Defender, la energía, las apps y el punto de restauración.
Wine no los implementa, así que falta la prueba en un Windows 10 real. Para eso está la sección siguiente.

## Cómo probarlo en UTM (Mac) antes de usarlo en una PC real

1. Creá una VM de **Windows 10 x64 22H2** con **2 GB de RAM** y 2 núcleos, igual que la PC vieja.
   En una Mac con Apple Silicon, UTM emula x86_64: va a andar lento, pero para probar alcanza.
2. Terminá la instalación, conectala a internet y dejala actualizar un rato.
3. Corré `VerificarEstado.bat` y guardá la salida (botón derecho > "Ejecutar como administrador").
4. **Sacá un snapshot de la VM.** Es el "deshacer" más confiable que existe.
5. (Opcional) Corré el script original (v1), después `VerificarEstado.bat`, y probá `DeshacerPerjudiciales.bat`.
6. Volvé al snapshot, corré `OptimizarPC.bat`, reiniciá y corré `VerificarEstado.bat` otra vez.
7. Checklist de cosas que **no** tienen que romperse:
   - [ ] Escribir en el menú Inicio y que la búsqueda encuentre apps (por ejemplo, "calc").
   - [ ] Escribir en Configuración y en alguna app de la Store (Calculadora).
   - [ ] *Configuración > Windows Update > Buscar actualizaciones* funciona.
   - [ ] La Store abre y descarga una app.
   - [ ] *Seguridad de Windows*: protección en tiempo real encendida y firmas actualizadas.
   - [ ] Sonido, red, hora correcta y el portapapeles (Ctrl+C y Ctrl+V).
   - [ ] Edge abre y navega.
   - [ ] Con los clásicos: una foto JPG abre con el Visualizador de fotos (después de elegirlo en Aplicaciones predeterminadas) y Alt+Tab muestra íconos.
   - [ ] Existe el punto de restauración "Antes de OptimizarPC v2" (`rstrui.exe`).
8. Probá `RevertirOptimizacion.bat` y verificá que todo vuelva a la normalidad.

Pasame las salidas de `VerificarEstado.bat` y lo que haya fallado del checklist, y lo ajustamos.

---

## Fuentes

Reddit bloquea el acceso automatizado de mi buscador, así que no lo leí directo. Usé las fuentes que recopilan
lo mismo que se recomienda ahí, contrastadas con documentación de Microsoft:

- **WinUtil (Chris Titus Tech):** [repositorio](https://github.com/ChrisTitusTech/winutil), `config/tweaks.json`.
  Se revisó cada tweak y el historial del recorte de servicios (commit `87a5779`, 21/04/2026).
  Issues sobre servicios en Manual: [#1098](https://github.com/ChrisTitusTech/winutil/issues/1098),
  [#1412](https://github.com/ChrisTitusTech/winutil/issues/1412),
  [#2685](https://github.com/ChrisTitusTech/winutil/issues/2685),
  [#2877](https://github.com/ChrisTitusTech/winutil/issues/2877).
- **Black Viper (servicios de Windows 10, valores de fábrica y configuración "segura"):** [BlackViperScript](https://github.com/madbomb122/BlackViperScript) (`BlackViper.csv`).
- **Win10-Initial-Setup-Script (Disassembler0):** [repositorio](https://github.com/Disassembler0/Win10-Initial-Setup-Script) y [PR #42 (apps en segundo plano y búsqueda)](https://github.com/Disassembler0/Win10-Initial-Setup-Script/pull/42).
- **SysMain y la compresión de memoria:** [WOSHub](https://woshub.com/memory-compression-process-high-usage-windows-10/), [ElevenForum](https://www.elevenforum.com/t/what-service-is-responsible-for-memory-compression.2953/), [TenForums](https://www.tenforums.com/tutorials/99821-enable-disable-superfetch-sysmain-windows.html).
- **IOPageLockLimit es un mito:** [MSFN, "Registry Myths #1"](https://msfn.org/board/topic/25684-registry-myths-1-iopagelocklimit/).
- **DontVerifyRandomDrivers:** [NTLite](https://ntlite.com/community/threads/are-the-listed-registry-settings-relevant.3221/).
- **DisablePagingExecutive con poca RAM:** [How-To Geek, mitos de tweaks](https://www.howtogeek.com/173648/10-windows-tweaking-myths-debunked/).
- **Deshabilitar DoSvc rompe Windows Update:** [privacy.sexy #223](https://github.com/undergroundwires/privacy.sexy/issues/223).
- **TabletInputService y escritura en Inicio y UWP:** [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/1321908/not-possible-to-disable-the-service-tabletinputser), [WindowsForum](https://windowsforum.com/threads/how-to-fix-touch-input-by-re-enabling-tabletinputservice-in-windows-11.386273/).
- **Búsqueda del Inicio sin el servicio Windows Search (20H2+):** [Winaero](https://winaero.com/how-to-search-in-windows-10-start-menu-with-search-box-disabled/).
- **Bing en el Inicio (`DisableSearchBoxSuggestions`):** [BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/windows-10-ignores-method-to-disable-bing-in-start-menu-fix-found/).
- **Noticias e intereses (`EnableFeeds`):** [TenForums](https://www.tenforums.com/tutorials/178178-how-enable-disable-news-interests-taskbar-windows-10-a.html).
- **Políticas de Edge:** [BackgroundModeEnabled](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled), [SleepingTabsTimeout](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/sleepingtabstimeout).
- **Defender, CPU de los análisis:** [TenForums](https://www.tenforums.com/tutorials/142728-set-windows-defender-antivirus-max-cpu-usage-scan-windows-10-a.html).
  Análisis de recuperación desactivados por defecto: [Microsoft Learn](https://learn.microsoft.com/en-us/defender-endpoint/schedule-antivirus-scans-powershell).
  Ocultar notificaciones: [Microsoft Learn](https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/windows-defender-security-center/wdsc-hide-notifications).
  Protección contra alteraciones: [Cloudbrothers](https://cloudbrothers.info/en/current-limits-defender-av-tamper-protection/).
- **WpnService:** [batcmd](https://batcmd.com/windows/10/services/wpnservice/).
- **CompactOS en HDD:** [TenForums](https://www.tenforums.com/performance-maintenance/131696-compression-os-experiment.html).
- **Precarga de apps (MMAgent):** [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/mmagent/disable-mmagent).
- **Netbooks de Conectar Igualdad:** generaciones y hardware en [netbookdelgobierno.com](https://www.netbookdelgobierno.com/2015/08/modelos-de-netbook-de-conectar-igualdad.html) y [Utiltecnico](https://www.utiltecnico.com/2021/08/todo-sobre-las-netbooks-conectar-igualdad-del-gobierno-argentino/). Windows 10 en estas netbooks: [Underc0de](https://underc0de.org/foro/dudas-generales-121/problemas-netbook-conectar-igualdad/).
- **GMA 3600 sin driver para Windows 10:** [Intel Community](https://community.intel.com/t5/Graphics/Intel-GMA-3600-amp-Windows-10/m-p/460312), [Intel Community (32 bits)](https://community.intel.com/t5/Graphics/Windows-10-Intel-Graphics-Adapter-3600/m-p/486688). GMA 3150 con driver de Windows Update: [Intel Community](https://community.intel.com/t5/Graphics/Intel-GMA-3150-drivers-for-Windows-8-1-10/m-p/398142).
- **RAM máxima del N2600:** [Intel](https://www.intel.com/content/www/us/en/products/sku/58916/intel-atom-processor-n2600-1m-cache-1-6-ghz/specifications.html). 32 contra 64 bits con 2 GB: [TenForums](https://www.tenforums.com/general-support/71501-32bit-vs-64bit-2gb-ram.html).
- **Antirrobo Theft Deterrent:** [manual del referente (Neuquén)](https://educaciondigital.neuquen.gov.ar/wp-content/uploads/2018/04/ManualdelReferente2016-1.pdf), [instalador para Windows 10 (técnicos Conectar)](https://groups.google.com/g/tecnicosconectar/c/24jhzaqOYKA), [configuración del agente](http://itibonzi.blogspot.com/2014/05/como-activar-y-configurar-el-agente-tda.html).
- **Visualizador de fotos:** registro de referencia del [códec JPEG-LS de CharLS](https://github.com/team-charls/jpegls-wic-codec/blob/main/restore-windows-photo-viewer.reg) y [gist con las asociaciones](https://gist.github.com/ebrasha/02e5c6fa895e0e3f8c65103c89440092). Alt+Tab clásico: [Winaero](https://winaero.com/how-to-get-the-old-alt-tab-dialog-in-windows-10/).
- **ESU extendido a 2027:** [BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-quietly-extends-free-windows-10-esu-support-to-october-2027/), [Help Net Security](https://www.helpnetsecurity.com/2026/06/26/microsoft-windows-10-free-security-updates-esu-program/).
