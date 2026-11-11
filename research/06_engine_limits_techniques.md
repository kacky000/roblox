# 06. Roblox エンジンの技術的限界と先進テクニック（2026-11 時点）

対象: (a) 数 km 規模の高密度スタイライズド都市オープンワールド、(b) バトルロイヤル＋建築シューター（Fortnite 系ジャンル・独自デザイン）、モバイルでも遊べること。

- 一次資料: ローカル Creator Docs `C:\Users\arakaki\roblox\docs\roblox-creator-docs\`（SOURCE_COMMIT: a47045fe…, 2026-11-04）
- API 存在確認: `C:\Users\arakaki\roblox\tools\roblox-api\API-Dump.json`（以下「API Dump で存在確認」）
- 補足: DevForum / Roblox Newsroom（URL を記載）
- ラベル: 【確定】=ドキュメントで確認／【報道】=DevForum・ニュース／【推計】=筆者の推定。「未確認」=裏付けが取れなかったもの

以下、ドキュメントのパスは `docs/` = `C:\Users\arakaki\roblox\docs\roblox-creator-docs\` の略。

---

## 0. 要点（TL;DR）

| 項目 | 数値・状態 | ラベル |
|---|---|---|
| 1 サーバーの最大人数 | 標準は 200 人（2023-04 に引き上げ）。700 人はベータ限定。100 人超ではボイスチャット不可 | 【報道】200/700、【確定】ボイスチャットは 100 人以下 |
| ストリーミング既定値 | MinRadius 64 / TargetRadius 1024（推奨値）、StreamOutBehavior=Opportunistic 推奨 | 【確定】 |
| 遠景 LOD | `Model.LevelOfDetail = SLIM`（クラウドで合成メッシュ＋多段 LOD を生成、静的モデル限定） | 【確定】 |
| 長距離視認 | `Player.FrustumStreaming`（スコープ・高速移動時にカメラ視錐台方向をストリーミング） | 【確定】 |
| メッシュ上限 | 1 メッシュ 20,000 三角形。EditableMesh は 60,000 頂点 / 20,000 三角形 | 【確定】 |
| テクスチャ | 最大 4096×4096（自動でダウンサンプル）。目安は 20×20 スタッドで 1024 | 【確定】 |
| パーツサイズ | 1 軸 0.001〜2048 スタッド | 【確定】 |
| 地形範囲 | セル座標 ±32,000 = ワールド ±128,000 スタッド。WriteVoxels は 1 回 4,194,304 ボクセルまで | 【確定】 |
| Server Authority | 2026-07-09 に全ゲーム向け正式リリース。予測＋ロールバック＋再シミュレーション。**ラグ補償付きのヒット判定（サーバー巻き戻し）は未搭載** | 【確定】仕組み、【報道】リリース日と未搭載の件 |
| Remote 制限 | クライアント→サーバーは種類ごとに約 500 回/秒、Unreliable は 1,000 バイト超で破棄 | 【確定】 |
| ネイティブコード生成 | サーバーと **Android クライアントのみ**（iOS は対象外） | 【確定】 |
| EditableMesh の複製 | Editable* 自体は複製されない。`CreateDataModelContentAsync` で焼いたコンテンツはサーバーからクライアントへ複製される（サーバー側 200MB まで） | 【確定】API、【報道】複製と 200MB |
| 場所ファイル | 100 MB 上限。Open Cloud のアセットアップロードは 1 ファイル 20 MB まで | 【確定】 |

---

## 1. ワールド規模

### 1.1 1 サーバーの最大人数
- 【確定】`Players.MaxPlayers` は読み取り専用で、Creator Dashboard からしか設定できない（`docs/reference/engine/classes/Players.yaml` L197-）。
- 【確定】ボイスチャットは最大 100 人の場所でしか使えない（`docs/chat/voice-chat.md` L10, L27-35）。100 人を超える設定値が想定されていることを示している。`docs/get-started/why-build-on-roblox.md` L44 には「Servers support up to 100 players」とあり、ドキュメント内でも記述が古いまま揃っていない。
- 【報道】2023-04-13 の公式発表で、全員が 200 人サーバーを作れるようになった。700 人サーバーは以前からベータ限定 — https://devforum.roblox.com/t/experience-join-improvements-server-size-join-queues-and-social-slots-reservations/2294621 ／ https://devforum.roblox.com/t/max-player-count-increased-in-beta/722045
- 【報道】700 人サーバーのメモリ上限が 12.5GB から 6.5GB に下げられた — https://devforum.roblox.com/t/server-memory-cap-for-700-player-servers-reduced-to-65gb-from-125gb/3109012
- 【推計】BR の現実的な人数は **1 マッチ 50〜100 人**。100 人を超えるとボイスチャットが無効になり、サーバーの CPU（Server Authority の再シミュレーション負荷が加わる）やモバイル端末のアバター描画も厳しくなる。BR＋建築を 100 人でやるのは現実的に厳しく、**最初は 24〜50 人を推奨**する。

### 1.2 パーツ数と描画予算
- 【確定】ベースライン端末の目安例として「描画コール 1,000 未満、三角形 1,000,000 未満」が挙げられている（`docs/performance-optimization/design.md` L14）。
- 【確定】Android はプレイヤー全体の約 65%。そのうち約 60% が RAM 2〜4GB。半数超が Passmark 10,000〜20,000 点の端末（`docs/performance-optimization/test-on-hardware.md` L26-31）。
- 【確定】インスタンシング: 同じ `MeshContent` で、`SurfaceAppearance` または `TextureContent` が同一、もしくはマテリアルが同一のメッシュは 1 回の描画コールにまとまる（`docs/performance-optimization/improve.md` L316-325）。→ 都市は「少ない種類のメッシュを大量に再利用する」モジュール方式が正解。
- 【確定】`ParticleEmitter` などのプロパティ変更は描画コストに大きく響く（同 L335）。
- 【推計】パーツ数のハードな上限は公表されていない。経験的には、ストリーミング範囲内でクライアントに存在するのが **2〜5 万 BasePart 程度**ならミドル帯のモバイルで 30〜60fps が狙える。ワールド全体（サーバー側）は 10〜50 万パーツでも成り立つが、サーバーメモリ（数 GB 帯）、場所ファイル 100MB、ロード時間が実際の制約になる。

### 1.3 StreamingEnabled（インスタンスストリーミング）
出典: `docs/workspace/streaming/index.md`, `techniques.md`, `slim.md`, `frustum.md`

- 【確定】`StreamingEnabled` はスクリプトからは設定できない。新規の場所では既定で有効（index.md L13）。
- 【確定】推奨設定（index.md L114-127 / techniques.md L33-46）:
  - `StreamingIntegrityMode = PauseOutsideLoadedArea`
  - `StreamingMinRadius = 64`（既定値。低スペック端末向けに縮められる余地を最大にする）
  - `StreamingTargetRadius = 1024`（既定値）
  - `StreamOutBehavior = Opportunistic`（積極的に GC して OOM を防ぐ。既定値は LowMemory）
  - `ModelStreamingBehavior = Improved`
  - TargetRadius は MinRadius より大きくし、差をバッファにする（L133）
- 【確定】`ModelStreamingMode`: `Default / Nonatomic / Atomic / Persistent / PersistentPerPlayer`（API Dump の Enum で存在確認）
  - Atomic: 初回の子孫をまとめてストリーミングする。後から追加した子は対象外（techniques.md L79）
  - Persistent: 参加直後に送られ、ストリームアウトされない。`Workspace.PersistentLoaded` を待つ。乱用は性能に悪影響（index.md L227-234）
  - PersistentPerPlayer: `Model:AddPersistentPlayer()` で指定したプレイヤーにだけ Persistent（L237-239）
- 【確定】モデルの空間的な広がりは「約 64 スタッド以内」に抑えると全体がまとめてストリーミングされやすい。大きいモデルはモジュール単位に分割する（techniques.md L59）。
- 【確定】`Player:RequestStreamAroundAsync()` でテレポート先をプリフェッチできる（techniques.md L202-。API Dump で存在確認）。`Player:AddReplicationFocus()` で追加の焦点を置ける。
- 【確定】Server Authority 時のクライアント予測はストリーミング済みの領域でしか動かない（index.md L150）。
- 【確定】`Touched`、`ProximityPrompt`、`ClickDetector` などは、そのクライアントにストリーミングされていないと動作しない（techniques.md L381）。
- 【確定】テストは `StreamingTargetRadius` を最小値 64 にして行うこと（techniques.md L389）。

#### SLIM（Scalable Lightweight Interactive Models）
- 【確定】`Model.LevelOfDetail = SLIM` にすると、クラウドで合成メッシュと多段 LOD が生成される。ストリームアウトされたモデルも SLIM の代替表示で見えたままになる。4 つの距離帯（フル描画 → 有利なら SLIM → インスタンス破棄して SLIM のみ → 非描画）（`slim.md` 全体）。
- 【確定】前提条件: StreamingEnabled、Roblox への保存（ローカル .rbxl では不可）、Team Create の有効化。初回のトランスコードには 1〜2 分かかる。
- 【確定】制限: **静的モデルのみ**（実行時のパーツ追加・削除、プロパティ変更、アニメーションは不可）。Humanoid を含むモデルは対象外。Scale 0 も不可。未対応プラットフォームでは Disabled 扱いにフォールバックする。CSG（`PartOperation`）は崩れる場合がある。面が重なると Z ファイティングが出るので 0.01 スタッドずらす。
- 【確定】`Workspace.EnableSLIMAvatars`（R15 プレイヤーのみ、NPC 不可）。ドキュメント上の例で、遠距離の観客が約 260 万から約 17 万三角形に、インスタンスが約 6 万から約 4,000 に減っている。
- 【確定】Enum `ModelLevelOfDetail` = Automatic / StreamingMesh / Disabled / SLIM（API Dump）。StreamingMesh は旧方式で、SLIM が後継。
- 【報道】2025-10 に Studio ベータ、2025-12 に Newsroom で発表、その後 Client Beta。SLIM は地形のストリーミングには今のところ影響しない — https://devforum.roblox.com/t/client-beta-introducing-scalable-lightweight-interactive-models-slim/4034709 ／ https://about.roblox.com/newsroom/2025/12/introducing-roblox-slim-scalable-lightweight-interactive-models
- 含意: **都市の建物（静的）は全部 SLIM、破壊可能・建築可能なものは SLIM にしない**、と二層に分けて設計する。

#### Frustum Streaming
- 【確定】`Player.FrustumStreaming`（`Enum.FrustumStreamingMode`: Default / Disabled / Automatic / Enabled）。サーバー側からのみ設定できる。Automatic は狭い FOV（スコープ）、高速移動、カメラが焦点から離れた状態を検知して有効化する。オクルージョンは考慮しない。描画距離が TargetRadius 以下になると自動で無効化される。予算は ReplicationFocus と同じ扱い（`frustum.md`）。
- 含意: スナイパーや降下（スカイダイブ）中の遠景に効く。

### 1.4 MeshPart / RenderFidelity / テクスチャ
- 【確定】1 メッシュ 20,000 三角形が上限（`docs/art/modeling/specifications.md` L29）。
- 【確定】`MeshPart.RenderFidelity` の Automatic は、250 スタッド未満で最高、250〜500 で中、500 以上で最低（`docs/reference/engine/classes/MeshPart.yaml` L189-）。Enum の値は Automatic / Precise / Performance（API Dump）。
- 【確定】テクスチャは最大 4096×4096。ロード時は低品質から段階的に上がる。目安は 5×5 スタッドで 256、10×10 で 512、20×20 で 1024。標準マテリアルは 8×8 スタッドあたり 1024（Part）、地形は 512（`docs/art/modeling/texture-specifications.md` L17-30）。多数を同時に描画すると自動でダウンサンプルされる。
- 【確定】標準マテリアルはカスタムテクスチャよりはるかにメモリが少ない（`design.md` L40）。→ スタイライズド都市なら、標準マテリアル＋MaterialVariant と少数のアトラステクスチャが最適。
- 【確定】Part の Size は 1 軸 0.001〜2048。0.05 未満は物理上 0.05 として扱われる（`BasePart.yaml` L1832-1840）。

### 1.5 低スペックモバイルのメモリ予算
- 【確定】低スペック端末は OOM クラッシュしやすい。ベースライン端末を決めて実機テストすること（`design.md` L8-26）。クラッシュ率が 2〜3% を超えたら調査する（`identify.md` L135）。サーバー側は `DataModel.ServerLowMemoryWarning` で早期に警告を受け取れる（`monitor.md` L19。API Dump で存在確認）。
- 【推計】2〜4GB RAM の Android で Roblox クライアントが実際に使えるのは **おおよそ 600MB〜1.2GB**。そのうちワールド（インスタンス、メッシュ、テクスチャ）に回せるのは 300〜600MB 程度と見るのが安全。正確な公式数値は**未確認**。

### 1.6 大きな座標での浮動小数点精度
- 【確定】ドキュメントに明示の記述はない（未記載）。
- 【報道】Vector3 / CFrame は単精度（float32）。原点から数千〜1 万スタッドあたりでカメラ揺れ、描画のジッター、ブリックシフトが報告されている。スタッフは「根本修正は現時点で取り組んでいない」と回答。標準のフローティングオリジン機能はない — https://devforum.roblox.com/t/loss-of-precision-causes-game-breaking-issues-at-distances-far-from-origin/202782 ／ https://devforum.roblox.com/t/floating-point-reaching-very-early-under-10k-studs/2879723
- 【推計】1 スタッド ≒ 0.28m（`docs/physics/units.md` 参照）とすると、4km 四方の都市は約 14,000 スタッド四方になる。**原点を中心に配置すれば各軸 ±7,000 スタッドに収まり、許容範囲**。±10,000 スタッドを超える場合は、プレイ領域を分割して別の Place（テレポート）にするのが現実的。フローティングオリジン（ワールド全体の移動）はストリーミングや物理と相性が悪く、非推奨。

### 1.7 地形（Terrain）
- 【確定】ボクセルは 4×4×4 スタッド（`docs/parts/terrain.md` L8）。ハイトマップは 1px = 4 スタッド、最大 4096×4096px（L286）。つまり 1 枚で 16,384 スタッド四方まで。
- 【確定】`Terrain.MaxExtents` はセル座標 ±32,000、ワールドでは ±128,000 スタッド（`Terrain.yaml` L120-128）。
- 【確定】`Terrain:WriteVoxels()` は resolution が 4 必須で、1 回 4,194,304 ボクセルまで。`WriteVoxelChannels` / `ReadVoxelChannels` でチャンネルを細かく制御できる（`Terrain.yaml` L1232-1251）。`FillBlock`、`FillBall`、`FillCylinder`、`FillWedge` もある（API Dump）。
- 【確定・API Dump のみ】新しいメンバーとして `WriteVoxelsAsync_beta`、`ReadVoxelsAsync_beta`、`ModifyVoxelsAsync_beta`、`IterateVoxelsAsync_beta`、`ClearVoxelsAsync_beta`、`CreateVoxelBuffer_beta`、`*Slot` 系（`FillBlockSlot`、`SetMaterialSlot` などのマテリアルスロット）、`ExpandedTerrainResolved`、`SmoothVoxelsUpgraded` が存在する。**ドキュメント本文での説明は未確認**で、ベータ扱い。
- 【報道】非同期ボクセル API は 2026 年中頃に「beta not enabled」の報告がある — https://devforum.roblox.com/t/optimizations-and-asynchronous-methods-for-terrain/3964467
- 【推計】都市の主体は Part/Mesh にし、地形は外周の自然、河川、丘陵に限る。地形はファイルサイズとメモリを大きく食う（place-files.md でも地形の削減が推奨されている）。

---

## 2. 実行時生成

### 2.1 EditableMesh / EditableImage
出典: `docs/reference/engine/classes/EditableMesh.yaml`, `EditableImage.yaml`, `AssetService.yaml`, `docs/projects/assets/in-experience-asset-creation.md`

- 【確定】公開済みゲームでは既定で失敗する。Creator Dashboard の「Enable Mesh / Image APIs」をオンにする必要がある（EditableMesh.yaml L16-24）。
- 【確定】読み込める元アセットは、ゲームオーナー、Studio ユーザー、クライアント側ならそのプレイヤーが所有しているか共有を受けたもの、またはグループ権限のあるもの（L26-44）。
- 【確定】**クライアント側には厳しいメモリ予算がある**（サーバー、Studio、プラグインは無制限）。予算を使い切ると生成に失敗する（AssetService.yaml L337, L368, L441）。FixedSize（アセットから作る場合の既定）のほうが省メモリで、1 つの EditableMesh を複数の MeshPart から参照するとさらに節約できる。
- 【確定】EditableMesh は 60,000 頂点 / 20,000 三角形（quad は 2 として数える）が上限（L288-293）。EditableImage は最大 1024×1024。表示中の EditableImage の更新は 1 フレームに 1 枚まで（EditableImage.yaml L33-37, L90）。
- 【確定】EditableMesh / EditableImage はどちらも **NotReplicated** タグ付き（EditableMesh.yaml L312、EditableImage.yaml L101）。
- 【確定】`AssetService:CreateDataModelContentAsync()` は、EditableMesh / EditableImage から DataModel スコープの不透明な Content を生成する。サーバーのストレージ予算を超えると `StorageLimitExceeded`（AssetService.yaml L238-276、capability: DynamicGeneration）。
- 【報道】CreateDataModelContent は 2026-03 に Studio ベータ、**2026-05-18 に公開ゲームで利用可能**。サーバーで作ったコンテンツは**クライアントへ複製される**（サーバー→クライアントの一方向）。Editable* のメモリ予算は消費せず、ディスクにページングされる。**サーバー作成分は 200MB まで**。セッション限定で永続化されない。初回の `CreateMeshPartAsync` で約 20ms のメインスレッド停止が報告されている — https://devforum.roblox.com/t/full-release-introducing-createdatamodelcontent-convert-editable-mesh-and-image-data-into-static-content/4541898 ／ https://devforum.roblox.com/t/createmeshpartasync-stalls-the-main-thread-20-ms-on-first-use-of-new-datamodelcontent/4884694
- 【報道】2026-09-15 にバッチ API（ループで個別呼び出しするより最大約 8 倍速い）と、並列 Luau からの読み取りクエリ（最大約 2 倍）が正式リリース。書き込みはシリアル必須。**「Editable* API の追加の ID 認証要件の整理」はまだ作業中**。つまり 13 歳以上の ID 認証（オーナー側）が引き続き必要と読める。クライアントでの同時数はユーザー報告で約 8 個 — https://devforum.roblox.com/t/full-release-editablemesh-batching-apis-parallel-queries/4779401 ／ https://devforum.roblox.com/t/editablemeshes-capped-at-8-on-client-vs-much-larger-cap-on-server/3644678
- 【確定】API Dump 上、EditableMesh には `thread_safety: Safe` のメンバーが多数ある（参照ドキュメントで 53 箇所）。
- 含意: 実行時の大量生成（建物を 1 棟ずつ EditableMesh で作る）は**クライアント予算の面で不可**。正解は「**サーバーで生成し、CreateDataModelContent で焼いて複製**」。ただし 200MB の上限と、初回適用時のスパイクがあるので、地形の装飾や破壊後の残骸など、限定的な用途にとどめる。

### 2.2 Instance.new による大量の Part 生成
- 【確定】Parallel フェーズではインスタンスを変更できない（`docs/scripting/multithreading.md` L18）。生成は必ずシリアルで行う。
- 【確定】`WorldRoot:BulkMoveTo()` が存在する（API Dump）。大量の CFrame 更新に使う。
- 【推計】サーバーで 1 フレームあたり数千個の `Instance.new` → 親付けを行うと、複製キューが詰まる。ストリーミング環境では、クライアントに届く量は半径内の分だけになる。**事前に作ったテンプレートを `Clone()` し、親付けは最後に 1 回だけ行う**。1 フレームあたり約 500〜2,000 個に分割して生成するのが安全圏。

### 2.3 Parallel Luau（Actors）
- 【確定】Actor ごとに並列実行され、同じ Actor 内のスクリプトはシリアル。並列化するには `task.desynchronize()` / `ConnectParallel`。並列フェーズで `require` は不可。`SharedTable` で状態を共有。Actor メッセージは `SendMessage` / `BindToMessage(Parallel)`。サーバー側レイキャスト検証の並列化例あり（`docs/scripting/multithreading.md` L20-218）。
- 【確定】`RunService:BindToSimulationParallel` が存在する（API Dump）。
- 手続き生成パターン【推計】: (1) Actor N 個でチャンクごとにノイズ、区画割り、建物レイアウトを計算し、結果を SharedTable やバッファに書き込む → (2) シリアルフェーズで Clone、親付けを時間分割して行う。計算部分は `--!native` と `buffer` で高速化する。

### 2.4 ネイティブコード生成
- 【確定】`--!native` または `@native`。**対応はサーバーと Android クライアントのみ**。コンパイル時間、メモリ、ゲーム全体のネイティブコード量の上限がある。1 スクリプト 100 万命令の上限。Vector3 の型注釈を推奨（`docs/luau/native-code-gen.md` L8-150）。
- 含意: iOS クライアントでは効かない。重い計算は**サーバー側に寄せる**のが一貫性のある方針。

---

## 3. シューターのネットワーク

### 3.1 Server Authority（2025-2026 の目玉）
- 【確定】仕組み: サーバーが唯一の真実で、クライアントは入力だけを送る。クライアントは予測し、ずれ（misprediction）が出たらロールバックして再シミュレーションする（`docs/projects/server-authority/index.md`）。
  - 設定: `Workspace.AuthorityMode = Server` で、`NextGenerationReplication`、`PlayerScriptsUseInputActionSystem`、`SignalBehavior=Deferred`、`UseFixedSimulation`、`StreamingEnabled` が自動で設定される（L33-42）
  - コアロジックは、クライアントとサーバーの両方で初期化する ModuleScript 内の `RunService:BindToSimulation()` に書く。時間は `time()` を使う（`tick`、`os.clock` は不可）
  - 予測状態の同期は属性で行う（1 インスタンスにつき先頭 64 個、名前は 50 文字以内、文字列値も 50 文字以内）。
  - 入力は Input Action System（`InputAction` / `InputContext`）を使い、`UserInputService.InputBegan` は使わない。
  - `Instance:Destroy()` はシミュレーション内では呼べない（属性でフラグを立て、`PostSimulation` で消す）。予測的なインスタンス生成（instance stitching）がある（techniques.md L8-）。
  - RemoteEvent は、プロパティや属性の更新と順序が揃う保証がない。
  - `RunService:SetPredictionMode()` / `GetPredictionStatus()`、イベント `Misprediction` / `Rollback`、`IsResimulating`（API Dump で存在確認）。
  - 他プレイヤーの入力はクライアントに転送されない（既定では他キャラは少し過去の状態で描画される）（techniques.md L338-）。
  - テンプレート: Racing / Soccer / Laser Tag（index.md 末尾）。
- 【報道】**2026-07-09 に全ゲームで正式リリース**。Tools / Backpack も対応した（ただし misprediction 中に Tool を切り替えると Weld が消える既知の問題あり）。Animator あたり同時 8 トラックまで。カメラの InputAction 複製は廃止され `Player:GetCameraState()` を使う（API Dump で存在確認）。**ラグ補償付きのヒット判定（server-side rewind）は未搭載で「検討中」**。Laser Tag では Remote が約 40〜50ms ずれる。サーバー負荷は増え、Extended Services for Compute を案内している — https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993 ／ https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority
- 【報道】技術解説（2026-05-08）: 100ms のレイテンシを再シミュレーションすると、通常の約 6.25 倍のシミュレーション負荷。ラグ補償ヒット判定の組み込み版は計画中 — https://devforum.roblox.com/t/server-authority-tech-deep-dive-engineering-insights/4624565
- 【確定】Extended Services for Compute は 1 プレイヤーあたりの CPU を 2 倍超にする（有料。月 10 万プレイ時間までは無料枠。18 歳以上の ID 認証が必要）（`docs/cloud-services/extended-services.md` L6-10, L81-91, L204-214）。
- 含意（BR/建築）: 移動の不正（スピードハック、フライ）は SA でほぼ封じられる。**射撃判定は自前でラグ補償を実装する必要がある**。100 人規模では再シミュレーションの CPU が厳しく、SA を使うなら 30〜50 人程度が無難【推計】。

### 3.2 ヒット判定のパターン
- 【確定】ドキュメントの推奨: 応答性のためにクライアントで武器をシミュレーションし、サーバーがレイキャストと、速度や過去の挙動に基づくヒューリスティックで確認する。プレイヤーごとに Actor を分けて並列検証する（`multithreading.md` L174-218）。`WorldRoot:Raycast / Spherecast / Blockcast / Shapecast` は API Dump で存在確認。
- 推奨実装【推計】:
  1. クライアント: 即時にレイキャスト（または弾道）してエフェクトを出し、`{発射時刻=workspace:GetServerTimeNow(), 原点, 方向, 命中候補}` を送る（`GetServerTimeNow` は API Dump で存在確認）。
  2. サーバー: 各キャラのヒットボックス履歴をリングバッファで持つ（例: 20〜30Hz で 1 秒分）。発射時刻から補間時間分を引いた時点に巻き戻して判定する。巻き戻しの上限は 200〜250ms。原点がキャラ位置から 5〜10 スタッド以内かを確認し、壁抜けは現在の世界で再レイキャストしてチェックする。
  3. 判定はサーバーで確定し、ダメージは Reliable RemoteEvent で通知する。
  - コミュニティ製の lag compensation モジュール「Rewind」がある（未検証）— https://text21.github.io/Rewind/docs
- ヒットスキャンか弾体か: ヒットスキャンは巻き戻しが簡単で、モバイルの帯域にも優しい。弾体（落下、弾速あり）は FastCast 系（コミュニティの弾体ライブラリ。公式 API ではない。現行のメンテナンス状況は**未確認**）でクライアント描画とサーバーの解析的検証を組み合わせる。【推計】BR では「近〜中距離はヒットスキャン、スナイパーと爆発物は弾体」のハイブリッドが一般的。

### 3.3 UnreliableRemoteEvent と帯域
- 【確定】RemoteEvent と UnreliableRemoteEvent は、**種類ごとに全インスタンス共有で、1 クライアントあたり約 500 回/秒**。Unreliable は 1,000 バイト超で破棄され、順序の保証もない（`UnreliableRemoteEvent.yaml` L37-57、`docs/scripting/events/remote.md` L373-406）。
- 【確定】buffer などは自動でエンコード・圧縮される（UnreliableRemoteEvent.yaml L59-）。
- 【確定】1 プレイヤーあたりの帯域上限の公式数値は**ドキュメントに記載なし（未確認）**。
- 【推計】モバイル回線を考えると、下り（サーバー→クライアント）は 1 プレイヤーあたり平均 50〜100 KB/s を目標にする。カスタム複製は buffer にパックし、20〜30Hz で Unreliable を使う。

### 3.4 物理オーナーシップ
- 【確定】未アンカーのパーツは近くのクライアントに自動で割り当てられる。`BasePart:SetNetworkOwner()`。乗り物は運転手に所有させる例がある。サーバー所有にするとクライアントでジッターが出る（`docs/physics/network-ownership.md` L6-60）。
- 含意: SA を使わない場合、クライアント所有の物体は改ざんできる。建築ピースはすべて**アンカーしてサーバー所有**にする。乗り物は「SA で予測するか、運転手所有にしてサーバーで速度・位置を検証するか」の二択。

### 3.5 アンチチートの現実
- 【確定】SA は「クライアントに自分の位置を報告させない」ことで、フライやスピードハックの類を防ぐ（SA index.md 冒頭）。
- 【推計】それでも残る問題: エイムボット、ESP（ストリーミングで遠方の敵情報を減らせる。プレイヤーは常に複製されるため完全には防げない）、Remote の濫用（レート制限やスキーマ検証で対処）、オートクリック。サーバー側では、レート、角速度、命中率の統計による異常検知と、`Players:BanAsync()`（API Dump で存在確認。`BanService` というクラスは存在しない）などを組み合わせる。

### 3.6 収縮ゾーン（ストーム）
- 【推計】実装: サーバーが `{中心, 半径, 開始時刻, 終了時刻}` のフェーズ表を決め、属性か Reliable Remote で全員に配る。クライアントは `GetServerTimeNow()` で補間して描画する（円柱 MeshPart を拡大縮小、あるいは内面描画の壁、フォグや ColorCorrection）。ダメージ判定はサーバーで 0.5〜1 秒ごとに 2D 距離を比べるだけ。帯域はほぼゼロ。ストリーミングとは無関係で軽い。

### 3.7 プレイヤー建築（建築シューターの核）
- 【推計】グリッドベース（例: 16×16×16 スタッドのセル。壁、床、階段、屋根の 4 種）。1 ピース = 1 アンカー済み MeshPart（同一メッシュなのでインスタンシングで描画コールが 1 本にまとまる）。
  - 50 人マッチで 1 人 100〜300 ピース建てるとして、**合計 5,000〜15,000 ピース**。アンカー済みで物理負荷はほぼないので、サーバーとクライアントともに十分許容範囲。ストリーミング内に入るのはその一部。
  - 設置の手順: クライアントで即座にゴースト表示（予測） → サーバーでグリッド、資源、重なり、射程を検証して生成 → 失敗したら取り消す。SA 環境ではシミュレーション内の `Instance.new` で予測生成と instance stitching が使える（SA techniques.md L8-）。
  - 破壊: HP を属性で持つ。0 になったら Destroy して破片エフェクトはクライアント側のみ。構造が支えを失ったときの連鎖崩壊は、グリッドの連結成分を BFS（サーバー、ネイティブ実行）で判定する。
  - **SLIM は使わない**（実行時に変更されるため）。代わりに RenderFidelity の自動設定と、低ポリなピースで対応する。
- 都市の既存建物の破壊: 静的な SLIM 建物を、破壊時だけ Disabled LOD のモジュール版に差し替える二層構成【推計】。全面的に破壊可能な都市はメモリと複製の面で非現実的。

### 3.8 乗り物
- 【確定】運転手にネットワーク所有させるのが既定パターン（network-ownership.md L35-60）。SA ではサーバー所有のまま予測できる（SA index.md「Network ownership and prediction」）。レーシングテンプレートがある。
- 【推計】BR では乗り物を 10 台程度に絞り、Constraint ベースのシンプルな車体にする。

---

## 4. マッチメイキングとスケール

### 4.1 標準マッチメイキング（`docs/matchmaking/`）
- 【確定】参加時に、公開サーバーのうち満員、プライベート、**予約済み**、終了予定のものを除外し、シグナル（位置、年齢、遅延、フレンド、言語、プレイ履歴＋カスタム属性）の重み付き和でスコアを付けて振り分ける（`matchmaking/index.md`）。カスタム属性とシグナルは Creator Dashboard で設定し、モックサーバーでシミュレーションできる（`customize-matchmaking.md`）。
- 【確定】`MatchmakingService` のメンバーは `GetServerAttribute / SetServerAttribute / InitializeServerAttributesForStudio` のみ（API Dump）。
- 含意: 標準マッチメイキングは「公開サーバーへの参加」を最適化するもので、**BR のマッチ単位の割り当ては自前のキューと予約サーバーで作る**のが基本。ロビー（公開サーバー）では skill / region シグナルを効かせる。

### 4.2 TeleportService の予約サーバー
- 【確定】`TeleportOptions.ReservedServerId` に `HttpService:GenerateGUID(false)` を入れて `TeleportAsync` すると、初回で予約サーバーが作成され、同じ ID で再利用できる（`docs/projects/teleport.md` L105-117。API Dump で `ReservedServerId` の存在確認）。旧 `ReserveServerAsync` も存在する。失敗に備えて retry する（L177-196）。TeleportData は平文なので秘密情報を入れない（L146）。

### 4.3 MemoryStore キュー
- 【確定】容量クォータは 64KB＋1.2KB×ユーザー数（ゲーム単位）。リクエストは毎分 1,000＋120×同時接続ユーザー数。1 つのキューまたはソート済みマップで最大 100 万アイテム・100MB。1 パーティションあたり毎分約 3 万ユニットでスロットル開始。キューとソート済みマップは単一パーティション（`docs/cloud-services/memory-stores/index.md` L38-107）。
- 推奨パターン【推計】: ロビー各サーバーが `MemoryStoreQueue:AddAsync` でエントリ（パーティー単位）を積む → 1 台（リーダー選出は SortedMap のロックで行う）が `ReadAsync` で N 人分を取り出す → 予約 ID を発行 → MessagingService か HashMap で各ロビーに通知 → TeleportAsync。高負荷時は地域や人数でキューをシャードする。

### 4.4 MessagingService の制限
- 【確定】メッセージ 1KB。送信はサーバーあたり毎分 600＋240×プレイヤー数。トピックごとの受信は毎分 40＋80×サーバー数。ゲーム全体の受信は毎分 400＋200×サーバー数。購読はサーバーあたり 20＋8×プレイヤー数。購読リクエストは毎分 240（`MessagingService.yaml` L26-85）。
- 含意: 低遅延の確実な RPC ではない。マッチ成立通知のような「ベストエフォート」用途に限り、確定は MemoryStore で行う。

### 4.5 100 人超・サーバー間連携
- 【推計】1 マッチ 100 人超は 200 人上限内で理論上は可能だが、モバイル、帯域、SA の CPU を考えると非推奨。サーバー間連携（シャード間で同じ世界を共有する MMO 型）は MessagingService の制限から**リアルタイム同期には使えない**。都市オープンワールドは「1 サーバー＝1 都市インスタンス、30〜50 人」を基本にする。

---

## 5. コンテンツパイプライン

### 5.1 Open Cloud Assets API
- 【確定】Create / Update Asset は 1 回 1 アセット、20MB まで。対応は Model（.fbx / .gltf / .glb / .rbxm / .rbxmx → MeshPart を含む Model、パッケージとして登録）、Decal / Image（.png / .jpeg / .bmp / .tga、8000×8000 未満）、Audio、Animation など。Mesh 単体は Asset Delivery から取得したデータの再アップロードのみ。「Studio 外で編集した .rbxm は動作しない可能性がある」（`docs/cloud/guides/usage-assets.md` L18-）。
- 【確定】Place Publishing API は .rbxl / .rbxlx を POST で公開できる。ただし EditableImage、EditableMesh、PartOperation、SurfaceAppearance、BaseWrap を含む場合は Studio から公開が必要（`docs/cloud/guides/usage-place-publishing.md` L8-11）。
- 【確定】場所ファイルは 100MB が上限（`docs/projects/place-files.md` L30）。
- 【報道】GenerateModelAsync（4D 生成。スキーマは Car5 / Body1。生成物はゲーム内で複製される）。レート制限はベータで 1 ゲームあたり毎分 10 リクエストから、同時接続数に応じて増える。生成に 20〜40 秒 — https://devforum.roblox.com/t/beta-4d-generation-unlock-new-types-of-gameplay/4331818 ／ 【確定】`docs/parts/model-generation.md`

### 5.2 Rojo / Lune によるオフライン生成
- 【確定】Rojo と Lune は Rokit で導入するのが公式の推奨（例: rojo 7.6.1、lune 0.10.4）（`docs/projects/external-tools.md` L27-44）。
- 【報道】Lune の `@lune/roblox` は `deserializePlace / serializePlace`（rbxl / rbxm、バイナリと XML）を提供。Rojo 7.7.0 は WebSocket＋MessagePack で同期を高速化 — https://lune-org.github.io/docs/api-reference/roblox
- 【推計】結論: **数千棟の建物モデルをオフライン（Lune スクリプト）で .rbxm として生成 → Rojo の `$path` で Workspace にマウント → `rojo build` で .rbxl → Place Publishing API で公開**、は実現可能。注意点:
  - メッシュアセットそのものは Rojo では作れない。メッシュは Open Cloud で FBX/glTF をアップロードし、得た AssetId を MeshPart の `MeshId` / `MeshContent` に埋める。**少数のモジュール部品メッシュ × 大量の配置（CFrame）** の構成にすれば、アップロードは数十〜数百件で済む。
  - Rojo のライブ同期で数十万インスタンスを Studio に流すのは重い。ワールドは `rojo build` で一括生成するか、.rbxm チャンクごとに分ける。
  - SLIM は Roblox 上に公開済みで Team Create 有効が前提なので、ビルド後に Studio で一度開いて公開またはプレイし、トランスコードさせる必要がある。
  - 100MB 制限: 1 Part あたり約 100〜200 バイト（バイナリ圧縮後）と見積もると、約 50 万パーツが限界帯。地形を併用すると大きく減る。
  - SurfaceAppearance を使う場合は API 公開不可（上記）なので、Studio から公開する。
- 【確定】`ProceduralModel`（`Generator`、`ForceGeneration`、`WaitForGenerationAsync` などのメンバー。API Dump で存在確認）を使うと、パラメータ駆動のモデルを編集時にも実行時にも生成できる（`docs/parts/procedural-models.md`）。
- 【確定】Packages は `docs/projects/assets/packages.md`（建物モジュールを共通化・一括更新）。

---

## 6. 「限界を押し広げる」テクニック ランキング（ソロ開発＋AI の実現性つき）

| 順位 | テクニック | 効果 | 実現性（ソロ＋AI） | 根拠 |
|---|---|---|---|---|
| 1 | **SLIM＋Opportunistic ストリーミング＋モジュール建物（64 スタッド単位）** | 都市の遠景が途切れず、メモリ・描画コールを大幅削減 | ◎ 設定中心で低コスト | 【確定】slim.md、techniques.md |
| 2 | **少数メッシュの大量再利用（インスタンシング）＋標準マテリアル中心のスタイライズ** | 描画コール 1,000 未満を維持 | ◎ アート方針で決まる | 【確定】improve.md、design.md |
| 3 | **Lune による手続き都市のオフライン生成 → Rojo build → Open Cloud 公開** の CI | 数千棟を AI 支援で量産・再生成 | ○ ツールは揃っている。100MB とメッシュアップロードに注意 | 【確定】external-tools.md、usage-place-publishing.md、【推計】 |
| 4 | **Server Authority（移動）＋自前のヒットボックス履歴による巻き戻し（射撃）** | スピード・フライ系チートの根絶と公正な判定 | △〜○ SA の作法（BindToSimulation、IAS、属性）の習得コストが大きい。テンプレートから始める | 【確定】SA docs、【報道】rewind 未搭載 |
| 5 | **建築ピース = アンカー済み同一 MeshPart＋グリッド＋サーバー検証＋BFS による崩壊** | 1 マッチ 1 万ピース級でも軽い | ○ ロジックは単純で AI が書きやすい | 【推計】 |
| 6 | **Parallel Luau（Actor ごとの検証や生成）＋ `--!native`（サーバー）＋ buffer** | サーバー CPU の余裕を確保 | ○ iOS クライアントでは native が効かない点に注意 | 【確定】multithreading.md、native-code-gen.md |
| 7 | **Frustum Streaming（スコープや降下時）** | 遠距離戦闘・スカイダイブ時の視認性 | ◎ 1 行で有効化。メモリ増に注意 | 【確定】frustum.md |
| 8 | **Unreliable＋buffer パックによる独自スナップショット複製（20〜30Hz）** | ストームやエフェクトなど非重要状態の帯域削減 | ○ | 【確定】UnreliableRemoteEvent.yaml |
| 9 | **MemoryStore キュー＋ReservedServerId テレポートによる BR マッチメイク** | ロビー → マッチの分離 | ○ 定番パターン | 【確定】memory-stores、teleport.md |
| 10 | **CreateDataModelContent（サーバーで焼いて複製）による動的メッシュ**（破壊痕、手続き的な装飾） | 実行時に独自形状を全員へ配信 | △ 200MB 上限、初回約 20ms のスパイク、Editable 有効化と ID 認証要件 | 【報道】 |
| 11 | **非同期ボクセル API（`*Async_beta`）による実行時の地形変形** | 爆破クレーターなど | ✕〜△ ベータでドキュメント未記載 | API Dump のみ |
| 12 | **SLIM Avatars** | 50〜100 人戦でのアバター描画コスト削減 | ○ R15 のみ。装備変更が反映されない制限が BR と相性が悪い可能性 | 【確定】slim.md |
| 13 | **GenerateModelAsync（4D 生成）でプレイヤー生成の乗り物や武器** | 話題性 | △ レート制限、20〜40 秒、モデレーション | 【報道】 |
| 14 | **200〜700 人の大規模サーバー** | スケール感 | ✕ ベータ限定でメモリ制約、モバイル不可に近い | 【報道】 |

### 推奨アーキテクチャ（要約）【推計】
- **都市オープンワールド**: 4km 規模を原点中心に配置（±7,000 スタッド）。建物はモジュール化して SLIM。ストリーミングは 64 / 1024、Opportunistic、Improved。サーバー 30〜50 人。重要な NPC や乗り物は SA で予測する。
- **BR＋建築**: マップは 2〜3km 規模（都市の一区画を流用）。1 マッチ 24〜50 人の予約サーバー。移動は SA、射撃は自前の巻き戻し、建築はグリッドとサーバー検証。ストームはサーバー時刻ベースで補間。ロビーは公開サーバーで、MemoryStore キューを使う。

### 未確認事項リスト
- 1 プレイヤーあたり帯域の公式上限値
- Editable* のクライアントメモリ予算の公式数値（ユーザー報告で約 8 メッシュ）
- Editable* の ID 認証要件が正式に撤廃されたか（2026-09 時点では「作業中」）
- 700 人サーバーのベータが現在も募集されているか
- `Terrain:*Async_beta` の一般公開状況
- FastCast の 2026 年時点のメンテナンス状況
- （解決済み）BAN は `Players:BanAsync()` / `GetBanHistoryAsync()`。`BanService` クラスは存在しない
