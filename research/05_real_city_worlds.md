# 05. 実在都市（東京 → パリ → NYC）を Roblox に再現する：データ・権利・パイプライン調査

調査日: 2026-11-11 ／ 対象: 個人開発者（ソロ）／ 前提リポジトリ: `C:\Users\arakaki\roblox`（`docs/roblox-creator-docs` は 2026-11-04 のコミット a47045f）

ラベルの意味
- 【確定】一次情報（公式ドキュメント・規約・法令の条文）で確認した
- 【報道】ニュース記事・第三者の解説・フォーラム投稿による
- 【推計】筆者の計算や推論。前提を併記する
- 「未確認」= 一次情報にたどり着けなかった。ライセンス条項を推測で補うことはしていない

> 本書は法的助言ではない。公開・収益化の前に、権利者への問い合わせか専門家への確認を推奨する。

---

## 0. 結論（TL;DR）

1. **東京は PLATEAU が第一候補**【確定】。建物は LOD1（23 区全域 627.57 km²）と LOD2（渋谷・新宿など 11 地区、計 32.02 km²。2020 年度版）があり、条件は「PLATEAU サイトポリシー」（公共データ利用規約 PDL1.0 準拠、CC BY 4.0 互換）。**商用利用可。出典の記載と「加工した」旨の記載が必要。** ODbL での利用も妨げないと明記されている。
2. **OSM（ODbL）は道路・線路・POI・海外都市の骨格に使う。** ゲームは原則「Produced Work」にあたり、ゲーム本体に share-alike はかからない【推計：OSMF ガイドラインの定義から】。ただし帰属表示は必須で、ゲームではスプラッシュ画面やクレジットページなどへの表示が認められている【確定】。
3. **Google Photorealistic 3D Tiles と Cesium ion の Google タイルは「メッシュを抜き出してゲームに使う」ことが規約で明確に禁止されている**【確定】。Apple Maps も copy / extract / scrape を禁止している【確定：一般の Maps 利用規約】。**使わない。**
4. **パリ**: IGN BD TOPO（建物の高さ付き）と LiDAR HD は Licence Ouverte 2.0（Etalab）で、商用利用と改変が可能。出典と最終更新日の記載が必要【確定／報道】。APUR の建物データは ODbL【報道】。**NYC**: NYC Open Data の 3D Building Model（CityGML）。市の条例が「ライセンスや利用制限を課さない」と定めている【確定】。LiDAR（2017）はライセンスの記載がない（未確認）。
5. **法的リスクの本丸はデータではなく「ランドマークの名称・ロゴ・看板・車両塗装」**。日本の著作権法 46 条により建築物の外観は原則として自由に利用できる【確定】。一方、商標（名称・ロゴ）、エッフェル塔の夜間照明、鉄道会社の車両デザインは許諾ビジネスの対象になっている【報道】。→ **名前を変える・ロゴを消す・形を少し崩す（スタイライズ）** を設計ルールにする。
6. **エンジンの制約**: 1 メッシュあたり 20,000 三角形、place ファイル 100MB、ストリーミングの既定 TargetRadius 1024 stud（約 287 m）、性能の目安は「シーンあたり描画呼び出し 1,000 回未満・三角形 100 万未満」【確定：公式 docs】。1 stud = 28 cm【確定】なので 1 km ≈ 3,571 stud。原点から 1 万 stud（約 2.8 km）を超えると精度の問題が出るという報告がある【報道】。→ **1 区 = 1 place（数 km 四方）程度に分割し、TeleportService でつなぐ**のが現実的。
7. **推奨パイプライン**: PLATEAU（CityGML。2020 年版は FBX/OBJ も配布）→ PLATEAU SDK（Unity）か PLATEAU GIS Converter で glTF/OBJ に変換 → Blender（bpy）でタイル分割・減面・パレットアトラス化（既存の `tools/blender/rbx_assets.py` の方針を流用）→ glTF/FBX → Studio Importer か Open Cloud → MeshPart + `Model.LevelOfDetail = SLIM` + StreamingEnabled。小物・道路・線路は OSM から Luau で手続き的に生成する。
8. **Roblox への PLATEAU 導入事例は見つからなかった**（Unity/Unreal/Godot/Fortnite/Minecraft の事例はある）。OSM → Roblox のプラグイン（City Loader → WorldLoader → GeoGenerator）は存在する【報道】。

---

## 1. データソースとライセンス

### 1.1 一覧表

| ソース | 対象 | 形式 | ライセンス／利用条件（要旨と URL） | 帰属表示 | ゲーム利用 |
|---|---|---|---|---|---|
| **PLATEAU 東京都23区（2020年度、V2 対応）** | 23 区の建物・橋・道路・地形・土地利用など | CityGML 2.0 + i-UR 1.4、3D Tiles、GeoJSON、MVT、Shape、**FBX（約 2.8GB）**、**OBJ（約 2.1GB）**、FGDB、オルソ画像 GeoTIFF【確定】 | 「PLATEAU Site Policy『3. 著作権について』に拠る」。商用利用も含め無償【確定】 https://www.geospatial.jp/ckan/dataset/plateau-tokyo23ku | 必要（下記 1.2） | 可 |
| **PLATEAU 区別データ（例: 渋谷区 2025年度、標準製品仕様 v5.0）** | 建物 LOD0/1/2.0/2.2、道路 LOD1/2/3.0、植生 LOD1/3、都市設備 LOD1/3.0、橋 LOD2.1、地下街 LOD1/4.1 など【確定】 | CityGML、3D Tiles、MVT。**FBX/OBJ は配布されない**（必要なら PLATEAU SDK で変換するよう案内）【確定】 | 同上 https://www.geospatial.jp/ckan/dataset/plateau-13113-shibuya-ku-2025 | 必要 | 可 |
| PLATEAU 東京23区（2022年度） | LOD2 の詳細範囲に新宿（2.57 km²）、渋谷（1.39 km²）などを含む【報道：検索結果の要約】 | CityGML ほか | 同上 https://wscart.geospatial.jp/ckan/dataset/plateau-tokyo23ku-2022 | 必要 | 可 |
| **OpenStreetMap** | 世界中の道路・線路・建物の輪郭・POI | OSM XML/PBF、Overpass | **ODbL 1.0** | 「OpenStreetMap」と ODbL であることを示す（下記 1.3）【確定】 | 可（Produced Work として） |
| 国土地理院（地理院タイル・基盤地図情報 DEM） | 標高（DEM5A/5B/10B）、地図タイル | PNG/テキストタイル、GML | 国土地理院コンテンツ利用規約（PDL1.0 準拠）。**基本測量成果の複製・使用には測量法 29 条・30 条の承認申請が必要な場合がある**【確定】 | 「出典：国土地理院ウェブサイト（URL）」＋加工した旨 | **ゲームへの組み込みが申請不要か「未確認」** |
| 国土数値情報（鉄道 N02 など） | 鉄道路線・駅 | GML/Shape/GeoJSON | 国土情報利用約款：出典を明記すれば無償で利用できる【報道：検索要約】。データごとに商用可否が異なる。N02 の可否は未確認 | 「国土数値情報（鉄道データ）国土交通省」＋整備年 | 未確認（N02 の約款本文を要確認） |
| **IGN BD TOPO** | フランス全土の建物（高さ属性付き）・道路など | GeoPackage/Shape | **Licence Ouverte 2.0（Etalab）**【報道：IGN 資料ほか】。年 4 回更新、2026 年 9 月にモデル変更予定【報道】 | 出典（最低でも提供者名）＋最終更新日【確定：LO2.0 本文】 | 可 |
| **IGN LiDAR HD** | フランス全土の点群（約 10 点/m²）と派生 DEM/DSM | LAZ、GeoTIFF | Licence Ouverte 2.0（Etalab）【報道】 | 同上 | 可 |
| APUR（パリ都市計画アトリエ）Volume bâti / Emprise bâtie | パリと周辺の建物の輪郭＋高さ（H_MEDIANE など） | Shape/GeoJSON | **ODbL**【報道：APUR のページ】 | ODbL に従う | 可（OSM と同じ扱い） |
| **NYC 3D Building Model** | NYC 全建物（2014 年の航空写真ベース） | CityGML、Multipatch、DGN【報道：data.gov】 | NYC Open Data。行政法典 §23-502(d)「登録要件・ライセンス要件・利用制限なし」【確定】。帰属表示は「求めることができる」（任意） | 推奨（出典＋版） | 可 |
| NYC Topobathymetric LiDAR 2017 | 点群、1ft DEM/DSM | LAS、GeoTIFF | data.gov 上は「No license information was provided」【報道】→ **未確認** | — | 要確認 |
| **Google Photorealistic 3D Tiles** | 世界の写真測量メッシュ | 3D Tiles（ストリーミングのみ） | **抽出・メッシュ化・オフライン利用は禁止**（1.6） | Google ロゴと帰属表示が必要 | **不可** |
| **Cesium ion**（Google タイル、World Terrain など） | — | — | Data Output を**オフライン・ローカル環境にコピー・保存・再配布してはならない**（Clips を除く）【確定】 | 「Cesium ion」ロゴ | **不可**（Cesium OSM Buildings は ODbL、Japan 3D Building は PLATEAU 条件と明記） |
| Apple Maps / MapKit | — | — | copy / extract / scrape / reutilize の禁止【確定：Maps 利用規約】 | — | **不可** |

