# ---- CSS app ----
css_app <- paste0(UBUNTU_FONT_FACES, "
.panel-form {
  background: #FFFFFF;
  border: 2px solid #151515;
  box-shadow: 4px 4px 0 #EE6331;
  padding: 1.5rem;
  height: fit-content;
}

.section-label {
  font-size: 0.72rem; font-weight: 700; letter-spacing: 0.1em;
  text-transform: uppercase; color: #447099;
  font-family: 'Ubuntu', sans-serif; margin-bottom: 0.5rem; display: block;
}

.btn-download {
  background: #151515; color: #EAFF38; border: 2px solid #151515;
  font-family: 'Ubuntu', sans-serif; font-weight: 700;
  padding: 0.6rem 1.5rem; width: 100%;
  text-transform: uppercase; letter-spacing: 0.08em;
  cursor: pointer; font-size: 0.85rem; margin-top: 0.5rem;
}
.btn-download:hover { background: #447099; color: #FFFFFF; }

.btn-zip {
  background: #447099; color: #FFFFFF; border: 2px solid #151515;
  font-family: 'Ubuntu', sans-serif; font-weight: 700;
  padding: 0.65rem 1.5rem; width: 100%;
  text-transform: uppercase; letter-spacing: 0.08em;
  cursor: pointer; font-size: 0.85rem; margin-top: 0.5rem;
}
.btn-zip:hover { background: #151515; color: #EAFF38; }

.slide-grid {
  display: grid;
  grid-template-columns: 540px 540px;
  gap: 1.25rem;
  padding: 1rem;
}

.slide-preview-wrap {
  width: 540px; height: 540px;
  overflow: hidden; flex-shrink: 0;
  border: 2px solid #C2C2C4;
  position: relative;
}

.slide-preview-wrap iframe {
  width: 1080px; height: 1080px; border: none;
  transform: scale(0.5); transform-origin: top left; display: block;
}

.slide-label {
  font-family: 'Ubuntu', sans-serif; font-size: 0.72rem; font-weight: 700;
  letter-spacing: 0.08em; text-transform: uppercase; color: #707073;
  margin-bottom: 0.4rem;
}

.flyer-wrap {
  display: flex; justify-content: center; align-items: flex-start; padding: 1rem;
}
")

# ---- CSS flyer LinkedIn/X ----
css_flyer <- paste0(UBUNTU_FONT_FACES, "
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; }

.flyer-wrap { display: flex; justify-content: center; align-items: flex-start; padding: 1rem; }

.flyer {
  width: 540px; min-height: 680px; background: #FFFFFF;
  border: 2.5px solid #151515; box-shadow: 8px 8px 0 #EAFF38;
  padding: 2.5rem 2.8rem 2rem 2.8rem; font-family: 'Ubuntu', sans-serif;
  display: flex; flex-direction: column; gap: 1.4rem; position: relative;
}
.flyer-course-image {
  width: calc(100% + 5.6rem); margin: -2.5rem -2.8rem 0 -2.8rem;
  height: 180px; object-fit: cover; display: block; border-bottom: 2.5px solid #151515;
}
.flyer-badge {
  display: inline-block; background: #447099; color: #FFFFFF;
  border: 2px solid #151515; padding: 0.22rem 0.85rem;
  font-size: 0.78rem; font-weight: 700; letter-spacing: 0.08em;
  text-transform: uppercase; font-family: 'Ubuntu', sans-serif; width: fit-content;
}
.flyer-title {
  font-size: 2.2rem; font-weight: 700; color: #151515;
  font-family: 'Ubuntu', sans-serif; line-height: 1.15; letter-spacing: -0.01em; margin: 0;
}
.flyer-subtitle { font-size: 0.95rem; color: #404041; margin: 0; line-height: 1.5; }
.flyer-bullets { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 0.5rem; }
.flyer-bullets li { display: flex; align-items: flex-start; gap: 0.6rem; font-size: 0.95rem; color: #151515; }
.flyer-bullets li::before { content: '●'; color: #EE6331; font-size: 0.7rem; margin-top: 0.3rem; flex-shrink: 0; }
.flyer-info-grid {
  display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem;
  border-top: 2px solid #151515; padding-top: 1rem; margin-top: auto;
}
.flyer-info-col { display: flex; flex-direction: column; gap: 0.25rem; }
.flyer-info-icon { font-size: 1.4rem; color: #447099; margin-bottom: 0.2rem; line-height: 1; }
.flyer-info-label { font-size: 0.68rem; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; color: #151515; font-family: 'Ubuntu', sans-serif; }
.flyer-info-text { font-size: 0.82rem; color: #404041; line-height: 1.4; }
.flyer-footer-highlight { background: #EAFF38; border: 2px solid #151515; padding: 0.75rem 1rem; display: flex; align-items: center; gap: 0.8rem; }
.flyer-footer-highlight .footer-icon { font-size: 1.5rem; flex-shrink: 0; }
.flyer-footer-text { font-size: 0.88rem; font-weight: 700; color: #151515; font-family: 'Ubuntu', sans-serif; text-transform: uppercase; letter-spacing: 0.04em; line-height: 1.4; }
.flyer-brand { text-align: center; font-size: 0.75rem; color: #707073; font-family: 'Ubuntu', sans-serif; letter-spacing: 0.08em; border-top: 1.5px solid #C2C2C4; padding-top: 0.75rem; }
.flyer-brand img { height: 28px; display: block; margin: 0 auto 0.3rem; }
")

css_tip <- paste0(UBUNTU_FONT_FACES, "
* { margin: 0; padding: 0; box-sizing: border-box; }
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
")

# ---- CSS base para slides del carrusel (embebido en iframes) ----
CAROUSEL_BASE_CSS <- paste0(UBUNTU_FONT_FACES, "
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #f5f5f5; display: flex; justify-content: center; align-items: center; padding: 0; margin: 0; min-height: 100vh; }")

