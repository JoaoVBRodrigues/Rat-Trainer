# GDD: Activities

## Overview

Cada periodo permite uma atividade: estudo, trabalho supervisionado, missao ou lazer. Valores de atributos sao limitados a 0-100; salarios e custos sao debitados pelo sistema de economia.

## Player Fantasy

As escolhas mostram como Nyx cresce por estudo, contribuicao e descanso sem transformar uma adolescente em trabalhadora adulta ou combatente manual.

## Detailed Design

### Estudo: tres cursos

Cada curso tem XP proprio e niveis 1-3. O ganho usa `base + level * 3`; a tabela inclui o resultado final de cada nivel.

| Curso | Atributo(s) | Nivel 1 | Nivel 2 | Nivel 3 | Custo base |
|-------|-------------|---------|---------|---------|------------|
| Tecnologia | INT | +12 | +15 | +18 | 8 Cr |
| Comunicacao e escrita | CHA +8 / REF +5 | +8 / +5 | +11 / +8 | +14 / +11 | 6 Cr |
| Artes e projeto | REF | +8 | +11 | +14 | 5 Cr |

O custo por sessao e `custo_base * nivel`. O valor e cobrado antes de conceder ganhos ou XP.

No curso Tecnologia, o jogador pode marcar a sessao como **Experimentacao tecnica**. A sessao usa o mesmo custo, ganhos e XP de Tecnologia; ao concluir, define `tech_experiments=true`. Uma missao tecnica tambem pode ser selecionada como **Experimentacao tecnica**; se for bem-sucedida, define a mesma flag. A opcao e explicita e nao e concedida por cursos de comunicacao/artes.

Cada sessao de estudo acrescenta +2 Stress, inclusive experimentacao tecnica. Antes da confirmacao, a UI mostra esse valor; qualquer delta de Stress nao especificado para uma escolha e zero.

### Trabalho supervisionado: tres tarefas

Todas as tarefas sao apropriadas para a idade e supervisionadas; nao existem empregos de seguranca armada ou telemarketing no MVP.

| Tarefa | Efeito por sessao | Salario base | Stress |
|--------|-------------------|--------------|--------|
| Reparo leve | +2 INT | 15 Cr | +3 |
| Entrega assistida | +2 CHA | 20 Cr | +3 |
| Apoio comunitario | +2 CHA | 25 Cr | +2 |

Uma promocao a nivel 2 ocorre depois de quatro meses consecutivos com ao menos uma sessao da mesma tarefa em cada mes. Ao fechar cada mes, cada tarefa usada no mes incrementa sua sequencia uma vez; uma tarefa nao usada zera sua sequencia. O nivel 2 permanece mesmo que a sequencia zere. A promocao aumenta o salario por sessao em 50%; nivel maximo 2.

Ao resolver uma sessao de trabalho, marcar a tarefa em `job_tasks_used_current_month=true`. No fechamento do periodo 3, incrementar `job_streaks[tarefa]` uma vez se marcada, zerar a streak se nao marcada, promover ao atingir quatro e zerar todos os marcadores mensais. O snapshot/autosave do periodo inclui marcadores e streaks.

### Missao: tres tipos

| Tipo | Resolucao | Atributo de teste | Stress da atividade | Recompensas em caso de sucesso |
|------|-----------|-------------------|-----------------------|-------------------------------|
| Fisica/protecao | Combate automatico | STR | +4, mais o delta de combate | 25 Cr, +2 STR, +5 Fighter Rep |
| Tecnica | Teste de sucesso | INT | +3 | 30 Cr, +2 INT, +5 Hacker Rep |
| Apoio comunitario | Teste de sucesso | CHA | +3 | 20 Cr, +2 CHA, +5 Social Rep, +2 ETH e flag `community_help` |

Uma missao falha ainda consome o periodo, mas nao concede salario, pontos de atributo, reputacao, contador de missao tecnica ou flag. Uma missao tecnica bem-sucedida incrementa `missoes_tecnicas_concluidas` em 1. Fugir de combate com sucesso tambem encerra a missao sem recompensa e nao cria `criminal_record`.

### Lazer: duas opcoes

| Opcao | Efeito | Custo |
|-------|--------|-------|
| Descanso | -15 Stress | 0 Cr |
| Passeio comunitario | -5 Stress, +2 CHA | 0 Cr |

Lazer nao altera ETH automaticamente. Recuperacao paga em clinica e definida em `items-and-shops.md`.

### Niveis e XP

Cada curso acompanha XP separadamente. Uma sessao concluida concede 10 XP; o nivel usado na sessao e o nivel anterior ao ganho de XP. Trabalho tem apenas a promocao por meses consecutivos. Missoes nao tem niveis.

## Formulas

### Ganho e custo do curso

`ganho = base_ganho + 3 * nivel`
`custo = custo_base * nivel`

| Curso | base_ganho | custo_base |
|-------|------------|------------|
| Tecnologia | 9 INT | 8 Cr |
| Comunicacao e escrita | 5 CHA e 2 REF | 6 Cr |
| Artes e projeto | 5 REF | 5 Cr |

- Nivel: 1-3; ganho e limitado pela faixa do atributo 0-100. Custo: 5-24 Cr.
- Exemplo: Tecnologia nivel 1 da `9 + 3*1 = 12 INT` e custa `8*1 = 8 Cr`.
- Exemplo: Tecnologia nivel 2 da `9 + 3*2 = 15 INT` e custa `8*2 = 16 Cr`; esses sao os valores da tabela.

