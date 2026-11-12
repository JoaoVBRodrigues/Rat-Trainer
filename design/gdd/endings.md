# GDD: Endings

## Overview

O MVP tem exatamente 15 finais juvenis, avaliados uma vez ao concluir o periodo 108. O primeiro final elegivel na ordem canonica e apresentado.

## Player Fantasy

O final reconhece a vocacao, os vinculos ou o caminho escolhido por Nyx; nenhum final apresenta uma vida adulta ja concluida ou um relacionamento romantico.

## Detailed Design

### Matriz e prioridade

| Prioridade | Final | Condicoes |
|------------|-------|-----------|
| 1 | Evadida do Sistema | `disappear_from_society` |
| 2 | Aprendiz de Ciborgues | INT >= 70, REF >= 50 e `tech_experiments` |
| 3 | Tecnica Juvenil da Cidade | INT >= 65, pelo menos 5 `missoes_tecnicas_concluidas` e Hacker Rep < 70 |
| 4 | Guardiã da Rede | ETH >= 65, Hacker Rep >= 70 e `community_help` |
| 5 | Lider Comunitaria Jovem | CHA >= 75, Social Rep >= 75 e `community_help` |
| 6 | Promessa Corporativa | CHA >= 60, Social Rep >= 70 e ETH <= 30 |
| 7 | Recruta do Submundo | INT >= 50, ETH <= 35 e `criminal_record` |
| 8 | Voz das Ruas | CHA >= 65, Social Rep >= 65 e `community_help` |
| 9 | Mediadora Comunitaria | ETH >= 70, CHA >= 55 e `community_help` |
| 10 | Autora Emergente | INT >= 55, REF >= 55 e menos de 3 `missoes_tecnicas_concluidas` |
| 11 | Mecanica de Campo | STR >= 50, INT >= 55 e pelo menos 3 missoes tecnicas concluidas |
| 12 | Defensora das Ruas | STR >= 60 e Fighter Rep >= 70 |
| 13 | Hacker de Elite | INT >= 65 e Hacker Rep >= 70 |
| 14 | Artista Emergente | REF >= 60 e Social Rep >= 65 |
| 15 | Caminho Equilibrado | Nenhum requisito; resultado de reserva. |

As prioridades 3 e 10 distinguem percursos que seriam absorvidos por finais posteriores: a prioridade 3 exige Hacker Rep < 70 para nao capturar Hacker de Elite; a prioridade 10 exige menos de 3 missoes tecnicas para nao capturar Mecanica de Campo. Essas duas condicoes tambem foram refletidas em `mvp-decisions.md`.

### Avaliacao

1. Executar somente apos o evento E12 do periodo 108.
2. Testar condicoes na ordem da tabela.
3. Retornar o primeiro final elegivel.
4. Se nenhum final de prioridade 1-14 for elegivel, retornar Caminho Equilibrado.

## Formulas

### Predicado de elegibilidade

`elegivel = (todos os limiares numericos atendidos) AND (todas as flags exigidas verdadeiras) AND (contagens atendidas)`

- Atributos e reputacoes sao inteiros de 0 a 100; contadores sao inteiros >=0; comparacoes sao inclusivas, salvo `Hacker Rep < 70` na prioridade 3.
- Exemplo: INT 65, 5 missoes tecnicas, Hacker Rep 69 atende prioridade 3; Hacker Rep 70 nao atende prioridade 3.
- Exemplo: INT 60, REF 60 e 2 missoes tecnicas atende prioridade 10; com 3 missoes tecnicas, essa condicao nao atende.

### Selecionar final

`final = primeiro elegivel entre prioridades 1-14; caso contrario, prioridade 15`

- Exemplo: `disappear_from_society=true` retorna Evadida do Sistema, mesmo que outras rotas tambem estejam qualificadas.
- Exemplo: sem flags de rota e sem condicoes 1-14, retorna Caminho Equilibrado.

## Edge Cases

- Flags ausentes em um save valido equivalem a `false`; tipo de dado incorreto invalida o save.
- Limiares fora de 0-100 ou contadores negativos indicam save invalido; nao ajustar silenciosamente.
- A prioridade elimina empates; nao existe sorteio nem ordem de iteracao de dicionario.
- A rota Hacker de Elite nao e bloqueada pela prioridade 3: exige Hacker Rep >=70, enquanto prioridade 3 exige <70.
- Finais nao implicam romance, casamento ou maioridade.

## Dependencies

- `mvp-decisions.md` e proprietario da lista, dos limiares e da ordem de prioridade.
- `stats-and-stress.md` define faixas de atributos, reputacoes e flags.
- `activities.md`, `events.md` e `auto-combat.md` incrementam os valores usados.
- `save-system.md` persiste os dados finais antes da avaliacao.

## Tuning Knobs

Os 15 nomes, condicoes e prioridades sao decisoes fechadas do MVP. Valores de ganho nas atividades podem ser balanceados, mas alteracoes de condicoes devem ser espelhadas em `mvp-decisions.md`.

## Acceptance Criteria

- A matriz contem exatamente os 15 finais e usa somente atributos, reputacoes, contadores e flags definidos.
- Uma bateria de estados de teste confirma que cada final de prioridade 1-14 pode ser o primeiro elegivel; o caso sem elegibilidade retorna Caminho Equilibrado.
- Prioridades 3 e 13 nunca se sobrepoem devido ao limite Hacker Rep; prioridades 10 e 11 nunca se sobrepoem devido ao limite de missoes tecnicas.
- A avaliacao nao cria nem altera stats, reputacoes, flags ou contadores.
