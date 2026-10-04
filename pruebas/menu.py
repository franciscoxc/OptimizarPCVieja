"""Comprueba que el menu del .bat, su despacho y la tabla del README digan lo mismo.

El numero de cada opcion esta escrito a mano en cuatro lugares: la cabecera del
.bat, el menu que se ve en pantalla, el despacho de choice a cada etiqueta y la
tabla del README. Cuando se reordeno el menu hubo que moverlos todos, y ninguno
falla a la vista si queda viejo: el texto pasa a mentir. Esto lo detecta.
"""
import re
import sys
import unicodedata
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
BAT = (RAIZ / "OptimizarPC.bat").read_text(encoding="ascii")
README = (RAIZ / "README.md").read_text(encoding="utf-8")

# Que palabra tiene que aparecer en el texto de cada opcion, segun a que
# etiqueta salta. Si se agrega una opcion, va aca.
CLAVE = {
    ":op_optimizar": "optimizar",
    ":op_limpiar_wu": "limpiar",
    ":op_desfragmentar": "desfragment",
    ":op_instalar": "instalar",
    ":op_chrome_aula": "chrome de aula",
    ":op_revertir": "revertir",
    ":op_verificar": "verificar",
    ":salir": "salir",
}


def plano(texto):
    sin_tildes = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    return sin_tildes.lower()


errores = []

teclas = re.search(r'^choice /c (\w+) /n /m "  Toca un numero', BAT, re.M).group(1)
despacho = {}
for nivel, etiqueta in re.findall(r"^if errorlevel (\d) goto (:\w+)", BAT[BAT.index(":menu"):BAT.index(":fin_con_reinicio")], re.M):
    despacho[teclas[int(nivel) - 1]] = etiqueta

menu = dict(re.findall(r"^echo {5}(\d)\. (.+)$", BAT[BAT.index(":menu"):BAT.index("choice /c " + teclas)], re.M))
cabecera = dict(re.findall(r"^:: {4}(\d)\. (.+)$", BAT[:BAT.index(":arquitectura_ok")], re.M))
tabla = dict(re.findall(r"^\| `(\d)` \| ([^|]+) \|", README, re.M))

if sorted(despacho) != sorted(teclas):
    errores.append(f"choice ofrece {teclas} pero el despacho cubre {''.join(sorted(despacho))}")
for tecla in teclas:
    etiqueta = despacho.get(tecla)
    clave = CLAVE.get(etiqueta)
    if not clave:
        errores.append(f"tecla {tecla}: salta a {etiqueta}, que no esta en CLAVE")
        continue
    lugares = {"menu": menu, "README": tabla}
    if tecla != "0":
        lugares["cabecera"] = cabecera
    for lugar, textos in lugares.items():
        texto = textos.get(tecla)
        if texto is None:
            errores.append(f"tecla {tecla}: falta en {lugar}")
        elif clave not in plano(texto):
            errores.append(f"tecla {tecla}: salta a {etiqueta}, pero en {lugar} dice {texto!r}")
    # read_text ya convierte los CRLF del .bat en saltos simples.
    if not re.search("^" + re.escape(etiqueta) + "$", BAT, re.M):
        errores.append(f"tecla {tecla}: la etiqueta {etiqueta} no existe")

if errores:
    print("El menu no coincide:")
    print("\n".join("  - " + e for e in errores))
    sys.exit(1)
print(f"Menu en orden: {len(teclas)} teclas, igual en el menu, la cabecera, el despacho y el README.")
