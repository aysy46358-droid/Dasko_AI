# Dasko AI visual assets

The current robot UI renders the bundled 2D poster at `robot_poster.png` through `InteractiveDaskoRobot` and Flutter's `Image.asset`. Robot status changes are represented by Flutter UI effects; the current app does not load a GLB model, model viewer, or WebView.

Keep image paths centralized in `lib/core/constants/app_assets.dart` and declared in the Flutter asset manifest (`pubspec.yaml`). Update the asset validator and widget tests if the required poster or its loading behavior changes.
