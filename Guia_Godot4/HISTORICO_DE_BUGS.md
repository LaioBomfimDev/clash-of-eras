# Histórico de bugs e investigações

Atualização: 2026-10-12, America/Sao_Paulo.

Este arquivo registra o que foi observado, como investigamos, quais hipóteses foram descartadas, o que mudou e como verificamos a solução. Consultar antes de investigar um problema semelhante. Decisões e regras atuais ficam em [CEREBRO.md](CEREBRO.md).

**Situação atual:** primeiro protótipo Godot local contra bot criado em 2026-10-11. BUG-001 registra uma falha real de cadência de ataque reproduzida e corrigida durante a implementação. As ocorrências anteriores de MCP/arte permanecem como histórico; testes locais não validam multiplayer, celular ou balanceamento.

## 1. Tipos de registro

| Prefixo | Uso |
| --- | --- |
| BUG | Defeito reproduzido no produto: comportamento implementado contraria a regra aprovada. |
| INC | Ocorrência de ambiente, ferramenta ou operação. Pode ter causa desconhecida. |
| DOC | Contradição, ambiguidade ou entendimento incorreto na documentação. |
| RISK | Hipótese de risco, sem defeito reproduzido. Preferir registrar no cérebro enquanto for assunto de design. |

Estados possíveis: aberto, em investigação, causa confirmada, correção aplicada aguardando validação, resolvido com evidência, contornado, não reproduzido e encerrado por decisão de design.

Uma imagem posterior correta pode comprovar que o sintoma desapareceu, mas não comprova a causa nem uma correção de código. Uma mudança de requisito pode encerrar uma dúvida documental sem ser uma correção de bug do jogo.

## 2. Regras de registro

- Descrever fatos e resultados reais; identificar interpretações como hipóteses.
- Registrar consultas, comandos e arquivos relevantes com resultado resumido, sem despejar saídas enormes.
- Uma tentativa malsucedida é útil quando explica por que uma hipótese foi descartada.
- “Resolvido” exige evidência do comportamento correto. Se só existe alternativa de uso, marcar contornado.
- Não afirmar que um teste passou se foi apenas proposto ou se não houve execução.
- Não registrar tokens, chaves de API, senhas ou conteúdo privado de contas.
- Uma lição só vira regra no cérebro quando é aplicável; não generalizar um incidente isolado sem evidência.
- Preservar o histórico de uma investigação quando novas evidências mudarem sua conclusão.

## 3. Modelo para um bug ou incidente

Copiar este modelo ao encontrar uma ocorrência real. Campos sem evidência devem dizer “não verificado”, “não aplicável” ou “pendente”.

### BUG-XXX — Título com sintoma e condição

**Tipo e estado:** BUG / aberto.

**Datas:** identificação; última investigação; validação final.

**Impacto:** quem é afetado, frequência, gravidade e se impede jogar. Gravidade e prioridade são informações distintas.

**Ambiente:** versão/commit do jogo, versão de regras, Godot, sistema, dispositivo, resolução quando relevante, cliente/servidor e topologia da rede.

**Regra esperada:** link para a decisão atual do cérebro ou requisito explícito do usuário.

**Resultado observado:** o que aconteceu, com mensagem de erro e evidência disponíveis.

**Reprodução mínima:**

1. Estado inicial necessário.
2. Comando ou ação.
3. Resultado observado e frequência de reprodução.

**Dados para reproduzir uma rodada:** semente, identificador da partida/rodada, relógio do servidor, decks, níveis, formação, moedas, inventário, sinergias, benefícios e versão de dados. Registrar apenas o que for necessário, sem dados privados.

**Evidências:** caminho do log, captura, estado serializado ou saída curta. Especificar o que cada evidência demonstra e o que ela não demonstra.

**Investigação:**

| Passo | Pergunta/hipótese | Busca, comando ou arquivo consultado | Resultado | Consequência |
| --- | --- | --- | --- | --- |
| 1 | Hipótese inicial. | Consulta exata ou procedimento. | Evidência real. | Manter, descartar ou investigar mais. |

**Causa:** mecanismo identificado e evidência que o sustenta. Se desconhecida, não preencher com uma suposição.

**Correção ou contorno:** arquivos/funções alterados, mudança de comportamento, motivo e limitações. Distinguir correção definitiva de alternativa operacional.

**Validação:**

- Antes: reprodução executada e resultado, se disponível.
- Depois: mesmo caso executado e resultado.
- Casos relevantes adicionais: limites, comando duplicado, outro cliente, outra fase ou outra semente, conforme o defeito.
- Testes não realizados e motivo.

**Regressão:** teste automatizado ou roteiro que detecta a volta do defeito. Evitar testes que apenas repetem a implementação sem verificar uma regra útil.

**Lição e prevenção:** o que procurar primeiro na próxima ocorrência; atualização necessária no cérebro ou nos dados.

**Encerramento:** estado final, data e evidência suficiente para a conclusão. Se houver reabertura, acrescentar nova evidência sem apagar a anterior.

## 4. Ocorrências reais da preparação

### INC-001 — Personagem não apareceu na primeira consulta à galeria

**Estado:** sintoma posteriormente ausente; causa não confirmada. Não foi aplicada uma correção técnica.

**Contexto:** conexão e inspeção do PixelLab pelo navegador, antes de validar MCP.

**Esperado:** localizar o personagem inspirado em Michael Jackson que o usuário havia criado.

**Observado:** uma consulta inicial mostrou galeria vazia/nenhuma imagem na área observada. Posteriormente, na página correta de Characters aberta pelo usuário, foi observado o personagem de 48 × 48 com 8 direções.

**Investigação e resultado:**

| Passo | Ação | Resultado |
| --- | --- | --- |
| 1 | Inspecionar as páginas disponíveis no navegador. | A primeira área observada não mostrou o personagem. |
| 2 | Inspecionar Characters após a navegação do usuário. | O personagem apareceu na tela observada. |

**Causa:** desconhecida. Não há evidência suficiente para atribuir a login, cache, conta, atraso ou problema do serviço.

**Ação:** nenhuma geração, exclusão, troca de conta ou redefinição foi executada para resolver esse sintoma.

**Validação e limite inicial:** a presença visual foi observada; naquele momento, download, qualidade de todas as direções, importação e consulta por MCP não haviam sido validados.

**Atualização em 2026-10-10:** list_characters com busca Michael e get_character foram executados por cliente MCP de diagnóstico e retornaram registros da conta sem erro, incluindo uma prévia. IDs e metadados estão no cérebro. Isso valida a consulta por MCP, sem esclarecer a causa da galeria vazia na primeira observação. Importação e qualidade de todos os quadros continuam sem validação.

**Lição:** confirmar página e método de acesso antes de concluir que um asset não existe. Navegador e ferramentas MCP são canais diferentes.

### INC-002 — Executável Godot dentro de pasta com nome terminado em .exe

**Estado:** localização e execução verificadas; instalação fora do PATH contornada pelo caminho absoluto.

**Ambiente:** Windows; Godot baixado pelo usuário. Nenhum projeto novo iniciado.

**Observado:** não havia comando `godot` disponível no PATH. O caminho externo `C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe` era uma pasta, contendo os executáveis.

**Investigação:** localizar a pasta e seus executáveis, depois executar o binário de console com argumento de versão.

~~~powershell
& 'C:/Users/m/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --version
~~~

**Resultado real:** `4.7.2.stable.official.ed1daf0bf`, código de saída 0.

**Causa do obstáculo de localização:** nome da pasta semelhante a um executável e ausência do comando no PATH. Isso não demonstra defeito do Godot.

**Ação:** uso do caminho absoluto. Não foi necessário alterar o PATH, reinstalar, mover ou excluir arquivos.

**Validação e limite:** binário executável e versão confirmados. Editor, renderização de uma cena, exportação móvel e servidor multiplayer não foram testados.

**Lição:** verificar se o caminho é arquivo ou pasta antes de tentar executar. Guardar o caminho confirmado no cérebro, sem confundir verificação de versão com teste de jogo.

### DOC-001 — Regras históricas conflitavam com o novo projeto

**Estado:** tratamento documental definido; arquivos antigos preservados.

**Observado:** o guia anterior e o novo pedido descrevem jogos diferentes em pontos relevantes.

**Buscas e evidências:** leitura e busca nos guias e no prompt antigo.

| Fonte histórica | Exemplo encontrado | Direção atual |
| --- | --- | --- |
| `GUIA_COMPLETO.md`, linha 77 na leitura inicial | 100 de vida e 12 moedas. | 4 vidas; ouro inicial ainda pendente. |
| `GUIA_COMPLETO.md`, linha 394 na leitura inicial | Renovação por 2 moedas. | Referência atual de 3, ainda hipótese. |
| `GUIA_COMPLETO.md`, linha 408 na leitura inicial | Evolução com três cópias/três estrelas. | Evolução na partida reaberta, sem regra aprovada. |
| `PROMPT_PARA_PROXIMA_LLM.md`, linhas 13–20 na leitura inicial | Campanha offline, loja de 5 e reserva de 8. | Multiplayer, aquisição reaberta e reserva pendente. |
| `PROMPT_PARA_PROXIMA_LLM.md`, linha 44 na leitura inicial | Instrução antiga para implementar. | Pedido atual autoriza documentação; implementação ainda depende do escopo solicitado. |

As linhas são referências da leitura de 2026-10-10, não uma garantia de posição após futuras edições.

