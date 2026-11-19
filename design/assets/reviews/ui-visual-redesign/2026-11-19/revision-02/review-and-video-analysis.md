# Revisão 02 — composição e comparação com o vídeo

19/11/2026. A nova orientação substitui a exigência anterior de mostrar o sprite inteiro: Nyx deve ocupar o primeiro plano, com a parte inferior oculta pelos HUDs/enquadramento. Esta revisão implementa apresentação e corrige margens; as diferenças de gameplay abaixo são análise, não funcionalidades implementadas.

## Correções realizadas

| Área | Correção |
|---|---|
| Tela principal | `MainScreen.gd`: CharacterVisual de `(282,8), 430×590` para `(180,20), 620×900`, mantendo proporção e z=-1. A arte continua por trás dos painéis; pernas/pés ficam ocultos. Menu em `(16,576), 650×192`, sem faixa de personagem reaparecendo abaixo dele. |
| Perfil | `ProfileScreen.gd`: área de retrato com recorte de apresentação e imagem de 520×830. Mostra Nyx maior; pés ficam fora do enquadramento; nome, idade, créditos e métricas continuam acessíveis. |
| Resultado | `ActivityResultScreen.gd`: retrato de 500×800 numa área de 360 pixels de largura, recortado antes do rodapé. Camada explícita z=1 isola o recorte: ilustração, título, tabelas e botões permanecem visíveis. |
| Molduras | `UITheme.gd`: margem interna compartilhada e padrão do helper de 40 pixels. As fatias NinePatch continuam 64, sem alterar o PNG. Margem interna é validada separadamente do limite da viewport. |
| HUD direito | Cartão 324×212 em `(684,16)`; status 324×394 em `(684,236)`; Salvar em `(684,642)`, 324×44; Agendar em `(684,698)`, 324×54. Não há sobreposição entre esses controles. Status compacto/detalhado continua com rolagem quando necessário. |
| Menu inferior | Botões com mínimo 180×44 e margem de 40 dentro do painel; mesmos seis destinos, ícones, ações e vizinhos de foco. |
| Lojas/equipamento | `ItemManagementScreen.gd`: painel e cartões com 40 pixels de margem. Comprar/Equipar/Usar passam a ter mínimo 104×44 e alinhamento vertical central, evitando botões altos encostados nos cantos ornamentados. Listas continuam roláveis; itens fora da região de rolagem não são botões escapando da moldura. |

Nenhuma textura, regra de simulação, save, fórmula, texto de localização ou ação de botão foi alterada. Não houve commit, staging ou alteração de ignore. Mudanças anteriores de documentação e o MP4 não foram tocados.

## Capturas reais atuais

Viewport e janela 1024×768, simulação em memória, mesma personagem/estado inicial da primeira revisão. Resultado usa a sessão real de Tecnologia do fixture: 192 Cr, INT 27, Stress 2. Capturas vieram de `get_viewport().get_texture().get_image()`, sem montagem/edição. Os PNGs abaixo contêm apenas Rat Trainer.

| Tela | Atual | Comparação anterior |
|---|---|---|
| Principal | [main.png](main.png) | [passagem anterior](../after/main.png) |
| Perfil | [profile.png](profile.png) | [passagem anterior](../after/profile.png) |
| Resultado | [result.png](result.png) | [passagem anterior](../after/result.png) |
| Falar | [talk.png](talk.png) | [passagem anterior](../after/talk.png) |
| Lojas | [shops.png](shops.png) | Print fornecido pelo usuário nesta solicitação |
| Equipamento | [equipment.png](equipment.png) | Captura local da primeira passagem |

## O que foi visto no vídeo

Arquivo original local: `Princess Maker Steam Trailer.mp4`, 318,88 s, 1920×1080, 60 fps. É uma gravação que inclui abertura e controles do player, não uma demonstração completa de todas as funcionalidades do jogo. Foi decodificado pelo FFmpeg já instalado em `C:/Users/João/AppData/Local/Effect House/ffmpeg.exe`. Nenhum arquivo de referência foi enviado a serviço externo, copiado para o relatório ou adicionado ao Git.

Além dos quadros da primeira análise (74, 76, 100, 125, 149, 151, 224, 226, 250, 300 s), nesta revisão foram extraídos e inspecionados 80, 90, 110, 130, 160, 170, 180, 190, 200, 210, 230, 240, 260, 270, 280, 290 e 310 s. Também foram inspecionadas sequências curtas em folha de contato: 110–114,5 s a 2 quadros/s e 278–284 s a 1 quadro/s. A sequência curta confirma mudanças de posição/pose dentro da vinheta e a progressão dos dias, não apenas ilustrações diferentes em quadros distantes. Os arquivos extraídos estão somente em `%TEMP%/rat-trainer-reference-2026-11-19/`.

