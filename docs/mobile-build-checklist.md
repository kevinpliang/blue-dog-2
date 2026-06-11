# Dog Run Mobile Build Checklist

## Shared Prerequisites

- Install Godot 4.5.1 export templates from **Editor > Manage Export Templates**.
- Confirm the project boots and all headless tests pass.
- Confirm the game remains portrait-only and HUD controls stay inside device safe areas.
- Update `config/version` and both export preset versions before release builds.

## Android Debug Build

1. Install Android Studio, Android SDK Platform Tools, and a compatible JDK.
2. Configure Godot's Android SDK and Java paths under **Editor Settings > Export > Android**.
3. Export:

```powershell
godot --headless --path . --export-debug "Android" build/dog-run-debug.apk
```

4. Install and launch:

```powershell
adb install -r build/dog-run-debug.apk
adb shell monkey -p com.kevin.dogrun 1
```

5. Before release, configure a private release keystore and replace debug signing.

## iOS Debug Build

1. Use macOS with Xcode and Godot 4.5.1 export templates installed.
2. Set `application/app_store_team_id` in `export_presets.cfg`.
3. Export the iOS project from Godot, open it in Xcode, select a development team, and run on a connected device.
4. Before release, verify bundle identifier, signing certificates, provisioning profile, version, and App Store metadata.

## Device Smoke Test

- Start, swipe in all four directions, and restart after collision.
- Background and foreground during an active run.
- Verify the distant track fades without a visible endpoint.
- Verify score and best score avoid notches and rounded corners.
- Run for three minutes while watching performance diagnostics.
- Confirm sound and haptics are comfortable and do not continue while paused.

## Current Environment Result

Verification attempted on June 11, 2026 with Godot 4.5.1:

- Android preset loaded, but export stopped because valid Java SDK and Android SDK paths are not configured in Godot Editor Settings.
- iOS preset loaded, but export stopped because `application/app_store_team_id` is intentionally unset.
- Physical Android and iOS smoke tests remain required.
