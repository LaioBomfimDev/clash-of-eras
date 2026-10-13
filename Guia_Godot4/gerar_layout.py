"""Generate a static documentation diagram, not a game or final art."""
from pathlib import Path
import xml.etree.ElementTree as ET

NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)
svg = ET.Element(f'{{{NS}}}svg', {'viewBox':'0 0 1600 920','width':'1600','height':'920','role':'img'})
ET.SubElement(svg, 'title').text = 'Xadrez Auto Battler: organização do HUD aberto e tabuleiro 7 por 8'
ET.SubElement(svg, 'desc').text = 'Diagrama documental com sinergias à esquerda, atributos à direita, chão central, oito reservas e cinco ofertas. Casas 0 a 27 são do jogador. Não é arte final nem captura do jogo.'


def node(kind, **attrs):
    return ET.SubElement(svg, kind, {k.replace('_','-'):str(v) for k,v in attrs.items()})


def rect(x,y,w,h,fill='#142737',stroke='#2d4558',radius=8):
    node('rect',x=x,y=y,width=w,height=h,rx=radius,fill=fill,stroke=stroke)


def text(x,y,value,size=17,color='#e8f2fa',weight='normal',anchor='start'):
    t=node('text',x=x,y=y,fill=color,font_size=size,font_weight=weight,
           text_anchor=anchor,font_family='Segoe UI, Arial, sans-serif')
    t.text=value


def badge(x,y,label,color='#56cbd7',radius=15):
    node('circle',cx=x,cy=y,r=radius,fill='#0a1725',stroke=color,stroke_width=2)
    text(x,y+5,label,12,color,'bold','middle')


rect(0,0,1600,920,'#09131f','#09131f',0)
for x,w,label,value,col in [(270,230,'RODADA','1 / 15','#e8f2fa'),(510,190,'VIDA','100','#80e5a3'),
                          (710,190,'OURO','9','#ffd578'),(910,190,'CAMPO','3 / 6','#8de0e8'),
                          (1110,210,'SAVE','SALVO','#80e5a3')]:
    rect(x,20,w,65)
    text(x+14,43,label,13,'#99adbd')
    text(x+14,70,value,23,col,'bold')
rect(20,20,220,65);text(130,60,'MENU / VOLTAR',19,anchor='middle')
rect(270,99,1050,32);text(286,121,'PREPARAÇÃO  ·  1-1 Equipe rival  ·  arraste para organizar',16)

# Logical row zero appears at the bottom. Visual geometry does not alter rules.
bx,by,cw,ch=330,150,130,52
selected=(3,3)
for row in range(8):
    for col in range(7):
        cell=row*7+col;x=bx+col*cw;y=by+(7-row)*ch
        near=max(abs(col-selected[0]),abs(row-selected[1]))<=1
        fill='#274537' if near else '#283844' if row<4 else '#3d2c35'
        stroke='#ffd578' if (col,row)==selected else '#80e5a3' if near else '#407382' if row<4 else '#825158'
        rect(x+2,y+2,cw-4,ch-4,fill,stroke,2)
        text(x+9,y+17,f'{chr(65+col)}{row+1} · {cell}',11,'#9fb1bb')
for col in range(7):text(bx+col*cw+cw/2,144,chr(65+col),13,'#99adbd',anchor='middle')
text(785,590,'CHÃO 7×8 · casas 0–27 na preparação · alcance marcado em verde',16,'#8de0e8',anchor='middle')
node('line',x1=bx,y1=by+4*ch,x2=bx+7*cw,y2=by+4*ch,stroke='#d79f66',stroke_width=3)


def unit(col,row,label,tag,hp,allied=True):
    x=bx+col*cw+cw/2;y=by+(7-row)*ch+ch/2+3;color='#56cbd7' if allied else '#ed7f85'
    node('ellipse',cx=x,cy=y+10,rx=27,ry=8,fill='#0a1725',opacity='0.65')
    badge(x,y-2,tag,color,17)
    rect(x-29,y-25,58,4,'#80e5a3' if allied else '#ed7f85',color,0)
    text(x,y+26,label,12,'#e8f2fa',anchor='middle')


unit(3,3,'Sumô','SU',80);unit(2,1,'Mosqueteiro','MO',50);unit(4,1,'Arcanista','AR',50)
unit(3,4,'Sumô','SU',80,False);unit(2,7,'Mosqueteiro','MO',50,False)
text(270,620,'1 CASA  /  2 CASAS  /  ∞  ·  o movimento entre casas é ortogonal',15,'#99adbd')

