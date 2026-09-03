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

  # -- Instagram: reactivos --
  ig_tipo <- reactive(input$ig_tipo_carrusel %||% "paquete")

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
  output$descargar_zip <- downloadHandler(
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

  # -- LinkedIn/X: reactivos --
  lnk_formato_dims <- reactive(FORMATOS_LNK[[input$lnk_formato]])

  # Preview en vivo (Etapa 3, mismo patrón que las otras 2 pestañas): el HTML
  # sale del worker (mismo builder JS que usan las descargas desde la Etapa 2,
  # ver R/10_flyer_worker.R), con debounce() y cache del último HTML bueno.
  lnk_last_html <- new.env(parent = emptyenv())

  lnk_debounced <- debounce(reactive({
    list(
      template = input$lnk_template,
      tip = list(
        categoria    = input$lnk_tip_categoria,
        pkg_nombre   = input$lnk_tip_nombre,
        version_line = input$lnk_tip_version,
        descripcion  = input$lnk_tip_desc,
        codigo       = input$lnk_tip_codigo,
        autor_line   = input$lnk_tip_autor
      ),
      curso = list(
        formato      = lnk_formato_dims()$key,
        imagen_curso = if (!is.null(input$lnk_course_image)) input$lnk_course_image$datapath else NULL,
        badge_texto  = input$lnk_badge,
        badge_color  = input$lnk_badge_color,
        titulo       = input$lnk_titulo,
        subtitulo    = input$lnk_subtitulo,
        bullets      = I(strsplit(input$lnk_bullets %||% "", "\n")[[1]]),
        col1_texto   = input$lnk_col1,
        col2_texto   = input$lnk_col2,
        col3_texto   = input$lnk_col3,
        footer_texto = input$lnk_footer_texto,
        footer_icon  = input$lnk_footer_icon
      ),
      w = lnk_formato_dims()$w
    )
  }), 400)

  output$preview_lnk <- renderUI({
    inp <- lnk_debounced()
    is_tip <- identical(inp$template, "Tip / Paquete de R")
    key <- if (is_tip) "tip" else "curso"
    config <- if (is_tip) inp$tip else inp$curso
    html <- flyer_worker_render(flyer_worker_ensure(), key, config)
    if (is.null(html)) html <- lnk_last_html[[key]] else lnk_last_html[[key]] <- html
    req(html)
    # isolate(): leemos la última altura reportada por el iframe anterior sin
    # suscribirnos a sus cambios -- si no, cada Shiny.setInputValue() del
    # onload (ver flyer_iframe en R/08_builders_linkedin.R) re-invalidaría
    # este mismo renderUI y armaría un loop de re-renders.
    last_h <- isolate(input$lnk_preview_h) %||% 520
    flyer_iframe(html, if (is_tip) 540 else inp$w, last_h = last_h)
  })

  # -- LinkedIn/X: descarga HTML --
  output$lnk_descargar_html <- downloadHandler(
    filename = function() {
      pref <- if (identical(input$lnk_template, "Tip / Paquete de R")) "tip_er_" else "flyer_er_"
      paste0(pref, format(Sys.Date(), "%Y%m%d"), ".html")
    },
    content = function(file) {
      tmp_html <- tempfile(fileext = ".html")
      on.exit(unlink(tmp_html), add = TRUE)

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
      } else {
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
      }

      cfg_file <- tempfile(fileext = ".json")
      writeLines(jsonlite::toJSON(config, auto_unbox = TRUE, null = "null"), cfg_file)
      on.exit(unlink(cfg_file), add = TRUE)

      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file, "--output", tmp_html), "el HTML", session)
      if (is.null(result)) req(FALSE)
      if (!file.exists(tmp_html)) {
        showNotification("No se pudo generar el HTML: el render no produjo ningún archivo (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }
      file.copy(tmp_html, file, overwrite = TRUE)
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
        result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file, "--output", file), "el PNG", session)
        unlink(cfg_file)
        if (is.null(result)) req(FALSE)
        if (!file.exists(file)) {
          showNotification("No se pudo generar el PNG: el render no produjo ningún archivo (probá de nuevo).",
            type = "error", duration = 10, session = session)
          req(FALSE)
        }
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
      result <- run_flyer_render(c(PLAYWRIGHT_SCRIPT, "--config", cfg_file, "--output", file), "el PNG", session)
      unlink(cfg_file)
      if (is.null(result)) req(FALSE)
      if (!file.exists(file)) {
        showNotification("No se pudo generar el PNG: el render no produjo ningún archivo (probá de nuevo).",
          type = "error", duration = 10, session = session)
        req(FALSE)
      }
    }
  )
}

shinyApp(ui, server)
