# Desempenho web e WebSocket — 13/10/2026

O usuário esclareceu: o Godot nativo no PC roda liso; o problema ocorre no navegador e no atalho instalado por ele. O atalho continua executando o cliente web. Esta entrega otimiza o cliente e o transporte existentes, sem trocar hospedagem, kits, economia ou arte. A continuação automática permanece pausada.

**Resultado local:** houve melhora real no combate Web, mas a meta de fluidez ainda não está concluída. Com um Chrome em DPR2, peer nativo sem renderização e servidor local, oito amostras de um segundo passaram de **8–12 FPS** para **29–38 FPS**, com outra execução da versão nova em **32–42 FPS**. A mediana dos intervalos médios de quadro passou de **105,48 ms para 31,40 ms** na comparação registrada. A baseline já contém as primeiras otimizações de interface/rede e ouro; ela é anterior aos caches de arena/molduras/cartas. Não confundir com uma medição pareada do site público original.

**Atualização posterior autorizada pelo usuário: publicação concluída em2026-10-13, commit999a37d.** HTML/PCK públicos iguais à build revisada, Vercel success e Render com pong validado sem entrar na fila. [Recibo de publicação](../deploy_2026-10-13/PUBLICACAO.json). Não houve compra ou migração. A versão preparada usa a cópia de fonte congelada para preservar as edições da outra IA no projeto principal. A entrega não comprova60FPS em combate, desempenho no celular físico ou capacidade do Render sob carga. A validação pública posterior foi de lobby/resize/protocolo, não de partidaPvP.

## O que foi medido e alterado

| Parte | Evidência antes | Alteração/resultado local |
| --- | --- | --- |
| Interface online | 3200 atualizações em2400quadros/800snapshots na fixture | 800 atualizações, uma por novo estado; animações continuam por quadro. |
| CPU do cliente na fixture | Preparação1,880ms; combate1,772ms | 0,542ms e1,076ms, respectivamente; exclui desenho/GPU e internet. |
| Rajada de8comandos | 16snapshots /38424bytes | 2snapshots /4803bytes; todos os comandos continuam processados. |
| Snapshot periódico | Combate3467B; preparação2379B | 2998B/1914B com cache negociado:−13,5%/−19,5%. Clientes antigos continuam compatíveis. |
| Mapeamento do time1 | Mediana664,93µs em combate | 426,17µs no benchmark pareado:−35,9%. |
| Recepção acumulada | Sem limite de trabalho por quadro | Até64pacotes e orçamento cooperativo4ms entre pacotes; eventos preservados. Não interrompe uma descompressão já iniciada. |
| Canvas em densidade2× | 2560×1440 para uma página1280×720 | Buffer limitado a1280×720:75% menos pixels nesse cenário, mantendo proporção, resize e orientação. |
| Servidor vazio | Cerca144polls/s, sem teto explícito | Cerca61polls/s, teto60; simulação20Hz e snapshots10Hz mantidos. Isso é contagem de polling, não medição de CPU no Render. |
| Ouro decorativo | 61 moedas geravam centenas de comandos Canvas por quadro | GPU cache desenhado uma vez; brilhos continuam animados. CPU nativa dos callbacks: 4,587 → 0,096 ms; isso não é tempo de GPU. |
| Arena/hexágonos/reserva | Base estática regenerada no mesmo desenho das tropas | Cache de GPU invalidado por fase, seleção, hover e ocupação relevante. Só o realce de seleção pulsa a 8 Hz. Corpos, projéteis e habilidades continuam por quadro. |
| Loja | Molduras, textos e ícones reapresentados como muitos comandos | Aparência das cartas em cache; os Buttons originais mantêm clique, tooltip, arrasto e comando autoritativo. Estado/hover renovam o cache. |

Também foram preparados antecipadamente bordas dos hexágonos, texturas dos feitiços e métricas dos quadros de animação. O histórico de eventos fica limitado; sinais continuam entregando todos os eventos. Há proteção contra acúmulo de snapshots substituíveis na fila de saída.

O diagnóstico opcional, em Configurações ou F3, separa FPS real, intervalo de quadro e ida/volta da rede. A ponte web expõe apenas números, sem nomes ou formações. O antigo selo fixo de60FPS foi removido.

## Evidências e limites

