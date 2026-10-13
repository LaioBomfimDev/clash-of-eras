# Junção D+E do Zumbi: pele do E, corrente cortada, lâmina maior, sombra do chão removida.
import sys
from PIL import Image
SRC, OUT = sys.argv[1], sys.argv[2]
im = Image.open(SRC).convert('RGBA'); W, H = im.size
orig = im.copy(); op = orig.load(); px = im.load()
BLACK = (0, 0, 0, 255); CLEAR = (0, 0, 0, 0)
SKIN = {(90,31,28):(62,20,23),(112,43,38):(81,29,30),(126,53,45):(91,35,34),(139,65,51):(109,47,40),
        (152,77,55):(117,53,43),(161,85,52):(125,58,46),(167,93,59):(135,68,50),(180,111,66):(141,76,55),
        (191,113,58):(154,91,61),(195,124,73):(159,101,65),(208,142,84):(175,117,76),(233,165,107):(196,140,95)}
ROCK = {(144,106,85),(114,84,73),(78,48,40),(100,67,54),(172,135,99),(193,163,113),(208,181,132),(177,145,93)}
GROUND = {(77,77,77),(107,103,104),(92,87,86)}
def rgb(p): return p[:3]
def is_body(p): return p[3] > 0 and (rgb(p) in SKIN or rgb(p) in ROCK)
def in_spear(x, y): return (95 <= x <= 104 and 0 <= y <= 35) or (95 <= x <= 101 and y >= 47)
# 1) pele mais escura (fora da lança)
for y in range(H):
    for x in range(W):
        p = op[x, y]
        if p[3] and rgb(p) in SKIN and not in_spear(x, y):
            px[x, y] = SKIN[rgb(p)] + (255,)
# 2) sombra opaca do chão (o jogo desenha a própria)
for y in range(119, H):
    for x in range(W):
        if op[x, y][3] and rgb(op[x, y]) in GROUND and not (96 <= x <= 99):
            px[x, y] = CLEAR
# 3) corrente entre os pés: apaga, preservando pedra, pé direito, argola direita e as pontas quebradas
CUT_LEFT_Y = int(sys.argv[3]) if len(sys.argv) > 3 else 105
CUT_RIGHT_X = int(sys.argv[4]) if len(sys.argv) > 4 else 90
def keep_zone(x, y):
    if 70 <= x <= 83 and 107 <= y <= 114: return True          # argola direita
    if 82 <= x <= CUT_RIGHT_X and 112 <= y <= 121: return True   # ponta à direita do pé
    return False
for y in range(CUT_LEFT_Y, H):
    for x in range(43, 96):
        if keep_zone(x, y): continue
        p = op[x, y]
        if not p[3] or is_body(p): continue
        if rgb(p) == (0, 0, 0):
            if any(0 <= x+dx < W and 0 <= y+dy < H and is_body(op[x+dx, y+dy]) for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))):
                continue
        px[x, y] = CLEAR
# 4) lâmina maior
for y in range(0, 23):
    for x in range(88, 112):
        px[x, y] = CLEAR
HW = {1:1,2:1,3:2,4:2,5:3,6:3,7:4,8:4,9:5,10:5,11:6,12:6,13:6,14:6,15:6,16:5,17:5,18:4,19:3,20:2,21:2,22:2}
fill = {}
for y, hw in HW.items():
    xs = list(range(100-hw, 100+hw))
    for x in xs:
        left, right = x - (100-hw), (99+hw) - x
        if y >= 20:   c = (122,121,121) if x <= 99 else (92,87,86)       # alvado
        elif x == 99: c = (236,239,244)                                    # crista iluminada
        elif x == 100: c = (122,121,121)                                   # crista em sombra
        elif x < 99:  c = (215,219,224) if left == 0 else (193,196,199)
        else:         c = (92,87,86) if right == 0 else (141,139,139)
        if y <= 2: c = (236,239,244) if x == 99 else (157,157,158)
        fill[(x, y)] = c
for (x, y), c in fill.items(): px[x, y] = c + (255,)
for (x, y) in list(fill):
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            q = (x+dx, y+dy)
            if q not in fill and 0 <= q[1] <= 23 and px[q][3] == 0:
                px[q] = BLACK
# 5) contorno solto: preto sem vizinho colorido some
for _ in range(2):
    snap = im.copy(); sp = snap.load()
    for y in range(90, H):
        for x in range(W):
            p = sp[x, y]
            if p[3] and rgb(p) == (0, 0, 0):
                if not any(0 <= x+dx < W and 0 <= y+dy < H and sp[x+dx, y+dy][3] and rgb(sp[x+dx, y+dy]) != (0,0,0)
                           for dx in (-1,0,1) for dy in (-1,0,1) if dx or dy):
                    px[x, y] = CLEAR
im.save(OUT)
print('bbox', im.getbbox())
