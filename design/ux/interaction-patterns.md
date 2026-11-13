# Interaction Pattern Library

> **Status**: In Design
> **Author**: user + ux-designer
> **Last Updated**: 2026-11-13
> **Version**: 1.0
> **Engine**: Godot 4.5.1
> **UI Framework**: Godot Control nodes
> **Template**: Interaction Pattern Library

---

## Overview

Esta biblioteca é a fonte única dos comportamentos reutilizáveis de UI do MVP. Specs de tela devem referenciar os nomes dos padrões abaixo, em vez de redefinir foco, confirmação, feedback ou navegação em cada tela. A biblioteca descreve comportamento; não implementa telas nem escolhe arte final.

O documento está em português; cada padrão recebe um nome canônico em inglês entre parênteses para facilitar referências entre specs e implementação. Os padrões permanecem **Draft** até serem implementados e validados em uma tela.

### Contexto e limites

- A única spec de tela existente é [main-screen.md](./main-screen.md). Ela não contém seções formais de inventário de componentes ou mapa de interação; os padrões existentes foram extraídos das regras descritas no documento.
- O suporte pedido para o MVP é mouse, teclado e gamepad. A plataforma-alvo ainda não está configurada no projeto; não se presume suporte a toque.
- Não há art bible nem tier de acessibilidade aprovado. Cores, bordas, tipografia e tempos exatos são decisões futuras do tema central; esta biblioteca não declara conformidade com um tier ainda não definido.
- Strings visíveis devem vir da tabela de localização `assets/data/strings_pt_br.json`; specs podem mostrar texto ilustrativo, mas cenas e componentes não devem fixar cópias literais.
- Esta etapa documenta padrões reutilizáveis. Telas futuras, cenas, código, tema e chaves novas de localização ficam fora do escopo.

### Regras transversais

1. Todo componente interativo define estados normal, focado, pressionado e desabilitado. Displays puramente informativos definem apenas os estados de dados aplicáveis; não ganham interação artificial.
2. Nenhuma informação depende apenas de cor. Combine cor com texto, ícone, símbolo, forma, padrão ou valor numérico conforme o padrão.
3. Alvos acionáveis medem pelo menos 40 × 40 px na resolução base de 1024 × 768.
4. Foco de teclado/gamepad permanece visível e nunca se perde ao abrir, fechar ou atualizar painéis. Ao fechar, retorna ao controle que abriu o painel, se ainda existir.
5. Esc, B do gamepad e o botão visível “Voltar” acionam a mesma regra de voltar/cancelar. Enter e o botão primário do gamepad confirmam a ação focada.
6. Texto essencial à decisão permanece visível; tooltip complementa, mas nunca substitui, nome, custo, requisito, consequência ou motivo de bloqueio.
7. Cores, bordas, tipografia e tokens de animação vêm de um único `UITheme` compartilhado; telas não duplicam valores locais para esses estilos.

---

## Pattern Catalog

Os nomes abaixo são identificadores canônicos; o texto em português é a forma usada nas specs. “Planejada” indica um padrão do MVP cuja tela ainda não tem spec própria.

### Navegação e controles

| Padrão | Descrição | Uso previsto | Status |
|---|---|---|---|
| Botão primário (Button Primary) | Ação principal da tela; seu efeito segue o fluxo definido para ela. | MainScreen: Agendar/SCHEDULE | Draft |
| Botão secundário (Button Secondary) | Ação alternativa ou de voltar, com menor ênfase. | MainScreen e telas planejadas | Draft |
| Item de menu em grade (Grid Item) | Atalho acionável com ícone, rótulo, foco, tooltip e estado bloqueado explicado. | MainScreen: faixa de menu | Draft |
| Seletor de período (Schedule Slot Selector) | Três períodos do mês com estados vazio, preenchido e ativo. | Agenda planejada | Draft |
| Seletor de categoria (Tab Bar) | Alterna entre estudo, trabalho, missão e lazer. | Agenda planejada | Draft |
| Item de atividade/loja (Activity/Shop List Item) | Linha com nome, ícone, custo, requisito, previsão de ganho/Stress e motivo de bloqueio. | Agenda e lojas planejadas | Draft |
| Voltar/cancelar (Escape / Cancel) | Une Esc, B do gamepad e botão visível Voltar. | Todas as telas planejadas | Draft |
| Gestão de foco (Focus Management) | Define foco ao abrir, fechar, bloquear ou remover controles/painéis. | Todas as telas | Draft |
| Transição entre telas (Screen Transition) | Fade curto e consistente, com restauração do foco ao retornar. | Navegação entre telas | Draft |

