# UX Spec: Monthly Schedule Flow

> **Status**: Proposed; pending UX review  
> **Author**: User + ux-designer  
> **Last Updated**: 2026-11-13  
> **Journey Phase(s)**: Monthly planning, activity resolution, and return to campaign hub; assumed because no player journey map exists  
> **Platform Target**: PC, 1024x768 base; keyboard/mouse and gamepad; Godot 4.5  
> **Source GDDs**: `design/game-brief.md`, `design/gdd/activities.md`, `calendar-and-turns.md`, `stats-and-stress.md`, `economy.md`  
> **Related UX**: `main-screen.md` (pending UX review); `interaction-patterns.md` (patterns Draft)  
> **Template**: UX Spec

---

## Purpose & Player Need

The player arrives wanting to plan all three periods of the current month, understand each activity's level, cost or income, requirements, expected stat/Stress effects and any blocking reason, then commit a valid schedule and see what actually happened. The flow supports the campaign's core cycle while keeping choices legible before commitment and results trustworthy afterward.

The UI presents choices and results; it never mutates `SimulationCore`. A flow/controller validates and executes the schedule. The MainScreen only emits `schedule_requested` and does not advance the calendar.

## Player Context on Arrival

`design/player-journey.md` is absent. Assumption: the player is at the campaign hub at the start of an eligible month, has just reviewed the current date and status, and is ready to make three consequential but unhurried choices. Show the month and relevant current resources immediately; do not assume the player remembers their previous schedule.

When no campaign is active, the hub offers `Nova campanha`; starting it initializes the default campaign before schedule actions become available.

This flow assumes a normal schedule-eligible month. Before opening planning, the owner checks the requested month's periods. An event-owned period is excluded from normal activity selection and routed to its owner when integrated; this flow does not define the event or sequence it. If an event-owned period exists and no owner integration is available, do not start normal agenda execution for that month. No event or flee content is designed here.

## Navigation Position

`Campaign -> MainScreen -> Monthly Schedule Flow -> three period results -> monthly summary -> MainScreen`

The flow opens from Agenda or AGENDAR through `MainScreen.schedule_requested(source)`. The Missão hub action opens the same flow with the mission category selected. It can be entered only when the calendar is at the start of a schedule-eligible month and all three periods are normal activity periods. An event-owned period is not represented as a normal activity slot; when event integration exists, the owner receives the handoff. Without that integration, the normal agenda is unavailable for that month rather than silently consuming or skipping an event-owned period. Cancel before confirmation returns to the hub without changing campaign state. After execution, the player continues through all results and the monthly summary before returning.

## Entry & Exit Points

| Entry Source | Trigger | Player carries this context |
|---|---|---|
| MainScreen | Agenda or AGENDAR emits `schedule_requested(source)` | Current month, period-1 calendar state, credits, stats, Stress/disease, activity data |
| MainScreen | Missão emits `schedule_requested("mission")` | Same campaign context, with the mission category preselected |
| Integration test harness | Programmatic monthly-flow test route | Isolated simulation, complete test schedule, explicit RNG seed |
| Event owner | Typed handoff when one or more requested month periods are event-owned | Owner-provided event context; normal agenda does not present those periods as activity choices |

| Exit Destination | Trigger | Notes |
|---|---|---|
| MainScreen | Cancel during planning | Discards the draft; no activity or calendar mutation |
| MainScreen | Continue after monthly summary | All three periods are resolved; calendar advances exactly three periods |
| Campaign-completion flow | The final campaign period is resolved | The calendar GDD has no period 109; do not invent an ending screen here |
| Caller/error recovery | Required data or a period resolution fails | Preserve the last confirmed state; show a localized error and do not claim success |
| Event owner | Event-owned period detected before normal agenda starts | Delegate; this flow does not create an activity choice or consume the period |

## Layout Specification

### ASCII Wireframe

