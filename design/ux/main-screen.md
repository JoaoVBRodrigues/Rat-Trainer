# UX: Main Screen

## Objetivo e layout

Resolucao base 1024x768, proporcao 4:3. Usar a composicao de agenda classica como referencia, sem copiar arte ou roupa de screenshots.

```text
┌──────────────────────────────────────────────────────────────┐
│ [ANO 1 | JANEIRO | SEG | DIA 1]                                │
│ ┌──────────┐                         ┌──────────────────────┐ │
│ │ Agenda   │    Cenario da cidade    │ NYX | 12 anos | 200Cr│ │
│ │ 1/108    │                         │ ATRIBUTOS  STR 15 ...│ │
│ └──────────┘                         │ COMBATE   chance ... │ │
│                                      │ REPUTACAO F/S/H ...  │ │
│                                      │ PROGRESSO cursos ... │ │
│                                      │ [Agenda] [Cidade]    │ │
│                                      │ [Itens] [Falar][Missao]│
│       [PERSONAGEM EM PRIMEIRO PLANO]  └──────────────────────┘ │
│                         [ SCHEDULE ]                           │
└──────────────────────────────────────────────────────────────┘
```

## Camadas e componentes

### Calendario (canto superior esquerdo)

- Mostra ano do jogo, mes, dia da semana (rotulo do periodo), numero do dia (1, 11 ou 21), periodo 1-3 e contador `periodo_concluido/108`.
- Rotulos de dia: periodo 1 = segunda, periodo 2 = quarta, periodo 3 = sexta. Sao decorativos; o MVP nao modela semanas ou dias individuais.
- Periodo e mes sao derivados de `turns_completed`; nao ha navegacao para o futuro.
- Evento fixo no periodo atual e indicado com um marcador visivel.

### Cartao da personagem (canto superior direito)

- Nome de trabalho, idade derivada (12-15) e saldo atual de creditos.
- O cartao encabeca um painel de status persistentemente visivel, alinhado a direita; nao substitui o painel por um cartao independente.
- O painel principal resume os quatro blocos de status abaixo, com valores e barras compactas. Selecionar Status expande os mesmos blocos sem esconder a cena de forma permanente.
- Icones de acesso a inventario e agenda; numeros importantes tambem tem rotulo textual.

### Faixa de menu

Icones em grade compacta: Agenda, Perfil, Cidade/Lojas, Equipamento, Falar e Missao. Cada icone tem rotulo acessivel, foco de teclado, tooltip e estado desabilitado explicado. A agenda/SCHEDULE e a acao primaria.

### Cena principal

Ordem de renderizacao: cenario ao fundo, personagem em primeiro plano, elementos de interface por cima. Nyx tem roupa apropriada para a idade, sem sexualizacao. Animacao idle discreta; sem flashes rapidos.

## Painel/tela de status

O painel fixo mostra versoes compactas; a tela expandida mostra os quatro blocos com valores numericos junto as barras, sempre 0-100:

1. **Atributos:** STR, INT, CHA, REF, STA, ETH; Stress aparece separado de STA.
2. **Combate:** chance base de missao, bonus de equipamento e explicacao de que combate e automatico.
3. **Reputacoes:** Fighter Rep, Social Rep e Hacker Rep.
4. **Habilidades/progresso:** niveis dos tres cursos, streak da tarefa de trabalho e contagem de missoes tecnicas.

## Agenda e execucao de atividade

Antes de confirmar, mostrar categoria, atividade, custo, ganhos previstos, Stress previsto e disponibilidade. Nao apresentar ganhos acima dos caps; avisar quando um atributo ja esta em 100. Confirmar debita custos e resolve exatamente um periodo.

A cena de resultado substitui o painel de selecao e inclui:

- Caixa de ganhos/perdas em creditos, atributos e reputacoes.
- Mini-cena ou ilustracao contextual, sem violencia grafica.
- Texto curto do resultado e barras com valores antes/depois.
- Botao Continuar, habilitado apos a resolucao ter sido persistida.

## Tela de evento e encontro

Eventos fixos e encontros aleatorios mostram as escolhas especificas da carta (`Ajudar/Recusar`, compra ou reportar/acessar); nao reutilizam automaticamente um conjunto universal de quatro respostas.

O menu contextual de encontro pode apresentar **Lutar**, **Conversar**, **Fugir** e **Esconder**, mas habilita somente as acoes definidas para aquela situacao. Em missoes fisicas, **Lutar** inicia a resolucao automatica de `auto-combat.md`; **Fugir** ou **Esconder** encerram a missao sem recompensa. **Conversar** so fica habilitado quando a carta/mission define um resultado social. Nenhuma dessas acoes cria `criminal_record` ou altera ETH sem uma escolha explicitamente ilegal ou um delta declarado.

## Tela de derrota

Cena nao grafica de ORAC levando Nyx para casa, com texto de cuidado e descricao do resultado. A derrota nao reduz atributos, nao cria crime e nao elimina um periodo adicional. Continuar avanca o fluxo, pois o periodo ja foi salvo.

## Acessibilidade e comportamento

- Contraste legivel, texto escalavel e icones acompanhados de rotulos.
- Estado nao depende apenas de cor; foco e controles de teclado disponiveis.
- Animacoes curtas, sem tremor ou flashes intensos.
- O botao Schedule abre a escolha de atividade ou, se houver evento fixo/aleatorio, a escolha especifica da carta. Uma missao fisica abre o menu contextual e a opcao Lutar executa o combate automaticamente.

## Referencias

Usar somente a estrutura de composicao descrita pelo usuario. Screenshots e PDF nao estao presentes nesta copia; nenhuma afirmacao de comparacao visual foi feita. Nao reproduzir roupas, arte ou elementos protegidos das referencias.
