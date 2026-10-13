"""Gera os ícones 16 x 16 da interface em pixel art com alto refinamento visual.

Arte desenhada por código com paleta rica, iluminação, reflexos metálicos e volume.
Totalmente compatível com as regras e testes do projeto (16x16 RGBA).
Reexecutar substitui os PNGs em assets/ui/icons/.

Uso, a partir de RelicArena/:
    python -I tools/gerar_icones.py
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "ui" / "icons"
SIZE = 16

# Paleta expandida de alta qualidade com sombreamento em 4-5 níveis por material
P = {
    # Metais / Aço
    "w": (255, 255, 255, 255),  # Brilho puro especular
    "s1": (225, 235, 245, 255), # Prata clara / lâmina
    "s2": (170, 185, 205, 255), # Aço médio
    "s3": (110, 125, 145, 255), # Sombra de aço
    "s4": (55, 65, 80, 255),    # Aço escuro
    # Ouro / Bronze
    "y1": (255, 245, 180, 255), # Ouro brilho
    "y2": (250, 205, 65, 255),  # Ouro vivo
    "y3": (210, 150, 35, 255),  # Ouro âmbar
    "y4": (145, 90, 25, 255),   # Ouro sombra
    "y5": (85, 48, 15, 255),    # Ouro escuro
    # Couro / Madeira
    "b1": (195, 145, 95, 255),  # Couro claro
    "b2": (145, 95, 50, 255),   # Couro médio
    "b3": (95, 55, 28, 255),    # Couro escuro
    "b4": (55, 30, 15, 255),    # Couro profundo
    # Vermelho / Chamas
    "r1": (255, 130, 130, 255), # Rosa/vermelho brilho
    "r2": (235, 55, 55, 255),   # Vermelho vivo / rubi
    "r3": (175, 25, 35, 255),   # Vermelho escuro
    "r4": (105, 15, 25, 255),   # Bordô sombra
    # Verde / Esmeralda
    "e1": (195, 255, 195, 255), # Verde brilho
    "e2": (80, 220, 105, 255),  # Esmeralda viva
    "e3": (35, 160, 65, 255),   # Verde médio
    "e4": (18, 95, 40, 255),    # Verde floresta escuro
    # Ciano / Barreira / Magia
    "c1": (220, 255, 255, 255), # Ciano brilho
    "c2": (85, 225, 245, 255),  # Ciano elétrico
    "c3": (35, 155, 185, 255),  # Turquesa médio
    "c4": (20, 90, 120, 255),   # Azul petróleo
    # Safira / Ametista / Místico
    "p1": (240, 215, 255, 255), # Ametista brilho
    "p2": (185, 115, 245, 255), # Ametista viva
    "p3": (125, 60, 185, 255),  # Roxo místico
    "p4": (70, 30, 115, 255),   # Roxo profundo
    # Contorno
    "k": (20, 22, 28, 255),     # Contorno escuro nítido
}

def canvas():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return img

def set_px(img, x, y, col):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img.putpixel((x, y), P[col] if isinstance(col, str) else col)

def set_grid(img, rows, col_map):
    for y, row in enumerate(rows):
        for x, char in enumerate(row):
            if char in col_map and col_map[char] is not None:
                set_px(img, x, y, col_map[char])

def auto_outline(img, color=P["k"]):
    src = img.load()
    out = img.copy()
    tgt = out.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1,0), (-1,0), (0,1), (0,-1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE and src[nx, ny][3] > 0:
                    tgt[x, y] = color
                    break
    return out


# ==============================================================================
# ITENS DO LABORATÓRIO (Refinados, com volume, reflexos e gemas)
# ==============================================================================

def icon_blade() -> Image.Image:
    """Lâmina de aço afiada com guarda de ouro, rubi central e reflexo metálico."""
    grid = [
        "...............k",
        "..............kw",
        ".............kws",
        "............kws.",
        "...........kws..",
        "..........kws...",
        ".........kws....",
        "........kws.....",
        ".......kws......",
        "....kyykwk......",
        "...kyrkys.......",
        "..kbyykyk.......",
        ".kbk.k..........",
        "kyk.............",
        "................",
        "................",
    ]
    # Usando desenho direto com iluminação rica
    img = canvas()
    # Lâmina diagonal de (5,10) até (14,1)
    blade_coords = [
        (14, 1, "w"), (13, 1, "w"), (13, 2, "s1"),
        (12, 2, "w"), (12, 3, "s1"), (11, 3, "s2"),
        (11, 4, "w"), (10, 4, "s1"), (10, 5, "s2"),
        (9, 5, "w"),  (9, 6, "s1"),  (8, 6, "s2"),
        (8, 7, "w"),  (7, 7, "s1"),  (7, 8, "s2"),
        (6, 8, "w"),  (6, 9, "s1"),  (5, 9, "s3"),
        (5, 10, "s1"),(4, 10, "s2"),
    ]
    for x, y, col in blade_coords:
        set_px(img, x, y, col)
    # Guarda de ouro com rubi
    guard_coords = [
        (3, 8, "y1"), (4, 9, "y2"), (5, 9, "y2"),
        (4, 11, "y3"), (5, 11, "y2"), (6, 11, "y1"), (7, 12, "y2"),
        (5, 10, "r2"), # Rubi no centro da guarda
    ]
    for x, y, col in guard_coords:
        set_px(img, x, y, col)
    # Cabo e Pomo
    set_px(img, 3, 11, "b2")
    set_px(img, 2, 12, "b3")
    set_px(img, 1, 13, "y2")
    set_px(img, 1, 14, "y3")
    set_px(img, 2, 14, "y4")
    return auto_outline(img)


def icon_great_blade() -> Image.Image:
    """Lâminas duplas flamejantes douradas cruzadas com poder de fusão."""
    img = canvas()
    # Espada 1 (diagonal subindo)
    for i in range(10):
        set_px(img, 4 + i, 11 - i, "y1" if i >= 6 else "y2")
        set_px(img, 5 + i, 11 - i, "y2")
        set_px(img, 5 + i, 12 - i, "r2")
    # Espada 2 (diagonal descendo/cruzada)
    for i in range(10):
        set_px(img, 11 - i, 11 - i, "w" if i >= 6 else "s1")
        set_px(img, 10 - i, 11 - i, "s2")
        set_px(img, 10 - i, 12 - i, "r3")
    # Centro mágico de fusão (chama radiante)
    set_px(img, 7, 8, "w")
    set_px(img, 8, 8, "y1")
    set_px(img, 7, 9, "r1")
    set_px(img, 8, 9, "r2")
    # Guardas
    for gx, gy in [(2, 12), (3, 13), (4, 13)]:
        set_px(img, gx, gy, "y3")
    for gx, gy in [(13, 12), (12, 13), (11, 13)]:
        set_px(img, gx, gy, "y3")
    # Cabos
    set_px(img, 1, 14, "b2")
    set_px(img, 14, 14, "b2")
    return auto_outline(img)


def icon_vest() -> Image.Image:
    """Colete tático blindado: peitoral de placas forjadas, rebites e ombreiras."""
    img = canvas()
    # Gola / Ombreiras
    set_px(img, 4, 2, "s1")
    set_px(img, 5, 2, "s2")
    set_px(img, 10, 2, "s1")
    set_px(img, 11, 2, "s2")
    # Ombreiras reforçadas
    for x in (3, 4, 11, 12):
        set_px(img, x, 3, "y3")
    # Peitoral superior (aço chanfrado)
    for x in range(4, 12):
        set_px(img, x, 4, "s1" if x in (5, 6) else "s2")
        set_px(img, x, 5, "s2" if x < 8 else "s3")
    # Placas centrais com rebites
    for x in range(3, 13):
        set_px(img, x, 6, "s2" if x in (4, 5, 8, 9) else "s3")
        set_px(img, x, 7, "s1" if x in (4, 8) else "s3")
        set_px(img, x, 8, "s2" if x < 8 else "s4")
        set_px(img, x, 9, "s3" if x < 8 else "s4")
        set_px(img, x, 10, "s2" if x < 8 else "s3")
        set_px(img, x, 11, "s3" if x < 8 else "s4")
        set_px(img, x, 12, "b2" if x in (3, 12) else "s4")
    # Fivela central e rebites dourados
    set_px(img, 5, 6, "y1")
    set_px(img, 10, 6, "y1")
    set_px(img, 5, 10, "y2")
    set_px(img, 10, 10, "y2")
    # Cinturão inferior
    for x in range(4, 12):
        set_px(img, x, 13, "b3")
    set_px(img, 7, 13, "y2")
    set_px(img, 8, 13, "y1")
    return auto_outline(img)


def icon_guard_vest() -> Image.Image:
    """Colete guardião divino: couraça cerúlea com gema arcana brilhante e filigrana dourada."""
    img = canvas()
    # Base igual ao vest mas com paleta azul místico e aura
    for x, y in [(4,2), (5,2), (10,2), (11,2)]:
        set_px(img, x, y, "y1")
    for x in (3, 4, 11, 12):
        set_px(img, x, 3, "y2")
    for x in range(4, 12):
        set_px(img, x, 4, "c1" if x in (5,6) else "c2")
        set_px(img, x, 5, "c2" if x < 8 else "c3")
    for x in range(3, 13):
        for y in range(6, 13):
            set_px(img, x, y, "c2" if x < 8 else "c4")
    # Gema mágica central radiante
    set_px(img, 7, 7, "w")
    set_px(img, 8, 7, "c1")
    set_px(img, 7, 8, "c1")
    set_px(img, 8, 8, "c2")
    set_px(img, 7, 9, "c3")
    set_px(img, 8, 9, "c3")
    # Borda dourada sagrada
    for y in (6, 7, 8, 9, 10, 11, 12):
        set_px(img, 3, y, "y3")
        set_px(img, 12, y, "y3")
    for x in range(4, 12):
        set_px(img, x, 13, "y4")
    return auto_outline(img)


def icon_boots() -> Image.Image:
    """Botas velozes aladas: couro esculpido, fivelas douradas e asas de vento cianas."""
    img = canvas()
    # Cano da bota
    for y in range(3, 10):
        for x in range(6, 11):
            col = "b1" if x == 6 else ("b2" if x < 9 else "b3")
            set_px(img, x, y, col)
    # Dobra superior da bota
    for x in range(6, 11):
        set_px(img, x, 3, "y3")
    # Pé e sola
    for y in range(9, 13):
        for x in range(6, 14):
            col = "b1" if y == 9 and x < 12 else ("b2" if x < 12 else "b3")
            set_px(img, x, y, col)
    # Bico da bota
    set_px(img, 14, 11, "b2")
    set_px(img, 14, 12, "b3")
    # Sola reforçada de ferro
    for x in range(6, 15):
        set_px(img, x, 13, "s3" if x < 10 else "s4")
    # Fivelas de ouro
    set_px(img, 8, 6, "y1")
    set_px(img, 8, 9, "y2")
    # Asas de velocidade (penas cianas/brancas saindo do calcanhar)
    wing_pixels = [
        (5, 5, "w"), (4, 4, "w"), (3, 4, "c1"), (2, 4, "c2"),
        (5, 7, "w"), (4, 7, "c1"), (3, 7, "c2"), (2, 7, "c3"), (1, 7, "c4"),
        (5, 9, "c1"), (4, 10, "c2"), (3, 10, "c3"), (2, 11, "c4")
    ]
    for x, y, col in wing_pixels:
        set_px(img, x, y, col)
    return auto_outline(img)


def icon_plate() -> Image.Image:
    """Placa / Escudo pesado de aço reforçado com rebites e cruz heráldica."""
    img = canvas()
    # Formato do escudo (topo reto com cantos chanfrados, bico pontudo embaixo)
    for y in range(2, 14):
        w = 10 if y <= 7 else (9 if y <= 9 else (7 if y <= 11 else (5 if y <= 12 else 3)))
        start_x = 8 - w // 2
        for x in range(start_x, start_x + w):
            # Gradiente de aço escovado
            if x < 8:
                col = "s1" if y <= 4 or x == start_x else "s2"
            else:
                col = "s3" if x < 8 + w - 2 else "s4"
            set_px(img, x, y, col)
    # Cruz heráldica central prateada/dourada
    for y in range(3, 12):
        set_px(img, 7, y, "w")
        set_px(img, 8, y, "s1")
    for x in range(4, 12):
        set_px(img, x, 6, "w")
        set_px(img, x, 7, "s1")
    # Boss central dourado
    set_px(img, 7, 6, "y1")
    set_px(img, 8, 6, "y2")
    set_px(img, 7, 7, "y2")
    set_px(img, 8, 7, "y3")
    # Rebites de aço nos cantos
    set_px(img, 4, 3, "w")
    set_px(img, 11, 3, "s2")
    set_px(img, 4, 9, "s1")
    set_px(img, 11, 9, "s3")
    return auto_outline(img)


def icon_ward() -> Image.Image:
    """Amuleto místico: corrente de ouro, engaste trabalhado e gema ametista facetada."""
    img = canvas()
    # Corrente de ouro
    chain = [(3, 1), (4, 2), (5, 3), (6, 4), (12, 1), (11, 2), (10, 3), (9, 4), (7, 5), (8, 5)]
    for x, y in chain:
        set_px(img, x, y, "y2" if x in (5, 6, 9, 10) else "y1")
    # Engaste dourado
    for x in range(5, 11):
        for y in range(6, 14):
            dist = abs(x - 7.5) + abs(y - 9.5)
            if dist <= 4.2:
                set_px(img, x, y, "y3")
    # Gema mística de ametista facetada
    facets = [
        (7, 7, "p1"), (8, 7, "w"),
        (6, 8, "p1"), (7, 8, "w"),  (8, 8, "p2"), (9, 8, "p3"),
        (6, 9, "p2"), (7, 9, "p2"), (8, 9, "p3"), (9, 9, "p4"),
        (6, 10, "p2"),(7, 10, "p3"),(8, 10, "p4"),(9, 10, "p4"),
        (7, 11, "p3"),(8, 11, "p4"),
        (7, 12, "p4"),
    ]
    for x, y, col in facets:
        set_px(img, x, y, col)
    # Brilho estelar na gema
    set_px(img, 7, 8, "w")
    return auto_outline(img)


def icon_charm() -> Image.Image:
    """Trevo de 4 folhas da sorte: folhas em formato de coração, orvalho e brilhos dourados."""
    img = canvas()
    # Folha superior esquerda
    for x, y in [(4, 3), (5, 3), (3, 4), (4, 4), (5, 4), (6, 4), (3, 5), (4, 5), (5, 5), (6, 5)]:
        set_px(img, x, y, "e1" if (x, y) == (4, 3) else ("e2" if x <= 5 else "e3"))
    # Folha superior direita
    for x, y in [(9, 3), (10, 3), (8, 4), (9, 4), (10, 4), (11, 4), (8, 5), (9, 5), (10, 5), (11, 5)]:
        set_px(img, x, y, "e1" if (x, y) == (9, 3) else ("e2" if y <= 4 else "e3"))
    # Folha inferior esquerda
    for x, y in [(3, 8), (4, 8), (5, 8), (6, 8), (3, 9), (4, 9), (5, 9), (6, 9), (4, 10), (5, 10)]:
        set_px(img, x, y, "e2" if x <= 4 else ("e3" if y <= 9 else "e4"))
    # Folha inferior direita
    for x, y in [(8, 8), (9, 8), (10, 8), (11, 8), (8, 9), (9, 9), (10, 9), (11, 9), (9, 10), (10, 10)]:
        set_px(img, x, y, "e2" if x == 8 else ("e3" if x <= 10 else "e4"))
    # Centro do trevo e nervuras
    set_px(img, 7, 6, "e4")
    set_px(img, 8, 6, "e4")
    set_px(img, 7, 7, "e4")
    set_px(img, 8, 7, "e4")
    # Caule elegante curvado
    for x, y in [(7, 8), (8, 9), (8, 10), (9, 11), (10, 12), (11, 13), (12, 14)]:
        set_px(img, x, y, "e4" if y > 10 else "e3")
    # Ponto de orvalho brilhante
    set_px(img, 4, 4, "w")
    # Brilhos mágicos dourados ao redor
    set_px(img, 2, 2, "y1")
    set_px(img, 12, 2, "y1")
    set_px(img, 13, 8, "y2")
    return auto_outline(img)


# ==============================================================================
# SINERGIAS (Ícones distintos, heráldicos e legíveis em selos TFT)
# ==============================================================================

def icon_crossed_mono() -> Image.Image:
    """Sinergia Atacantes: espadas de guerra cruzadas com lâminas de aço afiadas."""
    img = canvas()
    # Espada 1 (diagonal)
    for i in range(11):
        set_px(img, 3 + i, 12 - i, "w" if i >= 8 else "s1")
        set_px(img, 4 + i, 12 - i, "s2")
    # Espada 2 (diagonal oposta)
    for i in range(11):
        set_px(img, 12 - i, 12 - i, "w" if i >= 8 else "s1")
        set_px(img, 11 - i, 12 - i, "s3")
    # Centro
    set_px(img, 7, 8, "r2")
    set_px(img, 8, 8, "r2")
    # Guardas
    for gx, gy in [(2, 11), (3, 12), (4, 13)]:
        set_px(img, gx, gy, "y2")
    for gx, gy in [(13, 11), (12, 12), (11, 13)]:
        set_px(img, gx, gy, "y2")
    # Cabos
    set_px(img, 1, 13, "b2")
    set_px(img, 14, 13, "b2")
    return auto_outline(img)


def icon_target() -> Image.Image:
    """Sinergia Atiradores: retículo de precisão com anel ciano e mira central."""
    img = canvas()
    # Anel circular
    for y in range(SIZE):
        for x in range(SIZE):
            dist = math.hypot(x - 7.5, y - 7.5)
            if 4.2 <= dist <= 5.8:
                set_px(img, x, y, "c2" if y < 7.5 else "c3")
            elif dist <= 1.8:
                set_px(img, x, y, "r2")
    # Ponto central e eixos
    set_px(img, 7, 7, "w")
    set_px(img, 8, 7, "r1")
    # Miras cardeais (topo, baixo, esquerda, direita)
    for x in (7, 8):
        set_px(img, x, 0, "c1")
        set_px(img, x, 1, "c2")
        set_px(img, x, 2, "c2")
        set_px(img, x, 13, "c2")
        set_px(img, x, 14, "c2")
        set_px(img, x, 15, "c1")
    for y in (7, 8):
        set_px(img, 0, y, "c1")
        set_px(img, 1, y, "c2")
        set_px(img, 2, y, "c2")
        set_px(img, 13, y, "c2")
        set_px(img, 14, y, "c2")
        set_px(img, 15, y, "c1")
    return auto_outline(img)


def icon_support() -> Image.Image:
    """Sinergia Apoio: cruz de cura sagrada com asas e aura celestial."""
    img = canvas()
    # Cruz médica / sagrada central
    for y in range(3, 13):
        for x in range(6, 10):
            col = "w" if x == 7 or y == 7 else "e2"
            set_px(img, x, y, col)
    for y in range(6, 10):
        for x in range(3, 13):
            col = "w" if x == 7 or y == 7 else "e2"
            set_px(img, x, y, col)
    # Brilhos celestiais nas pontas
    set_px(img, 7, 2, "y1")
    set_px(img, 8, 2, "y1")
    set_px(img, 7, 13, "y2")
    set_px(img, 8, 13, "y2")
    set_px(img, 2, 7, "y1")
    set_px(img, 2, 8, "y1")
    set_px(img, 13, 7, "y2")
    set_px(img, 13, 8, "y2")
    # Brilho central
    set_px(img, 7, 7, "w")
    return auto_outline(img)


def icon_shield() -> Image.Image:
    """Sinergia Vanguarda: brasão de fortaleza/torre impenetrável em ouro e ferro."""
    img = canvas()
    # Escudo de torre com ameias no topo
    for x in range(3, 13):
        for y in range(2, 14):
            # Ameias
            if y == 2 and x in (5, 6, 9, 10):
                continue
            w = 10 if y <= 7 else (9 if y <= 9 else (7 if y <= 11 else (5 if y <= 12 else 3)))
            start_x = 8 - w // 2
            if start_x <= x < start_x + w:
                col = "y2" if x == start_x or x == start_x + w - 1 or y == 3 else ("s1" if x < 8 else "s3")
                set_px(img, x, y, col)
    # Brasão de castelo no centro
    set_px(img, 7, 6, "y1")
    set_px(img, 8, 6, "y1")
    set_px(img, 7, 7, "y2")
    set_px(img, 8, 7, "y2")
    set_px(img, 7, 8, "y3")
    set_px(img, 8, 8, "y3")
    return auto_outline(img)


# ==============================================================================
# INTERFACE E EFEITOS
# ==============================================================================

def icon_coin() -> Image.Image:
    """Moeda de ouro com relevo, estrela central e profundidade tridimensional."""
    img = canvas()
    for y in range(2, 14):
        for x in range(2, 14):
            dist = math.hypot(x - 7.5, y - 7.5)
            if dist <= 5.8:
                if dist >= 4.4:
                    set_px(img, x, y, "y1" if x + y < 15 else "y4")
                else:
                    set_px(img, x, y, "y2" if x < 8 else "y3")
    # Estrela / Símbolo central
    set_px(img, 7, 5, "y1")
    set_px(img, 8, 5, "y1")
    for x in range(5, 11):
        set_px(img, x, 7, "y1" if x <= 7 else "y4")
    set_px(img, 7, 8, "y1")
    set_px(img, 8, 8, "y2")
    set_px(img, 6, 9, "y3")
    set_px(img, 9, 9, "y4")
    # Ponto especular
    set_px(img, 4, 4, "w")
    return auto_outline(img, P["y5"])


def icon_refresh() -> Image.Image:
    """Setas de renovação circular dinâmicas em ciano com gradiente."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.arc((2, 2, 13, 13), 205, 335, fill=P["c1"], width=2)
    draw.arc((2, 2, 13, 13), 25, 155, fill=P["c2"], width=2)
    # Pontas das setas afiadas
    draw.polygon([(11, 1), (14, 5), (9, 5)], fill=P["c1"])
    draw.polygon([(4, 14), (1, 10), (6, 10)], fill=P["c2"])
    return auto_outline(img)