**Causa:** os documentos preservam uma versão anterior e foram anexados como material de referência. Não há evidência de que todos os requisitos históricos foram revalidados pelo usuário.

**Tratamento:** `CEREBRO.md` e `AGENTS.md` estabelecem precedência das decisões atuais e identificam o material antigo como histórico. Não editar os arquivos antigos nem seus manifestos nesta etapa.

**Validação:** revisão documental; não se trata de teste de gameplay.

**Lição:** antes de reutilizar código ou dados antigos, comparar a regra com a decisão atual e marcar conflitos, em vez de selecionar silenciosamente uma versão.

### DOC-002 — Percentual de progressão fora da partida entendido incorretamente

**Estado:** corrigido conforme instrução explícita do usuário.

**Observado:** o assistente interpretou o crescimento como 40% por nível e calculou seu efeito acumulado. O usuário esclareceu que pretende aproximadamente **5–6% por nível**, do nível 1 ao 10, fora da partida.

**Causa:** entendimento incorreto de um valor durante a conversa; não é defeito implementado no jogo.

**Correção:** registrar 5–6% como referência atual, descartar 40% e manter em aberto a fórmula exata, o arredondamento e os atributos afetados. Separar progressão de carta, eventual evolução na partida e fusão de itens.

**Validação documental:** com nove aumentos, a hipótese composta de 5% resulta em aproximadamente 1,5513 vezes o atributo; a de 6%, 1,6895. Esses exemplos não aprovam a fórmula composta.

**Lição:** quando o usuário corrigir uma hipótese, atualizar a regra principal e qualquer análise derivada. Não continuar apresentando o valor descartado como risco atual.

### INC-003 — Tipo de transporte preenchido no campo de variável do token

**Data:** 2026-10-10.

**Estado:** resolvido. Configuração e leitura autenticada validadas em 2026-10-10; exposição das ferramentas nativas neste chat e chamadas diretas confirmadas em 2026-10-11.

**Contexto:** usuário cadastrou o servidor MCP `pixellabs` no Codex para acessar PixelLab. Uma captura mostrou o texto `streamable HTTP` no campo “Variável de ambiente de token do portador”.

**Regra esperada:** esse campo deve conter o nome de uma variável de ambiente que fornece o token, ou ficar sem configuração quando a autenticação vem do cabeçalho Authorization. O transporte HTTP é indicado pela configuração de URL, não pelo nome de variável de token.

**Observado e investigação:**

| Passo | Verificação | Resultado |
| --- | --- | --- |
| 1 | Inspecionar a captura fornecida pelo usuário. | Texto de transporte preenchido no campo de variável do token. |
| 2 | Ler a configuração com tomllib e emitir somente indicadores sem segredos. | Servidor habilitado, URL esperada, bearer_token_env_var com o texto incorreto e Authorization com prefixo Bearer presente. |
| 3 | Consultar os nomes das ferramentas disponíveis neste chat. | Nenhuma ferramenta PixelLab disponível nessa consulta. |
| 4 | Remover somente a propriedade incorreta e comparar os dados antes/depois. | Todas as outras configurações preservadas. TOML reaberto e verificado. |

**Causa identificada inicialmente:** confusão entre tipo de transporte e nome de variável de ambiente na configuração. Não havia naquele momento evidência suficiente para explicar toda a ausência das ferramentas ou validar a chave. A investigação posterior confirmou nos logs a falha por variável ausente; detalhes abaixo.

**Correção:** remover somente `bearer_token_env_var` da seção do servidor em `C:/Users/m/.codex/config.toml`. URL, cabeçalhos e demais servidores foram preservados. A mudança foi gravada por substituição do arquivo temporário e verificada por igualdade dos dados, descontando a única propriedade removida.

**Validação inicial:** leitura TOML após gravação passou; propriedade incorreta ausente; demais dados iguais ao original. Naquele momento ainda não havia sido feita chamada autenticada ao PixelLab. Nenhuma geração ou rotação de chave foi realizada.

**Validação posterior, após o usuário informar PRONTO:**

| Passo | Ação/resultado real |
| --- | --- |
| 5 | Releitura sanitizada da configuração: campo incorreto continua ausente, URL esperada e Authorization presentes. |
| 6 | Catálogo deste chat ainda não apresentava ferramentas PixelLab. |
| 7 | Cliente MCP de diagnóstico executou initialize no endpoint /mcp: HTTP 200, servidor PixelLab MCP Server, protocolo 2025-11-25. |
| 8 | Notificação initialized aceita com HTTP 202; tools/list retornou 101 ferramentas, incluindo list_characters e get_character. |
| 9 | list_characters com busca Michael foi aceita sem erro, mas a primeira impressão do resultado falhou com UnicodeEncodeError no terminal Windows. A saída do cliente de diagnóstico foi configurada para UTF-8 e a consulta foi repetida com sucesso. |
| 10 | list_characters retornou quatro registros; get_character verificou versões prontas, um grupo de animação em oito direções e uma tentativa com Generation failed. Uma prévia foi observada. Nenhuma criação, exclusão ou repetição de geração. |

**Evidência nos logs locais:** `C:/Users/m/AppData/Local/Codex/Logs/2026/10/10/codex-desktop-ed23c37f-a6ba-45ad-90c0-daad9ad7bb91-7104-t0-i1-015800-0.log`, lido por indicadores sem expor credenciais:

- Linha 3131, às 17:57:32 de Brasília: última falha antiga por variável de ambiente streamable HTTP ausente.
- Arquivo de configuração corrigido gravado às 17:57:58, conforme metadados consultados.
- Linha 3331, às 18:03:27: servidor pixellabs starting, error=null e failureReason=null.
- Linha 3342, às 18:03:29: servidor pixellabs ready, error=null e failureReason=null.

O teste usou JSON-RPC MCP autenticado, não endpoints REST v2. O cabeçalho foi lido somente em memória e enviado ao endpoint previamente conferido; não foi incluído nas saídas ou documentos. O cliente seguiu a inicialização, notificação initialized e formato Streamable HTTP descritos na [especificação de ciclo de vida](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle) e de [transporte](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports).

**Conclusão prática:** configuração, inicialização local e leitura da conta pelo protocolo MCP funcionam. A exposição automática das ferramentas no catálogo deste chat é uma questão separada ainda sem causa confirmada. Não diagnosticar token inválido ou falha do serviço a partir da ausência no catálogo, pois as consultas autenticadas passaram.

**Atualização em 2026-10-11:** o catálogo deste chat passou a expor as ferramentas mcp__pixellabs. A chamada nativa get_balance retornou sem erro e create_image_pixen aceitou a primeira geração da arena, identificador f8547533-4fbd-4169-8319-40e920c8616f. A ausência anterior do catálogo não persistiu. Não houve nova edição de credenciais nem evidência que permita atribuir a mudança a uma causa adicional específica.

**Observação de interface:** um formulário aberto antes da edição pode estar desatualizado; reabrir a configuração antes de voltar a editá-la.

**Lição:** ao configurar autenticação, distinguir transporte, token literal em cabeçalho e nome de variável de ambiente. Investigar emitindo apenas indicadores, sem registrar credenciais.

### INC-004 — Abertura da prévia local recusada pelo navegador

**Data:** 2026-10-10.

**Categoria:** acesso de ferramenta; não é bug de gameplay.

**Estado:** alternativa estática entregue; abertura e interação do HTML no navegador não verificadas.

**Reprodução e observação:** após criar `visuais/arena_areia_estudo_01.html`, foi iniciado um servidor Python temporário, limitado a 127.0.0.1:8765 e à pasta de visuais. A tentativa de abrir a página com createBrowserTab foi recusada pela política do navegador, com a razão de que o usuário havia negado permissão à solicitação. A mensagem também proibiu contornar o bloqueio por outras superfícies ou mecanismos de navegador.

**Causa sustentada:** recusa explícita de acesso pela ferramenta. Não houve evidência de defeito no HTML, falha do Godot ou problema no PixelLab. Não inferir esses diagnósticos a partir do bloqueio.

**Ação:** encerrar o servidor temporário e criar `visuais/arena_areia_estudo_01.png` diretamente com Pillow, usando as fórmulas geométricas do esquema, sem acessar a página e sem tentar outro navegador, porta ou automação equivalente.

**Validação:** servidor encerrado; PNG salvo com 1600 × 1080 pixels e inspecionado como arquivo local. A contagem calculada confirmou 64 casas e 32 por lado. A imagem não é uma captura do HTML, e os controles do HTML não foram testados em navegador.

**Lição:** distinguir bloqueio de acesso de erro do artefato. Registrar a limitação e usar uma alternativa que não dependa da ação recusada, preservando a entrega para revisão.

### ART-001 — Geração de cenário trouxe dois coliseus

**Data:** 2026-10-11.

**Categoria:** revisão de arte gerada; não é bug de gameplay ou falha de autenticação.

**Estado:** duplicação ausente no terceiro estudo, mas o usuário rejeitou seu enquadramento e aparência. A revisão com referências está registrada em ART-002; não houve aprovação final.

**Esperado:** um único coliseu medieval ocupando a cena, com areia clara e centro livre para sobrepor o tabuleiro 8 × 8.

**Reprodução, investigação e resultados:**

