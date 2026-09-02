# ---- Worker persistente de generate_flyer.js para el preview en vivo ----
# Etapa 3 del plan de mejoras: evita spawnear un proceso `node` por tecla.
# Un solo proceso `node worker.js` por sesión de Shiny expone los builders de
# HTML de generate_flyer.js por HTTP local (127.0.0.1, puerto efímero) -- así
# el preview reactivo a cada tecla usa la misma fuente de verdad que los
# downloads en vez de los builders R espejados que causaron los bugs de la
# Etapa 1 (azul off-brand, handles rotos).
#
# Si el worker no arranca o deja de responder, flyer_worker_render() devuelve
# NULL: el llamador (server, ver app.R) decide el fallback -- mantener el
# último HTML bueno en cache en vez de mostrar un preview en blanco.

FLYER_WORKER_SCRIPT       <- "worker.js"
FLYER_WORKER_START_TIMEOUT_S   <- 5
FLYER_WORKER_REQUEST_TIMEOUT_S <- 2

# Arranca el worker y espera a que imprima "PORT:<n>" por stdout (una sola
# línea). Devuelve list(proc=<processx::process>, port=<int>) o NULL si no
# pudo arrancar a tiempo (el proceso, si llegó a crearse, se mata).
flyer_worker_start <- function() {
  proc <- tryCatch(
    processx::process$new(NODE_BIN, FLYER_WORKER_SCRIPT, stdout = "|", stderr = "|"),
    error = function(e) NULL
  )
  if (is.null(proc)) return(NULL)

  port <- NULL
  deadline <- Sys.time() + FLYER_WORKER_START_TIMEOUT_S
  while (is.null(port) && Sys.time() < deadline) {
    if (!proc$is_alive()) break
    linea <- grep("^PORT:", proc$read_output_lines(), value = TRUE)
    if (length(linea) > 0) port <- suppressWarnings(as.integer(sub("^PORT:", "", linea[1])))
    if (is.null(port)) Sys.sleep(0.05)
  }

  if (is.null(port) || is.na(port)) {
    try(proc$kill(), silent = TRUE)
    return(NULL)
  }
  list(proc = proc, port = port)
}

flyer_worker_alive <- function(worker) {
  !is.null(worker) &&
    isTRUE(tryCatch(worker$proc$is_alive(), error = function(e) FALSE))
}

# Pide HTML al worker. Devuelve el string HTML, o NULL si el worker no está
# vivo, no respondió a tiempo, o devolvió un error -- nunca lanza un error
# hacia el reactivo que lo llama (el fallback es responsabilidad de quien
# llama, ver viz_render_fmt() en app.R). tipo/position/total son solo para
# el template "course_slide" (carrusel de curso, placas de tipo variable).
flyer_worker_render <- function(worker, template, config, formato = NULL,
                                 tipo = NULL, position = NULL, total = NULL) {
  if (!flyer_worker_alive(worker)) return(NULL)

  payload <- list(template = template, config = config)
  if (!is.null(formato))  payload$formato  <- formato
  if (!is.null(tipo))     payload$tipo     <- tipo
  if (!is.null(position)) payload$position <- position
  if (!is.null(total))    payload$total    <- total

  resp <- tryCatch(
    httr::POST(
      url = paste0("http://127.0.0.1:", worker$port, "/render"),
      body = jsonlite::toJSON(payload, auto_unbox = TRUE, null = "null"),
      httr::content_type_json(),
      httr::timeout(FLYER_WORKER_REQUEST_TIMEOUT_S)
    ),
    error = function(e) NULL
  )
  if (is.null(resp) || httr::status_code(resp) != 200) return(NULL)

  parsed <- tryCatch(
    jsonlite::fromJSON(httr::content(resp, "text", encoding = "UTF-8")),
    error = function(e) NULL
  )
  if (is.null(parsed) || !isTRUE(parsed$ok)) return(NULL)
  parsed$html
}