Não se afirma que o vídeo inteiro foi assistido continuamente. Tampouco se deduzem sistemas que não aparecem no trecho.

## Diferenças de design/presentação

| Evidência direta | Rat Trainer atual | O que falta aproximar |
|---|---|---|
| 90, 110, 130 s: personagem grande no quarto; HUDs e janelas se sobrepõem intencionalmente à parte inferior. | A primeira passagem mostrou corpo inteiro. | Composição corrigida nesta revisão. Ainda falta integrar mais os resultados ao ambiente do quarto: hoje o resultado tem uma grande superfície burgundy. |
| 110–114,5 s: vinheta de trabalho muda poses/posições enquanto a personagem e o HUD permanecem. | `ActivityResultScreen` mostra uma textura estática e valores finais; `ArtPresentation.artwork()` cria TextureRect, sem uma sequência animada. | Animação curta da atividade e reação visual, com pular/velocidade preservados. Isso é falta de apresentação; não significa que o cálculo da atividade esteja ausente. |
| 110, 130, 224, 240 s: vinheta à esquerda, comentário do trabalho/aula ao lado, barras imediatamente abaixo. | Há ilustração, descrição e tabelas numéricas, em outra organização. | Narrativa contextual de sucesso/falha e feedback visual de progresso; agrupar apenas as métricas relevantes àquela atividade. Os deltas já existem. |
| 160, 210, 230 s: interlocutor com retrato e fala numa janela compacta. 278–284 s: retrato/retorno do encontro. | Falar usa só o retrato de Nyx; eventos usam título, descrição, opções e CG/cenário. | Apresentação de NPCs como interlocutores identificáveis, alternância de falas e reação. O vídeo não comprova por si só um sistema de afinidade persistente. |
| 170 vs 90 s: roupa diferente é visível na personagem. | `ArtPresentation.character_id()` escolhe por idade e estado normal/cansada/doente; não pelo equipamento. | Variação visual por roupa/equipamento/contexto. Existem artes escolares/de trabalho no projeto, mas a seleção atual não faz um guarda-roupa jogável. |
| 270–290 s: mapa, personagem pequena em movimento, inimigo sobreposto e HUD da expedição. | Encontro separado com cenário, inimigo e quatro opções. | Continuidade visual entre exploração, encontro e retorno; movimento pelo ambiente ainda não existe. |

## Diferenças de gameplay — separadas do que já funciona

| Sistema visto | Evidência | Situação comprovada no Rat Trainer | Diferença real |
|---|---|---|---|
| Planejamento e execução diária | 80 s mostra calendário mensal e trabalhos; 110–114,5 s avança dias 3–7 e mensagens do trabalho. | `CalendarSystem` usa 3 períodos por mês; `SimulationCore.advance_period()` aplica um resultado por período. A agenda mensal já existe. | Não há resolução diária dentro do bloco, com ocorrências intermediárias por dia. Pode-se primeiro apresentar os dias visualmente; simular novos efeitos diários exige uma decisão de design e nova lógica. |
| Exploração livre | 270 e 290 s mostram deslocamento por caminhos; 278–284 s entra num encontro. | Missões e encontros existem, mas não há mapa navegável, posição persistente da personagem nem escolha de rota. | Mapa com deslocamento e encontros ligados ao percurso. É a maior diferença estrutural, não um pequeno ajuste de HUD. |
| Quatro respostas ao encontro | 280 s: Fight, Talk, Run Away, Hide; sequência mostra tentativa de conversar e retorno de falha. | **Já existem** Lutar, Conversar, Fugir, Esconder. `ActivitySystem.resolve_encounter()` resolve chance, stress, efeitos e recompensas; equipamento pode ajudar. | Falta encenação/diálogo e integração com exploração; não falta adicionar os quatro botões. |
| Vestuário que altera aparência | 160 s oferta de Winter Dress; 170 s personagem com outro traje. | Compras, inventário, mão/proteção e consumível existem. Catálogo: 3 itens, sem guarda-roupa visual; equipar casaco não muda o sprite. | Compra/equipagem de roupas com mudança visual. Não foi comprovado neste vídeo se há bônus climáticos/atributos específicos; não se inventam esses efeitos. |
| Dieta/custos de manutenção e medidas | 90 s rótulo Standard diet; 210 s Refined diet; 190 s exibe Weight. Na primeira folha de contato há mensagem Food expenses. | Economia de créditos, custos de estudos, itens e stress existem; não há estado de dieta, peso ou altura no núcleo atual. | Rotina de alimentação/manutenção e medidas seriam sistemas novos. O vídeo exibe rótulos/valores; não permite inferir fórmulas ou todos os efeitos. |
| Conteúdo de atividades e NPCs | 80 s apresenta seis trabalhos; 110/130/149/151/240 s mostram atividades distintas; 210/230 s instrutor comenta. | Catálogo tem **3 estudos, 3 trabalhos e 2 lazeres**, além das missões. Eventos e progressão de curso já existem; Falar é consulta sem alterar atributos/tempo. | Maior variedade de atividades e falas condicionais dos instrutores/empregadores. Não se deve chamar cursos/eventos inexistentes: falta amplitude e contextualização. |
| Recursos de expedição | 270–280 s mostra HP/MP junto de data/créditos. | Núcleo tem seis atributos, reputações, stress e doença; encontro não possui estado HP/MP. | Recursos próprios de expedição, se desejados. O trecho inspecionado não prova uma luta manual por turnos; não se afirma que esse sistema inteiro foi demonstrado. |
| Crescimento | Vídeo passa por idades 10, 11, 12, 13, 16 e 18, com diferenças de aparência. | Crescimento **já existe** de 12 a 15 anos, 108 períodos, sprites por idade/estado. | Maior duração/faixa de conteúdo seria expansão deliberada, não bug da implementação atual. |

