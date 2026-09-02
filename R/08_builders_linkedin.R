# build_flyer_tag/build_flyer_tip_tag (builders del flyer LinkedIn/X) se
# eliminaron en la Etapa 3: el preview en vivo ahora pide el HTML a
# generate_flyer.js (buildHTML/buildTipHTML) vía el worker persistente, ver
# R/10_flyer_worker.R. A diferencia de las otras pestañas, el HTML que
# devuelve el worker es un documento standalone con su propio <style> (no
# comparte el css_flyer/css_tip inyectado en la página) -- se muestra en un
# iframe de ancho fijo (igual que la descarga) y alto automático. Cada
# renderUI reemplaza el iframe entero (nuevo srcdoc), así que arranca con
# `last_h` (la última altura real, reportada por el iframe anterior vía
# Shiny.setInputValue -- ver input_id) en vez de un valor fijo arbitrario:
# entre una tecla y la siguiente el contenido cambia poco, así que el
# iframe ya nace con la altura correcta o muy cerca; el onload ajusta el
# alto exacto y reporta el nuevo valor para la próxima vez (grande
# únicamente en la primera carga de la sesión).
flyer_iframe <- function(html_str, w, last_h = 520, input_id = "lnk_preview_h") {
  tags$iframe(
    srcdoc = html_str,
    scrolling = "no",
    style = paste0("width:", w, "px; height:", last_h, "px; border:none; display:block;"),
    onload = paste0(
      "var h=this.contentWindow.document.body.scrollHeight;",
      "this.style.height=h+'px';",
      "if(window.Shiny)Shiny.setInputValue('", input_id, "',h);"
    )
  )
}
