import json
import math
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "characters"
MANIFEST_PATH = ASSETS / "animations_manifest.json"

ALL_HEROES = [
    "neymar", "caramelo", "obama", "zumbi", "michael",
    "barbie", "ken", "elon", "snoop", "lula",
    "bob_marley", "rapunzel", "boss_dev"
]

DIRECTIONS = [
    "east", "west", "south", "north",
    "south-east", "south-west", "north-east", "north-west"
]

def inverse_map_stance_frame(arr: np.ndarray, phase: float, hero: str, is_lateral: bool) -> np.ndarray:
    """
    16 frames de stance / respiração viva e movimento com as mãos.
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)
    y_chest = int(y_top + char_h * 0.40)
    y_hands = int(y_top + char_h * 0.58)

    # Respiração torácica sutil
    breathe = int(round(-math.sin(phase) * 0.8))
    # Movimento das mãos / arma
    hand_sway = math.sin(phase + math.pi * 0.25) * 1.2

    out = np.zeros_like(arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny
            src_x = nx

            if y_top <= src_y <= y_hands:
                # Tórax respira
                src_y = ny - breathe
            elif y_hands < src_y <= y_bot - 4:
                # Zona das mãos / objeto
                t_hand = (src_y - y_hands) / max(1.0, (y_bot - y_hands))
                dx = int(round(hand_sway * (1.0 if is_lateral else 0.5) * t_hand))
                src_x = nx - dx

            if 0 <= src_y < h and 0 <= src_x < w:
                out[ny, nx] = arr[src_y, src_x]

    return out

def inverse_map_stun_frame(arr: np.ndarray, phase: float, is_lateral: bool) -> np.ndarray:
    """
    16 frames de stun / atordoamento (desorientação elíptica).
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)
    y_pivot = int(y_bot)

    # Balanço desorientado (cabeça balança mais que a base)
    sway_x = math.sin(phase) * 2.2
    sway_y = math.cos(phase * 2.0) * 0.8

    out = np.zeros_like(arr)

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
                out[ny, nx] = arr[src_y, src_x]

    return out

def inverse_map_death_frame(arr: np.ndarray, t_norm: float, is_lateral: bool) -> np.ndarray:
    """
    16 frames de morte / desfalecimento (sem loop).
    t_norm = 0.0 .. 0.25 (impacto letal recuando)
    t_norm = 0.25 .. 0.70 (queda e tombamento)
    t_norm = 0.70 .. 1.00 (repouso no solo)
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())
    char_h = max(1, y_bot - y_top)

    # Curva de achatamento e queda
    if t_norm < 0.25:
        p = t_norm / 0.25
        h_scale = 1.0 + p * 0.08
        recoil = -p * 2.0
        angle = 0.0
    elif t_norm < 0.70:
        p = (t_norm - 0.25) / 0.45
        # Corpo vai cedendo até o chão
        h_scale = 1.08 - p * 0.72 # Reduz altura para 36%
        recoil = -2.0 + p * 4.0
        angle = p * (0.35 if is_lateral else 0.2)
    else:
        # Repouso no solo
        h_scale = 0.36
        recoil = 2.0
        angle = 0.35 if is_lateral else 0.2

    alpha_fade = max(0.15, 1.0 - t_norm * 0.6)
    out = np.zeros_like(arr)

    for ny in range(h):
        for nx in range(w):
            if ny > y_bot:
                continue
            # Mapeamento inverso a partir dos pés (y_bot)
            dy = y_bot - ny
            src_y = int(y_bot - (dy / max(0.2, h_scale)))
            src_x = int(nx - recoil)

            if 0 <= src_y < h and 0 <= src_x < w and alpha[src_y, src_x] > 12:
                pix = arr[src_y, src_x].copy()
                # Escurecimento sutil de desfalecimento
                pix[0] = int(pix[0] * alpha_fade)
                pix[1] = int(pix[1] * alpha_fade)
                pix[2] = int(pix[2] * alpha_fade)
                out[ny, nx] = pix

    return out

def inverse_map_buff_frame(arr: np.ndarray, phase: float, is_lateral: bool) -> np.ndarray:
    """
    16 frames de buff / poder heroico e aura radiante.
    """
    h, w, c = arr.shape
    alpha = arr[:, :, 3]
    y_idx, x_idx = np.where(alpha > 12)
    if len(y_idx) == 0:
        return arr.copy()

    y_top, y_bot = int(y_idx.min()), int(y_idx.max())

    # Pulso de elevação e peito erguido
    lift = int(round(math.sin(phase) * 1.5))
    glow_pulse = 0.6 + 0.4 * math.sin(phase)

    out = np.zeros_like(arr)

    for ny in range(h):
        for nx in range(w):
            src_y = ny + lift
            src_x = nx

            if 0 <= src_y < h and 0 <= src_x < w and alpha[src_y, src_x] > 12:
                pix = arr[src_y, src_x].copy()
                # Realce luminoso nos realces de borda
                pix[0] = min(255, int(pix[0] + 35 * glow_pulse))
                pix[1] = min(255, int(pix[1] + 25 * glow_pulse))
                pix[2] = min(255, int(pix[2] + 10 * glow_pulse))
                out[ny, nx] = pix

    return out

def get_base_rotation(hero: str, direction: str) -> Path:
    if hero == "michael":
        p = ROOT / "assets" / "michael" / "original" / "Idle" / "rotations" / f"{direction}.png"
        if p.exists():
            return p
    if hero == "boss_dev":
        p = ASSETS / "boss_dev" / "game_ready" / f"idle_{direction}.png"
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
    print("Iniciando geracao dos estados completos de 16 quadros (stance, stun, death, buff)...")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8")) if MANIFEST_PATH.exists() else {"schema_version": 1, "characters": {}}
    chars = manifest.setdefault("characters", {})

    states_to_generate = ["stance", "stun", "death", "buff"]

    for hero in ALL_HEROES:
        print(f"Processando estados completos para: {hero}...")
        hero_def = chars.setdefault(hero, {"states": {}})
        hero_states = hero_def.setdefault("states", {})

        for state in states_to_generate:
            dest_base = ASSETS / hero / "animacoes_16f" / state
            dest_base.mkdir(parents=True, exist_ok=True)
            dir_entries = {}
            is_loop = state != "death"

            for d in DIRECTIONS:
                src = get_base_rotation(hero, d)
                if src is None or not src.exists():
                    src = get_base_rotation(hero, "south")
                if src is None or not src.exists():
                    continue

                im = Image.open(src).convert("RGBA")
                arr = np.array(im)
                alpha = arr[:, :, 3]
                y_idx = np.where(alpha > 12)[0]
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
                    t_norm = i / 15.0

                    if state == "stance":
                        frame_arr = inverse_map_stance_frame(arr, phase, hero, is_lat)
                    elif state == "stun":
                        frame_arr = inverse_map_stun_frame(arr, phase, is_lat)
                    elif state == "death":
                        frame_arr = inverse_map_death_frame(arr, t_norm, is_lat)
                    elif state == "buff":
                        frame_arr = inverse_map_buff_frame(arr, phase, is_lat)

                    frame_img = Image.fromarray(frame_arr, "RGBA")
                    fn = f"frame_{i:03d}.png"
                    frame_img.save(target_dir / fn)
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

        print(f"  -> {hero}: stance, stun, death e buff gerados com 16 frames em 8 direcoes a 24 FPS!")

    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("\nManifesto animations_manifest.json atualizado com TODOS os estados!")

if __name__ == "__main__":
    main()
