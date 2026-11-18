# Auditoria visual de arte — 18/11/2026

Escopo: projeto canônico na raiz, Godot 4.5.1. Foram lidos AGENTS.md, CLAUDE.md, README.md, regra de cenas, skill local Funplay, manifesto, guia de geração, índices de arte, proveniência, resolvedores, consumidores de texturas, cenas, tema e dados JSON. Alterações preexistentes foram preservadas. Nenhum PNG, ID, dado de gameplay ou regra do jogo foi alterado.

**Cobertura estática e resolução exaustiva:** 40 IDs de textura: 36 Final, 4 Placeholder, 0 Generated. Esta lista inclui consumidores legados e fallbacks condicionais, identificados abaixo. Nas cinco telas capturadas foram solicitados 26 IDs distintos: 22 finais e 4 placeholders. A sondagem posterior solicitou explicitamente os 40 IDs e confirmou 36/4/0; ver [evidência do resolvedor](after/resolution.json).

**Bloqueio principal:** cinco arquivos são WebP com extensão `.png`. O importador PNG do Godot os marcou `valid=false`; a leitura como WebP em memória confirmou conteúdo válido, mas esse não é o caminho usado pelo resolvedor. Quatro estão em uso: `backgrounds/bg_bedroom_day`, `icons/icon_agenda`, `icons/icon_city`, `icons/icon_profile`. O quinto, `characters/char_rat_casual_a_tired`, não está em uso. A referência interna também é JPEG com extensão PNG, mas está sob `.gdignore`. Não foram convertidos ou renomeados: esta passagem está restrita a apresentação e documentação.

## Cobertura por ID

Final significa fonte efetivamente carregada pelo resolvedor; não significa aprovação estética ou conformidade total com o guia. “—” na coluna de pendência significa que não falta arquivo, mas a validação técnica abaixo ainda pode registrar alertas. IDs citados apenas em geradores de placeholders ou dicionários sem chamada ao resolvedor não são contados como consumidores.