```text
PLANNING — 1024 x 768
┌───────────────────────────────────────────────────────────────┐
│ MÊS / ANO · período atual      Créditos · Stress / estado     │
├───────────────────────────────────────────────────────────────┤
│ [INÍCIO: activity] [MEIO: activity] [FIM: activity]           │
├───────────────────────────┬───────────────────────────────────┤
│ Categoria: estudo trabalho│ Atividade selecionada              │
│            missão  lazer  │ nível · requisitos/bloqueio        │
│                           │ custo/renda · efeitos esperados    │
│ Lista de atividades       │ Stress/risco quando aplicável      │
│                           │                                   │
├───────────────────────────┴───────────────────────────────────┤
│ [Repetir agenda anterior]*  [Cancelar]   Resumo   [Confirmar] │
└───────────────────────────────────────────────────────────────┘

EXECUTION / MONTHLY RESULT
┌───────────────────────────────────────────────────────────────┐
│ Período 1/3 · data · atividade e nível                        │
│ [Mini-cena placeholder da atividade; sem arte não aprovada]    │
│ Resultado localizado · créditos / atributos / reputação       │
│ Stress · valores resultantes                                  │
│ [Acelerar] [Pular apresentação]                 [Continuar]   │
└───────────────────────────────────────────────────────────────┘
```

`*` Repetir agenda anterior appears only after a month has completed in the active campaign. It uses the in-memory campaign history only; no save persistence is integrated in this scope. Result and summary views replace the planning content; they do not layer over it in a way that hides required values.

### Layout Zones

1. **Context header**: month/year, current calendar position, current credits, Stress and disease status.
2. **Schedule slots**: exactly three labeled slots—start, middle, end—with empty, selected, focused, and invalid states.
3. **Activity chooser**: four localized category tabs and a navigable list for the active category.
4. **Selected activity details**: name, level, cost/income, requirements and visible block reason, expected attribute/reputation/Stress effects, plus a non-color-only risk alert when relevant.
5. **Planning footer**: repeat-previous, cancel, compact schedule totals/validation and one primary confirm action.
6. **Result content**: one period at a time, with a neutral placeholder mini-scene corresponding to that activity (no unapproved assets or final art), then the monthly summary. Every result displays actual deltas and resulting values before continuing.

### Component Inventory

| Component | Behavior / data | Pattern |
|---|---|---|
| Three period slots | Selects the slot being edited; focus alone never changes a choice | Schedule Slot Selector |
| Four category tabs | Changes the activity list without leaving planning | Tab Bar |
| Activity rows | Show decision-critical level, costs/income, requirements, expected effects, and block reason | Activity / Shop List Item |
| Disease/stress warning | Explains current or predicted risk; does not itself block non-mission activities | Stress / Health Risk Alert |
| Repeat previous schedule | Copies the last completed month in this active campaign from in-memory history into the editable draft | Button Secondary; Schedule Slot Selector |
| Cancel / confirm | Discard draft / begin execution; confirm disabled until all three selections validate | Button Secondary / Button Primary |
| Period result + mini-scene | Presents actual `PeriodResult`, localized explanation, and a neutral activity-specific scene placeholder; no unapproved art/assets | Monthly / Mission Result Panel; Attribute Delta + Progress Bar |
| Speed / skip controls | Changes or ends presentation only; never skips simulation updates | Execution Speed Control |
| Monthly summary | Shows aggregate changes and resulting balances after period three | Monthly / Mission Result Panel |

The patterns are Draft and define behavior, not visual style. Use the shared `UITheme`; visual treatment belongs to the art direction.

### Information Hierarchy

1. Month and current resources/status.
2. The three slots and whether the full schedule is valid.
3. Activity requirements, block reason, cost/income, and expected consequences.
4. Confirm/cancel and repeat action.
5. During execution, the current period/activity and actual deltas/resulting values.
6. At month end, net stat changes, credit change and balance, and Stress change/result.

## States & Variants

