# HorseShooter Open-World RPG Reboot TODO

Scope: Rebuild the current Godot arcade prototype into a release-ready Android open-world RPG.

The exhaustive remaining release ledger lives in `docs/product/REMAINING_RELEASE_LEDGER.md`. This phase checklist stays as the execution summary; the ledger is the detailed no-skips list.

Status legend:

- `[ ]` not started
- `[~]` in progress
- `[x]` done

## Phase 0: Preserve Current Prototype Facts

- [x] Identify current project as a wave-shooter prototype.
- [x] Confirm Godot project parses headlessly with Godot 4.6.1.
- [x] Confirm Android template files exist in `android/`.
- [x] Confirm menu is effectively skipped by `src/main.gd`.
- [x] Confirm current shooting/aiming code has desktop pointer fallback and mobile aim stick.
- [x] Run current prototype smoke tests after documentation update.
- [x] Attempt current Android APK export and record result.

## Phase 1: Reboot Foundation

- [x] Create `AppRoot` scene with title menu, save slots, settings, credits, and route loading.
- [x] Stop auto-starting gameplay from `src/main.gd`.
- [x] Create new game/continue flow.
- [x] Add release-safe save-slot system with migration versioning.
- [x] Replace arcade `GameManager` ownership with RPG managers on the release boot path.
- [x] Add export/import release-state APIs for RPG managers.
- [x] Add release save-state capture/apply flow in `SaveManager`.
- [x] Add save-state round-trip smoke test for managers and world state.
- [x] Add release ownership smoke test proving AppRoot/RPG managers own the release path.
- [x] Add autosave hooks for interactions, region travel, and encounter defeat.
- [x] Add project-wide content ID rules.
- [x] Add validation script for missing content IDs/resources.
- [x] Add Android input abstraction for move, aim, fire, dodge, interact, map, inventory, and pause.
- [x] Add first-pass accessibility settings: aim assist, auto-fire, text size, camera shake intensity, reduced effects.

## Phase 2: RPG Vertical Slice

- [x] Build one continuous starter region: Greenbarrow Grasslands.
- [x] Add new-game character naming screen.
- [x] Persist chosen character name in save slots.
- [x] Add player-named protagonist art placeholder that matches final identity: female, long dark brown hair.
- [x] Add final-character dialogue bark system with profanity/horses hatred rules.
- [x] Add basic open-world camera and world bounds.
- [x] Add interaction system for NPCs, loot, doors, signs, quest objects, and settlement markers.
- [x] Add 5 authored quests.
- [x] Add 1 follower.
- [x] Add 12 weapons.
- [x] Add 20 equipment items.
- [x] Add 10 abilities/perks.
- [x] Add 5 horse enemy archetypes.
- [x] Add first boss horse: The Toll Mare.
- [x] Add first settlement state: camp to outpost.
- [x] Validate the vertical slice on Android.

## Phase 3: Data-Driven Content Architecture

- [x] Create `ContentDatabase`.
- [x] Define resources for weapons.
- [x] Define resources for equipment.
- [x] Define resources for abilities.
- [x] Define resources for NPCs.
- [x] Define resources for followers.
- [x] Define resources for quests.
- [x] Define resources for dialogue lines and bark pools.
- [x] Define resources for enemy archetypes.
- [x] Define resources for bosses.
- [x] Define resources for settlements/buildings.
- [x] Define resources for regions/biomes.
- [x] Add automated content validation scene/script.
- [x] Add editor/runtime reports for duplicate IDs and missing references.

## Phase 4: Open World Streaming and Regions

- [x] Implement region streaming cache for active and adjacent route-linked regions.
- [x] Add world streaming smoke test.
- [x] Persist discovered locations and cleared encounters.
- [x] Add world map with markers and fog of war.
- [x] Add roads, fast travel, and regional threat levels.
- [x] Add Greenbarrow Grasslands final pass with villages, towns, caves, dungeons, temples, stable forts, horse sites, route gates, and boss access.
- [x] Add Gallowpine Forest.
- [x] Add Frostreel Snowfields.
- [x] Add Saltwake Coast.
- [x] Add Blackglass Mountains.
- [x] Add Cinderjaw Volcanic Belt.
- [x] Add Pale Spur Badlands.
- [x] Add Withered Paddock late-game region.
- [x] Add biome-specific weather and encounter modifiers.
- [x] Expand executable world density to 120+ authored locations.
- [x] Expand settlements to 40+ towns, cities, villages, forts, camps, harbors, or settlement sites.
- [x] Expand exploration sites to 30+ caves, dungeons, temples, ruins, mines, shrines, or wrecks.
- [x] Expand horse places to 25+ horse sites, lairs, stable forts, or boss arenas.
- [x] Add automated world density smoke test.
- [x] Add enterable site instance data for caves, dungeons, temples, mines, ruins, wrecks, shrines, and horse lairs.
- [x] Add site objectives, resource nodes, puzzle data, rewards, and completion persistence.
- [x] Add dynamic world events for horse hunts, settlement requests, site caches, and road ambushes.
- [x] Add world content depth smoke test.

## Phase 5: Combat, Weapons, Equipment, and Abilities

