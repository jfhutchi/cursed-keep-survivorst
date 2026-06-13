"""Create Blender assets for the second batch of five enemy references."""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[2]
ASSET_ROOT = REPO_ROOT / "assets" / "blender" / "enemies"
GLB_ROOT = ASSET_ROOT / "glb"
PREVIEW_ROOT = ASSET_ROOT / "preview"
REFERENCE_CUTOUT_ROOT = ASSET_ROOT / "reference_cutouts"
BLEND_PATH = ASSET_ROOT / "second_five_enemy_assets.blend"
MANIFEST_PATH = ASSET_ROOT / "second_five_enemy_manifest.json"
COMBINED_PREVIEW_PATH = PREVIEW_ROOT / "second_five_enemy_roster_preview.png"

ENEMIES = [
    {
        "id": "shade_dusk_wraith",
        "name": "Shade",
        "title": "Dusk Wraith",
        "role": "phase assassin / spectral chill",
        "source_reference": "Photo 1.jpg",
        "cutout": "shade_dusk_wraith_front.png",
        "height_m": 2.25,
        "collision_radius_m": 0.38,
        "x": -3.0,
        "label_color": (0.63, 0.42, 1.0, 1.0),
        "abilities": ["phase_slice", "haunt_dash", "soul_chill"],
    },
    {
        "id": "maw_slag_hound",
        "name": "Maw",
        "title": "Slag Hound",
        "role": "pack charger / lava bite",
        "source_reference": "Photo 2.jpg",
        "cutout": "maw_slag_hound_front.png",
        "height_m": 1.45,
        "collision_radius_m": 0.44,
        "x": -1.5,
        "label_color": (1.0, 0.36, 0.08, 1.0),
        "abilities": ["pounce", "pack_howl", "lava_bite"],
    },
    {
        "id": "bulwark_iron_husk",
        "name": "Bulwark",
        "title": "Iron Husk",
        "role": "armored guard / shield wall",
        "source_reference": "Photo 3.jpg",
        "cutout": "bulwark_iron_husk_front.png",
        "height_m": 2.55,
        "collision_radius_m": 0.52,
        "x": 0.0,
        "label_color": (1.0, 0.24, 0.28, 1.0),
        "abilities": ["shield_slam", "march_guard", "iron_bash"],
    },
    {
        "id": "glob_rotspore_spitter",
        "name": "Glob",
        "title": "Rotspore Spitter",
        "role": "spore artillery / slime trail",
        "source_reference": "Photo 4.jpg",
        "cutout": "glob_rotspore_spitter_front.png",
        "height_m": 1.55,
        "collision_radius_m": 0.50,
        "x": 1.5,
        "label_color": (0.78, 0.86, 0.30, 1.0),
        "abilities": ["spore_glob", "slime_trail", "burst_puff"],
    },
    {
        "id": "rattle_bone_drudge",
        "name": "Rattle",
        "title": "Bone Drudge",
        "role": "skeleton skirmisher / bone toss",
        "source_reference": "Photo 5.jpg",
        "cutout": "rattle_bone_drudge_front.png",
        "height_m": 2.10,
        "collision_radius_m": 0.36,
        "x": 3.0,
        "label_color": (0.78, 0.94, 0.34, 1.0),
        "abilities": ["rust_slash", "grave_stumble", "bone_toss"],
    },
]


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
    roughness: float = 0.75,
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
            bsdf.inputs["Roughness"].default_value = 0.86
    return mat


def make_root(enemy: dict[str, object]) -> tuple[bpy.types.Collection, bpy.types.Object]:
    collection = bpy.data.collections.new(str(enemy["id"]))
    bpy.context.scene.collection.children.link(collection)
    root = bpy.data.objects.new(f"{enemy['id']}_root", None)
    root.empty_display_type = "PLAIN_AXES"
    root.location = (float(enemy["x"]), 0, 0)
    root["game_asset_id"] = enemy["id"]
    root["display_name"] = enemy["name"]
    root["title"] = enemy["title"]
    root["role"] = enemy["role"]
    root["target_height_m"] = enemy["height_m"]
    root["collision_radius_m"] = enemy["collision_radius_m"]
    collection.objects.link(root)
    return collection, root


def add_image_standee(
    enemy: dict[str, object],
    collection: bpy.types.Collection,
    root: bpy.types.Object,
) -> bpy.types.Object:
    image_path = REFERENCE_CUTOUT_ROOT / str(enemy["cutout"])
    image = bpy.data.images.load(str(image_path))
    aspect = image.size[0] / image.size[1]
    height = float(enemy["height_m"])
    width = height * aspect
    y = -0.72
    z0 = 0.02
    verts = [
        (-width / 2, y, z0),
        (width / 2, y, z0),
        (width / 2, y, z0 + height),
        (-width / 2, y, z0 + height),
    ]
    mesh = bpy.data.meshes.new(f"{enemy['id']}_standee_mesh")
    mesh.from_pydata(verts, [], [(0, 1, 2, 3)])
    mesh.update()
    mesh.uv_layers.new(name="UVMap")
    uv_data = mesh.uv_layers.active.data
    for uv, co in zip(uv_data, ((0, 0), (1, 0), (1, 1), (0, 1))):
        uv.uv = co

    obj = bpy.data.objects.new(f"{enemy['id']}_reference_matched_front_standee", mesh)
    obj.data.materials.append(make_image_material(f"{enemy['id']}_cutout_material", image_path))
    obj.parent = root
    obj["asset_layer"] = "reference_matched_cutout_standee"
    obj["game_asset_id"] = enemy["id"]
    obj["display_name"] = enemy["name"]
    obj["title"] = enemy["title"]
    obj["collision_radius_m"] = enemy["collision_radius_m"]
    collection.objects.link(obj)
    return obj


