#!/usr/bin/env bash
set -euo pipefail
PUBSPEC=pubspec.yaml
PREFIX=dasko-version-code-
LINE="$(grep -E '^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$' "$PUBSPEC" || true)"
[[ -n "$LINE" ]] || { echo "::error::Invalid pubspec version"; exit 1; }
BASE_VERSION="$(sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)[[:space:]]*$/\1/' <<< "$LINE")"
BASE_CODE="$(sed -E 's/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)[[:space:]]*$/\1/' <<< "$LINE")"
IFS=. read -r MAJOR MINOR PATCH <<< "$BASE_VERSION"
git fetch --force origin "+refs/tags/$PREFIX*:refs/tags/$PREFIX*" >/dev/null 2>&1 || true
for attempt in $(seq 1 10); do
  MAX=0
  while read -r tag; do
    code="${tag#refs/tags/$PREFIX}"
    [[ "$code" =~ ^[0-9]+$ ]] && (( code > MAX )) && MAX=$code
  done < <(git ls-remote --tags origin "refs/tags/$PREFIX*" | awk '{print $2}' | sed 's/\^{}$//' | sort -u)
  (( BASE_CODE > MAX )) && MAX=$BASE_CODE
  NEXT=$((MAX+1))
  TAG="$PREFIX$NEXT"
  git tag "$TAG" "$GITHUB_SHA"
  if git push origin "refs/tags/$TAG"; then
    CODE=$NEXT
    echo "Reserved versionCode=$CODE via $TAG"
    break
  fi
  git tag -d "$TAG" >/dev/null 2>&1 || true
  git fetch --force origin "+refs/tags/$PREFIX*:refs/tags/$PREFIX*" >/dev/null 2>&1 || true
  (( attempt < 10 )) || { echo "::error::Unable to reserve unique versionCode"; exit 1; }
  sleep "$attempt"
done
[[ -n "${CODE:-}" ]] || { echo "::error::Version reservation missing"; exit 1; }
DELTA=$((CODE-BASE_CODE))
(( DELTA > 0 )) || { echo "::error::Reserved code must exceed pubspec baseline"; exit 1; }
NEW_PATCH=$((PATCH+DELTA))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH+$CODE"
python3 - "$PUBSPEC" "$NEW_VERSION" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s, n = re.subn(r"(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$", f"version: {sys.argv[2]}", p.read_text(), count=1)
if n != 1: raise SystemExit("Expected exactly one version line in pubspec.yaml")
p.write_text(s)
print(f"Allocated Flutter version {sys.argv[2]}")
PY
echo "DASKO_VERSION_CODE=$CODE" >> "$GITHUB_ENV"
