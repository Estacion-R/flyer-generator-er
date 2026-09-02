#!/usr/bin/env node
/**
 * Worker persistente para el preview en vivo del Generador de Flyers.
 *
 * Arranca una vez por sesión de Shiny (ver R/10_flyer_worker.R) y expone los
 * builders de HTML puros de generate_flyer.js (sin Playwright) por HTTP en
 * 127.0.0.1 con un puerto efímero. Así el preview reactivo a cada tecla no
 * necesita spawnear un proceso `node` nuevo por keystroke -- solo hace un
 * POST local a un proceso que ya está arriba con los assets (logos, fuente
 * Array, íconos) precargados en memoria.
 *
 * Al arrancar imprime "PORT:<n>" en stdout (una sola línea) para que el
 * proceso R que lo lanzó sepa a qué puerto conectarse.
 *
 * Uso: node worker.js
 */
'use strict';
const http = require('http');
const {
  loadAssets,
  buildHTML,
  buildTipHTML,
  buildVizHTML,
  buildTarjetaHTML,
  buildSlide1,
  buildSlide2,
  buildSlide3,
  buildSlide4,
  buildCourseSlideByType
} = require('./generate_flyer.js');

const { logoB64, tarjAssets } = loadAssets(__dirname);

function render(body) {
  const { template, config, formato, tipo, position, total } = body;
  switch (template) {
    case 'viz_redes':
      return buildVizHTML(config, formato, tarjAssets);
    case 'tarjeta_curso':
      return buildTarjetaHTML(config, formato, tarjAssets);
    case 'slide1':
      return buildSlide1(config, logoB64);
    case 'slide2':
      return buildSlide2(config, logoB64);
    case 'slide3':
      return buildSlide3(config, logoB64);
    case 'slide4':
      return buildSlide4(config, logoB64);
    case 'course_slide':
      return buildCourseSlideByType(tipo, config, logoB64, tarjAssets.arrayFont, position, total);
    case 'curso':
      return buildHTML(config, logoB64);
    case 'tip':
      return buildTipHTML(config, logoB64);
    default:
      throw new Error('template desconocido: ' + template);
  }
}

const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }
  if (req.method !== 'POST' || req.url !== '/render') {
    res.writeHead(404);
    res.end();
    return;
  }
  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    try {
      const body = JSON.parse(Buffer.concat(chunks).toString('utf-8'));
      const html = render(body);
      res.end(JSON.stringify({ ok: true, html }));
    } catch (err) {
      res.end(JSON.stringify({ ok: false, error: err.message }));
    }
  });
});

server.listen(0, '127.0.0.1', () => {
  console.log('PORT:' + server.address().port);
});