- [Cliente: reprodução, benchmarks e testes](../../../revisoes/performance_2026-10-13/CLIENTE.md).
- [Rede: comparação pareada e contratos](../../../RelicArena/captures/perf_rede_2026_10_13/RELATORIO.md).
- `public_before/runtime.json`: página pública abriu em Chrome isolado, sem erros de página, com isolamento correto. DPR2 tinha buffer2560×1440, p95 de requestAnimationFrame33,6ms e três long tasks na amostra. Isso não mede FPS interno do Godot nem identifica toda a causa da reclamação.
- `local_capped_final/runtime.json`: build release nova, DPR1/2, buffer e viewport1280×720; resize retrato preservado; oito verificações aprovadas. DPR2 teve p95 de requestAnimationFrame18,2ms e nenhuma long task nos3s amostrados. Não é uma comparação pareada nem uma promessa de desempenho no celular. Tempos de carregamento remoto/local não são comparáveis.
- Testes iniciais do cliente: smoke488/0 headless e OpenGL; regressão20/0 em ambos; banco122/0. Rede: existentes21/0, novos71/0 e recepção13/0. Registros detalhados nos relatórios vinculados. Testes posteriores dos caches constam abaixo e no recibo da entrega.
- Bundle de servidor somente com código/dados iniciou sem arte/UI/cache de importação. Não foi construído/testado um container Linux neste PC.

## Combate e investigação adicional

- `web_online_verified/web_online.json`: dois clientes Web no mesmo PC funcionaram, porém tinham somente 3–4 FPS. Esse resultado impediu considerar resolvido o problema com base apenas em testes headless ou no lobby.
- `web_online_single/web_online.json`: tirar threads antes dos caches não resolveu, ficando em 3–4 FPS. `web_cache_single_fixed` e `web_cards_single_final` repetem a experiência após os caches; o último teve mediana 29,09 ms e 27–39 FPS, próxima da versão multithread. **Não foi promovida a mudança de threads**, nem atribuída a ela a melhora principal.
- `chrome_gpu.json`: Chrome usou AMD Radeon/ANGLE D3D11, com WebGL e composição por GPU habilitados. O teste não usou SwiftShader. Ainda é Chrome headless neste PC, não o navegador/dispositivo do usuário.
- `web_fixed_baseline/web_online.json`: baseline de ouro/UI/rede, antes dos caches da base e da loja, peer já na fila para fixar também o lado do jogador. Mediana de oito janelas: 105,48 ms; amostras de 8–12 FPS. A medição anterior `web_paired_baseline_8s` deu84,56ms, porém não fixava a ordem de entrada dos jogadores e não é a comparação principal.
- `web_fixed_final/web_online.json`: mesma semente de sala 20261013, renderizador único e peer já na fila antes do cliente; mediana 31,40 ms e 29–38 FPS. `web_cards_fixed` foi uma repetição anterior, 25,92 ms e 32–42 FPS. Há variação de carga/timing; não apresentar um único quadro como garantia de desempenho.
- `web_two_final/web_online.json`: dois renderizadores simultâneos no mesmo PC, ambos em combate, sem erros de script/página. Medianas 59,90/57,70 ms; últimos FPS 14/15. É uma carga diferente de dois jogadores em máquinas separadas e continua longe de 60 FPS.
- A métrica de quadro passou a usar `Time.get_ticks_usec()`: o delta de gameplay é limitado pelo engine em quadros muito lentos e escondia parte do atraso. Probe determinístico com quatro intervalos de 250 ms mostrou média/p95 de 250 ms; gameplay não foi alterado.
- O cronômetro de CPU inclui polling, decode, perspectiva, eventos e atualização de UI, mas não desenho/GPU nem a própria publicação de diagnóstico. No código oficial Godot 4.7, `EMWSPeer::poll()` é vazio na Web; não há espera síncrona de rede ali. Chamadas JS do diagnóstico a 1 Hz permanecem uma hipótese para picos isolados, sem evidência de explicar todo o intervalo do quadro. [Fonte oficial](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/modules/websocket/emws_peer.cpp).

As capturas de preparação/combate foram inspecionadas: areia, grid, reserva, corações, moedas e cartas permanecem; PNGs e kits não foram redesenhados. A fixture gráfica valida cache após lobby oculto, imagem preenchida, invalidação de seleção/hover e reutilização durante combate. Próximo passo de produto: implantar esta versão revisada e comparar F3/FPS/RTT na máquina do usuário. Se RTT/ticks forem o limite depois disso, medir servidor/região antes de migrar.

