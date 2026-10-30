"""Generate Dasko's free, editable GLB demo and a transparent poster.

Run from the repository root with:
  blender -b --python tooling/create_dasko_robot_model.py

Coordinates use meters; the model is built from procedural meshes/materials and
contains no neck mesh. The visible geometry is intentionally separate from the
animation pivots so later pose work does not alter the static body design.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
MODEL_PATH = ROOT / "assets" / "models" / "dasko_robot.glb"
POSTER_PATH = ROOT / "assets" / "images" / "dasko_robot_poster.png"


# ---------------------------------------------------------------------------
# Scene/material/mesh helpers
# ---------------------------------------------------------------------------
def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.actions, bpy.data.materials, bpy.data.meshes,
                       bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for item in list(datablocks):
            datablocks.remove(item)


def make_principled(name: str, color: tuple[float, float, float, float], *,
                    metallic: float = 0.0, roughness: float = 0.18,
                    emission: tuple[float, float, float, float] | None = None,
                    emission_strength: float = 0.0,
                    clearcoat: float = 0.0,
                    vertex_color: bool = False) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()
    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    coat = shader.inputs.get("Coat Weight")
    if coat is not None:
        coat.default_value = clearcoat
    coat_roughness = shader.inputs.get("Coat Roughness")
    if coat_roughness is not None:
        coat_roughness.default_value = 0.045
    if vertex_color:
        color_node = nodes.new("ShaderNodeVertexColor")
        color_node.layer_name = "Col"
        links.new(color_node.outputs["Color"], shader.inputs["Base Color"])
    if emission is not None:
        emission_input = shader.inputs.get("Emission Color")
        if emission_input is None:
            emission_input = shader.inputs.get("Emission")
        if emission_input is not None:
            emission_input.default_value = emission
        strength_input = shader.inputs.get("Emission Strength")
        if strength_input is not None:
            strength_input.default_value = emission_strength
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    return material


def lerp_color(a: tuple[float, float, float],
               b: tuple[float, float, float], t: float) -> tuple[float, float, float]:
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def add_vertical_gradient(obj: bpy.types.Object) -> None:
    mesh = obj.data
    if not isinstance(mesh, bpy.types.Mesh):
        return
    if "Col" in mesh.color_attributes:
        mesh.color_attributes.remove(mesh.color_attributes["Col"])
    colors = mesh.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    y_values = [vertex.co.y for vertex in mesh.vertices]
    y_min, y_max = min(y_values), max(y_values)
    span = max(y_max - y_min, 1e-6)
    bottom = (0.12, 0.47, 0.91)
    middle = (0.30, 0.72, 0.89)
    top = (0.70, 0.46, 0.94)
    for index, vertex in enumerate(mesh.vertices):
        t = (vertex.co.y - y_min) / span
        if t <= 0.53:
            rgb = lerp_color(bottom, middle, t / 0.53)
        else:
            rgb = lerp_color(middle, top, (t - 0.53) / 0.47)
        colors.data[index].color = (*rgb, 1.0)


def set_material(obj: bpy.types.Object, material: bpy.types.Material,
                 *, gradient: bool = False) -> bpy.types.Object:
    obj.data.materials.clear()
    obj.data.materials.append(material)
    if gradient:
        add_vertical_gradient(obj)
    if isinstance(obj.data, bpy.types.Mesh):
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    return obj


def make_empty(name: str, location: tuple[float, float, float],
               parent: bpy.types.Object | None = None) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = 0.035
    obj.location = location
    if parent is not None:
        obj.parent = parent
    obj["dasko_animation_pivot"] = True
    return obj


def make_box(name: str, dimensions: tuple[float, float, float],
             location: tuple[float, float, float], material: bpy.types.Material,
             *, bevel: float, parent: bpy.types.Object | None = None,
             gradient: bool = False,
             rotation: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.location = location
    obj.rotation_euler = rotation
    if parent is not None:
        obj.parent = parent
    if bevel > 0:
        modifier = obj.modifiers.new("Soft machined edges", "BEVEL")
        modifier.width = min(bevel, min(dimensions) * 0.48)
        modifier.segments = 8
        modifier.profile = 0.5
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    normals = obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    normals.keep_sharp = True
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=normals.name)
    set_material(obj, material, gradient=gradient)
    obj["dasko_visible_part"] = True
    return obj


def make_cylinder(name: str, radius: float, depth: float,
                  location: tuple[float, float, float], material: bpy.types.Material,
                  *, parent: bpy.types.Object | None = None,
                  rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
                  vertices: int = 64,
                  gradient: bool = False) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius,
                                       depth=depth, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.location = location
    obj.rotation_euler = rotation
    if parent is not None:
        obj.parent = parent
    set_material(obj, material, gradient=gradient)
    obj["dasko_visible_part"] = True
    return obj


def make_uv_sphere(name: str, scale: tuple[float, float, float],
                   location: tuple[float, float, float], material: bpy.types.Material,
                   *, parent: bpy.types.Object | None = None,
                   gradient: bool = False) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24,
                                        radius=1.0, location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.location = location
    if parent is not None:
        obj.parent = parent
    set_material(obj, material, gradient=gradient)
    obj["dasko_visible_part"] = True
    return obj


def make_torus(name: str, major_radius: float, minor_radius: float,
               location: tuple[float, float, float], material: bpy.types.Material,
               *, parent: bpy.types.Object | None = None,
               rotation: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(major_segments=64, minor_segments=12,
                                    major_radius=major_radius,
                                    minor_radius=minor_radius,
                                    location=(0.0, 0.0, 0.0))
    obj = bpy.context.object
    obj.name = name
    obj.location = location
    obj.rotation_euler = rotation
    if parent is not None:
        obj.parent = parent
    set_material(obj, material)
    obj["dasko_visible_part"] = True
    return obj


def make_curve(name: str, points: list[tuple[float, float, float]],
               bevel_depth: float, material: bpy.types.Material,
               *, parent: bpy.types.Object | None = None,
               cyclic: bool = False) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 16
    curve.bevel_depth = bevel_depth
    curve.bevel_resolution = 4
    spline = curve.splines.new("POLY")
    spline.points.add(len(points) - 1)
    for point, co in zip(spline.points, points):
        point.co = (*co, 1.0)
    spline.use_cyclic_u = cyclic
    obj = bpy.data.objects.new(name, curve)
    bpy.context.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    obj.data.materials.append(material)
    obj["dasko_visible_part"] = True
    return obj


def make_body_shell(material: bpy.types.Material,
                    parent: bpy.types.Object | None = None) -> bpy.types.Object:
    # Rounded, tapered torso: broad shoulders, narrowing toward the lower thruster.
    profile = [
        (0.012, 0.048, 0.052),
        (0.026, 0.078, 0.078),
        (0.055, 0.101, 0.100),
        (0.095, 0.124, 0.122),
        (0.145, 0.151, 0.145),
        (0.205, 0.181, 0.165),
        (0.265, 0.207, 0.177),
        (0.315, 0.222, 0.184),
        (0.352, 0.218, 0.183),
        (0.378, 0.198, 0.169),
        (0.392, 0.167, 0.145),
    ]
    segments = 96
    vertices: list[tuple[float, float, float]] = []
    faces: list[tuple[int, ...]] = []
    for y, radius_x, radius_z in profile:
        for j in range(segments):
            angle = 2.0 * math.pi * j / segments
            vertices.append((radius_x * math.cos(angle), y,
                             radius_z * math.sin(angle)))
    for ring in range(len(profile) - 1):
        for j in range(segments):
            a = ring * segments + j
            b = ring * segments + (j + 1) % segments
            c = (ring + 1) * segments + (j + 1) % segments
            d = (ring + 1) * segments + j
            faces.append((a, b, c, d))
    faces.append(tuple(range(segments - 1, -1, -1)))
    top_start = (len(profile) - 1) * segments
    faces.append(tuple(top_start + j for j in range(segments)))
    mesh = bpy.data.meshes.new("TorsoShellMesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new("Torso_TaperedShell", mesh)
    bpy.context.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    set_material(obj, material, gradient=True)
    obj["dasko_visible_part"] = True
    return obj


def add_action_strip(obj: bpy.types.Object, name: str,
                     keyframes: list[tuple[int, tuple[float, float, float],
                                           tuple[float, float, float]]]) -> None:
    """Create one independently named glTF animation on an empty pivot."""
    obj.animation_data_create()
    action = bpy.data.actions.new(name)
    obj.animation_data.action = action
    for frame, location, rotation in keyframes:
        obj.location = location
        obj.rotation_euler = rotation
        obj.keyframe_insert(data_path="location", frame=frame, group=name)
        obj.keyframe_insert(data_path="rotation_euler", frame=frame, group=name)
    for fcurve in action.fcurves:
        for point in fcurve.keyframe_points:
            point.interpolation = "BEZIER"
    obj.animation_data.action = None
    track = obj.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 0, action)
    strip.blend_type = "REPLACE"
    strip.extrapolation = "NOTHING"


def add_camera_and_lights() -> None:
    scene = bpy.context.scene
    bpy.ops.object.camera_add(location=(0.0, -3.2, 0.52))
    camera = bpy.context.object
    camera.name = "PosterCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.23
    direction = Vector((0.0, 0.0, 0.52)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.camera = camera

    def area(name: str, location: tuple[float, float, float],
             color: tuple[float, float, float], energy: float,
             size: float) -> None:
        bpy.ops.object.light_add(type="AREA", location=location)
        light = bpy.context.object
        light.name = name
        light.data.color = color
        light.data.energy = energy
        light.data.shape = "DISK"
        light.data.size = size
        direction = Vector((0.0, 0.0, 0.52)) - light.location
        light.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    area("CoolFrontFill", (-1.3, -2.0, 1.5), (0.34, 0.75, 1.0), 55.0, 2.0)
    area("VioletRim", (1.2, 1.2, 1.0), (0.62, 0.30, 1.0), 70.0, 1.6)
    area("SoftFront", (1.4, -2.2, 0.3), (0.75, 0.88, 1.0), 38.0, 2.2)


# ---------------------------------------------------------------------------
# Build the robot
# ---------------------------------------------------------------------------
clear_scene()
scene = bpy.context.scene
scene.render.fps = 24
scene.frame_start = 0
scene.frame_end = 52
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 512
scene.render.resolution_y = 640
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = True
scene.world.color = (0.012, 0.02, 0.045)
scene.render.image_settings.color_mode = "RGBA"

shell = make_principled("HolographicPorcelain", (0.36, 0.68, 0.88, 1.0),
                        metallic=0.12, roughness=0.12, clearcoat=0.72,
                        vertex_color=True)
trim = make_principled("IridescentTrim", (0.58, 0.38, 0.90, 1.0),
                       metallic=0.22, roughness=0.16, clearcoat=0.55)
dark = make_principled("ObsidianDisplay", (0.008, 0.012, 0.028, 1.0),
                       metallic=0.08, roughness=0.13, clearcoat=0.5)
metal = make_principled("GraphiteMechanism", (0.055, 0.075, 0.12, 1.0),
                        metallic=0.72, roughness=0.34)
cyan_glow = make_principled("LaserCyanEmission", (0.0, 0.75, 0.92, 1.0),
                            emission=(0.0, 0.80, 1.0, 1.0),
                            emission_strength=3.5, roughness=0.2)
blue_glow = make_principled("BlueCoreEmission", (0.10, 0.52, 1.0, 1.0),
                            emission=(0.12, 0.45, 1.0, 1.0),
                            emission_strength=1.5, roughness=0.2)

root = make_empty("Dasko_RootMotion", (0.0, 0.0, 0.0))
# Keep the motion root neutral; idle_float animates its rotation channels.
# Geometry uses local Y-up/+Z-front, so a fixed child frame converts Blender's
# Z-up coordinates without interfering with the root animation.
coordinate_frame = make_empty("Dasko_ModelCoordinateFrame", (0.0, 0.0, 0.0), root)
coordinate_frame.rotation_euler.x = math.pi / 2
head = make_empty("Head_TiltPivot", (0.0, 0.665, 0.0), coordinate_frame)
left_arm = make_empty("Arm_Left_StaticPivot", (-0.29, 0.392, 0.0), coordinate_frame)
right_arm = make_empty("Arm_Right_WavePivot", (0.29, 0.392, 0.0), coordinate_frame)
left_arm.rotation_euler.z = -math.radians(8.0)
right_arm.rotation_euler.z = math.radians(8.0)

# Head shell and inset display.
make_box("Head_PorcelainHelmet", (0.62, 0.47, 0.55), (0.0, 0.0, 0.0),
         shell, bevel=0.125, parent=head, gradient=True)
make_box("Face_Display_Rim", (0.535, 0.375, 0.025), (0.0, 0.0, 0.272),
         trim, bevel=0.105, parent=head)
make_box("Face_BlackGlass", (0.505, 0.345, 0.012), (0.0, 0.0, 0.289),
         dark, bevel=0.095, parent=head)

# Friendly cyan arc-eyes, positioned in the face plane.
for side, x_center in (("Left", -0.115), ("Right", 0.115)):
    eye_points = []
    for i in range(25):
        t = -1.0 + 2.0 * i / 24.0
        x = x_center + 0.045 * t
        y = 0.005 + 0.017 * (1.0 - t * t)
        eye_points.append((x, y, 0.298))
    make_curve(f"Eye_{side}_CyanArc", eye_points, 0.0068, cyan_glow, parent=head)
    # A restrained outer glow trace gives the glass a holographic read.
    glow_points = [(x, y - 0.006, z - 0.001) for x, y, z in eye_points]
    make_curve(f"Eye_{side}_SoftGlow", glow_points, 0.0024, blue_glow, parent=head)

# Symmetric ear cups and the pair of short antennae.
for side, sign in (("Left", -1.0), ("Right", 1.0)):
    make_cylinder(f"EarCup_{side}_Shell", 0.076, 0.14,
                  (sign * 0.315, 0.0, 0.202), trim,
                  parent=head, gradient=True)
    make_cylinder(f"EarCup_{side}_Inset", 0.053, 0.145,
                  (sign * 0.315, 0.0, 0.208), dark,
                  parent=head)
    make_torus(f"EarCup_{side}_LightRing", 0.061, 0.004,
               (sign * 0.315, 0.0, 0.283), cyan_glow,
               parent=head)
    make_cylinder(f"Antenna_{side}_Stem", 0.009, 0.098,
                  (sign * 0.13, 0.278, 0.0), trim, parent=head,
                  rotation=(math.pi / 2, 0.0, 0.0))
    make_uv_sphere(f"Antenna_{side}_OuterLens", (0.029, 0.029, 0.029),
                   (sign * 0.13, 0.337, 0.0), trim, parent=head)
    make_uv_sphere(f"Antenna_{side}_Orb", (0.014, 0.014, 0.014),
                   (sign * 0.13, 0.337, 0.025), blue_glow, parent=head)

# Tapered torso shell and independent chest display.
make_body_shell(shell, parent=coordinate_frame)
make_box("Chest_Display_Rim", (0.238, 0.145, 0.028), (0.0, 0.252, 0.181),
         trim, bevel=0.038, parent=coordinate_frame)
make_box("Chest_BlackGlass", (0.211, 0.119, 0.012), (0.0, 0.252, 0.201),
         dark, bevel=0.029, parent=coordinate_frame)
infinity_points = []
for i in range(161):
    t = 2.0 * math.pi * i / 160.0
    infinity_points.append((0.078 * math.cos(t),
                            0.252 + 0.032 * math.sin(2.0 * t),
                            0.211))
make_curve("Chest_Infinity_Sign", infinity_points, 0.0046, cyan_glow,
           parent=coordinate_frame, cyclic=True)

# Back cooling panel and understated vents; all remain behind the torso shell.
make_box("Back_CoolingPlate", (0.225, 0.145, 0.016), (0.0, 0.255, -0.177),
         metal, bevel=0.025, parent=coordinate_frame)
for i in range(7):
    x = -0.075 + i * 0.025
    make_box(f"BackVent_{i + 1}", (0.008, 0.085, 0.004),
             (x, 0.255, -0.188), trim, bevel=0.003,
             parent=coordinate_frame)
make_torus("Base_Thruster_Rim", 0.066, 0.005, (0.0, 0.018, 0.0),
           blue_glow, parent=coordinate_frame,
           rotation=(math.pi / 2, 0.0, 0.0))
make_cylinder("Bottom_Thruster_Core", 0.075, 0.020,
              (0.0, 0.012, 0.0), metal,
              parent=coordinate_frame,
              rotation=(math.pi / 2, 0.0, 0.0))
make_cylinder("Bottom_Thruster_Light", 0.044, 0.009,
              (0.0, 0.010, 0.0), blue_glow,
              parent=coordinate_frame,
              rotation=(math.pi / 2, 0.0, 0.0))

# Identical smooth arm pods. Their empty pivots are separated from the torso;
# no neck, shoulder joint, hand, or visible connector mesh is created.
for side, pivot in (("Left", left_arm), ("Right", right_arm)):
    make_box(f"Arm_{side}_FloatingShell", (0.11, 0.28, 0.105),
             (0.0, -0.14, 0.0), shell, bevel=0.052,
             parent=pivot, gradient=True)
    make_box(f"Arm_{side}_WristAccent", (0.105, 0.018, 0.101),
             (0.0, -0.232, 0.0), trim, bevel=0.008,
             parent=pivot)
    make_box(f"Arm_{side}_OuterGlow", (0.010, 0.12, 0.025),
             (0.056, -0.14, 0.0), blue_glow, bevel=0.005,
             parent=pivot)

# Named, independent actions: the renderer will loop idle/thinking and play the
# greeting one time. All pivots are empty nodes; the visible meshes stay clean.
add_action_strip(root, "idle_float", [
    (0, (0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    (36, (0.0, 0.004, 0.0), (0.0, 0.0, 0.0)),
    (72, (0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    (108, (0.0, -0.004, 0.0), (0.0, 0.0, 0.0)),
    (144, (0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
])
add_action_strip(head, "thinking_loop", [
    (0, (0.0, 0.665, 0.0), (0.0, 0.0, -math.radians(1.6))),
    (24, (0.0, 0.667, 0.0), (0.0, 0.0, math.radians(1.6))),
    (48, (0.0, 0.665, 0.0), (0.0, 0.0, -math.radians(1.6))),
])
add_action_strip(right_arm, "wave_hand", [
    (0, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(8.0))),
    (10, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(132.0))),
    (18, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(112.0))),
    (26, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(132.0))),
    (34, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(112.0))),
    (42, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(132.0))),
    (52, (0.29, 0.392, 0.0), (0.0, 0.0, math.radians(8.0))),
])

# The explicit names are also a lightweight editing/inspection contract.
scene["dasko_model_version"] = 1
scene["dasko_neck_mesh_count"] = 0
scene["dasko_animation_names"] = "wave_hand,idle_float,thinking_loop"

MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
POSTER_PATH.parent.mkdir(parents=True, exist_ok=True)

# Export only the model hierarchy; poster lights/camera are added after export.
bpy.ops.object.select_all(action="DESELECT")
for obj in scene.objects:
    if obj.type not in {"CAMERA", "LIGHT"}:
        obj.select_set(True)
bpy.context.view_layer.objects.active = root
bpy.ops.export_scene.gltf(
    filepath=str(MODEL_PATH),
    export_format="GLB",
    use_selection=True,
    export_animations=True,
    export_nla_strips=True,
    export_force_sampling=True,
    export_skins=False,
    export_morph=False,
    export_cameras=False,
    export_lights=False,
)

# Render the fallback from the exported asset itself. Importing glTF normalizes
# its Y-up coordinate system in Blender, so the poster matches the live viewer.
clear_scene()
bpy.ops.import_scene.gltf(filepath=str(MODEL_PATH))
scene = bpy.context.scene
scene.frame_set(0)
add_camera_and_lights()
scene.render.filepath = str(POSTER_PATH)
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.view_settings.exposure = 0.0
scene.view_settings.gamma = 1.0
scene.render.image_settings.color_mode = "RGBA"
bpy.ops.render.render(write_still=True)
print(f"Created GLB: {MODEL_PATH}")
print(f"Created poster: {POSTER_PATH}")
