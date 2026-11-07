#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOCATOR="$ROOT_DIR/tooling/allocate_android_version.sh"
TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ "${DASKO_TEST_KEEP_TEMP:-0}" == '1' ]]; then
    printf 'Keeping temporary test fixture for diagnosis: %s\n' "$TMP_DIR" >&2
  else
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

init_fixture() {
  local name="$1"
  local bare="$TMP_DIR/$name-origin.git"
  local seed="$TMP_DIR/$name-seed"
  mkdir -p "$seed/tooling"
  git init --bare --initial-branch=experimental-work "$bare" >/dev/null
  git init --initial-branch=experimental-work "$seed" >/dev/null
  git -C "$seed" config user.name 'Version allocator test'
  git -C "$seed" config user.email 'version-test@example.invalid'
  cp "$ALLOCATOR" "$seed/tooling/allocate_android_version.sh"
  printf 'name: dasko_ai\nversion: 1.0.0+2\n' > "$seed/pubspec.yaml"
  git -C "$seed" add tooling/allocate_android_version.sh pubspec.yaml
  git -C "$seed" commit -m 'test fixture' >/dev/null
  git -C "$seed" remote add origin "$bare"
  git -C "$seed" push -u origin experimental-work >/dev/null 2>&1
  printf '%s\n' "$bare" "$(git -C "$seed" rev-parse HEAD)"
}

run_allocator() {
  local repo="$1"
  local prefix="$2"
  local commit_sha
  commit_sha="$(git -C "$repo" rev-parse HEAD)"
  (
    cd "$repo"
    GITHUB_SHA="$commit_sha" \
      GITHUB_ENV="$TMP_DIR/$prefix.env" \
      GITHUB_OUTPUT="$TMP_DIR/$prefix.out" \
      bash tooling/allocate_android_version.sh
  ) > "$TMP_DIR/$prefix.log" 2>&1
}

read_output() {
  local file="$1"
  local key="$2"
  sed -n "s/^${key}=//p" "$file"
}

# Sequential allocation: each build gets a unique monotonically increasing code.
mapfile -t sequential_fixture < <(init_fixture sequential)
SEQUENTIAL_ORIGIN="${sequential_fixture[0]}"
SEQUENTIAL_SHA="${sequential_fixture[1]}"
for index in 1 2; do
  clone="$TMP_DIR/sequential-clone-$index"
  git clone --quiet --branch experimental-work "$SEQUENTIAL_ORIGIN" "$clone"
  git -C "$clone" config user.name 'Version allocator test'
  git -C "$clone" config user.email 'version-test@example.invalid'
  run_allocator "$clone" "sequential-$index"
  actual_version="$(sed -nE 's/^version: (.*)$/\1/p' "$clone/pubspec.yaml")"
  expected_version="1.0.$index+$((index + 2))"
  [[ "$actual_version" == "$expected_version" ]] || fail "sequential allocation $index: expected $expected_version, got $actual_version"
  actual_code="$(read_output "$TMP_DIR/sequential-$index.out" version_code)"
  [[ "$actual_code" == "$((index + 2))" ]] || fail "sequential output $index: unexpected version_code $actual_code"
done
[[ "$(git --git-dir="$SEQUENTIAL_ORIGIN" tag --list 'dasko-version-code-*' | sort | tr '\n' ' ')" == 'dasko-version-code-3 dasko-version-code-4 ' ]] || fail 'sequential tags are missing or unexpected'
printf '%s\n' 'PASS: sequential reservations produce versionCode 3 then 4.'

# Concurrent allocation: two isolated clones contend for the same next tag.
mapfile -t concurrent_fixture < <(init_fixture concurrent)
CONCURRENT_ORIGIN="${concurrent_fixture[0]}"
CONCURRENT_SHA="${concurrent_fixture[1]}"
REAL_GIT_BIN="$(command -v git)"
GIT_WRAPPER_DIR="$TMP_DIR/git-wrapper"
BARRIER_DIR="$TMP_DIR/ls-remote-barrier"
mkdir -p "$GIT_WRAPPER_DIR" "$BARRIER_DIR"
cat > "$GIT_WRAPPER_DIR/git" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == 'ls-remote' && "$*" == *'refs/tags/dasko-version-code-'* ]]; then
  output="$DASKO_TEST_BARRIER_DIR/${BASHPID}.out"
  "$DASKO_TEST_REAL_GIT" "$@" > "$output"
  : > "${output%.out}.ready"
  for attempt in $(seq 1 200); do
    ready_count="$(find "$DASKO_TEST_BARRIER_DIR" -maxdepth 1 -name '*.ready' | wc -l)"
    if (( ready_count >= 2 )); then
      cat "$output"
      exit 0
    fi
    sleep 0.05
  done
  printf 'Timed out waiting for both allocator processes to read remote tags.\n' >&2
  exit 98