def icon_expand() -> Image.Image:
    """Aumento de capacidade de campo: pedestal hexagonal e '+' dourado radiante."""
    img = canvas()
    # Silhueta de herói / campo
    draw = ImageDraw.Draw(img)
    draw.ellipse((3, 2, 7, 6), fill=P["s1"])
    draw.rectangle((2, 7, 8, 13), fill=P["s2"])
    # Sinal de '+' em ouro vibrante
    for y in range(6, 15):
        set_px(img, 12, y, "y1" if y in (9,10) else "y2")
        set_px(img, 13, y, "y2")
    for x in range(9, 16):
        set_px(img, x, 10, "y1")
        set_px(img, x, 11, "y2")
    return auto_outline(img)


def icon_scroll() -> Image.Image:
    """Pergaminho de eventos e histórico com hastes de madeira e selo."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.rectangle((3, 3, 12, 12), fill=P["y1"])
    draw.rectangle((2, 2, 13, 3), fill=P["y3"])
    draw.rectangle((2, 12, 13, 13), fill=P["y3"])
    for y in (5, 7, 9, 11):
        draw.line([(5, y), (10, y)], fill=P["b3"])
    return auto_outline(img)


def icon_menu() -> Image.Image:
    """Menu clássico de 3 barras metálicas arredondadas."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    for y in (3, 7, 11):
        draw.rectangle((2, y, 13, y + 1), fill=P["s1"])
        draw.point((3, y), fill=P["w"])
    return auto_outline(img)


