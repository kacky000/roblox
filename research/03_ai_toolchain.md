# 03. Roblox ゲーム制作の AI 支援ツールチェーン調査（2026-11-04 時点）

対象: 日本の個人クリエイター。構成は「Claude Code（Linux クラウドコンテナ）」と「本人の Windows/Mac PC（Roblox Studio）」の 2 か所。AI に設計・プログラミング・3D モデリングを任せる前提で調べた。

> **調査方法と信頼度について**
> - Roblox 公式ドキュメントは、このコンテナから `create.roblox.com` / `devforum.roblox.com` / `about.roblox.com` に直接アクセスできなかった。代わりに公式ドキュメントの GitHub ミラー **`github.com/Roblox/creator-docs`**（2026-11-04 10:09 UTC コミット＝本日更新）を clone して原文を読んだ。本書の「公式」記述はこの原文が根拠。
> - ツールのバージョンは `git ls-remote --tags` と GitHub Releases ページ（WebFetch）で確認した。
> - api.github.com はこのセッションではリポジトリごとにブロックされている（`gh api` は 403）。github.com のリリースアセット直リンクは HTTP 200 で取得できた。
> - 3D/画像/音声 SaaS の料金とライセンスは公式ページを直接読めず、検索結果（第三者サイト含む）頼り。**契約前に必ず公式規約を確認すること**（各所に注記）。

---

## 0. 結論（TL;DR）

1. **Studio 連携は「Studio 内蔵 MCP サーバー」が本命。** Roblox 公式のスタンドアロン版 `Roblox/studio-rust-mcp-server` は **2026-04-03 にアーカイブ（"END / Product discontinued"）** された。いまは Studio 本体に MCP サーバーが組み込まれていて、Assistant → … → *Manage MCP Servers* → *Enable Studio as MCP server* で有効化できる。Claude Code / Claude Desktop は **Quick Connect** でワンクリック接続できる。
2. 内蔵 MCP の転送方式は **stdio のローカルプロセス**なので、**Studio と同じ PC 上の MCP クライアント**からしか使えない。クラウドコンテナの Claude Code から直接 Studio は操作できない。そこで役割を分ける。
   - **PC 側**: Claude Code（または Claude Desktop）＋ Studio 内蔵 MCP。Studio 内の操作、プレイテスト、スクリーンショット、メッシュ生成を担当。
   - **クラウド側**: Claude Code。git リポジトリの Luau 編集、lint/型検査/整形、Lune による単体テスト、Blender(bpy) によるプロシージャルアセット生成、Open Cloud による公開と Luau 実行テストを担当。
3. コードの同期は **Rojo 7.7.1**（ファイルが正。`rojo build` でコンテナ内でも .rbxl を作れる）を推奨する。もっと軽く済ませたいなら Studio 標準の **Script Sync（ベータ）** でもよい。
4. **Studio を使わない CI も組める。** `rojo build` → Open Cloud *Place Publishing API* で公開 → Open Cloud *Luau Execution API* で実サーバー上のテスト実行、という流れ。ただし SurfaceAppearance / PartOperation（Union）/ EditableMesh などは API 公開で更新されないので、その種の変更は Studio から公開する。
5. 3D は「Roblox 内蔵の生成（Assistant `/generate_mesh`、MCP `generate_mesh`、Texture Generator）」を第一候補にする。追加で、ローポリの小物はクラウドで **bpy（Blender 5.2 の Python モジュール）** からプロシージャル生成し、ヒーロー級のアセットは Meshy / Tripo / Rodin の**有料プラン**（商用権付き）で作って Blender でリトポ・減面する。**1 メッシュあたり 20,000 三角形まで**、テクスチャは**最大 4096×4096**（推奨は大きさに応じて 256〜1024）。
6. **オープンソースの Cube 3D は研究用途限定（RAIL-MS Research-Only）なので、商用ゲームの素材作りには使えない。** 商用で Cube を使いたいなら Studio/Assistant/GenerationService 経由の公式サービスを使う。

---

## 1. Roblox 純正の AI 機能（2026 年版）

### 1.1 Assistant（Studio 内 AI）
- できること: LLM と run-command システムを組み合わせて、データモデルを直接操作する。オブジェクトの挿入と変更、スクリプト作成、一括プロパティ変更、Creator Store の検索と挿入、メッシュ・マテリアル・プロシージャルモデルの生成、仮想入力によるプレイテスト。
- **Planning Mode**: 複雑な依頼を受けると、実行前に計画（小さなゲームデザイン文書）を作る。計画は人が編集できる。
- **Playtesting Agent（ベータ）**: 2026 年 4 月の "Roblox Studio is Going Agentic" で発表された。計画と照らし合わせながら、コード・データモデル・ログを読み、プレイヤーキャラを動かして QA する。
- **BYOK**: Assistant → … → *Manage API Keys* で Anthropic / OpenAI / Google の API キーを入れると、そのモデルで Assistant を動かせる。
- **Skills**: Markdown（フロントマター＋指示）で Assistant に手順や規約を覚えさせられる。Claude Code の skills と似た仕組み。
- スラッシュコマンド: `/generate_mesh`、`/generate_procedural_model`（**24 時間のローリングウィンドウで 50 回まで**）、`/generate_texture`、`/segment_mesh`（インポートしたメッシュを部位に分割。アーリープレビュー）。
- `/generate_mesh` には、テキストか参照画像のどちらか一方を渡す（同時は不可）。選択中の Part をバウンディングボックスとして使える。**最大三角形数を指定でき、既定は 10,000**。
- 生成時にセグメンテーション（最大 8 パーツ）を計画して、4 枚のプレビューから選べる。

