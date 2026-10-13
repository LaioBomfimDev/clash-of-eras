"""Bonecos PROVISÓRIOS 48 x 48 (frente) para os personagens do lote 03, em proporção realista.

Servem só para testar os kits enquanto a arte do PixelLab não existe. Não são arte final,
não usam IA nem créditos. Reexecutar substitui somente assets/characters/provisorio/*.png.
Uso, a partir de RelicArena/:

    python -I tools/gerar_provisorios.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "characters" / "provisorio"
SIZE = 48
OUTLINE = (24, 20, 28, 255)


def rgb(value: tuple) -> tuple:
    return value + (255,) if len(value) == 3 else value


def shade(color: tuple, factor: float) -> tuple:
    return tuple(max(0, min(255, int(channel * factor))) for channel in color[:3]) + (255,)


def outline(image: Image.Image) -> Image.Image:
    source = image.load()
    result = image.copy()
    target = result.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if source[x, y][3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE and source[nx, ny][3]:
                    target[x, y] = OUTLINE
                    break
    return result


def body(draw: ImageDraw.ImageDraw, skin: tuple, top: tuple, legs: tuple, shoes: tuple,
         torso_width: int = 10, legs_skin: bool = False, arms_skin: bool = False) -> None:
    """Corpo de proporção realista (~7 cabeças): cabeça 4–11, tronco 13–26, pernas 27–44, pés 45–46."""
    cx = 24
    half = torso_width // 2
    # pernas e pés
    leg = skin if legs_skin else legs
    draw.rectangle((cx - half + 1, 27, cx - 1, 44), fill=rgb(leg))
    draw.rectangle((cx + 1, 27, cx + half - 1, 44), fill=rgb(leg))
    draw.rectangle((cx - half + 1, 27, cx - half + 1, 44), fill=shade(leg, 0.82))
    draw.rectangle((cx - half, 45, cx - 1, 46), fill=rgb(shoes))
    draw.rectangle((cx + 1, 45, cx + half, 46), fill=rgb(shoes))
    # tronco e braços
    draw.rectangle((cx - half, 13, cx + half - 1, 26), fill=rgb(top))
    draw.rectangle((cx + half - 3, 13, cx + half - 1, 26), fill=shade(top, 0.8))
    arm = skin if arms_skin else top
    draw.rectangle((cx - half - 3, 14, cx - half - 1, 25), fill=rgb(arm))
    draw.rectangle((cx + half, 14, cx + half + 2, 25), fill=shade(arm, 0.85))
    draw.rectangle((cx - half - 3, 26, cx - half - 1, 27), fill=rgb(skin))
    draw.rectangle((cx + half, 26, cx + half + 2, 27), fill=rgb(skin))
    # pescoço e cabeça
    draw.rectangle((cx - 1, 11, cx + 1, 12), fill=shade(skin, 0.85))
    draw.rectangle((cx - 3, 4, cx + 3, 10), fill=rgb(skin))
    draw.point((cx - 2, 7), fill=OUTLINE)
    draw.point((cx + 2, 7), fill=OUTLINE)
    draw.line([(cx - 1, 9), (cx + 1, 9)], fill=shade(skin, 0.7))


def barbie() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    hair = (250, 222, 120)
    draw.rectangle((19, 3, 29, 17), fill=rgb(hair))  # cabelo longo atrás
    body(draw, (242, 196, 172), (236, 92, 162), (242, 196, 172), (236, 92, 162), torso_width=9, legs_skin=True, arms_skin=True)
    draw.polygon([(19, 21), (29, 21), (31, 33), (17, 33)], fill=rgb((236, 92, 162)))  # saia
    draw.line([(20, 22), (28, 22)], fill=rgb((255, 170, 210)))
    draw.rectangle((20, 3, 28, 5), fill=rgb(hair))
    draw.rectangle((20, 4, 20, 9), fill=rgb(hair))
    draw.rectangle((28, 4, 28, 9), fill=rgb(hair))
    return outline(image)


def ken() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (222, 168, 128)
    body(draw, skin, skin, skin, skin, torso_width=11, legs_skin=True, arms_skin=True)
    draw.rectangle((19, 24, 28, 27), fill=rgb((52, 118, 226)))  # sunga
    draw.line([(21, 16), (23, 16)], fill=shade(skin, 0.86))
    draw.line([(25, 16), (27, 16)], fill=shade(skin, 0.86))
    for y in (19, 21):
        draw.point((23, y), fill=shade(skin, 0.86))
        draw.point((25, y), fill=shade(skin, 0.86))
    draw.rectangle((21, 3, 27, 5), fill=rgb((248, 214, 110)))
    return outline(image)


def elon() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    body(draw, (238, 204, 184), (28, 28, 34), (58, 60, 70), (18, 18, 22), torso_width=10)
    draw.rectangle((21, 3, 27, 5), fill=rgb((70, 50, 38)))
    draw.rectangle((31, 16, 32, 27), fill=rgb((235, 235, 240)))  # foguete
    draw.rectangle((31, 15, 32, 15), fill=rgb((220, 60, 50)))
    draw.point((30, 26), fill=rgb((220, 60, 50)))
    draw.point((33, 26), fill=rgb((220, 60, 50)))
    return outline(image)


def snoop() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    blue = (44, 92, 186)
    body(draw, (122, 82, 58), blue, blue, (240, 240, 240), torso_width=9)
    for x in (20, 22, 26, 28):  # tranças
        draw.line([(x, 4), (x, 19)], fill=rgb((24, 20, 22)))
    draw.rectangle((21, 3, 27, 4), fill=rgb((24, 20, 22)))
    draw.rectangle((21, 6, 27, 7), fill=rgb((14, 14, 18)))  # óculos
    draw.line([(19, 13), (19, 44)], fill=rgb((235, 235, 240)))
    draw.line([(28, 13), (28, 44)], fill=rgb((235, 235, 240)))
    draw.rectangle((15, 22, 16, 25), fill=rgb((60, 60, 66)))  # microfone
    return outline(image)


def lula() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    suit = (40, 46, 72)
    body(draw, (226, 182, 150), suit, suit, (20, 20, 24), torso_width=13)
    grey = (196, 196, 198)
    draw.rectangle((21, 3, 27, 5), fill=rgb(grey))
    draw.rectangle((21, 8, 27, 11), fill=rgb(grey))  # barba
    draw.line([(23, 9), (25, 9)], fill=rgb((150, 110, 100)))
    draw.polygon([(22, 13), (26, 13), (24, 17)], fill=rgb((240, 240, 240)))  # camisa
    draw.line([(24, 14), (24, 21)], fill=rgb((205, 40, 48)))  # gravata
    return outline(image)


def bob_marley() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    draw.polygon([(30, 12), (35, 22), (31, 30), (27, 22)], fill=rgb((150, 96, 52)))  # violão nas costas
    body(draw, (110, 72, 50), (74, 104, 154), (40, 44, 56), (60, 40, 30), torso_width=10)
    locks = (52, 36, 26)
    for x in (20, 21, 27, 28):
        draw.line([(x, 5), (x, 18)], fill=rgb(locks))
    for y, color in ((1, (214, 44, 44)), (2, (246, 206, 50)), (3, (44, 156, 72))):
        draw.line([(20, y + 1), (28, y + 1)], fill=rgb(color))  # gorro rasta
    return outline(image)


def rapunzel() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    dress = (196, 216, 170)
    body(draw, (244, 206, 184), dress, dress, (170, 120, 90), torso_width=9, arms_skin=True)
    draw.polygon([(19, 21), (29, 21), (31, 44), (17, 44)], fill=rgb(dress))  # vestido longo
    draw.line([(24, 22), (24, 44)], fill=shade(dress, 0.85))
    gold = (246, 204, 92)
    draw.rectangle((20, 3, 28, 5), fill=rgb(gold))
    for index, y in enumerate(range(6, 46, 2)):  # trança até o chão
        x = 15 + (index % 2)
        draw.rectangle((x, y, x + 1, y + 1), fill=rgb(gold if index % 2 == 0 else (226, 176, 70)))
    draw.line([(17, 5), (20, 5)], fill=rgb(gold))
    draw.point((27, 4), fill=rgb((236, 120, 170)))
    return outline(image)


def caramelo() -> Image.Image:
    """Cão vira-lata caramelo quadrúpede realista (48x48): focinho alongado, orelhas caídas, coleira vermelha, tronco ágil."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    gold = (218, 142, 60)
    shadow_col = (175, 108, 42)
    belly = (235, 175, 95)
    red_collar = (220, 42, 45)
    draw.polygon([(34, 25), (38, 18), (41, 14), (39, 14), (36, 19), (33, 27)], fill=rgb(gold))
    draw.point((41, 13), fill=rgb(belly))
    draw.rectangle((33, 31, 35, 44), fill=rgb(shadow_col))
    draw.rectangle((32, 45, 36, 46), fill=rgb(shadow_col))
    draw.polygon([(28, 25), (34, 25), (35, 32), (31, 36), (30, 44), (28, 44), (28, 33)], fill=rgb(gold))
    draw.rectangle((27, 45, 31, 46), fill=rgb(gold))
    draw.rectangle((17, 24, 34, 32), fill=rgb(gold))
    draw.rectangle((19, 31, 31, 33), fill=rgb(belly))
    draw.polygon([(16, 23), (22, 23), (23, 32), (18, 34), (16, 29)], fill=rgb(gold))
    draw.rectangle((21, 34, 23, 44), fill=rgb(shadow_col))
    draw.rectangle((20, 45, 24, 46), fill=rgb(shadow_col))
    draw.rectangle((16, 33, 18, 44), fill=rgb(gold))
    draw.rectangle((15, 45, 19, 46), fill=rgb(gold))
    draw.polygon([(18, 24), (23, 24), (22, 16), (17, 18)], fill=rgb(gold))
    draw.line([(17, 21), (22, 19)], fill=rgb(red_collar), width=2)
    draw.point((19, 21), fill=rgb((245, 210, 60)))
    draw.polygon([(14, 15), (22, 14), (23, 19), (13, 19)], fill=rgb(gold))
    draw.rectangle((10, 16, 14, 19), fill=rgb(belly))
    draw.point((9, 16), fill=rgb((20, 18, 20)))
    draw.point((10, 16), fill=rgb((20, 18, 20)))
    draw.point((16, 15), fill=rgb((30, 24, 20)))
    draw.point((16, 14), fill=rgb((240, 200, 140)))
    draw.polygon([(20, 13), (24, 14), (23, 21), (19, 18)], fill=rgb(shadow_col))
    return outline(image)


