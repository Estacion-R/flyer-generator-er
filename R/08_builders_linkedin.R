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
