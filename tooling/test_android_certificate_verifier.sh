#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/android_certificate_verifier.sh"

EXPECTED="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
OTHER="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

pass=0
fail() { echo "FAIL: $1" >&2; exit 1; }
assert_success() {
  local name="$1" output="$2" expected="$3"
  if verify_certificate_sha256 "$output" "$expected" >/dev/null 2>&1; then
    printf 'PASS: %s\n' "$name"
    ((pass += 1))
  else
    fail "$name (expected success)"
  fi
}
assert_failure() {
  local name="$1" output="$2" expected="$3"
  if verify_certificate_sha256 "$output" "$expected" >/dev/null 2>&1; then
    fail "$name (unexpected success)"
  else
    printf 'PASS: %s\n' "$name"
    ((pass += 1))
  fi
}

assert_success "V2 apksigner format" "V2 Signer: certificate SHA-256 digest: $EXPECTED" "$EXPECTED"
assert_success "legacy signer format and uppercase hex" "Signer #1 certificate SHA-256 digest: ${EXPECTED^^}" "$EXPECTED"
assert_failure "missing digest" "Verified using v2 scheme (APK Signature Scheme v2): true" "$EXPECTED"
assert_failure "incomplete digest" "Signer #1 certificate SHA-256 digest: ${EXPECTED:0:63}" "$EXPECTED"
assert_failure "non-hex digest" "Signer #1 certificate SHA-256 digest: ${EXPECTED:0:63}Z" "$EXPECTED"
assert_failure "valid digest mismatch" "Signer #1 certificate SHA-256 digest: $OTHER" "$EXPECTED"
assert_failure "multiple digest lines are rejected" $'Signer #1 certificate SHA-256 digest: '$EXPECTED$'\nV2 Signer: certificate SHA-256 digest: '$EXPECTED "$EXPECTED"

printf 'All %d certificate-verifier regression tests passed.\n' "$pass"
