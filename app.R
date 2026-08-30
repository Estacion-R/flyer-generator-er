library(shiny)
library(bslib)
library(htmltools)
library(base64enc)
library(jsonlite)

# ---- Config ----
BADGE_COLORES <- c(
  "Azul ER"    = "#447099",
  "Naranja ER" = "#EE6331",
  "Teal ER"    = "#419599",
  "Negro"      = "#151515"
)

FORMATOS <- list(
  "Vertical — feed / LinkedIn (4:5)" = list(w = 540, h = NULL, key = "linkedin"),
  "Cuadrado — Instagram (1:1)"       = list(w = 540, h = 540,  key = "instagram"),
  "Story / Reels — WhatsApp (9:16)"  = list(w = 380, h = 675,  key = "story")
)

# Rutas relativas al directorio de la app — repo y deploy comparten layout,
# así un clone fresco funciona igual (Shiny corre con wd = raíz de la app).
PLAYWRIGHT_SCRIPT <- "generate_flyer.js"
LOGO_PATH <- "www/logo_er.png"
# node de Linuxbrew: el /usr/bin/node v18 que resuelve el usuario shiny no cumple
# el engines.node >= 20 que pide playwright
NODE_BIN <- "/home/linuxbrew/.linuxbrew/bin/node"

# ---- SVG icons (Boxicons — mismos que estacion-r.com/courses) ----
SVG_ICON <- function(path_d, extra_path = NULL) {
  paths <- paste0('<path d="', path_d, '"/>')
  if (!is.null(extra_path)) paths <- paste0(paths, '<path d="', extra_path, '"/>')
  paste0(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" ',
    'style="width:1.5rem;height:1.5rem;fill:#447099;display:block;">',
    paths, '</svg>'
  )
}

SVG_MOVIE_PLAY <- SVG_ICON(
  "M20 3H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm.001 6c-.001 0-.001 0 0 0h-.465l-2.667-4H20l.001 4zM9.536 9 6.869 5h2.596l2.667 4H9.536zm5 0-2.667-4h2.596l2.667 4h-2.596zM4 5h.465l2.667 4H4V5zm0 14v-8h16l.002 8H4z",
  "m10 18 5.5-3-5.5-3z"
)

SVG_CERTIFICATION <- SVG_ICON(
  "M2.06 14.68a1 1 0 0 0 .46.6l1.91 1.11v2.2a1 1 0 0 0 1 1h2.2l1.11 1.91a1 1 0 0 0 .86.5 1 1 0 0 0 .51-.14l1.9-1.1 1.91 1.1a1 1 0 0 0 1.37-.36l1.1-1.91h2.2a1 1 0 0 0 1-1v-2.2l1.91-1.11a1 1 0 0 0 .37-1.36L20.76 12l1.11-1.91a1 1 0 0 0-.37-1.36l-1.91-1.1v-2.2a1 1 0 0 0-1-1h-2.2l-1.1-1.91a1 1 0 0 0-.61-.46 1 1 0 0 0-.76.1L12 3.26l-1.9-1.1a1 1 0 0 0-1.36.36L7.63 4.43h-2.2a1 1 0 0 0-1 1v2.2l-1.9 1.1a1 1 0 0 0-.37 1.37l1.1 1.9-1.1 1.91a1 1 0 0 0-.1.77zm3.22-3.17L4.39 10l1.55-.9a1 1 0 0 0 .49-.86V6.43h1.78a1 1 0 0 0 .87-.5L10 4.39l1.54.89a1 1 0 0 0 1 0l1.55-.89.91 1.54a1 1 0 0 0 .87.5h1.77v1.78a1 1 0 0 0 .5.86l1.54.9-.89 1.54a1 1 0 0 0 0 1l.89 1.54-1.54.9a1 1 0 0 0-.5.86v1.78h-1.83a1 1 0 0 0-.86.5l-.89 1.54-1.55-.89a1 1 0 0 0-1 0l-1.51.89-.89-1.54a1 1 0 0 0-.87-.5H6.43v-1.78a1 1 0 0 0-.49-.81l-1.55-.9.89-1.54a1 1 0 0 0 0-1.05z"
)

