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

**Generate missing UI icons:**
```powershell
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://src/tools/generate_missing_icons_cli.gd
```

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

### Asset Resolver Tests
GdUnit4 6.2.3 is included in `addons/gdUnit4/` under its MIT license. It was chosen for native GDScript tests and Godot 4.5 support. All GdUnit4 suites under `tests/unit/` are discovered by the command above.

```powershell
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit
```

The three resolver tests cover final-art priority, placeholder fallback including live appearance/removal of final art, and generated fallback.

### Simulation Tests
The simulation core tests (`tests/unit/simulation_core_test.gd` and related) validate the deterministic campaign logic, period advancement, statistics, economy, and activity resolution.

```powershell
# Run simulation tests only
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit/simulation_core_test.gd
```

### Running a Full Campaign
```powershell
# Run deterministic 108-period campaign with seed 12345
& "C:\Path\To\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://src/tools/simulation_cli.gd -- 12345
```

**Documentation:** See [docs/simulation-core.md](docs/simulation-core.md) for detailed API reference.

## Autoload scope

- `Game`: state transitions and orchestration only.
- `Data`: JSON save/load only.
- `Assets`: texture resolution and fallback only.
- `EventBus`: global signal declarations only.

No activity, stat, combat, or other gameplay rules are implemented in these autoloads.

## Project layout

- `assets/art/`: final artwork.
- `assets/placeholders/`: locally generated or approved placeholder PNGs.
- `src/core/`: infrastructure, simulation core, and core systems.
- `src/data/`: JSON persistence and data schemas.
- `src/scenes/`: main preview scene and UI scenes.
- `src/ui/`: UI components, widgets, and theme resources.
- `src/ui/widgets/`: reusable UI widgets (CalendarPanel, CharacterCard, StatsPanel, MenuGrid, ScheduleButton).
- `tests/unit/`: GdUnit4 tests for the asset resolver and simulation core.

See [assets/placeholders/README.md](assets/placeholders/README.md) for asset naming and categories.

## User Interface

The UI is built with placeholder aesthetics inspired by Princess Maker 2 but using neutral placeholder styles:

**Layout (inspired by screenshots):**
- **Calendar Panel (top-left):** Shows year, month, day label (Seg/Qua/Sex), period number, and progress counter (1/108).
- **Character Card (top-right):** Displays name (Nyx), age (12-15), credits, with status panel expanding below.
- **Status Panel (right):** Four blocks of status with compact bars - Attributes (STR, INT, CHA, REF, STA, ETH), Combat, Reputation, Skills.
- **Menu Grid (left):** 8 icons in compact grid - Agenda, Profile/Status, City/Stores, Equipment, Talk, Mission, Rest, Options.
- **SCHEDULE Button (bottom-right):** Primary action button.
- **Character Sprite (center):** Over background scene via Assets.get_texture.

**Technical notes:**
- All textures loaded via `Assets.get_texture()` - no direct path references.
- UI text goes through `Localization` system (strings in `assets/data/strings_pt_br.json`).
- Keyboard/gamepad navigation supported with focus indicators.
- Theme centralized in `src/ui/UITheme.tres` with NinePatch panel backgrounds.

## MainScreen Scene

The main UI is in [src/scenes/MainScreen.tscn](src/scenes/MainScreen.tscn) with:
- `CalendarPanel.gd` - Period display widget
- `CharacterCard.gd` - Character status widget  
- `StatsPanel.gd` - 4-block status panel widget
- `MenuGrid.gd` - 8-button icon grid widget
- `ScheduleButton.gd` - Primary action button widget

Run the main scene (F6/F5) to test the placeholder UI.

## UI Screens

- **MainScreen.tscn** - Main game screen with all UI panels positioned
- **ProfileScreen.tscn** - Expanded profile with full stats, opens when Profile icon clicked
- **ActivitySelection.tscn** - Activity/schedule selection screen (placeholder)
- **ActivityResult.tscn** - Results display after activity confirmation (placeholder)

## UI Architecture

All UI components follow these patterns:
- **Widgets** (`src/ui/widgets/`) are reusable Control nodes with their own scripts
- **Scenes** (`src/scenes/`) assemble widgets into screen layouts
- **Theme** (`src/ui/UITheme.tres`) centralizes colors, fonts, and styles
- **Localization** uses `assets/data/strings_*.json` for all user-facing text
- **Events** (`EventBus`) for UI-to-game communication (no direct state modification)
- **Assets** loaded via `Assets.get_texture()` for fallback/resolution logic

## Next Steps

To complete the UI:
1. Connect UI to SimulationCore for real state updates (currently placeholder values)
2. Implement ActivitySelection scene with activity choices and costs display
3. Implement ActivityResult scene with gains/losses visualization
4. Add animations and transitions
5. Add localization support (strings currently hardcoded in widgets)
6. Create missing icon placeholders for: agenda, profile, city, equipment, talk, mission, rest, options, schedule
7. Add schedule action display showing category, activity, cost, gains, stress

## Implementation Summary

**UI Components Created:**
- `src/ui/UITheme.tres` - Centralized theme with colors, styles
- `src/ui/UITheme.gd` - Theme resource helper class
- `src/ui/Localization.gd` - Localization system stub
- `assets/data/strings_pt_br.json` - Portuguese string table

**Widgets:**
- `CalendarPanel.gd` - Calendar/campaign progress display
- `CharacterCard.gd` - Character name/age/credits display + stats panel
- `StatsPanel.gd` - 4-block status panel (Attributes, Combat, Reputation, Skills)
- `MenuGrid.gd` - 8-button icon grid menu
- `ScheduleButton.gd` - Primary SCHEDULE action button
- `ActivitySelection.gd` - Activity selection screen stub
- `ActivityResult.gd` - Activity results display stub
- `StatusScreen.gd` - Expanded status screen

**Scenes:**
- `MainScreen.tscn` - Main game screen layout
- `MainScreen.gd` - Main game screen script
- `ProfileScreen.tscn` - Expanded profile screen layout
- `ProfileScreen.gd` - Expanded profile screen script

**Tools:**
- `src/tools/generate_missing_icons_cli.gd` - CLI script to generate missing icon placeholders

---

## Commit Checklist

**What was implemented:**
- [x] UI Theme centralized in `src/ui/UITheme.tres` and `src/ui/UITheme.gd`
- [x] MainScreen scene with all UI components positioned
- [x] CalendarPanel widget for period display
- [x] CharacterCard widget for character info
- [x] StatsPanel widget for 4-block status
- [x] MenuGrid widget for 8-button navigation
- [x] ScheduleButton widget for primary action
- [x] ProfileScreen for expanded status view
- [x] Localization system stub with Portuguese strings
- [x] CLI tool for generating missing icons

**Needs review:**
- [ ] Connect UI widgets to SimulationCore for real state updates
- [ ] Implement ActivitySelection scene with activity choices
- [ ] Implement ActivityResult scene with gains/losses visualization
- [ ] Add missing icon placeholders (agenda, profile, city, etc.)
- [ ] Add animations and transitions
- [ ] Connect EventBus signals in Main.gd

**Test verification:**
- [ ] Run Godot scene test to verify UI loads without errors