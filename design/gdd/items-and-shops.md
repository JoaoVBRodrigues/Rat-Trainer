# GDD: Items and Shops

## Overview

Tres lojas oferecem equipamento funcional simples e um item de recuperacao. Roupas reveladoras, customizacao de vestuario com bonus e durabilidade ficam fora do MVP.

## Player Fantasy

O jogador escolhe investimentos pequenos que apoiam estudo, seguranca e recuperacao, sem transformar compras em uma arvore de equipamento.

## Detailed Design

### Catalogo MVP

| Item | Loja | Preco | Efeito |
|------|------|-------|--------|
| Kit de ferramentas | Oficina comunitaria | 25 Cr | +5 pontos percentuais em missoes fisicas/protecao; equipamento de mao |
| Casaco acolchoado | Loja geral | 20 Cr | +5 pontos percentuais em missoes fisicas/protecao; protecao fechada e apropriada para a idade |
| Adesivo de recuperacao | Clinica comunitaria | 10 Cr | Consumido ao usar; -15 Stress |

Cada personagem pode equipar no maximo um item de mao e uma protecao. Os consumiveis sao guardados em inventario. Nao ha bonus passivos de roupa, requisitos de atributo, venda de itens, durabilidade ou quebra.

### Compras e uso

- A interface permite visitar lojas entre escolhas de periodo; navegar ou comprar nao consome um periodo.
- Uma compra debita o saldo antes de adicionar o item; sem saldo suficiente, a transacao e recusada sem alteracoes.
- Comprar um equipamento ja possuido e recusado antes do debito; itens unicos equipados contam como possuidos.
- Trocar equipamento equipado nao custa creditos; o equipamento anterior volta ao inventario.
- Usar o adesivo reduz Stress em 15, limitado ao minimo 0, e consome uma unidade.

## Formulas

### Compra

`saldo_apos = saldo_antes - preco`, se `saldo_antes >= preco`; caso contrario a compra e recusada.

- Precos inteiros: 10, 20 ou 25 Cr; saldo minimo 0.
- Exemplo: 30 Cr menos um Kit de ferramentas de 25 Cr resulta em 5 Cr.
- Exemplo: 9 Cr para um Adesivo de 10 Cr: compra recusada e saldo continua 9 Cr.

### Recuperacao

`stress_apos = max(0, stress_antes - 15)`

- Stress antes/depois: 0-100.
- Exemplo: Stress 40 passa a 25.
- Exemplo: Stress 8 passa a 0; o item e consumido mesmo quando a recuperacao efetiva e menor que 15.

### Bonus de equipamento

`bonus_equipamento = bonus_ferramenta + bonus_protecao`

- Cada item equipado soma 5 pontos percentuais; maximo 10, aplicado ao teste definido em `auto-combat.md`.
- Exemplo: apenas ferramenta: +5 pontos percentuais.
- Exemplo: ferramenta e casaco: +10 pontos percentuais, ainda sujeito ao clamp de 5-95%.

## Edge Cases

- Itens nao reduzem Stress automaticamente; apenas o Adesivo de recuperacao pode ser usado para isso.
- O bonus de equipamento soma pontos percentuais a chance, nao altera STR, STA ou reputacoes.
- Nenhuma roupa e descrita ou ilustrada de forma sexualizada; itens de vestuario cobrem o corpo.
- Quantidade de consumiveis e limitada apenas pelo saldo e inventario; compras nao avancam o calendario.

## Dependencies

- `economy.md` e proprietario do saldo e da validacao de transacao.
- `auto-combat.md` consome os bonus de equipamento.
- `stats-and-stress.md` define Stress e clamp.
- `save-system.md` persiste inventario, equipamentos e consumiveis.
- `ux/main-screen.md` apresenta o acesso a lojas e equipamentos.

## Tuning Knobs

| Knob | Faixa segura | Inicial |
|------|--------------|---------|
| Bonus por equipamento | 0-5 pontos percentuais | 5 |
| Precos | 10-25 Cr | Conforme catalogo |
| Recuperacao por adesivo | 10-20 Stress | 15 |

## Acceptance Criteria

- A loja apresenta somente os tres itens desta tabela.
- Compra recusada nao altera saldo, inventario ou equipamento.
- Um equipamento de cada slot pode ser usado simultaneamente e o bonus total nunca excede 10 pontos percentuais.
- Usar um adesivo consome uma unidade e reduz Stress em ate 15.
- Comprar ou equipar itens nao avanca o calendario.
