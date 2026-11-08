#!/usr/bin/env python3
"""Gera todos os sprites de pixel art do FMF (determinístico).

Uso: python3 tools/gen_sprites.py
Saída em assets/sprites/.
"""
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

# Paleta (estilo Hero Tale: terroso + destaques saturados)
PAL = {
    ".": None,
    "o": (34, 32, 52, 255),      # contorno
    "h": (40, 38, 50, 255),      # cabelo preto
    "H": (72, 70, 92, 255),      # brilho do cabelo
    "s": (244, 204, 161, 255),   # pele
    "S": (217, 160, 102, 255),   # sombra da pele
    "w": (255, 255, 255, 255),   # branco do olho
    "e": (48, 44, 64, 255),      # pupila
    "r": (208, 70, 72, 255),     # camisa vermelha
    "R": (158, 48, 58, 255),     # sombra da camisa
    "b": (138, 94, 60, 255),     # calça marrom
    "B": (104, 68, 44, 255),     # sombra da calça
    "k": (64, 58, 74, 255),      # tênis
    "c": (255, 236, 214, 255),   # cicatriz clara
    "g": (170, 170, 184, 255),   # lâmina (cinza claro)
    "G": (120, 120, 138, 255),   # lâmina sombra
    "y": (255, 214, 72, 255),    # dourado (punho/moeda)
    "Y": (214, 150, 32, 255),    # dourado escuro
    "m": (222, 158, 80, 255),    # corpo do ciclope
    "M": (170, 110, 58, 255),    # sombra do ciclope
    "d": (255, 92, 92, 255),     # detalhe vermelho vivo
    "t": (92, 64, 40, 255),      # chifre/garras
}


def draw_map(lines, cell=None, offset=(0, 0)):
    h = len(lines)
    w = max(len(l) for l in lines)
    img = Image.new("RGBA", cell if cell else (w, h), (0, 0, 0, 0))
    ox, oy = offset
    for y, row in enumerate(lines):
        for x, ch in enumerate(row):
            col = PAL.get(ch)
            if col:
                img.putpixel((x + ox, y + oy), col)
    return img


# ---------------------------------------------------------------- Zack
HEAD = [
    "....oooooo......",
    "...ohhhhhho.....",
    "..ohhHhhhhho....",
    "..ohhHhhhhho....",
    "..ohhhhhhhho....",
    "..ohsssssso.....",
    "..ohswsewso.....",
    "..ohsssssso.....",
    "...oSssssSo.....",
    "....osssso......",
]

TORSO = [
    "...oorrrroo.....",
    "..orrrrrrrro....",
    ".osrrrrrrrrso...",
    ".oscrRRRRrsso...",
    "..oorRRRRroo....",
    "...orrrrrro.....",
]

TORSO_ATK1 = [  # braço recuado para trás (antecipação)
    "...oorrrroos....",
    "..orrrrrrroso...",
    ".osrrrrrrroo....",
    ".oscrRRRRro.....",
    "..oorRRRRro.....",
    "...orrrrrro.....",
]

TORSO_ATK2 = [  # braço estendido à frente (golpe)
    "...oorrrroo.....",
    "..orrrrrrrrss...",
    ".osrrrrrrrroo...",
    ".oscrRRRRro.....",
    "..oorRRRRro.....",
    "...orrrrrro.....",
]

LEGS_IDLE = [
    "...obbbbbo......",
    "...obbbbbo......",
    "...obbBbbo......",
    "...obo.obo......",
    "...obo.obo......",
    "...oko.oko......",
    "..okko.okko.....",
    "...oo...oo......",
]

LEGS_IDLE2 = LEGS_IDLE  # idle 2 muda só o torso (respiração)

LEGS_RUN1 = [
    "...obbbbbo......",
    "...obbbbbo......",
    "...obBbBbo......",
    "..obo...obo.....",
    ".obo.....obo....",
    ".oko.....oko....",
    "okko.....okko...",
    ".oo.......oo....",
]

LEGS_RUN2 = [
    "...obbbbbo......",
    "...obbbbbo......",
    "...obBbBbo......",
    "...obo.obo......",
    "...obo..obo.....",
    "...oko..oko.....",
    "..okko..okko....",
    "...oo....oo.....",
]

