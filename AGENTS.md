# Instruções do projeto

## Memória de trabalho

- Antes de planejar ou modificar o projeto, leia `Guia_Godot4/CEREBRO.md`.
- Ao investigar um defeito, consulte também `Guia_Godot4/HISTORICO_DE_BUGS.md` e procure ocorrências semelhantes.
- Uma instrução direta e mais recente do usuário prevalece sobre estes documentos. Atualize a documentação quando houver mudança de decisão.
- Separe decisão confirmada, hipótese, proposta, dúvida e evidência de implementação. Não converta uma sugestão do assistente em requisito aprovado.
- Depois de uma correção real, registre reprodução, investigação, causa sustentada por evidências, mudança e validação no histórico. Não invente bugs, testes executados ou causas.
- Estes arquivos são referências persistentes; não representam treinamento automático do modelo nem garantem balanceamento.

## Escopo e arquivos históricos

- Os guias antigos em `Guia_Godot4/` e `Xadrez_Auto_Battler_Guia_Godot4/` descrevem uma versão anterior. Consulte a seção de precedência do cérebro antes de reutilizar regras ou código.
- Preserve esses arquivos e seus manifestos como arquivo histórico, salvo pedido explícito para atualizá-los.
- O estágio atual é o primeiro protótipo local contra bot, com arte provisória, após a mudança de direção do usuário em 2026-10-11. Avance em entregas pequenas jogáveis. Isso não autoriza gerar assets pagos, consumir créditos do PixelLab ou implementar o jogo inteiro.
- Em novos pedidos, avance no escopo autorizado pelo usuário sem pedir confirmação repetida para leituras, documentação ou mudanças reversíveis necessárias.

## Direção técnica

- Godot 4, PC e celular com tela deitada (paisagem); multiplayer com servidor dedicado como direção aprovada. Primeiro validar combate contra bot local; depois servidor separado dos clientes. Movimento por hexágonos substituiu o movimento livre.
- A versão local verificada em 2026-10-10 foi `4.7.2.stable.official.ed1daf0bf`. Reconfirme se o executável mudar.
- Prefira GDScript tipado, dados separados da apresentação e regras de combate executáveis sem interface. A arquitetura detalhada ainda é uma proposta a validar.
- O servidor deve validar comandos e controlar economia, sorteios, combate e resultado. Informações privadas da preparação não devem ser enviadas ao adversário antes da revelação.
- Não transporte automaticamente regras antigas de tabuleiro quadrado, campanha offline, estrelas por duplicatas, juros, níveis ou lojas para o novo projeto. Exceção atual, escolhida pelo usuário em 2026-10-11: cópias do mesmo herói sobem o nível na partida (2 cópias = nível 2; 3 cópias no total = nível 3); não reutilizar a regra antiga de três cópias por estrela.
- O usuário quer preservar coleção e níveis de cartas. A hipótese anterior de 5–6% por nível até 10 precisa ser conciliada com PvP justo; normalização competitiva e maestria cosmética são propostas, não decisões aprovadas. O entendimento de 40% foi descartado.
- Consulte a documentação oficial correspondente antes de copiar APIs de rede ou exemplos de versões antigas.

## Validação e comunicação

- Use verificações proporcionais ao trabalho. Documentação não exige inventar uma suíte de testes de jogo.
- Para regras de economia e rede, priorize testes de invariantes, comandos duplicados, limites, reprodução por semente e privacidade.
- Diferencie verificar a instalação do Godot de testar gameplay, conexão entre clientes ou balanceamento.
- Explique ao usuário iniciante o propósito de cada passo de Godot em português, com ações pequenas e verificáveis.
- Nunca registre chaves de API, tokens, senhas ou dados privados nos documentos e logs do projeto.
