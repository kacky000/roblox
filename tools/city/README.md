# tools/city — 実在都市の区画を Roblox 用に変換する

計画全体は `reports/future_games_plan.md` §2、データとライセンスは `research/05_real_city_worlds.md` を参照。

## osm_city.py（試作・A 方式：事前メッシュ）

OpenStreetMap から建物・道路・線路・水域・緑地を取得し、チャンクごとの OBJ メッシュにする。Python 3.10 以上の標準ライブラリだけで動く（Blender は不要）。

```bash
python tools/city/osm_city.py --name shibuya --bbox 35.6570,139.6980,35.6620,139.7040
python tools/city/osm_city.py --name shibuya --bbox 35.6570,139.6980,35.6620,139.7040 --scale 0.5 --chunk 512
```

- `--bbox` は south,west,north,east の順。最初は 1km 四方以内にする（Overpass に負荷をかけないため。結果は `osm_cache.json` にキャッシュされる）。
- `--scale`：縮尺（1.0 で 1 stud = 0.28 m）。鬼ごっこやバトルでは 0.5〜0.7 を推奨。
- 出力先は `assets/city/<name>/`。

| ファイル | 中身 |
|---|---|
| `chunk_<i>_<j>_<k>.obj` | チャンク（既定 512 studs 四方）ごとのメッシュ。1 ファイル 18,000 三角形以下（MeshPart の上限は 20,000） |
| `city.mtl` / `palette.png` | `tools/blender/rbx_assets.py` と同じパレット方式のテクスチャ |
| `manifest.json` | 各チャンクの原点、三角形数、バウンディング、統計、クレジット表記 |
| `place_chunks.luau` | Studio に OBJ を一括インポートしたあと、コマンドバーで実行すると各チャンクを正しい位置に並べる |
| `preview.svg` / `preview_iso.svg` | 上面図と等角投影図（AI の目視確認用） |

### 確認済みの結果（2026-11-11、渋谷駅前 約 550m 四方）

- 建物 436 棟、道路 804 本、線路 74 本、水域・緑地 14 → **23 メッシュ、12,413 三角形**。取得込みで約 40 秒。
- 最高の建物は 229.7 m（OSM の height タグ。実際の渋谷スクランブルスクエアの高さと一致）。
- 生成した `place_chunks.luau` は selene のエラー 0、stylua の差分なし。
- **未確認：** Studio へのインポート、見た目、縮尺の体感（Studio の操作が必要）。

### Studio への取り込み手順

1. Studio の 3D Importer（File → Import 3D）で `chunk_*.obj` を一括インポートする。
2. コマンドバーで `place_chunks.luau` の中身を実行する。
3. ゲーム内とストアページに「© OpenStreetMap contributors」を表示する（ODbL 1.0）。

## CityBuilder.luau（B 方式：実行時に Part で組み立てる）

`osm_city.py` が一緒に出力する `city_data.luau`（区画データ）から、Part で街を組み立てる。アセットのアップロードが要らない。

- 外形がほぼ長方形（面積比 0.85 以上）の建物は Part 1 個にまとめる。それ以外は、辺ごとの壁 Part と、三角形分割した屋根（三角形 1 つ = WedgePart 2 個）で作る。
- 道路と線路は区間ごとの Part、水域と緑地は薄い Wedge で作る。
- Roblox のサーバーで使うときは、`{ yieldEvery = 1000 }` を指定して少しずつ作る。
- SLIM（遠景 LOD）の対象外なので、固定マップは A 方式を使う。

```bash
lune run tools/city/bench_builder.luau assets/city/shibuya/city_data.luau out.rbxm
MIN_ROAD_WIDTH=15 lune run tools/city/bench_builder.luau assets/city/shibuya/city_data.luau   # 細い歩道を省く
```

`bench_builder.luau` は、Studio を使わずに Lune 上で組み立てて、Part 数・時間・rbxm の大きさを出力する。`out.rbxm` は Studio にドラッグすれば開ける。

### 確認済みの結果（B 方式、渋谷駅前 0.3km²、実寸）

- **5,947 Part**：長方形の建物 317（436 棟のうち）、壁 1,153、屋根の Wedge 1,994、道路 2,483、水・緑 93
- 組み立ては PC の Lune 上で 0.39 秒。rbxm は 180 KB、データは 103 KB。
- selene のエラー 0、stylua の差分なし。
- **未確認：** Studio と低スペックのモバイル実機での生成時間・メモリ・fps。採用基準は `reports/future_games_plan.md` §2-2-1。

### 既知の制限（次の改善点）

- 建物の穴（中庭）とマルチポリゴンには未対応。高さが不明な建物は 3〜6 階の乱数で埋めている。
- 屋根はすべて平ら。壁の UV はパレットの単色なので、窓は描かれない（キット配置方式 C で解決する予定）。
- 道路は帯を重ねているだけなので、交差点で重なる。
- 日本の建物は OSM に高さ情報がないことが多い。屋上を使う遊びの前に、PLATEAU（実測の高さ）を読めるようにする。
- 次にやること：PLATEAU（CityGML / 3D Tiles）の読み込み、B 方式の実機計測、屋上の経路グラフ。

## ライセンスとマナー

- OSM のデータは ODbL 1.0。クレジット表記が必須。生成物を配布するときの扱いは `research/05` を確認する。
- Overpass API は共有サーバー。大きな範囲を何度も取得しない。キャッシュを使い、広い範囲は分割するか、Geofabrik の抽出データを使う。
- 生成した区画に、実在の店名・ロゴ・看板を足さない（`reports/future_games_plan.md` §2-4）。