### Diálogos e feedback

| Padrão | Descrição | Uso previsto | Status |
|---|---|---|---|
| Diálogo com retrato e escolhas (Dialogue Box) | Retrato, texto e 2–3 escolhas, com avanço por confirmação. | Eventos/conversas planejados | Draft |
| Modal de confirmação (Confirmation Dialog) | Confirmar ou voltar; foco inicial no botão seguro Voltar. | Ações destrutivas ou caras | Draft |
| Tooltip contextual (Tooltip) | Descrição por hover do mouse ou foco de teclado/gamepad. | MainScreen e telas com contexto adicional | Draft |
| Notificação curta (Toast / Notification) | Feedback não bloqueante para compra, saldo insuficiente, evento ou equipamento. | Feedback global | Draft |
| Alerta de risco de Stress/Saúde (Stress/Health Risk Alert) | Aviso com texto, ícone e cor para comunicar risco sem depender da cor. | Agenda e status planejados | Draft |
| Painel de resultado (Monthly / Mission Result Panel) | Resume o fechamento mensal ou o resultado de missão, com ação para continuar. | Resultados planejados | Draft |
| Controle de velocidade de execução (Execution Speed Control) | Acelera ou pula animações em qualquer cena de execução. | Cenas de execução planejadas | Draft |

### Dados, inventário e opções

| Padrão | Descrição | Uso previsto | Status |
|---|---|---|---|
| Calendário informativo (Calendar Data Display) | Ano, mês, período, dia/rotulo do período, evento e progresso da campanha. | MainScreen | Draft |
| Cartão e resumo de status (Character Status Summary) | Nome, idade, créditos e resumo compacto/expandido dos blocos de status. | MainScreen e Status | Draft |
| Variação de atributo e barra (Attribute Delta + Progress Bar) | Mostra `+N`/`-N` com símbolo e barra numérica animada. | Resultado e status | Draft |
| Slot de inventário/equipamento (Inventory Slot) | Estados vazio, ocupado, equipado e bloqueado. | Inventário planejado | Draft |
| Controle contínuo (Slider) | Ajuste de volume com valor numérico visível. | Opções planejadas | Draft |
| Seletor de valor discreto (Dropdown / Select) | Escolha de velocidade de animação ou tamanho do texto. | Opções planejadas | Draft |
| Interruptor (Toggle) | Configuração binária com estado atual explícito. | Opções planejadas | Draft |

---

## Patterns

Os padrões a seguir são especificações de comportamento, não autorização para criar as telas que os usarão. “Foco” é sempre visível; regras globais de estado, localização, tamanho de alvo e contraste estão em **Regras transversais**.

### Navegação e controles

#### Botão primário (Button Primary)

**Category**: Input  
**Used In**: MainScreen — Agendar/SCHEDULE; confirmação de escolhas nas telas planejadas  
**Description**: Executa a ação principal disponível no contexto atual.  
**Specification**:
- Estados: normal, foco, pressionado e desabilitado. Apenas um botão primário por contexto/painel.
- Mouse ativa ao soltar dentro do alvo; teclado Enter/Espaço e botão de confirmar do gamepad ativam o botão focado.
- O rótulo descreve a ação; estado desabilitado apresenta o motivo próximo e acessível.
- Em telas/painéis que acabaram de abrir, não rouba foco de uma ação segura definida pelo padrão específico.
**When to Use**: Ação principal, como iniciar o agendamento ou continuar após um resultado.  
**When NOT to Use**: Voltar, cancelar ou ação destrutiva/cara sem confirmação.  
**Reference**: [main-screen.md](./main-screen.md), ação Agenda/SCHEDULE.

#### Botão secundário (Button Secondary)

