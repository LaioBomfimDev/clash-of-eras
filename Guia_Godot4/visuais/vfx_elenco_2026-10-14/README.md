# VFX do elenco — PixelLab MCP — 2026-10-14

Pedido confirmado: criar sprite sheet de efeitos animados distintos para todos os personagens, usando o MCP do PixelLab.

Entrega: 20 efeitos, 12 quadros cada, canvas transparente 96 × 96, 16 FPS. A folha conjunta tem 1152 × 1920 pixels: cada linha representa um efeito; colunas 0–11 são os quadros na ordem. Origem fixa (48,48), filtro nearest. O JSON indica loops e linhas. Na prévia todos repetem para comparação; no jogo, respeitar o campo loop.

Abra `galeria.html` para pausar e comparar velocidades. `previa_animada.gif` mostra o conjunto. `sprite_sheet_completa.png` é o atlas transparente. `originais/` preserva exatamente PNG, GIF e JSON exportados pelo PixelLab. Receitas, IDs, links de edição e recibos em `ORIGEM.json` e `receitas.json`; hashes dos downloads em `INTEGRIDADE.json`.

Criação: editor determinístico gratuito `mcp__pixellabs__vfx_workbench`. Cada efeito foi desenhado por receita e renderizado pelo PixelLab. Não foi usada geração por IA nem image_gen. Python/Pillow apenas recortam os quadros conforme o JSON exportado, montam atlas e prévias, sem redesenhar a arte. Saldo antes/depois: 1,75 geração e US$ 0,00.

Estado: proposta visual para revisão. Não integrada ao combate, não publicada e não aprovada como arte final. Os temas refletem os kits atuais; os novos desenhos não criam regras de ataque/dano/cura. Não inclui técnicas futuras em estudo. Nenhum asset ativo foi substituído.

Validação: 60 arquivos originais baixados; 20 clips com 12 quadros, alfa e variação temporal verificados; revisão visual dos retornos do MCP. Não houve teste de gameplay, FPS em jogo ou balanceamento.

## Ordem das linhas (índice zero)

- 0: Neymar - Bola de energia (`neymar_bola`)
- 1: Caramelo - Presas ferozes (`caramelo_mordida`)
- 2: Obama - Barreira da mala (`obama_barreira`)
- 3: Zumbi - Lanca ancestral (`zumbi_estocada`)
- 4: Michael - Escudo do moonwalk (`michael_escudo`)
- 5: Michael - Estrelas de cura (`michael_cura`)
- 6: Barbie - Invocacao do Ken (`barbie_invocacao`)
- 7: Elon - Minifoguete (`elon_minifoguete`)
- 8: Elon - Super explosao (`elon_superexplosao`)
- 9: Snoop - Fumaca verde (`snoop_fumaca`)
- 10: Lula - Asas do retorno (`lula_renascimento`)
- 11: Bob Marley - Onda reggae (`bob_notas`)
- 12: Rapunzel - Laco dourado (`rapunzel_laco`)
- 13: Ken - Guardiao leal (`ken_provocacao`)
- 14: Boss - Meteoro vermelho (`boss_fogo_vermelho`)
- 15: Boss - Singularidade violeta (`boss_fogo_roxo`)
- 16: Boss - Furacao de fogo (`boss_furacao`)
- 17: Boss - Portal arcano (`boss_teleporte`)
- 18: Lodo Negro - Gota sombria (`lodo_projetil`)
- 19: Aberracao - Chicote cosmico (`aberracao_tentaculo`)
