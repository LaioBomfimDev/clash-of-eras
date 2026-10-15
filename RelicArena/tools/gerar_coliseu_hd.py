import math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ARENA_PATH = ROOT / "assets" / "arena" / "coliseu_epico_hd.png"

W, H = 1340, 760

def create_epic_coliseum():
    img = Image.new("RGBA", (W, H), (26, 31, 34, 255))
    draw = ImageDraw.Draw(img)

    # 1. Ceu de fim de tarde romano épico no fundo superior
    for y in range(0, 160):
        t = y / 160.0
        # Gradiente suave de azul crepúsculo para dourado de arena
        r = int(28 * (1 - t) + 65 * t)
        g = int(32 * (1 - t) + 60 * t)
        b = int(48 * (1 - t) + 68 * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # 2. Arquibancadas do Coliseu (Nível Superior / Arcos Romanos)
    arch_bg = (45, 40, 48, 255)
    pillar_col = (92, 82, 90, 255)
    pillar_hi = (135, 122, 132, 255)
    pillar_sh = (32, 28, 35, 255)

    # Fileira de Arcos Romanos Superiores (y: 35 .. 140)
    for x in range(30, W - 30, 68):
        # Interior do arco escurecido (galeria)
        draw.ellipse([x + 6, 45, x + 58, 125], fill=(22, 20, 26, 255))
        draw.rectangle([x + 6, 85, x + 58, 142], fill=(22, 20, 26, 255))
        
        # Arco de pedra esculpida
        draw.arc([x + 4, 43, x + 60, 127], 180, 360, fill=pillar_hi, width=3)
        # Pilares laterais do arco
        draw.rectangle([x + 4, 85, x + 8, 142], fill=pillar_col)
        draw.rectangle([x + 56, 85, x + 60, 142], fill=pillar_sh)

    # Cornija imperial separando os níveis
    draw.rectangle([0, 140, W, 148], fill=pillar_hi)
    draw.line([(0, 148), (W, 148)], fill=(20, 18, 24, 255), width=2)

    # 3. Muro de Contenção da Arena (Podium de Mármore e Mureta)
    # Forma curva elíptica que abraça a arena
    center_x = 648
    arena_top_y = 175
    arena_bottom_y = 745
    arena_rad_x = 590
    arena_rad_y = 290

    # Parede externa do podium
    for i in range(148, 215):
        t = (i - 148) / 67.0
        r = int(75 * (1 - t) + 42 * t)
        g = int(68 * (1 - t) + 38 * t)
        b = int(72 * (1 - t) + 40 * t)
        draw.line([(0, i), (W, i)], fill=(r, g, b, 255))

    # Estandartes Imperiais de Veludo Carmesim e Ouro pendurados na mureta
    banner_xs = [160, 310, 480, 810, 980, 1130]
    for bx in banner_xs:
        # Haste dourada
        draw.rectangle([bx - 18, 150, bx + 18, 154], fill=(218, 165, 32, 255))
        # Tecido carmesim com ponta em V
        banner_pts = [
            (bx - 15, 154),
            (bx + 15, 154),
            (bx + 15, 208),
            (bx, 222),
            (bx - 15, 208)
        ]
        draw.polygon(banner_pts, fill=(142, 22, 38, 255))
        # Borda e brasão imperial dourado
        draw.line([(bx - 14, 155), (bx - 14, 207), (bx, 220), (bx + 14, 207), (bx + 14, 155)], fill=(230, 180, 40, 255), width=1)
        draw.ellipse([bx - 5, 172, bx + 5, 182], fill=(230, 180, 40, 255))
        draw.ellipse([bx - 2, 175, bx + 2, 179], fill=(142, 22, 38, 255))

    # 4. Braseiros Monumentais de Ferro nos Cantos com Chamas Crepitantes
    braziers = [(95, 180), (1245, 180)]
    for zx, zy in braziers:
        # Tripé de ferro fundido
        draw.polygon([(zx - 16, zy + 25), (zx - 8, zy), (zx + 8, zy), (zx + 16, zy + 25)], fill=(35, 36, 42, 255))
        draw.rectangle([zx - 18, zy - 4, zx + 18, zy + 2], fill=(60, 62, 70, 255))
        # Taça de fogo
        draw.ellipse([zx - 20, zy - 10, zx + 20, zy], fill=(45, 46, 52, 255))
        # Chamas douradas/laranjas em camadas
        draw.ellipse([zx - 14, zy - 28, zx + 14, zy - 4], fill=(225, 80, 15, 230))
        draw.ellipse([zx - 10, zy - 34, zx + 10, zy - 8], fill=(245, 160, 25, 240))
        draw.ellipse([zx - 5, zy - 38, zx + 5, zy - 12], fill=(255, 235, 120, 255))

    # 5. Piso da Arena do Coliseu (Areia Dourada Épica e Limpa)
    # Criar camada dedicada para a areia com relevo suave e anéis
    sand_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(sand_layer)

    # Base da elipse de areia
    sand_bbox = [center_x - arena_rad_x, 192, center_x + arena_rad_x, arena_bottom_y + 120]
    
    # Preenchimento gradiente da areia (mais iluminada no centro da batalha)
    sand_base = (226, 198, 142, 255) # Areia dourada clara
    sand_warm = (235, 212, 162, 255) # Realce quente central
    sand_edge = (195, 165, 115, 255) # Sombra nas bordas

    s_draw.ellipse(sand_bbox, fill=sand_base)

    # Anel de sombra de contato nas paredes da arena
    s_draw.ellipse([sand_bbox[0] - 2, sand_bbox[1] - 2, sand_bbox[2] + 2, sand_bbox[3] + 2], outline=(50, 42, 38, 140), width=6)
    s_draw.ellipse([sand_bbox[0] + 6, sand_bbox[1] + 6, sand_bbox[2] - 6, sand_bbox[3] - 6], outline=(155, 128, 88, 180), width=4)

    # Realce de iluminação solar central (clean e luminoso)
    sun_bbox = [center_x - 380, 260, center_x + 380, 620]
    s_draw.ellipse(sun_bbox, fill=sand_warm)

    # 6. Detalhes Geométricos Épicos na Areia (Sem poluição visual, traços limpos)
    # Grande Círculo Imperial Central entalhado na areia
    circle_center = (center_x, 415)
    r_outer = 240
    r_inner = 150

    # Anel imperial externo
    s_draw.ellipse([circle_center[0] - r_outer, circle_center[1] - r_outer * 0.58,
                    circle_center[0] + r_outer, circle_center[1] + r_outer * 0.58],
                   outline=(205, 175, 122, 160), width=3)

    # Anel imperial interno com losangos e glifos sutis
    s_draw.ellipse([circle_center[0] - r_inner, circle_center[1] - r_inner * 0.58,
                    circle_center[0] + r_inner, circle_center[1] + r_inner * 0.58],
                   outline=(215, 188, 135, 190), width=2)

    # Quatro medalhões solares nos pontos cardeais do círculo central
    for ang in [0, math.pi * 0.5, math.pi, math.pi * 1.5]:
        px = circle_center[0] + math.cos(ang) * r_inner
        py = circle_center[1] + math.sin(ang) * (r_inner * 0.58)
        s_draw.ellipse([px - 8, py - 5, px + 8, py + 5], fill=(210, 180, 125, 200), outline=(238, 218, 170, 230), width=1)

    # Linhas de cal de arena clássica (marcações discretas de gladiador nas fileiras)
    for ly in [330, 420, 510]:
        t_w = 460 - abs(ly - 420) * 1.2
        s_draw.line([(center_x - t_w, ly), (center_x + t_w, ly)], fill=(245, 235, 210, 65), width=1)

    # Suave textura de areia de grão fino em alta definição (limpa, sem granulação grossa)
    np_sand = np.array(sand_layer)
    # Adicionar sutil variação estocástica ultra-fina (desvio de apenas 2-3 tons)
    noise = (np.random.RandomState(42).randn(H, W) * 2.8).astype(np.int16)
    for c in range(3):
        channel = np_sand[:, :, c].astype(np.int16)
        mask = np_sand[:, :, 3] > 0
        channel[mask] = np.clip(channel[mask] + noise[mask], 0, 255)
        np_sand[:, :, c] = channel.astype(np.uint8)

    sand_filtered = Image.fromarray(np_sand, "RGBA")

    # Mesclar com a arena principal
    img.alpha_composite(sand_filtered)

    # 7. Moldura e parapeitos laterais do Coliseu (mármore romano delimitando as arquibancadas)
    draw_final = ImageDraw.Draw(img)
    # Lado esquerdo
    left_podium = [(0, 185), (145, 220), (120, 520), (0, 640), (0, 185)]
    draw_final.polygon(left_podium, fill=(48, 44, 52, 255))
    draw_final.line([(145, 220), (120, 520), (0, 640)], fill=pillar_hi, width=3)
    draw_final.line([(143, 220), (118, 520), (0, 640)], fill=(25, 22, 28, 255), width=2)

    # Lado direito
    right_podium = [(W, 185), (W - 145, 220), (W - 120, 520), (W, 640), (W, 185)]
    draw_final.polygon(right_podium, fill=(48, 44, 52, 255))
    draw_final.line([(W - 145, 220), (W - 120, 520), (W, 640)], fill=pillar_hi, width=3)
    draw_final.line([(W - 143, 220), (W - 118, 520), (W, 640)], fill=(25, 22, 28, 255), width=2)

    # Salvar arena
    ARENA_PATH.parent.mkdir(parents=True, exist_ok=True)
    img.save(ARENA_PATH, "PNG")
    print(f"Arena épica em alta definição gerada com sucesso em {ARENA_PATH} ({W}x{H})!")

if __name__ == "__main__":
    create_epic_coliseum()
