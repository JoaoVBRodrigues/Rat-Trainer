# GDD: Auto-Combat

## Overview

Missoes fisicas/protecao sao resolvidas automaticamente por uma unica verificacao de sucesso. Nao ha combate manual, dano grafico, morte ou perda permanente de atributos.

## Player Fantasy

Nyx enfrenta riscos de forma taticamente legivel, com o equipamento e a preparacao influenciando a chance sem transformar conflito em espetaculo violento.

## Detailed Design

### Resolucao

1. Verificar os requisitos de atributo e equipamento da missao; se faltarem, bloquear o agendamento.
2. Carregar os atributos relevantes, equipamento equipado e dificuldade da missao.
3. Calcular a chance da opcao uma vez, limitada a 5-95%.
4. Sortear um inteiro uniforme de 0 a 99. A opcao e bem-sucedida se o resultado for menor que a chance; igualdade falha.
5. Em sucesso, aplicar somente a recompensa correspondente a opcao; em falha, nao conceder recompensa.
6. Concluir o periodo uma vez, qualquer que seja o resultado.

| Missao | Dificuldade | Inimigo |
|--------|-------------|---------|
| Ruínas Industriais | 35 | Rastreador |
| Drones | 50 | Drone Patrulha |
| Infiltração | 60 | Sentinela |

O equipamento da tabela em `items-and-shops.md` fornece +5 pontos percentuais por item aplicavel, ate +10. Requisitos de equipamento nao sao satisfeitos por itens inexistentes; o equipamento inicial permanece vazio.

### Efeitos

- A atividade fisica acrescenta +4 Stress exatamente uma vez, qualquer que seja a opcao.
- Deltas adicionais por opcao: Lutar +3 em sucesso/+6 em falha; Conversar +2/+4; Fugir +2/+6; Esconder +1/+6.
- Derrota em Lutar mostra uma cena nao grafica de ORAC levando Nyx para casa. STA e demais atributos nao diminuem.
- Falhas em qualquer opcao sao nao letais, nao alteram atributos ou registros, e ainda consomem um periodo.

### Opcoes de Encontro

A tela de encontro apresenta quatro opcoes. Cada opcao consome o periodo e retorna um resultado distinto.

| Opcao | Resolucao | Recompensa | Penalidade |
|-------|-----------|------------|------------|
| Lutar | Teste STR/STA | Recompensas completas da missao em caso de sucesso | +6 Stress adicional em falha |
| Conversar | Teste CHA/INT | Metade dos creditos, +1 CHA, +2 Social Rep | +4 Stress adicional em falha |
| Fugir | Teste STA/REF | Nenhuma | +6 Stress adicional em falha |
| Esconder | Teste INT/CHA | Nenhuma | +6 Stress adicional em falha |

- Todas as opcoes usam uma rolagem uniforme de 0-99 e a mesma formula; cada opcao escolhe seu par de atributos.
- Conversar concede metade dos creditos da missao arredondada para baixo, +1 CHA e +2 Social Rep somente em sucesso.
- Somente sucesso em Lutar ou Conversar rola a chance de 25% para obter uma unidade de `adesivo_recuperacao`.
- Qualquer opcao consome exatamente um periodo. Nenhuma opcao cria `criminal_record`.

## Formulas

### Chance de vitoria

`chance = clamp(50 + floor((primario - dificuldade) / 2) + floor(suporte / 10) + bonus_equipamento, 5, 95)%`

- Pares: Lutar STR/STA; Conversar CHA/INT; Fugir STA/REF; Esconder INT/CHA. Atributos: 0-100; dificuldade: 35-60.
- Cada item aplicavel equipado da +5 pontos percentuais, no maximo +10.
- Um resultado aleatorio uniforme de 0-99 vence se `resultado < chance`; igualdade falha.
- Exemplo: Lutar com STR 60, STA 40, dificuldade 50 e sem equipamento: `50 + floor(10/2) + 4 = 59%`.
- Exemplo: Esconder com INT 15, CHA 20, dificuldade 60 e bonus 10: `50 + floor(-45/2) + 2 + 10 = 39%` (floor(-22.5) = -23).
- Limites: o clamp impede chance menor que 5% ou maior que 95%; nenhum combate e garantido ou impossivel.

### Recompensas e Penalidades por Opcao

| Opcao | Sucesso | Falha |
|-------|---------|-------|
| Lutar | Recompensas completas da missao (ver activities.md) +3 Stress | +6 Stress adicional, sem recompensa |
| Conversar | Metade dos creditos (piso), +1 CHA, +2 Social Rep, +2 Stress | +4 Stress adicional, sem recompensa |
| Fugir | Nenhuma, +2 Stress | +6 Stress adicional, sem recompensa |
| Esconder | Nenhuma, +1 Stress | +6 Stress adicional, sem recompensa |

- A atividade soma +4 Stress a tabela. Stress final e limitado a 100.
- Sucesso em Lutar ou Conversar tem chance de 25% de conceder uma unidade de `adesivo_recuperacao`; outras opcoes e falhas nunca concedem item.
- Derrota nao reduz atributos, nao cria crime e consome exatamente um periodo.

## Edge Cases

- O par de atributos da opcao e lido antes da rolagem, apos qualquer ganho ja aplicado no periodo.
- Sem equipamento, `bonus_equipamento=0`.
- Equipamento ausente ou nao equipado nunca recebe bonus.
- Uma falha ou erro de resolucao nao consome o encontro pendente, nao concede recompensa e nao avanca o calendario.
- O encontro pendente preserva o resultado e os metadados originais; uma conclusao aplica Stress/recompensas uma unica vez e avanca um periodo.
- Salvar ou retomar durante um encontro aberto nao faz parte desta entrega.
- O efeito de contador `missoes_tecnicas_concluidas` e aplicado a partir dos dados da missao bem-sucedida.
- Stress resultante e limitado a 100; nao ha reducao permanente de STA ou HP.

## Dependencies

- `activities.md` solicita o combate e concede recompensas exclusivamente em caso de vitoria.
- `stats-and-stress.md` define STR, STA, Stress e clamp.
- `items-and-shops.md` fornece os bonus de equipamento.
- `calendar-and-turns.md` consome exatamente um periodo.
- `save-system.md` persiste o resultado e impede duplicacao.

## Tuning Knobs

| Knob | Faixa | Inicial |
|------|-------|---------|
| Dificuldade por missao | 35-60 | 35/50/60 |
| Bonus total de equipamento | 0-10 pontos percentuais | Conforme equipamento |
| Stress adicional | 0-6 | Conforme opcao e resultado |
| Chance de item | 0-100% | 25% em sucesso de Lutar/Conversar |

## Acceptance Criteria

- Todas as quatro opcoes usam os pares STR/STA, CHA/INT, STA/REF e INT/CHA com chance inteira entre 5 e 95%.
- Uma rolagem igual a chance falha; seeds iguais produzem o mesmo resultado.
- Cada opcao aplica o Stress aprovado; falha nao reduz atributos nem cria crime e consome exatamente um periodo.
- Lutar e Conversar concedem as recompensas aprovadas e rolam uma unica chance de 25% para o adesivo.
- Um encontro concluido avanca o calendario uma vez e mantem os metadados do periodo original.
