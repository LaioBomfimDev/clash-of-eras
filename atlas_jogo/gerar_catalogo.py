import os
import json
import glob

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "RelicArena", "assets")

def rel_path(abs_p):
    p = os.path.relpath(abs_p, os.path.join(BASE_DIR, "atlas_jogo")).replace("\\", "/")
    return p

# Lista oficial de personagens
CHAR_INFO = {
    "neymar": {"name": "Neymar Jr.", "class": "Artilheiro / DPS", "origin": "PixelLab Lote 01/03 (Humano Realista)"},
    "caramelo": {"name": "Vira-lata Caramelo", "class": "Assassino / Sangramento", "origin": "PixelLab Lote 01 (Cachorro Clássico)"},
    "obama": {"name": "Obama", "class": "Tanque / Defesa", "origin": "PixelLab Lote 01/03 (Humano com Mala)"},
    "zumbi": {"name": "Zumbi dos Palmares", "class": "Guerreiro / Crítico", "origin": "PixelLab Lote 04 HD (Estátua com Cicatrizes)"},
    "michael": {"name": "Michael Jackson", "class": "Suporte / Escudo & Cura", "origin": "PixelLab Lote 02 (Moonwalk)"},
    "barbie": {"name": "Barbie", "class": "Comandante / Vanguarda", "origin": "Reformulação Local Lote 04 HD (Vestido e Bolsa de Grife)"},
    "ken": {"name": "Ken", "class": "Guardião / Protetor", "origin": "Reformulação Local Lote 04 HD (Surfista e Prancha de Surfe)"},
    "elon": {"name": "Elon Musk", "class": "Atirador / Fogueteiro", "origin": "PixelLab Lote 04 HD (Lança-chamas e Cybertruck)"},
    "snoop": {"name": "Snoop Dogg", "class": "Suporte / Fumaça & Buff", "origin": "PixelLab Lote 03 (48px com Charutão)"},
    "lula": {"name": "Lula", "class": "Líder / Renascimento Divino", "origin": "PixelLab Lote 03 (48px com Asas Divinas)"},
    "bob_marley": {"name": "Bob Marley", "class": "Místico / Ritmo & Aura", "origin": "PixelLab Lote 03 (48px Cores Reggae)"},
    "rapunzel": {"name": "Rapunzel", "class": "Controle / Cabelo Mágico", "origin": "PixelLab Lote 03 (48px Cabelo Longo)"},
    "boss_dev": {"name": "O Criador (Boss Dev)", "class": "Chefe PvE / Arcano", "origin": "PixelLab Folha Conceitual Oficial (Opção 1A e 2C)"}
}

DIRECTIONS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

def scan_character_base_frames(char_key):
    char_dir = os.path.join(ASSETS_DIR, "characters", char_key)
    versions = {}
    
    # 1. Procura subpastas de estilos conhecidos
    for candidate in ["grande_04", "realista_03", "original", "idle"]:
        c_dir = os.path.join(char_dir, candidate)
        if os.path.isdir(c_dir):
            rot_dir = os.path.join(c_dir, "original", "Idle", "rotations")
            if not os.path.isdir(rot_dir):
                rot_dir = os.path.join(c_dir, "Idle", "rotations")
            if not os.path.isdir(rot_dir):
                rot_dir = c_dir
            
            frames = {}
            for d in DIRECTIONS:
                f_path = os.path.join(rot_dir, f"{d}.png")
                if os.path.isfile(f_path):
                    frames[d] = rel_path(f_path)
            
            if frames:
                label = candidate
                if candidate == "grande_04":
                    label = "Lote 04 HD (128x128)"
                elif candidate == "realista_03":
                    label = "Lote 03 Realista (~48-50px)"
                elif candidate == "original":
                    label = "Original Inicial"
                versions[label] = frames

    # Caso especial para Zumbi níveis 2 e 3
    if char_key == "zumbi":
        for lvl in ["nivel_2", "nivel_3"]:
            lvl_dir = os.path.join(char_dir, "grande_04", "niveis", lvl, "rotations")
            if os.path.isdir(lvl_dir):
                frames = {}
                for d in DIRECTIONS:
                    f_path = os.path.join(lvl_dir, f"{d}.png")
                    if os.path.isfile(f_path):
                        frames[d] = rel_path(f_path)
                if frames:
                    versions[f"Lote 04 HD ({lvl.replace('_', ' ').title()})"] = frames

    # Caso especial para Boss Dev poses oficiais e turnaround
    if char_key == "boss_dev":
        boss_poses = {}
        for fname in ["idle_south.png", "cast_south_east.png", "cast_north.png"]:
            p = os.path.join(char_dir, "game_ready", fname)
            if os.path.isfile(p):
                boss_poses[fname.replace(".png", "")] = rel_path(p)
        if boss_poses:
            versions["Poses Oficiais no Jogo"] = boss_poses

        # Turnarounds conceituais
        ref_dir = os.path.join(char_dir, "referencias")
        if os.path.isdir(ref_dir):
            refs = {}
            for img in glob.glob(os.path.join(ref_dir, "*.png")):
                refs[os.path.basename(img).replace(".png", "")] = rel_path(img)
            if refs:
                versions["Turnarounds & Conceitos Originais"] = refs

    return versions

