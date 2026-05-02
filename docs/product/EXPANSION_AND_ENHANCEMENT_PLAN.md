# Expansion and Enhancement Plan

Scope: turn the current Godot prototype/RPG scaffold into the large Android open-world RPG described in the reboot direction. This is deliberately broad, but each item should become a small implementation ticket before coding.

## Current Project Audit

What is strong now:

- Godot 4.6.1 project boots headlessly.
- Android export wiring exists.
- AppRoot, save slots, character naming, settings, and world scene flow exist.
- RPG managers exist for content, quests, inventory, progression, followers, settlement, factions, combat, dialogue, and saves.
- A starter open-world scene exists with regions, locations, roads, interaction anchors, a player controller, map/journal/inventory/town overlay, and data stubs.
- Content scale targets are represented in generated starter resources.
- Player visual placeholder already preserves the required adult woman, long dark brown hair identity.
- The implemented world now has 8 major regions, 120+ authored locations, 40+ towns/villages/cities/forts/camps/settlements, 30+ cave/dungeon/temple/ruin/mine/shrine/wreck sites, and 25+ horse sites/lairs/stables/boss arenas.
- Open-world shooting now creates a visible tracer/muzzle flash, starts nearby horse-site encounters, resolves damage, and surfaces hit feedback in the RPG overlay.

Major gaps:

- Most "large RPG" systems are still shallow first passes.
- Region streaming is a single active chunk, not a mature chunk grid with async loads, persistence, and occlusion budgets.
- Quests and dialogue need authored structure, choices, consequences, and actual dialogue UI depth.
- Settlement growth lacks raids, layout editing depth, trade routes, production loops, and endings.
- Followers need AI roles, injuries, loyalty, equipment, personal quests, and settlement jobs with mechanical tradeoffs.
- The graphics are still procedural placeholders. They are now more atmospheric, but not final production art.
- Audio direction, music layering, bark delivery, and subtitle settings are not production-ready.
- Android validation still needs physical device testing, thermal/battery checks, and low-end graphics verification.

## Product Scale Targets

Release target:

- 8 major regions.
- 120+ authored explorable world locations at minimum.
- 40+ authored settlements across villages, towns, cities, forts, camps, harbors, and player-founded settlement growth.
- 30+ authored exploration interiors/sites across caves, dungeons, temples, mines, ruins, shrines, and wrecks.
- 25+ horse places across lairs, corrupted stables, horse runs, horse sites, and boss arenas.
- 60+ authored quests plus repeatable world events.
- 12+ followers with recruitment, banter, jobs, combat roles, loyalty, and personal quests.
- 100+ weapons.
- 150+ equipment items.
- 60+ abilities/perks.
- 25+ regular horse enemy archetypes.
- 12+ boss horses.
- 5+ faction arcs.
- 30-minute Android stability pass with stable memory and save/load behavior.

Vertical-slice target:

- Greenbarrow Grasslands as one dense, replayable starter region with villages, towns, ruins, caves, dungeons, temples, stables, a fort, roads, route gates, and boss access.
- 8-12 quests.
- 2 followers.
- 1 founded settlement tiering from camp to outpost.
- 12 weapons, 20 equipment items, 10 abilities.
- 5 horse archetypes, 1 boss.
- Final-style visual target represented by curated assets or high-fidelity placeholders.

## Graphics Revamp Plan

Immediate visual upgrades already started:

- Root `DESIGN.md` and `PRODUCT.md` now define product and design context.
- The title screen uses a drawn atmospheric RPG backdrop instead of flat blocks.
- The UI now has a shared rugged Android RPG theme.
- Regions now receive biome weather profiles and visual directives.
- Region chunks draw decals, lighting grade, weather overlays, and biome-specific atmosphere.
- Region chunks now draw distinct visual silhouettes for cities, towns, villages, caves, dungeon gates, temples, horse sites, mines, forts, boss arenas, and route nodes.
- The HUD now tells the player that Fire shoots, and shot feedback is visible in the world and UI.
- Low-end graphics mode exists as a saved setting and disables expensive weather particles/overlays.

Production graphics goals:

- Replace generated prototype sprites with curated character, horse, environment, prop, UI, and VFX atlases.
- Keep stylized realism: believable materials, shadows, lighting, and scale, but readable from an elevated 2D action-RPG camera.
- Use layered 2D/2.5D: ground, props, interactive objects, characters, weather, lighting, UI.
- Build texture atlases by region and character family.
- Create Android import presets for ETC2/ASTC, alpha textures, atlas grouping, and mipmap rules.
- Add low, standard, and high visual quality settings.

