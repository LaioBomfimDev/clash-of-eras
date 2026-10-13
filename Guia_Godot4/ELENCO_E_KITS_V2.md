# Elenco e kits V2 — expansão atual do laboratório

Atualizado em 2026-10-12 após a sincronização do cérebro. **Esta revisão substitui a proposta inicial deste arquivo:** Lula revive, Elon atira foguetes, Bob tem aura dos dois lados, e Barbie/Ken, Snoop e Rapunzel entram no lote. Cleópatra e Jack ficam fora desta etapa. Kits escolhidos não significam números ou balanceamento aprovados.

Fontes: [regras atuais](CEREBRO.md), [plano de arte do lote 03](PERSONAGENS_LOTE_03.md), [dados atuais de teste](../RelicArena/data/debug_characters.json), [contratos do núcleo](../RelicArena/simulation/README.md) e [Session](../RelicArena/simulation/match_session.gd). As descrições de implementação vêm da leitura desses arquivos; testes desta retomada serão relatados separadamente após execução.

## Elenco e escopo

- Pixel art pelo PixelLab, proporção realista como o Michael existente, **sem caricatura**. Figuras reconhecíveis, sem inventar lore ou biografias. Ordem escolhida: novos primeiro; depois refazer Neymar, Caramelo, Obama e Zumbi. Não se afirma aqui que novas artes terminaram.
- O catálogo lido contém **11 heróis recrutáveis**, mais Ken como invocação. O deck final de dez é uma decisão separada: não remover um herói silenciosamente. Definir depois quais dez entram em cada deck, ou revisar explicitamente esse limite.
- O teste continua com quatro ativos e expansão até cinco. Reserva de cinco espaços é hipótese implementada, não tamanho final escolhido. Ter mais referências não aumenta automaticamente a capacidade.
- Dano físico/mágico é um eixo; tanque, controle, suporte e carry são funções que podem coexistir. Aparência não define automaticamente defesa, tipo de dano ou grupo.

## Kits escolhidos e respostas a estudar

| Referência / chave | Escolhido pelo usuário | Estado ou hipótese; resposta pretendida |
| --- | --- | --- |
| Neymar / `neymar` | DPS à distância, velocidade de ataque; bola com até três impactos A → B → A. | Carry físico que pune adjacência. Separar alvos reduz ricochetes; acesso ao carry ameaça sua sobrevivência. Dano integral e crítico compartilhado são contratos de teste. |
| Caramelo / `caramelo` | Assassino/DPS, mordidas, sangramento e execução em 10% de vida. | Desgaste e finalização. Cura antes do limiar, armadura e controle da aproximação respondem. Caçar um carry à distância na abertura é refinamento proposto, não salto escolhido. Execução ignorar escudo é experimental. |
| Obama / `obama` | Tanque; mala como proteção. | Absorção contra picos. Reforço periódico do próprio escudo é refinamento proposto, sem virar cura coletiva. Dano sustentado entre reforços e acesso ao carry devem continuar úteis. |
| Zumbi / `zumbi` | Lança, bônus coletivo de crítico/velocidade; somente seus próprios críticos fortalecem o próximo crítico dele. | Carry sustentado e apoio ofensivo. Controle/foco reduzem a janela de crescimento. Fórmula, teto e persistência da aura após morte são testes. |
| Michael / `michael` | Três passos aleatórios de costas, escudo coletivo ao parar e cura pequena periódica enquanto vivo. | Proteção por ciclos. Pressão antes do escudo e acesso ao suporte respondem. Raio, autocura, intervalo e valores são experimentais; escudo não acumula indefinidamente. |
| Barbie / `barbie` | Tanque; invoca Ken de sunga, que atrai quem atacaria Barbie. Enquanto Ken vive, ela causa **+30% de dano**. | Vínculo escolhido; posição, nível herdado, capacidade e contagem de Ken são hipóteses. Remover Ken encerra o aumento; área pode atingir o par. |
| Elon / `elon` | Atirador que lança foguetes. | O núcleo usa foguete em cada ataque, não a antiga proposta de quarto disparo. Explosão vizinha a 50% e dano físico são testes. Dispersão, armadura e acesso à retaguarda respondem; não ricocheteia. |
| Snoop / `snoop` | Cantor/DPS com fumaça: dano contínuo **e** chance de inimigos dentro errarem ataques, com valores menores. | Fonte mágica de desgaste no teste. Uma nuvem por Snoop, raio, duração e chance de erro são hipóteses. Sair/deslocar alvos reduz cobertura; medir frustração por erros sucessivos. |
| Lula / `lula` | Tanque; na primeira queda da rodada volta com aproximadamente 40% da vida. | Não usa a provocação antes proposta. Segunda queda mata. Levantar contra execução e limpar sangramento são hipóteses implementadas. Dano sustentado após a volta testa o plano. |
| Bob / `bob_marley` | Cantor suporte; aliados próximos atacam mais rápido e inimigos mais devagar; **não reduz o dano inimigo**. Raio cresce a cada nível na partida. | Aura por posição, não o antigo pulso isolado. Valores/raios são testes. Afastar a luta ou alcançar Bob reduz cobertura. Somar Bob/Zumbi/itens precisa de teto. |
| Rapunzel / `rapunzel` | Controle; laço puxa o inimigo mais distante para perto e atordoa aproximadamente 1 s. Entrou no lugar de Jack. | Primeiro uso, recarga, destino e dano são testes. Isca resistente atrás responde. Alvo já próximo/destino ocupado precisam de fallback finito, sem empilhar corpos. |

