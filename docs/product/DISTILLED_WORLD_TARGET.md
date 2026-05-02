# Distilled World Target

This is the practical target for `HorseShooter: Equine Hate Saga`: a dense Android open-world RPG where shooting hateful magical horses is central, but the world is large enough to explore, settle, revisit, and care about.

## Core Pillars

- Dense world, not a sparse map: every region needs towns, villages, cities, caves, dungeons, temples, horse places, resources, route gates, and boss pressure.
- Horse hatred is the identity: horse sites, corrupted stables, lairs, boss arenas, and road ambushes are not optional side flavor.
- Exploration must change play: safe settlements unlock travel and services; dangerous sites start encounters; biomes alter visibility, weather, threat, and combat modifiers.
- Android-first scope: high readability, fast loadable chunks, stylized-realism visuals, low-end mode, and headless-loadable scenes.
- Data before hardcoding: locations, settlements, enemies, routes, quests, followers, gear, and abilities should stay content-driven as the project grows.

## Region Recipe

Each major region should ship with at least:

- 1 city or major town.
- 2-4 villages, camps, forts, harbors, or settlements.
- 2 caves, mines, wrecks, or ruins.
- 1-2 dungeons or temples.
- 3 horse places: lair, corrupted stable, horse run, horse field, or boss arena.
- 2 route gates or travel links.
- 1 biome-specific hazard or traversal wrinkle.
- 1 boss or lieutenant that changes regional threat.

## Implemented Floor

The current executable world now enforces this floor through `world_density_smoke_test`:

- 8 regions.
- 120+ authored locations.
- 40+ settlements, towns, cities, villages, forts, camps, or harbors.
- 30+ caves, dungeons, temples, mines, ruins, shrines, or wrecks.
- 25+ horse sites, horse lairs, stable forts, or boss arenas.

## Fun Test

A region is not good enough if the player can cross it without choosing between at least three meaningful activities: travel to a settlement, clear a horse place, enter a cave/dungeon/temple, pursue a quest/follower lead, gather settlement resources, or challenge a boss gate.