### 1.2 PLATEAU（国土交通省 3D 都市モデル）

**ライセンス（サイトポリシー 3. 著作権について）**【確定】 https://www.mlit.go.jp/plateau/site-policy/
- 権利の表記がない限り「公共データ利用規約（第1.0版）」（PDL1.0）に準拠した条件で利用できる。G空間情報センターで公開している 3D 都市モデルのオープンデータの著作権は**各地方公共団体に帰属**する。
- 出典の記載が必要。編集・加工した場合は、出典とは別に加工したことを記載する。加工したデータを国交省が作ったかのように見せてはいけない。
- 「本利用ルールは、クリエイティブ・コモンズ・ライセンスの表示 4.0 国際ライセンス（CC BY）と互換性があります」。**ODC-BY や ODbL での利用も妨げない**（OSM への取り込みが可能という意味。ゲームにとっても扱いやすい）。
- 「一部のコンテンツには、個別法令により利用に制約がある場合があります」。測量法に関する制約が 3D 都市モデルの作業手順書に記されている → **区別データの詳細は未確認。地形（DEM 由来）を使う場合は特に確認する。**

**PDL1.0 の主な条項**【確定】 https://www.digital.go.jp/resources/open_data/public_data_license_v1.0
- 複製・公衆送信・翻案などを自由にでき、「商用利用も可能です」。
- 出典の例：「出典：○○ウェブサイト（当該ページの URL）、PDL1.0（規約原文ページの URL）」。加工した場合は「加工したこと及びその主体」を記載する。
- 第三者の権利（著作権・肖像権など）が含まれる場合は、利用者の責任でその権利者の許諾を得る。→ **LOD2 のテクスチャは航空写真が元**【報道：PLATEAU 技術資料】なので、屋上の広告や看板が写り込んでいる可能性がある。テクスチャはパレット色に置き換えるのが安全。

**ゲーム内のクレジット記載例（案）**【推計】
> 出典：3D都市モデル（Project PLATEAU）東京都23区（国土交通省）https://www.geospatial.jp/ckan/dataset/plateau-tokyo23ku 。〇〇（開発者名）が減面・統合・色変更などの加工を行って作成。
> © OpenStreetMap contributors（ODbL） https://www.openstreetmap.org/copyright

**範囲と LOD**
| データセット | LOD1 | LOD2 | LOD3 | テクスチャ | 形式 |
|---|---|---|---|---|---|
| 23区（2020年度、V2） | 23 区全域 627.57 km²【確定】 | 11 地区 32.02 km²（池袋・新宿・渋谷・品川・東京都心・豊洲・羽田など）【確定】 | 建物は無し | LOD2 は航空写真由来のテクスチャ【報道】 | FBX/OBJ も配布（1 km メッシュ単位）【確定】 |
| 渋谷区 2025（v5.0） | 有 | LOD2.0 / 2.2【確定】 | 建物は無し（道路 3.0、都市設備 3.0、植生 3 は有り）【確定】 | ページには記載なし | CityGML / 3D Tiles / MVT のみ |
| 新宿区 2025（v5.0） | 有 | LOD2.0 / 2.2【報道：検索要約】 | — | — | 同上 |

- 渋谷区・新宿区の区別データは 2023 年度版と 2025 年度版がある【報道：ポータルの一覧】。2024 年度版は見つからなかった。
- **公式ツール**:
  - PLATEAU SDK for Unity / Unreal（MIT）: **FBX / OBJ / glTF(GLB) に書き出せる**。テクスチャを含めるかどうか、座標系（ローカル／平面直角座標）を選べる【確定】 https://project-plateau.github.io/PLATEAU-SDK-for-Unity/manual/ExportCityModels.html
  - **PLATEAU GIS Converter**（MIT、開発 MIERUNE）: 3D Tiles、MVT、GeoPackage、GeoJSON、Shapefile、KML、CZML、**Minecraft、glTF、OBJ** に書き出せる【確定】 https://github.com/Project-PLATEAU/PLATEAU-GIS-Converter
  - **Blender 用の公式アドオンは確認できなかった**。PlateauKit（Python）の PyPI ページに「Plateau-Blender-Importer」という名前が出てくるが、中身は未確認【報道】。FOSS4G 2026 の発表は「公式 SDK は Unity/Unreal 向けしかない」と指摘し、Blender 経由で Godot に持ち込む方法を提案している【報道】。
  - 非公式の PLATEAU SDK for Godot（shiena/godot-plateau）がある【報道】。
  - **Roblox 向けのツールや事例は見つからなかった**（DevForum / Qiita / Zenn / note を検索。2026-11 時点）。

### 1.3 OpenStreetMap（ODbL）

- **帰属表示**【確定】 https://osmfoundation.org/wiki/Licence/Attribution_Guidelines
  - 「OpenStreetMap」と表記し、データが ODbL で提供されていることがわかるようにする（openstreetmap.org/copyright へのリンクが一例）。「© OpenStreetMap contributors」も可。
  - **ゲームでは、起動時のスプラッシュ画面、ゲーム画面、プレイ中、クレジットページ、メニューのいずれでもよい**とされている。最初の表示が簡略な場合は、詳しい表示を別の適切な場所に置く。
