# UX Spec: Main Screen e Status Inline

> **Status**: Proposta revisada; pendente de UX Review
> **Author**: User + ux-designer
> **Last Updated**: 2026-11-13
> **Journey Phase(s)**: Planejamento da campanha e consulta de status; mapa de jornada indisponível
> **Platform Target**: PC, base 1024x768; mouse, teclado e gamepad
> **Source GDDs**: `design/gdd/calendar-and-turns.md`, `stats-and-stress.md`, `activities.md`, `economy.md`
> **Template**: UX Spec

---

## Purpose & Player Need

A pessoa jogadora chega querendo entender a data da campanha, a condição e os recursos da protagonista, e o que pode fazer em seguida. A MainScreen apresenta essas informações e oferece solicitações claras para os seis destinos em escopo e para o fluxo de agenda.

A tela apresenta estado, mas não altera o `SimulationCore`. Ativar Agenda ou AGENDAR solicita o fluxo de agenda, que está fora desta spec.

## Player Context on Arrival

O mapa de jornada não está disponível. O contexto provisório é a chegada ao hub da campanha entre períodos, para consultar o progresso antes de escolher um destino ou solicitar a agenda. A tela deve identificar data, protagonista, créditos e condição sem exigir que Status seja aberto.

## Navigation Position

`Fluxo da campanha -> MainScreen -> expansão inline de Status`

A MainScreen é o hub da campanha. Status é um estado inline desta tela, não uma cena separada. O item Perfil do menu continua sendo uma solicitação de destino e não deve ser confundido com o controle de expansão de Status. As telas de destino não fazem parte deste escopo.

## Entry & Exit Points

| Origem | Gatilho | Contexto recebido |
|---|---|---|
| Fluxo da campanha | Abrir ou retornar à MainScreen | `SimulationCore` inicializado e dados atuais do perfil/save |
| MainScreen | Ativar Status no cartão da personagem | A tela e o foco permanecem no contexto atual |

| Destino | Gatilho | Observações |
|---|---|---|
| MainScreen compacta | Fechar Status, `ui_cancel` ou cancelar no gamepad | Fecha somente a expansão e restaura foco ao controle Status |
| Fluxo de agenda | Item Agenda ou botão principal AGENDAR | Emite solicitação; não avança período |
| Fluxo de destino | Perfil, Cidade/Lojas, Equipamento, Falar ou Missão | Emite solicitação; destino fora desta spec |

Com Status fechado, esta tela não define uma ação de sair do aplicativo. Cancelar não avança nem altera a campanha.

## Layout Specification

### ASCII Wireframe

```text
┌──────────────────────────────────────────────────────────────────────┐
│ ┌────────────────────┐                     ┌──────────────────────┐ │
│ │ ANO · MÊS            │                     │ NOME · IDADE · CRÉDITOS│
│ │ DIA · PERÍODO        │       CENA          │ [STATUS / EXPANDIR] │ │
│ │ CONCLUÍDOS n / 108   │ [personagem visível]│ Atributos · resumo  │ │
│ └────────────────────┘                     │ Combate · explicação│ │
│                                             │ Reputações · resumo│ │
│                                             │ Níveis dos cursos  │ │
│                                             └──────────────────────┘ │
│                                                                      │
│ ┌────────────────────── MENU: 6 ITENS ────────────────────────────┐ │
│ │ Agenda       Perfil        Cidade/Lojas                          │ │
│ │ Equipamento  Falar         Missão                                │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                 [AGENDAR]            │
└──────────────────────────────────────────────────────────────────────┘
```

Ao expandir Status, os detalhes ocupam mais espaço na área direita; cenário e personagem continuam visíveis. O wireframe define relações, não coordenadas. Arte e roupas devem ser placeholders originais e adequados à idade, sem reproduzir arte de Princess Maker.

### Layout Zones

1. **Calendário, superior esquerdo**: ano, mês, rótulo do dia, período, dia do mês, períodos concluídos/108 e marcador de evento fixo somente quando fornecido pelo sistema responsável.
2. **Cena, centro**: cenário ao fundo e personagem em primeiro plano; a UI deve permanecer legível.
3. **Personagem e Status, direita**: nome do perfil/save, idade, créditos, controle Status e quatro resumos compactos; expansão inline.
4. **Menu, faixa inferior**: exatamente Agenda, Perfil, Cidade/Lojas, Equipamento, Falar e Missão.
5. **Ação principal, inferior direita**: AGENDAR, solicitando o mesmo fluxo que Agenda.

Canvas base 1024x768 (4:3). Os controles devem manter essas relações nas proporções suportadas e não podem se sobrepor nem ser cortados na resolução base.