def zumbi() -> Image.Image:
    """Zumbi lanceiro atlético realista (48x48): esguio, pele verde-oliva, tanga de guerreiro, lança com ponta em brasa."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (120, 148, 110)
    cloth = (84, 62, 48)
    draw.line([(34, 4), (34, 45)], fill=rgb((110, 78, 50)), width=1)
    draw.polygon([(34, 3), (36, 8), (34, 11), (32, 8)], fill=rgb((220, 70, 50)))
    draw.point((34, 6), fill=rgb((255, 180, 80)))
    body(draw, skin, cloth, cloth, (55, 45, 40), torso_width=9, legs_skin=True, arms_skin=True)
    draw.rectangle((20, 24, 27, 28), fill=rgb(cloth))
    draw.line([(21, 25), (26, 25)], fill=rgb((160, 130, 90)))
    draw.line([(18, 18), (19, 18)], fill=rgb((180, 175, 160)))
    draw.line([(18, 22), (19, 22)], fill=rgb((180, 175, 160)))
    draw.rectangle((21, 3, 27, 6), fill=rgb((32, 28, 28)))
    draw.line([(20, 5), (20, 9)], fill=rgb((32, 28, 28)))
    draw.point((22, 7), fill=rgb((255, 230, 120)))
    draw.point((26, 7), fill=rgb((255, 230, 120)))
    return outline(image)


def cleopatra() -> Image.Image:
    """Cleópatra (48x48): rainha egípcia elegante, vestido linho drapeado, diadema de serpente de ouro com rubi."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (226, 178, 142)
    linen = (245, 244, 240)
    gold = (242, 198, 64)
    black = (18, 16, 20)
    draw.rectangle((18, 3, 30, 19), fill=rgb(black))
    body(draw, skin, linen, linen, (200, 160, 60), torso_width=8, arms_skin=True)
    draw.polygon([(19, 21), (29, 21), (31, 44), (17, 44)], fill=rgb(linen))
    draw.line([(24, 22), (24, 44)], fill=rgb((210, 205, 195)))
    draw.rectangle((20, 22, 28, 24), fill=rgb(gold))
    draw.point((24, 23), fill=rgb((40, 170, 190)))
    draw.polygon([(20, 13), (28, 13), (27, 17), (21, 17)], fill=rgb(gold))
    draw.line([(21, 15), (27, 15)], fill=rgb((40, 170, 190)))
    draw.rectangle((20, 3, 28, 5), fill=rgb(gold))
    draw.polygon([(23, 1), (25, 1), (25, 4), (23, 4)], fill=rgb(gold))
    draw.point((24, 2), fill=rgb((230, 40, 40)))
    draw.point((22, 7), fill=rgb(black))
    draw.point((21, 7), fill=rgb((40, 170, 190)))
    draw.point((26, 7), fill=rgb(black))
    draw.point((27, 7), fill=rgb((40, 170, 190)))
    draw.line([(31, 16), (31, 38)], fill=rgb(gold))
    draw.polygon([(30, 13), (32, 13), (33, 15), (29, 15)], fill=rgb((40, 190, 180)))
    return outline(image)


