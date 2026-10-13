# Retoques pontuais depois da junção: pontas quebradas fechadas e sobras removidas.
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGBA'); px = im.load()
B = (0, 0, 0, 255); C = (0, 0, 0, 0)
for x in range(44, 49): px[x, 105] = B            # fecha o último elo da ponta esquerda
px[70, 113] = C; px[70, 114] = C; px[71, 114] = C   # sobra da corrente à esquerda da argola direita
for y in (115, 116, 119, 120): px[91, y] = B        # elo aberto (quebrado) na ponta direita
px[101, 118] = C                                    # pixel solto ao lado da lança
for x in range(95, 102): px[x, 123] = C             # sobra de sombra sob a lança
im.save(sys.argv[2]); print('ok', im.getbbox())
