# Churupos — Especificación de producto y técnica

**Versión:** 1.0.0
**Fecha:** 23 de octubre de 2026
**Estado:** implementado y probado en Android (v1.0.0+1)
**Plataforma:** Android (Flutter)

---

## 1. Resumen

Churupos es una calculadora de cambio de divisas para Venezuela. Convierte entre bolívares,
dólar BCV, euro BCV y USDT de Binance P2P en una sola pantalla, sin cuentas, sin publicidad y
sin backend propio.

El producto resuelve una pregunta concreta: **“¿cuánto son X en Y?”**, con la menor fricción
posible y con la fuente de cada tasa siempre a la vista.

### Objetivo

Que una persona pueda convertir 30 dólares BCV a bolívares en menos de cinco segundos, desde que
abre la app hasta que lee el resultado.

### Principios

1. **Una pantalla, una tarea.** No hay navegación principal, ni historial, ni dashboard.
2. **El resultado manda.** Es el elemento más grande, más contrastado y el único con brillo.
3. **Transparencia.** Toda tasa se puede rastrear hasta su fuente y su hora de actualización.
4. **La app no fija precios.** Solo comunica valores de referencia.
5. **Estética con carácter.** Cyberpunk sobrio, legible, sin los tics visuales de una app genérica.

---

## 2. Alcance

### Incluido en la v1

- Conversión entre 4 monedas: `VES` (bolívar), `USD` (dólar BCV), `EUR` (euro BCV) y
  `USDT` (Binance P2P).
- Selector de moneda de origen y destino en la misma pantalla.
- Intercambio rápido de origen/destino.
- Campo de monto con teclado numérico y formato venezolano.
- Resultado calculado en vivo mientras se escribe.
- Tasa unitaria y hora de actualización visibles.
- Actualización automática cada 5 minutos, manual, y al volver a la app.
- Caché local de la última tasa válida por fuente.
- Botón “Compartir cálculo”: captura el panel y comparte la imagen con el cálculo escrito.
- Hoja “De dónde salen estos valores” con enlaces y descargo de responsabilidad.
- Logo generado con el agente `@images` e integrado como marca de la app.
- Tema oscuro único, tipografía Poppins, español de Venezuela.

### Fuera de alcance (v1)

- iOS, web y escritorio.
- Historial, gráficos o alertas de tasa.
- Cuentas, sincronización, backend o base de datos remota.
- Comisiones, spreads configurables o casas de cambio.
- Dólar paralelo, efectivo, Zelle, PayPal u otras referencias.
- Modo claro.
- Multi-idioma.
- Widgets de pantalla de inicio.
- Monetización.

---

## 3. Decisiones tomadas

| Tema | Decisión |
|---|---|
| Plataforma | Solo Android, orientación vertical |
| Estado | Riverpod (providers manuales, sin codegen) |
| Fuente BCV | `https://ve.dolarapi.com/v1/cotizaciones` |
| Fuente Binance | Endpoint público de Binance P2P, sin API key |
| Precio Binance | Promedio de las 10 mejores ofertas de venta de USDT (lo que cuesta comprar USDT) |
| Actualización | Al abrir, cada 5 min, manual y al volver del background |
| Sin conexión | Última tasa cacheada + aviso con hora |
| Marca | Monograma “C” cyberpunk, sin texto dentro de la imagen |
| Tipografía | Poppins incluida en assets (no `google_fonts`) |
| Formato numérico | `es-VE` forzado, independiente del locale del equipo |
| Paquete Android | `com.isdose.churupos` |

---

## 4. Experiencia de usuario

### 4.1 Flujo principal

1. La app abre en **Dólar BCV → Bolívares** (o en el último par usado).
2. El usuario toca el selector de origen y elige una moneda.
3. Toca el selector de destino y elige otra.
4. Escribe el monto.
5. El resultado aparece debajo, actualizado en cada pulsación.
6. Opcional: toca el botón de intercambio para invertir el par y recalcular.
7. Opcional: toca “Compartir cálculo” para enviar una captura del panel con el texto.
8. Opcional: toca “De dónde salen estos valores” para ver fuentes y descargo.

### 4.2 Reglas de interacción

- **Mismo par:** si el usuario elige en un selector la moneda que ya está en el otro, los dos
  selectores se intercambian automáticamente. Nunca hay `USD → USD`.
- **Intercambio:** invierte origen y destino, conserva el monto y recalcula. Animación de 220 ms
  (rotación 180°) y háptica ligera.
- **Monto vacío:** se trata como `0`; el resultado muestra `0,00` atenuado.
- **Monto inválido:** no se permite. El campo solo admite dígitos y un separador decimal.
- **Persistencia:** se guardan el último par y el último monto al salir.
- **Teclado:** `TextInputType.numberWithOptions(decimal: true)`; el separador visible es la coma.
  Se acepta punto tecleado y se normaliza a coma.
