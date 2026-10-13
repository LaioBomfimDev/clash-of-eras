"""
Gera as artes complementares para a rodada do Boss Desenvolvedor:
1. Esfera de Loot Brilhante (Orbe de Espólio mágica em 32x32 com resplendor e faíscas)
2. Ícones dos 3 Drops:
   - Ouro / Moedas da Vitória (ouro brilhante)
   - Item Raro / Baú Arcano (item dropado)
   - Coração de Vida Extra (+1 Vida com aura radiante para os 20% de chance)
3. VFX da Explosão de Fogo Roxo (detonação mágica de 48x48)
4. Variações/Quadros do Furacão de Fogo para animação rodopiante contínua
"""

import math
import os
from PIL import Image, ImageDraw

def create_loot_orb():
    """Gera a Esfera Brilhante de Loot (32x32)"""
    size = 32
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 16, 16

    # Resplendor difuso externo
    for r in range(14, 8, -1):
        alpha = int(40 * (1.0 - (r - 8) / 6.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(210, 160, 255, alpha))

    # Borda externa da esfera (Ametista radiante com Ouro)
    draw.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(130, 40, 220, 230), outline=(255, 220, 100, 255))
    
    # Corpo da esfera
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(170, 70, 250, 255))
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(215, 130, 255, 255))
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(245, 210, 255, 255))

    # Ponto de brilho especular / reflexo estrelar
    draw.ellipse([cx - 5, cy - 6, cx - 2, cy - 3], fill=(255, 255, 255, 255))
    draw.point((cx - 4, cy - 5), fill=(255, 255, 255, 255))

    # Faíscas orbitais douradas
    sparks = [(cx + 10, cy - 5), (cx - 10, cy + 6), (cx + 6, cy + 10), (cx - 7, cy - 9)]
    for sx, sy in sparks:
        draw.rectangle([sx, sy, sx + 1, sy + 1], fill=(255, 240, 140, 240))

    return img


def create_drop_icon_gold():
    """Ícone de Recompensa: Moedas / Ouro (28x28)"""
    size = 28
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Brilho de fundo
    draw.ellipse([2, 2, 25, 25], fill=(255, 215, 0, 45))

    # Pilha de moedas douradas estilizadas
    # Moeda de trás
    draw.ellipse([7, 5, 21, 15], fill=(160, 100, 15, 255), outline=(90, 50, 5, 255))
    draw.ellipse([8, 6, 20, 14], fill=(245, 195, 45, 255))

    # Moeda da esquerda
    draw.ellipse([4, 11, 18, 22], fill=(180, 115, 20, 255), outline=(90, 50, 5, 255))
    draw.ellipse([5, 12, 17, 21], fill=(255, 210, 50, 255))
    draw.ellipse([7, 14, 15, 19], fill=(230, 175, 30, 255))

    # Moeda principal da frente
    draw.ellipse([10, 12, 24, 23], fill=(190, 125, 20, 255), outline=(90, 50, 5, 255))
    draw.ellipse([11, 13, 23, 22], fill=(255, 225, 75, 255))
    draw.ellipse([13, 15, 21, 20], fill=(255, 245, 160, 255))
    draw.point((14, 16), fill=(255, 255, 255, 255))

    return img


def create_drop_icon_item():
    """Ícone de Recompensa: Item Raro / Baú de Equipamento (28x28)"""
    size = 28
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Brilho azul safira/ciano
    draw.ellipse([2, 2, 25, 25], fill=(0, 180, 255, 45))

    # Baú rúnico
    # Base de madeira nobre
    draw.rectangle([5, 11, 22, 22], fill=(105, 55, 25, 255), outline=(45, 20, 10, 255))
    # Tampa curva
    draw.ellipse([5, 7, 22, 14], fill=(145, 80, 35, 255), outline=(45, 20, 10, 255))
    # Friso metálico dourado
    draw.rectangle([12, 7, 15, 22], fill=(255, 200, 50, 255), outline=(130, 80, 10, 255))
    # Fechadura brilhante de safira
    draw.ellipse([11, 12, 16, 17], fill=(0, 220, 255, 255), outline=(255, 255, 255, 255))

    return img


