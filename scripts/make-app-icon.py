#!/usr/bin/env python3
"""Draw the app icon (Resources/AppIcon.png, 1024x1024): an original retro TV set
with a warm glowing screen. Needs Pillow. Run: python3 scripts/make-app-icon.py"""
import math
import os
from PIL import Image, ImageDraw, ImageFilter

S = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "Resources", "AppIcon.png")


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(size[1]):
        draw.line([(0, y), (size[0], y)], fill=lerp(top, bottom, y / max(1, size[1] - 1)))
    return img


def main():
    icon = vertical_gradient((S, S), (40, 30, 26), (12, 10, 9))

    # Warm room glow behind the set.
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([152, 220, 872, 900], fill=(255, 160, 40, 120))
    icon.paste(glow.filter(ImageFilter.GaussianBlur(120)), (0, 0), glow.filter(ImageFilter.GaussianBlur(120)))

    draw = ImageDraw.Draw(icon)
    # Antennas.
    for angle in (-30, 26):
        rad = math.radians(angle)
        x0, y0 = 512, 300
        x1, y1 = x0 + math.sin(rad) * 230, y0 - math.cos(rad) * 230
        draw.line([(x0, y0), (x1, y1)], fill=(225, 214, 196), width=14)
        draw.ellipse([x1 - 16, y1 - 16, x1 + 16, y1 + 16], fill=(225, 214, 196))
    draw.ellipse([452, 270, 572, 330], fill=(30, 22, 18))

    # Cabinet: walnut with grain.
    cab = [150, 300, 874, 820]
    wood = vertical_gradient((cab[2] - cab[0], cab[3] - cab[1]), (150, 92, 46), (82, 46, 20))
    wd = ImageDraw.Draw(wood)
    seed = 7
    y = 10
    while y < wood.size[1]:
        seed = (seed * 37 + 11) % 97
        wd.line([(0, y), (wood.size[0], y + seed % 6)], fill=(70, 40, 18), width=2)
        y += 12 + seed % 9
    mask = Image.new("L", wood.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, wood.size[0] - 1, wood.size[1] - 1], radius=80, fill=255)
    icon.paste(wood, (cab[0], cab[1]), mask)

    # Screen with amber glow and scanlines.
    scr = [205, 355, 700, 765]
    sw, sh = scr[2] - scr[0], scr[3] - scr[1]
    screen = Image.new("RGB", (sw, sh))
    cx, cy = sw / 2, sh / 2
    px = screen.load()
    for yy in range(sh):
        for xx in range(sw):
            d = math.hypot((xx - cx) / (sw / 2), (yy - cy) / (sh / 2))
            t = min(1.0, d / 1.15)
            c = lerp((255, 214, 120), (255, 150, 30), min(1, t * 1.4)) if t < 0.7 else lerp((255, 150, 30), (40, 18, 6), (t - 0.7) / 0.3)
            if yy % 9 < 3:
                c = tuple(int(v * 0.78) for v in c)
            px[xx, yy] = c
    smask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(smask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=70, fill=255)
    draw.rounded_rectangle([scr[0] - 14, scr[1] - 14, scr[2] + 14, scr[3] + 14], radius=82, fill=(22, 14, 10))
    icon.paste(screen, (scr[0], scr[1]), smask)

    # Glass highlight.
    hl = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse([-sw * 0.2, -sh * 0.6, sw * 0.8, sh * 0.35], fill=(255, 255, 255, 50))
    hl_mask = Image.new("L", (sw, sh), 0)
    hl_mask.paste(smask, (0, 0))
    hl.putalpha(Image.composite(hl.getchannel("A"), Image.new("L", (sw, sh), 0), smask))
    icon.paste(hl, (scr[0], scr[1]), hl)

    draw = ImageDraw.Draw(icon)
    # Dials and speaker grille.
    for cyy in (430, 560):
        draw.ellipse([735, cyy - 48, 831, cyy + 48], fill=(205, 196, 182), outline=(60, 40, 25), width=6)
        draw.line([(783, cyy - 34), (783, cyy - 4)], fill=(50, 34, 22), width=10)
    for i in range(5):
        yy = 660 + i * 22
        draw.rounded_rectangle([740, yy, 826, yy + 9], radius=4, fill=(52, 30, 14))

    # Feet.
    draw.rounded_rectangle([230, 812, 330, 852], radius=14, fill=(30, 20, 14))
    draw.rounded_rectangle([694, 812, 794, 852], radius=14, fill=(30, 20, 14))

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    icon.save(OUT, "PNG")
    print("Wrote", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
