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