SVG_SLACK <- SVG_ICON(
  "M20.935 12.646a1.617 1.617 0 0 0-2.022-1.034l-1.632.532c-.355-1.099-.735-2.268-1.092-3.365l.006-.002-.004-.008 1.613-.523a1.62 1.62 0 0 0 1.035-2.023 1.62 1.62 0 0 0-2.025-1.034l-1.621.527-.519-1.604a1.619 1.619 0 0 0-2.024-1.034 1.618 1.618 0 0 0-1.033 2.024l.522 1.609-3.368 1.092-.524-1.611a1.618 1.618 0 0 0-2.022-1.034 1.617 1.617 0 0 0-1.034 2.023l.524 1.616-1.662.541a1.602 1.602 0 0 0-.988 1.95c.25.856 1.152 1.373 1.979 1.092.006 0 .658-.209 1.665-.536l1.099 3.386h-.002v.002l-1.67.545a1.599 1.599 0 0 0-.987 1.949c.25.857 1.15 1.374 1.979 1.093.007 0 .659-.211 1.665-.538l.003.005a.024.024 0 0 0 .008-.002l.539 1.657a1.6 1.6 0 0 0 1.949.989c.857-.25 1.373-1.151 1.094-1.979 0-.006-.209-.654-.533-1.654l-.003-.009c1.104-.358 2.276-.739 3.376-1.098l.543 1.668a1.602 1.602 0 0 0 1.949.989c.856-.251 1.374-1.152 1.092-1.979 0-.007-.209-.659-.535-1.663l.019-.006-.003-.007 1.609-.522a1.62 1.62 0 0 0 1.035-2.024zM10.86 14.238l-1.097-3.377a.02.02 0 0 0 .005-.001v-.006c1.098-.356 2.268-.735 3.363-1.092l1.098 3.377-3.369 1.099z"
)

css_flyer <- "
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; }

.flyer-wrap {
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 1rem;
}

.flyer {
  width: 540px;
  min-height: 680px;
  background: #FFFFFF;
  border: 2.5px solid #151515;
  box-shadow: 8px 8px 0 #EAFF38;
  padding: 2.5rem 2.8rem 2rem 2.8rem;
  font-family: 'Ubuntu', sans-serif;
  display: flex;
  flex-direction: column;
  gap: 1.4rem;
  position: relative;
}

.flyer-course-image {
  width: calc(100% + 5.6rem);
  margin: -2.5rem -2.8rem 0 -2.8rem;
  height: 180px;
  object-fit: cover;
  display: block;
  border-bottom: 2.5px solid #151515;
}

.flyer-badge {
  display: inline-block;
  background: #447099;
  color: #FFFFFF;
  border: 2px solid #151515;
  padding: 0.22rem 0.85rem;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-family: 'Ubuntu', sans-serif;
  width: fit-content;
}

.flyer-title {
  font-size: 2.2rem;
  font-weight: 700;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
  line-height: 1.15;
  letter-spacing: -0.01em;
  margin: 0;
}

.flyer-subtitle {
  font-size: 0.95rem;
  color: #404041;
  margin: 0;
  line-height: 1.5;
}

.flyer-bullets {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.flyer-bullets li {
  display: flex;
  align-items: flex-start;
  gap: 0.6rem;
  font-size: 0.95rem;
  color: #151515;
}

.flyer-bullets li::before {
  content: '●';
  color: #EE6331;
  font-size: 0.7rem;
  margin-top: 0.3rem;
  flex-shrink: 0;
}

.flyer-info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 1rem;
  border-top: 2px solid #151515;
  padding-top: 1rem;
  margin-top: auto;
}

