# Generador de Flyers — Estación R

App Shiny para generar piezas de difusión de Estación R (minimalista neobrutalist-light). Dos pestañas: **📸 Instagram** (carrusel de paquete de R en 4 slides 1080×1080, carrusel de anuncio de curso en 3 slides y **tarjeta clásica de curso** en 4:5 + 16:9 con 4 fondos) y **💼 LinkedIn/X** (flyer de curso y tarjeta de tip/paquete). Formulario en vivo, preview y descarga en HTML/PNG/ZIP.

**Deploy activo:** shiny-server local → `http://localhost:3838/flyer/` (en LAN: `http://192.168.0.74:3838/flyer/` — la IP cambia con la WiFi)

> **Historial del render:** la app pasó por html2canvas → webshot2 → dom-to-image (client-side, para shinyapps.io) → **Playwright server-side (actual)**. Las versiones anteriores quedan en la historia de git como referencia (`4c39755` es la última client-side). El deploy de shinyapps.io fue purgado el 2026-08-30; el único destino es el shiny-server local.

## Características

- Instagram: carrusel de paquete (4 slides), carrusel de curso (3 slides, sin precio) y **tarjeta clásica de curso** — feed 4:5 (1080×1350) + horizontal 16:9 (1920×1080), fondos negro/azul/amarillo/blanco con paleta adaptativa, título en Array, badge CURSOS (solo 4:5), caja central con imagen opcional o isotipo, 4 ítems editables (emoji + negrita + texto)
- Dos plantillas: **Curso** y **Tip / Paquete de R** (tarjeta con header azul, código R resaltado — comentarios, funciones, strings y args — y footer amarillo)
- Curso: formulario en vivo (formato/red, imagen, badge, título, contenidos, columnas de info, destacado)
- Tres formatos de salida para curso: vertical feed/LinkedIn (4:5), cuadrado Instagram (1:1), story/WhatsApp (9:16)
- Preview en vivo con branding ER: borde negro, sombra dura amarilla `#EAFF38`, paleta oficial, Ubuntu / Ubuntu Mono
- Descarga **HTML** (CSS y logo embebidos, abre solo) y **PNG** (render server-side)
- Íconos SVG de Boxicons (los mismos de estacion-r.com/courses)

## Arquitectura

El PNG se renderiza del lado del servidor:

1. `app.R` arma un JSON con el contenido del formulario
2. Lo pasa a `generate_flyer.js` vía `system2()`: `node generate_flyer.js --config <json> --output <png>`
3. El script arma el HTML, lo abre con Playwright (Chrome del sistema) y captura un screenshot al tamaño del formato

```
app.R (Shiny + bslib)
 ├── UI: formulario + preview (HTML tags + css inline)
 ├── downloadHandler HTML: tags autocontenidos, logo en base64
 └── downloadHandler PNG: system2(NODE_BIN, generate_flyer.js ...)
                                      │
generate_flyer.js (Node + playwright) ┘──▶ Chrome ──▶ screenshot PNG
```

`generate_flyer.js` también funciona como CLI independiente (schema de ambos templates en el header del archivo):

```bash
node generate_flyer.js --config config.json --output flyer.png
node generate_flyer.js --config config.json --output flyer.html   # solo HTML
```

El schema del `config.json` está documentado en el header del archivo.

## Requisitos

- R ≥ 4.3 con `shiny`, `bslib`, `htmltools`, `base64enc`, `jsonlite`
- Node ≥ 20 (ver nota del entorno) y `npm install` en la raíz del repo (`playwright`)
- Google Chrome instalado

## Cómo correr

Desde el repo: `shiny::runApp()`. La app usa rutas relativas a su raíz, así que un clone fresco funciona directo.

## Deploy local (shiny-server)

```bash
cp app.R generate_flyer.js package.json /srv/shiny-server/flyer/
cp -r www design /srv/shiny-server/flyer/
cd /srv/shiny-server/flyer && npm install   # node_modules
mkdir -p app_cache && chmod 1777 app_cache  # cache de sass/bslib (usuario shiny)
touch restart.txt                           # reinicia la app en el próximo acceso
```

Notas del entorno (notebook de Estación R):

- `NODE_BIN` (en `app.R`) apunta a `/home/linuxbrew/.linuxbrew/bin/node` (v26): el `/usr/bin/node` del sistema (v18) no cumple el mínimo de `playwright`
- Los paquetes R de apt pueden quedar compilados para otra ABI de R; los del runtime viven en `/usr/local/lib/R/site-library`
- `app_cache/` va con permisos `1777` para que el usuario `shiny` escriba la cache de sass

## Estructura

- `app.R` — app completa: UI, server, CSS inline, íconos SVG
- `generate_flyer.js` — CLI de render (HTML y PNG)
- `www/` — logos de ER (clásico + 3 tintas del branding 2026), isotipo, fuente Array (`fonts/`)
- `design/` — referencias de diseño (bocetos de próximos formatos)
- `.gitignore` — `node_modules/`, `app_cache/`, `restart.txt`, `rsconnect/`, etc.

## Branding

Toda pieza visual respeta el spec de [estacion-r-branding](https://github.com/Estacion-R/estacion-r-branding): paleta oficial (Azul `#447099`, Naranja `#EE6331`, Teal `#419599`, Negro `#151515`, acento amarillo `#EAFF38`), tipografías Ubuntu / Ubuntu Mono, sombras duras estilo neobrutalista.

## Roadmap

- ~~Formato 2 — flyer de tips/paquetes de R~~ ✅ hecho en `v1.1.0` (boceto original conservado en `design/formato2_tip.html`)
- ~~Anuncio de curso en carrusel (3 slides, sin precio)~~ ✅ `v2.1.0`/`v2.1.1`
- ~~Tarjeta clásica de curso como tercer tipo~~ ✅ `v2.2.0` (4:5 + 16:9, 4 fondos)
- Ideas: variantes de la tarjeta tip (dark mode), más formatos de salida para tips (cuadrado 1:1, story)

## Convenciones de desarrollo

- `main` = deploy: repo y `/srv/shiny-server/flyer/` se mantienen **idénticos**. Verificar con `diff -r` excluyendo `.git/`, `node_modules/`, `app_cache/`, `restart.txt`
- El render PNG es **server-side** (Playwright). No volver al client-side: queda en la historia (`4c39755`) solo como referencia
- Commits con prefijo descriptivo (`feat:`, `fix:`, `docs:`, `chore:`, `deploy:`) y versiones con tags (`v1.0.0`)

## Licencia

Uso interno de Estación R. Todos los derechos reservados.