## Hospedagem gratuita, verificada em13/10/2026

| Serviço | Adequação para este projeto |
| --- | --- |
| Vercel | Manter o frontend estático. A resposta pública foi cacheHIT com identificadorgru1 e COOP/COEP corretos. Trocar CDN não elimina custo de desenho/JavaScript depois de carregar. |
| Render Free | Compatível com o servidor atual;0,1CPU/512MB e750h/mês por workspace. Dorme após15min sem tráfego entrante; retomada pode demorar~1min. Oregon atual fica distante do Brasil; Virginia é candidata para comparação de rota, sem garantia de melhora. |
| Railway Free | TrialUS$5/30dias e depoisUS$1/mês recorrente. Aceita o container, mas o crédito pequeno precisa pagar memória/CPU/tráfego; não garante mês inteiro ligado. Não prometer escolha de região no Free. |
| Oracle AlwaysFree | Candidata mais forte para uma VM perto do Brasil, sujeita a capacidade/cadastro/cartão/administração. A documentação técnica atual informa ARM2OCPUs/12GB; Dockerfilex86_64 precisaria de adaptação paraARM. Nenhum cadastro ou mudança foi realizado. |
| Cloudflare | Workers/DurableObjects possuem cotas grátis, porém não executam diretamente o binário/container Godot. Containers são pagos. Pages também limita arquivos a25MiB; nossoWASM tem~37MiB. Não é migração gratuita direta. |

Fontes oficiais: [Render compute](https://render.com/docs/compute-plans), [Render Free](https://render.com/docs/free), [regiões Render](https://render.com/docs/regions), [Railway](https://railway.com/pricing), [Oracle AlwaysFree](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm), [Oracle regiões](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm), [Cloudflare Containers](https://developers.cloudflare.com/containers/platform/pricing/), [Pages limites](https://developers.cloudflare.com/pages/platform/limits/).

Vercel possui WebSockets em Functions em beta pública; portanto a afirmação antiga de que não suportaWS está desatualizada. Isso não substitui diretamente o processo Godot dedicado: Functions têm duração máxima e estado em memória não é garantido entre instâncias. [Documentação atual](https://vercel.com/docs/functions/websockets).

Recomendação: publicar/medir primeiro estas otimizações na hospedagem atual; comparar FPS/frame e RTT na mesma partida. Só migrar servidor se a medição indicar latência ou capacidade insuficiente. A versão foi implantada posteriormente, após autorização do usuário, conforme recibo acima.

## Entrega local preparada

- `dist/` contém os nove arquivos runtime da build multithread revisada. Publicado posteriormente no site público após aprovação.
- [Recibo consolidado](../../../RelicArena/VALIDACAO_PERFORMANCE_WEB_01.json): hashes da fonte congelada, logs, limites e comparação principal. Mediana do intervalo de quadro **105,48 → 31,40 ms**, redução local de **70,2%** nessa fixture; não é promessa de FPS público.
- [Build Web](../../../checkpoints/Clash_of_Eras_WEB_desempenho_2026-10-13.zip): nove arquivos, zero divergências de hash; basta publicar o conteúdo no frontend estático.
- [Fonte validada](../../../checkpoints/Clash_of_Eras_fonte_validada_desempenho_2026-10-13.zip):2249 arquivos, sem cache `.godot`; zero divergências na verificação. Preserva a versão efetivamente testada apesar das alterações simultâneas no projeto principal.
- [Backup da Web anterior](../../../checkpoints/Web_antes_desempenho_2026-10-13.zip) preservado. Não enviar toda a árvore alterada do Git automaticamente: há trabalho da outra IA e alterações anteriores fora deste escopo.
- Após o cache completo: cliente20/0, arrasto18/0, smoke488/0 headless e488/0 OpenGL, cache gráfico10/0, stderr vazio. Landing/resize Web DPR1/2:8/0; ambos os lobbies mediram60FPS. Um e dois clientes reais chegaram ao combate sem erros, mas as limitações de FPS acima permanecem.

Para revisar a publicação: frontend é o conteúdo preparado em `dist/`; backend precisa das mudanças em `net/` e `server/dedicated_server.gd`, junto das regras/dados da fonte validada. `.dockerignore` remove arte, caches e ferramentas do contexto do servidor. Container Linux e capacidade do Render não foram testados neste PC. Não há migração automática aprovada.
