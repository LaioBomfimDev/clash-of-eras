"""Empacota os pixels exportados do PixelLab sem redesenhar os efeitos."""
import hashlib
import html
import json
import zipfile
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
records = json.loads((ROOT / 'ORIGEM.json').read_text(encoding='utf-8'))
atlas = Image.new('RGBA', (1152, 1920))
clips = []
manifest = {'source': 'PixelLab MCP vfx_workbench', 'status': 'proposta visual, sem integracao no combate', 'image': 'sprite_sheet_completa.png', 'frame_size': [96,96], 'columns': 12, 'rows': 20, 'fps': 16, 'anchor': [48,48], 'effects': []}
report = []
for row, rec in enumerate(records):
    folder = ROOT / 'originais' / rec['key']
    meta = json.loads(next(folder.glob('*.json')).read_text(encoding='utf-8'))
    sheet = Image.open(next(folder.glob('*.png'))).convert('RGBA')
    assert len(meta['frames']) == 12
    frames = []
    for col, entry in enumerate(meta['frames']):
        f = entry['frame']
        assert (f['w'],f['h']) == (96,96)
        frame = sheet.crop((f['x'],f['y'],f['x']+96,f['y']+96))
        assert frame.getchannel('A').getextrema()[0] == 0
        atlas.paste(frame, (col*96,row*96))
        frames.append(frame)
    assert any(f.getbbox() for f in frames)
    unique = len({hashlib.sha256(f.tobytes()).hexdigest() for f in frames})
    assert unique > 1
    clips.append(frames)
    manifest['effects'].append({'key':rec['key'],'name':rec['name'],'row':row,'frames':12,'fps':16,'loop':rec['recipe']['loop'],'rect':[0,row*96,1152,96],'edit_url':rec['edit_url']})
    report.append({'key':rec['key'],'frames':12,'distinct_frames':unique,'alpha_verified':True})
