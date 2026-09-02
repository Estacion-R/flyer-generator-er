#!/usr/bin/env node
/**
 * Generador de Flyers — Estación R (versión local con Playwright)
 *
 * Uso:
 *   node generate_flyer.js --config config.json --output flyer.png
 *   node generate_flyer.js --config config.json  (carousel: genera slides en config.output_dir)
 *
 * config.json (template "curso"):
 * {
 *   "template": "curso",
 *   "formato": "linkedin|story",
 *   "imagen_curso": "/ruta/imagen.png",
 *   "badge_texto": "Curso virtual",
 *   "badge_color": "Azul ER",
 *   "titulo": "...", "subtitulo": "...",
 *   "bullets": ["Item 1", ...],
 *   "col1_texto": "...", "col2_texto": "...", "col3_texto": "...",
 *   "footer_texto": "...", "footer_icon": "📣"
 * }
 *
 * config.json (template "tip"):
 * {
 *   "template": "tip",
 *   "categoria": "Paquete de R",
 *   "pkg_nombre": "janitor",
 *   "version_line": "v2.2.0 · CRAN · Sam Firke",
 *   "descripcion": "...",
 *   "codigo": "datos <- datos |>\n  clean_names()",
 *   "autor_line": "📦 janitor · GitHub: sfirke/janitor"
 * }
 *
 * config.json (template "carousel" — paquete de R, 4 slides 1080×1080, ZIP desde R):
 * {
 *   "template": "carousel",
 *   "output_dir": "/tmp/carousel_xxx/",
 *   "pkg_nombre": "janitor",
 *   "categoria": "Paquete de R",
 *   "version_line": "v2.2.0 · CRAN · Sam Firke",
 *   "autor_line": "📦 janitor · GitHub: sfirke/janitor",
 *   "slide1_tagline": "Limpieza de datos en R, sin esfuerzo",
 *   "slide2_titulo": "¿Para qué sirve?",
 *   "slide2_desc": "...",
 *   "slide2_bullets": ["Bullet 1", "Bullet 2", "Bullet 3"],
 *   "slide3_titulo": "En la práctica",
 *   "slide3_codigo": "datos <- datos |>\n  clean_names()",
 *   "slide4_tagline": "Seguinos para más tips de R"
 * }
 *
 * config.json (template "carousel_curso" — anuncio de curso, 3 slides 1080×1080, ZIP desde R):
 * {
 *   "template": "carousel_curso",
 *   "output_dir": "/tmp/carousel_xxx/",
 *   "nombre": "Introducción a R para Ciencias Sociales",
 *   "badge": "Curso virtual",
 *   "tagline": "Aprendé a analizar datos con R desde cero",
 *   "fecha_inicio": "22 de septiembre",
 *   "imagen_curso": "/ruta/portada.png",
 *   "s2_bullets": ["Introducción a R y RStudio", "Manejo de datos con tidyverse"],
 *   "cta": "INSCRIPCIÓN ABIERTA"
 * }
 *
 * "imagen_curso" es opcional: banda superior (~40%) del slide 1; sin ella el slide se adapta.
 *
 * config.json (template "tarjeta_curso" — tarjeta clásica, 4:5 1080×1350 + 16:9 1920×1080):
 * {
 *   "template": "tarjeta_curso",
 *   "output_dir": "/tmp/tarjeta_xxx/",
 *   "fondo": "negro|azul|amarillo|blanco",
 *   "titulo": "R para el tratamiento de Hojas de Cálculo",
 *   "tagline": "El remedio para tus datos...",
 *   "items": [
 *     {"icon":"bx-laptop","strong":"Modalidad:","text":"Sincrónica/Asincrónica"},
 *     {"icon":"bx-chat","strong":"Foro de intercambio","text":"y seguimiento 24/7"},
 *     {"icon":"bx-calendar-check","strong":"4 semanas","text":"(10 hs. totales)"},
 *     {"icon":"bx-certification","strong":"Certificación","text":"con examen final"}
 *   ],
 *   "inscripcion_texto": "INSCRIPCIÓN ABIERTA\nMARTES 19:00 | INICIO 12 AGOSTO",
 *   "solo_45": false,
 *   "imagen_curso": "/ruta/caja.png"
 * }
 *
 * Genera tarjeta_4x5.png (+ tarjeta_16x9.png si !solo_45). "imagen_curso" opcional
 * (caja central); sin ella va el isotipo de ER sobre celeste #DFF5FF. "items" acepta
 * de 1 a 6 elementos: el tamaño de ícono/texto de la lista (16:9) se recalcula según
 * la cantidad para una distribución vertical armónica. "inscripcion_texto" es opcional
 * (vacío = sin recuadro); se renderiza igual en ambos formatos, con ícono de megáfono
 * y fondo amarillo fijo, al pie de la tarjeta (16:9: anclado a la columna de ítems;
 * 4:5: ancho completo debajo de los ítems). La etiqueta "CURSOS" aparece arriba a la
 * derecha en ambos formatos. El 16:9 también suma un borde negro.
 */

