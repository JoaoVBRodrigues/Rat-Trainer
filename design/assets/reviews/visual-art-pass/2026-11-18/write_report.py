from pathlib import Path
import json, collections, struct, hashlib

OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[4]
data=json.loads((OUT/'measurements.json').read_text(encoding='utf-8'))
webp=json.loads((OUT/'webp_metadata.json').read_text(encoding='utf-8'))
runtime={r['key']:r for r in json.loads((OUT/'after/resolution.json').read_text(encoding='utf-8'))}
files=data['files']
inventory=json.loads((ROOT/'design/assets/art-migration.json').read_text(encoding='utf-8-sig'))
hash_results=[]
for item in inventory['files']:
    if item['target'].startswith('assets/art/'):
        measured=hashlib.sha256((ROOT/item['target']).read_bytes()).hexdigest()
        hash_results.append({'path':item['target'],'matches_migration':measured.lower()==item['sha256'].lower()})
assert all(item['matches_migration'] for item in hash_results)
(OUT/'art-hashes.json').write_text(json.dumps(hash_results,indent=2),encoding='utf-8')
for row in files:
    if row['path'] in webp:
        meta=webp[row['path']]
        row.update(meta)
        row['alpha']=f"{meta['alpha_min']}–{meta['alpha_max']}; zero={meta['zero']}; partial={meta['partial']}"
        row['warnings']=[w for w in row['warnings'] if not w.startswith('NOT PNG')]+['FORMATO WebP com extensão PNG']
        if (row['width'],row['height'])!=tuple(row['expected']): row['warnings'].append('DIMENSÕES')
        if row['category']=='backgrounds' and row['width']*3!=row['height']*4: row['warnings'].append('FORA DE 4:3')
    elif row.get('error') and 'ffd8' in row['error']:
        raw=(ROOT/row['path']).read_bytes()
        pos=2
        while pos<len(raw):
            if raw[pos]!=255: pos+=1; continue
            marker=raw[pos+1]; pos+=2
            if marker in (0xd8,0xd9): continue
            n=struct.unpack('>H',raw[pos:pos+2])[0]
            if marker in (0xc0,0xc1,0xc2):
                h,w=struct.unpack('>HH',raw[pos+3:pos+7]); row.update(width=w,height=h,alpha='opaco (JPEG)'); break
            pos+=n
        row['warnings']=['FORMATO JPEG com extensão PNG; referência excluída do runtime']
    row.pop('error',None)

counts=collections.Counter(r['source'] for r in data['coverage'])
warn=collections.Counter(w for f in files if f['category']!='reference' for w in f['warnings'])
text=['# Auditoria visual de arte — 18/11/2026','',
'Escopo: projeto canônico na raiz, Godot 4.5.1. Foram lidos AGENTS.md, CLAUDE.md, README.md, regra de cenas, skill local Funplay, manifesto, guia de geração, índices de arte, proveniência, resolvedores, consumidores de texturas, cenas, tema e dados JSON. Alterações preexistentes foram preservadas. Nenhum PNG, ID, dado de gameplay ou regra do jogo foi alterado.','',
f"**Cobertura estática e resolução exaustiva:** {len(data['coverage'])} IDs de textura: {counts['Final']} Final, {counts['Placeholder']} Placeholder, {counts['Generated']} Generated. Esta lista inclui consumidores legados e fallbacks condicionais, identificados abaixo. Nas cinco telas capturadas foram solicitados 26 IDs distintos: 22 finais e 4 placeholders. A sondagem posterior solicitou explicitamente os 40 IDs e confirmou 36/4/0; ver [evidência do resolvedor](after/resolution.json).",'',
'**Bloqueio principal:** cinco arquivos são WebP com extensão `.png`. O importador PNG do Godot os marcou `valid=false`; a leitura como WebP em memória confirmou conteúdo válido, mas esse não é o caminho usado pelo resolvedor. Quatro estão em uso: `backgrounds/bg_bedroom_day`, `icons/icon_agenda`, `icons/icon_city`, `icons/icon_profile`. O quinto, `characters/char_rat_casual_a_tired`, não está em uso. A referência interna também é JPEG com extensão PNG, mas está sob `.gdignore`. Não foram convertidos ou renomeados: esta passagem está restrita a apresentação e documentação.','',
'## Cobertura por ID','',
'Final significa fonte efetivamente carregada pelo resolvedor; não significa aprovação estética ou conformidade total com o guia. “—” na coluna de pendência significa que não falta arquivo, mas a validação técnica abaixo ainda pode registrar alertas. IDs citados apenas em geradores de placeholders ou dicionários sem chamada ao resolvedor não são contados como consumidores.','',
'| ID | Categoria | Referência(s) | Fonte | Arquivo final | Placeholder | Pendência / contexto |',
'|---|---|---|---|---|---|---|']
for entry in data['coverage']:
    cat,name=entry['category'],entry['id']; measured=runtime[cat+'/'+name]
    assert measured['source']==entry['source'].lower(),(name,measured)
    action='WebP disfarçado de PNG: precisa exportação PNG real; fallback confirmado' if entry['import_bad'] else '—'
    text.append(f"| `{name}` | {cat} | `{entry['where']}` | {entry['source']} | `assets/art/{cat}/{name}.png` | {'presente' if entry['placeholder'] else 'ausente'} | {action}; {entry['context']} |")

