# Primeiro protótipo — ordem de trabalho

Atualização: 2026-10-11. Substitui o plano que colocava rede antes do combate, preservado em [PLANO_PROTOTIPO_01_ARQUIVO.md](PLANO_PROTOTIPO_01_ARQUIVO.md). Regras atuais: [CEREBRO.md](CEREBRO.md).

## Entregas

1. **Tabuleiro e posicionamento.** Projeto Godot 4 em `RelicArena/`, tela base 640 × 360, piso/grade simples e sprites atuais provisórios. São 64 hexágonos e quatro unidades de teste por lado. Selecionar uma unidade e uma casa válida na preparação.
2. **Simulação sem interface.** Hexágonos, ocupação, caminho, alvo, alcance, intervalo de ataque, dano, defesa, crítico e morte. Configuração separada do estado; passo fixo e semente registrada.
3. **Quatro kits.** Neymar A → B → A, Caramelo mordida/sangramento/execução, Obama mala-escudo experimental e Zumbi bônus coletivo/críticos pessoais. Números são dados de teste.
4. **Rodadas contra bot local.** Preparação → luta → resultado → próxima rodada, quatro corações, limite de 30 s e aceleração aos 15 s. Bot começa com formação simples, sem ler a formação privada atual para criar uma resposta perfeita.
5. **Servidor dedicado local e dois clientes.** Migrar autoridade para processo separado; validar comandos, duplicação, fases e privacidade. O cliente representa eventos; não calcula dano ou resultado como autoridade.
6. **Loja, itens e sinergias.** Heróis gratuitos, ouro para itens/capacidade, renovação por 2 como teste. Fechar recrutamento/reserva antes de implementar; patamares de composição entram após os kits estarem observáveis.

A primeira entrega usa só quatro personagens; deck final de dez, coleção e capacidade final não mudaram. Multiplayer continua sendo a direção do produto. Bot local é um ambiente de desenvolvimento e uma possível funcionalidade futura, sem promessa de matchmaking automático.

## Organização

**Estado após ampliação V1, 2026-10-11:** o usuário pediu uma versão local mais completa depois de jogar o primeiro protótipo. Tabuleiro, simulação e ciclo estão implementados; Michael é o quinto kit, com cura em pulsos de dança. Loja, reserva, equipamentos, receitas e benefícios foram antecipados para serem observados na partida local. Os números e grupos funcionais de sinergia são testes; o servidor ainda não foi implementado. Não reutilizar a ordem antiga como impedimento para esse escopo mais recente. Instruções de jogo e evidências em [README](../RelicArena/README.md).

| Pasta | Função |
| --- | --- |
| `data/` | Atributos e configurações temporárias editáveis. |
| `simulation/` | Combate e estado, executáveis sem interface. |
| `client/` | Tabuleiro, sprites, controles e apresentação. |
| `assets/` | Cópias de imagens existentes, sem novas gerações. |
| `tests/` | Casos significativos de combate e grade. |

Resources são dados compartilháveis; vida/escudo/acúmulos pertencem à instância de combate. O Godot permite recursos próprios para dados ([documentação](https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html)).

O servidor futuro pode usar ENet e RPCs da [API oficial](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html), com entrada própria e sem ocupar uma vaga de jogador. Godot 4 pode executá-lo com `--headless` ([servidores dedicados](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html)). Isso não garante que a simulação pura elimine todo trabalho de rede: protocolo, autoridade, sincronização, desconexão e privacidade ainda precisam ser implementados.

## Critérios de teste

- Grade: vizinhança/distance hexagonal correta, ocupação exclusiva e posições dentro dos limites.
- Neymar: no máximo três impactos na ordem A → B → A; sem vizinho, sem ricochete; morte/separação interrompe retornos inválidos.
- Caramelo: fronteira 11/10/9 de vida para máximo 100, sangramento com duração definida e morte única.
- Obama: escudo absorve até esgotar e excesso chega à vida.
- Zumbi: somente críticos pessoais incrementam o próximo crítico; sem acúmulo vazando para nova rodada.
- Rodada: limpeza de projéteis/efeitos, perda de uma vida por resolução, 15/30 s coerentes e repetição reproduzível no ambiente fixado.
- Interface: seleção/casa correspondem, escala legível e resultado mostrado corresponde ao core. Teste de celular exige dispositivo real.

## Primeiras 20 partidas observadas

Fazer depois que o usuário conseguir jogar. São triagem qualitativa, não prova estatística de balanceamento:

- Neymar contra agrupamento e contra formação espalhada;
- Caramelo com caminho aberto e com retaguarda protegida;
- Obama contra dano concentrado e dano sustentado;
- Zumbi em luta curta e longa;
- lados/posições alternados, mantendo números e semente anotados.

Registrar duração real, primeira morte, sobreviventes, dano, tempo de decisão e se a causa da derrota ficou compreensível. A meta de 5–6 min precisa desses dados; aumentar ou reduzir preparação só depois de observar.

**Não executado ainda:** vinte partidas humanas, balanceamento, rede, testes em celular ou publicação. Resultados técnicos reais da entrega devem ser registrados no cérebro e no README do projeto.