**Category**: Input / Navigation  
**Used In**: Telas e painéis planejados; ação visível Voltar  
**Description**: Ação alternativa ou de cancelamento, com hierarquia visual menor que a primária.  
**Specification**:
- Estados: normal, foco, pressionado e desabilitado; aparência e foco distinguem-se sem depender só de cor.
- Ativação por mouse, Enter/Espaço ou botão confirmar do gamepad.
- Em modais, a ação Voltar/Cancelar também responde a Esc e B; o contexto define o resultado.
**When to Use**: Voltar, cancelar ou escolher uma alternativa não principal.  
**When NOT to Use**: Confirmar a ação principal ou executar sozinho uma ação destrutiva/cara.  
**Reference**: Padrão transversal; telas específicas ainda não têm spec.

#### Item de menu em grade (Grid Item)

**Category**: Layout / Input  
**Used In**: MainScreen — faixa de menu  
**Description**: Atalho em grade com ícone e rótulo acessível.  
**Specification**:
- Estados: normal, foco, pressionado e desabilitado. Foco tem indicador visível; selecionar/pressionar não depende de cor.
- D-pad move espacialmente entre células; teclado percorre a grade; mouse pode apontar e ativar.
- Tooltip aparece por hover ou foco, mas o nome da ação permanece visível.
- Estado bloqueado apresenta o motivo em texto acessível; célula não fica silenciosamente sem resposta.
**When to Use**: Ações irmãs organizadas em grade compacta.  
**When NOT to Use**: Lista longa ou opções que precisam de custo e previsão detalhados.  
**Reference**: [main-screen.md](./main-screen.md), faixa de menu.

#### Seletor de período (Schedule Slot Selector)

**Category**: Input / Data Display  
**Used In**: Agenda planejada  
**Description**: Representa os três períodos de cada mês e o estado do período em planejamento.  
**Specification**:
- Exibe exatamente três posições: início, meio e fim. Estados de dados: vazio, preenchido e ativo.
- A distinção de estado usa rótulo/ícone ou contorno além da cor; o estado ativo é anunciado em texto acessível.
- D-pad/setas movem entre períodos; confirmar seleciona o período focado. O foco não muda o estado persistido por si só.
- A tela de Agenda define o que acontece ao selecionar um período já preenchido; esta biblioteca não autoriza sobrescrever uma escolha.
**When to Use**: Planejamento visual dos três períodos do mês.  
**When NOT to Use**: Navegar para datas futuras fora do calendário aprovado.  
**Reference**: MVP calendar/turns e fluxo de agenda pendente de spec.

#### Seletor de categoria (Tab Bar)

**Category**: Navigation / Input  
**Used In**: Agenda planejada  
**Description**: Alterna a lista visível entre estudo, trabalho, missão e lazer sem sair da tela.  
**Specification**:
- Exibe as quatro categorias com rótulos localizados; sempre há uma categoria ativa.
- Setas esquerda/direita e D-pad mudam a categoria ativa; o conteúdo muda sem perder o foco da aba.
- A aba ativa tem indicador visual além de cor; mouse pode selecionar diretamente.
- Não mistura essa troca de categoria com navegação entre telas.
**When to Use**: Seções irmãs da mesma tela, com uma lista visível de cada vez.  
**When NOT to Use**: Abrir uma tela independente ou apresentar poucas opções que devam ser comparadas simultaneamente.  
**Reference**: Categorias de atividade do MVP; tela ainda sem spec.

#### Item de atividade/loja (Activity / Shop List Item)

**Category**: Input / Data Display  
**Used In**: Agenda e lojas planejadas  
**Description**: Linha selecionável para uma atividade ou item, mostrando os dados necessários à decisão.  
**Specification**:
- Mostra, quando aplicável, nome, ícone, custo, requisito, ganhos previstos e variação prevista de Stress.
- Estados interativos: normal, foco, pressionado e bloqueado. Requisitos não atendidos exibem o motivo em texto; não basta desabilitar ou dessaturar.
- A previsão vem dos dados/sistemas; não promete ganho acima de cap nem esconde custo. Saldo insuficiente é explicado antes da confirmação.
- Setas/D-pad percorrem opções; confirmar abre ou seleciona a opção. A ação final segue o fluxo da tela, não ocorre por mero foco.
**When to Use**: Lista de atividades, produtos ou opções comparáveis.  
**When NOT to Use**: Atalho sem metadados (use Grid Item) ou painel de resultado.  
**Reference**: [main-screen.md](./main-screen.md), Agenda e execução de atividade.

#### Voltar/cancelar (Escape / Cancel)