| Passo | Evidência |
| --- | --- |
| 1 | create_image_pixen, 768 × 324, seed 10112026, job f8547533-4fbd-4169-8319-40e920c8616f: imagem concluída com dois coliseus. |
| 2 | Prompt reforçado para uma única construção e formato alterado para 640 × 360, seed 10112027, job 29f57669-2054-4ba9-8d60-4f5795f8806e: repetiu dois coliseus. |
| 3 | create_image_pixflux com descrição mais simples, 384 × 216, seed 10112028, job a6c01c0d-c767-4f18-a0dd-de2cc2a10452: imagem concluída com um único recinto oval e areia clara. |

**Causa:** não determinada. A alteração do prompt/proporção no segundo estudo não resolveu. Modelo, resolução, descrição e seed mudaram no terceiro, portanto o resultado não isola qual mudança evitou a duplicação. Não afirmar defeito interno do modelo sem evidência.

**Correção de composição observada:** terceiro estudo reservado como candidato para revisão. As paredes em faixas ainda não apresentam arquibancadas com degraus tão evidentes quanto a prévia; não tratar o cenário como arte final aprovada.

**Preservação e validação:** os três jobs retornaram completed, asset_status saved e charged 1 generation cada. As imagens foram observadas, e PNGs originais foram salvos e verificados nas dimensões informadas, sem edição local. Briefings, seeds, IDs e revisões estão em `visuais/arena_pixellab_01.json`, `arena_pixellab_02.json` e `arena_pixellab_03.json`. As tentativas anteriores e os personagens existentes foram preservados. Não houve teste de mapa no Godot ou do encaixe da grade.

**Lição:** inspecionar a composição inteira antes de importar o cenário. Uma geração concluída não comprova que o briefing foi seguido. Manter referência geométrica separada e limitar as tentativas; mudar várias condições ao mesmo tempo pode produzir uma candidata melhor, mas não estabelece a causa do problema.

### ART-002 — Revisão da arena com referência e limites do PixelLab

**Data:** 2026-10-11.

**Categoria:** arte e ferramentas de produção; não é bug de gameplay.

**Estado:** estudo derivado da referência e prévia estática entregues. Nova geração Pro bloqueada pelo limite informado pelo serviço; acabamento e aprovação final pendentes.

**Reprodução e esperado:** o usuário rejeitou o estudo 03, que mostrava uma construção em miniatura, e enviou três imagens. Pediu câmera inclinada dentro do coliseu, com arquibancadas altas em degraus e mais detalhe. A referência 02, com assentos vazios e areia clara, foi usada como base principal.

**Investigação e evidências:**

| Passo | Ação e resultado observado |
| --- | --- |
| 1 | As três referências foram preservadas em visuais/referencias. A segunda foi inspecionada; contagens e textos nela não foram adotados como regras do jogo. |
| 2 | unzoom_image, job 950f6419-4fb9-42ef-b71e-789890defca6, recuperou 351 × 195 pixels, salvou asset 4dd04d55-043f-57f3-a33e-d78b9830bd4f e informou cobrança de 0,1 geração. |
| 3 | Pixflux recusou a dimensão, que precisa ser múltipla de quatro. Preparação gratuita por draw retornou limite de memória. System.Drawing acrescentou uma coluna e linha transparentes para 352 × 196; comparação confirmou os 68.445 pixels originais intactos. |
| 4 | Estudo 04, job f5d354df-296a-469e-bde5-41413239390d, strength 150, seed 10112029: interior melhor, mas HUD, unidades e marcações permaneceram. Cobrança informada: 1 geração. |
| 5 | Estudo 05, job 4d5b6413-8130-44e6-af48-bfdeb9d87c80, strength 75, seed 10112030: serviço informou completed e saved, cobrou 1 geração, mas a imagem é preta. PNG válido 352 × 196; extremos dos três canais RGB iguais a (0,0). |
| 6 | edit_image Pro recusou a chamada com “trial generations used up”. Não criou job nem informou cobrança. Consulta get_balance ainda apresentou 15 gerações restantes e 2 diárias. Não atribuir a recusa a token inválido ou diagnosticar a discrepância sem evidência adicional. |
| 7 | O editor exato gratuito pixelart_workbench aceitou limpeza da referência. A primeira cópia da faixa superior inteira, id 8466905a-83ae-4395-87f8-f95fcc6699a9, duplicou degraus e plataformas. Inspeção visual independente confirmou a emenda horizontal. |
| 8 | Tentativa de recorte por draw foi recusada porque a fonte excedia a nova tela; nada foi renderizado. Não houve repetição de gerações pagas. |
| 9 | Limpeza refeita sobre a fonte com cópias localizadas apenas nas áreas de HUD; id 2b21d96c-b450-4c93-84a7-04c1ac33f4b5. A repetição grande desapareceu. Textura esparsa adicionada pelo mesmo editor; fundo final id 8e95c9b6-c4ec-4f4d-9617-95f81d28c2b5. |
| 10 | Prévia separada id 4d38fdfb-2b99-4a9b-8f16-b62ddd30b257 acrescentou 64 polígonos hexagonais. Fundo e prévia salvos gratuitamente como novas imagens na galeria: 7cc011ca-137c-4bd2-9461-527c0eb95d2f e 20112cfc-d086-49ba-9e0b-1a4269edd6b6. |

**Causas sustentadas:** a repetição de degraus na primeira edição exata veio da operação explícita de copiar a faixa inteira. A rejeição de formato e a recusa de limite têm mensagens explícitas. A causa interna da imagem preta, do limite de memória e da discrepância de saldo não foi determinada. Mudar strength, texto e seed simultaneamente não permite atribuir o resultado preto a um único parâmetro.

**Mudança e resultado:** substituição da cópia ampla por remendos localizados; remoção de HUD, unidades e grade da referência; textura discreta na areia; prévia de grade em arquivo próprio. A arquitetura foi preservada da imagem fornecida: não declarar que a edição produziu uma arena original nova.

**Validação e limites:** PNGs finais 351 × 195 baixados sem edição local e inspecionados. Revisão independente confirmou desaparecimento da repetição ampla, mas observou pequenas emendas superiores e acabamento provisório na grade. Quantidade de células conferida nos dados: 64, oito fileiras e oito colunas, quatro fileiras por lado. Nada disso valida toque, escala dos personagens, oclusão, partida ou Godot. Nenhum asset existente foi substituído e nenhuma credencial foi alterada.

**Arquivos:** visuais/arena_pixellab_04.json, arena_pixellab_05.json e arena_referencia_estudo_02.json preservam briefings, IDs e operações. arena_referencia_limpa_01.png preserva a limpeza inicial rejeitada; arena_referencia_limpa_02.png é o fundo atual; arena_referencia_previa_02.png é a prévia com grade.

**Custo informado:** 2,1 gerações nesta revisão, além das 3 anteriores. A edição exata e os dois salvamentos são gratuitos conforme o contrato nativo. Não continuar tentando modelos pagos após a recusa de limite.

**Lição:** completed não comprova qualidade nem conteúdo útil. Conferir PNG e composição; separar ajuste de câmera, limpeza e geometria; usar referência explícita e preservar a origem de uma edição. Um resultado derivado de referência deve ser identificado como estudo, com aprovação visual ainda aberta.

### INC-005 — Primeiro núcleo de personagens e limitações do PixelLab

**Data:** 2026-10-11. **Categoria:** ferramenta de produção; não é bug do jogo.

**Estado:** parâmetros corrigidos e Zumbi concluído; Caramelo/Obama continuam bloqueados pelo serviço. Download completo das rotações pendente.

**Reprodução e esperado:** criar três personagens estáticos em modo standard, oito direções, solicitando 48 × 48, preservando o Michael existente. Esperado: bases disponíveis para inspeção antes de animar.

| Investigação/ação | Resultado observado |
| --- | --- |
| Consulta à ajuda e ao saldo nativos | Standard aceita oito direções e anuncia 1 geração por personagem; saldo inicial: 15 restantes, 24 usadas, trial. Não usar custo Pro como se fosse standard. |
| Caramelo quadrúpede sem template | Validação recusou o pedido antes de criar job. Acrescentado template dog; pedido aceito com ID 8fe8568a-d1a7-4023-b22c-2e4bff40f642. |
| Proporções de humanoide em texto livre | Serviço exigiu JSON. Alterado para preset chibi em string JSON; Zumbi aceito com ID 40cff10a-fe31-472e-8bd8-94246e5f341e. |
| Obama enquanto havia tarefas ativas | Limite de tarefas simultâneas. Aguardada liberação antes de criar o pedido d33b1ab5-3166-4503-a90e-aaadb14cea0a. |
| Zumbi concluído | API informou oito direções. Prévia PNG RGBA é 68 × 68, embora o pedido fosse 48 × 48. Causa da diferença não determinada; original preservado. |
| Caramelo, primeira tentativa | Job falhou com mensagem de conexão ao worker. Feita uma única nova tentativa, ID 307e36d8-a8fe-4fd3-bf77-45f3a3bcf134. |
| Obama e segunda tentativa de Caramelo | Ambos falharam com “Sorry, we are experiencing high demand and need to temporarily limit free tier.” Nenhum PNG. Encerradas novas tentativas sob essa limitação. |
| Download público das rotações de Michael | HTTP 403. Acesso interrompido, sem outros endpoints, identidades ou rotas para contornar. Usadas apenas as prévias já entregues pelo MCP. |
| Saldo final | 14 restantes, 25 usadas, trial, créditos US$ 0. Não permite atribuir cobrança/reembolso individual às falhas. |