fi
exec "$DASKO_TEST_REAL_GIT" "$@"
SH
chmod +x "$GIT_WRAPPER_DIR/git"
for index in 1 2; do
  clone="$TMP_DIR/concurrent-clone-$index"
  git clone --quiet --branch experimental-work "$CONCURRENT_ORIGIN" "$clone"
  git -C "$clone" config user.name 'Version allocator test'
  git -C "$clone" config user.email 'version-test@example.invalid'
  (
    cd "$clone"
    PATH="$GIT_WRAPPER_DIR:$PATH" \
      DASKO_TEST_REAL_GIT="$REAL_GIT_BIN" \
      DASKO_TEST_BARRIER_DIR="$BARRIER_DIR" \
      GITHUB_SHA="$CONCURRENT_SHA" \
      GITHUB_ENV="$TMP_DIR/concurrent-$index.env" \
      GITHUB_OUTPUT="$TMP_DIR/concurrent-$index.out" \
      bash tooling/allocate_android_version.sh
  ) > "$TMP_DIR/concurrent-$index.log" 2>&1 &
done
wait
code_one="$(read_output "$TMP_DIR/concurrent-1.out" version_code)"
code_two="$(read_output "$TMP_DIR/concurrent-2.out" version_code)"
[[ "$code_one" =~ ^[0-9]+$ && "$code_two" =~ ^[0-9]+$ ]] || fail 'concurrent allocation did not emit numeric codes'
[[ "$code_one" != "$code_two" ]] || fail "concurrent reservations duplicated versionCode $code_one"
grep -qF 'was already created by another run; retrying.' "$TMP_DIR/concurrent-1.log" "$TMP_DIR/concurrent-2.log" || fail 'the test did not exercise the same-tag collision and retry path'
mapfile -t concurrent_tags < <(git --git-dir="$CONCURRENT_ORIGIN" tag --list 'dasko-version-code-*' | sort -V)
[[ "${#concurrent_tags[@]}" -eq 2 ]] || fail "expected 2 concurrent reservation tags, found ${#concurrent_tags[@]}"
[[ "${concurrent_tags[0]}" == 'dasko-version-code-3' && "${concurrent_tags[1]}" == 'dasko-version-code-4' ]] || fail 'concurrent reservations created unexpected tags'
printf 'PASS: concurrent reservations are unique (codes %s and %s).\n' "$code_one" "$code_two"

# Malformed baseline: reject before pushing a reservation tag.
invalid="$TMP_DIR/invalid-clone"
git clone --quiet --branch experimental-work "$SEQUENTIAL_ORIGIN" "$invalid"
git -C "$invalid" config user.name 'Version allocator test'
git -C "$invalid" config user.email 'version-test@example.invalid'
printf 'name: dasko_ai\nversion: malformed\n' > "$invalid/pubspec.yaml"
set +e
(
  cd "$invalid"
  GITHUB_SHA="$SEQUENTIAL_SHA" GITHUB_ENV="$TMP_DIR/invalid.env" GITHUB_OUTPUT="$TMP_DIR/invalid.out" \
    bash tooling/allocate_android_version.sh
) > "$TMP_DIR/invalid.log" 2>&1
invalid_status=$?
set -e
[[ "$invalid_status" -ne 0 ]] || fail 'malformed version baseline unexpectedly succeeded'
[[ "$(git --git-dir="$SEQUENTIAL_ORIGIN" tag --list 'dasko-version-code-*' | wc -l)" -eq 2 ]] || fail 'malformed baseline created a reservation tag'
printf '%s\n' 'PASS: malformed baseline fails without reserving a tag.'
