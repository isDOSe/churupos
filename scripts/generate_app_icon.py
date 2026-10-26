"""Genera los PNG de marca e iconos de Churupos.

Dibuja la marca (anillo "C" violeta + rayo ámbar) por geometría pura y la
compone sobre los distintos lienzos que necesita Android:

  assets/branding/churupos-mark.png          tile de la app (header in-app)
  assets/branding/app-icon-legacy.png        icono legacy (fondo a sangre)
  assets/branding/app-icon-foreground.png    capa foreground adaptativa
  assets/branding/app-icon-background.png    capa background adaptativa
  assets/branding/app-icon-monochrome.png    icono temático (Android 13+)

Uso:
    python scripts/generate_app_icon.py            # escribe los assets
    python scripts/generate_app_icon.py --preview  # solo previews en .preview/
"""

from __future__ import annotations

import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(BASE, "assets", "branding")
PREVIEW_DIR = os.path.join(BASE, ".preview")

OUT = 1024          # tamaño final de cada PNG
SS = 3              # supersampling
S = OUT * SS

# --- Paleta de marca ------------------------------------------------------
VOID = (7, 6, 11)
ULTRA = (124, 92, 255)
AMBER = (255, 176, 32)

PURPLE_STOPS = [(0.0, (168, 148, 255)), (0.45, (124, 92, 255)), (1.0, (88, 55, 232))]
AMBER_STOPS = [(0.0, (255, 214, 110)), (0.55, (255, 176, 32)), (1.0, (255, 152, 24))]


# --- Utilidades -----------------------------------------------------------
def _sample(stops, u: float):
    u = min(1.0, max(0.0, u))
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        if u <= p1:
            t = 0.0 if p1 == p0 else (u - p0) / (p1 - p0)
            return tuple(round(c0[i] + (c1[i] - c0[i]) * t) for i in range(3))
    return stops[-1][1]


def linear_gradient(size: int, stops, angle_deg: float) -> Image.Image:
    """Degradado lineal suave (se calcula a 128px y se escala)."""
    n = 128
    a = math.radians(angle_deg)
    dx, dy = math.cos(a), math.sin(a)
    small = Image.new("RGB", (n, n))
    px = small.load()
    for y in range(n):
        fy = y / (n - 1) - 0.5
        for x in range(n):
            u = (x / (n - 1) - 0.5) * dx + fy * dy + 0.5
            px[x, y] = _sample(stops, u)
    return small.resize((size, size), Image.LANCZOS)


def radial_gradient(size: int, stops, center=(0.5, 0.5), radius=1.0) -> Image.Image:
    n = 128
    cx, cy = center
    small = Image.new("RGB", (n, n))
    px = small.load()
    for y in range(n):
        for x in range(n):
            d = math.hypot(x / (n - 1) - cx, y / (n - 1) - cy) / radius
            px[x, y] = _sample(stops, d)
    return small.resize((size, size), Image.LANCZOS)


def rounded_mask(size: int, ratio: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=size * ratio, fill=255
    )
    return mask


# --- Marca ----------------------------------------------------------------
def ring_mask(size: int, box: float, stroke: float, gap_half: float) -> Image.Image:
    """Anillo "C" con extremos redondeados y abertura a la derecha."""
    c = size / 2
    r_out = box / 2
    thick = stroke * box
    r_in = r_out - thick
    r_mid = (r_out + r_in) / 2

    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    start, end = gap_half, 360 - gap_half
    draw.pieslice([c - r_out, c - r_out, c + r_out, c + r_out], start, end, fill=255)
    draw.pieslice([c - r_in, c - r_in, c + r_in, c + r_in], start, end, fill=0)
    for ang in (gap_half, -gap_half):
        a = math.radians(ang)
        x, y = c + r_mid * math.cos(a), c + r_mid * math.sin(a)
        draw.ellipse([x - thick / 2, y - thick / 2, x + thick / 2, y + thick / 2], fill=255)
    return mask