**Causas sustentadas:** parâmetros template e proportions incompatíveis tinham mensagens de validação explícitas e foram corrigidos. Alta demanda e limite da conta gratuita foram informados pelo serviço; não diagnosticar token inválido ou plano esgotado. Causas internas da conexão falha, do 403 e da dimensão 68 × 68 permanecem desconhecidas.

**Mudança e entrega:** dados de geração, briefings e IDs preservados em [personagens_lote_01.json](visuais/personagens_lote_01.json); [galeria](visuais/personagens_lote_01.html) apresenta duas prévias disponíveis e dois personagens pendentes. Michael e sua animação foram preservados. Prévia sul de cada resultado pronta em arquivo próprio, sem edição local de pixels; oito direções locais não foram obtidas.

**Validação executada:** Pillow verificou os três PNGs (coração, Michael e Zumbi), transparência, dimensões e área visível. Node conferiu sintaxe dos dois HTMLs; referências locais, JSONs, IDs únicos, 64 células e quatro corações por lado foram conferidos. [Resultado](visuais/personagens_lote_01_validacao.json). Renderização/interação em navegador, demais direções e Godot não testados.

**Lição:** validar os campos do gerador antes da fila; conferir dimensões retornadas; tratar conclusão, qualidade artística e exportação completa como verificações diferentes. Não insistir em gerações sob recusa explícita nem inventar PNGs ou cobranças de tarefas falhas.

**Continuação, após novo pedido do usuário para refinar e ampliar o elenco:** uma nova tentativa de Caramelo e uma de Obama concluíram, assim como Neymar. Isso comprova disponibilidade posterior do serviço; não determina a causa interna das falhas anteriores, nem prova que mudar o briefing as resolveu.

- Zumbi recebeu edição exata gratuita (corpo, lança e nó da faixa), galeria 096fe9a6-10de-47f7-b96e-80a5f117a46d, preservando o original. Uma nova base v3 reference em oito direções foi concluída, ID 7129a655-427d-4ca9-84bb-13ad3ddd4682. Pixels visíveis e alfa do sul iguais à referência; RGB difere somente sob transparência total.
- Caramelo 82eace58-7128-4f15-97ce-1944a5702428, Obama 9a2a0a13-3fca-4dd6-a685-94d312c75bb2 e Neymar fcc05054-6672-4efb-b417-f49cffcc7b7f concluíram oito direções, com prévias nativas salvas. Todos retornaram 68 × 68 após pedido de 48 × 48; causa não determinada.
- As oito direções do Caramelo foram inspecionadas pelo editor nativo. Uma inspeção sudeste retornou ocupado e uma repetição funcionou. Exportar image.png de um ID de inspeção retornou HTTP 404; não houve tentativa por URLs alternativas ou Backblaze. Exportações dos IDs de edição exata de Zumbi/Obama funcionaram. Não concluir uma causa geral para o 404 a partir desses casos.
- Obama e Neymar receberam refinamentos frontais gratuitos para exagerar acessórios; esses detalhes ainda não foram levados às outras sete direções. Originais e animação de Michael preservados.
- Ajuda estimou 2 gerações para v3 reference; a criação informou 1. Saldo 14/25 passou para 10/29 (restantes/usadas), compatível com quatro pedidos de 1. Custos das edições exatas foram zero. Registrar a diferença entre estimativa e retorno sem inventar cobrança extra.

**Estado atualizado:** bloqueio de geração anterior não persistiu nas novas tentativas; exportação completa e acabamento continuam pendentes. Dados desta continuação em [personagens_lote_02.json](visuais/personagens_lote_02.json). Não é correção de código do jogo.

### ART-003 — Lâmina pouco visível no perfil após rotação do Zumbi

**Data:** 2026-10-11. **Categoria:** continuidade de arte, não bug de gameplay.

**Reprodução:** após concluir oito direções a partir da frente refinada, inspecionar o oeste da base 7129a655-427d-4ca9-84bb-13ad3ddd4682 e comparar com leste/frente/costas. A lâmina branca larga quase desaparece atrás da cabeça no oeste; no leste permanece legível.

**Investigação:** oito vistas inspecionadas nativamente em 4×; registro dos IDs em personagens_lote_02_inspecoes.json. A identidade de pele, cabelo, faixa e roupa se mantém, mas arma e nó variam nos perfis. A causa interna da rotação gerada não foi determinada. O sintoma visual é oclusão/perda de leitura, não falha comprovada de código.

**Mudança aplicada:** oeste anterior preservado na galeria 3c592b44-a1e4-4748-a3ea-fe9505de660d. Primeira candidata tornou a lâmina visível, mas pareceu adereço no cabelo; não foi aceita como final. A segunda passagem colocou lâmina e cabo atrás da cabeça com máscara restrita a espaços transparentes. Resultado 8f7b050a-0068-4fd6-8c98-6ae30e838390 salvo na galeria 62aab996-fe20-4a26-bd0b-cef46932cab9 e aplicado somente ao oeste da nova base V3. O personagem original e os demais ângulos foram preservados. Sem geração de IA.

**Validação e estado:** correção estática aplicada e conferida. Inspeção nativa do personagem após salvar, em 6×, confirmou lâmina e cabo legíveis. PNG 68 × 68 com alfa binário; 86 pixels adicionados, preservando todos os 668 pixels originais visíveis. Área visível final (25,3,50,57). Não comprova animação ou acabamento final dos demais perfis. [Operações, IDs, undo e validação](visuais/personagens/zumbalhao/revisao_02/west_refinamento.json), [PNG corrigido](visuais/personagens/zumbalhao/revisao_02/rotacoes/west.png).

**Lição:** inspecionar todas as direções antes de animar; presença do acessório no briefing/frente não garante leitura nos perfis. Correção localizada pode preservar rosto/roupa por máscara e deve ser conferida depois de salvar no asset, com possibilidade de desfazer.

**Validação geral do lote:** onze PNGs, dois scripts HTML, cinco personagens/nove prévias, JSONs e links locais conferidos; hashes dos originais de Michael e Zumbi preservados. [Registro](visuais/personagens_lote_02_validacao.json). Nenhum teste em navegador, dispositivo, Godot ou rede foi executado.

## 5. Bugs do primeiro protótipo local

### BUG-001 — Ataques acumulados durante caminhada causavam rajada ao chegar

**Data/estado:** 2026-10-11; corrigido com regressão executada no Godot 4.7.2.

**Reprodução:** unidade fica fora de alcance por vários ticks, deixando seu `attack_cooldown` negativo; ao entrar em alcance, o código somava o intervalo ao saldo negativo e atacava a cada tick até consumir o atraso. Fixture em `RelicArena/tests/test_simulation.gd`, `_test_attack_cadence`: ataque de 1 por segundo, cooldown inicial -10, alvo adjacente e avanço de 0,15 s; deveria haver somente um ataque, mas o código anterior permitia vários.

**Investigação:** leitura do laço de atualização identificou decremento durante caminhada e reposição por soma depois do ataque. A fixture reproduziu o problema: execução anterior retornou 79 verificações aprovadas, 1 falha e saída 1. A revisão independente encontrou o mesmo caminho. Não era um buff aprovado nem aceleração dos 15 segundos.

**Causa:** tempo sem alvo em alcance virava crédito de ataques, violando o intervalo de ataque configurado e acelerando efeitos que dependem de acertar, como o crescimento pessoal do Zumbi.

**Mudança:** cooldown de ataque não acumula abaixo de zero durante a espera; após o golpe é atribuído o próximo intervalo. Comparação com epsilon trata a fronteira numérica do timer. Arquivo: `RelicArena/simulation/arena_simulation.gd`.

**Validação:** a regressão passou após a mudança (80 verificações, zero falhas); bateria ampliada para contratos ainda ausentes terminou com 90 verificações, zero falhas e saída 0, executada pelo agente responsável no Godot 4.7.2. A validação final integrada será registrada no cérebro. Não demonstra balanceamento ou justiça de iniciativa.

**Lição:** cooldown vencido permite estar pronto para o próximo ataque, não acumular ataques por tempo gasto caminhando. Testar transições fora/dentro do alcance além de uma unidade já atacando parada.

### BUG-002 — Cliente dependia de tipo global ainda não declarado

**Data/estado:** 2026-10-11; corrigido durante a primeira integração.

**Reprodução/evidência:** carregamento inicial do cliente retornou `Parse Error: Could not find type "ArenaSimulation" in the current scope`, em `res://client/main.gd:17`, conforme execução do agente responsável. O núcleo naquele momento ainda não declarava essa classe global. O comando de importação retornava saída 0 apesar do erro no log; por isso esse código sozinho não comprovava que a cena carregava.

**Investigação/causa:** a tipagem exigia uma classe global antes de existir no núcleo, embora já houvesse um `const Simulation = preload(...)` disponível no cliente.

**Mudança:** usar o tipo do preload (`Simulation`) na instância. A versão posterior do core também declara `class_name ArenaSimulation`, mas o cliente não depende do registro global para sua tipagem.

**Validação:** nova importação sem erro de script e cena exercitada no smoke headless, inclusive seleção, luta, resultado e próxima rodada. Validação final do root: 86 verificações de integração, zero falhas, saída 0. Renderização de preparação e combate também executada e capturada pelo viewport do jogo.

**Lição:** inspecionar log além do código de saída e iniciar a cena real; uma importação bem encerrada não prova ausência de erro GDScript.

### BUG-003 — Crítico corpo a corpo não recebia destaque visual

**Data/estado:** 2026-10-11; contrato de eventos corrigido e regressão aprovada.