text+=['','## Áudio — cobertura complementar','',
'O manifesto é visual. O jogo também usa `music/bgm_title` e `ui/ui_confirm` em `src/core/AudioManager.gd:22,77`; `AudioResolver.gd:42–49` gera tons quando faltam WAVs. Ambos são **Generated** (não entram nos totais de texturas). Não há áudio final nessas pastas. Arte final de áudio permanece pendente, fora do ajuste visual.','',
'## Planejados sem consumidor de textura atual','',
'Não são lacunas de gameplay. Status do manifesto preservado; nenhum asset foi promovido a Approved. Os quatro IDs Blocked são exclusões do catálogo, não tarefas para geração.','',
'| Manifesto | ID | Categoria | Arquivo disponível | Status do manifesto |','|---|---|---|---|---|']
used={e['id'] for e in data['coverage']}
by_id={f['id']:f for f in files}
for asset,name,category,status in data['planned']:
    if name in used: continue
    row=by_id.get(name)
    available=('presente; referência interna' if row['category']=='reference' else 'presente') if row else 'ausente'
    if row and any('FORMATO WebP' in w for w in row['warnings']): available+='; importação inválida'
    text.append(f'| {asset} | `{name}` | {category.strip()} | {available} | {status.strip()} |')
text+=['','Assets fora do catálogo de 110 IDs, também sem consumidor atual: '+', '.join('`'+f['id']+'`' for f in files if f['id'] not in {p[1] for p in data['planned']} and f['id'] not in used)+'.','',
'Os placeholders genéricos `items/item_generic` e `monsters/monster_generic` permanecem em disco para ferramentas/fallbacks anteriores; os consumidores atuais usam os IDs individuais dos JSONs. `icon_rest` e `icon_options` aparecem no dicionário legado MenuGrid, mas não há atribuição/chamada de textura para eles. Os IDs disponíveis `icon_menu_rest` e `icon_menu_options` não são substituições automáticas.','',
'## Validação dos arquivos','',
f"Foram medidos {len(files)} arquivos: 98 artes de jogo e 1 referência interna. Entre as artes de jogo: {warn['DIMENSÕES']} divergências de dimensões, {warn['FORA DE 4:3']} cenário fora de 4:3, {warn['>1 MB']} arquivos acima de 1.000.000 bytes, 5 incompatibilidades formato/extensão. Nomes em snake_case: todos passam. Transparência exigida: nenhuma ausência total de alfa transparente nos arquivos decodificados.",'',
'Valores esperados: guia de geração, seções dos prompts 02–105; variantes por idade: registro `reviews/nyx-mvp-age-variants.md`. Cenários de tela inteira: 1024×768 / 4:3; vinhetas: 640×260; CGs: 1024×640. A razão larga de vinhetas/CGs é uma exceção documentada ao pedido geral de 4:3. Números de alfa são valores reais dos pixels, de 0 a 255, com contagens de pixels totalmente transparentes e parcialmente transparentes. RGB e JPEG são opacos. Dimensões maiores que o guia são divergências, mesmo que preservem a proporção. Alertas de peso não são reprovação automática.','',
'**NOT ASSESSED:** halos em todas as bordas, consistência estética de todo o catálogo, aprovações humanas e composição de todas as imagens não exibidas. A medição de alfa não prova ausência de halos. Referência interna é exceção de uso; dimensão aproximada esperada 832×1216. `ui_panel` permite fundo opaco: “centro vazio” no guia é interpretado como sem texto/conteúdo.','',
'| Arquivo | Medido | Esperado | Bytes | Alfa real | Nome / categoria | Resultado |','|---|---|---|---:|---|---|---|']
for f in files:
    actual=f"{f.get('width','?')}×{f.get('height','?')}"
    expected='×'.join(map(str,f['expected']))
    text.append(f"| `{f['path']}` | {actual} | {expected} | {f['bytes']} | {f['alpha']} | OK | {'; '.join(f['warnings']) or 'OK'} |")