| State | Trigger | Behavior |
|---|---|---|
| Loading / data unavailable | Required calendar, activity, localization, or simulation data is not ready | Show localized loading/error state; do not invent values or allow confirmation |
| Planning: empty | New schedule draft | Three empty slots; confirm disabled with a visible explanation |
| Planning: partial | One or two slots selected | Allow editing; identify remaining slots; confirm disabled |
| Planning: valid | Three selected, current requirements and affordability pass | Show totals and enable confirm |
| Activity blocked | Requirement, affordability, or disease rule disallows the item | Keep reason visible in text; do not select it as valid |
| Repeat previous schedule available | At least one month completed in the active campaign | Show repeat action; source is campaign-session memory only; copying fills an editable draft and never executes |
| Repeat previous schedule unavailable | No month completed in this active campaign | Hide repeat action; do not load a schedule from save data |
| Event-owned period | Owner identifies any requested month period as event-owned before planning | Exclude it from normal activity selection and hand off to the owner when integrated. Until integration exists, do not start normal agenda execution for that month |
| Execution: period result | A period has resolved successfully | Present its actual result once; continue to next unresolved period |
| Execution failure | `SimulationCore` returns an error or data becomes invalid | Keep completed results and the next-unresolved slot index in the flow controller; never re-run completed periods. Pause execution and show localized recovery. Do not retry the failed slot until the controller verifies it was not applied or can resume it safely |
| Monthly summary | Period three resolves | Show all requested aggregate values and a single continue action |
| Campaign complete | Period 108 resolves | Delegate to campaign-completion flow; no period 109 or fabricated next month |
| Pending selection becomes invalid | Revalidation blocks a later selected mission, e.g. disease after an earlier period | Pause at that unresolved slot, preserve results already applied, and let the player replace the choice and revalidate. Do not consume the blocked period until a valid replacement is confirmed |

## Interaction Map

All interactive targets are at least 40x40 logical pixels. Focus order is: period slots; category tabs; activity list; selected details only if interactive; repeat (when present); cancel; confirm. A panel change preserves its owning focus. The selected slot and active tab are visually and textually identified.

| Action | Mouse | Keyboard | Gamepad | Outcome / feedback |
|---|---|---|---|---|
| Choose a period slot | Click slot | Tab/arrow navigation, Enter/Space | D-pad and confirm | Slot becomes the editing target; no campaign mutation |
| Change category | Click tab | Left/right arrows or focus + confirm | D-pad left/right | Updates the list and keeps tab focus |
| Select activity / level | Click valid row or level choice | Focus + Enter/Space | D-pad + confirm | Updates only the draft; refreshes details and validation |
| Inspect blocked item | Focus/hover row | Focus | Focus | Shows a persistent textual block reason; never relies on tooltip/color alone |
| Repeat previous schedule | Click | Focus + Enter/Space | Focus + confirm | When a month has completed in this active campaign, copies its schedule from in-memory campaign history to the draft; player can replace/clear any slot. No save persistence is read or written |
| Cancel planning | Click visible Cancel | `ui_cancel` / Escape | Cancel / B | Discards draft and returns to hub unchanged |
| Confirm schedule | Click enabled primary action | Focus + Enter/Space | Focus + confirm | Controller revalidates the complete schedule and event ownership before executing; if an event-owned period exists, normal agenda execution is unavailable and owner handoff is required |
| Replace invalid pending choice | Select an eligible activity in the paused slot | Focus + Enter/Space | Focus + confirm | Revalidates that unresolved slot against current state; completed results remain applied and the blocked period is not consumed until valid |
| Recover from core error | Activate recovery action after controller status is known | Focus + Enter/Space | Focus + confirm | Resume only when the failed slot is verified unapplied or safely resumable; otherwise remain paused and hand off to the core/save owner. Never replay completed slots |
| Accelerate / skip result | Click visible control | Focus + Enter/Space | Focus + confirm | Speeds or ends presentation only; state updates remain complete |
| Continue result | Click Continue | Focus + Enter/Space | Focus + confirm | Advances presentation to next result, then summary after result three |
| Continue monthly summary | Click Continue | Focus + Enter/Space | Focus + confirm | Returns to hub after exactly three periods have resolved |

