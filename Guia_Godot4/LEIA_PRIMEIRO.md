# Xadrez Auto Battler — passagem para Godot 4

Este pacote preserva o jogo que desenhamos e as regras da implementação 0.10.1.
Foi preparado em 09/10/2026 para iniciar **um projeto novo e editável no Godot 4**.
O projeto antigo foi encerrado pelo usuário. Nenhuma nova alteração foi feita nele
para produzir este material.

## Entregue estes arquivos à próxima LLM

1. **PROMPT_PARA_PROXIMA_LLM.md**: mensagem pronta para iniciar o trabalho.
2. **GUIA_COMPLETO.md**: visão, todas as regras, chão, interação, layout,
   persistência, desempenho, personagem dançarino e roteiro de implementação.
3. **DADOS_DO_JOGO.json**: catálogo e campanha extraídos do código, com números exatos.
4. **LAYOUT_REFERENCIA.svg**: diagrama do HUD aberto e do chão. É um esquema,
   não uma captura do jogo nem arte final.
5. **referencias/**: cópias dos três módulos próprios em JavaScript e seis
   conjuntos de testes independentes, para consultar/portar as regras.

O guia principal é suficiente para entender a proposta. O JSON e as referências
reduzem a necessidade de adivinhar valores ou reabrir o projeto antigo.

`exportar_dados.mjs` permite regenerar o catálogo a partir das referências;
`gerar_layout.py` gera o diagrama SVG estático usando apenas Python padrão.
São ferramentas de documentação, não executáveis do jogo.

## Como interpretar o material

- **BASE EXISTENTE**: regra realmente presente no código consultado.
- **REQUISITO DO USUÁRIO**: intenção expressa, inclusive quando ainda não entregue.
- **PROPOSTA PARA GODOT**: recomendação de implementação, não código já criado.
- **PENDENTE**: decisão que não foi fechada; não inventar consenso.

Godot 4 e foco em PC/offline estão confirmados. 2D/2.5D com sprites/pixel art
foi discutido como caminho econômico, mas o estilo artístico definitivo ainda
pode mudar. Michael Jackson foi pedido como suporte dançarino; não foi implementado.

As referências JS **não são scripts de Godot**. São a especificação executável
das regras. Não há projeto Godot pronto, modelos novos ou sprites finais aqui.
Não há executáveis, DLLs, assets extraídos, integração Steam ou patches Unity no pacote.

## Verificação sem abrir jogo

Com Node disponível, a partir desta pasta:

```powershell
node referencias/tests/hud.mjs
node referencias/tests/persistence.mjs
node referencias/tests/shop-and-fusion.mjs
node referencias/tests/reserve-and-balance.mjs
node referencias/tests/grid-and-drag.mjs
node referencias/tests/combat-regression.mjs
```

Esses comandos consultam somente a lógica própria copiada. Não iniciam o cliente
antigo, Unity ou uma partida. O resultado desta entrega está em VERIFICACAO.json.
O MANIFESTO_SHA256.json permite conferir a integridade dos arquivos do pacote.

Para transportar tudo, use o ZIP `Xadrez_Auto_Battler_Guia_Godot4.zip`, ao lado
desta pasta. Não é necessário levar a instalação inteira do jogo antigo.
