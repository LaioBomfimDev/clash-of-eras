# Versões de nível do Zumbi: a lâmina da lança cresce para cima a partir do encaixe.
# O corpo não muda; o quadro ganha altura em cima para caber a ponta (pés continuam na base).
# No leste a lança fica atrás da cabeça: usa a lâmina do oeste espelhada e só pinta atrás do corpo.
import sys, os, math
from PIL import Image, ImageOps
SRC_DIR, OUT_DIR = sys.argv[1], sys.argv[2]
FACTORS = {2: 1.25, 3: 1.5}
DIRS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']
BLACK = (0, 0, 0, 255)

def is_metal(p):
    r, g, b, a = p
    return a > 0 and max(r, g, b) - min(r, g, b) <= 16 and r >= 85

def is_dark(p):
    return p[3] > 0 and max(p[:3]) < 40  # contorno: preto ou quase-preto


def top_row(im):
    px = im.load(); w, h = im.size
    return min(y for y in range(h) for x in range(w) if px[x, y][3])

def tip_x(im):
    px = im.load(); y = top_row(im); xs = [x for x in range(im.width) if px[x, y][3]]
    return sum(xs) / len(xs)

def blade_mask(im):
    w, h = im.size; px = im.load(); top = top_row(im)
    stack = [(x, y) for y in range(top, top + 4) for x in range(w) if is_metal(px[x, y])]
    comp = set()
    while stack:
        x, y = stack.pop()
        if (x, y) in comp or not (0 <= x < w and 0 <= y < 48) or not is_metal(px[x, y]): continue
        comp.add((x, y))
        stack += [(x+dx, y+dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1) if dx or dy]
    # tons escuros do metal no meio da lâmina também são lâmina (linha a linha, de borda a borda)
    for y in {y for _, y in comp}:
        row = [x for x, yy in comp if yy == y]
        for x in range(min(row), max(row) + 1):
            if px[x, y][3] and not is_dark(px[x, y]):
                comp.add((x, y))
    outline = {(x+dx, y+dy) for (x, y) in comp for dx in (-1, 0, 1) for dy in (-1, 0, 1)
               if 0 <= x+dx < w and 0 <= y+dy < h and is_dark(px[x+dx, y+dy])}
    return comp, outline

def build(direction, level):
    im = Image.open(os.path.join(SRC_DIR, direction + '.png')).convert('RGBA')
    w, h = im.size; px = im.load()
    own_metal, own_outline = blade_mask(im)
    if direction == 'east':
        src = ImageOps.mirror(Image.open(os.path.join(SRC_DIR, 'west.png')).convert('RGBA'))
        dx = round(tip_x(im) - tip_x(src)); dy = top_row(im) - top_row(src)
        sm, _ = blade_mask(src); spx = src.load()
        metal = {(x + dx, y + dy) for (x, y) in sm}
        color = {(x + dx, y + dy): spx[x, y] for (x, y) in sm}
    else:
        metal = own_metal; color = {q: px[q] for q in metal}
    xs = [x for x, _ in metal]; ys = [y for _, y in metal]
    bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)
    f = FACTORS[level]
    bw, bh = bx1 - bx0 + 1, by1 - by0 + 1
    nw, nh = round(bw * f), round(bh * f)
    pad = max(0, nh - bh + 2 - by0)
    out = Image.new('RGBA', (w, h + pad), (0, 0, 0, 0)); out.paste(im, (0, pad)); op = out.load()
    free = set()
    for (x, y) in own_metal | own_outline:
        neighbors = [(x+ex, y+ey) for ex in (-1, 0, 1) for ey in (-1, 0, 1)
                     if (ex or ey) and 0 <= x+ex < w and 0 <= y+ey < h]
        if (x, y) in own_outline and any(px[n][3] and not is_dark(px[n]) and n not in own_metal for n in neighbors):
            continue  # contorno dividido com a cabeça/mão fica
        op[x, y + pad] = (0, 0, 0, 0); free.add((x, y + pad))
    left = int(math.floor((bx0 + bx1) / 2.0 - (nw - 1) / 2.0 + 0.5))
    bottom = by1 + pad
    new_pixels = {}
    for ny in range(nh):
        for nx in range(nw):
            s = (bx0 + min(bw - 1, int(nx / f)), by0 + min(bh - 1, int(ny / f)))
            if s in metal:
                new_pixels[(left + nx, bottom - (nh - 1) + ny)] = color[s]
    behind = direction == 'east'  # só no leste a lança passa atrás da cabeça
    def paintable(q):
        x, y = q
        return 0 <= x < w and 0 <= y < h + pad and (not behind or op[x, y][3] == 0 or q in free)
    # sem buracos: cada linha da lâmina nova é contínua de borda a borda
    for y in {y for _, y in new_pixels}:
        row = sorted(x for x, yy in new_pixels if yy == y)
        last = new_pixels[(row[0], y)]
        for x in range(row[0], row[-1] + 1):
            if (x, y) in new_pixels: last = new_pixels[(x, y)]
            else: new_pixels[(x, y)] = last
    painted = set()
    for q, c in new_pixels.items():
        if paintable(q): op[q] = c; painted.add(q)
    for (x, y) in painted:
        for ex in (-1, 0, 1):
            for ey in (-1, 0, 1):
                q = (x+ex, y+ey)
                if q not in new_pixels and 0 <= q[0] < w and 0 <= q[1] < h + pad and (op[q][3] == 0 or (not behind and q not in painted and q[1] < bottom - nh // 3)):
                    op[q] = BLACK
    return out, (bw, bh, nw, nh, pad)

for level in FACTORS:
    for d in DIRS:
        img, info = build(d, level)
        folder = os.path.join(OUT_DIR, f'nivel_{level}', 'rotations'); os.makedirs(folder, exist_ok=True)
        img.save(os.path.join(folder, d + '.png'))
        print(level, d, img.size, 'lamina %dx%d -> %dx%d, topo +%d' % info)
