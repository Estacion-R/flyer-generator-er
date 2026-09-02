# tests/

## `generar_smoke_test.sh`

Smoke test del CLI `generate_flyer.js`. Genera los 6 builders de la app (carrusel de
paquete, carrusel de curso, tarjeta clásica de curso 4:5+16:9, visual de datos para
redes, flyer de curso LinkedIn/X y tarjeta de tip/paquete) con datos de prueba fijos,
sin pasar por la UI de Shiny.

Por cada uno verifica:

- que el proceso termine con exit code 0
- que el/los archivo(s) de salida existan y no estén vacíos ni truncados (umbral de
  tamaño mínimo, no comparación pixel a pixel — ver nota abajo)
- en las salidas HTML standalone (flyer de curso y tip): que no queden referencias a
  `fonts.googleapis.com`/`fonts.gstatic.com` (regresión del fix de fuentes embebidas
  en base64 de la Etapa 1)

No compara contenido visual (hash de imagen, pixel diff): sería frágil ante cambios de
layout legítimos. El objetivo es solo detectar un render roto (crash, archivo vacío,
regresión de fuentes online), como red de seguridad antes/después de cambios grandes
en `app.R` o `generate_flyer.js`.

### Cómo correrlo

```bash
cd flyer_generator_er
./tests/generar_smoke_test.sh
```

Sale con exit code 0 si todo pasó, 1 si algo falló (imprime el detalle de qué
archivo/paso falló al final). Usa un directorio temporal (`mktemp -d`) que se borra
solo al terminar — no toca `app.R` ni la app en producción.

Requiere lo mismo que la app: Node (detecta `/home/linuxbrew/.linuxbrew/bin/node` o,
si no existe, el `node` del PATH) y Google Chrome en `/usr/bin/google-chrome`.
