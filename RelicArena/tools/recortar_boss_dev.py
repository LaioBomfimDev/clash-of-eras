import os
import numpy as np
from PIL import Image
from collections import deque

def remove_background_quadrant(crop_rgb, tolerance=10):
    """
    Remove uniform gray background from quadrant image using edge flood-fill.
    """
    h, w, _ = crop_rgb.shape
    visited = np.zeros((h, w), dtype=bool)

    # Detect edge background color sample
    edge_samples = []
    for x in range(0, w, 5):
        edge_samples.append(crop_rgb[0, x])
        edge_samples.append(crop_rgb[h-1, x])
    for y in range(0, h, 5):
        edge_samples.append(crop_rgb[y, 0])
        edge_samples.append(crop_rgb[y, w-1])
    edge_arr = np.array(edge_samples)
    med_bg = np.median(edge_arr, axis=0)

    queue = deque()
    for x in range(w):
        queue.append((0, x))
        queue.append((h-1, x))
        visited[0, x] = True
        visited[h-1, x] = True
    for y in range(h):
        queue.append((y, 0))
        queue.append((y, w-1))
        visited[y, 0] = True
        visited[y, w-1] = True

    def is_bg(c):
        # Background is neutral gray around med_bg
        diff_channels = max(abs(int(c[0]) - int(c[1])), abs(int(c[0]) - int(c[2])), abs(int(c[1]) - int(c[2])))
        dist_med = abs(int(c[0]) - int(med_bg[0]))
        return diff_channels <= 8 and dist_med <= tolerance

    while queue:
        y, x = queue.popleft()
        for dy, dx in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if is_bg(crop_rgb[ny, nx]):
                    visited[ny, nx] = True
                    queue.append((ny, nx))

    # Also clear any enclosed background loops (isolated pockets of the same background gray)
    for y in range(h):
        for x in range(w):
            if not visited[y, x] and is_bg(crop_rgb[y, x]):
                visited[y, x] = True

    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[:, :, :3] = crop_rgb[:, :, :3]
    rgba[:, :, 3] = np.where(visited, 0, 255)

    # Crop to tight bounding box of visible pixels
    ys, xs = np.where(~visited)
    if len(ys) == 0:
        return Image.fromarray(rgba)
    
    img = Image.fromarray(rgba)
    return img.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def process_quadrants():
    src_path = 'RelicArena/assets/characters/boss_dev/referencias/boss_dev_apontando_quadrantes_4angulos.png'
    if not os.path.exists(src_path):
        print('Arquivo de quadrantes não encontrado:', src_path)
        return

    img = Image.open(src_path)
    arr = np.array(img)

    # Quadrant coordinates excluding black divider lines
    quads = {
        'cast_south_east': arr[5:505, 5:375],
        'cast_south_west': arr[5:505, 388:758],
        'cast_north_east': arr[518:1018, 5:375],
        'cast_north_west': arr[518:1018, 388:758]
    }

    out_dir = 'RelicArena/assets/characters/boss_dev/cast'
    os.makedirs(out_dir, exist_ok=True)

    for name, q_arr in quads.items():
        cropped = remove_background_quadrant(q_arr, tolerance=12)
        save_path = os.path.join(out_dir, f'{name}.png')
        cropped.save(save_path)
        print(f'Salvo {save_path} - Tamanho: {cropped.size}')


def process_turnaround():
    src_path = 'RelicArena/assets/characters/boss_dev/referencias/boss_dev_turnaround_parado_4angulos.jpg'
    if not os.path.exists(src_path):
        print('Arquivo turnaround não encontrado:', src_path)
        return

    img = Image.open(src_path)
    arr = np.array(img)

    # Columns:
    # 20..226: South (Frente)
    # 266..379: West / Right Profile
    # 397..602: North (Costas)
    # 618..730: East / Left Profile
    # Character feet end around y=738; below is floor shadow.
    columns = {
        'idle_south': (20, 226),
        'idle_profile_right': (266, 379),
        'idle_north': (397, 602),
        'idle_profile_left': (618, 730)
    }

    out_dir = 'RelicArena/assets/characters/boss_dev/idle'
    os.makedirs(out_dir, exist_ok=True)

    for name, (x1, x2) in columns.items():
        # y from 140 to 740 to avoid oval floor shadow
        sub_arr = arr[140:740, x1:x2]
        cropped = remove_background_quadrant(sub_arr, tolerance=14)
        save_path = os.path.join(out_dir, f'{name}.png')
        cropped.save(save_path)
        print(f'Salvo {save_path} - Tamanho: {cropped.size}')


if __name__ == '__main__':
    print('Iniciando recorte dos sprites do Boss Desenvolvedor...')
    process_quadrants()
    process_turnaround()
    print('Recorte concluído com sucesso!')
