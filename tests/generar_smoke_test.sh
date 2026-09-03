#!/usr/bin/env bash
# Smoke test del CLI generate_flyer.js: genera los 7 builders de la app
# (carrusel de paquete, carrusel de curso, tarjeta clásica de curso 4:5+16:9,
# visual de datos para redes, flyer de curso LinkedIn/X, tarjeta de tip/paquete,
# tarjeta de descuento 4:5+1:1+16:9) con datos de prueba fijos y verifica que
# cada uno termine sin error y produzca un archivo no vacío. No compara
# contenido pixel a pixel: solo "generó algo razonable sin crashear".
#
# Uso:
#   tests/generar_smoke_test.sh
#
# Requiere: node (ver NODE_BIN abajo), Google Chrome en /usr/bin/google-chrome
# (mismo binario que usa generate_flyer.js vía Playwright).

set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

NODE_BIN="/home/linuxbrew/.linuxbrew/bin/node"
[ -x "$NODE_BIN" ] || NODE_BIN="$(command -v node)"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

PASS=0
FAIL=0
FAILURES=()

# min_bytes es deliberadamente bajo (no pixel-perfect): solo descarta 0 bytes
# o archivos truncados/corruptos evidentes.
MIN_PNG_BYTES=2000
MIN_HTML_BYTES=500

log_pass() { echo "  OK  - $1"; PASS=$((PASS + 1)); }
log_fail() { echo "  FAIL - $1"; FAIL=$((FAIL + 1)); FAILURES+=("$1"); }

check_file() {
  local path="$1" min_bytes="$2" label="$3"
  if [ ! -f "$path" ]; then
    log_fail "$label: no se generó $path"
    return 1
  fi
  local size
  size=$(stat -c%s "$path" 2>/dev/null || stat -f%z "$path")
  if [ "$size" -lt "$min_bytes" ]; then
    log_fail "$label: $path tiene solo $size bytes (esperado >= $min_bytes)"
    return 1
  fi
  log_pass "$label: $path ($size bytes)"
  return 0
}

check_no_google_fonts() {
  local path="$1" label="$2"
  if [ ! -f "$path" ]; then
    return 1
  fi
  if grep -qE 'fonts\.(googleapis|gstatic)\.com' "$path"; then
    log_fail "$label: $path referencia Google Fonts online (regresión del fix de fuentes embebidas)"
    return 1
  fi
  log_pass "$label: sin referencias a Google Fonts"
  return 0
}

run_node() {
  local desc="$1"
  shift
  if "$NODE_BIN" "$@" > "$WORKDIR/last_stdout.log" 2>&1; then
    log_pass "$desc: exit 0"
    return 0
  else
    log_fail "$desc: exit $? — ver $WORKDIR/last_stdout.log"
    echo "----- stdout/stderr -----"
    cat "$WORKDIR/last_stdout.log"
    echo "--------------------------"
    return 1
  fi
}

echo "== Smoke test: generate_flyer.js (7 builders) =="
echo "Node: $NODE_BIN"
echo "Workdir temporal: $WORKDIR"
echo

# ---------------------------------------------------------------
# 1. Carrusel de paquete de R (4 slides, 1080x1080)
# ---------------------------------------------------------------
echo "-- 1. Carrusel de paquete --"
CFG="$WORKDIR/carousel.json"
OUT_DIR="$WORKDIR/carousel"
cat > "$CFG" <<JSON
{
  "template": "carousel",
  "output_dir": "$OUT_DIR",
  "pkg_nombre": "janitor",
  "categoria": "Paquete de R",
  "version_line": "v2.2.0 - CRAN - Sam Firke",
  "autor_line": "janitor - GitHub: sfirke/janitor",
  "slide1_tagline": "Limpieza de datos en R, sin esfuerzo",
  "slide2_titulo": "Para que sirve?",
  "slide2_desc": "Limpia nombres de columnas y filas vacias automaticamente.",
  "slide2_bullets": ["Nombres de columnas consistentes", "Detecta filas/columnas vacias", "Tablas de frecuencia rapidas"],
  "slide3_titulo": "En la practica",
  "slide3_codigo": "datos <- datos |>\n  clean_names()",
  "slide4_tagline": "Seguinos para mas tips de R",
  "redes": ["Instagram", "X / Twitter", "LinkedIn"]
}
JSON
if run_node "carousel: render" generate_flyer.js --config "$CFG"; then
  for n in 01 02 03 04; do
    check_file "$OUT_DIR/slide_$n.png" "$MIN_PNG_BYTES" "carousel: slide_$n.png"
  done
