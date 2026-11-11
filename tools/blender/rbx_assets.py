"""
Roblox向けローポリ3Dアセット生成パイプライン（Blender bpy / headless）

設計方針
- 1アセット = 1メッシュ = 1マテリアル = 1パレットテクスチャ（ドローコール最小・統一感）
- 面ごとにパレットの色セルへUVを寄せる「パレットアトラス方式」（頂点カラー非依存）
- 三角形数を予算内に収め、Roblox Studio 3D Importer 向けに FBX / GLB を出力
- プレビューPNG（Cycles CPU）を出力し、AIが見た目を自己確認できるようにする

使い方
  .venv/bin/python tools/blender/rbx_assets.py specs/example.json
  spec JSON: {"assets":[{"kind":"tree","name":"PineTree","seed":1,"params":{...}}], "out":"assets/out"}
"""
from __future__ import annotations

import json
import math
import os
import random
import sys
from dataclasses import dataclass

import bpy  # noqa: E402  bpy を先に import すると bmesh/mathutils が使えるようになる
import bmesh
from mathutils import Vector

# Roblox の MeshPart 上限（2026時点のドキュメント値。research/03 を参照し変更があれば更新）
ROBLOX_MAX_TRIS = 20_000
DEFAULT_TRI_BUDGET = 2_000  # 小物はこれ以下を推奨（モバイル比率が高いため）

# ---------------------------------------------------------------- palette
# 16行 x 8列 = 128色（256x256px, セル 32x16px）。行=色相系統、列=明度(0暗→7明)
PALETTE_COLS = 8
PALETTE_ROWS = 16
PALETTE_PX = 256  # Roblox テクスチャ上限は 4096（research/03 §4.1）。パレットは小さいほど軽い

# (名前, 色相, 彩度基準)  彩度0 = グレー系
PALETTE_ROW_DEFS = [
    ("red", 0.00, 0.85), ("orange", 0.07, 0.85), ("yellow", 0.14, 0.85), ("lime", 0.22, 0.80),
    ("green", 0.30, 0.80), ("teal", 0.47, 0.80), ("cyan", 0.53, 0.80), ("blue", 0.60, 0.80),
    ("indigo", 0.68, 0.75), ("purple", 0.78, 0.75), ("pink", 0.90, 0.70), ("gray", 0.0, 0.0),
    ("skin", 0.07, 0.40), ("earth", 0.08, 0.55), ("moss", 0.20, 0.45), ("slate", 0.60, 0.25),
]


def _hsv(h, s, v):
    import colorsys

    return colorsys.hsv_to_rgb(h % 1.0, max(0, min(1, s)), max(0, min(1, v)))


def build_palette():
    """名前付き色 -> (行, 列) と、テクスチャ用ピクセル配列（下の行から）。"""
    colors = {}
    pixels = [0.0] * (PALETTE_PX * PALETTE_PX * 4)
    cw, ch = PALETTE_PX // PALETTE_COLS, PALETTE_PX // PALETTE_ROWS
    for r, (hname, h, sat) in enumerate(PALETTE_ROW_DEFS):
        for c in range(PALETTE_COLS):
            v = 0.22 + 0.11 * c
            s = sat * (1.0 - 0.07 * c)
            rgb = _hsv(h, s, v)
            colors[f"{hname}{c}"] = (r, c)
            for y in range(r * ch, (r + 1) * ch):
                for x in range(c * cw, (c + 1) * cw):
                    i = (y * PALETTE_PX + x) * 4
                    pixels[i : i + 4] = [*rgb, 1.0]
    aliases = {
        "brown": "earth2", "darkbrown": "earth0", "wood": "earth4", "leaf": "green4",
        "leaflight": "lime5", "stone": "gray4", "darkstone": "gray2", "gold": "yellow6",
        "white": "gray7", "black": "gray0", "grass": "green5", "water": "cyan5",
    }
    for a, t in aliases.items():
        colors[a] = colors[t]
    return colors, pixels


PALETTE, _PALETTE_PIXELS = build_palette()


def palette_uv(name: str):
    if name not in PALETTE:
        raise KeyError(f"unknown palette color: {name}  (例: red5, gray3, wood, leaf)")
    r, c = PALETTE[name]
    u = (c + 0.5) / PALETTE_COLS
    v = (r + 0.5) / PALETTE_ROWS  # Blender の image.pixels は下の行から並ぶ
    return (u, v)


# ---------------------------------------------------------------- scene utils
def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scn = bpy.context.scene
    # 1 Blender unit = 1 stud として扱う（FBX書き出し時に scale を調整）
    scn.unit_settings.system = "METRIC"
    scn.unit_settings.scale_length = 1.0


