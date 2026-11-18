# Remediação de formatos e dimensões — 18/11/2026

Corrigidos **51 arquivos nos caminhos originais**: todos os **50 casos de dimensões** da auditoria e a referência interna. Os **5 WebPs e o JPEG** agora contêm PNG verdadeiro. A medição final leu os **99 arquivos em assets/art/**: todos têm assinatura PNG, chunks com CRC válido, decodificação válida e dimensões esperadas. Nenhum caso ficou `NOT SAFELY RESIZABLE`. A referência foi ajustada proporcionalmente a 832×1216 com extensão das bordas claras.

A auditoria anterior é histórica e foi preservada integralmente. Não foram alterados IDs, categorias, caminhos, cenas, scripts do projeto, dados, tema, layout, créditos, manifesto ou .gitignore. Nenhum arquivo foi staged ou committed. Os status humanos de aprovação não foram promovidos.

## Fontes e ferramentas

Lidos AGENTS.md, CLAUDE.md, regras aplicáveis, skill local Funplay, coverage-and-validation.md, measurements.json, webp_metadata.json, manifesto, guia de geração, registro de variantes por idade, índices de arte, Assets.gd, project.godot e .gitignore. As dimensões esperadas de todos os 99 registros foram cruzadas com measurements.json original; a lista de 50 foi identificada pelas dimensões numéricas, incluindo os 5 WebPs cujas medições detalhadas estão em webp_metadata.json.

Ferramentas existentes: Godot 4.5.1 (Image, decoders WebP/JPEG/PNG e filtro Lanczos), Python 3.14 com biblioteca padrão (PNG independente, CRC, hashes, inventário e Git), System.Drawing já disponível para comparação de bordas em fundos preto e branco. Nenhum pacote instalado e nenhum gerador de imagens usado. Scripts auxiliares e logs foram criados na pasta temporária externa, sem mudanças em scripts do projeto.

## Backups e validação antes da substituição

Pasta externa preservada: `C:\Users\João\AppData\Local\Temp\rat-trainer-art-remediation-bmypx9re`.

- `originals/assets/art/...`: bytes originais de cada um dos 51 arquivos, com os mesmos caminhos relativos. Nenhum original de backup foi apagado.
- `candidates/assets/art/...`: PNGs corrigidos, mantidos mesmo após sua cópia aos caminhos originais.
- `job.json`, `candidates.json`, `published.json`, `final-measurements.json`: inventário detalhado de origem, método, padding, alfa, dimensões, tamanhos e hashes.
- `convert.gd`, `verify_and_publish.py`, `probe.gd`, logs e evidências do MCP: auxiliares externos à árvore do jogo.

Antes de substituir cada fonte, sua candidata foi decodificada explicitamente como PNG, teve assinatura, dimensões e alfa conferidos, passou por um segundo leitor PNG independente com verificação de CRC e foi comparada visualmente. Hashes do backup e da fonte foram comparados antes da publicação. Após copiar, o SHA256 do arquivo final foi conferido e a medição final releu os próprios arquivos em assets/art/.

**Conversão sem resize:** source-decoded RGBA8 → PNG → decoded RGBA8 deu diferença máxima de canal **0**, byte a byte, em todos os 51 arquivos, incluindo os cinco WebPs e o JPEG. Essa comparação ocorreu antes de qualquer redimensionamento. PNG preserva os pixels já decodificados do JPEG; não recupera informação perdida na compressão JPEG original.

## Critério de redimensionamento e inspeção

Foi usado um fator de escala único `min(largura_alvo/largura_fonte, altura_alvo/altura_fonte)`, com arredondamento apenas à grade inteira de pixels. Todo o canvas de origem foi preservado: sem recorte por bounding box, sem reposicionamento automático do objeto e sem alongamento por eixo. O canvas foi encaixado simetricamente; a posição do objeto dentro do canvas original permanece proporcional à origem. A diferença de até um pixel entre lados vem do arredondamento inteiro.

Sprites e ícones com alfa foram filtrados em RGBA float pré-multiplicado, depois desmultiplicados e gravados como RGBA8. Isso evita misturar RGB oculto dos pixels transparentes com a silhueta e não introduz matte opaco. Padding desses arquivos é transparente. Retratos opacos quadrados foram apenas reduzidos. Padding opaco, quando necessário, repete os pixels da borda mais próxima; não inventa conteúdo.

O quarto manteve **todos os pixels originais em 1024×765**, com uma linha repetida no topo e duas na base para chegar a 1024×768. A referência foi reduzida a 816×1216 e ganhou 8 px de borda clara de cada lado, preservando a silhueta e o fundo original. Cenários com proporção já correta foram reduzidos proporcionalmente. Vinhetas/CGs já corretos ficaram intactos.

Foram inspecionados os 51 pares nas três pranchas em fundo quadriculado (antes à esquerda, depois à direita em cada par, ordem igual à tabela abaixo). Também foram vistos diretamente o sprite idle e o drone, e o sprite idle foi comparado sobre preto e branco. Não foram observados recortes novos, membros/cauda/orelhas perdidos, matte opaco, halo novo visível ou deformação perceptível. A perda de detalhe fino por redução para as dimensões documentadas é esperada; nenhum filtro artístico ou compressão com perdas foi aplicado. Esta inspeção em escala de apresentação não equivale a aprovação artística humana ou garantia microscópica de ausência de halos em todas as escalas.

Pranchas temporárias em `reports/art-remediation-review-bmypx9re/comparison_01.png`, `comparison_02.png`, `comparison_03.png` e `character_edges.png`; já ignoradas pela regra `reports/`. Cópias das três pranchas também permanecem na pasta temporária externa. Não são novos assets do jogo.

## Inventário dos arquivos reparados

Todos os caminhos abaixo são PNG real ao final, com assinatura `89504e470d0a1a0a`, dimensões esperadas verificadas e resultado **OK**. A coluna de assinatura identifica os bytes originais, não a extensão. Bytes são tamanhos exatos.

| Caminho | Formato / assinatura original (16 bytes) | Origem | Esperado / final | Bytes originais → finais | Método |
|---|---|---|---|---:|---|
| `assets/art/backgrounds/bg_bedroom_day.png` | WebP / `52494646740202005745425056503820` | 1024×765 | 1024×768 / 1024×768 | 131708 → 1158575 | Sem reamostragem; borda: 1 linha acima + 2 abaixo |
| `assets/art/backgrounds/bg_ending.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1448×1086 | 1024×768 / 1024×768 | 2366511 → 1110454 | Lanczos opaco |
| `assets/art/characters/char_rat_casual_a_tired.png` | WebP / `5249464638850900574542505650384c` | 1027×1531 | 512×768 / 512×768 | 623936 → 298546 | Lanczos com alfa pré-multiplicado em float; padding 0/2/0/3 px (E/T/D/B), transparente |
| `assets/art/characters/char_rat_idle.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1027×1531 | 512×768 / 512×768 | 937366 → 291255 | Lanczos com alfa pré-multiplicado em float; padding 0/2/0/3 px (E/T/D/B), transparente |
| `assets/art/characters/char_rat_work.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1024×1536 | 512×768 / 512×768 | 1980834 → 389375 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/characters/portrait_rat_angry.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2308544 → 133174 | Lanczos opaco |
| `assets/art/characters/portrait_rat_happy.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2337000 → 131263 | Lanczos opaco |
| `assets/art/characters/portrait_rat_neutral.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2333100 → 130115 | Lanczos opaco |
| `assets/art/characters/portrait_rat_sad.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2355775 → 132506 | Lanczos opaco |
| `assets/art/characters/portrait_rat_shy.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2411141 → 132703 | Lanczos opaco |
| `assets/art/characters/portrait_rat_sick.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2339980 → 132097 | Lanczos opaco |
| `assets/art/characters/portrait_rat_surprised.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2346994 → 132667 | Lanczos opaco |
| `assets/art/characters/portrait_rat_tired.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 256×256 / 256×256 | 2321671 → 130718 | Lanczos opaco |
| `assets/art/endings/aprendiz_de_ciborgues.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1252867 → 22302 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/artista_emergente.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1207746 → 25736 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/autora_emergente.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1383607 → 22798 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/caminho_equilibrado.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1732308 → 29289 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/defensora_das_ruas.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1473263 → 24658 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/evadida_do_sistema.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1837225 → 27888 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/guardia_da_rede.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1867032 → 32032 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/hacker_de_elite.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1470655 → 27160 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/lider_comunitaria_jovem.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1653809 → 29653 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/mecanica_de_campo.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1751957 → 30469 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/mediadora_comunitaria.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1316528 → 25095 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/promessa_corporativa.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1684292 → 29152 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/recruta_do_submundo.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1642468 → 27981 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/tecnica_juvenil_da_cidade.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1393174 → 23692 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/endings/voz_das_ruas.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1724344 → 31228 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/icons/icon_agenda.png` | WebP / `5249464668540800574542505650384c` | 1254×1254 | 128×128 / 128×128 | 545904 → 15067 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/icons/icon_city.png` | WebP / `52494646f4520a00574542505650384c` | 1536×1024 | 128×128 / 128×128 | 676604 → 14856 | Lanczos com alfa pré-multiplicado em float; padding 0/21/0/22 px (E/T/D/B), transparente |
| `assets/art/icons/icon_equipment.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1536×1024 | 128×128 / 128×128 | 1975616 → 23281 | Lanczos com alfa pré-multiplicado em float; padding 0/21/0/22 px (E/T/D/B), transparente |
| `assets/art/icons/icon_mission.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1230×1278 | 128×128 / 128×128 | 903495 → 18785 | Lanczos com alfa pré-multiplicado em float; padding 2/0/3/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_profile.png` | WebP / `5249464600e90900574542505650384c` | 1254×1254 | 128×128 / 128×128 | 649480 → 17280 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/icons/icon_stat_cha.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1281×1227 | 128×128 / 128×128 | 1028869 → 20049 | Lanczos com alfa pré-multiplicado em float; padding 0/2/0/3 px (E/T/D/B), transparente |
| `assets/art/icons/icon_stat_eth.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1237×1271 | 128×128 / 128×128 | 926729 → 19977 | Lanczos com alfa pré-multiplicado em float; padding 1/0/2/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_stat_int.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1232×1277 | 128×128 / 128×128 | 940984 → 18464 | Lanczos com alfa pré-multiplicado em float; padding 2/0/3/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_stat_ref.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1230×1278 | 128×128 / 128×128 | 831513 → 19787 | Lanczos com alfa pré-multiplicado em float; padding 2/0/3/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_stat_sta.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1229×1280 | 128×128 / 128×128 | 1034259 → 19946 | Lanczos com alfa pré-multiplicado em float; padding 2/0/3/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_stat_str.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1234×1274 | 128×128 / 128×128 | 961470 → 19887 | Lanczos com alfa pré-multiplicado em float; padding 2/0/2/0 px (E/T/D/B), transparente |
| `assets/art/icons/icon_talk.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1536×1024 | 128×128 / 128×128 | 1418652 → 15515 | Lanczos com alfa pré-multiplicado em float; padding 0/21/0/22 px (E/T/D/B), transparente |
| `assets/art/items/adesivo_recuperacao.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1536×1024 | 128×128 / 128×128 | 1892210 → 17662 | Lanczos com alfa pré-multiplicado em float; padding 0/21/0/22 px (E/T/D/B), transparente |
| `assets/art/items/casaco_acolchoado.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1461305 → 28002 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/items/kit_ferramentas.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1295×1215 | 128×128 / 128×128 | 1416392 → 24985 | Lanczos com alfa pré-multiplicado em float; padding 0/4/0/4 px (E/T/D/B), transparente |
| `assets/art/monsters/drone_patrulha.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1024×1536 | 512×512 / 512×512 | 1910192 → 188560 | Lanczos com alfa pré-multiplicado em float; padding 85/0/86/0 px (E/T/D/B), transparente |
| `assets/art/monsters/rastreador.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1242×1266 | 512×512 / 512×512 | 1609788 → 310646 | Lanczos com alfa pré-multiplicado em float; padding 5/0/5/0 px (E/T/D/B), transparente |
| `assets/art/monsters/sentinela.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1231×1278 | 512×512 / 512×512 | 1713820 → 313122 | Lanczos com alfa pré-multiplicado em float; padding 9/0/10/0 px (E/T/D/B), transparente |
| `assets/art/reference/char_rat_sheet_base.png` | JPEG / `ffd8ffe000104a464946000101000001` | 1696×2528 | 832×1216 / 832×1216 | 2247261 → 1248520 | Lanczos opaco; padding 8/0/8/0 px (E/T/D/B), extensão de borda |
| `assets/art/ui/icon_ending.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1226418 → 25532 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/ui/icon_schedule.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 1083324 → 21383 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/ui/icon_success.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 128×128 / 128×128 | 516611 → 11292 | Lanczos com alfa pré-multiplicado em float |
| `assets/art/ui/ui_panel.png` | PNG / `89504e470d0a1a0a0000000d49484452` | 1254×1254 | 512×512 / 512×512 | 2086111 → 301315 | Lanczos opaco |

## Transparência por arquivo reparado

Valores de alfa de 0 a 255; são contagens de pixels reais, não apenas presença de canal. Todos os arquivos com transparência obrigatória conservam pixels de alfa zero e pixels parcialmente transparentes. Os demais mantêm a opacidade original.

| Caminho | Alfa original min–max | Alfa final min–max | Pixels finais transparentes | Pixels finais parciais |
|---|---|---|---:|---:|
| `assets/art/backgrounds/bg_bedroom_day.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/backgrounds/bg_ending.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/char_rat_casual_a_tired.png` | 0–255 | 0–255 | 269932 | 121279 |
| `assets/art/characters/char_rat_idle.png` | 0–255 | 0–255 | 278194 | 113122 |
| `assets/art/characters/char_rat_work.png` | 0–254 | 0–255 | 254992 | 136023 |
| `assets/art/characters/portrait_rat_angry.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_happy.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_neutral.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_sad.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_shy.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_sick.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_surprised.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/characters/portrait_rat_tired.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/endings/aprendiz_de_ciborgues.png` | 0–255 | 0–255 | 10799 | 5261 |
| `assets/art/endings/artista_emergente.png` | 0–255 | 0–255 | 10677 | 4997 |
| `assets/art/endings/autora_emergente.png` | 0–255 | 0–255 | 8405 | 7654 |
| `assets/art/endings/caminho_equilibrado.png` | 0–255 | 0–255 | 8245 | 7865 |
| `assets/art/endings/defensora_das_ruas.png` | 0–255 | 0–255 | 9086 | 7042 |
| `assets/art/endings/evadida_do_sistema.png` | 0–255 | 0–255 | 7876 | 8172 |
| `assets/art/endings/guardia_da_rede.png` | 0–255 | 0–255 | 7391 | 8626 |
| `assets/art/endings/hacker_de_elite.png` | 0–255 | 0–255 | 8061 | 8046 |
| `assets/art/endings/lider_comunitaria_jovem.png` | 0–255 | 0–255 | 7697 | 8380 |
| `assets/art/endings/mecanica_de_campo.png` | 0–255 | 0–255 | 8194 | 7805 |
| `assets/art/endings/mediadora_comunitaria.png` | 0–255 | 0–255 | 9770 | 6125 |
| `assets/art/endings/promessa_corporativa.png` | 0–255 | 0–255 | 7578 | 8482 |
| `assets/art/endings/recruta_do_submundo.png` | 0–255 | 0–255 | 8444 | 7685 |
| `assets/art/endings/tecnica_juvenil_da_cidade.png` | 0–255 | 0–255 | 9731 | 6373 |
| `assets/art/endings/voz_das_ruas.png` | 0–255 | 0–255 | 7548 | 8370 |
| `assets/art/icons/icon_agenda.png` | 0–255 | 0–255 | 11722 | 4441 |
| `assets/art/icons/icon_city.png` | 0–254 | 0–255 | 12049 | 3987 |
| `assets/art/icons/icon_equipment.png` | 0–254 | 0–255 | 9399 | 6664 |
| `assets/art/icons/icon_mission.png` | 0–255 | 0–255 | 11519 | 4499 |
| `assets/art/icons/icon_profile.png` | 0–255 | 0–255 | 10543 | 5586 |
| `assets/art/icons/icon_stat_cha.png` | 0–255 | 0–255 | 10589 | 5561 |
| `assets/art/icons/icon_stat_eth.png` | 0–255 | 0–255 | 11307 | 4760 |
| `assets/art/icons/icon_stat_int.png` | 0–255 | 0–255 | 10942 | 5217 |
| `assets/art/icons/icon_stat_ref.png` | 0–255 | 0–255 | 11666 | 4286 |
| `assets/art/icons/icon_stat_sta.png` | 0–255 | 0–255 | 10815 | 5326 |
| `assets/art/icons/icon_stat_str.png` | 0–255 | 0–255 | 10778 | 5256 |
| `assets/art/icons/icon_talk.png` | 0–254 | 0–255 | 12435 | 3684 |
| `assets/art/items/adesivo_recuperacao.png` | 0–254 | 0–255 | 11633 | 4516 |
| `assets/art/items/casaco_acolchoado.png` | 0–255 | 0–255 | 6902 | 9127 |
| `assets/art/items/kit_ferramentas.png` | 0–255 | 0–255 | 8549 | 7550 |
| `assets/art/monsters/drone_patrulha.png` | 0–254 | 0–255 | 202572 | 58195 |
| `assets/art/monsters/rastreador.png` | 0–255 | 0–255 | 145636 | 115149 |
| `assets/art/monsters/sentinela.png` | 0–255 | 0–255 | 141921 | 118795 |
| `assets/art/reference/char_rat_sheet_base.png` | 255–255 | 255–255 | 0 | 0 |
| `assets/art/ui/icon_ending.png` | 0–255 | 0–255 | 8058 | 8068 |
| `assets/art/ui/icon_schedule.png` | 0–255 | 0–255 | 9499 | 6615 |
| `assets/art/ui/icon_success.png` | 0–255 | 0–255 | 13528 | 2630 |
| `assets/art/ui/ui_panel.png` | 255–255 | 255–255 | 0 | 0 |

## Hashes e rastreabilidade

Os hashes originais abaixo correspondem aos backups externos, não aos bytes finais. O inventário de migração permanece histórico e não foi reescrito.

| Caminho | SHA256 original / backup | SHA256 final |
|---|---|---|
| `assets/art/backgrounds/bg_bedroom_day.png` | `730200161a1d1344dd203c4b1ecdcb8ca50b34e6e40df819bd1628f362b7455a` | `a0b81b14ebaafdd1d01f5f64c2007250d0643e784d01b0fde93eae03d32bde29` |
| `assets/art/backgrounds/bg_ending.png` | `f0f5e678cb8390fb5c0d2a5698cb7e3fed020edd9f055a7024de83e29744251a` | `68e44c56f123ab3d09e14b52e3b6e6ae16380914c0496ff41ecd5e01a29b6b39` |
| `assets/art/characters/char_rat_casual_a_tired.png` | `72b8ac562130007cd9c859aae09b3594e5e80b4d360e23efdfaf15093961a561` | `b2459ad9224c5367fdb61236339444710095a114fed4f3247c9bcd3b9e478fa1` |
| `assets/art/characters/char_rat_idle.png` | `2cedc364c1d900871ef7318d49b51ad085f77b39a5c3ef752d50fd1a920901c1` | `6a0d4e1be645c1a1e7827d7f3935c3483fd97fdbf76a7d767652978fd85f9ffd` |
| `assets/art/characters/char_rat_work.png` | `74f5b408fa428d307de57927c6800ee1d8ad100cd2cc9823ae9010359f937da2` | `b79978c1686f7558015990036e1c74a29c80a765d8c08edfad6e4dd05cd7b1e6` |
| `assets/art/characters/portrait_rat_angry.png` | `2b30debac056c0e87b0e4ebdc44ccccf547a8b138cb65af69ac43d40d7687546` | `8f9cd4c341ec637980c4361cb3f2af34ae0e48ce6594a86c3509f931b8fc9491` |
| `assets/art/characters/portrait_rat_happy.png` | `eeb805f2aabd6de4326f10c8efff6bea4e6182f017b59cb989e8eb2087a88bff` | `f666db1c0004c5dd9bae7951340c53030ef88908b3bc679c281ead0c2bc32f5b` |
| `assets/art/characters/portrait_rat_neutral.png` | `85d38b5d4b5893ee10e952156a2b859c409a71338eb56cc5e8f14daa17e76b31` | `f6c45a54631540b3f70095dc312d9ef8327c5d79ff5cbed63c71331335a34a9d` |
| `assets/art/characters/portrait_rat_sad.png` | `d43376a471e43374b34032b849272c9a5eebda52d3b31e79f9924e7d93715e1b` | `59a0c00d08be430abe8603e53178eb42bc676ddf856c1215cdff0eddd3c4e111` |
| `assets/art/characters/portrait_rat_shy.png` | `9ed109e50f569aa04f589a75b9474fcbecbb3ec39da1636da1641443387472bb` | `4f4884251f9c1ea817467b99762b2660b227e3504aca3472ef6b5331fe3e2de3` |
| `assets/art/characters/portrait_rat_sick.png` | `5da4c6e3064a83c314146293043233d6dbda48ff0f57e280e0f1618dfd39af35` | `13a64ded79b3fc807f4fad12c9186087af092a96a384f408486298967b41a5fe` |
| `assets/art/characters/portrait_rat_surprised.png` | `59eb1c76b88b3e274198bce068fc5681ab9c3b7c46355f3d6867dc6a4da525eb` | `f114b5e5784d485034243eab27e2652c8cd4c283a812895ef1aa153fb5e9f34c` |
| `assets/art/characters/portrait_rat_tired.png` | `1843925a125e94d627b0316b77f89df82dde2647ac35bc1e1474155fd912c59f` | `4d96b5284652c14f325ccae68282c75a20176ae3f1ef6f746d5c292bf854520d` |
| `assets/art/endings/aprendiz_de_ciborgues.png` | `27d61328ef56401c6ebf7c0ca75dfc2f0a3458344fc6979a99e8147a1058a8c8` | `149f2e9f1e4bbf1977b33e447dccb4e1d32daf83a9b6b28693d01ee73deeb9f9` |
| `assets/art/endings/artista_emergente.png` | `22243ff0f2fa699a93dc952483e52876afe4543b42b7e34c3d5f8d2ca64bac76` | `f2c06a91bff77d730ae16ae14fed33e8486a4947d35821d510b230520a8c8f5c` |
| `assets/art/endings/autora_emergente.png` | `fac80b2a035805bd1cda23b08281fc7f476c2784ff7bc6d8493e6f0b8c3379c8` | `2b3326aa2030f3546588410db1bb6b7d68ea0838b94ff2a02861115f2eaf857c` |
| `assets/art/endings/caminho_equilibrado.png` | `779e2cda419c668d39358ae91ca22cd6775c755971a5a458c934521bf72465ca` | `8cfe726bc9511a2e7fe12ec332b05fb1675a6d2495010b823cd88b3b0560f78e` |
| `assets/art/endings/defensora_das_ruas.png` | `51b026567b9e9291ef66f2c33616911688cdf61ada925370b75b0e7fdb3df04b` | `594a5d58b8a5ab21294218f2c01dee1139e3ecfad4e2233358f2fd8a9d66061a` |
| `assets/art/endings/evadida_do_sistema.png` | `4ad4186b4987a114942808be51c987af5e7372a5cd333e0efed8946b0a7dd7be` | `8f67c0111b5b6f9ff360fec98d17586fdcd7e574e5709cccb1dc7cb873c890e7` |
| `assets/art/endings/guardia_da_rede.png` | `673d8a35d92f2554522f1912a80e55918ed4da4ea36a9a33c08802a1fa868bb3` | `32f440bd9cb607ed17de0be868d47d1ce262bd4b2c95d9b06a9da23eb6a1410b` |
| `assets/art/endings/hacker_de_elite.png` | `fc3842cba1dc26f3ac4fbb1dda7fa50a3fc20d942622de643f4593e3cf8f1ad7` | `d8011729696f7f949e480ae0dbac934c37161abf317e5146a944e0071a6c4ae8` |
| `assets/art/endings/lider_comunitaria_jovem.png` | `cb4c7a313a9f30b130449856b8d82e37326f46bf9ba2733a6b73482cbcb6d738` | `1526330fb881497f1ce9b531cc8d6922e093278dbb638ca682744d65413a06a5` |
| `assets/art/endings/mecanica_de_campo.png` | `c7df9b8c7d35caf18fee6e0a26f782cccf18866048b844b1a15c96dc324926c0` | `ef82a06f0e3449f24ae18bbb60f6c3a392734e4df0eaed8959b978c91a4e2b33` |
| `assets/art/endings/mediadora_comunitaria.png` | `4ad971cbc35d76465e85ef85eee88e435c7ec6a5cd5cf198e72fd70dd70a130c` | `632625a94ec59620941374cf2b6e2492b1aa2a94d4a84cb1a89bb828bd5815c4` |
| `assets/art/endings/promessa_corporativa.png` | `4653b2ce8e80a93487c56b3359660e4019099bc399d99f8d3fc59829152fe339` | `b82a08ea96732e41f36c319f869b609f920db690e4a8a65ffc280d2e6c377985` |
| `assets/art/endings/recruta_do_submundo.png` | `d7419395a7a8d188759166b15a76207243e05250e18408c45cc1ca7093ab6ae5` | `999e06be82cdc5f3a03659500a89096b121af8ec4d7ef2cb11dabb527bd6d4d6` |
| `assets/art/endings/tecnica_juvenil_da_cidade.png` | `dbe7015f7c3b9d6811f13b319f73691c61c8cb5bf25b709a56a82563938ec1ef` | `48ec8adda520a5455cc859078e2c21764ea600eabb15e1417ac8c345bd9fd3f1` |
| `assets/art/endings/voz_das_ruas.png` | `7f614d8d5fa577d8639a73f10aa4afc1d02ef4587d28a164eda8f4fcd75c6abb` | `73744bcda53b67a3fd588bbf2bbeadfebdd03c23be36aacee673c4f4000149f3` |
| `assets/art/icons/icon_agenda.png` | `b37dd6c76ddfe62b38a6cce5371dd8745a324f2ff24f4d4128b7a4da92c530e1` | `521820a68feae808cc82feef90f8af597615fa1f08730bbe1e1d064fc770f214` |
| `assets/art/icons/icon_city.png` | `d566966d6a43bd1457c95953df025c88804a3fe800f7664e55560d34707c793d` | `3c94acc584a4158d0fa248f87c92b11bf081609231133c9be92bd4123c1d0213` |
| `assets/art/icons/icon_equipment.png` | `db23f16c7b014d5bb6a5e1ba5146fb514a28d217532896fe477f18bfd59aa839` | `15641b8c659a76f3b266d47c68a9b3b6998d4377f572a018c6504079058ab3ee` |
| `assets/art/icons/icon_mission.png` | `5f7ed812704c40d335b538955ab34548d18d3927b559d23d74a2faef95277356` | `f5f081e82ac4d8c9de735b3036753f45effaaf362aec40c8a639cf92825278b6` |
| `assets/art/icons/icon_profile.png` | `01c90204414ada0b6a87de2ddaaf0d8ee53991df7bfe9b9a384051ef6492eae1` | `eee72ffd7c5e0adbf170066ab29591fcfdf19cdb2a74927e29ccbf4378246dcc` |
| `assets/art/icons/icon_stat_cha.png` | `8e93116acc1dfd822c83637f369670b55f5dceaa1575a0716e42c65a1a56006f` | `4cef067af6500fd46dd3d2b3404e16bf76909568b5001de6cca0cd0cf22aa094` |
| `assets/art/icons/icon_stat_eth.png` | `d6e73137b1a06d2e7163ac5889b8b4935e70f63ea4862540df80d5f21953309d` | `3dda4d93aa26e7c7ce595a24174412e103c0f277e55a13cfcef9a175a0381e2d` |
| `assets/art/icons/icon_stat_int.png` | `eca5ce649f06b12d4fa6dec86bf151dd9e473018c029bf295615ad090fca8b8b` | `24ad2b7889b82860e3e441dbb9fcfbc140af26cb7fe81a2d0ad9d0d468f58157` |
| `assets/art/icons/icon_stat_ref.png` | `b000604e8d2efcb84ca7201c6a102706d00a63cdc7c85f4007a483db3722803a` | `514d5e839a84216575d19ff4e86c957d8a75b0b47000571bc2edae9d1b61feaa` |
| `assets/art/icons/icon_stat_sta.png` | `8e446f562645a590ce6254994c2fc5609375c50cad9eeff24974fcb692a29702` | `1daa74ed3a0d7b971e4f22c1a37312a3357733c4191808b7b8cc3c94e2904ca9` |
| `assets/art/icons/icon_stat_str.png` | `c99365e97594879d4a8295ed31043a95906ac8b8d57dc8d551e51c68fc5dbad9` | `ac67b1224abc6a5387c8056f7d2e0a4ce122a3b92430b04c8a686e215459b454` |
| `assets/art/icons/icon_talk.png` | `817e7792de531271b16f8e6261bc1adf8f40472a6a8d8edb397344812a9efd23` | `49af628f1ad5589a02d5e2192ec92129b06b8d4d0cd1764bb7f3096f4cfced02` |
| `assets/art/items/adesivo_recuperacao.png` | `aa09e4a59b639468a44cd15fc23f3a54666845099da3ccfc605348d5d7d963f2` | `26cbc8434d48ead49f4638da489aff3b1de078995ea21048ae14adf565337448` |
| `assets/art/items/casaco_acolchoado.png` | `ef524908ee9d9e72d4e126ed22096e35194098a8569fcbc4313b286afee32172` | `d98714ecdcc49ac23cb4866b21a237c4b7dba4c72fb0e8d8ad81f4652af47a46` |
| `assets/art/items/kit_ferramentas.png` | `531ae972ddb725afa1d45e7331666577db19c117a54c4346249220e8a5deb01d` | `4ecb0262d64961646c002f77aa3906542f050a56846407dee6d7d8d6f2b90e29` |
| `assets/art/monsters/drone_patrulha.png` | `f7f7e057fb22ae7cc13740c1467350d4b22d32483f372b3300e728b796ccdf3f` | `0d54dc993521379b08577c848828974fdce2e09a4cfbc5fd49e895a4263307fa` |
| `assets/art/monsters/rastreador.png` | `08c678bda8be9bb632f530adafc3a03dbbf1136f553418a9e3c273760fbe9dbc` | `21351d6d5e6bc669b65a1b0d3ef318cd8a6de3ffe0dd785f602c0f76d835d2c7` |
| `assets/art/monsters/sentinela.png` | `25f545f68788324bba5d9d24455039a954c8c44d3bb413fb74135a181f5c3737` | `071c9698367c572827fd9c8f97eb4823da21a7d99664719fe0a3ddd4ef6ddcfd` |
| `assets/art/reference/char_rat_sheet_base.png` | `c6ddf82cb9defbd816444fa7cdd5c2c4519282293d02614f617bc8428ffe616b` | `d22cbcb21ddc980b5fa4f981470104489d0fe122f99a277581abe4548798e9c8` |
| `assets/art/ui/icon_ending.png` | `54b13c813f8a86c83135d810a1d12f77f73c84bcf070fdfa836f6e117ac3005a` | `977d316c0145e1e72ef291c069f3fcd839576774594ed1a75def1072e73e78ca` |
| `assets/art/ui/icon_schedule.png` | `b9c9af6e60ffe949a30f6e6de460e73d365169ebb6a7b8dd7514708efab023ed` | `28b2229f713987d3b72182cce58b25053fdac5d6210d3308cfba971c00c7751e` |
| `assets/art/ui/icon_success.png` | `85d4e2a076608c9337c31070a0953b9c6cf3d0008fa821445b0479806a2aa0f6` | `107c15e5ff00a3b9a138c53ab9ee40317c1980579df07a1fa89f896d23a01b90` |
| `assets/art/ui/ui_panel.png` | `b9040330a9077a4b818cf9754d72d40f131a89b8797ff1c0f8edc127b01af201` | `9713caa32765ccb986cc59ea34accbfaa24e6f68f2956110de5861a787c857b9` |

## Verificação Godot e runtime

Executados na raiz canônica pelo wrapper do repositório. Pasta temporária abreviada nos comandos abaixo como `$taskTemp`, exatamente a pasta externa registrada neste relatório.

```powershell
$taskTemp = 'C:/Users/João/AppData/Local/Temp/rat-trainer-art-remediation-bmypx9re'
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --editor --quit --log-file "$taskTemp/import.log"
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --log-file "$taskTemp/art-test.log" -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/art_integration_test.gd
```

A primeira importação retornou **0**, mas manteve os cinco sidecars anteriormente marcados `valid=false`. O primeiro teste ainda retornou **100**, com as três asserções do caso `test_every_installed_game_texture_resolves_as_final_art` falhando: linha 21 esperava 98 finais e obteve 93; linha 22 esperava 0 placeholders e obteve 4; linha 23 esperava 0 gerados e obteve 1. Evidência `reports/report_215/results.xml`. Os testes de itens e monstros passaram. Não foram alterados testes ou resolvedor.

Em seguida foi solicitada a reimportação oficial pelo editor ativo, via Funplay `execute_code`, sem excluir ou editar metadados manualmente:

```gdscript
var paths = PackedStringArray(["res://assets/art/backgrounds/bg_bedroom_day.png", "res://assets/art/icons/icon_agenda.png", "res://assets/art/icons/icon_city.png", "res://assets/art/icons/icon_profile.png", "res://assets/art/characters/char_rat_casual_a_tired.png"])
EditorInterface.get_resource_filesystem().reimport_files(paths)
```

O editor regenerou os sidecars e texturas importadas normalmente, preservando os UIDs. Evidência externa: `reimport-mcp.json`. Reexecuções:

```powershell
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --log-file "$taskTemp/art-test-final.log" -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/art_integration_test.gd
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --log-file "$taskTemp/probe.log" --script "$taskTemp/probe.gd" -- "$taskTemp/runtime-resolution.json"
& 'C:/Program Files/Git/bin/bash.exe' tools/godot.sh --headless --path . --editor --quit --log-file "$taskTemp/import-final.log"
```

**Teste final: exit 0, 3 casos, 0 erros, 0 falhas, 0 órfãos**; `reports/report_216/results.xml`. O teste solicita todas as 98 texturas de jogo instaladas e confirma 98 finais, nenhum placeholder e nenhuma textura gerada. A referência interna continua excluída da cobertura de runtime por `.gdignore`. Não foram executadas ou modificadas outras suítes de gameplay nesta tarefa.

**Sondagem independente: exit 0, exatamente quatro IDs solicitados e quatro finais.** Não são atribuídos à sondagem assets que ela não requisitou:

| ID | Fonte confirmada | Dimensões de runtime | Caminho |
|---|---|---|---|
| `backgrounds/bg_bedroom_day` | final | 1024×768 | `res://assets/art/backgrounds/bg_bedroom_day.png` |
| `icons/icon_agenda` | final | 128×128 | `res://assets/art/icons/icon_agenda.png` |
| `icons/icon_city` | final | 128×128 | `res://assets/art/icons/icon_city.png` |
| `icons/icon_profile` | final | 128×128 | `res://assets/art/icons/icon_profile.png` |

**Importação final: exit 0.** Permanecem mensagens ambientais preexistentes: falha na leitura do repositório de certificados do sistema e impossibilidade de salvar `Godot/editor_settings-4.5.tres` fora do workspace. Não há erro de importação das imagens corrigidas no teste final. Não se interpreta exit 0 como ausência de toda mensagem de erro ambiental. Os logs completos estão na pasta externa; não houve escalonamento de permissões para gravar configurações globais.

## Git, temporários e escopo preservado

`.gitignore` **sem alterações**. Todos os 51 PNGs reparados e este relatório foram verificados juntos com `git check-ignore -v --stdin`: **exit 1, saída vazia**, portanto nenhum é ignorado. Eles permanecem disponíveis para revisão e commit manual. Não foi acrescentada nenhuma regra.

`git check-ignore -v -- .godot/imported/probe.ctex assets/art/icons/icon_city.png.import reports/art-remediation-review-bmypx9re/comparison_01.png builds/probe.txt` retornou **exit 0**:

```text
.gitignore:2:.godot/	.godot/imported/probe.ctex
.gitignore:10:*.import	assets/art/icons/icon_city.png.import
.gitignore:7:reports/	reports/art-remediation-review-bmypx9re/comparison_01.png
.gitignore:11:builds/	builds/probe.txt
```

Backups, candidatas, scripts auxiliares, JSONs de evidência e logs ficam fora do repositório em `%TEMP%`, sem necessidade de regra Git. As pranchas de inspeção dentro de reports/ já são ignoradas pela regra existente.

Conferência de preservação: **172 arquivos preexistentes** em src/, assets/data/, project.godot, CREDITS.md, .gitignore e na pasta da auditoria antiga mantiveram seus SHA256. Nenhum desses arquivos foi modificado. Mudanças anteriores do usuário foram preservadas. `.import` foi atualizado apenas pelo Godot e continua ignorado.

Lista de mudanças desta tarefa: os **51 caminhos de imagem** listados no inventário acima e este único relatório Markdown. Os 48 arquivos de imagem restantes mantêm dimensões corretas e não foram regravados pelo conversor. Nenhum arquivo foi adicionado ao índice ou commitado.

## Pendências para revisão

- Revisar visualmente a apresentação dos ícones reduzidos a 128×128 e o encaixe proporcional dos assets originalmente largos; a composição inteira foi preservada.
- O inventário de migração, os créditos e a auditoria anterior descrevem o estado histórico e não foram alterados, conforme o escopo solicitado. Este relatório registra os novos hashes e o runtime atual.
- Permanecem **22 arquivos de arte de jogo acima de 1 MB**, sobretudo artes não alteradas nesta tarefa; são alertas, sem compressão com perdas ou otimização adicional.
- Não resta incompatibilidade de formato/extensão nem divergência de dimensão entre os 99 arquivos medidos. Nenhuma outra falha de gameplay foi investigada ou declarada corrigida.

Mensagem de commit sugerida (nenhum commit criado): `fix(art): repair image encodings and documented dimensions`
