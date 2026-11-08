/// Selectable app palettes.
///
/// `neon` is the product's signature look: the dark canvas plus cyan/violet
/// glow accents. `light` and `dark` are the plain Material variants.
///
/// Lives in `core/theme` because both the palette definitions and the settings
/// layer depend on it; keeping it here means `core` never imports `features`.
enum AppThemeMode { light, dark, neon }
