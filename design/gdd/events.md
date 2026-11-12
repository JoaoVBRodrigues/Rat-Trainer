# GDD: Events

## Overview

O MVP tem exatamente 12 eventos fixos, quatro por ano, nos periodos 3 dos meses 3, 6, 9 e 12, mais um pool finito de tres encontros aleatorios. Cada evento substitui a atividade daquele periodo; nenhum evento fixo faz uma rolagem aleatoria.

## Player Fantasy

Os eventos mostram como Nyx e sua comunidade enfrentam vigilancia, escassez e oportunidades sem tratar autonomia como crime automatico.

## Detailed Design

### Calendario e escolhas

| ID | Ano/Mes/Periodo | Evento | Opcao A | Opcao B |
|----|-----------------|--------|---------|---------|
| E01 | 1/3/3 | Mutirao do Mercado | Ajudar: +2 CHA, +5 Social Rep, +3 ETH, `community_help` | Descansar: -5 Stress |
| E02 | 1/6/3 | Feira Maker | Apresentar projeto: +2 INT, +5 Hacker Rep | Visitar bancas: +10 Cr |
| E03 | 1/9/3 | Repetidor Comunitario | Reparar para o bairro: +2 INT, +5 Hacker Rep, +3 ETH, `community_help` | Conversar com moradores: +2 CHA, +5 Social Rep |
| E04 | 1/12/3 | Festival de Luzes | Apresentacao artistica: +2 REF, +5 Social Rep | Ajudar na organizacao: +2 CHA, `community_help` |
| E05 | 2/3/3 | Oficina Aberta | Testar prototipo: +2 INT, +5 Hacker Rep | Ensinar criancas: +2 CHA, +5 Social Rep, +3 ETH, `community_help` |
| E06 | 2/6/3 | Falha de Drones | Reportar falha: +2 INT, +5 Hacker Rep | Desviar uma unidade ilegalmente: +10 Cr, -5 ETH, `criminal_record` |
| E07 | 2/9/3 | Assembleia do Bairro | Mediar: +2 CHA, +5 Social Rep, +3 ETH, `community_help` | Preparar cartazes: +2 REF |
| E08 | 2/12/3 | Troca de Inverno | Contribuir: +3 ETH, `community_help`, +5 Social Rep | Guardar materiais recuperaveis: +10 Cr |
| E09 | 3/3/3 | Desafio de Tecnologia Juvenil | Participar: +2 INT, +5 Hacker Rep | Apoiar outra equipe: +2 CHA, `community_help` |
| E10 | 3/6/3 | Alerta na Passarela | Coordenar ajuda: +2 CHA, +5 Social Rep, +3 ETH, `community_help` | Fazer reparo seguro: +2 INT, +5 Hacker Rep |
| E11 | 3/9/3 | Arquivo da Cidade | Publicar uma historia: +2 REF, +5 Social Rep | Verificar dados: +2 INT, +5 Hacker Rep |
| E12 | 3/12/3 | Escolha de Caminho | Permanecer ligada a comunidade: +2 CHA, +3 ETH, `community_help` | Planejar desaparecer do sistema: `disappear_from_society` |

Cada escolha resolve uma vez e consome um periodo. Eventos fixos marcam seu ID como concluido; encontros aleatorios registram o par periodo/ID e podem voltar a ocorrer em outros periodos. Nenhum evento se soma a uma atividade.

### Encontros aleatorios

Fora dos periodos de evento fixo, uma verificacao pode gerar no maximo um encontro de um pool fechado de tres eventos:

| ID | Evento | Opcao A | Opcao B |
|----|--------|---------|---------|
| R01 | Mercador itinerante | Comprar Kit de ferramentas por 25 Cr (opcao indisponivel se ja possuido) | Recusar |
| R02 | Pedido de ajuda no bairro | Ajudar: +2 CHA, +5 Social Rep, `community_help` | Recusar |
| R03 | Repetidor vulneravel | Reportar com seguranca: +2 INT, +5 Hacker Rep | Acessar ilegalmente: +10 Cr, -5 ETH, `criminal_record` |

Se a verificacao ativar um encontro, escolher uma das tres cartas com probabilidade uniforme. Eventos aleatorios tambem ocupam o periodo atual. Os tres eventos e seus resultados sao authored/finitos; nao ha geracao procedural de conteudo.

### Regras de flags

