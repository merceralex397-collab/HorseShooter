# Art Direction and Asset Pipeline

## Visual Target

High-detail stylized-realistic 2D/2.5D fantasy-western satire for Android. The target is pleasant, authored, and believable at mobile scale, not literal photorealism that breaks readability or performance.

The final game should not look like the current generated pixel prototype. It should feel authored, dramatic, readable, and mobile performant:

- layered painted environments,
- animated characters with strong silhouettes,
- directional lighting,
- weather overlays,
- biome color scripts,
- shader-driven water, snow, heat haze, ash, and fog,
- punchy combat VFX,
- readable UI with rustic metal, parchment, charcoal, and red accent details.

This pass adds the first runtime visual systems that support the final look: biome weather profiles, weather-driven encounter modifiers, weather/decal overlays in region chunks, a low-end graphics switch, and a more atmospheric title screen. These are still scaffolding for final art, not a replacement for curated sprite sheets and atlases.

## Protagonist Visual Contract

Player-named protagonist:

- adult woman,
- long dark brown hair,
- strong readable silhouette,
- practical coat and boots,
- weapon harness,
- expressive angry face,
- no horse-friendly styling,
- animation set must preserve hair identity from front, side, and back.

Required animation families:

- idle,
- walk/run eight directions,
- aim eight directions,
- shoot,
- reload,
- dodge,
- interact,
- hurt,
- downed,
- victory/insult bark,
- settlement command gesture.

## Horse Enemy Art Contract

Horse enemies must be varied and region-specific. The silhouette should make threat role obvious:

- runners: lean and fast,
- chargers: heavy shoulders and low head,
- ranged horses: lifted neck/head projectile posture,
- pack leaders: banners, marks, or glow,
- bosses: huge silhouette, multi-part animations, phase damage states.

Avoid making all horses simple color swaps. Color swaps are acceptable for low-tier variants only.

## Biome Art Direction

Grassland:

- gold-green grasses,
- broken fences,
- big sky,
- readable roads,
- dust from hooves.

Forest:

- layered trunks,
- fog bands,
- moss,
- shafts of light,
- hidden horse eyes in darkness.

Snow:

- blue-white shadows,
- wind streaks,
- crunch decals,
- frozen rivers,
- breath vapor.

Ocean/coast:

- animated water,
- tide foam,
- ropes,
- docks,
- gull-free soundscape if desired,
- brine-stained horse variants.

Mountains:

- steep parallax cliffs,
- bridges,
- scree,
- mine entrances,
- wind particles.

Volcano:

- ash,
- lava glow,
- heat haze,
- basalt,
- ember particles,
- high-contrast silhouettes.

Badlands:

- salt flats,
- canyon shadows,
- bleached bones,
- distant mirage distortion.

Withered Paddock:

- corrupted color script,
- warped roads,
- impossible stable geometry,
- animated shadows,
- horse-mark glyphs.

## UI Direction

Use a functional mobile RPG interface, not a decorative web landing page.

Style:

- dark iron and worn parchment surfaces,
- red accent for danger/horse threat,
- warm brass for progression,
- cool blue for map/quest markers,
- restrained shadows,
- square or mildly rounded panels,
- icon plus label for navigation,
- large touch targets.

Required UI qualities:

- readable on 6-inch phones,
- no tiny icon-only critical controls,
- clear back behavior,
- bottom combat controls do not obscure threats,
- inventory and settlement screens can handle hundreds of entries through filters and categories.

## Image Generation Usage

Use AI-generated raster imagery for concept exploration and production references, then normalize into Godot-ready assets. Do not reference project assets directly from generator output until they are curated, compressed, named, and imported.

Recommended asset prompt schema:

```text
Use case: stylized-concept
Asset type: Godot 2D open-world RPG concept art reference
Primary request: [specific character, biome, horse boss, settlement, or UI scene]
Scene/backdrop: [region and environmental details]
Subject: [main subject]
Style/medium: high-detail stylized 2D game concept art, painterly but readable at mobile scale
Composition/framing: orthographic or slightly elevated action-RPG camera, clear silhouettes
Lighting/mood: dramatic but readable, strong value separation
Color palette: biome-specific palette from this art direction doc
Constraints: no text, no watermark, no photorealism, no unreadable tiny details
Avoid: generic stock fantasy, over-dark scenes, low-contrast characters, horse-friendly tone
```

See `docs/product/IMAGEGEN_PROMPT_PACK.md` for production-ready prompt sets for protagonist, UI, Greenbarrow, settlement growth, starter horses, Toll Mare, and biome sheets.

Priority generated concept sets:

1. Player-named protagonist full-body turnaround and portrait.
2. Grassland vertical-slice environment.
3. First town/camp visual development.
4. Four starter horse enemy archetypes.
5. First boss horse key art.
6. UI mood board for Android menus.
7. Biome concept sheets for snow, ocean, mountain, volcano, forest, badlands, and corruption.

## Godot Asset Pipeline

Recommended pipeline:

1. Generate or paint concept art.
2. Produce clean sprite sheets or layered source art.
3. Pack atlases by region and character family.
4. Import with explicit compression settings for Android.
5. Validate memory and draw-call budgets.
6. Add resource manifests so missing assets fail validation.

Texture guidelines:

- Use atlases for repeated environment props.
- Keep large backgrounds region-scoped and streamable.
- Prefer WebP/PNG based on alpha and compression needs.
- Avoid unbounded unique full-screen textures.
- Keep VFX sprite sheets short, punchy, and reusable.

Shader guidelines:

- Use low-cost CanvasItem shaders.
- Budget each biome effect separately.
- Disable expensive overlays on low-end mode.
- Prefer scrolling textures and simple distortion over heavy multi-pass effects.