| ID | Categoria | Referência(s) | Fonte | Arquivo final | Placeholder | Pendência / contexto |
|---|---|---|---|---|---|---|
| `bg_bedroom_day` | backgrounds | `src/scenes/MainScreen.gd:146` | Placeholder | `assets/art/backgrounds/bg_bedroom_day.png` | presente | WebP disfarçado de PNG: precisa exportação PNG real; fallback confirmado; ativo |
| `bg_ending` | backgrounds | `src/ui/widgets/EndingScreen.gd:71; CreditsScreen.gd:29` | Final | `assets/art/backgrounds/bg_ending.png` | presente | —; ativo |
| `char_rat_idle` | characters | `src/scenes/MainScreen.gd:159; src/ui/widgets/CharacterCard.gd:50; src/scenes/ProfileScreen.gd:41` | Final | `assets/art/characters/char_rat_idle.png` | presente | —; ativo |
| `aprendiz_de_ciborgues` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/aprendiz_de_ciborgues.png` | presente | —; ativo |
| `artista_emergente` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/artista_emergente.png` | presente | —; ativo |
| `autora_emergente` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/autora_emergente.png` | presente | —; ativo |
| `caminho_equilibrado` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/caminho_equilibrado.png` | presente | —; ativo |
| `defensora_das_ruas` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/defensora_das_ruas.png` | presente | —; ativo |
| `evadida_do_sistema` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/evadida_do_sistema.png` | presente | —; ativo |
| `guardia_da_rede` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/guardia_da_rede.png` | presente | —; ativo |
| `hacker_de_elite` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/hacker_de_elite.png` | presente | —; ativo |
| `lider_comunitaria_jovem` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/lider_comunitaria_jovem.png` | presente | —; ativo |
| `mecanica_de_campo` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/mecanica_de_campo.png` | presente | —; ativo |
| `mediadora_comunitaria` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/mediadora_comunitaria.png` | presente | —; ativo |
| `promessa_corporativa` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/promessa_corporativa.png` | presente | —; ativo |
| `recruta_do_submundo` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/recruta_do_submundo.png` | presente | —; ativo |
| `tecnica_juvenil_da_cidade` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/tecnica_juvenil_da_cidade.png` | presente | —; ativo |
| `voz_das_ruas` | endings | `src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294; assets/data/endings.json` | Final | `assets/art/endings/voz_das_ruas.png` | presente | —; ativo |
| `icon_agenda` | icons | `src/scenes/MainScreen.gd:16,250` | Placeholder | `assets/art/icons/icon_agenda.png` | presente | WebP disfarçado de PNG: precisa exportação PNG real; fallback confirmado; ativo |
| `icon_city` | icons | `src/scenes/MainScreen.gd:16,250` | Placeholder | `assets/art/icons/icon_city.png` | presente | WebP disfarçado de PNG: precisa exportação PNG real; fallback confirmado; ativo |
| `icon_equipment` | icons | `src/scenes/MainScreen.gd:16,250` | Final | `assets/art/icons/icon_equipment.png` | presente | —; ativo |
| `icon_mission` | icons | `src/scenes/MainScreen.gd:16,250` | Final | `assets/art/icons/icon_mission.png` | presente | —; ativo |
| `icon_profile` | icons | `src/scenes/MainScreen.gd:16,250` | Placeholder | `assets/art/icons/icon_profile.png` | presente | WebP disfarçado de PNG: precisa exportação PNG real; fallback confirmado; ativo |
| `icon_stat_cha` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_cha.png` | ausente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_stat_eth` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_eth.png` | ausente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_stat_int` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_int.png` | ausente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_stat_ref` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_ref.png` | ausente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_stat_sta` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_sta.png` | ausente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_stat_str` | icons | `src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94` | Final | `assets/art/icons/icon_stat_str.png` | presente | —; consumidor legado; ausente no StatusPanel ativo |
| `icon_talk` | icons | `src/scenes/MainScreen.gd:16,250` | Final | `assets/art/icons/icon_talk.png` | presente | —; ativo |
| `adesivo_recuperacao` | items | `src/ui/widgets/ItemManagementScreen.gd:249; assets/data/items.json` | Final | `assets/art/items/adesivo_recuperacao.png` | ausente | —; ativo |
| `casaco_acolchoado` | items | `src/ui/widgets/ItemManagementScreen.gd:249; assets/data/items.json` | Final | `assets/art/items/casaco_acolchoado.png` | ausente | —; ativo |
| `kit_ferramentas` | items | `src/ui/widgets/ItemManagementScreen.gd:249; assets/data/items.json` | Final | `assets/art/items/kit_ferramentas.png` | ausente | —; ativo |
| `drone_patrulha` | monsters | `src/ui/widgets/EncounterScreen.gd:111; assets/data/monsters.json` | Final | `assets/art/monsters/drone_patrulha.png` | ausente | —; ativo |
| `rastreador` | monsters | `src/ui/widgets/EncounterScreen.gd:111; assets/data/monsters.json` | Final | `assets/art/monsters/rastreador.png` | ausente | —; ativo |
| `sentinela` | monsters | `src/ui/widgets/EncounterScreen.gd:111; assets/data/monsters.json` | Final | `assets/art/monsters/sentinela.png` | ausente | —; ativo |
| `icon_ending` | ui | `src/ui/widgets/EndingScreen.gd:297` | Final | `assets/art/ui/icon_ending.png` | ausente | —; fallback condicional |
| `icon_schedule` | ui | `src/ui/widgets/ScheduleButton.gd:25` | Final | `assets/art/ui/icon_schedule.png` | ausente | —; widget legado |
| `icon_success` | ui | `src/ui/widgets/ActivityResult.gd:54` | Final | `assets/art/ui/icon_success.png` | ausente | —; ativo |
| `ui_panel` | ui | `src/ui/UITheme.gd:18` | Final | `assets/art/ui/ui_panel.png` | presente | —; ativo |

## Áudio — cobertura complementar

O manifesto é visual. O jogo também usa `music/bgm_title` e `ui/ui_confirm` em `src/core/AudioManager.gd:22,77`; `AudioResolver.gd:42–49` gera tons quando faltam WAVs. Ambos são **Generated** (não entram nos totais de texturas). Não há áudio final nessas pastas. Arte final de áudio permanece pendente, fora do ajuste visual.

## Planejados sem consumidor de textura atual

Não são lacunas de gameplay. Status do manifesto preservado; nenhum asset foi promovido a Approved. Os quatro IDs Blocked são exclusões do catálogo, não tarefas para geração.

