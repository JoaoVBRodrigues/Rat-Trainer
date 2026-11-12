# GDD: Auto-Combat

## Overview

Missoes fisicas/protecao sao resolvidas automaticamente por uma unica verificacao de sucesso. Nao ha combate manual, dano grafico, morte ou perda permanente de atributos.

## Player Fantasy

Nyx enfrenta riscos de forma taticamente legivel, com o equipamento e a preparacao influenciando a chance sem transformar conflito em espetaculo violento.

## Detailed Design

### Resolucao

1. Carregar STR, STA, equipamento equipado e dificuldade da missao.
2. Calcular chance uma vez, limitada a 5-95%.
3. Sortear um inteiro uniforme de 0 a 99. O combate e vencido se o resultado for menor que a chance.
4. Em vitoria, conceder as recompensas da missao em `activities.md`.
5. Em derrota, consumir o periodo e aplicar Stress; nao conceder recompensa ou `criminal_record`.

| Missao | Dificuldade |
|--------|-------------|
| Apoio fisico local | 35 |
| Protecao de rota comunitaria | 50 |
| Escolta de equipamento | 60 |

O equipamento da tabela em `items-and-shops.md` fornece bonus de chance; apenas uma ferramenta e uma protecao podem estar equipadas.

### Efeitos

- O sistema de atividades acrescenta +4 Stress pela missao fisica, independentemente do resultado.
- Este sistema retorna somente o delta adicional de combate: +3 Stress em vitoria e +6 em derrota.
- Derrota mostra a cena nao grafica de ORAC levando Nyx para casa. STA e demais atributos nao diminuem.
- Fugir ou esconder-se em uma tela de encontro evita a resolucao de combate, encerra a missao sem recompensa e nao altera ETH nem registros.

## Formulas

### Chance de vitoria

`chance = clamp(50 + floor((STR - dificuldade) / 2) + floor(STA / 10) + bonus_equipamento, 5, 95)%`

- STR e STA: 0-100. Dificuldade: 35-60. Bonus: soma de bonus de equipamento, maximo 10 pontos percentuais.
- Um resultado aleatorio uniforme de 0-99 vence se `resultado < chance`.
- Exemplo: STR 60, STA 40, dificuldade 50, sem equipamento: `50 + floor(10/2) + 4 = 59%`.
- Exemplo: STR 15, STA 20, dificuldade 60, bonus 10: `50 + floor(-45/2) + 2 + 10 = 39%` (floor(-22.5) = -23).
- Limites: o clamp impede chance menor que 5% ou maior que 95%; nenhum combate e garantido ou impossivel.

## Edge Cases

- Valores de STR e STA sao lidos apos os ganhos do periodo e antes da verificacao de doenca do fim do periodo.
- Sem equipamento, `bonus_equipamento=0`.
- Equipamento ausente ou nao equipado nunca recebe bonus.
- Um erro de resolucao ou save nao pode conceder recompensas duplicadas; usar o ID do periodo/missao como idempotency key.
- O resultado deste sistema e somente desfecho e delta adicional de Stress; nao aplica o +4 da atividade, nao paga recompensas e nao altera contadores.
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
| Stress adicional em vitoria | 0-5 | 3 |
| Stress adicional em derrota | 3-10 | 6 |

## Acceptance Criteria

- A chance calculada e sempre um inteiro entre 5 e 95%.
- O resultado usa `rng_state` persistido em `save-system.md`; uma recarga antes do autosave repete o mesmo resultado.
- Vitoria concede recompensas de combate uma unica vez; derrota nao concede nenhuma.
- Derrota nao reduz atributos, nao cria crime e consome exatamente um periodo.
- Stress de combate e aplicado e limitado pelo sistema de Stress.
