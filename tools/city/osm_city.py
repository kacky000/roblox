"""
実在都市の街区を OpenStreetMap から Roblox 用メッシュに変換する試作ツール（標準ライブラリのみ・Blender 不要）

何をするか
  1. Overpass API から範囲内の建物（footprint・高さ・階数）と道路・線路・水域・緑地を取得する（結果はキャッシュ）
  2. 緯度経度を中心からのローカル座標（studs、1 stud = 0.28 m。--scale で縮尺変更）に投影する
  3. 建物は「外周の壁 + 耳切り法で三角形分割した屋根」に押し出し、道路は幅つきの帯にする
  4. グリッド（--chunk studs）ごとに 1 メッシュへまとめ、MeshPart 上限（20,000 tris）を超えたら分割する
  5. OBJ（パレット UV 付き。assets/sample_pack/palette.png と同じ配色規則）、manifest.json、上面図 SVG を出力する

使い方
  python tools/city/osm_city.py --name shibuya --bbox 35.6560,139.6960,35.6620,139.7050
  python tools/city/osm_city.py --name shibuya --bbox ... --scale 0.5 --chunk 512
  bbox は south,west,north,east（Overpass と同じ順）

ライセンス
  出力は OpenStreetMap のデータから作った派生物（ODbL 1.0）。ゲーム内とストアページに
  「© OpenStreetMap contributors」のクレジットを表示すること。詳細は research/05 を参照。
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import sys
import time
import urllib.parse
import urllib.request

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
USER_AGENT = "roblox-city-prototype/0.1 (OSM import test)"
METERS_PER_STUD = 0.28  # docs/roblox-creator-docs/physics/units.md
ROBLOX_MAX_TRIS = 20_000
TRI_BUDGET_PER_MESH = 18_000  # 上限ぎりぎりを避ける

# パレット（tools/blender/rbx_assets.py と同じ 16 行 x 8 列。行=色相系統、列=明度）
PALETTE_ROWS = {
    "red": 0, "orange": 1, "yellow": 2, "lime": 3, "green": 4, "teal": 5, "cyan": 6, "blue": 7,
    "indigo": 8, "purple": 9, "pink": 10, "gray": 11, "skin": 12, "earth": 13, "moss": 14, "slate": 15,
}


def palette_uv(name: str) -> tuple[float, float]:
    row = "".join(ch for ch in name if not ch.isdigit())
    col = int(name[len(row):])
    return ((col + 0.5) / 8, (PALETTE_ROWS[row] + 0.5) / 16)


# 建物用途ごとの壁色候補（同じ建物は ID から決定的に選ぶ）
WALL_COLORS = {
    "commercial": ["gray6", "slate6", "gray5", "slate5", "skin6"],
    "residential": ["skin6", "earth6", "gray6", "skin5", "earth5"],
    "station": ["slate4", "gray4"],
    "default": ["gray6", "gray5", "slate6", "skin6", "earth6", "slate5"],
}
ROOF_COLORS = ["gray3", "gray4", "slate3", "slate4"]
ROAD_STYLE = {  # highway 種別 -> (幅 m, 色)
    "motorway": (16, "gray1"), "trunk": (14, "gray1"), "primary": (12, "gray1"),
    "secondary": (10, "gray2"), "tertiary": (8, "gray2"), "residential": (6, "gray2"),
    "unclassified": (6, "gray2"), "service": (4, "gray3"), "living_street": (5, "gray3"),
    "pedestrian": (6, "gray4"), "footway": (2.5, "gray4"), "steps": (2.5, "gray4"),
}
RAIL_STYLE = (4, "earth1")


# ---------------------------------------------------------------- fetch
def overpass_query(bbox: str) -> str:
    return f"""[out:json][timeout:120];
