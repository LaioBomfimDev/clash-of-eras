"""Gerador de arte pixel art para a tela de Lobby / Boas-Vindas de Clash of Eras.

Gera assets/ui/lobby_background.png em 640x360 com estética pixel art rica:
- Céu cósmico crepuscular com gradiente e estrelas
- Silhueta do Coliseu monumental com arcos, colunas e estandartes roxos/ouro
- Braseiros com fogo vivo ardendo nas pilastras
- Piso de pedra da arena com grande selo místico entalhado
- Iluminação atmosférica quente e vinheta suave
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

OUT_PATH = Path(__file__).resolve().parent.parent / "assets" / "ui" / "lobby_background.png"
WIDTH = 640
HEIGHT = 360

def gerar_lobby():
    img = Image.new("RGBA", (WIDTH, HEIGHT), (14, 12, 28, 255))
    draw = ImageDraw.Draw(img)

    # 1. Céu crepuscular místico (gradiente vertical com faixas de pixel art)
    sky_colors = [
        (10, 8, 24),     # y: 0 - 35
        (18, 14, 38),    # y: 35 - 70
        (32, 20, 56),    # y: 70 - 105
        (52, 26, 72),    # y: 105 - 135
        (84, 36, 78),    # y: 135 - 160
        (128, 52, 74),   # y: 160 - 180
        (168, 80, 72),   # y: 180 - 195
        (210, 120, 78),  # y: 195 - 205 (brilho do horizonte)
    ]
    
    for y in range(210):
        t = y / 210.0
        idx = min(len(sky_colors) - 1, int(t * len(sky_colors)))
        base_col = sky_colors[idx]
        # Dithering suave entre faixas
        for x in range(WIDTH):
            c = base_col
            # Pequena variação de ruído estelar / dither
            if y < 140 and (x * 7 + y * 13) % 19 == 0:
                c = tuple(min(255, val + 20) for val in base_col)
            draw.point((x, y), fill=c + (255,))

    # Estrelas no alto do céu
    import random
    rng = random.Random(20261012)
    for _ in range(85):
        sx = rng.randint(10, WIDTH - 10)
        sy = rng.randint(4, 120)
        brightness = rng.choice([(255, 245, 220), (220, 200, 255), (255, 220, 180)])
        draw.point((sx, sy), fill=brightness + (240,))
        if rng.random() < 0.25:
            draw.point((sx + 1, sy), fill=brightness + (140,))
            draw.point((sx - 1, sy), fill=brightness + (140,))
            draw.point((sx, sy + 1), fill=brightness + (140,))
            draw.point((sx, sy - 1), fill=brightness + (140,))

    # Lua mística crescente ao fundo
    moon_cx, moon_cy = 480, 56
    for dy in range(-16, 17):
        for dx in range(-16, 17):
            d2 = dx * dx + dy * dy
            if d2 <= 220:
                # Efeito crescente
                d_crescent = (dx - 5) * (dx - 5) + (dy - 2) * (dy - 2)
                if d_crescent > 140:
                    alpha = 255 if d2 <= 180 else 160
                    draw.point((moon_cx + dx, moon_cy + dy), fill=(245, 235, 210, alpha))
                elif d2 <= 190:
                    # Halo suave dentro da sombra
                    draw.point((moon_cx + dx, moon_cy + dy), fill=(60, 40, 75, 90))

    # Nuvens baixas no horizonte com silhueta púrpura
    cloud_pts = []
    for x in range(0, WIDTH, 8):
        cy = 185 + int(math.sin(x * 0.02) * 12 + math.cos(x * 0.05) * 6)
        draw.rectangle((x, cy, x + 8, 215), fill=(70, 32, 60, 255))
        draw.line([(x, cy), (x + 8, cy)], fill=(150, 70, 80, 255))

    # 2. Silhueta de Muralhas e Arcos Distantes do Coliseu (Plano Médio-Fundo)
    wall_color = (36, 26, 48)
    wall_highlight = (64, 44, 76)
    draw.rectangle((0, 175, WIDTH, 235), fill=wall_color + (255,))
    
    # Arcadas na muralha distante
    for arch_x in range(40, WIDTH - 30, 48):
        # Janela / arco vazado mostrando o céu crepuscular
        draw.polygon([
            (arch_x + 6, 210), (arch_x + 6, 192),
            (arch_x + 10, 185), (arch_x + 22, 185),
            (arch_x + 26, 192), (arch_x + 26, 210)
        ], fill=(130, 55, 70, 255))
        # Borda de pedra do arco
        draw.line([(arch_x + 5, 210), (arch_x + 5, 192), (arch_x + 10, 184), (arch_x + 22, 184), (arch_x + 27, 192), (arch_x + 27, 210)], fill=wall_highlight + (255,))

    # 3. Piso da Arena Imperial (Perspectiva de lajotas de pedra)
    # y = 225 até 360
    floor_top = 225
    stone_dark = (22, 18, 30)
    stone_mid = (38, 30, 46)
    stone_light = (58, 46, 68)
    gold_tint = (160, 110, 50)
    
    draw.rectangle((0, floor_top, WIDTH, HEIGHT), fill=stone_dark + (255,))
    
    # Faixas horizontais de lajotas com perspectiva
    grid_y_lines = [225, 232, 240, 250, 262, 276, 292, 312, 335, 360]
    for i in range(len(grid_y_lines) - 1):
        y0 = grid_y_lines[i]
        y1 = grid_y_lines[i + 1]
        t = i / float(len(grid_y_lines))
        band_col = (
            int(stone_mid[0] + (gold_tint[0] - stone_mid[0]) * 0.15 * (1.0 - t)),
            int(stone_mid[1] + (gold_tint[1] - stone_mid[1]) * 0.15 * (1.0 - t)),
            int(stone_mid[2] + (gold_tint[2] - stone_mid[2]) * 0.15 * (1.0 - t)),
        )
        draw.rectangle((0, y0, WIDTH, y1), fill=band_col + (255,))
        # Linha de argamassa
        draw.line([(0, y0), (WIDTH, y0)], fill=(16, 12, 22, 255))

    # Linhas radiais de perspectiva convergindo para o centro superior (320, 205)
    vanishing_point = (320, 205)
    for bx in range(-120, WIDTH + 140, 40):
        draw.line([vanishing_point, (bx, HEIGHT)], fill=(20, 14, 26, 200), width=1)

    # 4. Grande Selo Místico no Centro da Arena (Elipse entalhada com runas douradas)
    seal_cx, seal_cy = 320, 280
    seal_rx, seal_ry = 135, 50
    # Círculo externo
    for dy in range(-seal_ry, seal_ry + 1):
        for dx in range(-seal_rx, seal_rx + 1):
            norm = (dx / float(seal_rx)) ** 2 + (dy / float(seal_ry)) ** 2
            if norm <= 1.0:
                dist = math.sqrt(norm)
                if 0.92 <= dist <= 1.0:
                    draw.point((seal_cx + dx, seal_cy + dy), fill=(210, 160, 70, 230))
                elif 0.75 <= dist <= 0.82:
                    draw.point((seal_cx + dx, seal_cy + dy), fill=(160, 100, 210, 200))
                elif 0.35 <= dist <= 0.42:
                    draw.point((seal_cx + dx, seal_cy + dy), fill=(240, 190, 80, 240))
                elif dist < 0.35:
                    draw.point((seal_cx + dx, seal_cy + dy), fill=(48, 28, 64, 180))

    # Estrela de 8 pontas no centro do selo
    for angle_deg in range(0, 360, 45):
        rad = math.radians(angle_deg)
        x_ray = seal_cx + int(math.cos(rad) * seal_rx * 0.72)
        y_ray = seal_cy + int(math.sin(rad) * seal_ry * 0.72)
        draw.line([(seal_cx, seal_cy), (x_ray, y_ray)], fill=(225, 175, 75, 180), width=1)

    # 5. Colunas Monumentais de Pedra nas Laterais (Primeiro Plano)
    def desenhar_coluna(col_x, col_width=36):
        # Base da coluna
        draw.rectangle((col_x - 6, 260, col_x + col_width + 6, 360), fill=(26, 20, 32, 255))
        draw.line([(col_x - 6, 260), (col_x + col_width + 6, 260)], fill=(75, 58, 85, 255), width=2)
        # Tronco da coluna
        draw.rectangle((col_x, 0, col_x + col_width, 260), fill=(34, 26, 42, 255))
        # Caneluras (linhas verticais entalhadas)
        for fx in range(col_x + 4, col_x + col_width - 2, 7):
            draw.line([(fx, 0), (fx, 260)], fill=(22, 16, 28, 255), width=2)
            draw.line([(fx + 2, 0), (fx + 2, 260)], fill=(62, 48, 72, 255), width=1)
        # Capitel superior
        draw.polygon([
            (col_x - 10, 0), (col_x + col_width + 10, 0),
            (col_x + col_width + 4, 30), (col_x - 4, 30)
        ], fill=(42, 32, 52, 255))
        draw.line([(col_x - 10, 30), (col_x + col_width + 10, 30)], fill=(85, 68, 98, 255), width=2)

    desenhar_coluna(16, 40)
    desenhar_coluna(WIDTH - 56, 40)

    # Arquitrave superior conectando as colunas (topo da tela)
    draw.rectangle((0, 0, WIDTH, 28), fill=(28, 22, 36, 255))
    draw.line([(0, 28), (WIDTH, 28)], fill=(68, 52, 78, 255), width=2)
    # Friso com relevo dourado sutil
    for friso_x in range(60, WIDTH - 60, 24):
        draw.polygon([(friso_x + 4, 10), (friso_x + 12, 10), (friso_x + 8, 20)], fill=(180, 140, 60, 220))

    # Estandartes heráldicos reais roxos e dourados pendurados
    def desenhar_estandarte(est_x, est_y, est_w, est_h):
        # Haste de ferro
        draw.line([(est_x - 6, est_y), (est_x + est_w + 6, est_y)], fill=(120, 100, 70, 255), width=3)
        draw.circle((est_x - 6, est_y), 3, fill=(210, 170, 80, 255))
        draw.circle((est_x + est_w + 6, est_y), 3, fill=(210, 170, 80, 255))
        # Pano roxo nobre
        banner_pts = [
            (est_x, est_y), (est_x + est_w, est_y),
            (est_x + est_w, est_y + est_h - 12),
            (est_x + est_w // 2, est_y + est_h),
            (est_x, est_y + est_h - 12)
        ]
        draw.polygon(banner_pts, fill=(105, 32, 130, 255))
        # Borda dourada
        draw.polygon(banner_pts, outline=(225, 185, 75, 255), width=2)
        # Brasão / emblema no estandarte
        bcx = est_x + est_w // 2
        bcy = est_y + est_h // 2 - 4
        draw.polygon([(bcx, bcy - 12), (bcx + 9, bcy), (bcx, bcy + 12), (bcx - 9, bcy)], fill=(240, 200, 85, 255))
        draw.circle((bcx, bcy), 3, fill=(140, 45, 170, 255))

    desenhar_estandarte(68, 28, 44, 98)
    desenhar_estandarte(WIDTH - 112, 28, 44, 98)

    # 6. Braseiros Monumentais com Fogo Ardente e Halo Quente
    def desenhar_braseiro(bx, by):
        # Halo de luz quente volumétrica no chão e parede
        for hr in range(65, 0, -4):
            alpha = int(45 * (1.0 - hr / 65.0))
            draw.ellipse([(bx - hr, by - hr * 0.7), (bx + hr, by + hr * 0.7)], fill=(255, 140, 40, alpha))
        
        # Pedestal e tigela de bronze
        draw.rectangle((bx - 6, by + 12, bx + 6, by + 34), fill=(30, 24, 28, 255))
        draw.polygon([(bx - 14, by + 34), (bx + 14, by + 34), (bx + 9, by + 40), (bx - 9, by + 40)], fill=(55, 42, 38, 255))
        draw.polygon([
            (bx - 18, by + 12), (bx + 18, by + 12),
            (bx + 12, by + 24), (bx - 12, by + 24)
        ], fill=(78, 56, 44, 255))
        draw.line([(bx - 18, by + 12), (bx + 18, by + 12)], fill=(160, 115, 65, 255), width=2)
        
        # Chamas vivas (camadas externa rubra, média laranja e núcleo amarelo-branco)
        draw.polygon([
            (bx - 14, by + 12), (bx + 14, by + 12),
            (bx + 9, by - 6), (bx + 2, by - 26),
            (bx - 4, by - 18), (bx - 11, by - 4)
        ], fill=(235, 65, 30, 240))
        draw.polygon([
            (bx - 10, by + 11), (bx + 10, by + 11),
            (bx + 6, by - 3), (bx + 1, by - 20),
            (bx - 2, by - 14), (bx - 8, by - 2)
        ], fill=(255, 155, 45, 250))
        draw.polygon([
            (bx - 5, by + 10), (bx + 5, by + 10),
            (bx + 3, by - 1), (bx, by - 14), (bx - 3, by - 1)
        ], fill=(255, 240, 160, 255))
        # Faíscas voando
        draw.point((bx + 3, by - 32), fill=(255, 210, 80, 240))
        draw.point((bx - 4, by - 27), fill=(255, 180, 60, 240))
        draw.point((bx + 6, by - 22), fill=(255, 230, 120, 240))

    desenhar_braseiro(90, 185)
    desenhar_braseiro(WIDTH - 90, 185)

    # 7. Vinheta suave nas bordas para reforçar profundidade e foco
    vignette = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    cx, cy = WIDTH / 2.0, HEIGHT / 2.0
    max_d = math.sqrt(cx * cx + cy * cy)
    for y in range(0, HEIGHT, 2):
        for x in range(0, WIDTH, 2):
            dx = (x - cx) / cx
            dy = (y - cy) / cy
            d = math.sqrt(dx * dx + dy * dy)
            if d > 0.65:
                v_alpha = int(min(170, (d - 0.65) * 280))
                v_draw.rectangle((x, y, x + 2, y + 2), fill=(8, 6, 14, v_alpha))
                
    img = Image.alpha_composite(img, vignette)

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT_PATH)
    print(f"Lobby background pixel art salvo em {OUT_PATH} ({WIDTH}x{HEIGHT})")

if __name__ == "__main__":
    gerar_lobby()