- **Límite de entrada:** 12 dígitos enteros y 2 decimales.
- **Foco:** al abrir, el campo de monto NO se enfoca solo (evita que el teclado tape el
  resultado). Un toque en el panel del monto lo enfoca.
- **Cerrar hojas:** gesto de arrastre hacia abajo, botón atrás de Android y toque fuera.

### 4.3 Estados

| Estado | Qué ve el usuario |
|---|---|
| Cargando inicial | Panel con línea de progreso de 2 px en la parte superior; campos deshabilitados; resultado `—` |
| Datos frescos | Punto verde en la tasa; botón “Actualizar” disponible en el encabezado |
| Datos con caché | Punto ámbar y aviso “Sin conexión. Mostrando la última tasa guardada.” |
| Fuente parcial | La moneda afectada muestra “sin actualizar” en su selector; el resto opera normal |
| Error total sin caché | Resultado `—`, aviso bajo la tasa y botón “Reintentar”; “Actualizar” en el encabezado |
| Actualizando con datos previos | Los valores actuales siguen visibles; no se bloquea la interfaz |

Nunca se muestra un spinner de pantalla completa ni se borran los datos previos durante un
refresco.

---

## 5. Diseño visual

### 5.1 Dirección

**“Mostrador de cambio en Caracas, 2 a.m.”**: asfalto mojado, luz de sodio y ultravioleta,
señalética de neón. Un panel de instrumento, no una tarjeta de SaaS.

La app es oscura, precisa y legible. El cromo cyberpunk vive en los bordes, las esquinas
cortadas y un único brillo; el contenido es tipografía grande y limpia. El resultado es el faro:
todo lo demás está en silencio.

**Sí:**

- Esquinas biseladas (chamfer) en el panel principal y en los selectores.
- Líneas de 1 px que separan información real.
- Un solo acento brillante: el resultado en ámbar.
- Fondo con scanlines horizontales al 2 % y un resplandor violeta muy leve arriba.
- Poppins en todo, con números grandes y tracking negativo.

**No:**

- Glassmorphism, blobs degradados, brillos por todas partes.
- Tarjetas blancas semitransparentes o sombras difusas genéricas.
- Monedas 3D, robots, mascotas ni cripto-bro art.
- Etiquetas en MAYÚSCULAS con tracking, “→” al final de botones, emojis.
- Degradado rosa/cian por defecto, verde ácido sobre negro.
- Texto generado dentro de la imagen del logo.

### 5.2 Paleta

| Token | Hex | Uso |
|---|---|---|
| `void` | `#07060B` | Fondo de la app |
| `panel` | `#121019` | Panel del conversor |
| `raised` | `#191527` | Hojas y elementos elevados |
| `line` | `#2B2440` | Bordes de 1 px |
| `ink` | `#F5F1FF` | Texto principal |
| `muted` | `#9A93B3` | Texto secundario y unidades |
| `ultra` | `#7C5CFF` | Acento primario, foco, selección |
| `amber` | `#FFB020` | Resultado y avisos de datos viejos |
| `mint` | `#35E0B0` | Frescura de la tasa (punto) |
| `rose` | `#FF5C7A` | Errores |

Reglas:

- El ámbar se usa **solo** para el resultado y la frescura de los datos. No para botones.
- El violeta se usa para foco, selección, botón de intercambio y línea de progreso.
- Ningún texto secundario baja de 4,5:1 de contraste sobre su fondo.
- Prohibido el texto gris sobre `raised` por debajo de `#9A93B3`.

### 5.3 Tipografía

**Poppins** (SIL Open Font License), incluida en `assets/fonts/`:

| Rol | Peso | Tamaño | Detalle |
|---|---|---|---|
| Resultado | 700 | 60 sp (mín. 40, `FittedBox`) | `letterSpacing: -2`, `height: 0.95` |
| Monto | 600 | 34 sp | `letterSpacing: -0.8` |
| Código de moneda en selector | 700 | 26 sp | `letterSpacing: -0.5` |
| Nombre de moneda | 400 | 12,5 sp | color `muted` |
| Título de hoja | 600 | 22 sp | |
| Cuerpo | 400 | 15 sp | `height: 1.5` |
| Tasa unitaria | 500 | 13 sp | |
| Botón de fuente | 500 | 12,5 sp | subrayado al pulsar |
| Wordmark | 600 | 22 sp | `letterSpacing: -0.4` |

