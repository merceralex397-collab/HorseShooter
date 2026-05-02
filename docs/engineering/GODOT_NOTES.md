# Godot Engineering Notes

This project targets Godot 4.6.1 and Android. Keep these details in mind while implementing the RPG reboot.

## Headless Test Scenes

Godot 4.6 `--script` expects a script that inherits `SceneTree` or `MainLoop`. The repo smoke tests inherit `Node`, so run them through `.tscn` scenes:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/ci_smoke_test.tscn
```

Use this pattern for new validation tests: create a small scene under `tools/` whose root node owns the test script, then call `get_tree().quit(0)` or `get_tree().quit(1)`.

## Android Export Requirements

Android export requires:

- Godot Android export templates installed for the exact engine version.
- `export/android/java_sdk_path` set in Godot editor settings.
- Android SDK with platform tools and build tools.
- `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`.
- A Godot 4.6-shaped `export_presets.cfg`; older Android keys such as `application/package/unique_name` are ignored by the 4.6 exporter.

Current local export uses Android build-tools `36.1.0`. Godot warns `Could not find version of build tools that matches Target SDK, using 36.1.0`, then exports and signs successfully. Treat that as a toolchain-version warning unless export verification fails.

Verify release APK signatures with:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Users\rowan\AppData\Local\Android\Sdk\build-tools\36.1.0\apksigner.bat' verify --verbose export\HorseShooter.apk
```

## Autoloads

Release-critical managers should be autoloaded in `project.godot` only when they are required before any scene runs. Current reboot autoloads:

- `SaveManager`
- `DialogueManager`
- `ContentDatabase`
- `QuestManager`
- `InventoryManager`
- `ProgressionManager`
- `FollowerManager`
- `SettlementManager`
- `CombatDirector`
- temporary prototype managers: `GameManager`, `AudioManager`, `ObjectPool`

Keep new managers small. Prefer explicit APIs and signals over broad global mutable state.

## Save Data

Use `user://saves/<slot>.json` for RPG save slots. Stable IDs must be persisted instead of scene node paths.

The player character has a player-chosen name stored as `chosen_character_name`. Do not introduce a canonical protagonist name in scripts, resources, or docs.