LEGS_RUN3 = [
    "...obbbbbo......",
    "...obbbbbo......",
    "...obBbBbo......",
    "..obbo.obo......",
    "..obo...obo.....",
    "..oko...okko....",
    ".okko....oo.....",
    "..oo............",
]

LEGS_RUN4 = LEGS_RUN2

LEGS_JUMP = [
    "...obbbbbo......",
    "...obbbbbo......",
    "...obBbBbo......",
    "..obbo.obbo.....",
    "..okko.okko.....",
    "...oo...oo......",
    "................",
    "................",
]


def zack_frame(torso, legs, sword=None):
    cell = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    body = draw_map(HEAD + torso + legs)
    cell.alpha_composite(body, (8, 8))
    d = ImageDraw.Draw(cell)
    if sword == "up":      # espada erguida para trás (diagonal)
        for i in range(6):
            cell.putpixel((26 - i, 10 + i), PAL["g"])
            cell.putpixel((27 - i, 10 + i), PAL["G"])
        d.point([(27, 9), (28, 8)], PAL["g"])
        d.point([(21, 16)], PAL["y"])
    elif sword == "fwd":   # espada horizontal à frente
        d.rectangle([22, 18, 30, 19], PAL["g"])
        d.line([(22, 19), (30, 19)], PAL["G"])
        d.point([(31, 18), (31, 19)], PAL["g"])
        d.rectangle([21, 16, 21, 21], PAL["Y"])  # guarda
        d.point([(20, 18), (20, 19)], PAL["y"])  # punho
    return cell


def build_zack():
    frames = [
        zack_frame(TORSO, LEGS_IDLE),            # 0 idle1
        zack_frame(TORSO_ATK1[:1] + TORSO[1:], LEGS_IDLE2),  # 1 idle2 (ombro sobe)
        zack_frame(TORSO, LEGS_RUN1),            # 2 run1
        zack_frame(TORSO, LEGS_RUN2),            # 3 run2
        zack_frame(TORSO, LEGS_RUN3),            # 4 run3
        zack_frame(TORSO, LEGS_RUN4),            # 5 run4
        zack_frame(TORSO, LEGS_JUMP),            # 6 jump
        zack_frame(TORSO_ATK1, LEGS_IDLE, "up"),  # 7 attack1
        zack_frame(TORSO_ATK2, LEGS_IDLE, "fwd"),  # 8 attack2
    ]
    sheet = Image.new("RGBA", (32 * len(frames), 32), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * 32, 0))
    sheet.save(os.path.join(OUT, "zack_sheet.png"))


# ---------------------------------------------------------- Ciclope
CYCLOPS = [
    "........tt..............",
    ".......ttoooooo.........",
    ".....oommmmmmmmoo.......",
    "....ommmmmmmmmmmmo......",
    "...ommmMmmmmmmMmmmo.....",
    "..ommmmoooooooommmmo....",
    "..ommmoowwwwwwoommmo....",
    ".ommmmowwweewwwommmmo...",
    ".ommmmowwweewwwommmmo...",
    ".ommmmoowwwwwwoommmmo...",
    ".ommmmmoooooooommmmmo...",
    ".oMmmmmmmmmmmmmmmmMo....",
    ".oMmmmmddddddmmmmmMo....",
    "..ommmmmddddmmmmmmo.....",
    "..oMmmmmmmmmmmmmMo......",
    "...ooMmmmmmmmmMoo.......",
    ".....oooMMMMooo.........",
    "....otto....otto........",
    "...ottto....ottto.......",
    "....oo........oo........",
]

CYCLOPS2 = CYCLOPS[:-3] + [
    "....otto..otto..........",
    "....ottto.ottto.........",
    ".....oo....oo...........",
]


