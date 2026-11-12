# GDD: Stats and Stress

## Overview

Seis atributos medem as capacidades e escolhas de Nyx. Stress e um medidor separado de 0 a 100. Todos os valores numericos ficam limitados a 0-100.

## Player Fantasy

O desenvolvimento reflete as atividades escolhidas, nao uma barra de moralidade que julga autonomia. Etica (ETH) representa escolhas eticas; fugir ou buscar seguranca nao e crime por si so.

## Detailed Design

| Atributo | Simbolo | Inicial | Uso |
|----------|---------|---------|-----|
| Forca | STR | 15 | Missoes fisicas e protecao. |
| Inteligencia | INT | 15 | Estudo tecnico, hacking e missoes tecnicas. |
| Carisma | CHA | 15 | Negociacao, comunicacao e apoio comunitario. |
| Refinamento | REF | 15 | Artes, projeto e apresentacoes. `EGG` nao e um identificador valido. |
| Resistencia | STA | 20 | Defesa em combate e tolerancia ao Stress. |
| Etica | ETH | 50 | Decisoes eticas e condicoes de finais; nao define crime automaticamente. |
| Stress | Stress | 0 | Medidor separado de fadiga; nao e atributo nem reputacao. |

Ganhos e perdas de atributos sao aplicados depois da atividade e limitados a 0-100. Reputacoes Fighter, Social e Hacker sao mantidas separadamente e limitadas a 0-100; seus valores iniciais sao 0.

### Stress e doenca

- Atividades e combates fornecem deltas de Stress; descanso reduz Stress. `stats-and-stress.md` e o proprietario do saldo e da regra de doenca.
- Ao fim de cada periodo, se `Stress >= 60 + floor(STA / 5)`, Nyx entra em estado de doenca.
- Enquanto a condicao permanecer, Missoes ficam indisponiveis. O tempo continua e a escolha do periodo segue disponivel; nao ha turno perdido.
- O estado de doenca termina quando Stress fica abaixo do limiar atual.
- Fuga e sobrevivencia nao reduzem ETH nem criam `criminal_record`; essa flag so vem de uma escolha ilegal explicita.

## Formulas

### Clamp de atributo

`novo_valor = clamp(valor_atual + delta, 0, 100)`

- `delta` e fornecido pelo sistema que concede ou remove pontos.
- Limites: atributo final 0-100.
- Exemplo: INT 96 recebendo +12 resulta em `clamp(108,0,100)=100`.
- Exemplo: ETH 3 recebendo -5 resulta em `clamp(-2,0,100)=0`.

### Limiar de doenca

`limiar = 60 + floor(STA / 5)`

- `STA`: 0-100; limiar resultante: 60-80. A doenca inicia quando Stress e maior ou igual ao limiar.
- Exemplo: STA 20 da limiar 64; Stress 64 inicia doenca.
- Exemplo: STA 100 da limiar 80; Stress 79 nao inicia doenca.

### Stress do periodo

`stress_final = clamp(stress_inicial + delta_atividade + delta_combate, 0, 100)`

- Os deltas sao inteiros e pertencem aos GDDs de atividades e auto-combate; recuperacao e um delta negativo.
- Exemplo: Stress 18, atividade +5 e combate +4 resulta em 27.
- Exemplo: Stress 8, descanso -15 resulta em 0 depois do clamp.

## Edge Cases

- Em Stress 100, novos deltas positivos nao excedem 100; recuperacao pode reduzir Stress normalmente.
- Em Stress zero, recuperacoes adicionais continuam em zero.
- Se STA mudar, o limiar e recalculado no fim do proximo periodo.
- Doenca nao remove periodo, nao altera ETH e nao cria flags de crime.
- Atributos e reputacoes de uma carga de save fora de 0-100 tornam o save invalido; nao os corrigir silenciosamente.

## Dependencies

- `activities.md` e `auto-combat.md` fornecem deltas de atributo e Stress.
- `calendar-and-turns.md` define o momento de avaliar doenca e avancar o periodo.
- `economy.md` e proprietario dos precos de recuperacao; este GDD define apenas o efeito de Stress.
- `events.md` e `endings.md` consomem atributos, reputacoes e flags, sem altera-los fora das suas regras de recompensa.
- `save-system.md` persiste estes valores.

## Tuning Knobs

| Knob | Faixa segura | Efeito |
|------|--------------|--------|
| Limiar base de Stress | 60; alterar requer atualizar `mvp-decisions.md` | Frequencia de doenca. |
| Divisor de STA | 5; alterar requer atualizar `mvp-decisions.md` | Quanto STA amplia tolerancia. |
| Recuperacao por descanso | 15-20 pontos por periodo | Ritmo de recuperacao; o efeito adotado pelo MVP e -15. |

## Acceptance Criteria

- Todos os seis atributos usam os nomes e valores iniciais desta tabela.
- ETH inicia em 50; REF e o unico identificador do atributo de Refinamento.
- Ganhos e perdas nunca deixam atributos, Stress ou reputacoes fora de 0-100.
- Com STA 20, Stress 64 inicia doenca; com STA 100, o limiar e 80.
- Doenca bloqueia Missoes, mas nao remove nem acrescenta periodos.