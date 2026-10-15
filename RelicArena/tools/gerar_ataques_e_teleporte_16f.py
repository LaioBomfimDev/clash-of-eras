import json
import math
import shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "characters"
MANIFEST_PATH = ASSETS / "animations_manifest.json"

HEROES_ATTACK = [
    "neymar", "caramelo", "obama", "michael",
    "barbie", "ken", "elon", "snoop", "lula",
    "bob_marley", "rapunzel", "boss_dev"
]

DIRECTIONS = [
    "east", "west", "south", "north",
    "south-east", "south-west", "north-east", "north-west"
]

def inverse_map_attack_frame(arr: np.ndarray, t_norm: float, hero: str, is_lateral: bool) -> np.ndarray:
    """
    Inverse mapping cinemático de ataque (16 frames, t_norm de 0.0 a 1.0).
    t_norm = 0.0 .. 0.25 (preparação/antecipação)
    t_norm = 0.25 .. 0.55 (impacto/extensão máxima do golpe)
    t_norm = 0.55 .. 1.0  (recuperação/retorno suave à pose)
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    x_left, x_right = int(x_idx.min()), int(x_idx.max())
    char_h = max(1, y_bot - y_top)
    char_w = max(1, x_right - x_left)
    cx = (x_left + x_right) / 2.0

    y_head = int(y_top + char_h * 0.35)
    y_chest = int(y_top + char_h * 0.60)
    y_hips = int(y_top + char_h * 0.75)

    # Curva de impulso do ataque
    if t_norm < 0.25:
        # Antecipação / recuo preparatório
        p = t_norm / 0.25
        impulse = -math.sin(p * math.pi * 0.5) * 0.4
        lift = 0.0
    elif t_norm < 0.55:
        # Golpe explosivo para frente
        p = (t_norm - 0.25) / 0.30
        impulse = math.sin(p * math.pi) * 1.0
        lift = math.sin(p * math.pi) * 1.5
    else:
        # Recuperação amortecida
        p = (t_norm - 0.55) / 0.45
        impulse = (1.0 - p) * 0.3 * math.cos(p * math.pi * 2.0)
        lift = (1.0 - p) * 0.2

    out = np.zeros_like(arr)

    # Multiplicador por herói
    reach = 2.5 if is_lateral else 1.5
    if hero in ["caramelo", "neymar", "ken"]:
        reach = 3.2 if is_lateral else 2.0
    elif hero == "elon":
        reach = -2.0 # Recuo da arma no ombro
    elif hero == "rapunzel":
        reach = 3.5

    for ny in range(h):
        for nx in range(w):
            src_y = ny
            src_x = nx

            # Translação de corpo baseada na altura
            if src_y >= y_head:
                # Membros inferiores e tronco acompanham o golpe
                t_zone = (src_y - y_head) / max(1.0, (y_bot - y_head))
                
                if hero == "caramelo":
                    # Bote de 4 patas
                    dx = impulse * reach * t_zone
                    dy = -lift * 1.8 * t_zone
                    src_x = int(round(nx - dx))
                    src_y = int(round(ny - dy))
                elif hero == "neymar":
                    # Chute: perna inferior avança intensamente
                    if src_y >= y_chest:
                        leg_t = (src_y - y_chest) / max(1.0, (y_bot - y_chest))
                        dx = impulse * reach * 1.4 * leg_t
                        dy = -lift * 2.0 * leg_t
                        src_x = int(round(nx - dx))
                        src_y = int(round(ny - dy))
                    else:
                        dx = impulse * reach * 0.3
                        src_x = int(round(nx - dx))
                elif is_lateral:
                    dx = impulse * reach * t_zone
                    dy = -lift * t_zone * 0.5
                    src_x = int(round(nx - dx))
                    src_y = int(round(ny - dy))
                else:
                    # Frontal
                    dy = -lift * t_zone
                    # Expansão simétrica
                    if nx > cx:
                        dx = impulse * reach * 0.5
                    else:
                        dx = -impulse * reach * 0.5
                    src_x = int(round(nx - dx))
                    src_y = int(round(ny - dy))

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = arr[src_y, src_x]

    return out

def generate_boss_teleport_frames(base_img: Image.Image) -> list[Image.Image]:
    """
    Gera 16 frames dedicados para o teleporte do Boss Dev:
    Frames 0..7: Desmaterialização arcana ascendente (dissolvendo no vórtice).
    Frames 8..15: Rematerialização cósmica descendente (recompondo o corpo).
    """
    arr = np.array(base_img)
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return [base_img] * 16

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)

    frames = []

    for i in range(16):
        t_phase = i / 15.0
        frame_arr = np.zeros_like(arr)

        if i < 8:
            # Fase 1: Desmaterialização (0..7)
            # Corpo estica ligeiramente para cima e dissolve linha a linha
            prog = i / 7.0
            cutoff_y = y_bot - int(prog * char_h * 1.1)
            scale_v = 1.0 + prog * 0.35
            alpha_mult = max(0.0, 1.0 - prog * 0.95)

            for y in range(h):
                for x in range(w):
                    if alpha[y, x] <= 12:
                        continue
                    # Estica verticalmente em direção ao portal
                    dy_from_bot = y_bot - y
                    new_y = int(y_bot - dy_from_bot * scale_v)

                    # Efeito de scanline de dissolução
                    if new_y > cutoff_y or (new_y % 2 == 0 and prog > 0.4):
                        continue

                    if 0 <= new_y < h:
                        pix = arr[y, x].copy()
                        # Adiciona brilho arcano nos pixels que estão sumindo
                        if new_y < cutoff_y + 6:
                            # Brilho magenta/ouro
                            pix[0] = min(255, int(pix[0] * 1.4 + 60))
                            pix[1] = min(255, int(pix[1] * 1.1 + 20))
                            pix[2] = min(255, int(pix[2] * 1.5 + 80))
                        pix[3] = int(pix[3] * alpha_mult)
                        frame_arr[new_y, x] = pix
        else:
            # Fase 2: Rematerialização (8..15)
            # Desce do topo do portal e recompõe até assentar no solo
            prog = (i - 8) / 7.0 # 0.0 a 1.0
            cutoff_y = y_top + int(prog * char_h * 1.1)
            scale_v = 1.35 - prog * 0.35
            alpha_mult = min(1.0, 0.2 + prog * 0.8)

            for y in range(h):
                for x in range(w):
                    if alpha[y, x] <= 12:
                        continue
                    dy_from_bot = y_bot - y
                    new_y = int(y_bot - dy_from_bot * scale_v)

                    # Reconstituição progressiva de cima para baixo
                    if new_y > cutoff_y and prog < 0.9:
                        continue

                    if 0 <= new_y < h:
                        pix = arr[y, x].copy()
                        if new_y > cutoff_y - 8 and prog < 0.85:
                            # Borda de materialização luminosa
                            pix[0] = min(255, int(pix[0] * 1.3 + 50))
                            pix[1] = min(255, int(pix[1] * 1.3 + 50))
                            pix[2] = min(255, int(pix[2] * 1.6 + 90))
                        pix[3] = int(pix[3] * alpha_mult)
                        frame_arr[new_y, x] = pix

        frames.append(Image.fromarray(frame_arr, "RGBA"))

    return frames

def get_rotation_source(hero: str, direction: str) -> Path:
    if hero == "michael":
        p = ROOT / "assets" / "michael" / "original" / "Idle" / "rotations" / f"{direction}.png"
        if p.exists():
            return p
    if hero == "boss_dev":
        is_east = "east" in direction
        fn = "cast_south_east.png" if is_east else "cast_south_west.png"
        p = ASSETS / "boss_dev" / "game_ready" / fn
        if p.exists():
            return p
        return ASSETS / "boss_dev" / "game_ready" / "idle_south.png"
    if hero == "elon":
        p = ASSETS / "elon" / "grande_04" / "original" / "Idle" / "rotations" / f"{direction}.png"
        if p.exists():
            return p
    for sub in ["realista_03/original/Idle/rotations", "original/Idle/rotations", "rotations"]:
        p = ASSETS / hero / sub / f"{direction}.png"
        if p.exists():
            return p
    return None

def main():
    print("Iniciando geracao de animacoes de ATAQUE (16 frames) e TELEPORTE DO BOSS...")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else {"schema_version": 1, "characters": {}}
    chars = manifest.setdefault("characters", {})

    # 1. Gerar ataques para os heróis
    for hero in HEROES_ATTACK:
        print(f"Processando ataque de {hero}...")
        dest_base = ASSETS / hero / "animacoes_16f" / "attack"
        dest_base.mkdir(parents=True, exist_ok=True)
        dir_entries = {}

        for d in DIRECTIONS:
            src = get_rotation_source(hero, d)
            if src is None or not src.exists():
                src = get_rotation_source(hero, "south")
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
                t_norm = i / 15.0
                frame_arr = inverse_map_attack_frame(arr, t_norm, hero, is_lateral=is_lat)
                frame_img = Image.fromarray(frame_arr, "RGBA")
                fn = f"frame_{i:03d}.png"
                frame_img.save(target_dir / fn)
                frame_paths.append(f"res://assets/characters/{hero}/animacoes_16f/attack/{d}/{fn}")

            dir_entries[d] = {
                "frames": frame_paths,
                "anchor": [anchor_x, anchor_y],
                "fps": 24
            }

        hero_def = chars.setdefault(hero, {"states": {}})
        hero_states = hero_def.setdefault("states", {})
        hero_states["attack"] = {
            "loop": False,
            "fps": 24,
            "directions": dir_entries
        }
        print(f"  -> {hero}: attack gerado com 16 frames em {len(dir_entries)} direcoes!")

    # 2. Gerar teleporte do Boss Dev (skill)
    print("Processando teleporte dedicado do Boss Dev (skill)...")
    boss_dest = ASSETS / "boss_dev" / "animacoes_16f" / "skill"
    boss_dest.mkdir(parents=True, exist_ok=True)
    boss_src = ASSETS / "boss_dev" / "game_ready" / "idle_south.png"
    boss_im = Image.open(boss_src).convert("RGBA")
    teleport_frames = generate_boss_teleport_frames(boss_im)

    boss_dir_entries = {}
    for d in DIRECTIONS:
        t_dir = boss_dest / d
        t_dir.mkdir(parents=True, exist_ok=True)
        f_paths = []
        for i, f in enumerate(teleport_frames):
            fn = f"frame_{i:03d}.png"
            f.save(t_dir / fn)
            f_paths.append(f"res://assets/characters/boss_dev/animacoes_16f/skill/{d}/{fn}")

        arr_b = np.array(boss_im)
        alpha_b = arr_b[:, :, 3]
        y_b = np.where(alpha_b > 12)[0]
        anchor_y = int(y_b.max()) + 1 if len(y_b) > 0 else 112
        anchor_x = int(boss_im.width // 2)

        boss_dir_entries[d] = {
            "frames": f_paths,
            "anchor": [anchor_x, anchor_y],
            "fps": 24
        }

    boss_def = chars.setdefault("boss_dev", {"states": {}})
    boss_def.setdefault("states", {})["skill"] = {
        "loop": False,
        "fps": 24,
        "directions": boss_dir_entries
    }
    print("  -> boss_dev: teleporte (skill) gerado com 16 frames em 8 direcoes a 24 FPS!")

    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("\nManifesto animations_manifest.json atualizado com sucesso com todos os ataques e teleporte!")

if __name__ == "__main__":
    main()
