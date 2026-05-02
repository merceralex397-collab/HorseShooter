# AGENTS.md

This repository is being led as a Godot 4.6 Android open-world RPG reboot. Treat the current wave-shooter as a prototype, not the final product shape.

## Project Direction

Target game: `HorseShooter: Equine Hate Saga`

Non-negotiable requirements:

- Android is the release platform.
- The player character is female, has long dark brown hair, and constantly swears about hating horses.
- The game is an open-world RPG, not a level-based roguelite or arena shooter.
- Horse shooting remains a central gameplay identity.
- The final game needs towns, villages, settlements, cities, quests, stories, bosses, biomes, settlement founding, followers, weapons, equipment, and abilities.

## Working Rules

- Keep changes scoped to the current implementation phase in `docs/v2_revamp_todo.md`.
- Do not preserve old arcade systems when they block the RPG architecture.
- Prefer data-driven resources for weapons, equipment, abilities, quests, NPCs, followers, settlements, biomes, and encounters.
- Keep Android performance visible in every design decision.
- Use small focused scripts; avoid growing one giant scene controller.
- Keep docs updated when architecture, naming, release criteria, or implementation order changes.

## Godot Conventions

- Additional Godot-specific implementation notes are in `docs/engineering/GODOT_NOTES.md`.
- Content ID rules are in `docs/engineering/CONTENT_IDS.md`.
- Engine target: Godot 4.6.1.
- Language: GDScript unless a specific performance hotspot requires another approach.
- Runtime systems should communicate through clear signals or typed manager APIs.
- Avoid hardcoded content in scripts once a system has more than a few entries.
- Do not rely on editor-only setup for release-critical data.
- Every scene that is part of the Android build must be loadable in headless mode.

## Content Conventions

- The protagonist has no canonical name. The player chooses the character name during new-game setup.
- Dialogue should address the player character through the chosen name only when the line can do so naturally; otherwise use neutral phrasing.
- Dialogue can be profane, but it should serve character, comedy, anger, or story pace.
- Horse enemies should vary by region, faction, behavior, threat role, and boss mechanics.
- Settlements must have mechanical consequences, not just cosmetic upgrades.
- Biomes must affect encounters, traversal, resources, enemies, quests, and visuals.

## Validation

Before claiming a phase is complete, run the relevant checks from:

- `docs/product/ANDROID_RELEASE_VALIDATION.md`
- `docs/v2_revamp_todo.md`
- `docs/superpowers/plans/2026-05-01-horseshooter-open-world-rpg.md`

Minimum local checks:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/ci_smoke_test.tscn
```

Android release validation requires an export attempt and, for final release, device install testing.