- `community_help`: concedida somente nas escolhas identificadas como ajuda comunitaria acima.
- As sete opcoes comunitarias E01-A, E03-A, E05-B, E07-A, E08-A, E10-A e E12-A concedem +3 ETH cada, alem dos efeitos listados. Os ganhos sao limitados a 100.
- `criminal_record`: concedida somente ao escolher uma opcao explicitamente ilegal (E06-B ou R03-B).
- `tech_experiments`: concedida somente por uma sessao de Tecnologia ou missao explicitamente experimental, conforme `activities.md`.
- `disappear_from_society`: concedida somente por E12-B. Nao implica crime nem altera ETH.
- Flags sao booleanas cumulativas e nao sao removidas por eventos posteriores.

### Resolução

Todos os efeitos de atributo, reputacao e Stress usam os clamps de `stats-and-stress.md`. Creditos de evento sao entradas unicas definidas nas tabelas. Eventos fixos nao fazem rolagem; apenas a verificacao de encontros aleatorios usa atributo.

## Formulas

### Periodo do evento

`evento_fixo = (periodo == 3) e (mes em {3, 6, 9, 12})`

- Ano: 1-3; mes: 1-12; periodo: 1-3. Existem quatro eventos em cada ano e doze no total.
- Exemplo: Ano 2, mes 6, periodo 3 ativa E06.
- Exemplo: Ano 2, mes 6, periodo 2 nao ativa evento; o jogador escolhe uma atividade normal.

### Probabilidade de encontro aleatorio

`chance = clamp(5 + floor(max(INT, CHA, REF) / 10), 5, 15)%`

- A verificacao ocorre uma vez em cada periodo sem evento fixo; usa um inteiro uniforme de 0-99 e ativa encontro se `resultado < chance`.
- Exemplo: maior valor entre INT/CHA/REF igual a 75 resulta em `5 + floor(75/10) = 12%`.
- Exemplo: maior valor 100 resulta em 15%; maior valor 0 resulta em 5%.
- Se houver encontro, sorteia-se uma das tres cartas R01-R03 com chance igual; nao se repetem cartas por periodo.

### Etica de escolhas comunitarias

`ETH_novo = clamp(ETH_atual + delta_ETH, 0, 100)`

- `delta_ETH=+3` somente nas sete opcoes comunitarias listadas; opcoes sem delta especificado alteram ETH em 0. Atos ilegais E06-B e R03-B aplicam -5 ETH.
- Exemplo: ETH 62 apos E10-A passa a `clamp(62+3,0,100)=65`.
- Exemplo: ETH 50 apos E01-A, E05-B e E07-A passa a `50+3+3+3=59`.

## Edge Cases

- Uma ocorrencia ja concluida nunca e executada de novo ao carregar um save; um tipo aleatorio pode ocorrer em outro periodo.
- Evento fixo tem prioridade sobre qualquer atividade; o periodo nao fica disponivel para uma segunda escolha.
- Opcoes sem recompensa financeira nao podem criar credito; nenhuma escolha deixa saldo negativo.
- A escolha ilegal e opcional e explicitamente rotulada; fugir, esconder-se ou desaparecer nao cria `criminal_record`.
- Uma opcao comunitaria aumenta ETH somente se estiver explicitamente marcada; recusar ou escolher a alternativa nao marcada concede zero ETH.
- E12 e o ultimo periodo da campanha; apos a escolha, o jogo avalia imediatamente os finais.

## Dependencies

- `calendar-and-turns.md` determina data, periodo ocupado e fim da campanha.
- `stats-and-stress.md` define atributos, reputacoes, Stress e flags relacionadas a doenca.
- `economy.md` credita as recompensas financeiras E02-B, E06-B e E08-B.
- `endings.md` consome as quatro flags de percurso.
- `save-system.md` persiste os IDs concluidos e as flags.

## Tuning Knobs

Os doze eventos, suas datas e os gatilhos das flags sao escopo fechado do MVP. Ganhos numericos podem ser balanceados em playtest, mantendo limites 0-100 e sem alterar quais escolhas concedem ETH ou flags.

## Acceptance Criteria

- Existem exatamente 12 eventos fixos nos periodos especificados, quatro por ano, e tres cartas aleatorias finitas.
- Cada evento ocupa um periodo e oferece exatamente uma escolha resolvida.
- `community_help` e `disappear_from_society` sao concedidas somente pelas escolhas descritas; `criminal_record` somente por E06-B/R03-B; `tech_experiments` segue `activities.md`.
- Encontros aleatorios usam somente o pool fechado R01-R03 e a chance limitada de 5-15%.
- E12 e resolvido em Ano 3, mes 12, periodo 3 e precede a avaliacao dos finais.
