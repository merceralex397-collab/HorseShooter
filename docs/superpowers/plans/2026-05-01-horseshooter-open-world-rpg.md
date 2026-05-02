# HorseShooter Open World RPG Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild HorseShooter from the current wave-shooter prototype into a release-ready Android open-world action RPG with a player-named horse-hating protagonist, profanity, world exploration, quests, followers, settlements, bosses, and large-scale progression.

**Architecture:** Build the RPG in vertical slices. First stabilize boot/menu/save/input, then add one playable open-world region, then scale content through data resources and validators. Keep old arcade code only where it accelerates touch controls, shooting, pooling, smoke tests, or Android export validation.

**Tech Stack:** Godot 4.6.1, GDScript, Godot Resource data, Android export templates, headless validation scenes, signed APK/AAB release flow.

---

## File Structure Target

- Create: `scenes/app/app_root.tscn`
- Create: `src/app/app_root.gd`
- Create: `src/save/save_manager.gd`
- Create: `src/content/content_database.gd`
- Create: `src/content/content_ids.gd`
- Create: `src/world/world_root.gd`
- Create: `src/world/region_chunk.gd`
- Create: `src/player/rpg_player_controller.gd`
- Create: `src/dialogue/dialogue_manager.gd`
- Create: `src/quests/quest_manager.gd`
- Create: `src/inventory/inventory_manager.gd`
- Create: `src/progression/progression_manager.gd`
- Create: `src/settlement/settlement_manager.gd`
- Create: `src/followers/follower_manager.gd`
- Create: `src/combat/combat_director.gd`
- Create: `src/ui/menu_controller.gd`
- Create: `src/ui/mobile_controls.gd`
- Create: `resources/weapons/`
- Create: `resources/equipment/`
- Create: `resources/abilities/`
- Create: `resources/quests/`
- Create: `resources/dialogue/`
- Create: `resources/enemies/`
- Create: `resources/regions/`
- Modify: `project.godot`
- Modify: `scenes/main.tscn`
- Modify: `src/main.gd`
- Modify: `src/game_manager.gd`
- Modify: `docs/v2_revamp_todo.md`

## Phase 1: Boot, Menu, Save, and Android Control Foundation

### Task 1: Add AppRoot and restore menu-first startup

**Files:**

- Create: `scenes/app/app_root.tscn`
- Create: `src/app/app_root.gd`
- Create: `src/ui/menu_controller.gd`
- Modify: `project.godot`
- Modify: `src/main.gd`

- [ ] **Step 1: Create a menu-first root scene**

Create `AppRoot` as the main scene. It owns title menu, save-slot selection, settings, and loading the world scene.

- [ ] **Step 2: Stop immediate gameplay auto-start**

Remove the direct `gm.start_game()` call from startup flow. New game should start only after player chooses `New Game`.

- [ ] **Step 3: Add menu actions**

Support `New Game`, `Continue`, `Settings`, `Credits`, and `Quit To Menu`.

- [ ] **Step 4: Verify**