- Pesos incluidos: 300, 400, 500, 600, 700, 800.
- Números del resultado con `FontFeature.tabularFigures()`.
- Escalado de texto del sistema soportado hasta 1,3 sin recortes.
- Prohibido usar una segunda familia.

### 5.4 Layout

Una sola columna, alineación a la izquierda en etiquetas y a la derecha en cifras.

```
┌──────────────────────────────────────────────┐
│  [C]  Churupos                  ↻ Actualizar   │  header 64 dp
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │  Desde                     Hacia       │  │
│  │  ┌──────────┐   ┌──┐   ┌──────────┐    │  │
│  │  │ USD    ⌄ │   │⇅ │   │ VES    ⌄ │    │  │  selectores 108 dp
│  │  │ Dólar BCV│   └──┘   │ Bolívar  │    │  │
│  │  └──────────┘          └──────────┘    │  │
│  │                                        │  │
│  │  Monto                                 │  │
│  │                              30,00 USD │  │  campo 76 dp
│  │  ────────────────────────────────────  │  │
│  │  Equivale a                            │  │
│  │                        Bs. 26.586,81  │  │  resultado 96 dp
│  │  ────────────────────────────────────  │  │
│  │  1 USD = Bs. 886,23        hoy 00:00  │  │  tasa 32 dp
│  └────────────────────────────────────────┘  │
│                                              │
│                                              │
│      ¿De dónde salen estos valores?          │  pie
└──────────────────────────────────────────────┘
```

Medidas:

- Margen horizontal: 20 dp; 24 dp en pantallas ≥ 400 dp.
- Separación header → panel: 28 dp.
- Panel: padding 20 dp, borde `line` de 1 px, esquinas cortadas 16 dp arriba-izquierda y
  abajo-derecha (CustomClipper), sin sombra.
- Selectores: ancho flexible, alto 92 dp, separados 12 dp del botón de intercambio.
- Botón de intercambio: 48×48 dp, borde violeta de 1,5 px, esquinas cortadas 10 dp.
- Campo de monto: sin caja; línea inferior de 1 px que se ilumina en violeta al enfocar.
- Resultado: alineado a la derecha, sobre una línea base clara; ancho completo.
- Botón de compartir: debajo del panel, a 12 dp, 50 dp de alto, borde violeta y texto
  “Compartir cálculo”. No forma parte de la captura.
- Pie: a 20 dp del borde inferior seguro.

### 5.5 Componentes

**Header**
- Marca de 40×40 dp + wordmark “Churupos”.
- A la derecha, botón de refrescar de 32 dp (radio 4 dp, borde violeta al 50 %):
  icono de refresco + “Actualizar”.
- Al pulsar: háptica y refresco manual. Mientras actualiza muestra un spinner y queda
  deshabilitado.
- No hay etiqueta de estado: la frescura se indica con el punto y la antigüedad de la tasa.

**Selector de moneda**
- Área táctil completa de 92 dp.
- Contenido: código grande (`USD`), nombre pequeño (`Dólar BCV`), chevron de 16 dp a la derecha.
- Fondo `panel`, borde `line`; al abrir, borde `ultra` y un tinte violeta al 4 %.
- No usar `DropdownButton`: abre una hoja inferior.
- La hoja lista las 4 monedas con su tasa actual y una marca de selección violeta.
- Si una moneda no tiene tasa, aparece deshabilitada con el texto “sin datos”.

**Botón de intercambio**
- Icono propio de dos flechas verticales, no el emoji `⇄`.
- Al pulsar: rotación de 180°, háptica `selectionClick`, recálculo inmediato.
- Semántica: “Intercambiar monedas”.

**Campo de monto**
- Etiqueta “Monto” arriba, en `muted`, 12 sp.
- Cifra a la derecha, 34 sp; sufijo con el código de la moneda en `muted`.
- Sin placeholder de ejemplo; el `0` inicial es suficiente.
- Al enfocar, la línea inferior pasa a `ultra` con un glow de 6 px al 25 %.
- Botón “limpiar” (×) de 20 dp cuando hay valor.

**Resultado**
- Etiqueta “Equivale a” en `muted`, 12 sp.
- Cifra en `amber`, 60 sp, 700, con `boxShadow` ámbar al 22 %, blur 24.
- Debajo, el nombre de la moneda destino en `muted`.
- Al cambiar el valor: animación de conteo de 280 ms y un barrido de la línea inferior de
  izquierda a derecha (una sola vez). Respetar `MediaQuery.disableAnimations`.

**Tasa unitaria**
- “1 USD = Bs. 886,23” con el código de origen y el símbolo del destino.
- A la derecha, antigüedad: “ahora”, “hace 4 min”, “hoy 09:41”, “ayer 18:20”.
- Punto `mint` si ninguna de las dos tasas está en caché; `amber` si alguna lo está.
- Sin conexión, debajo aparece “Sin conexión. Mostrando la última tasa guardada.” en ámbar.

