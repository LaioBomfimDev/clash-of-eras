from pathlib import Path
import json
root=Path(__file__).resolve().parents[3]
p=root/'RelicArena/assets/characters/manifest.json'
data=json.loads(p.read_text(encoding='utf-8'))
entry=data['characters']['snoop']
entry['art_batch']='detalhado_mcp_01'
entry['art_origin']='PixelLab MCP pixelart_workbench; recipes and receipts in Guia_Godot4/visuais/snoop_detalhado_mcp_2026-10-15/'
mapping={'south':'south-east','south-east':'south-east','east':'south-east','south-west':'south-west','west':'south-west','north':'north-east','north-east':'north-east','north-west':'north-west'}
entry['states']['idle']['directions']={d:f'res://assets/characters/snoop/detalhado_mcp_01/base/{v}/frame_000.png' for d,v in mapping.items()}
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Snoop appearance manifest now points to the reviewed detailed MCP base.')