fi
echo

# ---------------------------------------------------------------
# 2. Carrusel de anuncio de curso (plan variable, v2.8.0+)
# ---------------------------------------------------------------
echo "-- 2. Carrusel de curso --"
CFG="$WORKDIR/carousel_curso.json"
OUT_DIR="$WORKDIR/carousel_curso"
cat > "$CFG" <<JSON
{
  "template": "carousel_curso",
  "output_dir": "$OUT_DIR",
  "plan": ["portada", "aprender", "llevas", "cta", "contacto"],
  "nombre": "Introduccion a R para Ciencias Sociales",
  "badge": "Curso virtual",
  "tagline": "Aprende a analizar datos con R desde cero",
  "fecha_inicio": "22 de septiembre",
  "s2_bullets": ["Introduccion a R y RStudio", "Manejo de datos con tidyverse"],
  "llevas_bullets": ["Certificado de participacion", "Acceso a la comunidad"],
  "cta": "INSCRIPCION ABIERTA",
  "s4_instr": "Escribinos",
  "s4_palabra": "INFO",
  "s4_refuerzo": "y te contamos todo",
  "redes": ["Instagram", "LinkedIn"]
}
JSON
if run_node "carousel_curso: render" generate_flyer.js --config "$CFG"; then
  for n in 01 02 03 04 05; do
    check_file "$OUT_DIR/slide_$n.png" "$MIN_PNG_BYTES" "carousel_curso: slide_$n.png"
  done
fi
echo

# ---------------------------------------------------------------
# 3. Tarjeta clasica de curso (4:5 + 16:9)
# ---------------------------------------------------------------
echo "-- 3. Tarjeta clasica de curso --"
CFG="$WORKDIR/tarjeta_curso.json"
OUT_DIR="$WORKDIR/tarjeta_curso"
cat > "$CFG" <<JSON
{
  "template": "tarjeta_curso",
  "output_dir": "$OUT_DIR",
  "fondo": "azul",
  "titulo": "R para el tratamiento de Hojas de Calculo",
  "tagline": "El remedio para tus datos desordenados",
  "items": [
    {"icon":"bx-laptop","strong":"Modalidad:","text":"Sincronica/Asincronica"},
    {"icon":"bx-chat","strong":"Foro de intercambio","text":"y seguimiento 24/7"},
    {"icon":"bx-calendar-check","strong":"4 semanas","text":"(10 hs. totales)"},
    {"icon":"bx-certification","strong":"Certificacion","text":"con examen final"}
  ],
  "inscripcion_texto": "INSCRIPCION ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO",
  "solo_45": false
}
JSON
if run_node "tarjeta_curso: render" generate_flyer.js --config "$CFG"; then
  check_file "$OUT_DIR/tarjeta_4x5.png" "$MIN_PNG_BYTES" "tarjeta_curso: tarjeta_4x5.png"
  check_file "$OUT_DIR/tarjeta_16x9.png" "$MIN_PNG_BYTES" "tarjeta_curso: tarjeta_16x9.png"
fi
echo

# ---------------------------------------------------------------
# 4. Visual de datos para redes (1:1 + 4:5 + 16:9)
# ---------------------------------------------------------------
echo "-- 4. Visual de datos para redes --"
CFG="$WORKDIR/viz_redes.json"
OUT_DIR="$WORKDIR/viz_redes"
cat > "$CFG" <<JSON
{
  "template": "viz_redes",
  "output_dir": "$OUT_DIR",
  "badge": "DATOS",
  "titulo": "La ropa bajo, los paquetes turisticos subieron",
  "fuente": "Fuente: INDEC - IPC julio 2026",
  "handles": "@estacion.erre",
  "formatos": ["1x1", "4x5", "16x9"]
}
JSON
if run_node "viz_redes: render" generate_flyer.js --config "$CFG"; then
  for fmt in 1x1 4x5 16x9; do
    check_file "$OUT_DIR/viz_$fmt.png" "$MIN_PNG_BYTES" "viz_redes: viz_$fmt.png"
  done
