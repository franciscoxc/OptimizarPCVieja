# Prueba la funcion Vaciar del .bat, la unica que borra archivos, contra un arbol
# de prueba: borra lo comun, no sigue enlaces, no toca la carpeta del script ni
# una carpeta prohibida, y con el script en la raiz de un disco igual limpia.
# Corre en Linux o en Windows con PowerShell 7: no necesita nada de Windows.
$ErrorActionPreference = 'Stop'
$bat = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..' 'OptimizarPC.bat'))
$i = $bat.IndexOf('function Vaciar(')
$j = $bat.IndexOf('# Vacia varias carpetas')
if ($i -lt 0 -or $j -lt $i) { Write-Output 'No se encontro la funcion Vaciar en el .bat.'; exit 1 }
. ([scriptblock]::Create($bat.Substring($i, $j - $i)))

$raiz = Join-Path ([IO.Path]::GetTempPath()) ('vaciar-' + [guid]::NewGuid())
$temp = Join-Path $raiz 'Temp'
$afuera = Join-Path $raiz 'Afuera'
$carpetaScript = Join-Path $temp 'script'
New-Item -ItemType Directory -Path $temp, $afuera, $carpetaScript, (Join-Path $temp 'sub') | Out-Null
'x' | Set-Content (Join-Path $temp 'basura.tmp')
'x' | Set-Content (Join-Path $temp 'sub' 'otra.tmp')
'x' | Set-Content (Join-Path $afuera 'importante.txt')
'x' | Set-Content (Join-Path $carpetaScript 'OptimizarPC.bat')
New-Item -ItemType SymbolicLink -Path (Join-Path $temp 'enlace') -Target $afuera | Out-Null

$totalBytes = 0; $totalSalteados = 0; $totalSinPermiso = 0
$fallas = @()

$prohibidas = @($temp)
$self = $null
Vaciar 'prohibida' $temp -Callado
if (-not (Test-Path (Join-Path $temp 'basura.tmp'))) { $fallas += 'vacio una carpeta prohibida' }

$prohibidas = @()
$self = $carpetaScript
Vaciar 'prueba' $temp -Callado
if (Test-Path (Join-Path $temp 'basura.tmp')) { $fallas += 'no borro un archivo comun' }
if (Test-Path (Join-Path $temp 'sub')) { $fallas += 'no borro una subcarpeta que quedo vacia' }
if (-not (Test-Path (Join-Path $afuera 'importante.txt'))) { $fallas += 'siguio un enlace y borro afuera' }
if (-not (Test-Path (Join-Path $carpetaScript 'OptimizarPC.bat'))) { $fallas += 'borro la carpeta del script' }

'x' | Set-Content (Join-Path $temp 'nueva.tmp')
$self = [IO.Path]::GetPathRoot($temp)
Vaciar 'script en la raiz' $temp -Callado
if (Test-Path (Join-Path $temp 'nueva.tmp')) { $fallas += 'con el script en la raiz del disco no borro nada' }

Remove-Item -LiteralPath $raiz -Recurse -Force
if ($fallas) { Write-Output 'La limpieza fallo:'; $fallas | ForEach-Object { Write-Output ('  - ' + $_) }; exit 1 }
Write-Output 'Limpieza en orden: borra lo comun, no sigue enlaces y respeta lo que debe.'
