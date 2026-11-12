# Placeholder Asset Convention

Este documento define o padrão de placeholders usado no jogo "Rat Trainer".

## Convenções

### a) IDs de Assets
Todo asset do jogo possui um ID em `snake_case`:
- Exemplos: `ui_portrait_frame`, `char_rat_idle`, `bg_bedroom_day`, `icon_stat_int`

### b) Localização de Arquivos
- **Arquivo final** (arte oficial): `assets/art/<categoria>/<id>.png`
- **Placeholder**: `assets/placeholders/<categoria>/<id>.png` (mesmo nome do final)

### c) Fallback de Renderização
O jogo procura os assets na seguinte ordem:
1. Arquivo final em `assets/art/`
2. Placeholder em `assets/placeholders/`
3. Se nenhum encontrado, gera um retângulo colorido com o ID escrito (implementado no prompt 02)

### d) Créditos de Terceiros
Todo arquivo de terceiros precisa de uma linha em `CREDITS.md` no momento em que entra no repositório.

### e) Fontes de Placeholders
Fontes recomendadas do catálogo ellisonleao/magictools (seção Graphics > Assets/Placeholders):
- **Kenney** (kenney.nl/assets) - CC0
- **OpenGameArt** (opengameart.org) - Licenças variam
- **Game-icons.net** - Requer atribuição
- **420 Pixel Art Icons for RPGs**

### f) Preferências de Design
- UI: neutra/escura
- Ícones: monocromáticos
- Personagens: silhueta ou sprite genérico
- Nada que lembre Princess Maker ou jogos comerciais

## Categorias
- `ui/` - Elementos de interface (botões, frames, painéis)
- `characters/` - Sprites de personagens
- `backgrounds/` - Planos de fundo
- `icons/` - Ícones de status, menus, itens
- `items/` - Sprites de itens
- `monsters/` - Sprites de criaturas/inimigos
- `fx/` - Efeitos visuais
- `audio/` - Assets de áudio (placeholder sonoro)