**Compartir cálculo**
- Botón de 50 dp debajo del panel, fuera del área capturada.
- Borde `ultra` al 55 %, fondo `panel`, icono de compartir y texto 13,5 sp semibold.
- Deshabilitado con monto `0`, sin tasa o mientras se genera la captura.
- Al pulsar: háptica, captura del panel a 3× con margen de 12 dp sobre `void`, y abre la hoja
  nativa de compartir con la imagen PNG y el texto.
- Texto compartido:

```text
30,00 USD = Bs. 26.586,81
1 USD = Bs. 886,23 · hoy 14:35

Calculado con Churupos, la calculadora de cambio para Venezuela.
Descarga la app: https://churupos.isdose.com
```

- La hora mostrada es la del momento en que se comparte, que es el dato más actualizado.
- Si la tasa viene de caché, añade “· tasa guardada".
- Si falla la captura, muestra un aviso y no interrumpe la app.

**Crédito de autor**
- Al pie de la pantalla, debajo del botón de fuentes: logo de isdose de 14 dp y el texto
  “Hecho por isdose.com” en 10,5 sp, `muted` al 72 %. Discreto, alineado al centro.
- Se repite al pie de la hoja de fuentes.
- Tocar el crédito abre `https://isdose.com`.
- No compite con la marca de Churupos ni con el resultado.

**Hoja de fuentes**
- Título “De dónde salen estos valores”.
- Dos bloques, separados por una línea:
  1. **Dólar y euro BCV** — “Banco Central de Venezuela, publicado por dolarapi.com.”
     Enlace: `ve.dolarapi.com`.
  2. **Binance (USDT)** — “Promedio de las 10 mejores ofertas de venta de USDT en Binance P2P,
     calculado por Churupos al actualizar.”
     Enlace: `p2p.binance.com`.
- Descargo, en 13 sp: “Churupos no fija, compra ni vende divisas. Los valores son referenciales
  y pueden cambiar en cualquier momento. Verifica siempre en la fuente antes de operar.”
- Botón “Entendido” de ancho completo, fondo `ultra`, texto `ink`.
- Los enlaces abren el navegador con `url_launcher`.

### 5.6 Movimiento

- Una sola secuencia de entrada al abrir: el panel aparece con opacidad 0→1 en 200 ms. Sin
  desplazamientos por sección.
- Conteo del resultado y barrido de la línea al cambiar el monto.
- Rotación del botón de intercambio.
- Apertura de hojas con `showModalBottomSheet` y curva `easeOutCubic` de 260 ms.
- Todo el movimiento se desactiva si el sistema tiene animaciones reducidas.

---

## 6. Datos y cálculo

### 6.1 Monedas

| ID | Código | Nombre visible | Símbolo en resultado | Fuente |
|---|---|---|---|---|
| `ves` | `VES` | Bolívar | `Bs.` | Base |
| `usd` | `USD` | Dólar BCV | `$` | dolarapi |
| `eur` | `EUR` | Euro BCV | `€` | dolarapi |
| `usdt` | `USDT` | Binance | `USDT` | Binance P2P |

`USDT` no es lo mismo que `USD`. Son opciones separadas y nunca se suman ni se promedian entre sí.

### 6.2 Modelo

Cada moneda se representa por **cuántos bolívares vale una unidad**:

```dart
class RateQuote {
  final Currency currency;
  final double vesPerUnit; // VES por 1 unidad de la moneda
  final DateTime updatedAt;
  final RateSource source; // dolarApi, binanceP2p, base
  final bool stale;        // true si viene de caché
}
```

`VES` siempre vale `1.0`.

### 6.3 Fórmula

```
resultado = monto × vesPerUnit[origen] / vesPerUnit[destino]
```

No se usan tasas cruzadas precalculadas. Todo pasa por bolívares, lo que evita inconsistencias
y permite añadir monedas después sin tocar el motor.

Ejemplos con las tasas del 23/10/2026:

| Conversión | Cálculo | Resultado |
|---|---|---|
| 30 USD → VES | 30 × 886,2271 | `Bs. 26.586,81` |
| 30 EUR → USD | 30 × 993,0884 / 886,2271 | `$ 33,62` |
| 100 VES → USDT | 100 / 1000,616 | `0,10 USDT` |
| 50 USDT → EUR | 50 × 1000,616 / 993,0884 | `€ 50,38` |

### 6.4 Formato

