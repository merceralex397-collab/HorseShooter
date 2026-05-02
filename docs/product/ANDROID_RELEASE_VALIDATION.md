# Android Release Validation

## Current Local Facts

Godot executable discovered on this machine:

```powershell
C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe
```

The user-provided path points at a directory named `.exe`; the runnable console binary is inside that directory.

Current repository includes:

- `android/gradlew.bat`
- `android/libs/release/godot-lib.template_release.aar`
- `export_presets.cfg`

Resolved local export setup:

- Godot 4.6.1 Android export templates are installed at `C:\Users\rowan\AppData\Roaming\Godot\export_templates\4.6.1.stable`.
- Godot editor setting `export/android/java_sdk_path` is set to `C:\Program Files\Android\Android Studio\jbr`.
- Android SDK is available at `C:\Users\rowan\AppData\Local\Android\Sdk`.
- A local validation release keystore exists at `C:\Users\rowan\AppData\Roaming\Godot\keystores\horseshooter-release.keystore`.
- `export/HorseShooter.apk` has been generated and verified with APK Signature Scheme v2/v3.
- `export/HorseShooter-debug.apk` has been generated successfully.
- AAB export currently requires the Godot Android source build template (`android_source.zip`), which is not installed in `C:\Users\rowan\AppData\Roaming\Godot\export_templates\4.6.1.stable`.
- Physical device install, 30-minute stability, battery, and thermal validation are blocked until `adb devices` shows an attached device.

Store release signing should use a proper private upload/release key, not the local validation keystore.

## Validation Commands

Godot version:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --version
```

Headless project parse:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --quit
```

Prototype smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://tools/ci_smoke_test.gd
```

Gameplay quality smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --script res://tools/gameplay_quality_smoke_test.gd
```

World weather and biome modifier smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/world_weather_smoke_test.tscn
```

World density smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/world_density_smoke_test.tscn
```

World streaming smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/world_streaming_smoke_test.tscn
```

World content depth smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/world_content_depth_smoke_test.tscn
```

Open-world shooting smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/rpg_shooting_smoke_test.tscn
```

Combat matrix smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/combat_matrix_smoke_test.tscn
```

Release save-state round-trip smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/save_state_roundtrip_smoke_test.tscn
```

Release ownership smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/release_ownership_smoke_test.tscn
```

Dialogue UI smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/dialogue_ui_smoke_test.tscn
```

Follower depth smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/follower_depth_smoke_test.tscn
```

Settlement simulation smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/settlement_simulation_smoke_test.tscn
```

Audio presentation smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/audio_presentation_smoke_test.tscn
```

UI/UX screens smoke test:

```powershell
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --scene res://tools/ui_ux_screens_smoke_test.tscn
```

Android export:

```powershell
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH='C:\Users\rowan\AppData\Roaming\Godot\keystores\horseshooter-release.keystore'
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER='horseshooter'
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='horseshooter'
New-Item -ItemType Directory -Force export
& 'C:\Users\rowan\Downloads\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe' --headless --path . --export-release Android export/HorseShooter.apk
```

APK signature verification:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
& 'C:\Users\rowan\AppData\Local\Android\Sdk\build-tools\36.1.0\apksigner.bat' verify --verbose export\HorseShooter.apk
```

Install on connected device:

```powershell
adb install -r export/HorseShooter.apk
adb shell monkey -p com.horseshooter.game 1
```

## Release Build Requirements

- Android SDK path configured in Godot editor settings.
- JDK configured and compatible.
- Debug export works.
- Release export works.
- Release keystore exists and is configured.
- Package name is final.
- Version code and version name are updated.
- APK/AAB installs on at least one physical Android device.
- App survives launch, suspend, resume, rotate or locked-orientation behavior, and back button.

## Runtime QA Matrix

Startup:

- cold launch reaches title menu,
- continue button only enabled when save exists,
- new game creates a valid save slot,
- settings persist.

Controls:

- left thumb movement,
- right thumb aim,
- fire,
- interact,
- dodge,
- map,
- inventory,
- pause/back,
- dialogue advance,
- settlement building placement.

Performance:

- target 60 FPS on mid-range device,
- minimum acceptable 30 FPS on low-end supported device,
- no shader spikes over budget,
- chunk streaming does not hitch above accepted threshold,
- memory stable after 30 minutes,
- save/load under target time.

Content:

- no missing sprites,
- no missing sounds,
- no missing dialogue IDs,
- no missing biome weather profiles,
- world density floor remains at 120+ locations, 40+ settlements, 30+ exploration sites, and 25+ horse places,
- open-world shooting creates visible feedback and resolves nearby horse-site combat,
- no broken quest objectives,
- no unreachable settlement buildings,
- no invalid item references,
- no orphaned follower states.

Release:

- signed APK/AAB generated,
- install verified,
- offline play verified,
- save migration verified,
- crash logs clean for smoke path,
- credits/licenses present.