**Category**: Navigation / Input  
**Used In**: Todas as telas e painéis interativos do MVP  
**Description**: Uma ação consistente cancela o contexto superior ou retorna ao contexto anterior.  
**Specification**:
- Esc, B do gamepad e o botão visível Voltar acionam a mesma operação contextual.
- Prioridade: fecha/cancela o painel superior; se não houver painel, retorna à tela anterior. Cancelar nunca confirma uma compra, atividade ou escolha.
- O botão Voltar segue o mesmo resultado e fica acessível por foco; não há comportamento exclusivo de mouse.
- Se não houver destino de volta, a spec da tela define o comportamento seguro antes da implementação.
**When to Use**: Todo contexto com cancelamento ou navegação de retorno.  
**When NOT to Use**: Confirmar/avançar uma decisão.  
**Reference**: Regra transversal solicitada pelo usuário.

#### Gestão de foco (Focus Management)

**Category**: Navigation  
**Used In**: Todas as telas, painéis e modais  
**Description**: Mantém uma posição de foco visível e recuperável em teclado/gamepad.  
**Specification**:
- Ao abrir uma tela/painel, foco vai ao controle principal seguro; exceções explícitas (como confirmação) prevalecem.
- Ao abrir modal, foco fica contido nele. Ao fechar, retorna ao acionador se ainda existir.
- Se o controle focado ficar desabilitado/removido, transfere foco ao próximo controle disponível; nunca deixa foco sem destino interativo.
- Navegação por D-pad/setas é espacial em grades e segue esquerda/direita nas abas. O foco nunca depende de cor apenas.
**When to Use**: Qualquer interface navegável sem mouse.  
**When NOT to Use**: Display puramente informativo sem controles.  
**Reference**: Requisito transversal de foco do MVP.

#### Transição entre telas (Screen Transition)

**Category**: Navigation / Feedback  
**Used In**: Navegação futura entre telas  
**Description**: Transição curta em fade, consistente e configurável centralmente.  
**Specification**:
- Abertura e retorno usam o mesmo token de duração/curva do tema; valores exatos ficam pendentes de validação visual.
- Ao retornar, restaura o foco que iniciou a navegação, conforme Focus Management.
- O controle global de execução pode acelerar ou pular apenas a apresentação; não pula decisões nem persistência.
- Evita flashes, deslocamentos inesperados e mudança de layout durante a transição.
**When to Use**: Troca entre telas do fluxo.  
**When NOT to Use**: Atualização de um valor dentro da mesma tela.  
**Reference**: Requisito de fade e restauração de foco fornecido pelo usuário.

### Diálogos e feedback

#### Diálogo com retrato e escolhas (Dialogue Box)

**Category**: Modal / Input  
**Used In**: Eventos e conversas planejados  
**Description**: Apresenta uma fala identificada por retrato e permite uma resposta curta.  
**Specification**:
- Exibe retrato, identificação do falante e texto localizado; escolhas têm 2–3 opções.
- Sem escolhas, confirmar avança uma fala concluída. Com escolhas, o foco inicial vai à primeira opção e confirmar escolhe a opção focada.
- Setas/D-pad percorrem as escolhas; mouse pode apontar e selecionar. Não há avanço automático.
- Ao fechar, retorna o foco ao controle que abriu o diálogo; o texto essencial não fica apenas em tooltip.
**When to Use**: Fala com personagem e escolha contextual.  
**When NOT to Use**: Aviso não bloqueante (use Toast) ou confirmação de ação cara/destrutiva (use Confirmation Dialog).  
**Reference**: Eventos/conversas previstos; tela ainda sem spec.

#### Modal de confirmação (Confirmation Dialog)

**Category**: Modal / Input  
**Used In**: Ações destrutivas ou caras  
**Description**: Interrompe o fluxo para confirmar uma consequência antes de executá-la.  
**Specification**:
- Mostra título específico, consequência/custo e duas ações: confirmar com rótulo explícito e Voltar/Cancelar.
- Foco inicial obrigatório no botão seguro Voltar/Cancelar. Esc, B ou Voltar cancela sem executar; confirmar executa uma única vez.
- Modal captura foco e bloqueia os controles de fundo; ao fechar, restaura o foco ao acionador.
- Toda consequência e custo necessários à decisão ficam visíveis antes da confirmação.
**When to Use**: Ação irreversível ou transação classificada como cara.  
**When NOT to Use**: Notificação simples ou ação reversível sem risco significativo.  
**Reference**: Requisito do usuário; limiar para “cara” pendente em Open Questions.

