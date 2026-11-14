# Systems Map - Rat Trainer

## Dependencias

```text
Decisoes do MVP
  ├─ Calendario ─────┬─ Eventos
  ├─ Atributos/Stress ├─ Atividades ──┬─ Economia
  │                  │                ├─ Missoes/Combate
  │                  │                └─ Itens/Lojas
  └─ Save schema <────┴────────────────────┘
                           │
                           └── Finais
                                │
                                └── UX e fluxo integrado
```

| Sistema | Le de | Escreve |
|---------|-------|---------|
| Calendario | Estado de progresso | Turnos concluidos, data derivada |
| Atributos/Stress | Efeitos das escolhas | Atributos, reputacoes, Stress, doenca |
| Economia | Calendario,atividades, lojas, eventos | Creditos e transacoes |
| Atividades | Calendario, stats, economia, eventos | XP, streaks, recompensas, contagens |
| Combate | Stats, equipamento, missao | Resultado e Stress de combate |
| Monstros | Dados de missao | Dificuldade por missao |
| Eventos | Calendario, stats, economia | Flags, escolhas, IDs concluidos |
| Lojas/itens | Economia, combate, Stress | Inventario e equipamento |
| Save | Estado dos sistemas | Estado serializado e validado |
| Finais | Estado completo apos 108 periodos | Final selecionado |
| UX | Todos os contratos acima | Entradas do jogador e apresentacao |

## Ordem recomendada de implementacao

1. **Contratos de estado e save:** definir schema, autosave por periodo e estado parcial de trabalho mensal.
2. **Calendario e progresso:** garantir 108 periodos, datas derivadas e slots de evento.
3. **Atributos, reputacoes e Stress:** clamps, fontes de delta e limiar de doenca.
4. **Economia:** saldo inicial, mesadas por ano e transacoes sem saldo negativo.
5. **Catalogo de itens:** dados de preco, slots e bonus; sem interface de compra ainda.
6. **Resolucao de combate:** funcao deterministica por estado/`rng_state` e resultado de missao, consumindo stats e equipamento.
7. **Atividades:** cursos, trabalho, lazer e missoes; integrar com a interface de combate do passo 6.
8. **Eventos fixos e encontros:** 12 escolhas, pool R01-R03, flags e efeitos testados contra o calendario.
9. **Finais:** matriz de 15 condicoes, ordem de prioridade e casos de sobreposicao.
10. **UX e integracao:** tela principal, status, execucao de atividade, encontros, derrota, save/load; entao regressao ponta a ponta.

Essa ordem prioriza contratos estaveis, depois sistemas que produzem estado e por ultimo sistemas que o consomem. O resultado de combate e uma interface consumida por `activities.md`: recebe missao, STR/STA, bonus de equipamento e `rng_state`; retorna sucesso/falha e Stress de combate. Atividades aplica seu delta-base uma vez, e combate nao concede recompensas nem altera contadores. Assim o sistema de combate pode ser validado antes da integracao de missoes.

## Validacao de dependencias

- A implementacao de calendario nao deve incorporar regras de economia ou conteudo de evento.
- Cada campo persistido tem um unico sistema proprietario; `save-system.md` persiste, mas nao decide os valores.
- Cada recompensa de missao aparece uma vez em `activities.md`; combate apenas informa sucesso/falha.
- Cada flag tem fontes limitadas em `events.md` e `activities.md`, e consumidores identificados em `endings.md`.
- Encontros aleatorios usam somente um pool fixo de tres cartas e uma verificacao por periodo sem evento fixo.

## Relacao com prompts 03-12

Os arquivos de prompts numerados 03-12 nao estao presentes nesta copia. Portanto, esta e uma ordem recomendada pelas dependencias, nao uma afirmacao de que ela corresponde a uma sequencia de prompts ausente. Conferir o mapeamento quando os prompts forem disponibilizados.

## Fora do MVP

Sem multiplayer, combate manual/tempo real, conteudo procedural, expansao etaria aos 15-18, minigames ou arvore extensa de habilidades.