### Component Inventory

| Componente | Conteúdo e comportamento | Padrão |
|---|---|---|
| Calendário | Ano, mês, período 1-3, dias 1/11/21, dia da semana decorativo e ordinal atual / 108. Informativo e não focável. | Calendar Data Display |
| Cartão da personagem | Nome do perfil/save, idade derivada, créditos e controle Status | Character Status Summary; Button Secondary |
| Atributos | STR, INT, CHA, REF, STA, ETH; Stress separado; valores e barras em 0-100 | Character Status Summary; Attribute Delta + Progress Bar somente para deltas reais |
| Combate | Explicação localizada de que o combate de missão é automático; sem chance ou bônus de equipamento | Character Status Summary |
| Reputações | Fighter, Social e Hacker com valores numéricos e barras | Character Status Summary |
| Habilidades/progresso | Nível de cada um dos três cursos; sem streak de trabalho nem contagem de missões nesta versão | Character Status Summary |
| Seis itens de menu | Ícone e rótulo textual persistente; cada item emite solicitação de destino | Grid Item; Tooltip; Focus Management |
| AGENDAR | Ação principal; emite solicitação de agenda sem avançar a simulação | Button Primary |
| Status inline | Expande os quatro blocos existentes; fechar devolve foco ao acionador | Button Secondary; Escape/Cancel |

Todos os alvos interativos têm pelo menos 40x40 pixels lógicos. Ícones complementam os rótulos textuais. Todas as texturas, incluindo ícones e moldura dos painéis, são resolvidas via `Assets.get_texture`. O `UITheme` compartilhado centraliza cores, tipografia e estilo de painel; a textura NinePatch é resolvida por `Assets` em runtime, nunca por caminho direto na cena.

### Information Hierarchy

1. Ano, mês, período e progresso ordinal da campanha.
2. Identidade, idade e créditos da protagonista.
3. Quatro grupos de Status: atributos, explicação de combate, reputações e níveis dos cursos.
4. Seis solicitações de destino e a ação principal de agenda.
5. Tooltips e explicações suplementares.

## States & Variants

| Estado | Gatilho | Comportamento |
|---|---|---|
| Carregando | Dependências obrigatórias ainda não fornecidas | Mostra estado localizado; não mostra valores inventados nem habilita solicitações |
| Padrão | Simulação e perfil válidos | Mostra calendário, cena, cartão, Status compacto e seis itens |
| Sem campanha ativa | Não existe save/campanha para apresentar | Mostra estado vazio localizado e solicita ao fluxo chamador que forneça ou crie uma campanha; não mostra valores simulados nem habilita ações |
| Status expandido | Ativar Status | Expande os mesmos quatro grupos inline; mantém a cena visível e oferece controle de fechar |
| Campanha concluída | 108 períodos concluídos | Mostra data terminal e 108/108; não sugere período 109 |
| Doença bloqueia missões | Simulação informa doença | Missão fica desabilitada com motivo localizado; os outros controles permanecem disponíveis |
| Campo de perfil ausente | Nome não existe | Mostra indisponibilidade localizada; não inventa nome |
| Métrica opcional ausente | Valor não fornecido pelo responsável | Mostra indisponibilidade localizada ou omite a métrica; não substitui por zero |
| Erro de dados obrigatórios | Falha ao inicializar o núcleo ou carregar dados requeridos | Mostra erro localizado; não emite solicitação como se tivesse sucesso |
| Textura ausente | Resolver não encontra arte final ou placeholder | Usa fallback procedural; controles permanecem legíveis e utilizáveis |

Não há busca assíncrona definida atualmente. Se o carregamento for síncrono, o estado de carregamento pode ser breve ou omitido, mas deve existir para uma tela ainda sem dependências.

## Interaction Map

A ordem de foco por teclado é Status, itens do menu em ordem de linha, depois AGENDAR. Ao expandir Status, o foco vai para o controle de fechar; ao fechar, retorna a Status. Navegação direcional acompanha a grade visível. Calendário, barras e resumos somente textuais não recebem foco.

| Ação | Mouse | Teclado | Gamepad | Resultado |
|---|---|---|---|---|
| Expandir Status | Clicar no controle visível | Foco + Enter/Espaço | D-pad até o controle + confirmar | Expande inline |
| Fechar Status | Clicar em fechar | `ui_cancel` ou fechar + Enter/Espaço | Cancelar/B ou fechar + confirmar | Fecha e restaura foco |
| Navegar pelo menu | Hover/clique | Tab/Shift+Tab e setas | D-pad | Foco visível; rótulos permanecem |
| Ativar Agenda ou AGENDAR | Clicar | Foco + Enter/Espaço | Foco + confirmar | Emite solicitação de agenda; não avança período |
| Ativar Perfil, Cidade/Lojas, Equipamento, Falar ou Missão | Clicar no item | Foco + Enter/Espaço | Foco + confirmar | Emite solicitação de destino correspondente |
| Consultar calendário/status | Não interativo | Não focável | Não focável | Valores informativos também são apresentados como texto |
| Consultar tooltip | Hover | Foco | Foco | Mesmo conteúdo suplementar para todos os métodos |

