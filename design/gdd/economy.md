# GDD: Economy

## Overview

A economia usa creditos inteiros. Nyx recebe 200 Cr no inicio de cada ano de jogo, totalizando 600 Cr ao longo dos tres anos; trabalhos e missoes bem-sucedidas podem acrescentar renda.

## Player Fantasy

Os creditos representam recursos limitados para estudo, equipamento e cuidado. O jogador escolhe entre investir, trabalhar ou guardar saldo; nao existe renda mensal automatica.

## Detailed Design

### Saldo e entradas

- Antes da primeira atividade do Ano 1, creditar 200 Cr. Creditar mais 200 Cr no primeiro periodo dos Anos 2 e 3.
- Trabalho paga uma vez por sessao selecionada. Os valores base e a promocao sao definidos em `activities.md`.
- Uma missao paga somente se for bem-sucedida; os valores sao definidos na tabela abaixo.
- Nao ha venda de itens, credito por tempo real, juros, inflacao ou salario passivo.

| Missao bem-sucedida | Credito |
|---------------------|---------|
| Fisica/protecao | 25 Cr |
| Tecnica | 30 Cr |
| Apoio comunitario | 20 Cr |

### Saidas

- Cursos: custo por nivel definido em `activities.md`.
- Itens e tratamentos: preco definido em `items-and-shops.md`.
- Nenhuma compra cria saldo negativo; nao ha emprestimo.

## Formulas

### Credito anual

`saldo_apos_mesada = saldo_anterior + 200`

- A mesada ocorre uma vez no primeiro periodo de cada ano, nunca a cada mes.
- Limites: 3 pagamentos no MVP, 200 Cr cada; total de mesada = 600 Cr.
- Exemplo: saldo 35 Cr no inicio do Ano 2 torna-se 235 Cr.
- Exemplo: iniciar o jogo com saldo 0 credita os primeiros 200 Cr antes do primeiro periodo.

### Salario por sessao

`pagamento = floor(salario_base * multiplicador_do_nivel)`

- Multiplicador: 1.0 ou 1.5; salario base: 15-25 Cr conforme a tarefa; resultado inteiro.
- Exemplo: apoio comunitario promovido: `floor(25*1.5)=37 Cr`.
- Exemplo: reparo leve no nivel 1 paga `15*1.0=15 Cr`.

### Transacao

`saldo_final = saldo_inicial + entrada - custo`

- Saldo inteiro nao pode ficar abaixo de 0; a compra e recusada se `saldo_inicial < custo`.
- Exemplo: 200 Cr, compra de item de 25 Cr e salario de 15 Cr: `200-25+15=190 Cr`.
- Exemplo: saldo 7 Cr para curso de 8 Cr: compra recusada e saldo permanece 7 Cr.

## Edge Cases

- Salarios fracionarios sao arredondados para baixo antes de creditar.
- Uma mesada e concedida exatamente uma vez por ano, inclusive ao carregar um save no inicio do ano.
- Uma missao que falha ou termina em fuga nao paga recompensa.
- Saldo nunca e negativo; uma operacao rejeitada nao altera inventario nem saldo.
- A economia nao tenta garantir equilibrio mensal: a renda e por escolha de atividade e a mesada e anual.

## Dependencies

- `calendar-and-turns.md` notifica o inicio do ano e controla os periodos.
- `activities.md` solicita debitos de cursos e creditos de trabalho/missao.
- `items-and-shops.md` e proprietario dos precos de itens e tratamentos.
- `events.md` solicita debitos e creditos de evento explicitamente definidos; compras do mercador seguem o catalogo de `items-and-shops.md`.
- `save-system.md` persiste o saldo.

## Tuning Knobs

| Knob | Faixa segura | Inicial |
|------|--------------|---------|
| Mesada anual | 200 fixo nesta decisao do MVP | 200 Cr |
| Salarios por sessao | 10-25 Cr | 15/20/25 Cr |
| Recompensas de missao | 10-30 Cr | 20/30/25 Cr |
| Precos de curso | 5-24 Cr por nivel | Ver `activities.md` |
| Inflacao | Desativada | Sem mudanca de preco por ano |

Alterar a mesada de 200 Cr ou a sua frequencia exige atualizar `mvp-decisions.md`.

## Acceptance Criteria

- Um novo jogo recebe 200 Cr antes da primeira escolha.
- Anos 2 e 3 recebem exatamente um credito adicional de 200 Cr no primeiro periodo.
- Ao fim do Ano 3, a mesada total creditada e 600 Cr, excluindo trabalho, missoes e eventos.
- Uma compra sem saldo suficiente nao altera saldo ou inventario.
- Salarios e recompensas sao entradas pontuais, nao rendas mensais automaticas.