def build_cyclops():
    sheet = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    sheet.alpha_composite(draw_map(CYCLOPS), (4, 10))
    sheet.alpha_composite(draw_map(CYCLOPS2), (36, 10))
    sheet.save(os.path.join(OUT, "cyclops_small.png"))

    # Chefe: 2x maior, tom avermelhado
    boss_pal_shift = {"m": (196, 108, 72, 255), "M": (148, 74, 48, 255),
                      "d": (255, 214, 72, 255)}
    old = {k: PAL[k] for k in boss_pal_shift}
    PAL.update(boss_pal_shift)
    f1 = draw_map(CYCLOPS).resize((48, 40), Image.NEAREST)
    f2 = draw_map(CYCLOPS2).resize((48, 40), Image.NEAREST)
    PAL.update(old)
    sheet = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
    sheet.alpha_composite(f1, (8, 20))
    sheet.alpha_composite(f2, (72, 20))
    sheet.save(os.path.join(OUT, "cyclops_boss.png"))


# ---------------------------------------------------------- Tileset
def speckle(d, box, col, n, rng):
    for _ in range(n):
        x = rng.randint(box[0], box[2])
        y = rng.randint(box[1], box[3])
        d.point((x, y), col)


def build_tiles():
    rng = random.Random(7)
    ts = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(ts)
    grass_l, grass_d = (106, 190, 48, 255), (75, 145, 50, 255)
    dirt, dirt_d = (155, 108, 70, 255), (120, 80, 54, 255)
    stone, stone_d = (140, 134, 144, 255), (106, 100, 112, 255)

    # tile 0: grama sobre terra
    d.rectangle([0, 0, 15, 15], dirt)
    speckle(d, (0, 6, 15, 15), dirt_d, 14, rng)
    d.rectangle([0, 0, 15, 4], grass_l)
    d.rectangle([0, 4, 15, 5], grass_d)
    for x in range(0, 16, 3):
        d.point((x, 5 + (x % 2)), grass_d)
    # tile 1: terra cheia
    d.rectangle([16, 0, 31, 15], dirt)
    speckle(d, (16, 0, 31, 15), dirt_d, 20, rng)
    # tile 2: plataforma de pedra
    d.rectangle([32, 0, 47, 15], stone)
    d.rectangle([32, 0, 47, 1], (178, 172, 184, 255))
    speckle(d, (32, 3, 47, 15), stone_d, 16, rng)
    d.rectangle([32, 14, 47, 15], stone_d)
    # tile 3: bloco escuro (fundo da caverna / parede)
    d.rectangle([48, 0, 63, 15], (72, 62, 78, 255))
    speckle(d, (48, 0, 63, 15), (58, 50, 64, 255), 18, rng)
    ts.save(os.path.join(OUT, "tileset.png"))


