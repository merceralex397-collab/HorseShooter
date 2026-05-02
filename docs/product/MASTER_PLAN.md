# HorseShooter: Equine Hate Saga Master Plan

## Product Vision

Build a release-ready Android open-world action RPG where a foul-mouthed horse-hating heroine explores a dangerous continent, shoots absurdly varied horse threats, builds a settlement into a city, recruits followers, uncovers why horses are becoming organized and monstrous, and turns personal spite into a world-changing campaign.

The current wave shooter is not the target structure. It is prototype evidence for movement, aiming, shooting, UI telemetry, Android templates, and tone.

## Fixed Creative Requirements

- Protagonist: player-named adult woman with long dark brown hair.
- Naming: the player chooses the character name during new-game setup; there is no canonical protagonist name in story, UI, saves, or documentation.
- Voice: angry, dry, profane, and constantly hostile toward horses.
- Platform: Android.
- Genre: open-world RPG with action shooting.
- Core fantasy: travel, fight horses, swear about horses, loot weapons, recruit followers, build settlements, and reshape the world.

## Design Pillars

1. Open world with consequence
   - Regions are connected through roads, wilderness, ruins, coasts, mountain passes, and dangerous horse territories.
   - World events continue even when the player is elsewhere.
   - Settlements can grow, decline, be raided, trade, and unlock story outcomes.

2. Horse shooting with depth
   - Horses are not just targets. They have archetypes, factions, bosses, habitats, behaviors, loot tables, and world-state pressure.
   - The unfun prototype miss/escape system is replaced by world consequences: lost cargo, damaged buildings, scared followers, increased regional threat, and new counter-quests.

3. RPG breadth without chaos
   - Weapons, equipment, abilities, followers, quests, and settlements are data-driven.
   - Systems are built in vertical slices before large content expansion.
   - Every content type has a validator before scaling to hundreds of entries.

4. Mobile-first quality
   - Touch controls are primary.
   - UI uses large readable targets, safe-area layout, quick navigation, and minimal nested panels.
   - World streaming, save size, draw calls, shader cost, and memory are budgeted from phase one.

5. High-detail stylized presentation
   - Rebuild graphics from scratch.
   - Use layered 2D/2.5D environments, authored sprites, modular atlases, lighting, weather, screen-space effects, and biome color scripts.
   - Final art direction is gritty fantasy-western satire, not retro placeholder sprites.

## Target Player Experience

The first minute:

1. Player sees the title menu: the protagonist in silhouette with long dark brown hair, a smoking weapon, and a deadpan line about horses.
2. New game begins in a damaged roadside settlement.
3. The protagonist swears about the horse tracks everywhere.
4. A short tutorial teaches move, aim, shoot, dodge, interact, loot, and quest tracking.
5. The player repels a horse raid, meets the first follower, and chooses where to place the first settlement marker.

The first hour:

- Explore grassland, forest edge, and a ruined stable fort.
- Complete 5-8 quests.
- Find 12+ weapons and 20+ equipment items.
- Fight the first boss horse.
- Recruit 2 followers.
- Upgrade camp into an outpost.
- Unlock the world map and regional threat system.

## Implementation Strategy

The project should be rebuilt in layers:

1. Stabilize current project and Android build.
2. Replace arcade scene flow with a menu, save system, and RPG game state.
3. Build one playable open-world vertical slice.
4. Add data-driven content foundations.
5. Expand world streaming and regions.
6. Add settlement simulation.
7. Add follower and quest depth.
8. Rebuild graphics and audio into final direction.
9. Scale content.
10. Harden Android release.

## Definition of Done

A complete release-ready Android game has:

- Signed release APK or AAB.
- Main menu, settings, credits, new game, continue, save slots, pause, and quit-to-menu.
- Stable touch controls with movement, aiming, shooting, interaction, inventory, map, and settlement controls.
- A player-named protagonist as the only player character, represented in final art as a woman with long dark brown hair.
- 8+ major regions, including grassland, forest, snow, ocean/coast, mountains, volcano, desert/salt flats, and corrupted horse plains.
- 6+ settlements plus player-founded settlement growth path.
- 60+ authored quests and repeatable dynamic world events.
- 12+ followers with recruitment, banter, combat roles, and settlement assignments.
- 100+ weapons, 150+ equipment items, and 60+ abilities/perks.
- 25+ horse enemy archetypes and 12+ boss fights.
- Complete save/load and migration.
- Performance at target Android budgets.
- No missing resources, fatal script errors, broken scenes, or export blockers.
