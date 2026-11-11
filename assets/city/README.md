# assets/city — 実在都市の区画データ（サンプル）

`tools/city/osm_city.py` で生成した区画。生成方法と使い方は `tools/city/README.md` を参照。

| 区画 | 範囲（S,W,N,E） | 中身 |
|---|---|---|
| `shibuya/` | 35.6570,139.6980,35.6620,139.7040（渋谷駅前 約 550 m 四方） | 建物 436 棟、道路 804 本、線路 74 本 |

各フォルダのファイル：

| ファイル | 内容 |
|---|---|
| `city_data.luau` | B 方式（`tools/city/CityBuilder.luau`）用の区画データ |
| `shibuya_parts.rbxm` | B 方式で Part に組み立てた街（5,947 Part）。Studio にドラッグすると開ける |
| `place_chunks.luau` | A 方式（OBJ メッシュ）を Studio で並べるスクリプト。OBJ は容量が大きいのでコミットしない（再生成する） |
| `manifest.json` | チャンクごとの三角形数と統計 |
| `preview.png` / `preview_iso.png` | 上面図、等角投影図 |

## ライセンス

このフォルダのデータは OpenStreetMap から作った派生データベースで、**Open Database License (ODbL) 1.0** で提供する。
© OpenStreetMap contributors — https://www.openstreetmap.org/copyright

ゲームに使うときは、ゲーム内のクレジット画面とストアページの説明文に「© OpenStreetMap contributors」を表示すること（`research/05_real_city_worlds.md` §1.3）。
