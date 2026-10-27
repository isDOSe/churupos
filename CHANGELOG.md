# Changelog de Churupos

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [1.0.2+3] - 2026-10-27

### Agregado
- Pantalla de historial de la tasa con rangos de 7, 30 y 90 días.
  - Gráfico interactivo: tocar o arrastrar muestra el cierre de cada día.
  - Variación del periodo en porcentaje y bolívares, más mínimo, máximo y promedio.
  - Monedas `USD` y `EUR` con el histórico oficial del BCV vía
    `https://ve.dolarapi.com/v1/historicos/dolares` y `/euros` (datos desde 2023).
  - `USDT` con snapshots diarios guardados por la app: Binance P2P no publica histórico.
  - Acceso desde el icono de gráfico del encabezado; caché de 6 h y refresco manual.
- Nuevo script `scripts/generate_play_store_graphics.py` que genera los gráficos para Google Play Store:
  - `feature-graphic.png` (1024 x 500): banner principal destacando "Sin publicidad" y "Fácil de usar".
  - 4 screenshots de teléfono (1080 x 1920) con titular, mockup de teléfono y pie: conversión, sin publicidad, transparencia de fuentes y compartir.

### Corregido
- El texto para compartir ya no muestra `00:00` como hora de la tasa; ahora muestra la hora actual en que se comparte el cálculo, que es el momento más actualizado de la información.

### Cambiado
- Logo e icono de la app: se mantuvo el monograma "C" original (sin flechas) tras probar la variante.
- El historial de USDT se guarda una vez al día en cada refresco exitoso de tasas.

### Técnicos
- Serie histórica recortada a 120 días antes de cachearla; una sola descarga alimenta los tres rangos.
- 68 tests: parser y rangos del histórico, snapshots de USDT, caché y pantalla de historial.
- APK `churupos-1.0.2.apk` firmado con la clave de depuración.

## [1.0.1+2] - 2026-10-25

> Nota: los cambios exactos de esta versión no están documentados en el historial del proyecto. Si los recuerdas, agrégalos aquí.

### Cambios conocidos
- Versión empaquetada como `churupos-1.0.1.apk`.
- `minSdkAndroid` ajustado a 24 (Android 7.0+).
- APK publicado como [release de GitHub v1.0.1](https://github.com/isDOSe/churupos/releases/tag/v1.0.1).

## [1.0.0+1] - 2026-10-23

### Agregado
- Pantalla única de conversión entre `VES`, `USD BCV`, `EUR BCV` y `USDT Binance P2P`.
- Selectores de moneda origen y destino con intercambio rápido y animación.
- Campo de monto con teclado numérico, formato venezolano (`es-VE`) y límites de entrada.
- Resultado calculado en vivo mientras se escribe.
- Tasa unitaria y hora de actualización visibles.
- Actualización automática cada 5 minutos, manual y al volver de background.
- Caché local de la última tasa válida por fuente; modo sin conexión con aviso.
- Botón "Compartir cálculo": captura el panel y comparte imagen + texto.
- Hoja "De dónde salen estos valores" con fuentes y descargo de responsabilidad.
- Tema oscuro cyberpunk con tipografía Poppins incluida en assets.
- Logo monograma "C" + rayo ámbar, generado por código en `scripts/generate_app_icon.py`.
- 51 tests unitarios, de dominio y de widgets.
- APK de prueba firmado con clave de depuración, publicado como [release de GitHub v1.0.0](https://github.com/isDOSe/churupos/releases/tag/v1.0.0).

### Técnicos
- Estado con Riverpod (providers manuales, sin codegen).
- Fuente BCV: `https://ve.dolarapi.com/v1/cotizaciones`.
- Fuente Binance: endpoint público P2P, promedio de las 10 mejores ofertas de venta de USDT.
- Paquete Android: `com.isdose.churupos`.
