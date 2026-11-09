# Dasko AI launcher icon assets

The approved icon set is stored here without modifying the supplied PNGs:

- `dasko_icon_full_1024.png`: complete icon used by `image_path`.
- `dasko_foreground_1024.png`: transparent adaptive-icon foreground.
- `dasko_background_1024.png`: adaptive-icon background layer.

`flutter_launcher_icons` is configured in the root `pubspec.yaml` for Android. iOS generation remains disabled because this repository does not currently contain an iOS project (`ios/`). Once an iOS project is added, enable `ios: true` to generate its icon catalog from the full image.

Regenerate Android icons with:

```sh
dart run flutter_launcher_icons
```
