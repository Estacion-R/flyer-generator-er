# tarjeta_html/tarjeta_item_html (builder de la tarjeta clásica) se eliminaron
# en la Etapa 3: el preview en vivo ahora pide el HTML a generate_flyer.js
# (buildTarjetaHTML) vía el worker persistente, ver R/10_flyer_worker.R.

# ---- Iframe de preview reusado por tarjeta clásica y visuales para redes ----
tarjeta_iframe <- function(html_str, w, h, wrap_w) {
  scale <- round(wrap_w / w, 4)
  div(style = paste0("width:", wrap_w, "px; height:", ceiling(h * scale),
    "px; overflow:hidden; flex-shrink:0; border:2px solid #C2C2C4;"),
    tags$iframe(srcdoc = html_str, scrolling = "no",
      style = paste0("width:", w, "px; height:", h, "px; border:none; display:block;",
        "transform:scale(", scale, "); transform-origin:top left;")))
}