BOLT_PTS = [
    (0.56, 0.00),
    (0.02, 0.60),
    (0.41, 0.60),
    (0.33, 1.00),
    (0.98, 0.38),
    (0.57, 0.38),
]


def bolt_mask(size: int, cx: float, cy: float, w: float, h: float,
              rotation: float = 0.0) -> Image.Image:
    """Rayo con esquinas ligeramente suavizadas."""
    a = math.radians(rotation)
    cos_a, sin_a = math.cos(a), math.sin(a)
    poly = []
    for x, y in BOLT_PTS:
        dx, dy = (x - 0.5) * w, (y - 0.5) * h
        poly.append((cx + dx * cos_a - dy * sin_a, cy + dx * sin_a + dy * cos_a))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(size * 0.0055))
    return mask.point(lambda v: 255 if v >= 118 else 0)


def render_mark(size: int, box: float, gap_half: float = 52.0, stroke: float = 0.20,
                bolt_scale: float = 1.18, bolt_x: float = 0.012, bolt_y: float = 0.0,
                bolt_rotation: float = 0.0) -> Image.Image:
    """Marca completa (anillo + rayo) centrada en un lienzo transparente."""
    c = size / 2
    mark = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mark.paste(linear_gradient(size, PURPLE_STOPS, 45), (0, 0),
               ring_mask(size, box, stroke=stroke, gap_half=gap_half))

    boltw = box * 0.255 * bolt_scale
    bolth = box * 0.395 * bolt_scale
    mark.paste(linear_gradient(size, AMBER_STOPS, 75), (0, 0),
               bolt_mask(size, c + box * bolt_x, c + box * bolt_y, boltw, bolth,
                         bolt_rotation))
    return mark


def add_soft_shadow(canvas: Image.Image, mark: Image.Image, blur: float, offset: float,
                    opacity: float, color=(4, 3, 8)) -> None:
    alpha = mark.getchannel("A").filter(ImageFilter.GaussianBlur(blur))
    if opacity < 1.0:
        alpha = alpha.point(lambda v: int(v * opacity))
    shadow = Image.new("RGBA", canvas.size, color + (0,))
    shadow.putalpha(alpha)
    canvas.alpha_composite(shadow, (0, int(offset)))


# --- Composiciones --------------------------------------------------------
MARK_TILE = 0.63
MARK_ADAPTIVE = 0.55


def build_tile() -> Image.Image:
    """Tile cuadrado con esquinas redondeadas: marca dentro de la app."""
    bg_stops = [(0.0, (30, 24, 48)), (0.55, (16, 13, 24)), (1.0, (9, 8, 14))]
    bg = radial_gradient(S, bg_stops, center=(0.32, 0.22), radius=1.15).convert("RGBA")

    mark = render_mark(S, S * MARK_TILE)
    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    add_soft_shadow(canvas, mark, blur=S * 0.022, offset=S * 0.010, opacity=0.55)
    canvas.alpha_composite(bg)
    canvas.alpha_composite(mark)

    tile = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    tile.paste(canvas, (0, 0), rounded_mask(S, 0.225))
    return tile


def build_legacy() -> Image.Image:
    """Icono clásico: fondo a sangre completa (sin transparencia)."""
    bg = radial_gradient(S, [(0.0, (34, 27, 56)), (0.6, (14, 12, 21)), (1.0, (7, 6, 11))],
                         center=(0.36, 0.24), radius=1.2).convert("RGBA")
    canvas = Image.new("RGBA", (S, S), VOID + (255,))
    canvas.alpha_composite(bg)

    mark = render_mark(S, S * MARK_TILE)
    add_soft_shadow(canvas, mark, blur=S * 0.026, offset=S * 0.012, opacity=0.6)
    canvas.alpha_composite(mark)
    return canvas


def build_foreground() -> Image.Image:
    """Capa adaptativa: marca al 55% del lienzo (dentro de la zona segura)."""
    return render_mark(S, S * MARK_ADAPTIVE)