**Ken / `ken`:** invocação fora do deck/loja. No teste herda o nível da Barbie, não usa capacidade, não participa da formação pública e não conta no desempate; esses detalhes continuam propostas. Não fecha sinergia sozinho com Barbie. Não atribuir identidades pessoais não declaradas para preencher grupos; habilidades são escolhas de jogo, não biografias.

## Números e aprovação

Inventário da configuração lida, **não recomendação ou aprovação nova**; conferir os dados porque o núcleo está sendo refinado.

| Mecânica | Configuração lida | Estado |
| --- | --- | --- |
| Cópias/força | 1/2/3 cópias totais → níveis 1/2/3; vida/dano ×1/1,5/2,25 | Escolhidos para teste. Escalar cura/escudo/sangramento igual ainda é hipótese. |
| Barbie | +30% de dano enquanto Ken vive | Percentual escolhido. Demais atributos são testes. |
| Elon | Explosão raio um; secundários recebem 50% | Proposta implementada; não migrar para quarto ataque ou híbrido silenciosamente. |
| Snoop | Raio um, 3 s, 6 de dano a cada 0,5 s, erro 15% | Dois efeitos escolhidos; números exatos são testes. |
| Lula | Uma volta com 40% da vida máxima | Uma volta e aproximadamente 40% escolhidos; interação com execução/efeitos é hipótese. |
| Bob | +20% de velocidade aliada, −20% inimiga; raios 2/3/4 por nível | Aura dupla e raio crescente escolhidos; intensidades/raios exatos são testes. |
| Rapunzel | Primeiro laço 2,5 s; recarga 7 s; atordoamento 1 s; dano 40 antes da escala | Puxar o distante e atordoar aproximadamente 1 s escolhidos; demais números são testes. |

Crescimento do sprite não aumenta ocupação lógica. Nível não amplia automaticamente execução, chance máxima de crítico, ricochetes, invocações ou passos. **Raio do Bob é exceção escolhida**, não regra geral de alcance.

## Sinergias candidatas

Confirmado: maioria com duas ou três, patamares próprios, maior substitui menor, morte não desfaz a sinergia da formação. **Proposta:** cada chave ativa conta uma vez; cópias, nível, reserva e Ken não acrescentam membros. Classes funcionais atuais são TESTE, não aprovação dos grupos novos.

Camada cotidiana e classe de combate separadas; tabela inteira é **proposta**, não foi instalada. Presidentes permanece único, sem a divisão rejeitada em Governantes/Presidentes.

| Herói | Grupos candidatos |
| --- | --- |
| Neymar | Brasileiros · Atiradores |
| Caramelo | Brasileiros · Assassinos |
| Obama | Presidentes · Vanguardas |
| Zumbi | Brasileiros · Apoio |
| Michael | Músicos · Apoio |
| Barbie | Brinquedos · Vanguardas |
| Elon | Tecnologia · Atiradores |
| Snoop | Músicos · Atiradores |
| Lula | Brasileiros · Presidentes · Vanguardas |
| Bob | Músicos · Apoio |
| Rapunzel | Contos · Apoio |