**Reprodução/investigação:** revisão do cliente identificou que a linha de impacto consumia `attack`, evento de início sem informação `critical`. O resultado verdadeiro chegava em `hit`, que o filtro ignorava; o destaque amarelo previsto para críticos melee não era alimentado. Isso afetava a observação do Zumbi, não seu cálculo de dano.

**Mudança:** consumir `hit`/`execute` para linhas de impacto; bolas continuam representadas por seus projéteis, sem duplicar a linha com `attack`. Traduzidos os eventos reais utilizados pelo núcleo.

**Validação:** regressão adicionada ao smoke injeta `attack` seguido de `hit` crítico e exige exatamente uma linha com `critical=true`. Passou na execução final do root, incluída nas 86 verificações de integração. Não foi alegada uma execução anterior com essa fixture falhando; o defeito anterior foi identificado pela inspeção do contrato de eventos.

**Lição:** evento de intenção/início não é resultado do ataque. Feedback de acerto/crítico deve usar o evento emitido após a regra resolver o golpe.

## 6. Bugs da ampliação local V1 — 2026-10-11

### BUG-004 — Morte por sangramento interrompia os outros ticks

**Reprodução real:** captura do resultado pelo Godot com `--script res://tools/capture_preview.gd -- --result`, sem comprar/expandir, exibiu `Invalid assignment of property or key 'bleeds' with value of type 'Array'` em `arena_simulation.gd:466`. O motor ainda salvou a imagem e retornou 0. A bateria anterior passava porque não exercitava esse ramo.

**Investigação/causa:** `bleeds` é `Array[Dictionary]`, mas o ramo de morte do ternário `remaining if target.alive else []` produzia um array genérico. Isso abortava `_update_bleeds` antes dos próximos alvos. O gatilho é morte por sangramento, independente de renderizador.

**Mudança:** manter a atribuição do array tipado quando vivo; limpar com `bleeds.clear()` quando morto. Fixture `_test_bleed_kill_continues_tick` coloca dois alvos sangrando no mesmo passo: primeiro com 3 HP, segundo com 1000; cada tick causa 4. Antes, reproduziu o mesmo erro e duas falhas reais: segundo permanecia com 1000 em vez de 996 e dano total era 3 em vez de 7. Execução anterior: 153 aprovadas/2 falhas/saída 1.

**Validação:** após a correção, 155 verificações do core, zero falhas, saída 0; Session 78 e quatro partidas automatizadas 666 também passaram. O root repetiu core e captura de resultado, sem erro de script. Primeiro alvo morre uma vez, sangramentos são limpos e segundo recebe seu tick.

**Lição:** preservar tipos em todos os ramos e testar efeitos que matam durante a iteração. Importação, PNG salvo e saída 0 não bastam: ler o log e conferir a continuação do processamento.

### BUG-005 — Resposta de comando compartilhava o item concedido

**Reprodução/investigação:** revisão da implementação inicial da Session identificou que `response.data` apontava para o mesmo dicionário do item na bolsa. A fixture em `tests/test_match_session.gd` altera `response.data.key` e exige que a bolsa permaneça intacta. Não há execução anterior falhando preservada; o achado veio da leitura do fluxo de referências, não de incidente com usuário.

**Causa/mudança:** dado autoritativo devolvido por referência. `apply_command` passa a devolver uma cópia profunda da resposta, além da cópia guardada para deduplicação.

**Validação:** regressão incluída nas 78 verificações finais da Session, zero falhas/saída 0, repetidas pelo root. **Lição:** retornar estado ao cliente não deve permitir que ele altere a autoridade indiretamente.

### BUG-006 — IDs próprios denunciavam compras privadas do adversário

**Reprodução/investigação:** o contador global de itens fazia o próximo ID do time 0 mudar se o time 1 comprasse antes. A fixture cria duas sessões da mesma semente, faz compra adicional somente no adversário de uma delas e compara o próximo ID concedido ao jogador. Identificado por revisão; não alegamos falha anterior executada nem exploração em rede.

**Causa/mudança:** identidade de item dependia de operações privadas do outro time. Substituído por contadores separados por time em `match_session.gd`.

**Validação:** a comparação passa nas 78 verificações finais da Session, zero falhas/saída 0. **Lição:** privacidade inclui metadados e identificadores, além do conteúdo explícito do snapshot. Isso não representa teste de servidor, que ainda não existe.

### BUG-007 — Fila de eventos expunha economia do bot

**Reprodução/investigação:** revisão identificou que o dreno inicial devolvia também eventos de compra/equipamento/benefício do bot. A fixture provoca compras privadas e exige que `drain_events(0)` não contenha eventos econômicos com `team=1`.

**Causa/mudança:** snapshots eram filtrados, mas o canal de eventos ainda não. `drain_events(team)` agora filtra eventos privados pela equipe. A fila continua um mecanismo de consumo local, não um protocolo com entrega independente a dois clientes.

**Validação:** regressão incluída nas 78 verificações finais, zero falhas/saída 0. Não há contagem anterior falhando preservada. **Lição:** conferir todos os canais de informação; futuramente a rede exigirá filas/cursores por destinatário.

### BUG-008 — Playback de áudio deixava recursos no encerramento headless

**Reprodução/investigação:** agente do cliente observou avisos de 7–8 recursos de áudio não liberados ao tocar os efeitos durante o smoke headless. Execução com `--verbose` identificou `AudioStreamWAV` e playback entre as classes envolvidas. Não foi confirmado problema audível ou vazamento em sessão normal.

**Mudança:** `prototype_audio.gd` não inicia playback quando `DisplayServer` é headless; `_exit_tree` para os players no encerramento. Os streams PCM continuam sendo construídos e conferidos pelo teste.

**Validação:** smoke posterior sem os avisos; execução final do root 152 aprovadas/0 falhas/saída 0. Capturas com renderizador silenciam o áudio deliberadamente. **Lição:** testar dados sonoros em headless não exige tocar áudio sem dispositivo; não confundir esse teste com audição real.

### BUG-009 — Camadas e dimensões escondiam corações e sobrepunham textos

**Reprodução real:** root renderizou e abriu as capturas V1. Corações desenhados no Node2D eram cobertos pelo painel opaco do CanvasLayer; título de resultado aparecia duas vezes; cabeçalhos de estatísticas não alinhavam com valores; segunda receita da bolsa ultrapassava sua borda.

**Investigação/causa:** desenho da vida estava na camada inferior; havia um título na UI raiz e outro no overlay; cabeçalho dependia de espaços numa única string; limites da receita excediam 222 px. A regressão geométrica encontrou ainda que o helper atribuía tamanho antes de fonte/texto, conservando altura mínima de 23 px mesmo com fonte 9 (204 + 23 = 227).

**Mudança:** dez `TextureRect` de coração como filhos da UI (quatro iniciais por lado e quinto para vida extra); somente `ResultHeading` visível; rótulos separados com as mesmas coordenadas das colunas; receitas compactadas e helper aplica tamanho depois de fonte/texto.

**Validação:** smoke final 152 aprovadas/zero falhas/saída 0 inclui camada/visibilidade dos corações, quinto coração, título único e controles da bolsa dentro do painel. Root repetiu e inspecionou as seis capturas OpenGL: menu, benefício, preparação, bolsa, combate e resultado, sem sobreposição/ocultação observada nesses casos. Toque em aparelho não foi testado.

**Lição:** regras e sinais passando não comprovam composição visual. Inspecionar o viewport renderizado e testar limites mínimos efetivos de controles, não somente tamanhos pedidos.

## 6b. Bugs da V1.1 — 2026-10-11

### BUG-010 — Tela de resultado mostrava nível 1 para heróis de nível 2 ou 3

**Tipo e estado:** BUG / resolvido com evidência. **Impacto:** visual, sem alterar regra ou resultado; confundia a leitura das cópias.

**Reprodução:** revisão pedida pelo usuário. A tela de resultado chama `_stars(..., unit.get("level", 1))` sobre `round_result.units_summary`. Fixture: Neymar no nível 2 via `set_unit_level`, combate de 30 s; o resumo não tinha a chave `level`, então o padrão 1 era usado.

**Causa:** `unit_summaries()` (em `arena_simulation.gd`) foi criado antes do nível na partida e não recebeu o campo quando os níveis foram introduzidos. O resto da interface lia `level` de `as_dictionary()`, que já o tinha.

**Mudança:** `unit_summaries()` inclui `"level": unit.level`. **Validação:** nova verificação em `_test_match_levels` ("round summary reports match level"); simulação 190 aprovadas, zero falhas. **Lição:** ao acrescentar um campo de estado, procurar todos os formatos de saída (`as_dictionary`, resumos, formação pública), não só o principal.

### INC-006 — Duas sessões de IA editando o cliente ao mesmo tempo

**Data:** 2026-10-12, ~01:55. **Categoria:** operação; não é bug do jogo. **Estado:** contornado (a sessão Claude parou de editar o cliente).

**Observado:** durante a implementação do lote 03, `client/main.gd`, `client/board_projection.gd` e `client/character_visuals.gd` foram regravados às 01:54:49 por outro processo. Processos `codex.exe` estavam ativos. Um patch da sessão Claude falhou na verificação de texto porque o arquivo tinha mudado. Logo depois, `main.gd` passou a chamar `_spawn_kit_feedback()` e `_load_arena_props()` ainda inexistentes: parse error temporário, coerente com uma edição em andamento.