No action in this flow designs or invokes `Falar` (mimar/mesada/repreender); its rules are undefined and it remains a separate design dependency.

## Data Requirements

The UI reads a presentation projection. A flow/controller owns validation, calls to `SimulationCore`, in-session recovery cursor/results, and transition sequencing. UI controls only edit a draft until confirmation. Schedule-history save persistence is not integrated in this scope; any existing simulation save behavior remains owned by its system.

| Data | Source / owner | Read / write | Notes |
|---|---|---|---|
| Month, period, turn count, current resources and status | `SimulationCore` calendar/stats/economy | Read | Entry must be at period 1; no fabricated defaults |
| Activity IDs, categories, levels, names, costs/income, requirements, gains and activity Stress | `assets/data/activities.json` and owning GDDs | Read | Use the configured activity level; do not duplicate numeric formulas in UI |
| Mission eligibility and block reason | `SimulationCore` / activity validator | Read | Disease blocks missions only; other available categories remain usable |
| Expected effects shown during planning | Authoritative activity/mission data and simulation projection | Read | The UI does not estimate or promise random mission outcomes; show conditional outcomes or a provider-supplied expectation |
| Draft of three selections | Flow/controller, represented by `MonthSchedule` or equivalent typed contract | Draft write only | Must be complete and valid before confirmation; repeating the prior schedule only seeds this draft |
| Last completed monthly schedule | Active campaign's in-memory flow/session history | Read; update after month completes | Repeat is available only after a completed month in this active campaign. Do not load from or write schedule history to save data in this scope; use a future save owner if persistence is later required |
| Event ownership for requested month periods | Calendar/event owner, when integrated | Read / typed handoff | Event-owned periods are not normal activity slots. Without integration, do not execute the normal monthly agenda for that month |
| Next unresolved slot and completed result list | Flow/controller | In-memory write | Maintain across interruptions/errors during this flow; never replay completed periods. After an error, retry the failed slot only if the controller verifies it was unapplied or can safely resume |
| Actual credit, stat, reputation and Stress deltas; resulting values; activity/outcome | `PeriodResult` from `SimulationCore` | Read | Render actual resolved data, including mission failure/success and clamped result values; do not recalculate |
| Localized result explanation and labels | `Localization` using stable activity/outcome IDs and result values | Read | Missing key is a data/localization error, not a reason to hardcode copy |
| Monthly summary | Controller aggregation of initial snapshot and three `PeriodResult` post-states | Read | Display net stat deltas, credit change and final balance, Stress change and final Stress |
| Test seed and isolated campaign state | Integration test harness | Test-only write | Must not mutate a player's live campaign or persistent save |

### Programmatic Integration-Test Route

Provide a deterministic test-only route equivalent to `run_month_for_test(schedule: MonthSchedule, seed: int) -> MonthlySummary`. It must enter the same flow/controller validation and period-resolution path as a confirmed schedule, use the real `SimulationCore` and result models, and surface all three `PeriodResult`s plus the monthly summary without simulated mouse, keyboard, or gamepad clicks. Use an isolated simulation and explicit RNG seed; assert one execution per slot and a calendar delta of exactly three. Test mode may complete presentation automatically, but must not bypass state updates, validation, result generation, or summary aggregation.

## Events Fired

| Action | Signal / event | Payload / mutation |
|---|---|---|
| Open Agenda from MainScreen | `schedule_requested(source: String)` | Existing MainScreen contract; no simulation mutation |
| Confirm valid schedule | Flow/controller confirmation contract | Complete typed schedule; controller owns validation and starts execution |
| Period resolves | `PeriodResult` delivered to result presentation | Actual result; core has applied the period exactly once |
| Event-owned period detected | Typed handoff to event owner (when integrated) | No normal schedule slot is executed and this flow does not consume time |
| Pending choice invalidated | Flow/controller pause state | Unresolved slot index and completed results; wait for replacement/revalidation |
| Core resolution error | Flow/controller error/recovery state | Error plus next-unresolved slot index and completed results; pause until failed-slot status is known; retry cannot replay earlier periods |
| Month resolves | Typed monthly summary delivered to summary presentation | Three results and initial/final snapshot; no extra period advancement |
| Cancel planning | Flow cancellation/return | Discard draft only; no simulation mutation |