(
  way["building"]({bbox});
  way["highway"]({bbox});
  way["railway"~"^(rail|subway|light_rail)$"]({bbox});
  way["natural"="water"]({bbox});
  way["leisure"="park"]({bbox});
  way["landuse"="grass"]({bbox});
);
out body geom;"""


def fetch_osm(bbox: str, cache_path: str) -> dict:
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            return json.load(f)
    data = urllib.parse.urlencode({"data": overpass_query(bbox)}).encode()
    req = urllib.request.Request(OVERPASS_URL, data=data, headers={"User-Agent": USER_AGENT})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                raw = json.load(r)
            break
        except Exception as e:  # Overpass は混雑時に 429/504 を返す
            if attempt == 2:
                raise
            print(f"  overpass error ({e}); retry in {10 * (attempt + 1)}s", file=sys.stderr)
            time.sleep(10 * (attempt + 1))
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    with open(cache_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(raw, f)
    return raw


# ---------------------------------------------------------------- geometry
class Projector:
    """中心からの等距円筒投影。数 km 四方なら誤差は無視できる。Roblox は +X 東、-Z 北とする。"""

    def __init__(self, lat0: float, lon0: float, scale: float):
        self.lat0, self.lon0 = lat0, lon0
        self.mx = 111_320.0 * math.cos(math.radians(lat0))
        self.my = 110_540.0
        self.k = scale / METERS_PER_STUD  # m -> studs

    def __call__(self, lat: float, lon: float) -> tuple[float, float]:
        return ((lon - self.lon0) * self.mx * self.k, -(lat - self.lat0) * self.my * self.k)


def signed_area(poly):
    a = 0.0
    for i in range(len(poly)):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % len(poly)]
        a += x1 * z2 - x2 * z1
    return a / 2


def clean_ring(pts):
    out = []
    for p in pts:
        if not out or (abs(p[0] - out[-1][0]) > 1e-3 or abs(p[1] - out[-1][1]) > 1e-3):
            out.append(p)
    if len(out) > 1 and abs(out[0][0] - out[-1][0]) < 1e-3 and abs(out[0][1] - out[-1][1]) < 1e-3:
        out.pop()
    return out


def ear_clip(poly):
    """単純多角形（穴なし）の三角形分割。poly は signed_area>0 の向きに揃えて渡す。"""
    n = len(poly)
    if n < 3:
        return []
    idx = list(range(n))
    tris = []

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    def inside(p, a, b, c):
        return cross(a, b, p) >= 0 and cross(b, c, p) >= 0 and cross(c, a, p) >= 0

    guard = 0
    while len(idx) > 3 and guard < n * n:
        guard += 1
        found = False
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = poly[i0], poly[i1], poly[i2]
            if cross(a, b, c) <= 1e-9:
                continue
            if any(inside(poly[j], a, b, c) for j in idx if j not in (i0, i1, i2)):
                continue
            tris.append((i0, i1, i2))
            idx.pop(k)
            found = True
            break
        if not found:  # 自己交差など。扇形でごまかす
            break
    if len(idx) >= 3:
        for k in range(1, len(idx) - 1):
            tris.append((idx[0], idx[k], idx[k + 1]))
    return tris


class Mesh:
    def __init__(self):
        self.v: list[tuple[float, float, float]] = []
        self.vt: list[tuple[float, float]] = []
        self.f: list[tuple[int, int, int, int]] = []  # (v1,v2,v3,uv) 0-based

    @property
    def tris(self):
        return len(self.f)

    def _uv(self, color):
        self.vt.append(palette_uv(color))
        return len(self.vt) - 1

    def add_tri(self, a, b, c, color):
        base = len(self.v)
        self.v.extend([a, b, c])
        uv = self._uv(color)
        self.f.append((base, base + 1, base + 2, uv))

    def add_quad(self, a, b, c, d, color):
        self.add_tri(a, b, c, color)
        self.add_tri(a, c, d, color)


def building_height_m(tags: dict, rng: int) -> float:
    for key in ("height", "building:height"):
        if key in tags:
            try:
                return max(3.0, float(tags[key].replace("m", "").strip()))
            except ValueError:
                pass
    if "building:levels" in tags:
        try:
            return max(3.0, float(tags["building:levels"]) * 3.2)
        except ValueError:
            pass
    return 9.0 + (rng % 4) * 3.2  # 不明なら 3〜6 階程度（決定的なばらつき）


def emit_building(mesh: Mesh, ring, h: float, wall: str, roof: str):
    """ring: signed_area>0 にした多角形（studs）。Roblox は Y 上。"""
    n = len(ring)
    for i in range(n):
        x1, z1 = ring[i]
        x2, z2 = ring[(i + 1) % n]
        # 法線が外を向く巻き順（OBJ は反時計回りが表）
        mesh.add_quad((x1, 0, z1), (x1, h, z1), (x2, h, z2), (x2, 0, z2), wall)
    for i0, i1, i2 in ear_clip(ring):
        a, b, c = ring[i0], ring[i1], ring[i2]
        mesh.add_tri((a[0], h, a[1]), (c[0], h, c[1]), (b[0], h, b[1]), roof)


def emit_strip(mesh: Mesh, line, width: float, y: float, color: str):
    hw = width / 2
    for i in range(len(line) - 1):
        (x1, z1), (x2, z2) = line[i], line[i + 1]
        dx, dz = x2 - x1, z2 - z1
        L = math.hypot(dx, dz)
        if L < 1e-3:
            continue
        nx, nz = -dz / L * hw, dx / L * hw
        mesh.add_quad((x1 + nx, y, z1 + nz), (x2 + nx, y, z2 + nz), (x2 - nx, y, z2 - nz), (x1 - nx, y, z1 - nz), color)


def emit_flat(mesh: Mesh, ring, y: float, color: str):
    for i0, i1, i2 in ear_clip(ring):
        a, b, c = ring[i0], ring[i1], ring[i2]
        mesh.add_tri((a[0], y, a[1]), (c[0], y, c[1]), (b[0], y, b[1]), color)


# ---------------------------------------------------------------- main
def pick(seq, key: int):
    return seq[key % len(seq)]


def flat(pts) -> list[float]:
    return [round(c, 1) for p in pts for c in p]


def write_data_module(path, rows, manifest):
    """B 方式（tools/city/CityBuilder.luau）用の ModuleScript。
    buildings: {高さ, x1, z1, x2, z2, ...}（反時計回り）、roads/rails: {幅, x1, z1, ...}、areas: {種類(1水/2緑), x1, z1, ...}"""

    def fmt(v: float) -> str:
        return str(int(v)) if v == int(v) else f"{v:.1f}"

    lines = [
        "--!strict",
        f"-- {manifest['name']}: tools/city/osm_city.py が自動生成。手で編集しない",
        f"-- {manifest['attribution']}。このデータは OSM の派生データベースなので ODbL 1.0 で提供すること",
        "return {",
        f'\tname = "{manifest["name"]}",',
        f"\tscale = {manifest['scale']},",
        f'\tattribution = "{manifest["attribution"]}",',
    ]
    for key in ("buildings", "roads", "rails", "areas"):
        lines.append(f"\t{key} = {{")
        for r in rows[key]:
            lines.append("\t\t{ " + ", ".join(fmt(v) for v in r) + " },")
        lines.append("\t},")
    lines.append("}")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--name", required=True)
    ap.add_argument("--bbox", required=True, help="south,west,north,east")
    ap.add_argument("--out", default=None, help="出力先（既定 assets/city/<name>）")
    ap.add_argument("--scale", type=float, default=1.0, help="縮尺。0.5 なら実寸の半分（移動時間を短くしたいとき）")
    ap.add_argument("--chunk", type=float, default=512.0, help="チャンク一辺（studs）")
    a = ap.parse_args(argv)
    if hasattr(sys.stdout, "reconfigure"):  # Windows の cp932 コンソール対策
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    out = a.out or os.path.join(root, "assets", "city", a.name)
    os.makedirs(out, exist_ok=True)
    s, w, n, e = (float(x) for x in a.bbox.split(","))
    bbox = f"{s},{w},{n},{e}"

    print(f"▶ fetch OSM {bbox}")
    raw = fetch_osm(bbox, os.path.join(out, "osm_cache.json"))
    proj = Projector((s + n) / 2, (w + e) / 2, a.scale)
    k = proj.k  # m -> studs

    chunks: dict[tuple[int, int], list[Mesh]] = {}
    # B 方式（実行時生成）用の軽量データ。座標は 0.1 studs に丸める
    data_rows: dict[str, list[list[float]]] = {"buildings": [], "roads": [], "rails": [], "areas": []}
    stats = {"buildings": 0, "roads": 0, "rails": 0, "areas": 0, "skipped": 0, "max_height_m": 0.0}
    svg_items = []

    bx0, bz1 = proj(s, w)  # 南西 -> (x 最小, z 最大)
    bx1, bz0 = proj(n, e)

    def inside(p) -> bool:
        return bx0 <= p[0] <= bx1 and bz0 <= p[1] <= bz1

    def clip_runs(line):
        """範囲外まで伸びる道路・線路を、範囲内に端点がある区間だけの連続列に切る。"""
        runs, cur = [], []
        for i in range(len(line) - 1):
            if inside(line[i]) or inside(line[i + 1]):
                if not cur:
                    cur = [line[i]]
                cur.append(line[i + 1])
            elif cur:
                runs.append(cur)
                cur = []
        if cur:
            runs.append(cur)
        return runs

    def mesh_for(cx: float, cz: float) -> Mesh:
        key = (math.floor(cx / a.chunk), math.floor(cz / a.chunk))
        lst = chunks.setdefault(key, [Mesh()])
        if lst[-1].tris > TRI_BUDGET_PER_MESH:
            lst.append(Mesh())
        return lst[-1]

    for el in raw.get("elements", []):
        if el.get("type") != "way" or "geometry" not in el:
            continue
        tags = el.get("tags", {})
        pts = [proj(g["lat"], g["lon"]) for g in el["geometry"]]
        hid = int(hashlib.md5(str(el["id"]).encode()).hexdigest()[:8], 16)
        if "building" in tags:
            ring = clean_ring(pts)
            if len(ring) < 3 or abs(signed_area(ring)) < 1.0:
                stats["skipped"] += 1
                continue
            if not inside((sum(p[0] for p in ring) / len(ring), sum(p[1] for p in ring) / len(ring))):
                continue
            if signed_area(ring) < 0:
                ring.reverse()
            hm = building_height_m(tags, hid)
            stats["max_height_m"] = max(stats["max_height_m"], hm)
            kind = tags.get("building")
            if kind in ("commercial", "retail", "office"):
                palette = WALL_COLORS["commercial"]
            elif kind in ("residential", "apartments", "house"):
                palette = WALL_COLORS["residential"]
            elif kind in ("train_station", "transportation"):
                palette = WALL_COLORS["station"]
            else:
                palette = WALL_COLORS["default"]
            cx = sum(p[0] for p in ring) / len(ring)
            cz = sum(p[1] for p in ring) / len(ring)
            emit_building(mesh_for(cx, cz), ring, hm * k, pick(palette, hid), pick(ROOF_COLORS, hid >> 3))
            data_rows["buildings"].append([round(hm * k, 1), *flat(ring)])
            stats["buildings"] += 1
            svg_items.append(("b", ring, hm))
        elif "highway" in tags:
            wm, col = ROAD_STYLE.get(tags["highway"], (0, None))
            if not col or len(pts) < 2:
                continue
            for run in clip_runs(pts):
                emit_strip(mesh_for(*run[len(run) // 2]), run, wm * k, 0.15, col)
                svg_items.append(("r", run, wm * k))
                data_rows["roads"].append([round(wm * k, 1), *flat(run)])
            stats["roads"] += 1
        elif "railway" in tags:
            for run in clip_runs(pts):
                emit_strip(mesh_for(*run[len(run) // 2]), run, RAIL_STYLE[0] * k, 0.25, RAIL_STYLE[1])
                svg_items.append(("l", run, RAIL_STYLE[0] * k))
                data_rows["rails"].append([round(RAIL_STYLE[0] * k, 1), *flat(run)])
            stats["rails"] += 1
        else:
            ring = clean_ring(pts)
            if len(ring) < 3:
                continue
            if signed_area(ring) < 0:
                ring.reverse()
            col = "cyan4" if tags.get("natural") == "water" else "green4"
            cx = sum(p[0] for p in ring) / len(ring)
            cz = sum(p[1] for p in ring) / len(ring)
            if not inside((cx, cz)):
                continue
            emit_flat(mesh_for(cx, cz), ring, 0.08, col)
            data_rows["areas"].append([1 if col.startswith("cyan") else 2, *flat(ring)])
            stats["areas"] += 1
            svg_items.append(("w" if col.startswith("cyan") else "g", ring, 0))

    # ---- write OBJ per chunk (頂点はチャンク原点からの相対座標。MeshPart の Position = 原点 + バウンディング中心)
    with open(os.path.join(out, "city.mtl"), "w", encoding="utf-8", newline="\n") as f:
        f.write("newmtl palette\nKd 1 1 1\nmap_Kd palette.png\n")
    manifest = {"name": a.name, "bbox": [s, w, n, e], "scale": a.scale, "metersPerStud": METERS_PER_STUD,
                "chunkSize": a.chunk, "attribution": "© OpenStreetMap contributors (ODbL 1.0)", "meshes": []}
    total_tris = 0
    for (ci, cj), meshes in sorted(chunks.items()):
        for mi, m in enumerate(meshes):
            if m.tris == 0:
                continue
            ox, oz = ci * a.chunk, cj * a.chunk
            fname = f"chunk_{ci}_{cj}_{mi}.obj"
            xs = [v[0] for v in m.v]; ys = [v[1] for v in m.v]; zs = [v[2] for v in m.v]
            with open(os.path.join(out, fname), "w", encoding="utf-8", newline="\n") as f:
                f.write(f"# {a.name} chunk ({ci},{cj}) part {mi} — © OpenStreetMap contributors\nmtllib city.mtl\nusemtl palette\n")
                for x, y, z in m.v:
                    f.write(f"v {x - ox:.3f} {y:.3f} {z - oz:.3f}\n")
                for u, v in m.vt:
                    f.write(f"vt {u:.5f} {v:.5f}\n")
                for a1, b1, c1, uv in m.f:
                    f.write(f"f {a1 + 1}/{uv + 1} {b1 + 1}/{uv + 1} {c1 + 1}/{uv + 1}\n")
            total_tris += m.tris
            assert m.tris <= ROBLOX_MAX_TRIS, fname
            manifest["meshes"].append({
                "file": fname, "chunk": [ci, cj], "origin": [ox, 0, oz], "tris": m.tris,
                "boundsMin": [min(xs), min(ys), min(zs)], "boundsMax": [max(xs), max(ys), max(zs)],
            })
    manifest["stats"] = {**stats, "meshes": len(manifest["meshes"]), "tris": total_tris}
    with open(os.path.join(out, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)

    # ---- palette.png をコピー（OBJ のテクスチャ参照用）
    pal = os.path.join(root, "assets", "sample_pack", "palette.png")
    if os.path.exists(pal):
        with open(pal, "rb") as src, open(os.path.join(out, "palette.png"), "wb") as dst:
            dst.write(src.read())

    write_place_script(os.path.join(out, "place_chunks.luau"), manifest)
    write_data_module(os.path.join(out, "city_data.luau"), data_rows, manifest)
    write_svg(os.path.join(out, "preview.svg"), svg_items, a.name, manifest["stats"])
    write_iso_svg(os.path.join(out, "preview_iso.svg"), chunks, a.name)
    print(json.dumps(manifest["stats"], ensure_ascii=False))
    print(f"✅ {len(manifest['meshes'])} meshes → {out}")


def write_svg(path, items, name, stats):
    xs = [p[0] for _, pts, _ in items for p in pts] or [0]
    zs = [p[1] for _, pts, _ in items for p in pts] or [0]
    x0, x1, z0, z1 = min(xs), max(xs), min(zs), max(zs)
    W = 1000
    sc = W / max(1e-6, x1 - x0)
    H = int((z1 - z0) * sc) + 40
    hmax = max([h for t, _, h in items if t == "b"] or [1])
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" style="background:#f4f5f1">']
    order = {"g": 0, "w": 1, "r": 2, "l": 3, "b": 4}
    for t, pts, val in sorted(items, key=lambda it: order[it[0]]):
        d = " ".join(f"{(x - x0) * sc:.1f},{(z - z0) * sc:.1f}" for x, z in pts)
        if t == "b":
            g = int(220 - 170 * min(1.0, val / hmax))
            out.append(f'<polygon points="{d}" fill="rgb({g},{g},{min(255, g + 20)})" stroke="#555" stroke-width="0.3"/>')
        elif t in ("g", "w"):
            out.append(f'<polygon points="{d}" fill="{"#a8d5a2" if t == "g" else "#9cc9e8"}"/>')
        else:
            col = "#c9c9c9" if t == "r" else "#8a5a3c"
            out.append(f'<polyline points="{d}" fill="none" stroke="{col}" stroke-width="{max(0.6, val * sc):.1f}"/>')
    out.append(f'<text x="8" y="{H - 12}" font-size="14" font-family="sans-serif">{name}: '
               f'{stats["buildings"]} buildings, {stats["tris"]:,} tris, {stats["meshes"]} meshes — © OpenStreetMap contributors</text>')
    out.append("</svg>")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


def write_place_script(path, manifest):
    """3D Importer で OBJ を一括インポートした後、Studio のコマンドバーで実行して各チャンクを正しい位置に並べる。
    インポーターはメッシュの中心をピボットにするので、位置 = チャンク原点 + バウンディング中心。"""
    rows = []
    for m in manifest["meshes"]:
        name = m["file"].removesuffix(".obj")
        c = [m["origin"][i] + (m["boundsMin"][i] + m["boundsMax"][i]) / 2 for i in range(3)]
        rows.append(f'\t["{name}"] = Vector3.new({c[0]:.3f}, {c[1]:.3f}, {c[2]:.3f}),')
    body = "\n".join(rows)
    src = f"""--!strict