**Ação:** nenhuma escrita por cima. Conferido que as mudanças de regras do Claude (simulação, Session, testes, dados, provisórios) continuavam presentes e passando. Efeitos visuais dos kits novos adiados até haver um único editor do cliente.

**Lição:** antes de editar, conferir horários de modificação; com duas IAs no mesmo projeto, dividir arquivos (por exemplo regras × cliente) ou trabalhar uma de cada vez.

**Atualização de coordenação, 2026-10-12:** usuário respondeu à pergunta pendente e confirmou outra IA trabalhando no projeto. Identidade e escopo atual não foram informados; não atribuir essa confirmação automaticamente à sessão Claude do incidente anterior. Divisão de arquivos solicitada. Nenhum novo conflito ou defeito foi investigado/reproduzido nesta atualização; apenas memória operacional/documentação alteradas.

### BUG-011 — Envio de herói ativo para o banco não validava limite da reserva

**Tipo e estado:** BUG / resolvido com evidência. **Impacto:** gameplay e regras de inventário. **Ambiente:** Godot 4.7.2 local, `simulation/match_session.gd`.

**Reprodução:** no teste automatizado `test_match_session.gd:180-183` (`_test_lote_03_session`), com o campo cheio (4 heróis) e a reserva cheia (5 heróis do lote 03 recrutados), executar o comando `bench` para uma unidade ativa em campo. O comando era aceito indevidamente com `ok: true`, abrindo uma vaga no campo e permitindo recrutar um 6º herói acima do limite combinado.

**Investigação/causa:** a operação `"bench"` em `_position()` de `match_session.gd` apenas verificava se a unidade estava ativa (`not unit.active`), omitindo a verificação de capacidade da reserva (`_bench_count(team) >= BENCH_CAPACITY`).

**Mudança:** adicionada checagem explícita `if _bench_count(team) >= BENCH_CAPACITY: return _fail("bench_full")` antes de desativar o herói ativo.

**Validação:** `tests/test_match_session.gd` passou 100% (135 aprovados, 0 falhas). Rejeição preserva formação e posse atomicamente.

### BUG-012 — Falta de _load_arena_props impedia compilação do GDScript do visor

**Tipo e estado:** BUG / resolvido com evidência. **Impacto:** impedia inicialização da cena `main.tscn` no cliente e quebrava `smoke.gd`.

**Reprodução:** executar `client/smoke.gd`. O Godot emitia erro de parse em `client/main.gd:123` acusando que a função `_load_arena_props()` não existia em `self`, e quebrava o instanciamento da cena principal.

**Investigação/causa:** durante a estruturação de props e iluminação viva do coliseu, a chamada `_load_arena_props()` foi adicionada em `_ready()`, mas a definição da função não havia sido inserida no arquivo.

**Mudança:** implementada `_load_arena_props()` com 4 tochas em pilastras da arena, halos de iluminação quente, braseiro e chamas oscilantes em `_draw_arena()`; implementados `_spawn_kit_feedback()` e `_draw_kit_feedback()` com suporte completo às habilidades de todos os heróis (foguetes, explosões, fumaça do Snoop, laço da Rapunzel, volta por cima do Lula, etc.) e projéteis diferenciados em `_draw_units_layer()`.

**Validação:** `client/smoke.gd` passou 100% (208 aprovados, 0 falhas); capturas de tela OpenGL (`v1_1_preparacao.png`, `v1_1_combate.png`, `v1_1_itens.png`, `v1_1_niveis.png`) geradas perfeitamente.

### BUG-013 — Sangramento reaparecia depois de provocar a volta por cima

**Data, tipo e estado:** 2026-10-12; BUG / resolvido com evidência. **Impacto:** o Lula revivido continuava recebendo um sangramento que a rotina de volta por cima havia acabado de limpar. Não é a atribuição de array genérico do BUG-004.

**Reprodução:** auditoria dos kits do lote 03, com fixture temporária fora do projeto, deixou Lula com 1 HP e um sangramento de 4 por segundo. Depois do golpe letal, ficou vivo com 400 HP e um efeito; um segundo depois, estava com 396 HP. A regressão persistente `_test_revive_clears_bleeds` usa 5 HP e dois efeitos de 4: o primeiro era retido localmente antes de o segundo provocar o retorno. Antes da correção, ambos reapareciam e a vida caía de 400 para 392 no segundo seguinte.

**Investigação/causa:** `_deal_damage` limpava `target.bleeds` ao reviver, mas `_update_bleeds` ainda guardava os dicionários em processamento. Como o alvo voltava vivo, a rotina adicionava o efeito atual ao array local `remaining` e o atribuía ao alvo, recolocando também efeitos já retidos nesse mesmo passo.

**Mudança:** detectar a transição de `revived = false` para `true` durante o tick de sangramento, limpar o array local e encerrar somente os efeitos daquele alvo. A atualização continua para as outras unidades; arrays permanecem tipados.

**Validação:** a bateria com as regressões de BUG-013 e BUG-014, antes das correções, teve 292 verificações aprovadas e 5 falhas, saída 1. Depois: core 297 aprovadas, zero falhas; quatro partidas automatizadas, 816 aprovadas, zero falhas; saídas 0 e logs sem erro. A fixture verifica limpeza completa, manutenção de 400 HP, continuação do tick em outro aliado e limite de uma volta por cima por rodada. Não houve teste humano ou de balanceamento.

**Lição:** limpar a coleção autoritativa durante uma iteração não invalida automaticamente os efeitos já guardados em uma coleção local; testar a transição de estado e a continuação do processamento.

### BUG-014 — Ken podia receber o ID de um herói do elenco customizado

**Data, tipo e estado:** 2026-10-12; BUG / resolvido com evidência. **Impacto:** IDs duplicados e vínculo de proteção apontando para outro herói. O elenco padrão da Session usa IDs que não provocavam a colisão; o defeito foi reproduzido pela API válida de elenco customizado.

**Reprodução:** `preparation_setup` aceitou Barbie com ID 6, Neymar com ID 86 e um adversário. Ao iniciar o combate, Ken também recebeu 86, deixando duas unidades com esse ID; `get_unit(86)` retornava Neymar e o `guardian_id` da Barbie apontava para ele. A regressão `_test_summon_unique_ids` também ocupa o ID 87, cobrindo a necessidade de pular mais de um identificador.

**Investigação/causa:** a invocação usava sempre `summoner.id + 80`, embora a validação de elenco permita outros IDs positivos únicos. Não havia verificação de colisão com as unidades já presentes. Procura de alvo, dano e proteção usam `get_unit`, portanto dependem da unicidade.

**Mudança:** manter o ID preferido e avançar deterministicamente até encontrar um identificador livre antes de criar Ken e guardar o vínculo. Não altera o contrato de snapshot nem os IDs padrão que já estavam livres.

**Validação:** na execução anterior conjunta, três das cinco falhas verificavam vínculo errado, duplicação e repetição do erro na rodada seguinte. Após as correções: core 297/0 e quatro partidas automatizadas 816/0, saídas 0 e logs limpos. A fixture confirma unicidade, preservação de Neymar/Obama nos IDs originais, vínculo correto, exclusão de Ken do desempate por sobreviventes e descarte/recriação da invocação na próxima rodada.

**Lição:** uma regra de geração de IDs precisa respeitar todos os IDs aceitos pela API de entrada, incluindo invocações transitórias, sem depender apenas do padrão da interface atual.

### BUG-015 — Linha do Ken sobrepunha o botão no resultado

**Data, tipo e estado:** 2026-10-12; BUG / resolvido com evidência. **Impacto:** a sexta linha do resumo ficava atrás de PRÓXIMA RODADA, dificultando ler as estatísticas da invocação. Regras e resultado do combate não foram alterados.

**Reprodução real:** captura OpenGL de `tools/capture_preview.gd -- --kits --result`, com cinco heróis do jogador e Ken invocado pela Barbie. A imagem anterior foi preservada em [v1_2_lote03_resultado_antes_Ken.png](../RelicArena/captures/v1_2_lote03_resultado_antes_Ken.png). O smoke anterior passava 282 verificações, mas ainda não conferia a geometria desse resultado de seis unidades.

**Investigação/causa:** `_refresh_overlay` desenhava linhas diretamente no painel usando `y = 102 + linha * 54`. Ken, na sexta linha, começava em 372 e o retrato terminava em 420; o botão ocupava 374–422. A tabela foi dimensionada para cinco unidades antes de existir a invocação. Consultado o BUG-009 por sintoma semelhante de sobreposição, mas a causa desta ocorrência é a quantidade adicional de linhas.

**Mudança:** área de tabela delimitada em um `ScrollContainer` de 264 px; seis linhas usam passo de 44 px e retratos compactos. As seis ficam visíveis até y = 366, com o botão independente a partir de 374. A rolagem permanece disponível para tabelas maiores. Cabeçalhos, colunas, níveis, estatísticas e o título único foram preservados.

**Validação:** Godot 4.7.2; `client/smoke.gd` final com **289 aprovadas, zero falhas**, tanto headless quanto OpenGL, saídas 0 e logs sem erro. A regressão monta a equipe por comandos da Session, completa o combate com Ken, exige seis linhas dentro da área, verifica limites de todos os controles da tabela e separação do botão. [Captura posterior](../RelicArena/captures/v1_2_lote03_resultado.png) renderizada e inspecionada: Ken, seus números e PRÓXIMA RODADA legíveis. Também inspecionadas as capturas de menu, benefício, preparação, itens e combate. Não houve teste de toque em aparelho.

