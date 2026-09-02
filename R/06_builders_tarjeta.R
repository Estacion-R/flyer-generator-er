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

