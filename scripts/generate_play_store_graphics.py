"""Genera gráficos profesionales para la ficha de Google Play Store.

Salidas en assets/play-store/:
  feature-graphic.png     1024 x 500
  screenshot-1-main.png   1080 x 1920
  screenshot-2-noads.png  1080 x 1920
  screenshot-3-sources.png 1080 x 1920
  screenshot-4-share.png  1080 x 1920

Uso:
    python scripts/generate_play_store_graphics.py
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "assets", "play-store")
FONTS_DIR = os.path.join(BASE, "assets", "fonts")
MARK_PATH = os.path.join(BASE, "assets", "branding", "churupos-mark.png")

# Paleta de la app
VOID = (7, 6, 11)
PANEL = (18, 16, 25)
RAISED = (25, 21, 39)
LINE = (43, 36, 64)
INK = (245, 241, 255)
MUTED = (154, 147, 179)
ULTRA = (124, 92, 255)
ULTRA_LIGHT = (168, 148, 255)
AMBER = (255, 176, 32)
MINT = (53, 224, 176)

SCREEN_W, SCREEN_H = 1080, 1920


# --------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------
def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(os.path.join(FONTS_DIR, name), size)


def radial_gradient(size, stops, center=(0.5, 0.5), radius=1.0) -> Image.Image:
    n = 160
    cx, cy = center
    small = Image.new("RGB", (n, n))
    for y in range(n):
        for x in range(n):
            d = math.hypot(x / (n - 1) - cx, y / (n - 1) - cy) / radius
            d = min(1.0, max(0.0, d))
            color = stops[-1][1]
            for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
                if d <= p1:
                    t = 0.0 if p1 == p0 else (d - p0) / (p1 - p0)
                    color = tuple(round(c0[i] + (c1[i] - c0[i]) * t) for i in range(3))
                    break
            small.putpixel((x, y), color)
    return small.resize(size, Image.LANCZOS)


def text_at(draw, xy, text, fnt, fill, anchor="la"):
    draw.text(xy, text, font=fnt, fill=fill, anchor=anchor)


def chamfer_poly(x, y, w, h, cut):
    return [
        (x + cut, y),
        (x + w, y),
        (x + w, y + h - cut),
        (x + w - cut, y + h),
        (x, y + h),
        (x, y + cut),
    ]


def chamfer_panel(draw, x, y, w, h, cut=40, fill=PANEL, outline=LINE, width=2):
    poly = chamfer_poly(x, y, w, h, cut)
    draw.polygon(poly, fill=fill)
    draw.line(poly + [poly[0]], fill=outline, width=width)


def arrow(draw, x1, y1, x2, y2, color, width=4, head=14):
    draw.line([(x1, y1), (x2, y2)], fill=color, width=width)
    dx, dy = x2 - x1, y2 - y1
    length = math.hypot(dx, dy)
    if length == 0:
        return
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    p1 = (x2 - ux * head + px * head * 0.55, y2 - uy * head + py * head * 0.55)
    p2 = (x2 - ux * head - px * head * 0.55, y2 - uy * head - py * head * 0.55)
    draw.polygon([(x2, y2), p1, p2], fill=color)


def swap_icon(draw, cx, cy, size, color):
    half = size * 0.5
    gap = size * 0.18
    arrow(draw, cx - half, cy - gap, cx + half, cy - gap, color, width=max(2, size // 9), head=size // 4)
    arrow(draw, cx + half, cy + gap, cx - half, cy + gap, color, width=max(2, size // 9), head=size // 4)


def paste_glow(canvas, xy, radius, color, strength=70):
    """Resplandor radial suave detrás de un elemento."""
    x, y = xy
    w = h = radius * 2
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    steps = 26
    for i in range(steps, 0, -1):
        r = radius * i / steps
        alpha = int(strength * (1 - i / steps) ** 1.6)
        gd.ellipse([w / 2 - r, h / 2 - r, w / 2 + r, h / 2 + r], fill=color + (alpha,))
    glow = glow.filter(ImageFilter.GaussianBlur(radius * 0.16))
    canvas.alpha_composite(glow, (int(x - radius), int(y - radius)))


# --------------------------------------------------------------------------
# Pantallas de la app (1080 x 1920)
# --------------------------------------------------------------------------
def app_background() -> Image.Image:
    bg = radial_gradient(
        (SCREEN_W, SCREEN_H),
        [(0.0, (32, 26, 52)), (0.55, (15, 12, 23)), (1.0, VOID)],
        center=(0.30, 0.16),
        radius=1.1,
    ).convert("RGBA")
    return bg


def app_header(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    mark = Image.open(MARK_PATH).convert("RGBA").resize((66, 66), Image.LANCZOS)
    canvas.alpha_composite(mark, (60, 78))
    text_at(draw, (144, 88), "Churupos", font("Poppins-SemiBold.ttf", 40), INK)
    text_at(draw, (SCREEN_W - 60, 108), "Actualizar", font("Poppins-Medium.ttf", 26), MUTED, anchor="ra")


def currency_selector(draw, x, y, w, code, name, active=False):
    h = 128
    cut = 26
    poly = chamfer_poly(x, y, w, h, cut)
    draw.polygon(poly, fill=RAISED if active else PANEL)
    draw.line(poly + [poly[0]], fill=ULTRA if active else LINE, width=3 if active else 2)
    text_at(draw, (x + 30, y + 24), code, font("Poppins-Bold.ttf", 54), INK)
    text_at(draw, (x + 30, y + 86), name, font("Poppins-Regular.ttf", 23), MUTED)


def app_main() -> Image.Image:
    canvas = app_background()
    draw = ImageDraw.Draw(canvas)
    app_header(canvas)

    px, py, pw, ph = 60, 220, 960, 840
    chamfer_panel(draw, px, py, pw, ph)

    text_at(draw, (px + 50, py + 52), "Monto", font("Poppins-Regular.ttf", 25), MUTED)
    text_at(draw, (px + 50, py + 96), "30,00 USD", font("Poppins-SemiBold.ttf", 76), INK)

    currency_selector(draw, px + 50, py + 226, 420, "USD", "Dólar BCV", active=True)
    currency_selector(draw, px + pw - 470, py + 226, 420, "VES", "Bolívar")

    # Botón de intercambio
    scx, scy = px + pw / 2, py + 420
    draw.regular_polygon((scx, scy, 42), n_sides=6, fill=RAISED, outline=ULTRA, width=3)
    swap_icon(draw, scx, scy, 44, ULTRA)

    text_at(draw, (px + 50, py + 500), "Resultado", font("Poppins-Regular.ttf", 25), MUTED)
    text_at(draw, (px + 50, py + 540), "Bs. 26.586,81", font("Poppins-Bold.ttf", 104), AMBER)
    text_at(draw, (px + 50, py + 712), "1 USD = Bs. 886,23  ·  hoy 14:35",
            font("Poppins-Medium.ttf", 27), MUTED)

    draw.ellipse([(px + 50, py + 766), (px + 68, py + 784)], fill=MINT)
    text_at(draw, (px + 84, py + 758), "Tasa actualizada", font("Poppins-Medium.ttf", 27), MUTED)

    # Botón compartir
    bx, by, bw, bh = 60, 1110, 960, 120
    chamfer_panel(draw, bx, by, bw, bh, cut=30, fill=RAISED, outline=LINE)
    text_at(draw, (bx + bw / 2, by + bh / 2), "Compartir cálculo",
            font("Poppins-SemiBold.ttf", 34), INK, anchor="mm")

    # Pie
    text_at(draw, (SCREEN_W / 2, 1738), "De dónde salen estos valores",
            font("Poppins-Medium.ttf", 27), MUTED, anchor="mm")
    text_at(draw, (SCREEN_W / 2, 1792), "Hecho por isdose.com",
            font("Poppins-Regular.ttf", 23), (120, 114, 142), anchor="mm")
    return canvas


def app_noads() -> Image.Image:
    canvas = app_background()
    draw = ImageDraw.Draw(canvas)
    app_header(canvas)

    px, py, pw, ph = 60, 300, 960, 560
    chamfer_panel(draw, px, py, pw, ph)
    text_at(draw, (px + 50, py + 60), "Resultado", font("Poppins-Regular.ttf", 25), MUTED)
    text_at(draw, (px + 50, py + 104), "Bs. 26.586,81", font("Poppins-Bold.ttf", 100), AMBER)
    text_at(draw, (px + 50, py + 268), "30,00 USD", font("Poppins-SemiBold.ttf", 54), INK)
    text_at(draw, (px + 50, py + 350), "1 USD = Bs. 886,23", font("Poppins-Medium.ttf", 30), MUTED)
    text_at(draw, (px + 50, py + 408), "hoy 14:35", font("Poppins-Medium.ttf", 30), MUTED)

    # Sello grande
    bx, by, bw, bh = 60, 990, 960, 150
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=26, fill=ULTRA)
    text_at(draw, (bx + bw / 2, by + bh / 2), "SIN PUBLICIDAD",
            font("Poppins-Bold.ttf", 54), INK, anchor="mm")

    text_at(draw, (SCREEN_W / 2, 1230), "Sin banners. Sin videos forzados.",
            font("Poppins-SemiBold.ttf", 40), INK, anchor="mm")
    text_at(draw, (SCREEN_W / 2, 1300), "Solo abres, calculas y listo.",
            font("Poppins-Regular.ttf", 32), MUTED, anchor="mm")

    text_at(draw, (SCREEN_W / 2, 1738), "De dónde salen estos valores",
            font("Poppins-Medium.ttf", 27), MUTED, anchor="mm")
    text_at(draw, (SCREEN_W / 2, 1792), "Hecho por isdose.com",
            font("Poppins-Regular.ttf", 23), (120, 114, 142), anchor="mm")
    return canvas


def app_sources() -> Image.Image:
    canvas = app_background()
    draw = ImageDraw.Draw(canvas)
    app_header(canvas)

    # Fondo atenuado detrás de la hoja inferior
    dim = Image.new("RGBA", canvas.size, (0, 0, 0, 115))
    canvas.alpha_composite(dim)

    hx, hy, hw, hh = 40, 360, 1000, 1500
    draw.rounded_rectangle([hx, hy, hx + hw, hy + hh], radius=44, fill=RAISED)
    # Asa
    draw.rounded_rectangle([SCREEN_W / 2 - 50, hy + 22, SCREEN_W / 2 + 50, hy + 32],
                           radius=5, fill=LINE)

    text_at(draw, (hx + 56, hy + 86), "De dónde salen estos valores",
            font("Poppins-SemiBold.ttf", 44), INK)
    text_at(draw, (hx + 56, hy + 152), "Cada tasa tiene una fuente y una hora.",
            font("Poppins-Regular.ttf", 26), MUTED)

    items = [
        ("Dólar BCV", "Banco Central de Venezuela via dolarapi.com"),
        ("Euro BCV", "Banco Central de Venezuela via dolarapi.com"),
        ("USDT Binance", "Promedio P2P de Binance (10 ofertas)"),
    ]
    y = hy + 240
    for name, desc in items:
        draw.ellipse([(hx + 58, y + 6), (hx + 80, y + 28)], fill=MINT)
        text_at(draw, (hx + 100, y - 4), name, font("Poppins-SemiBold.ttf", 30), INK)
        text_at(draw, (hx + 100, y + 44), desc, font("Poppins-Regular.ttf", 25), MUTED)
        draw.line([(hx + 56, y + 100), (hx + hw - 56, y + 100)], fill=LINE, width=1)
        y += 136

    text_at(draw, (hx + 56, y + 34), "Churupos no fija ni vende divisas.",
            font("Poppins-Medium.ttf", 28), MUTED)
    text_at(draw, (hx + 56, y + 82), "Los valores son referenciales.",
            font("Poppins-Regular.ttf", 25), MUTED)

    # Bloque de cierre
    box_y = hy + hh - 300
    draw.rounded_rectangle([hx + 56, box_y, hx + hw - 56, box_y + 220], radius=26,
                           fill=PANEL, outline=LINE, width=1)
    text_at(draw, (hx + 88, box_y + 38), "Transparencia total",
            font("Poppins-SemiBold.ttf", 38), INK)
    text_at(draw, (hx + 88, box_y + 96), "Sabes de dónde viene cada tasa.",
            font("Poppins-Regular.ttf", 27), MUTED)
    text_at(draw, (hx + 88, box_y + 150), "Sin letra pequeña.",
            font("Poppins-Regular.ttf", 27), MUTED)
    return canvas


def app_share() -> Image.Image:
    canvas = app_background()
    draw = ImageDraw.Draw(canvas)
    app_header(canvas)

    px, py, pw, ph = 60, 240, 960, 760
    chamfer_panel(draw, px, py, pw, ph)
    text_at(draw, (px + 60, py + 70), "Bs. 26.586,81", font("Poppins-Bold.ttf", 96), AMBER)
    text_at(draw, (px + 60, py + 230), "30,00 USD a VES", font("Poppins-SemiBold.ttf", 34), INK)
    text_at(draw, (px + 60, py + 292), "1 USD = Bs. 886,23", font("Poppins-Medium.ttf", 30), MUTED)
    text_at(draw, (px + 60, py + 342), "hoy 14:35", font("Poppins-Medium.ttf", 30), MUTED)

    tx, ty, tw, th = px + 60, py + 440, pw - 120, 230
    draw.rounded_rectangle([tx, ty, tx + tw, ty + th], radius=20, fill=RAISED, outline=LINE, width=1)
    text_at(draw, (tx + 34, ty + 34), "30,00 USD = Bs. 26.586,81",
            font("Poppins-Regular.ttf", 26), INK)
    text_at(draw, (tx + 34, ty + 80), "1 USD = Bs. 886,23 · hoy 14:35",
            font("Poppins-Regular.ttf", 26), MUTED)
    text_at(draw, (tx + 34, ty + 150), "Calculado con Churupos...",
            font("Poppins-Regular.ttf", 26), MUTED)

    text_at(draw, (SCREEN_W / 2, py + ph + 110), "Comparte el cálculo en segundos",
            font("Poppins-SemiBold.ttf", 46), INK, anchor="mm")
    text_at(draw, (SCREEN_W / 2, py + ph + 180), "Imagen + texto listo para enviar.",
            font("Poppins-Regular.ttf", 32), MUTED, anchor="mm")

    text_at(draw, (SCREEN_W / 2, 1738), "De dónde salen estos valores",
            font("Poppins-Medium.ttf", 27), MUTED, anchor="mm")
    text_at(draw, (SCREEN_W / 2, 1792), "Hecho por isdose.com",
            font("Poppins-Regular.ttf", 23), (120, 114, 142), anchor="mm")
    return canvas


# --------------------------------------------------------------------------
# Mockup de teléfono
# --------------------------------------------------------------------------
def phone_mockup(content: Image.Image, screen_w: int = 640) -> Image.Image:
    """Envuelve una pantalla 9:16 en un marco de teléfono con sombra."""
    screen_h = round(content.height * screen_w / content.width)
    screen = content.resize((screen_w, screen_h), Image.LANCZOS)

    pad = 20
    outer_w, outer_h = screen_w + pad * 2, screen_h + pad * 2
    margin = 90

    canvas = Image.new("RGBA", (outer_w + margin * 2, outer_h + margin * 2), (0, 0, 0, 0))

    # Sombra difusa
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [margin, margin + 18, margin + outer_w, margin + outer_h + 18],
        radius=62, fill=(2, 1, 5, 190),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(46))
    canvas.alpha_composite(shadow)

    # Cuerpo del teléfono
    frame = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle(
        [margin, margin, margin + outer_w, margin + outer_h],
        radius=62, fill=(11, 9, 16, 255),
    )
    fd.rounded_rectangle(
        [margin + 6, margin + 6, margin + outer_w - 6, margin + outer_h - 6],
        radius=56, outline=(46, 39, 66, 255), width=2,
    )
    canvas.alpha_composite(frame)

    # Pantalla
    canvas.paste(screen, (margin + pad, margin + pad))

    # Notch
    nd = ImageDraw.Draw(canvas)
    nd.rounded_rectangle(
        [margin + outer_w / 2 - 74, margin + pad + 12,
         margin + outer_w / 2 + 74, margin + pad + 34],
        radius=11, fill=(5, 4, 8, 255),
    )
    return canvas


# --------------------------------------------------------------------------
# Composiciones de marketing
# --------------------------------------------------------------------------
def marketing_screenshot(eyebrow: str, lines: list[str], caption: str,
                          screen: Image.Image, eyebrow_color=ULTRA_LIGHT) -> Image.Image:
    canvas = radial_gradient(
        (SCREEN_W, SCREEN_H),
        [(0.0, (34, 27, 58)), (0.45, (16, 13, 25)), (1.0, (5, 4, 8))],
        center=(0.22, 0.10), radius=1.05,
    ).convert("RGBA")

    # Resplandores de ambiente
    paste_glow(canvas, (960, 120), 360, ULTRA, strength=64)
    paste_glow(canvas, (120, 1760), 320, (88, 55, 232), strength=52)

    draw = ImageDraw.Draw(canvas)

    # Eyebrow
    text_at(draw, (SCREEN_W / 2, 96), eyebrow.upper(), font("Poppins-SemiBold.ttf", 26),
            eyebrow_color, anchor="mm")

    # Titular
    headline_font = font("Poppins-Bold.ttf", 82)
    y = 140
    for line in lines:
        text_at(draw, (SCREEN_W / 2, y), line, headline_font, INK, anchor="ma")
        y += 96

    # Teléfono
    mock = phone_mockup(screen, screen_w=640)
    mock_x = (SCREEN_W - mock.width) // 2
    mock_y = 372
    canvas.alpha_composite(mock, (mock_x, mock_y))

    # Pie
    text_at(draw, (SCREEN_W / 2, 1690), caption, font("Poppins-Regular.ttf", 30),
            MUTED, anchor="mm")

    # Detalle de marca
    text_at(draw, (SCREEN_W / 2, 1760), "CHURUPOS", font("Poppins-SemiBold.ttf", 20),
            (120, 114, 142), anchor="mm")
    return canvas


def feature_graphic() -> Image.Image:
    w, h = 1024, 500
    canvas = radial_gradient(
        (w, h),
        [(0.0, (36, 29, 60)), (0.55, (15, 12, 23)), (1.0, VOID)],
        center=(0.28, 0.16), radius=1.15,
    ).convert("RGBA")
    paste_glow(canvas, (120, 90), 300, ULTRA, strength=58)
    draw = ImageDraw.Draw(canvas)

    # Logo
    mark = Image.open(MARK_PATH).convert("RGBA").resize((310, 310), Image.LANCZOS)
    canvas.alpha_composite(mark, (58, 95))

    x = 430
    text_at(draw, (x, 78), "Churupos", font("Poppins-Bold.ttf", 70), INK)
    text_at(draw, (x, 166), "Calculadora de cambio", font("Poppins-Medium.ttf", 35), INK)
    text_at(draw, (x, 210), "para Venezuela", font("Poppins-Medium.ttf", 35), INK)

    # Sello sin publicidad (texto centrado dentro del sello)
    bx, by, bw, bh = x, 292, 300, 48
    draw.rounded_rectangle([bx, by, bx + bw, by + bh], radius=10, fill=ULTRA)
    text_at(draw, (bx + bw / 2, by + bh / 2), "SIN PUBLICIDAD",
            font("Poppins-SemiBold.ttf", 21), INK, anchor="mm")
    text_at(draw, (x, 356), "Fácil de usar · Sin anuncios",
            font("Poppins-Regular.ttf", 21), MUTED)
    return canvas


# --------------------------------------------------------------------------
def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    feature_graphic().convert("RGB").save(os.path.join(OUT_DIR, "feature-graphic.png"))

    shots = [
        ("screenshot-1-main.png", "Sin cuentas · Sin registro",
         ["Cambia divisas", "en segundos"], "USD, EUR y USDT en una sola pantalla.", app_main()),
        ("screenshot-2-noads.png", "Cero anuncios",
         ["Sin publicidad.", "Sin distracciones."], "Solo abres, calculas y listo.", app_noads()),
        ("screenshot-3-sources.png", "Transparencia total",
         ["Cada tasa,", "con su fuente"], "BCV y Binance P2P, con hora de actualización.", app_sources()),
        ("screenshot-4-share.png", "Listo para enviar",
         ["Comparte tu", "cálculo"], "Imagen + texto con la tasa y la hora.", app_share()),
    ]
    for name, eyebrow, lines, caption, screen in shots:
        marketing_screenshot(eyebrow, lines, caption, screen).convert("RGB").save(
            os.path.join(OUT_DIR, name))

    print("play store graphics ->", OUT_DIR)


if __name__ == "__main__":
    main()