# ---------------------------------------------------------- UI
def build_ui():
    # corações: cheio, 2/3, 1/3, vazio (8x8 cada → 32x8)
    heart_full = [
        ".dd..dd.",
        "dddddddd",
        "dddddddd",
        "dddddddd",
        ".dddddd.",
        "..dddd..",
        "...dd...",
        "........",
    ]
    sheet = Image.new("RGBA", (32, 8), (0, 0, 0, 0))
    red = (255, 92, 92, 255)
    dark = (120, 40, 52, 255)
    for i, frac in enumerate([1.0, 2 / 3, 1 / 3, 0.0]):
        img = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
        for y, row in enumerate(heart_full):
            for x, ch in enumerate(row):
                if ch in "da":
                    img.putpixel((x, y), dark)
        fill_w = round(8 * frac)
        for y, row in enumerate(heart_full):
            for x, ch in enumerate(row):
                if ch in "da" and x < fill_w:
                    img.putpixel((x, y), red)
        sheet.alpha_composite(img, (i * 8, 0))
    sheet.save(os.path.join(OUT, "hearts.png"))

    # moeda girando: 4 frames 8x8 → 32x8
    sheet = Image.new("RGBA", (32, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(sheet)
    y_, Y_, o_ = PAL["y"], PAL["Y"], PAL["o"]
    widths = [6, 4, 2, 4]
    for i, w in enumerate(widths):
        cx = i * 8 + 4
        x0, x1 = cx - w // 2, cx + w // 2 - 1
        d.ellipse([x0, 1, x1, 6], fill=y_, outline=Y_)
        if w >= 4:
            d.point((cx - 1, 3), (255, 240, 170, 255))
    sheet.save(os.path.join(OUT, "coin.png"))


# ---------------------------------------------------------- Botões de toque
def circle_button(icon):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([2, 2, 61, 61], fill=(40, 40, 60, 110), outline=(255, 255, 255, 160), width=3)
    w = (255, 255, 255, 200)
    if icon == "left":
        d.polygon([(40, 16), (40, 48), (18, 32)], fill=w)
    elif icon == "right":
        d.polygon([(24, 16), (24, 48), (46, 32)], fill=w)
    elif icon == "jump":
        d.polygon([(32, 14), (48, 34), (38, 34), (38, 50), (26, 50), (26, 34), (16, 34)], fill=w)
    elif icon == "punch":  # punho
        d.rounded_rectangle([16, 22, 44, 44], radius=8, fill=w)
        for x in (20, 27, 34):
            d.line([(x, 22), (x, 30)], fill=(40, 40, 60, 200), width=2)
        d.rectangle([40, 28, 50, 40], fill=(255, 214, 72, 220))
    elif icon == "kick":  # perna com tênis
        d.line([(20, 14), (30, 36)], fill=w, width=9)
        d.rounded_rectangle([24, 34, 50, 48], radius=6, fill=(255, 214, 72, 230))
    elif icon == "run":  # setas duplas
        d.polygon([(14, 16), (14, 48), (32, 32)], fill=w)
        d.polygon([(32, 16), (32, 48), (50, 32)], fill=(255, 214, 72, 230))
    elif icon == "special":  # estrela
        import math
        pts = []
        for i in range(10):
            r = 22 if i % 2 == 0 else 9
            a = -math.pi / 2 + i * math.pi / 5
            pts.append((32 + r * math.cos(a), 33 + r * math.sin(a)))
        d.polygon(pts, fill=(255, 214, 72, 240))
    elif icon == "attack":
        d.line([(20, 44), (42, 22)], fill=w, width=5)
        d.line([(40, 14), (48, 22)], fill=w, width=3)
        d.line([(28, 38), (38, 48)], fill=(255, 214, 72, 220), width=4)
    return img


def build_buttons():
    for name in ["left", "right", "jump", "attack", "punch", "kick", "run", "special"]:
        circle_button(name).save(os.path.join(OUT, f"btn_{name}.png"))


# ---------------------------------------------------------- Logo FMF
def letter_F(d, x, y, u, fill, outline):
    """F gordinho estilo desenho infantil; u = unidade (altura = 9u)."""
    bars = [
        (x, y, x + 2 * u, y + 9 * u),          # haste
        (x, y, x + 6 * u, y + 2 * u),          # topo
        (x, y + 4 * u, x + 5 * u, y + 6 * u),  # meio
    ]
    for b in bars:
        d.rectangle(b, fill=fill)
    d.rectangle([x, y, x + 2 * u, y + 9 * u], outline=outline, width=2)
    d.rectangle([x, y, x + 6 * u, y + 2 * u], outline=outline, width=2)
    d.rectangle([x, y + 4 * u, x + 5 * u, y + 6 * u], outline=outline, width=2)


def build_logo():
    s = 4  # unidade de pixel
    img = Image.new("RGBA", (240, 136), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    yellow, ydark = (245, 208, 90, 255), (34, 32, 52, 255)
    # fundo azul-claro arredondado
    d.rounded_rectangle([2, 2, 237, 133], radius=16, fill=(142, 198, 228, 255),
                        outline=(34, 32, 52, 255), width=3)
    u = 5
    base_y = 42
    # F
    letter_F(d, 24, base_y, u, yellow, ydark)
    # M = dois triângulos (como no desenho)
    for i in range(2):
        x0 = 66 + i * 40
        tri = [(x0, base_y + 9 * u), (x0 + 19, base_y), (x0 + 38, base_y + 9 * u)]
        d.polygon(tri, fill=yellow, outline=ydark)
        inner = [(x0 + 11, base_y + 9 * u - 4), (x0 + 19, base_y + 18),
                 (x0 + 27, base_y + 9 * u - 4)]
        d.polygon(inner, fill=(142, 198, 228, 255), outline=ydark)
    # F-espada: lâmina vertical + duas barras amarelas
    sx = 168
    d.polygon([(sx + 3, base_y - 14), (sx + 9, base_y - 14), (sx + 6, base_y - 22)],
              fill=(188, 188, 200, 255), outline=ydark)      # ponta
    d.rectangle([sx + 3, base_y - 14, sx + 9, base_y + 34], fill=(188, 188, 200, 255),
                outline=ydark)                                # lâmina
    d.rectangle([sx - 6, base_y + 34, sx + 18, base_y + 39], fill=(120, 120, 138, 255),
                outline=ydark)                                # guarda
    d.rectangle([sx + 3, base_y + 39, sx + 9, base_y + 54], fill=(176, 128, 72, 255),
                outline=ydark)                                # punho
    d.ellipse([sx + 2, base_y + 54, sx + 10, base_y + 62], fill=(245, 208, 90, 255),
              outline=ydark)                                  # pomo
    # barras do F-espada
    d.rectangle([sx + 14, base_y, sx + 44, base_y + 2 * u], fill=yellow, outline=ydark, width=2)
    d.rectangle([sx + 14, base_y + 4 * u, sx + 38, base_y + 6 * u], fill=yellow, outline=ydark, width=2)
    img.save(os.path.join(OUT, "logo_fmf.png"))

    # ícone do app: fundo azul + espada do logo centralizada
    icon = Image.new("RGBA", (128, 128), (142, 198, 228, 255))
    sword = img.crop((sx - 8, base_y - 24, sx + 20, base_y + 64)).resize((56, 176), Image.NEAREST)
    sword = sword.crop((0, 24, 56, 152))
    icon.alpha_composite(sword, (36, 0))
    icon.save(os.path.join(OUT, "..", "..", "icon.png"))


# ---------------------------------------------------------- Fundo parallax
def build_bg():
    rng = random.Random(3)
    # céu com gradiente + nuvens
    sky = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(sky)
    for y in range(270):
        t = y / 270
        col = (int(120 + 60 * t), int(190 + 40 * t), int(235 + 15 * t), 255)
        d.line([(0, y), (480, y)], col)
    d.ellipse([390, 20, 440, 70], fill=(255, 244, 180, 255))
    for _ in range(7):
        cx, cy = rng.randint(0, 460), rng.randint(15, 110)
        w, h = rng.randint(30, 70), rng.randint(10, 18)
        for dx, dy, f in [(0, 0, 1.0), (-w // 3, h // 4, .7), (w // 3, h // 4, .7)]:
            d.ellipse([cx + dx, cy + dy, cx + dx + int(w * f), cy + dy + h],
                      fill=(255, 255, 255, 230))
    sky.save(os.path.join(OUT, "bg_sky.png"))

    # colinas (camada parallax com transparência)
    hills = Image.new("RGBA", (480, 270), (0, 0, 0, 0))
    d = ImageDraw.Draw(hills)
    for cx, r, col in [(60, 90, (122, 176, 122, 255)), (230, 120, (102, 160, 104, 255)),
                       (420, 100, (122, 176, 122, 255)), (330, 70, (140, 190, 130, 255))]:
        d.ellipse([cx - r, 270 - r, cx + r, 270 + r], fill=col)
    hills.save(os.path.join(OUT, "bg_hills.png"))


def build_vignette():
    w, h = 480, 270
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx, cy = w / 2, h / 2
    max_d = (cx ** 2 + cy ** 2) ** 0.5
    px = img.load()
    for y in range(h):
        for x in range(w):
            d = (((x - cx) ** 2 + (y - cy) ** 2) ** 0.5) / max_d
            a = int(max(0.0, (d - 0.55)) / 0.45 * 150)
            px[x, y] = (5, 8, 12, min(150, a))
    img.save(os.path.join(OUT, "vignette.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    build_vignette()
    build_zack()
    build_cyclops()
    build_tiles()
    build_ui()
    build_buttons()
    build_logo()
    build_bg()
    print("sprites OK")


if __name__ == "__main__":
    main()
