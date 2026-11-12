# GDD: Calendar and Turns

## Overview

O calendario organiza a campanha de Rat Trainer em 3 anos, dos 12 aos 15 anos. Cada ano tem 12 meses e cada mes tem 3 periodos: sao 36 periodos por ano e 108 no MVP.

## Player Fantasy

O jogador orienta Nyx Volt, sob a tutela de ORAC, equilibrando aprendizagem, trabalho supervisionado, missoes e descanso. Cada periodo oferece uma escolha; eventos substituem a escolha normal daquele periodo, sem acrescentar turnos.

## Detailed Design

### Calendario

- Anos de jogo: 1 a 3. Nyx comeca aos 12 anos; o desfecho ocorre ao completar o terceiro ano, aos 15.
- Meses: 1 a 12; periodos: 1 a 3.
- Para apresentacao, o calendario associa periodo 1/2/3 ao dia 1/11/21 e ao rotulo semanal segunda/quarta/sexta. O rotulo e decorativo e nao altera regras ou datas.
- Uma atividade ou escolha de evento ocupa exatamente um periodo.
- Ao terminar a resolucao, o periodo avanca. Depois do periodo 3 avanca o mes; depois de dezembro avanca o ano.
- O decimo segundo evento fixo e o ultimo periodo da campanha; apos sua resolucao, o jogo avalia os finais.

### Ordem de resolucao de um periodo

1. Mostrar a data e as atividades permitidas no estado atual.
2. No primeiro periodo de cada ano, creditar a mesada antes de abrir escolhas, se ainda nao estiver registrada como paga. Se houver evento fixo, apresenta-lo; caso contrario, fazer no maximo uma verificacao de evento aleatorio.
3. O jogador escolhe uma atividade ou uma opcao do evento. Um evento ocupa o periodo; nao ha atividade adicional no mesmo periodo.
4. Resolver custos, ganhos, missao/combate e efeitos do evento.
5. Atualizar atributos, reputacoes, flags, stress e saldo, sempre limitando os valores as faixas definidas nos GDDs proprietarios.
6. No periodo 3, fechar as sequencias mensais de trabalho usando os marcadores do save e limpar esses marcadores.
7. Avaliar a condicao de doenca e avancar exatamente um periodo.
8. Salvar automaticamente ao concluir o periodo.
9. Ao concluir o periodo 3, criar tambem um snapshot mensal de recuperacao.

Uma doenca restringe missoes enquanto `Stress` estiver no limiar de doenca ou acima dele, mas nao remove periodos. Assim, a campanha preserva os 108 periodos e uma escolha por periodo.

## Formulas

### Numero de periodos

`periodos_totais = anos * meses_por_ano * periodos_por_mes`

- Variaveis: `anos=3`, `meses_por_ano=12`, `periodos_por_mes=3`.
- Limites: 1 a 3 anos configurados; o MVP fixa 3. O total fixo do MVP e 108.
- Exemplo: `3 * 12 * 3 = 108` periodos.

### Indice do periodo

Para `turnos_concluidos` entre 0 e 107:

`year = floor(turnos_concluidos / 36) + 1`
`month = floor((turnos_concluidos % 36) / 3) + 1`
`period = (turnos_concluidos % 3) + 1`
`age = 12 + floor(turnos_concluidos / 36)`

- Os indices de ano, mes e periodo sao 1-based; `turnos_concluidos` e 0-based.
- Idade: 12-15; no valor 108 a campanha esta concluida, Nyx tem 15 anos e nao calcular um novo periodo.
- Exemplo: com 7 periodos concluidos, ano=1, mes=3 e periodo=2.
- Exemplo: com 36 periodos concluidos, inicia ano=2, mes=1 e periodo=1.
- Exemplo: com 108 periodos concluidos, idade=15 e campanha concluida.

## Edge Cases

- Uma doenca nao adiciona nem remove tempo: a atividade Missao fica indisponivel ate Stress cair abaixo do limiar.
- Eventos fixos tem prioridade sobre o sorteio aleatorio; no maximo um evento ocupa cada periodo.
- O saldo nunca fica negativo; uma atividade que nao pode ser paga nao aparece como selecionavel.
- Ao concluir o periodo 108, nao existe periodo 109: mostrar o resultado final e manter a data de encerramento em Ano 3, Mes 12, Periodo 3.

## Dependencies

- Depende de `stats-and-stress.md` para o estado de doenca e limites dos atributos.
- Depende de `activities.md` para as escolhas de periodo e `events.md` para eventos.
- `save-system.md` persiste o contador de periodos e a data derivada.
- `economy.md` recebe do calendario o inicio de cada ano para creditar a mesada.

## Tuning Knobs

| Knob | Faixa segura | Efeito |
|------|--------------|--------|
| Anos do MVP | fixo em 3 | Duracao e idade final; mudar exige revisao de `mvp-decisions.md`. |
| Periodos por mes | fixo em 3 | Numero de escolhas e ritmo mensal; mudar exige revisao de `mvp-decisions.md`. |

## Acceptance Criteria

- A campanha gera exatamente 108 periodos, distribuidos em 36 por ano.
- Cada periodo resolvido avanca uma unica vez; um evento nao cria um segundo turno.
- O periodo 36 avanca para Ano 2, Mes 1, Periodo 1; o 108 conclui a campanha.
- Doenca nao altera o contador de periodos nem permite missoes enquanto Stress esta no limiar.