#### Tooltip contextual (Tooltip)

**Category**: Feedback  
**Used In**: MainScreen e controles com contexto adicional  
**Description**: Complementa um rótulo visível com explicação acessível por mouse e foco.  
**Specification**:
- Hover do mouse e foco de teclado/gamepad acionam o mesmo conteúdo; tooltip não exige mouse.
- Reposiciona-se para permanecer dentro da tela e não cobre informação crítica do controle.
- O rótulo e as informações obrigatórias continuam visíveis sem abrir o tooltip.
- Atraso e duração são tokens configuráveis; valores serão definidos ao validar o tema e o ritmo.
**When to Use**: Explicação opcional de ícone, atributo ou estado.  
**When NOT to Use**: Custo, requisito, bloqueio ou consequência indispensável à escolha.  
**Reference**: [main-screen.md](./main-screen.md), faixa de menu e acessibilidade.

#### Notificação curta (Toast / Notification)

**Category**: Feedback  
**Used In**: Feedback de compra, créditos insuficientes, evento e equipamento  
**Description**: Confirma um fato recente sem bloquear a interação atual.  
**Specification**:
- Mensagem curta localizada, com ícone e texto; cor pode reforçar tipo, nunca ser o único sinal.
- Aparece e some sem roubar foco; duração suficiente para leitura e token configurável.
- Mensagens repetidas podem ser enfileiradas/substituídas sem cobrir controles principais.
- Falha que exige ação ou aviso que precisa permanecer não pode depender apenas do toast; apresenta feedback persistente no contexto.
**When to Use**: Compra concluída, saldo insuficiente, evento disparado ou item equipado.  
**When NOT to Use**: Escolha obrigatória ou consequência que precisa ser confirmada.  
**Reference**: Requisitos de feedback fornecidos pelo usuário.

#### Alerta de risco de Stress/Saúde (Stress / Health Risk Alert)

**Category**: Feedback / Data Display  
**Used In**: Agenda e Status planejados  
**Description**: Explica um risco atual ou previsto relacionado a Stress e saúde.  
**Specification**:
- Apresenta texto localizado, ícone e cor; inclui o motivo e a consequência conhecida.
- Distingue risco atual de previsão antes da atividade; não afirma doença/limiar sem usar a regra vigente do GDD/sistema.
- Não bloqueia uma escolha por si só. Se a ação estiver realmente indisponível, usa também o estado bloqueado do item e explica o motivo.
**When to Use**: O Stress/estado atual alcança um limiar de aviso definido pelo GDD.  
**When NOT to Use**: Informar variação numérica pós-ação (use Attribute Delta).  
**Reference**: GDD de Stress e Saúde; valores exatos dependem da regra aprovada.

#### Painel de resultado mensal ou de missão (Monthly / Mission Result Panel)

**Category**: Feedback / Data Display  
**Used In**: Fim de mês e resolução de missão, ambos planejados  
**Description**: Resume efeitos já resolvidos antes de permitir continuar.  
**Specification**:
- Variante mensal resume os períodos e efeitos do mês; variante de missão resume resultado, recompensas e variações aplicadas.
- Valores exibidos correspondem ao estado efetivamente resolvido; ganhos/perdas incluem sinal e valor numérico.
- Exibe uma ação localizada de continuar. Não avança automaticamente nem reaplica efeitos ao reabrir.
- Animação é apenas apresentação e pode ser acelerada/pulada; persistência e resultado não são pulados.
**When to Use**: Depois que um mês ou missão foi resolvido.  
**When NOT to Use**: Prévia de custo/ganho antes de escolher (use Activity/Shop List Item).  
**Reference**: Fluxos de resultado descritos em [main-screen.md](./main-screen.md).

#### Controle de velocidade de execução (Execution Speed Control)

