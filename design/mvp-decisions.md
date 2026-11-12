# Decisoes do MVP - Rat Trainer

## Status do documento

- **Revisado:** 2026-11-12
- **Estado:** decisoes do MVP consolidadas; nenhum item abaixo depende de escolha futura do usuario.
- **Base verificada:** premissa e regras de conteudo em `CLAUDE.md`; escolhas confirmadas pelo usuario nesta revisao.
- **Referencia indisponivel:** `design/reference/sumario-executivo.pdf` nao existe nesta copia do projeto e, portanto, nao foi usado para validar valores.
- **Nomes:** Rat Trainer, Nyx Volt e ORAC sao nomes de trabalho, marcados como provisorios.
- **Balanceamento:** numeros de atributos, reputacoes e limiares abaixo sao valores iniciais do MVP; podem ser ajustados por playtest sem reabrir as decisoes de escopo.

## Decisoes consolidadas

### 1. Faixa etaria e duracao

- A protagonista comeca aos **12 anos**.
- O MVP cobre **3 anos de jogo**, terminando aos **15 anos**.
- Cada ano tem 12 meses e cada mes tem 3 periodos: **12 x 3 = 36 decisoes por ano**.
- A campanha do MVP tem **3 x 36 = 108 decisoes**. Cada periodo corresponde a uma atividade agendada.
- A faixa de 12 a 18 anos permanece como limite de conteudo do projeto. Avancar dos 15 aos 18 anos e uma possivel expansao, fora do MVP.
- Os finais do MVP representam reputacao, vocacao ou proximo caminho da protagonista adolescente; nao representam casamento, romance ou vida adulta ja estabelecida.

### 2. Mesada e dinheiro

- A protagonista recebe **200 creditos no inicio de cada ano de jogo**.
- Trabalho supervisionado e outras recompensas podem acrescentar creditos; a tabela de recompensas pertence ao balanceamento da economia e nao altera o valor da mesada definido aqui.
- Valores de recompensas serao validados em playtest, sem mudar a duracao nem o numero de periodos do MVP.

### 3. Stress e doenca

- Stress e um medidor separado, de **0 a 100**, iniciado em **0**; nao e um atributo de habilidade.
- Atividades exigentes podem aumentar Stress; lazer e descanso o reduzem.
- **STA** representa resistencia e altera a tolerancia ao stress. A doenca e acionada ao fim do periodo em que `Stress >= 60 + floor(STA / 5)`. Com STA entre 0 e 100, o limiar fica entre 60 e 80.
- Assim, Stress nao e comparado com uma Constituicao inexistente, e STA nao e tratada como o proprio nivel de fadiga.

### 4. Etica

- **Etica (ETH)** substitui Moral e Fe como um unico valor de **0 a 100**, iniciado em **50**.
- ETH representa as escolhas eticas da protagonista; nao e obediencia, reputacao publica nem uma medida automatica de criminalidade.
- Fuga, autonomia e sobrevivencia nao reduzem ETH nem criam ficha criminal por si so. Um ato ilegal escolhido e registrado separadamente.

### 5. Atributos e reputacoes

Todos os atributos e reputacoes variam de **0 a 100**; ganhos e perdas sao limitados a essa faixa. Atributos comecam em valores fixos para evitar intervalos ambiguos; o balanceamento posterior pode ajustar esses valores.

| Atributo | Inicial | Uso em atividades e resultados |
|----------|---------|--------------------------------|
| Forca (STR) | 15 | Ajuda em missoes fisicas e de protecao; requisito da rota de defensora. |
| Inteligencia (INT) | 15 | Ajuda em estudo, hacking e missoes tecnicas; requisito de rotas tecnicas e de autoria. |
| Carisma (CHA) | 15 | Ajuda em negociacao e atividades comunitarias; requisito de rotas sociais. |
| Refinamento (REF) | 15 | Ajuda em apresentacoes, artes e etiqueta; requisito de rotas artisticas e tecnicas de precisao. Substitui o codigo ambiguo `EGG`. |
| Resistencia (STA) | 20 | Aumenta a tolerancia ao stress pela regra da secao 3. |
| Etica (ETH) | 50 | Reflete escolhas eticas e participa dos requisitos de finais; nao define crime sozinha. |
| Stress | 0 | Medidor de carga acumulada; nao e atributo nem reputacao. |

| Reputacao | Inicial | Como e obtida e usada |
|------------|---------|-----------------------|
| Fighter Rep | 0 | Missoes fisicas e de protecao; requisito da rota de defensora. |
| Social Rep | 0 | Negociacao, apresentacoes e ajuda comunitaria; requisito de rotas sociais. |
| Hacker Rep | 0 | Missoes tecnicas e de rede; requisito de rotas de hacker, corporativa e de guardia da rede. |

