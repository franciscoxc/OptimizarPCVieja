# Prueba DeFabrica, la que decide que programas de fabrica desinstala la opcion 1: lo
# que se tiene que ir y, sobre todo, lo que no. Un patron de mas se lleva un driver o
# el programa del boton Escanear, y nadie lo nota hasta que el cliente quiere escanear.
# Corre en Linux o en Windows con PowerShell 7: no necesita nada de Windows.
$ErrorActionPreference = 'Stop'
$bat = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..' 'OptimizarPC.bat'))
$i = $bat.IndexOf('$fabrica = @(')
$j = $bat.IndexOf('function EsetVencido')
if ($i -lt 0 -or $j -lt $i) { Write-Output 'No se encontro la lista de fabrica en el .bat.'; exit 1 }
. ([scriptblock]::Create($bat.Substring($i, $j - $i)))
# La del .bat mira el disco: aca se elige si el programa de Dropbox esta o no.
$dropbox = $false
function DropboxInstalado { return $dropbox }

# Editor, nombre y si se tiene que ir.
$casos = @(
    @('HP Inc.', 'HP JumpStart Bridge', $true),
    @('HP Inc.', 'HP System Event Utility', $false),
    @('Hewlett-Packard', 'HP Recovery Manager', $false),
    @('WildTangent', 'Un juego cualquiera', $true),
    @('Dropbox, Inc.', 'Dropbox 25 GB', $true),
    @('Dropbox, Inc.', 'Dropbox', $false),
    @('Seiko Epson Corporation', 'Epson Software Updater', $true),
    @('Seiko Epson Corporation', 'Epson Scan 2', $false),
    @('SEIKO EPSON CORPORATION', 'Epson Event Manager', $false),
    @('', 'Manual Epson L3250', $true),
    @('Brother Industries, Ltd.', 'StatusMonitor', $true),
    @('Brother Industries, Ltd.', 'ControlCenter4', $false),
    @('Otra Empresa', 'StatusMonitor', $false),
    @('Lavasoft', 'Web Companion', $true),
    @('Wondershare Software', 'Wondershare Filmora 11', $true),
    @('Microsoft Corporation', 'Windows PC Health Check', $true),
    @('Microsoft Corporation', ('Comprobaci' + [char]0xF3 + 'n de estado de PC Windows'), $true),
    @('Microsoft Corporation', 'Microsoft Office Professional Plus 2016', $false)
)
$fallas = @()
function Probar([string]$Editor, [string]$Nombre, [bool]$Esperado, [string]$Nota = '') {
    $dio = [bool](DeFabrica ([pscustomobject]@{ Publisher = $Editor; DisplayName = $Nombre }))
    if ($dio -ne $Esperado) { $script:fallas += ('"' + $Nombre + '" de "' + $Editor + '"' + $Nota + ': dio ' + $dio + ', se esperaba ' + $Esperado) }
}
foreach ($c in $casos) { Probar $c[0] $c[1] $c[2] }
# El ayudante de actualizacion de Dropbox se va solo si el programa no esta.
Probar 'Dropbox, Inc.' 'Dropbox Update Helper' $true ' sin el programa'
$dropbox = $true
Probar 'Dropbox, Inc.' 'Dropbox Update Helper' $false ' con el programa'

if ($fallas) { Write-Output 'La lista de fabrica fallo:'; $fallas | ForEach-Object { Write-Output ('  - ' + $_) }; exit 1 }
Write-Output ('Fabrica en orden: ' + ($casos.Count + 2) + ' casos, se va lo que sobra y queda lo que hace falta.')
