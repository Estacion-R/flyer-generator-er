# ---- HTML de slides CURSO para preview (iframes) ----
course_slide_portada_html <- function(nombre, badge, tagline, fecha_inicio, logo_b64 = LOGO_B64, img_b64 = NULL, position = 1, total = 5, redes = character(0)) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:52px;display:block;"/>') else ""
  tagline_div <- if (nchar(trimws(tagline)) > 0)
    paste0('<div class="tl">', he(tagline), '</div>') else ""
  img_band <- if (!is.null(img_b64))
    paste0('<div class="band"><img src="', img_b64, '" alt=""/></div>') else ""
  has_img <- if (!is.null(img_b64)) " has-img" else ""
  is_last <- position == total
  tail_div <- if (!is_last) {
    '<div class="tail"><div class="swipe">👉</div></div>'
  } else if (length(redes) > 0) {
    paste0('<div class="tail"><div class="handles">', paste0(vapply(redes, social_pill_html, character(1), fg = "#EAFF38"), collapse = ""), '</div></div>')
  } else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#405BFF;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.band{width:100%;height:430px;border-bottom:6px solid #151515;overflow:hidden;flex-shrink:0}
.band img{width:100%;height:100%;object-fit:cover;display:block}
.wm{position:absolute;right:-10px;bottom:-30px;font-family:"Ubuntu",sans-serif;font-size:260px;font-weight:700;color:rgba(255,255,255,0.06);line-height:1;pointer-events:none;user-select:none}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.slide.has-img .ctr{top:480px}
.mc{flex:1;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;gap:44px;position:relative;z-index:1}
.slide.has-img .mc{padding:48px 90px;gap:32px}
.badge{display:inline-block;background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;padding:12px 30px;border:3px solid #151515;width:fit-content}
.cn{font-family:"Array",sans-serif;font-size:70px;font-weight:700;color:#fff;line-height:1.1;max-width:900px}
.slide.has-img .cn{font-size:54px}
.tl{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.72);line-height:1.55;max-width:820px}
.slide.has-img .tl{font-size:28px}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:30px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fi{font-family:"Ubuntu Mono",monospace;font-size:21px;color:#404041;letter-spacing:0.08em}
.tail{position:absolute;right:52px;bottom:132px;z-index:2}
.swipe{font-size:48px;line-height:1;filter:drop-shadow(0 2px 3px rgba(0,0,0,0.35))}
.handles{display:flex;gap:14px;flex-wrap:wrap;justify-content:flex-end;max-width:800px}
.pill{display:flex;align-items:center;gap:8px;background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:19px;font-weight:700;padding:10px 20px;letter-spacing:0.05em}
</style></head><body>
<div class="slide', has_img, '">
  <div class="wm">ER</div><div class="ctr">', position, ' / ', total, '</div>
  ', img_band, '
  <div class="mc">
    <div class="badge">', he(badge), '</div>
    <div class="cn">', he(nombre), '</div>
    ', tagline_div, '
  </div>
  ', tail_div, '
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fi">Inicio: ', he(fecha_inicio), '</div>
  </div>
</div></body></html>')
}

course_slide_bullets_html <- function(nombre, titulo_seccion, bullets, logo_b64 = LOGO_B64, position = 1, total = 5, redes = character(0)) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="ER" style="height:48px;display:block;"/>') else ""
  blist <- bullets[nchar(trimws(bullets)) > 0]
  bullets_html <- if (length(blist) > 0)
    paste0('<ul class="bul">', paste0('<li><span class="dot">●</span><span>', he(blist), '</span></li>', collapse = ""), '</ul>')
  else ""
  is_last <- position == total
  tail_div <- if (!is_last) {
    '<div class="tail"><div class="swipe">👉</div></div>'
  } else if (length(redes) > 0) {
    paste0('<div class="tail"><div class="handles">', paste0(vapply(redes, social_pill_html, character(1), fg = "#EAFF38"), collapse = ""), '</div></div>')
  } else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, '
.slide{width:1080px;height:1080px;background:#fff;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#405BFF;padding:52px 80px 42px;position:relative}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.hl{font-family:"Ubuntu Mono",monospace;font-size:20px;color:rgba(255,255,255,0.55);letter-spacing:0.12em;text-transform:uppercase;margin-bottom:14px}
.hn{font-family:"Ubuntu",sans-serif;font-size:52px;font-weight:700;color:#fff;letter-spacing:-0.02em;line-height:1.1}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:28px}
.stit{font-family:"Ubuntu",sans-serif;font-size:52px;font-weight:700;color:#405BFF;line-height:1.1;border-left:14px solid #EAFF38;padding-left:28px}
.bul{list-style:none;display:flex;flex-direction:column;gap:18px}
.bul li{display:flex;align-items:flex-start;gap:20px;font-size:26px;color:#151515;font-family:"Ubuntu",sans-serif;line-height:1.45}
.dot{color:#EE6331;font-size:18px;margin-top:6px;flex-shrink:0}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:"Ubuntu Mono",monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
.tail{position:absolute;right:52px;bottom:120px;z-index:2}
.swipe{font-size:48px;line-height:1;filter:drop-shadow(0 2px 3px rgba(0,0,0,0.25))}
.handles{display:flex;gap:14px;flex-wrap:wrap;justify-content:flex-end;max-width:800px}
.pill{display:flex;align-items:center;gap:8px;background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:19px;font-weight:700;padding:10px 20px;letter-spacing:0.05em}
</style></head><body>
<div class="slide">
  <div class="hdr">
    <div class="ctr">', position, ' / ', total, '</div>
    <div class="hl">Estación R</div>
    <div class="hn">', he(nombre), '</div>
  </div>
  <div class="bd">
    <div class="stit">', he(titulo_seccion), '</div>
    ', bullets_html, '
  </div>
  ', tail_div, '
  <div class="foot">
    <div class="fb">Estación R</div>', logo, '<div class="fu">estacion-r.com</div>
  </div>
</div></body></html>')
}

course_slide_cta_html <- function(cta, redes = character(0), logo_b64 = LOGO_B64, position = 1, total = 5) {
  logo <- if (nchar(logo_b64) > 10)
    paste0('<img src="', logo_b64, '" alt="Estación R" style="height:110px;display:block;"/>') else ""
  is_last <- position == total
  swipe_div <- if (!is_last) '<div class="swipe">👉</div>' else ""
  handles_div <- if (is_last && length(redes) > 0)
    paste0('<div class="handles">', paste0(vapply(redes, social_pill_html, character(1), fg = "#EAFF38"), collapse = ""), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#EAFF38;border:6px solid #151515;box-shadow:16px 16px 0 #405BFF;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:44px;padding:80px}
.cta{font-family:"Array",sans-serif;font-size:64px;font-weight:700;color:#151515;text-align:center;line-height:1.2;max-width:900px;text-transform:uppercase}
.bio{font-family:"Ubuntu",sans-serif;font-size:34px;color:#151515;background:#fff;border:3px solid #151515;padding:18px 44px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center}
.pill{display:flex;align-items:center;gap:10px;background:#151515;color:#EAFF38;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
.swipe{position:absolute;right:52px;bottom:44px;font-size:48px;line-height:1;filter:drop-shadow(0 2px 3px rgba(0,0,0,0.25))}
</style></head><body>
<div class="slide">
  <div class="ctr">', position, ' / ', total, '</div>
  <div class="mc">
    ', logo, '
    <div class="cta">', he(cta), '</div>
    <div class="bio">🔗 Link en bio</div>
    ', handles_div, '
  </div>
  ', swipe_div, '
</div></body></html>')
}

course_slide_contacto_html <- function(instr, palabra, refuerzo, redes = character(0), position = 1, total = 5) {
  instr_div <- if (nchar(trimws(instr)) > 0)
    paste0('<div class="in">', he(instr), '</div>') else ""
  refuerzo_div <- if (nchar(trimws(refuerzo)) > 0)
    paste0('<div class="rf">', he(refuerzo), '</div>') else ""
  is_last <- position == total
  swipe_div <- if (!is_last) '<div class="swipe">👉</div>' else ""
  handles_div <- if (is_last && length(redes) > 0)
    paste0('<div class="handles">', paste0(vapply(redes, social_pill_html, character(1), fg = "#151515"), collapse = ""), '</div>')
  else ""
  paste0('<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><style>', CAROUSEL_BASE_CSS, ARRAY_FONT_FACE, '
.slide{width:1080px;height:1080px;background:#151515;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:"Ubuntu Mono",monospace;font-size:24px;color:rgba(255,255,255,0.22);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:28px;padding:80px;text-align:center}
.in{font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;color:#EAFF38;letter-spacing:0.14em;text-transform:uppercase}
.pw{font-family:"Array",sans-serif;font-weight:700;font-size:160px;color:#fff;line-height:1;text-transform:uppercase}
.rf{font-family:"Ubuntu",sans-serif;font-size:32px;color:rgba(255,255,255,0.82);line-height:1.4;max-width:780px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center;margin-top:12px}
.pill{display:flex;align-items:center;gap:10px;background:#EAFF38;color:#151515;font-family:"Ubuntu Mono",monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
.swipe{position:absolute;right:52px;bottom:44px;font-size:48px;line-height:1;filter:drop-shadow(0 2px 3px rgba(0,0,0,0.25))}
</style></head><body>
<div class="slide">
  <div class="ctr">', position, ' / ', total, '</div>
  <div class="mc">
    ', instr_div, '
    <div class="pw">', he(palabra), '</div>
    ', refuerzo_div, '
    ', handles_div, '
  </div>
  ', swipe_div, '
</div></body></html>')
}

# Arma el HTML de una placa del carrusel de curso según su tipo y su posición
# en el plan (para el contador "N / total", el 👉 y las píldoras de redes).
course_slide_dispatch <- function(tipo, d, position, total, img_b64 = NULL) {
  switch(tipo,
    portada  = course_slide_portada_html(d$nombre, d$badge, d$tagline, d$fecha_inicio,
      img_b64 = img_b64, position = position, total = total, redes = d$redes),
    aprender = course_slide_bullets_html(d$nombre, CURSO_SLIDE_LABELS[["aprender"]], d$s2_bullets,
      position = position, total = total, redes = d$redes),
    llevas   = course_slide_bullets_html(d$nombre, CURSO_SLIDE_LABELS[["llevas"]], d$llevas_bullets,
      position = position, total = total, redes = d$redes),
    cta      = course_slide_cta_html(d$cta, redes = d$redes, position = position, total = total),
    contacto = course_slide_contacto_html(d$s4_instr, d$s4_palabra, d$s4_refuerzo,
      redes = d$redes, position = position, total = total),
    NULL
  )
}