As tres reputacoes sao independentes dos atributos e limitadas a 0-100. Nas condicoes dos finais, `>= 65`, `>= 70` etc. significa atingir aquele limiar; nao existe comparacao indefinida com `max`.

### 6. Atividades, registros e finais

- As quatro categorias de atividade sao **estudo, trabalho supervisionado, missao e lazer**.
- O estudo tem tres cursos: tecnologia (INT), comunicacao e escrita (CHA/REF) e artes e projeto (REF).
- O trabalho supervisionado tem tres tarefas: reparo leve, entrega assistida e apoio comunitario.
- Ha tres tipos de missao: fisica/protecao, tecnica e apoio comunitario. O MVP tambem tem 2 atividades de lazer e 12 eventos.
- Tipos de missao podem ser repetidos. Uma missao tecnica concluida com sucesso incrementa `missoes_tecnicas_concluidas`.
- Registros usados nos finais:
  - `community_help`: obtido ao concluir uma missao ou evento identificado como ajuda comunitaria.
  - `criminal_record`: obtido somente ao escolher e concluir uma acao explicitamente ilegal.
  - `tech_experiments`: obtido ao concluir uma opcao de estudo ou missao de experimentacao tecnica.
  - `disappear_from_society`: obtido somente ao aceitar a opcao explicita de desaparecer em um evento.
- Os registros sao fatos de percurso, nao juizos automaticos sobre a protagonista. Em particular, `disappear_from_society` nao implica `criminal_record` nem reduz ETH.
- O MVP tem **exatamente 15 finais**. A tabela abaixo tambem fixa a prioridade: avaliar de cima para baixo e conceder o primeiro final cujas condicoes forem atendidas. "Caminho Equilibrado" e o resultado de reserva se nenhum outro final for elegivel.

| Prioridade | Final | Condicoes |
|------------|-------|-----------|
| 1 | Evadida do Sistema | `disappear_from_society` |
| 2 | Aprendiz de Ciborgues | INT >= 70, REF >= 50 e `tech_experiments` |
| 3 | Tecnica Juvenil da Cidade | INT >= 65 e pelo menos 5 `missoes_tecnicas_concluidas` |
| 4 | Guardiã da Rede | ETH >= 65, Hacker Rep >= 70 e `community_help` |
| 5 | Lider Comunitaria Jovem | CHA >= 75, Social Rep >= 75 e `community_help` |
| 6 | Promessa Corporativa | CHA >= 60, Social Rep >= 70 e ETH <= 30 |
| 7 | Recruta do Submundo | INT >= 50, ETH <= 35 e `criminal_record` |
| 8 | Voz das Ruas | CHA >= 65, Social Rep >= 65 e `community_help` |
| 9 | Mediadora Comunitaria | ETH >= 70, CHA >= 55 e `community_help` |
| 10 | Autora Emergente | INT >= 55 e REF >= 55 |
| 11 | Mecanica de Campo | STR >= 50, INT >= 55 e pelo menos 3 missoes tecnicas concluidas |
| 12 | Defensora das Ruas | STR >= 60 e Fighter Rep >= 70 |
| 13 | Hacker de Elite | INT >= 65 e Hacker Rep >= 70 |
| 14 | Artista Emergente | REF >= 60 e Social Rep >= 65 |
| 15 | Caminho Equilibrado | Nenhum requisito; resultado de reserva. |

A ordem resolve sobreposicoes sem depender da ordem acidental de condicoes em codigo. Todos os limiares numericos estao dentro das faixas definidas.

### 7. Fuga e delinquencia no tema cyberpunk

- Fuga e tratada como uma escolha de autonomia ou sobrevivencia diante de vigilância, controle ou risco; nao e automaticamente delinquencia.
- A escolha pode registrar `disappear_from_society` e levar ao final Evadida do Sistema.
- Somente uma acao explicitamente ilegal cria `criminal_record`; ETH pode ser afetada pela acao, mas fugir nao altera ETH por si so.
- O tom e de consequencias e sobrevivencia, sem glamourizar crime nem mostrar violencia graficamente.

### 8. Escopo fechado do MVP

**Dentro do escopo:** agenda de 3 anos, atributos e reputacoes da secao 5, quatro categorias de atividade, economia basica, 12 eventos e 15 finais.

**Fora do escopo:**