### 1.2 Cube 基盤モデル / Mesh Generation / 「4D 生成」
- **Cube 3D**（2025-03 発表）は Roblox のテキスト→3D 基盤モデル。2026-02 に **"4D generation"（ベータ）** が発表された。スキーマで物体を部位に分け、部位ごとに挙動を付ける仕組みで、「走る車」「飛ぶ飛行機」「撃てる武器」のように動く物体を生成できる。
- ゲーム内（ランタイム）API: `GenerationService:GenerateMeshAsync()` / `LoadGeneratedMeshAsync()` / `GenerateModelAsync(inputs, schema)`（例: `PredefinedSchema = "Car5"` で車体 1＋車輪 4）。最大三角形数とバウンディングボックスを指定できる。分単位のレート制限とモデレーションがある。
- 生成 AI をゲームに組み込む場合の規約（公式「Games with Generative AI」）: 出力はコミュニティ規約に従うこと、Content Maturity 質問票で申告すること、AI 会話であることを表示すること。継続会話型や、セッションをまたぐ記憶を持つ AI NPC は **Restricted（18 歳以上）** 扱いになる。

### 1.3 オープンソース版 Cube（github.com/Roblox/cube）
- 公開物: **Cube 3D v0.1**（2025-03）、**v0.5**（2025-07。バウンディングボックス条件付け）、**CubePart**（2026-05。入力メッシュをスキーマ通りの部位に分割する）。重みは HuggingFace の `Roblox/cube3d-v0.5` と `Roblox/cubepart`。リポジトリのスターは約 1.3k。
- 出力は **形状のみ（.obj）で、テクスチャ生成は未公開**（README では "upcoming"）。
- 必要な GPU: **VRAM 16GB 以上（`--fast-inference` を使うなら 24GB）**。動作確認は L40S / H100 / A100 と Apple Silicon M2〜M4（MPS。fast-inference は非対応）。Windows では CUDA toolkit が要る。
- **ライセンス: "CUBE3D RESEARCH-ONLY RAIL-MS LICENSE"。用途は "academic or research purposes only"。** → **商用ゲームのアセット制作には使えない。**
- このクラウドコンテナには GPU がない（`nvidia-smi` なし、4 コア / 15GB RAM）ので、**ここでは実行できない**。PC に RTX 4090 クラスがあれば試せるが、上記ライセンスの都合で研究・評価用途に限られる。

### 1.4 Texture Generator / Material Generator / Avatar Auto-Setup / Code Assist
- **Texture Generator**: メッシュ（または MeshPart の集まり）を選び、テキストか画像で指示する。プレビュー 3 枚が約 10 秒で出る。**Fast = 1K の diffuse（30 秒以内）**、**Quality = 4K の PBR（数分）**。Assistant の `/generate_texture` と MCP からも呼べる。
- **Material Generator**: タイル状の 2D マテリアルを作り、MaterialVariant として保存する。床・壁・地形向け。
- **Avatar Auto-Setup**: 3D モデルを自動でリグ付け・ケージ付け・セグメント化し、アニメーションできる Roblox アバターにする。
- **Code Assist**: スクリプトエディタ内のインライン補完。
- **glTF Export（ベータ）**: Studio から .gltf で書き出せる（アニメーションは非対応）。Blender との往復に便利。

### 1.5 Studio 内蔵 MCP サーバー（公式。最重要）
**場所**: Studio に同梱されていて、別途インストールは不要。
- 有効化: **Assistant → … → Manage MCP Servers → "Enable Studio as MCP server" をオン**。接続中のクライアント数が緑のインジケーターで表示される。
- **Quick Connect に対応するクライアント**: Antigravity / Codex CLI / **Claude Code** / **Claude Desktop** / Cursor / Gemini CLI / VS Code。
- 手動設定（JSON）:
  - Windows: `{"mcpServers":{"Roblox_Studio":{"command":"cmd.exe","args":["/c","%LOCALAPPDATA%\\Roblox\\mcp.bat"]}}}`
  - macOS: `{"mcpServers":{"Roblox_Studio":{"command":"/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"}}}`
- Claude Code の CLI で登録する場合（公式 CLI 文字列を `claude mcp add` 形式にしたもの。この形の Claude Code コマンドは公式ドキュメントに載っていない）:
  - Windows: `claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
  - macOS: `claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
- **公開ツール（公式ドキュメントの一覧）**

| 分類 | ツール |
|---|---|
| スクリプト | `script_read`, `multi_edit`（パスがなければ新規作成）, `script_search`, `script_grep` |
| アセット/生成 | `generate_mesh`, `generate_material`, `generate_procedural_model`, `wait_job_finished`, `search_asset`（Creator Store と自分/グループの在庫を検索）, `insert_asset`, `upload_image`（HTTP URL の画像をまとめてアップロード）, `store_image`（ローカル画像を参照画像として読み込む） |
| データモデル探索 | `subagent`（`explore` / `playtest` 型のサブエージェント）, `search_game_tree`, `inspect_instance` |
| Luau 実行 | `execute_luau`（Edit / Client / Server を指定） |
| プレイテスト | `get_studio_state`, `start_stop_play`, `get_console_output`, `screen_capture`（カメラ位置を指定できる） |
| 入力シミュレーション | `character_navigation`, `user_keyboard_input`, `user_mouse_input` |
| ドキュメント | `http_get`（Roblox 公式ドキュメントのみ取得可）, `skill` |
| セッション | `list_roblox_studios`（複数 Studio の一覧。名前・studio_id・place ID） |

  - すべてのツール呼び出しに `studio_id` を渡す。複数の Studio を同時に開いても、複数エージェントで扱える。
- 経緯: 2026-02「Studio MCP Server Updates and External LLM Support（BYOK）」→ 2026-03-05「Studio Built-in MCP Server and Playtest Automation」→ その後に Screenshot / Mesh Generation ツールの追加 → 「Multi-Agent Improvements and Connected AI Clients」（place ID、接続中クライアントの表示）。
- 注意: MCP クライアントは開いている place を読み書きできる。信頼できるクライアントだけを接続すること。

### 1.6 旧スタンドアロン版（参考）
- `Roblox/studio-rust-mcp-server`: 最後の版は v0.2.365（2026-02-24）、**2026-04-03 にアーカイブ**。ツールは `run_code` / `insert_model` / `get_console_output` / `start_stop_play` / `run_script_in_play_mode` / `get_studio_mode` の 6 個だけ。**新規に導入する理由はない。**

---

