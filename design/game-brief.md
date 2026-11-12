# Rat Trainer - Game Brief

## Premissa

Em 2087, na cidade cyberpunk de Neo-Arcadia, Nyx Volt, uma garota-rato, e criada por ORAC, uma inteligencia artificial que atua exclusivamente como sua guardia. Durante tres anos, dos 12 aos 15, Nyx escolhe como estudar, contribuir com o bairro, encarar missoes e descansar.

Rat Trainer e um simulador de agenda mensal inspirado na estrutura de planejamento de Princess Maker 2. Nyx Volt, ORAC e Neo-Arcadia sao nomes provisorios.

## Fantasia do jogador

Guiar uma adolescente em crescimento e construir um caminho para seu futuro por meio de escolhas pequenas e consequentes. O jogador deve sentir que administra tempo, recursos, bem-estar e vinculos, sem que autonomia seja tratada automaticamente como delinquencia.

## Loop principal

1. Consultar ano, mes, periodo, atributos, reputacoes, Stress e creditos.
2. Em cada periodo, escolher estudo, trabalho supervisionado, missao ou lazer; eventos fixos substituem a atividade quando agendados.
3. Resolver efeitos, atualizar saldo e estado, persistir progresso.
4. Repetir por 3 anos x 12 meses x 3 periodos = 108 decisoes.
5. Apos a escolha do ultimo evento, avaliar o primeiro final elegivel na ordem fixa.

## Primeiros dois minutos

- Ver a tela principal com Nyx em primeiro plano e ORAC como presenca de guardia, sem romance ou sexualizacao.
- Entender a data de campanha, o cartao da personagem e as seis barras de atributo.
- Abrir status e reconhecer que Stress e separado de STA.
- Consultar uma atividade e ver seu custo, ganho esperado e efeito de Stress antes de confirma-la.
- Fazer a primeira escolha do Ano 1; a mesada inicial de 200 Cr ja aparece no saldo.

## Desafio

Os periodos sao limitados: uma atividade ou evento por periodo. O jogador precisa equilibrar crescimento, renda, equipamento e Stress. A doença restringe missoes a partir do limiar `60 + floor(STA/5)`, mas nao remove periodos.

## Sistemas MVP

- Calendario de 3 anos, 12 meses por ano, 3 periodos por mes.
- Atributos STR, INT, CHA, REF, STA, ETH; reputacoes Fighter, Social e Hacker; Stress separado.
- Quatro categorias de atividade, 12 eventos fixos, pool de tres encontros aleatorios, mesada anual de 200 creditos.
- Missoes fisicas com combate automatico e catalogo pequeno de lojas/equipamentos.
- Save JSON e exatamente 15 finais juvenis, incluindo um final de reserva.

## Primeiros itens e futuro

Ficam fora do MVP: avancar dos 15 aos 18 anos, minigames, dialogos longos, combate manual/tempo real, multiplayer, multiplas protagonistas, progressao procedural, arvore extensa de habilidades e customizacao de roupas com bonus complexos.

## Regras de conteudo

Nyx tem de 12 a 15 anos durante o MVP. Proibidos conteudo sexual/sexualizado, vestuario revelador, romance com a protagonista ou com a guardia. Finais de relacionamento, se houver, sao somente platonicos, familiares ou profissionais. Conteudo sombrio nao deve ser grafico nem glamourizar dano.

## Referencias e limites de verificacao

O PDF `design/reference/sumario-executivo.pdf` e screenshots de `references/` nao estao disponiveis na copia atual; este brief nao afirma ter sido validado contra esses materiais.