| Manifesto | ID | Categoria | Arquivo disponível | Status do manifesto |
|---|---|---|---|---|
| ASSET-001 | `char_rat_sheet_base` | Reference | presente; referência interna | In Progress |
| ASSET-042 | `char_rat_school` | Characters | ausente | Deferred |
| ASSET-043 | `char_rat_casual_b` | Characters | ausente | Deferred |
| ASSET-044 | `char_rat_work` | Characters | presente | In Progress |
| ASSET-045 | `char_rat_hacker` | Characters | ausente | Deferred |
| ASSET-046 | `char_rat_armor` | Characters | ausente | Deferred |
| ASSET-047 | `char_rat_gala` | Characters | ausente | Blocked |
| ASSET-048 | `char_rat_casual_a_tired` | Characters | presente; importação inválida | In Progress |
| ASSET-049 | `char_rat_school_tired` | Characters | ausente | Deferred |
| ASSET-050 | `char_rat_casual_b_tired` | Characters | ausente | Deferred |
| ASSET-051 | `char_rat_work_tired` | Characters | ausente | Deferred |
| ASSET-052 | `char_rat_hacker_tired` | Characters | ausente | Deferred |
| ASSET-053 | `char_rat_armor_tired` | Characters | ausente | Deferred |
| ASSET-054 | `char_rat_gala_tired` | Characters | ausente | Blocked |
| ASSET-055 | `char_rat_casual_a_sick` | Characters | ausente | Deferred |
| ASSET-056 | `char_rat_casual_b_sick` | Characters | ausente | Deferred |
| ASSET-057 | `portrait_rat_neutral` | Characters | presente | In Progress |
| ASSET-058 | `portrait_rat_happy` | Characters | presente | In Progress |
| ASSET-059 | `portrait_rat_angry` | Characters | presente | In Progress |
| ASSET-060 | `portrait_rat_sad` | Characters | presente | In Progress |
| ASSET-061 | `portrait_rat_surprised` | Characters | presente | In Progress |
| ASSET-062 | `portrait_rat_tired` | Characters | presente | In Progress |
| ASSET-063 | `portrait_rat_shy` | Characters | presente | In Progress |
| ASSET-064 | `portrait_rat_sick` | Characters | presente | In Progress |
| ASSET-065 | `portrait_guardian_neutral` | Characters | ausente | Deferred |
| ASSET-066 | `portrait_guardian_happy` | Characters | ausente | Deferred |
| ASSET-067 | `portrait_guardian_worried` | Characters | ausente | Deferred |
| ASSET-068 | `char_guardian_idle` | Characters | ausente | Deferred |
| ASSET-069 | `bg_bedroom_night` | Backgrounds | presente | In Progress |
| ASSET-070 | `bg_street_night` | Backgrounds | presente | In Progress |
| ASSET-071 | `bg_corp_lobby` | Backgrounds | presente | In Progress |
| ASSET-072 | `bg_market` | Backgrounds | presente | In Progress |
| ASSET-073 | `bg_workshop` | Backgrounds | presente | In Progress |
| ASSET-074 | `bg_school` | Backgrounds | presente | In Progress |
| ASSET-075 | `bg_clinic` | Backgrounds | presente | In Progress |
| ASSET-076 | `bg_shop_weapons` | Backgrounds | ausente | Blocked |
| ASSET-077 | `bg_shop_fashion` | Backgrounds | presente | In Progress |
| ASSET-078 | `bg_shop_black_market` | Backgrounds | presente | In Progress |
| ASSET-079 | `bg_mission_factory` | Backgrounds | presente | In Progress |
| ASSET-080 | `bg_mission_subway` | Backgrounds | presente | In Progress |
| ASSET-081 | `bg_mission_rooftop` | Backgrounds | presente | In Progress |
| ASSET-082 | `bg_bedroom_day_b` | Backgrounds | presente | In Progress |
| ASSET-083 | `scene_work_mechanic` | Backgrounds | presente | In Progress |
| ASSET-084 | `scene_work_courier` | Backgrounds | presente | In Progress |
| ASSET-085 | `scene_work_clerk` | Backgrounds | presente | In Progress |
| ASSET-086 | `scene_study_tech` | Backgrounds | presente | In Progress |
| ASSET-087 | `scene_study_etiquette` | Backgrounds | presente | In Progress |
| ASSET-088 | `scene_study_combat` | Backgrounds | presente | In Progress |
| ASSET-089 | `scene_rest_home` | Backgrounds | presente | In Progress |
| ASSET-090 | `scene_leisure_park` | Backgrounds | presente | In Progress |
| ASSET-091 | `cg_festival_parkour` | Backgrounds | presente | In Progress |
| ASSET-092 | `cg_festival_hacking` | Backgrounds | presente | In Progress |
| ASSET-093 | `cg_festival_drones` | Backgrounds | presente | In Progress |
| ASSET-094 | `cg_merchant` | Backgrounds | presente | In Progress |
| ASSET-095 | `cg_chase` | Backgrounds | presente | In Progress |
| ASSET-096 | `cg_defeat_carried` | Backgrounds | presente | In Progress |
| ASSET-097 | `cg_birthday` | Backgrounds | presente | In Progress |
| ASSET-098 | `cg_gala` | Backgrounds | ausente | Blocked |
| ASSET-099 | `ui_frame_mission` | UI | presente | In Progress |
| ASSET-100 | `ui_dialog_box` | UI | presente | In Progress |
| ASSET-101 | `ui_hex_button` | UI | presente | In Progress |
| ASSET-102 | `icon_stress` | Icons | presente | In Progress |
| ASSET-103 | `icon_credits` | Icons | presente | In Progress |
| ASSET-104 | `icon_menu_rest` | Icons | presente | In Progress |
| ASSET-105 | `icon_menu_options` | Icons | presente | In Progress |
| ASSET-106 | `item_jacket_hardlight` | Items | ausente | Deferred |
| ASSET-107 | `item_implant_focus` | Items | ausente | Deferred |
| ASSET-108 | `item_energy_drink` | Items | ausente | Deferred |
| ASSET-109 | `item_cyber_glasses` | Items | ausente | Deferred |
| ASSET-110 | `item_gift_chip` | Items | ausente | Deferred |