## 2. サードパーティ MCP / プラグイン、Rojo ワークフロー

### 2.1 サードパーティ MCP（2026-11 時点）
| 名前 | 最新 | 状態・特徴 |
|---|---|---|
| boshyxd/robloxstudio-mcp | v2.7.0（npm `robloxstudio-mcp` は latest 2.6.0 / next 2.7.0-next.6） | **2026-06-06 にアーカイブ**。作者は fork の Chrrxs 版を推奨。43 ツール、読み取り専用の inspector 版あり。MIT |
| **Chrrxs/robloxstudio-mcp**（npm `@chrrxs/robloxstudio-mcp`） | **v3.4.2（2026-10-26）** | boshyxd 版の後継 fork で活発に保守されている。テスト・デバッグ・Studio 制御。MIT。Studio プラグインと HTTP 許可が必要 |
| 6xvl/robloxstudio-mcp-server（`@6xvl/robloxstudio-mcp`） | 3.5.0（2026-10-20） | 同系統の fork |
| hope1026/weppy-roblox-mcp（`@weppy/roblox-mcp`） | v2.17.21（2026-11-01） | 製品寄り（独自ライセンス）。複数 place、Open Cloud 経由のアセットアップロード、双方向同期。日本語ページあり |
| EL4CTEO/rbx-studio-mcp | v1.0.5（2026-11-03） | 35 ツール、エージェントを動かすコンソールパネル |
| rbx-mcp-hub（DevForum） | — | 複数のゲームを並行して扱うハブ |

**評価**: 公式の内蔵 MCP がスクリプト編集・Luau 実行・プレイテスト・入力シミュレーション・スクショ・メッシュ生成・アセット検索まで揃えたので、サードパーティを使う理由は大きく減った。サードパーティはどれも Studio プラグインを別途入れる必要があり、HTTP の許可も要る。**Claude Code ユーザーには公式内蔵 MCP を推奨する。** 公式にない機能（例: 一括プロパティ検索、属性/タグ操作の専用ツール）が欲しいときだけ、Chrrxs 版の inspector（読み取り専用）を追加すれば十分。

### 2.2 コード同期: Rojo と Script Sync
| | **Rojo 7.7.1** | **Script Sync（Studio 標準・ベータ）** |
|---|---|---|
| 正となるもの | ファイルシステム（プロジェクト全体） | Studio（スクリプトのみディスクへミラー） |
| 同期対象 | スクリプト、モデル(.rbxm/.rbxmx)、JSON、各種インスタンス | Script / LocalScript / ModuleScript / Folder のみ |
| コンテナ内で `.rbxl` をビルド | **可能（`rojo build`）** → Open Cloud で公開できる | 不可 |
| 既存 place の取り込み | `rojo syncback`（7.7.0 で追加） | 右クリック → Sync to… |
| Team Create | 苦手 | 対応 |
| 必要なもの | PC 側で `rojo serve`＋Studio プラグイン（Rojo.rbxm） | Studio のベータ機能を有効化するだけ |
| 命名規則 | `*.server.luau` / `*.client.luau` / `init.luau` など | 同じ規則（`.server` / `.client` / `.local` / `.legacy` / `.plugin`） |

