# Content ID Rules

All scalable RPG content must use stable IDs. Save files and quest state should store IDs, not scene paths or display names.

## Format

Use lowercase dotted IDs:

```text
domain.category.name
```

Allowed characters:

- lowercase letters,
- numbers,
- underscores inside segments,
- dots between segments.

Examples:

```text
weapon.revolver.rusty_oath
equipment.coat.ash_walker
quest.greenbarrow.road_full_of_hooves
enemy.horse.runner_greenbarrow
settlement.building.watchtower_wood
```

Do not use spaces, display punctuation, uppercase letters, localized text, or scene paths as IDs.

## Godot Notes

Godot Resources can expose `@export var id := ""`, but validation must happen through tooling before content is scaled. The initial validator lives in `src/content/content_validator.gd` and is smoke-tested by `tools/content_id_smoke_test.tscn`.