-- {manifest["name"]}: OBJ を Workspace にインポートした後、コマンドバーに貼って実行する（自動生成）
-- {manifest["attribution"]} — ゲーム内とストアページにクレジットを表示すること
local POS: {{ [string]: Vector3 }} = {{
{body}
}}
local folder = workspace:FindFirstChild("City_{manifest["name"]}") or Instance.new("Folder")
folder.Name = "City_{manifest["name"]}"
folder.Parent = workspace
local placed = 0
for _, inst in workspace:GetDescendants() do
	local pos = POS[inst.Name]
	if pos and inst:IsA("MeshPart") then
		inst.Anchored = true
		inst.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
		inst.Position = pos
		inst.Parent = folder
		placed += 1
	end
end
print(("placed %d / %d chunks"):format(placed, {len(rows)}))
"""
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(src)


def write_iso_svg(path, chunks, name, W=1400):
    """生成したメッシュそのものを等角投影で描く（画家のアルゴリズム＋簡易ライティング）。AI の目視確認用。"""
    tris = []
    light = (0.45, 0.8, -0.35)
    ln = math.sqrt(sum(c * c for c in light))
    light = tuple(c / ln for c in light)
    ang = math.radians(30)
    ca, sa = math.cos(math.radians(45)), math.sin(math.radians(45))
    for meshes in chunks.values():
        for m in meshes:
            for i1, i2, i3, uv in m.f:
                p = [m.v[i1], m.v[i2], m.v[i3]]
                ux, uy, uz = (p[1][j] - p[0][j] for j in range(3))
                vx, vy, vz = (p[2][j] - p[0][j] for j in range(3))
                nx, ny, nz = uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx
                nl = math.sqrt(nx * nx + ny * ny + nz * nz) or 1
                shade = 0.55 + 0.45 * abs((nx * light[0] + ny * light[1] + nz * light[2]) / nl)
                u, v = m.vt[uv]
                col, row = int(u * 8), int(v * 16)
                base = 0.22 + 0.11 * col
                tint = {11: (1, 1, 1), 15: (0.92, 0.95, 1.05), 12: (1.08, 0.98, 0.9), 13: (1.05, 0.95, 0.85),
                        4: (0.6, 1.1, 0.6), 6: (0.6, 0.9, 1.15), 0: (1.2, 0.5, 0.5)}.get(row, (1, 1, 1))
                rgb = tuple(int(max(0, min(255, 255 * base * t * shade))) for t in tint)
                scr = []
                depth = 0.0
                for x, y, z in p:
                    rx, rz = x * ca - z * sa, x * sa + z * ca  # 45°回転
                    scr.append((rx, rz * math.sin(ang) - y))
                    depth += rz * math.cos(ang) + y * math.sin(ang) * 0.0
                tris.append((depth / 3 + sum(q[1] for q in p) / 3 * 0.001, scr, rgb))
    if not tris:
        return
    xs = [q[0] for _, s, _ in tris for q in s]
    ys = [q[1] for _, s, _ in tris for q in s]
    x0, y0 = min(xs), min(ys)  # ループ内で毎回 min を取ると O(n²) になる
    sc = W / (max(xs) - x0)
    H = int((max(ys) - y0) * sc) + 30
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" style="background:#eef1f4">']
    for _, s, (r, g, b) in sorted(tris, key=lambda t: t[0]):
        d = " ".join(f"{(x - x0) * sc:.1f},{(y - y0) * sc:.1f}" for x, y in s)
        out.append(f'<polygon points="{d}" fill="rgb({r},{g},{b})" stroke="rgb({r},{g},{b})" stroke-width="0.4"/>')
    out.append(f'<text x="8" y="{H - 10}" font-size="14" font-family="sans-serif">{name} (isometric, generated mesh) — © OpenStreetMap contributors</text></svg>')
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    main()
