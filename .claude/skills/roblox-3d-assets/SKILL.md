---
name: roblox-3d-assets
description: Roblox用の3Dモデル(ローポリ小物・環境・ペット・卵・建物など)をAIで作る。headless Blender(bpy)での手続き生成、三角形数/テクスチャ制限の検証、FBX/GLB書き出し、プレビュー画像での自己確認、外部AI(Meshy/Tripo/Studio generate_mesh)の使い分けと商用ライセンス確認。「3Dモデル」「アセット」「モデリング」「メッシュ」「Blender」で必ず使う。
---

# Roblox 3D アセットスキル

## 方針（ヒット作の画風と軽さを両立）
- **ローポリ＋フラットシェーディング＋パレットテクスチャ1枚**で作る。
  - 1アセットにつきメッシュ1つ、マテリアル1つ、256pxのパレット1枚。
  - 色を揃えやすく、ドローコールが少なく、モバイルでも軽い。AIでも量産しやすい。
- **Robloxの制限**（`research/03_ai_toolchain.md` で確認済み）
  - MeshPart 1つにつき20,000三角形まで
  - テクスチャは最大4096²（推奨は5スタッド四方で256、10スタッドで512、20スタッドで1024）
  - マテリアルはメッシュ1つにつき1つ
  - 取り込める形式は fbx / gltf / glb / obj
- **三角形数の予算**
  - 小物：≤500
  - 木・岩：≤300
  - ペット：≤1,500
  - 建物：≤5,000
  - ヒーロー級：≤10,000
- 単位は 1 Blender unit = 1 stud。Studio の 3D Importer で Scale Unit を Stud にする。原点は底面中央にする（スクリプトが自動で寄せる）。

## クラウドで生成する（主力）
```bash
cd /home/user/roblox-studio
.venv/bin/python tools/blender/rbx_assets.py tools/blender/specs/<pack>.json
```
- spec の形式：`{"out":"assets/<pack>","assets":[{"kind":"tree","name":"PineTree","seed":1,"params":{...},"tri_budget":800,"scale":1.0}]}`
- 既存の kind：tree, round_tree, rock, crystal, crate, coin, egg, pet, mushroom, fence
- 出力は `<name>.fbx` / `<name>.glb` / `<name>.png`（プレビュー）/ `palette.png` / `manifest.json`（三角形数と寸法）。
- **必ずプレビューPNGを Read で見て自己確認する。** 形・色・向き・比率を見る。複数あるときはPILで1枚にまとめて見る。ユーザーに見せる場合は SendUserFile を使う。
- 色はパレット名で指定する。
  - 系統：red / orange / yellow / lime / green / teal / cyan / blue / indigo / purple / pink / gray / skin / earth / moss / slate
  - 明度：0〜7（例：`green4`）
  - 別名：wood, leaf, stone, gold, white, black, grass, water
- 新しい kind を足すときは `GENERATORS` に関数を追加する。
  - 部品は MeshBuilder の cone / ico / uvsphere / box を組み合わせて作る。
  - 部品が多いほど三角形が増えるので、予算を超えたら Decimate で自動的に減らす。ただし減らしすぎると形が崩れるので、部品数で調整するのが基本。

## 外部AIの使い分け
| 用途 | 手段 | 注意 |
|---|---|---|
| 複雑な有機形状・キャラ | Studio Assistant の `/generate_mesh` か、MCP の `generate_mesh`（PC側。Roblox内で使う分には無料） | 三角形数とBBoxを指定できる。第一候補 |
| ヒーロー級アセット | Meshy / Tripo / Rodin の**有料プラン** | 無料プランは CC BY か商用不可。減面とリトポは bpy で行う |
| ローカルでの生成 | Hunyuan3D-2.1（日本は可、MAU100万超は別途許諾）/ TRELLIS.2（MIT） | 24GB以上のGPUが必要。このコンテナでは動かない |
| 使わない | オープンソース版 Cube 3D | 研究用途限定ライセンスのため商用不可 |

外部モデルの後処理（bpy）
- Decimate、Merge by distance、法線の再計算、原点を底面に、スケールの適用
- テクスチャは 512〜1024 に縮小
- `tri_count()` で20k未満を検証する

## Roblox への取り込み
- **PC：** Studio の 3D Importer（Avatar → Import 3D）で取り込む。CollisionFidelity は Box/Hull にする。
- **クラウド：** Open Cloud Assets API（`POST /assets/v1/assets`、Model として fbx/glb、20MBまで）を使う。
  - API キー（環境シークレット `ROBLOX_API_KEY`）が必要。
  - ネットワーク許可に apis.roblox.com が必要。2026-11 時点のこの環境では未許可。
- 取り込んだら、アセットIDを `games/<slug>/assets.md` に記録する。

## IP・品質チェック
- 既存のゲームやアニメのキャラに酷似していないか確認する。AI生成物でも侵害になりうる。
- パレットの統一：1つのゲームで使う色の系統は5〜6系統までに絞る。