Do not add an event/flee signal or event mechanics for this scope. Add a typed extension only when an owning system requires it.

## Transitions & Animations

- Open from MainScreen with the shared `Screen Transition` behavior and initial focus on the first schedule slot.
- Slot/category/list changes update in place without losing focus.
- Confirm enters sequential period-result presentation. A result is generated and applied before its presentation can be skipped.
- `ActivityResult`/`ActivityResultScreen` presents each `PeriodResult` alongside a neutral, activity-specific placeholder mini-scene. Use only placeholder/procedural content or already approved assets; do not imply final art or introduce unapproved assets. Continuing advances to the next unresolved result. Result screens never call the core or apply effects.
- If any requested period is event-owned, exclude it from normal activity choices and hand off to its owner when integrated. Until integration is defined, do not execute the normal agenda for that month or consume the owned period.
- Before each unresolved period executes, revalidate its choice. If disease has made a mission invalid, pause at that slot, keep prior results applied, allow replacement and revalidation, and consume no time until valid.
- If the core errors after earlier periods resolved, keep their results and the next-unresolved slot index in the controller. Pause until the controller determines whether the failed slot was applied or can be resumed safely; completed periods are never executed again.
- After period three, show the monthly summary. Continue returns to MainScreen (or delegates if the campaign is complete).
- Accelerate/skip reduces or ends visual presentation only. It never skips a selection, state update, save, result, or period.
- No flashes; motion must have a reduced-motion/static alternative. Exact timings come from shared theme tokens.

## Input Method Completeness Checklist

**Keyboard**
- [ ] All slots, tabs, activity choices, repeat, cancel, confirm, result controls, and summary actions are reachable and activatable.
- [ ] Logical tab/arrow order, visible focus, and `ui_cancel` behavior are implemented.
- [ ] Disabled choices expose their reason in accessible text.

**Mouse**
- [ ] All actions are clickable; hover adds information but does not hide required decision details.
- [ ] Target sizes meet 40x40 logical pixels.

**Gamepad**
- [ ] All actions are reachable with D-pad/navigation and confirm/cancel; focus remains visible.
- [ ] Disconnect/reconnect preserves the current draft and focus context.

Touch is not in scope or assumed supported.

## Accessibility

`design/accessibility-requirements.md` is absent; the project has no committed accessibility tier. This spec assumes a practical baseline for this flow—keyboard and gamepad completion, visible focus, readable text and numbers, no color-only meanings, no flashing, skippable/acceleratable motion, and scaling without clipping. This is an assumption, not an approved tier or accessibility audit.

- Provide textual labels for all slots, categories, values, statuses, and disabled reasons; pair icons/color with text or symbols.
- Keep costs, requirements, expected changes, and result values visible without hover.
- Ensure all content remains usable at 1024x768 and at supported UI scales/resolutions; do not clip focus or decision-critical text.
- No dialogue is designed here; dialogue/subtitle requirements remain governed by the uncommitted project accessibility standard.
- Minimum font size, contrast targets, screen-reader behavior, and supported resolution range remain uncommitted and must be established before claiming compliance.

## Localization Considerations

- All fixed interface text, errors, prompts, accessibility labels, and explanatory result copy use `Localization`; no user-facing strings are hardcoded in scenes/scripts.
- Activity IDs/types and numeric rules come from `activities.json` and their owning GDDs. Resolve player-facing names through the localization catalog by stable ID; do not duplicate names or formulas in UI code.
- Use locale-aware formatting for credits, signed deltas, dates, and numbers. Distinguish current value, delta, and conditional mission outcome in text.
- Allow at least 40% text expansion in tabs, slot labels, result explanations, and block reasons. Long explanations wrap without covering controls or hiding the continue action.
- A missing key or unknown activity is an explicit localized data error; do not substitute a hardcoded string or numeric guess.