def ensure_palette_material(out_dir: str):
    img_path = os.path.join(out_dir, "palette.png")
    img = bpy.data.images.get("palette")
    if img is None:
        img = bpy.data.images.new("palette", PALETTE_PX, PALETTE_PX, alpha=False)
        img.pixels = _PALETTE_PIXELS
        img.filepath_raw = img_path
        img.file_format = "PNG"
        img.save()
    mat = bpy.data.materials.get("Palette")
    if mat is None:
        mat = bpy.data.materials.new("Palette")
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = nt.nodes.get("Principled BSDF")
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = "Closest"  # 色セルの滲み防止
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.8
    return mat


class MeshBuilder:
    """bmesh に部品を積み上げ、面ごとに色を割り当てる。"""

    def __init__(self):
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")

    def _color_faces(self, faces, color):
        uv = palette_uv(color)
        for f in faces:
            for loop in f.loops:
                loop[self.uv].uv = uv

    def add_geom(self, geom_verts, color, jitter=0.0, rng=None):
        faces = list({f for v in geom_verts for f in v.link_faces})
        if jitter and rng:
            for v in geom_verts:
                v.co += Vector((rng.uniform(-jitter, jitter) for _ in range(3)))
        self._color_faces(faces, color)
        return faces

    def cone(self, loc, r1, r2, depth, segs, color, rot_z=0.0, jitter=0.0, rng=None):
        res = bmesh.ops.create_cone(
            self.bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=depth
        )
        verts = res["verts"]
        bmesh.ops.rotate(self.bm, verts=verts, cent=(0, 0, 0), matrix=_rotz(rot_z))
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(loc) + Vector((0, 0, depth / 2)))
        return self.add_geom(verts, color, jitter, rng)

    def ico(self, loc, radius, subdiv, color, scale=(1, 1, 1), jitter=0.0, rng=None):
        res = bmesh.ops.create_icosphere(self.bm, subdivisions=subdiv, radius=radius)
        verts = res["verts"]
        bmesh.ops.scale(self.bm, verts=verts, vec=scale)
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(loc))
        return self.add_geom(verts, color, jitter, rng)

    def uvsphere(self, loc, radius, segs, rings, color, scale=(1, 1, 1)):
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=radius)
        verts = res["verts"]
        bmesh.ops.scale(self.bm, verts=verts, vec=scale)
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(loc))
        return self.add_geom(verts, color)

    def box(self, loc, size, color, bevel=0.0):
        res = bmesh.ops.create_cube(self.bm, size=1.0)
        verts = res["verts"]
        bmesh.ops.scale(self.bm, verts=verts, vec=size)
        bmesh.ops.translate(self.bm, verts=verts, vec=Vector(loc))
        if bevel > 0:
            edges = list({e for v in verts for e in v.link_edges})
            bmesh.ops.bevel(self.bm, geom=edges, offset=bevel, segments=1, affect="EDGES", profile=0.5)
            verts = [v for v in self.bm.verts if _inside_box(v.co, loc, size, bevel)]
        return self.add_geom(verts, color)

    def to_object(self, name: str, mat):
        me = bpy.data.meshes.new(name)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        self.bm.to_mesh(me)
        self.bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        me.materials.append(mat)
        for p in me.polygons:
            p.use_smooth = False  # フラットシェーディング（ローポリ表現）
        return obj


def _rotz(a):
    from mathutils import Matrix

    return Matrix.Rotation(a, 3, "Z")


def _inside_box(co, loc, size, pad):
    return all(abs(co[i] - loc[i]) <= size[i] / 2 + pad + 1e-4 for i in range(3))


# ---------------------------------------------------------------- generators
def gen_tree(b: MeshBuilder, rng, p):
    h = p.get("height", 6.0)
    layers = p.get("layers", 3)
    leaf = p.get("leaf", "leaf")
    b.cone((0, 0, 0), 0.35, 0.25, h * 0.35, 6, p.get("trunk", "wood"))
    for i in range(layers):
        t = i / max(1, layers - 1)
        r = (1.0 - 0.55 * t) * p.get("radius", 2.0)
        z = h * 0.25 + i * h * 0.22
        shade = leaf if i % 2 == 0 else p.get("leaf2", "leaflight")
        b.cone((0, 0, z), r, 0.0 if i == layers - 1 else r * 0.35, h * 0.32, 7, shade,
               rot_z=rng.uniform(0, 1), jitter=0.12, rng=rng)