- Dieta, peso, medidas e composicao corporal.
- Customizacao de roupas e bonus complexos de vestuario.
- Dialogos longos e minigames.
- Combate manual ou em tempo real.
- Multiplayer, conectividade online e multiplas protagonistas jogaveis.
- Conteudo procedural e arvore de habilidades extensa.
- Mais de 15 finais no MVP.
- Avanco dos 15 aos 18 anos; e uma possivel expansao, nao parte do ciclo inicial.

### 9. Premissa e nomes de trabalho

Em 2087, Neo-Arcadia vive entre controle corporativo e comunidades independentes. Nyx Volt, uma garota-rato, e criada por ORAC, uma inteligencia artificial que atua como sua guardia e protege sua sobrevivencia depois da morte de seus genitores humanos. **Nyx Volt, ORAC e Neo-Arcadia sao nomes provisorios.**

Durante os tres anos do MVP, Nyx organiza seus periodos entre estudo, trabalho supervisionado, missoes e lazer. Hacking, biotecnologia, protecao e ajuda comunitaria representam rotas possiveis, sem exigir que todas sejam usadas em uma partida.

Ao final, os atributos, reputacoes, registros e decisoes determinam um caminho para o futuro de Nyx. A campanha termina aos 15 anos; os finais descrevem reconhecimento ou vocacao juvenil, nao uma vida adulta consumada.

### 10. Regras de conteudo

| Regra | Aplicacao no MVP |
|-------|------------------|
| Idade da protagonista | 12 a 15 anos durante o MVP; nenhuma cena deve apresenta-la como adulta. |
| Conteudo sexual ou sexualizado | Proibido. |
| Vestuario revelador | Proibido. |
| Romance envolvendo menor de idade | Proibido. |
| Relacao romantica ou inadequada com a guardia | Proibida; ORAC e exclusivamente guardia. |
| Finais de relacionamento | Somente platonicos, familiares ou profissionais, sem romance com a protagonista. |
| Finais sombrios | Podem tratar de crime, caos ou isolamento, sem conteudo sexual, violencia grafica ou glamourizacao de dano. |
| Assets e textos | Adequados para a faixa etaria de 12 a 15 anos. |

## Revisao final

| Verificacao solicitada | Resolucao |
|------------------------|-----------|
| Incoerencias sem uma decisao | Todas resolvidas; o conjunto de escolhas esta fechado. |
| Duracao | 3 anos, 12 meses e 3 periodos por mes: **108 decisoes no MVP**. 36 e o total anual; 216 corresponde a seis anos e fica fora do MVP. |
| Atributos e reputacoes | Seis atributos e tres reputacoes, com faixa, inicial e utilidade em atividades, regras ou finais. Stress e separado; todos os limiares sao validos. |
| Fuga e delinquencia | Fuga e autonomia/sobrevivencia; crime exige uma acao ilegal explicita. |
| Nome do jogo e da protagonista | Rat Trainer e Nyx Volt marcados como provisorios; ORAC e Neo-Arcadia tambem. |
| Fora do escopo | Inclui os adiamentos definidos na secao 8, inclusive multiplayer, romance, multiplas protagonistas, expansao etaria e sistemas complexos. |
| Regras de conteudo | Mantidas e explicitadas na secao 10, incluindo a proibicao de relacao inadequada com a guardia. |

## Fontes e confianca

| Fonte | Estado | Uso |
|-------|--------|-----|
| `CLAUDE.md` do projeto | Consultado | Premissa, faixa etaria e regras de conteudo. |
| Decisoes confirmadas pelo usuario nesta revisao | Confirmadas em 2026-11-12 | Duracao de 3 anos; estrutura de atributos e reputacoes; regra de fuga; nomes provisorios e escopo. |
| `design/reference/sumario-executivo.pdf` | Ausente nesta copia do projeto | Nenhuma afirmacao foi atribuida ou conferida com esse documento. |
| Inspiracao em Princess Maker 2 e design proprio | Referencia conceitual, nao validacao numerica | Inspira o agendamento e a fantasia geral; nao comprova balanceamento. |

## Proximos passos de producao

Os itens abaixo sao tarefas de detalhamento/implementacao e balanceamento; nao reabrem as decisoes consolidadas acima:

1. Detalhar os 12 eventos e suas escolhas, incluindo os registros que podem conceder.
2. Especificar recompensas de atividades e economia usando a mesada anual de 200 creditos como base inicial.
3. Implementar e testar a regra de Stress, STA e doenca.
4. Implementar a avaliacao ordenada dos 15 finais e testar cada condicao e sobreposicao.
