#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

command -v flutter >/dev/null 2>&1 || fail 'Flutter is not on PATH. Install the repository-pinned Flutter SDK first.'
command -v java >/dev/null 2>&1 || fail 'Java is not on PATH. Install the JDK required by the Android Gradle build.'
command -v python3 >/dev/null 2>&1 || fail 'Python 3 is required to safely preserve existing Android local.properties entries.'

FLUTTER_VERSION_LINE="$(flutter --version | head -n 1)"
[[ "$FLUTTER_VERSION_LINE" == *"3.47.8"* ]] || fail "Expected Flutter 3.47.8, found: $FLUTTER_VERSION_LINE"
JAVA_MAJOR="$(java -version 2>&1 | sed -nE 's/.*version "([0-9]+).*/\1/p' | head -n 1)"
[ "$JAVA_MAJOR" = "17" ] || fail "Expected Java 17, found major version: ${JAVA_MAJOR:-unknown}"

FLUTTER_BIN="$(command -v flutter)"
FLUTTER_REAL_BIN="$(readlink -f "$FLUTTER_BIN")"
FLUTTER_SDK="$(cd "$(dirname "$FLUTTER_REAL_BIN")/.." && pwd)"
ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"

[ -n "$ANDROID_SDK" ] || fail 'Set ANDROID_HOME or ANDROID_SDK_ROOT to the installed Android SDK directory.'
[ -d "$ANDROID_SDK" ] || fail "Android SDK directory does not exist: $ANDROID_SDK"
[ -d "$ANDROID_SDK/platforms" ] || fail "Android SDK platforms directory is missing: $ANDROID_SDK/platforms"
[ -d "$ANDROID_SDK/build-tools" ] || fail "Android SDK build-tools directory is missing: $ANDROID_SDK/build-tools"
[ -s pubspec.lock ] || fail 'pubspec.lock is missing; restore the tracked lockfile before setup.'

python3 - "$ROOT_DIR/android/local.properties" "$FLUTTER_SDK" "$ANDROID_SDK" <<'PY'
import os
import pathlib
import sys
import tempfile

path = pathlib.Path(sys.argv[1])
flutter_sdk, android_sdk = sys.argv[2:]


def escape(value: str) -> str:
    return (value.replace("\\", "\\\\")
                 .replace(" ", "\\ ")
                 .replace(":", "\\:")
                 .replace("=", "\\="))

updates = {"flutter.sdk": escape(flutter_sdk), "sdk.dir": escape(android_sdk)}
lines = path.read_text().splitlines() if path.exists() else []
seen = set()
result = []
for line in lines:
    stripped = line.lstrip()
    if not stripped or stripped.startswith(("#", "!")) or "=" not in line:
        result.append(line)
        continue
    key = line.split("=", 1)[0].strip()
    if key in updates:
        if key not in seen:
            result.append(f"{key}={updates[key]}")
            seen.add(key)
    else:
        result.append(line)
for key, value in updates.items():
    if key not in seen:
        result.append(f"{key}={value}")

path.parent.mkdir(parents=True, exist_ok=True)
fd, temp_name = tempfile.mkstemp(prefix="local.properties.", dir=path.parent)
try:
    with os.fdopen(fd, "w") as temp_file:
        temp_file.write("\n".join(result) + "\n")
    os.replace(temp_name, path)
finally:
    if os.path.exists(temp_name):
        os.unlink(temp_name)
PY

printf '%s\n' 'Android local.properties updated with Flutter and Android SDK paths.'
flutter pub get --enforce-lockfile
printf '%s\n' 'Environment setup completed.'
