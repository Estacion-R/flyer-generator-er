# ---- Config ----
BADGE_COLORES <- c(
  "Azul ER"    = "#447099",
  "Naranja ER" = "#EE6331",
  "Teal ER"    = "#419599",
  "Negro"      = "#151515"
)

FORMATOS_LNK <- list(
  "Vertical — feed / LinkedIn (4:5)" = list(w = 540, h = NULL, key = "linkedin"),
  "Story / Reels — WhatsApp (9:16)"  = list(w = 380, h = 675,  key = "story")
)

# Redes sociales oficiales de Estación R (confirmado con redes, 2026-09-02).
# Instagram/X/LinkedIn están en el footer del sitio; Bluesky/Mastodon son cuenta
# personal de Pablo con voz de marca, activas pero no oficializadas en el sitio.
# Íconos: Simple Icons (CC0), viewBox 24x24, un solo <path>.
SOCIAL_ICONS <- list(
  "Instagram" = list(
    handle = "@estacion.erre",
    icon = "M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077"
  ),
  "X / Twitter" = list(
    handle = "@estacion_erre",
    icon = "M14.234 10.162 22.977 0h-2.072l-7.591 8.824L7.251 0H.258l9.168 13.343L.258 24H2.33l8.016-9.318L16.749 24h6.993zm-2.837 3.299-.929-1.329L3.076 1.56h3.182l5.965 8.532.929 1.329 7.754 11.09h-3.182z"
  ),
  "LinkedIn" = list(
    handle = "Estación R",
    icon = "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z"
  ),
  "Bluesky" = list(
    handle = "@pablote.bsky.social",
    icon = "M5.202 2.857C7.954 4.922 10.913 9.11 12 11.358c1.087-2.247 4.046-6.436 6.798-8.501C20.783 1.366 24 .213 24 3.883c0 .732-.42 6.156-.667 7.037-.856 3.061-3.978 3.842-6.755 3.37 4.854.826 6.089 3.562 3.422 6.299-5.065 5.196-7.28-1.304-7.847-2.97-.104-.305-.152-.448-.153-.327 0-.121-.05.022-.153.327-.568 1.666-2.782 8.166-7.847 2.97-2.667-2.737-1.432-5.473 3.422-6.3-2.777.473-5.899-.308-6.755-3.369C.42 10.04 0 4.615 0 3.883c0-3.67 3.217-2.517 5.202-1.026"
  ),
  "Mastodon" = list(
    handle = "@pablote@mastodon.social",
    icon = "M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.67 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z"
  )
)
SOCIAL_ICONS_DEFAULT <- c("Instagram", "X / Twitter", "LinkedIn")

social_pill_html <- function(name, fg) {
  info <- SOCIAL_ICONS[[name]]
  if (is.null(info)) return("")
  paste0('<div class="pill"><svg viewBox="0 0 24 24" style="width:22px;height:22px;flex-shrink:0;display:block;" fill="', fg, '"><path d="', info$icon, '"/></svg><span>', he(info$handle), '</span></div>')
}

# ---- Catálogo de placas del carrusel de curso (orden/selección vía sticker) ----
CURSO_SLIDE_LABELS <- c(
  portada  = "Portada",
  aprender = "¿Qué vas a aprender?",
  llevas   = "¿Qué te llevás?",
  cta      = "CTA de inscripción",
  contacto = "Contacto (INFO)"
)
CURSO_SLIDES_DEFAULT <- c("portada", "aprender", "llevas", "cta", "contacto")

# Arma un vector con nombre = etiqueta visible, valor = clave interna, para orderInput()
curso_slide_items <- function(keys) setNames(keys, unname(CURSO_SLIDE_LABELS[keys]))

PLAYWRIGHT_SCRIPT <- "generate_flyer.js"
LOGO_PATH         <- "www/logo_er.png"
NODE_BIN          <- "/home/linuxbrew/.linuxbrew/bin/node"
LOGO_B64          <- paste0("data:image/png;base64,", base64enc::base64encode(LOGO_PATH))
RENDER_TIMEOUT_S  <- 40

# Corre el render de Playwright (generate_flyer.js) con timeout; devuelve NULL
# y avisa con showNotification en español si el proceso falla o no responde,
# en vez de dejar pasar el error crudo de R/Shiny a la UI.
run_flyer_render <- function(args, label, session, timeout = RENDER_TIMEOUT_S) {
  tryCatch({
    system2(NODE_BIN, args = args, stdout = TRUE, stderr = TRUE, timeout = timeout)
  }, error = function(e) {
    showNotification(
      paste0("No se pudo generar ", label, ": ", conditionMessage(e)),
      type = "error", duration = 10, session = session)
    NULL
  })
}

# ---- Tarjeta clásica de curso (4:5 + 16:9, 4 fondos) ----
TARJETA_FONDO_OPTS <- c("Negro" = "negro", "Azul" = "azul",
                        "Amarillo ER" = "amarillo", "Blanco" = "blanco")

