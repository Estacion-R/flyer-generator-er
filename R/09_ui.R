# ============================================================
# ---- UI ----
# ============================================================
# Envuelta en función (en vez de `ui <- page_navbar(...)` a nivel de archivo):
# Shiny auto-carga R/ (loadSupport()) ANTES de correr app.R y sin haber
# corrido todavía sus library(bslib/htmltools/...) -- si esto se evaluara acá
# arriba, page_navbar() no existiría aún. build_ui() se llama recién desde
# app.R, después de sus library(), cuando bslib ya está attached.
build_ui <- function() {
  page_navbar(
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
                      "🎴 Tarjeta clásica" = "tarjeta", "🏷️ Tarjeta de descuento" = "descuento"),
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

          tags$span("Placas del carrusel — arrastrá para sacar/agregar y para ordenar", class = "section-label"),
          orderInput("ig_c_slides_dentro", "En el carrusel (el orden acá = el orden final)",
            items = curso_slide_items(CURSO_SLIDES_DEFAULT),
            connect = "ig_c_slides_fuera", item_class = "primary",
            placeholder = "Arrastrá placas acá"),
          orderInput("ig_c_slides_fuera", "Disponibles (afuera del carrusel)",
            items = curso_slide_items(character(0)),
            connect = "ig_c_slides_dentro", item_class = "default",
            placeholder = "Arrastrá acá para sacar una placa del carrusel"),
          tags$div(style = "height: 0.75rem;"),

          accordion(
            open = c("cpkg"),
            multiple = TRUE,

            accordion_panel("🎓 Datos del curso", value = "cpkg",
              tags$span("Tipo de evento (badge)", class = "section-label"),
              textInput("ig_c_badge", NULL, value = "Curso virtual"),
              tags$span("Nombre del curso", class = "section-label"),
              textAreaInput("ig_c_nombre", NULL, rows = 2,
                value = "Introducción a R para Ciencias Sociales"),
              tags$span("Tagline (portada)", class = "section-label"),
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

            accordion_panel("Contenido — ¿Qué vas a aprender?", value = "cs2",
              tags$span("Contenidos (uno por línea, máx 6)", class = "section-label"),
              textAreaInput("ig_c_s2_bullets", NULL, rows = 6,
                value = "Introducción a R y RStudio\nManejo de datos con tidyverse\nVisualización con ggplot2\nReportes con Quarto\nAnálisis estadístico aplicado\nProyecto integrador")
            ),

            accordion_panel("Contenido — ¿Qué te llevás?", value = "cllevas",
              tags$span("Contenidos (uno por línea, máx 6)", class = "section-label"),
              textAreaInput("ig_c_llevas_bullets", NULL, rows = 6,
                value = "Certificado de finalización\nGrabaciones de todas las clases\nMaterial y ejercicios en Google Drive\nAcceso a la comunidad de Estación R")
            ),

            accordion_panel("📱 Redes (última placa)", value = "credes",
              tags$span("Qué redes mostrar (van solo en la última placa)", class = "section-label"),
              checkboxGroupInput("ig_c_redes", NULL,
                choices = names(SOCIAL_ICONS), selected = SOCIAL_ICONS_DEFAULT)
            ),

            accordion_panel("Contenido — CTA de inscripción", value = "cs3",
              tags$span("Frase CTA", class = "section-label"),
              textInput("ig_c_cta", NULL, value = "Inscripción abierta")
            ),

            accordion_panel("Contenido — Contacto (INFO)", value = "cs4",
              tags$span("Instrucción", class = "section-label"),
              textInput("ig_c_s4_instr", NULL, value = "Comentá esta palabra en el posteo"),
              tags$span("Palabra clave (grande)", class = "section-label"),
              textInput("ig_c_s4_palabra", NULL, value = "INFO"),
              tags$span("Refuerzo", class = "section-label"),
              textAreaInput("ig_c_s4_refuerzo", NULL, rows = 2,
                value = "Te mandamos el programa completo y todo lo que tenés que saber de la nueva edición")
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

        conditionalPanel(
          condition = "input.ig_tipo_carrusel == 'descuento'",
          accordion(
            open = c("dbase"),
            multiple = TRUE,

            accordion_panel("🏷️ Descuento", value = "dbase",
              tags$span("Descuento (elemento central)", class = "section-label"),
              textInput("ig_d_descuento", NULL, value = "30% OFF"),
              tags$span("Curso / paquete al que aplica (opcional)", class = "section-label"),
              textAreaInput("ig_d_curso", NULL, rows = 2,
                value = "Introducción a R para Ciencias Sociales"),
              tags$span("Código de cupón (opcional)", class = "section-label"),
              textInput("ig_d_codigo", NULL, value = "R2026"),
              tags$span("Vigencia / fecha límite (opcional)", class = "section-label"),
              textInput("ig_d_vigencia", NULL, value = "Válido hasta el 30/9"),
              tags$span("CTA", class = "section-label"),
              textInput("ig_d_cta", NULL, value = "Aprovechá ahora")
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
            condition = "input.ig_tipo_carrusel == 'paquete'",
            div(
              div(class = "slide-label", "Slide 1 — Portada"),
              uiOutput("preview_s1")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'paquete'",
            div(
              uiOutput("label_s2"),
              uiOutput("preview_s2")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'paquete'",
            div(
              uiOutput("label_s3"),
              uiOutput("preview_s3")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'paquete'",
            div(
              uiOutput("label_s4"),
              uiOutput("preview_s4")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'curso'",
            uiOutput("curso_preview_grid")
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
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'descuento'",
            div(
              div(class = "slide-label", "Feed — 4:5 (1080×1350)"),
              uiOutput("preview_d45")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'descuento'",
            div(
              div(class = "slide-label", "Cuadrado — 1:1 (1080×1080)"),
              uiOutput("preview_d11")
            )
          ),
          conditionalPanel(
            condition = "input.ig_tipo_carrusel == 'descuento'",
            div(
              div(class = "slide-label", "Horizontal — 16:9 (1920×1080)"),
              uiOutput("preview_d169")
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
          value = "@estacion.erre · @estacion_erre"),

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
}