text+=['','## Ajuste aplicado','',
'`src/ui/UITheme.gd:7`: `PANEL_CONTENT_MARGIN` de **12.0 → 20.0 px**, nos quatro lados dos PanelContainers que recebem o tema em runtime. Isso afasta conteúdo da borda sem exceder a largura disponível do menu (610 px de conteúdo + 40 px de margens = 650 px). NinePatch mantido em 16 px: a comparação visual não justificou ampliar as fatias. Âncoras, escala e ordem de camadas da personagem foram inspecionadas e mantidas, pois a silhueta completa já está dentro do espaço disponível. Nenhum fluxo, sinal, navegação, simulação ou JSON alterado nesta passagem.','',
'Pendências visuais: ornamentos do painel de origem têm escala excessiva em alguns tamanhos; cabeçalhos em painéis grandes ainda podem coincidir com ornamentos. A posição preexistente do painel de status em relação ao cartão superior também permanece. Uma solução geral exigiria outra textura de painel ou ajustes de layout fora desta passagem.','',
'## Capturas reais antes/depois','',
'Capturadas no viewport renderizado do Godot, **1024×768**, com Compatibility/OpenGL, pelo cenário auxiliar `capture.tscn` e script `capture.gd`. Mesma semente/estado inicial da simulação, personagem, créditos, loja inicial, encontro Rastreador e galeria bloqueada. A simulação é inicializada apenas em memória, sem chamar Game.start_new_game, saves, compras, decisões de encontro ou avanço de tempo. Não são mockups. O “antes” já contém os assets finais migrados anteriormente; mostra o estado existente antes do ajuste de margem, inclusive os fallbacks causados pelos WebPs.','',
'O perfil ativo é o painel Status expandido na MainScreen. ProfileScreen.tscn é um caminho legado, sem consumidor no fluxo principal, e não foi apresentado como captura do fluxo ativo. O título não usa os assets ajustados.','',
'| Tela | Antes | Depois |','|---|---|---|']
for name,label in [('main_screen','Principal'),('status_screen','Status expandido'),('items_screen','Loja / itens'),('mission_screen','Encontro / missão'),('endings_screen','Galeria de finais')]:
    text.append(f'| {label} | [Abrir](before/{name}.png) | [Abrir](after/{name}.png) |')