- **Share-alike の範囲**【確定＋推計】 https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline
  - Produced Work は「データの全体または実質的な部分を使って作られた作品（画像・映像・テキスト・音など）」。公開物が元のデータを取り出すためのものでない限り Produced Work とする、という指針。Produced Work は**好きなライセンスで公開できる**。
  - ただし ODbL 4.6 により、Produced Work を公開するときは、その元になった**派生データベース**（OSM を加工したデータ）も ODbL で提供する必要がある。
  - 【推計】Roblox のゲーム（メッシュとして焼き込んだ街）は Produced Work にあたる可能性が高い。ただし **OSM から作った中間データ（建物の輪郭や高さを整理した GeoJSON など）は ODbL で公開できる状態にしておく**のが安全。ゲーム内に生の座標テーブル（ModuleScript など）を含める実行時生成方式は「データベースの配布」と見なされる余地があるので、そのデータは ODbL で扱う前提にする。
  - ゲームや 3D モデルについて明示したガイドラインは見つからなかった（Produced Work のページの事例欄は「None」）。
- **Overpass API の利用方針**【確定】 https://dev.overpass-api.de/overpass-doc/en/preface/commons.html
  - 公開インスタンスは 1 日あたり約 1 万リクエスト、約 1 GB までが目安。並列数を超えると HTTP 429。既定のタイムアウトは 180 秒、メモリ 512 MiB。
  - 大量に取得する場合は planet ダンプ（地域抽出なら Geofabrik など）を使う。アプリのバックエンドにするなら自前のインスタンスを立てる。→ **ゲームの実行時に Overpass を呼んではいけない。**事前に取得して加工したデータを焼き込む。
- 日本の OSM は建物の高さ（`height`、`building:levels`）が少ない【推計】→ 東京は PLATEAU の高さを使い、OSM は道路・線路・POI に限定する。

### 1.4 国土地理院（GSI）・道路／鉄道データ

- **地理院タイル**【確定】 https://maps.gsi.go.jp/development/ichiran.html
  - 3 区分（基本測量成果／出典の記載のみで使えるもの／その他）。基本測量成果は測量法に基づく申請が必要な場合がある。**ただし Web・ソフト・アプリで「リアルタイムに読み込む」場合は申請不要で、出典の明示だけでよい。**
  - 【推計】Roblox ではタイルをリアルタイムに読み込めない（HttpService はサーバーのみ。画像を実行時に表示するにはアセットにする必要がある）。そのため、DEM をハイトマップに変換して焼き込む場合は「複製・使用」にあたる可能性がある → **申請の要否は未確認。** 申請不要の例は「デザイン、内部利用、テレビ番組、書籍の挿入図」とされ、ゲームは例に含まれていない【確定】 https://www.gsi.go.jp/LAW/2930-index.html 。**国土地理院の「地図の利用手続ナビ」で確認するか、問い合わせる。**
- **国土地理院コンテンツ利用規約**【確定】 https://www.gsi.go.jp/kikakuchousei/kikakuchousei40182.html
  - 出典の例：「出典：国土地理院ウェブサイト（URL）」。加工の例：「地理院タイル（標高タイル（基盤地図情報数値標高モデル））を加工して作成」。
- **代替案**【推計】: PLATEAU の地形（LOD1、CityGML）を使う（ただし 1.2 の測量法の注記あり）。東京の都心部はほぼ平らなので、**DEM を使わず手作業で数段の高低差だけ再現する**のが、権利面でも性能面でも最も安全。
- 鉄道: 国土数値情報 N02（約款で出典の明記が条件。商用可否はデータごとで、N02 は未確認）。OSM の `railway=*` も使える（ODbL）。

### 1.5 パリ／フランス

- **Licence Ouverte 2.0**【確定】 https://www.data.gouv.fr/pages/legal/licences/etalab-2.0
  - 無償・非独占で、商用・非商用を問わず再利用できる（「de l'exploiter à titre commercial」）。改変・抽出・変換も可。
  - 帰属表示：**出典（最低でも提供者の名前）と最終更新日**。URL を示す方法でもよい。公的機関が推奨しているかのように見せてはいけない。
  - **CC BY、ODC-BY、英国 OGL と互換**と明記されている。
- **IGN BD TOPO / LiDAR HD**: Etalab 2.0【報道：IGN の資料・data.gouv.fr】。IGN の FAQ にも製品ごとの CGU 確認が推奨されている【報道】。ダウンロードは geoservices.ign.fr（Géoportail のアカウントは cartes.gouv.fr に移行済み）【報道】。https://geoservices.ign.fr/bdtopo / https://geoservices.ign.fr/lidarhd
- **APUR**: 建物の輪郭と高さ（Volume bâti、Emprise bâtie の H_MEDIANE）が **ODbL**【報道】 https://www.apur.org/en/geo-data
- **opendata.paris.fr**: データセットごとにライセンスが異なる（ODbL が多い）。**個別に未確認。**

### 1.6 NYC

- **3D Building Model**: CityGML / Multipatch / DGN。2014 年の航空写真と建物輪郭から作られた【報道】 https://catalog.data.gov/dataset/3-d-building-model
- **NYC 行政法典 §23-502(d)**: 公開データセットは「without any registration requirement, license requirement or restrictions on their use」で提供する。出典と版の明示は「求めることができる」【確定】 https://nyc-laws.readthedocs.io/en/latest/nycadmincode/t23/c05/
- ポータルの利用規約には「情報提供目的」「保証しない」という免責もある【報道】。「NYC」は市の商標【確定】 https://www.nyc.gov/main/terms-of-use → **ゲーム名やロゴに「NYC」の公式マークを使わない。**
- LiDAR 2017: ライセンスの記載なし → **未確認**。NYC は平らなので、必要性は低い【推計】。

### 1.7 Google / Cesium / Apple（予想どおり禁止。確認済み）

- **Google Maps Platform 利用規約 3.2.3**（2026-08-26 改定版）【確定】 https://cloud.google.com/maps-platform/terms
  - (a) No Scraping: 「Customer will not export, extract, or otherwise scrape Google Maps Content for use outside the Services.」
  - (c) No Creating Content From Google Maps Content: 例として、建物の輪郭をトレースすること、**45° 画像から 3D 建物モデルを作ること**、Elevation API から地形モデルを作ることが挙げられている。
- **Map Tiles API のポリシー**【確定】 https://developers.google.com/maps/documentation/tile/policies
  - 自分の 3D オブジェクトを重ねてよいのは、それが Photorealistic 3D Tiles から「抽出・トレース・派生」したものでない場合に限る。3D モデルや地形モデルを作ってはいけない。キャッシュ・一括ダウンロード・オフライン利用は禁止。地図の可視化専用。
- **Cesium ion**【確定】 https://cesium.com/legal/terms-of-service/
  - 2.2.2 Offline Use: Clips を除き、Cesium Data Output の一部を、オフライン・ローカル環境で使うためにコピー・保存・再配布してはならない。
  - Cesium のフォーラムでは、Clips 機能は Google / Bing のタイルには使えないとされている【報道】。
  - 第三者の条件（Appendix B）【確定】 https://cesium.com/legal/third-party-terms/ : Cesium OSM Buildings は ODbL、「Japan 3D Building Data / Japan Regional Terrain」は PLATEAU の条件。→ **使うなら元データ（OSM、PLATEAU）から直接取る。**
