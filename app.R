library(shiny)
library(bslib)
library(htmltools)
library(base64enc)
library(jsonlite)

`%||%` <- function(a, b) if (!is.null(a) && nchar(a) > 0) a else b

# ---- Config ----
BADGE_COLORES <- c(
  "Azul ER"    = "#447099",
  "Naranja ER" = "#EE6331",
  "Teal ER"    = "#419599",
  "Negro"      = "#151515"
)

FORMATOS_LNK <- list(
  "Vertical — feed / LinkedIn (4:5)" = list(w = 540, h = NULL, key = "linkedin"),
  "Story / Reels — WhatsApp (9:16)"  = list(w = 380, h = 675,  key = "story")
)

PLAYWRIGHT_SCRIPT <- "generate_flyer.js"
LOGO_PATH         <- "www/logo_er.png"
NODE_BIN          <- "/home/linuxbrew/.linuxbrew/bin/node"
LOGO_B64          <- paste0("data:image/png;base64,", base64enc::base64encode(LOGO_PATH))

# ---- Tarjeta clásica de curso (4:5 + 16:9, 4 fondos) ----
TARJETA_FONDO_OPTS <- c("Negro" = "negro", "Azul" = "azul",
                        "Amarillo ER" = "amarillo", "Blanco" = "blanco")

TARJETA_FONDOS <- list(
  negro    = list(bg = "#191919", ink = "#FFFFFF", tag = "rgba(255,255,255,0.9)",
                  logo = "blanco", badge_bg = "#FFFFFF", badge_fg = "#191919",
                  circ_bg = "#FFFFFF", circ_fg = "#191919",
                  btn_bg = "#EAFF38", btn_fg = "#191919"),
  azul     = list(bg = "#405BFF", ink = "#FFFFFF", tag = "rgba(255,255,255,0.9)",
                  logo = "blanco", badge_bg = "#FFFFFF", badge_fg = "#191919",
                  circ_bg = "#FFFFFF", circ_fg = "#191919",
                  btn_bg = "#EAFF38", btn_fg = "#191919"),
  amarillo = list(bg = "#EAFF38", ink = "#191919", tag = "rgba(25,25,25,0.92)",
                  logo = "azul", badge_bg = "#405BFF", badge_fg = "#FFFFFF",
                  circ_bg = "#405BFF", circ_fg = "#FFFFFF",
                  btn_bg = "#405BFF", btn_fg = "#FFFFFF"),
  blanco   = list(bg = "#FFFFFF", ink = "#191919", tag = "rgba(25,25,25,0.85)",
                  logo = "negro", badge_bg = "#405BFF", badge_fg = "#FFFFFF",
                  circ_bg = "#405BFF", circ_fg = "#FFFFFF",
                  btn_bg = "#405BFF", btn_fg = "#FFFFFF")
)

# Tamaño de ítems (16:9) según cantidad: n=4 preserva los valores originales (v2.3.0).
TARJETA_ITEM_SIZING <- list(
  `1` = list(gap = 0,  font = 34, circle = 74, svg = 40),
  `2` = list(gap = 34, font = 31, circle = 66, svg = 36),
  `3` = list(gap = 26, font = 29, circle = 60, svg = 32),
  `4` = list(gap = 20, font = 27, circle = 54, svg = 30),
  `5` = list(gap = 16, font = 25, circle = 48, svg = 26),
  `6` = list(gap = 13, font = 23, circle = 44, svg = 24)
)
tarjeta_item_sizing <- function(n) {
  k <- max(1, min(6, if (is.null(n) || is.na(n)) 4 else n))
  TARJETA_ITEM_SIZING[[as.character(k)]]
}

TARJETA_BORDE <- 6

# Íconos Boxicons (set basic/regular, free) para los ítems de la tarjeta
TARJETA_ICON_DIR  <- "www/icons"
TARJETA_ICON_NAMES <- list.files(TARJETA_ICON_DIR, pattern = "\\.svg$")
TARJETA_ICONS <- setNames(
  lapply(TARJETA_ICON_NAMES, function(f)
    paste(readLines(file.path(TARJETA_ICON_DIR, f), warn = FALSE), collapse = "")),
  sub("\\.svg$", "", TARJETA_ICON_NAMES))
TARJETA_ICON_OPTS <- setNames(names(TARJETA_ICONS), sub("^bx-", "", names(TARJETA_ICONS)))

tarjeta_icon_svg <- function(icon, fill) {
  svg <- TARJETA_ICONS[[icon]]
  if (is.null(svg) || nchar(svg) == 0) return("")
  svg <- sub('width="24" height="24" ', "", svg, fixed = TRUE)
  svg <- sub("<svg ", paste0('<svg fill="', fill, '" '), svg, fixed = TRUE)
  svg
}

TARJETA_LOGOS <- list(
  blanco = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_blanco.png")),
  azul   = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_azul.png")),
  negro  = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_negro.png"))
)

ISOTIPO_B64 <- paste0("data:image/svg+xml;base64,",
  base64enc::base64encode("www/isotipo_estacion_r.svg"))

# ---- Visuales para redes (tab 📊): 1:1, 4:5 y 16:9 ----
VIZ_FORMATOS_OPTS <- c("1:1 — Instagram (1080×1080)" = "1x1",
                       "4:5 — Instagram feed (1080×1350)" = "4x5",
                       "16:9 — LinkedIn / X (1920×1080)" = "16x9")

ARRAY_FONT_FACE <- paste0(
  "@font-face{font-family:'Array';src:url('data:font/woff2;base64,",
  base64enc::base64encode("www/fonts/Array-Bold.woff2"),
  "') format('woff2');font-weight:700;font-style:normal;font-display:block;}")

TARJETA_FONTS <- paste0(
  "@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');",
  ARRAY_FONT_FACE)

# ---- SVG icons ----
SVG_ICON <- function(path_d, extra_path = NULL) {
  paths <- paste0('<path d="', path_d, '"/>')
  if (!is.null(extra_path)) paths <- paste0(paths, '<path d="', extra_path, '"/>')
  paste0('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" ',
         'style="width:1.5rem;height:1.5rem;fill:#447099;display:block;">',
         paths, '</svg>')
}
SVG_MOVIE_PLAY <- SVG_ICON(
  "M20 3H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm.001 6c-.001 0-.001 0 0 0h-.465l-2.667-4H20l.001 4zM9.536 9 6.869 5h2.596l2.667 4H9.536zm5 0-2.667-4h2.596l2.667 4h-2.596zM4 5h.465l2.667 4H4V5zm0 14v-8h16l.002 8H4z",
  "m10 18 5.5-3-5.5-3z")
SVG_CERTIFICATION <- SVG_ICON(
  "M2.06 14.68a1 1 0 0 0 .46.6l1.91 1.11v2.2a1 1 0 0 0 1 1h2.2l1.11 1.91a1 1 0 0 0 .86.5 1 1 0 0 0 .51-.14l1.9-1.1 1.91 1.1a1 1 0 0 0 1.37-.36l1.1-1.91h2.2a1 1 0 0 0 1-1v-2.2l1.91-1.11a1 1 0 0 0 .37-1.36L20.76 12l1.11-1.91a1 1 0 0 0-.37-1.36l-1.91-1.1v-2.2a1 1 0 0 0-1-1h-2.2l-1.1-1.91a1 1 0 0 0-.61-.46 1 1 0 0 0-.76.1L12 3.26l-1.9-1.1a1 1 0 0 0-1.36.36L7.63 4.43h-2.2a1 1 0 0 0-1 1v2.2l-1.9 1.1a1 1 0 0 0-.37 1.37l1.1 1.9-1.1 1.91a1 1 0 0 0-.1.77zm3.22-3.17L4.39 10l1.55-.9a1 1 0 0 0 .49-.86V6.43h1.78a1 1 0 0 0 .87-.5L10 4.39l1.54.89a1 1 0 0 0 1 0l1.55-.89.91 1.54a1 1 0 0 0 .87.5h1.77v1.78a1 1 0 0 0 .5.86l1.54.9-.89 1.54a1 1 0 0 0 0 1l.89 1.54-1.54.9a1 1 0 0 0-.5.86v1.78h-1.83a1 1 0 0 0-.86.5l-.89 1.54-1.55-.89a1 1 0 0 0-1 0l-1.51.89-.89-1.54a1 1 0 0 0-.87-.5H6.43v-1.78a1 1 0 0 0-.49-.81l-1.55-.9.89-1.54a1 1 0 0 0 0-1.05z")
SVG_SLACK <- SVG_ICON(
  "M20.935 12.646a1.617 1.617 0 0 0-2.022-1.034l-1.632.532c-.355-1.099-.735-2.268-1.092-3.365l.006-.002-.004-.008 1.613-.523a1.62 1.62 0 0 0 1.035-2.023 1.62 1.62 0 0 0-2.025-1.034l-1.621.527-.519-1.604a1.619 1.619 0 0 0-2.024-1.034 1.618 1.618 0 0 0-1.033 2.024l.522 1.609-3.368 1.092-.524-1.611a1.618 1.618 0 0 0-2.022-1.034 1.617 1.617 0 0 0-1.034 2.023l.524 1.616-1.662.541a1.602 1.602 0 0 0-.988 1.95c.25.856 1.152 1.373 1.979 1.092.006 0 .658-.209 1.665-.536l1.099 3.386h-.002v.002l-1.67.545a1.599 1.599 0 0 0-.987 1.949c.25.857 1.15 1.374 1.979 1.093.007 0 .659-.211 1.665-.538l.003.005a.024.024 0 0 0 .008-.002l.539 1.657a1.6 1.6 0 0 0 1.949.989c.857-.25 1.373-1.151 1.094-1.979 0-.006-.209-.654-.533-1.654l-.003-.009c1.104-.358 2.276-.739 3.376-1.098l.543 1.668a1.602 1.602 0 0 0 1.949.989c.856-.251 1.374-1.152 1.092-1.979 0-.007-.209-.659-.535-1.663l.019-.006-.003-.007 1.609-.522a1.62 1.62 0 0 0 1.035-2.024zM10.86 14.238l-1.097-3.377a.02.02 0 0 0 .005-.001v-.006c1.098-.356 2.268-.735 3.363-1.092l1.098 3.377-3.369 1.099z")