text+=['','## Créditos e proveniência','',
'CREDITS.md recebeu uma lista explícita dos 36 IDs confirmados como Final pelo resolvedor, com caminho e ferramenta: geração de imagens nativa OpenAI no Codex (IA). Fonte: créditos preexistentes, inventário art-migration.json e registros de geração/revisão em design/assets/reviews/. Não se presume modelo exato. Os quatro arquivos usados com importação inválida não foram marcados final. Demais artes sem consumidor, incluindo referência interna, conservam seus status; nenhuma aprovação humana foi inferida.','',
'## Verificação executada','',
'Wrapper utilizado: `C:/Program Files/Git/bin/bash.exe tools/godot.sh` (Git Bash disponível; `bash` do PATH aponta para outro executável). Todos os comandos foram executados na raiz.','',
'| Verificação | Argumentos após o wrapper | Exit / resultado |','|---|---|---|',
'| Importação | `--headless --path . --editor --quit --log-file <caminho absoluto>/import.log` | 0; com erros ambientais de certificado e de gravação de editor_settings fora do workspace. Não corrigiu os WebPs. |',
'| Teste de integração | `--headless --path . --log-file <caminho absoluto>/art-test.log -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/art_integration_test.gd` | 100; teste “every installed” falha em 3 asserções de contagem por causa dos 5 arquivos inválidos; testes individuais de itens e monstros passaram. Ver reports/report_213/results.xml. |',
'| MainScreen após ajuste | `--headless --path . --log-file <absoluto>/main-screen-test.log -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/main_screen_test.gd` | 100; 15 casos, 2 falhas e 1 erro. Falhas em main_screen_test.gd:91–92 (tela de missão nula) e :274 (fluxo mensal); teste de expansão de status e tema passou. Não foi demonstrada causalidade com esta mudança de margem; não foram corrigidos fluxos de gameplay. Evidência reports/report_214/results.xml. |',
'| Capturas | `--path . --log-file <absoluto>/<before ou after>.log --disable-shader-cache --rendering-method gl_compatibility res://design/assets/reviews/visual-art-pass/2026-11-18/capture.tscn -- before` (repetido com `after`) | 0 nos dois; 5 capturas por execução. Logs contêm erros de certificado, cache de shaders e 4 texturas finais inválidas. A sondagem completa posterior confirma 36/4/0. |',
'| Metadados WebP | `--headless --path . --log-file <absoluto>/webp-metadata.log --script res://design/assets/reviews/visual-art-pass/2026-11-18/webp_metadata.gd` | 0; decode explícito como WebP somente em memória; nenhum arquivo alterado. |',
'| Auditoria PNG | Python 3.14 existente: `audit.py` | 0; leitura stdlib, dimensões, bytes, filtros PNG e alfa real; ver measurements.json. Metadados WebP complementados em webp_metadata.json. |','',
'A primeira tentativa de CLI com log padrão terminou em crash por acesso negado a user://logs; repetida com log absoluto dentro do workspace. Uma primeira versão do capturador via --script teve erros de autoload e foi substituída por um cenário normal, cuja execução final não tem esses erros. O endpoint Funplay respondeu get_project_info e confirmou a raiz; capturas finais usam diretamente o viewport do runtime. Os logs de compilação do projeto e as verificações finais estão nos arquivos desta pasta. Exit 0 não é apresentado como ausência de erros.','',
f"Conferência SHA256: {len(hash_results)} arquivos de assets/art/ continuam idênticos ao inventário original da migração; ver art-hashes.json. Funplay get_script_errors com caminho de arquivo devolveu checked=0; portanto esse resultado não é uma validação de compilação. As cenas com o tema alterado foram de fato executadas nas capturas e nos testes.",'',
'## Próximas ações','',
'1. Reexportar os cinco WebPs como PNG real em uma etapa autorizada de edição dos assets; repetir importação e o teste que hoje falha. Prioridade para os quatro IDs usados. Nenhum ID precisa mudar.','2. Revisar divergências de dimensões/proporção e os alertas de peso; esta auditoria não redimensiona nem recomprime arquivos.','3. Revisar visualmente os cinco pares de capturas e decidir se o painel precisa de uma variante com ornamentos menores.','4. Os 20 IDs ausentes não bloqueados do manifesto continuam planejados, sem consumidor; os 4 Blocked permanecem excluídos.','',
'Mensagem de commit sugerida (nenhum commit criado): `chore(art): audit asset coverage and adjust panel content margins`','']
(OUT/'coverage-and-validation.md').write_text('\n'.join(text),encoding='utf-8')
(OUT/'validated-measurements.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')

credits_path=ROOT/'CREDITS.md'
credits=credits_path.read_text(encoding='utf-8')
start='<!-- visual-art-pass-2026-11-18:start -->'
end='<!-- visual-art-pass-2026-11-18:end -->'
block=[start,'## Final assets confirmed on 2026-11-18','',
'The following exact IDs resolve to **final** game textures. Each was **AI-generated using OpenAI native image generation in Codex**, as documented in the existing generation records and migration inventory. “Final” identifies the loaded art source; it does not certify dimensions or human visual approval. See the [coverage and validation audit](design/assets/reviews/visual-art-pass/2026-11-18/coverage-and-validation.md) for warnings.','',
'| Asset ID | File | Status | Tool |','|---|---|---|---|']
for entry in data['coverage']:
    if entry['source']!='Final': continue
    block.append(f"| `{entry['id']}` | `assets/art/{entry['category']}/{entry['id']}.png` | final | AI-generated; OpenAI native image generation in Codex |")
block+=['',
'`bg_bedroom_day`, `icon_agenda`, `icon_city`, and `icon_profile` currently load procedural placeholder PNGs because their final-directory files contain WebP bytes with a PNG extension. These four are **not confirmed final** in this pass. The unused `char_rat_casual_a_tired` has the same format issue. Other unused artwork remains available for review; the internal character reference remains reference-only.',end,'']
new='\n'.join(block)
if start in credits:
    a=credits.index(start);b=credits.index(end,a)+len(end)
    credits=credits[:a]+new.rstrip()+credits[b:]
else:
    credits=credits.replace('## Development tools',new+'\n## Development tools')
credits_path.write_text(credits,encoding='utf-8')
print('REPORT',counts,dict(warn))