- **Apple Maps 利用規約**【確定】 https://www.apple.com/legal/internet-services/maps/terms-en.html : Data を copy / extract / scrape / reutilize しようとする利用を禁止。Flyover（3D）に特化した条項は未確認。

---

## 2. 法的・IP リスク（実在のランドマークを Roblox に置く場合）

### 2.1 日本：著作権法 46 条（建築の著作物）【確定】
条文（e-Gov 法令 API で取得）：
> 第四十六条　美術の著作物でその原作品が前条第二項に規定する屋外の場所に恒常的に設置されているもの又は建築の著作物は、次に掲げる場合を除き、いずれの方法によるかを問わず、利用することができる。
> 一　彫刻を増製し、又はその増製物の譲渡により公衆に提供する場合
> 二　建築の著作物を建築により複製し、又はその複製物の譲渡により公衆に提供する場合
> 三　前条第二項に規定する屋外の場所に恒常的に設置するために複製する場合
> 四　専ら美術の著作物の複製物の販売を目的として複製し、又はその複製物を販売する場合

- 建築の著作物（10 条 1 項 5 号）は「いずれの方法によるかを問わず」利用できる。例外は「建築による複製」（実物を建てること）だけ → **ゲーム内の 3D 再現は 46 条で許される方向**【推計】。
- 注意【推計】:
  - 屋外の**彫刻やパブリックアート**（ハチ公像、新宿の LOVE オブジェ、六本木ヒルズの「ママン」など）は「美術の著作物」。4 号「専ら……複製物の販売を目的として」に注意。**像をそのまま再現したものを有料 UGC やゲームパスとして単体販売するのは避ける。** 背景として置くだけならリスクは低め。
  - ビル壁面の**看板・広告・巨大ビジョンの映像・キャラクター**は 46 条の対象外（屋外に恒常的に設置された美術の著作物とはいえない場合がある。商標の問題もある）。→ 消す、または架空のものに差し替える。

### 2.2 商標（名称・ロゴ・形状）
- **商標法 26 条 1 項 6 号**【確定】: 「需要者が何人かの業務に係る商品又は役務であることを認識することができる態様により使用されていない商標」には商標権の効力が及ばない。
  - 【推計】街並みの一部として建物の形があるだけなら「商標的使用」にあたりにくい。**ゲームのタイトル、サムネイル、アイコン、販売アイテム名に「東京スカイツリー」「SHIBUYA109」「東京タワー」などを使うと、商標的使用と判断されるリスクが一気に上がる。**
- 東京スカイツリー: 東武タワースカイツリーに「東京スカイツリーライセンス事務局」があり、名称・ロゴ・シルエットデザインなどを管理しているとされる【報道】 https://www.ben54.jp/news/1913 。登録番号や立体商標の有無は未確認。
- 東京タワー: 公式グッズに「Licensed by TOKYO TOWER」の表記があり、許諾ビジネスが行われている【報道】。外観の立体商標の登録は未確認（J-PlatPat で要確認）。
- SHIBUYA109 などの店名・ロゴ: 登録の詳細は未確認。一般にロゴや店名は商標なので、ロゴは消し、店名は変える。
- **エッフェル塔**: 塔そのものは 1990 年からパブリックドメイン【報道：仏の法律事務所 Dreyfus】。ただし**夜間照明（1985 年〜、金色の照明・きらめき・サーチライト・イベント照明）は保護されており、商用での夜景利用は SETE の事前許可と使用料が必要**【報道：SETE のサイトを引用した複数の二次情報。公式ページは取得できず（403）】。「Tour Eiffel」の名称・ロゴは SETE の商標とされる（未確認）。
  - → **夜のエッフェル塔は「きらめき」を再現しない／照明パターンを変える／名前を変える。**
- **フランスのパノラマの自由（CPI L122-5 11°）**: 対象は自然人による**非商用**の複製に限られる【報道：仏の法律事務所 CMS などの解説。Légifrance の原文は未確認】→ **存命・没後 70 年以内の建築家の作品**（ルーヴルのピラミッド〔I.M. Pei、2019 年没〕、ラ・デファンスのグランダルシュなど）を収益化するゲームで忠実に再現するのはリスクが高い【推計】。
- **米国**: 17 U.S.C. §120(a)【確定：Cornell LII】は、公共の場所から見える建築物について「pictures, paintings, photographs, or other pictorial representations」の作成・頒布・公衆展示を著作権者が妨げられない、と定める。**3D の再現物が「pictorial representations」に含まれるかは争いがある**【推計】。1990 年 12 月 1 日より前に建てられた建物は建築著作物として保護されない（AWCPA）【推計：一般的な理解】。
  - 実例: 『Marvel's Spider-Man: Miles Morales』ではクライスラー・ビルが許諾を得られず登場しなかった【報道】 https://www.gamesradar.com/the-chrysler-building-is-not-in-spider-man-miles-morales-due-to-copyright-issues 。エンパイア・ステート・ビルは名称・画像のライセンス窓口を持ち、建物のデザインを含む商標が登録されている【報道】 https://www.esbnyc.com/licensing-application 。
  - → **大手のスタジオでさえランドマークを外したり許諾を取ったりしている。ソロ開発なら、名前を変えて形をスタイライズするのが基本。**

### 2.3 鉄道の車両デザイン・塗装
- 鉄道会社は車両を使った商品化について許諾契約を求めるのが一般的。例として西武鉄道は「当社への申請・商品化許諾契約が必要」とし、法人のみを対象にしている【確定：西武鉄道の公式ページ】 https://www.seiburailway.jp/company/business/license/
- JR 各社の商品には「JR東日本商品化許諾済」などの表示がある【報道】。**ゲームでの扱いを定めた JR 東日本／東京メトロの公式ガイドラインは見つからなかった（未確認）。**
- → **架空の路線名・架空の塗装（色の帯の配色や太さを変える）・社紋なし。** 「山手線っぽい黄緑」も、組み合わせ次第で連想されるため、色・帯・形状の 2 つ以上を変える【推計】。駅名は地名（渋谷、新宿）なら普通名称・地名だが、路線名や駅ナンバリングのデザイン（JY 20 など）は避ける【推計】。

### 2.4 Roblox のルール
- **IP ガイドライン**（ローカルの docs `production/publishing/ip-guidelines.md`）【確定】: 「収益化していない」「クレジットした」「ネットからダウンロードした」「他の人も使っていた」などは、著作権侵害にならない理由にならない。権利者は著作権・商標の通知を出せ、繰り返し侵害したアカウントは停止される。
- **Rules of Conduct の「Real-World Sensitive Events」**【報道：Roblox ヘルプの検索要約】: 大量殺傷、特定の災害・重大事故、センセーショナルな犯罪などの再現や美化を禁止。→ **事故・災害・事件の現場をそれとわかる形で再現しない**（例：地下鉄の事件の再現、群衆事故、9.11 のワールドトレードセンター）。
- **広告ルール（2026-05-04 から）**: ブランドの広告的な組み込みは事前登録・審査・ラベル表示が必要。13 歳未満には広告を見せない【報道：DevForum・業界メディア】 https://devforum.roblox.com/t/new-advertising-policies-standards/4527365 → 実在の店の看板を置くと「無許可の広告／ブランド侵害」の両方で問題になりうる【推計】。**看板は架空のブランドにする。**
- EditableMesh を公開ゲームで使うには「Allow Mesh / Image APIs」を有効にし、利用規約を確認する必要がある【確定：EditableMesh リファレンス】。