def add_label(
    enemy: dict[str, object],
    collection: bpy.types.Collection,
    root: bpy.types.Object,
    mat: bpy.types.Material,
) -> None:
    bpy.ops.object.text_add(location=(0, -0.93, 0.03), rotation=(math.radians(75), 0, 0))
    obj = bpy.context.object
    obj.name = f"label_{enemy['id']}"
    obj.data.body = str(enemy["name"]).upper()
    obj.data.align_x = "CENTER"
    obj.data.align_y = "CENTER"
    obj.data.size = 0.18
    obj.data.materials.append(mat)
    obj.parent = root
    collection.objects.link(obj)
    for src in list(obj.users_collection):
        if src != collection:
            src.objects.unlink(obj)


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    try:
        scene.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = 64
    scene.render.resolution_x = 2200
    scene.render.resolution_y = 1200
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("dark_enemy_batch2_preview_world")
    world.color = (0.030, 0.028, 0.034)
    scene.world = world

    bpy.ops.object.light_add(type="AREA", location=(0, -4.8, 6.2))
    key = bpy.context.object
    key.name = "large_softbox_key"
    key.data.energy = 760
    key.data.size = 5.7
    look_at(key, (0, 0, 1.2))

    bpy.ops.object.light_add(type="POINT", location=(-4.2, -2.8, 2.3))
    violet = bpy.context.object
    violet.name = "violet_batch2_rim_light"
    violet.data.energy = 95
    violet.data.color = (0.48, 0.16, 1.0)

    bpy.ops.object.light_add(type="POINT", location=(4.3, -2.8, 2.1))
    ember = bpy.context.object
    ember.name = "ember_batch2_rim_light"
    ember.data.energy = 90
    ember.data.color = (1.0, 0.30, 0.08)

    bpy.ops.object.camera_add(location=(0, -8.2, 3.4))
    camera = bpy.context.object
    camera.name = "enemy_batch2_preview_camera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4.25
    look_at(camera, (0, 0, 1.24))
    scene.camera = camera

    scene.view_settings.view_transform = "Filmic"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = 0
    scene.view_settings.gamma = 1
    scene.render.use_freestyle = False
    return camera


def set_camera(camera: bpy.types.Object, target_x: float, ortho_scale: float, output_path: Path) -> None:
    camera.location = (target_x, -8.2, 3.4)
    camera.data.ortho_scale = ortho_scale
    look_at(camera, (target_x, 0, 1.24))
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


def build_enemy(enemy: dict[str, object]) -> dict[str, object]:
    collection, root = make_root(enemy)
    label_mat = make_material(
        f"{enemy['id']}_label_glow",
        enemy["label_color"],
        roughness=0.45,
        emission=enemy["label_color"],
        emission_strength=0.9,
    )
    add_image_standee(enemy, collection, root)
    add_label(enemy, collection, root, label_mat)
    return enemy


def main() -> dict[str, object]:
    ensure_dirs()
    clear_scene()
    built = [build_enemy(enemy) for enemy in ENEMIES]
    camera = setup_scene()

    exported = {enemy["id"]: export_collection(str(enemy["id"])) for enemy in built}
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))

    render_preview(camera, COMBINED_PREVIEW_PATH, 0.0, 7.8)
    characters: list[dict[str, object]] = []
    for enemy in built:
        preview_path = PREVIEW_ROOT / f"{enemy['id']}.png"
        render_preview(camera, preview_path, float(enemy["x"]), 3.25)
        characters.append(
            {
                **enemy,
                "glb": exported[enemy["id"]],
                "preview": str(preview_path.relative_to(REPO_ROOT)).replace("\\", "/"),
                "notes": "Reference-matched transparent front-view standee GLB for immediate game use.",
            }
        )

    manifest = {
        "source_script": str((REPO_ROOT / "scripts" / "blender" / Path(__file__).name).relative_to(REPO_ROOT)).replace("\\", "/"),
        "blend": str(BLEND_PATH.relative_to(REPO_ROOT)).replace("\\", "/"),
        "preview": str(COMBINED_PREVIEW_PATH.relative_to(REPO_ROOT)).replace("\\", "/"),
        "style": "Halls-of-Torment enemy readability with anime/cartoon concept-sheet fidelity",
        "characters": characters,
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


if __name__ == "__main__":
    result = main()
    print(json.dumps(result, indent=2))