/*
 * config.json (template "viz_redes" — visuales de datos para redes, 1:1 + 4:5 + 16:9):
 *   "template": "viz_redes",
 *   "output_dir": "/tmp/viz_xxx/",
 *   "badge": "DATOS",
 *   "titulo": "La ropa bajó, los paquetes turísticos subieron",
 *   "fuente": "Fuente: INDEC · IPC julio 2026",
 *   "handles": "@estacion_r · @estacionr.bsky.social",
 *   "formatos": ["1x1", "4x5", "16x9"],
 *   "imagen": "/ruta/chart.png"
 * "imagen" es opcional. Título/fuente/handles vacíos se omiten del diseño.
 * Genera viz_1x1.png + viz_4x5.png + viz_16x9.png en output_dir.
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// ---- Colores ER ----
const BADGE_COLORES = {
  'Azul ER': '#447099',
  'Naranja ER': '#EE6331',
  'Teal ER': '#419599',
  'Negro': '#151515'
};

const FORMATOS = {
  linkedin: { w: 540, h: null },
  story: { w: 380, h: 675 }
};

// ---- SVG icons ----
const SVG_ICONS = {
  movie_play: '<path d="M20 3H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm.001 6c-.001 0-.001 0 0 0h-.465l-2.667-4H20l.001 4zM9.536 9 6.869 5h2.596l2.667 4H9.536zm5 0-2.667-4h2.596l2.667 4h-2.596zM4 5h.465l2.667 4H4V5zm0 14v-8h16l.002 8H4z"/><path d="m10 18 5.5-3-5.5-3z"/>',
  certification: '<path d="M2.06 14.68a1 1 0 0 0 .46.6l1.91 1.11v2.2a1 1 0 0 0 1 1h2.2l1.11 1.91a1 1 0 0 0 .86.5 1 1 0 0 0 .51-.14l1.9-1.1 1.91 1.1a1 1 0 0 0 1.37-.36l1.1-1.91h2.2a1 1 0 0 0 1-1v-2.2l1.91-1.11a1 1 0 0 0 .37-1.36L20.76 12l1.11-1.91a1 1 0 0 0-.37-1.36l-1.91-1.1v-2.2a1 1 0 0 0-1-1h-2.2l-1.1-1.91a1 1 0 0 0-.61-.46 1 1 0 0 0-.76.1L12 3.26l-1.9-1.1a1 1 0 0 0-1.36.36L7.63 4.43h-2.2a1 1 0 0 0-1 1v2.2l-1.9 1.1a1 1 0 0 0-.37 1.37l1.1 1.9-1.1 1.91a1 1 0 0 0-.1.77zm3.22-3.17L4.39 10l1.55-.9a1 1 0 0 0 .49-.86V6.43h1.78a1 1 0 0 0 .87-.5L10 4.39l1.54.89a1 1 0 0 0 1 0l1.55-.89.91 1.54a1 1 0 0 0 .87.5h1.77v1.78a1 1 0 0 0 .5.86l1.54.9-.89 1.54a1 1 0 0 0 0 1l.89 1.54-1.54.9a1 1 0 0 0-.5.86v1.78h-1.83a1 1 0 0 0-.86.5l-.89 1.54-1.55-.89a1 1 0 0 0-1 0l-1.51.89-.89-1.54a1 1 0 0 0-.87-.5H6.43v-1.78a1 1 0 0 0-.49-.81l-1.55-.9.89-1.54a1 1 0 0 0 0-1.05z"/>',
  slack: '<path d="M20.935 12.646a1.617 1.617 0 0 0-2.022-1.034l-1.632.532c-.355-1.099-.735-2.268-1.092-3.365l.006-.002-.004-.008 1.613-.523a1.62 1.62 0 0 0 1.035-2.023 1.62 1.62 0 0 0-2.025-1.034l-1.621.527-.519-1.604a1.619 1.619 0 0 0-2.024-1.034 1.618 1.618 0 0 0-1.033 2.024l.522 1.609-3.368 1.092-.524-1.611a1.618 1.618 0 0 0-2.022-1.034 1.617 1.617 0 0 0-1.034 2.023l.524 1.616-1.662.541a1.602 1.602 0 0 0-.988 1.95c.25.856 1.152 1.373 1.979 1.092.006 0 .658-.209 1.665-.536l1.099 3.386h-.002v.002l-1.67.545a1.599 1.599 0 0 0-.987 1.949c.25.857 1.15 1.374 1.979 1.093.007 0 .659-.211 1.665-.538l.003.005a.024.024 0 0 0 .008-.002l.539 1.657a1.6 1.6 0 0 0 1.949.989c.857-.25 1.373-1.151 1.094-1.979 0-.006-.209-.654-.533-1.654l-.003-.009c1.104-.358 2.276-.739 3.376-1.098l.543 1.668a1.602 1.602 0 0 0 1.949.989c.856-.251 1.374-1.152 1.092-1.979 0-.007-.209-.659-.535-1.663l.019-.006-.003-.007 1.609-.522a1.62 1.62 0 0 0 1.035-2.024zM10.86 14.238l-1.097-3.377a.02.02 0 0 0 .005-.001v-.006c1.098-.356 2.268-.735 3.363-1.092l1.098 3.377-3.369 1.099z"/>'
};

function svgIcon(pathContent, color = '#447099') {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" style="width:1.5rem;height:1.5rem;fill:${color};display:block;">${pathContent}</svg>`;
}

// ---- Helpers ----
function escapeHtml(s) {
  return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function highlightR(code) {
  const esc = escapeHtml(code);
  return esc.replace(
    /("(?:[^"\\]|\\.)*")|(#[^\n]*)|([A-Za-z_.][A-Za-z0-9_.]*(?=\s*\())|([A-Za-z_][A-Za-z0-9_.]*(?=\s*=))/g,
    (m, str, com, fn, arg) => {
      if (str) return `<span class="code-str">${str}</span>`;
      if (com) return `<span class="code-comment">${com}</span>`;
      if (fn)  return `<span class="code-fn">${fn}</span>`;
      if (arg) return `<span class="code-arg">${arg}</span>`;
      return m;
    }
  );
}

// ---- CSS flyer (LinkedIn/Story) ----
const CSS = `
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; display: flex; justify-content: center; align-items: flex-start; padding: 2rem; }

.flyer {
  width: {{WIDTH}}px;
  {{HEIGHT}}
  background: #FFFFFF;
  border: 2.5px solid #151515;
  box-shadow: 8px 8px 0 #EAFF38;
  padding: 2.5rem 2.8rem 2rem 2.8rem;
  font-family: 'Ubuntu', sans-serif;
  display: flex;
  flex-direction: column;
  gap: 1.4rem;
  position: relative;
}

.flyer-course-image {
  width: calc(100% + 5.6rem);
  margin: -2.5rem -2.8rem 0 -2.8rem;
  height: 180px;
  object-fit: cover;
  display: block;
  border-bottom: 2.5px solid #151515;
}

.flyer-badge {
  display: inline-block;
  background: {{BADGE_BG}};
  color: {{BADGE_FG}};
  border: 2px solid #151515;
  padding: 0.22rem 0.85rem;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-family: 'Ubuntu', sans-serif;
  width: fit-content;
}

.flyer-title {
  font-size: 2.2rem;
  font-weight: 700;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
  line-height: 1.15;
  letter-spacing: -0.01em;
  margin: 0;
}

.flyer-subtitle { font-size: 0.95rem; color: #404041; margin: 0; line-height: 1.5; }

.flyer-bullets { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.5rem; }
.flyer-bullets li { display: flex; align-items: flex-start; gap: 0.6rem; font-size: 0.95rem; color: #151515; }
.flyer-bullets li::before { content: '●'; color: #EE6331; font-size: 0.7rem; margin-top: 0.3rem; flex-shrink: 0; }

.flyer-info-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; border-top: 2px solid #151515; padding-top: 1rem; margin-top: auto; }
.flyer-info-col { display: flex; flex-direction: column; gap: 0.25rem; }
.flyer-info-icon { font-size: 1.4rem; color: #447099; margin-bottom: 0.2rem; line-height: 1; }
.flyer-info-label { font-size: 0.68rem; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #151515; font-family: 'Ubuntu', sans-serif; }
.flyer-info-text { font-size: 0.82rem; color: #404041; line-height: 1.4; }

.flyer-footer-highlight { background: #EAFF38; border: 2px solid #151515; padding: 0.75rem 1rem; display: flex; align-items: center; gap: 0.8rem; }
.flyer-footer-highlight .footer-icon { font-size: 1.5rem; flex-shrink: 0; }
.flyer-footer-text { font-size: 0.88rem; font-weight: 700; color: #151515; font-family: 'Ubuntu', sans-serif; text-transform: uppercase; letter-spacing: 0.04em; line-height: 1.4; }

.flyer-brand { text-align: center; font-size: 0.75rem; color: #707073; font-family: 'Ubuntu', sans-serif; letter-spacing: 0.08em; border-top: 1.5px solid #C2C2C4; padding-top: 0.75rem; }
.flyer-brand img { height: 28px; display: block; margin: 0 auto 0.3rem; }
`;

// ---- CSS tip ----
const CSS_TIP = `
@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');

* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; display: flex; justify-content: center; align-items: flex-start; padding: 2rem; }

.tip-card { width: 540px; border: 3px solid #151515; box-shadow: 10px 10px 0 #EAFF38; overflow: hidden; background: #FFFFFF; font-family: 'Ubuntu', sans-serif; }

.tip-header { background: #447099; padding: 2.2rem 2.5rem 2rem 2.5rem; position: relative; display: flex; flex-direction: column; gap: 1rem; }
.tip-header::after { content: 'R'; position: absolute; right: -0.5rem; bottom: -1.2rem; font-family: 'Ubuntu Mono', monospace; font-size: 8rem; font-weight: 700; color: rgba(255,255,255,0.08); line-height: 1; pointer-events: none; user-select: none; }

.tip-badge { display: inline-block; background: #EAFF38; color: #151515; font-family: 'Ubuntu Mono', monospace; font-size: 0.7rem; font-weight: 700; letter-spacing: 0.1em; text-transform: uppercase; padding: 0.2rem 0.7rem; border: 2px solid #151515; width: fit-content; }

.tip-nombre { font-family: 'Ubuntu Mono', monospace; font-size: 3rem; font-weight: 700; color: #FFFFFF; line-height: 1.1; letter-spacing: -0.02em; position: relative; }
.tip-nombre .brace { color: #EAFF38; font-size: 2.2rem; }
.tip-version { font-family: 'Ubuntu Mono', monospace; font-size: 0.75rem; color: rgba(255,255,255,0.55); letter-spacing: 0.08em; }

.tip-body { padding: 1.8rem 2.5rem 1.5rem 2.5rem; display: flex; flex-direction: column; gap: 1.4rem; }
.tip-desc { font-size: 0.95rem; color: #404041; line-height: 1.6; }

.tip-code { background: #F5F5F5; border: 2px solid #151515; border-left: 5px solid #447099; padding: 0.9rem 1rem; font-family: 'Ubuntu Mono', monospace; font-size: 0.82rem; color: #151515; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
.tip-code .code-comment { color: #707073; }
.tip-code .code-fn { color: #447099; font-weight: 700; }
.tip-code .code-arg { color: #EE6331; }
.tip-code .code-str { color: #419599; }

.tip-autor { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8rem; color: #707073; font-family: 'Ubuntu Mono', monospace; }
.tip-autor strong { color: #151515; }

.tip-footer { background: #EAFF38; border-top: 2px solid #151515; padding: 0.65rem 2.5rem; display: flex; align-items: center; justify-content: space-between; }
.tip-footer .brand { font-family: 'Ubuntu Mono', monospace; font-size: 0.72rem; font-weight: 700; color: #151515; letter-spacing: 0.1em; text-transform: uppercase; }
.tip-footer .url { font-family: 'Ubuntu Mono', monospace; font-size: 0.68rem; color: #404041; letter-spacing: 0.06em; }
`;

// ---- CSS carrusel base (compartido entre slides, 1080×1080) ----
const CSS_CAROUSEL_FONTS = `@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; display: flex; justify-content: center; align-items: center; padding: 0; margin: 0; min-height: 100vh; }`;

// ---- Build HTML flyer ----
function buildHTML(config, logoB64) {
  const formato = FORMATOS[config.formato] || FORMATOS.linkedin;
  const badgeHex = BADGE_COLORES[config.badge_color] || BADGE_COLORES['Azul ER'];
  const badgeFG = badgeHex === '#151515' ? '#EAFF38' : '#FFFFFF';

  let css = CSS
    .replace('{{WIDTH}}', formato.w)
    .replace('{{HEIGHT}}', formato.h ? `height: ${formato.h}px; min-height: ${formato.h}px;` : '')
    .replace('{{BADGE_BG}}', badgeHex)
    .replace('{{BADGE_FG}}', badgeFG);

  let imgTag = '';
  if (config.imagen_curso) {
    const imgData = fs.readFileSync(config.imagen_curso);
    const ext = path.extname(config.imagen_curso).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
    imgTag = `<img src="data:${mime};base64,${imgData.toString('base64')}" class="flyer-course-image" alt=""/>`;
  }

  const bulletsHTML = (config.bullets || []).map(b => `<li>${b}</li>`).join('');
  const footerHTML = (config.footer_texto || '').replace(/\n/g, '<br>');
  const logoTag = logoB64 ? `<img src="${logoB64}" alt="Estación R"/>` : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><style>${css}</style></head>
<body>
<div class="flyer">
  ${imgTag}
  <div class="flyer-badge">${config.badge_texto || 'Curso virtual'}</div>
  <h1 class="flyer-title">${config.titulo || ''}</h1>
  <p class="flyer-subtitle">${config.subtitulo || ''}</p>
  <ul class="flyer-bullets">${bulletsHTML}</ul>
  <div class="flyer-info-grid">
    <div class="flyer-info-col">
      <div class="flyer-info-icon">${svgIcon(SVG_ICONS.movie_play)}</div>
      <div class="flyer-info-label">ACCESO DE POR VIDA</div>
      <div class="flyer-info-text">${config.col1_texto || ''}</div>
    </div>
    <div class="flyer-info-col">
      <div class="flyer-info-icon">${svgIcon(SVG_ICONS.certification)}</div>
      <div class="flyer-info-label">CERTIFICACIÓN</div>
      <div class="flyer-info-text">${config.col2_texto || ''}</div>
    </div>
    <div class="flyer-info-col">
      <div class="flyer-info-icon">${svgIcon(SVG_ICONS.slack)}</div>
      <div class="flyer-info-label">ACCESO A LA COMUNIDAD</div>
      <div class="flyer-info-text">${config.col3_texto || ''}</div>
    </div>
  </div>
  <div class="flyer-footer-highlight">
    <div class="footer-icon">${config.footer_icon || '📣'}</div>
    <div class="flyer-footer-text">${footerHTML}</div>
  </div>
  <div class="flyer-brand">${logoTag}<span>estacion-r.com</span></div>
</div>
</body>
</html>`;
}

// ---- Build HTML tip ----
function buildTipHTML(config, logoB64) {
  const nombre = config.pkg_nombre || 'paquete';
  let autorHTML = escapeHtml(config.autor_line || '');
  if (nombre) {
    autorHTML = autorHTML.replace(new RegExp(escapeRegExp(nombre), 'g'),
      (m) => `<strong>${m}</strong>`);
  }
  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><style>${CSS_TIP}</style></head>
<body>
<div class="tip-card">
  <div class="tip-header">
    <div class="tip-badge">${escapeHtml(config.categoria || 'Paquete de R')}</div>
    <div class="tip-nombre"><span class="brace">{</span>${escapeHtml(nombre)}<span class="brace">}</span></div>
    <div class="tip-version">${escapeHtml(config.version_line || '')}</div>
  </div>
  <div class="tip-body">
    <p class="tip-desc">${escapeHtml(config.descripcion || '')}</p>
    <div class="tip-code">${highlightR(config.codigo || '')}</div>
    <div class="tip-autor">${autorHTML}</div>
  </div>
  <div class="tip-footer">
    <span class="brand">Estación R</span>
    <span class="url">estacion-r.com</span>
  </div>
</div>
</body>
</html>`;
}

// ============================================================
// ---- Carrusel Instagram (4 slides 1080×1080) ----
// ============================================================

function buildSlide1(config, logoB64) {
  const nombre  = escapeHtml(config.pkg_nombre   || 'paquete');
  const categ   = escapeHtml(config.categoria    || 'Paquete de R');
  const tagline = escapeHtml(config.slide1_tagline || '');
  const logo    = logoB64 ? `<img src="${logoB64}" alt="ER" style="height:52px;display:block;"/>` : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
.slide {
  width: 1080px; height: 1080px;
  background: #447099;
  border: 6px solid #151515;
  box-shadow: 16px 16px 0 #EAFF38;
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.watermark {
  position: absolute;
  right: -20px; bottom: -40px;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 340px; font-weight: 700;
  color: rgba(255,255,255,0.07);
  line-height: 1; pointer-events: none; user-select: none;
}
.counter {
  position: absolute; top: 44px; right: 52px;
  font-family: 'Ubuntu Mono', monospace; font-size: 24px;
  color: rgba(255,255,255,0.28); letter-spacing: 0.15em;
}
.main-content {
  flex: 1; display: flex; flex-direction: column;
  justify-content: center; padding: 80px 90px;
  gap: 44px; position: relative; z-index: 1;
}
.badge {
  display: inline-block;
  background: #EAFF38; color: #151515;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 24px; font-weight: 700;
  letter-spacing: 0.12em; text-transform: uppercase;
  padding: 12px 30px; border: 3px solid #151515;
  width: fit-content;
}
.pkg-nombre {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 110px; font-weight: 700;
  color: #FFFFFF; line-height: 1.05; letter-spacing: -0.02em;
}
.pkg-nombre .brace { color: #EAFF38; font-size: 78px; }
.tagline {
  font-family: 'Ubuntu', sans-serif;
  font-size: 32px; color: rgba(255,255,255,0.72);
  line-height: 1.55; max-width: 820px;
}
.footer-strip {
  background: #EAFF38; border-top: 5px solid #151515;
  padding: 30px 52px;
  display: flex; align-items: center; justify-content: space-between;
}
.footer-brand {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 26px; font-weight: 700;
  color: #151515; letter-spacing: 0.12em; text-transform: uppercase;
}
.footer-url {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 21px; color: #404041; letter-spacing: 0.08em;
}
</style>
</head>
<body>
<div class="slide">
  <div class="watermark">R</div>
  <div class="counter">1 / 4</div>
  <div class="main-content">
    <div class="badge">${categ}</div>
    <div class="pkg-nombre"><span class="brace">{</span>${nombre}<span class="brace">}</span></div>
    ${tagline ? `<div class="tagline">${tagline}</div>` : ''}
  </div>
  <div class="footer-strip">
    <div class="footer-brand">Estación R</div>
    ${logo}
    <div class="footer-url">estacion-r.com</div>
  </div>
</div>
</body>
</html>`;
}

function buildSlide2(config, logoB64) {
  const nombre   = escapeHtml(config.pkg_nombre   || 'paquete');
  const titulo   = escapeHtml(config.slide2_titulo || '¿Para qué sirve?');
  const desc     = escapeHtml(config.slide2_desc   || '');
  const bullets  = (config.slide2_bullets || []).filter(b => String(b).trim());
  const logoTag  = logoB64 ? `<img src="${logoB64}" alt="ER" style="height:48px;display:block;"/>` : '';

  const bulletsHTML = bullets
    .map(b => `<li><span class="dot">●</span><span>${escapeHtml(b)}</span></li>`)
    .join('');

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
.slide {
  width: 1080px; height: 1080px;
  background: #FFFFFF;
  border: 6px solid #151515;
  box-shadow: 16px 16px 0 #EAFF38;
  position: relative;
  display: flex; flex-direction: column; overflow: hidden;
}
.header {
  background: #447099; padding: 52px 80px 42px;
  position: relative;
}
.counter {
  position: absolute; top: 44px; right: 52px;
  font-family: 'Ubuntu Mono', monospace; font-size: 24px;
  color: rgba(255,255,255,0.28); letter-spacing: 0.15em;
}
.pkg-label {
  font-family: 'Ubuntu Mono', monospace; font-size: 20px;
  color: rgba(255,255,255,0.55); letter-spacing: 0.12em;
  text-transform: uppercase; margin-bottom: 14px;
}
.header-name {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 56px; font-weight: 700;
  color: #FFFFFF; letter-spacing: -0.02em;
}
.header-name .brace { color: #EAFF38; font-size: 40px; }
.body {
  flex: 1; padding: 56px 80px;
  display: flex; flex-direction: column; gap: 36px;
}
.section-title {
  font-family: 'Ubuntu', sans-serif;
  font-size: 58px; font-weight: 700;
  color: #447099; line-height: 1.1;
  border-left: 14px solid #EAFF38; padding-left: 28px;
}
.desc {
  font-family: 'Ubuntu', sans-serif;
  font-size: 28px; color: #404041; line-height: 1.6;
}
.bullets { list-style: none; display: flex; flex-direction: column; gap: 22px; }
.bullets li {
  display: flex; align-items: flex-start; gap: 20px;
  font-size: 26px; color: #151515;
  font-family: 'Ubuntu', sans-serif; line-height: 1.45;
}
.dot { color: #EE6331; font-size: 18px; margin-top: 6px; flex-shrink: 0; }
.footer-strip {
  background: #EAFF38; border-top: 5px solid #151515;
  padding: 28px 52px;
  display: flex; align-items: center; justify-content: space-between;
}
.footer-brand {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 24px; font-weight: 700;
  color: #151515; letter-spacing: 0.12em; text-transform: uppercase;
}
.footer-url {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 20px; color: #404041; letter-spacing: 0.08em;
}
</style>
</head>
<body>
<div class="slide">
  <div class="header">
    <div class="counter">2 / 4</div>
    <div class="pkg-label">${nombre}</div>
    <div class="header-name"><span class="brace">{</span>${nombre}<span class="brace">}</span></div>
  </div>
  <div class="body">
    <div class="section-title">${titulo}</div>
    ${desc ? `<p class="desc">${desc}</p>` : ''}
    ${bulletsHTML ? `<ul class="bullets">${bulletsHTML}</ul>` : ''}
  </div>
  <div class="footer-strip">
    <div class="footer-brand">Estación R</div>
    ${logoTag}
    <div class="footer-url">estacion-r.com</div>
  </div>
</div>
</body>
</html>`;
}

function buildSlide3(config, logoB64) {
  const nombre  = escapeHtml(config.pkg_nombre   || 'paquete');
  const titulo  = escapeHtml(config.slide3_titulo || 'En la práctica');
  const codigo  = config.slide3_codigo || '';
  const logoTag = logoB64 ? `<img src="${logoB64}" alt="ER" style="height:48px;display:block;"/>` : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
.slide {
  width: 1080px; height: 1080px;
  background: #F5F5F5;
  border: 6px solid #151515;
  box-shadow: 16px 16px 0 #EAFF38;
  position: relative;
  display: flex; flex-direction: column; overflow: hidden;
}
.header {
  background: #151515; padding: 42px 80px;
  display: flex; align-items: center; justify-content: space-between;
}
.counter {
  position: absolute; top: 44px; right: 52px;
  font-family: 'Ubuntu Mono', monospace; font-size: 24px;
  color: rgba(0,0,0,0.18); letter-spacing: 0.15em;
  z-index: 2;
}
.header-title {
  font-family: 'Ubuntu', sans-serif;
  font-size: 42px; font-weight: 700;
  color: #EAFF38; letter-spacing: 0.08em; text-transform: uppercase;
}
.header-pkg {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 28px; color: rgba(255,255,255,0.45); letter-spacing: 0.06em;
}
.body {
  flex: 1; padding: 56px 80px;
  display: flex; flex-direction: column;
  gap: 28px; justify-content: center;
}
.code-block {
  background: #FFFFFF;
  border: 3px solid #151515; border-left: 11px solid #447099;
  padding: 42px 50px;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 27px; color: #151515;
  line-height: 1.7; white-space: pre-wrap; word-break: break-word;
}
.code-block .code-comment { color: #707073; }
.code-block .code-fn { color: #447099; font-weight: 700; }
.code-block .code-arg { color: #EE6331; }
.code-block .code-str { color: #419599; }
.code-note {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 22px; color: #A0A0A2; letter-spacing: 0.06em;
}
.footer-strip {
  background: #EAFF38; border-top: 5px solid #151515;
  padding: 28px 52px;
  display: flex; align-items: center; justify-content: space-between;
}
.footer-brand {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 24px; font-weight: 700;
  color: #151515; letter-spacing: 0.12em; text-transform: uppercase;
}
.footer-url {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 20px; color: #404041; letter-spacing: 0.08em;
}
</style>
</head>
<body>
<div class="slide">
  <div class="counter">3 / 4</div>
  <div class="header">
    <div class="header-title">${titulo}</div>
    <div class="header-pkg">{${nombre}}</div>
  </div>
  <div class="body">
    <div class="code-block">${highlightR(codigo)}</div>
    <div class="code-note"># copiá este código en tu consola de R</div>
  </div>
  <div class="footer-strip">
    <div class="footer-brand">Estación R</div>
    ${logoTag}
    <div class="footer-url">estacion-r.com</div>
  </div>
</div>
</body>
</html>`;
}

function buildSlide4(config, logoB64) {
  const tagline = escapeHtml(config.slide4_tagline || 'Seguinos para más tips de R');
  const autor   = escapeHtml(config.autor_line || '');
  const logoTag = logoB64 ? `<img src="${logoB64}" alt="Estación R" style="height:110px;display:block;"/>` : '';

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
.slide {
  width: 1080px; height: 1080px;
  background: #EAFF38;
  border: 6px solid #151515;
  box-shadow: 16px 16px 0 #447099;
  position: relative;
  display: flex; flex-direction: column;
  align-items: center; justify-content: center;
  overflow: hidden;
}
.counter {
  position: absolute; top: 44px; right: 52px;
  font-family: 'Ubuntu Mono', monospace; font-size: 24px;
  color: rgba(0,0,0,0.18); letter-spacing: 0.15em;
}
.main-content {
  display: flex; flex-direction: column;
  align-items: center; gap: 52px; padding: 80px;
}
.cta-title {
  font-family: 'Ubuntu', sans-serif;
  font-size: 58px; font-weight: 700;
  color: #151515; text-align: center; line-height: 1.2;
  max-width: 900px;
}
.handles { display: flex; gap: 32px; flex-wrap: wrap; justify-content: center; }
.handle-pill {
  background: #151515; color: #EAFF38;
  font-family: 'Ubuntu Mono', monospace;
  font-size: 26px; font-weight: 700;
  padding: 16px 36px; letter-spacing: 0.06em;
}
.pkg-credit {
  font-family: 'Ubuntu Mono', monospace;
  font-size: 21px; color: rgba(0,0,0,0.38);
  text-align: center; letter-spacing: 0.06em;
}
</style>
</head>
<body>
<div class="slide">
  <div class="counter">4 / 4</div>
  <div class="main-content">
    ${logoTag}
    <div class="cta-title">${tagline}</div>
    <div class="handles">
      <div class="handle-pill">@estacion_r</div>
      <div class="handle-pill">@estacionr.bsky.social</div>
    </div>
    ${autor ? `<div class="pkg-credit">${autor}</div>` : ''}
  </div>
</div>
</body>
</html>`;
}

// ============================================================
// ---- Carrusel Anuncio de Curso (3 slides 1080×1080) ----
// ============================================================

function buildCourseSlide1(config, logoB64, arrayFont, total) {
  const nombre  = escapeHtml(config.nombre || '');
  const badge   = escapeHtml(config.badge  || 'Curso virtual');
  const tagline = escapeHtml(config.tagline || '');
  const fecha   = escapeHtml(config.fecha_inicio || '');
  const logo    = logoB64 ? `<img src="${logoB64}" alt="ER" style="height:52px;display:block;"/>` : '';
  const arrayFace = `@font-face{font-family:'Array';src:url('data:font/woff2;base64,${arrayFont}') format('woff2');font-weight:700;font-style:normal;font-display:block;}`;

  let imgBand = '';
  let hasImg = '';
  if (typeof config.imagen_curso === 'string' && config.imagen_curso && fs.existsSync(config.imagen_curso)) {
    const imgData = fs.readFileSync(config.imagen_curso);
    const ext = path.extname(config.imagen_curso).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
    imgBand = `<div class="band"><img src="data:${mime};base64,${imgData.toString('base64')}" alt=""/></div>`;
    hasImg = ' has-img';
  }

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
${arrayFace}
.slide{width:1080px;height:1080px;background:#405BFF;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.band{width:100%;height:430px;border-bottom:6px solid #151515;overflow:hidden;flex-shrink:0}
.band img{width:100%;height:100%;object-fit:cover;display:block}
.wm{position:absolute;right:-10px;bottom:-30px;font-family:'Ubuntu',sans-serif;font-size:260px;font-weight:700;color:rgba(255,255,255,0.06);line-height:1;pointer-events:none;user-select:none}
.ctr{position:absolute;top:44px;right:52px;font-family:'Ubuntu Mono',monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.slide.has-img .ctr{top:480px}
.mc{flex:1;display:flex;flex-direction:column;justify-content:center;padding:80px 90px;gap:44px;position:relative;z-index:1}
.slide.has-img .mc{padding:48px 90px;gap:32px}
.badge{display:inline-block;background:#EAFF38;color:#151515;font-family:'Ubuntu Mono',monospace;font-size:24px;font-weight:700;letter-spacing:0.12em;text-transform:uppercase;padding:12px 30px;border:3px solid #151515;width:fit-content}
.cn{font-family:'Array',sans-serif;font-size:70px;font-weight:700;color:#fff;line-height:1.1;max-width:900px}
.slide.has-img .cn{font-size:54px}
.tl{font-family:'Ubuntu',sans-serif;font-size:32px;color:rgba(255,255,255,0.72);line-height:1.55;max-width:820px}
.slide.has-img .tl{font-size:28px}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:30px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fi{font-family:'Ubuntu Mono',monospace;font-size:21px;color:#404041;letter-spacing:0.08em}
</style>
</head>
<body>
<div class="slide${hasImg}">
  <div class="wm">ER</div>
  <div class="ctr">1 / ${total}</div>
  ${imgBand}
  <div class="mc">
    <div class="badge">${badge}</div>
    <div class="cn">${nombre}</div>
    ${tagline ? `<div class="tl">${tagline}</div>` : ''}
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>${logo}<div class="fi">Inicio: ${fecha}</div>
  </div>
</div>
</body>
</html>`;
}

function buildCourseSlide2(config, logoB64, total) {
  const nombre  = escapeHtml(config.nombre || '');
  const bullets = (config.s2_bullets || []).filter(b => String(b).trim());
  const logoTag = logoB64 ? `<img src="${logoB64}" alt="ER" style="height:48px;display:block;"/>` : '';
  const bulletsHTML = bullets
    .map(b => `<li><span class="dot">●</span><span>${escapeHtml(b)}</span></li>`)
    .join('');

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
.slide{width:1080px;height:1080px;background:#FFFFFF;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;overflow:hidden}
.hdr{background:#405BFF;padding:52px 80px 42px;position:relative}
.ctr{position:absolute;top:44px;right:52px;font-family:'Ubuntu Mono',monospace;font-size:24px;color:rgba(255,255,255,0.28);letter-spacing:0.15em}
.hl{font-family:'Ubuntu Mono',monospace;font-size:20px;color:rgba(255,255,255,0.55);letter-spacing:0.12em;text-transform:uppercase;margin-bottom:14px}
.hn{font-family:'Ubuntu',sans-serif;font-size:52px;font-weight:700;color:#fff;letter-spacing:-0.02em;line-height:1.1}
.bd{flex:1;padding:56px 80px;display:flex;flex-direction:column;gap:28px}
.stit{font-family:'Ubuntu',sans-serif;font-size:52px;font-weight:700;color:#405BFF;line-height:1.1;border-left:14px solid #EAFF38;padding-left:28px}
.bul{list-style:none;display:flex;flex-direction:column;gap:18px}
.bul li{display:flex;align-items:flex-start;gap:20px;font-size:26px;color:#151515;font-family:'Ubuntu',sans-serif;line-height:1.45}
.dot{color:#EE6331;font-size:18px;margin-top:6px;flex-shrink:0}
.foot{background:#EAFF38;border-top:5px solid #151515;padding:28px 52px;display:flex;align-items:center;justify-content:space-between}
.fb{font-family:'Ubuntu Mono',monospace;font-size:24px;font-weight:700;color:#151515;letter-spacing:0.12em;text-transform:uppercase}
.fu{font-family:'Ubuntu Mono',monospace;font-size:20px;color:#404041;letter-spacing:0.08em}
</style>
</head>
<body>
<div class="slide">
  <div class="hdr">
    <div class="ctr">2 / ${total}</div>
    <div class="hl">Estación R</div>
    <div class="hn">${nombre}</div>
  </div>
  <div class="bd">
    <div class="stit">¿Qué vas a aprender?</div>
    ${bulletsHTML ? `<ul class="bul">${bulletsHTML}</ul>` : ''}
  </div>
  <div class="foot">
    <div class="fb">Estación R</div>${logoTag}<div class="fu">estacion-r.com</div>
  </div>
</div>
</body>
</html>`;
}

function buildCourseSlide3(config, logoB64, arrayFont, total) {
  const cta     = escapeHtml(config.cta || 'INSCRIPCIÓN ABIERTA');
  const logoTag = logoB64 ? `<img src="${logoB64}" alt="Estación R" style="height:110px;display:block;"/>` : '';
  const arrayFace = `@font-face{font-family:'Array';src:url('data:font/woff2;base64,${arrayFont}') format('woff2');font-weight:700;font-style:normal;font-display:block;}`;

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
${arrayFace}
.slide{width:1080px;height:1080px;background:#EAFF38;border:6px solid #151515;box-shadow:16px 16px 0 #405BFF;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:'Ubuntu Mono',monospace;font-size:24px;color:rgba(0,0,0,0.18);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:44px;padding:80px}
.cta{font-family:'Array',sans-serif;font-size:64px;font-weight:700;color:#151515;text-align:center;line-height:1.2;max-width:900px;text-transform:uppercase}
.bio{font-family:'Ubuntu',sans-serif;font-size:34px;color:#151515;background:#FFFFFF;border:3px solid #151515;padding:18px 44px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center}
.pill{background:#151515;color:#EAFF38;font-family:'Ubuntu Mono',monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
</style>
</head>
<body>
<div class="slide">
  <div class="ctr">3 / ${total}</div>
  <div class="mc">
    ${logoTag}
    <div class="cta">${cta}</div>
    <div class="bio">🔗 Link en bio</div>
    <div class="handles">
      <div class="pill">@estacion_r</div>
      <div class="pill">@estacionr.bsky.social</div>
    </div>
  </div>
</div>
</body>
</html>`;
}

function buildCourseSlide4(config, arrayFont) {
  const instr    = escapeHtml(config.s4_instr || '');
  const palabra  = escapeHtml(config.s4_palabra || 'INFO');
  const refuerzo = escapeHtml(config.s4_refuerzo || '');
  const arrayFace = `@font-face{font-family:'Array';src:url('data:font/woff2;base64,${arrayFont}') format('woff2');font-weight:700;font-style:normal;font-display:block;}`;

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${CSS_CAROUSEL_FONTS}
${arrayFace}
.slide{width:1080px;height:1080px;background:#151515;border:6px solid #151515;box-shadow:16px 16px 0 #EAFF38;position:relative;display:flex;flex-direction:column;align-items:center;justify-content:center;overflow:hidden}
.ctr{position:absolute;top:44px;right:52px;font-family:'Ubuntu Mono',monospace;font-size:24px;color:rgba(255,255,255,0.22);letter-spacing:0.15em}
.mc{display:flex;flex-direction:column;align-items:center;gap:28px;padding:80px;text-align:center}
.in{font-family:'Ubuntu Mono',monospace;font-size:24px;font-weight:700;color:#EAFF38;letter-spacing:0.14em;text-transform:uppercase}
.pw{font-family:'Array',sans-serif;font-weight:700;font-size:160px;color:#fff;line-height:1;text-transform:uppercase}
.rf{font-family:'Ubuntu',sans-serif;font-size:32px;color:rgba(255,255,255,0.82);line-height:1.4;max-width:780px}
.handles{display:flex;gap:24px;flex-wrap:wrap;justify-content:center;margin-top:12px}
.pill{background:#EAFF38;color:#151515;font-family:'Ubuntu Mono',monospace;font-size:24px;font-weight:700;padding:14px 30px;letter-spacing:0.06em}
</style>
</head>
<body>
<div class="slide">
  <div class="ctr">4 / 4</div>
  <div class="mc">
    ${instr ? `<div class="in">${instr}</div>` : ''}
    <div class="pw">${palabra}</div>
    ${refuerzo ? `<div class="rf">${refuerzo}</div>` : ''}
    <div class="handles">
      <div class="pill">@estacion_r</div>
      <div class="pill">@estacionr.bsky.social</div>
    </div>
  </div>
</div>
</body>
</html>`;
}

async function generateCarousel(config, logoB64, arrayFont) {
  const outputDir = config.output_dir;
  if (!outputDir) throw new Error('output_dir requerido para template carousel');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  let slides;
  if (config.template === 'carousel_curso') {
    const total = parseInt(config.n_slides, 10) === 4 ? 4 : 3;
    slides = [
      buildCourseSlide1(config, logoB64, arrayFont, total),
      buildCourseSlide2(config, logoB64, total),
      buildCourseSlide3(config, logoB64, arrayFont, total)
    ];
    if (total === 4) slides.push(buildCourseSlide4(config, arrayFont));
  } else {
    slides = [
      buildSlide1(config, logoB64),
      buildSlide2(config, logoB64),
      buildSlide3(config, logoB64),
      buildSlide4(config, logoB64)
    ];
  }

  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu']
  });

  try {
    for (let i = 0; i < slides.length; i++) {
      const tmpHTML = path.join(require('os').tmpdir(), `carousel_s${i+1}_${Date.now()}.html`);
      fs.writeFileSync(tmpHTML, slides[i]);

      const page = await browser.newPage();
      await page.setViewportSize({ width: 1200, height: 1200 });
      await page.goto('file://' + tmpHTML, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(500);

      const outPNG = path.join(outputDir, `slide_0${i+1}.png`);
      await page.locator('.slide').screenshot({ path: outPNG, scale: 'css', type: 'png' });
      await page.close();
      fs.unlinkSync(tmpHTML);
      console.log(`Slide ${i+1}/${slides.length}: ${outPNG}`);
    }
  } finally {
    await browser.close();
  }
}

// ============================================================
// ---- Tarjeta clásica de curso (4:5 1080×1350 + 16:9 1920×1080) ----
// ============================================================

const TARJETA_FONDOS = {
  negro:    { bg: '#191919', ink: '#FFFFFF', tag: 'rgba(255,255,255,0.9)',  logo: 'blanco', badge_bg: '#FFFFFF', badge_fg: '#191919', circ_bg: '#FFFFFF', circ_fg: '#191919', btn_bg: '#EAFF38', btn_fg: '#191919' },
  azul:     { bg: '#405BFF', ink: '#FFFFFF', tag: 'rgba(255,255,255,0.9)',  logo: 'blanco', badge_bg: '#FFFFFF', badge_fg: '#191919', circ_bg: '#FFFFFF', circ_fg: '#191919', btn_bg: '#EAFF38', btn_fg: '#191919' },
  amarillo: { bg: '#EAFF38', ink: '#191919', tag: 'rgba(25,25,25,0.92)',   logo: 'azul',   badge_bg: '#405BFF', badge_fg: '#FFFFFF', circ_bg: '#405BFF', circ_fg: '#FFFFFF', btn_bg: '#405BFF', btn_fg: '#FFFFFF' },
  blanco:   { bg: '#FFFFFF', ink: '#191919', tag: 'rgba(25,25,25,0.85)',   logo: 'negro',  badge_bg: '#405BFF', badge_fg: '#FFFFFF', circ_bg: '#405BFF', circ_fg: '#FFFFFF', btn_bg: '#405BFF', btn_fg: '#FFFFFF' }
};

// Tamaño de ítems (16:9) según cantidad: n=4 preserva los valores originales (v2.3.0).
const TARJETA_ITEM_SIZING = {
  1: { gap: 0,  font: 34, circle: 74, svg: 40 },
  2: { gap: 34, font: 31, circle: 66, svg: 36 },
  3: { gap: 26, font: 29, circle: 60, svg: 32 },
  4: { gap: 20, font: 27, circle: 54, svg: 30 },
  5: { gap: 16, font: 25, circle: 48, svg: 26 },
  6: { gap: 13, font: 23, circle: 44, svg: 24 }
};
function tarjetaItemSizing(n) {
  const k = Math.max(1, Math.min(6, n || 4));
  return TARJETA_ITEM_SIZING[k];
}

const TARJETA_BORDE = 6;

// Ícono Boxicons inline con fill según fondo (los SVG viven en www/icons/)
function tarjetaIconSvg(icon, fill, assets) {
  const svg = assets.icons && assets.icons[icon];
  if (!svg) return '';
  return String(svg)
    .replace('width="24" height="24" ', '')
    .replace('<svg ', `<svg fill="${fill}" `);
}

function buildTarjetaHTML(config, formato, assets) {
  const f = TARJETA_FONDOS[config.fondo] || TARJETA_FONDOS.negro;
  const logo = (assets.logos && assets.logos[f.logo]) || '';
  const es45 = formato === '4x5';

  const items = (config.items || []).filter(it => {
    if (!it) return false;
    return (String(it.strong || '') + String(it.text || '')).trim().length > 0;
  });
  const itemsHTML = items.map(it =>
    `<div class="it"><div class="circ">${tarjetaIconSvg(it.icon || '', f.circ_fg, assets)}</div>` +
    `<div class="tx"><strong>${escapeHtml(it.strong || '')}</strong>${escapeHtml(it.text || '')}</div></div>`
  ).join('');

  const inscTxt = String(config.inscripcion_texto || '').trim();
  const inscHTML = inscTxt
    ? `<div class="insc"><div class="ico">📣</div><div class="txt">${escapeHtml(inscTxt).replace(/\n/g, '<br>')}</div></div>`
    : '';

  let caja;
  if (typeof config.imagen_curso === 'string' && config.imagen_curso && fs.existsSync(config.imagen_curso)) {
    const imgData = fs.readFileSync(config.imagen_curso);
    const ext = path.extname(config.imagen_curso).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
    caja = `<img src="data:${mime};base64,${imgData.toString('base64')}" alt=""/>`;
  } else {
    caja = `<img class="iso" src="${assets.isotipo}" alt="ER"/>`;
  }
  const badge = `<div class="badge">CURSOS</div>`;

  const fontsCSS =
    `@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');` +
    `@font-face{font-family:'Array';src:url('data:font/woff2;base64,${assets.arrayFont}') format('woff2');font-weight:700;font-style:normal;font-display:block;}`;

  const baseCSS =
    `*{margin:0;padding:0;box-sizing:border-box}` +
    `.hd{display:flex;justify-content:space-between;align-items:center;padding:${es45 ? '56px' : '52px 64px 0'}}` +
    `.hd .lg{height:${es45 ? '58px' : '56px'};display:block}` +
    `.badge{background:${f.badge_bg};color:${f.badge_fg};font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;padding:10px 26px}` +
    `.tt{font-family:'Array',sans-serif;font-weight:700;line-height:1.05;color:${f.ink};white-space:pre-wrap}` +
    `.caja{border:5px solid #191919;background:#DFF5FF;overflow:hidden;display:flex;align-items:center;justify-content:center}` +
    `.caja img{width:100%;height:100%;object-fit:cover;display:block}` +
    `.caja img.iso{width:280px;height:auto;object-fit:contain}` +
    `.tag{font-size:31px;line-height:1.45;color:${f.tag};white-space:pre-wrap}` +
    `.it{display:flex;gap:18px;align-items:flex-start}` +
    `.circ{width:54px;height:54px;border-radius:50%;background:${f.circ_bg};display:flex;align-items:center;justify-content:center;flex-shrink:0}` +
    `.circ svg{width:30px;height:30px;display:block}` +
    `.cta-btn{display:inline-block;background:${f.btn_bg};color:${f.btn_fg};font-family:'Ubuntu',sans-serif;font-weight:700;font-size:34px;line-height:1;padding:22px 64px;border-radius:14px}` +
    `.it .tx{font-size:27px;line-height:1.32;color:${f.ink}}` +
    `.it .tx strong{display:block;font-weight:700}`;

  let layoutCSS, body;
  if (es45) {
    layoutCSS =
      `.tarjeta{width:1080px;height:1350px;background:${f.bg};font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;display:flex;flex-direction:column}` +
      `.tt{font-size:70px;padding:52px 58px 0}` +
      `.caja{margin:44px 58px 0;height:500px;flex:1 1 auto;min-height:360px}` +
      `.tag{padding:36px 58px 0}` +
      `.items{display:grid;grid-template-columns:1fr 1fr;gap:26px 24px;padding:42px 58px 0}` +
      `.insc{background:#EAFF38;border:3px solid #151515;padding:26px 34px;display:flex;align-items:center;gap:22px;margin:36px 58px 56px}` +
      `.insc .ico{font-size:36px;line-height:1;flex-shrink:0}` +
      `.insc .txt{font-size:25px;font-weight:700;color:#151515;font-family:'Ubuntu',sans-serif;text-transform:uppercase;letter-spacing:0.03em;line-height:1.3;white-space:pre-wrap}`;
    body =
      `<div class="tarjeta">` +
      `<div class="hd"><img class="lg" src="${logo}"/>${badge}</div>` +
      `<div class="tt">${escapeHtml(config.titulo || '')}</div>` +
      `<div class="caja">${caja}</div>` +
      `<div class="tag">${escapeHtml(config.tagline || '')}</div>` +
      `<div class="items">${itemsHTML}</div>` +
      inscHTML +
      `</div>`;
  } else {
    // 16:9 — grid con filas explícitas: título/tagline comparten fila 1, imagen/ítems
    // comparten fila 2 (mismo grid-row), así el primer ítem queda siempre alineado con
    // el borde superior de la imagen sin importar cuánto ocupe el título o el tagline.
    const sz = tarjetaItemSizing(items.length);
    layoutCSS =
      `.tarjeta{width:1920px;height:1080px;background:${f.bg};font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;display:flex;flex-direction:column;border:${TARJETA_BORDE}px solid #151515}` +
      `.cols{display:grid;grid-template-columns:1fr 690px;grid-template-rows:auto 1fr;column-gap:36px;padding:30px 64px 44px;flex:1 1 auto;min-height:0}` +
      `.tt{font-size:74px;grid-column:1;grid-row:1}` +
      `.tag{padding:6px 0 0;grid-column:2;grid-row:1}` +
      `.caja{margin:34px 0 0;grid-column:1;grid-row:2;min-height:0}` +
      `.items-cta{grid-column:2;grid-row:2;display:flex;flex-direction:column;min-height:0}` +
      `.items{display:flex;flex-direction:column;gap:${sz.gap}px;padding:26px 0 0}` +
      `.it .tx{font-size:${sz.font}px}` +
      `.circ{width:${sz.circle}px;height:${sz.circle}px}` +
      `.circ svg{width:${sz.svg}px;height:${sz.svg}px}` +
      `.insc{background:#EAFF38;border:3px solid #151515;padding:16px 20px;display:flex;align-items:center;gap:14px;margin-top:auto}` +
      `.insc .ico{font-size:30px;line-height:1;flex-shrink:0}` +
      `.insc .txt{font-size:21px;font-weight:700;color:#151515;font-family:'Ubuntu',sans-serif;text-transform:uppercase;letter-spacing:0.03em;line-height:1.3;white-space:pre-wrap}`;
    body =
      `<div class="tarjeta">` +
      `<div class="hd"><img class="lg" src="${logo}"/>${badge}</div>` +
      `<div class="cols">` +
      `<div class="tt">${escapeHtml(config.titulo || '')}</div>` +
      `<div class="tag">${escapeHtml(config.tagline || '')}</div>` +
      `<div class="caja">${caja}</div>` +
      `<div class="items-cta"><div class="items">${itemsHTML}</div>${inscHTML}</div>` +
      `</div></div>`;
  }

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${fontsCSS}${baseCSS}${layoutCSS}
</style>
</head>
<body>
${body}
</body>
</html>`;
}

async function generateTarjeta(config, assets) {
  const outputDir = config.output_dir;
  if (!outputDir) throw new Error('output_dir requerido para template tarjeta_curso');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  const formatos = config.solo_45 ? ['4x5'] : ['4x5', '16x9'];
  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu']
  });

  try {
    for (const fmt of formatos) {
      const html = buildTarjetaHTML(config, fmt, assets);
      const tmpHTML = path.join(require('os').tmpdir(), `tarjeta_${fmt}_${Date.now()}.html`);
      fs.writeFileSync(tmpHTML, html);

      const page = await browser.newPage();
      await page.setViewportSize(fmt === '4x5' ? { width: 1200, height: 1450 } : { width: 2000, height: 1200 });
      await page.goto('file://' + tmpHTML, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(500);

      const outPNG = path.join(outputDir, `tarjeta_${fmt}.png`);
      await page.locator('.tarjeta').screenshot({ path: outPNG, scale: 'css', type: 'png' });
      await page.close();
      fs.unlinkSync(tmpHTML);
      console.log(`Tarjeta ${fmt}: ${outPNG}`);
    }
  } finally {
    await browser.close();
  }
}

// ---- Visuales para redes (1:1, 4:5, 16:9) — espejo de viz_html en app.R ----
function buildVizHTML(config, formato, assets) {
  const es169 = formato === '16x9';
  const dims = formato === '1x1' ? { w: 1080, h: 1080 }
    : formato === '4x5' ? { w: 1080, h: 1350 } : { w: 1920, h: 1080 };
  const pad = es169 ? 64 : 58;
  const logoHd = (assets.logos && assets.logos.azul) || '';
  const logoFt = (assets.logos && assets.logos.negro) || '';

  const badgeTxt = String(config.badge || '').trim();
  const badge = badgeTxt ? `<div class="badge">${escapeHtml(badgeTxt)}</div>` : '';
  const tituloTxt = String(config.titulo || '').trim();
  const titulo = tituloTxt ? `<div class="tt">${escapeHtml(tituloTxt)}</div>` : '';

  let chart;
  if (typeof config.imagen === 'string' && config.imagen && fs.existsSync(config.imagen)) {
    const imgData = fs.readFileSync(config.imagen);
    const ext = path.extname(config.imagen).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
    chart = `<img src="data:${mime};base64,${imgData.toString('base64')}" alt=""/>`;
  } else {
    chart = `<div class="ph">Subí tu gráfico</div>`;
  }

  const fuenteTxt = String(config.fuente || '').trim();
  const handlesTxt = String(config.handles || '').trim();
  const fuente = fuenteTxt ? `<div class="src">${escapeHtml(fuenteTxt)}</div>` : '';
  const handles = handlesTxt ? `<div class="hand">${escapeHtml(handlesTxt)}</div>` : '';
  const hdLogo = logoHd ? `<img class="lg" src="${logoHd}" alt="ER"/>` : '';
  const ftLogo = logoFt ? `<img class="lgn" src="${logoFt}" alt="ER"/>` : '';

  const fontsCSS =
    `@import url('https://fonts.googleapis.com/css2?family=Ubuntu:wght@400;500;700&family=Ubuntu+Mono:wght@400;700&display=swap');` +
    `@font-face{font-family:'Array';src:url('data:font/woff2;base64,${assets.arrayFont}') format('woff2');font-weight:700;font-style:normal;font-display:block;}`;

  const css =
    `*{margin:0;padding:0;box-sizing:border-box}` +
    `.viz{width:${dims.w}px;height:${dims.h}px;background:#FFFFFF;font-family:'Ubuntu',sans-serif;overflow:hidden;position:relative;display:flex;flex-direction:column}` +
    `.hd{display:flex;justify-content:space-between;align-items:center;padding:${es169 ? '40px 64px 0' : '52px 58px 0'}}` +
    `.hd .lg{height:${es169 ? '60px' : '64px'};display:block}` +
    `.badge{background:#FFFFFF;color:#191919;border:3px solid #151515;font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;padding:10px 26px}` +
    `.tt{font-family:'Array',sans-serif;font-weight:700;line-height:1.05;color:#191919;white-space:pre-wrap;font-size:${es169 ? '96px' : '88px'};padding:34px ${pad}px 0}` +
    `.chart{flex:1 1 auto;min-height:0;display:flex;align-items:center;justify-content:center;padding:40px ${pad}px}` +
    `.chart img{max-width:100%;max-height:100%;width:auto;height:auto;object-fit:contain;display:block}` +
    `.ph{border:4px dashed #C2C2C4;padding:60px;font-family:'Ubuntu Mono',monospace;font-size:30px;color:#707073}` +
    `.ft{background:#EAFF38;border-top:5px solid #151515;display:flex;justify-content:space-between;align-items:center;gap:36px;padding:${es169 ? '30px' : '36px'}px ${pad}px}` +
    `.src{font-family:'Ubuntu Mono',monospace;font-size:26px;font-weight:700;color:#151515;letter-spacing:0.03em;text-transform:uppercase;line-height:1.45;white-space:pre-wrap}` +
    `.hand{font-family:'Ubuntu Mono',monospace;font-size:22px;font-weight:700;color:rgba(21,21,21,0.78);line-height:1.5;margin-top:10px}` +
    `.lgn{height:72px;display:block}`;

  const body =
    `<div class="viz">` +
    `<div class="hd">${hdLogo}${badge}</div>` +
    titulo +
    `<div class="chart">${chart}</div>` +
    `<div class="ft"><div>${fuente}${handles}</div>${ftLogo}</div>` +
    `</div>`;

  return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8">
<style>
${fontsCSS}${css}
</style>
</head>
<body>
${body}
</body>
</html>`;
}

async function generateViz(config, assets) {
  const outputDir = config.output_dir;
  if (!outputDir) throw new Error('output_dir requerido para template viz_redes');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

  const formatos = Array.isArray(config.formatos)
    ? config.formatos
    : (typeof config.formatos === 'string' && config.formatos ? [config.formatos] : ['1x1', '4x5', '16x9']);

  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu']
  });

  try {
    for (const fmt of formatos) {
      const html = buildVizHTML(config, fmt, assets);
      const tmpHTML = path.join(require('os').tmpdir(), `viz_${fmt}_${Date.now()}.html`);
      fs.writeFileSync(tmpHTML, html);

      const page = await browser.newPage();
      await page.setViewportSize(fmt === '4x5' ? { width: 1200, height: 1500 }
        : fmt === '16x9' ? { width: 2000, height: 1200 } : { width: 1200, height: 1200 });
      await page.goto('file://' + tmpHTML, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(500);

      const outPNG = path.join(outputDir, `viz_${fmt}.png`);
      await page.locator('.viz').screenshot({ path: outPNG, scale: 'css', type: 'png' });
      await page.close();
      fs.unlinkSync(tmpHTML);
      console.log(`Viz ${fmt}: ${outPNG}`);
    }
  } finally {
    await browser.close();
  }
}

// ---- Main ----
async function main() {
  const args = process.argv.slice(2);
  let configFile = null;
  let outputFile = 'flyer.png';

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--config' && args[i + 1]) configFile = args[i + 1];
    if (args[i] === '--output' && args[i + 1]) outputFile = args[i + 1];
  }

  if (!configFile) {
    console.error('Uso: node generate_flyer.js --config config.json [--output flyer.png]');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));

  const scriptDir = __dirname;
  const logoPath = path.join(scriptDir, 'www', 'logo_er.png');
  let logoB64 = null;
  if (fs.existsSync(logoPath)) {
    logoB64 = 'data:image/png;base64,' + fs.readFileSync(logoPath).toString('base64');
  }

  // Assets tarjeta clásica: logos por tinta, isotipo, fuente Array, íconos Boxicons
  const tarjAssets = { logos: {}, icons: {} };
  const iconsDir = path.join(scriptDir, 'www', 'icons');
  if (fs.existsSync(iconsDir)) {
    for (const f of fs.readdirSync(iconsDir)) {
      if (f.endsWith('.svg')) {
        tarjAssets.icons[f.replace(/\.svg$/, '')] = fs.readFileSync(path.join(iconsDir, f), 'utf-8');
      }
    }
  }
  for (const v of ['negro', 'blanco', 'azul']) {
    const p = path.join(scriptDir, 'www', `logo_er_${v}.png`);
    if (fs.existsSync(p)) tarjAssets.logos[v] = 'data:image/png;base64,' + fs.readFileSync(p).toString('base64');
  }
  const isoPath = path.join(scriptDir, 'www', 'isotipo_estacion_r.svg');
  if (fs.existsSync(isoPath)) {
    tarjAssets.isotipo = 'data:image/svg+xml;base64,' + fs.readFileSync(isoPath).toString('base64');
  }
  const arrayPath = path.join(scriptDir, 'www', 'fonts', 'Array-Bold.woff2');
  if (fs.existsSync(arrayPath)) {
    tarjAssets.arrayFont = fs.readFileSync(arrayPath).toString('base64');
  }

  // Tarjeta clásica (4:5 + 16:9): genera PNGs en output_dir; no usa --output
  if (config.template === 'tarjeta_curso') {
    await generateTarjeta(config, tarjAssets);
    return;
  }

  // Visuales para redes (1:1 + 4:5 + 16:9): genera PNGs en output_dir; no usa --output
  if (config.template === 'viz_redes') {
    await generateViz(config, tarjAssets);
    return;
  }

  // Carousel (paquete 4 slides / curso 3-4 slides): genera PNGs en output_dir; no usa --output
  if (config.template === 'carousel' || config.template === 'carousel_curso') {
    await generateCarousel(config, logoB64, tarjAssets.arrayFont);
    return;
  }

  const html = config.template === 'tip'
    ? buildTipHTML(config, logoB64)
    : buildHTML(config, logoB64);

  if (outputFile.endsWith('.html')) {
    fs.writeFileSync(outputFile, html);
    console.log(`HTML escrito: ${outputFile}`);
    return;
  }

  const tmpHTML = path.join(require('os').tmpdir(), `flyer_${Date.now()}.html`);
  fs.writeFileSync(tmpHTML, html);

  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu']
  });
  const page = await browser.newPage();
  await page.goto('file://' + tmpHTML, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);

  const selector = config.template === 'tip' ? '.tip-card' : '.flyer';
  await page.locator(selector).screenshot({ path: outputFile, scale: 'css', type: 'png' });

  await browser.close();
  fs.unlinkSync(tmpHTML);
  console.log(`PNG generado: ${outputFile}`);
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