def julio_cesar() -> Image.Image:
    """Júlio César (48x48): imperador romano, armadura lorica musculata de bronze, capa vermelha carmesim, louros."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (230, 188, 160)
    bronze = (196, 142, 68)
    red = (198, 38, 45)
    tunic = (240, 238, 230)
    draw.polygon([(17, 14), (31, 14), (33, 43), (15, 43)], fill=rgb(red))
    body(draw, skin, bronze, tunic, (80, 50, 30), torso_width=11)
    draw.rectangle((19, 13, 29, 25), fill=rgb(bronze))
    draw.line([(22, 16), (26, 16)], fill=rgb((230, 180, 95)))
    draw.line([(23, 19), (25, 19)], fill=rgb((230, 180, 95)))
    draw.rectangle((19, 26, 29, 31), fill=rgb(tunic))
    for px in range(20, 29, 2):
        draw.line([(px, 26), (px, 30)], fill=rgb((130, 85, 45)))
    draw.rectangle((21, 3, 27, 5), fill=rgb((90, 85, 80)))
    draw.line([(20, 4), (28, 4)], fill=rgb((60, 160, 60)))
    draw.point((24, 3), fill=rgb((245, 215, 80)))
    draw.line([(16, 23), (16, 35)], fill=rgb(bronze), width=2)
    return outline(image)


def einstein() -> Image.Image:
    """Albert Einstein (48x48): físico da era moderna, terno de tweed marrom, colete, cabelo branco rebelde e bigode."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (232, 192, 168)
    tweed = (118, 92, 70)
    vest = (78, 64, 52)
    pants = (85, 80, 75)
    white = (245, 245, 248)
    body(draw, skin, tweed, pants, (45, 38, 35), torso_width=10)
    draw.rectangle((22, 14, 26, 24), fill=rgb(vest))
    draw.polygon([(23, 13), (25, 13), (24, 16)], fill=rgb(white))
    draw.point((24, 14), fill=rgb((30, 30, 35)))
    draw.rectangle((18, 2, 30, 7), fill=rgb(white))
    draw.point((17, 3), fill=rgb(white))
    draw.point((17, 5), fill=rgb(white))
    draw.point((31, 3), fill=rgb(white))
    draw.point((31, 5), fill=rgb(white))
    draw.line([(22, 9), (26, 9)], fill=rgb(white))
    draw.rectangle((30, 22, 35, 28), fill=rgb((160, 130, 85)))
    draw.line([(31, 23), (34, 23)], fill=rgb(white))
    draw.line([(31, 25), (34, 25)], fill=rgb(white))
    return outline(image)