def icon_sound() -> Image.Image:
    """Alto-falante metálico com ondas sonoras."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.rectangle((2, 6, 5, 9), fill=P["s2"])
    draw.polygon([(5, 6), (9, 2), (9, 13), (5, 9)], fill=P["s1"])
    draw.arc((7, 3, 13, 12), 300, 60, fill=P["c1"], width=2)
    return auto_outline(img)


def icon_bolt() -> Image.Image:
    """Raio de luta / combate elétrico com núcleo branco e aura dourada."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    draw.polygon([(9, 1), (3, 9), (7, 9), (5, 15), (13, 6), (8, 6), (10, 1)], fill=P["y2"])
    draw.line([(9, 2), (5, 8)], fill=P["w"])
    draw.line([(8, 7), (6, 13)], fill=P["y1"])
    return auto_outline(img)


def icon_star() -> Image.Image:
    """Estrela 3D com facetas sombreadas (nível 1, 2, 3)."""
    img = canvas()
    draw = ImageDraw.Draw(img)
    points = []
    for index in range(10):
        radius = 7.2 if index % 2 == 0 else 3.0
        angle = -math.pi / 2 + index * math.pi / 5
        points.append((7.5 + math.cos(angle) * radius, 8.0 + math.sin(angle) * radius))
    draw.polygon(points, fill=P["w"])
    # Facetas sombreadas à direita
    draw.point((7, 8), fill=P["s2"])
    draw.point((8, 8), fill=P["s3"])
    draw.point((7, 9), fill=P["s2"])
    draw.point((8, 9), fill=P["s3"])
    return auto_outline(img)


