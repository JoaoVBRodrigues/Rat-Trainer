"""Read-only asset audit; report generation uses only the Python standard library."""
from pathlib import Path
import struct, zlib, re, json, collections

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent

def png(path):
    data = path.read_bytes()
    if data[:8] != b'\x89PNG\r\n\x1a\n':
        return dict(error='NOT PNG: ' + data[:12].hex(), bytes=len(data))
    pos, packed = 8, bytearray()
    while pos < len(data):
        n = struct.unpack('>I', data[pos:pos+4])[0]
        kind, chunk = data[pos+4:pos+8], data[pos+8:pos+8+n]
        if kind == b'IHDR':
            w,h,depth,color,_,_,interlace = struct.unpack('>IIBBBBB', chunk)
        if kind == b'IDAT': packed.extend(chunk)
        pos += n+12
    result = dict(width=w,height=h,bytes=len(data),color=color,depth=depth,alpha='opaque')
    if color not in (4,6): return result
    if depth != 8 or interlace:
        result['alpha'] = 'NOT ASSESSED: unsupported depth/interlace'
        return result
    channels = 4 if color == 6 else 2
    stride = w*channels
    raw = zlib.decompress(packed)
    prior = bytearray(stride)
    transparent, partial, amin, amax = 0, 0, 255, 0
    for y in range(h):
        start = y*(stride+1)
        filt = raw[start]
        row = bytearray(raw[start+1:start+1+stride])
        if filt:
            for i in range(stride):
                a = row[i-channels] if i >= channels else 0
                b = prior[i]
                c = prior[i-channels] if i >= channels else 0
                if filt == 1: predict = a
                elif filt == 2: predict = b
                elif filt == 3: predict = (a+b)//2
                elif filt == 4:
                    p = a+b-c
                    pa,pb,pc=abs(p-a),abs(p-b),abs(p-c)
                    predict=a if pa<=pb and pa<=pc else b if pb<=pc else c
                else: raise ValueError(filt)
                row[i] = (row[i]+predict)&255
        alpha = row[channels-1::channels]
        transparent += alpha.count(0)
        partial += len(alpha)-alpha.count(0)-alpha.count(255)
        amin,amax=min(amin,min(alpha)),max(amax,max(alpha))
        prior=row
    result.update(alpha=f'{amin}–{amax}; zero={transparent}; partial={partial}', alpha_min=amin)
    return result

def expected(category, name):
    if category == 'reference': return (832,1216),False,'aproximado; referência'
    if category == 'backgrounds':
        if name.startswith('scene_'): return (640,260),False,'vinheta; exceção documentada ao 4:3'
        if name.startswith('cg_'): return (1024,640),False,'CG; exceção documentada ao 4:3'
        return (1024,768),False,'cenário 4:3'
    if category == 'characters':
        if name.startswith('portrait_'): return (256,256),False,'fundo burgundy permitido'
        return (512,768),True,'sprite'
    if category in ('icons','items','endings'): return (128,128),True,'ícone/emblema'
    if category == 'monsters': return (512,512),True,'sprite'
    return {'ui_panel':((512,512),False,'RGBA; centro vazio sem texto'),
            'ui_frame_mission':((1024,768),True,'moldura'),
            'ui_dialog_box':((800,200),False,'fundo liso ou transparente permitido'),
            'ui_hex_button':((128,128),True,'botão')}.get(name,((128,128),True,'ícone UI'))

used = {}
def use(cat, names, where, context='ativo'):
    for name in names:
        used[(cat,name)] = dict(where=where,context=context)

use('backgrounds',['bg_bedroom_day'],'src/scenes/MainScreen.gd:146')
use('characters',['char_rat_idle'],'src/scenes/MainScreen.gd:159; src/ui/widgets/CharacterCard.gd:50; src/scenes/ProfileScreen.gd:41')
use('ui',['ui_panel'],'src/ui/UITheme.gd:18')
use('icons',['icon_agenda','icon_profile','icon_city','icon_equipment','icon_talk','icon_mission'],'src/scenes/MainScreen.gd:16,250')
use('icons',['icon_stat_'+s for s in ['str','int','cha','ref','sta','eth']],'src/ui/widgets/StatsPanel.gd:112; StatusScreen.gd:94','consumidor legado; ausente no StatusPanel ativo')
use('ui',['icon_schedule'],'src/ui/widgets/ScheduleButton.gd:25','widget legado')
use('ui',['icon_success'],'src/ui/widgets/ActivityResult.gd:54')
use('ui',['icon_ending'],'src/ui/widgets/EndingScreen.gd:297','fallback condicional')
use('backgrounds',['bg_ending'],'src/ui/widgets/EndingScreen.gd:71; CreditsScreen.gd:29')
for cat, key, field, where in [('items','items','icon','src/ui/widgets/ItemManagementScreen.gd:249'),('monsters','monsters','id','src/ui/widgets/EncounterScreen.gd:111'),('endings','endings','id','src/ui/widgets/EndingGallery.gd:178; EndingScreen.gd:294')]:
    data=json.loads((ROOT/f'assets/data/{cat}.json').read_text(encoding='utf-8-sig'))
    use(cat,[item[field] for item in data[key]],where+'; assets/data/'+cat+'.json')

rows=[]
for path in sorted((ROOT/'assets/art').rglob('*.png')):
    cat,name=path.parent.name,path.stem
    info=png(path)
    size,alpha,note=expected(cat,name)
    warnings=[]
    if info.get('error'): warnings.append(info['error'])
    else:
        if (info['width'],info['height']) != size: warnings.append('DIMENSÕES')
        if alpha and info.get('alpha_min',255)==255: warnings.append('SEM TRANSPARÊNCIA')
        if cat=='backgrounds' and not name.startswith(('cg_','scene_')) and info['width']*3!=info['height']*4: warnings.append('FORA DE 4:3')
    if info['bytes']>1_000_000: warnings.append('>1 MB')
    if not re.fullmatch(r'[a-z][a-z0-9]*(?:_[a-z0-9]+)*',name): warnings.append('NOME')
    rows.append(dict(path=str(path.relative_to(ROOT)).replace('\\','/'),category=cat,id=name,expected=size,requires_alpha=alpha,note=note,warnings=warnings,**info))
    print(cat+'/'+name,info.get('error','OK'),flush=True)

coverage=[]
for (cat,name),entry in sorted(used.items()):
    final=ROOT/f'assets/art/{cat}/{name}.png'
    ph=ROOT/f'assets/placeholders/{cat}/{name}.png'
    imp=Path(str(final)+'.import')
    import_bad=imp.exists() and 'valid=false' in imp.read_text()
    source='Final' if final.exists() and not import_bad else 'Placeholder' if ph.exists() else 'Generated'
    coverage.append(dict(category=cat,id=name,source=source,final=final.exists(),placeholder=ph.exists(),import_bad=import_bad,**entry))

manifest=(ROOT/'design/assets/asset-manifest.md').read_text(encoding='utf-8-sig')
planned=re.findall(r'\| (ASSET-\d+) \| \d+ \| `([^`]+)` \| ([^|]+) \| ([^|]+) \|',manifest)
payload=dict(files=rows,coverage=coverage,planned=planned)
(OUT/'measurements.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf-8')
print('COUNTS',dict(collections.Counter(x['source'] for x in coverage)))
print('WARNINGS',dict(collections.Counter(w for x in rows for w in x['warnings'])))
