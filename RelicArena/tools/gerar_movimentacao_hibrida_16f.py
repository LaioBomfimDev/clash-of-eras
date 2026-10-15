import json
import math
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "characters"
MANIFEST_PATH = ASSETS / "animations_manifest.json"

HEROES = [
    "neymar", "caramelo", "obama", "zumbi", "michael",
    "barbie", "ken", "elon", "snoop", "lula",
    "bob_marley", "rapunzel", "boss_dev"
]

DIRECTIONS = [
    "east", "west", "south", "north",
    "south-east", "south-west", "north-east", "north-west"
]

def inverse_map_walk_frame(arr: np.ndarray, phase: float, is_lateral: bool, is_quadruped: bool = False) -> np.ndarray:
    """
    Inverse mapping pixel-art walk cycle frame.
    Garante que a imagem resultante não tenha lacunas (gaps) e preserve
    estritamente os valores exatos de pixels da imagem fonte.
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    x_left, x_right = int(x_idx.min()), int(x_idx.max())
    char_h = max(1, y_bot - y_top)
    cx = (x_left + x_right) / 2.0

    # Altura das pernas (a partir de 60% da altura do personagem)
    y_hip = int(y_top + char_h * 0.58)

    # Bobbing vertical: 2 ciclos completos de elevação por passada completa (16 frames)
    # No impacto (fases 0 e pi) corpo desce 1px, na passagem (fases pi/2 e 3pi/2) corpo sobe 1px
    bob = int(round(-math.sin(phase * 2.0) * 1.0))

    out = np.zeros_like(arr)

    # Parametros de passada
    stride = math.sin(phase) * 1.7
    lift = max(0.0, math.cos(phase)) * 1.5

    for ny in range(h):
        for nx in range(w):
            # Mapeamento reverso: descobrir qual pixel (src_y, src_x) corresponde a (ny, nx)
            # Desfaz o bobbing vertical
            src_y = ny - bob
            src_x = nx

            if y_hip <= src_y <= y_bot + 4:
                t_leg = (src_y - y_hip) / max(1.0, (y_bot - y_hip))
                t_leg = min(1.0, max(0.0, t_leg))

                if is_quadruped:
                    # Trote quadrúpede (Caramelo): dianteira vs traseira
                    if nx < cx:
                        # Patas esquerdas
                        dx = math.sin(phase) * 1.4 * t_leg
                        dy = -max(0.0, math.cos(phase)) * 1.2 * t_leg
                    else:
                        # Patas direitas
                        dx = math.sin(phase + math.pi) * 1.4 * t_leg
                        dy = -max(0.0, math.cos(phase + math.pi)) * 1.2 * t_leg
                    src_x = int(round(nx - dx))
                    src_y = int(round(src_y - dy))
                elif is_lateral:
                    # Perfil lateral: perna avança/recua
                    dx = stride * t_leg
                    dy = -lift * t_leg if stride > 0 else 0.0
                    src_x = int(round(nx - dx))
                    src_y = int(round(src_y - dy))
                else:
                    # Frontal ou 3/4: pernas alternadas
                    if nx < cx:
                        # Perna esquerda
                        dx = stride * t_leg * 0.6
                        dy = -lift * t_leg
                    else:
                        # Perna direita
                        dx = -stride * t_leg * 0.6
                        dy = -max(0.0, math.cos(phase + math.pi)) * 1.5 * t_leg
                    src_x = int(round(nx - dx))
                    src_y = int(round(src_y - dy))

            # Validação de limites
            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = arr[src_y, src_x]

    return out

def get_character_rotation_source(hero: str, direction: str) -> Path:
    """Encontra o PNG fonte mais fidedigno para o herói e direção."""
    if hero == "michael":
        return None # Michael usa frames do moonwalk
    if hero == "boss_dev":
        p = ASSETS / "boss_dev" / "game_ready" / f"idle_{direction}.png"
        if p.exists():
            return p
        # Fallback
        return ASSETS / "boss_dev" / "game_ready" / "idle_south.png"
    if hero == "elon":
        p = ASSETS / "elon" / "grande_04" / "original" / "Idle" / "rotations" / f"{direction}.png"
        if p.exists():
            return p
    if hero == "zumbi":
        return None # Zumbi usa frames do PixelLab
    
    # Procura nas pastas realista_03 ou original
    for sub in ["realista_03/original/Idle/rotations", "original/Idle/rotations", "rotations"]:
        p = ASSETS / hero / sub / f"{direction}.png"
        if p.exists():
            return p
    return None

def interpolate_sequence_16(frames_orig: list[Image.Image]) -> list[Image.Image]:
    """Interpola uma sequência original (ex: 9 frames) para 16 frames fluidos."""
    n_orig = len(frames_orig)
    out_frames = []
    for i in range(16):
        t = (i * (n_orig - 1)) / 15.0
        idx_low = int(math.floor(t))
        idx_high = min(n_orig - 1, int(math.ceil(t)))
        frac = t - idx_low
        if frac < 0.15:
            out_frames.append(frames_orig[idx_low].copy())
        elif frac > 0.85:
            out_frames.append(frames_orig[idx_high].copy())
        else:
            # Mistura Nearest / Alpha blend discreto preservando o pixel art
            img_a = frames_orig[idx_low]
            img_b = frames_orig[idx_high]
            blended = Image.blend(img_a, img_b, frac)
            out_frames.append(blended)
    return out_frames

def process_michael(dest_base: Path) -> dict:
    src_base = ROOT / "assets" / "michael" / "original" / "Idle" / "animations" / "The_subject_performs_the_classic_moonwalk_slide_rh"
    dir_entries = {}
    for d in DIRECTIONS:
        folder = src_base / d
        if not folder.exists():
            continue
        orig_pngs = sorted(folder.glob("frame_*.png"))
        if not orig_pngs:
            continue
        frames = [Image.open(p).convert("RGBA") for p in orig_pngs]
        frames_16 = interpolate_sequence_16(frames)
        
        target_dir = dest_base / d
        target_dir.mkdir(parents=True, exist_ok=True)
        frame_paths = []
        for i, f in enumerate(frames_16):
            fn = f"frame_{i:03d}.png"
            f.save(target_dir / fn)
            frame_paths.append(f"res://assets/characters/michael/animacoes_16f/walk/{d}/{fn}")
        
        # Âncora: centro horizontal e base dos pés
        arr = np.array(frames_16[0])
        alpha = arr[:, :, 3]
        y_idx, x_idx = np.where(alpha > 12)
        anchor_y = int(y_idx.max()) + 1 if len(y_idx) > 0 else 46
        anchor_x = int(frames_16[0].width // 2)
        dir_entries[d] = {
            "frames": frame_paths,
            "anchor": [anchor_x, anchor_y],
            "fps": 24
        }
    return dir_entries

def process_zumbi(dest_base: Path) -> dict:
    dir_entries = {}
    # East
    east_folder = ASSETS / "zumbi" / "animacoes_01" / "exports" / "walk_east_02" / "original" / "Idle" / "animations" / "walk_ground_v2" / "east"
    if east_folder.exists():
        orig_pngs = sorted(east_folder.glob("frame_*.png"))
        if orig_pngs:
            frames = [Image.open(p).convert("RGBA") for p in orig_pngs]
            frames_16 = interpolate_sequence_16(frames)
            
            # Salvar East
            e_dir = dest_base / "east"
            e_dir.mkdir(parents=True, exist_ok=True)
            w_dir = dest_base / "west"
            w_dir.mkdir(parents=True, exist_ok=True)
            
            e_paths = []
            w_paths = []
            for i, f in enumerate(frames_16):
                fn = f"frame_{i:03d}.png"
                f.save(e_dir / fn)
                e_paths.append(f"res://assets/characters/zumbi/animacoes_16f/walk/east/{fn}")
                
                # West espelhado
                f_w = ImageOps.mirror(f)
                f_w.save(w_dir / fn)
                w_paths.append(f"res://assets/characters/zumbi/animacoes_16f/walk/west/{fn}")
                
            dir_entries["east"] = {"frames": e_paths, "anchor": [64, 149], "fps": 24}
            dir_entries["west"] = {"frames": w_paths, "anchor": [64, 149], "fps": 24}
            
    # North-East / North-West
    ne_folder = ASSETS / "zumbi" / "animacoes_02" / "walk" / "north-east"
    if ne_folder.exists():
        orig_pngs = sorted(ne_folder.glob("frame_*.png"))
        if orig_pngs:
            frames = [Image.open(p).convert("RGBA") for p in orig_pngs]
            frames_16 = interpolate_sequence_16(frames)
            ne_dir = dest_base / "north-east"
            ne_dir.mkdir(parents=True, exist_ok=True)
            nw_dir = dest_base / "north-west"
            nw_dir.mkdir(parents=True, exist_ok=True)
            
            ne_paths = []
            nw_paths = []
            for i, f in enumerate(frames_16):
                fn = f"frame_{i:03d}.png"
                f.save(ne_dir / fn)
                ne_paths.append(f"res://assets/characters/zumbi/animacoes_16f/walk/north-east/{fn}")
                
                f_nw = ImageOps.mirror(f)
                f_nw.save(nw_dir / fn)
                nw_paths.append(f"res://assets/characters/zumbi/animacoes_16f/walk/north-west/{fn}")
                
            dir_entries["north-east"] = {"frames": ne_paths, "anchor": [64, 145], "fps": 24}
            dir_entries["north-west"] = {"frames": nw_paths, "anchor": [64, 145], "fps": 24}
            
    return dir_entries

def process_procedural_hero(hero: str, dest_base: Path) -> dict:
    dir_entries = {}
    is_quad = (hero == "caramelo")
    
    for d in DIRECTIONS:
        src = get_character_rotation_source(hero, d)
        if src is None or not src.exists():
            # Fallback para south se nao existir a direcao especifica
            src = get_character_rotation_source(hero, "south")
        if src is None or not src.exists():
            continue
            
        im = Image.open(src).convert("RGBA")
        arr = np.array(im)
        alpha = arr[:, :, 3]
        y_idx, x_idx = np.where(alpha > 12)
        if len(y_idx) == 0:
            continue
            
        anchor_y = int(y_idx.max()) + 1
        anchor_x = int(im.width // 2)
        is_lat = d in ["east", "west", "south-east", "south-west", "north-east", "north-west"]
        
        target_dir = dest_base / d
        target_dir.mkdir(parents=True, exist_ok=True)
        frame_paths = []
        
        for i in range(16):
            phase = 2.0 * math.pi * i / 16.0
            frame_arr = inverse_map_walk_frame(arr, phase, is_lateral=is_lat, is_quadruped=is_quad)
            frame_img = Image.fromarray(frame_arr, "RGBA")
            fn = f"frame_{i:03d}.png"
            frame_img.save(target_dir / fn)
            frame_paths.append(f"res://assets/characters/{hero}/animacoes_16f/walk/{d}/{fn}")
            
        dir_entries[d] = {
            "frames": frame_paths,
            "anchor": [anchor_x, anchor_y],
            "fps": 24
        }
    return dir_entries

def main():
    print("Iniciando Pipeline Hibrido de Movimentacao (16 Frames)...")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else {"schema_version": 1, "characters": {}}
    chars = manifest.setdefault("characters", {})

    for hero in HEROES:
        print(f"Processando movimentacao de {hero}...")
        dest_base = ASSETS / hero / "animacoes_16f" / "walk"
        dest_base.mkdir(parents=True, exist_ok=True)
        
        if hero == "michael":
            dir_entries = process_michael(dest_base)
        elif hero == "zumbi":
            dir_entries = process_zumbi(dest_base)
        else:
            dir_entries = process_procedural_hero(hero, dest_base)
            
        if not dir_entries:
            print(f"  [AVISO] Nenhuma direcao gerada para {hero}")
            continue
            
        hero_def = chars.setdefault(hero, {"states": {}})
        hero_states = hero_def.setdefault("states", {})
        
        # Preserva estados de attack e skill se existirem (ex: Zumbi)
        hero_states["walk"] = {
            "loop": True,
            "fps": 24,
            "directions": dir_entries
        }
        print(f"  -> {hero}: walk gerado com 16 frames em {len(dir_entries)} direcoes a 24 FPS!")

    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("\nManifesto animations_manifest.json atualizado com sucesso!")

if __name__ == "__main__":
    main()
