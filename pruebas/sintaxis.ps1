# Pasa cada seccion de PowerShell del .bat por el parser oficial, sin ejecutarla.
# Una llave o una comilla de mas no se ve hasta que la seccion corre en Windows, y
# :ps la corre con Invoke-Expression: el paso entero se cae y el resto sigue como
# si nada. Corre en Linux o en Windows con PowerShell 7.
$ErrorActionPreference = 'Stop'
$bat = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..' 'OptimizarPC.bat'))
$fallas = @()
# El .bat es CRLF: el $ de .NET corta antes del \n, no antes del \r.
$nombres = @([regex]::Matches($bat, '(?m)^#(\w+)-INICIO#\r?$') | ForEach-Object { $_.Groups[1].Value })
foreach ($n in $nombres) {
    $i = $bat.IndexOf('#' + $n + '-INICIO#'); $j = $bat.IndexOf('#' + $n + '-FIN#')
    $tokens = $null; $errores = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($bat.Substring($i, $j - $i), [ref]$tokens, [ref]$errores)
    foreach ($e in @($errores)) { $fallas += ($n + ', linea ' + $e.Extent.StartLineNumber + ': ' + $e.Message) }
}
# Los PowerShell de una linea que cmd lanza con -Command: lo que va entre comillas
# dobles, que adentro no hay (cmd no lo permite). Las variables de cmd se reemplazan.
foreach ($m in [regex]::Matches($bat, '-Command "([^"]*)"')) {
    $codigo = $m.Groups[1].Value -replace '%~\d', 'X' -replace '%[A-Za-z_][A-Za-z_0-9]*%', 'X'
    $tokens = $null; $errores = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($codigo, [ref]$tokens, [ref]$errores)
    foreach ($e in @($errores)) { $fallas += ('una linea: ' + $e.Message + ' en: ' + $codigo.Substring(0, [Math]::Min(80, $codigo.Length))) }
}
if (-not $nombres.Count) { Write-Output 'No se encontro ninguna seccion.'; exit 1 }
if ($fallas) { Write-Output 'PowerShell con errores de sintaxis:'; $fallas | ForEach-Object { Write-Output ('  - ' + $_) }; exit 1 }
Write-Output ('Sintaxis en orden: ' + $nombres.Count + ' secciones y los PowerShell de una linea pasan el parser.')