As referências de status fornecidas também têm mais atributos e especializações que o MVP. O nosso conjunto menor é uma simplificação de design; aumentar a quantidade de barras sem dar função a elas não resolve a diferença.

## Ordem sugerida de próximos trabalhos

1. **Apresentação dos resultados:** vinheta animada, comentário contextual e deltas/barras claros, reutilizando cálculos existentes. É a mudança com ligação mais direta à sensação do vídeo e menor impacto no núcleo.
2. **NPCs/contexto:** instrutores e comerciantes com retrato, falas condicionais e reação. Definir antes se as conversas apenas informam ou geram consequências; hoje Falar é intencionalmente leitura.
3. **Roupas/contexto visual:** conectar variações adequadas já existentes a situações e, depois, definir guarda-roupa. Não conceder bônus sem especificação.
4. **Expedição por mapa:** especificar rota, encontros e retorno antes de implementar movimento/estado persistente. É gameplay novo, exige escopo próprio.
5. **Rotina ampliada:** decidir se dias internos, dieta e recursos de expedição cabem no projeto. Não copiar todos os sistemas de Princess Maker automaticamente.

Nenhum item desta lista foi implementado disfarçado de correção visual. O vídeo não comprova todos os finais, relações persistentes, torneios ou demais sistemas do original; esses pontos não foram usados como fatos desta comparação.

## Validação e limites

- Capturas finais em runtime: 17 telas/estados no fixture, saída 0, sem `SCRIPT ERROR`, `BUTTON_OUTSIDE_FRAME` ou `BUTTON_OUTSIDE_VIEWPORT`. A checagem considera a margem interna da moldura; rolagem intencional é tratada à parte. Capturas finais e métricas locais em `reports/ui-redesign/checkrevisionlayer*`; somente seis PNGs de Rat Trainer foram preservados aqui.
- Janela 800×600: captura e checagens da revisão passaram, saída 0, canvas lógico 1024×768. Essa passagem antecedeu o último ajuste de recorte do retrato de resultado; o recorte final foi conferido a 1024×768.
- Teste com cliques reais: Perfil, fechar, Falar, três tópicos, fechar e Continuar passaram; foco retornou e snapshots da simulação não mudaram por ações de apresentação. Log `reports/ui-redesign/revision-input.log`.
- Suíte completa final: 206 testes, 21 suítes, sem falhas/erros/skips. Saída 0. XML `reports/report_241/results.xml`; logs em `reports/ui-redesign/revision-final-unit*`.
- Importação do editor: saída 0, sem falhas de parser; persistem erros ambientais de certificados e tentativa de salvar preferências globais do editor fora do sandbox. Renderização também registra erros preexistentes de inicialização do cache de shaders GLES; capturas foram visualmente conferidas, não aprovadas só pelo exit code.
- Um recorte experimental do resultado escondeu visualmente os irmãos na renderização, apesar de os textos estarem preenchidos e os testes passarem. A inspeção da captura detectou o problema; a camada explícita do retrato corrigiu a exibição. O PNG experimental não é a evidência final.
- Não foi feito teste exaustivo de toda a campanha nesta revisão. Hardware de gamepad, leitor de tela, nomes muito longos e todos os estados possíveis não foram certificados.

Escopo Git desta continuação: ajustes em MainScreen, ProfileScreen, ActivityResultScreen, ItemManagementScreen e UITheme; este relatório e seis capturas. Alterações da primeira passagem em TalkScreen e documentação continuam presentes. Scripts temporários, logs e quadros de referência não foram preparados para commit.

Mensagem sugerida: `fix(ui): layer Nyx behind HUDs and contain panel actions`
