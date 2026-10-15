from pathlib import Path
from urllib.request import urlopen
from PIL import Image, ImageDraw
import sys, hashlib, json

root=Path(__file__).resolve().parent
name, job=sys.argv[1:3]
folder=root/name; folder.mkdir(exist_ok=True)
frames=[]; receipts=[]
for i in range(9):
    url=f'https://api.pixellab.ai/mcp/images/{job}/download?index={i}'
    p=folder/f'frame_{i:03d}.png'
    if not p.exists(): p.write_bytes(urlopen(url,timeout=90).read())
    image=Image.open(p).convert('RGBA')
    assert image.size==(64,120), image.size
    frames.append(image)
    receipts.append({'file':p.name,'url':url,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bounds':image.getbbox()})
sheet=Image.new('RGB',(64*3*5,140*3*2),'#202836')
draw=ImageDraw.Draw(sheet)
for i,f in enumerate(frames):
    xy=((i%5)*192,(i//5)*420+30)
    sheet.paste(f.resize((192,360),Image.Resampling.NEAREST),xy,f.resize((192,360),Image.Resampling.NEAREST))
    draw.text((xy[0]+10,xy[1]-22),f'{i}: '+('source' if i==0 else 'PixelLab'),fill='white')
sheet.save(root/f'{name}_quadros.png')
(folder/'DOWNLOADS.json').write_text(json.dumps(receipts,indent=2),encoding='utf-8')
print(name, len(frames), 'frames downloaded; canvas 64x120; source preserved.')
