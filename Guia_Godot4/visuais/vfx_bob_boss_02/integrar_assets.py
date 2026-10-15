from pathlib import Path
from urllib.request import urlopen
from PIL import Image, ImageDraw, ImageFont
import json, hashlib, shutil
ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parents[2]/'RelicArena'
records=json.loads((ROOT/'ORIGEM.json').read_text(encoding='utf-8'))
manifest_path=PROJECT/'assets/vfx/manifest.json'
manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
backup=ROOT/'antes';backup.mkdir(exist_ok=True)
for p in [manifest_path,PROJECT/'client/main.gd',PROJECT/'client/character_visuals.gd']:
    target=backup/p.name
    if not target.exists():shutil.copy2(p,target)
frames_all=[]
for r in records:
    folder=ROOT/'originais'/r['key']
    meta=json.loads(next(folder.glob('*.json')).read_text(encoding='utf-8'))
    img=Image.open(next(folder.glob('*.png'))).convert('RGBA')
    assert len(meta['frames'])==16
    w,h=meta['frames'][0]['frame']['w'],meta['frames'][0]['frame']['h']
    frames=[]
    for entry in meta['frames']:
        f=entry['frame'];frames.append(img.crop((f['x'],f['y'],f['x']+w,f['y']+h)))
    assert len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})>1
    out=PROJECT/'assets/vfx/refino_bob_boss_02'/r['key'];out.mkdir(parents=True,exist_ok=True)
    sheet=Image.new('RGBA',(w*4,h*4))
    for i,f in enumerate(frames):sheet.paste(f,((i%4)*w,(i//4)*h))
    sheet.save(out/'sheet.png')
    anchor=[67,40] if 'projetil' in r['key'] else ([64,100] if 'furacao' in r['key'] else r['recipe']['origin'])
    pack={'fps':r['recipe']['fps'],'clips':[{'name':'whole','frames':16,'loop':r['recipe']['loop'],'frame':{'w':w,'h':h},'offset':{'x':-anchor[0],'y':-anchor[1]},'sheets':[{'file':'sheet.png','columns':4,'rows':4,'frames':16,'first_frame':0}]}]}
    (out/'manifest.json').write_text(json.dumps(pack,indent=2),encoding='utf-8')
    (out/'ORIGEM.json').write_text(json.dumps({'source':r['edit_url'],'source_file':str(next(folder.glob('*.png')).relative_to(PROJECT.parent)),'pixel_lab_step':r['step'],'pixel_preserving_pack':True,'anchor':anchor,'purpose':'VFX only; embedded reference is an effect, not a character'},indent=2),encoding='utf-8')
    manifest['effects']=[e for e in manifest['effects'] if e['key']!=r['key']]
    manifest['effects'].append({'key':r['key'],'original_manifest':'res://'+(out/'manifest.json').relative_to(PROJECT).as_posix(),'clip':'whole','character_embedded':False,'runtime_role':'active','effect_url':r['edit_url']})
    frames_all.append(frames)
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
arm_url=json.loads((ROOT/'BRACO_PIXEL_LAB.json').read_text())['url']
arm_data=urlopen(arm_url,timeout=90).read()
(ROOT/'cast_south_west_02.png').write_bytes(arm_data)
dest=PROJECT/'assets/characters/boss_dev/refino_02';dest.mkdir(exist_ok=True)
(dest/'cast_south_west.png').write_bytes(arm_data)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
previews=[]
for t in range(16):
    p=Image.new('RGB',(1000,490),'#141b2c');d=ImageDraw.Draw(p)
    for i,r in enumerate(records):
        x=12+(i%4)*246;y=12+(i//4)*236
        f=frames_all[i][t];f=f.resize((f.width*2,f.height*2),Image.Resampling.NEAREST)
        p.paste(f,(x+(232-f.width)//2,y+(200-f.height)//2),f)
        d.text((x+5,y+205),r['name'].replace('Boss - ','').replace('Bob Marley - ',''),font=font,fill='#f2d795')
    arm=Image.open(ROOT/'cast_south_west_02.png').convert('RGBA');p.paste(arm,(805,270),arm)
    d.text((755,453),'Boss: braco corrigido',font=font,fill='#f2d795')
    previews.append(p)
previews[6].save(ROOT/'previa.png')
previews[0].save(ROOT/'previa_animada.gif',save_all=True,append_images=previews[1:],duration=65,loop=0)
print('7 clips, 112 frames, RGBA verified; original pixels repacked; arm downloaded.')