- Locale forzado `es_VE`: miles con `.`, decimales con `,`.
- `VES`: `Bs. 26.586,81` (siempre 2 decimales).
- `USD`: `$ 30,00`; `EUR`: `€ 30,00`; `USDT`: `30,00 USDT`.
- El símbolo va antes en fiat y después en USDT.
- Montos de entrada: hasta 2 decimales; se descartan decimales extra al escribir.
- Redondeo solo de presentación (`half-up`); el cálculo interno conserva `double`.
- Resultado menor que `0,01` se muestra con 2 decimales igualmente; nunca en notación científica.
- `-0,00` se normaliza a `0,00`.

### 6.5 Fecha y hora

- Las tasas se muestran en hora local del dispositivo.
- Texto relativo: `< 60 s` → “ahora”; `< 60 min` → “hace N min”; mismo día → “hoy HH:mm”;
  día anterior → “ayer HH:mm”; más antiguo → “dd/MM HH:mm”.
- La “frescura” del par es la del dato **más viejo** de los dos.

---

## 7. Fuentes de datos

### 7.1 BCV — dolarapi.com

```
GET https://ve.dolarapi.com/v1/cotizaciones
```

Respuesta (solo los campos usados):

```json
[
  {
    "moneda": "USD",
    "fuente": "oficial",
    "nombre": "Dólar",
    "promedio": 886.2271,
    "fechaActualizacion": "2026-10-23T00:00:00-04:00"
  },
  {
    "moneda": "EUR",
    "fuente": "oficial",
    "nombre": "Euro",
    "promedio": 993.08836371,
    "fechaActualizacion": "2026-10-23T00:00:00-04:00"
  }
]
```

Reglas:

- Una sola petición para ambas monedas.
- `promedio` es la tasa oficial; `compra` y `venta` vienen nulas y se ignoran.
- Si falta una moneda, esa moneda queda sin tasa; la otra sigue disponible.
- El BCV publica una vez al día; no se esperan cambios intradía.

### 7.2 Binance P2P — endpoint público

```
POST https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search
Content-Type: application/json

{
  "page": 1,
  "rows": 10,
  "payTypes": [],
  "asset": "USDT",
  "fiat": "VES",
  "tradeType": "BUY"
}
```

Respuesta relevante:

```json
{
  "data": [
    { "adv": { "price": "1008.498", "minSingleTransAmount": "10", "maxSingleTransAmount": "5000" } }
  ]
}
```

Reglas:

- `tradeType: "BUY"` significa “yo quiero comprar USDT”. Binance responde con anuncios cuyo
  `adv.tradeType` es `"SELL"`: terceros que venden USDT y aceptan bolívares. Son los precios
  que paga quien compra USDT. No confundir el parámetro (la acción del usuario) con el lado del
  anunciante.
- Se toman los 10 primeros anuncios y se promedian sus `adv.price`.
- Se descartan precios no numéricos, `<= 0` o no finitos.
- Si quedan menos de 3 precios válidos, la consulta se considera fallida (no se promedia ruido).
- `updatedAt` para Binance es el instante de la consulta.
- No se envían `payTypes` para no sesgar el promedio a un banco.
- Cabeceras recomendadas: `User-Agent` de navegador y `Accept: application/json`.
- Este endpoint **no es una API oficial**. Debe quedar aislado en un cliente propio para poder
  sustituirlo sin tocar la app.

Promedio de referencia del 23/10/2026: **1000,616 VES/USDT** (10 anuncios, entre 980,54 y
1003,998). La consulta con `tradeType: "SELL"` devuelve el otro lado del mercado (quien compra
USDT), alrededor de 1000,85; no se usa.

### 7.3 Restricciones de red

- Android únicamente: no hay problema de CORS.
- Timeout de conexión: 8 s. Timeout de respuesta: 10 s.
- Reintento único con espera de 500 ms solo para errores de red o 5xx.
- Sin reintentos para 4xx.
- Máximo una petición en vuelo por fuente; los refrescos se deduplican.
- Refresco manual limitado a uno cada 5 s.
- Todo el tráfico es HTTPS; no se requiere `usesCleartextTraffic`.

---

## 8. Arquitectura

### 8.1 Stack

| Capa | Elección |
|---|---|
| Framework | Flutter estable, Dart 3 |
| Estado | `flutter_riverpod` (Notifier/AsyncNotifier, sin generadores) |
| HTTP | `dio` |
| Persistencia | `shared_preferences` |
| Formato | `intl` |
| Enlaces | `url_launcher` |
| Compartir | `share_plus` + `path_provider` |
| Fuentes | Poppins en `assets/fonts/` |
| Tests | `flutter_test`, `mocktail` |

No se usan: `google_fonts`, `freezed`, `json_serializable`, `get_it`, `provider`, `bloc`,
`flutter_animate`, bases de datos ni analytics.