def napoleao() -> Image.Image:
    """Napoleão Bonaparte (48x48): comandante, bicorne preto com cocar tricolor, casaco azul-noite, dragonas e culotes."""
    image = Image.new("RGBA", (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    skin = (235, 195, 170)
    navy = (32, 42, 78)
    white = (245, 245, 248)
    gold = (242, 198, 64)
    boots = (22, 20, 25)
    body(draw, skin, navy, white, boots, torso_width=10)
    draw.rectangle((23, 14, 25, 24), fill=rgb(white))
    draw.line([(20, 13), (22, 13)], fill=rgb(gold))
    draw.line([(26, 13), (28, 13)], fill=rgb(gold))
    draw.line([(22, 14), (26, 22)], fill=rgb((200, 35, 40)))
    draw.polygon([(15, 4), (33, 4), (31, 1), (17, 1)], fill=rgb((20, 18, 24)))
    draw.line([(14, 4), (34, 4)], fill=rgb(gold))
    draw.point((23, 3), fill=rgb((30, 70, 190)))
    draw.point((24, 3), fill=rgb(white))
    draw.point((25, 3), fill=rgb((210, 35, 40)))
    return outline(image)


CHARACTERS = {
    "barbie": barbie, "ken": ken, "elon": elon, "snoop": snoop, "lula": lula,
    "bob_marley": bob_marley, "rapunzel": rapunzel,
    "caramelo": caramelo, "zumbi": zumbi,
    "cleopatra": cleopatra, "julio_cesar": julio_cesar, "einstein": einstein, "napoleao": napoleao
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for key, build in CHARACTERS.items():
        image = build()
        assert image.size == (SIZE, SIZE)
        image.save(OUT / f"{key}.png")
    print(f"{len(CHARACTERS)} bonecos provisórios em {OUT}")


if __name__ == "__main__":
    main()