def gen_round_tree(b, rng, p):
    h = p.get("height", 5.0)
    b.cone((0, 0, 0), 0.35, 0.28, h * 0.5, 6, p.get("trunk", "wood"))
    for _ in range(p.get("blobs", 3)):
        off = (rng.uniform(-0.8, 0.8), rng.uniform(-0.8, 0.8), h * 0.55 + rng.uniform(0, 1.2))
        b.ico(off, rng.uniform(1.2, 1.8), 1, rng.choice([p.get("leaf", "leaf"), "leaflight"]),
              jitter=0.15, rng=rng)


def gen_rock(b, rng, p):
    s = p.get("size", 2.0)
    b.ico((0, 0, s * 0.35), s * 0.6, 1, p.get("color", "stone"),
          scale=(1.0, rng.uniform(0.7, 1.0), rng.uniform(0.5, 0.8)), jitter=s * 0.12, rng=rng)


def gen_crystal(b, rng, p):
    col = p.get("color", "purple5")
    for i in range(p.get("count", 4)):
        a = i / p.get("count", 4) * math.tau + rng.uniform(-0.3, 0.3)
        d = 0 if i == 0 else rng.uniform(0.3, 0.7)
        hgt = rng.uniform(1.0, 2.4) if i else 2.8
        # 先細りの六角柱（傾けずに簡潔に）
        b.cone((math.cos(a) * d, math.sin(a) * d, 0), 0.35, 0.0, hgt, 5,
               col if i % 2 == 0 else col[:-1] + "7")


def gen_crate(b, rng, p):
    s = p.get("size", 2.0)
    b.box((0, 0, s / 2), (s, s, s), p.get("color", "wood"), bevel=s * 0.06)
    # 補強の帯
    for z in (0.15, 0.85):
        b.box((0, 0, s * z), (s * 1.02, s * 1.02, s * 0.12), "darkbrown")


def gen_coin(b, rng, p):
    r = p.get("radius", 1.0)
    faces = b.cone((0, 0, 0), r, r, r * 0.25, 16, p.get("color", "gold"))
    # 縦向きに立てる
    verts = list({v for f in faces for v in f.verts})
    from mathutils import Matrix

    bmesh.ops.rotate(b.bm, verts=verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 3, "X"))
    bmesh.ops.translate(b.bm, verts=verts, vec=(0, r * 0.125, r))


def gen_egg(b, rng, p):
    """ガチャ用の卵。spots で模様。"""
    h = p.get("height", 2.4)
    b.uvsphere((0, 0, h / 2), h / 2, 12, 8, p.get("color", "yellow6"), scale=(0.78, 0.78, 1.0))
    for _ in range(p.get("spots", 5)):
        th, ph = rng.uniform(0, math.tau), rng.uniform(0.6, 2.4)
        pos = (0.78 * h / 2 * math.sin(ph) * math.cos(th), 0.78 * h / 2 * math.sin(ph) * math.sin(th),
               h / 2 + h / 2 * math.cos(ph))
        b.ico(pos, h * 0.09, 0, p.get("spot", "pink5"))


def gen_pet(b, rng, p):
    """丸いマスコット系ペット（ペットシミュ系のベース体型）。"""
    body = p.get("color", "pink5")
    b.uvsphere((0, 0, 1.0), 1.0, 12, 8, body, scale=(1.0, 0.9, 0.9))
    for sx in (-1, 1):
        b.uvsphere((sx * 0.38, -0.8, 1.2), 0.17, 8, 6, "black")  # 目
        b.uvsphere((sx * 0.42, -0.92, 1.25), 0.06, 6, 4, "white")  # ハイライト
        b.cone((sx * 0.55, 0, 1.6), 0.28, 0.0, 0.6, 5, body)  # 耳
        b.uvsphere((sx * 0.55, -0.2, 0.15), 0.25, 8, 6, body[:-1] + "3")  # 足
    b.uvsphere((0, -0.88, 0.9), 0.1, 6, 4, "red4")  # 口


def gen_mushroom(b, rng, p):
    b.cone((0, 0, 0), 0.3, 0.25, 0.9, 7, "white")
    b.uvsphere((0, 0, 0.95), 0.8, 10, 5, p.get("color", "red5"), scale=(1, 1, 0.6))
    for _ in range(5):
        a = rng.uniform(0, math.tau)
        b.ico((math.cos(a) * 0.5, math.sin(a) * 0.5, 1.2), 0.1, 0, "white")


def gen_fence(b, rng, p):
    n = p.get("posts", 4)
    gap = p.get("gap", 2.0)
    for i in range(n):
        b.box((i * gap, 0, 0.75), (0.3, 0.3, 1.5), "wood", bevel=0.03)
    L = (n - 1) * gap
    for z in (0.5, 1.1):
        b.box((L / 2, 0, z), (L + 0.3, 0.15, 0.25), "brown")