### 8.2 Estructura

```
lib/
  main.dart
  app.dart
  core/
    theme/
      colors.dart
      typography.dart
      app_theme.dart
      chamfer_clipper.dart
    format/
      money_format.dart
      relative_time.dart
  features/
    converter/
      domain/
        currency.dart
        rate_quote.dart
        conversion.dart
      data/
        dolar_api_client.dart
        binance_p2p_client.dart
        rate_repository.dart
        rate_cache.dart
      providers.dart
      presentation/
        converter_screen.dart
        share_text.dart
        sources_sheet.dart
        widgets/
          brand_header.dart
          currency_selector.dart
          swap_button.dart
          amount_field.dart
          result_readout.dart
          rate_caption.dart
          status_tag.dart
          currency_sheet.dart
          share_button.dart
  assets/
    branding/churupos-mark.png
    fonts/poppins-*.ttf
test/
  conversion_test.dart
  money_format_test.dart
  binance_average_test.dart
  rate_repository_test.dart
  converter_widget_test.dart
```

### 8.3 Piezas

**`Currency`** — enum con `code`, `label`, `symbol`, `source`.

**`ConversionService`** — funciones puras:

```dart
double convert(double amount, RateQuote from, RateQuote to);
double crossRate(RateQuote from, RateQuote to);
```

Sin estado, sin Flutter, 100 % testeable.

**`RateRepository`**
- `Future<RateSnapshot> fetchAll()`: lanza dolarapi y Binance en paralelo.
- Devuelve un snapshot parcial si una fuente falla.
- Persiste el último snapshot válido por fuente.
- Expone `loadCached()` para el arranque inmediato.

**`RatesNotifier`** (AsyncNotifier)
- Estado: `RatesState { quotes, fetchedAt, refreshing, errors }`.
- Al construir: carga caché → pinta → refresca en segundo plano.
- `refresh({bool manual = false})`.
- Timer de 5 min activo solo en foreground; al volver, refresca si el dato tiene más de 5 min.
- `WidgetsBindingObserver` para pausar/reanudar.

**`PairNotifier`**
- `from`, `to`, `amount`.
- Reglas de intercambio y de duplicados.
- Persistencia en `SharedPreferences`.

**`ConversionProvider`**
- Derivado puro: combina `RatesState` + `PairState` y devuelve el resultado formateado.

### 8.4 Contrato de error

```dart
enum RateError { network, timeout, badResponse, unavailable, empty }
```

- La UI nunca muestra excepciones ni códigos HTTP.
- Cada fuente conserva su propio error.
- El resultado se calcula si ambas monedas del par tienen tasa (aunque sea de caché).
- Si falta una tasa y no hay caché, el par queda deshabilitado con el texto
  “No hay tasa disponible”.

### 8.5 Caché

Clave `rates_snapshot_v1` en `SharedPreferences`:

```json
{
  "fetchedAt": "2026-10-23T09:41:00-04:00",
  "quotes": {
    "usd": { "vesPerUnit": 886.2271, "updatedAt": "2026-10-23T00:00:00-04:00" },
    "eur": { "vesPerUnit": 993.08836371, "updatedAt": "2026-10-23T00:00:00-04:00" },
    "usdt": { "vesPerUnit": 1000.616, "updatedAt": "2026-10-23T09:41:00-04:00" }
  }
}
```

- Se escribe solo tras una respuesta válida.
- Se descarta si el JSON no valida o si `vesPerUnit <= 0`.
- No expira por tiempo: se usa siempre, marcado como `stale`.

---

## 9. Marca y logo

### 9.1 Concepto

Monograma **“C”**, geométrico, con una esquina cortada y un trazo interior que insinúa dos
flechas opuestas (intercambio). Luz ultravioleta en el contorno y un filo ámbar en el interior.
Sin texto, sin mascota, sin monedas 3D.

### 9.2 Requisitos del asset

- Formato: PNG 512×512 (generado a 2K y reducido; fondo `#07060B` sólido).
- Fondo: `#07060B` sólido (la app no usa transparencia).
- Legible a 40×40 dp; sin detalles menores a 2 px en ese tamaño.
- Sin texto generado, sin mockups, sin marcos ni sombras de tarjeta.
- Paleta limitada a `#7C5CFF`, `#FFB020` y el fondo.
- Peso final < 300 KB.
- Ruta: `assets/branding/churupos-mark.png`.

### 9.3 Generación con `@images`