### 2.5 実践的な「安全な設計ルール」（推奨）
| # | ルール | 理由 |
|---|---|---|
| 1 | **実在の店名・ロゴ・看板・広告は全部消して、架空ブランドに置き換える**（例：SHIBUYA109 → 「SHIBUYA 108」のような捩りも避け、まったく別の名前にする） | 商標・不正競争・Roblox の広告ルール |
| 2 | ランドマークは**名前を変え、形を 10〜20% スタイライズ**（比率・装飾・照明を変える）。ゲームタイトル・サムネイルに実名のランドマークを使わない | 商標的使用の回避、海外の建築著作権 |
| 3 | 地名（「渋谷」「新宿」）は使ってよい【推計】。ただし施設の固有名（「スクランブル交差点」は一般的な呼び方なので可、「渋谷スクランブルスクエア」は施設名）は避ける | 地名は普通名称・産地表示に近い |
| 4 | 鉄道は架空の路線名・架空の塗装・社紋なし | 鉄道会社の商品化許諾 |
| 5 | 屋外の彫刻を単体で販売しない（背景に置くのは可） | 著作権法 46 条 4 号 |
| 6 | 夜のエッフェル塔は照明を独自デザインにする | SETE の照明著作権 |
| 7 | 事故・事件・災害の現場をそれとわかる形で再現しない | Roblox の Real-World Sensitive Events |
| 8 | ゲーム内に「クレジット」画面を作り、PLATEAU（加工した旨を含む）、OSM（ODbL）、IGN（最終更新日を含む）を表示する。ゲームの説明文にも記載する | 各ライセンスの帰属表示義務 |
| 9 | Google / Apple / Cesium のメッシュや衛星画像は、トレースも含めて一切使わない | 各規約 |
| 10 | 写真のテクスチャ（PLATEAU LOD2 の航空写真）はそのまま使わず、パレット色や汎用マテリアルに置き換える | 写り込んだ第三者の権利（PDL1.0 の第三者権利条項）、容量 |

---

## 3. 変換パイプラインの現実性

### 3.1 Roblox の制約（ローカル docs と research/03 §4.1 で確認）
| 項目 | 値 | 出典 |
|---|---|---|
| 1 メッシュあたりの三角形数 | **20,000 まで**【確定】 | `art/modeling/specifications.md`、`parts/models.md` |
| EditableMesh | **頂点 60,000、三角形 20,000 まで**。クライアント側のメモリ予算は厳しい（サーバー・Studio・プラグインは無制限）。`FixedSize` と、1 つの EditableMesh を複数の MeshPart で共有することでメモリを節約できる【確定】 | `reference/engine/classes/EditableMesh.yaml` |
| テクスチャ | 最大 4096²（research/03 §4.1）。Open Cloud での画像アップロードは 8000×8000 未満【確定】 | research/03、`cloud/guides/usage-assets.md` |
| インポート形式 | Studio: .fbx / .gltf(.glb) / .obj。Open Cloud の Model: .fbx / .gltf / .glb / .rbxm / .rbxmx（パッケージとして扱われる）、1 ファイル 20MB【確定】 | research/03 §4.1、`usage-assets.md` |
| place ファイル | **100 MB（104,857,600 バイト）**まで【確定】 | `includes/place-size-limit.md` |
| ストリーミングの推奨値 | StreamingMinRadius 64、**StreamingTargetRadius 1024**、ModelStreamingBehavior Improved、StreamOutBehavior Opportunistic、StreamingIntegrityMode PauseOutsideLoadedArea【確定】 | `workspace/streaming/techniques.md` |
| SLIM | `Model.LevelOfDetail = SLIM` にすると、クラウドで合成メッシュと複数の LOD が自動生成され、ストリームアウトした遠景も表示される。条件は StreamingEnabled、Roblox に保存した place、Team Create。**静的なモデルのみ**。モデルの範囲は約 64 stud 以内が推奨【確定】 | `workspace/streaming/slim.md`、`techniques.md` |
| メッシュの LOD（RenderFidelity Automatic） | 250 stud 未満は最高、250〜500 stud は中…（距離で自動）【確定】 | `parts/meshes.md` |
| 性能の目安の例 | 基準端末で「描画呼び出し 1,000 回未満、三角形 100 万未満」を目安にした例【確定】 | `performance-optimization/design.md` |
| 端末の分布 | Android が約 65%。そのうち約 60% が RAM 2〜4 GB、約 35% が 4〜8 GB【確定】 | `performance-optimization/test-on-hardware.md` |
| 単位 | **1 stud = 28 cm**【確定】→ 1 km ≈ 3,571 stud | `physics/units.md` |
| 地形のハイトマップ | 1 ピクセル = 4 stud、最大 4096×4096 → 1 回のインポートで最大 16,384 stud（約 4.6 km）四方【確定＋計算】 | `parts/terrain.md` |
| 座標の精度 | 公式の上限は見つからなかった。原点から 8,000〜10,000 stud でジッターが出るという報告、10 万 stud 以上で問題になるという報告がある【報道：DevForum】 | DevForum の各スレッド |
| プラグインからのアセット化 | `AssetService:CreateAssetAsync` で EditableMesh を **Mesh アセットとしてアップロードできる**（ローカルのプラグインのみ）【確定】 | `AssetService.yaml` |
| 実行時のメッシュ共有 | `AssetService:CreateDataModelContentAsync` が EditableMesh / EditableImage から「DataModel スコープ」の一時コンテンツを作る。サーバーのストレージ予算を超えると失敗する【確定】。**サーバーで作ったメッシュをクライアントに複製できるかは docs から読み取れない（未検証）** | `AssetService.yaml`、`CreateContentResult.yaml` |

> リポジトリ内の不整合（修正はしていない）: `tools/blender/rbx_assets.py` の `PALETTE_PX = 256` のコメントに「Roblox テクスチャ上限 1024 以下」とあるが、research/03 §4.1 では上限 4096²（「1024 上限」は古い情報）とされている。256px のパレット自体は都市にも適している。

### 3.2 規模の推計（渋谷・新宿）
前提【確定】: 23 区の建物は約 176 万棟【報道：東洋経済。PLATEAU から集計】、LOD1 の範囲は 627.57 km²【確定】。
- 平均密度 ≈ 1,760,000 ÷ 628 ≈ **約 2,800 棟/km²**【推計】。渋谷区（約 15 km²）と新宿区（約 18 km²）は全体で **各 4〜6 万棟程度**と見込む【推計：密度 × 面積。実数は PLATEAU のデータを集計して確定させる】。