fi
echo

# ---------------------------------------------------------------
# 5. Flyer de curso LinkedIn/X (PNG + HTML standalone)
# ---------------------------------------------------------------
echo "-- 5. Flyer de curso (LinkedIn/X) --"
CFG="$WORKDIR/curso.json"
cat > "$CFG" <<JSON
{
  "template": "curso",
  "formato": "linkedin",
  "badge_texto": "Curso virtual",
  "badge_color": "Azul ER",
  "titulo": "Introduccion a R para Ciencias Sociales",
  "subtitulo": "Aprende a analizar datos con R desde cero",
  "bullets": ["Sin experiencia previa", "100% online", "Certificado"],
  "col1_texto": "4 semanas",
  "col2_texto": "Asincronico",
  "col3_texto": "Certificado",
  "footer_texto": "Inscripcion abierta",
  "footer_icon": "Megafono"
}
JSON
OUT_PNG="$WORKDIR/curso.png"
if run_node "curso: render PNG" generate_flyer.js --config "$CFG" --output "$OUT_PNG"; then
  check_file "$OUT_PNG" "$MIN_PNG_BYTES" "curso: curso.png"
fi
OUT_HTML="$WORKDIR/curso.html"
if run_node "curso: render HTML" generate_flyer.js --config "$CFG" --output "$OUT_HTML"; then
  check_file "$OUT_HTML" "$MIN_HTML_BYTES" "curso: curso.html"
  check_no_google_fonts "$OUT_HTML" "curso.html"
fi
echo

# ---------------------------------------------------------------
# 6. Tarjeta de tip / paquete de R (PNG + HTML standalone)
# ---------------------------------------------------------------
echo "-- 6. Tarjeta de tip / paquete --"
CFG="$WORKDIR/tip.json"
cat > "$CFG" <<JSON
{
  "template": "tip",
  "categoria": "Paquete de R",
  "pkg_nombre": "janitor",
  "version_line": "v2.2.0 - CRAN - Sam Firke",
  "descripcion": "Limpieza de datos en R, sin esfuerzo.",
  "codigo": "datos <- datos |>\n  clean_names()",
  "autor_line": "janitor - GitHub: sfirke/janitor"
}
JSON
OUT_PNG="$WORKDIR/tip.png"
if run_node "tip: render PNG" generate_flyer.js --config "$CFG" --output "$OUT_PNG"; then
  check_file "$OUT_PNG" "$MIN_PNG_BYTES" "tip: tip.png"
fi
OUT_HTML="$WORKDIR/tip.html"
if run_node "tip: render HTML" generate_flyer.js --config "$CFG" --output "$OUT_HTML"; then
  check_file "$OUT_HTML" "$MIN_HTML_BYTES" "tip: tip.html"
  check_no_google_fonts "$OUT_HTML" "tip.html"
fi
echo

# ---------------------------------------------------------------
# 7. Tarjeta de descuento (4:5 + 1:1 + 16:9)
# ---------------------------------------------------------------
echo "-- 7. Tarjeta de descuento --"
CFG="$WORKDIR/descuento.json"
OUT_DIR="$WORKDIR/descuento"
cat > "$CFG" <<JSON
{
  "template": "descuento",
  "output_dir": "$OUT_DIR",
  "descuento": "30% OFF",
  "curso": "Introduccion a R para Ciencias Sociales",
  "codigo": "R2026",
  "vigencia": "Valido hasta el 30/9",
  "cta": "Aprovecha ahora",
  "formatos": ["4x5", "1x1", "16x9"]
}
JSON
if run_node "descuento: render" generate_flyer.js --config "$CFG"; then
  for fmt in 4x5 1x1 16x9; do
    check_file "$OUT_DIR/descuento_$fmt.png" "$MIN_PNG_BYTES" "descuento: descuento_$fmt.png"
  done
fi
echo

echo "== Resumen =="
echo "OK: $PASS   FAIL: $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Fallos:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
exit 0
