# ---- HTML de slides para preview (iframes) ----
slide1_html <- function(nombre, categoria, tagline, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:52px;display:block;"/>')
  else ""
  tagline_div <- if (nchar(trimws(tagline)) > 0)
    paste0('<div class="tagline">', he(tagline), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#447099;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.wm{position:absolute;right:-20px;bottom:-40px;font-family:"Ubuntu Mono",monospace;font-size:340px;font-weight:700;color:rgba(255,255,255,0.07);line-height:1;pointer-events:none;user-select:none}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.mc{flex:1;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;gap:44px;position:relative;z-index:1}
.badge{display:inline-block;background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;padding:12px 30px;border:3px solid #151515;width:fit-content}
.pn{font-family:"Ubuntu Mono",monospace;font-size:110px;font-weight:700;color:#fff;line-height:1.05;letter-spacing:-0.02em}
.br{color:#EAFF38;font-size:78px}
.tagline{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.72);line-height:1.55;max-width:820px}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:30px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:21px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="wm">R</div><div class="ctr">1 / 4</div>
  <div class="mc">
    <div class="badge">', he(categoria), '</div>
    <div class="pn"><span class="br">{</span>', he(nombre), '<span class="br">}</span></div>
    ', tagline_div, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide2_html <- function(nombre, titulo, desc, bullets, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>')
  else ""
  blist <- bullets[nchar(trimws(bullets)) > 0]
  bullets_html <- if (length(blist) > 0)
    paste0('<ul class="bul">',
      paste0('<li><span class="dot">●</span><span>', he(blist), '</span></li>', collapse = ""),
      '</ul>')
  else ""
  desc_html <- if (nchar(trimws(desc)) > 0) paste0('<p class="dsc">', he(desc), '</p>') else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#fff;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#447099;padding:52px 80px 42px;position:relative}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.pl{font-family:"Ubuntu Mono",monospace;font-size:20px;color:rgba(255,255,255,0.55);letter-spacing:0.12em;text-transform:uppercase;margin-bottom:14px}
.hn{font-family:"Ubuntu Mono",monospace;font-size:56px;font-weight:700;color:#fff;letter-spacing:-0.02em}
.br{color:#EAFF38;font-size:40px}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:36px}
.stit{font-family:"Ubuntu",sans-serif;font-size:58px;font-weight:700;color:#447099;line-height:1.1;border-left:14px solid #EAFF38;padding-left:28px}
.dsc{font-family:"Ubuntu",sans-serif;font-size:28px;color:#404041;line-height:1.6}
.bul{list-style:none;display:flex;flex-direction:column;gap:22px}
.bul li{display:flex;align-items:flex-start;gap:20px;font-size:26px;color:#151515;font-family:"Ubuntu",sans-serif;line-height:1.45}
.dot{color:#EE6331;font-size:18px;margin-top:6px;flex-shrink:0}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ctr">2 / 4</div>
    <div class="pl">', he(nombre), '</div>
    <div class="hn"><span class="br">{</span>', he(nombre), '<span class="br">}</span></div>
  </div>
  <div class="bd">
    <div class="stit">', he(titulo), '</div>
    ', desc_html, bullets_html, '
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide3_html <- function(nombre, titulo, codigo, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#F5F5F5;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#151515;padding:42px 80px;display:flex;align-items:center;justify-content:space-between}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em;z-index:2}
.ht{font-family:"Ubuntu",sans-serif;font-size:42px;font-weight:700;color:#EAFF38;letter-spacing:0.08em;text-transform:uppercase}
.hp{font-family:"Ubuntu Mono",monospace;font-size:28px;color:rgba(255,255,255,0.45);letter-spacing:0.06em}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:28px;justify-content:center}
.cb{background:#fff;border:3px solid #151515;border-left:11px solid #447099;padding:42px 50px;font-family:"Ubuntu Mono",monospace;font-size:27px;color:#151515;line-height:1.7;white-space:pre-wrap;word-break:break-word}
.cb .code-comment{color:#707073}
.cb .code-fn{color:#447099;font-weight:700}
.cb .code-arg{color:#EE6331}
.cb .code-str{color:#419599}
.cn{font-family:"Ubuntu Mono",monospace;font-size:22px;color:#A0A0A2;letter-spacing:0.06em}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ht">', he(titulo), '</div>
    <div class="hp">{', he(nombre), '}</div>
  </div>
  <div class="ctr">3 / 4</div>
  <div class="bd">
    <div class="cb">', highlight_r_code(codigo), '</div>
    <div class="cn"># copiá este código en tu consola de R</div>
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

slide4_html <- function(tagline, autor, logo_b64 = LOGO_B64) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="Estación R" style="height:110px;display:block;"/>')
  else ""
  autor_div <- if (nchar(trimws(autor)) > 0)
    paste0('<div class="cred">', he(autor), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>',
    CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#EAFF38;border:6px solid #151515;box-shadow:16px 16px 0 #447099;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:52px;padding:80px}
.cta{font-family:"Ubuntu",sans-serif;font-size:58px;font-weight:700;color:#151515;text-align:center;line-height:1.2;max-width:900px}
.handles{display:flex;gap:32px;flex-wrap:wrap;justify-content:center}
.pill{background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;padding:16px 36px;letter-spacing:0.06em}
.cred{font-family:"Ubuntu Mono",monospace;font-size:21px;color:rgba(0,0,0,0.38);text-align:center;letter-spacing:0.06em}
</style></head><body>
<div class="slide">
  <div class="ctr">4 / 4</div>
  <div class="mc">
    ', logo, '
    <div class="cta">', he(tagline), '</div>
    <div class="handles">
      <div class="pill">@estacion.erre</div>
      <div class="pill">@estacion_erre</div>
    </div>
    ', autor_div, '
  </div>
</div></body></html>')
}

# Helper: envuelve el HTML de una slide en un iframe escalado a 540×540
slide_iframe <- function(html_str) {
  div(class = "slide-preview-wrap",
    tags$iframe(srcdoc = html_str, scrolling = "no")
  )
}