GENERATORS = {
    "tree": gen_tree,
    "round_tree": gen_round_tree,
    "rock": gen_rock,
    "crystal": gen_crystal,
    "crate": gen_crate,
    "coin": gen_coin,
    "egg": gen_egg,
    "pet": gen_pet,
    "mushroom": gen_mushroom,
    "fence": gen_fence,
}


# ---------------------------------------------------------------- validate / export
def tri_count(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def enforce_budget(obj, budget: int):
    tris = tri_count(obj)
    if tris > budget:
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = budget / tris
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return tri_count(obj)


def ground_and_center(obj):
    """原点を底面中央へ（Robloxで置きやすくする）。"""
    me = obj.data
    xs = [v.co.x for v in me.vertices]
    ys = [v.co.y for v in me.vertices]
    zs = [v.co.z for v in me.vertices]
    off = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, min(zs)))
    for v in me.vertices:
        v.co -= off
    return Vector((max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs)))


def export(obj, out_dir: str, name: str):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    fbx = os.path.join(out_dir, f"{name}.fbx")
    glb = os.path.join(out_dir, f"{name}.glb")
    # 1 Blender unit = 1 stud。Studio 3D Importer の "Scale Unit" で Stud を選ぶ（research/03 参照）
    bpy.ops.export_scene.fbx(filepath=fbx, use_selection=True, global_scale=1.0,
                             apply_unit_scale=True, apply_scale_options="FBX_SCALE_UNITS",
                             axis_forward="-Z", axis_up="Y", path_mode="COPY", embed_textures=True,
                             mesh_smooth_type="FACE")
    bpy.ops.export_scene.gltf(filepath=glb, use_selection=True, export_format="GLB")
    return fbx, glb


def render_preview(obj, out_png: str, size: int = 512):
    scn = bpy.context.scene
    dims = obj.dimensions
    radius = max(dims) * 0.9 + 0.5
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    scn.collection.objects.link(cam)
    cam.location = (radius * 1.4, -radius * 1.8, dims.z * 0.6 + radius * 0.9)
    target = Vector((0, 0, dims.z * 0.45))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scn.camera = cam
    sun_d = bpy.data.lights.new("sun", "SUN")
    sun_d.energy = 4.0
    sun = bpy.data.objects.new("sun", sun_d)
    sun.rotation_euler = (math.radians(50), 0, math.radians(30))
    scn.collection.objects.link(sun)
    world = bpy.data.worlds.new("w")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.85, 1.0, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.8
    scn.world = world
    scn.view_settings.view_transform = "Standard"  # Roblox上の見た目に近い発色
    scn.render.engine = "CYCLES"
    scn.cycles.device = "CPU"
    scn.cycles.samples = 24
    scn.render.resolution_x = scn.render.resolution_y = size
    scn.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    for o in (cam, sun):
        bpy.data.objects.remove(o)


@dataclass
class Result:
    name: str
    kind: str
    tris: int
    size_studs: tuple
    fbx: str
    glb: str
    preview: str | None


def build_asset(spec: dict, out_dir: str, preview: bool = True) -> Result:
    reset_scene()
    mat = ensure_palette_material(out_dir)
    rng = random.Random(spec.get("seed", 0))
    b = MeshBuilder()
    GENERATORS[spec["kind"]](b, rng, spec.get("params", {}))
    obj = b.to_object(spec["name"], mat)
    budget = min(spec.get("tri_budget", DEFAULT_TRI_BUDGET), ROBLOX_MAX_TRIS)
    tris = enforce_budget(obj, budget)
    size = ground_and_center(obj)
    scale = spec.get("scale", 1.0)
    if scale != 1.0:
        obj.scale = (scale,) * 3
        bpy.ops.object.transform_apply(scale=True)
        size = size * scale
    fbx, glb = export(obj, out_dir, spec["name"])
    png = None
    if preview:
        png = os.path.join(out_dir, f"{spec['name']}.png")
        render_preview(obj, png)
    return Result(spec["name"], spec["kind"], tris, tuple(round(x, 2) for x in size), fbx, glb, png)


def main(argv):
    if not argv:
        print(__doc__)
        print("kinds:", ", ".join(GENERATORS))
        return 1
    spec = json.load(open(argv[0], encoding="utf-8"))
    out_dir = os.path.abspath(spec.get("out", "assets/out"))
    os.makedirs(out_dir, exist_ok=True)
    no_preview = "--no-preview" in argv
    results = []
    for a in spec["assets"]:
        r = build_asset(a, out_dir, preview=not no_preview)
        results.append(r.__dict__)
        print(f"[ok] {r.name:<16} kind={r.kind:<10} tris={r.tris:<6} size(studs)={r.size_studs}")
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
