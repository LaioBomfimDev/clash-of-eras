import json
import math
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "characters"
MANIFEST_PATH = ASSETS / "manifest.json"
ANIMATIONS_MANIFEST_PATH = ASSETS / "animations_manifest.json"

DIRECTIONS = [
    "south", "south-east", "east", "north-east",
    "north", "north-west", "west", "south-west"
]

def make_color(r, g, b, a=255):
    return (int(r), int(g), int(b), int(a))

# ==============================================================================
# 1. RENDERIZADORES EM ALTA DEFINIÇÃO (128x128) - BARBIE & KEN
# ==============================================================================

def render_barbie_hd(direction: str) -> Image.Image:
    """Renderiza a Barbie no padrão Lote 04 HD (128x128, proporções reais, bolsa-escudo fashion)."""
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    is_back = "north" in direction
    is_front = "south" in direction
    is_side = "east" in direction or "west" in direction
    flip_h = "west" in direction

    # Paleta de Cores
    C_HAIR_LIGHT = (255, 248, 215, 255)
    C_HAIR_MID = (245, 226, 145, 255)
    C_HAIR_SHADOW = (210, 180, 95, 255)
    C_HAIR_DARK = (160, 130, 50, 255)

    C_SKIN_LIGHT = (255, 235, 225, 255)
    C_SKIN_MID = (248, 212, 195, 255)
    C_SKIN_SHADOW = (220, 175, 155, 255)
    C_EYES = (0, 160, 255, 255)
    C_LIPS = (255, 60, 130, 255)

    C_PINK_LIGHT = (255, 110, 180, 255)
    C_PINK_MID = (235, 30, 135, 255)
    C_PINK_DARK = (185, 10, 95, 255)
    C_PINK_DEEP = (130, 5, 65, 255)

    C_GOLD_LIGHT = (255, 225, 80, 255)
    C_GOLD_MID = (230, 180, 20, 255)
    C_GOLD_DARK = (160, 120, 10, 255)

    OUTLINE = (40, 15, 25, 255)
    GOLD_OUTLINE = (90, 70, 10, 255)

    # 1. Cabelos traseiros (quando de frente ou costas)
    # y de 22 a 72 descendo pelos ombros e costas
    if is_back or is_front:
        # Massa traseira volumosa do cabelo platinado
        draw.ellipse([50, 22, 78, 50], fill=C_HAIR_MID, outline=OUTLINE)
        draw.rectangle([52, 38, 76, 72], fill=C_HAIR_MID)
        draw.line([54, 40, 54, 73], fill=C_HAIR_LIGHT, width=2)
        draw.line([74, 40, 74, 73], fill=C_HAIR_SHADOW, width=2)
        draw.line([51, 38, 51, 74], fill=OUTLINE, width=1)
        draw.line([77, 38, 77, 74], fill=OUTLINE, width=1)
        draw.line([51, 74, 77, 74], fill=OUTLINE, width=1)
    else:
        # Perfil do cabelo
        draw.ellipse([54, 22, 74, 52], fill=C_HAIR_MID, outline=OUTLINE)
        draw.rectangle([54, 38, 72, 70], fill=C_HAIR_MID)
        draw.line([53, 38, 53, 72], fill=OUTLINE, width=1)
        draw.line([73, 38, 73, 72], fill=OUTLINE, width=1)

    # 2. Pernas e Saltos Altos (y = 86 a 118)
    # Perna esquerda
    draw.rectangle([56, 86, 61, 114], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([57, 88, 57, 112], fill=C_SKIN_LIGHT, width=1)
    # Scarpin esquerdo salto fino
    draw.rectangle([54, 113, 62, 118], fill=C_PINK_MID, outline=OUTLINE)
    draw.line([55, 115, 55, 118], fill=C_PINK_DARK, width=1) # salto agulha
    draw.point([61, 114], fill=C_PINK_LIGHT)

    # Perna direita
    draw.rectangle([67, 86, 72, 114], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([68, 88, 68, 112], fill=C_SKIN_LIGHT, width=1)
    # Scarpin direito salto fino
    draw.rectangle([66, 113, 74, 118], fill=C_PINK_MID, outline=OUTLINE)
    draw.line([67, 115, 67, 118], fill=C_PINK_DARK, width=1) # salto agulha
    draw.point([73, 114], fill=C_PINK_LIGHT)

    # 3. Vestido Rosa Choque Glamouroso (y = 44 a 88)
    # Saia elegante estruturada
    poly_skirt = [(56, 58), (72, 58), (78, 88), (50, 88)]
    draw.polygon(poly_skirt, fill=C_PINK_MID, outline=OUTLINE)
    # Pregas e realces de tecido
    draw.line([58, 60, 56, 87], fill=C_PINK_LIGHT, width=2)
    draw.line([65, 60, 65, 87], fill=C_PINK_LIGHT, width=1)
    draw.line([70, 60, 72, 87], fill=C_PINK_DARK, width=2)

    # Cinto com fivela dourada na cintura
    draw.rectangle([56, 55, 72, 58], fill=C_GOLD_MID, outline=GOLD_OUTLINE)
    draw.rectangle([62, 54, 66, 59], fill=C_GOLD_LIGHT, outline=GOLD_OUTLINE)

    # Corpete com decote coração elegante
    poly_corset = [(56, 44), (72, 44), (72, 55), (56, 55)]
    draw.polygon(poly_corset, fill=C_PINK_MID, outline=OUTLINE)
    draw.line([58, 46, 70, 46], fill=C_PINK_LIGHT, width=1)
    draw.line([56, 53, 72, 53], fill=C_PINK_DARK, width=1)

    # 4. Tronco, Colo e Braços (y = 38 a 60)
    # Colo e pescoço
    draw.rectangle([61, 38, 67, 45], fill=C_SKIN_MID, outline=OUTLINE)
    # Colar de ouro
    draw.line([61, 43, 67, 43], fill=C_GOLD_LIGHT, width=1)

    # Braço direito
    draw.rectangle([72, 44, 76, 62], fill=C_SKIN_MID, outline=OUTLINE)
    draw.rectangle([71, 60, 75, 65], fill=C_SKIN_MID, outline=OUTLINE) # mão delicada
    draw.rectangle([72, 56, 76, 58], fill=C_GOLD_MID, outline=GOLD_OUTLINE) # pulseira de ouro

    # 5. Rosto e Cabeça (y = 23 a 40)
    if is_front or is_side:
        # Rosto esbelto
        draw.ellipse([57, 26, 71, 41], fill=C_SKIN_MID, outline=OUTLINE)
        draw.line([59, 28, 69, 28], fill=C_SKIN_LIGHT, width=1)
        if not is_back:
            # Olhos azuis brilhantes com cílios
            draw.rectangle([60, 32, 63, 35], fill=C_EYES)
            draw.point([61, 33], fill=(255, 255, 255, 255))
            draw.line([59, 31, 63, 31], fill=(20, 10, 15, 255), width=1) # cílio superior

            draw.rectangle([66, 32, 69, 35], fill=C_EYES)
            draw.point([67, 33], fill=(255, 255, 255, 255))
            draw.line([65, 31, 69, 31], fill=(20, 10, 15, 255), width=1)

            # Lábios rosados
            draw.rectangle([63, 37, 66, 39], fill=C_LIPS)
            draw.point([64, 37], fill=(255, 180, 210, 255))

    # Cabelos frontais / franja platinada
    draw.arc([56, 23, 72, 36], 180, 360, fill=C_HAIR_LIGHT, width=2)
    draw.line([57, 28, 59, 44], fill=C_HAIR_MID, width=2)
    draw.line([70, 28, 68, 44], fill=C_HAIR_SHADOW, width=2)

    # 6. OBJETO-MARCA: BOLSA DE GRIFE / ESCUDO DE VANGUARDA (y = 48 a 76)
    # Braço esquerdo segurando a alça da bolsa
    draw.rectangle([51, 44, 56, 56], fill=C_SKIN_MID, outline=OUTLINE)
    draw.rectangle([50, 54, 54, 58], fill=C_SKIN_MID, outline=OUTLINE) # mão na alça

    # Alça metálica dourada de corrente
    draw.arc([43, 44, 55, 56], 180, 360, fill=C_GOLD_LIGHT, width=2)

    # Corpo da Bolsa estruturada fashion (22x26 px)
    bag_box = [38, 52, 58, 76] if not is_side else [44, 52, 62, 76]
    draw.rectangle(bag_box, fill=C_PINK_DEEP, outline=OUTLINE)
    draw.rectangle([bag_box[0]+1, bag_box[1]+1, bag_box[2]-1, bag_box[3]-1], fill=C_PINK_MID)

    # Textura matelassê em losangos e linhas de alta costura
    draw.line([bag_box[0]+2, bag_box[1]+6, bag_box[2]-2, bag_box[3]-6], fill=C_PINK_LIGHT, width=1)
    draw.line([bag_box[0]+2, bag_box[3]-6, bag_box[2]-2, bag_box[1]+6], fill=C_PINK_LIGHT, width=1)
    draw.line([bag_box[0]+4, bag_box[1]+2, bag_box[2]-4, bag_box[3]-2], fill=C_PINK_DARK, width=1)

    # Fecho metálico / Emblema em Ouro de Vanguarda
    cx_bag = (bag_box[0] + bag_box[2]) // 2
    cy_bag = (bag_box[1] + bag_box[3]) // 2
    draw.rectangle([cx_bag-3, cy_bag-3, cx_bag+3, cy_bag+3], fill=C_GOLD_MID, outline=GOLD_OUTLINE)
    draw.point([cx_bag, cy_bag], fill=C_GOLD_LIGHT)
    draw.point([cx_bag-1, cy_bag], fill=(255, 255, 255, 255)) # brilho

    if flip_h:
        im = ImageOps.mirror(im)
    return im

def render_ken_hd(direction: str) -> Image.Image:
    """Renderiza o Ken no padrão Lote 04 HD (128x128, proporções atléticas, prancha-escudo de guardião)."""
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    draw = ImageDraw.Draw(im)

    is_back = "north" in direction
    is_front = "south" in direction
    is_side = "east" in direction or "west" in direction
    flip_h = "west" in direction

    # Paleta de Cores
    C_HAIR_LIGHT = (255, 235, 110, 255)
    C_HAIR_MID = (245, 195, 45, 255)
    C_HAIR_SHADOW = (195, 140, 20, 255)
    C_HAIR_DARK = (140, 95, 10, 255)

    C_SKIN_LIGHT = (250, 185, 145, 255)
    C_SKIN_MID = (235, 155, 110, 255)
    C_SKIN_SHADOW = (195, 115, 75, 255)
    C_SKIN_DARK = (150, 80, 50, 255)

    C_TEAL_LIGHT = (80, 240, 255, 255)
    C_TEAL_MID = (0, 180, 220, 255)
    C_TEAL_DARK = (0, 120, 160, 255)

    C_YELLOW_LIGHT = (255, 245, 100, 255)
    C_YELLOW_MID = (255, 205, 20, 255)

    C_BLUE_BOARD = (15, 70, 160, 255)
    C_BLUE_LIGHT = (40, 120, 230, 255)
    C_WHITE = (255, 255, 255, 255)

    OUTLINE = (35, 20, 15, 255)
    BOARD_OUTLINE = (10, 30, 80, 255)

    # 1. Pernas Musculosas e Pés Descalços (y = 82 a 119)
    # Perna esquerda
    draw.rectangle([54, 82, 61, 115], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([56, 84, 56, 113], fill=C_SKIN_LIGHT, width=1)
    draw.line([60, 84, 60, 113], fill=C_SKIN_SHADOW, width=1)
    # Pé esquerdo firme
    draw.rectangle([52, 114, 62, 119], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([54, 116, 59, 116], fill=(0, 180, 220, 255), width=1) # tira da sandália

    # Perna direita
    draw.rectangle([67, 82, 74, 115], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([69, 84, 69, 113], fill=C_SKIN_LIGHT, width=1)
    draw.line([73, 84, 73, 113], fill=C_SKIN_SHADOW, width=1)
    # Pé direito firme
    draw.rectangle([66, 114, 76, 119], fill=C_SKIN_MID, outline=OUTLINE)
    draw.line([68, 116, 73, 116], fill=(0, 180, 220, 255), width=1) # tira da sandália

    # 2. Sunga/Bermuda de Banho Tropical (y = 66 a 83)
    poly_shorts = [(53, 66), (75, 66), (75, 83), (67, 83), (64, 76), (61, 83), (53, 83)]
    draw.polygon(poly_shorts, fill=C_TEAL_MID, outline=OUTLINE)
    # Detalhes tropicais: listras e faixas de surfista
    draw.line([54, 68, 74, 68], fill=C_WHITE, width=2) # cós branco
    draw.line([55, 74, 60, 80], fill=C_TEAL_LIGHT, width=2)
    draw.line([68, 74, 73, 80], fill=C_TEAL_LIGHT, width=2)

    # 3. Tronco Atlético, Abdômen e Peitorais Definidos (y = 40 a 67)
    poly_torso = [(50, 42), (78, 42), (73, 67), (55, 67)]
    draw.polygon(poly_torso, fill=C_SKIN_MID, outline=OUTLINE)

    if not is_back:
        # Peitoral musculoso e abdômen trincado
        draw.line([52, 44, 76, 44], fill=C_SKIN_LIGHT, width=2) # clavícula iluminada
        # Peitoral esquerdo e direito
        draw.rectangle([54, 46, 62, 53], fill=C_SKIN_MID, outline=C_SKIN_SHADOW)
        draw.rectangle([66, 46, 74, 53], fill=C_SKIN_MID, outline=C_SKIN_SHADOW)
        # Linha alba e gomos do abdômen
        draw.line([64, 46, 64, 65], fill=C_SKIN_DARK, width=1)
        draw.line([58, 57, 70, 57], fill=C_SKIN_SHADOW, width=1)
        draw.line([59, 62, 69, 62], fill=C_SKIN_SHADOW, width=1)
    else:
        # Costas musculosas de nadador/surfista
        draw.line([54, 45, 74, 45], fill=C_SKIN_LIGHT, width=2)
        draw.line([64, 44, 64, 66], fill=C_SKIN_SHADOW, width=1) # espinha dorsal

    # Braço esquerdo musculoso (y = 42 a 66)
    draw.rectangle([76, 42, 82, 62], fill=C_SKIN_MID, outline=OUTLINE)
    draw.rectangle([75, 61, 80, 66], fill=C_SKIN_MID, outline=OUTLINE) # punho/mão

    # 4. Cabeça, Rosto Quadrado e Topete Loiro (y = 21 a 41)
    draw.rectangle([60, 36, 68, 42], fill=C_SKIN_MID, outline=OUTLINE) # pescoço forte

    if not is_back:
        # Mandíbula quadrada
        poly_face = [(56, 26), (72, 26), (71, 38), (64, 41), (57, 38)]
        draw.polygon(poly_face, fill=C_SKIN_MID, outline=OUTLINE)
        draw.line([58, 28, 70, 28], fill=C_SKIN_LIGHT, width=1)

        # Olhos azuis e sobrancelhas marcantes
        draw.line([58, 30, 62, 30], fill=C_HAIR_DARK, width=1)
        draw.rectangle([59, 32, 62, 34], fill=(0, 140, 240, 255))
        draw.point([60, 33], fill=C_WHITE)

        draw.line([66, 30, 70, 30], fill=C_HAIR_DARK, width=1)
        draw.rectangle([66, 32, 69, 34], fill=(0, 140, 240, 255))
        draw.point([67, 33], fill=C_WHITE)

        # Sorriso galante
        draw.line([61, 37, 67, 37], fill=C_WHITE, width=1)
        draw.point([60, 36], fill=C_SKIN_DARK)
        draw.point([68, 36], fill=C_SKIN_DARK)

    # Cabelo Loiro Dourado com Topete Esculpido Clássico
    poly_hair = [(54, 26), (64, 20), (74, 24), (73, 29), (55, 29)]
    draw.polygon(poly_hair, fill=C_HAIR_MID, outline=OUTLINE)
    draw.line([58, 22, 68, 22], fill=C_HAIR_LIGHT, width=2)
    draw.line([55, 26, 73, 26], fill=C_HAIR_SHADOW, width=1)

    # 5. OBJETO-MARCA: PRANCHA DE SURFE ESTILIZADA / ESCUDO DE GUARDIÃO (y = 40 a 108)
    # Braço direito segurando a prancha firme
    draw.rectangle([46, 42, 52, 60], fill=C_SKIN_MID, outline=OUTLINE)
    draw.rectangle([44, 58, 49, 63], fill=C_SKIN_MID, outline=OUTLINE) # mão segurando

    # Prancha de Surfe aerodinâmica (24x64 px)
    poly_board = [
        (36, 46), (42, 40), (48, 46),
        (50, 80), (48, 106), (36, 106), (34, 80)
    ]
    draw.polygon(poly_board, fill=C_BLUE_BOARD, outline=BOARD_OUTLINE)
    # Faixa esportiva central amarela e branca
    draw.polygon([(40, 43), (44, 43), (44, 105), (40, 105)], fill=C_YELLOW_MID)
    draw.line([42, 43, 42, 105], fill=C_YELLOW_LIGHT, width=1)
    draw.line([39, 45, 39, 104], fill=C_WHITE, width=1)
    draw.line([45, 45, 45, 104], fill=C_BLUE_LIGHT, width=1)

    if flip_h:
        im = ImageOps.mirror(im)
    return im

# ==============================================================================
# 2. CINEMÁTICA DE MOVIMENTOS EM 16 FRAMES (24 FPS) NAS 8 DIREÇÕES
# ==============================================================================

def generate_walk_frame(base_arr: np.ndarray, phase: float, is_lateral: bool, is_female_heels: bool = False) -> np.ndarray:
    """16 frames de caminhada suave com bobbing vertical e articulação de passada."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return base_arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)
    cx = (x_idx.min() + x_idx.max()) / 2.0

    y_hip = int(y_top + char_h * (0.55 if is_female_heels else 0.58))
    # Bobbing vertical: 2 ciclos completos de elevação por passada
    bob = int(round(-math.sin(phase * 2.0) * (1.2 if is_female_heels else 1.0)))

    stride = math.sin(phase) * (1.9 if is_female_heels else 2.2)
    lift = max(0.0, math.cos(phase)) * (1.8 if is_female_heels else 1.6)

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny - bob
            src_x = nx

            if y_hip <= src_y <= y_bot + 4:
                t_leg = (src_y - y_hip) / max(1.0, (y_bot - y_hip))
                t_leg = min(1.0, max(0.0, t_leg))

                if is_lateral:
                    dx = stride * t_leg
                    dy = -lift * t_leg if stride > 0 else 0.0
                    src_x = int(round(nx - dx))
                    src_y = int(round(src_y - dy))
                else:
                    if nx < cx:
                        # Perna esquerda
                        dx = stride * t_leg * 0.7
                        dy = -lift * t_leg
                    else:
                        # Perna direita
                        dx = -stride * t_leg * 0.7
                        dy = -max(0.0, math.cos(phase + math.pi)) * 1.6 * t_leg
                    src_x = int(round(nx - dx))
                    src_y = int(round(src_y - dy))

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = base_arr[src_y, src_x]

    return out

def generate_attack_frame(base_arr: np.ndarray, t_norm: float, hero: str, is_lateral: bool) -> np.ndarray:
    """16 frames de ataque (antecipação, impacto/golpe e recuperação)."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return base_arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)

    if t_norm < 0.25:
        p = t_norm / 0.25
        impulse = -math.sin(p * math.pi * 0.5) * 0.4
        lift = 0.0
    elif t_norm < 0.55:
        p = (t_norm - 0.25) / 0.30
        impulse = math.sin(p * math.pi) * 1.0
        lift = math.sin(p * math.pi) * 1.6
    else:
        p = (t_norm - 0.55) / 0.45
        impulse = (1.0 - p) * 0.3 * math.cos(p * math.pi * 2.0)
        lift = (1.0 - p) * 0.2

    reach = 3.6 if hero == "ken" else 2.8
    y_chest = int(y_top + char_h * 0.45)

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny
            src_x = nx

            if src_y >= y_chest:
                t = (src_y - y_chest) / max(1.0, (y_bot - y_chest))
                dx = impulse * reach * (1.2 if is_lateral else 0.8) * t
                dy = -lift * 1.5 * t
                src_x = int(round(nx - dx))
                src_y = int(round(ny - dy))
            else:
                dx = impulse * reach * 0.4
                src_x = int(round(nx - dx))

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = base_arr[src_y, src_x]

    return out

def generate_stance_frame(base_arr: np.ndarray, phase: float, is_lateral: bool) -> np.ndarray:
    """16 frames de postura viva de prontidão de combate."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx = np.where(alpha > 12)[0]
    if len(y_idx) == 0:
        return base_arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)
    y_chest = int(y_top + char_h * 0.40)
    breathe = int(round(-math.sin(phase) * 1.0))
    sway = math.sin(phase + math.pi * 0.25) * 1.2

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny
            src_x = nx

            if y_top <= src_y <= y_chest:
                src_y = ny - breathe
            elif y_chest < src_y <= y_bot - 4:
                t = (src_y - y_chest) / max(1.0, (y_bot - y_chest))
                dx = int(round(sway * (1.0 if is_lateral else 0.5) * t))
                src_x = nx - dx

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = base_arr[src_y, src_x]

    return out

def generate_skill_frame(base_arr: np.ndarray, t_norm: float, hero: str, is_lateral: bool) -> np.ndarray:
    """16 frames de habilidade: invocação da Barbie ou provocação de guardião do Ken."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx = np.where(alpha > 12)[0]
    if len(y_idx) == 0:
        return base_arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)

    # Pose de invocação ou batida de prancha
    p = math.sin(t_norm * math.pi)
    lift = int(round(p * 2.5))
    glow_val = int(round(p * 45))

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny + lift
            src_x = nx

            if 0 <= src_y < h and 0 <= src_x < w and alpha[src_y, src_x] > 12:
                pix = base_arr[src_y, src_x].copy()
                if hero == "barbie":
                    # Brilho mágico rosa choque
                    pix[0] = min(255, pix[0] + glow_val)
                    pix[1] = min(255, int(pix[1] + glow_val * 0.3))
                    pix[2] = min(255, int(pix[2] + glow_val * 0.8))
                else:
                    # Brilho áureo azul de guardião
                    pix[0] = min(255, int(pix[0] + glow_val * 0.3))
                    pix[1] = min(255, int(pix[1] + glow_val * 0.8))
                    pix[2] = min(255, pix[2] + glow_val)
                out[ny, nx] = pix

    return out

def generate_death_frame(base_arr: np.ndarray, t_norm: float) -> np.ndarray:
    """16 frames de desfalecimento/queda."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx = np.where(alpha > 12)[0]
    if len(y_idx) == 0:
        return base_arr.copy()

    y_bot = int(y_idx.max())
    if t_norm < 0.25:
        p = t_norm / 0.25
        h_scale = 1.0 + p * 0.08
        recoil = -p * 2.0
    elif t_norm < 0.70:
        p = (t_norm - 0.25) / 0.45
        h_scale = 1.08 - p * 0.72
        recoil = -2.0 + p * 4.0
    else:
        h_scale = 0.36
        recoil = 2.0

    alpha_fade = max(0.15, 1.0 - t_norm * 0.6)
    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            if ny > y_bot:
                continue
            dy = y_bot - ny
            src_y = int(y_bot - (dy / max(0.2, h_scale)))
            src_x = int(nx - recoil)

            if 0 <= src_y < h and 0 <= src_x < w and alpha[src_y, src_x] > 12:
                pix = base_arr[src_y, src_x].copy()
                pix[0] = int(pix[0] * alpha_fade)
                pix[1] = int(pix[1] * alpha_fade)
                pix[2] = int(pix[2] * alpha_fade)
                out[ny, nx] = pix

    return out

def generate_stun_frame(base_arr: np.ndarray, phase: float) -> np.ndarray:
    """16 frames de desorientação/atordoamento."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx = np.where(alpha > 12)[0]
    if len(y_idx) == 0:
        return base_arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)
    sway_x = math.sin(phase) * 2.2
    sway_y = math.cos(phase * 2.0) * 0.8

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny
            src_x = nx

            if y_top <= src_y <= y_bot:
                t = (y_bot - src_y) / float(char_h)
                dx = int(round(sway_x * t))
                dy = int(round(sway_y * t))
                src_x = nx - dx
                src_y = ny - dy

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = base_arr[src_y, src_x]

    return out

def generate_buff_frame(base_arr: np.ndarray, phase: float) -> np.ndarray:
    """16 frames de pulso de empoderamento e realce luminoso."""
    h, w, c = base_arr.shape
    alpha = base_arr[:, :, 3]
    y_idx = np.where(alpha > 12)[0]
    if len(y_idx) == 0:
        return base_arr.copy()

    lift = int(round(math.sin(phase) * 1.5))
    glow_pulse = 0.6 + 0.4 * math.sin(phase)

    out = np.zeros_like(base_arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny + lift
            src_x = nx

            if 0 <= src_y < h and 0 <= src_x < w and alpha[src_y, src_x] > 12:
                pix = base_arr[src_y, src_x].copy()
                pix[0] = min(255, int(pix[0] + 35 * glow_pulse))
                pix[1] = min(255, int(pix[1] + 25 * glow_pulse))
                pix[2] = min(255, int(pix[2] + 15 * glow_pulse))
                out[ny, nx] = pix

    return out

# ==============================================================================
# 3. PIPELINE DE EXECUÇÃO E INTEGRAÇÃO
# ==============================================================================

def make_import_file(png_path: Path):
    """Cria arquivo .import compatível com Godot 4.7.2."""
    import_path = png_path.with_name(png_path.name + ".import")
    content = f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://auto_{abs(hash(str(png_path))) % 1000000000}"
path="res://.godot/imported/{png_path.name}-{abs(hash(str(png_path))) % 1000000000}.ctex"

[deps]

source_file="res://assets/characters/{png_path.relative_to(ASSETS).as_posix()}"
dest_files=["res://.godot/imported/{png_path.name}-{abs(hash(str(png_path))) % 1000000000}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
editor/scale_with_editor_scale=false
editor/convert_colors_with_editor_theme=false
"""
    import_path.write_text(content, encoding="utf-8")

def main():
    print("=== REFORMULANDO VISUAL DA BARBIE E DO KEN (LOTE 04 HD) ===")

    # 1. Gerar rotações estáticas HD (128x128)
    for hero in ["barbie", "ken"]:
        print(f"\n--- Gerando rotações estáticas HD 128x128 para: {hero} ---")
        dest_rot = ASSETS / hero / "grande_04" / "original" / "Idle" / "rotations"
        dest_rot.mkdir(parents=True, exist_ok=True)

        for d in DIRECTIONS:
            if hero == "barbie":
                im = render_barbie_hd(d)
            else:
                im = render_ken_hd(d)
            out_file = dest_rot / f"{d}.png"
            im.save(out_file)
            make_import_file(out_file)
            print(f"  Salvo: {out_file.name} (128x128)")

        # Criar metadata.json
        meta_file = ASSETS / hero / "grande_04" / "original" / "metadata.json"
        meta_file.write_text(json.dumps({
            "character_id": f"{hero}_hd_lote04",
            "name": hero.capitalize(),
            "art_batch": "grande_04",
            "canvas_size": [128, 128],
            "directions": DIRECTIONS
        }, indent=2), encoding="utf-8")

    # 2. Gerar movimentos animados de 16 frames a 24 FPS
    anim_manifest = json.loads(ANIMATIONS_MANIFEST_PATH.read_text(encoding="utf-8")) if ANIMATIONS_MANIFEST_PATH.exists() else {"schema_version": 1, "characters": {}}
    chars_entry = anim_manifest.setdefault("characters", {})

    states_list = ["walk", "attack", "stance", "skill", "death", "stun", "buff"]

    for hero in ["barbie", "ken"]:
        print(f"\n--- Gerando clips animados de 16 frames para: {hero} ---")
        hero_def = chars_entry.setdefault(hero, {"states": {}})
        hero_states = hero_def.setdefault("states", {})

        is_female = (hero == "barbie")
        base_rot_dir = ASSETS / hero / "grande_04" / "original" / "Idle" / "rotations"

        for state in states_list:
            state_dir = ASSETS / hero / "animacoes_16f" / state
            state_dir.mkdir(parents=True, exist_ok=True)
            dir_entries = {}
            is_loop = state != "death"

            for d in DIRECTIONS:
                src_png = base_rot_dir / f"{d}.png"
                if not src_png.exists():
                    src_png = base_rot_dir / "south.png"
                im_base = Image.open(src_png).convert("RGBA")
                arr_base = np.array(im_base)

                alpha = arr_base[:, :, 3]
                y_idx = np.where(alpha > 12)[0]
                anchor_y = int(y_idx.max()) + 1 if len(y_idx) > 0 else 118
                anchor_x = int(im_base.width // 2)
                is_lat = d in ["east", "west", "south-east", "south-west", "north-east", "north-west"]

                target_folder = state_dir / d
                target_folder.mkdir(parents=True, exist_ok=True)
                frame_paths = []

                for i in range(16):
                    phase = 2.0 * math.pi * i / 16.0
                    t_norm = i / 15.0

                    if state == "walk":
                        f_arr = generate_walk_frame(arr_base, phase, is_lat, is_female)
                    elif state == "attack":
                        f_arr = generate_attack_frame(arr_base, t_norm, hero, is_lat)
                    elif state == "stance":
                        f_arr = generate_stance_frame(arr_base, phase, is_lat)
                    elif state == "skill":
                        f_arr = generate_skill_frame(arr_base, t_norm, hero, is_lat)
                    elif state == "death":
                        f_arr = generate_death_frame(arr_base, t_norm)
                    elif state == "stun":
                        f_arr = generate_stun_frame(arr_base, phase)
                    elif state == "buff":
                        f_arr = generate_buff_frame(arr_base, phase)

                    frame_im = Image.fromarray(f_arr)
                    fn = f"frame_{i:03d}.png"
                    out_f = target_folder / fn
                    frame_im.save(out_f)
                    make_import_file(out_f)
                    frame_paths.append(f"res://assets/characters/{hero}/animacoes_16f/{state}/{d}/{fn}")

                dir_entries[d] = {
                    "frames": frame_paths,
                    "anchor": [anchor_x, anchor_y],
                    "fps": 24
                }

            hero_states[state] = {
                "loop": is_loop,
                "fps": 24,
                "directions": dir_entries
            }
            print(f"  Estado '{state}' gerado com 16 frames nas 8 direcoes.")

    # Gravar animations_manifest.json atualizado
    ANIMATIONS_MANIFEST_PATH.write_text(json.dumps(anim_manifest, indent=2), encoding="utf-8")
    print("\nAnimations manifest atualizado com sucesso!")

    # 3. Atualizar manifest.json (direções estáticas grande_04)
    if MANIFEST_PATH.exists():
        man = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        for h in ["barbie", "ken"]:
            man_chars = man.setdefault("characters", {})
            h_entry = man_chars.setdefault(h, {})
            h_entry["art_batch"] = "grande_04"
            h_entry["portrait_focus"] = [64, 24]
            h_states = h_entry.setdefault("states", {})
            h_idle = h_states.setdefault("idle", {})
            dirs_map = {}
            for d in DIRECTIONS:
                dirs_map[d] = f"res://assets/characters/{h}/grande_04/original/Idle/rotations/{d}.png"
            h_idle["directions"] = dirs_map
        MANIFEST_PATH.write_text(json.dumps(man, indent=2), encoding="utf-8")
        print("Manifest.json atualizado com as rotas grande_04 de Barbie e Ken!")

    print("\n=== REFORMULAÇÃO E MOVIMENTOS CONCLUÍDOS COM SUCESSO! ===")

if __name__ == "__main__":
    main()
