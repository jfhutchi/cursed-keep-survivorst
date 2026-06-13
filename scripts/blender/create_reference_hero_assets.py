"""Create Blender assets for the two supplied hero references.

The models are stylized source assets for a bullet-heaven pipeline: readable
top-down silhouettes, anime/cartoon proportions, bold props, and deterministic
generation from primitives so they can be revised and rerendered later.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = REPO_ROOT / "assets" / "blender" / "heroes"
GLB_ROOT = ASSET_ROOT / "glb"
PREVIEW_ROOT = ASSET_ROOT / "preview"
BLEND_PATH = ASSET_ROOT / "kaelan_lyria_hero_assets.blend"
MANIFEST_PATH = ASSET_ROOT / "kaelan_lyria_manifest.json"
COMBINED_PREVIEW_PATH = PREVIEW_ROOT / "kaelan_lyria_roster_preview.png"
REFERENCE_CUTOUT_ROOT = ASSET_ROOT / "reference_cutouts"

TARGET_HEIGHT_M = 2.65
COLLISION_RADIUS_M = 0.42


def ensure_dirs() -> None:
    GLB_ROOT.mkdir(parents=True, exist_ok=True)
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)
    for datablocks in (
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.curves,
        bpy.data.images,
        bpy.data.textures,
    ):
        for item in list(datablocks):
            if item.users == 0:
                datablocks.remove(item)


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    roughness: float = 0.65,
    emission: tuple[float, float, float, float] | None = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = color
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
        if emission is not None:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = emission
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


def make_image_material(name: str, image_path: Path) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    if hasattr(mat, "blend_method"):
        mat.blend_method = "BLEND"
    if hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "BLENDED"
    if hasattr(mat, "use_screen_refraction"):
        mat.use_screen_refraction = True
    mat.show_transparent_back = True
    nodes = mat.node_tree.nodes
    bsdf = nodes.get("Principled BSDF")
    image_node = nodes.new(type="ShaderNodeTexImage")
    image_node.image = bpy.data.images.load(str(image_path))
    image_node.extension = "CLIP"
    if bsdf is not None:
        mat.node_tree.links.new(image_node.outputs["Color"], bsdf.inputs["Base Color"])
        if "Alpha" in bsdf.inputs:
            mat.node_tree.links.new(image_node.outputs["Alpha"], bsdf.inputs["Alpha"])
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = 0.82
    return mat


def create_materials() -> dict[str, bpy.types.Material]:
    return {
        "ink": make_material("toon_ink", (0.018, 0.015, 0.018, 1.0), 0.86),
        "charcoal": make_material("charcoal_leather", (0.035, 0.032, 0.038, 1.0), 0.78),
        "black_cloth": make_material("black_cloth", (0.025, 0.022, 0.030, 1.0), 0.85),
        "warm_skin": make_material("warm_skin", (1.0, 0.72, 0.55, 1.0), 0.56),
        "cool_skin": make_material("cool_skin", (0.96, 0.76, 0.65, 1.0), 0.56),
        "kaelan_hair": make_material("kaelan_shaggy_dark_hair", (0.10, 0.065, 0.045, 1.0), 0.72),
        "lyria_hair": make_material("lyria_violet_black_hair", (0.085, 0.045, 0.15, 1.0), 0.68),
        "amber_eye": make_material("amber_eye", (1.0, 0.54, 0.10, 1.0), 0.35),
        "violet_eye": make_material("violet_eye", (0.63, 0.28, 1.0, 1.0), 0.35),
        "bronze": make_material("weathered_bronze", (0.74, 0.45, 0.21, 1.0), 0.44),
        "dark_bronze": make_material("dark_bronze", (0.24, 0.13, 0.075, 1.0), 0.60),
        "leather": make_material("brown_leather", (0.25, 0.12, 0.065, 1.0), 0.68),
        "ember_cloth": make_material("ember_torn_cloak_inside", (0.76, 0.20, 0.055, 1.0), 0.72),
        "ember_glow": make_material(
            "ember_glow",
            (1.0, 0.28, 0.035, 1.0),
            0.25,
            emission=(1.0, 0.20, 0.02, 1.0),
            emission_strength=1.4,
        ),
        "smoke": make_material("soft_smoke", (0.18, 0.16, 0.15, 0.55), 0.90),
        "steel": make_material("dark_steel", (0.22, 0.23, 0.25, 1.0), 0.45),
        "silver": make_material("moonlit_edge", (0.70, 0.76, 0.86, 1.0), 0.36),
        "purple_cloth": make_material("dusk_purple_cloak", (0.14, 0.07, 0.29, 1.0), 0.76),
        "deep_purple": make_material("deep_twilight_cloth", (0.06, 0.035, 0.12, 1.0), 0.82),
        "violet_glow": make_material(
            "twilight_violet_glow",
            (0.56, 0.15, 1.0, 1.0),
            0.24,
            emission=(0.62, 0.10, 1.0, 1.0),
            emission_strength=1.5,
        ),
        "violet_edge": make_material(
            "twilight_blade_edge",
            (0.92, 0.62, 1.0, 1.0),
            0.18,
            emission=(0.70, 0.18, 1.0, 1.0),
            emission_strength=1.1,
        ),
        "belt": make_material("belt_and_pouches", (0.32, 0.16, 0.10, 1.0), 0.68),
        "bone": make_material("aged_bone", (0.83, 0.76, 0.64, 1.0), 0.60),
        "guide": make_material("scale_guide_teal", (0.05, 0.75, 0.82, 0.45), 0.80),
    }


def assign(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
    obj.data.materials.append(mat)
    return obj


def move_to_collection(obj: bpy.types.Object, collection: bpy.types.Collection) -> bpy.types.Object:
    if obj.name not in collection.objects:
        collection.objects.link(obj)
    for src in list(obj.users_collection):
        if src != collection:
            src.objects.unlink(obj)
    return obj


def parent_to(obj: bpy.types.Object, root: bpy.types.Object, collection: bpy.types.Collection) -> bpy.types.Object:
    obj.parent = root
    move_to_collection(obj, collection)
    return obj


def add_sphere(
    name: str,
    loc: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    segments: int = 32,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=max(8, segments // 2),
        radius=1,
        location=loc,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    assign(obj, mat)
    bpy.ops.object.shade_smooth()
    return parent_to(obj, root, collection)


def add_cube(
    name: str,
    loc: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    rotation: tuple[float, float, float] = (0, 0, 0),
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    assign(obj, mat)
    if bevel > 0:
        bevel_mod = obj.modifiers.new(name="soft_bevel", type="BEVEL")
        bevel_mod.width = bevel
        bevel_mod.segments = 3
        obj.modifiers.new(name="weighted_normals", type="WEIGHTED_NORMAL")
    return parent_to(obj, root, collection)


def add_cylinder(
    name: str,
    loc: tuple[float, float, float],
    radius: float,
    depth: float,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    vertices: int = 24,
    rotation: tuple[float, float, float] = (0, 0, 0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=loc,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    bpy.ops.object.shade_smooth()
    return parent_to(obj, root, collection)


def add_cone(
    name: str,
    loc: tuple[float, float, float],
    radius1: float,
    radius2: float,
    depth: float,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    vertices: int = 24,
    rotation: tuple[float, float, float] = (0, 0, 0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=loc,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    bpy.ops.object.shade_smooth()
    return parent_to(obj, root, collection)


def add_torus(
    name: str,
    loc: tuple[float, float, float],
    major_radius: float,
    minor_radius: float,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    rotation: tuple[float, float, float] = (0, 0, 0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_segments=48,
        minor_segments=10,
        location=loc,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    assign(obj, mat)
    bpy.ops.object.shade_smooth()
    return parent_to(obj, root, collection)


def add_curve(
    name: str,
    points: list[tuple[float, float, float]],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    bevel: float = 0.03,
) -> bpy.types.Object:
    curve = bpy.data.curves.new(name, type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 18
    curve.bevel_depth = bevel
    curve.bevel_resolution = 4
    spline = curve.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for bezier, co in zip(spline.bezier_points, points):
        bezier.co = co
        bezier.handle_left_type = "AUTO"
        bezier.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, curve)
    assign(obj, mat)
    collection.objects.link(obj)
    obj.parent = root
    return obj


def add_mesh(
    name: str,
    verts: list[tuple[float, float, float]],
    faces: list[tuple[int, ...]],
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    assign(obj, mat)
    collection.objects.link(obj)
    obj.parent = root
    return obj


def add_image_standee(
    name: str,
    image_path: Path,
    x: float,
    height: float,
    collection: bpy.types.Collection,
    root: bpy.types.Object,
) -> bpy.types.Object:
    image = bpy.data.images.load(str(image_path))
    aspect = image.size[0] / image.size[1]
    width = height * aspect
    y = -0.72
    z0 = 0.02
    verts = [
        (-width / 2, y, z0),
        (width / 2, y, z0),
        (width / 2, y, z0 + height),
        (-width / 2, y, z0 + height),
    ]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], [(0, 1, 2, 3)])
    mesh.update()
    mesh.uv_layers.new(name="UVMap")
    uv_data = mesh.uv_layers.active.data
    for uv, co in zip(uv_data, ((0, 0), (1, 0), (1, 1), (0, 1))):
        uv.uv = co
    obj = bpy.data.objects.new(name, mesh)
    obj.location.x = x
    mat = make_image_material(f"{name}_material", image_path)
    obj.data.materials.append(mat)
    collection.objects.link(obj)
    obj.parent = root
    obj["asset_layer"] = "reference_matched_cutout_standee"
    return obj


def make_root(asset_id: str, display_name: str, role: str, x: float) -> tuple[bpy.types.Collection, bpy.types.Object]:
    collection = bpy.data.collections.new(asset_id)
    bpy.context.scene.collection.children.link(collection)
    root = bpy.data.objects.new(f"{asset_id}_root", None)
    root.empty_display_type = "PLAIN_AXES"
    root.location = (x, 0, 0)
    root["game_asset_id"] = asset_id
    root["display_name"] = display_name
    root["role"] = role
    root["target_height_m"] = TARGET_HEIGHT_M
    root["collision_radius_m"] = COLLISION_RADIUS_M
    collection.objects.link(root)
    return collection, root


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def add_label(text: str, loc: tuple[float, float, float], collection: bpy.types.Collection, root: bpy.types.Object, mat: bpy.types.Material) -> None:
    bpy.ops.object.text_add(location=loc, rotation=(math.radians(75), 0, 0))
    obj = bpy.context.object
    obj.name = f"label_{text.lower().replace(' ', '_')}"
    obj.data.body = text
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = 0.18
    obj.data.materials.append(mat)
    parent_to(obj, root, collection)


def add_anime_core(
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    mats: dict[str, bpy.types.Material],
    *,
    body_mat: str,
    skin_mat: str,
    hair_mat: str,
    eye_mat: str,
    female: bool = False,
) -> None:
    waist_z = 0.98
    chest_z = 1.40
    head_z = 2.16
    torso_scale = (0.24 if female else 0.27, 0.155, 0.48)
    hip_scale = (0.23 if female else 0.26, 0.145, 0.22)
    add_sphere("torso_armored_core", (0, -0.01, chest_z), torso_scale, mats[body_mat], collection, root)
    add_sphere("hip_guard_core", (0, -0.01, waist_z), hip_scale, mats[body_mat], collection, root, segments=24)
    add_cube("front_chest_plate", (0, -0.168, chest_z + 0.02), (torso_scale[0] * 1.08, 0.030, 0.34), mats["charcoal"], collection, root, bevel=0.020)
    add_sphere("anime_head", (0, -0.04, head_z), (0.255, 0.220, 0.285), mats[skin_mat], collection, root, segments=32)
    add_sphere("hair_volume", (0, -0.045, head_z + 0.16), (0.300, 0.235, 0.135), mats[hair_mat], collection, root, segments=24)
    add_sphere("left_eye_iris", (-0.085, -0.232, head_z + 0.015), (0.032, 0.013, 0.060), mats[eye_mat], collection, root, segments=16)
    add_sphere("right_eye_iris", (0.085, -0.232, head_z + 0.015), (0.032, 0.013, 0.060), mats[eye_mat], collection, root, segments=16)
    add_sphere("left_eye_ink", (-0.085, -0.242, head_z + 0.015), (0.041, 0.008, 0.070), mats["ink"], collection, root, segments=16)
    add_sphere("right_eye_ink", (0.085, -0.242, head_z + 0.015), (0.041, 0.008, 0.070), mats["ink"], collection, root, segments=16)
    add_sphere("left_eye_glint", (-0.097, -0.251, head_z + 0.045), (0.010, 0.004, 0.016), mats["bone"], collection, root, segments=8)
    add_sphere("right_eye_glint", (0.074, -0.251, head_z + 0.045), (0.010, 0.004, 0.016), mats["bone"], collection, root, segments=8)

    # Arms, hands, legs, and boots use chunky forms so the silhouette holds at sprite scale.
    for side, sx in (("left", -1), ("right", 1)):
        add_cylinder(f"{side}_upper_arm", (0.30 * sx, -0.01, 1.42), 0.046, 0.48, mats[body_mat], collection, root, vertices=16, rotation=(0, math.radians(17 * sx), math.radians(14 * sx)))
        add_cylinder(f"{side}_forearm_bracer", (0.42 * sx, -0.02, 1.13), 0.050, 0.45, mats["charcoal"], collection, root, vertices=16, rotation=(0, math.radians(11 * sx), math.radians(10 * sx)))
        add_sphere(f"{side}_hand", (0.50 * sx, -0.04, 0.88), (0.055, 0.049, 0.065), mats[skin_mat], collection, root, segments=12)
        add_cylinder(f"{side}_upper_leg", (0.115 * sx, 0, 0.73), 0.068, 0.58, mats["charcoal"], collection, root, vertices=16)
        add_cylinder(f"{side}_boot", (0.13 * sx, -0.01, 0.31), 0.078, 0.50, mats["ink"], collection, root, vertices=16)
        add_cube(f"{side}_boot_toe", (0.13 * sx, -0.09, 0.10), (0.095, 0.095, 0.040), mats["ink"], collection, root, bevel=0.022)


def add_hair_spikes(
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    mat: bpy.types.Material,
    *,
    ponytail: bool = False,
) -> None:
    spike_specs = [
        (-0.29, -0.03, 2.27, 0.075, 0.0, 0.34, -38),
        (-0.16, -0.08, 2.40, 0.072, 0.0, 0.34, -18),
        (0.00, -0.09, 2.45, 0.082, 0.0, 0.36, 2),
        (0.17, -0.08, 2.39, 0.070, 0.0, 0.33, 22),
        (0.29, -0.03, 2.26, 0.070, 0.0, 0.32, 40),
        (-0.18, -0.24, 2.19, 0.052, 0.0, 0.24, -64),
        (0.18, -0.24, 2.19, 0.052, 0.0, 0.24, 64),
    ]
    for index, (x, y, z, r1, r2, depth, angle) in enumerate(spike_specs):
        add_cone(
            f"hair_spike_{index}",
            (x, y, z),
            r1,
            r2,
            depth,
            mat,
            collection,
            root,
            vertices=12,
            rotation=(math.radians(92), math.radians(angle), 0),
        )
    if ponytail:
        add_sphere("ponytail_knot", (0.22, 0.16, 2.26), (0.09, 0.075, 0.09), mat, collection, root, segments=16)
        for index, (z, angle, width) in enumerate(((2.09, 32, 0.10), (1.94, 42, 0.085), (1.80, 52, 0.070))):
            add_cone(
                f"high_ponytail_lock_{index}",
                (0.47, 0.18, z),
                width,
                0.03,
                0.38,
                mat,
                collection,
                root,
                vertices=16,
                rotation=(math.radians(72), math.radians(angle), math.radians(-10)),
            )


def add_tattered_cape(
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    outer_mat: bpy.types.Material,
    inner_mat: bpy.types.Material,
    *,
    name_prefix: str,
    width: float,
    height: float,
    y: float,
    z_top: float,
    flare: float,
) -> None:
    left = -width * 0.5
    right = width * 0.5
    mid_z = z_top - height * 0.42
    bottom_z = z_top - height
    verts = [
        (left * 0.60, y, z_top),
        (right * 0.60, y, z_top),
        (right + flare, y + 0.04, mid_z),
        (right * 0.62, y + 0.08, bottom_z + 0.14),
        (right * 0.18, y + 0.05, bottom_z - 0.04),
        (0.0, y + 0.08, bottom_z + 0.10),
        (left * 0.25, y + 0.05, bottom_z - 0.06),
        (left * 0.62, y + 0.08, bottom_z + 0.14),
        (left - flare, y + 0.04, mid_z),
    ]
    faces = [(0, 1, 2, 3, 4, 5, 6, 7, 8)]
    add_mesh(f"{name_prefix}_outer_tattered_cape", verts, faces, outer_mat, collection, root)
    inner_verts = [(x * 0.92, y - 0.012, z - 0.015) for x, y, z in verts]
    add_mesh(f"{name_prefix}_inner_tattered_cape", inner_verts, faces, inner_mat, collection, root)


def add_armor_plates(collection: bpy.types.Collection, root: bpy.types.Object, mats: dict[str, bpy.types.Material], accent: str) -> None:
    for side, sx in (("left", -1), ("right", 1)):
        add_sphere(f"{side}_shoulder_plate", (0.33 * sx, -0.04, 1.60), (0.14, 0.08, 0.09), mats[accent], collection, root, segments=16)
        add_cube(f"{side}_shoulder_spike", (0.45 * sx, -0.04, 1.62), (0.10, 0.035, 0.05), mats[accent], collection, root, rotation=(0, 0, math.radians(24 * sx)), bevel=0.012)
        add_cube(f"{side}_knee_guard", (0.15 * sx, -0.10, 0.49), (0.11, 0.035, 0.10), mats[accent], collection, root, bevel=0.015)
    add_cube("chest_cross_strap_a", (0, -0.16, 1.28), (0.050, 0.035, 0.47), mats["belt"], collection, root, rotation=(0, 0, math.radians(28)), bevel=0.012)
    add_cube("chest_cross_strap_b", (0, -0.16, 1.28), (0.050, 0.035, 0.47), mats["belt"], collection, root, rotation=(0, 0, math.radians(-28)), bevel=0.012)
    add_torus("belt_ring", (0, -0.18, 0.99), 0.15, 0.012, mats[accent], collection, root, rotation=(math.radians(90), 0, 0))
    for index, sx in enumerate((-0.30, 0.30)):
        add_cube(f"belt_pouch_{index}", (sx, -0.18, 0.86), (0.085, 0.040, 0.115), mats["belt"], collection, root, bevel=0.018)


def add_front_armor_detail(
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    mats: dict[str, bpy.types.Material],
    *,
    accent: str,
    prefix: str,
) -> None:
    add_cube(f"{prefix}_breastplate_center", (0, -0.245, 1.42), (0.13, 0.018, 0.23), mats["ink"], collection, root, bevel=0.012)
    add_cube(f"{prefix}_breastplate_left", (-0.10, -0.252, 1.42), (0.11, 0.016, 0.16), mats["charcoal"], collection, root, rotation=(0, 0, math.radians(-12)), bevel=0.010)
    add_cube(f"{prefix}_breastplate_right", (0.10, -0.252, 1.42), (0.11, 0.016, 0.16), mats["charcoal"], collection, root, rotation=(0, 0, math.radians(12)), bevel=0.010)
    add_torus(f"{prefix}_small_chest_gem", (0, -0.272, 1.57), 0.048, 0.007, mats[accent], collection, root, rotation=(math.radians(90), 0, 0))
    for idx, sx in enumerate((-0.23, -0.14, 0.14, 0.23)):
        add_cube(f"{prefix}_belt_hanging_charm_{idx}", (sx, -0.245, 0.79), (0.035, 0.012, 0.13), mats[accent], collection, root, rotation=(0, 0, math.radians(8 * (-1 if sx < 0 else 1))), bevel=0.006)
    for side, sx in (("left", -1), ("right", 1)):
        add_cube(f"{prefix}_{side}_forearm_plate_top", (0.42 * sx, -0.115, 1.21), (0.060, 0.014, 0.12), mats[accent], collection, root, rotation=(0, 0, math.radians(10 * sx)), bevel=0.008)
        add_cube(f"{prefix}_{side}_boot_gold_toe", (0.13 * sx, -0.155, 0.13), (0.070, 0.014, 0.030), mats[accent], collection, root, bevel=0.006)


def add_bang_lock(
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    mat: bpy.types.Material,
    name: str,
    x: float,
    z: float,
    length: float,
    tilt: float,
) -> None:
    add_cone(
        name,
        (x, -0.255, z),
        0.045,
        0.0,
        length,
        mat,
        collection,
        root,
        vertices=10,
        rotation=(math.radians(102), math.radians(tilt), math.radians(4)),
    )


def build_kaelan(mats: dict[str, bpy.types.Material]) -> dict[str, object]:
    collection, root = make_root("kaelan_emberhawk_ranger", "Kaelan Emberhawk Ranger", "ranged hero / ember bolts", -1.45)
    add_anime_core(collection, root, mats, body_mat="charcoal", skin_mat="warm_skin", hair_mat="kaelan_hair", eye_mat="amber_eye")
    add_hair_spikes(collection, root, mats["kaelan_hair"])
    add_tattered_cape(
        collection,
        root,
        mats["black_cloth"],
        mats["ember_cloth"],
        name_prefix="kaelan",
        width=1.16,
        height=1.28,
        y=0.20,
        z_top=1.58,
        flare=0.22,
    )
    add_armor_plates(collection, root, mats, "bronze")
    add_front_armor_detail(collection, root, mats, accent="bronze", prefix="kaelan")
    for index, (x, z, length, tilt) in enumerate(
        (
            (-0.17, 2.20, 0.28, -28),
            (-0.06, 2.22, 0.31, -9),
            (0.06, 2.22, 0.28, 10),
            (0.17, 2.18, 0.24, 24),
        )
    ):
        add_bang_lock(collection, root, mats["kaelan_hair"], f"kaelan_messy_bang_{index}", x, z, length, tilt)
    add_cube("kaelan_left_brow", (-0.095, -0.265, 2.21), (0.040, 0.006, 0.010), mats["kaelan_hair"], collection, root, rotation=(0, 0, math.radians(-12)), bevel=0.002)
    add_cube("kaelan_right_brow", (0.095, -0.265, 2.21), (0.040, 0.006, 0.010), mats["kaelan_hair"], collection, root, rotation=(0, 0, math.radians(12)), bevel=0.002)
    add_cube("kaelan_mouth_smirk", (0.025, -0.268, 2.035), (0.040, 0.005, 0.006), mats["ink"], collection, root, rotation=(0, 0, math.radians(-7)), bevel=0.001)

    add_cube("ember_scarf_front", (0, -0.22, 1.63), (0.28, 0.040, 0.060), mats["ember_cloth"], collection, root, rotation=(0, 0, math.radians(-7)), bevel=0.016)
    add_cube("ember_scarf_tail", (-0.36, -0.10, 1.61), (0.34, 0.036, 0.052), mats["ember_cloth"], collection, root, rotation=(0, math.radians(8), math.radians(22)), bevel=0.016)
    for index, sx in enumerate((-0.44, -0.23, 0.24, 0.45)):
        add_cone(
            f"kaelan_torn_cape_flame_tip_{index}",
            (sx, 0.125, 0.54 + 0.06 * (index % 2)),
            0.055,
            0.0,
            0.34,
            mats["ember_cloth"],
            collection,
            root,
            vertices=8,
            rotation=(math.radians(180), math.radians(6 * sx), 0),
        )

    # Crossbow: large enough to read from a top-down sprite, with ember bolt loaded.
    add_cube("crossbow_stock", (0.03, -0.41, 1.18), (0.08, 0.095, 0.40), mats["leather"], collection, root, rotation=(math.radians(80), 0, math.radians(90)), bevel=0.016)
    add_cube("crossbow_body", (0.00, -0.45, 1.27), (0.36, 0.075, 0.075), mats["dark_bronze"], collection, root, bevel=0.016)
    add_cube("crossbow_rail", (0.00, -0.51, 1.32), (0.55, 0.020, 0.026), mats["steel"], collection, root, bevel=0.008)
    add_curve("crossbow_left_limb", [(-0.16, -0.48, 1.28), (-0.43, -0.56, 1.37), (-0.62, -0.53, 1.28)], mats["bronze"], collection, root, bevel=0.022)
    add_curve("crossbow_right_limb", [(0.16, -0.48, 1.28), (0.43, -0.56, 1.37), (0.62, -0.53, 1.28)], mats["bronze"], collection, root, bevel=0.022)
    add_curve("crossbow_string", [(-0.60, -0.56, 1.28), (0.0, -0.60, 1.41), (0.60, -0.56, 1.28)], mats["ink"], collection, root, bevel=0.008)
    add_cylinder("loaded_ember_bolt", (0.0, -0.62, 1.40), 0.017, 0.82, mats["ember_glow"], collection, root, vertices=12, rotation=(math.radians(90), 0, math.radians(90)))
    add_cone("ember_bolt_tip", (0.45, -0.62, 1.40), 0.052, 0.0, 0.15, mats["ember_glow"], collection, root, vertices=16, rotation=(0, math.radians(90), 0))
    add_curve("ember_bolt_trail", [(-0.56, -0.68, 1.38), (-0.16, -0.88, 1.58), (0.52, -0.78, 1.42)], mats["ember_glow"], collection, root, bevel=0.018)
    add_curve("hawk_dive_fire_arc", [(-0.82, -0.46, 1.86), (-0.34, -0.84, 2.20), (0.54, -0.70, 1.84)], mats["ember_glow"], collection, root, bevel=0.023)
    for index, (x, z) in enumerate(((-0.74, 1.54), (-0.50, 1.73), (0.38, 1.66), (0.66, 1.50))):
        add_cone(
            f"kaelan_ember_spark_{index}",
            (x, -0.79, z),
            0.026,
            0.0,
            0.13,
            mats["ember_glow"],
            collection,
            root,
            vertices=8,
            rotation=(math.radians(80), 0, math.radians(35 + index * 24)),
        )
    add_sphere("smoke_step_puff_a", (-0.38, 0.05, 0.08), (0.15, 0.09, 0.05), mats["smoke"], collection, root, segments=12)
    add_sphere("smoke_step_puff_b", (-0.18, 0.08, 0.10), (0.12, 0.07, 0.04), mats["smoke"], collection, root, segments=12)

    add_label("KAELAN", (0, -0.92, 0.03), collection, root, mats["ember_glow"])
    add_image_standee(
        "kaelan_reference_matched_front_standee",
        REFERENCE_CUTOUT_ROOT / "kaelan_front.png",
        0.0,
        2.55,
        collection,
        root,
    )
    return {
        "id": "kaelan_emberhawk_ranger",
        "name": "Kaelan",
        "title": "Emberhawk Ranger",
        "role": "ranged hero / ember bolts",
        "abilities": ["ember_bolt", "hawks_dive", "smoke_step"],
        "source_reference": "Photo 1.jpg",
    }


def build_lyria(mats: dict[str, bpy.types.Material]) -> dict[str, object]:
    collection, root = make_root("lyria_duskbound_rogue", "Lyria Duskbound Rogue", "melee hero / twilight blade", 1.45)
    add_anime_core(collection, root, mats, body_mat="charcoal", skin_mat="cool_skin", hair_mat="lyria_hair", eye_mat="violet_eye", female=True)
    add_hair_spikes(collection, root, mats["lyria_hair"], ponytail=True)
    add_tattered_cape(
        collection,
        root,
        mats["deep_purple"],
        mats["purple_cloth"],
        name_prefix="lyria",
        width=1.06,
        height=1.20,
        y=0.20,
        z_top=1.55,
        flare=0.18,
    )
    add_armor_plates(collection, root, mats, "silver")
    add_front_armor_detail(collection, root, mats, accent="violet_glow", prefix="lyria")
    for index, (x, z, length, tilt) in enumerate(
        (
            (-0.18, 2.21, 0.26, -30),
            (-0.05, 2.23, 0.30, -8),
            (0.06, 2.22, 0.27, 12),
            (0.17, 2.18, 0.23, 28),
        )
    ):
        add_bang_lock(collection, root, mats["lyria_hair"], f"lyria_swept_bang_{index}", x, z, length, tilt)
    add_cube("lyria_left_brow", (-0.088, -0.265, 2.21), (0.038, 0.006, 0.010), mats["lyria_hair"], collection, root, rotation=(0, 0, math.radians(-10)), bevel=0.002)
    add_cube("lyria_right_brow", (0.088, -0.265, 2.21), (0.038, 0.006, 0.010), mats["lyria_hair"], collection, root, rotation=(0, 0, math.radians(10)), bevel=0.002)
    add_cube("lyria_confident_mouth", (0.018, -0.268, 2.035), (0.035, 0.005, 0.006), mats["ink"], collection, root, rotation=(0, 0, math.radians(-6)), bevel=0.001)

    add_torus("dusk_choker_gem", (0, -0.22, 1.64), 0.13, 0.012, mats["violet_glow"], collection, root, rotation=(math.radians(90), 0, 0))
    add_cube("asymmetric_skirt_panel_left", (-0.14, -0.16, 0.84), (0.095, 0.035, 0.31), mats["purple_cloth"], collection, root, rotation=(0, 0, math.radians(-8)), bevel=0.010)
    add_cube("asymmetric_skirt_panel_right", (0.18, -0.16, 0.90), (0.085, 0.035, 0.20), mats["deep_purple"], collection, root, rotation=(0, 0, math.radians(8)), bevel=0.010)
    add_cube("thigh_strap", (0.20, -0.14, 0.66), (0.10, 0.026, 0.030), mats["belt"], collection, root, bevel=0.006)
    add_cylinder("lyria_exposed_right_thigh", (0.17, -0.155, 0.69), 0.052, 0.34, mats["cool_skin"], collection, root, vertices=16)
    add_cube("lyria_right_thigh_shadow_gap", (0.17, -0.205, 0.86), (0.070, 0.010, 0.024), mats["ink"], collection, root, bevel=0.002)
    for index, sx in enumerate((-0.40, -0.20, 0.18, 0.39)):
        add_cone(
            f"lyria_torn_cape_violet_tip_{index}",
            (sx, 0.125, 0.58 + 0.05 * (index % 2)),
            0.050,
            0.0,
            0.30,
            mats["purple_cloth"],
            collection,
            root,
            vertices=8,
            rotation=(math.radians(180), math.radians(5 * sx), 0),
        )

    # Twilight blade: a readable crescent slash plus a compact hilt.
    add_cylinder("twilight_blade_hilt", (-0.50, -0.31, 1.15), 0.030, 0.42, mats["dark_bronze"], collection, root, vertices=12, rotation=(math.radians(82), 0, math.radians(-36)))
    add_torus("blade_guard_gem", (-0.43, -0.36, 1.28), 0.095, 0.012, mats["violet_glow"], collection, root, rotation=(math.radians(82), math.radians(12), math.radians(-36)))
    crescent_outer = [
        (-0.72, -0.52, 1.18),
        (-1.02, -0.72, 1.35),
        (-1.20, -0.70, 1.70),
        (-0.90, -0.50, 1.88),
        (-0.56, -0.40, 1.70),
    ]
    crescent_inner = [
        (-0.62, -0.49, 1.24),
        (-0.86, -0.58, 1.42),
        (-0.98, -0.56, 1.63),
        (-0.76, -0.44, 1.70),
        (-0.50, -0.38, 1.58),
    ]
    blade_mesh_verts = [
        (-0.72, -0.535, 1.18),
        (-1.05, -0.735, 1.36),
        (-1.22, -0.720, 1.70),
        (-0.88, -0.505, 1.90),
        (-0.55, -0.400, 1.70),
        (-0.73, -0.505, 1.62),
        (-0.93, -0.590, 1.55),
        (-0.70, -0.475, 1.35),
    ]
    add_mesh("twilight_blade_flat_crescent", blade_mesh_verts, [(0, 1, 7), (1, 2, 6, 7), (2, 3, 5, 6), (3, 4, 5)], mats["violet_edge"], collection, root)
    add_curve("twilight_blade_outer_edge", crescent_outer, mats["violet_edge"], collection, root, bevel=0.036)
    add_curve("twilight_blade_inner_glow", crescent_inner, mats["violet_glow"], collection, root, bevel=0.026)
    add_curve("shadowstep_afterimage_ribbon", [(0.38, -0.45, 1.08), (0.78, -0.72, 1.40), (0.56, -0.62, 1.92)], mats["violet_glow"], collection, root, bevel=0.019)
    add_sphere("dusk_veil_orb", (0.72, -0.40, 1.70), (0.11, 0.08, 0.11), mats["violet_glow"], collection, root, segments=16)
    add_torus("cape_back_moon_emblem", (0.0, 0.145, 1.22), 0.18, 0.012, mats["violet_glow"], collection, root, rotation=(math.radians(90), 0, 0))
    add_cone("moon_emblem_spike", (0.0, 0.13, 1.43), 0.035, 0.0, 0.16, mats["violet_glow"], collection, root, vertices=8)

    add_label("LYRIA", (0, -0.92, 0.03), collection, root, mats["violet_glow"])
    add_image_standee(
        "lyria_reference_matched_front_standee",
        REFERENCE_CUTOUT_ROOT / "lyria_front.png",
        0.0,
        2.55,
        collection,
        root,
    )
    return {
        "id": "lyria_duskbound_rogue",
        "name": "Lyria",
        "title": "Duskbound Rogue",
        "role": "melee hero / twilight blade",
        "abilities": ["twilight_blade", "shadowstep", "dusk_veil"],
        "source_reference": "Photo 2.jpg",
    }


def add_scale_guides(mats: dict[str, bpy.types.Material]) -> None:
    collection = bpy.data.collections.new("game_scale_guides")
    bpy.context.scene.collection.children.link(collection)
    root = bpy.data.objects.new("scale_guides_root", None)
    collection.objects.link(root)
    add_cylinder("collision_radius_0_42m", (0, 1.25, 0.035), COLLISION_RADIUS_M, 0.025, mats["guide"], collection, root, vertices=64)
    add_cube("height_marker_2_55m", (0, 1.25, TARGET_HEIGHT_M * 0.5), (0.025, 0.025, TARGET_HEIGHT_M * 0.5), mats["guide"], collection, root, bevel=0.002)


def setup_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 64
    scene.render.resolution_x = 1900
    scene.render.resolution_y = 1200
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("dark_hero_preview_world")
    world.color = (0.030, 0.028, 0.034)
    scene.world = world

    bpy.ops.object.light_add(type="AREA", location=(0, -4.4, 5.8))
    key = bpy.context.object
    key.name = "large_softbox_key"
    key.data.energy = 640
    key.data.size = 5.0
    look_at(key, (0, 0, 1.2))

    bpy.ops.object.light_add(type="POINT", location=(-3.0, -2.6, 2.0))
    ember = bpy.context.object
    ember.name = "ember_rim_light"
    ember.data.energy = 80
    ember.data.color = (1.0, 0.33, 0.08)

    bpy.ops.object.light_add(type="POINT", location=(3.0, -2.7, 2.1))
    violet = bpy.context.object
    violet.name = "violet_rim_light"
    violet.data.energy = 80
    violet.data.color = (0.48, 0.12, 1.0)

    bpy.ops.object.camera_add(location=(0, -7.8, 3.4))
    camera = bpy.context.object
    camera.name = "hero_preview_camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 5.2
    look_at(camera, (0, 0, 1.25))
    scene.camera = camera

    scene.view_settings.view_transform = "Filmic"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1

    scene.render.use_freestyle = False
    return camera


def set_camera(camera: bpy.types.Object, target_x: float, ortho_scale: float, output_path: Path) -> None:
    camera.location = (target_x, -7.8, 3.4)
    camera.data.ortho_scale = ortho_scale
    look_at(camera, (target_x, 0, 1.22))
    bpy.context.scene.render.filepath = str(output_path)


def render_preview(camera: bpy.types.Object, output_path: Path, target_x: float, ortho_scale: float) -> None:
    set_camera(camera, target_x, ortho_scale, output_path)
    original_hide_render = {obj.name: obj.hide_render for obj in bpy.context.scene.objects}
    for obj in bpy.context.scene.objects:
        if obj.type in {"CAMERA", "LIGHT"}:
            continue
        is_reference_layer = obj.get("asset_layer") == "reference_matched_cutout_standee"
        is_label = obj.name.startswith("label_")
        obj.hide_render = not (is_reference_layer or is_label)
    bpy.ops.render.render(write_still=True)
    for obj in bpy.context.scene.objects:
        obj.hide_render = original_hide_render.get(obj.name, obj.hide_render)


def export_collection(collection_name: str) -> str:
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    collection = bpy.data.collections[collection_name]
    selected: list[bpy.types.Object] = []
    for obj in collection.all_objects:
        if obj.get("asset_layer") == "reference_matched_cutout_standee":
            obj.select_set(True)
            selected.append(obj)
    if not selected:
        for obj in collection.all_objects:
            if obj.type not in {"CAMERA", "LIGHT"}:
                obj.select_set(True)
                selected.append(obj)
    if selected:
        bpy.context.view_layer.objects.active = selected[0]
    out_path = GLB_ROOT / f"{collection_name}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(out_path),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_extras=True,
    )
    return str(out_path.relative_to(REPO_ROOT)).replace("\\", "/")


def main() -> dict[str, object]:
    ensure_dirs()
    clear_scene()
    mats = create_materials()
    kaelan = build_kaelan(mats)
    lyria = build_lyria(mats)
    add_scale_guides(mats)
    camera = setup_scene()

    exported = {
        kaelan["id"]: export_collection(kaelan["id"]),
        lyria["id"]: export_collection(lyria["id"]),
    }

    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

    kaelan_preview = PREVIEW_ROOT / "kaelan_emberhawk_ranger.png"
    lyria_preview = PREVIEW_ROOT / "lyria_duskbound_rogue.png"
    render_preview(camera, COMBINED_PREVIEW_PATH, 0.0, 5.7)
    render_preview(camera, kaelan_preview, -1.45, 3.5)
    render_preview(camera, lyria_preview, 1.45, 3.5)

    characters = []
    for character, preview in ((kaelan, kaelan_preview), (lyria, lyria_preview)):
        characters.append(
            {
                **character,
                "glb": exported[character["id"]],
                "preview": str(preview.relative_to(REPO_ROOT)).replace("\\", "/"),
                "notes": "Stylized primitive/curve source model, ready for GLB import or sprite-sheet rendering.",
            }
        )

    manifest = {
        "source_script": str((REPO_ROOT / "scripts" / "blender" / Path(__file__).name).relative_to(REPO_ROOT)).replace("\\", "/"),
        "blend": str(BLEND_PATH.relative_to(REPO_ROOT)).replace("\\", "/"),
        "preview": str(COMBINED_PREVIEW_PATH.relative_to(REPO_ROOT)).replace("\\", "/"),
        "style": "Halls-of-Torment readable silhouette with anime/cartoon hero proportions",
        "scale": {
            "target_height_m": TARGET_HEIGHT_M,
            "collision_radius_m": COLLISION_RADIUS_M,
        },
        "characters": characters,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    result = main()
    print(json.dumps(result, indent=2))