| 指標 | LOD1（押し出しの箱） | LOD2（屋根形状あり、減面後） | 根拠【推計】 |
|---|---|---|---|
| 1 棟あたりの三角形 | 約 20〜30（輪郭の頂点 8 前後：壁 16 + 屋根 6。底面は削除） | 平均 150〜300 を目標（元データは数百〜数千） | 頂点数からの概算 |
| 1 km² あたり | 3,000 棟 × 25 ≈ **7.5 万三角形** | 3,000 × 200 ≈ **60 万三角形** | |
| 渋谷区全域 | ≈ 100 万三角形 | ≈ 900 万三角形 | 約 15 km² |
| ストリーミング範囲（半径 1024 stud ≈ 287 m → 約 0.26 km²） | ≈ 2 万三角形 | ≈ **16 万三角形** | 目安の 100 万三角形に対して十分に余裕がある |
| MeshPart の数（100 m 四方のタイル ≈ 357 stud） | 100 個/km²、1 タイル ≈ 750 三角形 | 1 タイル ≈ 6,000 三角形（20k 未満） | 1 タイル = 1 メッシュ = 1 パレットテクスチャ |
| 描画呼び出し（範囲内） | 約 26 タイル + 道路など | 同じ | パレットアトラスを共有すればマテリアルの切り替えは最小限 |
| アセットの数 | 渋谷区全域で約 1,500 メッシュ | 同じ | タイルごとに固有のメッシュ（建物は使い回せない） |

- **超高層ビルの扱い**: 新宿の 200 m 級のビルは 714 stud。SLIM が推奨する「範囲は約 64 stud」を大きく超えるので、超高層ビルはタイルから外し、1 棟 = 1 Model（必要なら縦に分割）にする【推計】。
- **ワールドの大きさ**: 渋谷区の東西は約 4 km ≈ 14,000 stud → 原点を区の中心に置けば、端までの距離は約 7,000 stud で、ジッターの報告がある範囲（8,000〜10,000 stud）よりわずかに内側【推計】。23 区全体（約 25 km ≈ 9 万 stud）を 1 つの place に入れるのは避け、**区やエリアごとに place を分けて TeleportService でつなぐ**。縮尺を下げる（例：0.5 倍）のも有効。ゲームとしては、移動距離が半分になるほうが遊びやすいことが多い【推計】。
- place ファイル 100 MB: メッシュはアセット ID で参照されるので place の容量はあまり使わない。Part で組み立てる方式（下記 B）は 1 棟あたり数 Part × 5 万棟 = 数十万インスタンスになり、容量・メモリともに厳しい【推計】。

### 3.3 方式の比較
| 方式 | 内容 | 長所 | 短所 | 判定【推計】 |
|---|---|---|---|---|
| **A. 事前に焼き込んだメッシュ（推奨）** | PLATEAU / OSM → Blender でタイル化・減面・パレットアトラス化 → glTF/FBX → MeshPart | 三角形・描画呼び出し・テクスチャを完全に管理できる。SLIM と StreamingEnabled がそのまま効く。実行時の CPU 負荷がない | アップロードするアセットが数千個。データを更新するたびに再アップロードが必要 | **本命** |
| B. Part を並べる（WorldLoader 型） | OSM の輪郭を Part や Wedge で近似 | Studio だけで完結し、すぐ試せる | 形が粗い、インスタンス数が膨大、place の容量 | プロトタイプ用 |
| C. 実行時に EditableMesh で生成 | 輪郭＋高さのデータ（buffer）を持たせ、クライアントで押し出す | アセットのアップロードが不要。データの差し替えが簡単 | クライアントのメモリ予算が厳しい。1 つ 20k 三角形。「Allow Mesh / Image APIs」の有効化が必要。SLIM が使えない（実行時に変わるモデルは対象外）。生データを配布することになり ODbL 4.6 に注意 | 小さな区域や動的な要素に限る |
| **D. Studio プラグインで生成 → CreateAssetAsync でアセット化** | プラグイン内で EditableMesh を作り、Mesh アセットとして保存 → MeshPart | Blender なしでも A と同じ成果物ができる。Luau だけで完結 | ローカルのプラグインでのみ動く。UV やパレットの処理を自作する必要がある | A の代替案（Blender が使えない環境向け） |

### 3.4 推奨パイプライン（東京・渋谷を最初の目標にする）
```
[取得]
  PLATEAU 23区(2020, FBX/OBJ 1km メッシュ) ─┐  ※最新の形状が必要なら 渋谷区2025 CityGML → PLATEAU SDK(Unity)/GIS Converter → glTF
  OSM (Geofabrik の関東抽出 .pbf)          ─┤  道路・線路・歩道・水域・POI
  (地形) 原則は使わない / 使うなら PLATEAU 地形 or GSI DEM（測量法の要否を確認してから）
        ↓
[前処理: Python (ogr/pyproj/shapely) → GeoJSON]  ※OSM 由来の中間データは ODbL で公開できる状態で保存
  - 平面直角座標 第IX系 → ローカル座標(原点=渋谷駅付近) → stud(÷0.28) ×縮尺
  - 建物属性(用途・高さ)→ パレット色を割り当て
        ↓
[Blender bpy（tools/blender/rbx_assets.py の方針を流用）]
  - 100m タイルに分割（超高層は単独 Model）
  - 底面削除、Merge by distance、Decimate（LOD2 は平均 200 tri/棟）、三角形化して数える
  - 1 タイル = 1 メッシュ = 1 マテリアル = 256px パレット（面ごとに UV をパレットのセルへ寄せる）
  - 窓は法線マップかタイル状のテクスチャ（共通の 1 枚）で表現（ジオメトリを増やさない）
  - glTF/FBX で書き出し（20,000 tri 未満・20MB 未満であることを自動チェック）
        ↓
[Roblox]
  - Studio 3D Importer（まとめて取り込み）か Open Cloud Assets API
  - Workspace: StreamingEnabled, TargetRadius 1024, ModelStreamingBehavior Improved, StreamOutBehavior Opportunistic
  - 各タイル Model: LevelOfDetail = SLIM、MeshPart: CollisionFidelity = Box、CastShadow はタイルごとに調整
  - 道路・線路は OSM から Luau（プラグイン）で生成 → 同じくメッシュとして焼き込む（方式 D）
  - クレジット画面（PLATEAU 加工表示 / © OpenStreetMap contributors ODbL）
  - 区ごとに place を分け TeleportService で接続（パリ・NYC も同じ構成）
```
- 段階計画【推計】: ① 渋谷駅の周り 1 km²（LOD1）で、実機（RAM 3 GB 級の Android）の FPS とメモリを計測 → ② LOD2 に差し替え、SLIM の効果を確認 → ③ 区全体へ → ④ パリ（BD TOPO の高さ＋APUR）→ ⑤ NYC（3D Building Model）。
- パリ・NYC 用の変更点: 座標系（パリ: Lambert-93 / EPSG:2154、NYC: NY State Plane Long Island / EPSG:2263 はフィート単位）【推計：一般的な既定値】。建物は「輪郭＋高さ」で LOD1 を作り、ランドマークだけ手作業でスタイライズしたモデルを作る。

---

## 4. 既存の事例と教訓