# ---- CSS app ----
css_app <- "
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');

.panel-form {
  background: #FFFFFF;
  border: 2px solid #151515;
  box-shadow: 4px 4px 0 #EE6331;
  padding: 1.5rem;
  height: fit-content;
}

.section-label {
  font-size: 0.72rem; font-weight: 700; letter-spacing: 0.1em;
  text-transform: uppercase; color: #447099;
  font-family: 'Ubuntu', sans-serif; margin-bottom: 0.5rem; display: block;
}

.btn-download {
  background: #151515; color: #EAFF38; border: 2px solid #151515;
  font-family: 'Ubuntu', sans-serif; font-weight: 700;
  padding: 0.6rem 1.5rem; width: 100%;
  text-transform: uppercase; letter-spacing: 0.08em;
  cursor: pointer; font-size: 0.85rem; margin-top: 0.5rem;
}
.btn-download:hover { background: #447099; color: #FFFFFF; }

.btn-zip {
  background: #447099; color: #FFFFFF; border: 2px solid #151515;
  font-family: 'Ubuntu', sans-serif; font-weight: 700;
  padding: 0.65rem 1.5rem; width: 100%;
  text-transform: uppercase; letter-spacing: 0.08em;
  cursor: pointer; font-size: 0.85rem; margin-top: 0.5rem;
}
.btn-zip:hover { background: #151515; color: #EAFF38; }

.slide-grid {
  display: grid;
  grid-template-columns: 540px 540px;
  gap: 1.25rem;
  padding: 1rem;
}

.slide-preview-wrap {
  width: 540px; height: 540px;
  overflow: hidden; flex-shrink: 0;
  border: 2px solid #C2C2C4;
  position: relative;
}

.slide-preview-wrap iframe {
  width: 1080px; height: 1080px; border: none;
  transform: scale(0.5); transform-origin: top left; display: block;
}

.slide-label {
  font-family: 'Ubuntu', sans-serif; font-size: 0.72rem; font-weight: 700;
  letter-spacing: 0.08em; text-transform: uppercase; color: #707073;
  margin-bottom: 0.4rem;
}

.flyer-wrap {
  display: flex; justify-content: center; align-items: flex-start; padding: 1rem;
}
"

# ---- CSS flyer LinkedIn/X ----
css_flyer <- "
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; }

.flyer-wrap { display: flex; justify-content: center; align-items: flex-start; padding: 1rem; }

.flyer {
  width: 540px; min-height: 680px; background: #FFFFFF;
  border: 2.5px solid #151515; box-shadow: 8px 8px 0 #EAFF38;
  padding: 2.5rem 2.8rem 2rem 2.8rem; font-family: 'Ubuntu', sans-serif;
  display: flex; flex-direction: column; gap: 1.4rem; position: relative;
}
.flyer-course-image {
  width: calc(100% + 5.6rem); margin: -2.5rem -2.8rem 0 -2.8rem;
  height: 180px; object-fit: cover; display: block; border-bottom: 2.5px solid #151515;
}
.flyer-badge {
  display: inline-block; background: #447099; color: #FFFFFF;
  border: 2px solid #151515; padding: 0.22rem 0.85rem;
  font-size: 0.78rem; font-weight: 700; letter-spacing: 0.08em;
  text-transform: uppercase; font-family: 'Ubuntu', sans-serif; width: fit-content;
}
.flyer-title {
  font-size: 2.2rem; font-weight: 700; color: #151515;
  font-family: 'Ubuntu', sans-serif; line-height: 1.15; letter-spacing: -0.01em; margin: 0;
}
.flyer-subtitle { font-size: 0.95rem; color: #404041; margin: 0; line-height: 1.5; }
.flyer-bullets { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.5rem; }
.flyer-bullets li { display: flex; align-items: flex-start; gap: 0.6rem; font-size: 0.95rem; color: #151515; }
.flyer-bullets li::before { content: '●'; color: #EE6331; font-size: 0.7rem; margin-top: 0.3rem; flex-shrink: 0; }
.flyer-info-grid {
  display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;
  border-top: 2px solid #151515; padding-top: 1rem; margin-top: auto;
}
.flyer-info-col { display: flex; flex-direction: column; gap: 0.25rem; }
.flyer-info-icon { font-size: 1.4rem; color: #447099; margin-bottom: 0.2rem; line-height: 1; }
.flyer-info-label { font-size: 0.68rem; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #151515; font-family: 'Ubuntu', sans-serif; }
.flyer-info-text { font-size: 0.82rem; color: #404041; line-height: 1.4; }
.flyer-footer-highlight { background: #EAFF38; border: 2px solid #151515; padding: 0.75rem 1rem; display: flex; align-items: center; gap: 0.8rem; }
.flyer-footer-highlight .footer-icon { font-size: 1.5rem; flex-shrink: 0; }
.flyer-footer-text { font-size: 0.88rem; font-weight: 700; color: #151515; font-family: 'Ubuntu', sans-serif; text-transform: uppercase; letter-spacing: 0.04em; line-height: 1.4; }
.flyer-brand { text-align: center; font-size: 0.75rem; color: #707073; font-family: 'Ubuntu', sans-serif; letter-spacing: 0.08em; border-top: 1.5px solid #C2C2C4; padding-top: 0.75rem; }
.flyer-brand img { height: 28px; display: block; margin: 0 auto 0.3rem; }
"

css_tip <- "
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }
.tip-card { width: 540px; border: 3px solid #151515; box-shadow: 10px 10px 0 #EAFF38; overflow: hidden; background: #FFFFFF; font-family: 'Ubuntu', sans-serif; }
.tip-header { background: #447099; padding: 2.2rem 2.5rem 2rem 2.5rem; position: relative; display: flex; flex-direction: column; gap: 1rem; }
.tip-header::after { content: 'R'; position: absolute; right: -0.5rem; bottom: -1.2rem; font-family: 'Ubuntu Mono', monospace; font-size: 8rem; font-weight: 700; color: rgba(255,255,255,0.08); line-height: 1; pointer-events: none; user-select: none; }
.tip-badge { display: inline-block; background: #EAFF38; color: #151515; font-family: 'Ubuntu Mono', monospace; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; padding: 0.2rem 0.7rem; border: 2px solid #151515; width: fit-content; }
.tip-nombre { font-family: 'Ubuntu Mono', monospace; font-size: 3rem; font-weight: 700; color: #FFFFFF; line-height: 1.1; letter-spacing: -0.02em; position: relative; }
.tip-nombre .brace { color: #EAFF38; font-size: 2.2rem; }
.tip-version { font-family: 'Ubuntu Mono', monospace; font-size: 0.75rem; color: rgba(255,255,255,0.55); letter-spacing: 0.08em; }
.tip-body { padding: 1.8rem 2.5rem 1.5rem 2.5rem; display: flex; flex-direction: column; gap: 1.4rem; }
.tip-desc { font-size: 0.95rem; color: #404041; line-height: 1.6; }
.tip-code { background: #F5F5F5; border: 2px solid #151515; border-left: 5px solid #447099; padding: 0.9rem 1rem; font-family: 'Ubuntu Mono', monospace; font-size: 0.82rem; color: #151515; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
.tip-code .code-comment { color: #707073; }
.tip-code .code-fn { color: #447099; font-weight: 700; }
.tip-code .code-arg { color: #EE6331; }
.tip-code .code-str { color: #419599; }
.tip-autor { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8rem; color: #707073; font-family: 'Ubuntu Mono', monospace; }
.tip-autor strong { color: #151515; }
.tip-footer { background: #EAFF38; border-top: 2px solid #151515; padding: 0.65rem 2.5rem; display: flex; align-items: center; justify-content: space-between; }
.tip-footer .brand { font-family: 'Ubuntu Mono', monospace; font-size: 0.72rem; font-weight: 700; color: #151515; letter-spacing: 0.1em; text-transform: uppercase; }
.tip-footer .url { font-family: 'Ubuntu Mono', monospace; font-size: 0.68rem; color: #404041; letter-spacing: 0.06em; }
"

# ---- CSS base para slides del carrusel (embebido en iframes) ----
CAROUSEL_BASE_CSS <- "@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; display: flex; justify-content: center; align-items: center; padding: 0; margin: 0; min-height: 100vh; }"

# ---- Highlighter R ----
highlight_r_code <- function(code) {
  esc <- gsub("&", "&amp;", code, fixed = TRUE)
  esc <- gsub("<", "&lt;", esc, fixed = TRUE)
  esc <- gsub(">", "&gt;", esc, fixed = TRUE)
  pat <- '"(?:[^"\\\\]|\\\\.)*"|#[^\\n]*|[A-Za-z_.][A-Za-z0-9_.]*(?=\\s*\\()|[A-Za-z_][A-Za-z0-9_.]*(?=\\s*=)'
  m_list <- gregexpr(pat, esc, perl = TRUE)
  m <- m_list[[1]]
  if (m[1] == -1) return(esc)
  full <- regmatches(esc, m_list)[[1]]
  lens <- attr(m, "match.length")
  clas <- vapply(seq_along(full), function(i) {
    txt <- full[i]
    if (substr(txt, 1, 1) == '"') return("code-str")
    if (substr(txt, 1, 1) == "#") return("code-comment")
    despues <- substring(esc, m[i] + lens[i], m[i] + lens[i] + 4)
    if (grepl("^\\s*\\(", despues)) return("code-fn")
    "code-arg"
  }, character(1))
  wrapped <- paste0('<span class="', clas, '">', full, '</span>')
  parts <- regmatches(esc, m_list, invert = TRUE)[[1]]
  paste0(parts[1], paste0(paste0(wrapped, parts[-1]), collapse = ""))
}

he <- function(x) htmltools::htmlEscape(x)

# ---- HTML de slides para preview (iframes) ----
slide1_html <- function(nombre, categoria, tagline, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:52px;display:block;"/>')
  else ""
  tagline_div <- if (nchar(trimws(tagline)) > 0)
    paste0('<div class="tagline">', he(tagline), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#447099;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.wm{position:absolute;right:-20px;bottom:-40px;font-family:"Ubuntu Mono",monospace;font-size:340px;font-weight:700;color:rgba(255,255,255,0.07);line-height:1;pointer-events:none;user-select:none}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.mc{flex:1;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;gap:44px;position:relative;z-index:1}
.badge{display:inline-block;background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;padding:12px 30px;border:3px solid #151515;width:fit-content}
.pn{font-family:"Ubuntu Mono",monospace;font-size:110px;font-weight:700;color:#fff;line-height:1.05;letter-spacing:-0.02em}
.br{color:#EAFF38;font-size:78px}
.tagline{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.72);line-height:1.55;max-width:820px}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:30px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:21px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="wm">R</div><div class="ctr">1 / 4</div>
  <div class="mc">
    <div class="badge">', he(categoria), '</div>
    <div class="pn"><span class="br">{</span>', he(nombre), '<span class="br">}</span></div>
    ', tagline_div, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide2_html <- function(nombre, titulo, desc, bullets, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>')
  else ""
  blist <- bullets[nchar(trimws(bullets)) > 0]
  bullets_html <- if (length(blist) > 0)
    paste0('<ul class="bul">',
      paste0('<li><span class="dot">●</span><span>', he(blist), '</span></li>', collapse = ""),
      '</ul>')
  else ""
  desc_html <- if (nchar(trimws(desc)) > 0) paste0('<p class="dsc">', he(desc), '</p>') else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#fff;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#447099;padding:52px 80px 42px;position:relative}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.pl{font-family:"Ubuntu Mono",monospace;font-size:20px;color:rgba(255,255,255,0.55);letter-spacing:0.12em;text-transform:uppercase;margin-bottom:14px}
.hn{font-family:"Ubuntu Mono",monospace;font-size:56px;font-weight:700;color:#fff;letter-spacing:-0.02em}
.br{color:#EAFF38;font-size:40px}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:36px}
.stit{font-family:"Ubuntu",sans-serif;font-size:58px;font-weight:700;color:#447099;line-height:1.1;border-left:14px solid #EAFF38;padding-left:28px}
.dsc{font-family:"Ubuntu",sans-serif;font-size:28px;color:#404041;line-height:1.6}
.bul{list-style:none;display:flex;flex-direction:column;gap:22px}
.bul li{display:flex;align-items:flex-start;gap:20px;font-size:26px;color:#151515;font-family:"Ubuntu",sans-serif;line-height:1.45}
.dot{color:#EE6331;font-size:18px;margin-top:6px;flex-shrink:0}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ctr">2 / 4</div>
    <div class="pl">', he(nombre), '</div>
    <div class="hn"><span class="br">{</span>', he(nombre), '<span class="br">}</span></div>
  </div>
  <div class="bd">
    <div class="stit">', he(titulo), '</div>
    ', desc_html, bullets_html, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide3_html <- function(nombre, titulo, codigo, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#F5F5F5;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#151515;padding:42px 80px;display:flex;align-items:center;justify-content:space-between}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em;z-index:2}
.ht{font-family:"Ubuntu",sans-serif;font-size:42px;font-weight:700;color:#EAFF38;letter-spacing:0.08em;text-transform:uppercase}
.hp{font-family:"Ubuntu Mono",monospace;font-size:28px;color:rgba(255,255,255,0.45);letter-spacing:0.06em}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:28px;justify-content:center}
.cb{background:#fff;border:3px solid #151515;border-left:11px solid #447099;padding:42px 50px;font-family:"Ubuntu Mono",monospace;font-size:27px;color:#151515;line-height:1.7;white-space:pre-wrap;word-break:break-word}
.cb .code-comment{color:#707073}
.cb .code-fn{color:#447099;font-weight:700}
.cb .code-arg{color:#EE6331}
.cb .code-str{color:#419599}
.cn{font-family:"Ubuntu Mono",monospace;font-size:22px;color:#A0A0A2;letter-spacing:0.06em}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ht">', he(titulo), '</div>
    <div class="hp">{', he(nombre), '}</div>
  </div>
  <div class="ctr">3 / 4</div>
  <div class="bd">
    <div class="cb">', highlight_r_code(codigo), '</div>
    <div class="cn"># copiá este código en tu consola de R</div>
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide4_html <- function(tagline, autor, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="Estación R" style="height:110px;display:block;"/>')
  else ""
  autor_div <- if (nchar(trimws(autor)) > 0)
    paste0('<div class="cred">', he(autor), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#EAFF38;border:6px solid #151515;box-shadow:16px 16px 0 #447099;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:52px;padding:80px}
.cta{font-family:"Ubuntu",sans-serif;font-size:58px;font-weight:700;color:#151515;text-align:center;line-height:1.2;max-width:900px}
.handles{display:flex;gap:32px;flex-wrap:wrap;justify-content:center}
.pill{background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;padding:16px 36px;letter-spacing:0.06em}
.cred{font-family:"Ubuntu Mono",monospace;font-size:21px;color:rgba(0,0,0,0.38);text-align:center;letter-spacing:0.06em}
</style></head><body>
<div class="slide">
  <div class="ctr">4 / 4</div>
  <div class="mc">
    ', logo, '
    <div class="cta">', he(tagline), '</div>
    <div class="handles">
      <div class="pill">@estacion_r</div>
      <div class="pill">@estacionr.bsky.social</div>
    </div>
    ', autor_div, '
  </div>
</div></body></html>')
}

# Helper: envuelve el HTML de una slide en un iframe escalado a 540×540
slide_iframe <- function(html_str) {
  div(class = "slide-preview-wrap",
    tags$iframe(srcdoc = html_str, scrolling = "no")
  )
}

# ---- HTML de slides CURSO para preview (iframes) ----
course_slide1_html <- function(nombre, badge, tagline, fecha_inicio, logo_b64 = LOGO_B64, img_b64 = NULL, total = 3) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:52px;display:block;"/>') else ""
  tagline_div <- if (nchar(trimws(tagline)) > 0)
    paste0('<div class="tl">', he(tagline), '</div>') else ""
  img_band <- if (!is.null(img_b64))
    paste0('<div class="band"><img src="', img_b64, '" alt=""/></div>') else ""
  has_img <- if (!is.null(img_b64)) " has-img" else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#447099;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.band{width:100%;height:430px;border-bottom:6px solid #151515;overflow:hidden;flex-shrink:0}
.band img{width:100%;height:100%;object-fit:cover;display:block}
.wm{position:absolute;right:-10px;bottom:-30px;font-family:"Ubuntu",sans-serif;font-size:260px;font-weight:700;color:rgba(255,255,255,0.06);line-height:1;pointer-events:none;user-select:none}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.slide.has-img .ctr{top:480px}
.mc{flex:1;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;gap:44px;position:relative;z-index:1}
.slide.has-img .mc{padding:48px 90px;gap:32px}
.badge{display:inline-block;background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;padding:12px 30px;border:3px solid #151515;width:fit-content}
.cn{font-family:"Array",sans-serif;font-size:70px;font-weight:700;color:#fff;line-height:1.1;max-width:900px}
.slide.has-img .cn{font-size:54px}
.tl{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.72);line-height:1.55;max-width:820px}
.slide.has-img .tl{font-size:28px}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:30px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fi{font-family:"Ubuntu Mono",monospace;font-size:21px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide', has_img, '">
  <div class="wm">ER</div><div class="ctr">1 / ', total, '</div>
  ', img_band, '
  <div class="mc">
    <div class="badge">', he(badge), '</div>
    <div class="cn">', he(nombre), '</div>
    ', tagline_div, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fi">Inicio: ', he(fecha_inicio), '</div>
  </div>
</div></body></html>')
}

course_slide2_html <- function(nombre, bullets, logo_b64 = LOGO_B64, total = 3) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>') else ""
  blist <- bullets[nchar(trimws(bullets)) > 0]
  bullets_html <- if (length(blist) > 0)
    paste0('<ul class="bul">', paste0('<li><span class="dot">●</span><span>', he(blist), '</span></li>', collapse = ""), '</ul>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#fff;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#447099;padding:52px 80px 42px;position:relative}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.hl{font-family:"Ubuntu Mono",monospace;font-size:20px;color:rgba(255,255,255,0.55);letter-spacing:0.12em;text-transform:uppercase;margin-bottom:14px}
.hn{font-family:"Ubuntu",sans-serif;font-size:52px;font-weight:700;color:#fff;letter-spacing:-0.02em;line-height:1.1}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:28px}
.stit{font-family:"Ubuntu",sans-serif;font-size:52px;font-weight:700;color:#447099;line-height:1.1;border-left:14px solid #EAFF38;padding-left:28px}
.bul{list-style:none;display:flex;flex-direction:column;gap:18px}
.bul li{display:flex;align-items:flex-start;gap:20px;font-size:26px;color:#151515;font-family:"Ubuntu",sans-serif;line-height:1.45}
.dot{color:#EE6331;font-size:18px;margin-top:6px;flex-shrink:0}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ctr">2 / ', total, '</div>
    <div class="hl">Estación R</div>
    <div class="hn">', he(nombre), '</div>
  </div>
  <div class="bd">
    <div class="stit">¿Qué vas a aprender?</div>
    ', bullets_html, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

course_slide3_html <- function(cta, logo_b64 = LOGO_B64, total = 3) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="Estación R" style="height:110px;display:block;"/>') else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#EAFF38;border:6px solid #151515;box-shadow:16px 16px 0 #447099;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:44px;padding:80px}
.cta{font-family:"Array",sans-serif;font-size:64px;font-weight:700;color:#151515;text-align:center;line-height:1.2;max-width:900px;text-transform:uppercase}
.bio{font-family:"Ubuntu",sans-serif;font-size:34px;color:#151515;background:#fff;border:3px solid #151515;padding:18px 44px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center}
.pill{background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
</style></head><body>
<div class="slide">
  <div class="ctr">3 / ', total, '</div>
  <div class="mc">
    ', logo, '
    <div class="cta">', he(cta), '</div>
    <div class="bio">🔗 Link en bio</div>
    <div class="handles">
      <div class="pill">@estacion_r</div>
      <div class="pill">@estacionr.bsky.social</div>
    </div>
  </div>
</div></body></html>')
}

course_slide4_html <- function(instr, palabra, refuerzo) {
  instr_div <- if (nchar(trimws(instr)) > 0)
    paste0('<div class="in">', he(instr), '</div>') else ""
  refuerzo_div <- if (nchar(trimws(refuerzo)) > 0)
    paste0('<div class="rf">', he(refuerzo), '</div>') else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#151515;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.22);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:28px;padding:80px;text-align:center}
.in{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#EAFF38;letter-spacing:0.14em;text-transform:uppercase}
.pw{font-family:"Array",sans-serif;font-weight:700;font-size:160px;color:#fff;line-height:1;text-transform:uppercase}
.rf{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.82);line-height:1.4;max-width:780px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center;margin-top:12px}
.pill{background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
</style></head><body>
<div class="slide">
  <div class="ctr">4 / 4</div>
  <div class="mc">
    ', instr_div, '
    <div class="pw">', he(palabra), '</div>
    ', refuerzo_div, '
    <div class="handles">
      <div class="pill">@estacion_r</div>
      <div class="pill">@estacionr.bsky.social</div>
    </div>
  </div>
</div></body></html>')
}

# ---- HTML tarjeta clásica de curso (preview iframes) ----
tarjeta_iframe <- function(html_str, w, h, wrap_w) {
  scale <- round(wrap_w / w, 4)
  div(style = paste0("width:", wrap_w, "px; height:", ceiling(h * scale),
    "px; overflow:hidden; flex-shrink:0; border:2px solid #C2C2C4;"),
    tags$iframe(srcdoc = html_str, scrolling = "no",
      style = paste0("width:", w, "px; height:", h, "px; border:none; display:block;",
        "transform:scale(", scale, "); transform-origin:top left;")))
}

tarjeta_item_html <- function(it, fill) {
  if (nchar(trimws(paste0(it$strong, it$text))) == 0) return("")
  paste0(
    '<div class="it"><div class="circ">', tarjeta_icon_svg(it$icon, fill), '</div>',
    '<div class="tx"><strong>', he(it$strong), '</strong>', he(it$text), '</div></div>')
}

tarjeta_html <- function(d, formato = c("4x5", "16x9"), img_b64 = NULL) {
  formato <- match.arg(formato)
  f <- TARJETA_FONDOS[[d$fondo %||% "negro"]]
  logo <- TARJETA_LOGOS[[f$logo]]
  items_ok <- Filter(function(it) nchar(trimws(paste0(it$strong, it$text))) > 0, d$items)
  items_html <- paste(vapply(d$items, tarjeta_item_html, character(1), f$circ_fg), collapse = "")
  insc_html <- if (nchar(trimws(d$inscripcion_texto %||% "")) > 0)
    paste0('<div class="insc"><div class="ico">\U0001F4E3</div><div class="txt">',
      gsub("\n", "<br>", he(d$inscripcion_texto)), '</div></div>') else ""
  caja <- if (!is.null(img_b64))
    paste0('<img src="', img_b64, '" alt=""/>')
  else
    paste0('<img class="iso" src="', ISOTIPO_B64, '" alt="ER"/>')
  badge <- '<div class="badge">CURSOS</div>'
  es45 <- identical(formato, "4x5")

  base_css <- paste0(
    "*{margin:0;padding:0;box-sizing:border-box}",
    ".hd{display:flex;justify-content:space-between;align-items:center;padding:", if (es45) "56px" else "52px 64px 0", "}",
    ".hd .lg{height:", if (es45) "58px" else "56px", ";display:block}",
    ".badge{background:", f$badge_bg, ";color:", f$badge_fg, ";font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;padding:10px 26px}",
    ".tt{font-family:'Array',sans-serif;font-weight:700;line-height:1.05;color:", f$ink, ";white-space:pre-wrap}",
    ".caja{border:5px solid #191919;background:#DFF5FF;overflow:hidden;display:flex;align-items:center;justify-content:center}",
    ".caja img{width:100%;height:100%;object-fit:cover;display:block}",
    ".caja img.iso{width:280px;height:auto;object-fit:contain}",
    ".tag{font-size:31px;line-height:1.45;color:", f$tag, ";white-space:pre-wrap}",
    ".it{display:flex;gap:18px;align-items:flex-start}",
    ".circ{width:54px;height:54px;border-radius:50%;background:", f$circ_bg, ";display:flex;align-items:center;justify-content:center;flex-shrink:0}",
    ".circ svg{width:30px;height:30px;display:block}",
    ".cta-btn{display:inline-block;background:", f$btn_bg, ";color:", f$btn_fg, ";font-family:'Ubuntu',sans-serif;font-weight:700;font-size:34px;line-height:1;padding:22px 64px;border-radius:14px}",
    ".it .tx{font-size:27px;line-height:1.32;color:", f$ink, "}",
    ".it .tx strong{display:block;font-weight:700}")

  if (es45) {
    layout_css <- paste0(
      ".tarjeta{width:1080px;height:1350px;background:", f$bg, ";font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;display:flex;flex-direction:column}",
      ".tt{font-size:70px;padding:52px 58px 0}",
      ".caja{margin:44px 58px 0;height:500px;flex:1 1 auto;min-height:360px}",
      ".tag{padding:36px 58px 0}",
      ".items{display:grid;grid-template-columns:1fr 1fr;gap:26px 24px;padding:42px 58px 0}",
      ".insc{background:#EAFF38;border:3px solid #151515;padding:26px 34px;display:flex;align-items:center;gap:22px;margin:36px 58px 56px}",
      ".insc .ico{font-size:36px;line-height:1;flex-shrink:0}",
      ".insc .txt{font-size:25px;font-weight:700;color:#151515;font-family:'Ubuntu',sans-serif;text-transform:uppercase;letter-spacing:0.03em;line-height:1.3;white-space:pre-wrap}")
    body <- paste0(
      '<div class="tarjeta">',
      '<div class="hd"><img class="lg" src="', logo, '"/>', badge, '</div>',
      '<div class="tt">', he(d$titulo), '</div>',
      '<div class="caja">', caja, '</div>',
      '<div class="tag">', he(d$tagline), '</div>',
      '<div class="items">', items_html, '</div>',
      insc_html,
      '</div>')
  } else {
    # 16:9 — grid con filas explícitas: título/tagline comparten fila 1, imagen/ítems
    # comparten fila 2 (mismo grid-row), así el primer ítem queda siempre alineado con
    # el borde superior de la imagen sin importar cuánto ocupe el título o el tagline.
    sz <- tarjeta_item_sizing(length(items_ok))
    layout_css <- paste0(
      ".tarjeta{width:1920px;height:1080px;background:", f$bg, ";font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;",
      "display:flex;flex-direction:column;border:", TARJETA_BORDE, "px solid #151515}",
      ".cols{display:grid;grid-template-columns:1fr 690px;grid-template-rows:auto 1fr;column-gap:36px;padding:30px 64px 44px;flex:1 1 auto;min-height:0}",
      ".tt{font-size:74px;grid-column:1;grid-row:1}",
      ".tag{padding:6px 0 0;grid-column:2;grid-row:1}",
      ".caja{margin:34px 0 0;grid-column:1;grid-row:2;min-height:0}",
      ".items-cta{grid-column:2;grid-row:2;display:flex;flex-direction:column;min-height:0}",
      ".items{display:flex;flex-direction:column;gap:", sz$gap, "px;padding:26px 0 0}",
      ".it .tx{font-size:", sz$font, "px}",
      ".circ{width:", sz$circle, "px;height:", sz$circle, "px}",
      ".circ svg{width:", sz$svg, "px;height:", sz$svg, "px}",
      ".insc{background:#EAFF38;border:3px solid #151515;padding:16px 20px;display:flex;align-items:center;gap:14px;margin-top:auto}",
      ".insc .ico{font-size:30px;line-height:1;flex-shrink:0}",
      ".insc .txt{font-size:21px;font-weight:700;color:#151515;font-family:'Ubuntu',sans-serif;text-transform:uppercase;letter-spacing:0.03em;line-height:1.3;white-space:pre-wrap}")
    body <- paste0(
      '<div class="tarjeta">',
      '<div class="hd"><img class="lg" src="', logo, '"/>', badge, '</div>',
      '<div class="cols">',
      '<div class="tt">', he(d$titulo), '</div>',
      '<div class="tag">', he(d$tagline), '</div>',
      '<div class="caja">', caja, '</div>',
      '<div class="items-cta"><div class="items">', items_html, '</div>', insc_html, '</div>',
      '</div></div>')
  }

  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    TARJETA_FONTS, base_css, layout_css,
    '</style></head><body>', body, '</body></html>')
}

# ---- Visuales para redes: builder HTML (espejo de buildVizHTML en JS) ----
viz_html <- function(d, formato = c("1x1", "4x5", "16x9"), img_b64 = NULL,
                     logo_hd_b64 = NULL, logo_ft_b64 = NULL) {
  formato <- match.arg(formato)
  es169 <- identical(formato, "16x9")
  dims <- switch(formato, "1x1" = c(1080L, 1080L), "4x5" = c(1080L, 1350L), c(1920L, 1080L))
  pad <- if (es169) 64 else 58

  badge <- if (nchar(trimws(d$badge %||% "")) > 0)
    paste0('<div class="badge">', he(d$badge), '</div>') else ""
  titulo_html <- if (nchar(trimws(d$titulo %||% "")) > 0)
    paste0('<div class="tt">', he(d$titulo), '</div>') else ""
  chart <- if (!is.null(img_b64))
    paste0('<img src="', img_b64, '" alt=""/>') else
    '<div class="ph">Subí tu gráfico</div>'
  fuente_html <- if (nchar(trimws(d$fuente %||% "")) > 0)
    paste0('<div class="src">', he(d$fuente), '</div>') else ""
  handles_html <- if (nchar(trimws(d$handles %||% "")) > 0)
    paste0('<div class="hand">', he(d$handles), '</div>') else ""
  hd_logo <- if (!is.null(logo_hd_b64))
    paste0('<img class="lg" src="', logo_hd_b64, '" alt="ER"/>') else ""
  ft_logo <- if (!is.null(logo_ft_b64))
    paste0('<img class="lgn" src="', logo_ft_b64, '" alt="ER"/>') else ""

  css <- paste0(
    "*{margin:0;padding:0;box-sizing:border-box}",
    ".viz{width:", dims[1], "px;height:", dims[2], "px;background:#FFFFFF;font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;display:flex;flex-direction:column}",
    ".hd{display:flex;justify-content:space-between;align-items:center;padding:", if (es169) "40px 64px 0" else "52px 58px 0", "}",
    ".hd .lg{height:", if (es169) "60px" else "64px", ";display:block}",
    ".badge{background:#FFFFFF;color:#191919;border:3px solid #151515;font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;padding:10px 26px}",
    ".tt{font-family:'Array',sans-serif;font-weight:700;line-height:1.05;color:#191919;white-space:pre-wrap;font-size:", if (es169) "96px" else "88px", ";padding:34px ", pad, "px 0}",
    ".chart{flex:1 1 auto;min-height:0;display:flex;align-items:center;justify-content:center;padding:40px ", pad, "px}",
    ".chart img{max-width:100%;max-height:100%;width:auto;height:auto;object-fit:contain;display:block}",
    ".ph{border:4px dashed #C2C2C4;padding:60px;font-family:'Ubuntu Mono',monospace;font-size:30px;color:#707073}",
    ".ft{background:#EAFF38;border-top:5px solid #151515;display:flex;justify-content:space-between;align-items:center;gap:36px;padding:", if (es169) "30px" else "36px", "px ", pad, "px}",
    ".src{font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.03em;text-transform:uppercase;line-height:1.45;white-space:pre-wrap}",
    ".hand{font-family:'Ubuntu Mono',monospace;font-size:22px;font-weight:700;color:rgba(21,21,21,0.78);line-height:1.5;margin-top:10px}",
    ".lgn{height:72px;display:block}"
  )
  body <- paste0(
    '<div class="viz">',
    '<div class="hd">', hd_logo, badge, '</div>',
    titulo_html,
    '<div class="chart">', chart, '</div>',
    '<div class="ft"><div>', fuente_html, handles_html, '</div>', ft_logo, '</div>',
    '</div>')
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    TARJETA_FONTS, css, '</style></head><body>', body, '</body></html>')
}

# ---- build_flyer_tag para LinkedIn/X ----
build_flyer_tag <- function(badge_color_hex, logo_b64 = NULL, course_img_src = NULL, dims = NULL,
                             badge, titulo, subtitulo, bullets_txt, col1, col2, col3, footer_icon, footer_texto) {
  blist <- strsplit(bullets_txt, "\n")[[1]]
  blist <- blist[nchar(trimws(blist)) > 0]
  badge_text_color <- if (badge_color_hex == "#151515") "#EAFF38" else "#FFFFFF"
  badge_style <- paste0("background:", badge_color_hex, "; color:", badge_text_color, ";")

  logo_tag <- if (!is.null(logo_b64))
    tags$img(src = logo_b64, style = "height:28px; display:block; margin:0 auto 0.3rem;")
  else
    tags$img(src = "logo_er.png", style = "height:28px; display:block; margin:0 auto 0.3rem;")

  course_img_tag <- if (!is.null(course_img_src))
    tags$img(src = course_img_src, class = "flyer-course-image")
  else NULL

  flyer_style <- if (!is.null(dims)) {
    w <- paste0(dims$w, "px")
    if (!is.null(dims$h))
      paste0("width:", w, "; height:", dims$h, "px; min-height:", dims$h, "px;")
    else
      paste0("width:", w, ";")
  } else ""

  div(class = "flyer", style = flyer_style,
    course_img_tag,
    div(class = "flyer-badge", style = badge_style, toupper(badge)),
    h1(class = "flyer-title", titulo),
    p(class = "flyer-subtitle", subtitulo),
    tags$ul(class = "flyer-bullets", lapply(blist, function(b) tags$li(b))),
    div(class = "flyer-info-grid",
      div(class = "flyer-info-col",
        div(class = "flyer-info-icon", HTML(SVG_MOVIE_PLAY)),
        div(class = "flyer-info-label", "ACCESO DE POR VIDA"),
        div(class = "flyer-info-text", col1)),
      div(class = "flyer-info-col",
        div(class = "flyer-info-icon", HTML(SVG_CERTIFICATION)),
        div(class = "flyer-info-label", "CERTIFICACIÓN"),
        div(class = "flyer-info-text", col2)),
      div(class = "flyer-info-col",
        div(class = "flyer-info-icon", HTML(SVG_SLACK)),
        div(class = "flyer-info-label", "ACCESO A LA COMUNIDAD"),
        div(class = "flyer-info-text", col3))
    ),
    div(class = "flyer-footer-highlight",
      div(class = "footer-icon", footer_icon),
      div(class = "flyer-footer-text", HTML(gsub("\n", "<br>", footer_texto)))
    ),
    div(class = "flyer-brand", logo_tag,
      tags$span("estacion-r.com", style = "color:#707073; font-size:0.72rem;"))
  )
}

build_flyer_tip_tag <- function(categoria, nombre, version_line, desc, codigo, autor_line) {
  autor_html <- he(autor_line)
  if (nchar(nombre) > 0)
    autor_html <- gsub(nombre, paste0("<strong>", nombre, "</strong>"), autor_html, fixed = TRUE)
  div(class = "tip-card",
    div(class = "tip-header",
      div(class = "tip-badge", categoria),
      div(class = "tip-nombre",
        span(class = "brace", "{"), nombre, span(class = "brace", "}")),
      div(class = "tip-version", version_line)),
    div(class = "tip-body",
      p(class = "tip-desc", desc),
      div(class = "tip-code", HTML(highlight_r_code(codigo))),
      div(class = "tip-autor", HTML(autor_html))),
    div(class = "tip-footer",
      span(class = "brand", "Estación R"),
      span(class = "url", "estacion-r.com"))
  )
}

# ============================================================
# ---- UI ----
# ============================================================
ui <- page_navbar(
  title = "Generador Estación R",
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF", fg = "#151515",
    primary = "#447099", secondary = "#707073",
    base_font = font_google("Ubuntu"),
    heading_font = font_google("Ubuntu", wght = c(400, 700)),
    "border-radius" = "0"
  ),
  header = tags$head(
    tags$style(HTML(css_app)),
    tags$style(HTML(css_flyer)),
    tags$style(HTML(css_tip))
  ),

  # ---- Tab Instagram ----
  nav_panel(
    "📸 Instagram — Carrusel",
    layout_sidebar(
      sidebar = sidebar(
        width = 340,
        class = "panel-form",

        tags$span("Tipo de carrusel", class = "section-label"),
        selectInput("ig_tipo_carrusel", NULL,
          choices = c("📦 Paquete de R" = "paquete", "🎓 Anuncio de curso" = "curso",
                      "🎴 Tarjeta clásica" = "tarjeta"),
          selected = "paquete"),

        conditionalPanel(
          condition = "input.ig_tipo_carrusel == 'paquete'",
          accordion(
            open = c("pkg"),
            multiple = TRUE,

            accordion_panel("📦 Datos del paquete", value = "pkg",
              tags$span("Categoría (badge)", class = "section-label"),
              textInput("ig_categoria", NULL, value = "Paquete de R"),
              tags$span("Nombre del paquete", class = "section-label"),
              textInput("ig_nombre", NULL, value = "janitor"),
              tags$span("Versión / fuente", class = "section-label"),
              textInput("ig_version", NULL, value = "v2.2.0 · CRAN · Sam Firke"),
              tags$span("Autor / repo (slide 4)", class = "section-label"),
              textInput("ig_autor", NULL, value = "📦 janitor · GitHub: sfirke/janitor")
            ),

            accordion_panel("Slide 1 — Portada", value = "s1",
              tags$span("Tagline", class = "section-label"),
              textAreaInput("ig_s1_tagline", NULL, rows = 2,
                value = "Limpieza de datos en R, sin esfuerzo")
            ),

            accordion_panel("Slide 2 — ¿Qué hace?", value = "s2",
              tags$span("Título de sección", class = "section-label"),
              textInput("ig_s2_titulo", NULL, value = "¿Para qué sirve?"),
              tags$span("Descripción", class = "section-label"),
              textAreaInput("ig_s2_desc", NULL, rows = 3,
                value = "Normalizá nombres de columnas, eliminá filas vacías y detectá duplicados con una línea de código."),
              tags$span("Bullets (uno por línea, máx 3)", class = "section-label"),
              textAreaInput("ig_s2_bullets", NULL, rows = 3,
                value = "clean_names(): columnas en snake_case\nremove_empty(): filas y columnas vacías\nget_dupes(): detecta duplicados")
            ),

            accordion_panel("Slide 3 — Código", value = "s3",
              tags$span("Título de sección", class = "section-label"),
              textInput("ig_s3_titulo", NULL, value = "En la práctica"),
              tags$span("Código R", class = "section-label"),
              textAreaInput("ig_s3_codigo", NULL, rows = 6,
                value = "# Normalizá los nombres de columnas\ndatos <- datos |>\n  clean_names() |>\n  remove_empty(which = \"rows\")")
            ),

            accordion_panel("Slide 4 — Cierre", value = "s4",
              tags$span("Tagline de cierre", class = "section-label"),
              textAreaInput("ig_s4_tagline", NULL, rows = 2,
                value = "Seguinos para más tips de R")
            )
          )
        ),

        conditionalPanel(
          condition = "input.ig_tipo_carrusel == 'curso'",
          accordion(
            open = c("cpkg"),
            multiple = TRUE,

            accordion_panel("🎓 Datos del curso", value = "cpkg",
              tags$span("Cantidad de placas", class = "section-label"),
              selectInput("ig_c_n_slides", NULL,
                choices = c("3 — portada, contenido, CTA" = "3",
                            "4 — + slide de contacto (INFO)" = "4"),
                selected = "3"),
              tags$span("Tipo de evento (badge)", class = "section-label"),
              textInput("ig_c_badge", NULL, value = "Curso virtual"),
              tags$span("Nombre del curso", class = "section-label"),
              textAreaInput("ig_c_nombre", NULL, rows = 2,
                value = "Introducción a R para Ciencias Sociales"),
              tags$span("Tagline (slide 1)", class = "section-label"),
              textAreaInput("ig_c_tagline", NULL, rows = 2,
                value = "Aprendé a analizar datos con R desde cero"),
              tags$span("Fecha de inicio", class = "section-label"),
              textInput("ig_c_fecha_inicio", NULL, value = "22 de septiembre"),
              tags$span("Imagen del curso (opcional)", class = "section-label"),
              fileInput("ig_c_img", NULL,
                accept = c("image/png", "image/jpeg"),
                buttonLabel = "Elegir imagen...",
                placeholder = "Sin imagen: portada a fondo azul")
            ),

            accordion_panel("Slide 2 — Contenidos", value = "cs2",
              tags$span("Contenidos (uno por línea, máx 6)", class = "section-label"),
              textAreaInput("ig_c_s2_bullets", NULL, rows = 6,
                value = "Introducción a R y RStudio\nManejo de datos con tidyverse\nVisualización con ggplot2\nReportes con Quarto\nAnálisis estadístico aplicado\nProyecto integrador")
            ),

            accordion_panel("Slide 3 — CTA", value = "cs3",
              tags$span("Frase CTA", class = "section-label"),
              textInput("ig_c_cta", NULL, value = "Inscripción abierta")
            ),
            conditionalPanel(
              condition = "input.ig_c_n_slides == '4'",
              accordion_panel("Slide 4 — Contacto", value = "cs4",
                tags$span("Instrucción", class = "section-label"),
                textInput("ig_c_s4_instr", NULL, value = "Comentá esta palabra en el posteo"),
                tags$span("Palabra clave (grande)", class = "section-label"),
                textInput("ig_c_s4_palabra", NULL, value = "INFO"),
                tags$span("Refuerzo", class = "section-label"),
                textAreaInput("ig_c_s4_refuerzo", NULL, rows = 2,
                  value = "Te mandamos el programa completo y todo lo que tenés que saber de la nueva edición")
              )
            )
          )
        ),

        conditionalPanel(
          condition = "input.ig_tipo_carrusel == 'tarjeta'",
          accordion(
            open = c("tbase"),
            multiple = TRUE,

            accordion_panel("🎴 Tarjeta", value = "tbase",
              tags$span("Fondo", class = "section-label"),
              selectInput("ig_t_fondo", NULL,
                choices = TARJETA_FONDO_OPTS, selected = "negro"),
              tags$span("Título del curso", class = "section-label"),
              textAreaInput("ig_t_titulo", NULL, rows = 2,
                value = "R para el tratamiento de Hojas de Cálculo"),
              tags$span("Tagline", class = "section-label"),
              textAreaInput("ig_t_tagline", NULL, rows = 3,
                value = "El remedio para tus datos. Aprendé a trabajar con R y Excel, Googlesheets o LibreOffice sin perder la calma (ni información)."),
              tags$span("Imagen (opcional — ocupa la caja central)", class = "section-label"),
              fileInput("ig_t_img", NULL,
                accept = c("image/png", "image/jpeg"),
                buttonLabel = "Elegir imagen...",
                placeholder = "Sin imagen: isotipo de ER"),
              checkboxInput("ig_t_solo_45",
                "Solo generar la de 4:5 (feed)", value = FALSE),
              tags$span("Recuadro de inscripción (vacío = sin recuadro)", class = "section-label"),
              textAreaInput("ig_t_inscripcion", NULL, rows = 2,
                value = "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO")
            ),

            accordion_panel("Ítems destacados (hasta 6)", value = "titems",
              tags$span("Cantidad de ítems a mostrar", class = "section-label"),
              selectInput("ig_t_n_items", NULL,
                choices = setNames(1:6, ifelse(1:6 == 1, "1 ítem", paste0(1:6, " ítems"))),
                selected = 4),
              tags$span("Ítem 1 — ícono / negrita / texto", class = "section-label"),
              selectInput("ig_t_i1_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-laptop"),
              textInput("ig_t_i1_strong", NULL, value = "Modalidad:"),
              textInput("ig_t_i1_text", NULL, value = "Sincrónica/Asincrónica"),
              conditionalPanel(condition = "input.ig_t_n_items >= 2",
                tags$span("Ítem 2", class = "section-label"),
                selectInput("ig_t_i2_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-chat"),
                textInput("ig_t_i2_strong", NULL, value = "Foro de intercambio"),
                textInput("ig_t_i2_text", NULL, value = "y seguimiento 24/7")
              ),
              conditionalPanel(condition = "input.ig_t_n_items >= 3",
                tags$span("Ítem 3", class = "section-label"),
                selectInput("ig_t_i3_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-calendar-check"),
                textInput("ig_t_i3_strong", NULL, value = "4 semanas"),
                textInput("ig_t_i3_text", NULL, value = "(10 hs. totales)")
              ),
              conditionalPanel(condition = "input.ig_t_n_items >= 4",
                tags$span("Ítem 4", class = "section-label"),
                selectInput("ig_t_i4_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-certification"),
                textInput("ig_t_i4_strong", NULL, value = "Certificación"),
                textInput("ig_t_i4_text", NULL, value = "con examen final")
              ),
              conditionalPanel(condition = "input.ig_t_n_items >= 5",
                tags$span("Ítem 5", class = "section-label"),
                selectInput("ig_t_i5_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-globe"),
                textInput("ig_t_i5_strong", NULL, value = "Comunidad"),
                textInput("ig_t_i5_text", NULL, value = "acceso internacional")
              ),
              conditionalPanel(condition = "input.ig_t_n_items >= 6",
                tags$span("Ítem 6", class = "section-label"),
                selectInput("ig_t_i6_icon", NULL, choices = TARJETA_ICON_OPTS, selected = "bx-award"),
                textInput("ig_t_i6_strong", NULL, value = "Becas"),
                textInput("ig_t_i6_text", NULL, value = "disponibles")
              )
            )
          )
        ),

        downloadButton("descargar_zip",
          "⬇ Descargar ZIP",
          class = "btn-zip",
          style = "margin-top: 1rem;")
      ),

      # Main: grid 2×2 de previews
      div(
        style = "padding: 1rem; overflow: auto;",
        div(
          style = "display: grid; grid-template-columns: 540px 540px; gap: 1.25rem;",
          conditionalPanel(
            condition = "input.ig_tipo_carrusel != 'tarjeta'",
            div(
              div(class = "slide-label", "Slide 1 — Portada"),
              uiOutput("preview_s1")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel != 'tarjeta'",
            div(
              uiOutput("label_s2"),
              uiOutput("preview_s2")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel != 'tarjeta'",
            div(
              uiOutput("label_s3"),
              uiOutput("preview_s3")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'paquete' || (input.ig_tipo_carrusel == 'curso' && input.ig_c_n_slides == '4')",
            div(
              uiOutput("label_s4"),
              uiOutput("preview_s4")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'tarjeta'",
            div(
              div(class = "slide-label", "Feed — 4:5 (1080×1350)"),
              uiOutput("preview_t45")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'tarjeta'",
            div(
              div(class = "slide-label", "Horizontal — 16:9 (1920×1080)"),
              uiOutput("preview_t169")
            )
          )
        )
      )
    )
  ),

  # ---- Tab Visuales para redes ----
  nav_panel(
    "📊 Visuales para redes",
    layout_sidebar(
      sidebar = sidebar(
        width = 320,
        class = "panel-form",

        tags$span("Gráfico (PNG o JPG desde R)", class = "section-label"),
        fileInput("viz_img", NULL,
          accept = c("image/png", "image/jpeg"),
          buttonLabel = "Elegir gráfico...",
          placeholder = "Sin gráfico"),

        tags$span("Badge", class = "section-label"),
        textInput("viz_badge", NULL, value = "DATOS"),

        tags$span("Título (opcional)", class = "section-label"),
        textAreaInput("viz_titulo", NULL, rows = 2,
          value = "La ropa bajó, los paquetes turísticos subieron"),

        tags$span("Fuente de datos", class = "section-label"),
        textAreaInput("viz_fuente", NULL, rows = 2,
          value = "Fuente: INDEC · IPC julio 2026"),

        tags$span("Redes (footer)", class = "section-label"),
        textInput("viz_handles", NULL,
          value = "@estacion_r · @estacionr.bsky.social"),

        tags$hr(),
        tags$span("Formatos a descargar", class = "section-label"),
        checkboxGroupInput("viz_formatos", NULL,
          choices = VIZ_FORMATOS_OPTS,
          selected = unname(VIZ_FORMATOS_OPTS)),

        downloadButton("descargar_viz_zip", "⬇ Descargar ZIP", class = "btn-zip")
      ),

      div(class = "flyer-wrap",
        div(class = "slide-label", "1:1 — Instagram (1080×1080)"),
        uiOutput("preview_viz_11"),
        div(class = "slide-label", "4:5 — Instagram feed (1080×1350)"),
        uiOutput("preview_viz_45"),
        div(class = "slide-label", "16:9 — LinkedIn / X (1920×1080)"),
        uiOutput("preview_viz_169")
      )
    )
  ),

  # ---- Tab LinkedIn / X ----
  nav_panel(
    "💼 LinkedIn · X",
    layout_sidebar(
      sidebar = sidebar(
        width = 320,
        class = "panel-form",

        tags$span("Plantilla", class = "section-label"),
        selectInput("lnk_template", NULL,
          choices = c("Curso", "Tip / Paquete de R"),
          selected = "Curso"),

        conditionalPanel(
          condition = "input.lnk_template == 'Curso'",

          tags$span("Formato", class = "section-label"),
          selectInput("lnk_formato", NULL,
            choices = names(FORMATOS_LNK),
            selected = names(FORMATOS_LNK)[1]),

          tags$span("Imagen del curso", class = "section-label"),
          fileInput("lnk_course_image", NULL,
            accept = c("image/png", "image/jpeg"),
            buttonLabel = "Elegir imagen...",
            placeholder = "Sin imagen"),

          tags$span("Tipo de evento", class = "section-label"),
          textInput("lnk_badge", NULL, value = "Curso virtual"),

          tags$span("Color del badge", class = "section-label"),
          selectInput("lnk_badge_color", NULL,
            choices = names(BADGE_COLORES), selected = "Azul ER"),

          tags$span("Título del curso", class = "section-label"),
          textAreaInput("lnk_titulo", NULL,
            value = "INTRODUCCIÓN A R PARA CIENCIAS SOCIALES", rows = 3),

          tags$span("Descripción breve", class = "section-label"),
          textAreaInput("lnk_subtitulo", NULL,
            value = "Aprendé a procesar, visualizar y comunicar datos con R desde cero.", rows = 2),

          tags$span("Contenidos (uno por línea)", class = "section-label"),
          textAreaInput("lnk_bullets", NULL,
            value = "Introducción a R y RStudio\nManejo de datos con tidyverse\nVisualización con ggplot2\nReportes con Quarto\nAnálisis estadístico aplicado",
            rows = 5),

          tags$hr(),
          tags$span("Acceso de por vida — texto", class = "section-label"),
          textAreaInput("lnk_col1", NULL,
            value = "Grabaciones disponibles para repasar cuando quieras", rows = 2),
          tags$span("Certificación — texto", class = "section-label"),
          textAreaInput("lnk_col2", NULL,
            value = "Certificado de participación al completar el programa", rows = 2),
          tags$span("Acceso a la comunidad — texto", class = "section-label"),
          textAreaInput("lnk_col3", NULL,
            value = "Canal exclusivo de Estación R para consultas y seguimiento", rows = 2),

          tags$hr(),
          tags$span("Destacado final", class = "section-label"),
          textInput("lnk_footer_icon", "Ícono (emoji)", value = "📣"),
          textAreaInput("lnk_footer_texto", "Texto",
            value = "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO", rows = 2)
        ),

        conditionalPanel(
          condition = "input.lnk_template == 'Tip / Paquete de R'",
          tags$span("Categoría (badge)", class = "section-label"),
          textInput("lnk_tip_categoria", NULL, value = "Paquete de R"),
          tags$span("Nombre del paquete / tip", class = "section-label"),
          textInput("lnk_tip_nombre", NULL, value = "janitor"),
          tags$span("Versión / fuente", class = "section-label"),
          textInput("lnk_tip_version", NULL, value = "v2.2.0 · CRAN · Sam Firke"),
          tags$span("Descripción", class = "section-label"),
          textAreaInput("lnk_tip_desc", NULL, rows = 2,
            value = "Limpiá y normalizá datos de forma rápida: nombres de columnas, tablas cruzadas y detección de duplicados con una sola línea de código."),
          tags$span("Código (R)", class = "section-label"),
          textAreaInput("lnk_tip_codigo", NULL, rows = 5,
            value = "# Normalizá los nombres de columnas\ndatos <- datos |>\n  clean_names() |>\n  remove_empty(which = \"rows\")"),
          tags$span("Autor / repo", class = "section-label"),
          textInput("lnk_tip_autor", NULL, value = "📦 janitor · GitHub: sfirke/janitor")
        ),

        div(style = "display:flex; gap:0.5rem; margin-top:1rem;",
          downloadButton("lnk_descargar_html", "⬇ HTML", class = "btn-download",
            style = "flex:1; margin:0;"),
          downloadButton("lnk_descargar_png", "⬇ PNG", class = "btn-download",
            style = "flex:1; margin:0; background:#447099; color:#fff;")
        )
      ),

      div(class = "flyer-wrap", uiOutput("preview_lnk"))
    )
  )
)

# ============================================================
# ---- SERVER ----
# ============================================================
server <- function(input, output, session) {

  # -- Instagram: reactivos --
  ig_tipo <- reactive(input$ig_tipo_carrusel %||% "paquete")

  ig_data <- reactive(list(
    nombre   = input$ig_nombre,
    categoria = input$ig_categoria,
    version  = input$ig_version,
    autor    = input$ig_autor,
    s1_tagline = input$ig_s1_tagline,
    s2_titulo  = input$ig_s2_titulo,
    s2_desc    = input$ig_s2_desc,
    s2_bullets = strsplit(input$ig_s2_bullets %||% "", "\n")[[1]],
    s3_titulo  = input$ig_s3_titulo,
    s3_codigo  = input$ig_s3_codigo,
    s4_tagline = input$ig_s4_tagline
  ))

  ig_curso_data <- reactive(list(
    n_slides     = as.integer(input$ig_c_n_slides %||% 3),
    nombre       = input$ig_c_nombre %||% "",
    badge        = input$ig_c_badge %||% "Curso virtual",
    tagline      = input$ig_c_tagline %||% "",
    fecha_inicio = input$ig_c_fecha_inicio %||% "",
    s2_bullets   = strsplit(input$ig_c_s2_bullets %||% "", "\n")[[1]],
    cta          = input$ig_c_cta %||% "Inscripción abierta",
    s4_instr     = input$ig_c_s4_instr %||% "",
    s4_palabra   = input$ig_c_s4_palabra %||% "INFO",
    s4_refuerzo  = input$ig_c_s4_refuerzo %||% ""
  ))

  ig_c_img_b64 <- reactive({
    req(input$ig_c_img)
    ext <- tools::file_ext(input$ig_c_img$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,", base64enc::base64encode(input$ig_c_img$datapath))
  })

  ig_tarjeta_data <- reactive({
    n <- as.integer(input$ig_t_n_items %||% 4)
    items <- lapply(1:n, function(i) {
      list(
        icon   = input[[paste0("ig_t_i", i, "_icon")]] %||% "bx-star",
        strong = input[[paste0("ig_t_i", i, "_strong")]] %||% "",
        text   = input[[paste0("ig_t_i", i, "_text")]] %||% ""
      )
    })
    list(
      fondo   = input$ig_t_fondo %||% "negro",
      titulo  = input$ig_t_titulo %||% "",
      tagline = input$ig_t_tagline %||% "",
      items   = items,
      inscripcion_texto = input$ig_t_inscripcion %||% ""
    )
  })

  ig_t_img_b64 <- reactive({
    req(input$ig_t_img)
    ext <- tools::file_ext(input$ig_t_img$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,", base64enc::base64encode(input$ig_t_img$datapath))
  })

  output$preview_t45 <- renderUI({
    d <- ig_tarjeta_data()
    img_b64 <- if (!is.null(input$ig_t_img)) ig_t_img_b64() else NULL
    tarjeta_iframe(tarjeta_html(d, "4x5", img_b64), 1080, 1350, 540)
  })
  output$preview_t169 <- renderUI({
    d <- ig_tarjeta_data()
    img_b64 <- if (!is.null(input$ig_t_img)) ig_t_img_b64() else NULL
    tarjeta_iframe(tarjeta_html(d, "16x9", img_b64), 1920, 1080, 540)
  })

  output$preview_s1 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      d <- ig_curso_data()
      img_b64 <- if (!is.null(input$ig_c_img)) ig_c_img_b64() else NULL
      slide_iframe(course_slide1_html(d$nombre, d$badge, d$tagline, d$fecha_inicio, img_b64 = img_b64, total = d$n_slides))
    } else {
      d <- ig_data()
      slide_iframe(slide1_html(d$nombre, d$categoria, d$s1_tagline))
    }
  })
  output$preview_s2 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      d <- ig_curso_data()
      slide_iframe(course_slide2_html(d$nombre, d$s2_bullets, total = d$n_slides))
    } else {
      d <- ig_data()
      slide_iframe(slide2_html(d$nombre, d$s2_titulo, d$s2_desc, d$s2_bullets))
    }
  })
  output$preview_s3 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      d <- ig_curso_data()
      slide_iframe(course_slide3_html(d$cta, total = d$n_slides))
    } else {
      d <- ig_data()
      slide_iframe(slide3_html(d$nombre, d$s3_titulo, d$s3_codigo))
    }
  })
  output$preview_s4 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      d <- ig_curso_data()
      if (d$n_slides < 4) return(NULL)
      slide_iframe(course_slide4_html(d$s4_instr, d$s4_palabra, d$s4_refuerzo))
    } else {
      d <- ig_data()
      slide_iframe(slide4_html(d$s4_tagline, d$autor))
    }
  })

  # -- Instagram: labels dinámicos de slides --
  output$label_s2 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      div(class = "slide-label", "Slide 2 — ¿Qué vas a aprender?")
    } else {
      div(class = "slide-label", "Slide 2 — ¿Qué hace?")
    }
  })
  output$label_s3 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      div(class = "slide-label", "Slide 3 — CTA")
    } else {
      div(class = "slide-label", "Slide 3 — Código")
    }
  })
  output$label_s4 <- renderUI({
    if (identical(ig_tipo(), "curso")) {
      div(class = "slide-label", "Slide 4 — Contacto")
    } else {
      div(class = "slide-label", "Slide 4 — Cierre")
    }
  })

  # -- Instagram: descarga ZIP --
  output$descargar_zip <- downloadHandler(
    filename = function() {
      pref <- switch(ig_tipo(),
        tarjeta = "tarjeta_er_",
        curso   = "carrusel_curso_er_",
        "carrusel_er_")
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".zip")
    },
    content = function(file) {
      slide_dir <- tempfile(pattern = "carousel_")
      dir.create(slide_dir)
      on.exit(unlink(slide_dir, recursive = TRUE), add = TRUE)

      if (identical(ig_tipo(), "tarjeta")) {
        d <- ig_tarjeta_data()
        config <- list(
          template     = "tarjeta_curso",
          output_dir   = slide_dir,
          fondo        = d$fondo,
          titulo       = d$titulo,
          tagline      = d$tagline,
          items        = d$items,
          inscripcion_texto = d$inscripcion_texto,
          solo_45      = isTRUE(input$ig_t_solo_45),
          imagen_curso = if (!is.null(input$ig_t_img)) input$ig_t_img$datapath else NULL
        )
      } else if (identical(ig_tipo(), "curso")) {
        d <- ig_curso_data()
        config <- list(
          template     = "carousel_curso",
          output_dir   = slide_dir,
          n_slides     = d$n_slides,
          nombre       = d$nombre,
          badge        = d$badge,
          tagline      = d$tagline,
          fecha_inicio = d$fecha_inicio,
          s2_bullets   = d$s2_bullets,
          cta          = d$cta,
          s4_instr     = d$s4_instr,
          s4_palabra   = d$s4_palabra,
          s4_refuerzo  = d$s4_refuerzo,
          imagen_curso = if (!is.null(input$ig_c_img)) input$ig_c_img$datapath else NULL
        )
      } else {
        d <- ig_data()
        config <- list(
          template      = "carousel",
          output_dir    = slide_dir,
          pkg_nombre    = d$nombre,
          categoria     = d$categoria,
          version_line  = d$version,
          autor_line    = d$autor,
          slide1_tagline = d$s1_tagline,
          slide2_titulo  = d$s2_titulo,
          slide2_desc    = d$s2_desc,
          slide2_bullets = d$s2_bullets,
          slide3_titulo  = d$s3_titulo,
          slide3_codigo  = d$s3_codigo,
          slide4_tagline = d$s4_tagline
        )
      }

      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- system2(NODE_BIN,
        args = c(PLAYWRIGHT_SCRIPT, "--config", cfg_file),
        stdout = TRUE, stderr = TRUE)

      pngs <- list.files(slide_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0)
        stop("Error generando carrusel: ", paste(result, collapse = "\n"))

      old_wd <- setwd(slide_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Visuales para redes: reactivos --
  viz_data <- reactive({
    list(
      badge   = input$viz_badge %||% "",
      titulo  = input$viz_titulo %||% "",
      fuente  = input$viz_fuente %||% "",
      handles = input$viz_handles %||% ""
    )
  })

  viz_img_b64 <- reactive({
    req(input$viz_img)
    ext <- tools::file_ext(input$viz_img$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,", base64enc::base64encode(input$viz_img$datapath))
  })

  viz_preview <- function(fmt, w, h) {
    d <- viz_data()
    img_b64 <- if (!is.null(input$viz_img)) viz_img_b64() else NULL
    tarjeta_iframe(viz_html(d, fmt, img_b64, TARJETA_LOGOS$azul, TARJETA_LOGOS$negro), w, h, 540)
  }

  output$preview_viz_11  <- renderUI(viz_preview("1x1", 1080, 1080))
  output$preview_viz_45  <- renderUI(viz_preview("4x5", 1080, 1350))
  output$preview_viz_169 <- renderUI(viz_preview("16x9", 1920, 1080))

  # -- Visuales para redes: descarga ZIP --
  output$descargar_viz_zip <- downloadHandler(
    filename = function() paste0("viz_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$viz_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- viz_data()
      viz_dir <- tempfile(pattern = "viz_")
      dir.create(viz_dir)
      on.exit(unlink(viz_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template   = "viz_redes",
        output_dir = viz_dir,
        badge      = d$badge,
        titulo     = d$titulo,
        fuente     = d$fuente,
        handles    = d$handles,
        formatos   = fmts,
        imagen     = if (!is.null(input$viz_img)) input$viz_img$datapath else NULL
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- system2(NODE_BIN,
        args = c(PLAYWRIGHT_SCRIPT, "--config", cfg_file),
        stdout = TRUE, stderr = TRUE)

      pngs <- list.files(viz_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0)
        stop("Error generando visuales: ", paste(result, collapse = "\n"))

      old_wd <- setwd(viz_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- LinkedIn/X: reactivos --
  lnk_badge_hex <- reactive(BADGE_COLORES[[input$lnk_badge_color]])

  lnk_img_b64 <- reactive({
    req(input$lnk_course_image)
    ext <- tools::file_ext(input$lnk_course_image$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,", base64enc::base64encode(input$lnk_course_image$datapath))
  })

  lnk_formato_dims <- reactive(FORMATOS_LNK[[input$lnk_formato]])

  output$preview_lnk <- renderUI({
    if (identical(input$lnk_template, "Tip / Paquete de R")) {
      return(build_flyer_tip_tag(
        input$lnk_tip_categoria, input$lnk_tip_nombre, input$lnk_tip_version,
        input$lnk_tip_desc, input$lnk_tip_codigo, input$lnk_tip_autor))
    }
    img_src <- if (!is.null(input$lnk_course_image)) lnk_img_b64() else NULL
    build_flyer_tag(
      lnk_badge_hex(), course_img_src = img_src, dims = lnk_formato_dims(),
      badge = input$lnk_badge, titulo = input$lnk_titulo,
      subtitulo = input$lnk_subtitulo, bullets_txt = input$lnk_bullets,
      col1 = input$lnk_col1, col2 = input$lnk_col2, col3 = input$lnk_col3,
      footer_icon = input$lnk_footer_icon, footer_texto = input$lnk_footer_texto)
  })

  # -- LinkedIn/X: descarga HTML --
  output$lnk_descargar_html <- downloadHandler(
    filename = function() {
      pref <- if (identical(input$lnk_template, "Tip / Paquete de R")) "tip_er_" else "flyer_er_"
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      if (identical(input$lnk_template, "Tip / Paquete de R")) {
        tip_tag <- build_flyer_tip_tag(
          input$lnk_tip_categoria, input$lnk_tip_nombre, input$lnk_tip_version,
          input$lnk_tip_desc, input$lnk_tip_codigo, input$lnk_tip_autor)
        html <- paste0(
          "<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n<meta charset=\"UTF-8\">\n",
          "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap\">\n",
          "<style>", css_tip, "</style>\n</head>\n",
          "<body style=\"margin:0; padding:2rem; background:#f5f5f5;\">\n",
          as.character(tip_tag), "\n</body>\n</html>")
        writeLines(html, file)
        return(invisible())
      }
      logo_b64 <- paste0("data:image/png;base64,", base64enc::base64encode(LOGO_PATH))
      img_src <- if (!is.null(input$lnk_course_image)) lnk_img_b64() else NULL
      flyer_tag <- build_flyer_tag(
        lnk_badge_hex(), logo_b64 = logo_b64, course_img_src = img_src,
        dims = lnk_formato_dims(),
        badge = input$lnk_badge, titulo = input$lnk_titulo,
        subtitulo = input$lnk_subtitulo, bullets_txt = input$lnk_bullets,
        col1 = input$lnk_col1, col2 = input$lnk_col2, col3 = input$lnk_col3,
        footer_icon = input$lnk_footer_icon, footer_texto = input$lnk_footer_texto)
      html <- paste0(
        "<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n<meta charset=\"UTF-8\">\n",
        "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap\">\n",
        "<style>", css_flyer, "</style>\n</head>\n",
        "<body style=\"margin:0; padding:2rem; background:#f5f5f5;\">\n",
        as.character(flyer_tag), "\n</body>\n</html>")
      writeLines(html, file)
    }
  )

  # -- LinkedIn/X: descarga PNG --
  output$lnk_descargar_png <- downloadHandler(
    filename = function() {
      pref <- if (identical(input$lnk_template, "Tip / Paquete de R")) "tip_er_" else "flyer_er_"
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      if (identical(input$lnk_template, "Tip / Paquete de R")) {
        config <- list(
          template     = "tip",
          categoria    = input$lnk_tip_categoria,
          pkg_nombre   = input$lnk_tip_nombre,
          version_line = input$lnk_tip_version,
          descripcion  = input$lnk_tip_desc,
          codigo       = input$lnk_tip_codigo,
          autor_line   = input$lnk_tip_autor
        )
        cfg_file <- tempfile(fileext = ".json")
        writeLines(jsonlite::toJSON(config, auto_unbox = TRUE), cfg_file)
        result <- system2(NODE_BIN,
          args = c(PLAYWRIGHT_SCRIPT, "--config", cfg_file, "--output", file),
          stdout = TRUE, stderr = TRUE)
        unlink(cfg_file)
        if (!file.exists(file)) stop("Error generando PNG: ", paste(result, collapse = "\n"))
        return(invisible())
      }
      dims <- lnk_formato_dims()
      img_path <- if (!is.null(input$lnk_course_image)) input$lnk_course_image$datapath else NULL
      config <- list(
        template     = "curso",
        formato      = dims$key,
        imagen_curso = img_path,
        badge_texto  = input$lnk_badge,
        badge_color  = input$lnk_badge_color,
        titulo       = input$lnk_titulo,
        subtitulo    = input$lnk_subtitulo,
        bullets      = strsplit(input$lnk_bullets, "\n")[[1]],
        col1_texto   = input$lnk_col1,
        col2_texto   = input$lnk_col2,
        col3_texto   = input$lnk_col3,
        footer_texto = input$lnk_footer_texto,
        footer_icon  = input$lnk_footer_icon
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      result <- system2(NODE_BIN,
        args = c(PLAYWRIGHT_SCRIPT, "--config", cfg_file, "--output", file),
        stdout = TRUE, stderr = TRUE)
      unlink(cfg_file)
      if (!file.exists(file)) stop("Error generando PNG: ", paste(result, collapse = "\n"))
    }
  )
}

shinyApp(ui, server)