Assets fora do catálogo de 110 IDs, também sem consumidor atual: `char_rat_casual_a_age12`, `char_rat_casual_a_age12_sick`, `char_rat_casual_a_age12_tired`, `char_rat_casual_a_age13`, `char_rat_casual_a_age13_sick`, `char_rat_casual_a_age13_tired`, `char_rat_casual_a_age14`, `char_rat_casual_a_age14_sick`, `char_rat_casual_a_age14_tired`, `char_rat_casual_a_age15`, `char_rat_casual_a_age15_sick`, `char_rat_casual_a_age15_tired`, `char_rat_school_age12`.

Os placeholders genéricos `items/item_generic` e `monsters/monster_generic` permanecem em disco para ferramentas/fallbacks anteriores; os consumidores atuais usam os IDs individuais dos JSONs. `icon_rest` e `icon_options` aparecem no dicionário legado MenuGrid, mas não há atribuição/chamada de textura para eles. Os IDs disponíveis `icon_menu_rest` e `icon_menu_options` não são substituições automáticas.

## Validação dos arquivos

Foram medidos 99 arquivos: 98 artes de jogo e 1 referência interna. Entre as artes de jogo: 50 divergências de dimensões, 1 cenário fora de 4:3, 58 arquivos acima de 1.000.000 bytes, 5 incompatibilidades formato/extensão. Nomes em snake_case: todos passam. Transparência exigida: nenhuma ausência total de alfa transparente nos arquivos decodificados.

Valores esperados: guia de geração, seções dos prompts 02–105; variantes por idade: registro `reviews/nyx-mvp-age-variants.md`. Cenários de tela inteira: 1024×768 / 4:3; vinhetas: 640×260; CGs: 1024×640. A razão larga de vinhetas/CGs é uma exceção documentada ao pedido geral de 4:3. Números de alfa são valores reais dos pixels, de 0 a 255, com contagens de pixels totalmente transparentes e parcialmente transparentes. RGB e JPEG são opacos. Dimensões maiores que o guia são divergências, mesmo que preservem a proporção. Alertas de peso não são reprovação automática.

**NOT ASSESSED:** halos em todas as bordas, consistência estética de todo o catálogo, aprovações humanas e composição de todas as imagens não exibidas. A medição de alfa não prova ausência de halos. Referência interna é exceção de uso; dimensão aproximada esperada 832×1216. `ui_panel` permite fundo opaco: “centro vazio” no guia é interpretado como sem texto/conteúdo.