def create_drop_icon_life():
    """Ícone de Recompensa: Vida Extra (+1 Coração Radiante, 20% chance) (28x28)"""
    size = 28
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Aura dourada e vermelha brilhante
    draw.ellipse([1, 1, 26, 26], fill=(255, 50, 80, 40))
    draw.ellipse([3, 3, 24, 24], fill=(255, 215, 0, 50))

    # Coração vermelho rubi
    # Desenho dos dois lobos superiores e bico inferior
    draw.ellipse([5, 6, 14, 15], fill=(235, 30, 60, 255), outline=(120, 10, 25, 255))
    draw.ellipse([13, 6, 22, 15], fill=(235, 30, 60, 255), outline=(120, 10, 25, 255))
    draw.polygon([(5, 11), (22, 11), (14, 22)], fill=(235, 30, 60, 255))
    draw.line([(5, 11), (14, 22)], fill=(120, 10, 25, 255), width=1)
    draw.line([(22, 11), (14, 22)], fill=(120, 10, 25, 255), width=1)

    # Realce interno brilhante
    draw.ellipse([7, 8, 12, 12], fill=(255, 120, 150, 255))
    draw.ellipse([15, 8, 19, 12], fill=(255, 120, 150, 255))
    draw.point((8, 9), fill=(255, 255, 255, 255))

    # Texto "+1" dourado brilhante no canto superior direito
    # Simulação pixel art do +1
    draw.line([(19, 3), (19, 7)], fill=(255, 240, 100, 255), width=1)
    draw.line([(17, 5), (21, 5)], fill=(255, 240, 100, 255), width=1)
    draw.line([(24, 3), (24, 8)], fill=(255, 240, 100, 255), width=1)

    return img


def create_purple_fire_explosion():
    """Gera o VFX de Explosão de Fogo Roxo (48x48)"""
    size = 48
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 24, 24

    # Onda de choque esférica
    for r in range(22, 12, -2):
        alpha = int(55 * (1.0 - (r - 12) / 10.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(180, 50, 255, alpha))

    # Chamas e labaredas em estrela/radial
    angles = [0, 40, 80, 120, 160, 200, 240, 280, 320]
    for a in angles:
        rad = math.radians(a)
        x_tip = cx + int(19 * math.cos(rad))
        y_tip = cy + int(19 * math.sin(rad))
        draw.line([(cx, cy), (x_tip, y_tip)], fill=(150, 30, 230, 220), width=3)
        draw.point((x_tip, y_tip), fill=(230, 160, 255, 255))

    # Núcleo explosivo incandescente violeta/branco
    draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=(160, 40, 240, 255), outline=(100, 10, 170, 255))
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(210, 110, 255, 255))
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 230, 255, 255))

    return img


def create_fire_tornado_frames():
    """Gera variações angulares rodopiantes do furacão de fogo a partir da imagem enviada"""
    src = "RelicArena/assets/vfx/boss_dev/furacao_fogo.png"
    if not os.path.exists(src):
        return []
    base_img = Image.open(src)
    frames = []
    # Cria 4 rotações sutis e deformações de vórtice para criar animação fluida
    for angle in [0, 8, 16, 24]:
        # Leve rotação e escala oscilante para dar sensação de sucção e giro
        rotated = base_img.rotate(angle, resample=Image.Resampling.BICUBIC)
        frames.append(rotated)
    return frames


def create_red_fire_projectile():
    """Gera o VFX de Projétil de Fogo Vermelho ardente (32x32)"""
    size = 32
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 18, 16

    # Rastro e cauda de chamas incandescentes
    for i in range(12):
        tx = cx - 4 - i
        ty = cy + int(math.sin(i * 0.8) * 2.5)
        r = max(1, 5 - int(i * 0.35))
        alpha = int(220 * (1.0 - i / 12.0))
        draw.ellipse([tx - r, ty - r, tx + r, ty + r], fill=(240, 40 + i * 8, 10, alpha))
        if i % 3 == 0:
            draw.point((tx, ty - r - 1), fill=(255, 160, 40, alpha))
            draw.point((tx, ty + r + 1), fill=(255, 100, 20, alpha))

    # Resplendor difuso de calor
    for r in range(12, 6, -1):
        alpha = int(45 * (1.0 - (r - 6) / 6.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 70, 20, alpha))

    # Esfera externa de fogo escarlate
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(225, 35, 15, 245), outline=(150, 15, 5, 255))
    draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=(255, 110, 20, 255))
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 205, 50, 255))
    draw.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 255, 210, 255))
    draw.point((cx + 1, cy - 1), fill=(255, 255, 255, 255))

    return img


