# Paquetes que no están en las librerías del sistema (ej. shinyjqui) viven en
# rlibs/, relativo a esta app — evita depender de una instalación system-wide
# que requeriría permisos de root para el usuario "shiny".
.libPaths(c(file.path(getwd(), "rlibs"), .libPaths()))

# Shiny auto-carga R/*.R (loadSupport()) ANTES de correr este app.R -- por
# eso el código de nivel superior en R/ es o bien definiciones de función, o
# bien código base-R / con paquete namespaced explícito (ej. base64enc::), y
# por lo que la UI (R/09_ui.R) queda envuelta en build_ui() en vez de
# ejecutarse al cargar: recién se llama acá abajo, con los paquetes ya
# adjuntos. global.R NO se usa (Shiny no lo lee en apps de un solo app.R).
library(shiny)
library(bslib)
library(htmltools)
library(base64enc)
library(jsonlite)
library(shinyjqui)

# ---- Módulos (R/): utilidades, config, CSS, builders de HTML y UI ----
# Ya fueron auto-cargados por Shiny (loadSupport(), orden numérico en R/) --
# los objetos y funciones que definen (build_ui(), build_flyer_tag(), css_*,
# run_flyer_render(), etc.) están disponibles en este entorno.
ui <- build_ui()

# ============================================================
# ---- SERVER ----
# ============================================================
server <- function(input, output, session) {

  # -- Worker de preview en vivo (Etapa 3, ver R/10_flyer_worker.R) --
  # Un proceso node por sesión; si no arranca, flyer_worker_ensure() sigue
  # devolviendo NULL y el llamador cae al último HTML bueno en cache.
  flyer_worker <- flyer_worker_start()
  session$onSessionEnded(function() {
    if (!is.null(flyer_worker)) try(flyer_worker$proc$kill(), silent = TRUE)
  })
  flyer_worker_ensure <- function() {
    if (!flyer_worker_alive(flyer_worker)) flyer_worker <<- flyer_worker_start()
    flyer_worker
  }

  # -- Landing: tarjetas --
  # Cada tarjeta de "Inicio" cambia de tab con nav_select(). Ya no hace falta
  # precargar ningún selector interno (2026-09-17): las 4 variantes del
  # carrusel de Instagram, que antes vivían detrás de un selectInput "Tipo
  # de carrusel" dentro de una sola tab, ahora son 4 tabs dedicadas -- ver
  # nota en R/09_ui.R.
  observeEvent(input$home_curso_carrusel,  nav_select("main_nav", "ig_curso", session = session))
  observeEvent(input$home_curso_tarjeta,   nav_select("main_nav", "ig_tarjeta", session = session))
  observeEvent(input$home_descuento,       nav_select("main_nav", "ig_descuento", session = session))
  observeEvent(input$home_paquete_carrusel, nav_select("main_nav", "ig_paquete", session = session))
  observeEvent(input$home_catalogo, nav_select("main_nav", "catalogo", session = session))
  observeEvent(input$home_viz,      nav_select("main_nav", "viz", session = session))
  observeEvent(input$home_newsletter, nav_select("main_nav", "newsletter", session = session))
  observeEvent(input$home_cita,      nav_select("main_nav", "cita", session = session))
  observeEvent(input$home_blog,      nav_select("main_nav", "blog", session = session))
  observeEvent(input$home_encuesta,  nav_select("main_nav", "encuesta", session = session))

  # Links "← Inicio" repetidos arriba de cada generador (ver back_to_home()
  # en R/09_ui.R, un input distinto por tab para no repetir IDs) -- todas
  # las tabs de destino están escondidas de la barra de navegación (ver
  # .navbar-nav en css_app), así que esta es la única vuelta explícita.
  for (suf in c("paquete", "curso", "tarjeta", "descuento", "viz", "catalogo", "newsletter", "cita", "blog", "encuesta")) {
    local({
      id <- paste0("go_home_", suf)
      observeEvent(input[[id]], nav_select("main_nav", "home", session = session), ignoreInit = TRUE)
    })
  }

  # -- Instagram: reactivos --
  # Deriva de qué tab está activa en vez de un selectInput -- las 4
  # variantes (paquete/curso/tarjeta/descuento) son tabs separadas desde
  # 2026-09-17, no un selector dentro de una tab compartida.
  ig_tipo <- reactive({
    switch(input$main_nav %||% "",
      ig_paquete   = "paquete",
      ig_curso     = "curso",
      ig_tarjeta   = "tarjeta",
      ig_descuento = "descuento",
      "paquete"
    )
  })

  ig_data <- reactive({
    redes_sel <- input$ig_pkg_redes
    if (is.null(redes_sel)) redes_sel <- character(0)
    list(
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
      s4_tagline = input$ig_s4_tagline,
      redes      = redes_sel
    )
  })

  ig_curso_data <- reactive({
    redes_sel <- input$ig_c_redes
    if (is.null(redes_sel)) redes_sel <- character(0)
    plan <- input$ig_c_slides_dentro
    if (is.null(plan)) plan <- CURSO_SLIDES_DEFAULT
    list(
      plan           = plan,
      nombre         = input$ig_c_nombre %||% "",
      badge          = input$ig_c_badge %||% "Curso virtual",
      tagline        = input$ig_c_tagline %||% "",
      fecha_inicio   = input$ig_c_fecha_inicio %||% "",
      s2_bullets     = strsplit(input$ig_c_s2_bullets %||% "", "\n")[[1]],
      llevas_bullets = strsplit(input$ig_c_llevas_bullets %||% "", "\n")[[1]],
      cta            = input$ig_c_cta %||% "Inscripción abierta",
      redes          = redes_sel,
      s4_instr       = input$ig_c_s4_instr %||% "",
      s4_palabra     = input$ig_c_s4_palabra %||% "INFO",
      s4_refuerzo    = input$ig_c_s4_refuerzo %||% ""
    )
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

  # Preview en vivo (Etapa 3, mismo patrón que Visuales para redes, ver
  # R/10_flyer_worker.R): el HTML sale del worker (misma fuente que el ZIP
  # descargado), con debounce() y cache del último HTML bueno por slide para
  # que un worker lento/reiniciándose no deje el preview en blanco.
  ig_last_html <- new.env(parent = emptyenv())

  # -- Carrusel de paquete (slides 1-4) --
  ig_debounced <- debounce(reactive({
    list(d = ig_data(), imagen = if (!is.null(input$ig_pkg_img)) input$ig_pkg_img$datapath else NULL)
  }), 400)

  ig_slide_render <- function(key, template) {
    inp <- ig_debounced()
    d <- inp$d
    config <- list(
      pkg_nombre     = d$nombre,
      categoria      = d$categoria,
      version_line   = d$version,
      autor_line     = d$autor,
      slide1_tagline = d$s1_tagline,
      slide1_imagen  = inp$imagen,
      slide2_titulo  = d$s2_titulo,
      slide2_desc    = d$s2_desc,
      slide2_bullets = I(d$s2_bullets),
      slide3_titulo  = d$s3_titulo,
      slide3_codigo  = d$s3_codigo,
      slide4_tagline = d$s4_tagline,
      redes          = I(d$redes)
    )
    html <- flyer_worker_render(flyer_worker_ensure(), template, config)
    if (is.null(html)) html <- ig_last_html[[key]] else ig_last_html[[key]] <- html
    html
  }

  output$preview_s1 <- renderUI({ html <- ig_slide_render("s1", "slide1"); req(html); slide_iframe(html) })
  output$preview_s2 <- renderUI({ html <- ig_slide_render("s2", "slide2"); req(html); slide_iframe(html) })
  output$preview_s3 <- renderUI({ html <- ig_slide_render("s3", "slide3"); req(html); slide_iframe(html) })
  output$preview_s4 <- renderUI({ html <- ig_slide_render("s4", "slide4"); req(html); slide_iframe(html) })

  # -- Instagram: labels de slides (paquete de R) --
  output$label_s2 <- renderUI(div(class = "slide-label", "Slide 2 — ¿Qué hace?"))
  output$label_s3 <- renderUI(div(class = "slide-label", "Slide 3 — Código"))
  output$label_s4 <- renderUI(div(class = "slide-label", "Slide 4 — Cierre"))

  # -- Tarjeta clásica de curso (4:5 + 16:9) --
  ig_tarjeta_debounced <- debounce(reactive({
    list(d = ig_tarjeta_data(), imagen = if (!is.null(input$ig_t_img)) input$ig_t_img$datapath else NULL)
  }), 400)

  ig_tarjeta_render <- function(key, formato) {
    inp <- ig_tarjeta_debounced()
    config <- list(
      fondo   = inp$d$fondo,
      titulo  = inp$d$titulo,
      tagline = inp$d$tagline,
      items   = inp$d$items,
      inscripcion_texto = inp$d$inscripcion_texto,
      imagen_curso = inp$imagen
    )
    html <- flyer_worker_render(flyer_worker_ensure(), "tarjeta_curso", config, formato)
    if (is.null(html)) html <- ig_last_html[[key]] else ig_last_html[[key]] <- html
    html
  }

  output$preview_t45 <- renderUI({
    html <- ig_tarjeta_render("t45", "4x5")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_t169 <- renderUI({
    html <- ig_tarjeta_render("t169", "16x9")
    req(html)
    tarjeta_iframe(html, 1920, 1080, 540)
  })

  # -- Tarjeta de descuento (4:5 + 1:1 + 16:9) --
  ig_descuento_data <- reactive({
    list(
      descuento = input$ig_d_descuento %||% "",
      curso     = input$ig_d_curso %||% "",
      codigo    = input$ig_d_codigo %||% "",
      vigencia  = input$ig_d_vigencia %||% "",
      cta       = input$ig_d_cta %||% "Aprovechá ahora"
    )
  })

  ig_descuento_debounced <- debounce(ig_descuento_data, 400)

  ig_descuento_render <- function(key, formato) {
    d <- ig_descuento_debounced()
    config <- list(
      descuento = d$descuento,
      curso     = d$curso,
      codigo    = d$codigo,
      vigencia  = d$vigencia,
      cta       = d$cta
    )
    html <- flyer_worker_render(flyer_worker_ensure(), "descuento", config, formato)
    if (is.null(html)) html <- ig_last_html[[key]] else ig_last_html[[key]] <- html
    html
  }

  output$preview_d45 <- renderUI({
    html <- ig_descuento_render("d45", "4x5")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_d11 <- renderUI({
    html <- ig_descuento_render("d11", "1x1")
    req(html)
    tarjeta_iframe(html, 1080, 1080, 540)
  })
  output$preview_d169 <- renderUI({
    html <- ig_descuento_render("d169", "16x9")
    req(html)
    tarjeta_iframe(html, 1920, 1080, 540)
  })

  # -- Instagram: carrusel de curso — grid dinámico según el plan de placas --
  ig_curso_debounced <- debounce(reactive({
    list(d = ig_curso_data(), imagen = if (!is.null(input$ig_c_img)) input$ig_c_img$datapath else NULL)
  }), 400)

  output$curso_preview_grid <- renderUI({
    inp <- ig_curso_debounced()
    d <- inp$d
    plan <- d$plan
    total <- length(plan)
    config <- list(
      plan           = I(plan),
      nombre         = d$nombre,
      badge          = d$badge,
      tagline        = d$tagline,
      fecha_inicio   = d$fecha_inicio,
      s2_bullets     = I(d$s2_bullets),
      llevas_bullets = I(d$llevas_bullets),
      cta            = d$cta,
      redes          = I(d$redes),
      s4_instr       = d$s4_instr,
      s4_palabra     = d$s4_palabra,
      s4_refuerzo    = d$s4_refuerzo,
      imagen_curso   = inp$imagen
    )
    worker <- flyer_worker_ensure()
    tagList(lapply(seq_along(plan), function(i) {
      tipo <- plan[i]
      etiqueta <- CURSO_SLIDE_LABELS[[tipo]] %||% tipo
      key <- paste0("curso_", i, "_", tipo)
      html <- flyer_worker_render(worker, "course_slide", config, tipo = tipo, position = i, total = total)
      if (is.null(html)) html <- ig_last_html[[key]] else ig_last_html[[key]] <- html
      if (is.null(html)) return(NULL)
      div(
        div(class = "slide-label", paste0(i, ". ", etiqueta)),
        slide_iframe(html)
      )
    }))
  })

  # -- Instagram: descarga ZIP --
  # Los 4 botones de descarga (uno por tab, ver R/09_ui.R) comparten esta
  # misma lógica -- content()/filename() ya leen de ig_tipo(), que ahora
  # deriva de qué tab está activa, así que un solo downloadHandler asignado
  # a los 4 outputs alcanza (no hace falta duplicar la lógica).
  descargar_zip_handler <- downloadHandler(
    filename = function() {
      pref <- switch(ig_tipo(),
        tarjeta   = "tarjeta_er_",
        curso     = "carrusel_curso_er_",
        descuento = "descuento_er_",
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
      } else if (identical(ig_tipo(), "descuento")) {
        d <- ig_descuento_data()
        config <- list(
          template  = "descuento",
          output_dir = slide_dir,
          descuento = d$descuento,
          curso     = d$curso,
          codigo    = d$codigo,
          vigencia  = d$vigencia,
          cta       = d$cta,
          formatos  = I(c("4x5", "1x1", "16x9"))
        )
      } else if (identical(ig_tipo(), "curso")) {
        d <- ig_curso_data()
        config <- list(
          template       = "carousel_curso",
          output_dir     = slide_dir,
          plan           = I(d$plan),
          nombre         = d$nombre,
          badge          = d$badge,
          tagline        = d$tagline,
          fecha_inicio   = d$fecha_inicio,
          s2_bullets     = I(d$s2_bullets),
          llevas_bullets = I(d$llevas_bullets),
          cta            = d$cta,
          redes          = I(d$redes),
          s4_instr       = d$s4_instr,
          s4_palabra     = d$s4_palabra,
          s4_refuerzo    = d$s4_refuerzo,
          imagen_curso   = if (!is.null(input$ig_c_img)) input$ig_c_img$datapath else NULL
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
          slide1_imagen  = if (!is.null(input$ig_pkg_img)) input$ig_pkg_img$datapath else NULL,
          slide2_titulo  = d$s2_titulo,
          slide2_desc    = d$s2_desc,
          slide2_bullets = d$s2_bullets,
          slide3_titulo  = d$s3_titulo,
          slide3_codigo  = d$s3_codigo,
          slide4_tagline = d$s4_tagline,
          redes          = I(d$redes)
        )
      }

      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "el carrusel", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(slide_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar el carrusel: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(slide_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )
  output$descargar_zip_paquete   <- descargar_zip_handler
  output$descargar_zip_curso     <- descargar_zip_handler
  output$descargar_zip_tarjeta   <- descargar_zip_handler
  output$descargar_zip_descuento <- descargar_zip_handler

  # -- Visuales para redes: reactivos --
  viz_data <- reactive({
    list(
      badge   = input$viz_badge %||% "",
      titulo  = input$viz_titulo %||% "",
      fuente  = input$viz_fuente %||% "",
      handles = input$viz_handles %||% ""
    )
  })

  # Preview en vivo (Etapa 3): el HTML sale del worker (mismo builder JS que
  # generate_flyer.js usa para el ZIP descargado, ver R/10_flyer_worker.R),
  # no de un builder R espejado. debounce() evita pegarle al worker en cada
  # tecla; viz_last_html cachea el último HTML bueno por formato para que,
  # si el worker no respondió a tiempo, el preview no parpadee a blanco.
  viz_debounced <- debounce(reactive({
    list(d = viz_data(), imagen = if (!is.null(input$viz_img)) input$viz_img$datapath else NULL)
  }), 400)

  viz_last_html <- new.env(parent = emptyenv())

  viz_render_fmt <- function(fmt) {
    inp <- viz_debounced()
    config <- list(
      badge   = inp$d$badge,
      titulo  = inp$d$titulo,
      fuente  = inp$d$fuente,
      handles = inp$d$handles,
      imagen  = inp$imagen
    )
    html <- flyer_worker_render(flyer_worker_ensure(), "viz_redes", config, fmt)
    if (is.null(html)) {
      html <- viz_last_html[[fmt]]
    } else {
      viz_last_html[[fmt]] <- html
    }
    html
  }

  viz_preview <- function(fmt, w, h) {
    html <- viz_render_fmt(fmt)
    req(html)
    tarjeta_iframe(html, w, h, 540)
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

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "los visuales", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(viz_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar los visuales: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(viz_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # La pestaña "💼 LinkedIn · X" (tarjeta Tip/Paquete de R) se sacó el
  # 2026-09-17 -- Pablo decidió usar los slides de "💡 Tip de R" (antes
  # "Carrusel de paquete", renombrado en R/09_ui.R) para LinkedIn/X también,
  # en vez de mantener un generador aparte. Ver
  # memory/proyecto-flyer-generator.md.

  # -- Catálogo de Paquetes: reactivos --
  # Mismo patrón que "Visuales para redes": el preview siempre muestra los 3
  # formatos, el checkbox de formatos solo decide qué va en el ZIP descargado.
  catalogo_data <- reactive({
    list(
      paquetes = list(
        list(nombre = input$cat_p1_nombre %||% "", pais = input$cat_p1_pais %||% "", descripcion = input$cat_p1_desc %||% ""),
        list(nombre = input$cat_p2_nombre %||% "", pais = input$cat_p2_pais %||% "", descripcion = input$cat_p2_desc %||% ""),
        list(nombre = input$cat_p3_nombre %||% "", pais = input$cat_p3_pais %||% "", descripcion = input$cat_p3_desc %||% "")
      ),
      total_paquetes = input$cat_total_paquetes %||% 0,
      total_paises   = input$cat_total_paises %||% 0
    )
  })

  catalogo_debounced <- debounce(catalogo_data, 400)

  catalogo_last_html <- new.env(parent = emptyenv())

  catalogo_render <- function(key, formato) {
    d <- catalogo_debounced()
    config <- list(
      paquetes       = d$paquetes,
      total_paquetes = d$total_paquetes,
      total_paises   = d$total_paises
    )
    html <- flyer_worker_render(flyer_worker_ensure(), "catalogo", config, formato)
    if (is.null(html)) html <- catalogo_last_html[[key]] else catalogo_last_html[[key]] <- html
    html
  }

  output$preview_cat_redes <- renderUI({
    html <- catalogo_render("redes", "redes")
    req(html)
    tarjeta_iframe(html, 1200, 630, 540)
  })
  output$preview_cat_feed <- renderUI({
    html <- catalogo_render("feed", "feed")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_cat_story <- renderUI({
    html <- catalogo_render("story", "story")
    req(html)
    tarjeta_iframe(html, 1080, 1920, 540)
  })

  # -- Catálogo de Paquetes: descarga ZIP --
  output$descargar_catalogo_zip <- downloadHandler(
    filename = function() paste0("catalogo_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$cat_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- catalogo_data()
      cat_dir <- tempfile(pattern = "catalogo_")
      dir.create(cat_dir)
      on.exit(unlink(cat_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template       = "catalogo",
        output_dir     = cat_dir,
        paquetes       = d$paquetes,
        total_paquetes = d$total_paquetes,
        total_paises   = d$total_paises,
        formatos       = I(fmts)
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "el catálogo", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(cat_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar el catálogo: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(cat_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Newsletter semanal: reactivos --
  # Fusiona generar_imagen_newsletter.py de redes (2026-10-02): mismo layout
  # de dos bloques que el Catálogo (template "catalogo" con tipo "newsletter"
  # en generate_flyer.js), sin lista de paquetes -- el bloque amarillo lleva
  # número de edición y fecha en vez de totales del catálogo.
  newsletter_data <- reactive({
    list(
      tipo        = "newsletter",
      badge_texto = "Newsletter",
      titulo      = input$nl_titulo  %||% "Newsletter<br>Semanal",
      tagline     = input$nl_tagline %||% "Lo mejor de la semana en R, directo a tu email",
      num         = input$nl_edicion %||% "",
      num_label   = "Edición",
      num_sub     = input$nl_fecha   %||% ""
    )
  })

  newsletter_debounced <- debounce(newsletter_data, 400)
  newsletter_last_html <- new.env(parent = emptyenv())

  newsletter_render <- function(key, formato) {
    d <- newsletter_debounced()
    html <- flyer_worker_render(flyer_worker_ensure(), "catalogo", d, formato)
    if (is.null(html)) html <- newsletter_last_html[[key]] else newsletter_last_html[[key]] <- html
    html
  }

  output$preview_nl_redes <- renderUI({
    html <- newsletter_render("redes", "redes")
    req(html)
    tarjeta_iframe(html, 1200, 630, 540)
  })
  output$preview_nl_feed <- renderUI({
    html <- newsletter_render("feed", "feed")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_nl_story <- renderUI({
    html <- newsletter_render("story", "story")
    req(html)
    tarjeta_iframe(html, 1080, 1920, 540)
  })

  # -- Newsletter semanal: descarga ZIP --
  output$descargar_newsletter_zip <- downloadHandler(
    filename = function() paste0("newsletter_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$nl_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- newsletter_data()
      nl_dir <- tempfile(pattern = "newsletter_")
      dir.create(nl_dir)
      on.exit(unlink(nl_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template    = "catalogo",
        tipo        = "newsletter",
        output_dir  = nl_dir,
        badge_texto = d$badge_texto,
        titulo      = d$titulo,
        tagline     = d$tagline,
        num         = d$num,
        num_label   = d$num_label,
        num_sub     = d$num_sub,
        formatos    = I(fmts)
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "la newsletter", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(nl_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar la newsletter: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(nl_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Cita destacada: reactivos (issue #3, template "cita" en JS) --
  cita_data <- reactive({
    list(
      cita        = input$cita_texto %||% "",
      autor       = input$cita_autor %||% "",
      contexto    = input$cita_contexto %||% "",
      badge_texto = input$cita_badge %||% "Cita",
      handles     = input$cita_handles %||% ""
    )
  })

  cita_debounced <- debounce(cita_data, 400)
  cita_last_html <- new.env(parent = emptyenv())

  cita_render <- function(key, formato) {
    d <- cita_debounced()
    html <- flyer_worker_render(flyer_worker_ensure(), "cita", d, formato)
    if (is.null(html)) html <- cita_last_html[[key]] else cita_last_html[[key]] <- html
    html
  }

  output$preview_cita_redes <- renderUI({
    html <- cita_render("redes", "redes")
    req(html)
    tarjeta_iframe(html, 1200, 630, 540)
  })
  output$preview_cita_feed <- renderUI({
    html <- cita_render("feed", "feed")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_cita_story <- renderUI({
    html <- cita_render("story", "story")
    req(html)
    tarjeta_iframe(html, 1080, 1920, 540)
  })

  # -- Cita destacada: descarga ZIP --
  output$descargar_cita_zip <- downloadHandler(
    filename = function() paste0("cita_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$cita_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- cita_data()
      out_dir <- tempfile(pattern = "cita_")
      dir.create(out_dir)
      on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template    = "cita",
        output_dir  = out_dir,
        cita        = d$cita,
        autor       = d$autor,
        contexto    = d$contexto,
        badge_texto = d$badge_texto,
        handles     = d$handles,
        formatos    = I(fmts)
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "la cita", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(out_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar la cita: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(out_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Anuncio de blog: reactivos (tipo "blog" del template catalogo) --
  blog_data <- reactive({
    list(
      tipo        = "blog",
      badge_texto = "Blog",
      titulo      = input$blog_titulo %||% "",
      tagline     = input$blog_extracto %||% "",
      num         = input$blog_cta_num %||% "Leer",
      num_label   = input$blog_cta_label %||% "Link en el post fijado",
      num_sub     = input$blog_cta_sub %||% "estacion-r.com"
    )
  })

  blog_debounced <- debounce(blog_data, 400)
  blog_last_html <- new.env(parent = emptyenv())

  blog_render <- function(key, formato) {
    d <- blog_debounced()
    html <- flyer_worker_render(flyer_worker_ensure(), "catalogo", d, formato)
    if (is.null(html)) html <- blog_last_html[[key]] else blog_last_html[[key]] <- html
    html
  }

  output$preview_blog_redes <- renderUI({
    html <- blog_render("redes", "redes")
    req(html)
    tarjeta_iframe(html, 1200, 630, 540)
  })
  output$preview_blog_feed <- renderUI({
    html <- blog_render("feed", "feed")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_blog_story <- renderUI({
    html <- blog_render("story", "story")
    req(html)
    tarjeta_iframe(html, 1080, 1920, 540)
  })

  # -- Anuncio de blog: descarga ZIP --
  output$descargar_blog_zip <- downloadHandler(
    filename = function() paste0("blog_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$blog_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- blog_data()
      out_dir <- tempfile(pattern = "blog_")
      dir.create(out_dir)
      on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template    = "catalogo",
        tipo        = "blog",
        output_dir  = out_dir,
        badge_texto = d$badge_texto,
        titulo      = d$titulo,
        tagline     = d$tagline,
        num         = d$num,
        num_label   = d$num_label,
        num_sub     = d$num_sub,
        formatos    = I(fmts)
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "el anuncio de blog", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(out_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar el anuncio de blog: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(out_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Resumen de encuesta: reactivos (tipo "encuesta" del template catalogo) --
  enc_data <- reactive({
    opciones <- list(
      list(texto = input$enc_o1 %||% "", pct = as.numeric(input$enc_p1 %||% 0)),
      list(texto = input$enc_o2 %||% "", pct = as.numeric(input$enc_p2 %||% 0)),
      list(texto = input$enc_o3 %||% "", pct = as.numeric(input$enc_p3 %||% 0)),
      list(texto = input$enc_o4 %||% "", pct = as.numeric(input$enc_p4 %||% 0))
    )
    # Opciones vacías no se muestran (uso esporádico, cantidad variable)
    opciones <- Filter(function(o) nzchar(trimws(o$texto)), opciones)
    list(
      tipo      = "encuesta",
      titulo    = input$enc_pregunta %||% "",
      opciones  = opciones,
      num       = input$enc_total %||% 0,
      num_label = "Respuestas",
      num_sub   = "¡Gracias por participar!"
    )
  })

  enc_debounced <- debounce(enc_data, 400)
  enc_last_html <- new.env(parent = emptyenv())

  enc_render <- function(key, formato) {
    d <- enc_debounced()
    html <- flyer_worker_render(flyer_worker_ensure(), "catalogo", d, formato)
    if (is.null(html)) html <- enc_last_html[[key]] else enc_last_html[[key]] <- html
    html
  }

  output$preview_enc_redes <- renderUI({
    html <- enc_render("redes", "redes")
    req(html)
    tarjeta_iframe(html, 1200, 630, 540)
  })
  output$preview_enc_feed <- renderUI({
    html <- enc_render("feed", "feed")
    req(html)
    tarjeta_iframe(html, 1080, 1350, 540)
  })
  output$preview_enc_story <- renderUI({
    html <- enc_render("story", "story")
    req(html)
    tarjeta_iframe(html, 1080, 1920, 540)
  })

  # -- Resumen de encuesta: descarga ZIP --
  output$descargar_enc_zip <- downloadHandler(
    filename = function() paste0("encuesta_er_", format(Sys.Date(), "%Y%m%d"), ".zip"),
    content = function(file) {
      fmts <- input$enc_formatos
      if (length(fmts) == 0) stop("Elegí al menos un formato")
      d <- enc_data()
      out_dir <- tempfile(pattern = "encuesta_")
      dir.create(out_dir)
      on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

      config <- list(
        template    = "catalogo",
        tipo        = "encuesta",
        output_dir  = out_dir,
        titulo      = d$titulo,
        opciones    = d$opciones,
        num         = d$num,
        num_label   = d$num_label,
        num_sub     = d$num_sub,
        formatos    = I(fmts)
      )
      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file), "la encuesta", session)
      if (is.null(result)) req(FALSE)

      pngs <- list.files(out_dir, pattern = "\\.png$", full.names = FALSE)
      if (length(pngs) == 0) {
        showNotification("No se pudo generar la encuesta: el render no produjo ninguna imagen (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }

      old_wd <- setwd(out_dir)
      on.exit(setwd(old_wd), add = TRUE)
      utils::zip(zipfile = file, files = pngs, flags = "-j9")
    }
  )

  # -- Fix: previews de cita/blog/encuesta no computaban al abrir la tab --
  # Sintoma: al entrar desde la landing, los previews quedaban en
  # "recalculating" eterno (0 iframes) mientras newsletter/catalogo andaban
  # igual. Diagnostico con trazas: el path de computo estaba OK (worker
  # responde, debounce dispara, renderUI corre); lo que no llega es la
  # senal de visibilidad del cliente para estos outputs al activar el pane
  # via nav_select -- con Shiny.unbindAll()/bindAll() manual renderizaban
  # al instante (probado E2E). Con suspendWhenHidden = FALSE el server los
  # computa en el primer flush (invalidacion del debounce ~400ms tras el
  # arranque) y el preview ya esta renderizado al abrir la tab. Mismo
  # patron que shiny_eph_panel usa para sus vistas conditionalPanel. Las
  # tabs preexistentes no se tocan: su senalizacion funciona y no vale la
  # pena sumar renders de arranque.
  for (out in c(
    "preview_cita_redes", "preview_cita_feed", "preview_cita_story",
    "preview_blog_redes", "preview_blog_feed", "preview_blog_story",
    "preview_enc_redes",  "preview_enc_feed",  "preview_enc_story"
  )) {
    outputOptions(output, out, suspendWhenHidden = FALSE)
  }
}

shinyApp(ui, server)
