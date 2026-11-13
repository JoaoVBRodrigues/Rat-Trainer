# Placeholder asset convention

Use `snake_case` IDs and preserve the same ID between final art and its placeholder.

- Final art: `assets/art/<category>/<id>.png`
- Placeholder: `assets/placeholders/<category>/<id>.png`
- Resolution order: final art, placeholder, then an in-memory procedural texture

Texture categories are `ui`, `characters`, `backgrounds`, `icons`, `items`, `monsters`, and `fx`. The resolver currently handles textures only; audio placeholders are outside its API.

Run `src/core/GeneratePlaceholders.gd` from Godot's Script editor or run `src/tools/generate_placeholders_cli.gd` with Godot's headless `--script` option. Both entry points call the same procedural generator.

Current generated examples:

- `ui/ui_panel`
- `characters/char_rat_idle`
- `backgrounds/bg_bedroom_day`
- `icons/icon_stat_str`
- `items/item_generic`
- `monsters/monster_generic`

All six are original procedural images and require no third-party art credit. Add credits in `CREDITS.md` before adding any third-party art.
