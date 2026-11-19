# Validação funcional e visual — Rat Trainer

Data: 18/11/2026. Projeto canônico: `project.godot` na raiz, Godot 4.5.1.

**Resultado:** 206 testes passaram em 21 suítes, sem falhas, erros ou órfãos. Uma campanha real de 36 meses/108 períodos chegou ao final por meio de 595 cliques de mouse nos controles do jogo. Uma segunda passagem, com 169 cliques, verificou doença, bloqueio de missões, recuperação e atualização da personagem. Opções e galeria também foram exercitadas no runtime.

Esta evidência cobre as mecânicas do MVP e os cenários descritos abaixo. Uma campanha completa não equivale a percorrer todas as combinações de escolhas. Os 15 finais foram avaliados com estados de teste independentes; a campanha interativa terminou em **Caminho Equilibrado**.

## Problemas corrigidos

- **Perfil:** o botão emitia uma solicitação sem destino conectado. Agora abre uma tela com a personagem, idade, créditos, atributos, stress, doença, reputações e níveis dos cursos. Voltar/Escape fecha a tela e restaura o foco.
- **Falar:** agora abre conversas curtas sobre bem-estar, estudos e cidade. O retrato acompanha o estado de Nyx. São conversas informativas: não concedem atributos, dinheiro ou períodos extras.
- **Travamento no mês seguinte:** o controlador conservava o índice 3 do mês anterior. A nova agenda agora começa no índice 0. A campanha interativa passou por todos os 36 meses.
- **Resultados verticais e botão fora da tela:** foi removida a apresentação visual de texto em um CenterContainer de largura insuficiente. A tela agora mostra a ilustração da atividade, a personagem, os ganhos e os valores atuais, com detalhes roláveis e rodapé acessível.
- **Valores invisíveis ou zerados:** os rótulos de atributos ganharam dimensões legíveis. Resultados, resumo mensal e relatório do controlador agora leem os atributos dentro do estado real de StatsSystem, em vez de buscar os campos no nível errado.
- **Recuperação de agenda:** a validação considera os períodos ainda editáveis, sem exigir novas escolhas para períodos já concluídos. Um encontro pendente em memória abre suas opções, em vez de sobrepor uma agenda vazia.
- **Falha de autosave:** um período já aplicado permanece apresentado e oferece uma nova tentativa de salvar, sem executar a atividade novamente. Um evento continua respondível caso seu checkpoint falhe.
- **Doença e consumível:** usar um adesivo atualiza imediatamente os valores, a disponibilidade de missões e a arte da personagem. Antes, a simulação podia se recuperar enquanto o botão continuava desabilitado.
- **Título e formulários:** título, criação de personagem, opções e seleção de save foram centralizados corretamente.
- **Script legado de Status:** foram corrigidas propriedades/sintaxe antigas incompatíveis com Godot 4, com teste de carregamento pelo editor.

## Apresentação e imagens

Os prints de Princess Maker enviados na conversa orientaram a composição: calendário à esquerda, personagem maior em primeiro plano, informações à direita, perfil com barras, retrato nas conversas e ilustrações nos resultados de atividades. As imagens de referência não foram incorporadas ao jogo.

Foi reutilizada a arte existente, sem gerar ou redesenhar imagens. `ArtPresentation.gd` seleciona imagens conforme atividade, evento, idade e estado. As variantes de 12–15 anos, cansada e doente foram conectadas. Estudos, trabalhos, lazer, missões, eventos e lojas usam imagens correspondentes quando disponíveis. A moldura também é aplicada no título e nos formulários. A janela mantém a composição lógica 1024×768 e a proporção 4:3, com tamanho mínimo 800×600.

## Cobertura por mecânica