Cancelar/B fecha Status somente quando ele está aberto. Na MainScreen compacta, não sai do aplicativo, não confirma ação nem altera a campanha. Controles desabilitados mostram o motivo em texto visível, não apenas em tooltip.

## Data Requirements

A tela consome uma projeção fornecida pelo chamador e não calcula recompensas nem altera diretamente `SimulationCore`.

| Dado exibido | Responsável/origem | Atualização | Comportamento se ausente/inválido |
|---|---|---|---|
| Ano, mês, período, idade, períodos concluídos e total de períodos | `SimulationCore.calendar` | Binding inicial e atualização de estado fornecida pelo chamador | Indisponibilidade localizada; não inventar data. O contador é `turns_completed/108`, começando em 0/108 |
| Dias 1/11/21 e rótulo do dia da semana | Regras de apresentação do calendário | Derivado do período atual | Apenas decorativo; não implica regras adicionais |
| Nome do perfil | Save/perfil atual via `DataManager` | Binding inicial e atualização do perfil | Indisponibilidade localizada |
| Créditos | `SimulationCore.economy` | Binding inicial e atualização de estado | O núcleo deve creditar a mesada de 200 Cr antes da primeira escolha; ausência não equivale a zero e o saldo nunca é negativo |
| Seis atributos, Stress, doença e reputações | `SimulationCore.stats`; rótulos dos atributos via `assets/data/stats.json` | Binding inicial e atualização de estado | Dados inválidos são reportados; UI não corrige nem substitui silenciosamente |
| Níveis dos três cursos | `SimulationCore.activities` e registros em `assets/data/activities.json` | Binding inicial e atualização de estado | Indisponibilidade localizada |
| Explicação de combate | Tabela de strings localizada | Ao carregar a tela | Chave ausente é erro de dados, não motivo para hardcode |
| Marcador de evento | Sistema de calendário/eventos, quando integrado | Mudança do estado do evento | Sem marcador se não houver fonte ou evento ativo |
| Rótulos, mensagens, meses, dias da semana, tooltips | `assets/data/strings_pt_br.json`, exceto nomes de atributos de `stats.json` | Ao carregar ou trocar idioma | Chaves ausentes são identificadas e corrigidas no catálogo |
| Imagens e textura do painel | `Assets.get_texture` | Ao construir a UI | Fallback: arte final, placeholder, textura procedural |

Os nomes dos atributos vêm de `stats.json` e são associados pelo ID. Todos os outros textos apresentados ao jogador vêm da tabela de localização. Valores dinâmicos do save são dados, não cópia da interface.

## Events Fired

Os sinais abaixo são contratos da tela; não pressupõem que as telas de destino já existam.

| Ação do jogador | Intenção/sinal | Payload | Mutação da simulação |
|---|---|---|---|
| Agenda ou AGENDAR | `schedule_requested` | ID do controle de origem | Nenhuma |
| Perfil, Cidade/Lojas, Equipamento, Falar, Missão | `destination_requested` | ID estável do destino | Nenhuma |
| Expandir/fechar Status | Estado de apresentação local | Aberto/fechado e dono do foco | Nenhuma |
| Ler calendário/status | Nenhum | — | Nenhuma |
| Ação desabilitada | Nenhum | — | Nenhuma |

## Transitions & Animations

- Status expande/fecha inline com transição curta, sem flashes; a cena permanece visível.
- O foco continua visível durante e depois da transição.
- Barras atualizam somente após mudança fornecida pelo sistema responsável; a UI não inventa deltas de jogo.
- Nenhum som, haptic ou fluxo de transição entre telas é adicionado neste escopo.

## Input Method Completeness Checklist

- [ ] Mouse: seis itens, Status, AGENDAR e fechar são acionáveis; blocos informativos não simulam botões.
- [ ] Teclado: todas as ações são alcançáveis e ativáveis sem mouse; `ui_cancel` fecha Status.
- [ ] Gamepad: todas as ações são alcançáveis pelo D-pad e confirmáveis; cancelar/B fecha Status.
- [ ] Ordem de foco: Status, menu em ordem de linha, AGENDAR; Status expandido tem controle de fechar visível.
- [ ] Fechar Status restaura o foco ao acionador.
- [ ] Todos os alvos acionáveis têm no mínimo 40x40 pixels lógicos.
- [ ] Todo ícone de menu tem rótulo textual visível.