| Arquivo | Medido | Esperado | Bytes | Alfa real | Nome / categoria | Resultado |
|---|---|---|---:|---|---|---|
| `assets/art/backgrounds/bg_bedroom_day.png` | 1024×765 | 1024×768 | 131708 | 255–255; zero=0; partial=0 | OK | FORMATO WebP com extensão PNG; DIMENSÕES; FORA DE 4:3 |
| `assets/art/backgrounds/bg_bedroom_day_b.png` | 1024×768 | 1024×768 | 1877533 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_bedroom_night.png` | 1024×768 | 1024×768 | 1862379 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_clinic.png` | 1024×768 | 1024×768 | 2027908 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_corp_lobby.png` | 1024×768 | 1024×768 | 2003805 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_ending.png` | 1448×1086 | 1024×768 | 2366511 | 255–255; zero=0; partial=0 | OK | DIMENSÕES; >1 MB |
| `assets/art/backgrounds/bg_market.png` | 1024×768 | 1024×768 | 2090074 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_mission_factory.png` | 1024×768 | 1024×768 | 2000217 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_mission_rooftop.png` | 1024×768 | 1024×768 | 1962446 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_mission_subway.png` | 1024×768 | 1024×768 | 1956713 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_school.png` | 1024×768 | 1024×768 | 2061460 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_shop_black_market.png` | 1024×768 | 1024×768 | 1997553 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_shop_fashion.png` | 1024×768 | 1024×768 | 2034855 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_street_night.png` | 1024×768 | 1024×768 | 2082504 | opaque | OK | >1 MB |
| `assets/art/backgrounds/bg_workshop.png` | 1024×768 | 1024×768 | 2005104 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_birthday.png` | 1024×640 | 1024×640 | 1757681 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_chase.png` | 1024×640 | 1024×640 | 1847096 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_defeat_carried.png` | 1024×640 | 1024×640 | 1736060 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_festival_drones.png` | 1024×640 | 1024×640 | 1777176 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_festival_hacking.png` | 1024×640 | 1024×640 | 1787750 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_festival_parkour.png` | 1024×640 | 1024×640 | 1780302 | opaque | OK | >1 MB |
| `assets/art/backgrounds/cg_merchant.png` | 1024×640 | 1024×640 | 1818736 | opaque | OK | >1 MB |
| `assets/art/backgrounds/scene_leisure_park.png` | 640×260 | 640×260 | 463644 | opaque | OK | OK |
| `assets/art/backgrounds/scene_rest_home.png` | 640×260 | 640×260 | 454913 | opaque | OK | OK |
| `assets/art/backgrounds/scene_study_combat.png` | 640×260 | 640×260 | 465418 | opaque | OK | OK |
| `assets/art/backgrounds/scene_study_etiquette.png` | 640×260 | 640×260 | 477133 | opaque | OK | OK |
| `assets/art/backgrounds/scene_study_tech.png` | 640×260 | 640×260 | 458100 | opaque | OK | OK |
| `assets/art/backgrounds/scene_work_clerk.png` | 640×260 | 640×260 | 466736 | opaque | OK | OK |
| `assets/art/backgrounds/scene_work_courier.png` | 640×260 | 640×260 | 479066 | opaque | OK | OK |
| `assets/art/backgrounds/scene_work_mechanic.png` | 640×260 | 640×260 | 465648 | opaque | OK | OK |
| `assets/art/characters/char_rat_casual_a_age12.png` | 512×768 | 512×768 | 375352 | 0–255; zero=270615; partial=120006 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age12_sick.png` | 512×768 | 512×768 | 394882 | 0–255; zero=265373; partial=125357 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age12_tired.png` | 512×768 | 512×768 | 364819 | 0–255; zero=275248; partial=115477 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age13.png` | 512×768 | 512×768 | 339444 | 0–255; zero=285185; partial=105472 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age13_sick.png` | 512×768 | 512×768 | 367283 | 0–255; zero=275418; partial=115450 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age13_tired.png` | 512×768 | 512×768 | 368616 | 0–255; zero=276091; partial=114809 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age14.png` | 512×768 | 512×768 | 351456 | 0–255; zero=279879; partial=110988 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age14_sick.png` | 512×768 | 512×768 | 368681 | 0–255; zero=273452; partial=117307 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age14_tired.png` | 512×768 | 512×768 | 365555 | 0–255; zero=271676; partial=119232 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age15.png` | 512×768 | 512×768 | 312146 | 0–255; zero=292904; partial=98271 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age15_sick.png` | 512×768 | 512×768 | 299414 | 0–255; zero=299283; partial=91443 | OK | OK |
| `assets/art/characters/char_rat_casual_a_age15_tired.png` | 512×768 | 512×768 | 317721 | 0–255; zero=293552; partial=97018 | OK | OK |
| `assets/art/characters/char_rat_casual_a_tired.png` | 1027×1531 | 512×768 | 623936 | 0–255; zero=1074458; partial=496813 | OK | FORMATO WebP com extensão PNG; DIMENSÕES |
| `assets/art/characters/char_rat_idle.png` | 1027×1531 | 512×768 | 937366 | 0–255; zero=1107608; partial=463849 | OK | DIMENSÕES |
| `assets/art/characters/char_rat_school_age12.png` | 512×768 | 512×768 | 318691 | 0–255; zero=287088; partial=104061 | OK | OK |
| `assets/art/characters/char_rat_work.png` | 1024×1536 | 512×768 | 1980834 | 0–254; zero=1012415; partial=560449 | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_angry.png` | 1254×1254 | 256×256 | 2308544 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_happy.png` | 1254×1254 | 256×256 | 2337000 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_neutral.png` | 1254×1254 | 256×256 | 2333100 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_sad.png` | 1254×1254 | 256×256 | 2355775 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_shy.png` | 1254×1254 | 256×256 | 2411141 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_sick.png` | 1254×1254 | 256×256 | 2339980 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_surprised.png` | 1254×1254 | 256×256 | 2346994 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/characters/portrait_rat_tired.png` | 1254×1254 | 256×256 | 2321671 | opaque | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/aprendiz_de_ciborgues.png` | 1254×1254 | 128×128 | 1252867 | 0–255; zero=1053844; partial=518243 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/artista_emergente.png` | 1254×1254 | 128×128 | 1207746 | 0–255; zero=1108180; partial=462576 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/autora_emergente.png` | 1254×1254 | 128×128 | 1383607 | 0–255; zero=845402; partial=725923 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/caminho_equilibrado.png` | 1254×1254 | 128×128 | 1732308 | 0–255; zero=825250; partial=746530 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/defensora_das_ruas.png` | 1254×1254 | 128×128 | 1473263 | 0–255; zero=903791; partial=668249 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/evadida_do_sistema.png` | 1254×1254 | 128×128 | 1837225 | 0–255; zero=790977; partial=780648 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/guardia_da_rede.png` | 1254×1254 | 128×128 | 1867032 | 0–255; zero=729621; partial=842666 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/hacker_de_elite.png` | 1254×1254 | 128×128 | 1470655 | 0–255; zero=810412; partial=761019 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/lider_comunitaria_jovem.png` | 1254×1254 | 128×128 | 1653809 | 0–255; zero=775458; partial=795797 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/mecanica_de_campo.png` | 1254×1254 | 128×128 | 1751957 | 0–255; zero=836812; partial=734383 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/mediadora_comunitaria.png` | 1254×1254 | 128×128 | 1316528 | 0–255; zero=991497; partial=579676 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/promessa_corporativa.png` | 1254×1254 | 128×128 | 1684292 | 0–255; zero=772008; partial=799456 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/recruta_do_submundo.png` | 1254×1254 | 128×128 | 1642468 | 0–255; zero=844524; partial=727334 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/tecnica_juvenil_da_cidade.png` | 1254×1254 | 128×128 | 1393174 | 0–255; zero=969948; partial=601783 | OK | DIMENSÕES; >1 MB |
| `assets/art/endings/voz_das_ruas.png` | 1254×1254 | 128×128 | 1724344 | 0–255; zero=766693; partial=805478 | OK | DIMENSÕES; >1 MB |
| `assets/art/icons/icon_agenda.png` | 1254×1254 | 128×128 | 545904 | 0–255; zero=1154141; partial=417557 | OK | FORMATO WebP com extensão PNG; DIMENSÕES |
| `assets/art/icons/icon_city.png` | 1536×1024 | 128×128 | 676604 | 0–254; zero=1012143; partial=560721 | OK | FORMATO WebP com extensão PNG; DIMENSÕES |
| `assets/art/icons/icon_credits.png` | 128×128 | 128×128 | 17960 | 0–255; zero=11170; partial=4956 | OK | OK |
| `assets/art/icons/icon_equipment.png` | 1536×1024 | 128×128 | 1975616 | 0–254; zero=615531; partial=957333 | OK | DIMENSÕES; >1 MB |
| `assets/art/icons/icon_menu_options.png` | 128×128 | 128×128 | 24240 | 0–255; zero=8504; partial=7500 | OK | OK |
| `assets/art/icons/icon_menu_rest.png` | 128×128 | 128×128 | 16545 | 0–255; zero=11561; partial=4433 | OK | OK |
| `assets/art/icons/icon_mission.png` | 1230×1278 | 128×128 | 903495 | 0–255; zero=1124738; partial=445806 | OK | DIMENSÕES |
| `assets/art/icons/icon_profile.png` | 1254×1254 | 128×128 | 649480 | 0–255; zero=1042543; partial=529119 | OK | FORMATO WebP com extensão PNG; DIMENSÕES |
| `assets/art/icons/icon_stat_cha.png` | 1281×1227 | 128×128 | 1028869 | 0–255; zero=1024766; partial=546608 | OK | DIMENSÕES; >1 MB |
| `assets/art/icons/icon_stat_eth.png` | 1237×1271 | 128×128 | 926729 | 0–255; zero=1113279; partial=457734 | OK | DIMENSÕES |
| `assets/art/icons/icon_stat_int.png` | 1232×1277 | 128×128 | 940984 | 0–255; zero=1057415; partial=515647 | OK | DIMENSÕES |
| `assets/art/icons/icon_stat_ref.png` | 1230×1278 | 128×128 | 831513 | 0–255; zero=1159782; partial=410729 | OK | DIMENSÕES |
| `assets/art/icons/icon_stat_sta.png` | 1229×1280 | 128×128 | 1034259 | 0–255; zero=1047035; partial=525522 | OK | DIMENSÕES; >1 MB |
| `assets/art/icons/icon_stat_str.png` | 1234×1274 | 128×128 | 961470 | 0–255; zero=1058217; partial=512896 | OK | DIMENSÕES |
| `assets/art/icons/icon_stress.png` | 128×128 | 128×128 | 12150 | 0–255; zero=12169; partial=3957 | OK | OK |
| `assets/art/icons/icon_talk.png` | 1536×1024 | 128×128 | 1418652 | 0–254; zero=1026976; partial=545888 | OK | DIMENSÕES; >1 MB |
| `assets/art/items/adesivo_recuperacao.png` | 1536×1024 | 128×128 | 1892210 | 0–254; zero=931368; partial=641496 | OK | DIMENSÕES; >1 MB |
| `assets/art/items/casaco_acolchoado.png` | 1254×1254 | 128×128 | 1461305 | 0–255; zero=704081; partial=866926 | OK | DIMENSÕES; >1 MB |
| `assets/art/items/kit_ferramentas.png` | 1295×1215 | 128×128 | 1416392 | 0–255; zero=805008; partial=766869 | OK | DIMENSÕES; >1 MB |
| `assets/art/monsters/drone_patrulha.png` | 1024×1536 | 512×512 | 1910192 | 0–254; zero=1041682; partial=531182 | OK | DIMENSÕES; >1 MB |
| `assets/art/monsters/rastreador.png` | 1242×1266 | 512×512 | 1609788 | 0–255; zero=861772; partial=709904 | OK | DIMENSÕES; >1 MB |
| `assets/art/monsters/sentinela.png` | 1231×1278 | 512×512 | 1713820 | 0–255; zero=826625; partial=745599 | OK | DIMENSÕES; >1 MB |
| `assets/art/reference/char_rat_sheet_base.png` | 1696×2528 | 832×1216 | 2247261 | opaco (JPEG) | OK | FORMATO JPEG com extensão PNG; referência excluída do runtime |
| `assets/art/ui/icon_ending.png` | 1254×1254 | 128×128 | 1226418 | 0–255; zero=805014; partial=766536 | OK | DIMENSÕES; >1 MB |
| `assets/art/ui/icon_schedule.png` | 1254×1254 | 128×128 | 1083324 | 0–255; zero=940634; partial=631013 | OK | DIMENSÕES; >1 MB |
| `assets/art/ui/icon_success.png` | 1254×1254 | 128×128 | 516611 | 0–255; zero=1324152; partial=247702 | OK | DIMENSÕES |
| `assets/art/ui/ui_dialog_box.png` | 800×200 | 800×200 | 139187 | 0–255; zero=40278; partial=117809 | OK | OK |
| `assets/art/ui/ui_frame_mission.png` | 1024×768 | 1024×768 | 418674 | 0–255; zero=625591; partial=159383 | OK | OK |
| `assets/art/ui/ui_hex_button.png` | 128×128 | 128×128 | 23249 | 0–255; zero=8714; partial=7365 | OK | OK |
| `assets/art/ui/ui_panel.png` | 1254×1254 | 512×512 | 2086111 | opaque | OK | DIMENSÕES; >1 MB |

## Ajuste aplicado

`src/ui/UITheme.gd:7`: `PANEL_CONTENT_MARGIN` de **12.0 → 20.0 px**, nos quatro lados dos PanelContainers que recebem o tema em runtime. Isso afasta conteúdo da borda sem exceder a largura disponível do menu (610 px de conteúdo + 40 px de margens = 650 px). NinePatch mantido em 16 px: a comparação visual não justificou ampliar as fatias. Âncoras, escala e ordem de camadas da personagem foram inspecionadas e mantidas, pois a silhueta completa já está dentro do espaço disponível. Nenhum fluxo, sinal, navegação, simulação ou JSON alterado nesta passagem.

Pendências visuais: ornamentos do painel de origem têm escala excessiva em alguns tamanhos; cabeçalhos em painéis grandes ainda podem coincidir com ornamentos. A posição preexistente do painel de status em relação ao cartão superior também permanece. Uma solução geral exigiria outra textura de painel ou ajustes de layout fora desta passagem.

## Capturas reais antes/depois

Capturadas no viewport renderizado do Godot, **1024×768**, com Compatibility/OpenGL, pelo cenário auxiliar `capture.tscn` e script `capture.gd`. Mesmo estado inicial da simulação, personagem, créditos, loja inicial, encontro Rastreador e galeria bloqueada. A simulação é inicializada apenas em memória, sem chamar Game.start_new_game, saves, compras, decisões de encontro ou avanço de tempo. Não são mockups. O “antes” já contém os assets finais migrados anteriormente; mostra o estado existente antes do ajuste de margem, inclusive os fallbacks causados pelos WebPs.

O perfil ativo é o painel Status expandido na MainScreen. ProfileScreen.tscn é um caminho legado, sem consumidor no fluxo principal, e não foi apresentado como captura do fluxo ativo. O título não usa os assets ajustados.

| Tela | Antes | Depois |
|---|---|---|
| Principal | [Abrir](before/main_screen.png) | [Abrir](after/main_screen.png) |
| Status expandido | [Abrir](before/status_screen.png) | [Abrir](after/status_screen.png) |
| Loja / itens | [Abrir](before/items_screen.png) | [Abrir](after/items_screen.png) |
| Encontro / missão | [Abrir](before/mission_screen.png) | [Abrir](after/mission_screen.png) |
| Galeria de finais | [Abrir](before/endings_screen.png) | [Abrir](after/endings_screen.png) |

## Créditos e proveniência

CREDITS.md recebeu uma lista explícita dos 36 IDs confirmados como Final pelo resolvedor, com caminho e ferramenta: geração de imagens nativa OpenAI no Codex (IA). Fonte: créditos preexistentes, inventário art-migration.json e registros de geração/revisão em design/assets/reviews/. Não se presume modelo exato. Os quatro arquivos usados com importação inválida não foram marcados final. Demais artes sem consumidor, incluindo referência interna, conservam seus status; nenhuma aprovação humana foi inferida.

## Verificação executada

Wrapper utilizado: `C:/Program Files/Git/bin/bash.exe tools/godot.sh` (Git Bash disponível; `bash` do PATH aponta para outro executável). Todos os comandos foram executados na raiz.

| Verificação | Argumentos após o wrapper | Exit / resultado |
|---|---|---|
| Importação | `--headless --path . --editor --quit --log-file <caminho absoluto>/import.log` | 0; com erros ambientais de certificado e de gravação de editor_settings fora do workspace. Não corrigiu os WebPs. |
| Teste de integração | `--headless --path . --log-file <caminho absoluto>/art-test.log -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/art_integration_test.gd` | 100; teste “every installed” falha em 3 asserções de contagem por causa dos 5 arquivos inválidos; testes individuais de itens e monstros passaram. Ver reports/report_213/results.xml. |
| MainScreen após ajuste | `--headless --path . --log-file <absoluto>/main-screen-test.log -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/main_screen_test.gd` | 100; 15 casos, 2 falhas e 1 erro. Falhas em main_screen_test.gd:91–92 (tela de missão nula) e :274 (fluxo mensal); teste de expansão de status e tema passou. Não foi demonstrada causalidade com esta mudança de margem; não foram corrigidos fluxos de gameplay. Evidência reports/report_214/results.xml. |
| Capturas | `--path . --log-file <absoluto>/<before ou after>.log --disable-shader-cache --rendering-method gl_compatibility res://design/assets/reviews/visual-art-pass/2026-11-18/capture.tscn -- before` (repetido com `after`) | 0 nos dois; 5 capturas por execução. Logs contêm erros de certificado, cache de shaders e 4 texturas finais inválidas. A sondagem completa posterior confirma 36/4/0. |
| Metadados WebP | `--headless --path . --log-file <absoluto>/webp-metadata.log --script res://design/assets/reviews/visual-art-pass/2026-11-18/webp_metadata.gd` | 0; decode explícito como WebP somente em memória; nenhum arquivo alterado. |
| Auditoria PNG | Python 3.14 existente: `audit.py` | 0; leitura stdlib, dimensões, bytes, filtros PNG e alfa real; ver measurements.json. Metadados WebP complementados em webp_metadata.json. |

