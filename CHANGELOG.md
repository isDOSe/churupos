# Changelog de Churupos

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

## [1.0.7+8] - 2026-11-07

### Agregado
- Tocar el resultado lo copia al portapapeles con el formato venezolano (`Bs. 26.586,81`,
  `$ 30,00`, `12,50 USDT`) y muestra el aviso “Copiado al portapapeles”.
  - Vibración corta al copiar y un icono junto a “Equivale a” como pista.
  - Solo copia cuando hay monto escrito y tasa disponible; con el campo vacío no hace nada
    y el icono no aparece.

### Técnicos
- Tests del portapapeles, con y sin monto (84 tests en total).
- APK `churupos-1.0.7.apk` firmado con la clave de depuración en `dist/`.

## [1.0.6+7] - 2026-10-30

### Agregado
- Botón de reinicio en el encabezado, junto a “Actualizar”: vuelve el cálculo a
  **1 dólar BCV a bolívares** en cualquier momento.

### Cambiado
- La portada web (`landing/`) actualiza la captura del conversor con el nuevo botón
  de reinicio y con la hora exacta del cálculo.

### Web
- El sitio oficial estrena **“Probar versión web”**: un modal con conversor limitado
  a dólar y euro BCV. No incluye USDT, historial, compartir captura ni modo offline;
  esos quedan como exclusivos de la app.
- El modal funciona sin backend: consulta dolarapi directo y guarda la última tasa
  en el navegador.

### Técnicos
- `PairNotifier.reset()` restaura el par por defecto y lo guarda junto al monto.
- Test del botón de reinicio (82 tests en total).
- APK `churupos-1.0.6.apk` firmado con la clave de depuración en `dist/`.

## [1.0.5+6] - 2026-10-28

### Corregido
- La hora que aparece junto a la tasa dentro de la app ahora es la del último refresco
  exitoso, igual que en el texto al compartir. Se muestra como hora exacta en
  formato 12 h (`1:18 p. m.`) en lugar de `hace 5 min`, así ya no aparece `00:00`
  (la hora de publicación del BCV) y se entiende de un vistazo cuándo se actualizó.

### Técnicos
- `ConversionView.effectiveAt` toma `RatesState.fetchedAt` y solo usa la marca de la
  cotización como respaldo.
- `buildShareText()` usa esa misma marca para que la app y el texto compartido coincidan.
- Nuevos tests de la hora del cálculo, del formato de hora y del texto al compartir
  (81 tests en total).
- APK `churupos-1.0.5.apk` firmado con la clave de depuración en `dist/`.

## [1.0.4+5] - 2026-10-27

### Agregado
- Landing web en `landing/` para `churupos.isdose.com`: HTML/CSS estático, sin JavaScript,
  con la misma paleta, Poppins local y paneles chamferados de la app.
  - Hero con el conversor, sección de “cero anuncios”, pasos de uso, ficha técnica, fuentes y
    descarga.
  - Bloque final con el proceso de construcción: IA, `specs.md` de más de 1.000 líneas,
    iteraciones y criterio humano.
  - Placeholder de Google Play y mensaje honesto para iOS.
- `robots.txt` y `sitemap.xml` para la landing.

### Cambiado
- El crédito de la app y de la web ahora dice **“Hecho por DOSe”** en lugar de
  “Hecho por isdose.com”.
- Los gráficos de Play Store se regeneraron con el nuevo crédito.
- El hero de la landing usa **“Calcula divisas”** para no sonar a exchange.

### Técnicos
- APK `churupos-1.0.4.apk` firmado con la clave de depuración en `dist/`.

## [1.0.3+4] - 2026-10-27

### Agregado
- Botón **Historial** debajo de **Compartir cálculo**, con el icono de gráfico y acceso directo
  a la pantalla de historial.
- Selector de fecha específica al inicio de la fila de rangos (`7D`, `30D`, `90D`).
  - Al elegir una fecha se consulta `ve.dolarapi.com` para ese día y se muestra su tasa.
  - La fecha activa muestra una `X` para quitarla y volver al cierre más reciente.
  - Si el BCV no publicó tasa ese día, se avisa y se ofrece elegir otra fecha o quitar el filtro.
  - Para USDT se usa el snapshot diario guardado por la app, porque Binance P2P no publica histórico.
- Localización de Material en español de Venezuela, incluido el selector de fechas.

### Cambiado
- El acceso al historial ya no ocupa un icono en el encabezado; ahora es un botón visible junto a
  las acciones principales.

### Técnicos
- `DolarHistoryClient.fetchForDate()` y `HistoryRepository.fetchForDate()` separan la consulta
  puntual de la descarga de la serie de 120 días.
- 74 tests: parser de la respuesta por fecha, repositorio y flujo de la pantalla de historial.
- `flutter_localizations` añadido al `pubspec.yaml`.
- APK `churupos-1.0.3.apk` firmado con la clave de depuración en `dist/`.

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