BALL_PIXELS = (
    "................",
    ".....kkkkkk.....",
    "...kkwwddwwkk...",
    "..kwwwwddwwwwk..",
    ".kwwwwwggwwwwwk.",
    ".kwwwwwggwwwwwk.",
    "kddwwwwddwwwwddk",
    "kddggwddddwggddk",
    "kddwwwddddwwwddk",
    "kwwwwwwddwwwwwsk",
    "kwwwwwgwwgwwwwsk",
    ".kwddgwwwwgddwk.",
    ".kwdddwwwwdddwk.",
    "..kwddwwwwddwk..",
    "...kksssssssk...",
    ".....kkkkkk.....",
)

def icon_ball() -> Image.Image:
    """Bola de futebol perfeitamente sombreada em esfera 3D."""
    colors = {
        "k": P["k"],
        "w": P["w"],
        "d": (40, 42, 50, 255),
        "g": P["s2"],
        "s": P["s3"]
    }
    img = canvas()
    for y, row in enumerate(BALL_PIXELS):
        for x, char in enumerate(row):
            if char in colors:
                img.putpixel((x, y), colors[char])
    return img


ICONS = {
    # Sinergias
    "syn_atacantes": icon_crossed_mono,
    "syn_atiradores": icon_target,
    "syn_apoio": icon_support,
    "syn_vanguarda": icon_shield,
    # Itens do laboratório V1
    "item_blade": icon_blade,
    "item_great_blade": icon_great_blade,
    "item_vest": icon_vest,
    "item_guard_vest": icon_guard_vest,
    "item_boots": icon_boots,
    "item_plate": icon_plate,
    "item_ward": icon_ward,
    "item_charm": icon_charm,
    # Interface
    "ui_coin": icon_coin,
    "ui_refresh": icon_refresh,
    "ui_expand": icon_expand,
    "ui_scroll": icon_scroll,
    "ui_menu": icon_menu,
    "ui_sound": icon_sound,
    "ui_fight": icon_bolt,
    "ui_star": icon_star,
    # Efeitos
    "fx_ball": icon_ball,
}

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, builder in ICONS.items():
        img = builder()
        assert img.size == (SIZE, SIZE), f"{name} size mismatch: {img.size}"
        img.save(OUT / f"{name}.png")
    print(f"{len(ICONS)} ícones de alta qualidade gerados em {OUT}")

if __name__ == "__main__":
    main()