for i,(label,count,tag) in enumerate([('Guardiões','1/2','GU'),('Atiradores','1/2','AT'),('Místicos','1/2','MI'),
                                     ('Assassinos','0/2','AS'),('Selvagens','0/2','SE'),('Ancestrais','0/2','AN')]):
    y=145+i*57;rect(20,y,220,51);badge(43,y+25,tag)
    text(66,y+22,f'{label}  {count}',16);text(66,y+42,'Inativa · tipos distintos',12,'#99adbd')
text(20,510,'BOLSA DE ITENS',15,'#99adbd','bold')
for i,(label,amount,effect,tag) in enumerate([('Lâmina',1,'+1 ataque','LA'),('Couraça',1,'+10 vida','CO'),('Tomo',0,'+2 cura','TO')]):
    y=523+i*43;rect(20,y,220,38);badge(43,y+19,tag,'#ffd578',12)
    text(64,y+17,f'{label} ×{amount}',14);text(64,y+32,effect,12,'#99adbd')
rect(20,660,220,35);text(130,683,'RETIRAR ITENS',14,anchor='middle')

rect(1360,145,220,155)
text(1375,171,'SUMÔ ★',22,'#ffd578','bold');text(1375,194,'Normal · Tanque · Campo',14)
text(1375,218,'VIDA 80   ·   ATAQUE 1',16,'#80e5a3');text(1375,241,'1 casa · a cada 2,6s',16,'#8de0e8')
text(1375,266,'ITENS 0/3',14);text(1375,286,'Sem equipamento',13,'#99adbd')
for i,label in enumerate(['Sumô ★','Mosqueteiro ★','Arcanista ★','Vaga 4','Vaga 5','Vaga 6']):
    y=314+i*45;rect(1360,y,220,39,stroke='#ffd578' if i==0 else '#2d4558')
    text(1376,y+26,label,16,'#e8f2fa' if i<3 else '#83929c')
rect(1360,599,220,48);text(1375,620,'CÓPIAS 1/3',15);text(1375,639,'★ → ★★ automaticamente',13,'#ffd578')
rect(1360,660,220,87,'#522633','#e17882');text(1470,691,'VENDER  +1 OURO',18,'#ffb4bc','bold','middle')
text(1470,720,'ARRASTE A PEÇA AQUI',14,'#ffb4bc',anchor='middle')
rect(1360,758,220,32);text(1470,780,'GUARDAR NA RESERVA',13,anchor='middle')
rect(1360,805,220,80,'#22483e','#80e5a3');text(1470,855,'LUTAR',25,'#80e5a3','bold','middle')

for x,w,label,col in [(270,165,'RESERVA 0/8','#e8f2fa'),(445,250,'JUROS +0 / batalha','#ffd578'),
                       (705,195,'SEQUÊNCIA +0','#ffd578'),(910,410,'LOJA N 75% / R 25% / E 0%','#8de0e8')]:
    rect(x,640,w,30);text(x+10,661,label,14,col)
for i in range(8):
    x=270+i*132;rect(x,683,122,77);text(x+12,707,f'VAGA {i+1}',13,'#83929c')
    text(x+61,743,'+',23,'#407382',anchor='middle')
offers=[('Comprado','Sumô'),('Comprado','Mosqueteiro'),('Comprado','Arcanista'),('Duelista','Normal · 1 ouro'),('Bruxa','Raro · 3 ouro')]
for i,(name,detail) in enumerate(offers):
    x=270+i*212;rect(x,781,202,104,stroke='#79c4ff' if i==4 else '#2d4558')
    badge(x+25,808,'R' if i==4 else 'N','#79c4ff' if i==4 else '#bcc6cc',12)
    text(x+46,813,name,16,'#83929c' if i<3 else '#e8f2fa','bold')
    text(x+13,843,detail,14,'#79c4ff' if i==4 else '#bcc6cc')
    text(x+13,870,'2 casas' if i==4 else '1 casa' if i==3 else 'Oferta vazia',13,'#8de0e8' if i>=3 else '#83929c')
rect(20,781,220,46);text(130,810,'RENOVAR · 2 OURO',17,'#ffd578',anchor='middle')
rect(20,838,220,47);text(130,868,'TRAVAR LOJA',17,anchor='middle')
text(800,910,'ESQUEMA DOCUMENTAL · não é arte final nem captura do jogo · posição/função dos elementos',14,'#99adbd',anchor='middle')
output=Path(__file__).resolve().parent/'LAYOUT_REFERENCIA.svg'
ET.ElementTree(svg).write(output,encoding='utf-8',xml_declaration=True)
print('Generated static layout diagram:',output.name)