### XP e nivel

`nivel = 1 se XP < 100; 2 se 100 <= XP < 250; 3 se XP >= 250`

- XP e inteiro, minimo 0 e maximo util 250; nivel maximo 3.
- Exemplo: 10 sessoes de tecnologia concedem 100 XP e desbloqueiam nivel 2.
- Exemplo: 25 sessoes concedem 250 XP e desbloqueiam nivel 3.

### Promocao

`salario = floor(salario_base * multiplicador)`

- Multiplicador: 1.0 no nivel 1 e 1.5 no nivel 2; creditos sao inteiros e arredondados para baixo.
- Exemplo: reparo leve no nivel 2 paga `floor(15*1.5)=22 Cr` por sessao.
- Exemplo: entrega assistida no nivel 2 paga `floor(20*1.5)=30 Cr`.

### Sucesso de missao sem combate

`chance = clamp(50 + (atributo_relevante - 50) + floor(ETH / 10), 5, 95)%`

- `atributo_relevante`: INT ou CHA, de 0-100; ETH: 0-100. O limite impede sucesso garantido ou impossivel.
- Exemplo: INT 65 e ETH 40 dao `50+15+4=69%`.
- Exemplo: CHA 0 e ETH 0 dao 5% depois do clamp; CHA 100 e ETH 100 dao 95%.
- Uma unica rolagem uniforme de 0-99 determina o resultado; sucesso se a rolagem for menor que a chance.

### Stress por atividade

`stress_final = clamp(stress_inicial + stress_atividade + stress_combate + stress_evento, 0, 100)`

- Estudo: +2; trabalho: valor da tabela; lazer: valor da tabela; missao tecnica/comunitaria: +3; fisica: +4 antes do delta de combate. Valores nao especificados sao 0.
- Exemplo: Stress 20, curso +2 resulta em 22.
- Exemplo: Stress 57, missao tecnica +3 resulta em 60; a verificacao de doenca usa este estado final.
- Exemplo: Stress 58, missao fisica vencida (+4 atividade e +3 combate) resulta em 65 antes do clamp.

## Edge Cases

- Atividade paga fica indisponivel se o saldo for insuficiente; nenhum saldo negativo e criado.
- Uma promocao ocorre uma vez e nunca ultrapassa nivel 2.
- Uma tarefa usada em dois periodos do mesmo mes conta como um mes, nao dois; o marcador do mes e persistido a cada autosave.
- XP que ultrapasse 250 e limitado a 250.
- Ganhos de atributos sao limitados a 100; ganhos de reputacao seguem o clamp de 0-100.
- `missoes_tecnicas_concluidas` incrementa somente em uma missao tecnica bem-sucedida; falhas e fugas nao incrementam.
- `tech_experiments` e definida somente ao concluir uma sessao de Tecnologia marcada como Experimentacao tecnica ou uma missao explicitamente rotulada como experimental.
- Stress de estudo e missao segue a tabela e a formula; efeitos nao especificados sao zero.
- Se Nyx estiver doente, a categoria Missao fica indisponivel ate Stress cair abaixo do limiar.

## Dependencies

- `calendar-and-turns.md` fornece os 108 periodos e a ordem de resolucao.
- `stats-and-stress.md` fornece atributos, clamp, Stress e doenca.
- `economy.md` debita custos e credita salarios e recompensas.
- `events.md` pode ocupar um periodo; uma opcao de evento nao se soma a uma atividade.
- `save-system.md` persiste XP, promocao e historico de missoes.
- `auto-combat.md` resolve o resultado fisico e acrescenta somente o Stress de combate, sem duplicar o delta de atividade.

## Tuning Knobs

| Knob | Faixa segura | Efeito |
|------|--------------|--------|
| XP por sessao de curso | 5-15; inicial 10 | Ritmo para niveis 2 e 3. |
| Ganho base por curso | 2-12 por atributo | Progressao; sempre limitar atributo a 100. |
| Salarios base | 10-25 Cr por sessao | Acesso a cursos e itens; fonte em `economy.md`. |
| Teste de sucesso | 5-95% | Risco das missoes sem combate. |
| Promocao | 4 meses consecutivos; faixa 3-6 | Progressao de trabalho; nivel maximo 2. |
| Stress de estudo/missao | Estudo +2; missao tecnica/comunitaria +3; fisica +4 antes do combate | Carga de atividade e limiar de doenca. |

## Acceptance Criteria

- Uma atividade concluida consome exatamente um periodo.
- Cada curso concede os ganhos e custos da tabela para os tres niveis.
- 10 sessoes de um curso desbloqueiam nivel 2; 25 desbloqueiam nivel 3.
- Uma tarefa de trabalho so promove apos quatro meses consecutivos com atividade registrada.
- Recarregar um save entre periodos e fechar o mes produz a mesma streak que concluir o mes sem recarregar.
- Cada tipo de atividade aplica exatamente o delta de Stress especificado; valores ausentes aplicam zero.
- Uma missao fisica usa combate; uma missao tecnica/comunitaria usa a formula limitada de sucesso.
- Cada missao tecnica bem-sucedida incrementa a contagem persistente exatamente uma vez.
- Uma sessao de Tecnologia marcada como Experimentacao tecnica conclui o periodo e define a flag `tech_experiments`.
- Missoes falhas nao concedem recompensas, e fuga nunca cria `criminal_record`.