- Rojo 7.7.0（2026-07-02）: `rojo syncback`、WebSocket＋MessagePack 化、`.jsonc` 対応。7.7.1（2026-10-02）: Windows の `\\?\` パス問題を修正。プラグインが api.github.com をブロックされても落ちにくくなった。
- 公式チュートリアル「Build with a coding harness」も **Script Sync＋MCP＋Git** の構成で、VS Code の Claude Code 拡張を例に出している。
- **推奨**: AI がリポジトリを主に編集し、クラウドで CI を回すなら **Rojo**。UI（StarterGui）や配置物は MCP で Studio 側を編集し、必要に応じて `rojo syncback` か .rbxm 書き出しでリポジトリに戻す。
- **Rojo の `serve` は Studio のある PC で動かす必要がある**（Studio プラグインが localhost:34872 に接続するため）。クラウドの Claude Code が push → PC で `git pull` → Rojo が Studio に即反映、という流れになる。

---

## 3. Luau ツールチェーン（最新版と Linux x86_64 バイナリの有無）

| ツール | 最新安定版（日付） | Linux x86_64 バイナリ | 用途 |
|---|---|---|---|
| **rokit** (rojo-rbx/rokit) | **v1.2.0**（2025-09-30） | `rokit-1.2.0-linux-x86_64.zip` ✅ | ツールチェーン管理（aftman/foreman の後継） |
| **rojo** | **v7.7.1**（2026-10-02） | `rojo-7.7.1-linux-x86_64.zip` ✅（crates.io も 7.7.1） | ファイル↔Studio 同期、.rbxl ビルド |
| **wally** | **v0.3.2**（2023-06-05、Latest 扱い）／プレリリース **v0.4.0-alpha.1**（2026-10-12） | `wally-v0.3.2-linux.zip` ✅ / `wally-0.4.0-alpha.1-linux-x86_64.zip` ✅ | パッケージ管理（代替: pesde v0.7.4） |
| **selene** | **0.32.0**（2026-10-01） | `selene-0.32.0-linux.zip` ✅（crates.io は 0.31.0 までしか来ていない） | リンター（`std = "roblox"`） |
| **StyLua** | **v2.6.0**（2026-10-10） | `stylua-linux-x86_64.zip` ✅（musl 版あり） | フォーマッタ |
| **luau-lsp** | **1.70.1**（2026-09-27、Luau 0.740 に追従） | `luau-lsp-linux-x86_64.zip` ✅ | LSP と `luau-lsp analyze`（CI 型検査） |
| **lune** | **v0.11.1**（2026-10-21。HTTPS 証明書の脆弱性修正版なので更新推奨） | `lune-0.11.1-linux-x86_64.zip` ✅ | スタンドアロン Luau ランタイム。`@lune/roblox` で place/model ファイルを読み書き |
| **darklua** | **v0.19.0**（2026-06-10） | `darklua-linux-x86_64.zip` ✅ | Luau の変換・バンドル（string require → Roblox パス変換など） |
| **luau（公式 CLI）** | **0.745**（2026-10-30） | `luau-ubuntu.zip` ✅（`luau` / `luau-analyze` / `luau-compile` など） | 公式インタプリタと解析器 |
| （参考）lute | v1.0.0（nightly は毎日） | — | Luau 公式の汎用ランタイム |
| （参考）rbxcloud CLI | v0.17.0 | crates.io あり | Open Cloud CLI（Sleitnick） |
| （参考）jest-lua | v3.10.0 | — (Wally) | Roblox 内でしか動かない |
| （参考）jest-roblox-cli | v0.4.11（npm `@isentinel/jest-roblox`、2026-11-02） | rokit でも導入可 | Open Cloud / Studio / Studio CLI の 3 つのバックエンドで Jest を実行 |

`rokit.toml` の例（2026-11 時点の最新）:
```toml
[tools]
rojo = "rojo-rbx/rojo@7.7.1"
wally = "UpliftGames/wally@0.3.2"
selene = "Kampfkarren/selene@0.32.0"
stylua = "JohnnyMorganz/StyLua@2.6.0"
luau-lsp = "JohnnyMorganz/luau-lsp@1.70.1"
lune = "lune-org/lune@0.11.1"
darklua = "seaofvoices/darklua@0.19.0"
```

**このクラウドコンテナでの注意**: rokit は GitHub API（api.github.com）でリリースを解決するが、このセッションでは api.github.com がリポジトリ単位でブロックされている。そのため `rokit install` は失敗する可能性が高い（未検証。実行は権限で止めた）。代わりの手段:
- github.com のリリース直リンク（HTTP 200 を確認済み）から zip を取得して展開する
- `cargo install rojo@7.7.1 stylua@2.6.0 lune darklua`（crates.io はプロキシ対象外で使える。selene は crates.io が 0.31.0 止まり）
- 環境設定でネットワーク許可を足すか、`add_repo` でリポジトリへの読み取りアクセスを付ける

**型定義と std**
- luau-lsp は Roblox の型定義（`scripts/globalTypes.d.luau`。セキュリティレベル別に `globalTypes.None` / `PluginSecurity` / `LocalUserSecurity` / `RobloxScriptSecurity` の各 `.d.luau`）を**既定で自動読み込み**する。CLI で使う場合は `luau-lsp analyze --definitions=globalTypes.d.luau --sourcemap=sourcemap.json src/`。sourcemap は `rojo sourcemap default.project.json -o sourcemap.json` で作る。
- selene は `selene.toml` に `std = "roblox"` と書くと Roblox 用の std を自動生成する（`selene generate-roblox-std` でも可）。0.31.0 で `EnumItem:IsA()` と `Enum:FromName()` / `FromValue()` に対応した。

**テストの選択肢**
| 方式 | Studio 要否 | コンテナで実行 | 備考 |
|---|---|---|---|
| Lune で純粋ロジックの単体テスト | 不要 | ✅ | ゲームロジックを Roblox API から切り離して書くのが前提。`@lune/roblox` で Instance ツリーもある程度扱える |
| **Open Cloud Luau Execution API** | 不要 | ✅（API キー） | 実際の Roblox サーバー上で、指定した place のバージョンに対してスクリプトを実行する。物理演算なし、place 内のスクリプトは自動起動しない、変更は保存されない。スクリプト 4MB / 5 分 / 戻り値 4MB / ログ 450KB。同時に未完了でいられるタスクは 1 place あたり 10 件。**タスク作成は API キー所有者あたり 5 回/分**。スコープ `universe.place.luau-execution-session:write`。DataStore を触れるので**テスト用の別 universe を使うこと** |
| jest-roblox-cli（Open Cloud バックエンド） | 不要 | ✅ | Jest 互換。カバレッジや agent 向け出力フォーマットあり |
| run-in-roblox v0.3.0 | 必要（PC） | ✗ | 更新が止まっている |
| Studio 内蔵 MCP（`execute_luau` / `start_stop_play` / `get_console_output` / playtest subagent） | 必要（PC） | ✗ | 実際のプレイテストと入力シミュレーション |

---

## 4. AI 3D モデリング（Roblox 向け）

### 4.1 Roblox のメッシュ・テクスチャ制限（公式ドキュメントで確認）
- **1 メッシュ 20,000 三角形まで**（アバター用アイテムは別に予算がある）。水密であること、厚み 0 は不可、N-gon は避けて可能ならクアッド。
- **テクスチャは最大 4096×4096**（エンジンが低解像度から段階的に読み込む）。推奨の目安は 5×5 スタッドの物体で 256²、10×10 で 512²、20×20 で 1024²。※「1024 上限」は古い情報。
- メッシュに割り当てられるマテリアルは 1 つ。PBR は SurfaceAppearance（ColorMap / NormalMap / MetalnessMap / RoughnessMap）を使う。
- リグ: 1 頂点あたりのボーン影響は 4 本まで。ルートボーンは原点に置き、影響を持たせない。
- **インポート形式（2026）**: 3D Importer は **.fbx / .gltf（.glb）/ .obj**。fbx と gltf は複数メッシュ・階層・PBR・ケージ・リグ・アニメーション・頂点カラーに対応する。画像は .png / .jpg / .gif / .tga / .bmp。
- **Open Cloud Assets API で受け付ける Model**: .fbx / .gltf / .glb / .rbxm / .rbxmx（パッケージとして Model＋MeshPart になる）。1 ファイル 20MB まで。

### 4.2 ツール比較
| ツール | 実行場所 | 費用 | 商用ライセンス | Roblox 向けの評価 |
|---|---|---|---|---|
| **Studio `/generate_mesh` / MCP `generate_mesh`** | Roblox クラウド（Studio から呼ぶ） | 無料（レート制限あり） | Roblox 上で使う分には問題ない | 三角形数・BBox・セグメント化を指定でき、Roblox に直接入る。**第一候補** |
| **Texture Generator** | Roblox クラウド | 無料 | 同上 | 自作メッシュの塗りに使う。4K PBR |
| **headless Blender (bpy)** | **クラウドコンテナ ✅**（PyPI `bpy` 5.2.3、Python 3.13 用。コンテナの Python は 3.13.18） | 無料（GPL のツール。出力物は自分のもの） | ✅ | Claude がコードで建物・家具・岩・道などのローポリを量産できる。三角形数を厳密に管理でき、FBX/glTF で書き出せる。**クラウド側の主力** |
| **MCP for Blender**（旧 blender-mcp、ahujasid/mcp-for-blender、33k★、MIT。PyPI `mcp-for-blender` 2.2.6） | PC（Blender GUI を起動しておく必要あり） | 無料（連携先 API は有料） | 連携先次第 | `claude mcp add blender uvx mcp-for-blender`。Poly Haven / Sketchfab / Poly Pizza / Rodin / Tripo / Hunyuan3D / Meshy と連携。ソケットに認証がないので localhost で使うか SSH トンネル経由にする |
| **Meshy** | SaaS / API | Free 100 クレジット/月、Pro 約 $20/月（第三者情報） | Free は **CC BY 4.0（帰属表示が必要）**、有料は商用可（公式ドキュメントの検索結果より） | リメッシュ・減面・PBR が揃っている。API あり |
| **Tripo**（3.0） | SaaS / API | Pro 約 $12〜20/月、API は 1 モデル約 $0.2〜0.4（第三者情報） | Free は CC BY 4.0 で商用不可、有料は商用可（第三者情報） | 速くて扱いやすい。ローポリ・スマートメッシュ機能 |
| **Rodin / Hyper3D**（Gen-2 / 2.5） | SaaS / API | Creator $30〜/月、API は Business $120/月（第三者情報） | 明記されているのは Business のみ（要確認） | 品質が高い。クアッドトポロジーを出せる |
| **Hunyuan3D-2.1**（オープン重み） | GPU 付き PC | 無料 | **地域条件: EU・英国・韓国を除く（日本は OK）。MAU 100 万超は別途許諾が必要** | 形状 10GB / テクスチャ 21GB / 合計 29GB の VRAM。PBR 対応。3.0 はホスト型サービス |
| **TRELLIS.2**（Microsoft、オープン） | GPU 付き PC（24GB 以上、A100/H100 で検証） | 無料 | **MIT**（依存の nvdiffrast 等は別ライセンス） | 高品質だが出力が高ポリなので減面が必須 |
| **Cube 3D v0.5 / CubePart**（オープン） | GPU 付き PC（16〜24GB） | 無料 | ✗ **研究用途限定** | 商用不可。評価用 |

### 4.3 Roblox 制限内に収める手順（Claude に任せる部分）
1. 生成（SaaS / Studio / bpy）
2. **bpy で後処理**: Decimate（目標 5k〜10k tri）、`bmesh.ops.triangulate` で三角形数を数える、Merge by distance、法線の再計算、原点・スケールの適用（1 スタッド ≒ 0.28m。Roblox のインポート単位設定に合わせる）、UV の再展開とベイク、テクスチャを 512〜1024² に縮小（ヒーロー素材は最大 2048〜4096²）。
3. `.fbx` か `.glb` で書き出す → Studio の 3D Importer（PC）か、Open Cloud Assets API（コンテナ）でアップロードする。
4. **テクスチャ生成 AI の出力は、ゲーム内の見た目のスタイルに合わせて Texture Generator / Material Generator で統一する**のが楽。
5. 衝突判定: MeshPart の CollisionFidelity は Box / Hull を基本にする（物理コストを下げるため）。

---

## 5. AI による 2D アート（サムネイル・アイコン・UI）

### 5.1 画像モデル（2026 年 10 月時点の評価。第三者ランキングに基づく）
| モデル | 強み | 注意 |
|---|---|---|
| **GPT Image 2 / 2.5**（OpenAI） | 指示への忠実さと文字の描画。総合トップ評価 | API 従量課金。OpenAI 規約では出力の権利は利用者に帰属 |
| **Nano Banana Pro / Nano Banana 2**（Google Gemini 画像） | 4K 出力、反復が速い、編集 | 生成画像に SynthID の透かしが入る |
| **Midjourney V8.1** | 美しさ、キービジュアル | 有料プラン必須。一定以上の収益がある事業者は Pro 以上が必要 |
| **FLUX.2**（Black Forest Labs） | オープン重みで最良。[klein] は一般向け GPU でも動く | 重みのライセンスがバリアントごとに違う（dev 系は非商用重み）。確認が必要 |
| **Ideogram 4.5**（2026-09-30） | ロゴ・タイポグラフィ | — |
| Roblox Ads Manager「AI generate」 | 広告用サムネイルを 3 案生成 | 広告キャンペーン専用 |

### 5.2 Roblox 側のルール（公式ドキュメント）
- **サムネイル**: 16:9、推奨 1920×1080、3MB 以下。最大 10 枚。2 枚以上を有効にすると**サムネイルのパーソナライズ（A/B 最適化）**が働く。**下端は人数表示などのメタデータで隠れることがある**ので、重要な要素を置かない。
- **アイコン**: 正方形 512×512 で、150×150 まで縮んでも判読できるようにする。ジャンルと雰囲気が伝わる絵にする。
- **動画サムネイル**: 実際のゲームプレイだけを使う。ナレーションや歌詞入りの音楽は不可。「50% OFF」「Free UGC!」のような宣伝文句は不可。実写の人物や場所は不可。
- **ディスカバリー**: 「誤解を招く、または中身と一致しないメタデータ」や「ギブアウェイを前面に出すこと」は露出低下の対象。→ **AI 画像を使う場合も、実際のゲームに存在する要素だけを描く**。
- すべての画像はモデレーション対象で、コミュニティ規約に従う必要がある。**実在の人物、他社の IP やキャラクター、ブランドロゴ、他ゲームに似た絵**は使わない（AI 出力でも著作権・肖像権・商標の責任はクリエイターにある）。
- 実務のおすすめ: **ゲーム内のスクリーンショット（MCP の `screen_capture` か freecam: Shift+P）を下敷きにして、画像モデルで「整える」**。完全な捏造ではなく、実際の画面から作ったキービジュアルにする。

---

## 6. AI 音声・音楽・効果音と Roblox の音声ルール

### 6.1 Roblox の音声アップロード（公式ドキュメント）
- 形式は .mp3 / .ogg / .wav / .flac。**20MB 未満かつ 7 分以内**、48kHz 以下、モノラル〜5.1ch。
- **アップロード上限**: Audio ドキュメントでは **ID 認証済みなら 30 日で 2,000 件、未認証なら 100 件**（無料）。※Open Cloud Assets ガイドの表には「認証済み 100 件/月、未認証 10 件/月」という古い記述が残っていて、ドキュメント間で食い違っている。**本人確認（ID verification）は済ませておく。**
- **プライバシー**: アップロードした音声は既定で非公開。アセット権限システムで、特定のゲームや友達に使用権を与える。
- 自動分類（効果音か曲か）: 効果音は Creator Store で配布できる。曲は条件（ID 認証、Audio Terms 同意、モデレーションと著作権チェック通過など）を満たすとゲーム詳細ページに表示される。
- 公式ルールとして「**その音声の法的な権利を持っていること**」が条件になっている。

### 6.2 AI 音声サービスのライセンス（第三者情報が中心。必ず公式規約を確認）
| サービス | 無料プラン | 有料プラン | Roblox で使うときの推奨 |
|---|---|---|---|
| **ElevenLabs**（SFX / 音声 / 音楽） | 商用利用不可（公式 SFX ページでは「無料プランは elevenlabs.io への帰属表示が必要」との記載あり） | Starter（約 $6/月）以上で商用可。**サブスク加入中に生成したものだけ**が対象 | 効果音・ボイスは**有料プラン加入中に生成**して保存しておく |
| **Suno** | 非商用のみ。**後から加入しても、過去の生成物に遡って権利は付かない** | Pro / Premier で商用可。2025 年末の WMG 和解後に規約が変わり、「所有権」か「永続ライセンス」かは情報源によって食い違う | BGM 用途なら有料で生成する。**実在アーティスト風の指示は避ける** |
| Roblox 公式の音声ライブラリ | — | 無料 | Creator Store のライセンス済み音楽・効果音（動画サムネイルにも使える）が最も安全 |
| Roblox `AudioTextToSpeech` | — | 無料 | ゲーム内のナレーションや UI 読み上げに使える |

---

## 7. Open Cloud API（Studio なしで公開・アップロード・実行）

| API | エンドポイント | スコープ | 用途 / 制限 |
|---|---|---|---|
| **Place Publishing** | `POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`（.rbxl は `application/octet-stream`、.rbxlx は `application/xml`） | `universe-places:write` | `rojo build` の成果物を CI から公開する。`versionType=Saved` なら保存のみ。**EditableImage / EditableMesh / PartOperation / SurfaceAppearance / BaseWrap は API 公開では更新されない** |
| **Assets** | `POST /assets/v1/assets`（multipart）, `PATCH /assets/v1/assets/{id}`, `GET /assets/v1/operations/{id}` | `asset:read`, `asset:write` | 1 ファイル 20MB まで。Model（fbx / gltf / glb / rbxm）、Decal/Image（png / jpeg / bmp / tga、8000px 未満）、Audio（mp3 / ogg / wav / flac、7 分以内）、Video（mp4 / mov）、Animation（rbxm）。Mesh 単体はアップロード不可（Model として上げる） |
| **Luau Execution** | `POST /cloud/v2/universes/{u}/places/{p}[/versions/{v}]/luau-execution-session-tasks` → `GET .../tasks/{id}` と `.../logs` | `universe.place.luau-execution-session:write` | 3 章の通り。テスト・データ移行・検証に使う。**5 回/分** |
| **DataStores v2** | `/cloud/v2/universes/{u}/data-stores/{ds}/entries[...]`（get / list / create / patch / delete / increment / listRevisions） | `universe-datastores...` | セーブデータの調査・修正、ローンチ前のリセット |
| その他 | Messaging、Secrets Store、Configs、Developer Products / Game Passes、Experience Notifications、Analytics | — | 運用の自動化 |

- API キーは Creator Dashboard で作成する。**IP 許可リスト（クラウドコンテナの出口 IP は変わりうるので 0.0.0.0/0 にするか、CI 側で制御する）と有効期限を設定する**。権限は対象 universe だけに絞る。
- キーはリポジトリに入れない。環境のシークレット（`ROBLOX_API_KEY`）として保存する。
- クラウドコンテナから `apis.roblox.com` に届くかは**ネットワーク許可の設定次第**。今回の調査では roblox.com 系のドメインが名前解決できなかったので、**環境のネットワーク設定に `apis.roblox.com`（と必要なら `create.roblox.com`）を追加する必要がある**。
- 便利な CLI: `rbxcloud` v0.17.0（Rust 製。publish、asset、datastore、messaging に対応）。

---

## 8. 推奨スタック（役割と実行場所）

| ツール | 目的 | 実行場所 | 費用 | 最新版（2026-11-04） |
|---|---|---|---|---|
| Claude Code（クラウド） | 設計書、Luau 実装、テスト、アセットのスクリプト生成、CI | クラウドコンテナ | Claude のプラン | — |
| Claude Code / Claude Desktop（ローカル） | Studio 操作、プレイテスト、UI 構築 | 本人 PC | 同上 | — |
| **Roblox Studio＋内蔵 MCP サーバー** | Studio を AI から操作（Quick Connect） | 本人 PC | 無料 | Studio 同梱（自動更新） |
| Roblox Assistant（＋BYOK、Skills、Planning、Playtest Agent） | Studio 内の補助、メッシュ・テクスチャ生成 | 本人 PC（処理は Roblox クラウド） | 無料（BYOK は API 料金） | — |
| **Rojo** | ファイル↔Studio 同期、`rojo build` | serve は PC、build はコンテナ | 無料（MPL-2.0） | **7.7.1** |
| Script Sync（代替） | 簡易なスクリプト同期 | 本人 PC | 無料 | Studio ベータ機能 |
| **rokit** | ツールのバージョン固定 | 両方 | 無料 | **1.2.0** |
| **wally**（または pesde） | パッケージ管理 | 両方 | 無料 | **0.3.2**（0.4.0-alpha.1） |
| **selene** | lint | コンテナ（CI）＋エディタ | 無料 | **0.32.0** |
| **StyLua** | 整形 | コンテナ（CI）＋エディタ | 無料 | **2.6.0** |
| **luau-lsp** | 型検査（`analyze`）、LSP | コンテナ（CI）＋エディタ | 無料 | **1.70.1** |
| **lune** | 単体テスト、place ファイル操作スクリプト | コンテナ | 無料 | **0.11.1** |
| darklua | バンドルと変換 | コンテナ | 無料 | 0.19.0 |
| luau CLI | 公式解析器と REPL | コンテナ | 無料 | 0.745 |
| jest-lua / jest-roblox-cli | Roblox 上の統合テスト（Open Cloud） | コンテナ→Roblox | 無料（API 制限内） | 3.10.0 / 0.4.11 |
| Open Cloud（Place Publishing / Assets / Luau Execution / DataStores）＋ rbxcloud | Studio なしの公開とアップロード | コンテナ / CI | 無料 | rbxcloud 0.17.0 |
| **bpy（headless Blender）** | プロシージャルなローポリ生成、減面、FBX/GLB 書き出し | コンテナ | 無料 | bpy 5.2.3 |
| MCP for Blender | Blender GUI を AI で操作し、外部 3D 生成と連携 | 本人 PC | 無料（連携先は有料） | PyPI mcp-for-blender 2.2.6 / blender-mcp 2.0.0 |
| Meshy / Tripo / Rodin | ヒーロー級アセットの生成 | SaaS | 月 $12〜120 程度（有料プランで商用可） | — |
| Hunyuan3D-2.1 / TRELLIS.2 | ローカルでの 3D 生成（任意） | GPU 付き PC（VRAM 24〜29GB） | 無料（各ライセンス要確認） | — |
| GPT Image 2.x / Nano Banana Pro / Ideogram 4.5 | サムネイル、アイコン、UI | SaaS / API | 従量またはサブスク | — |
| ElevenLabs / Suno（有料） | 効果音、ボイス、BGM | SaaS | $6〜/月 | — |

### 推奨ワークフロー
```
[クラウド Claude Code]
  ├─ docs/ にゲームデザイン（GDD）
  ├─ src/ に Luau（Rojo 構成）→ selene / stylua / luau-lsp analyze / lune テスト
  ├─ assets/ に bpy スクリプト → .glb / .fbx を書き出し（20k tri 未満を CI で検査）
  ├─ rojo build → test.rbxl → Open Cloud で「テスト用 place」に Saved 公開
  │     → Luau Execution で統合テストを実行し、結果を JSON で受け取る
  └─ git push
