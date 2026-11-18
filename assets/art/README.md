# Game artwork

The project loads textures through `Assets.get_texture(id, category)`. Keep game
images directly inside their category with the unchanged `<id>.png` filename.
Final art takes priority over procedural placeholders automatically.

| Directory | PNGs | Content |
|---|---:|---|
| `characters/` | 24 | Nyx sprites, portraits, and the 12 age/state variants |
| `backgrounds/` | 30 | Locations, activity vignettes and event CGs |
| `ui/` | 7 | Panels, frames, button and feedback symbols |
| `icons/` | 16 | Menu and attribute/status icons |
| `items/` | 3 | The three MVP item icons, mapped in `assets/data/items.json` |
| `monsters/` | 3 | Encounter machines, resolved by monster ID |
| `endings/` | 15 | Ending emblems, resolved by ending ID |
| `reference/` | 1 | Internal Nyx identity reference; excluded from Godot import |

The 12 age/state sprites retain IDs such as `char_rat_casual_a_age15_sick` in
`characters/`; organizing them here does not introduce automatic age or state
selection in screens that still request `char_rat_idle`. Likewise, CGs, optional
UI assets and additional backgrounds are available to the resolver without
creating or replacing screens that do not yet use their IDs.

See the [art index](../../design/assets/README.md),
[file migration inventory](../../design/assets/art-migration.json), and
[credits](../../CREDITS.md). The temporary `Imgs Rat Trainer/` directory has been
fully migrated and removed. Superseded images are preserved under
`design/assets/archive/`, outside the game artwork.
