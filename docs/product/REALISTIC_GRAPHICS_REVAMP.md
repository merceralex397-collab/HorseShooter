# Realistic Graphics Revamp

The requested visual standard is "pleasant and realistic" while remaining Android-safe. For this project that means stylized realism, not literal photorealism. A top-down/elevated 2D RPG needs clear silhouettes, readable terrain, fast controls, and stable frame time. The right target is authored 2D/2.5D with believable light, materials, weather, and animation.

## Visual North Star

The game should feel like a gritty fantasy-western RPG world that happens to be absurdly hostile to horses:

- painted terrain with believable material variation,
- layered props and foreground/background depth,
- soft but readable shadows,
- dramatic weather that changes play,
- enemy silhouettes visible at phone scale,
- strong color scripting per biome,
- UI that feels physical without becoming ornate clutter.

## What Changed In This Pass

- Added root product/design context files.
- Added a shared Godot UI theme with dark iron, leather, parchment, brass, red, and map-blue tokens.
- Added an atmospheric title screen backdrop with road, hills, hoof tracks, protagonist silhouette, and hostile distant horse shapes.
- Added biome weather profiles for all major regions.
- Added weather overlay/decal drawing to region chunks.
- Added weather encounter modifiers for health, damage, weak-point windows, and escape pressure.
- Added low-end graphics setting and low-end behavior in the weather director.
- Added smoke tests for weather profiles and enhanced visual reports.
- Added readable drawn silhouettes for settlement clusters, caves, dungeon gates, temple ruins, horse sites, mines, and distinct location emblems.
- Added visible open-world shot tracer, muzzle flash, and HUD combat feedback so shooting is legible during exploration.

## Final Art Pipeline

1. Generate concept references from `IMAGEGEN_PROMPT_PACK.md`.
2. Select only images that match protagonist identity, readability, tone, and biome clarity.
3. Paint/edit final source art into production sheets.
4. Export Godot-ready atlases:
   - character atlases,
   - horse enemy atlases,
   - boss atlases,
   - biome ground/prop atlases,
   - UI atlases,
   - VFX atlases.
5. Import with Android compression settings.
6. Run headless scene load and visual smoke tests.
7. Test on actual Android hardware before claiming a graphics phase complete.

## Quality Tiers

Low-end:

- No weather particles.
- Reduced overlay intensity.
- No distortion.
- Fewer decals.
- Smaller VFX budgets.
- Shorter combat effect lifetimes.

Standard:

- Weather overlays.
- Decals.
- Region color grade.
- Normal VFX counts.
- Atlas textures at target mobile resolution.

High:

- Extra atmospheric particles.
- More prop variation.
- Higher-resolution portraits and key UI art.
- Stronger lighting passes if device budget allows.

## Scene Composition Rules

- Roads must always be readable.
- Quest and interaction anchors cannot be hidden by high-frequency clutter.
- Horse tracks should support navigation and story, not become noise.
- Boss arenas need clear shape language and safe boundaries.
- Settlements must visibly change by tier.
- Weather should never make UI or telegraphs unreadable.
- The player silhouette must remain identifiable from front, side, and back.

## Android Rendering Rules

- Prefer CanvasItem shaders only when they replace a real need.
- Avoid multi-pass full-screen effects on low-end.
- Pack repeated props into atlases.
- Keep large backgrounds region-scoped and streamable.
- Keep UI textures separate from world textures.
- Use stable texture dimensions and import settings.
- Validate all build scenes in headless mode.

## Replacement Order

1. Protagonist concept and sprite sheet.
2. Greenbarrow terrain and props.
3. Starter horse enemy family.
4. Toll Mare boss.
5. UI atlas and icons.
6. Weather/VFX atlas.
7. Remaining biome atlases.
8. Remaining horse families and bosses.
9. Store key art and loading screens.

## Acceptance Criteria

- The title screen immediately signals open-world RPG, female long-dark-haired protagonist, and hostile horse world.
- Greenbarrow no longer looks like a prototype arena.
- Each region has unique color, weather, resources, hazards, and horse identity.
- UI is readable on a 6-inch Android phone.
- Low-end graphics mode keeps the game playable.
- No final-release scene depends on uncurated generator output.