```powershell
node "C:\Users\DOSe\.config\opencode\scripts\image.mjs" `
  --prompt "Minimal cyberpunk monogram of the letter C, geometric chamfered ring, one diagonal cut, thin ultraviolet neon outline (#7C5CFF) with a warm amber inner edge (#FFB020), centered, flat vector style, solid near-black background (#07060B), no text, no letters other than the C, no mockup, no extra symbols, crisp edges, high contrast, app icon mark" `
  --out "assets/branding/churupos-mark.png" `
  --resolution 2K --ratio 1:1
```

Generar 3 variantes en llamadas separadas (la API de Google solo acepta `n: 1`) y elegir la que
siga legible a 40 dp. El wordmark “Churupos”
**no** forma parte de la imagen: se dibuja con Poppins en el header.

### 9.4 Uso

- Header: 40×40 dp + wordmark.
- Icono de lanzador Android: adaptativo, con el monograma al 60 % del área segura y fondo `void`.
- Splash: fondo `void`, monograma centrado, sin texto.
- No deformar, no rotar, no recolorear fuera de la paleta.

---

## 10. Contenido y tono

- Español de Venezuela, frases cortas, sin tecnicismos.
- Sentence case en todas las etiquetas.
- Nada de “Bienvenido”, “Descubre”, “Potencia tus finanzas” ni signos de admiración.
- La app habla de cifras, no de promesas.

Textos definitivos:

| Ubicación | Texto |
|---|---|
| Título de app | `Churupos` |
| Etiqueta de origen | `Desde` |
| Etiqueta de destino | `Hacia` |
| Etiqueta de monto | `Monto` |
| Etiqueta de resultado | `Equivale a` |
| Botón de actualización | `Actualizar` |
| Aviso de caché | `Sin conexión. Mostrando la última tasa guardada.` |
| Error total | `No pudimos cargar las tasas` |
| Acción de reintento | `Reintentar` |
| Pie | `¿De dónde salen estos valores?` |
| Compartir | `Compartir cálculo` |
| Crédito | `Hecho por isdose.com` |
| Moneda sin tasa | `Sin datos` |

El descargo de la hoja de fuentes es el texto de la sección 5.5 y no se acorta.

---

## 11. Accesibilidad

- Áreas táctiles mínimas de 48×48 dp.
- Contraste mínimo 4,5:1 en texto normal; 3:1 en texto grande.
- El resultado se anuncia con `Semantics(liveRegion: true)` al cambiar.
- Etiquetas semánticas: “Monto en dólares BCV”, “Convertir a bolívares”,
  “Intercambiar monedas”, “Abrir fuentes de las tasas”.
- El estado no depende solo del color: el aviso de caché lleva texto.
- Soporte de escalado de texto hasta 1,3; el resultado usa `FittedBox` para no romper.
- Animaciones desactivables por preferencia del sistema.
- Teclado: no se abre automáticamente al entrar; el foco es visible.

---

## 12. Rendimiento y calidad

- Arranque en frío < 2 s hasta ver la interfaz con caché.
- Primer resultado visible < 100 ms tras cargar caché.
- Conversión recalculada < 16 ms por pulsación.
- Sin llamadas de red con la app en background.
- Sin `setState` en la pantalla principal; todo por providers.
- Sin reconstrucciones del panel completo al escribir: solo el resultado y la tasa.
- Tamaño de APK razonable: sin assets pesados más allá del logo y las fuentes.

---

## 13. Pruebas

### Unitarias

- `conversion_test.dart`
  - Las 12 combinaciones de pares.
  - Identidad (`USD → USD` no ocurre en UI, pero el servicio devuelve el mismo monto).
  - Ida y vuelta con tolerancia `1e-9`.
  - Monto `0`, montos grandes (1e9) y resultados menores que `0,01`.
  - Tasas inválidas (`0`, negativas, `NaN`, infinito) lanzan o se rechazan.
- `money_format_test.dart`
  - `26586.813` → `Bs. 26.586,81`.
  - `30` USD → `$ 30,00`.
  - `-0.0` → `0,00`.
  - Entrada `30,5` y `30.5` producen el mismo valor.
  - Se descarta el tercer decimal.
- `binance_average_test.dart`
  - Fixture de 10 anuncios → promedio exacto.
  - Precios inválidos se filtran.
  - Menos de 3 válidos → error.
  - Respuesta vacía → error.
- `rate_repository_test.dart`
  - Ambas fuentes OK.
  - dolarapi OK + Binance KO → snapshot parcial.
  - Binance OK + dolarapi KO → snapshot parcial.
  - Ambas KO con caché → snapshot stale.
  - Caché corrupta → se ignora.
  - Timeout → `RateError.timeout`.
- `share_text_test.dart`
  - Incluye monto, resultado, tasa, nota y enlace.
  - Marca las tasas guardadas.
  - Sin líneas vacías al final.

### Widget

- Abre con el par por defecto y el resultado en `0,00`.
- Escribir `30` con USD→VES muestra `Bs. 26.586,81` con el fixture.
- Cambiar de moneda recalcula.
- Elegir la moneda del otro lado intercambia el par.
- El botón de intercambio invierte y conserva el monto.
- La hoja de fuentes muestra los dos enlaces y el descargo.
- El botón de compartir aparece bajo el panel y está deshabilitado sin monto.
- El texto de compartir contiene el cálculo y el enlace de descarga.
- Estado sin red con caché muestra el aviso ámbar y sigue calculando.
- Estado sin red sin caché muestra el error y deshabilita el cálculo.

### Manual

- Modo avión: abrir, convertir con caché, volver a con conexión.
- Bloquear el dominio de Binance: la app sigue con BCV y avisa.
- Cambiar hora/zona del dispositivo: las antigüedades siguen siendo coherentes.
- Fuente del sistema al 130 %.
- Animaciones reducidas activadas.

---

## 14. Criterios de aceptación

- [ ] La app abre en Android y muestra el logo, el par Dólar BCV → Bolívares y `0,00`.
- [ ] Escribir `30` con Dólar BCV → Bolívares muestra `Bs. 26.586,81` con las tasas del día.
- [ ] Los cuatro selectores muestran las cuatro monedas y sus tasas vigentes.
- [ ] El botón central intercambia el par y conserva el monto.
- [ ] Elegir la misma moneda en ambos lados intercambia en lugar de duplicar.
- [ ] El resultado se actualiza sin pulsar ningún botón.
- [ ] La tasa unitaria y la antigüedad son visibles sin abrir otra pantalla.
- [ ] El botón del pie abre la explicación con las dos fuentes, sus direcciones y el descargo.
- [ ] Compartir genera una captura del panel y un texto con la nota y el enlace
  `https://churupos.isdose.com`.
