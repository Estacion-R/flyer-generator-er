library(shiny)
library(bslib)
library(htmltools)
library(base64enc)

BADGE_COLORES <- c(
  "Azul ER"    = "#447099",
  "Naranja ER" = "#EE6331",
  "Teal ER"    = "#419599",
  "Negro"      = "#151515"
)

css_flyer_raw <- readLines(
  file.path(getwd(), "www/css/flyer.css"), warn = FALSE
)
css_flyer <- paste(
  css_flyer_raw[!grepl("^@import", css_flyer_raw)],
  collapse = "\n"
)

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
    tags$link(rel = "stylesheet", href = "css/flyer.css"),
    tags$link(rel = "stylesheet",
              href = "https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css"),
    tags$script(
      src = "https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js"
    ),
    tags$script(HTML("
      function descargarPNG() {
        var flyer = document.querySelector('.flyer');
        if (!flyer) { alert('No se encontró el flyer'); return; }
        html2canvas(flyer, { scale: 2, useCORS: true, backgroundColor: '#ffffff' })
          .then(function(canvas) {
            var link = document.createElement('a');
            link.download = 'flyer_er.png';
            link.href = canvas.toDataURL('image/png');
            link.click();
          });
      }
    "))
  ),

  # ---- PANEL LATERAL ----
  sidebar = sidebar(
    width = 320,
    class = "panel-form",

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
    tags$span("Destacado final (precio / fecha / horario)", class = "section-label"),
    textInput("footer_icon", "Ícono (emoji)", value = "📣"),
    textAreaInput("footer_texto", "Texto",
      value = "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO",
      rows = 2),

    tags$div(
      style = "display:flex; gap:0.5rem; margin-top:1rem;",
      downloadButton("descargar_html", "⬇ HTML", class = "btn-download",
        style = "flex:1; margin:0;"),
      tags$button(
        "⬇ PNG",
        onclick = "descargarPNG()",
        class = "btn-download",
        style = "flex:1; margin:0; background:#447099; color:#fff; border:2px solid #151515; cursor:pointer;"
      )
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

  img_b64 <- reactive({
    req(input$course_image)
    ext <- tools::file_ext(input$course_image$name)
    mime <- if (tolower(ext) == "png") "image/png" else "image/jpeg"
    paste0("data:", mime, ";base64,",
           base64enc::base64encode(input$course_image$datapath))
  })

  build_flyer_tag <- function(badge_color_hex, logo_b64 = NULL, course_img_src = NULL) {
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

    div(class = "flyer",
      course_img_tag,
      div(class = "flyer-badge", style = badge_style, toupper(input$badge)),
      h1(class = "flyer-title", input$titulo),
      p(class = "flyer-subtitle", input$subtitulo),

      tags$ul(class = "flyer-bullets",
        lapply(bullets, function(b) tags$li(b))
      ),

      div(class = "flyer-info-grid",
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", tags$i(class = "bx bx-movie-play")),
          div(class = "flyer-info-label", "ACCESO DE POR VIDA"),
          div(class = "flyer-info-text", input$col1_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", tags$i(class = "bx bx-certification")),
          div(class = "flyer-info-label", "CERTIFICACIÓN"),
          div(class = "flyer-info-text", input$col2_texto)
        ),
        div(class = "flyer-info-col",
          div(class = "flyer-info-icon", tags$i(class = "bx bxl-slack-old")),
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

  output$preview <- renderUI({
    img_src <- if (!is.null(input$course_image)) img_b64() else NULL
    build_flyer_tag(badge_hex(), course_img_src = img_src)
  })

  output$descargar_html <- downloadHandler(
    filename = function() paste0("flyer_er_", format(Sys.Date(), "%Y%m%d"), ".html"),
    content = function(file) {
      logo_b64 <- paste0(
        "data:image/png;base64,",
        base64enc::base64encode("www/logo_er.png")
      )
      img_src <- if (!is.null(input$course_image)) img_b64() else NULL
      flyer_tag <- build_flyer_tag(badge_hex(), logo_b64 = logo_b64, course_img_src = img_src)
      html <- as.character(tagList(
        tags$html(
          tags$head(
            tags$meta(charset = "UTF-8"),
            tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap"),
            tags$link(rel = "stylesheet",
              href = "https://unpkg.com/boxicons@2.1.4/css/boxicons.min.css"),
            tags$style(HTML(css_flyer))
          ),
          tags$body(style = "margin:0; padding:2rem; background:#f5f5f5;", flyer_tag)
        )
      ))
      writeLines(html, file)
    }
  )
}

shinyApp(ui, server)
