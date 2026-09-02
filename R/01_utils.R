# ---- Utilidades compartidas (%||%, escape HTML, highlighter de código R) ----
`%||%` <- function(a, b) if (!is.null(a) && nchar(a) > 0) a else b

# ---- Highlighter R ----
highlight_r_code <- function(code) {
  esc <- gsub("&", "&amp;", code, fixed = TRUE)
  esc <- gsub("<", "&lt;", esc, fixed = TRUE)
  esc <- gsub(">", "&gt;", esc, fixed = TRUE)
  pat <- '"(?:[^"\\\\]|\\\\.)*"|#[^\\n]*|[A-Za-z_.][A-Za-z0-9_.]*(?=\\s*\\()|[A-Za-z_][A-Za-z0-9_.]*(?=\\s*=)'
  m_list <- gregexpr(pat, esc, perl = TRUE)
  m <- m_list[[1]]
  if (m[1] == -1) return(esc)
  full <- regmatches(esc, m_list)[[1]]
  lens <- attr(m, "match.length")
  clas <- vapply(seq_along(full), function(i) {
    txt <- full[i]
    if (substr(txt, 1, 1) == '"') return("code-str")
    if (substr(txt, 1, 1) == "#") return("code-comment")
    despues <- substring(esc, m[i] + lens[i], m[i] + lens[i] + 4)
    if (grepl("^\\s*\\(", despues)) return("code-fn")
    "code-arg"
  }, character(1))
  wrapped <- paste0('<span class="', clas, '">', full, '</span>')
  parts <- regmatches(esc, m_list, invert = TRUE)[[1]]
  paste0(parts[1], paste0(paste0(wrapped, parts[-1]), collapse = ""))
}

he <- function(x) htmltools::htmlEscape(x)
