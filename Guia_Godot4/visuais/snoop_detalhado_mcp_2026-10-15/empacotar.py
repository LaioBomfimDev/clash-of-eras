from pathlib import Path
from urllib.request import urlopen
from PIL import Image, ImageDraw, ImageFont
import json, hashlib

root=Path(__file__).resolve().parent
project=root.parents[2]/'RelicArena'
out=project/'assets/characters/snoop/detalhado_mcp_01'
views=['south-east','south-west','north-east','north-west']
records=[]; clips={}
for kind in ['base','walk','smoke']:
    rec=json.loads((root/f'{kind}_RECEITA.json').read_text(encoding='utf-8'))
    step=rec['mcp_drawing_id'];clips[kind]={}
    for view in views:
        native=root/'originais'/kind/view;native.mkdir(parents=True,exist_ok=True)
        png=native/'full.png';gif=native/'animation.gif'
        base=f'https://api.pixellab.ai/mcp/pixel-tools/{step}/assets/{view}/'
        for path in [png,gif]:
            if not path.exists():path.write_bytes(urlopen(base+path.name,timeout=90).read())
        sheet=Image.open(png).convert('RGBA');w,h=112,128
        count=1 if kind=='base' else 16
        columns=sheet.width//w
        assert sheet.width%w==0 and sheet.height%h==0
        assert columns*(sheet.height//h)>=count
        folder=out/kind/view;folder.mkdir(parents=True,exist_ok=True)
        frames=[];paths=[]
        for i in range(count):
            frame=sheet.crop(((i%columns)*w,(i//columns)*h,(i%columns+1)*w,(i//columns+1)*h))
            p=folder/f'frame_{i:03d}.png';frame.save(p)
            assert frame.getbbox() is not None
            frames.append(frame);paths.append('res://'+p.relative_to(project).as_posix())
            records.append({'file':str(p.relative_to(project)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'source':base+'full.png','source_frame':i})
        clips[kind][view]={'frames':frames,'paths':paths,'anchor':[65 if 'west' in view else 47,119]}

directions={'south':'south-east','south-east':'south-east','east':'south-east','south-west':'south-west','west':'south-west','north':'north-east','north-east':'north-east','north-west':'north-west'}
states={}
for state,kind,fps,loop in [('stance','base',10,True),('walk','walk',1000/60,True),('attack','smoke',1000/90,False),('skill','smoke',1000/90,False)]:
    states[state]={'fps':fps,'loop':loop,'directions':{d:{'frames':clips[kind][v]['paths'],'anchor':clips[kind][v]['anchor']} for d,v in directions.items()}}
manifest={'schema_version':1,'note':'Authored in free PixelLab MCP pixelart_workbench, no AI generation. Two authored front/back quarter views plus MCP mirrors. Eight game directions map to these four views.','characters':{'snoop':{'states':states}}}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
receipt={'method':'PixelLab MCP deterministic layered drawing and articulated rig','generations_charged':0,'steps':{k:json.loads((root/f'{k}_RECEITA.json').read_text())['mcp_drawing_id'] for k in clips},'direction_mapping':directions,'files':records,'trial_ai_request':'create_image_pro rejected before generation; free editor used instead'}
(out/'ORIGEM.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
(root/'ENTREGA.json').write_text(json.dumps(receipt,indent=2),encoding='utf-8')
preview=[];font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',20)
for t in range(48):
    pic=Image.new('RGB',(1400,440),'#182334');draw=ImageDraw.Draw(pic)
    for i,(label,kind,view,frame) in enumerate([
      ('SNOOP DETALHADO','base','south-east',0),('ANDANDO','walk','south-east',t%16),('CHARUTAO','smoke','south-east',(t//2)%16),('COSTAS','walk','north-east',t%16)
    ]):
        f=clips[kind][view]['frames'][frame]
        big=f.resize((f.width*3,f.height*3),Image.Resampling.NEAREST)
        pic.paste(big,(i*350+5,42),big)
        draw.text((i*350+20,15),label,font=font,fill='#f4d590')
    preview.append(pic)
preview[12].save(root/'previa.png')
preview[0].save(root/'previa_animada.gif',save_all=True,append_images=preview[1:],duration=60,loop=0)
print('Snoop: 4 base views + 64 walk frames + 64 smoke frames. Original MCP pixels preserved.')
