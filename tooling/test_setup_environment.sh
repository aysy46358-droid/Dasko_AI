#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

PROJECT="$TMP_DIR/project"
FAKE_FLUTTER_ROOT="$TMP_DIR/fake-flutter"
FAKE_BIN="$TMP_DIR/fake-bin"
SDK="$TMP_DIR/android-sdk"
mkdir -p "$PROJECT/tooling" "$PROJECT/android" "$FAKE_FLUTTER_ROOT/bin" "$FAKE_BIN"
cp "$ROOT_DIR/tooling/setup_environment.sh" "$PROJECT/tooling/setup_environment.sh"
cp "$ROOT_DIR/pubspec.lock" "$PROJECT/pubspec.lock"

cat > "$FAKE_FLUTTER_ROOT/bin/flutter" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == '--version' ]]; then
  printf 'Flutter 3.47.8 • channel stable\n'
  exit 0
fi
if [[ "${1:-}" == 'pub' && "${2:-}" == 'get' && "${3:-}" == '--enforce-lockfile' ]]; then
  printf 'fake flutter pub get succeeded\n'
  exit 0
fi
printf 'unexpected fake flutter arguments: %s\n' "$*" >&2
exit 2
SH
chmod +x "$FAKE_FLUTTER_ROOT/bin/flutter"

cat > "$FAKE_BIN/java" <<'SH'
#!/usr/bin/env bash
printf 'openjdk version "%s"\n' "${DASKO_TEST_JAVA_VERSION:-17.0.17}"
SH
chmod +x "$FAKE_BIN/java"

export PATH="$FAKE_FLUTTER_ROOT/bin:$FAKE_BIN:/usr/bin:/bin"
export ANDROID_HOME="$SDK"
unset ANDROID_SDK_ROOT || true

# Success case: paths are refreshed atomically while unrelated local properties survive.
mkdir -p "$SDK/platforms/android-36" "$SDK/build-tools/36.0.0"
printf '# local property\nflutter.sdk=stale\nsdk.dir=stale\norg.gradle.java.home=/custom/jdk\n' > "$PROJECT/android/local.properties"
printf '#!/usr/bin/env bash\nexit 0\n' > "$SDK/build-tools/36.0.0/aapt"
printf '#!/usr/bin/env bash\nexit 0\n' > "$SDK/build-tools/36.0.0/apksigner"
chmod +x "$SDK/build-tools/36.0.0/aapt" "$SDK/build-tools/36.0.0/apksigner"
bash "$PROJECT/tooling/setup_environment.sh" > "$TMP_DIR/valid.log" 2>&1
EXPECTED_FLUTTER_SDK="$(cd "$FAKE_FLUTTER_ROOT" && pwd)"
EXPECTED_ANDROID_SDK="$(cd "$SDK" && pwd)"
grep -Fx "flutter.sdk=$EXPECTED_FLUTTER_SDK" "$PROJECT/android/local.properties" >/dev/null || fail 'Flutter SDK path was not updated.'
grep -Fx "sdk.dir=$EXPECTED_ANDROID_SDK" "$PROJECT/android/local.properties" >/dev/null || fail 'Android SDK path was not updated.'
grep -Fx 'org.gradle.java.home=/custom/jdk' "$PROJECT/android/local.properties" >/dev/null || fail 'Unrelated Android local.properties setting was not preserved.'
[[ "$(grep -c '^flutter\.sdk=' "$PROJECT/android/local.properties")" -eq 1 ]] || fail 'Duplicate flutter.sdk entries were written.'
[[ "$(grep -c '^sdk\.dir=' "$PROJECT/android/local.properties")" -eq 1 ]] || fail 'Duplicate sdk.dir entries were written.'
printf '%s\n' 'PASS: valid pinned toolchain configures paths and preserves unrelated properties.'

# Missing platform must fail before changing local.properties.
cp -a "$SDK" "$TMP_DIR/sdk-missing-platform"
rm -rf "$TMP_DIR/sdk-missing-platform/platforms/android-36"
props_before="$(sha256sum "$PROJECT/android/local.properties" | cut -d' ' -f1)"
if ANDROID_HOME="$TMP_DIR/sdk-missing-platform" bash "$PROJECT/tooling/setup_environment.sh" > "$TMP_DIR/missing-platform.log" 2>&1; then
  fail 'SDK without android-36 unexpectedly passed setup.'
fi
grep -F 'platform android-36 is required' "$TMP_DIR/missing-platform.log" >/dev/null || fail 'Missing-platform failure was not actionable.'
props_after="$(sha256sum "$PROJECT/android/local.properties" | cut -d' ' -f1)"
[[ "$props_before" == "$props_after" ]] || fail 'Failed SDK validation modified local.properties.'
printf '%s\n' 'PASS: missing compile platform fails closed without modifying local properties.'

# Missing actual aapt/apksigner executables must also fail early.
cp -a "$SDK" "$TMP_DIR/sdk-missing-tools"
rm -f "$TMP_DIR/sdk-missing-tools/build-tools/36.0.0/aapt" "$TMP_DIR/sdk-missing-tools/build-tools/36.0.0/apksigner"
if ANDROID_HOME="$TMP_DIR/sdk-missing-tools" bash "$PROJECT/tooling/setup_environment.sh" > "$TMP_DIR/missing-tools.log" 2>&1; then
  fail 'SDK without aapt/apksigner unexpectedly passed setup.'
fi
grep -F 'must include executable aapt and apksigner' "$TMP_DIR/missing-tools.log" >/dev/null || fail 'Missing-tools failure was not actionable.'
printf '%s\n' 'PASS: missing build-tools executables fail closed.'

# Wrong Java major must fail before other setup work.
if DASKO_TEST_JAVA_VERSION=21.0.12 bash "$PROJECT/tooling/setup_environment.sh" > "$TMP_DIR/java21.log" 2>&1; then
  fail 'Java 21 unexpectedly passed the Java 17 pin.'
fi
grep -F 'Expected Java 17' "$TMP_DIR/java21.log" >/dev/null || fail 'Java mismatch failure was not actionable.'
printf '%s\n' 'PASS: non-pinned Java major is rejected.'
