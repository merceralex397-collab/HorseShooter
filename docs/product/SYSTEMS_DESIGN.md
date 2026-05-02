# Systems Design

## Architecture Target

The final game should use a modular Godot architecture:

- `AppRoot`: boot, menu routing, save-slot selection, platform services.
- `WorldRoot`: world streaming, region state, player spawn, camera, weather, time.
- `PlayerController`: movement, aim, shooting, interaction, abilities.
- `CombatDirector`: enemy activation, encounter pacing, boss phases.
- `QuestManager`: quest state, objectives, dialogue flags, rewards.
- `InventoryManager`: weapons, equipment, consumables, crafting materials.
- `ProgressionManager`: XP, perks, abilities, follower upgrades.
- `SettlementManager`: founded settlement state, buildings, citizens, assignments, raids.
- `DialogueManager`: conversations, barks, protagonist profanity lines, follower banter, and chosen-name token substitution.
- `SaveManager`: save slots, migrations, autosaves, validation.
- `ContentDatabase`: loads resource data for items, abilities, quests, NPCs, regions, and enemies.

The current `GameManager` can be kept temporarily as a compatibility bridge, but it should not remain the final source of all game state.

## Open World

World representation:

- Large 2D world split into region chunks.
- Region chunks contain terrain layers, navigation, encounter anchors, NPC anchors, loot anchors, and settlement links.
- Chunks stream in around the player and unload safely.
- Persistent changes are stored by stable IDs, not node paths.

Required systems:

- world map,
- compass/quest tracker,
- fast travel between discovered safe locations,
- dynamic encounters,
- biome weather,
- road safety/threat levels,
- region boss influence.

## Combat

Core combat:

- Twin-stick movement and aim on Android.
- Weapons fire in aimed direction, not locked to one direction.
- Manual fire, hold fire, and optional accessibility auto-fire.
- Dodge or evasive movement ability.
- Reload/cooldown feedback.
- Hit reactions, stagger, armor, shields, weak points, elemental effects.

Enemy horse categories:

- Runner: fast pressure unit.
- Charger: telegraphed impact attack.
- Spitter: ranged projectile horse.
- Pack leader: buffs nearby horses.
- Burrower: terrain ambush.
- Flyer or spectral: ignores some terrain.
- Armored: weak-point or armor-piercing solution.
- Elemental: snow, fire, poison, storm, brine, shadow.
- Boss: multi-phase arena or roaming world boss.

The old miss/escape fail loop is removed. Replacements:

- missed shots cost ammo, heat, stealth, or opportunity;
- escaped enemies can raise regional threat;
- failed defense events damage settlement assets;
- letting a named horse escape can unlock a hunt quest rather than ending fun.

## Weapons

Data-driven weapon families:

- pistols,
- revolvers,
- rifles,
- shotguns,
- lever guns,
- hand cannons,
- crossbows,
- launchers,
- elemental guns,
- traps,
- thrown weapons,
- settlement defense weapons,
- experimental anti-horse devices.

Weapon properties:

- damage,
- fire rate,
- reload time,
- range,
- spread,
- projectile count,
- ammo type,
- recoil,
- movement penalty,
- rarity,
- tags,
- status effects,
- mod slots,
- upgrade path,
- flavor bark trigger chance.

Content target:

- vertical slice: 12 weapons;
- alpha: 60 weapons;
- release: 100+ weapons.

## Equipment

Slots:

- coat,
- boots,
- gloves,
- hat or hair accessory,
- belt,
- charm,
- weapon mod,
- utility item,
- settlement banner.

Stats:

- health,
- stamina,
- speed,
- reload,
- accuracy,
- crit chance,
- armor,
- elemental resistance,
- settlement bonuses,
- follower synergy.

Release target: 150+ equipment items.

## Abilities and Progression

Progression layers:

- protagonist level,
- weapon mastery,
- region reputation,
- follower loyalty,
- settlement rank,
- faction standing,
- boss trophies.

Ability trees:

- Gunslinger: direct shooting power.
- Hunter: tracking, weak points, boss preparation.
- Survivor: healing, defense, traversal.
- Commander: followers and settlement defense.
- Mechanist: crafted weapons, traps, turrets.
- Profane Focus: the protagonist's rage barks trigger combat effects.

Release target: 60+ abilities/perks.

## Quests

Quest data should be resource-driven:

- quest ID,
- title,
- region,
- giver,
- prerequisites,
- stages,
- objectives,
- dialogue lines,
- rewards,
- failure consequences,
- settlement/faction effects.

Objective types:

- travel to location,
- talk to NPC,
- kill enemy group,
- defeat boss phase,
- collect item,
- build structure,
- assign follower,
- defend settlement,
- escort caravan,
- investigate tracks,
- choose faction outcome.

## Followers

Follower systems:

- recruitment quest,
- combat role,
- settlement role,
- loyalty score,
- banter pool,
- personal quest,
- equipment slot,
- injury state,
- faction preference.

Follower roles:

- sniper,
- medic,
- scout,
- engineer,
- shieldbearer,
- trader,
- cook,
- mayoral adviser,
- beast tracker,
- explosive specialist.

Release target: 12+ authored followers.

## Settlement Simulation

Settlement resources:

- population,
- food,
- water,
- timber,
- ore,
- medicine,
- ammo,
- morale,
- defense,
- trade,
- research,
- corruption pressure.

Building categories:

- housing,
- farms,
- wells,
- walls,
- towers,
- workshops,
- clinic,
- tavern,
- market,
- forge,
- stables converted into anti-horse armories,
- council hall,
- docks,
- research lab.

Settlement events:

- horse raid,
- refugee arrival,
- trade caravan,
- disease,
- faction dispute,
- follower conflict,
- boss threat,
- resource shortage,
- festival,
- sabotage.

The player must be able to found the settlement, choose expansion priorities, assign followers, and watch it grow into a city.

## Save System

Save slots must include:

- chosen character name,
- player position,
- region states,
- active quests,
- completed quests,
- inventory,
- equipped items,
- ability unlocks,
- follower states,
- settlement state,
- faction reputation,
- defeated bosses,
- discovered locations,
- settings,
- migration version.

Autosave moments:

- entering region,
- completing quest stage,
- changing equipment,
- building settlement structure,
- recruiting follower,
- defeating boss,
- before major story decisions.

## UI and UX

Android-first required screens:

- title menu,
- new-game character naming,
- save slots,
- pause menu,
- settings,
- inventory,
- equipment,
- map,
- quest journal,
- follower roster,
- settlement management,
- dialogue,
- vendor,
- crafting,
- boss intro,
- death/retry,
- credits.

Touch rules:

- 48dp minimum touch targets.
- Primary combat controls remain reachable without covering the player.
- Menus support back navigation.
- Text must remain readable on phones.
- Critical actions require confirmation.
- Safe areas are respected.
