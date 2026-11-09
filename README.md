# THE LOST JOURNEY OF GR

A 2D landscape adventure game built in Godot 4 and GDScript. The project contains five connected chapters, touch and keyboard controls, puzzles, dialogue, inventory, save/load, audio settings, chapter selection, and an ending sequence.

## Technology choice

This project is already implemented in Godot 4. It is not a Phaser/Vite/Capacitor project. The Android build therefore uses Godot's Android export templates. This keeps the existing game and avoids replacing working gameplay with a port. You do not need Godot, Android Studio, Java, or the Android SDK installed locally to get the APK; GitHub Actions installs those tools in its free cloud runner.

## Branding

`assets/branding/official_logo.png` is the supplied logo image. The full image is used in the main menu and startup splash. Android icon files are generated from that source:

- `assets/branding/android/launcher_main_192.png` — legacy launcher icon.
- `assets/branding/android/adaptive_foreground_432.png` and `adaptive_background_432.png` — Android adaptive icon layers. The foreground artwork is kept within the centered safe circle.
- `assets/branding/android/adaptive_monochrome_432.png` — Android themed icon compass mark.
- `assets/branding/splash_logo.png` — game startup splash artwork.
- `assets/branding/android/splash_branding.png` — Android system splash branding.

Godot uses the provided high-resolution launcher layers to generate the Android mipmap density variants during export. Regenerate assets from the supplied source with:

```sh
godot --headless --path . --script tools/generate_android_branding.gd
```

## Build a downloadable APK in GitHub Actions

1. The source repository is `vikasvardhanreddy/THE-LOST-JOURNEY-OF-GR-12`.
2. From a terminal in this project folder, the source can also be pushed with the following commands:

   ```sh
   git init
   git add .
   git commit -m "Prepare THE LOST JOURNEY Android build"
   git branch -M main
   git remote add origin https://github.com/vikasvardhanreddy/THE-LOST-JOURNEY-OF-GR-12.git
   git push -u origin main
   ```

   If `git init` or `git remote add origin` reports that it already exists, keep the existing repository/remote and only push the `main` branch. Keep `.godot/` and local build output ignored.
3. Open the repository's **Actions** tab and enable workflows if GitHub asks.
4. Select **Build THE LOST JOURNEY Android APK** and choose **Run workflow**. A push to `main` or `master` also starts a build.
5. When the job succeeds, open the run and download its `TheLostJourney-Android-Debug` artifact. Unzip it to get `TheLostJourney-debug.apk`.

The workflow runs the project smoke checks, imports the game, exports and validates the debug APK, then uploads it as a 14-day artifact. No signing secrets are needed for a debug install. This APK is for device testing and is not a Play Store release.

## Install on an Android phone

1. Download the artifact ZIP on the phone, or copy it from the computer, and extract the APK.
2. Tap `TheLostJourney-debug.apk`. If Android asks, allow the browser or file manager to install unknown apps for this one installation.
3. Confirm the install and launch **THE LOST JOURNEY**. The app is configured for landscape orientation.

If an older copy with the same package ID but a different debug signing key is installed, uninstall that older copy before installing the new debug APK. Its local save data will also be removed by Android when uninstalled.

## Project layout

```text
assets/                 Game art, audio, and official branding
scenes/                 Main menu, player, HUD, and five chapters
scripts/                Player, systems, chapter logic, and UI
tools/                  Branding generator and headless smoke checks
.github/workflows/      Cloud Android APK build
project.godot           Godot project settings and main scene
export_presets.cfg      Android package, orientation, icon, and splash settings
```
