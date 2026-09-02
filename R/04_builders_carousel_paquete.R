# slide1_html-slide4_html (builders del carrusel de paquete) se eliminaron
# en la Etapa 3: el preview en vivo ahora pide el HTML a generate_flyer.js
# (buildSlide1-4) vía el worker persistente, ver R/10_flyer_worker.R.

# Helper: envuelve el HTML de una slide en un iframe escalado a 540×540
slide_iframe <- function(html_str) {
  div(class = "slide-preview-wrap",
    tags$iframe(srcdoc = html_str, scrolling = "no")
  )
}