**Lição:** invocações também ampliam relatórios; conferir quantidade máxima de linhas e a imagem renderizada, além de testar o núcleo e o fluxo de botões.

### BUG-016 — Ordem dos argumentos impedia compilar o desenho dos VFX novos

**Data, tipo e estado:** 2026-10-12; BUG / resolvido durante a implementação da V1.3. **Impacto:** o cliente novo não compilava naquele estado intermediário. Não foi reproduzido na V1.2 nem na entrega final da V1.3.

**Reprodução/evidência:** a primeira importação da integração registrou em `RelicArena/captures/v1_3_import.log` que `draw_texture_rect_region()` esperava `Texture2D` no primeiro argumento, mas recebeu `Rect2`; o script `client/main.gd` não carregou. O log intermediário foi preservado.

**Investigação/causa:** `_draw_vfx_frame()` passou o retângulo de destino antes da textura. Consultado BUG-012 por também impedir compilar o cliente; a causa aqui é a ordem dos argumentos, não função ausente.

**Mudança:** usar `draw_texture_rect_region(texture, destination_rect, source_rect)`, mantendo os recortes e offsets do pacote. Nenhum PNG, atributo ou regra de combate foi alterado.

**Validação:** importação final em `v1_3_import_final.log` sem erro; biblioteca 61/0 e cliente 321/0 tanto headless quanto OpenGL, saídas 0. As duas capturas reais da V1.3 foram renderizadas e inspecionadas, cobrindo os quatro efeitos. Logs finais limpos; registro em `RelicArena/VALIDACAO_V1_3.json`.

**Lição:** conferir o diagnóstico de tipos da importação antes de avaliar a aparência; log inicial preservado não substitui a verificação da versão final.

### BUG-017 — Fio do laço se separava do corpo durante o puxão

**Data, tipo e estado:** 2026-10-12; BUG / resolvido com evidência. Apresentação da Rapunzel no cliente local Godot 4.7.2, viewport 1280 × 720. Não altera dano, destino lógico ou atordoamento.

**Reprodução:** puxar visualmente de [7,0] para [2,4] e avançar seis passos de 0,05 s. `tools/repro_lasso_endpoint.gd` executou no Godot a fórmula de desenho anterior, preservada literalmente, e comparou suas extremidades com o chão interpolado do corpo/nó. Às 0,20 s, a ponta ficou a **65,6483 px** do corpo; a origem oscilou até **4,8760 px** mesmo com Rapunzel parada. A fixture verificou que não alterou a simulação. Evidência em `captures/v1_4_bug017_repro_antes.log/.json`; captura real anterior preservada em `v1_4_support_combate_antes_alinhar_fio.png/.json`. As medidas são da fixture, não segmentação da captura.

**Investigação/causa:** revisão independente comparou `main.gd` ao snapshot V1.3 e apontou curvas diferentes: o corpo usa easing cúbico, a ponta do fio usava interpolação linear. A ondulação também era aplicada aos vértices inicial/final, deslocando as duas extremidades. A fórmula vinha da V1.3; o nó separado tornou a diferença mais evidente. Busca no histórico por corda/laço/interpolação/âncora não encontrou ocorrência anterior equivalente; BUG-012 registra a introdução dos efeitos, sem esse diagnóstico.

**Mudança:** `_lasso_points()` é usado pelo desenho real. Fonte/alvo usam o mesmo chão visual do corpo, com offset (0,-21); vértices inicial/final ficam fixos e a ondulação atua no interior. Fallback permanece quando as unidades/assets não existem. Nenhum original PixelLab, dado ou regra de combate foi alterado.

**Validação:** runner posterior mediu **0 px** de erro geométrico nas duas extremidades em todas as seis amostras (`v1_4_bug017_repro_depois.log/.json`), saída 0 e núcleo idêntico. Regressões incluídas no cliente, com fonte móvel, fallback e todos os fios de uma luta real: 370/0 headless e 370/0 OpenGL, saídas 0. Importação/logs finais limpos. Captura final em `v1_4_support_combate.png/.json`: luta real aos 2,6 s, nó durante puxão, erros de ponta/origem 0. Os PNGs de combate/preparação foram inspecionados; preparação sem efeitos ou formação inimiga atual. Dados/simulação: 18 arquivos idênticos à V1.3.

**Lição:** elementos ligados a um personagem devem usar sua posição visual interpolada; curvas de movimento distintas e ondulação aplicada aos extremos podem desconectar a composição mesmo com a regra lógica correta.

### BUG-018 — Snapshot compartilhava arrays das regras com a autoridade local

**Data/estado:** 2026-10-12, resolvido na revisão da pasta após V1.6. Achado por leitura e reproduzido em sessão descartável; não foi exploração em rede.

**Reprodução/investigação:** após `snapshot_for_team(0)`, alterar `test_config.power_multiplier[1]` para 9 e `copies_for_level[2]` para 99 também alterava `sim.level_rules`: `level_multiplier(2)` retornou 9 e `_max_copies()` 99. Consultado BUG-005 pelo mesmo princípio de referência compartilhada; a resposta de comandos já tinha cópia, mas esses dois arrays do snapshot não. [Fixture/logs antes e depois](revisoes/2026-10-12_1409/REVISAO.md), cópias anteriores preservadas em `antes/`.

**Causa/mudança:** arrays retornados diretamente pelo `Dictionary.get()`. `match_session.gd` agora duplica profundamente os dois arrays. Nenhum multiplicador aprovado ou custo alterado.

**Validação:** runner conjunto antes 2/2, saída 1; depois 4/0, saída 0 e stderr vazio: multiplicador interno fica 1,5 e limite fica 3 apesar de alterar o snapshot. Regressão permanente `tests/test_review_contracts.gd`; Session 155/0, simulação 297/0, quatro partidas 668/0 e cliente 370/0 headless/OpenGL. Resultados completos no relatório.

**Lição:** conferir todas as estruturas mutáveis retornadas, incluindo metadados/configuração; a cópia de outra parte do snapshot não protege referências vizinhas.

### BUG-019 — Gaveta mostrava contagem de sinergia reduzida após uma morte

**Data/estado:** 2026-10-12, apresentação corrigida na revisão da pasta após V1.6. O bônus de combate já permanecia correto.

**Reprodução:** recrutar Neymar e Elon por comandos, iniciar combate, marcar Elon morto somente na fixture descartável e reabrir a gaveta. O preview dos vivos cai para 1; formação congelada permanece 2. Antes: gaveta “Atiradores · 1 membros”; depois: “Atiradores · 2 membros”. Logs no [relatório da revisão](revisoes/2026-10-12_1409/REVISAO.md).

**Investigação/causa:** `_refresh_drawer()` usava `own.synergies`, recalculado pelos vivos, enquanto a barra já usava `_displayed_synergies()` com `combat.synergy_snapshot`. Busca por sinergia/snapshot no histórico não encontrou correção anterior dessa gaveta; teste do núcleo já cobria persistência do bônus, smoke antigo só abria a gaveta na preparação.

**Mudança/validação:** gaveta e sua assinatura de atualização passam a usar o mesmo helper da barra. Regressões 4/0 headless e OpenGL, cliente 370/0 nos dois renderizadores, todos saída 0 e stderr vazio. Cinco capturas gerais inspecionadas; a contagem após morte é verificada pelo controle Label real no runner, não inferida de PNG. Nenhuma mudança no cálculo da sinergia.

**Lição:** apresentações diferentes da mesma regra devem consultar a mesma fonte correspondente à fase da partida.

### BUG-020 — Sobreposição de layout de capacidade sobre botão FUNDIR e ilegibilidade de botões ornamentados

**Data/estado:** 2026-10-12, resolvido com evidência visual e teste real.

**Sintoma/Reprodução:**
1. O mostrador de capacidade (`CAMPO 4/4`) colidia e sobrepunha diretamente o canto inferior direito do painel de itens (`ITENS 0/8`), cobrindo o botão `FUNDIR`.
2. Os botões ornamentados (`ESPAÇO · 8`, `RENOVAR · 2`, `LUTAR`, `EQUIPAR`, `FUNDIR`) apresentavam texto e ícones quase invisíveis/apagados.
3. Efeitos de mouse hover pouco perceptíveis nas cartas da loja e botões interativos.

**Investigação/Causa:**
1. `bag_panel` estava em `Rect2(12, 380, 214, 196)` (terminava em Y=576), com botão FUNDIR em Y=524..564, enquanto `capacity_pill` estava em `Rect2(190, 558, 180, 34)` (X=190..370, Y=558..592), havendo colisão direta em X [190..216] e Y [558..564].
2. No Godot 4, nós filhos de um CanvasItem desenham após o pai por padrão; o nó `frame` adicionado ao `Button` desenhava o retângulo de fundo opaco por cima do texto e ícone do próprio botão. Adicionalmente, faltavam overrides explícitos de contorno escuro e cores de texto claras.
3. Não havia cursor de mãozinha (`CURSOR_POINTING_HAND`) configurado nos botões e cartas, e as auras luminosas de hover necessitavam de multicamadas na cor da raridade.