| Mecânica | Verificação executada | Resultado / limite |
|---|---|---|
| Novo jogo e identidade | Cliques em Novo jogo e criação; leitura do nome e estado inicial | Funcionando |
| Calendário, idade e término | 108 períodos reais, 36 meses; CLI adicional com seed 12345 | Campanha concluída aos 15 anos |
| Mesada e créditos | Testes de concessão inicial/anual, custos e transações; campanha com estudo/trabalho | Funcionando nos cenários testados |
| Agenda de três períodos | Seleção por cliques, execução, segundo mês, repetição, cancelamento e recuperação | Funcionando; regressão do índice corrigida |
| Estudo e trabalho | Ganhos, custos, níveis, XP, sequência de trabalho e promoção nos testes; estudo/trabalho no percurso completo | Funcionando; apresentação com imagens |
| Lazer e descanso | Testes de efeitos/limites; passeio na campanha interativa | Funcionando |
| Atributos e reputações | Testes de valores iniciais, ganhos e limites; perfil e resumo com valores reais | Funcionando; leitura incorreta corrigida |
| Stress e doença | Testes de limiar; passagem interativa até 69 de stress e doença | Missões bloqueadas e arte alterada |
| Recuperação | Compra e uso do adesivo pela interface | Stress 69 → 54, doença encerrada, missões liberadas, arte atualizada |
| Lojas e inventário | Compra real dos três itens; testes de preço, saldo insuficiente, limite e duplicação | Funcionando |
| Equipar/desequipar e bônus | Equipamento real de ferramenta e proteção; testes de bônus, remoção e persistência | Funcionando |
| Consumível e recompensas | Uso real, redução de quantidade e stress; testes de limites e recompensa de missão | Funcionando |
| Missões e encontros | Encontro real contra Rastreador e escolha Lutar; testes das quatro ações, chances, requisitos, equipamento e stress | As quatro ações têm cobertura automatizada; uma foi usada no percurso principal |
| Eventos fixos | Os 12 eventos, de e01 a e12, apareceram no percurso completo e receberam escolha | Funcionando no percurso testado |
| Eventos aleatórios | r01, r02 e r03 apareceram no percurso; testes de chance e determinismo | Funcionando nos cenários testados |
| Flags de percurso | Testes de efeitos de eventos e fixtures de finais | Funcionando nos casos cobertos; não foram percorridas todas as combinações de opções |
| Salvar/carregar | Save manual, retorno ao título com autosave e carregamento real no período concluído 6 | Calendário e equipamento preservados |
| Migração, RNG e recuperação de saves | Testes de roundtrip, migração, evento pendente, RNG e falha de gravação | Funcionando nos casos automatizados |
| Finais e galeria | Fixtures independentes dos 15 resultados, regras/prioridades e 15 entradas na galeria; um final obtido em campanha real | Avaliação dos 15 aprovada; apenas um percurso completo foi jogado |
| Perfil e conversas | Cliques reais para abrir, escolher tópico e voltar; teste de fechamento | Funcionando |
| Opções e áudio | Clique no slider de música, persistência em 50%, conferência do bus em −6,02 dB e retorno ao título | Controle funcionando; áudio continua usando os tons procedurais existentes |
| Resoluções e texto | Capturas 800×600, 1024×768 e 1280×960; texto em 150% nas telas de conversa/resultados; medição de limites dos botões | Sem botões fora do viewport nos casos exercitados |

## Capturas reais

As imagens abaixo são capturas do viewport renderizado do Godot, não mockups. As passagens usaram saves próprios em `reports/functional-pass/`, sem carregar saves pessoais. Capturas de resolução e escala de texto são verificações visuais; a campanha de 108 períodos foi executada na resolução base.

| Tela | Captura |
|---|---|
| Título centralizado | [Abrir](title.png) |
| Principal e atributos legíveis | [Abrir](main.png) |
| Perfil funcionando | [Abrir](profile.png) |
| Conversa com retrato | [Abrir](talk.png) |
| Loja com cenário | [Abrir](shop.png) |
| Equipamento comprado e equipado | [Abrir](equipment.png) |
| Estudo com imagem | [Abrir](study_result.png) |
| Trabalho com imagem e valores | [Abrir](work_result.png) |
| Encontro de missão | [Abrir](mission.png) |
| Resumo mensal com ganhos reais | [Abrir](monthly_summary.png) |
| Segundo mês selecionável | [Abrir](second_month.png) |
| Campanha carregada | [Abrir](loaded_save.png) |
| Evento durante a campanha | [Abrir](event.png) |
| Evento final e12 | [Abrir](final_event.png) |
| Final após 108 períodos | [Abrir](ending.png) |
| Doença e missões bloqueadas | [Abrir](disease.png) |
| Conversa durante a doença | [Abrir](sick_talk.png) |
| Recuperação e missões disponíveis | [Abrir](recovery.png) |
| Opções de áudio | [Abrir](options.png) |
| Galeria de 15 finais | [Abrir](gallery.png) |

## Testes, regressões e comandos

Os primeiros testes contra o código anterior retornaram exit 100: 194 casos, 30 falhas de asserção e 6 erros. Parte das falhas vinha de fixtures que tentavam gravar em `user://` fora do workspace. Esses testes agora usam diretórios próprios em `res://reports/`, com limpeza onde aplicável. Nenhum valor esperado de gameplay foi afrouxado. O teste específico de fallback de finais agora isola a ausência de arte final para realmente exercitar placeholders, mesmo com a arte instalada.

