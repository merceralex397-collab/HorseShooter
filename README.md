# HorseShooter: Equine Hate Saga

HorseShooter is being rebuilt from the current arcade prototype into a mobile-first open-world action RPG for Android, built in Godot 4.6.

The current project state is treated as a concept prototype: useful for proving touch movement, aiming, shooting, Android export wiring, and horse-combat tone. The target game is much larger: a continuous world with towns, villages, cities, wilderness regions, story quests, followers, boss horses, settlement founding, settlement management, deep character growth, and a large data-driven equipment system.

## Creative Pillars

- Open-world RPG first: exploration, quests, factions, settlements, companions, crafting, bosses, and player choice.
- Horse shooting remains central: horses are enemies, bosses, regional hazards, quest targets, settlement threats, and comedy fuel.
- The player character has a fixed identity but a player-chosen name: a woman with long dark brown hair who constantly talks about how much she hates horses while swearing.
- Android is the release platform: every system must be touch-first, readable on phones, performant, and exportable to APK/AAB.
- Graphics are being rebuilt from scratch: the new visual target is high-detail stylized 2D/2.5D with layered environments, lighting, shaders, animated characters, weather, and biome-specific atmosphere.

## Target Game

Working title: `HorseShooter: Equine Hate Saga`

Player character: a player-named, foul-mouthed horse-hating gunslinger with long dark brown hair, a battered coat, and a pathological refusal to let any horse-related problem remain unsolved.

Core loop:

1. Explore a large continuous world.
2. Discover settlements, roads, ruins, wilderness encounters, horse territories, and faction conflicts.
3. Talk to NPCs, accept quests, recruit followers, and make settlement decisions.
4. Fight horse packs, mounted gangs, cursed steeds, mechanical cavalry, and boss horses.
5. Loot weapons, equipment, abilities, materials, maps, and settlement resources.
6. Upgrade the player character, followers, gear, and founded settlements.
7. Expand a camp into a village, town, and eventually a city with defenses, workshops, trade, and story consequences.

## Documentation

Start here:

- [Documentation Index](docs/INDEX.md)
- [Master Plan](docs/product/MASTER_PLAN.md)
- [World and Story Bible](docs/product/WORLD_STORY_BIBLE.md)
- [Systems Design](docs/product/SYSTEMS_DESIGN.md)
- [Art Direction and Asset Pipeline](docs/product/ART_DIRECTION.md)
- [Realistic Graphics Revamp](docs/product/REALISTIC_GRAPHICS_REVAMP.md)
- [Expansion and Enhancement Plan](docs/product/EXPANSION_AND_ENHANCEMENT_PLAN.md)
- [Image Generation Prompt Pack](docs/product/IMAGEGEN_PROMPT_PACK.md)
- [Android Release Validation](docs/product/ANDROID_RELEASE_VALIDATION.md)
- [Implementation TODO](docs/v2_revamp_todo.md)
- [Open World RPG Implementation Plan](docs/superpowers/plans/2026-05-01-horseshooter-open-world-rpg.md)

## Current Prototype

The current Godot project contains:

- A 2D wave-shooter scene in `scenes/main.tscn`.
- Touch movement and aim controls in `src/hud_manager.gd`.
- Shooting, bullets, horses, powerups, scoring, waves, audio, and VFX.
- Android export template files under `android/`.
- Smoke-test scenes under `tools/`.

Known prototype issues relative to the new direction:

- The main menu is effectively skipped because `src/main.gd` starts the game immediately.
- The existing game is level/wave based, not open world.
- The escape/miss pressure loop belongs to the arcade prototype and will be replaced by world-state consequences.
- Art assets are placeholder/generated sprites and must not define the final look.

## Build Requirements

- Godot 4.6.1 stable.
- Android SDK configured for Godot export.
- OpenJDK compatible with the Android Gradle plugin used by the Godot Android template.
- Release keystore for signed release APK/AAB builds.

Godot path used on this machine:

```powershell
C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe
```

Headless parse check:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit
```

Android export target:

```powershell
New-Item -ItemType Directory -Force export
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --export-release Android export/HorseShooter.apk
```

## Repository Layout

```text
assets/       Prototype sprites and sounds. Final assets will be rebuilt.
android/      Godot Android build template.
docs/         Product, design, implementation, and validation plans.
scenes/       Godot scenes.
src/          GDScript gameplay systems.
tools/        Headless smoke-test scenes.
```

## Release Definition

Release ready means:

- Runs reliably on Android phones.
- Exports a signed release APK/AAB.
- Has a working menu, save/load, settings, touch controls, readable UI, and offline play.
- Contains the open-world RPG vertical content promised by the final release scope.
- Includes authored graphics, audio, quests, followers, settlements, bosses, and progression data.
- Passes the validation matrix in [Android Release Validation](docs/product/ANDROID_RELEASE_VALIDATION.md).
