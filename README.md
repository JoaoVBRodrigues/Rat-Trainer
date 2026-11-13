# Rat Trainer

Rat Trainer is a monthly scheduling simulator prototype built with Godot 4.5 and typed GDScript. This repository's root `project.godot` is the canonical project; open the repository root, not `src/`. The old nested `src/project.godot` has been preserved as `src/project.godot.legacy` so Godot will index scripts and assets under `src/`.

## Open and run

1. Install Godot 4.5.1.
2. In the Project Manager, choose **Import** and select the root `project.godot`.
3. Run the project with F6/F5. The main scene displays the procedural bedroom and character placeholders.

The viewport is 1024x768 (4:3), uses `canvas_items` stretching, keeps the aspect ratio, and uses nearest-neighbor texture filtering.

## Generate the six placeholders

The generated PNGs are authored in-project; no MagicTools or other external artwork is used.

- **Editor:** open `src/core/GeneratePlaceholders.gd` in the Script editor and use its **Run** button.
- **Command line (Windows):**

```powershell
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://src/tools/generate_placeholders_cli.gd
```

The script writes `ui/ui_panel`, `characters/char_rat_idle`, `backgrounds/bg_bedroom_day`, `icons/icon_stat_str`, `items/item_generic`, and `monsters/monster_generic` under `assets/placeholders/`.

## Asset fallback and live preview

`Assets.get_texture(id, category)` checks these paths in order:

1. `assets/art/<category>/<id>.png`
2. `assets/placeholders/<category>/<id>.png`
3. A generated pixel texture with a category shape and the asset ID

The main-scene preview checks its two textures twice per second. Add or remove a PNG with a matching ID while the project runs to see the final-art/placeholder fallback change. File-loaded textures are cached until the source file changes.

Enable the asset usage summary by adding `debug/show_asset_report=true` to the `[debug]` section of `project.godot`; the report prints when the project exits.

## Simulation Core (Headless)

The simulation core provides a pure-code, deterministic simulation engine that can be tested independently of UI:

**Main Systems:**
- `CalendarSystem` - Period → month → year progression (108 periods total)
- `StatsSystem` - Attributes, stress, disease mechanics
- `EconomySystem` - Credits, costs, yearly stipends (200 Cr/year)
- `ActivitySystem` - Study, work, mission, and leisure activities
- `SimulationCore` - Facade coordinating all systems

**Test the simulation core:**
```powershell
# Run all GdUnit4 tests, including the simulation tests
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit

# Run a complete deterministic campaign; optionally pass a seed after --
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://src/tools/simulation_cli.gd -- 12345
```

**Documentation:** See [docs/simulation-core.md](docs/simulation-core.md) for detailed API reference.

## Tests

GdUnit4 6.2.3 is included in `addons/gdUnit4/` under its MIT license. It was chosen for native GDScript tests and Godot 4.5 support. All GdUnit4 suites under `tests/unit/` are discovered by the command above.

```powershell
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit
```

The three resolver tests cover final-art priority, placeholder fallback including live appearance/removal of final art, and generated fallback.

## Autoload scope

- `Game`: state transitions and orchestration only.
- `Data`: JSON save/load only.
- `Assets`: texture resolution and fallback only.
- `EventBus`: global signal declarations only.

No activity, stat, combat, or other gameplay rules are implemented in these autoloads.

## Project layout

- `assets/art/`: final artwork.
- `assets/placeholders/`: locally generated or approved placeholder PNGs.
- `src/core/`, `src/data/`: infrastructure and JSON persistence.
- `src/scenes/`: main preview scene.
- `src/systems/`, `src/ui/`: intentionally empty; no gameplay systems are in scope.
- `tests/unit/`: GdUnit4 tests for the asset resolver.

See [assets/placeholders/README.md](assets/placeholders/README.md) for asset naming and categories.