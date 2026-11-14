# GDD: Monsters

## Overview

Três inimigos específicos, um por missão física. Cada inimigo define a dificuldade da missão e fornece um `enemy_id` para a resolução do combate. Não há combate manual, dano gráfico, morte ou perda permanente de atributos.

## Player Fantasy

Nyx enfrenta riscos de forma taticamente legível, com o equipamento e a preparação influenciando a chance sem transformar conflito em espetáculo violento.

## Detailed Design

### Inimigos

| ID | Nome | Tipo | Dificuldade | Missão | Requisito | Equipamento exigido |
|----|------|------|-------------|--------|-----------|--------------------|
| `rastreador` | Rastreador | Patrulha | 35 | Ruínas Industriais | STR >= 15 | Nenhum |
| `drone_patrulha` | Drone Patrulha | Máquina | 50 | Drones | INT >= 27 | `kit_ferramentas` |
| `sentinela` | Sentinela | Defesa | 60 | Infiltração | STR >= 25 | `kit_ferramentas`, `casaco_acolchoado` |

As descricoes de cena sao placeholders nao graficos. Equipamento inicial e vazio; requisito ausente bloqueia a missao sem conceder item.

### Resolução

1. Carregar o `enemy_id` da missão selecionada.
2. Buscar a dificuldade correspondente em `monsters.json`.
3. Calcular chance para a opcao escolhida, limitada a 5-95%.
4. Sortear um inteiro uniforme de 0 a 99. A opcao tem sucesso se o resultado for menor que a chance; igualdade falha.
5. Aplicar Stress e, apenas em sucesso, a recompensa definida para a opcao.
6. Concluir o periodo uma vez; falhas sao nao letais e nao criam `criminal_record`.

### Efeitos

- A atividade fisica acrescenta +4 Stress uma vez. O delta adicional depende da opcao e do resultado, conforme `auto-combat.md`.
- Derrota em Lutar mostra ORAC levando Nyx para casa em cena nao grafica. STA e demais atributos nao diminuem.
- Falhas em qualquer opcao nao sao letais, nao concedem recompensa e nao alteram ETH ou registros.
- Somente sucesso em Lutar ou Conversar pode conceder `adesivo_recuperacao`, com chance de 25%.

## Formulas

### Chance de vitória

`chance = clamp(50 + floor((primario - dificuldade) / 2) + floor(suporte / 10) + bonus_equipamento, 5, 95)%`

- Os pares sao Lutar STR/STA, Conversar CHA/INT, Fugir STA/REF e Esconder INT/CHA; atributos: 0-100 e dificuldade: 35-60.
- Cada item aplicavel equipado da +5 pontos percentuais, no maximo +10.
- Um resultado aleatorio uniforme de 0-99 tem sucesso se `resultado < chance`; igualdade falha.
- Exemplo: STR 60, STA 40, dificuldade 50 e sem equipamento: `50 + floor(10/2) + 4 = 59%`.
- Exemplo: INT 15, CHA 20, dificuldade 60, bonus 10: `50 + floor(-45/2) + 2 + 10 = 39%` (floor(-22.5) = -23).
- Limites: o clamp impede chance menor que 5% ou maior que 95%; nenhum combate é garantido ou impossível.

## Edge Cases

- Valores de STR e STA são lidos após os ganhos do período e antes da verificação de doença do fim do período.
- Sem equipamento, `bonus_equipamento=0`.
- Equipamento ausente ou não equipado nunca recebe bonus.
- Uma falha ou erro de resolucao preserva o encontro pendente e nao avanca o calendario.
- Um resultado concluido preserva os metadados originais e aplica Stress/recompensas uma unica vez.
- Salvar/retomar durante encontro aberto fica fora desta entrega.
- Efeitos de contador, como `missoes_tecnicas_concluidas` em Drones, sao aplicados pelos dados da missao.
- Stress resultante é limitado a 100; não há redução permanente de STA ou HP.

## Dependencies

- `activities.md` solicita o combate e concede recompensas exclusivamente em caso de vitória.
- `auto-combat.md` define a fórmula de chance, as opções de encontro e as penalidades.
- `stats-and-stress.md` define STR, STA, Stress e clamp.
- `items-and-shops.md` fornece os bonus de equipamento.
- `calendar-and-turns.md` consome exatamente um período.
- `save-system.md` persiste o resultado e impede duplicação.

## Tuning Knobs

| Knob | Faixa | Inicial |
|------|-------|---------|
| Dificuldade por inimigo | 35-60 | 35/50/60 |
| Bonus total de equipamento | 0-10 pontos percentuais | Conforme equipamento |
| Stress adicional em vitória | 0-5 | 3 |
| Stress adicional em derrota | 3-10 | 6 |

## Acceptance Criteria

- Todas as quatro opcoes usam os pares aprovados e chance inteira de 5-95%.
- Cada opcao aplica o Stress aprovado; falha nao reduz atributos, nao cria crime e consome exatamente um periodo.
- Um encontro concluido avanca o calendario uma vez e preserva o resultado original.
- Cada inimigo está associado a exatamente uma missão física.