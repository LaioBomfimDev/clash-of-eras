"""Gera o ícone temático de time/equipe (ui_team.png) em 32x32 e 16x16 pixel art.
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "ui" / "icons"
OUT_DIR.mkdir(parents=True, exist_ok=True)

def generate_team_icon():
    # 32x32 RGBA
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Cores
    w = (255, 255, 255, 255)
    gold_light = (255, 235, 140, 255)
    gold = (245, 195, 50, 255)
    gold_dark = (180, 130, 25, 255)
    steel_light = (220, 235, 245, 255)
    steel = (160, 185, 210, 255)
    steel_dark = (90, 115, 140, 255)
    shadow = (15, 20, 30, 220)
    crest = (65, 185, 225, 255) # Ciano sutil

    # Soldado 1 (Esquerda / Trás): Centro em (11, 14)
    # Cabeça / Elmo
    d.ellipse([(8, 6), (15, 13)], fill=steel, outline=shadow)
    d.line([(10, 7), (13, 7)], fill=steel_light)
    # Viseira
    d.line([(9, 9), (14, 9)], fill=shadow)
    d.line([(10, 9), (13, 9)], fill=crest)
    # Ombros / Torso
    d.polygon([(5, 15), (17, 15), (15, 24), (7, 24)], fill=steel_dark, outline=shadow)
    d.line([(6, 15), (16, 15)], fill=steel)

    # Soldado 2 (Direita / Frente / Capitão Dourado): Centro em (20, 12)
    # Cabeça / Elmo Dourado com Crista
    # Crista vermelha/dourada
    d.line([(18, 2), (22, 2)], fill=gold_light)
    d.line([(17, 3), (23, 3)], fill=gold)
    d.ellipse([(16, 4), (24, 12)], fill=gold, outline=shadow)
    d.line([(18, 5), (22, 5)], fill=gold_light)
    # Viseira
    d.line([(17, 8), (23, 8)], fill=shadow)
    d.line([(18, 8), (22, 8)], fill=gold_light)
    # Ombros e armadura dourada
    d.polygon([(13, 14), (27, 14), (25, 26), (15, 26)], fill=gold_dark, outline=shadow)
    d.line([(14, 14), (26, 14)], fill=gold)
    d.line([(16, 17), (24, 17)], fill=gold_light)

    # Escudo frontal heróico de equipe no centro (11 a 21, 17 a 30)
    # Formato de escudo heráldico
    shield_pts = [(16, 16), (22, 17), (23, 23), (16, 30), (9, 23), (10, 17)]
    d.polygon(shield_pts, fill=steel, outline=shadow)
    # Borda dourada do escudo
    d.polygon([(16, 18), (20, 19), (21, 22), (16, 27), (11, 22), (12, 19)], fill=gold, outline=gold_dark)
    # Emblema central no escudo (cruz heróica / estrela)
    d.line([(16, 20), (16, 25)], fill=w, width=1)
    d.line([(13, 22), (19, 22)], fill=w, width=1)
    d.point([(16, 22)], fill=gold_light)

    # Brilho especular no canto superior esquerdo
    d.point([(11, 18)], fill=w)
    d.point([(19, 5)], fill=w)

    out_path = OUT_DIR / "ui_team.png"
    img.save(out_path)
    print("Salvo:", out_path)

if __name__ == "__main__":
    generate_team_icon()