.flyer-info-col {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.flyer-info-icon {
  font-size: 1.4rem;
  color: #447099;
  margin-bottom: 0.2rem;
  line-height: 1;
}

.flyer-info-label {
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
}

.flyer-info-text {
  font-size: 0.82rem;
  color: #404041;
  line-height: 1.4;
}

.flyer-footer-highlight {
  background: #EAFF38;
  border: 2px solid #151515;
  padding: 0.75rem 1rem;
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.flyer-footer-highlight .footer-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.flyer-footer-text {
  font-size: 0.88rem;
  font-weight: 700;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  line-height: 1.4;
}

.flyer-brand {
  text-align: center;
  font-size: 0.75rem;
  color: #707073;
  font-family: 'Ubuntu', sans-serif;
  letter-spacing: 0.08em;
  border-top: 1.5px solid #C2C2C4;
  padding-top: 0.75rem;
}

.flyer-brand img {
  height: 28px;
  display: block;
  margin: 0 auto 0.3rem;
}

.panel-form {
  background: #FFFFFF;
  border: 2px solid #151515;
  box-shadow: 4px 4px 0 #EE6331;
  padding: 1.5rem;
  height: fit-content;
}

.section-label {
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #447099;
  font-family: 'Ubuntu', sans-serif;
  margin-bottom: 0.5rem;
  display: block;
}

.btn-download {
  background: #151515;
  color: #EAFF38;
  border: 2px solid #151515;
  font-family: 'Ubuntu', sans-serif;
  font-weight: 700;
  padding: 0.6rem 1.5rem;
  width: 100%;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  cursor: pointer;
  font-size: 0.85rem;
  margin-top: 1rem;
}

.btn-download:hover {
  background: #447099;
  color: #FFFFFF;
}
"

css_tip <- "
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }

.tip-card {
  width: 540px;
  border: 3px solid #151515;
  box-shadow: 10px 10px 0 #EAFF38;
  overflow: hidden;
  background: #FFFFFF;
  font-family: 'Ubuntu', sans-serif;
}

.tip-header {
  background: #447099;
  padding: 2.2rem 2.5rem 2rem 2.5rem;
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.tip-header::after {
  content: 'R';
  position: absolute;
  right: -0.5rem;
  bottom: -1.2rem;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 8rem;
  font-weight: 700;
  color: rgba(255,255,255,0.08);
  line-height: 1;
  pointer-events: none;
  user-select: none;
}

.tip-badge {
  display: inline-block;
  background: #EAFF38;
  color: #151515;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  padding: 0.2rem 0.7rem;
  border: 2px solid #151515;
  width: fit-content;
}

.tip-nombre {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 3rem;
  font-weight: 700;
  color: #FFFFFF;
  line-height: 1.1;
  letter-spacing: -0.02em;
  position: relative;
}

.tip-nombre .brace { color: #EAFF38; font-size: 2.2rem; }

.tip-version {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 0.75rem;
  color: rgba(255,255,255,0.55);
  letter-spacing: 0.08em;
}

.tip-body {
  padding: 1.8rem 2.5rem 1.5rem 2.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.4rem;
}

.tip-desc {
  font-size: 0.95rem;
  color: #404041;
  line-height: 1.6;
}

.tip-code {
  background: #F5F5F5;
  border: 2px solid #151515;
  border-left: 5px solid #447099;
  padding: 0.9rem 1rem;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 0.82rem;
  color: #151515;
  line-height: 1.6;
  white-space: pre-wrap;
  word-break: break-word;
}

.tip-code .code-comment { color: #707073; }
.tip-code .code-fn { color: #447099; font-weight: 700; }
.tip-code .code-arg { color: #EE6331; }
.tip-code .code-str { color: #419599; }

.tip-autor {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8rem;
  color: #707073;
  font-family: 'Ubuntu Mono', monospace;
}

.tip-autor strong { color: #151515; }

.tip-footer {
  background: #EAFF38;
  border-top: 2px solid #151515;
  padding: 0.65rem 2.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.tip-footer .brand {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 0.72rem;
  font-weight: 700;
  color: #151515;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.tip-footer .url {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 0.68rem;
  color: #404041;
  letter-spacing: 0.06em;
}
"

# ---- Highlighter de R (una sola pasada, mismo criterio que generate_flyer.js) ----
highlight_r_code <- function(code) {
  esc <- gsub("&", "&amp;", code, fixed = TRUE)
  esc <- gsub("<", "&lt;", esc, fixed = TRUE)
  esc <- gsub(">", "&gt;", esc, fixed = TRUE)

  # strings | comentarios | funciones (lookahead "(") | args (lookahead "=")
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

# ---- UI ----
ui <- page_sidebar(
  title = "Generador de Flyers — Estación R",
  theme = bs_theme(
    version = 5,
    bg = "#FFFFFF", fg = "#151515",
    primary = "#447099", secondary = "#707073",
    base_font = font_google("Ubuntu"),
    heading_font = font_google("Ubuntu", wght = c(400, 700)),
    "border-radius" = "0"
  ),
  tags$head(
    tags$style(HTML(css_flyer)),
    tags$style(HTML(css_tip))
  ),

  sidebar = sidebar(
    width = 320,
    class = "panel-form",

    tags$span("Plantilla", class = "section-label"),
    selectInput("template", NULL,
      choices = c("Curso", "Tip / Paquete de R"),
      selected = "Curso"),

    conditionalPanel(
      condition = "input.template == 'Curso'",

    tags$span("Formato / red social", class = "section-label"),
    selectInput("formato", NULL,
      choices = names(FORMATOS),
      selected = names(FORMATOS)[1]),

    tags$span("Imagen del curso", class = "section-label"),
    fileInput("course_image", NULL,
              accept = c("image/png", "image/jpeg", "image/jpg"),
              buttonLabel = "Elegir imagen...",
              placeholder = "Sin imagen"),

    tags$span("Tipo de evento", class = "section-label"),
    textInput("badge", NULL, value = "Curso virtual"),

    tags$span("Color del badge", class = "section-label"),
    selectInput("badge_color", NULL,
      choices = names(BADGE_COLORES),
      selected = "Azul ER"),

    tags$span("Título del curso", class = "section-label"),
    textAreaInput("titulo", NULL,
      value = "INTRODUCCIÓN A R PARA CIENCIAS SOCIALES",
      rows = 3),

    tags$span("Descripción breve", class = "section-label"),
    textAreaInput("subtitulo", NULL,
      value = "Aprendé a procesar, visualizar y comunicar datos con R desde cero.",
      rows = 2),

    tags$span("Contenidos (uno por línea)", class = "section-label"),
    textAreaInput("bullets", NULL,
      value = "Introducción a R y RStudio\nManejo de datos con tidyverse\nVisualización con ggplot2\nReportes con Quarto\nAnálisis estadístico aplicado",
      rows = 5),

    tags$hr(),
    tags$span("Acceso de por vida — texto", class = "section-label"),
    textAreaInput("col1_texto", NULL,
      value = "Grabaciones disponibles para repasar cuando quieras",
      rows = 2),

    tags$span("Certificación — texto", class = "section-label"),
    textAreaInput("col2_texto", NULL,
      value = "Certificado de participación al completar el programa",
      rows = 2),

    tags$span("Acceso a la comunidad — texto", class = "section-label"),
    textAreaInput("col3_texto", NULL,
      value = "Canal exclusivo de Estación R para consultas y seguimiento",
      rows = 2),

    tags$hr(),
    tags$span("Destacado final", class = "section-label"),
    textInput("footer_icon", "Ícono (emoji)", value = "📣"),
    textAreaInput("footer_texto", "Texto",
      value = "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO",
      rows = 2)
    ),  # /conditionalPanel curso

    conditionalPanel(
      condition = "input.template == 'Tip / Paquete de R'",

      tags$span("Categoría (badge)", class = "section-label"),
      textInput("tip_categoria", NULL, value = "Paquete de R"),

      tags$span("Nombre del paquete / tip", class = "section-label"),
      textInput("tip_nombre", NULL, value = "janitor"),

      tags$span("Versión / fuente", class = "section-label"),
      textInput("tip_version", NULL, value = "v2.2.0 · CRAN · Sam Firke"),

      tags$span("Descripción", class = "section-label"),
      textAreaInput("tip_desc", NULL, rows = 2,
        value = "Limpiá y normalizá datos de forma rápida: nombres de columnas, tablas cruzadas y detección de duplicados con una sola línea de código."),

      tags$span("Código (R)", class = "section-label"),
      textAreaInput("tip_codigo", NULL, rows = 5,
        value = "# Normalizá los nombres de columnas\ndatos <- datos |>\n  clean_names() |>\n  remove_empty(which = \"rows\")"),

      tags$span("Autor / repo", class = "section-label"),
      textInput("tip_autor", NULL, value = "📦 janitor · GitHub: sfirke/janitor")
    ),

    tags$div(
      style = "display:flex; gap:0.5rem; margin-top:1rem;",
      downloadButton("descargar_html", "⬇ HTML", class = "btn-download",
        style = "flex:1; margin:0;"),
      downloadButton("descargar_png", "⬇ PNG", class = "btn-download",
        style = "flex:1; margin:0; background:#447099; color:#fff;")
    )
  ),

  div(
    class = "flyer-wrap",
    uiOutput("preview")
  )
)

# ---- SERVER ----
server <- function(input, output, session) {

  badge_hex <- reactive({
    BADGE_COLORES[[input$badge_color]]
  })

  img_b64 <- reactive({
    req(input$course_image)
    ext <- tools::file_ext(input$course_image$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,",
           base64enc::base64encode(input$course_image$datapath))
  })

  formato_dims <- reactive({
    FORMATOS[[input$formato]]
  })

  build_flyer_tag <- function(badge_color_hex, logo_b64 = NULL, course_img_src = NULL, dims = NULL) {
    bullets <- strsplit(input$bullets, "\n")[[1]]
    bullets <- bullets[nchar(trimws(bullets)) > 0]

    badge_text_color <- if (badge_color_hex == "#151515") "#EAFF38" else "#FFFFFF"
    badge_style <- paste0("background:", badge_color_hex, "; color:", badge_text_color, ";")

    logo_tag <- if (!is.null(logo_b64)) {
      tags$img(src = logo_b64, style = "height:28px; display:block; margin:0 auto 0.3rem;")
    } else {
      tags$img(src = "logo_er.png", style = "height:28px; display:block; margin:0 auto 0.3rem;")
    }

    course_img_tag <- if (!is.null(course_img_src)) {
      tags$img(src = course_img_src, class = "flyer-course-image")
    } else NULL

    flyer_style <- if (!is.null(dims)) {
      w <- paste0(dims$w, "px")
      if (!is.null(dims$h)) {
        paste0("width:", w, "; height:", dims$h, "px; min-height:", dims$h, "px;")
      } else {
        paste0("width:", w, ";")
      }
    } else ""

    div(class = "flyer", style = flyer_style,
      course_img_tag,
      div(class = "flyer-badge", style = badge_style, toupper(input$badge)),
      h1(class = "flyer-title", input$titulo),
      p(class = "flyer-subtitle", input$subtitulo),

      tags$ul(class = "flyer-bullets",
        lapply(bullets, function(b) tags$li(b))
      ),

      div(class = "flyer-info-grid",
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", HTML(SVG_MOVIE_PLAY)),
          div(class = "flyer-info-label", "ACCESO DE POR VIDA"),
          div(class = "flyer-info-text", input$col1_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", HTML(SVG_CERTIFICATION)),
          div(class = "flyer-info-label", "CERTIFICACIÓN"),
          div(class = "flyer-info-text", input$col2_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", HTML(SVG_SLACK)),
          div(class = "flyer-info-label", "ACCESO A LA COMUNIDAD"),
          div(class = "flyer-info-text", input$col3_texto)
        )
      ),

      div(class = "flyer-footer-highlight",
        div(class = "footer-icon", input$footer_icon),
        div(class = "flyer-footer-text",
          HTML(gsub("\n", "<br>", input$footer_texto))
        )
      ),

      div(class = "flyer-brand",
        logo_tag,
        tags$span("estacion-r.com", style = "color:#707073; font-size:0.72rem;")
      )
    )
  }

  build_flyer_tip_tag <- function() {
    nombre <- input$tip_nombre

    autor_html <- input$tip_autor
    if (nchar(nombre) > 0) {
      autor_html <- gsub(nombre, paste0("<strong>", nombre, "</strong>"),
                         autor_html, fixed = TRUE)
    }

    div(class = "tip-card",
      div(class = "tip-header",
        div(class = "tip-badge", input$tip_categoria),
        div(class = "tip-nombre",
          span(class = "brace", "{"), nombre, span(class = "brace", "}")
        ),
        div(class = "tip-version", input$tip_version)
      ),
      div(class = "tip-body",
        p(class = "tip-desc", input$tip_desc),
        div(class = "tip-code", HTML(highlight_r_code(input$tip_codigo))),
        div(class = "tip-autor", HTML(autor_html))
      ),
      div(class = "tip-footer",
        span(class = "brand", "Estación R"),
        span(class = "url", "estacion-r.com")
      )
    )
  }

  output$preview <- renderUI({
    if (identical(input$template, "Tip / Paquete de R")) {
      return(build_flyer_tip_tag())
    }
    img_src <- if (!is.null(input$course_image)) img_b64() else NULL
    build_flyer_tag(badge_hex(), course_img_src = img_src, dims = formato_dims())
  })

  # ---- Download HTML ----
  output$descargar_html <- downloadHandler(
    filename = function() {
      pref <- if (identical(input$template, "Tip / Paquete de R")) "tip_er_" else "flyer_er_"
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      if (identical(input$template, "Tip / Paquete de R")) {
        tip_tag <- build_flyer_tip_tag()
        # htmltools descarta tags$head con as.character(tagList()) —
        # se arma el documento a mano para no perder charset/fonts/css
        html <- paste0(
          "<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n<meta charset=\"UTF-8\">\n",
          "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap\">\n",
          "<style>", css_tip, "</style>\n</head>\n",
          "<body style=\"margin:0; padding:2rem; background:#f5f5f5;\">\n",
          as.character(tip_tag),
          "\n</body>\n</html>"
        )
        writeLines(html, file)
        return(invisible())
      }
      logo_b64 <- paste0(
        "data:image/png;base64,",
        base64enc::base64encode(LOGO_PATH)
      )
      img_src <- if (!is.null(input$course_image)) img_b64() else NULL
      flyer_tag <- build_flyer_tag(badge_hex(), logo_b64 = logo_b64,
                                   course_img_src = img_src, dims = formato_dims())
      # htmltools descarta tags$head con as.character(tagList()) —
      # se arma el documento a mano para no perder charset/fonts/css
      html <- paste0(
        "<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n<meta charset=\"UTF-8\">\n",
        "<link rel=\"stylesheet\" href=\"https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap\">\n",
        "<style>", css_flyer, "</style>\n</head>\n",
        "<body style=\"margin:0; padding:2rem; background:#f5f5f5;\">\n",
        as.character(flyer_tag),
        "\n</body>\n</html>"
      )
      writeLines(html, file)
    }
  )

  # ---- Download PNG via Playwright ----
  output$descargar_png <- downloadHandler(
    filename = function() {
      pref <- if (identical(input$template, "Tip / Paquete de R")) "tip_er_" else "flyer_er_"
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      if (identical(input$template, "Tip / Paquete de R")) {
        config <- list(
          template = "tip",
          categoria = input$tip_categoria,
          pkg_nombre = input$tip_nombre,
          version_line = input$tip_version,
          descripcion = input$tip_desc,
          codigo = input$tip_codigo,
          autor_line = input$tip_autor
        )
        config_file <- tempfile(fileext = ".json")
        writeLines(jsonlite::toJSON(config, auto_unbox = TRUE), config_file)
        result <- system2(
          NODE_BIN,
          args = c(PLAYWRIGHT_SCRIPT, "--config", config_file, "--output", file),
          stdout = TRUE, stderr = TRUE
        )
        unlink(config_file)
        if (!file.exists(file)) {
          stop("Error generando PNG: ", paste(result, collapse = "\n"))
        }
        return(invisible())
      }
      # Build config JSON for the Node script
      dims <- formato_dims()
      formato_key <- dims$key

      # Handle course image: save to temp file if provided
      img_path <- NULL
      if (!is.null(input$course_image)) {
        img_path <- input$course_image$datapath
      }

      config <- list(
        template = "curso",
        formato = formato_key,
        imagen_curso = img_path,
        badge_texto = input$badge,
        badge_color = input$badge_color,
        titulo = input$titulo,
        subtitulo = input$subtitulo,
        bullets = strsplit(input$bullets, "\n")[[1]],
        col1_texto = input$col1_texto,
        col2_texto = input$col2_texto,
        col3_texto = input$col3_texto,
        footer_texto = input$footer_texto,
        footer_icon = input$footer_icon
      )

      config_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), config_file)

      # Run Node script
      result <- system2(
        NODE_BIN,
        args = c(PLAYWRIGHT_SCRIPT, "--config", config_file, "--output", file),
        stdout = TRUE, stderr = TRUE
      )

      # Clean up
      unlink(config_file)

      if (!file.exists(file)) {
        stop("Error generando PNG: ", paste(result, collapse = "\n"))
      }
    }
  )

}

shinyApp(ui, server)