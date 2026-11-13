# Simulation Core Documentation

This document describes the headless simulation core for Rat Trainer, designed for batch testing and AI agent integration.

## Architecture

The simulation core consists of several independent systems that can be tested in isolation:

```
SimulationCore (Facade)
├── CalendarSystem (period → month → year progression)
├── StatsSystem (attributes, stress, disease)
├── EconomySystem (credits, costs, stipends)
└── ActivitySystem (study, work, mission, leisure)
```

## Systems

### CalendarSystem

Manages the game calendar progression:
- 108 total periods (3 years × 12 months × 3 periods)
- Tracks year (1-3), month (1-12), period (1-3), and age (12-15)
- Accepts a one-year calendar JSON for short test campaigns
- Detects month ends, year starts, and campaign completion
- Detects campaign completion

**Key Methods:**
- `advance_period()` - Move to next period
- `is_month_end()`, `is_year_end()`, `is_new_year_period()` - Detect calendar boundaries
- `is_campaign_complete()` - Check if all periods done
- `get_year()`, `get_month()`, `get_period()`, `get_age()` - Query current state

### StatsSystem

Handles attributes and stress mechanics:
- 6 attributes: STR, INT, CHA, REF, STA, ETH
- Stress meter: 0-100
- Disease threshold: 60 + floor(STA / 5)
- Reputations: Fighter, Social, Hacker

**Key Methods:**
- `add_stat(stat_id, delta)` - Apply clamped stat change
- `add_stress(delta)` - Apply stress change
- `check_and_update_disease()` - Update disease state based on stress
- `is_mission_blocked_by_disease()` - Check if mission unavailable

### EconomySystem

Manages credits and transactions:
- New-game balance: 0 before the first choice; `SimulationCore` credits the first stipend before resolving period one
- Yearly stipend: 200 credits (at start of each year)
- Total stipends: 600 credits over 3 years
- No negative balance allowed

**Key Methods:**
- `can_afford(cost)` - Check if can pay
- `pay(cost)` - Deduct credits
- `receive_income(amount)` - Add credits
- `start_year(year)` - Return the once-per-year stipend amount; `SimulationCore` credits it

### ActivitySystem

Executes player activities:

**Study Activities:**
- Tecnologia (INT): +12/15/18 INT, 8/16/24 Cr, +2 Stress
- Comunicação (CHA/REF): +8 CHA/+5 REF, +11 CHA/+8 REF, +14 CHA/+11 REF, 6/12/18 Cr
- Artes (REF): +8/11/14 REF, 5/10/15 Cr
- Always +2 Stress
- 10 XP per session

**Work Activities:**
- Reparo Leve: +2 INT, 15 Cr, +3 Stress (promoted: 22 Cr)
- Entrega Assistida: +2 CHA, 20 Cr, +3 Stress (promoted: 30 Cr)
- Apoio Comunitário: +2 CHA, 25 Cr, +2 Stress (promoted: 37 Cr)
- 4 consecutive months same task = promotion to level 2

**Missions:**
- Fisica (STR): +4 Stress, success on combat roll, 25 Cr, +2 STR, +5 Fighter Rep
- Tecnica (INT): +3 Stress, success check, 30 Cr, +2 INT, +5 Hacker Rep
- Comunitaria (CHA): +3 Stress, success check, 20 Cr, +2 CHA, +5 Social Rep, +2 ETH

**Leisure:**
- Descanso: -15 Stress, 0 Cr
- Passeio Comunitario: -5 Stress, +2 CHA, 0 Cr

### SimulationCore

Main facade that coordinates all systems:

```gdscript
var sim = SimulationCore.new()
sim.initialize()
sim.set_seed(12345)  # For deterministic testing

# Advance one period
var result = sim.advance_period("study_curso_tecnologia_l1")

# Check results
print(result.stat_changes)    # {"int": 12}
print(result.credits_change)  # 192 (200 stipend - 8 cost on period one)
print(result.year, result.month, result.period)
```

## Result Structure

`PeriodResult` contains:
- `year`, `month`, `period`, `age` - Calendar state
- `activity_type` - STUDY, WORK, MISSION, LEISURE
- `stat_changes` - Dictionary of stat deltas
- `stress_change`, `stress_final` - Stress values
- `credits_change` - Credit delta
- `rep_gained` - Reputation deltas
- `flags_set` - New flags set
- `is_diseased_after` - Disease state
- `year_stipend_given` - Whether stipend was given
- `mission_success`, `success_chance`, `mission_count` - Mission result
- `promotion_unlocked`, `streaks_incremented`, `month_end_processed` - Work progression
- `pre_period_state`, `post_period_state`, `error_message` - State snapshots and failure details

Disease is checked after each period. At or above `60 + floor(STA / 5)`, missions are
blocked until Stress drops below the threshold; the campaign does not skip periods.
The GDD does not specify reduced gains for other activities while diseased.

## Testing

Run tests with Godot's GDUnit4:

```powershell
# Run all GdUnit4 test suites
godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode --continue -a res://tests/unit
```

## Headless CLI

Run a complete campaign using the built-in balanced strategy. Pass a seed after
`--` to reproduce a run; the default seed is `12345`.

```powershell
godot --headless --path . --script res://src/tools/simulation_cli.gd -- 12345
```

The CLI prints a stat and credits snapshot after each in-game year and a final
campaign summary.

## Deterministic Seeds

For reproducible testing, use fixed RNG seeds:
- `set_seed(seed)` on SimulationCore
- Optionally pass a nonzero seed to `advance_period(choice, period_seed)` to reset the RNG for that period

## Design Documents

- [GDD: Calendar and Turns](design/gdd/calendar-and-turns.md)
- [GDD: Stats and Stress](design/gdd/stats-and-stress.md)
- [GDD: Activities](design/gdd/activities.md)
- [GDD: Economy](design/gdd/economy.md)