Brasileiros inclui a referência cultural do Caramelo. Tecnologia/Brinquedos/Contos/Assassinos têm só um membro neste lote: não conceder bônus singleton automaticamente; aguardar pares ou propor efeito raro explícito. Rótulo sem patamar atingível deve ser distinto de sinergia ativa.

| Grupo / membros | Patamares | Efeito proposto, não aprovado |
| --- | --- | --- |
| Brasileiros: Neymar, Caramelo, Zumbi, Lula | 2/4 | +5%/+8% de vida aos membros; sem renda/cópias extras. |
| Presidentes: Obama, Lula | 2 | Escudo inicial de 6% da vida máxima aos dois, uma vez por rodada. Rivalidade de alvo em teste separado. |
| Músicos: Michael, Snoop, Bob | 2/3 | −15%/−25% de duração de controle forte aos membros; não muda dano/erro/relógio. |
| Atiradores: Neymar, Elon, Snoop | 2/3 | +8%/+12% de velocidade, respeitando teto. Michael sai desse rótulo provisório de teste. |
| Vanguardas: Obama, Barbie, Lula | 2/3 | +8/+12 de armadura aos membros, sem transferir automaticamente a Ken. |
| Apoio: Zumbi, Michael, Bob, Rapunzel | 2/4 | +5%/+8% de vida à equipe; maior substitui menor. |

Medir a camada cotidiana antes de somar todas as classes. Lula conecta três grupos; Obama/Lula ativam dois patamares; Michael/Bob combinam Músicos/Apoio; Bob/Zumbi já dão velocidade por kit. Podem virar peças obrigatórias ou reforçar demais escudos: riscos a medir, não conclusão de equilíbrio.

## Composições para comparar

Quatro ativos e quinto opcional; carry recebe prioridade de itens/cópias. Comparar lojas imperfeitas e níveis diferentes, não somente todos no nível 3.

| Ideia | Quatro / quinto opcional | Condição e resposta |
| --- | --- | --- |
| Carry físico | Neymar, Obama, Michael, Zumbi / Lula | Proteger ataques repetidos. Separar alvos e alcançar Neymar/Michael responde. |
| Dois carries distantes | Neymar, Elon, Obama, Bob / Snoop | Duas ameaças e investimento dividido; ambos físicos no teste. Armadura/flanco respondem; Snoop acrescenta mágico ao custo de proteção. |
| Desgaste mágico | Snoop, Lula, Rapunzel, Michael / Bob | Laço muda posição e fumaça desgasta. Resistência, sair da área e alcançar Snoop respondem. Não é composição de explosão mágica: esse carry ainda não entrou. |
| Assassino/finalização | Caramelo, Barbie, Zumbi, Bob / Rapunzel | Ken compra tempo; Caramelo se aproxima e Zumbi pressiona. Proteger a retaguarda, remover Ken e curar antes do limiar responde. Caça inicial é teste. |
| Carry corpo a corpo | Zumbi, Lula, Bob, Michael / Obama | Sustentar crescimento limitado. Controle, foco e afastar luta do Bob criam resposta. |
| Área/deslocamento | Elon, Snoop, Rapunzel, Barbie / Michael | Punir agrupamento e puxar uma peça. Isca resistente atrás, dispersão e acesso aos DPS respondem; Ken não deve vencer por contagem acidental. |

Separar vitórias por eliminação/tempo. Sobreviventes vêm antes de dano no desempate atual: avaliar juntos cura, escudo, volta de Lula e Ken, sem assumir que resistir até 30 s é necessariamente defeito ou meta desejada.

## Limites e contratos

Limites numéricos abaixo são **propostas**, não regras vigentes:

- Ricochete, explosão, fumaça e sangramento não geram ataques novos. IDs/limites evitam eventos repetidos; foguete não ricocheteia e nuvem não gera nuvem por tick.
- Lula volta uma vez, antes de avaliar eliminação; segunda queda mata. Barbie não recria Ken indefinidamente. Se não há célula livre, fallback finito e +30% desligado sem Ken vivo. Contagem/nível/capacidade da invocação devem continuar explícitos como hipóteses.
- Controle deixa agir: testar teto de 2 s consecutivos e 1 s de resistência após terminar. Não somar duração de fontes. Laço revalida destino e não empilha corpos.
- Lentidão não aumenta cadência: teto proposto de 40% de redução e piso 0,5 ataque/s, ou valor anterior se já menor. Ataque desabilitado fica zero. Bob muda velocidade, não dano/curas/relógio; recalcular cobertura após morte/movimento.
- Velocidade tem teto proposto de 3 ataques/s antes da aceleração e 6 sob 2×. Bob/Zumbi/itens/sinergias entram juntos; espera/caminhada/controle não acumulam ataques atrasados.
- Escudo da mesma fonte renova sem somar; fontes distintas têm ordem. Teto total de 50% da vida máxima é proposta a comparar. Mala periódica não cura ou concede escudo a cada tick por cooldown negativo.
- Cura para na vida máxima e não revive; Lula tem sua volta específica. Fumaça/sangramento são finitos, em relógio normal. Uma nuvem por Snoop é hipótese atual; substituição não pode duplicar ticks no mesmo instante.
- Miss é sorteado pela semente no momento definido pelo núcleo, sem novo sorteio por quadro visual. Erro de ataque não cancela habilidade independente silenciosamente. Projétil já lançado/área têm resultado consistente.
- Crítico próprio de Zumbi cresce com teto e reinicia por rodada; aliados/efeitos contínuos não o alimentam. Cópias não criam corpos, invocações ou membros extras.
- Relógio de 30 s e ocupação prevalecem sobre animação. Moonwalk, laço e Ken revalidam células; somente ativos/vivos ocupam. Efeitos pendentes não prorrogam rodada.

Sinergia persistir após morte não decide todas as auras: cura do Michael e aura posicional de Bob dependem de ele viver; teste de Zumbi captura bônus no começo; morrer Ken encerra +30% da Barbie.

## Loja, integração e prioridades

Com 11 candidatos, cópias tendem a aparecer menos que no conjunto antigo de cinco. Medir custo de renovações, rodadas até nível 2/3 e ausência de peça funcional. Não alterar probabilidades/preços/multiplicadores silenciosamente. Cópias grátis se juntam; excesso no máximo deve ser rejeitado sem consumir oferta.

Session atual já inicia chaves extras fora do campo com célula inválida segura; preservar essa extensão. Limite de reserva deve valer para recrutamento, remoção e troca, com rejeição atômica. Cópias possuídas podem juntar com reserva cheia porque não usam espaço adicional.

Preparação não revela itens, cópias, auras ou formação atuais do adversário; somente formação anterior com nível daquele momento. Ken surge na revelação, sem vazar Barbie da preparação. Aleatoriedade usa semente; animação não escolhe alvo/dano.

1. Exportar artes autorizadas preservando originais; conferir oito direções e novos primeiro. Efeitos técnicos não exigem geração paga para validar regra.
2. Preservar kits novos implementados e terminar refinos autorizados dos quatro antigos. Não reinstalar provocação de Lula, quarto disparo de Elon ou Jack/Cleópatra.
3. Após núcleo estável, rodar `test_match_session.gd` e `test_full_matches.gd`; investigar falhas antes de alterar fixtures. Verificar economia, cópias, reserva, invocação, vidas, privacidade e reprodução nas sementes existentes.
4. Comparar kits sem bônus novos; depois introduzir sinergias em etapas. Trocar lados/posições para observar viés de ordem e distinguir defeito de preferência de design.
5. Cerca de vinte partidas humanas iniciais servem para observar clareza/frustração, sem prova estatística de equilíbrio. Registrar duração, causa da vitória, níveis, itens, dano efetivo, cura, escudo, controle/erros recebidos e tempo sem agir do carry.

Este documento não autoriza novos heróis ou gasto extra e não executa gameplay. Cérebro/histórico registram decisões e validações reais; aqui ficam o plano de comparação e propostas ainda abertas.