- [ ] Sin internet, la app abre con la última tasa y lo dice con la hora exacta.
- [ ] Si Binance falla, BCV sigue funcionando y la moneda USDT se marca como no disponible.
- [ ] El formato es venezolano aunque el teléfono esté en inglés.
- [ ] No hay claves, cuentas, analytics ni peticiones a dominios distintos de los dos documentados.
- [ ] Todos los tests pasan y no hay warnings de `flutter analyze`.
- [ ] La app se ve legible a pleno sol y con el brillo al mínimo razonable.

---

## 15. Riesgos y mitigaciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Binance cambia o bloquea el endpoint no oficial | No hay tasa USDT | Cliente aislado, caché, error por fuente, posibilidad de sustituir por proveedor con key |
| Binance devuelve anuncios atípicos | Promedio engañoso | Filtrar inválidos, exigir ≥ 3 ofertas y usar 10 para diluir extremos |
| dolarapi no responde | No hay BCV | Caché del día anterior + aviso; Binance sigue operando |
| El BCV no publica un día | Tasa vieja | Mostrar fecha real de actualización, no “hoy” |
| Red lenta al abrir | Mala primera impresión | Caché primero, refresco en segundo plano |
| Logo generado con ruido o texto | Marca sucia | Sin texto, 3 variantes, revisión a 40 dp, recrear en SVG si hace falta |
| Confusión USDT vs USD | Cálculo incorrecto | Etiquetas explícitas “Dólar BCV” y “Binance (USDT)” |

---

## 16. Orden de implementación

1. `flutter create` solo Android, tema, Poppins, paleta y estructura de carpetas.
2. Dominio: `Currency`, `RateQuote`, `ConversionService` + tests.
3. Formato de dinero y tiempo + tests.
4. Clientes de dolarapi y Binance + promedio + tests con fixtures.
5. Repositorio, caché y providers de Riverpod + tests.
6. Pantalla y componentes visuales (header, selectores, monto, resultado, tasa).
7. Hojas de moneda y de fuentes; estados de error y caché.
8. Animaciones, háptica y accesibilidad.
9. Logo con `@images` e integración de marca.
10. QA manual, `flutter analyze`, tests y build de release.

---

## 17. Definición de terminado

- Código en `D:\Projects\churupos`, compilando en release para Android.
- `flutter analyze` sin issues y `flutter test` en verde (51 tests).
- APK de prueba en `dist/churupos-1.0.0.apk`, firmado con clave de depuración.
- Los criterios de aceptación marcados.
- Sin secretos en el repositorio.
- `README.md` con cómo correr, cómo probar y de dónde salen las tasas.
- Captura de la pantalla principal y del estado sin conexión.
- El logo vive en `assets/branding/churupos-mark.png` y se ve nítido a 40 dp.