| 事例 | 内容 | 教訓【推計】 |
|---|---|---|
| **City Loader**（Roblox プラグイン、paracdil） | OSM の道路・建物と Nextzen の地形で、最大約 30 平方マイルを生成。現在は動かない【報道】 https://devforum.roblox.com/t/city-loader-plugin-templates-for-real-life-buildingscities-in-studio/696886 | 外部 API に頼るプラグインは寿命が短い。データは自分で保存しておく |
| **WorldLoader**（Klingaac、2024-10〜） | OSM から街を生成。縮尺の指定、地形の有無、色や素材を設定できる。Creator Store で配布。2026-03 時点で接続エラーや湖が草地になる報告がある【報道】 https://devforum.roblox.com/t/worldloader-plugin-import-real-life-places-into-studio/3190878 | すぐ試せるプロトタイプとして使える。**OSM の帰属表示は自分で入れる必要がある** |
| **GeoGenerator**（WorldLoader の fork、GitHub） | 歩道・縁石の生成、衛星画像のテクスチャ（任意）、Overpass リクエストの分割とキャッシュ、標高のキャッシュ【報道】 https://github.com/illegalgames099/GeoGenerator | 衛星画像の出どころ（Google/Bing なら規約違反）を確認すること。ライセンスは未確認 |
| DevForum「Real World Cities to Roblox through JSON」 | OSM XML → Lua テーブルに手作業で変換。キャンパス規模なら動いたが、都市全体ではファイルが大きすぎた【報道】 https://devforum.roblox.com/t/real-world-cities-to-roblox-through-json/24257 | 生データを丸ごと入れる方式（C）は規模が大きくなると破綻する |
| **PLATEAU × Roblox** | **見つからなかった**（2026-11） | 先行者がいない。手法を記事にすれば差別化と発信のネタになる |
| Fortnite UEFN「TOKYO PAYLOAD」 | PLATEAU で新宿区四谷の一本道を再現したペイロード型のゲーム【報道】 https://www.fortnite.com/@lit_creator/3906-5009-3855 | **狭い範囲を深く作り込む**のが成功パターン |
| Fortnite UEFN「TOKYO JAPAN REALMAP」（キャドセンター） | 自社の 3D 都市データ「街バース」で東京駅前・丸の内を再現【報道】 https://cgworld.jp/flashnews/202307-Cad-machi.html | 写実路線は商用データとチームが前提。ソロではスタイライズ路線が現実的 |
| PLATEAU 公式 TOPIC 10（Unreal で表示） | 23 区の FBX（LOD1）を平面直角座標で原点合わせ。軸の入れ替え、インポートに時間がかかることに注意【確定】 https://www.mlit.go.jp/plateau/learning/tpc10-1/ | 座標系の扱いはどのエンジンでも最初の壁になる |
| PLATEAU GIS Converter の Minecraft 出力 | 公式ツールが Minecraft 形式に対応【確定】 | 「ボクセル化した街」は公式に想定されている使い方。Roblox の Part 版（方式 B）の参考になる |
| **Denmark in Minecraft**（デンマーク地理データ庁、2014） | 国土全体 43,000 km² を 1:1 で再現（ギネス記録）。公開サーバーは期間限定で 2014-10-23 まで。公開直後に荒らされた【報道】 https://www.guinnessworldrecords.com/world-records/117559-first-country-modelled-at-full-scale-in-a-videogame | ①公的データを使った「話題性」は大きい。②**壊せる世界は荒らされる** → Roblox では地形・建物を破壊不可にする。③運営期間を最初に決めておく |
| VRChat の PLATEAU / 渋谷ワールド | 渋谷を再現したワールドが多数ある【報道】 https://planetvrchat.net/archives/tag/plateau | 「街を歩くだけ」では弱い。**ゲームの仕組み（配達・鬼ごっこ・レース・観光クイズなど）が必要** |

---

## 5. 未確認事項と次のアクション

| 未確認事項 | 確認方法 |
|---|---|
| 地理院の DEM をゲームに焼き込む場合に測量法の申請が必要か | 国土地理院「地図の利用手続ナビ」か問い合わせ（または DEM を使わない） |
| PLATEAU 区別データの測量法関連の個別制約 | 3D 都市モデルの作業手順書と、各データセットのページの注記 |
| 国土数値情報 N02 の商用可否 | N02 のダウンロードページの約款 |
| 東京タワー／スカイツリー／SHIBUYA109 の立体商標・図形商標の登録 | J-PlatPat で検索 |
| JR 東日本・東京メトロのゲームでの車両利用の方針 | 各社の商品化許諾窓口（架空化すれば不要） |
| SETE の照明の権利の公式文言 | toureiffel.paris の business ページ（今回は 403 で取得できず） |
| NYC LiDAR 2017 のライセンス | NYC OTI に問い合わせ（使わなければ不要） |
| Roblox の Community Standards の IP 条項の正確な文言 | about.roblox.com/community-standards（今回は 403 で取得できず） |
| `CreateDataModelContentAsync` のコンテンツがクライアントに複製されるか | Studio で実験する |
| 渋谷区・新宿区の正確な建物数と LOD2 の三角形数の分布 | PLATEAU のデータを Python で集計（plateaukit などを使う） |

---

## 6. 出典（Sources）

**ローカル（リポジトリ内）**
- `docs/roblox-creator-docs/art/modeling/specifications.md`（20,000 三角形）
- `docs/roblox-creator-docs/reference/engine/classes/EditableMesh.yaml`（頂点 60k・三角形 20k、メモリ予算、権限）
- `docs/roblox-creator-docs/reference/engine/classes/AssetService.yaml`（CreateAssetAsync、CreateDataModelContentAsync、CreateMeshPartAsync）
- `docs/roblox-creator-docs/workspace/streaming/slim.md`、`workspace/streaming/techniques.md`
- `docs/roblox-creator-docs/includes/place-size-limit.md`（100 MB）
- `docs/roblox-creator-docs/cloud/guides/usage-assets.md`（Open Cloud の形式と上限）
- `docs/roblox-creator-docs/parts/terrain.md`（ハイトマップ 4096²、1px = 4 stud）、`parts/meshes.md`（RenderFidelity）
- `docs/roblox-creator-docs/physics/units.md`（1 stud = 28 cm）
- `docs/roblox-creator-docs/performance-optimization/design.md`、`test-on-hardware.md`
- `docs/roblox-creator-docs/production/publishing/ip-guidelines.md`
- `research/03_ai_toolchain.md` §4、`tools/blender/rbx_assets.py`