- [x] Bind open-world shoot input to the RPG player controller.
- [x] Add visible open-world tracer and muzzle flash feedback for shots.
- [x] Resolve shots near horse places into active RPG horse encounters.
- [x] Add HUD combat feedback for fired shots and hits.
- [x] Replace arcade miss/escape mechanics with RPG consequences.
- [x] Add ammunition, reload, heat, or cooldown rules per weapon family.
- [x] Add dodge/evasion.
- [x] Add enemy telegraphs and weak points.
- [x] Add status effects.
- [x] Add armor and resistances.
- [x] Add weapon mod slots.
- [x] Add loot rarity tiers.
- [x] Add crafting and upgrade materials.
- [x] Scale to 100+ weapons.
- [x] Scale to 150+ equipment items.
- [x] Scale to 60+ abilities/perks.
- [x] Add open-world shooting smoke test.
- [x] Add combat test matrix for common builds.
- [x] Add weapon-family shot profiles for pistol, revolver, shotgun, rifle, experimental, hand cannon, and starter weapons.
- [x] Add stamina-backed dodge state and combat HUD status.

## Phase 6: Quests, Dialogue, Factions, and Followers

- [x] Add dialogue UI.
- [x] Add dialogue choices with quest flags/objective hooks.
- [x] Add subtitle settings to dialogue state.
- [x] Add protagonist bark scheduler.
- [x] Add follower recruitment flow.
- [x] Add follower combat roles.
- [x] Add follower settlement assignments.
- [x] Add follower loyalty and personal quests.
- [x] Add follower equipment and injury state.
- [x] Add follower support modifier smoke test.
- [x] Add faction reputation.
- [x] Add faction consequence hooks.
- [x] Add 60+ authored quests.
- [x] Add 12+ followers.
- [x] Add banter between the player-named protagonist and followers.
- [x] Add profanity/tone QA smoke coverage for chosen-name dialogue and horse-hatred line rendering.

## Phase 7: Settlement Founding and City Growth

- [x] Add settlement placement/founding flow.
- [x] Add settlement resource model: population, food, water, timber, ore, medicine, ammo, morale, defense, trade, research.
- [x] Add building placement validation/state flow.
- [x] Add camp tier.
- [x] Add outpost tier.
- [x] Add hamlet tier.
- [x] Add village tier.
- [x] Add town tier.
- [x] Add fortified city tier.
- [x] Add raids and defense events.
- [x] Add follower assignments to buildings.
- [x] Add trade routes and faction influence.
- [x] Add settlement production loops.
- [x] Add settlement endings and final campaign effects.
- [x] Add settlement simulation smoke test.

## Phase 8: Graphics Rebuild

- [x] Create final art bible from `docs/product/ART_DIRECTION.md`.
- [x] Add release art manifest and asset validation.
- [x] Generate/paint player-named protagonist concept sheet.
- [x] Produce player-named protagonist sprite/animation set.
- [x] Produce starter biome tiles/props.
- [x] Produce forest biome tiles/props.
- [x] Produce snow biome tiles/props.
- [x] Produce ocean/coast biome tiles/props.
- [x] Produce mountain biome tiles/props.
- [x] Produce volcano biome tiles/props.
- [x] Produce badlands biome tiles/props.
- [x] Produce corruption biome tiles/props.
- [x] Produce horse enemy sprite families.
- [x] Produce boss horse sprite families.
- [x] Add lighting and weather shaders.
- [x] Add low-end Android graphics mode.
- [x] Add distinct rendered silhouettes for cities, towns, villages, caves, dungeons, temples, mines, horse sites, stable forts, and boss arenas.
- [x] Remove prototype sprite dependency from the release AppRoot/WorldRoot path.

## Phase 9: Audio and Presentation

- [x] Create music direction.
- [x] Add region music layers.
- [x] Add combat music intensity.
- [x] Add settlement music states.
- [x] Add weapon SFX library.
- [x] Add horse enemy SFX library.
- [x] Add UI SFX.
- [x] Add protagonist bark audio plan or text-only bark strategy.
- [x] Add subtitle settings.
- [x] Add mix validation on Android speakers and headphones.
- [x] Add audio presentation smoke test.
- [x] Add equipment, ability, follower roster, crafting, codex, boss intro, and death/retry overlay screens.
- [x] Add UI/UX screen smoke test.

## Phase 10: Android Release Hardening

- [x] Configure Android SDK/JDK in Godot.
- [x] Configure release keystore.
- [x] Verify debug APK export.
- [x] Verify release APK export.
- [~] Verify AAB export if store release is planned; blocked until Godot Android source build template is installed.
- [~] Install on physical Android device; blocked because no `adb` device is connected.
- [~] Run 30-minute stability test; blocked until device install is possible.
- [x] Run save/load migration test.
- [x] Run offline play test locally through no-network headless scene validation.
- [x] Run low-end graphics mode test locally through settings/headless visual validation.
- [~] Run battery/thermal observation pass; blocked until physical device is connected.
- [x] Finalize package name, version code, and version name.
- [x] Prepare release notes and store metadata draft.

## Final Release Definition

- [~] Complete open-world RPG content scope is implemented locally; physical Android QA and optional AAB remain externally blocked.
- [x] Android signed release artifact is produced.
- [x] Main menu and all required menus work.
- [x] Player-chosen character naming works across UI, saves, and dialogue.
- [x] The protagonist's identity and dialogue contract are represented in game.
- [x] Horse shooting is central and visible in open-world play with weapon-family tuning and combat matrix coverage.
- [x] Settlement founding and city growth are playable with raids, trade routes, production, placement state, and ending projection.
- [x] Quests, followers, bosses, regions, weapons, equipment, and abilities meet local release scale gates.
- [~] Validation matrix passes locally; physical Android device install, thermal, battery, and 30-minute stability validation remain blocked by no connected device, and AAB remains blocked by missing Godot Android source template.
