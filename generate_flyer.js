#!/usr/bin/env node
/**
 * Generador de Flyers — Estación R (versión local con Playwright)
 *
 * Uso:
 *   node generate_flyer.js --config config.json --output flyer.png
 *   node generate_flyer.js --config config.json --output flyer.html  (solo HTML)
 *
 * config.json:
 * {
 *   "formato": "instagram|linkedin|story",
 *   "imagen_curso": "/ruta/a/imagen.png",   // opcional
 *   "badge_texto": "Curso virtual",
 *   "badge_color": "Azul ER",               // Azul ER | Naranja ER | Teal ER | Negro
 *   "titulo": "INTRODUCCIÓN A R...",
 *   "subtitulo": "Descripción breve",
 *   "bullets": ["Item 1", "Item 2", ...],
 *   "col1_texto": "Grabaciones...",
 *   "col2_texto": "Certificado...",
 *   "col3_texto": "Canal exclusivo...",
 *   "footer_texto": "INSCRIPCIÓN ABIERTA\nMARTES 19:00",
 *   "footer_icon": "📣"
 * }
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
  instagram: { w: 540, h: 540 },
  linkedin: { w: 540, h: null },   // auto height
  story: { w: 380, h: 675 }
};

// ---- SVG icons (Boxicons paths) ----
const SVG_ICONS = {
  movie_play: '<path d="M20 3H4c-1.103 0-2 .897-2 2v14c0 1.103.897 2 2 2h16c1.103 0 2-.897 2-2V5c0-1.103-.897-2-2-2zm.001 6c-.001 0-.001 0 0 0h-.465l-2.667-4H20l.001 4zM9.536 9 6.869 5h2.596l2.667 4H9.536zm5 0-2.667-4h2.596l2.667 4h-2.596zM4 5h.465l2.667 4H4V5zm0 14v-8h16l.002 8H4z"/><path d="m10 18 5.5-3-5.5-3z"/>',
  certification: '<path d="M2.06 14.68a1 1 0 0 0 .46.6l1.91 1.11v2.2a1 1 0 0 0 1 1h2.2l1.11 1.91a1 1 0 0 0 .86.5 1 1 0 0 0 .51-.14l1.9-1.1 1.91 1.1a1 1 0 0 0 1.37-.36l1.1-1.91h2.2a1 1 0 0 0 1-1v-2.2l1.91-1.11a1 1 0 0 0 .37-1.36L20.76 12l1.11-1.91a1 1 0 0 0-.37-1.36l-1.91-1.1v-2.2a1 1 0 0 0-1-1h-2.2l-1.1-1.91a1 1 0 0 0-.61-.46 1 1 0 0 0-.76.1L12 3.26l-1.9-1.1a1 1 0 0 0-1.36.36L7.63 4.43h-2.2a1 1 0 0 0-1 1v2.2l-1.9 1.1a1 1 0 0 0-.37 1.37l1.1 1.9-1.1 1.91a1 1 0 0 0-.1.77zm3.22-3.17L4.39 10l1.55-.9a1 1 0 0 0 .49-.86V6.43h1.78a1 1 0 0 0 .87-.5L10 4.39l1.54.89a1 1 0 0 0 1 0l1.55-.89.91 1.54a1 1 0 0 0 .87.5h1.77v1.78a1 1 0 0 0 .5.86l1.54.9-.89 1.54a1 1 0 0 0 0 1l.89 1.54-1.54.9a1 1 0 0 0-.5.86v1.78h-1.83a1 1 0 0 0-.86.5l-.89 1.54-1.55-.89a1 1 0 0 0-1 0l-1.51.89-.89-1.54a1 1 0 0 0-.87-.5H6.43v-1.78a1 1 0 0 0-.49-.81l-1.55-.9.89-1.54a1 1 0 0 0 0-1.05z"/>',
  slack: '<path d="M20.935 12.646a1.617 1.617 0 0 0-2.022-1.034l-1.632.532c-.355-1.099-.735-2.268-1.092-3.365l.006-.002-.004-.008 1.613-.523a1.62 1.62 0 0 0 1.035-2.023 1.62 1.62 0 0 0-2.025-1.034l-1.621.527-.519-1.604a1.619 1.619 0 0 0-2.024-1.034 1.618 1.618 0 0 0-1.033 2.024l.522 1.609-3.368 1.092-.524-1.611a1.618 1.618 0 0 0-2.022-1.034 1.617 1.617 0 0 0-1.034 2.023l.524 1.616-1.662.541a1.602 1.602 0 0 0-.988 1.95c.25.856 1.152 1.373 1.979 1.092.006 0 .658-.209 1.665-.536l1.099 3.386h-.002v.002l-1.67.545a1.599 1.599 0 0 0-.987 1.949c.25.857 1.15 1.374 1.979 1.093.007 0 .659-.211 1.665-.538l.003.005a.024.024 0 0 0 .008-.002l.539 1.657a1.6 1.6 0 0 0 1.949.989c.857-.25 1.373-1.151 1.094-1.979 0-.006-.209-.654-.533-1.654l-.003-.009c1.104-.358 2.276-.739 3.376-1.098l.543 1.668a1.602 1.602 0 0 0 1.949.989c.856-.251 1.374-1.152 1.092-1.979 0-.007-.209-.659-.535-1.663l.019-.006-.003-.007 1.609-.522a1.62 1.62 0 0 0 1.035-2.024zM10.86 14.238l-1.097-3.377a.02.02 0 0 0 .005-.001v-.006c1.098-.356 2.268-.735 3.363-1.092l1.098 3.377-3.369 1.099z"/>'
};

function svgIcon(pathContent, color = '#447099') {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" style="width:1.5rem;height:1.5rem;fill:${color};display:block;">${pathContent}</svg>`;
}

// ---- CSS ----
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

.flyer-subtitle {
  font-size: 0.95rem;
  color: #404041;
  margin: 0;
  line-height: 1.5;
}

.flyer-bullets {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.flyer-bullets li {
  display: flex;
  align-items: flex-start;
  gap: 0.6rem;
  font-size: 0.95rem;
  color: #151515;
}

.flyer-bullets li::before {
  content: '●';
  color: #EE6331;
  font-size: 0.7rem;
  margin-top: 0.3rem;
  flex-shrink: 0;
}

.flyer-info-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 1rem;
  border-top: 2px solid #151515;
  padding-top: 1rem;
  margin-top: auto;
}

.flyer-info-col {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.flyer-info-icon {
  font-size: 1.4rem;
  color: #447099;
  margin-bottom: 0.2rem;
  line-height: 1;
}

.flyer-info-label {
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
}

.flyer-info-text {
  font-size: 0.82rem;
  color: #404041;
  line-height: 1.4;
}

.flyer-footer-highlight {
  background: #EAFF38;
  border: 2px solid #151515;
  padding: 0.75rem 1rem;
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.flyer-footer-highlight .footer-icon {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.flyer-footer-text {
  font-size: 0.88rem;
  font-weight: 700;
  color: #151515;
  font-family: 'Ubuntu', sans-serif;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  line-height: 1.4;
}

.flyer-brand {
  text-align: center;
  font-size: 0.75rem;
  color: #707073;
  font-family: 'Ubuntu', sans-serif;
  letter-spacing: 0.08em;
  border-top: 1.5px solid #C2C2C4;
  padding-top: 0.75rem;
}

.flyer-brand img {
  height: 28px;
  display: block;
  margin: 0 auto 0.3rem;
}
`;

// ---- Build HTML ----
function buildHTML(config, logoB64) {
  const formato = FORMATOS[config.formato] || FORMATOS.linkedin;
  const badgeHex = BADGE_COLORES[config.badge_color] || BADGE_COLORES['Azul ER'];
  const badgeFG = badgeHex === '#151515' ? '#EAFF38' : '#FFFFFF';

  let css = CSS
    .replace('{{WIDTH}}', formato.w)
    .replace('{{HEIGHT}}', formato.h ? `height: ${formato.h}px; min-height: ${formato.h}px;` : '')
    .replace('{{BADGE_BG}}', badgeHex)
    .replace('{{BADGE_FG}}', badgeFG);

  // Image
  let imgTag = '';
  if (config.imagen_curso) {
    const imgData = fs.readFileSync(config.imagen_curso);
    const ext = path.extname(config.imagen_curso).slice(1).toLowerCase();
    const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
    const b64 = imgData.toString('base64');
    imgTag = `<img src="data:${mime};base64,${b64}" class="flyer-course-image" alt=""/>`;
  }

  // Bullets
  const bulletsHTML = (config.bullets || [])
    .map(b => `<li>${b}</li>`).join('');

  // Footer text (preserve newlines)
  const footerHTML = (config.footer_texto || '')
    .replace(/\n/g, '<br>');

  // Logo
  const logoTag = logoB64
    ? `<img src="${logoB64}" alt="Estación R"/>`
    : '';

  return `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<style>${css}</style>
</head>
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
  <div class="flyer-brand">
    ${logoTag}
    <span>estacion-r.com</span>
  </div>
</div>
</body>
</html>`;
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
    console.error('Uso: node generate_flyer.js --config config.json --output flyer.png');
    process.exit(1);
  }

  const config = JSON.parse(fs.readFileSync(configFile, 'utf-8'));

  // Resolve logo path relative to script dir
  const scriptDir = __dirname;
  const logoPath = path.join(scriptDir, 'logo_er.png');
  let logoB64 = null;
  if (fs.existsSync(logoPath)) {
    logoB64 = 'data:image/png;base64,' + fs.readFileSync(logoPath).toString('base64');
  }

  const html = buildHTML(config, logoB64);

  // If output is .html, just write and exit
  if (outputFile.endsWith('.html')) {
    fs.writeFileSync(outputFile, html);
    console.log(`HTML escrito: ${outputFile}`);
    return;
  }

  // PNG: render with Playwright
  const tmpHTML = path.join(require('os').tmpdir(), `flyer_${Date.now()}.html`);
  fs.writeFileSync(tmpHTML, html);

  const browser = await chromium.launch({
    executablePath: '/usr/bin/google-chrome',
    args: ['--no-sandbox', '--disable-gpu']
  });
  const page = await browser.newPage();
  await page.goto('file://' + tmpHTML, { waitUntil: 'networkidle' });
  // Wait for fonts to load
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);

  const flyer = await page.locator('.flyer');
  await flyer.screenshot({
    path: outputFile,
    scale: 'css',
    type: 'png'
  });

  await browser.close();
  fs.unlinkSync(tmpHTML);
  console.log(`PNG generado: ${outputFile}`);
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});