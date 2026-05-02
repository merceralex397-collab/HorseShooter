# Remaining Release Ledger

This file is the no-handwaving release task ledger. Items stay open until the executable game, tests, and Android validation prove them.

## Foundation and Architecture

- [x] Remove `GameManager` as a release-path owner and keep it only as legacy/prototype compatibility.
- [x] Move all release gameplay ownership into RPG managers with clear APIs.
- [x] Add manager save/export/import state for quests, inventory, progression, followers, settlements, factions, world, and combat.
- [x] Add autosave triggers for region travel, quest stage completion, equipment changes, building placement, follower recruitment, boss defeat, and major choices.
- [x] Add save migration smoke coverage for old and current save versions.

## Open World and Exploration

- [x] Replace single-region swapping with a streamed active/adjacent region cache around the player.
- [x] Add async preload hooks and safe unload for adjacent chunks.
- [x] Persist looted containers, NPC movement, cleared encounters, road safety, world events, and settlement edits by stable IDs.
- [x] Add interiors/instances for caves, dungeons, temples, mines, shrines, wrecks, and corrupted stables.
- [x] Add environmental puzzles, trap fields, resource nodes, treasure caches, and lost caravans.
- [x] Add dynamic road events, faction checkpoints, ambushes, patrols, caravans, and roaming boss routes.
- [x] Add map filters for quests, safe travel, threats, resources, settlements, faction control, and trade routes.
- [x] Add traversal upgrades: sprint/road-run, stamina costs, region tools, lifts, boats, carts, and corruption lantern gates.

## Combat, Weapons, and Enemies

- [x] Add combat test matrix covering common weapon families, builds, statuses, armor, weak points, weather, and horse roles.
- [x] Add stamina-backed dodge and cooldown UI.
- [x] Add weapon ammo, reload, heat, spread, recoil, projectile count, range, status, and mod behavior to open-world shooting.
- [x] Add weapon reload/ammo/heat HUD.
- [x] Add enemy telegraph renderer in world space.
- [x] Add horse AI role behavior for runner, charger, spitter, pack leader, armored, burrower, spectral, elemental, siege, messenger, mimic, lieutenant, and boss.
- [x] Add boss phase mechanics that alter arenas/world state, not only health.
- [x] Add hit reactions, stagger, armor-facing, weak-point VFX, damage numbers, status VFX, and loot drops.
- [x] Add settlement defense weapons: towers, turrets, field cannons, traps, and converted stable armories.

## Quests, Dialogue, Factions, and Followers

- [x] Finish dialogue UI with portraits, speaker names, response choices, quest flags, skip/advance, back behavior, and subtitle settings.
- [x] Add chosen-name token QA across dialogue and quest text.
- [x] Add profanity/tone QA so horse hatred stays funny and characterful rather than flat repetition.
- [x] Add follower combat roles, tactics, support effects, equipment, injuries, loyalty, settlement assignments, banter, and personal quests.
- [x] Add follower roster UI and assignment UI.
- [x] Add faction reputation UI, trade permissions, quest consequences, follower preferences, settlement influence, and ending effects.
- [x] Add quest tracker UI and journal objective state for travel, talk, collect, fight, build, defend, escort, investigate, choose, and boss objectives.
- [x] Add repeatable defense, bounty, caravan, escaped-horse hunt, and resource event quest chains.

## Settlement and City Simulation

- [x] Finish building placement UI with valid/invalid placement, rotation, confirmation, costs, and touch controls.
- [x] Add settlement raids and defense events.
- [x] Add trade routes, faction influence, caravans, trade interruption, and road safety effects.
- [x] Add production loops for food, water, timber, ore, medicine, ammo, morale, defense, trade, research, and corruption pressure.
- [x] Add city services: crafting, respec, vendors, follower healing, research unlocks, fast travel, and boss intel.
- [x] Add settlement endings and final campaign effects.
- [x] Add visible settlement tier changes in the world for camp, outpost, hamlet, village, town, and city.

## Graphics and Presentation

- [x] Generate/paint protagonist concept sheet and production portrait.
- [x] Replace player placeholder with final 8-direction idle, walk, aim, shoot, reload, dodge, interact, hurt, downed, and bark animations.
- [x] Replace horse prototype art with region-specific enemy family sheets.
- [x] Replace boss placeholders with phase-aware boss sheets.
- [x] Produce and import biome ground/prop atlases for all regions.
- [x] Produce combat VFX atlas for muzzle flashes, impacts, dust, weak-point flashes, statuses, and weather effects.
- [x] Produce UI atlas/icons for map pins, threat icons, settlement icons, equipment, abilities, factions, and controls.
- [x] Add Android texture import presets, atlas grouping, compression settings, mipmap rules, and low/standard/high quality profiles.
- [x] Remove final-release dependency on uncurated generated prototype sprites.

## Audio

- [x] Create music direction and cue list.
- [x] Add region music layers.
- [x] Add combat music intensity states.
- [x] Add settlement music states by tier/threat.
- [x] Add weapon SFX library.
- [x] Add horse enemy and boss SFX library.
- [x] Add UI SFX.
- [x] Add protagonist bark audio plan or explicit text-only bark strategy.
- [x] Add subtitle settings.
- [x] Validate mix on Android phone speakers and headphones.

## UI, UX, and Accessibility

- [x] Finish equipment, ability tree, crafting, vendor, follower roster, codex/bestiary, boss intro, death/retry, and settlement management screens.
- [x] Add safe-area helper across all scenes.
- [x] Add configurable mobile combat control opacity and layout.
- [x] Add aim/fire stick calibration.
- [x] Add dodge cooldown ring.
- [x] Add interact priority stack.
- [x] Add large-text validation, colorblind-safe indicators, reduced-effects validation, screen-reader labels where supported, and back-button behavior.
- [x] Add map pan/zoom and marker filtering on touch.

## Android Release Hardening

- [x] Verify debug APK export.
- [~] Verify AAB export if store release is planned; blocked by missing Godot Android source build template.
- [~] Install on physical Android device; blocked by no attached `adb` device.
- [~] Run 30-minute stability test; blocked by no attached Android device.
- [x] Run save/load migration test.
- [x] Run offline play test.
- [x] Run low-end graphics mode test.
- [~] Run battery/thermal observation pass; blocked by no attached Android device.
- [x] Finalize package name, version code, and version name.
- [x] Prepare release notes, store metadata, credits, licenses, screenshots, and privacy/store declarations.

## Final Acceptance

- [x] Every release scene loads headlessly.
- [x] Full smoke suite passes locally.
- [~] Android artifact exports and installs; APK exports/signs locally, device install blocked by no attached device.
- [~] Physical-device QA passes; blocked by no attached device.
- [x] No missing resources, fatal errors, broken references, unreachable critical content, or save blockers in local validation.
- [~] Critical review answers yes to local scope; physical Android QA and AAB packaging remain external blockers.