**Category**: Input / Accessibility  
**Used In**: Qualquer cena de execução  
**Description**: Permite acelerar ou pular a apresentação animada sem alterar a simulação.  
**Specification**:
- Controle visível e navegável por mouse, teclado e gamepad em toda cena de execução.
- Oferece estado normal, acelerado e pular animação; nomes e valores exatos ficam centralizados em localização/tema.
- Acelerar reduz a duração visual; pular encerra somente a apresentação. Não pula escolhas, cálculo, transação ou gravação.
- Mudança de velocidade atualiza a cena sem perder o foco. A regra de persistência da preferência entre cenas fica para a spec de Opções.
**When to Use**: Resolução com animações ou apresentação sequencial.  
**When NOT to Use**: Acelerar a lógica da simulação ou ignorar uma escolha do jogador.  
**Reference**: Requisito de controle global fornecido pelo usuário.

### Dados, inventário e opções

#### Calendário informativo (Calendar Data Display)

**Category**: Data Display  
**Used In**: MainScreen  
**Description**: Apresenta a posição atual da campanha sem oferecer navegação para o futuro.  
**Specification**:
- Mostra ano, mês, período 1–3, rótulo do dia e dia do período, além do contador concluído/total.
- Dia e data derivam da configuração/calendário; um evento agendado recebe marcador visível e rótulo textual.
- É informativo, não focalizável nem pressionável. Atualiza após a resolução do período sem mover o foco.
**When to Use**: Contexto temporal persistente da campanha.  
**When NOT to Use**: Selecionar um slot de planejamento (use Schedule Slot Selector).  
**Reference**: [main-screen.md](./main-screen.md), Calendário.

#### Cartão e resumo de status (Character Status Summary)

**Category**: Data Display / Input  
**Used In**: MainScreen e Status  
**Description**: Mostra identidade/recursos da personagem e resume os blocos de status sem esconder a cena.  
**Specification**:
- Cartão mostra nome, idade derivada e créditos atuais; o nome não é fonte para cálculo da idade.
- Resumo compacto e painel expandido usam os mesmos quatro blocos; abrir/fechar Status não substitui nem perde o contexto da MainScreen.
- Nomes dos atributos vêm de `assets/data/stats.json`; valores vêm do estado atual. Stress aparece separado de STA.
- Barras mostram valor numérico; estado de display não recebe estados pressionado/desabilitado, mas o controle para expandir Status segue estados interativos.
**When to Use**: Consulta rápida ou detalhada dos dados atuais da personagem.  
**When NOT to Use**: Mostrar alteração causada por uma ação (use Attribute Delta + Progress Bar).  
**Reference**: [main-screen.md](./main-screen.md), Cartão da personagem e Painel/tela de status.

#### Variação de atributo e barra (Attribute Delta + Progress Bar)

**Category**: Feedback / Data Display  
**Used In**: Resultado, Status e prévia de atividade  
**Description**: Comunica a mudança de um atributo junto ao valor atual e sua faixa.  
**Specification**:
- A variação aparece como `+N` ou `-N`, acompanhada de símbolo e cor temática; o significado não depende apenas da cor.
- A barra mostra o valor numérico atual e a faixa válida do atributo; ganhos respeitam clamp/cap e perdas não ultrapassam o mínimo.
- A animação da barra representa somente a mudança real. O controle de velocidade pode acelerá-la ou pulá-la sem mudar o valor.
- Nomes e rótulos de atributos são localizados e lidos de `stats.json`, não fixados no componente.
**When to Use**: Resultado de atividade, missão ou alteração de status.  
**When NOT to Use**: Barra sem valor atual/limite definido.  
**Reference**: [main-screen.md](./main-screen.md), Painel de status; `assets/data/stats.json`.

#### Slot de inventário/equipamento (Inventory Slot)

**Category**: Game-Specific / Input  
**Used In**: Inventário planejado  
**Description**: Contêiner selecionável para item ou equipamento.  
**Specification**:
- Estados: vazio, ocupado, equipado e bloqueado. Estados são distintos por ícone/rótulo/contorno além de cor.
- Foco permite consultar descrição contextual; item e estado ficam acessíveis por texto.
- Bloqueado explica o motivo. Vazio não é tratado como desabilitado. Ações disponíveis (equipar/inspecionar) são definidas pela tela.
**When to Use**: Inventário ou equipamento com posições definidas.  
**When NOT to Use**: Lista linear de produtos (use Activity/Shop List Item).  
**Reference**: Requisito de inventário/equipamento do usuário.

#### Controle contínuo (Slider)