**Mudança/Validação:**
1. `bag_panel` reposicionado para `Rect2(12, 340, 214, 196)`, deixando 22px livres acima de `capacity_pill`.
2. `capacity_pill` ajustado para `Rect2(148, 558, 122, 32)`, alinhado exatamente sobre a coluna de botões de controle da loja.
3. `frame.show_behind_parent = true` definido nos botões e cartas para desenhar a moldura atrás do texto/ícone.
4. Cores e contornos nítidos configurados nos botões (`outline_size: 3`) e nos labels de cartas (`outline_size: 2`).
5. Cursor `CURSOR_POINTING_HAND` configurado em todos os botões e cartas interativas.
6. Auras difusas de 3 camadas na cor da raridade, feixe de luz superior e cantoneiras estelares cintilantes adicionadas em `draw_ornate_card_frame` e `draw_ornate_button_frame`.
### BUG-021 — Tooltip duplo em sinergias (nativo de texto cru cobrindo card rico)

**Data/estado:** 2026-10-12, resolvido com eliminação do tooltip nativo redundante e refinamento visual por ícones e mini-retratos.

**Sintoma/Reprodução:**
Ao passar o mouse sobre um grupo de sinergia na barra lateral, dois elementos de hover eram disparados simultaneamente: o tooltip de texto padrão do Godot na frente (com caracteres de console como `===`, `*`, `▶`, `•`, `✓`) e o card gráfico rico `synergy_hover_card` atrás, gerando sobreposição confusa.

**Investigação/Causa:**
Em `_refresh_synergies()`, a propriedade `row.tooltip_text = _rich_synergy_tooltip(group, own)` ativava o tooltip nativo de texto puro do motor, enquanto `row.mouse_entered` chamava simultaneamente `_show_synergy_hover()`.

**Mudança/Validação:**
1. Atribuição de `row.tooltip_text` removida, eliminando completamente a caixa de texto nativa do motor.
2. `synergy_hover_card` refinado com:
   - Mini-retratos pixel art reais dos heróis em campo e na reserva (`art.portrait_for`).
   - Estrelas de nível reais renderizadas por herói com `_stars()`.
   - Patamares de bônus em painéis estilizados com indicador visual `ATIVO`/`INATIVO`.
   - Mini-compêndio horizontal de todos os heróis da classe com destaque de posse.
   - Remoção de todos os caracteres de terminal/código (`===`, `*`, `✓`).
3. Captura do viewport em `v1_4_hover_sinergia.png` gerada e inspecionada com OpenGL; 440 testes do smoke e demais suítes aprovados com 0 falhas.

**Lição:** ao utilizar painéis ricos customizados no `mouse_entered`, não atribuir `tooltip_text` nativo no mesmo controle para evitar disparos visuais duplicados do engine.

## 7. Verificações futuras importantes

Esta lista orienta próximas etapas. Formação, relógio, resultado, economia local, itens e privacidade da Session já têm fixtures; rede, coleção, sinergias completas e dispositivo continuam pendentes. Não são bugs encontrados nem uma lista de testes de rede aprovados.

| Área | Regra/invariante a verificar |
| --- | --- |
| Economia | Compra só ocorre com saldo e espaço válidos; falha não remove moedas ou concede itens parcialmente. |
| Comandos de rede | Repetir o mesmo identificador de compra não duplica gasto ou recompensa. |
| Fases | Comando de posicionamento/compras atrasado não altera uma rodada que já entrou em combate. |
| Formação | Respeita área permitida, capacidade e personagens disponíveis do deck. |
| Sinergias | Maior patamar substitui menor; morte não remove o bônus aprovado da rodada. |
| Itens | Fusões e desmontagens respeitam receitas e não criam componentes indevidos. |
| Trocas | Comportamento dos itens de quem sai de campo segue a decisão final, sem duplicação. |
| Sorteios | Ofertas respeitam deck e regras de repetição/recrutamento que forem escolhidas. |
| Relógio | Aceleração aos 15 segundos e encerramento aos 30 seguem o relógio definido, sem depender dos quadros do cliente. |
| Resultado | Sobreviventes, dano efetivo, empate e morte simultânea seguem regras explícitas e iguais no servidor e na interface. |
| Benefícios | Vida extra e recompensas são aplicadas uma vez; duração e repetição seguem seus limites. |
| Informação privada | Adversário não recebe a formação atual escondida durante a preparação. |
| Reconexão | Estado reenviado é consistente; comandos pendentes não duplicam compras ou recompensas. |
| Coleção | Fichas, consumo, nível máximo 10 e arredondamentos respeitam a fórmula finalmente aprovada. |
| Apresentação | Posição visual e ataques correspondem ao estado do servidor em PC e celular. |

## 8. Índice e manutenção

| ID | Categoria | Conclusão atual |
| --- | --- | --- |
| INC-001 | PixelLab/navegador | Personagem localizado posteriormente; causa inicial desconhecida. |
| INC-002 | Ambiente Godot | Caminho absoluto e versão verificados; PATH não alterado. |
| INC-003 | Configuração MCP PixelLab | Resolvido: campo corrigido, leitura autenticada validada e ferramentas nativas do chat disponíveis em 2026-10-11. |
| INC-004 | Acesso ao navegador | Página local recusada pela política; servidor encerrado e prévia PNG criada diretamente, sem contornar o bloqueio. |
| INC-005 | Produção de personagens PixelLab | Novas tentativas concluíram Caramelo/Obama/Neymar e Zumbi refinado; falhas anteriores preservadas. Prévias locais, demais exportações/acabamento pendentes; nenhum limite contornado. |
| DOC-001 | Documentação | Precedência dos requisitos atuais definida. |
| DOC-002 | Entendimento de regra | Progressão corrigida para aproximadamente 5–6%. |
| ART-001 | Composição de cenário | Terceira geração não duplicou coliseus, mas foi rejeitada pelo usuário. Revisão em ART-002. |
| ART-002 | Referência e produção de cenário | Entregues fundo derivado da referência e prévia 8 × 8 por edição gratuita; Pro recusado por limite, aprovação final pendente. |
| ART-003 | Continuidade de arma entre direções | Oeste corrigido e reinspecionado após salvar; pixels originais preservados e undo registrado. Animação/acabamento geral pendentes. |
| BUG-001 | Cadência de combate | Cooldown negativo acumulava ataques durante caminhada; regressão reproduzida, corrigida e executada no Godot. |
| BUG-002 | Carregamento do cliente | Tipo global ausente no primeiro carregamento; uso do preload corrigido, importação/cena/smoke posteriores limpos. |
| BUG-003 | Feedback de crítico | Impacto visual passou a consumir `hit` com resultado crítico; regressão de integração aprovada. |
| BUG-004 | Sangramento | Morte atribuía array genérico e interrompia ticks seguintes; reproduzido, corrigido e validado. |
| BUG-005 | Autoridade local | Resposta de comando passou a ser cópia profunda do dado concedido. |
| BUG-006 | Informação privada | Contadores de identidade de itens separados por time. |
| BUG-007 | Informação privada | Dreno local filtra eventos econômicos pelo destinatário; entrega em rede ainda pendente. |
| BUG-008 | Encerramento headless | Playback omitido sem dispositivo e players parados ao sair; avisos não reapareceram. |
| BUG-009 | Interface renderizada | Corações, título, colunas e limites da bolsa corrigidos; capturas reinspecionadas. |
| INC-006 | Operação | Codex e Claude editaram o cliente simultaneamente; Claude parou de escrever, regras conferidas e testadas. |
| BUG-010 | Resultado / níveis | Resumo da rodada não informava o nível; estrelas do resultado ficavam em 1. Campo adicionado e coberto por teste. |
| BUG-011 | Regras / banco | Comando bench não verificava BENCH_CAPACITY; trava adicionada e validada no Session. |
| BUG-012 | Compilação / visor | Função _load_arena_props ausente no GDScript; tochas e efeitos visuais implementados e validados no smoke. |
| BUG-013 | Sangramento / retorno | Array local recolocava efeitos limpos pela volta por cima; transição de revive detectada e coberta por regressão. |
| BUG-014 | Invocação / identidade | Ken podia duplicar ID de elenco customizado; alocação pula IDs ocupados e preserva o vínculo correto. |
| BUG-015 | Resultado / invocação | Sexta linha sobrepunha PRÓXIMA RODADA; tabela delimitada e compactada, com regressão e capturas antes/depois. |
| BUG-016 | Compilação / VFX | Ordem dos argumentos no desenho do clip corrigida durante implementação; importação e renderização finais validadas. |
| BUG-017 | Apresentação / laço | Extremidades seguem os corpos; reprodução antes/depois, regressões e captura real confirmam alinhamento. |
| BUG-018 | Autoridade local / snapshot | Arrays de configuração retornados como cópias profundas; mutação do snapshot não muda regras. |
| BUG-019 | Apresentação / sinergias | Gaveta consulta a formação congelada, igual à barra; morte não reduz o patamar exibido. |
| BUG-020 | Layout / botões / hover | Sobreposição de CAMPO com FUNDIR resolvida, legibilidade de texto recuperada com show_behind_parent e auras de hover implementadas. |
| BUG-021 | Apresentação / sinergia | Tooltip nativo redundante removido; card gráfico refinado com retratos pixel art e sem caracteres de console. |
| INC-007 | Configuração MCP & Moedas HD | Sintaxe JSON em mcp_config.json corrigida, servidor AutoSprite MCP configurado, cliente REST CLI criado e moedas HD integradas com animação no HUD. |

O primeiro bug de combate foi registrado como BUG-001. Se uma ocorrência acima voltar, acrescentar evidências ao registro existente ou vincular o novo caso; não presumir a mesma causa apenas por ter sintoma parecido.