def build_background() -> Image.Image:
    bg = radial_gradient(S, [(0.0, (30, 24, 50)), (0.62, (12, 10, 18)), (1.0, VOID)],
                         center=(0.38, 0.26), radius=1.25)
    return bg.convert("RGBA")


def build_monochrome() -> Image.Image:
    """Silueta blanca para iconos temáticos de Android 13+."""
    mark = render_mark(S, S * MARK_ADAPTIVE)
    mono = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    mono.putalpha(mark.getchannel("A"))
    return mono


def _adaptive_preview(canvas: Image.Image, px: int, shape: str) -> Image.Image:
    """Simula el recorte real de un icono adaptativo (zona visible 72/108)."""
    w = int(canvas.width * 72 / 108)
    off = (canvas.width - w) // 2
    visible = canvas.crop((off, off, off + w, off + w)).resize((px, px), Image.LANCZOS)
    mask = Image.new("L", (px * 4, px * 4), 0)
    d = ImageDraw.Draw(mask)
    if shape == "circle":
        d.ellipse([0, 0, px * 4 - 1, px * 4 - 1], fill=255)
    elif shape == "squircle":
        d.rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=px * 1.05, fill=255)
    else:
        d.rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=px * 0.62, fill=255)
    mask = mask.resize((px, px), Image.LANCZOS)
    out = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    out.paste(visible, (0, 0), mask)
    return out


def main() -> None:
    preview = "--preview" in sys.argv
    os.makedirs(OUT_DIR, exist_ok=True)

    legacy = build_legacy()
    tile = build_tile()
    bg = build_background()
    fg = build_foreground()
    mono = build_monochrome()

    if preview:
        os.makedirs(PREVIEW_DIR, exist_ok=True)
        adaptive = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        adaptive.alpha_composite(bg)
        adaptive.alpha_composite(fg)

        sheet = Image.new("RGBA", (1560, 700), (58, 56, 68, 255))
        x = 40
        for shape in ("rounded", "squircle", "circle"):
            sheet.alpha_composite(_adaptive_preview(adaptive, 240, shape), (x, 40))
            x += 300
        sheet.alpha_composite(legacy.resize((240, 240), Image.LANCZOS), (x, 40))
        sheet.alpha_composite(_adaptive_preview(
            Image.composite(mono, Image.new("RGBA", (S, S), (0, 0, 0, 0)), mono), 240,
            "circle"), (40, 360))
        sheet.alpha_composite(tile.resize((240, 240), Image.LANCZOS), (340, 360))
        # tamaños reales de launcher / header
        mark_small = render_mark(S, S * MARK_TILE)
        for i, px in enumerate((48, 64, 96)):
            sheet.alpha_composite(mark_small.resize((px, px), Image.LANCZOS),
                                  (640 + i * 120, 380))
            sheet.alpha_composite(legacy.resize((px, px), Image.LANCZOS),
                                  (640 + i * 120, 500))
        sheet.convert("RGB").save(os.path.join(PREVIEW_DIR, "final-sheet.png"))
        print("previews ->", PREVIEW_DIR)
        return

    tile.resize((OUT, OUT), Image.LANCZOS).save(os.path.join(OUT_DIR, "churupos-mark.png"))
    legacy.convert("RGB").resize((OUT, OUT), Image.LANCZOS).save(
        os.path.join(OUT_DIR, "app-icon-legacy.png"))
    fg.resize((OUT, OUT), Image.LANCZOS).save(
        os.path.join(OUT_DIR, "app-icon-foreground.png"))
    bg.resize((OUT, OUT), Image.LANCZOS).save(
        os.path.join(OUT_DIR, "app-icon-background.png"))
    mono.resize((OUT, OUT), Image.LANCZOS).save(
        os.path.join(OUT_DIR, "app-icon-monochrome.png"))
    print("assets ->", OUT_DIR)


if __name__ == "__main__":
    main()