TARJETA_FONDOS <- list(
  negro    = list(bg = "#191919", ink = "#FFFFFF", tag = "rgba(255,255,255,0.9)",
                  logo = "blanco", badge_bg = "#FFFFFF", badge_fg = "#191919",
                  circ_bg = "#FFFFFF", circ_fg = "#191919",
                  btn_bg = "#EAFF38", btn_fg = "#191919"),
  azul     = list(bg = "#405BFF", ink = "#FFFFFF", tag = "rgba(255,255,255,0.9)",
                  logo = "blanco", badge_bg = "#FFFFFF", badge_fg = "#191919",
                  circ_bg = "#FFFFFF", circ_fg = "#191919",
                  btn_bg = "#EAFF38", btn_fg = "#191919"),
  amarillo = list(bg = "#EAFF38", ink = "#191919", tag = "rgba(25,25,25,0.92)",
                  logo = "azul", badge_bg = "#405BFF", badge_fg = "#FFFFFF",
                  circ_bg = "#405BFF", circ_fg = "#FFFFFF",
                  btn_bg = "#405BFF", btn_fg = "#FFFFFF"),
  blanco   = list(bg = "#FFFFFF", ink = "#191919", tag = "rgba(25,25,25,0.85)",
                  logo = "negro", badge_bg = "#405BFF", badge_fg = "#FFFFFF",
                  circ_bg = "#405BFF", circ_fg = "#FFFFFF",
                  btn_bg = "#405BFF", btn_fg = "#FFFFFF")
)

# Tamaño de ítems (16:9) según cantidad: n=4 preserva los valores originales (v2.3.0).
TARJETA_ITEM_SIZING <- list(
  `1` = list(gap = 0,  font = 34, circle = 74, svg = 40),
  `2` = list(gap = 34, font = 31, circle = 66, svg = 36),
  `3` = list(gap = 26, font = 29, circle = 60, svg = 32),
  `4` = list(gap = 20, font = 27, circle = 54, svg = 30),
  `5` = list(gap = 16, font = 25, circle = 48, svg = 26),
  `6` = list(gap = 13, font = 23, circle = 44, svg = 24)
)
tarjeta_item_sizing <- function(n) {
  k <- max(1, min(6, if (is.null(n) || is.na(n)) 4 else n))
  TARJETA_ITEM_SIZING[[as.character(k)]]
}

TARJETA_BORDE <- 6

# Íconos Boxicons (set basic/regular, free) para los ítems de la tarjeta
TARJETA_ICON_DIR  <- "www/icons"
TARJETA_ICON_NAMES <- list.files(TARJETA_ICON_DIR, pattern = "\\.svg$")
TARJETA_ICONS <- setNames(
  lapply(TARJETA_ICON_NAMES, function(f)
    paste(readLines(file.path(TARJETA_ICON_DIR, f), warn = FALSE), collapse = "")),
  sub("\\.svg$", "", TARJETA_ICON_NAMES))
TARJETA_ICON_OPTS <- setNames(names(TARJETA_ICONS), sub("^bx-", "", names(TARJETA_ICONS)))

tarjeta_icon_svg <- function(icon, fill) {
  svg <- TARJETA_ICONS[[icon]]
  if (is.null(svg) || nchar(svg) == 0) return("")
  svg <- sub('width="24" height="24" ', "", svg, fixed = TRUE)
  svg <- sub("<svg ", paste0('<svg fill="', fill, '" '), svg, fixed = TRUE)
  svg
}

TARJETA_LOGOS <- list(
  blanco = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_blanco.png")),
  azul   = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_azul.png")),
  negro  = paste0("data:image/png;base64,", base64enc::base64encode("www/logo_er_negro.png"))
)

ISOTIPO_B64 <- paste0("data:image/svg+xml;base64,",
  base64enc::base64encode("www/isotipo_estacion_r.svg"))

# ---- Visuales para redes (tab 📊): 1:1, 4:5 y 16:9 ----
VIZ_FORMATOS_OPTS <- c("1:1 — Instagram (1080×1080)" = "1x1",
                       "4:5 — Instagram feed (1080×1350)" = "4x5",
                       "16:9 — LinkedIn / X (1920×1080)" = "16x9")

ARRAY_FONT_FACE <- paste0(
  "@font-face{font-family:'Array';src:url('data:font/woff2;base64,",
  base64enc::base64encode("www/fonts/Array-Bold.woff2"),
  "') format('woff2');font-weight:700;font-style:normal;font-display:block;}")

# Ubuntu / Ubuntu Mono embebidas en base64 (offline, sin depender de Google Fonts).
ubuntu_font_face <- function(family, weight, file) {
  paste0("@font-face{font-family:'", family, "';src:url('data:font/woff2;base64,",
    base64enc::base64encode(file.path("www/fonts", file)),
    "') format('woff2');font-weight:", weight, ";font-style:normal;font-display:block;}")
}
UBUNTU_FONT_FACES <- paste0(
  ubuntu_font_face("Ubuntu", 400, "Ubuntu-Regular.woff2"),
  ubuntu_font_face("Ubuntu", 500, "Ubuntu-Medium.woff2"),
  ubuntu_font_face("Ubuntu", 700, "Ubuntu-Bold.woff2"),
  ubuntu_font_face("Ubuntu Mono", 400, "UbuntuMono-Regular.woff2"),
  ubuntu_font_face("Ubuntu Mono", 700, "UbuntuMono-Bold.woff2")
)

