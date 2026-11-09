#!/usr/bin/env python3
"""Validate the bundled robot artwork and its narrowly scoped Android transport."""

from __future__ import annotations

import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
POSTER_PATH = ROOT / "assets/images/robot_poster.png"
MANIFEST_PATH = ROOT / "android/app/src/main/AndroidManifest.xml"
NETWORK_CONFIG_PATH = ROOT / "android/app/src/main/res/xml/network_security_config.xml"
ANDROID_NS = "http://schemas.android.com/apk/res/android"

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
JPEG_SIGNATURE = b"\xff\xd8\xff"
MIN_POSTER_EDGE = 512
MAX_POSTER_BYTES = 4 * 1024 * 1024


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def png_size(data: bytes) -> tuple[int, int]:
    return struct.unpack_from(">II", data, 16)


def jpeg_size(data: bytes) -> tuple[int, int]:
    index = 2
    while index + 9 < len(data):
        if data[index] != 0xFF:
            index += 1
            continue
        marker = data[index + 1]
        if marker in (0xC0, 0xC1, 0xC2, 0xC3):
            height, width = struct.unpack_from(">HH", data, index + 5)
            return width, height
        if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            index += 2
            continue
        segment_length = struct.unpack_from(">H", data, index + 2)[0]
        index += 2 + segment_length
    fail("JPEG poster has no SOF frame header")


def validate_poster() -> None:
    if not POSTER_PATH.is_file():
        fail(f"Missing robot poster: {POSTER_PATH.relative_to(ROOT)}")

    data = POSTER_PATH.read_bytes()
    if not data:
        fail("Robot poster is empty")
    if len(data) > MAX_POSTER_BYTES:
        fail("Robot poster exceeds the 4 MiB app-asset budget")

    # The asset is a raster image; PNG and JPEG are both accepted because the
    # Flutter engine decodes by content, not by file extension.
    if data.startswith(PNG_SIGNATURE):
        width, height = png_size(data)
    elif data.startswith(JPEG_SIGNATURE):
        width, height = jpeg_size(data)
    else:
        fail("Robot poster is neither a PNG nor a JPEG image")

    if min(width, height) < MIN_POSTER_EDGE:
        fail(f"Robot poster is too small: {width}x{height} (min {MIN_POSTER_EDGE}px)")

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if "    - assets/images/" not in pubspec:
        fail("pubspec.yaml does not include assets/images/")
    if "assets/models/" in pubspec:
        fail("pubspec.yaml still declares the retired assets/models/ folder")

    print(f"Robot poster valid: {width}x{height} raster asset within budget")


def validate_android_network_policy() -> None:
    manifest = ET.parse(MANIFEST_PATH).getroot()
    application = manifest.find("application")
    if application is None:
        fail("AndroidManifest.xml has no application element")
    config_reference = application.get(f"{{{ANDROID_NS}}}networkSecurityConfig")
    if config_reference != "@xml/network_security_config":
        fail("AndroidManifest.xml does not reference the expected network config")

    root = ET.parse(NETWORK_CONFIG_PATH).getroot()
    base = root.find("base-config")
    if base is None or base.get("cleartextTrafficPermitted") != "false":
        fail("Cleartext traffic must be denied by default")

    domain_configs = root.findall("domain-config")
    if len(domain_configs) != 1:
        fail("Only one cleartext allowlist entry is permitted")
    domain_config = domain_configs[0]
    if domain_config.get("cleartextTrafficPermitted") != "true":
        fail("The loopback asset proxy must be explicitly allowlisted")
    domains = domain_config.findall("domain")
    if len(domains) != 1 or (domains[0].text or "").strip() != "127.0.0.1":
        fail("The only permitted cleartext host is 127.0.0.1")
    if domains[0].get("includeSubdomains", "false").lower() != "false":
        fail("Subdomains must not be included in the loopback exception")

    print("Android network policy valid: cleartext denied except loopback 127.0.0.1")


def main() -> None:
    validate_poster()
    validate_android_network_policy()


if __name__ == "__main__":
    main()