def create_red_fire_explosion():
    """Gera o VFX de Explosão de Fogo Vermelho (48x48)"""
    size = 48
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 24, 24

    # Onda de choque esférica ardente
    for r in range(22, 12, -2):
        alpha = int(55 * (1.0 - (r - 12) / 10.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 50, 10, alpha))

    # Chamas e labaredas em estrela/radial
    angles = [0, 40, 80, 120, 160, 200, 240, 280, 320]
    for a in angles:
        rad = math.radians(a)
        x_tip = cx + int(19 * math.cos(rad))
        y_tip = cy + int(19 * math.sin(rad))
        draw.line([(cx, cy), (x_tip, y_tip)], fill=(240, 50, 10, 230), width=3)
        draw.point((x_tip, y_tip), fill=(255, 200, 50, 255))

    # Núcleo explosivo incandescente escarlate/laranja/branco
    draw.ellipse([cx - 12, cy - 12, cx + 12, cy + 12], fill=(230, 40, 10, 255), outline=(140, 15, 5, 255))
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(255, 120, 20, 255))
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 240, 180, 255))

    return img


def main():
    print("Gerando assets complementares para a batalha do Boss Desenvolvedor...")

    out_vfx = "RelicArena/assets/vfx/boss_dev"
    out_ui = "RelicArena/assets/ui/boss_dev"
    os.makedirs(out_vfx, exist_ok=True)
    os.makedirs(out_ui, exist_ok=True)

    # 1. Esfera de Loot Brilhante
    orb = create_loot_orb()
    orb.save(os.path.join(out_ui, "loot_orb_brilhante.png"))
    orb.save(os.path.join(out_vfx, "loot_orb_brilhante.png"))
    print("Salvo: loot_orb_brilhante.png (32x32)")

    # 2. Ícones de Recompensa
    gold = create_drop_icon_gold()
    gold.save(os.path.join(out_ui, "drop_ouro.png"))
    print("Salvo: drop_ouro.png (28x28)")

    item = create_drop_icon_item()
    item.save(os.path.join(out_ui, "drop_item.png"))
    print("Salvo: drop_item.png (28x28)")

    life = create_drop_icon_life()
    life.save(os.path.join(out_ui, "drop_vida_extra.png"))
    print("Salvo: drop_vida_extra.png (28x28)")

    # 3. Explosão do Fogo Roxo
    purple_exp = create_purple_fire_explosion()
    purple_exp.save(os.path.join(out_vfx, "explosao_fogo_roxo.png"))
    print("Salvo: explosao_fogo_roxo.png (48x48)")

    # 4. Projétil e Explosão do Fogo Vermelho
    red_proj = create_red_fire_projectile()
    red_proj.save(os.path.join(out_vfx, "fogo_vermelho_projetil.png"))
    print("Salvo: fogo_vermelho_projetil.png (32x32)")

    red_exp = create_red_fire_explosion()
    red_exp.save(os.path.join(out_vfx, "explosao_fogo_vermelho.png"))
    print("Salvo: explosao_fogo_vermelho.png (48x48)")

    # 5. Quadros do Furacão de Fogo
    tornado_frames = create_fire_tornado_frames()
    for idx, f in enumerate(tornado_frames):
        f.save(os.path.join(out_vfx, f"furacao_fogo_frame_{idx}.png"))
    print(f"Salvos {len(tornado_frames)} frames de animação do furacão de fogo!")

    print("Todas as artes complementares foram geradas com sucesso!")


if __name__ == "__main__":
    main()