Foram adicionados 11 casos de regressão de UI/fluxo, observados falhando antes das respectivas correções: Perfil/Falar, segundo mês, resultado ilustrado e rodapé, centralização do título, rótulos de atributos, encontro pendente, tentativa de salvar sem repetir atividade, valores do resumo, recuperação por consumível, script legado e evento com falha de checkpoint. Outro caso verifica os 15 finais com fixtures independentes.

Comandos executados na raiz; os logs e auxiliares ficam em `reports/functional-pass/`, ignorados pelo Git:

```powershell
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --editor --quit --log-file 'C:/Users/João/Documents/rat-trainer/reports/functional-pass/import-final.log'

& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --log-file 'C:/Users/João/Documents/rat-trainer/reports/functional-pass/suite-final.log' -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit

& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --log-file 'C:/Users/João/Documents/rat-trainer/reports/functional-pass/simulation-12345.log' --script res://src/tools/simulation_cli.gd -- 12345

& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --path . --rendering-method gl_compatibility --disable-shader-cache --disable-vsync --max-fps 240 --log-file 'C:/Users/João/Documents/rat-trainer/reports/functional-pass/runtime.log' res://reports/functional-pass/runtime_qa.tscn --quit-after 20000
```

- **Importação:** exit 0. Persistem mensagens ambientais de certificados e de gravação de `editor_settings-4.5.tres` fora do workspace; não foram ocultadas nem resolvidas por alterações no jogo.
- **Suíte final:** exit 0; **206 casos, 21 suítes, 0 falhas, 0 erros, 0 órfãos**. XML local: `reports/report_234/results.xml`.
- **Campanha renderizada:** exit 0; **108 períodos, 595 cliques, e01–e12 e r01–r03**, final Caminho Equilibrado. Evidência local: `reports/functional-pass/runtime_evidence.json`.
- **Passagem de saúde:** exit 0; doença após 10 meses de trabalho; **169 cliques**, stress 69 → 54 e missões liberadas. Evidência local: `reports/functional-pass/health/runtime_evidence.json`.
- **Menus:** exit 0; opções persistidas, bus de música conferido e 15 entradas na galeria. Evidência local: `reports/functional-pass/menus/runtime_evidence.json`.
- **Resoluções:** exit 0 nas passagens `resolution_qa.tscn -- small` com `--resolution 800x600` e `-- large` com `--resolution 1280x960`; listas de botões fora dos limites vazias em `small/bounds.json` e `large/bounds.json`.
- **CLI adicional:** exit 0; 108 períodos aos 15 anos. Houve aviso de ObjectDB ao encerrar esse utilitário; a suíte final não registrou órfãos.
- **Funplay:** confirmou projeto/versão e executou inspeção de scripts. O verificador isolado `godot-check-only` não fornece os autoloads ao compilar algumas dependências e acusou `Assets`/`EventBus` ausentes; esse resultado não é apresentado como uma compilação limpa. O erro sintático real no Status legado foi corrigido e seu carregamento foi incluído na suíte. As execuções completas validam os scripts com os autoloads do projeto.

O percurso usou cliques de mouse injetados nas posições reais dos controles, não chamadas diretas para avançar o calendário. Os scripts auxiliares configuraram apenas saves isolados e seeds reprodutíveis. Nas verificações específicas de resolução, as telas também foram abertas diretamente para medir layout. As fixtures dos 15 finais não representam 15 campanhas jogadas.

## Revisão restante

- Aparência, legibilidade e balanceamento precisam do playtest humano do projeto; a validação não cobre todas as sequências de opções nem hardware de gamepad.
- As conversas são curtas e informativas. Diálogos longos e bônus novos por conversar não foram introduzidos.
- A apresentação de atividades é estática; as imagens foram conectadas, mas não foram criadas animações ou minigames.
- O áudio permanece procedural; controlar volume não valida qualidade de uma trilha final que ainda não existe.
- Encontros físicos não são serializados no meio de uma escolha pelo núcleo atual. O fluxo salva imediatamente antes da missão e depois da resolução; um carregamento anterior à resolução permite refazer a missão sem reaplicar um período concluído.

As alterações anteriores do usuário foram preservadas. Prompts, logs, medições e scripts temporários de QA continuam locais/ignorados; as capturas finais e este relatório são documentação revisável. Nenhum commit foi criado.

Mensagem sugerida: `fix(game): restore playable menus and monthly progression with illustrated screens`