def scan_character_animations(char_key):
    anim_dir = os.path.join(ASSETS_DIR, "characters", char_key, "animacoes_16f")
    actions = {}
    if not os.path.isdir(anim_dir):
        return actions
    
    for action in sorted(os.listdir(anim_dir)):
        act_path = os.path.join(anim_dir, action)
        if os.path.isdir(act_path):
            directions_data = {}
            for d in DIRECTIONS:
                d_path = os.path.join(act_path, d)
                if os.path.isdir(d_path):
                    frames = []
                    for i in range(16):
                        f_name = f"frame_{i:03d}.png"
                        f_file = os.path.join(d_path, f_name)
                        if os.path.isfile(f_file):
                            frames.append(rel_path(f_file))
                    if frames:
                        directions_data[d] = frames
            if directions_data:
                actions[action] = {
                    "fps": 24,
                    "frame_count": 16,
                    "directions": directions_data
                }
    return actions

def scan_boss_data():
    boss_dir = os.path.join(ASSETS_DIR, "characters", "boss_dev")
    mobs = {}
    mobs_dir = os.path.join(boss_dir, "monstros")
    if os.path.isdir(mobs_dir):
        for img in glob.glob(os.path.join(mobs_dir, "*.png")):
            if not img.endswith(".import"):
                key = os.path.basename(img).replace(".png", "")
                mobs[key] = {
                    "name": "Lodo Negro de Olho" if "slime" in key else "Aberração Cósmica (Olho Tentáculos)",
                    "file": rel_path(img)
                }
    
    vfx_boss = {}
    refino_dir = os.path.join(ASSETS_DIR, "vfx", "refino_bob_boss_02")
    if os.path.isdir(refino_dir):
        for sub in sorted(os.listdir(refino_dir)):
            sub_p = os.path.join(refino_dir, sub)
            if os.path.isdir(sub_p):
                frames = []
                for f in sorted(glob.glob(os.path.join(sub_p, "*.png"))):
                    if not f.endswith(".import"):
                        frames.append(rel_path(f))
                if frames:
                    vfx_boss[sub] = frames

    return {"mobs": mobs, "vfx": vfx_boss}

def scan_maps_data():
    arena_dir = os.path.join(ASSETS_DIR, "arena")
    maps = {}
    if os.path.isdir(arena_dir):
        for f in glob.glob(os.path.join(arena_dir, "*.png")):
            if not f.endswith(".import"):
                key = os.path.basename(f).replace(".png", "")
                name = key
                if "coliseu_epico_hd" in key:
                    name = "Coliseu Épico HD (1340x760 - Resolução Nativa Atual)"
                elif "coliseu_estudo" in key:
                    name = "Coliseu Estudo 02 (320x180 - Versão Anterior)"
                elif "braseiro" in key:
                    name = "Braseiro de Ferro Fundido (Prop de Iluminação)"
                maps[key] = {
                    "name": name,
                    "file": rel_path(f)
                }
    return maps

def scan_vfx_data():
    vfx_dir = os.path.join(ASSETS_DIR, "vfx")
    effects = {}
    
    # 1. VFX novos do elenco
    novos_dir = os.path.join(vfx_dir, "elenco_novos")
    if os.path.isdir(novos_dir):
        for skill in sorted(os.listdir(novos_dir)):
            s_path = os.path.join(novos_dir, skill)
            sheet = os.path.join(s_path, "sheet.png")
            if os.path.isfile(sheet):
                effects[skill] = {
                    "name": skill.replace("_", " ").title(),
                    "sheet": rel_path(sheet),
                    "frames_count": 12,
                    "frame_width": 96,
                    "frame_height": 96,
                    "fps": 16
                }
    
    # 2. Outros VFX avulsos
    for sub in sorted(os.listdir(vfx_dir)):
        sub_p = os.path.join(vfx_dir, sub)
        if os.path.isdir(sub_p) and sub not in ["elenco_novos", "refino_bob_boss_02"]:
            whole = os.path.join(sub_p, "game_pack", "whole.png")
            if not os.path.isfile(whole):
                orig = os.path.join(sub_p, "original")
                if os.path.isdir(orig):
                    pngs = glob.glob(os.path.join(orig, "*.png"))
                    if pngs:
                        whole = pngs[0]
            if os.path.isfile(whole):
                effects[sub] = {
                    "name": sub.replace("_", " ").title(),
                    "file": rel_path(whole)
                }
        elif os.path.isfile(sub_p) and sub_p.endswith(".png") and not sub_p.endswith(".import"):
            key = os.path.basename(sub_p).replace(".png", "")
            effects[key] = {
                "name": key.replace("_", " ").title(),
                "file": rel_path(sub_p)
            }

    return effects

def main():
    catalog = {
        "title": "Clash of Eras - Atlas Visual e Compêndio Completo de Assets",
        "generated_at": "2026-10-15",
        "characters": {},
        "boss": scan_boss_data(),
        "maps": scan_maps_data(),
        "vfx": scan_vfx_data()
    }
    
    for key, info in CHAR_INFO.items():
        base_frames = scan_character_base_frames(key)
        animations = scan_character_animations(key)
        catalog["characters"][key] = {
            "name": info["name"],
            "class": info["class"],
            "origin": info["origin"],
            "base_frames": base_frames,
            "animations": animations
        }

    out_file = os.path.join(BASE_DIR, "atlas_jogo", "catalogo_assets.json")
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    
    print(f"Catálogo gerado com sucesso em: {out_file}")
    print(f"Total de personagens indexados: {len(catalog['characters'])}")
    print(f"Total de mapas: {len(catalog['maps'])}")
    print(f"Total de VFX: {len(catalog['vfx'])}")

if __name__ == "__main__":
    main()
