"""Comprueba que cada call :ps NOMBRE tenga su seccion de PowerShell, y una sola.

:ps busca los marcadores #NOMBRE-INICIO# y #NOMBRE-FIN# en el archivo entero y
corre lo que hay entre los dos. Si un nombre no coincide, la seccion no corre y
nada lo avisa: el paso se saltea en silencio. Y si un marcador aparece dos veces,
IndexOf se queda con el primero, que puede ser una linea de cmd.
"""
import re
import sys
from pathlib import Path

BAT = (Path(__file__).resolve().parent.parent / "OptimizarPC.bat").read_text(encoding="ascii")

errores = []
llamadas = set(re.findall(r"^call :ps (\w+)\s*$", BAT, re.M))
# :detectar corre EQUIPO por su cuenta, porque necesita leer la salida.
llamadas.add("EQUIPO")
secciones = set(re.findall(r"^#(\w+)-INICIO#$", BAT, re.M))

for nombre in sorted(llamadas | secciones):
    ini, fin = "#%s-INICIO#" % nombre, "#%s-FIN#" % nombre
    if nombre not in llamadas:
        errores.append("la seccion %s no la llama nadie" % nombre)
    for marca in (ini, fin):
        if BAT.count(marca) != 1:
            errores.append("%s aparece %d veces: tiene que estar una sola" % (marca, BAT.count(marca)))
    if BAT.find(ini) > BAT.find(fin):
        errores.append("%s esta despues de %s" % (ini, fin))

if errores:
    print("Secciones de PowerShell con problemas:")
    print("\n".join("  - " + e for e in errores))
    sys.exit(1)
print("Secciones en orden: %s." % ", ".join(sorted(llamadas)))
