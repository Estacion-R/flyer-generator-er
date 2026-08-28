library(shiny)
library(bslib)
library(htmltools)
library(webshot2)

BADGE_COLORES <- c(
  "Azul ER"   = "#447099",
  "Naranja ER" = "#EE6331",
  "Teal ER"   = "#419599",
  "Negro"     = "#151515"
)

css_flyer <- paste(readLines("www/css/flyer.css", warn = FALSE), collapse = "\n")

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
    tags$link(rel = "stylesheet", href = "css/flyer.css")
  ),

  # ---- PANEL LATERAL ----
  sidebar = sidebar(
    width = 320,
    class = "panel-form",

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
    tags$span("Columna 1", class = "section-label"),
    textInput("col1_icon", "Ícono (emoji)", value = "👥"),
    textInput("col1_label", "Título", value = "DIRIGIDO A"),
    textAreaInput("col1_texto", "Texto",
      value = "Profesionales de Ciencias Sociales, docentes e investigadores/as",
      rows = 2),

    tags$span("Columna 2", class = "section-label"),
    textInput("col2_icon", "Ícono (emoji)", value = "🎯"),
    textInput("col2_label", "Título", value = "METODOLOGÍA"),
    textAreaInput("col2_texto", "Texto",
      value = "Clases prácticas con datos reales y ejercicios guiados",
      rows = 2),

    tags$span("Columna 3", class = "section-label"),
    textInput("col3_icon", "Ícono (emoji)", value = "📅"),
    textInput("col3_label", "Título", value = "INFO GENERAL"),
    textAreaInput("col3_texto", "Texto",
      value = "8 encuentros virtuales\nCertificado de participación\nMateriales incluidos",
      rows = 2),

    tags$hr(),
    tags$span("Destacado final (precio / fecha / horario)", class = "section-label"),
    textInput("footer_icon", "Ícono (emoji)", value = "📣"),
    textAreaInput("footer_texto", "Texto",
      value = "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO",
      rows = 2),

    tags$div(
      style = "display:flex; gap:0.5rem; margin-top:1rem;",
      downloadButton("descargar_html", "⬇ HTML", class = "btn-download",
        style = "flex:1; margin:0;"),
      downloadButton("descargar_png", "⬇ PNG", class = "btn-download",
        style = "flex:1; margin:0; background:#447099; color:#fff;")
    )
  ),

  # ---- PREVIEW ----
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

  build_flyer_tag <- function(badge_color_hex, logo_base64 = NULL) {
    bullets <- strsplit(input$bullets, "\n")[[1]]
    bullets <- bullets[nchar(trimws(bullets)) > 0]

    badge_style <- paste0("background:", badge_color_hex, ";")
    badge_text_color <- if (badge_color_hex == "#151515") "#EAFF38" else "#FFFFFF"
    badge_style <- paste0(badge_style, "color:", badge_text_color, ";")

    logo_tag <- if (!is.null(logo_base64)) {
      tags$img(src = logo_base64, style = "height:28px; display:block; margin:0 auto 0.3rem;")
    } else {
      tags$img(src = "logo_er.png", style = "height:28px; display:block; margin:0 auto 0.3rem;")
    }

    div(class = "flyer",

      div(class = "flyer-badge", style = badge_style, toupper(input$badge)),
      h1(class = "flyer-title", input$titulo),
      p(class = "flyer-subtitle", input$subtitulo),

      tags$ul(class = "flyer-bullets",
        lapply(bullets, function(b) tags$li(b))
      ),

      div(class = "flyer-info-grid",
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", input$col1_icon),
          div(class = "flyer-info-label", input$col1_label),
          div(class = "flyer-info-text", input$col1_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", input$col2_icon),
          div(class = "flyer-info-label", input$col2_label),
          div(class = "flyer-info-text", input$col2_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", input$col3_icon),
          div(class = "flyer-info-label", input$col3_label),
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

  output$preview <- renderUI({
    build_flyer_tag(badge_hex())
  })

  # Descarga HTML standalone
  output$descargar_html <- downloadHandler(
    filename = function() paste0("flyer_er_", format(Sys.Date(), "%Y%m%d"), ".html"),
    content = function(file) {
      logo_b64 <- paste0(
        "data:image/png;base64,",
        base64enc::base64encode("www/logo_er.png")
      )
      flyer_tag <- build_flyer_tag(badge_hex(), logo_base64 = logo_b64)
      html <- as.character(tagList(
        tags$html(
          tags$head(
            tags$meta(charset = "UTF-8"),
            tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap"),
            tags$style(HTML(css_flyer))
          ),
          tags$body(style = "margin:0; padding:2rem; background:#f5f5f5;", flyer_tag)
        )
      ))
      writeLines(html, file)
    }
  )

  # Descarga PNG via webshot2
  output$descargar_png <- downloadHandler(
    filename = function() paste0("flyer_er_", format(Sys.Date(), "%Y%m%d"), ".png"),
    content = function(file) {
      logo_b64 <- paste0(
        "data:image/png;base64,",
        base64enc::base64encode("www/logo_er.png")
      )
      flyer_tag <- build_flyer_tag(badge_hex(), logo_base64 = logo_b64)
      html <- as.character(tagList(
        tags$html(
          tags$head(
            tags$meta(charset = "UTF-8"),
            tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap"),
            tags$style(HTML(css_flyer))
          ),
          tags$body(style = "margin:0; padding:2rem; background:#f5f5f5;", flyer_tag)
        )
      ))
      tmp_html <- tempfile(fileext = ".html")
      writeLines(html, tmp_html)
      webshot2::webshot(tmp_html, file, vwidth = 600, vheight = 800, delay = 1,
        selector = ".flyer")
    }
  )
}

shinyApp(ui, server)
