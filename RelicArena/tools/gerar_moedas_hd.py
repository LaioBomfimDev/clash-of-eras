"""Gera sprites de moedas de ouro em alta fidelidade e spritesheet animado (rotação 3D).

Cria:
  1. assets/ui/icons/ui_coin.png (Ícone de alta fidelidade com relevo chanfrado, brasão e brilho)
  2. assets/ui/icons/coin_sheet.png (Spritesheet com 8 frames de rotação 3D contínua)
  3. assets/ui/icons/coin_sheet.json (Atlas dos frames para carregamento no Godot / AutoSprite)
"""

import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "ui" / "icons"
FRAME_SIZE = 32
NUM_FRAMES = 8

# Paleta de ouro nobre (5 tons metálicos de iluminação)
GOLD_PALETTE = {
    "specular": (255, 255, 250, 255),    # Brilho puro de diamante/reflexo
    "light": (255, 240, 160, 255),       # Ouro claro luminoso
    "base": (245, 195, 45, 255),         # Ouro vivo puro
    "amber": (205, 145, 25, 255),        # Ouro âmbar profundo
    "shadow": (140, 85, 18, 255),        # Sombra de metal
    "edge_dark": (75, 40, 10, 255),      # Contorno de profundidade
    "crest": (255, 235, 130, 255),       # Brasão em relevo
    "crest_shadow": (175, 115, 20, 255), # Sombra do brasão
}