TARJETA_FONTS <- paste0(UBUNTU_FONT_FACES, ARRAY_FONT_FACE)

# ---- SVG icons ----
SVG_ICON <- function(path_d, extra_path = NULL) {
  paths <- paste0('<path d="', path_d, '"/>')
  if (!is.null(extra_path)) paths <- paste0(paths, '<path d="', extra_path, '"/>')
  paste0('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" ',
         'style="width:1.5rem;height:1.5rem;fill:#447099;display:block;">',
         paths, '</svg>')
}
SVG_MOVIE_PLAY <- SVG_ICON(
  "M20 3H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm.001 6c-.001 0-.001 0 0 0h-.465l-2.667-4H20l.001 4zM9.536 9 6.869 5h2.596l2.667 4H9.536zm5 0-2.667-4h2.596l2.667 4h-2.596zM4 5h.465l2.667 4H4V5zm0 14v-8h16l.002 8H4z",
  "m10 18 5.5-3-5.5-3z")
SVG_CERTIFICATION <- SVG_ICON(
  "M2.06 14.68a1 1 0 0 0 .46.6l1.91 1.11v2.2a1 1 0 0 0 1 1h2.2l1.11 1.91a1 1 0 0 0 .86.5 1 1 0 0 0 .51-.14l1.9-1.1 1.91 1.1a1 1 0 0 0 1.37-.36l1.1-1.91h2.2a1 1 0 0 0 1-1v-2.2l1.91-1.11a1 1 0 0 0 .37-1.36L20.76 12l1.11-1.91a1 1 0 0 0-.37-1.36l-1.91-1.1v-2.2a1 1 0 0 0-1-1h-2.2l-1.1-1.91a1 1 0 0 0-.61-.46 1 1 0 0 0-.76.1L12 3.26l-1.9-1.1a1 1 0 0 0-1.36.36L7.63 4.43h-2.2a1 1 0 0 0-1 1v2.2l-1.9 1.1a1 1 0 0 0-.37 1.37l1.1 1.9-1.1 1.91a1 1 0 0 0-.1.77zm3.22-3.17L4.39 10l1.55-.9a1 1 0 0 0 .49-.86V6.43h1.78a1 1 0 0 0 .87-.5L10 4.39l1.54.89a1 1 0 0 0 1 0l1.55-.89.91 1.54a1 1 0 0 0 .87.5h1.77v1.78a1 1 0 0 0 .5.86l1.54.9-.89 1.54a1 1 0 0 0 0 1l.89 1.54-1.54.9a1 1 0 0 0-.5.86v1.78h-1.83a1 1 0 0 0-.86.5l-.89 1.54-1.55-.89a1 1 0 0 0-1 0l-1.51.89-.89-1.54a1 1 0 0 0-.87-.5H6.43v-1.78a1 1 0 0 0-.49-.81l-1.55-.9.89-1.54a1 1 0 0 0 0-1.05z")
SVG_SLACK <- SVG_ICON(
  "M20.935 12.646a1.617 1.617 0 0 0-2.022-1.034l-1.632.532c-.355-1.099-.735-2.268-1.092-3.365l.006-.002-.004-.008 1.613-.523a1.62 1.62 0 0 0 1.035-2.023 1.62 1.62 0 0 0-2.025-1.034l-1.621.527-.519-1.604a1.619 1.619 0 0 0-2.024-1.034 1.618 1.618 0 0 0-1.033 2.024l.522 1.609-3.368 1.092-.524-1.611a1.618 1.618 0 0 0-2.022-1.034 1.617 1.617 0 0 0-1.034 2.023l.524 1.616-1.662.541a1.602 1.602 0 0 0-.988 1.95c.25.856 1.152 1.373 1.979 1.092.006 0 .658-.209 1.665-.536l1.099 3.386h-.002v.002l-1.67.545a1.599 1.599 0 0 0-.987 1.949c.25.857 1.15 1.374 1.979 1.093.007 0 .659-.211 1.665-.538l.003.005a.024.024 0 0 0 .008-.002l.539 1.657a1.6 1.6 0 0 0 1.949.989c.857-.25 1.373-1.151 1.094-1.979 0-.006-.209-.654-.533-1.654l-.003-.009c1.104-.358 2.276-.739 3.376-1.098l.543 1.668a1.602 1.602 0 0 0 1.949.989c.856-.251 1.374-1.152 1.092-1.979 0-.007-.209-.659-.535-1.663l.019-.006-.003-.007 1.609-.522a1.62 1.62 0 0 0 1.035-2.024zM10.86 14.238l-1.097-3.377a.02.02 0 0 0 .005-.001v-.006c1.098-.356 2.268-.735 3.363-1.092l1.098 3.377-3.369 1.099z")