**データ・ライセンス**
- PLATEAU サイトポリシー https://www.mlit.go.jp/plateau/site-policy/
- 公共データ利用規約 PDL1.0 https://www.digital.go.jp/resources/open_data/public_data_license_v1.0
- PLATEAU 東京都23区 https://www.geospatial.jp/ckan/dataset/plateau-tokyo23ku
- PLATEAU 東京23区（2022年度） https://wscart.geospatial.jp/ckan/dataset/plateau-tokyo23ku-2022
- PLATEAU 渋谷区（2025年度） https://www.geospatial.jp/ckan/dataset/plateau-13113-shibuya-ku-2025
- PLATEAU 新宿区（2025年度） https://search.ckan.jp/datasets/www.geospatial.jp__ckan__dataset:plateau-13104-shinjuku-ku-2025
- G空間情報センター PLATEAU ポータル https://front.geospatial.jp/plateau_portal_site/
- PLATEAU SDK for Unity のエクスポート https://project-plateau.github.io/PLATEAU-SDK-for-Unity/manual/ExportCityModels.html
- PLATEAU GIS Converter https://github.com/Project-PLATEAU/PLATEAU-GIS-Converter
- PlateauKit https://pypi.org/project/plateaukit
- FOSS4G 2026 の発表（PLATEAU → Blender → Godot） https://talks.osgeo.org/foss4g-2026/talk/RP9FQJ/
- PLATEAU TOPIC 10（Unreal） https://www.mlit.go.jp/plateau/learning/tpc10-1/
- 東洋経済（23 区の約 176 万棟） https://toyokeizai.net/articles/-/924717
- OSM 帰属表示ガイドライン https://osmfoundation.org/wiki/Licence/Attribution_Guidelines
- OSM Produced Work ガイドライン https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline
- Overpass API の利用方針 https://dev.overpass-api.de/overpass-doc/en/preface/commons.html
- 地理院タイル一覧 https://maps.gsi.go.jp/development/ichiran.html
- 国土地理院コンテンツ利用規約 https://www.gsi.go.jp/kikakuchousei/kikakuchousei40182.html
- 測量成果の利用手続 https://www.gsi.go.jp/LAW/2930-index.html
- 国土数値情報 N02 製品仕様 https://nlftp.mlit.go.jp/ksj/gml/product_spec/KS-PS-N02-v3_0.pdf
- Licence Ouverte 2.0 https://www.data.gouv.fr/pages/legal/licences/etalab-2.0
- IGN BD TOPO https://geoservices.ign.fr/bdtopo ／ LiDAR HD https://geoservices.ign.fr/lidarhd ／ IGN BD TOPO 資料 https://www.ign.fr/files/default/2026-01/IGN_bdtopo_janvier2026.pdf ／ LiDAR HD の地図 https://www.data.gouv.fr/datasets/carte-du-lidar-hd-de-lign-par-commune-date-du-vol-et-couverture-en-france
- APUR のオープンデータ https://www.apur.org/en/geo-data ／ Volume bâti https://geocatalogue.apur.org/catalogue/srv/api/records/urn:apur:emprise_batie_od
- NYC 3D Building Model https://catalog.data.gov/dataset/3-d-building-model ／ メタデータ https://www.nyc.gov/assets/planning/download/pdf/data-maps/open-data/nyc-3d-model-metadata.pdf
- NYC 行政法典 第 23 編第 5 章 https://nyc-laws.readthedocs.io/en/latest/nycadmincode/t23/c05/
- NYC.gov 利用規約 https://www.nyc.gov/main/terms-of-use
- NYC LiDAR 2017 https://catalog.data.gov/dataset/topobathymetric-lidar-data-2017
- Google Maps Platform 利用規約 https://cloud.google.com/maps-platform/terms ／ Map Tiles API のポリシー https://developers.google.com/maps/documentation/tile/policies
- Cesium ion 利用規約 https://cesium.com/legal/terms-of-service/ ／ 第三者の条件 https://cesium.com/legal/third-party-terms/ ／ コンテンツ利用ガイド https://cesium.com/learn/ion/content-usage-and-attribution-guide/ ／ Google 向けの条件 https://cesium.com/legal/terms-for-google/
- Apple Maps 利用規約 https://www.apple.com/legal/internet-services/maps/terms-en.html

**法律・IP**
- 著作権法（e-Gov 法令 API で取得した 46 条・10 条） https://laws.e-gov.go.jp/law/345AC0000000048
- 商標法 26 条（e-Gov） https://laws.e-gov.go.jp/law/334AC0000000127
- 17 U.S.C. §120 https://www.law.cornell.edu/uscode/text/17/120
- フランス CPI L122-5 11° の解説 https://cms.law/fr/fra/a-la-une/la-nouvelle-exception-de-panorama-et-la-reproduction-de-l-image-de-l-immeuble
- エッフェル塔の照明 https://www.dreyfus.fr/en/2015/12/11/nighttime-photos-of-the-eiffel-tower-is-the-lighting-protected-by-copyright/ ／ https://www.klemchuk.com/resources/faqs-ip-law/is-it-illegal-to-photograph-the-eiffel-tower-at-night ／ SETE の公式ページ（取得できず） https://www.toureiffel.paris/en/business/use-image-of-eiffel-tower
- 東京スカイツリーライセンス事務局 https://www.ben54.jp/news/1913 ／ 建築と商標の解説 https://webtan.impress.co.jp/e/2019/02/27/31766
- 東京タワーのライセンス商品 https://corporate.sanrio.co.jp/news/assets/pdf/2018/20220310142226210s.pdf
- 西武鉄道の商品化許諾 https://www.seiburailway.jp/company/business/license/
- Spider-Man とクライスラー・ビル https://www.gamesradar.com/the-chrysler-building-is-not-in-spider-man-miles-morales-due-to-copyright-issues ／ ESB のライセンス https://www.esbnyc.com/licensing-application ／ https://www.selling-stock.com/Article/can-landmarks-be-trademarked
- Roblox IP ガイドライン https://create.roblox.com/docs/production/publishing/ip-guidelines ／ Rules of Conduct https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct ／ Community Standards https://about.roblox.com/en-au/community-standards
- Roblox の広告ルール（2026） https://devforum.roblox.com/t/new-advertising-policies-standards/4527365 ／ https://www.pocketgamer.biz/roblox-to-take-cut-of-in-game-brand-deals-from-2027-under-new-advertising-rules

**事例**
- City Loader https://devforum.roblox.com/t/city-loader-plugin-templates-for-real-life-buildingscities-in-studio/696886
- WorldLoader https://devforum.roblox.com/t/worldloader-plugin-import-real-life-places-into-studio/3190878 ／ https://create.roblox.com/store/asset/76005743851966/WorldLoader-Import-Real-life-places
- GeoGenerator https://github.com/illegalgames099/GeoGenerator
- Real World Cities to Roblox through JSON https://devforum.roblox.com/t/real-world-cities-to-roblox-through-json/24257
- 座標の精度（DevForum） https://devforum.roblox.com/t/how-large-can-a-map-be-before-floating-point-errors-start-to-appear/630965 ／ https://devforum.roblox.com/t/floating-point-reaching-very-early-under-10k-studs/2879723 ／ https://devforum.roblox.com/t/loss-of-precision-causes-game-breaking-issues-at-distances-far-from-origin/202782
- TOKYO PAYLOAD https://www.fortnite.com/@lit_creator/3906-5009-3855 ／ TOKYO JAPAN REALMAP https://cgworld.jp/flashnews/202307-Cad-machi.html ／ https://www.walkerplus.com/article/1217316/
- Denmark in Minecraft https://www.guinnessworldrecords.com/world-records/117559-first-country-modelled-at-full-scale-in-a-videogame ／ https://siliconangle.com/blog/2014/04/30/denmark-writes-minecraft-world-history-with-official-map-data/
- VRChat の PLATEAU ワールド https://planetvrchat.net/archives/tag/plateau
- 非公式 PLATEAU SDK for Godot https://godotengine.org/asset-library/asset/edit/20635
