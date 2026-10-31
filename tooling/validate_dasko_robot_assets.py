#!/usr/bin/env python3
"""Validate the bundled Dasko GLB and its narrowly scoped Android transport."""

from __future__ import annotations

import json
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT / "assets/models/dasko_robot.glb"
POSTER_PATH = ROOT / "assets/images/dasko_robot_poster.png"
MANIFEST_PATH = ROOT / "android/app/src/main/AndroidManifest.xml"
NETWORK_CONFIG_PATH = ROOT / "android/app/src/main/res/xml/network_security_config.xml"
ANDROID_NS = "http://schemas.android.com/apk/res/android"
REQUIRED_ANIMATIONS = {"wave_hand", "idle_float", "thinking_loop"}
REQUIRED_NODES = {
    "Dasko_RootMotion",
    "Dasko_ModelCoordinateFrame",
    "Arm_Left_FloatingShell",
    "Arm_Left_StaticPivot",
    "Arm_Right_FloatingShell",
    "Arm_Right_WavePivot",
    "Head_PorcelainHelmet",
    "Head_TiltPivot",
    "Torso_TaperedShell",
}
ANIMATION_TARGETS = {
    "wave_hand": "Arm_Right_WavePivot",
    "idle_float": "Dasko_RootMotion",
    "thinking_loop": "Head_TiltPivot",
}
ANIMATION_REQUIRED_PATHS = {
    "wave_hand": {"rotation"},
    "idle_float": {"translation"},
    "thinking_loop": {"rotation"},
}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_glb(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        fail(f"GLB is too small: {path}")
    magic, version, declared_length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or declared_length != len(data):
        fail("GLB header/version/length is invalid")

    offset = 12
    json_document = None
    while offset < len(data):
        if offset + 8 > len(data):
            fail("GLB has a truncated chunk header")
        chunk_length, chunk_type = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk_end = offset + chunk_length
        if chunk_end > len(data):
            fail("GLB has a truncated chunk")
        if chunk_type == b"JSON":
            if json_document is not None:
                fail("GLB contains more than one JSON chunk")
            chunk = data[offset:chunk_end].decode("utf-8").rstrip("\x00 \t\r\n")
            json_document = json.loads(chunk)
        offset = chunk_end

    if offset != len(data) or json_document is None:
        fail("GLB is missing its JSON chunk or has trailing bytes")
    return json_document


def validate_model() -> None:
    if not MODEL_PATH.is_file():
        fail(f"Missing local GLB: {MODEL_PATH.relative_to(ROOT)}")
    if MODEL_PATH.stat().st_size > 5 * 1024 * 1024:
        fail("GLB exceeds the 5 MiB app-asset budget")

    document = read_glb(MODEL_PATH)
    animations = {item.get("name") for item in document.get("animations", [])}
    if animations != REQUIRED_ANIMATIONS:
        fail(f"Unexpected GLB animation names: {sorted(animations)}")

    nodes = document.get("nodes", [])
    node_names = {node.get("name", "") for node in nodes}
    missing_nodes = REQUIRED_NODES - node_names
    if missing_nodes:
        fail(f"Missing required model nodes: {sorted(missing_nodes)}")

    node_indices = {node.get("name", ""): index for index, node in enumerate(nodes)}
    root_scale = nodes[node_indices["Dasko_RootMotion"]].get(
        "scale", [1.0, 1.0, 1.0]
    )
    if (
        not isinstance(root_scale, list)
        or len(root_scale) != 3
        or any(
            not isinstance(value, (int, float)) or abs(value - 1.0) > 1e-6
            for value in root_scale
        )
    ):
        fail("Dasko_RootMotion scale must remain fixed at 1 1 1")

    def require_child(parent_name: str, child_name: str) -> None:
        parent_index = node_indices[parent_name]
        child_index = node_indices[child_name]
        if child_index not in nodes[parent_index].get("children", []):
            fail(f"Model hierarchy must place {child_name} under {parent_name}")

    require_child("Dasko_RootMotion", "Dasko_ModelCoordinateFrame")
    for child_name in (
        "Arm_Left_StaticPivot",
        "Arm_Right_WavePivot",
        "Head_TiltPivot",
        "Torso_TaperedShell",
    ):
        require_child("Dasko_ModelCoordinateFrame", child_name)
    require_child("Head_TiltPivot", "Head_PorcelainHelmet")
    if any("neck" in name.casefold() for name in node_names):
        fail("A physical neck node is not allowed in the floating-head design")

    for visible_node in (
        "Arm_Left_FloatingShell",
        "Arm_Right_FloatingShell",
        "Head_PorcelainHelmet",
        "Torso_TaperedShell",
    ):
        node = next(item for item in nodes if item.get("name") == visible_node)
        if not isinstance(node.get("mesh"), int):
            fail(f"Required visible model node has no mesh: {visible_node}")

    for animation in document.get("animations", []):
        name = animation.get("name")
        if not animation.get("channels") or not animation.get("samplers"):
            fail(f"Animation has no playable channels: {name}")
        target_paths: dict[str, set[str]] = {}
        for channel in animation["channels"]:
            target_info = channel.get("target", {})
            target = target_info.get("node")
            if not isinstance(target, int) or target < 0 or target >= len(nodes):
                fail(f"Animation targets an invalid node: {name}")
            if target_info.get("path") == "scale":
                fail(f"Animation must not change model scale: {name}")
            target_name = nodes[target].get("name", "")
            target_paths.setdefault(target_name, set()).add(target_info.get("path", ""))
        expected_target = ANIMATION_TARGETS[name]
        if expected_target not in target_paths:
            fail(f"Animation {name} does not animate {expected_target}")
        required_paths = ANIMATION_REQUIRED_PATHS[name]
        if not required_paths.issubset(target_paths[expected_target]):
            fail(
                f"Animation {name} is missing required paths on "
                f"{expected_target}: {sorted(required_paths)}"
            )

    external_uris = [
        item.get("uri")
        for section in ("buffers", "images")
        for item in document.get(section, [])
        if item.get("uri")
    ]
    if external_uris:
        fail(f"GLB must be self-contained; external URIs found: {external_uris}")

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if "    - assets/models/" not in pubspec:
        fail("pubspec.yaml does not include assets/models/")
    print("GLB valid: self-contained asset, required nodes, and mapped animation clips")


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


def validate_poster() -> None:
    if not POSTER_PATH.is_file():
        fail(f"Missing robot poster fallback: {POSTER_PATH.relative_to(ROOT)}")
    data = POSTER_PATH.read_bytes()
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n":
        fail("Robot poster is not a valid PNG")
    width, height = struct.unpack_from(">II", data, 16)
    color_type = data[25]
    if (width, height) != (512, 640) or color_type != 6:
        fail("Robot poster must be a 512x640 RGBA PNG")
    print("Robot poster valid: 512x640 RGBA fallback image")


def main() -> None:
    validate_model()
    validate_android_network_policy()
    validate_poster()


if __name__ == "__main__":
    main()