[本人 PC]
  ├─ git pull → rojo serve → Studio（Rojo プラグイン）に即反映
  ├─ Claude Code（ローカル）＋ Studio 内蔵 MCP（Quick Connect）
  │     → UI 構築、配置、generate_mesh / texture、playtest subagent、screen_capture
  └─ 最終確認後、Studio から本番 place に公開（SurfaceAppearance などは Studio 公開が必要）
```
- 補足: Claude Code のクラウドセッションには、本人 PC のフォルダを Remote Control 経由でつなぎ、そこでコマンドを実行する機能がある（アカウントや環境によっては使えない）。これが使えれば、クラウド側から PC の `git pull` や `rojo serve` を動かせる可能性がある。ただし Studio 内蔵 MCP は PC 上の MCP クライアントにつなぐ前提なので、**Studio 操作はローカルの Claude Code で行うのが確実**。

### 推奨 MCP 設定（PC 側の Claude Code）
1. Studio を最新版に更新 → Assistant → … → Manage MCP Servers → **Enable Studio as MCP server** をオン → Quick connect で **Claude Code** をオン（または下のコマンドで登録）。
   - Windows: `claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
   - macOS: `claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
2. （任意）Blender: `claude mcp add blender uvx mcp-for-blender` → `uvx mcp-for-blender install-addon` → Blender のサイドバーからサーバーを起動。
3. （任意、読み取り専用の補助）`claude mcp add robloxstudio-inspector -- npx -y robloxstudio-mcp-inspector@latest`。本体は 2026-06 にアーカイブされたので、使うなら fork の `@chrrxs/robloxstudio-mcp`（v3.4.2）の導入手順を確認する。
4. 旧 `studio-rust-mcp-server` は**入れない**（アーカイブ済みで、内蔵版と重複する）。

---

## 9. リスクと注意点
- **Cube（オープン版）は研究用途限定**。Hunyuan3D は地域と MAU の条件付き。FLUX は重みのライセンスがバリアントごとに違う。各 SaaS は**無料プランだと商用不可か帰属表示が必要**。生成した時点で加入していたプランが基準になる（ElevenLabs / Suno）。
- AI で作った素材でも、権利侵害やモデレーション違反の責任はクリエイターにある。生成時のプロンプトとプランのスクリーンショットを素材台帳に残す（例: `assets/LICENSES.md`）。
- 内蔵 MCP は place を自由に書き換えられる。**作業は Rojo/git で管理し、本番 place に直接つながない**運用を勧める（テスト place → 本番公開）。
- Open Cloud の Luau Execution は DataStore を変更できる。テスト専用の universe を作って分ける。
- 3D/画像/音声 SaaS の料金は 2026 年に何度も改定されている（例: Tripo の上位プランが 2026-08 に値上げ）。公式ページで再確認する。

---

## 10. 出典（Sources）

**Roblox 公式（creator-docs の GitHub ミラーで原文確認。2026-11-04 版）**
- Studio MCP server: https://create.roblox.com/docs/studio/mcp （原文: https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md ）
- Assistant ガイド（mesh / procedural / segmentation / Planning Mode）: https://create.roblox.com/docs/assistant/guide
- Assistant MCP / BYOK: https://create.roblox.com/docs/assistant/mcp ／ Skills: https://create.roblox.com/docs/assistant/skills
- Build with a coding harness（Script Sync＋MCP＋Git）: https://create.roblox.com/docs/ai/coding-harness
- AI on Roblox（一覧）: https://create.roblox.com/docs/ai/accelerated-workflows
- Script Sync: https://create.roblox.com/docs/scripting/sync ／ Third-party tools（Rojo / Rokit / Wally）: https://create.roblox.com/docs/projects/external-tools
- Model generation（GenerateModelAsync / 4D）: https://create.roblox.com/docs/parts/model-generation ／ GenerationService: https://create.roblox.com/docs/reference/engine/classes/GenerationService
- Texture Generator: https://create.roblox.com/docs/studio/texture-generator ／ Avatar Auto-Setup: https://create.roblox.com/docs/avatar-setup
- Games with Generative AI: https://create.roblox.com/docs/generative-AI
- Modeling specifications（20,000 tri）: https://create.roblox.com/docs/art/modeling/specifications ／ Texture specs（4096²）: https://create.roblox.com/docs/art/modeling/texture-specifications
- 3D Importer（fbx / gltf / obj）: https://create.roblox.com/docs/studio/importer ／ glTF Export: https://create.roblox.com/docs/art/modeling/gltf-export
- Studio CLI: https://create.roblox.com/docs/studio/cli
- Place Publishing: https://create.roblox.com/docs/cloud/guides/usage-place-publishing ／ Assets API: https://create.roblox.com/docs/cloud/guides/usage-assets ／ Open Cloud OpenAPI（Luau Execution / DataStores）: https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/cloud/openapi.json
- Audio assets: https://create.roblox.com/docs/audio/assets ／ Thumbnails: https://create.roblox.com/docs/production/publishing/thumbnails ／ Icons: https://create.roblox.com/docs/production/publishing/experience-icons ／ Discovery FAQ: https://create.roblox.com/docs/discovery-faq
- DevForum 発表: https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631 ／ https://devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643 ／ https://devforum.roblox.com/t/assistant-updates-mesh-generation-new-mcp-server-tools-screenshot-tool-and-more/4527258 ／ https://devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583
- Newsroom: https://about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic ／ https://about.roblox.com/newsroom/2026/02/accelerating-creation-powered-roblox-cube-foundation-model ／ https://www.pocketgamer.biz/roblox-launches-4d-generation-creation-feature-enters-beta/ ／ https://windowsreport.com/roblox-studio-gets-planning-mode-ai-and-automated-playtesting-tools/

**GitHub / パッケージ（バージョン確認）**
- https://github.com/Roblox/studio-rust-mcp-server （2026-04-03 アーカイブ）
- https://github.com/Roblox/cube （LICENSE: Research-Only RAIL-MS）／ https://huggingface.co/Roblox/cube3d-v0.5
- https://github.com/rojo-rbx/rokit/releases ／ https://github.com/rojo-rbx/rojo/releases ／ https://github.com/UpliftGames/wally/releases ／ https://github.com/Kampfkarren/selene/releases ／ https://github.com/JohnnyMorganz/StyLua/releases ／ https://github.com/JohnnyMorganz/luau-lsp/releases ／ https://github.com/lune-org/lune/releases ／ https://github.com/seaofvoices/darklua/releases ／ https://github.com/luau-lang/luau/releases ／ https://github.com/luau-lang/lute
- https://github.com/jsdotlua/jest-lua ／ https://github.com/christopher-buss/jest-roblox-cli ／ https://github.com/rojo-rbx/run-in-roblox ／ https://github.com/Sleitnick/rbxcloud
- https://github.com/boshyxd/robloxstudio-mcp （2026-06-06 アーカイブ）／ https://github.com/Chrrxs/robloxstudio-mcp ／ https://www.npmjs.com/package/@chrrxs/robloxstudio-mcp ／ https://github.com/hope1026/weppy-roblox-mcp ／ https://github.com/EL4CTEO/rbx-studio-mcp ／ https://devforum.roblox.com/t/tool-rbx-mcp-hub-%E2%80%94-work-on-multiple-roblox-games-at-once-with-claude-code-cursor-codex-and-other-ai-agents/4582579
- https://github.com/ahujasid/mcp-for-blender ／ https://pypi.org/project/bpy/ （5.2.3）／ https://pypi.org/project/mcp-for-blender/
- https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1 ／ https://huggingface.co/tencent/Hunyuan3D-2/blob/main/LICENSE ／ https://github.com/microsoft/TRELLIS.2

**3D / 画像 / 音声 SaaS（料金とライセンス。第三者情報を含むので要確認）**
- Meshy: https://meshy.ai/pricing ／ https://docs.meshy.ai/en/webapp/pricing ／ https://costbench.com/software/ai-3d-generation/meshy/free-plan/
- Tripo: https://costbench.com/software/ai-3d-generation/tripo-ai/ ／ https://costbench.com/changelog/tripo-ai-price-increase-2026-08/
- Rodin / Hyper3D: https://hyper3d.ai/pricing ／ https://costbench.com/software/ai-3d-generation/rodin-hyper3d/
- Hunyuan 3D 3.0: https://www.notebookcheck.net/Tencent-s-new-Hunyuan-3D-3-0-brings-realistic-AI-model-generation-to-developers-and-creators.1116964.0.html
- 画像モデル比較: https://journal.everypixel.com/best-ai-image-models-2026 ／ https://budgetpixel.com/learn/best-ai-image-generators ／ https://tech-insider.org/best-ai-image-generator-2026/
- ElevenLabs SFX: https://elevenlabs.io/sound-effects/commercial ／ https://www.costbench.com/software/ai-voice-tools/elevenlabs/free-plan/
- Suno: https://www.musicinafrica.net/magazine/suno-adjusts-ai-music-ownership-terms-after-warner-music-partnership ／ https://blog.dubspot.com/ai-music-licensing-explained-2026 ／ https://terms.law/ai-output-rights/suno/
