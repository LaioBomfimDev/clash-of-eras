from pathlib import Path
from PIL import Image
import base64, io, json
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[2]/'RelicArena'
ROOT.mkdir(parents=True,exist_ok=True)
sources={}
def source(key,img):
    b=io.BytesIO();img.save(b,format='PNG');sources[key]='data:image/png;base64,'+base64.b64encode(b.getvalue()).decode()
crop=Image.open(PROJECT/'assets/characters/boss_dev/referencias/boss_dev_apontando_linha_4angulos.jpg').convert('RGBA').crop((207,294,380,760))
crop.save(ROOT/'braco_fonte_recorte.png');source('arm',crop)
for key in ['fogo_vermelho_projetil','fogo_roxo_projetil','explosao_fogo_vermelho','explosao_fogo_roxo','furacao_fogo']:
    source(key,Image.open(PROJECT/f'assets/vfx/boss_dev/{key}.png').convert('RGBA'))
print(json.dumps(sources))
