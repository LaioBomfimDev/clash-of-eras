from pathlib import Path
from urllib.request import urlopen
from PIL import Image, ImageDraw, ImageFont
import json, shutil, hashlib

root=Path(__file__).resolve().parent
project=root.parents[2]/'RelicArena'
out=project/'assets/characters/boss_dev/movimento_mcp_01'
out.mkdir(parents=True,exist_ok=True)
walk=[]
for i in range(1,9):
    folder=out/'walk';folder.mkdir(exist_ok=True)
    p=folder/f'frame_{i-1:03d}.png'
    url=f'https://api.pixellab.ai/mcp/pixel-tools/912a5d7b-cf83-4905-af4c-145eec730407/assets/f{i}/full.png'
    if not p.exists():p.write_bytes(urlopen(url,timeout=90).read())
    im=Image.open(p).convert('RGBA');assert im.size==(96,120)
    walk.append(im)
cast=[]
for i in range(9):
    folder=out/'cast';folder.mkdir(exist_ok=True)
    p=folder/f'frame_{i:03d}.png';shutil.copy2(root/'conjuracao'/p.name,p)
    cast.append(Image.open(p).convert('RGBA'))
def paths(kind,seq):return ['res://'+(out/kind/f'frame_{i:03d}.png').relative_to(project).as_posix() for i in seq]
cast_seq=list(range(9))+[8,8]+list(range(7,-1,-1))
cast_clip={'frames':paths('cast',cast_seq),'anchor':[21,116]}
manifest={'schema_version':1,'note':'Generated through PixelLab MCP animate_image. Front walk only; right-pointing cast. No mirrored tattoo. Cast return reuses generated poses in reverse.','characters':{'boss_dev':{'states':{
    'walk':{'fps':12,'loop':True,'directions':{'south':{'frames':paths('walk',range(8)),'anchor':[45,116]}}},
    'attack':{'fps':24,'loop':False,'directions':{'south-east':cast_clip,'east':cast_clip,'south':cast_clip}}
}}}}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
for name,frames in [('caminhada',walk),('conjuracao',cast)]:
    w,h=frames[0].size;sheet=Image.new('RGBA',(w*len(frames),h))
    for i,f in enumerate(frames):sheet.paste(f,(i*w,0))
    sheet.save(root/f'{name}_spritesheet.png')
# Export de apresentação: mesmos pixels sobre fundo sólido, em escala inteira.
preview=[]
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for t in range(76):
    pic=Image.new('RGB',(620,440),'#182334');d=ImageDraw.Draw(pic)
    for idx,(name,f,anchor) in enumerate([
        ('CAMINHADA',walk[(t//2)%8],(45,116)),
        ('LEVANTAR O BRACO',cast[cast_seq[t%len(cast_seq)]],(21,116))
    ]):
        d.text((idx*310+45,20),name,font=font,fill='#f4d590')
        big=f.resize((f.width*3,f.height*3),Image.Resampling.NEAREST)
        pic.paste(big,(idx*310+155-anchor[0]*3,402-anchor[1]*3),big)
    preview.append(pic)
preview[0].save(root/'previa_animada.gif',save_all=True,append_images=preview[1:],duration=40,loop=0)
preview[7].save(root/'previa.png')
receipt={'walk_job':'66d09dbe-358c-47e5-bb33-95bece34eab3','cast_job':'9ac8c9b0-749e-4ce4-a61c-1a751895874f','alignment_step':'912a5d7b-cf83-4905-af4c-145eec730407','charged_generations':2,'balance_after':{'generations_remaining':0,'daily_bonus':8,'credits':0},'cast_playback_sequence':cast_seq,'frames':{str(p.relative_to(out)):hashlib.sha256(p.read_bytes()).hexdigest() for p in out.rglob('*.png')}}
(out/'ORIGEM.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
(root/'ENTREGA.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
print('8 walk poses, 9 cast poses; 19-frame cast playback with hold and return; originals preserved.')
