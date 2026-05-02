# HorseShooter Design System

## Design Register

Product UI for an Android game. The interface serves play, inventory management, map reading, dialogue, settlement planning, and save/settings workflows. It should feel rugged, readable, physical, and direct.

## Physical Scene

The player is holding an Android phone in mixed light, glancing between twin-stick combat, quest text, map routes, and settlement decisions. The UI must survive daylight glare, quick thumb input, and dense RPG information without covering immediate threats.

## Visual Strategy

- Theme: dark iron, weathered leather, worn parchment, brass progress accents, danger red for horse pressure, map blue for navigation.
- Color use: restrained product palette. Red and brass are accents, not decorative floods.
- Shape: squared panels or 4-8 px radius equivalents. Avoid pill-heavy UI except for tiny status chips.
- Texture: subtle framed surfaces and readable contrast, not glassmorphism.
- Motion: 150-250 ms transitions for menu panels, pressed states, and route changes only.

## Semantic Tokens

- `surface_base`: charcoal iron, used for full-screen UI backgrounds.
- `surface_panel`: warm dark leather, used for menus, inventory, dialogue, settlement panels.
- `surface_elevated`: slightly lighter worn iron, used for active selections and modal sheets.
- `text_primary`: warm parchment.
- `text_secondary`: muted parchment.
- `accent_danger`: dry blood red, used for horse threat, damage, destructive actions.
- `accent_progress`: tarnished brass, used for XP, upgrades, selected tabs, confirmed actions.
- `accent_map`: desaturated blue, used for map routes, tracked quests, discovery.
- `success`: muted field green.
- `warning`: amber ochre.
- `disabled`: low-contrast iron gray with clear non-interactive opacity.

## Mobile Interaction Rules

- Touch targets are at least 48 px in Godot UI coordinates.
- Critical icon actions must also have labels or accessible text.
- Fixed combat UI respects safe areas and must not cover the player, boss telegraphs, or interaction prompts.
- Back closes the active panel first, then returns to the previous screen.
- Inventory, quest journal, follower roster, and settlement screens need filters before content reaches release scale.

## Typography

- Use Godot default/system font unless a production font is imported intentionally.
- Minimum body copy size for phone UI: 16.
- Primary panel title: 24-34 depending on screen.
- Buttons: 16-18, medium weight where available.
- Long prose wraps at readable widths, not edge-to-edge across tablet landscape.

## Component Rules

- Buttons: default, pressed, hover/focus, disabled, and selected states.
- Panels: strong contrast from background, 2 px brass or iron border only when helpful.
- Lists: row height supports touch, selected row uses brass or map-blue indicator plus text state.
- Dialogue: speaker, line, response choices, and next action must be visually separate.
- Settings: visible labels, helper text where values affect accessibility or performance.

## Art Direction Summary

The in-game world targets stylized realism: painted 2D/2.5D environments, layered lighting, practical silhouettes, atmospheric weather, and readable combat shapes. Generated images are concept references until processed into Godot-ready atlases with explicit import settings and validation.