## Acceptance Criteria

- [ ] From MainScreen, Agenda and AGENDAR each open the same schedule flow through `schedule_requested`; opening it does not change `SimulationCore`.
- [ ] At 1024x768, exactly three labeled slots and all four activity categories are usable without overlap or clipping.
- [ ] A schedule with zero, one, or two valid selections cannot be confirmed; a complete schedule with an invalid, unaffordable, or disease-blocked mission cannot be confirmed.
- [ ] Each activity row and detail view shows its data-defined level, cost/income, requirements or visible block reason, and expected stat/Stress effects before confirmation.
- [ ] Repeating is absent without a completed prior schedule; when present, it fills an editable draft and never starts execution.
- [ ] Repeating is available only after a month completes in the active campaign and uses in-memory history; this flow neither reads nor writes save persistence.
- [ ] An event-owned period is routed to its owner before normal agenda entry; it is not shown as an activity slot and is not consumed by this flow.
- [ ] Cancel before confirmation returns to the hub with the same calendar and campaign state as entry.
- [ ] Confirming a valid schedule resolves three distinct periods once each; disease can block missions but never removes a period.
- [ ] Each result shows the current period/activity, actual credit/stat/reputation/Stress deltas, resulting values, and localized explanatory text from the result.
- [ ] Each period result includes a mini-scene placeholder specific to the activity; no unapproved final art or assets are used.
- [ ] Accelerate and skip change presentation only; the same three state updates and results occur.
- [ ] The monthly summary shows net stat deltas, credit change and final balance, and Stress change/final value; returning from it advances exactly three periods.
- [ ] If disease invalidates a future mission, the flow pauses on that unresolved slot, preserves earlier applied results, permits replacement/revalidation, and does not consume the slot before a valid choice.
- [ ] If the core errors after prior periods, the controller retains the completed result list and next-unresolved index, pauses until failed-slot status is known, and never re-executes a completed period.
- [ ] A deterministic programmatic integration test can run a complete month without simulated clicks, using an isolated state and explicit seed, and inspect all period results plus the summary.
- [ ] With required data and assets already loaded, the schedule flow is interactive within 250 ms of its open request, excluding initial Godot import, measured at the same boundary as MainScreen.
- [ ] Keyboard-only and gamepad-only users can complete planning, execution, and return; focus is visible and no information depends on color alone.
- [ ] Missing/invalid data and resolution errors never appear as success, fabricate values, or silently consume a period.

## Open Questions

- No player journey map exists; the arrival context and start-of-month entry are assumptions. Create the journey map to validate player state and recovery needs.
- No accessibility tier is committed. Record one through the project's accessibility workflow and audit this flow before claiming conformance.
- `design/ux/hud.md` is absent; confirm how the flow inherits shared status/context components.
- The MainScreen spec is pending UX review and explicitly leaves Agenda outside its scope; align the handoff contract during that review.
- The interaction patterns used here remain Draft; validate them when implemented.
- Events can replace normal activity periods in the calendar GDD, but event content and active-event/flee UX are out of scope. Event-owned periods are excluded from normal activity selection and handed to their owner when integrated; until then, do not execute the normal agenda for a month containing an owned period.
- A mission selected while healthy can become blocked by disease after an earlier period. The flow pauses at that unresolved slot, preserves completed results, allows replacement/revalidation, and consumes no time for the blocked slot.
- Recovery after a core error is in-memory only for this flow: the controller retains completed results and the next-unresolved index, and pauses until the failed slot's application status is known. It never replays completed periods. Durable recovery requires a future save owner.
- Repeat schedule history is in-memory within the active campaign, available after at least one completed month; it does not depend on save/load and schedule-history persistence is not integrated in this scope. A future save owner may define durable history.
- The final campaign period has no next month and routes to campaign completion; confirm that handoff with the campaign flow owner.
- `Falar` (mimar/mesada/repreender) is out of scope because its rules are undefined in the GDD. It is a separate game-design dependency and is not specified here.