Art production list:

- Protagonist full-body concept sheet.
- Protagonist portrait sheet.
- Protagonist 8-direction idle, walk, aim, shoot, reload, dodge, interact, hurt, downed, bark animation.
- Long dark brown hair silhouette variants for motion and readability.
- Greenbarrow ground atlas: grasses, dirt, roads, hoof prints, trampled crops, broken fences.
- Greenbarrow prop atlas: wagons, tents, barricades, road signs, crates, campfire, ruins.
- Settlement atlas: camp, outpost, hamlet, village, town, city buildings.
- Weather atlases: dust, fog, snow, salt mist, ash, embers, corruption veil.
- Combat VFX atlas: muzzle flashes, impact sparks, dust puffs, weak-point flashes, status effects.
- Horse enemy family sheets by region.
- Boss horse sheets with phase damage states.
- UI atlas: brass frames, iron panels, parchment strips, map pins, threat icons, settlement icons.
- Loading/title art and store key art.

Region visual identity:

- Greenbarrow: warm grass, dust, readable roads, trampled farms, early settlement growth.
- Gallowpine: layered trees, fog bands, moss, hidden movement, lower visibility.
- Frostreel: blue-white snow, wind needles, frozen rivers, breath vapor.
- Saltwake: tide foam, ropes, docks, brine stains, kelp-like horse corruption.
- Blackglass: cliffs, scree, bridges, mine shafts, glassy black rocks.
- Cinderjaw: basalt, lava glow, ash, ember particles, heat distortion.
- Pale Spur: salt flats, cracked roads, canyon shadows, mirage dust.
- Withered Paddock: corrupted stable geometry, purple-black veil, warped roads, hostile shadows.

## World and Exploration Plan

World systems:

- Chunk grid with stable region/chunk IDs.
- Async chunk preloading around player.
- Safe unload that preserves cleared encounters, looted containers, NPC movement, and settlement edits.
- Roads with safety ratings, patrol state, ambush state, and fast-travel unlocks.
- Fog of war per region and per landmark.
- Player map with tracked quests, discovered locations, filters, threat overlays, and trade route overlays.
- Biome weather modifiers for traversal, encounter density, visibility, resources, and combat.
- Regional threat level driven by escapes, raids, boss influence, faction activity, and quest choices.

Exploration content list:

- Roadside camps.
- Ruined farms.
- Stable forts.
- Abandoned villages.
- Mines.
- Coastal wrecks.
- Frozen lakes.
- Lava roads.
- Salt flats.
- Corrupted paddocks.
- Faction checkpoints.
- Follower recruitment sites.
- Hidden shrines.
- Boss lairs.
- Treasure caches.
- Lost caravans.
- Settlement founding plots.
- Environmental puzzles.
- Trap fields.
- Horse nest clearings.
- Roaming boss routes.

Current implemented world-density floor:

- Every major region has at least 15 authored sites.
- Each region has multiple safe settlements and multiple dangerous horse/exploration sites.
- Greenbarrow starts with 18 sites including Millbrook Village, Sableford Town, No-Reins Market, Clatterhoof Cave, Understable Dungeon, Old Stone Temple, Sunk Stable, Trampled Orchard, East Watch Fort, and the Toll Mare Arena.
- Later regions include forest cities, snow towns, harbor cities, mountain mines, volcanic settlements, badland temples, corrupted final-region cities, and multiple route gates between regions.

Traversal upgrades:

- Dodge with stamina cost and i-frame tuning.
- Sprint or road-run mode.
- Climb/vault for low obstacles where useful.
- Region-specific traversal tools: snow cleats, brine boots, heat cloak, mine lift pass, corruption lantern.
- Mounts are not appropriate for the premise unless deliberately subverted. Use carts, lifts, boats, teleport markers, and settlement roads instead.

## Combat Plan

Combat principles:

- Every horse role has a readable silhouette and telegraph.
- Misses cost ammo/heat/opportunity, not instant failure.
- Escapes become world consequences or hunt quests.
- Weapons differ by handling, reload, spread, range, ammo, weak-point behavior, heat, and status.
- Bosses change the arena and world state, not just health totals.

Core combat backlog:

- Stamina-backed dodge with cooldown UI.
- Weapon reload and ammo UI.
- Heat/cooldown families for experimental weapons.
- Manual aim, hold fire, auto-fire accessibility mode.
- Weak-point feedback: hit quality, sound, VFX, damage text.
- Enemy telegraph renderer.
- Status effects: bleed, burn, freeze, brine, fear, stagger, corrosion, curse.
- Armor/resistance model visible in inspection UI.
- Difficulty tuning tables per biome.
- Combat test matrix by weapon family and horse role.

Horse enemy expansion:

- Runner: speed pressure.
- Charger: line telegraph, impact, wall stun.
- Spitter: arcing mud/brine/ash projectile.
- Pack leader: buffs and summons.
- Armored: plate facing, weak points.
- Burrower: ground eruption.
- Spectral: phase shift, anti-corruption tools.
- Elemental: fire, snow, brine, poison, storm, ash, shadow.
- Siege horse: targets settlement buildings.
- Messenger horse: tries to flee and raise regional threat.
- Mimic horse: disguised as a normal object or landmark.
- Boss lieutenant: mini-boss with named hunt consequences.

Boss horse plan:

- The Toll Mare: charge, summon, road smash.
- Whiteout Stallion: vanishes in snow, creates false silhouettes, freezes paths.
- Reef Kelpie: pulls player with tide lanes, splits in foam.
- Glassback Colossus: armored plates rotate, rockfalls create cover.
- Cinder Mare: lava trails, ember kicks, arena heat pressure.
- Pale Herd King: mirage copies, dust wall, bone charge.
- Orchard Widow: corrupted farm boss with root snares and poisoned apples.
- Brass Cavalry Engine: mechanical horse boss built by a hostile faction.
- Black Stable Saint: story boss tied to horse worship cult.
- The Last Horse: final campaign boss with world-trample phases.

## Weapons, Equipment, and Progression

Weapon families:

- Pistols: fast, low damage, strong mobility.
- Revolvers: reliable crit and weak-point play.
- Rifles: range and precision.
- Shotguns: close burst and stagger.
- Lever guns: rhythm reload.
- Hand cannons: slow, high impact.
- Crossbows: quiet, status bolts.
- Launchers: area damage, expensive ammo.
- Traps: preparation, chokepoints, boss setup.
- Throwables: emergency control.
- Experimental anti-horse devices: heat, unstable effects, settlement crafting.
- Settlement weapons: turrets, watchtowers, field cannons.

Equipment categories:

- Coats, boots, gloves, hat/hair accessory, belt, charm, weapon mod, utility, banner.
- Gear should support builds: crit hunter, shotgun brawler, settlement commander, trap mechanist, follower tactician, survival explorer, profane-focus rage build.

Ability trees:

- Gunslinger: fire rate, crit, reload, recoil, weak-point reward.
- Hunter: tracks, preparation, boss knowledge, ambush prevention.
- Survivor: health, stamina, dodge, resistance, weather tools.
- Commander: followers, settlement defense, morale, rally actions.
- Mechanist: traps, turrets, crafted weapons, mod slots.
- Profane Focus: barks trigger buffs, debuffs, fear, reload surges, horse-targeted rage.

Progression requirements:

- Every perk has a clear UI description.
- Every stat has a readable effect.
- Builds are valid with touch controls.
- Respec exists through settlement services or rare items.
- Save/load preserves equipped state, perks, mastery, and UI new-item flags.

## Quest, Dialogue, and Story Plan

Quest types:

- Main campaign.
- Region arcs.
- Settlement growth quests.
- Follower recruitment and loyalty quests.
- Boss hunts.
- Faction choices.
- Crafting unlocks.
- Dynamic encounter chains.
- Consequence quests caused by escaped named horses.
- Repeatable defense and bounty events.

Dialogue requirements:

- Chosen-name token only where natural.
- No canonical protagonist name.
- Profanity must fit anger, comedy, pace, or story.
- Followers should react to the protagonist's horse hatred without flattening into one joke.
- Dialogue UI needs speaker portrait, line text, response choices, quest flags, skip/advance, back behavior, and subtitle settings.

Story arcs:

- Greenbarrow: survival and founding Spitehold.
- Gallowpine: old road cult and ambushes.
- Frostreel: isolated settlements and whiteout boss threat.
- Saltwake: trade, smuggling, coast boss, water routes.
- Blackglass: mining factions, bridges, mechanical upgrades.
- Cinderjaw: volcanic resources and weapon experiments.
- Pale Spur: outlaw settlements, mirages, faction war.
- Withered Paddock: corrupted origin of organized horses and final campaign pressure.

