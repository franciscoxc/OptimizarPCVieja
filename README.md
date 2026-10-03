# Optimizar PC Vieja

Un script con menú para exprimir PCs viejas con **Windows 10, disco mecánico (HDD) y 2 GB de RAM**, incluidas las
netbooks de Conectar Igualdad con procesador Atom (ver [su sección](#netbooks-de-conectar-igualdad-con-atom)).
Funcionan en Windows 10 de 64 y de 32 bits.
Objetivo: la mayor velocidad posible y el menor consumo de RAM, **sin apagar la seguridad**.

> Advertencia honesta: ningún script convierte una PC de 2 GB con disco mecánico en una gamer.
> Lo que sí se puede lograr es que deje de arrastrarse. El resto lo hacen un SSD y otro módulo de RAM
> (ver [Lo que ningún script puede hacer](#lo-que-ningún-script-puede-hacer)).

## Un archivo, un menú

Todo está en **`OptimizarPC.bat`**. Al abrirlo pide permisos de administrador y muestra un menú:

| Opción | Qué hace | Cambia algo |
|---|---|---|
| **1. Optimizar la PC** (o solo Enter) | La optimización (v2). Ya incluye las correcciones del script original. | Sí |
| 2. Verificar el estado | Muestra el hardware (procesador, video, RAM), el antirrobo de Conectar Igualdad si lo hay, y el estado de todo lo que toca el script. Lo guarda en un `.txt` al lado del script, para comparar antes y después. | **No** (solo lee) |
| 3. Limpiar restos de Windows Update | De vez en cuando: borra con DISM las versiones viejas que guardan las actualizaciones (WinSxS). Libera espacio, no acelera. Puede tardar más de una hora. Ver [Limpiar restos de Windows Update](#limpiar-restos-de-windows-update-vale-la-pena). | Sí (solo restos de actualizaciones) |
| 4. Desfragmentar a fondo | De vez en cuando, para discos mecánicos: analiza, desfragmenta, junta el espacio libre y optimiza el arranque. En un SSD solo manda TRIM. Puede tardar horas. | Sí (solo ordena el disco) |
| 5. Revertir la optimización | Vuelve a los valores de fábrica lo que cambia la opción 1, por si algo sale mal. | Sí |
| 6. Deshacer lo perjudicial del script original (v1) | Deshace **solo** lo dañino del v1, para PCs donde ya lo corriste. | Sí, poco |
| 0. Salir | | |

Se responde con el número y Enter. Al terminar cada opción se vuelve al menú. Las que cambian el sistema (1, 5 y 6)
ofrecen reiniciar al final; si decís que no, el menú recuerda que falta reiniciar y lo vuelve a ofrecer al salir.

## Cómo usarlo

1. Copiá `OptimizarPC.bat` a la PC (pendrive, red, lo que sea). Si lo bajaste en un ZIP, **descomprimilo primero**:
   funciona igual desde adentro del ZIP, pero avisa, porque Windows lo corre desde una carpeta temporal.
2. Doble clic en `OptimizarPC.bat`. Si no tiene permisos, los pide solo (aparece el cartel de UAC).
   No hay que instalar nada: usa `cmd` y PowerShell, que vienen con Windows 10. Si lo bajaste de internet, Windows
   puede avisar una vez ("Windows protegió su PC": *Más información > Ejecutar de todas formas*). Para que no
   avise: botón derecho en el archivo *> Propiedades >* tildá *Desbloquear*.
3. En el menú, Enter (o 1): **Optimizar la PC**.
4. Leé los avisos de hardware si aparece alguno (poca RAM, video sin driver, antirrobo de Conectar Igualdad)
   y respondé las 4 preguntas: impresora, compartir en red, OneDrive y apps preinstaladas. Después no pregunta más.
5. Esperá. En un disco mecánico puede tardar 10 a 20 minutos. Paciencia, mate y facturas.
6. **Reiniciá** la PC (lo ofrece al final). Como el script apaga el inicio rápido, desde ahora *Apagar*
   también es un apagado completo: ya no hace falta acordarse de usar *Reiniciar*.
   **Ojo:** desde ahora, cerrar la tapa o apretar el botón de encendido **apaga** la PC, sin suspender. Guardá antes.

Si en esa PC ya habías corrido el script original, no hace falta nada más: la opción 1 corrige lo que el original hizo mal.
Si solo querés reparar el daño sin optimizar nada más, usá la opción 6.

### ¿A qué usuario se le aplican los cambios?

Al que tiene la **sesión abierta**, aunque el script se ejecute "como administrador" con **otra** cuenta.
Esto es típico cuando la PC tiene un usuario común y el técnico pone la clave de administrador.

Windows guarda la configuración de cada usuario en `HKEY_CURRENT_USER`. Si elevás con otra cuenta,
`HKEY_CURRENT_USER` pasa a ser el del administrador y los cambios caen en el usuario equivocado.
El script lo evita así: busca el `explorer.exe` de la sesión actual, obtiene el SID de su dueño y
escribe directo en `HKEY_USERS\<SID>`. Al empezar la opción 1 te muestra el nombre del usuario detectado para que lo confirmes.

---

## Qué hace la opción 1, Optimizar la PC (y por qué)

Criterio general:

- **Cada cambio tiene una razón y, si existe, una fuente.** Lo que no tiene evidencia, no entra.
- **La seguridad no se negocia.** Lo que debería estar encendido se verifica y se repara, por si otra herramienta lo apagó.
- **Servicios: Manual siempre que se pueda.** Si un servicio tiene que arrancar solo, va en *Automático (retrasado)*.
  Se *deshabilita* solo lo inútil para esta PC: telemetría, Xbox, Bluetooth y el indexador.
- **Nada residente que no se gane el lugar.** Lo que corre de fondo sin que lo uses se apaga. Lo que queda, queda
  porque le ahorra trabajo al disco o porque protege (ver [Caché de disco, ReadyBoost y las optimizaciones de Windows](#caché-de-disco-readyboost-y-las-optimizaciones-de-windows)).
- **Sin puntos de restauración.** Restaurar sistema se desactiva: en la práctica, ante un problema se reinstala.
  La vuelta atrás es la opción 5 del menú.

### 0. Red de seguridad

- **No crea punto de restauración:** Restaurar sistema se desactiva (ver la sección 7), así que se borraría igual.
  La vuelta atrás es la opción 5 del menú, que deja de fábrica lo que cambia la optimización.
- Verifica que el archivo de paginación exista. Con 2 GB de RAM, sin paginación Windows se cuelga y cierra programas.

### 1. Seguridad: asegurar que lo importante esté encendido

Solo **repara** lo que encuentra apagado; lo que ya está bien no se toca.

| Qué | Qué hace el script |
|---|---|
| Servicios esenciales | Si alguno está **deshabilitado**, lo vuelve a su valor de fábrica: Defender, Centro de seguridad, Firewall, Windows Update (y sus ayudantes BITS, Orquestador, Medic, Delivery Optimization), Store y licencias de apps, UAC (`Appinfo`), instantáneas de volumen (`VSS`, `swprv`), hora (`W32Time`), red, audio y temas. |
| Defender | Borra las políticas que lo desactivan (puestas por "debloaters"). Activa el bloqueo de PUA (adware y "optimizadores" truchos, justo lo que llena de basura una PC vieja). Las firmas las sigue bajando Windows Update. |
| Firewall | Lo enciende en los 3 perfiles y borra políticas que lo apaguen. |
| SmartScreen | Borra políticas que lo apaguen (Windows y Edge). |
| UAC | Si estaba apagado o en "no notificar nunca", lo vuelve al valor de fábrica. |
| DEP | Si estaba en `AlwaysOff`, lo vuelve a `OptIn` (el valor por defecto). |
| Mitigaciones Spectre/Meltdown | Si alguien las apagó "para ganar rendimiento", las vuelve a encender. |
| Windows Update | Borra políticas que lo bloquean. Windows 10 tiene parches gratis hasta el **12/10/2027** si la PC está inscripta en ESU (ver más abajo). |
| Reproducción automática | La desactiva en todas las unidades (vía clásica de virus por pendrive). |
| Tareas importantes | Se asegura de que estén activas la desfragmentación programada (clave en HDD), la limpieza automática de restos de actualizaciones (`StartComponentCleanup`), el aviso de disco por fallar y los análisis de Defender. |

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
| **Deshabilitado** | `WSearch` (indexador) | Su único trabajo es leer y releer el disco para indexarlo, justo lo que un HDD no aguanta. La búsqueda del Inicio sigue encontrando apps (Win10 20H2 en adelante); lo que se pierde es la búsqueda *instantánea* de archivos. Para eso, [Everything](https://www.voidtools.com/) de voidtools: lee el índice del propio NTFS, encuentra cualquier archivo al instante y casi no usa disco. |
| **Deshabilitado** | Xbox (`XblAuthManager`, `XblGameSave`, `XboxNetApiSvc`, `XboxGipSvc`, `xbgm`) | No usás juegos. |
| **Deshabilitado** | Bluetooth (`bthserv`, `BTAGService`, `BthAvctpSvc`) | No usás Bluetooth. |
| **Deshabilitado** | `RemoteRegistry` | Ya viene así de fábrica; se asegura por seguridad. |
| **Deshabilitado** | `AdobeARMservice`, si Adobe Reader está instalado | Su actualizador automático. Ver [Adobe Reader](#11-adobe-reader-si-está-instalado). |
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
| Análisis de descargas y adjuntos | |
| Ícono de la bandeja (versiones anteriores lo ocultaban: ahora vuelve) | |
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
- **Apps en segundo plano:** se apagan una por una, **excepto** los componentes de Windows (búsqueda, Inicio, notificaciones y seguridad), la Store, las alarmas, los reproductores de música y Recortes y anotación.
  **Fotos sí se apaga**: es de las que más RAM y disco usan de fondo, y se puede reactivar desde *Configuración > Privacidad > Aplicaciones en segundo plano*.
  No se usa el interruptor general porque rompe la búsqueda de apps recién instaladas en el Inicio ([detalle](https://github.com/Disassembler0/Win10-Initial-Setup-Script/pull/42)).
- Precarga de apps UWP (`ApplicationPreLaunch`): apagada. Windows ya no carga en RAM apps "por si las abrís".
- Tareas programadas de telemetría apagadas, entre ellas el *Compatibility Appraiser* (`CompatTelRunner`), famoso por dejar el disco al 100%. También WinSAT, que hace benchmarks de disco en el mantenimiento.
- Otras dos de WinUtil, inofensivas: no ejecutar el software que el fabricante esconde en el BIOS (WPBT) y no bajar "apps acompañantes" al conectar dispositivos.

### 6. Interfaz y Explorador

- Efectos visuales en "mejor rendimiento". Quedan solo tres:
  - **Mostrar el contenido de la ventana mientras se arrastra.**
  - **Suavizar bordes para las fuentes de pantalla:** no es un efecto, es lo que hace legible el texto, y casi no gasta.
  - **Animar las ventanas al minimizar y maximizar**, solo si la placa de video tiene driver. Con el *Adaptador de
    pantalla básico* (las G3/G4 de Conectar Igualdad sin driver) la dibuja el procesador y va a los saltos, así que se apaga.
- **Íconos en vez de miniaturas.** En un disco mecánico, abrir una carpeta con fotos o videos obliga a leer cada
  archivo para dibujar su miniatura. Para recorrer fotos está el Visualizador (con las flechas pasás de una a otra).
  Si las querés de vuelta: *Opciones de carpeta > Ver >* destildá *Mostrar siempre iconos, nunca vistas en miniatura*.
- Sin transparencias, sin animaciones de menús ni de la barra de tareas, y sin Aero Peek.
- Sin el desenfoque "acrílico" de la pantalla de inicio de sesión (`DisableAcrylicBackgroundOnLogon`, también de WinUtil): es otro
  efecto de transparencia, y sin aceleración de video lo calcula el procesador.
- Menús más rápidos (`MenuShowDelay` de 400 a 100 ms).
- El Explorador abre en "Este equipo" en vez de "Acceso rápido", que en un HDD tarda en calcular los archivos recientes.
- **Sin detección automática del tipo de carpeta.** Explorer deja de leer el contenido de cada carpeta para adivinar si es de fotos o de música (tweak de WinUtil).
  Efecto secundario: se resetean las vistas guardadas de las carpetas.

### 7. Memoria, disco y energía

- Compresión de memoria: activada (requiere SysMain).
- **Archivo de paginación fijo en el doble de la RAM instalada** (con 2 GB, 4096 MB). El automático arranca chico y
  crece de a pedazos, y en un disco lento eso trae errores y fragmentación. Fijo, nunca cambia de tamaño
  (ver [Caché de disco](#caché-de-disco-readyboost-y-las-optimizaciones-de-windows)).
- **Caché de escritura del disco activada y sin vaciado del búfer** (salvo en un SSD): Windows deja de esperar a que
  el disco confirme cada escritura. Se gana tiempo; el costo es el riesgo ante un corte de luz
  (ver [Caché de disco](#caché-de-disco-readyboost-y-las-optimizaciones-de-windows)).
- NTFS: sin registro de último acceso y sin nombres cortos 8.3 (como en el v1).
- **Restaurar sistema: desactivado.** Mientras haya puntos de restauración, cada escritura en el disco puede costar
  una copia extra, y ocupan hasta un 10% del disco. Desactivarlo saca ese trabajo de fondo y borra **todos** los puntos.
  En la práctica, ante un problema se reinstala, así que no se extrañan.

**Energía: la prioridad es la velocidad, no el ahorro.** Se aplica a los tres planes de Windows (Equilibrado, Alto
rendimiento y Economizador), por si alguien cambia de plan después, y también al plan activo si es otro (por ejemplo,
uno del fabricante):

| Qué | Cómo queda | Por qué |
|---|---|---|
| Plan de energía | *Alto rendimiento*, también en notebooks | Windows deja de frenar el procesador para ahorrar. La batería dura menos: es el precio. |
| Disco | Nunca se apaga solo, enchufada o a batería | El HDD dormido tarda varios segundos en despertar: es la típica "congelada" al volver a la PC. |
| Suspender sola | A las **4 horas** sin uso, enchufada o a batería | Le da tiempo de sobra al mantenimiento automático de Windows (desfragmentación, limpieza de actualizaciones, análisis de Defender), que corre con la PC prendida y sin uso. Para despertarla, el botón de encendido. |
| Hibernar sola | Nunca | La hibernación queda desactivada (ver abajo). |
| Botón de encendido | Apagado completo | |
| Cerrar la tapa | Apagado completo | En una PC de escritorio no hace nada: no tiene tapa. |
| Botón de suspensión (si el teclado lo tiene) | Nada | El Panel de control no le ofrece "Apagar" a ese botón. |
| Batería crítica | Apagado completo | De fábrica suele hibernar. Sin hibernación hay que decirle qué hacer, y apagar es la salida prolija: Windows cierra todo antes de que se corte. |
| Hibernación e inicio rápido | Desactivados | Se borra `hiberfil.sys`: el 40% de la RAM, unos 800 MB con 2 GB. |
| Menú de apagado | Sin *Suspender* ni *Hibernar* | Quedan *Apagar* y *Reiniciar*: la suspensión es solo la automática. *Suspender* se puede volver a mostrar desde *Panel de control > Opciones de energía > Elegir el comportamiento de los botones de inicio/apagado*. |

El apagado de la pantalla no se toca: no cambia la velocidad.

**Por qué sin inicio rápido:** en un disco mecánico, el inicio rápido acelera el arranque, porque Windows lee una sola
"foto" del sistema en vez de cientos de archivos sueltos. Pero esa foto es un apagado a medias: el núcleo de Windows
no se reinicia nunca y arrastra lo que tenía de un arranque al otro. Con drivers viejos (por ejemplo, los de Windows 7)
puede dejar algo mal después de prender, y hay casos de `ntoskrnl.exe` usando 10-15% de procesador que desaparecen al
desactivarlo ([HP Community](https://h30434.www3.hp.com/t5/Notebook-Boot-and-Lockup/Fast-startup-causing-high-cpu-usage/td-p/7888113)).
Además, algunas actualizaciones necesitan un reinicio completo. Sin él, el arranque desde cero tarda más en un
HDD, pero cada arranque es limpio y *Apagar* significa apagar.

### 8. Navegadores

- **Edge:** sin "arranque acelerado" (Edge precargado al iniciar Windows), sin quedar corriendo de fondo al cerrarlo, sin barra lateral, sin la "Edge bar" y sin recomendaciones ni compras.
  **Pestañas en suspensión a los 5 minutos** (de fábrica, 2 horas): esto es oro con 2 GB de RAM.
- **Chrome:** sin quedar corriendo de fondo al cerrarlo.
- Nota: Edge y Chrome van a mostrar "Administrado por tu organización". Es normal: así se ven las políticas.

### 9. Las 4 preguntas

Sin preguntar, siempre: los [clásicos de Windows 7](#clásicos-de-windows-7) (el Visualizador de fotos en lugar de la
app Fotos, y el Alt+Tab clásico) y Restaurar sistema desactivado.

| Pregunta | Si respondés "No" |
|---|---|
| ¿Usás impresora? | `Spooler` en Manual |
| ¿Compartís carpetas o impresora en red? | `LanmanServer` en Manual |
| ¿Usás OneDrive? | Se saca OneDrive del inicio (no se desinstala; si lo abrís, vuelve) |
| ¿Quitar apps preinstaladas? (si respondés "Sí") | Se desinstalan para todos los usuarios: Xbox, Solitario, Candy Crush, Noticias, Tu Teléfono, Skype, Contactos, Mapas, Correo y Calendario (Microsoft los discontinuó en 2024), Outlook nuevo, OneNote para Win10, Notas rápidas, Alarmas, Groove, Películas y TV, Paint 3D, Visor 3D, Portal de realidad mixta, Obtener ayuda, Sugerencias, Centro de comentarios, To Do, Cortana y Copilot. **Quedan** la Store, Calculadora, Cámara, Grabadora de sonidos, **Clima** y **Recortes y anotación** (Win+Shift+S). El Bloc de notas, Paint y la Herramienta Recortes clásicos no son apps de la Store: siguen. Todo se puede reinstalar desde la Store. |

### 10. Limpieza

Vacía todas las carpetas temporales de Windows. Lo que está en uso **se saltea solo**, sin frenarse (siempre hay un par),
y al final muestra cuánto liberó cada carpeta y cuántos archivos salteó:

| Carpeta | Qué es |
|---|---|
| `C:\Windows\Temp` | La que se abre con *Ejecutar > temp*. |
| `%temp%` de **cada** usuario | La que se abre con *Ejecutar > %temp%* (`C:\Users\<usuario>\AppData\Local\Temp`). Incluye la del administrador que elevó el script. |
| Temp de las cuentas del sistema | `SYSTEM` (64 y 32 bits), `LocalService` y `NetworkService`: las usan servicios e instaladores, y nadie las limpia. |
| Informes de errores | De Windows y de cada usuario (WER). |
| Volcados de memoria | `MEMORY.DMP` (puede pesar como toda la RAM), `Minidump` y `LiveKernelReports`. Esta última junta los cuelgues de video, frecuentes con drivers forzados. |
| Registros viejos de actualizaciones | `C:\Windows\Logs\CBS\CbsPersist_*`. El registro actual no se toca. |
| Caché de Delivery Optimization | Actualizaciones ya instaladas que se guardaban para compartir. |
| `C:\Windows\Prefetch` | Solo las entradas de programas: ver abajo. |
| Caché y actualizaciones bajadas de Adobe Reader | Si está instalado. Ver [Adobe Reader](#11-adobe-reader-si-está-instalado). |

Medidas de seguridad: nunca sigue enlaces (junctions o symlinks) que apunten fuera de la carpeta, nunca vacía
carpetas enteras como `C:\Windows` o un perfil de usuario (aunque alguien edite mal la lista), y saltea la carpeta
desde la que corre el script, por si se abrió adentro de un ZIP.

**Sobre Prefetch:** vaciarlo de vez en cuando tiene sentido, porque se llena de entradas de programas que ya no se
usan (Adobe Reader y su actualizador dejan varias). Pero vaciarlo **entero** tiene un costo medido: Windows usa esa
carpeta para arrancar y abrir programas más rápido, y un desarrollador del equipo de rendimiento de Windows midió que,
sin ella, el reinicio siguiente tardó entre 4 y 15 segundos **más**
([Microsoft](https://learn.microsoft.com/en-us/archive/blogs/ryanmy/misinformation-and-the-the-prefetch-flag),
[Ed Bott](https://edbott.com/2005/06/01/one-more-time-do-not-clean-out-your-prefetch-folder/)).
Por eso el script borra solo las entradas de programas (`*.pf`) y conserva lo que Windows usa para arrancar:

- `NTOSBOOT-B00DFAAD.pf`, el rastro del arranque;
- `Layout.ini`, el mapa con el que el desfragmentador ordena los archivos del arranque;
- la carpeta `ReadyBoot` y las bases de SysMain (`Ag*.db`), que deciden qué precargar en memoria
  ([Prefetcher](https://en.wikipedia.org/wiki/Prefetcher), [ReadyBoot y SuperFetch](https://en.wikipedia.org/wiki/Windows_Vista_I/O_technologies)).

Así se va la basura y el arranque conserva su optimización. Cada programa tarda un poco más solo la primera vez que
lo abrís, mientras Windows rehace su entrada.

**Lo que no se toca, a propósito:** la Papelera (son tus archivos); la caché de miniaturas (regenerarla en un disco
mecánico hace lentas las carpetas); `SoftwareDistribution\Download` (si hay una actualización a medio instalar, se
rompe). `Windows.old` y los restos de actualizaciones grandes se borran mejor con *Liberador de espacio en disco >
Limpiar archivos del sistema*.

### 11. Adobe Reader, si está instalado

Los PDF quedan para Edge o Chrome. Adobe Reader sigue instalado y anda si alguien lo abre, pero ya no arranca nada solo:

| Qué | Qué hace el script |
|---|---|
| Entradas de inicio | Quita las de Reader y Acrobat: *Adobe ARM* (el actualizador), *Speed Launcher* (`reader_sl.exe`, que precargaba Reader "por si acaso") y *Acrobat Assistant* (`acrotray.exe`). También las de *RunOnce*: algunas actualizaciones de Reader las volvían a agregar solas. |
| Tarea *Adobe Acrobat Update Task* | Desactivada. Corría el actualizador al iniciar sesión y todos los días. |
| Servicio `AdobeARMservice` | Detenido y deshabilitado. Es el que instala las actualizaciones en silencio, y estaba siempre en memoria. |
| Caché de Reader | Vacía `AppData\LocalLow\Adobe\AcroCef\DC\Acrobat\Cache` de cada usuario: la parte web de Reader. |
| Actualizaciones bajadas | Vacía `C:\ProgramData\Adobe\ARM`: el actualizador guarda ahí cada instalador que baja y no los borra nunca. |

**El precio:** Reader deja de recibir parches de seguridad, y los PDF son una vía clásica de virus. Por eso:

- Hacé que los PDF abran con el navegador: *Configuración > Aplicaciones > Aplicaciones predeterminadas > Elegir
  aplicaciones predeterminadas por tipo de archivo > .pdf*. El script lo recuerda al final, y la opción 2
  muestra cuál quedó.
- Si no usás Reader para nada, desinstalalo. Lo único que suele necesitarlo son los formularios PDF "dinámicos" (XFA),
  que los navegadores no abren.

Al terminar, el script muestra el estado de Defender y los programas que arrancan con Windows (revisalos en *Administrador de tareas > Inicio*), y ofrece reiniciar.

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
  Si quitaste las apps preinstaladas, es el reproductor que queda, porque Groove y Películas y TV se van.
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
es lo que más se nota. Aun así, los videos (YouTube) van a ir mal.
**Driver de Windows 7:** en el campo, en muchas Conectar Igualdad funciona, sobre todo en Windows 10 de 32 bits. En los
foros de Intel también hay casos de pantalla azul (`VIDEO_TDR_FAILURE`). Si falla, se vuelve atrás desde el *Administrador de dispositivos* (*Revertir al controlador anterior*) o desde el
modo seguro.
Con drivers viejos es donde más problemas da el inicio rápido, y el script lo apaga siempre. Además detecta si estás
con el driver básico y te avisa.

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

## Desfragmentar: ¿sirve el de Windows?

Tu intuición es correcta en parte: el desfragmentador automático trabaja "por encima", **a propósito**.

- Ignora los fragmentos de más de **64 MB**: Microsoft midió que juntarlos casi no cambia la velocidad, porque leer
  64 MB seguidos tarda muchísimo más que el salto de un fragmento al otro
  ([Microsoft Tech Community](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921)).
- La pasada semanal automática hace la desfragmentación normal, pero no junta el espacio libre.

Para mantenimiento, la semanal alcanza, y la opción 1 se asegura de que esté activa. Para una pasada a fondo
está la **opción 4, *Desfragmentar a fondo***, que usa la misma herramienta de Windows con todos sus parámetros
([`defrag`, Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/defrag)):

| Paso | Parámetro | Qué hace |
|---|---|---|
| 1 | `/A /V` | Analiza y muestra el porcentaje de fragmentación. |
| 2 | `/W` | Desfragmentación completa, incluidos los fragmentos de más de 64 MB. Si esa versión de Windows no acepta `/W`, hace la normal (`/D`). |
| 3 | `/X` | Junta el espacio libre: los archivos nuevos se fragmentan menos. |
| 4 | `/B` | Optimiza el arranque: junta los archivos que Windows lee al prender. Usa `Layout.ini`, el mapa de la carpeta Prefetch, que la opción 1 conserva al limpiar. |
| 5 | `/A /V` | Analiza otra vez, para comparar. |

Usa `/H` (prioridad normal, termina antes) y `/U` (muestra el progreso). En un SSD no desfragmenta: manda TRIM.
Antes de empezar avisa si queda menos de 15% libre: con menos, Windows solo desfragmenta en parte, porque usa ese
espacio para acomodar los pedazos ([`defrag`, Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/defrag)).
Puede tardar horas en un Atom: dejala enchufada y sin usar.

Lo único que la herramienta de Windows no puede mover es lo que está en uso mientras Windows corre: el archivo de
paginación y partes de la tabla del disco (MFT). Para eso hace falta un desfragmentador que trabaje durante el
arranque, como [UltraDefrag](https://en.wikipedia.org/wiki/UltraDefrag). La versión 7.1.4 es la última de código abierto.

## Limpiar restos de Windows Update: ¿vale la pena?

Cada actualización guarda en `C:\Windows\WinSxS` la versión anterior de lo que reemplaza, por si hay que
desinstalarla. Los comandos que circulan para limpiar eso
([Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder)):

| Comando | Qué hace | ¿Va? |
|---|---|---|
| `Dism.exe /Online /Cleanup-Image /StartComponentCleanup` | Borra las versiones anteriores que ya fueron reemplazadas. Windows hace lo mismo solo con la tarea *StartComponentCleanup*, pero recién a los 30 días y cortando a la hora de trabajo; el comando lo hace ya y completo. | **Sí** |
| `... /StartComponentCleanup /ResetBase` | Además, las actualizaciones instaladas pasan a ser la base del sistema y se borra todo lo que quedaba para desinstalarlas. Libera más, pero esas actualizaciones **no se pueden desinstalar nunca más** (las que vengan después, sí). | **Opcional:** el script lo pregunta |
| `Dism.exe /Online /Cleanup-Image /SPSuperseded` | Borra los archivos de respaldo de un *Service Pack* ([era de Windows 7](https://learn.microsoft.com/en-us/archive/blogs/joscon/how-to-reclaim-space-after-applying-windows-72008-r2-service-pack-1)). Windows 10 no tiene Service Packs: no hace nada. | **No** |

**Vale la pena de vez en cuando, pero aparte.** Libera espacio (desde nada hasta varios GB, según cuántas
actualizaciones se acumularon), pero **no acelera nada**, y en un Atom con disco mecánico puede tardar más de una hora
con el disco al 100%. Por eso no está dentro de la opción 1, que en cambio se asegura de que la limpieza
automática de Windows esté activa.

Para hacerla a mano está la **opción 3, *Limpiar restos de Windows Update***: primero analiza (`/AnalyzeComponentStore` dice si conviene
limpiar), después pregunta por `/ResetBase`, limpia y muestra cuánto liberó. Si hay una actualización esperando un
reinicio, DISM se niega con el error `0x800F0806`
([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/2192270/dism-startcomponentcleanup-give-error-0x800f0806-t)):
reiniciá y volvé a correrlo.

Rutina de mantenimiento, cada tantos meses: la opción 3 y después la 4, que con menos archivos tiene menos que
mover.

## Caché de disco, ReadyBoost y las optimizaciones de Windows

**El criterio: nada residente que no se gane el lugar.** Lo que corre de fondo sin que lo uses se apaga. Lo que queda,
queda porque le ahorra trabajo al disco o porque protege. Así quedan las optimizaciones que trae Windows:

| Optimización de Windows | Qué hace | Veredicto |
|---|---|---|
| Prefetch | Al abrir un programa, lee de una pasada lo que usó la última vez, en vez de saltar por el disco. | **Se queda.** No corre de fondo: trabaja al abrir programas. |
| ReadyBoot | Al arrancar, precarga en RAM los archivos del arranque. | **Se queda.** Trabaja solo durante el arranque. |
| Compresión de memoria (SysMain) | Comprime en RAM lo que si no iría al archivo de paginación. | **Se queda: es la más importante con 2 GB.** Comprimir en RAM es muchísimo más rápido que escribir y leer del disco. |
| SuperFetch (SysMain) | Llena la RAM libre con los programas que más usás. | Viene en el mismo servicio que la compresión, así que se queda. Con 2 GB casi no hay RAM libre que llenar. |
| Precarga de apps (PreLaunch) | Abre apps de la Store "por si acaso". | **Apagada.** |
| Inicio rápido | Hiberna el núcleo al apagar. | **Apagado.** Ver la sección de energía. |
| Indexador de búsqueda | Lee y relee el disco para indexarlo. | **Apagado.** |
| ReadyBoost | Usa un pendrive o una tarjeta SD como caché del disco. | **Experimento opcional:** ver abajo. |

### ¿Se puede agrandar la caché del disco?

La caché de archivos de Windows ya usa **toda la RAM que sobra**, sola (en el Administrador de tareas figura como
"En caché"), y la devuelve al instante cuando un programa la pide. Con 2 GB no hay de dónde sacar más sin quitársela
a los programas, que terminarían en el archivo de paginación: justo lo que se quiere evitar. Los tweaks que circulan:

| Tweak | Qué promete | Veredicto |
|---|---|---|
| `LargeSystemCache = 1` | Más caché de archivos | **No.** Es para servidores: le da prioridad a la caché por sobre los programas, y algunos drivers se portan mal con él ([TweakHound](https://www.tweakhound.com/2011/09/20/bad-tweaks/)). |
| `fsutil behavior set memoryusage 2` | Más memoria para NTFS | **No.** Microsoft dice que ayuda cuando se abren muchísimos archivos *y sobra memoria*; si no, le quita memoria al resto ([Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior)). |
| `IoPageLockLimit` | "Buffer para el disco" | **Mito:** Windows lo ignora. |
| Caché de escritura del disco | Que Windows no espere a que el disco termine cada escritura | **Sí.** Viene activada; el script se asegura de que lo esté. |
| Desactivar el vaciado del búfer de caché de escritura | Que Windows ni siquiera espere a que el disco confirme cada escritura | **Sí, por decisión.** Se gana tiempo en cada escritura. El costo: ante un corte de luz se pueden perder o corromper los últimos cambios, y el propio cartel de Windows pide no marcarlo salvo que el disco tenga alimentación aparte ([Raymond Chen](https://devblogs.microsoft.com/oldnewthing/20130416-00/?p=4643)). Acá importa más el tiempo que esos datos: quien mantiene este repo lo usa así hace años sin problemas. En un SSD no se toca, y la opción 5 lo revierte. |
| Archivo de paginación fijo | Que no crezca de a pedazos | **Sí.** El automático arranca chico y crece cuando hace falta. En un disco lento, mientras crece, los programas pueden fallar por falta de memoria ([Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/slow-page-file-growth-memory-allocation-errors)), y crecer y achicarse lo fragmenta ([Microsoft](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921)). El script lo deja **fijo en el doble de la RAM instalada**: con 2 GB, 4096 MB. Es la experiencia de quien mantiene este repo, y queda por encima del 1,5 veces la RAM que recomienda Microsoft como mínimo inicial. Fijo, nunca cambia de tamaño, y entre RAM y paginación hay hasta 6 GB para los programas. Si no hay espacio libre suficiente, queda como estaba. |
| `fsutil behavior set mftzone` | Que la tabla de archivos (MFT) no se fragmente | **No.** Solo sirve en discos con muchísimos archivos chicos; la reserva ya existe. |

### ReadyBoost: lo único pensado justo para "los fragmentos"

ReadyBoost no es RAM: es una caché de **lecturas chicas y dispersas** en un pendrive o una tarjeta SD. Es exactamente
lo que un disco mecánico hace peor: cada salto del cabezal tarda milisegundos, y una memoria flash no tiene cabezal.
Las lecturas grandes y seguidas las sigue haciendo el disco, que en eso es más rápido
([Wikipedia](https://en.wikipedia.org/wiki/ReadyBoost), [Microsoft](https://learn.microsoft.com/en-us/archive/blogs/tomarcher/readyboost-qa)).

Lo que dicen las pruebas: ayuda sobre todo con 1 GB de RAM o menos, y con 2 GB la diferencia es chica. En pruebas con
PCMark dio entre 1% y 2% más con 4 GB, y 1% **menos** en una notebook con 2 GB
([Digital Citizen](https://www.digitalcitizen.life/does-readyboost-work-does-it-improve-performance-slower-pcs/),
[How-To Geek](https://www.howtogeek.com/123780/htg-explains-is-readyboost-worth-using/)). En un Atom hay un costo
más: ReadyBoost cifra todo lo que guarda, y estos Atom no tienen instrucciones para cifrar
([AES-NI](https://en.wikipedia.org/wiki/AES_instruction_set)): lo hacen a pura fuerza.

Por eso no está en el script: hace falta hardware y la ganancia es incierta. Si querés probarlo en una netbook:

1. Usá la ranura de tarjetas SD: la tarjeta queda adentro y no ocupa un USB. Una decente (clase 10 o A1) de 4 a 16 GB alcanza.
2. *Este equipo >* botón derecho en la tarjeta *> Propiedades > ReadyBoost > Dedicar este dispositivo a ReadyBoost.*
   Si Windows dice que es lenta, no sirve: probá otra.
3. Usala una semana. Si no notás diferencia, sacala: no se rompe nada.

La opción 1 deja SysMain activo, que es lo que ReadyBoost necesita, y la opción 2 muestra si está en uso. Con un SSD, ReadyBoost no tiene sentido.

### Lo que de verdad ataca los fragmentos

1. **Desfragmentar:** la pasada semanal, que el script deja activa, y la opción 4 de vez en cuando.
2. **Dejar al menos 15% libre:** con menos, defrag solo desfragmenta en parte. La opción 4 avisa.
3. **El archivo de paginación fijo**, que hace el script. Si ya está muy fragmentado, se desfragmenta al
   arranque con UltraDefrag (ver [Desfragmentar](#desfragmentar-sirve-el-de-windows)).
4. **Revisar el cabezal del disco.** Muchos discos de notebook estacionan el cabezal a los pocos segundos sin uso, para
   ahorrar energía, y volver a leer tarda hasta un par de segundos: las típicas congeladas cortas. Con
   [CrystalDiskInfo](https://crystalmark.info/en/software/crystaldiskinfo/) mirá el recuento de ciclos de carga y
   descarga (*Load/Unload Cycle Count*): si sube de a miles por día, es eso. Se corrige subiendo la administración de
   energía del disco (APM) a 254 desde el mismo programa, pero en la mayoría de los discos hay que repetirlo en cada
   arranque, y eso implica dejar un programa residente: no lo automatizo ([detalle](https://commonemitter.blogspot.com/2019/09/disabling-hdd-apm.html)).
5. **Un SSD**, que termina con el problema de raíz.

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
| `fsutil behavior set memoryusage 2`, `mftzone` | Más memoria para NTFS y más reserva para la MFT: con 2 GB y un disco de uso normal, no ayudan. Ver [Caché de disco](#caché-de-disco-readyboost-y-las-optimizaciones-de-windows). |
| Deshabilitar la desfragmentación | En HDD es necesaria. El script se asegura de que esté **activa**. Para una pasada a fondo, ver [Desfragmentar](#desfragmentar-sirve-el-de-windows). |
| "Limpiadores de RAM" | Contraproducentes: Windows vuelve a cargar todo desde el disco lento. |
| Vaciar `Prefetch` entero, o en cada arranque | Lo que hacen algunos "limpiadores": se lleva también el rastro de arranque, y los arranques siguientes son más lentos. El script borra solo las entradas de programas. |
| `Dism /SPSuperseded` | Limpia restos de *Service Packs*, que Windows 10 no tiene. Ver [Limpiar restos de Windows Update](#limpiar-restos-de-windows-update-vale-la-pena). |
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

- **Wine (el `cmd.exe` de Wine):** el menú y sus seis opciones corren de punta a punta, una tras otra, con distintas
  combinaciones de respuestas (por ejemplo: con y sin impresora, con y sin quitar apps).
  El menú se probó con entradas torpes: Enter solo, letras, números de más, comillas, `&` y `%PATH%`.
  Se simuló el estado que deja el script original (y políticas que apagan Defender y Windows Update)
  y se verificó en el registro que cada valor quedara corregido y escrito en `HKEY_USERS\<SID>` del usuario.
  También se probó el ciclo completo optimizar, revertir y verificar: el inicio rápido queda apagado, *Suspender* e
  *Hibernar* salen del menú de apagado, y la opción 5 los devuelve.
- **PowerShell:** los 33 bloques de PowerShell pasan el parser oficial. La lógica de apps en segundo plano se probó con
  nombres reales de paquetes.
- **Limpieza:** la sección que vacía los temporales se **ejecutó de verdad** sobre un árbol de carpetas simulado, con
  trampas (y una carpeta Prefetch de mentira, donde solo se fueron las entradas de programas): un enlace a una carpeta valiosa (no la siguió), archivos de solo lectura (los borró), archivos imposibles de
  borrar (los salteó y los contó), la carpeta del propio script (no la tocó) y un intento de vaciar la carpeta de
  Windows entera (lo bloqueó).
- **Netbook simulada:** una G4 (Atom N2600, 1 GB, video sin driver, con antirrobo) muestra los tres avisos.
  El registro del Visualizador de fotos se verificó valor por valor contra el `.reg` de referencia, incluidos los
  íconos con `%SystemRoot%`, con comillas o inexistentes.
- **Formato:** ASCII puro y fin de línea CRLF (con LF, `cmd` puede fallar al saltar a etiquetas).

Lo que **no** se pudo probar acá: los servicios, Defender, la energía, la caché de escritura del disco, las apps y
Restaurar sistema.
Wine no los implementa, así que falta la prueba en un Windows 10 real. Para eso está la sección siguiente.

## Cómo probarlo en UTM (Mac) antes de usarlo en una PC real

1. Creá una VM de **Windows 10 x64 22H2** con **2 GB de RAM** y 2 núcleos, igual que la PC vieja.
   En una Mac con Apple Silicon, UTM emula x86_64: va a andar lento, pero para probar alcanza.
2. Terminá la instalación, conectala a internet y dejala actualizar un rato.
3. Abrí `OptimizarPC.bat`, elegí la opción 2 y guardá el reporte (queda en un `.txt` al lado del script).
4. **Sacá un snapshot de la VM.** Es el "deshacer" más confiable que existe.
5. (Opcional) Corré el script original (v1), después la opción 2, y probá la opción 6.
6. Volvé al snapshot, elegí la opción 1, reiniciá y elegí la opción 2 otra vez.
7. Checklist de cosas que **no** tienen que romperse:
   - [ ] Escribir en el menú Inicio y que la búsqueda encuentre apps (por ejemplo, "calc").
   - [ ] Escribir en Configuración y en alguna app de la Store (Calculadora).
   - [ ] *Configuración > Windows Update > Buscar actualizaciones* funciona.
   - [ ] La Store abre y descarga una app.
   - [ ] *Seguridad de Windows*: protección en tiempo real encendida y firmas actualizadas.
   - [ ] Sonido, red, hora correcta y el portapapeles (Ctrl+C y Ctrl+V).
   - [ ] Edge abre y navega.
   - [ ] Una foto JPG abre con el Visualizador de fotos (después de elegirlo en Aplicaciones predeterminadas) y Alt+Tab muestra íconos.
   - [ ] El resumen de la limpieza muestra lo liberado por carpeta y los archivos salteados.
   - [ ] `C:\Windows\Prefetch` conserva `Layout.ini`, `NTOSBOOT-B00DFAAD.pf` y la carpeta `ReadyBoot`.
   - [ ] Win+Shift+S abre el recorte de pantalla (Recortes y anotación sigue instalado).
   - [ ] Al arrastrar una ventana se ve su contenido, y las carpetas con fotos muestran íconos.
   - [ ] Con Adobe Reader instalado: no aparece en *Administrador de tareas > Inicio*, y el servicio *Adobe Acrobat
     Update Service* está deshabilitado.
   - [ ] (Opcional) La opción 3 analiza, limpia y muestra lo liberado sin errores.
   - [ ] El menú de apagado muestra *Apagar* y *Reiniciar*, sin *Suspender* ni *Hibernar*.
   - [ ] El botón de encendido apaga la PC por completo. En UTM se prueba con el botón de apagado de la ventana de la
     VM (el apagado normal, no el forzado), que le manda a Windows la misma señal que el botón físico.
   - [ ] En la netbook real: cerrar la tapa la apaga (la VM no tiene tapa).
   - [ ] *Propiedades del sistema > Protección del sistema* dice "Desactivado".
   - [ ] La opción 2 muestra la paginación fija en el doble de la RAM, la caché de escritura activada y el vaciado del búfer
     desactivado.
   - [ ] En el menú, Enter solo elige la opción 1 y un número inválido vuelve al menú.
8. Probá la opción 5 y verificá que todo vuelva a la normalidad.

Pasame los reportes de la opción 2 y lo que haya fallado del checklist, y lo ajustamos.

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
- **Prefetch:** [Ryan Myers, Microsoft](https://learn.microsoft.com/en-us/archive/blogs/ryanmy/misinformation-and-the-the-prefetch-flag), [Ed Bott](https://edbott.com/2005/06/01/one-more-time-do-not-clean-out-your-prefetch-folder/).
- **Inicio rápido:** cómo funciona y sus contras, en [Winbuzzer](https://winbuzzer.com/2020/05/19/how-to-disable-windows-10-fast-startup-hiberboot-hybrid-boot-hybrid-shutdown-xcxwbt/); caso de CPU alta, en [HP Community](https://h30434.www3.hp.com/t5/Notebook-Boot-and-Lockup/Fast-startup-causing-high-cpu-usage/td-p/7888113).
- **Energía:** valores de [botones y tapa](https://learn.microsoft.com/en-us/windows-hardware/customize/power-settings/power-button-and-lid-settings)
  y de [batería crítica](https://learn.microsoft.com/en-us/answers/questions/823581/powercfg-command-line-for-editing-the-existing-val)
  (0 nada, 1 suspender, 2 hibernar, 3 apagar), [opciones de `powercfg`](https://learn.microsoft.com/windows-hardware/design/device-experiences/powercfg-command-line-options),
  tamaño de `hiberfil.sys` (40% de la RAM; 20% si es el reducido, que solo sirve para el inicio rápido) en
  [ElevenForum](https://www.elevenforum.com/t/specify-hibernation-file-type-as-full-or-reduced-in-windows-11.1955/),
  y *Suspender* en el menú (`FlyoutMenuSettings`) en [TenForums](https://www.tenforums.com/tutorials/7456-add-remove-sleep-power-menu-windows-10-a.html).
- **Adobe Reader:** qué hacen `armsvc.exe` y `AdobeARM.exe` en [Techdows](https://techdows.com/2014/06/how-to-disable-or-stop-armsvc-exe-of-adobe-reader.html)
  y [gHacks](https://www.ghacks.net/2010/04/09/adobearm-exe-and-reader_sl-exe/); la entrada *RunOnce* del Speed Launcher en
  [Dell Community](https://www.dell.com/community/en/conversations/virus-spyware/adobe-reader-11010-update-adds-run-once-entry-for-speed-launcher/647f4d26f4ccf8a8de5e0bee?commentId=647f4d60f4ccf8a8de61d495&page=2);
  la carpeta de actualizaciones bajadas en [Adobe Community](https://community.adobe.com/t5/acrobat-discussions/multiple-acrordrdcupd-msi-files-taking-up-space/td-p/13858757);
  la caché `AcroCef` en [Adobe Community](https://community.adobe.com/t5/acrobat-discussions/when-open-a-pdf-file-a-file-created-quot-debug-log-quot/m-p/12466171).
- **Limpieza de WinSxS:** [Microsoft Learn](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder);
  `/SPSuperseded` es para Service Packs ([Microsoft](https://learn.microsoft.com/en-us/archive/blogs/joscon/how-to-reclaim-space-after-applying-windows-72008-r2-service-pack-1));
  error `0x800F0806` por operaciones pendientes ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/2192270/dism-startcomponentcleanup-give-error-0x800f0806-t)).
- **Caché y paginación:** crecimiento lento del archivo de paginación ([Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/slow-page-file-growth-memory-allocation-errors)),
  tamaños del automático ([Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/how-to-determine-the-appropriate-page-file-size-for-64-bit-versions-of-windows)),
  paginación dinámica y fragmentación ([Microsoft Tech Community](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921)),
  `memoryusage` y `mftzone` ([`fsutil behavior`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/fsutil-behavior)),
  vaciado del búfer ([Raymond Chen](https://devblogs.microsoft.com/oldnewthing/20130416-00/?p=4643)),
  estado de la caché de escritura ([`Get-StorageAdvancedProperty`](https://learn.microsoft.com/en-us/powershell/module/storage/get-storageadvancedproperty)),
  `LargeSystemCache` ([TweakHound](https://www.tweakhound.com/2011/09/20/bad-tweaks/)).
- **ReadyBoost:** [Wikipedia](https://en.wikipedia.org/wiki/ReadyBoost), [Microsoft](https://learn.microsoft.com/en-us/archive/blogs/tomarcher/readyboost-qa),
  [Digital Citizen](https://www.digitalcitizen.life/does-readyboost-work-does-it-improve-performance-slower-pcs/), [How-To Geek](https://www.howtogeek.com/123780/htg-explains-is-readyboost-worth-using/).
  Cabezal estacionado (APM): [Common Emitter](https://commonemitter.blogspot.com/2019/09/disabling-hdd-apm.html).
- **Qué hay en la carpeta Prefetch:** [Prefetcher](https://en.wikipedia.org/wiki/Prefetcher), [ReadyBoot y SuperFetch](https://en.wikipedia.org/wiki/Windows_Vista_I/O_technologies).
- **Restaurar sistema:** desactivarlo borra los puntos, según [TenForums](https://www.tenforums.com/tutorials/99782-enable-disable-system-restore-windows-3.html).
- **Desfragmentador:** [límite de 64 MB](https://techcommunity.microsoft.com/blog/askperf/disk-fragmentation-and-system-performance/372921), [parámetros de `defrag`](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/defrag), [UltraDefrag](https://en.wikipedia.org/wiki/UltraDefrag).
- **Desenfoque del inicio de sesión:** `DisableAcrylicBackgroundOnLogon`, tweak *Logon Screen Acrylic Blur* de WinUtil.
- **Precarga de apps (MMAgent):** [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/mmagent/disable-mmagent).
- **Netbooks de Conectar Igualdad:** generaciones y hardware en [netbookdelgobierno.com](https://www.netbookdelgobierno.com/2015/08/modelos-de-netbook-de-conectar-igualdad.html) y [Utiltecnico](https://www.utiltecnico.com/2021/08/todo-sobre-las-netbooks-conectar-igualdad-del-gobierno-argentino/). Windows 10 en estas netbooks: [Underc0de](https://underc0de.org/foro/dudas-generales-121/problemas-netbook-conectar-igualdad/).
- **GMA 3600 sin driver para Windows 10:** [Intel Community](https://community.intel.com/t5/Graphics/Intel-GMA-3600-amp-Windows-10/m-p/460312), [Intel Community (32 bits)](https://community.intel.com/t5/Graphics/Windows-10-Intel-Graphics-Adapter-3600/m-p/486688). GMA 3150 con driver de Windows Update: [Intel Community](https://community.intel.com/t5/Graphics/Intel-GMA-3150-drivers-for-Windows-8-1-10/m-p/398142).
- **RAM máxima del N2600:** [Intel](https://www.intel.com/content/www/us/en/products/sku/58916/intel-atom-processor-n2600-1m-cache-1-6-ghz/specifications.html). 32 contra 64 bits con 2 GB: [TenForums](https://www.tenforums.com/general-support/71501-32bit-vs-64bit-2gb-ram.html).
- **Antirrobo Theft Deterrent:** [manual del referente (Neuquén)](https://educaciondigital.neuquen.gov.ar/wp-content/uploads/2018/04/ManualdelReferente2016-1.pdf), [instalador para Windows 10 (técnicos Conectar)](https://groups.google.com/g/tecnicosconectar/c/24jhzaqOYKA), [configuración del agente](http://itibonzi.blogspot.com/2014/05/como-activar-y-configurar-el-agente-tda.html).
- **Visualizador de fotos:** registro de referencia del [códec JPEG-LS de CharLS](https://github.com/team-charls/jpegls-wic-codec/blob/main/restore-windows-photo-viewer.reg) y [gist con las asociaciones](https://gist.github.com/ebrasha/02e5c6fa895e0e3f8c65103c89440092). Alt+Tab clásico: [Winaero](https://winaero.com/how-to-get-the-old-alt-tab-dialog-in-windows-10/).
- **ESU extendido a 2027:** [BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-quietly-extends-free-windows-10-esu-support-to-october-2027/), [Help Net Security](https://www.helpnetsecurity.com/2026/06/26/microsoft-windows-10-free-security-updates-esu-program/).