atlas.save(ROOT / 'sprite_sheet_completa.png')
(ROOT / 'sprite_sheet_completa.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
small = ImageFont.truetype('C:/Windows/Fonts/arial.ttf',12)
title = ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',24)

def gallery(t):
    canvas = Image.new('RGB',(1000,1160),'#0d1220')
    d = ImageDraw.Draw(canvas)
    d.text((26,17),'CLASH OF ERAS / VFX',font=title,fill='#f1dc93')
    d.text((26,51),'20 efeitos exclusivos · 12 quadros por efeito · PixelLab MCP',font=font,fill='#a4b2c8')
    for i,rec in enumerate(records):
        x=16+(i%4)*246; y=87+(i//4)*212
        d.rounded_rectangle((x,y,x+235,y+202),radius=10,fill='#182034',outline='#344258')
        frame=clips[i][t].resize((168,168),Image.Resampling.NEAREST)
        canvas.paste(frame,(x+33,y+1),frame)
        name,_,effect=rec['name'].partition(' - ')
        d.text((x+12,y+167),name,font=font,fill='#f7e5b9')
        d.text((x+12,y+187),effect,font=small,fill='#b8c7dc')
    return canvas

gallery(4).save(ROOT/'previa.png')
gif_frames=[gallery(i) for i in range(12)]
gif_frames[0].save(ROOT/'previa_animada.gif',save_all=True,append_images=gif_frames[1:],duration=[60,60,70]*4,loop=0,optimize=False)
cards=[]
for i,rec in enumerate(records):
    cards.append(f'<article><canvas width="96" height="96" data-row="{i}"></canvas><h2>{html.escape(rec["name"])}</h2><a href="{html.escape(rec["edit_url"])}" target="_blank" rel="noreferrer">Editar no PixelLab ↗</a></article>')
page='''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Clash of Eras · VFX PixelLab</title><style>*{box-sizing:border-box}body{margin:0;background:#0d1220;color:#e9eef7;font:16px system-ui}header{padding:28px;position:sticky;top:0;background:#0d1220ee;z-index:1}h1{margin:0;color:#f1dc93}p{color:#a4b2c8}button,select,a{color:#f1dc93}button,select{padding:10px;background:#202c43;border:1px solid #526080;border-radius:8px;margin-right:12px}main{padding:20px;display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px}article{text-align:center;background:#182034;border:1px solid #344258;border-radius:12px;padding:12px}canvas{width:192px;height:192px;image-rendering:pixelated}h2{font-size:16px}article a{font-size:13px}a{margin-right:12px}</style><header><h1>CLASH OF ERAS / VFX</h1><p>20 efeitos · 240 quadros · Proposta visual produzida no PixelLab MCP</p><button id="pause">Pausar</button><label>Velocidade <select id="speed"><option value="8">8 FPS</option><option value="16" selected>16 FPS</option><option value="24">24 FPS</option></select></label><a href="sprite_sheet_completa.png">Sprite sheet PNG</a><a href="VFX_ELENCO_PIXEL_LAB.zip">Pacote ZIP</a></header><main>'''+''.join(cards)+'''</main><script>const img=new Image();img.src='sprite_sheet_completa.png';let paused=false,fps=16,last=0,frame=0;const canvases=[...document.querySelectorAll('canvas')];document.querySelector('#pause').onclick=e=>{paused=!paused;e.target.textContent=paused?'Reproduzir':'Pausar'};document.querySelector('#speed').onchange=e=>fps=+e.target.value;function draw(now){if(img.complete&&img.naturalWidth&&!paused&&now-last>=1000/fps){last=now;for(const c of canvases){const ctx=c.getContext('2d');ctx.clearRect(0,0,96,96);ctx.drawImage(img,frame*96,+c.dataset.row*96,96,96,0,0,96,96)}frame=(frame+1)%12}requestAnimationFrame(draw)}requestAnimationFrame(draw);</script></html>'''
(ROOT/'galeria.html').write_text(page,encoding='utf-8')
(ROOT/'VALIDACAO.json').write_text(json.dumps({'effects':report,'total_frames':240,'atlas_size':[1152,1920],'art_creation':'PixelLab MCP; Python somente para empacotamento e galeria','visual_review':'Todos os 12 quadros de cada efeito vistos no retorno do MCP; composicao local conferida separadamente','gameplay_tested':False,'credits_before_after':{'generations_remaining':1.75,'usd':0}},ensure_ascii=False,indent=2),encoding='utf-8')
readme='''# VFX do elenco — PixelLab MCP — 2026-10-14

Pedido confirmado: criar sprite sheet de efeitos animados distintos para todos os personagens, usando o MCP do PixelLab.

Entrega: 20 efeitos, 12 quadros cada, canvas transparente 96 × 96, 16 FPS. A folha conjunta tem 1152 × 1920 pixels: cada linha representa um efeito; colunas 0–11 são os quadros na ordem. Origem fixa (48,48), filtro nearest. O JSON indica loops e linhas. Na prévia todos repetem para comparação; no jogo, respeitar o campo loop.

Abra `galeria.html` para pausar e comparar velocidades. `previa_animada.gif` mostra o conjunto. `sprite_sheet_completa.png` é o atlas transparente. `originais/` preserva exatamente PNG, GIF e JSON exportados pelo PixelLab. Receitas, IDs, links de edição e recibos em `ORIGEM.json` e `receitas.json`; hashes dos downloads em `INTEGRIDADE.json`.

Criação: editor determinístico gratuito `mcp__pixellabs__vfx_workbench`. Cada efeito foi desenhado por receita e renderizado pelo PixelLab. Não foi usada geração por IA nem image_gen. Python/Pillow apenas recortam os quadros conforme o JSON exportado, montam atlas e prévias, sem redesenhar a arte. Saldo antes/depois: 1,75 geração e US$ 0,00.

Estado: proposta visual para revisão. Não integrada ao combate, não publicada e não aprovada como arte final. Os temas refletem os kits atuais; os novos desenhos não criam regras de ataque/dano/cura. Não inclui técnicas futuras em estudo. Nenhum asset ativo foi substituído.

Validação: 60 arquivos originais baixados; 20 clips com 12 quadros, alfa e variação temporal verificados; revisão visual dos retornos do MCP. Não houve teste de gameplay, FPS em jogo ou balanceamento.

## Ordem das linhas (índice zero)

'''
readme+='\n'.join(f'- {i}: {r["name"]} (`{r["key"]}`)' for i,r in enumerate(records))+'\n'
(ROOT/'README.md').write_text(readme,encoding='utf-8')
zip_path=ROOT/'VFX_ELENCO_PIXEL_LAB.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
    for path in sorted(ROOT.rglob('*')):
        if path.is_file() and path!=zip_path and '__pycache__' not in path.parts:
            z.write(path,path.relative_to(ROOT))
print(json.dumps({'effects':20,'frames':240,'atlas':str(ROOT/'sprite_sheet_completa.png'),'zip_bytes':zip_path.stat().st_size}))