## Factions and Consequences

Faction list:

- Roadwardens: practical road defenders.
- Spitehold settlers: player-founded civic base.
- Gallowpine Watch: forest survivalists.
- Saltwake Compact: trade and docks.
- Blackglass Miners: ore, lifts, explosives.
- Cinderjaw Foundry: risky anti-horse technology.
- Pale Spur Outriders: outlaw pragmatists.
- Stable Choir: horse-worship cult.
- Last Pasture: corrupted horse-aligned force.

Faction systems:

- Reputation values.
- Conflict flags.
- Trade permissions.
- Settlement influence.
- Follower preferences.
- Quest availability.
- Boss hunt intel.
- Endings and city outcomes.

## Settlement and City Plan

Settlement pillars:

- Founded by player.
- Grows through resources, buildings, people, followers, quests, and defense.
- Has visible state in the world.
- Produces mechanical consequences, not cosmetic upgrades only.

Building categories:

- Housing.
- Food.
- Water.
- Defense.
- Production.
- Medicine.
- Trade.
- Research.
- Crafting.
- Governance.
- Travel.
- Story monuments.
- Converted stable armories.

Events:

- Horse raid.
- Named horse siege.
- Refugees.
- Disease.
- Water shortage.
- Trade caravan.
- Faction envoy.
- Sabotage.
- Follower dispute.
- Festival.
- Boss omen.
- Fire.
- Corruption outbreak.

Follower jobs:

- Scout: reduces ambushes, reveals map hints.
- Builder: reduces building cost.
- Doctor: prevents injury death and improves morale.
- Trader: increases trade and rare goods.
- Researcher: unlocks experimental gear.
- Guard: improves raid defense.
- Cook: boosts morale and stamina bonuses.
- Mechanist: turret and trap upgrades.
- Diplomat: faction pressure.
- Mayor's aide: city event mitigation.

## UI and UX Plan

Screens:

- Title.
- Save slots.
- Character naming.
- Settings.
- Credits.
- Pause.
- Inventory.
- Equipment.
- Ability trees.
- Map.
- Quest journal.
- Dialogue.
- Follower roster.
- Settlement management.
- Building placement.
- Crafting.
- Vendor.
- Boss intro.
- Death/retry.
- Codex/bestiary.

Mobile UI backlog:

- Safe-area helper.
- Bottom combat controls with configurable opacity.
- Aim/fire stick calibration.
- Dodge button with cooldown ring.
- Interact prompt priority stack.
- Quest tracker compact/full modes.
- Inventory filters and sort.
- Map pan/zoom with marker filters.
- Large-text mode validation.
- Reduced-effects mode validation.
- Colorblind-safe status indicators.
- Screen-reader labels where Godot/mobile support allows.

## Android Performance Plan

Budgets:

- 60 FPS target on mid-range device.
- 30 FPS minimum on low-end supported device.
- No single frame stutters above accepted threshold during chunk load.
- Texture memory budget per region.
- Draw-call budget per chunk.
- Weather particles disabled or reduced in low-end mode.
- UI remains responsive under heavy inventory lists.

Validation:

- Headless scene load for every build scene.
- Content ID validation.
- Content reference validation.
- World region smoke tests.
- Weather/visual-quality smoke tests.
- Save migration test.
- APK export.
- APK install on device.
- 30-minute stability test.
- Battery/thermal observation.

## Implementation Milestones

Milestone 1: Current vertical slice hardening.

- Weather/director smoke tests.
- Dodge UI.
- Basic dialogue UI.
- Greenbarrow quest chain tightened.
- Settlement camp to outpost polished.
- Low-end graphics mode verified locally.

Milestone 2: Art vertical slice.

- Protagonist concept and sprite sheet.
- Greenbarrow atlas.
- Starter horse family.
- Toll Mare boss art.
- UI atlas pass.
- First sound/music pass.

Milestone 3: World expansion.

- Chunk streaming grid.
- Gallowpine and Frostreel playable.
- Region weather affects encounters and resources.
- Map filters and fast travel.
- Faction reputation surfaced.

Milestone 4: Systems depth.

- Follower combat roles.
- Follower settlement assignments.
- Raids and defense events.
- Trade routes.
- Crafting and upgrade UI.
- Combat test matrix.

Milestone 5: Release content and hardening.

- Full region set.
- Full quest/follower/boss content.
- Android export verified.
- Device install, thermal, battery, offline, save/load, and migration tests complete.