A primeira tentativa de CLI com log padrão terminou em crash por acesso negado a user://logs; repetida com log absoluto dentro do workspace. Uma primeira versão do capturador via --script teve erros de autoload e foi substituída por um cenário normal, cuja execução final não tem esses erros. O endpoint Funplay respondeu get_project_info e confirmou a raiz; capturas finais usam diretamente o viewport do runtime. Os logs de compilação do projeto e as verificações finais estão nos arquivos desta pasta. Exit 0 não é apresentado como ausência de erros.

Conferência SHA256: 99 arquivos de assets/art/ continuam idênticos ao inventário original da migração; ver art-hashes.json. Funplay get_script_errors com caminho de arquivo devolveu checked=0; portanto esse resultado não é uma validação de compilação. As cenas com o tema alterado foram de fato executadas nas capturas e nos testes.

## Próximas ações

1. Reexportar os cinco WebPs como PNG real em uma etapa autorizada de edição dos assets; repetir importação e o teste que hoje falha. Prioridade para os quatro IDs usados. Nenhum ID precisa mudar.
2. Revisar divergências de dimensões/proporção e os alertas de peso; esta auditoria não redimensiona nem recomprime arquivos.
3. Revisar visualmente os cinco pares de capturas e decidir se o painel precisa de uma variante com ornamentos menores.
4. Os 20 IDs ausentes não bloqueados do manifesto continuam planejados, sem consumidor; os 4 Blocked permanecem excluídos.

Mensagem de commit sugerida (nenhum commit criado): `chore(art): audit asset coverage and adjust panel content margins`
