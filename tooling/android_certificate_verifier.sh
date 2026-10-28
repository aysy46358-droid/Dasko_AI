#!/usr/bin/env bash
# Strictly extract and verify the sole SHA-256 signing-certificate digest
# emitted by apksigner verify --verbose --print-certs.
set -euo pipefail

extract_certificate_sha256() {
  local signature_output="${1-}"
  local line digest=""
  local count=0

  while IFS= read -r line; do
    [[ "$line" == *"certificate SHA-256 digest:"* ]] || continue
    ((count += 1))

    # Accept known apksigner prefixes, but require exactly 64 hex digits
    # followed only by whitespace. Never accept a truncated or suffixed hash.
    if [[ "$line" =~ certificate\ SHA-256\ digest:[[:space:]]*([[:xdigit:]]{64})[[:space:]]*$ ]]; then
      digest="${BASH_REMATCH[1],,}"
    else
      echo "::error::Malformed certificate SHA-256 digest line." >&2
      return 1
    fi
  done <<< "$signature_output"

  if (( count != 1 )); then
    echo "::error::Expected exactly one certificate SHA-256 digest line; found $count." >&2
    return 1
  fi

  printf '%s\n' "$digest"
}

verify_certificate_sha256() {
  local signature_output="${1-}"
  local expected="${2-}"
  local actual

  if [[ ! "$expected" =~ ^[[:xdigit:]]{64}$ ]]; then
    echo "::error::Expected signing certificate fingerprint must be exactly 64 hexadecimal characters." >&2
    return 1
  fi

  expected="${expected,,}"
  if ! actual="$(extract_certificate_sha256 "$signature_output")"; then
    return 1
  fi

  if [[ "$actual" != "$expected" ]]; then
    echo "::error::Signing certificate fingerprint mismatch." >&2
    return 1
  fi

  printf 'Signing certificate SHA-256 verified: %s\n' "$actual"
}