def draw_coin_frame(angle_rad: float, size: int = 32) -> Image.Image:
    """Desenha um quadro da moeda girando em 3D no ângulo fornecido."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = size / 2.0
    cy = size / 2.0
    r_max = (size / 2.0) - 2.5
    thickness = 3.5

    cos_a = math.cos(angle_rad)
    sin_a = math.sin(angle_rad)

    # Largura aparente da face circular (compressão horizontal pelo ângulo de visão)
    w_scale = abs(cos_a)
    w_radius = max(1.2, r_max * w_scale)

    # Direção do bordo da moeda (se cos_a >= 0, a face visível é a frente)
    face_is_front = cos_a >= 0

    # 1. Borda da espessura tridimensional (cilindro lateral da moeda)
    edge_offset = thickness * sin_a
    if abs(edge_offset) > 0.5:
        edge_x_shift = -edge_offset * 0.9
        # Desenha a lateral da moeda preenchendo o volume entre o centro e o deslocamento
        steps = 14
        for step in range(steps):
            t = float(step) / (steps - 1)
            ox = edge_x_shift * t
            draw.ellipse(
                [cx - w_radius + ox, cy - r_max, cx + w_radius + ox, cy + r_max],
                fill=GOLD_PALETTE["edge_dark"] if t > 0.7 else GOLD_PALETTE["shadow"],
                outline=GOLD_PALETTE["edge_dark"]
            )
            # Ranhuras de serrilhado no bordo
            if int(step) % 3 == 0:
                draw.line(
                    [(cx + ox, cy - r_max + 2), (cx + ox, cy + r_max - 2)],
                    fill=GOLD_PALETTE["amber"],
                    width=1
                )

    # 2. Borda externa / Aro chanfrado da face principal
    rim_box = [cx - w_radius, cy - r_max, cx + w_radius, cy + r_max]
    draw.ellipse(rim_box, fill=GOLD_PALETTE["amber"], outline=GOLD_PALETTE["edge_dark"])

    # 3. Chanfro interno luminoso
    inner_w = max(0.8, (r_max - 2.0) * w_scale)
    inner_h = r_max - 2.0
    inner_box = [cx - inner_w, cy - inner_h, cx + inner_w, cy + inner_h]
    draw.ellipse(inner_box, fill=GOLD_PALETTE["base"], outline=GOLD_PALETTE["light"])

    # 4. Campo rebaixado da moeda
    field_w = max(0.5, (r_max - 3.8) * w_scale)
    field_h = r_max - 3.8
    field_box = [cx - field_w, cy - field_h, cx + field_w, cy + field_h]
    field_col = GOLD_PALETTE["amber"] if not face_is_front else GOLD_PALETTE["base"]
    draw.ellipse(field_box, fill=field_col)

    # 5. Brasão em relevo (Coroa Real de 3 pontas + Estrela central)
    if w_scale > 0.35:
        # Posições relativas dos vértices da coroa escalados pela largura aparente
        crest_pts = [
            (cx - 5.5 * w_scale, cy + 2.5),
            (cx - 5.5 * w_scale, cy - 1.5),
            (cx - 3.0 * w_scale, cy + 0.5),
            (cx, cy - 3.5),
            (cx + 3.0 * w_scale, cy + 0.5),
            (cx + 5.5 * w_scale, cy - 1.5),
            (cx + 5.5 * w_scale, cy + 2.5),
        ]
        # Sombra do relevo
        shadow_pts = [(x, y + 1) for x, y in crest_pts]
        draw.polygon(shadow_pts, fill=GOLD_PALETTE["crest_shadow"])
        draw.polygon(crest_pts, fill=GOLD_PALETTE["crest"])

        # Jóia / Pérola no topo da ponta central da coroa
        draw.ellipse(
            [cx - 1.2 * w_scale, cy - 4.5, cx + 1.2 * w_scale, cy - 2.5],
            fill=GOLD_PALETTE["specular"]
        )

        # Base da coroa
        draw.line(
            [(cx - 4.5 * w_scale, cy + 3.5), (cx + 4.5 * w_scale, cy + 3.5)],
            fill=GOLD_PALETTE["crest_shadow"],
            width=1
        )

    # 6. Ponto de reflexo especular dinâmico que corre com o ângulo da luz
    spec_alpha = max(0.0, math.cos(angle_rad - math.pi / 4.0))
    if spec_alpha > 0.2:
        sx = cx - (w_radius * 0.45)
        sy = cy - (r_max * 0.45)
        draw.ellipse([sx - 1.5, sy - 1.5, sx + 1.5, sy + 1.5], fill=GOLD_PALETTE["specular"])
        # Brilho de faísca em cruz
        draw.line([(sx - 3, sy), (sx + 3, sy)], fill=(255, 255, 255, int(220 * spec_alpha)), width=1)
        draw.line([(sx, sy - 3), (sx, sy + 3)], fill=(255, 255, 255, int(220 * spec_alpha)), width=1)

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    # 1. Gera o ícone estático principal ui_coin.png em alta fidelidade (32x32)
    coin_icon = draw_coin_frame(0.0, size=FRAME_SIZE)
    coin_icon.save(OUT / "ui_coin.png")
    print(f"Salvo: {OUT / 'ui_coin.png'} (32x32)")

    # 2. Gera o spritesheet contínuo coin_sheet.png com 8 quadros
    sheet_width = FRAME_SIZE * NUM_FRAMES
    sheet_img = Image.new("RGBA", (sheet_width, FRAME_SIZE), (0, 0, 0, 0))

    atlas_frames = []

    for i in range(NUM_FRAMES):
        angle = (float(i) / NUM_FRAMES) * math.pi * 2.0
        frame_img = draw_coin_frame(angle, size=FRAME_SIZE)
        x_pos = i * FRAME_SIZE
        sheet_img.paste(frame_img, (x_pos, 0), frame_img)

        atlas_frames.append({
            "frame": {"x": x_pos, "y": 0, "w": FRAME_SIZE, "h": FRAME_SIZE},
            "duration_ms": 100
        })

    sheet_img.save(OUT / "coin_sheet.png")
    print(f"Salvo: {OUT / 'coin_sheet.png'} ({sheet_width}x{FRAME_SIZE})")

    # 3. Gera atlas JSON com metadados para integração
    atlas_data = {
        "meta": {
            "app": "AutoSprite / RelicArena Generator",
            "image": "coin_sheet.png",
            "format": "RGBA8888",
            "size": {"w": sheet_width, "h": FRAME_SIZE},
            "frame_count": NUM_FRAMES,
            "frame_width": FRAME_SIZE,
            "frame_height": FRAME_SIZE
        },
        "frames": atlas_frames
    }
    with open(OUT / "coin_sheet.json", "w", encoding="utf-8") as f:
        json.dump(atlas_data, f, indent=2)
    print(f"Salvo: {OUT / 'coin_sheet.json'}")


if __name__ == "__main__":
    main()