Run:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit
```

Expected: exit code `0`, no missing main scene errors.

### Task 2: Add release-safe save slots

**Files:**

- Create: `src/save/save_manager.gd`
- Create: `src/save/save_slot.gd`
- Modify: `project.godot`

- [ ] **Step 1: Add SaveManager autoload**

SaveManager owns slot metadata, save read/write, migrations, autosave, and corruption fallback.

- [ ] **Step 2: Define save schema v1 for RPG reboot**

Fields: version, slot_id, timestamp, chosen_character_name, player, world, quests, inventory, progression, settlement, followers, factions, settings.

- [ ] **Step 3: Add migration harness**

Every save load passes through migration even when version is current.

- [ ] **Step 4: Verify**

Create, load, overwrite, delete, and corrupt a test save. Corrupt save must not crash boot.

### Task 3: Add Android-first input abstraction

**Files:**

- Create: `src/ui/mobile_controls.gd`
- Modify: `project.godot`
- Modify: `src/player/rpg_player_controller.gd`

- [ ] **Step 1: Define gameplay actions**

Actions: move, aim, fire, dodge, interact, ability_1, ability_2, map, inventory, pause.

- [ ] **Step 2: Build touch controls**

Left stick moves, right stick aims/fires, buttons for dodge/interact/abilities, and menu buttons outside unsafe areas.

- [ ] **Step 3: Fix one-direction shooting class of bug**

Every shot uses current aim vector, then last non-zero aim vector, then facing vector. Never default to one fixed direction while the player is actively aiming or moving.

- [ ] **Step 4: Verify**

Synthetic input test fires north, south, east, west, and diagonals. Bullet velocity must match aim direction.

### Task 3A: Add new-game character naming

**Files:**

- Create: `src/ui/character_name_screen.gd`
- Modify: `src/save/save_manager.gd`
- Modify: `src/ui/menu_controller.gd`
- Modify: `src/dialogue/dialogue_manager.gd`

- [ ] **Step 1: Add name entry screen**

After `New Game`, show a mobile-safe character naming screen before the world loads. The screen must have a visible label, text input, validation message, confirm button, and back button.

- [ ] **Step 2: Validate names**

Allow 1-24 visible characters after trimming. Reject empty names, control characters, and names that cannot be serialized to the save file.

- [ ] **Step 3: Persist chosen name**

Store the chosen name in save metadata and full save data as `chosen_character_name`.

- [ ] **Step 4: Add dialogue token support**

Dialogue lines may use `{player_name}`. The dialogue manager replaces it with the chosen name at render time. Lines that do not need the name should not force it.

- [ ] **Step 5: Verify**

Create a new game with a custom name, reload the save, open dialogue, quest journal, inventory, and pause menu. The chosen name must appear where intended and no fixed canonical protagonist name may appear anywhere.

## Phase 2: RPG Vertical Slice

### Task 4: Create world root and Greenbarrow starter region

**Files:**

- Create: `scenes/world/world_root.tscn`
- Create: `src/world/world_root.gd`
- Create: `src/world/region_chunk.gd`
- Create: `resources/regions/greenbarrow.tres`

- [ ] **Step 1: Create world scene**

WorldRoot loads player, camera, region chunks, encounter anchors, NPC anchors, and settlement marker.

- [ ] **Step 2: Add Greenbarrow chunk set**

Create starter road, ruined farm, forest edge, camp site, and Toll Mare arena.

- [ ] **Step 3: Add persistence IDs**

Every location, loot container, NPC, encounter, and boss has stable ID.

- [ ] **Step 4: Verify**

Player can move from camp site to road, farm, forest edge, and boss arena without scene reload.

### Task 5: Add player-named protagonist controller and bark system

**Files:**

- Create: `src/player/rpg_player_controller.gd`
- Create: `resources/dialogue/mara_barks.tres`
- Create: `src/dialogue/dialogue_manager.gd`

- [ ] **Step 1: Implement controller**

Move, aim, shoot, dodge, interact, and animation state output.

- [ ] **Step 2: Add identity placeholder**

Temporary art must still show female protagonist with long dark brown hair until final assets arrive.

- [ ] **Step 3: Add bark triggers**

Triggers: seeing tracks, missing a shot, killing a horse, entering stable, boss intro, low health, settlement raid.

- [ ] **Step 4: Verify**

The protagonist produces horse-hating profanity barks from multiple triggers and no bark contradicts the fixed character rule. No bark uses a fixed canonical protagonist name.

### Task 6: Add starter quests, follower, and boss

**Files:**

- Create: `src/quests/quest_manager.gd`
- Create: `resources/quests/q001_road_full_of_hooves.tres`
- Create: `resources/quests/q002_found_spitehold.tres`
- Create: `resources/followers/first_follower.tres`
- Create: `resources/enemies/boss_toll_mare.tres`
- Create: `src/combat/combat_director.gd`

- [ ] **Step 1: Quest framework**

Support objectives: talk, travel, kill, collect, build, defend.

- [ ] **Step 2: First quest chain**

Implement tutorial road defense, settlement founding, first follower recruitment, and Toll Mare hunt.

- [ ] **Step 3: Boss fight**

Toll Mare has at least three phases: charge, summon, enraged road smash.

- [ ] **Step 4: Verify**

New game through first boss can be completed with touch controls and saves after each quest stage.

## Phase 3: Data-Driven Scale

### Task 7: Build content database and validators

**Files:**

- Create: `src/content/content_database.gd`
- Create: `src/content/content_validator.gd`
- Create: `tools/content_validation_test.gd`

- [ ] **Step 1: Load resource folders**

Load weapons, equipment, abilities, quests, dialogue, enemies, regions, followers, and settlement buildings.

- [ ] **Step 2: Validate IDs**

Fail validation on duplicate IDs, missing names, missing icons, missing referenced rewards, and broken prerequisites.

- [ ] **Step 3: Verify**

Run content validation headlessly and require exit code `0` before scaling content.

### Task 8: Add item, ability, and inventory systems

**Files:**

- Create: `src/inventory/inventory_manager.gd`
- Create: `src/progression/progression_manager.gd`
- Create: `resources/weapons/*.tres`
- Create: `resources/equipment/*.tres`
- Create: `resources/abilities/*.tres`

- [ ] **Step 1: Define resource schemas**

Weapons, equipment, and abilities use typed Resource scripts.

- [ ] **Step 2: Implement inventory UI**

Filter by category, rarity, slot, equipped, and new item state.

- [ ] **Step 3: Add starter content**

12 weapons, 20 equipment items, 10 abilities.

- [ ] **Step 4: Verify**

Equipping every starter item updates stats and survives save/load.

## Phase 4: Settlement Simulation

### Task 9: Add Spitehold settlement foundation

**Files:**

- Create: `src/settlement/settlement_manager.gd`
- Create: `resources/settlements/buildings/*.tres`
- Create: `src/ui/settlement_screen.gd`

- [ ] **Step 1: Settlement state model**

Track tier, population, resources, buildings, followers assigned, threat, morale, and events.

- [ ] **Step 2: Build camp-to-outpost flow**

Player places marker, adds first buildings, assigns first follower, and repels first horse raid.

- [ ] **Step 3: Add city growth roadmap hooks**

State model supports camp, outpost, hamlet, village, town, and fortified city.

- [ ] **Step 4: Verify**

Settlement state changes persist and affect available services after reload.

## Phase 5: Graphics and Audio Replacement

### Task 10: Replace prototype visuals with final-style vertical slice assets

**Files:**

- Modify: `assets/`
- Create: `assets/art/mara/`
- Create: `assets/art/greenbarrow/`
- Create: `assets/art/horses/`
- Create: `assets/art/ui/`

- [ ] **Step 1: Produce player-named protagonist concept and sprites**

Must satisfy long dark brown hair and readable mobile silhouette.

- [ ] **Step 2: Produce Greenbarrow environment atlas**

Roads, grass, ruins, camp props, foliage, horse damage decals.

- [ ] **Step 3: Produce starter horse family**

Runner, charger, spitter, pack leader, Toll Mare boss.

- [ ] **Step 4: Verify**

No prototype generated sprites remain visible in the vertical slice.

### Task 11: Add final UI style pass

**Files:**

- Create: `src/ui/theme/`
- Modify: menu, inventory, map, quest, settlement, dialogue scenes.

- [ ] **Step 1: Create theme tokens**

Surfaces, text, danger, brass/progression, map blue, disabled, focus, and touch states.

- [ ] **Step 2: Apply mobile layout rules**

48dp touch targets, safe areas, readable type, back navigation, and no critical icon-only controls.

- [ ] **Step 3: Verify**

Phone portrait and landscape screenshots have no overlapping text or hidden controls.

## Phase 6: Release Hardening

### Task 12: Android export and device validation

**Files:**

- Modify: `export_presets.cfg`
- Modify: `project.godot`
- Modify: `docs/product/ANDROID_RELEASE_VALIDATION.md`

- [ ] **Step 1: Configure Android SDK/JDK**

Godot editor settings must point to valid SDK and JDK.

- [ ] **Step 2: Configure release signing**

Release keystore path, alias, and passwords must be available locally and not committed.

- [ ] **Step 3: Export release APK**

Run:

```powershell
New-Item -ItemType Directory -Force export
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --export-release Android export/HorseShooter.apk
```

- [ ] **Step 4: Install and smoke test**

Run:

```powershell
adb install -r export/HorseShooter.apk
adb shell monkey -p com.horseshooter.game 1
```

- [ ] **Step 5: Verify release definition**

Use `docs/product/ANDROID_RELEASE_VALIDATION.md` and `docs/v2_revamp_todo.md` final release checklist.

## Self-Review

- The plan covers the user's required direction: graphics reboot, Android, open-world RPG, player-named female dark-brown-haired protagonist, horse-hating profanity, towns, settlements, quests, bosses, biomes, settlement growth, followers, weapons, equipment, abilities, README, AGENTS, TODO, and release validation.
- The plan includes player-chosen character naming and removes the old hard-coded name requirement.
- The plan deliberately rejects the old arcade miss/escape mechanic and replaces it with RPG world consequences.
- The plan does not claim the final game is already complete; it defines the implementation order required to get there.