**Category**: Input  
**Used In**: Opções — volume  
**Description**: Ajusta valor contínuo com posição e valor numérico explícito.  
**Specification**:
- Estados: normal, foco, pressionado/arrastando e desabilitado; valor atual permanece legível.
- Mouse arrasta o controle; esquerda/direita ou D-pad ajustam em passos; extremos são acessíveis por controles de teclado equivalentes.
- Exibe valor numérico além da posição do indicador. Mudança atualiza a configuração sem perder foco.
**When to Use**: Volume e outros valores contínuos.  
**When NOT to Use**: Poucos valores discretos (use Dropdown / Select) ou estado binário (use Toggle).  
**Reference**: Opções planejadas.

#### Seletor de valor discreto (Dropdown / Select)

**Category**: Input  
**Used In**: Opções — velocidade de animação e tamanho do texto  
**Description**: Escolhe um valor nomeado de um conjunto finito.  
**Specification**:
- Estado fechado mostra rótulo e valor selecionado. Abrir transfere foco à opção atual; cima/baixo ou D-pad navega; confirmar seleciona.
- Esc, B ou Voltar fecha sem alterar o valor; escolha atual e foco continuam visíveis.
- Rótulos e opções são strings localizadas. Lista não pode ficar cortada na resolução base.
**When to Use**: Valores discretos de velocidade de animação ou tamanho do texto.  
**When NOT to Use**: Volume contínuo (use Slider) ou configuração binária (use Toggle).  
**Reference**: Opções planejadas.

#### Interruptor (Toggle)

**Category**: Input  
**Used In**: Opções planejadas  
**Description**: Alterna uma configuração persistente entre dois estados.  
**Specification**:
- Estados: normal, foco, pressionado/alternado e desabilitado; estado atual tem rótulo/indicador explícito além da posição/cor.
- Mouse, Enter/Espaço ou botão confirmar do gamepad alternam o valor. A mudança mantém foco e persiste conforme a configuração da tela.
- Rótulo acessível identifica a configuração; o valor On/Off é anunciado como estado, não misturado ao nome.
**When to Use**: Configuração binária persistente.  
**When NOT to Use**: Ação única, valor contínuo ou mais de duas opções.  
**Reference**: Opções planejadas.

---

## Gaps & Patterns Needed

### Specs e padrões ainda pendentes

- Não há specs próprias para Agenda/seleção de atividade, eventos/conversas, lojas/inventário, Opções ou painéis de resultado. Os padrões correspondentes estão em Draft e não substituem essas specs.
- Padrões de lista longa/rolagem, estados vazios e erros persistentes só serão adicionados se uma tela do MVP precisar deles; não foram incluídos sem requisito concreto.
- A spec de MainScreen ainda não referencia esta biblioteca pelos nomes canônicos. A atualização dessas referências fica para a revisão/implementação da UI, não altera seu conteúdo nesta etapa.

### Conflitos a resolver antes da UI

- O prompt de UI pede oito ícones de menu; [main-screen.md](./main-screen.md) enumera seis. A decisão de conteúdo deve ser resolvida antes de construir a grade.
- O prompt chama Status de tela; [main-screen.md](./main-screen.md) descreve expandir os mesmos blocos sem esconder permanentemente a cena. Confirmar se será painel expandido ou tela separada antes de criar a navegação.

Nenhum padrão adicional foi identificado além dos padrões do catálogo e dos dois pontos de escopo acima. Se uma screen spec posterior exigir outra interação reutilizável, documentá-la aqui antes de implementá-la.

---

## Open Questions

1. Qual critério numérico ou de contexto classifica uma compra/ação como “cara” e exige confirmação? Até essa decisão, a regra pode ser aplicada somente a ações destrutivas.
2. O alerta de Stress/Saúde usa apenas os limiares de consequência já definidos em `design/gdd/stats-and-stress.md`, ou precisa de um limiar de aviso anterior? Não inventar valores no componente.
3. Qual duração central do fade, do toast, do tooltip e da animação da barra será legível e consistente em 1024 × 768? Definir como tokens no `UITheme` após teste visual.
4. Quais valores e rótulos exatos de velocidade e tamanho de texto ficam disponíveis em Opções, e a velocidade persiste entre cenas?
5. Quais plataforma-alvo e requisitos de leitor de tela serão suportados? O projeto ainda não tem plataforma nem tier de acessibilidade configurados.
6. Resolver os dois conflitos de tela listados em **Gaps & Patterns Needed** antes de iniciar a implementação visual.