## Accessibility

Não foi encontrado um tier de acessibilidade comprometido pelo projeto. Portanto, esta tela não declara conformidade com um tier. Práticas exigidas para a tela:

- Navegação por teclado/gamepad e foco visível, sem depender somente de cor.
- Texto numérico acompanha cada barra; valor, doença e motivo de bloqueio não são comunicados somente por cor.
- Ícones têm rótulos textuais e alvos de no mínimo 40x40 pixels lógicos.
- Sem flashes ou movimento rápido; respeitar redução de movimento se uma opção do projeto for adicionada.
- Valores e motivos de desabilitação ficam visíveis sem hover.

## Localization Considerations

- Todo rótulo, mensagem, mês, dia da semana, tooltip e formato de valor vem da tabela PT-BR, exceto nomes de atributos, que vêm de `stats.json`.
- Nenhum texto visível é hardcoded em cena ou script de UI.
- Reservar pelo menos 40% de expansão textual. O texto não pode sobrepor valores, foco ou controles vizinhos em 1024x768.
- Limites da cópia PT-BR antes da expansão: rótulos de menu/botões até 18 caracteres; títulos de blocos até 24; mensagens de status/erro até 80; tooltips até 120. Meses e dias da semana até 12 caracteres.
- Nomes dinâmicos do perfil não são truncados; o cartão deve acomodá-los em até duas linhas.
- Chaves do catálogo devem identificar placeholders de valores dinâmicos. Chaves ausentes são registradas e corrigidas na tabela.

## Acceptance Criteria

1. Em 1024x768, calendário, cena/personagem, cartão, quatro grupos Status, exatamente seis itens e AGENDAR aparecem sem cortes ou sobreposição.
2. Status abre/fecha inline; a cena permanece visível e o foco retorna ao controle que abriu a expansão.
3. O calendário representa 3 anos, 12 meses/ano, 3 períodos/mês e 108 períodos; o contador mostra períodos concluídos (0/108 no início), os dias são 1/11/21 e os dias da semana são decorativos.
4. Toda ação é alcançável e ativável por mouse, teclado e gamepad; cada alvo tem ao menos 40x40 pixels lógicos.
5. Rótulos de atributos correspondem aos IDs/nomes carregados de `stats.json`; valores/barras ficam entre 0 e 100 e Stress é separado.
6. Créditos vêm de `SimulationCore`, iniciam em 200 Cr antes da primeira escolha, nunca são negativos e dados ausentes não são mostrados como zero.
7. Os quatro grupos mostram atributos, explicação de combate, reputações e níveis de cursos; não inventam chance, bônus de equipamento, streak ou contagem de missões.
8. Agenda/AGENDAR emite solicitação sem avançar `SimulationCore`; cada outro item emite sua própria solicitação de destino.
9. Alterar estilo/cor de painel em `UITheme` reflete em MainScreen e Status expandido.
10. Com dependências fornecidas, a tela fica interativa em até 250 ms, excluindo importação inicial do Godot e carregamento de assets.
11. A interface respeita os limites de texto definidos e acomoda 40% de expansão sem cortes/sobreposições na resolução base.
12. Perfil, dados obrigatórios, localização ou métricas opcionais ausentes seguem os estados documentados sem defaults com aparência de sucesso.

## Open Questions

- `design/player-journey.md` e `design/accessibility-requirements.md` não existem; o contexto de chegada é provisório e o tier de acessibilidade não foi avaliado.
- Não foram encontrados screenshots em `references/`; pode-se validar a composição contra esta spec, mas não alegar comparação com screenshots.
- Plataforma e suporte de input do projeto não estão configurados em `project.yaml`; esta tela considera PC com mouse, teclado e gamepad, conforme escopo solicitado.
- O sistema de eventos não está conectado ao `SimulationCore`; o marcador de calendário fica ausente até existir uma fonte.
- Chance de missão e bônus de equipamento foram omitidos intencionalmente até que a API responsável defina uma fonte estável.
- `README.md` e notas antigas de UI mencionam oito ícones; esta spec usa os seis itens acordados e exclui Descanso e Opções.
- Agenda e AGENDAR solicitam o mesmo fluxo; cada ativação emite apenas uma solicitação.
- Telas de agenda, eventos, encontros, resultado e derrota estão fora deste escopo.
- O GDD determina mesada inicial de 200 Cr; o `SimulationCore` atual precisa ser corrigido para expô-la antes da primeira escolha.
