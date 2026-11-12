# GDD: Save System

## Overview

O save JSON preserva o estado necessario para retomar qualquer um dos 108 periodos sem conceder novamente mesada, recompensas ou eventos.

## Player Fantasy

Salvar e carregar deve ser previsivel e seguro: uma falha de arquivo nunca apaga o progresso nem converte dados invalidos em um estado aparentemente valido.

## Detailed Design

### Dados persistidos

```json
{
  "schema_version": 1,
  "character": {
    "name": "Nyx Volt",
    "stats": {"STR": 15, "INT": 15, "CHA": 15, "REF": 15, "STA": 20, "ETH": 50},
    "stress": 0,
    "reputation": {"fighter": 0, "social": 0, "hacker": 0},
    "credits": 200,
    "flags": {
      "community_help": false,
      "criminal_record": false,
      "tech_experiments": false,
      "disappear_from_society": false
    }
  },
  "progress": {"turns_completed": 0, "completed_fixed_event_ids": [], "event_history": [], "stipend_years_paid": [1]},
  "rng_state": 736245197,
  "activities": {
    "course_xp": {"technology": 0, "communication": 0, "arts": 0},
    "job_streaks": {"repair": 0, "delivery": 0, "community_support": 0},
    "job_levels": {"repair": 1, "delivery": 1, "community_support": 1},
    "job_tasks_used_current_month": {"repair": false, "delivery": false, "community_support": false},
    "missoes_tecnicas_concluidas": 0
  },
  "inventory": {"items": [], "equipped_hand": null, "equipped_protection": null},
  "metadata": {"created_at": "ISO-8601", "saved_at": "ISO-8601", "game_version": "0.1.0"}
}
```

`turns_completed` e a fonte de verdade do calendario. Idade, ano, mes, periodo e turno atual sao derivados conforme `calendar-and-turns.md`; nao armazenar contadores duplicados. `completed_fixed_event_ids` contem cada ID E01-E12 no maximo uma vez; `event_history` registra tambem os encontros aleatorios repetiveis com ID e periodo. `stipend_years_paid` impede pagamentos anuais duplicados. `job_streaks` rastreia meses consecutivos por tarefa, `job_tasks_used_current_month` registra o uso antes do fechamento do mes e `job_levels` persiste niveis promovidos. `rng_state` e o estado do gerador usado por encontros e combate, persistido com o resultado de cada periodo. O nome inicial e provisorio conforme `mvp-decisions.md`.

### Salvamento e slots

- Autosave atomico ao fim de cada periodo resolvido, incluindo eventos.
- Ao concluir o periodo 3, manter tambem um snapshot mensal separado; esse snapshot nao substitui nem atrasa o autosave por periodo.
- Uma verificacao aleatoria nao resolvida e reproduzivel: se houver falha antes do autosave, carregar o ultimo estado repete o mesmo resultado a partir do mesmo `rng_state`, em vez de sortear outro evento.
- Tres slots manuais, mais um slot de autosave. Salvar manualmente pode ocorrer fora de uma resolucao.
- Cada transacao usa um arquivo temporario e substitui o slot somente apos serializacao e validacao bem-sucedidas.
- Uma recompensa de missao, evento ou mesada e persistida junto com o marcador do periodo/evento para impedir duplicacao.
- Creditar 200 Cr no inicio de cada ano e registrar o ano em `stipend_years_paid` na mesma operacao atomica; Ano 1 aparece no novo jogo como ja creditado.
- Ao fechar o mes, atualizar cada streak conforme `activities.md` usando `job_tasks_used_current_month`; depois zerar os marcadores para o novo mes, na mesma gravacao.

### Validacao e compatibilidade

- Verificar JSON, `schema_version`, campos obrigatorios, tipos e faixas antes de carregar.
- `turns_completed`: inteiro 0-108; atributos, reputacoes e Stress: inteiros 0-100; creditos e contadores: inteiros >=0; niveis de tarefa: 1-2; `rng_state`: inteiro positivo de 64 bits.
- Uma versao de schema desconhecida ou arquivo corrompido e reportado; nunca deletar automaticamente.
- Uma versao anterior so pode ser migrada por migracao explicita e testada. Sem migracao, preservar arquivo e oferecer voltar ao slot anterior ou iniciar novo jogo sem sobrescrever o original.
- Hash criptografico e deteccao de trapaça nao sao requisitos do MVP; saves locais nao sao fronteira de seguranca.

## Formulas

### Data derivada

`ano = floor(turns_completed / 36) + 1` para valores menores que 108; `idade = 12 + floor(turns_completed / 36)`; mes e periodo seguem a formula em `calendar-and-turns.md`.

- `turns_completed` varia de 0 a 108. Em 108 a campanha esta concluida e nao ha data ativa.
- Exemplo: 0 periodos completos corresponde ao Ano 1, Mes 1, Periodo 1.
- Exemplo: 36 periodos completos corresponde ao Ano 2, Mes 1, Periodo 1.
- Exemplo: 108 periodos completos corresponde a idade 15 e campanha concluida.

### Validade do estado

`save_valido = JSON valido AND versao suportada AND todos os campos/tipos/faixas validos`

- Exemplo: `REF=100`, `Stress=0`, `turns_completed=108` e valores validos.
- Exemplo: `ETH=101` ou `turns_completed=-1` torna o arquivo invalido; nenhum valor e clamped durante carregamento.

## Edge Cases

- Falha de escrita preserva o arquivo anterior e informa o erro.
- Carregar autosave nao repete mesada: o pagamento so ocorre se o ano nao estiver em `stipend_years_paid`, e a marcacao e gravada na mesma transacao.
- O periodo 108 persiste o resultado final e estado concluido.
- IDs fixos concluidos nao podem se repetir; R01-R03 podem reaparecer em periodos diferentes, mas nao duas vezes no mesmo periodo. IDs desconhecidos tornam o save incompativel.
- O estado do gerador so avanca na mesma transacao que persiste o periodo; recarga nao pode rerrolar um evento pendente.
- A carga de um save entre periodos do mesmo mes preserva exatamente quais tarefas de trabalho ja foram usadas naquele mes.
- O nome de arquivo e slot escolhido; nunca aceitar um caminho fornecido por dados internos do save.

## Dependencies

- `calendar-and-turns.md` define `turns_completed` e o limite 108.
- `stats-and-stress.md`, `activities.md`, `economy.md`, `events.md` e `items-and-shops.md` definem campos e limites persistidos.
- `endings.md` le o estado final sem altera-lo.

## Tuning Knobs

| Knob | Valor MVP |
|------|-----------|
| Versao do schema | 1 |
| Slots manuais | 3 |
| Autosave | Cada periodo |
| Snapshot mensal | Ao concluir periodo 3 |
| Limite de periodos | 108 |

## Acceptance Criteria

- Novo jogo inicia com os valores, flags, inventario e saldo inicial definidos nos GDDs proprietarios.
- Salvar e carregar o mesmo estado mantem todos os campos e a data derivada.
- Uma falha de validacao nao altera nem remove o arquivo original.
- Autosave apos uma recompensa e recarga nao concede a mesma recompensa novamente.
- Recarregar um save intermediario de mes preserva as marcacoes das tarefas ja usadas; fechar o mes atualiza cada streak no maximo uma vez e limpa as marcacoes.
- `turns_completed=108` carrega como campanha concluida sem gerar periodo 109.
