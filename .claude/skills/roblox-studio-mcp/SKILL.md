---
name: roblox-studio-mcp
description: Roblox Studio を AI(Claude Code)から操作する方法と、クラウド側/PC側の役割分担。Studio内蔵MCPサーバー(Quick Connect)、Rojo同期、プレイテスト自動化、Open Cloud API(公開/アセット/Luau実行)。「Studioで確認」「Studioにつなぐ」「MCP」「Rojo」「公開(publish)」「プレイテスト」で必ず使う。
---

# Studio 連携スキル

## 役割分担（重要）
Studio 内蔵の MCP は stdio 方式のローカルプロセスで、**Studio と同じPCの Claude Code からしか接続できない**。

| 場所 | 担当 |
|---|---|
| **クラウド（このコンテナ）** | 企画書、Luauの実装、lint・型チェック・テスト（`tools/check.sh`）、bpyによる3D生成、`rojo build`、git push、Open Cloud（ネットワーク許可を設定した後） |
| **本人PC** | git pull → `rojo serve` → Studio に即反映。PC の Claude Code ＋ Studio MCP で、UIの配置、見た目の確認、プレイテスト、generate_mesh、スクリーンショット、本番公開 |

## PC側の初期設定（ユーザーに案内する手順）
1. Roblox Studio を最新にし、Claude Code をPCに入れる。
2. ツールを入れる：Rokit を入れてから、`rokit add rojo-rbx/rojo@7.7.1` など（selene, stylua, luau-lsp, lune, wally）。VS Code には Rojo と Luau LSP の拡張を入れる。
3. Studio で、Assistant → … → Manage MCP Servers → **Enable Studio as MCP server** をオンにし、Quick Connect で **Claude Code** をオンにする。手動で登録する場合は次のとおり。
   - Windows：`claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat`
   - macOS：`claude mcp add --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP`
   - （この `claude mcp add` 形式は、公式のパスを元に組み立てたもの。Quick Connect のほうが確実）
4. Rojo の Studio プラグインを入れる → `rojo serve games/<slug>/default.project.json` → プラグインで Connect。
5. （任意）Blender MCP：`claude mcp add blender uvx mcp-for-blender`
6. 旧 `studio-rust-mcp-server` は入れない（2026-04 にアーカイブ済み）。

## 内蔵 MCP の主なツール（PC側で使う）
- スクリプト：script_read / multi_edit / script_search / script_grep
  - Rojo 管理下のスクリプトは**ファイル側が正**。Studio 上で直接編集しない。
- 生成：generate_mesh / generate_material / generate_procedural_model / wait_job_finished / search_asset / insert_asset / upload_image
- 実行：execute_luau（Edit / Client / Server）
- テスト：start_stop_play / get_console_output / screen_capture / character_navigation / user_keyboard_input / user_mouse_input / subagent(playtest)
- すべての呼び出しに `studio_id` を渡す（list_roblox_studios で取得）。

## PC側 Claude Code でのプレイテストの手順
1. `start_stop_play` で開始する。
2. `character_navigation` などで操作する。
3. `get_console_output` でエラーを確認する。
4. `screen_capture` で見た目を確認する。
5. 停止する。

## Open Cloud（Studio なしで公開・テスト）
- 前提：
  - Creator Dashboard で API キーを作る（対象 universe に限定し、期限を付ける）。
  - 環境シークレット `ROBLOX_API_KEY` に保存する。
  - 環境のネットワーク許可に `apis.roblox.com` を追加する。2026-11 時点のこの環境では未許可なので、`read_documentation`（environment.network / environment.secrets）で設定方法を案内する。
- Place の公開：`POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved`（テストは Saved、本番は Published）。ヘッダは `x-api-key`。ボディは .rbxl（`application/octet-stream`）。
  - SurfaceAppearance / Union / EditableMesh は API 公開では更新されないので、Studio から公開する。
- Luau の実行（統合テスト）：`POST /cloud/v2/universes/{u}/places/{p}/luau-execution-session-tasks` → task をポーリング → logs。5回/分、5分、4MB まで。
- CLI：`rbxcloud`（Rust 製）が便利。

## 公式ドキュメント
`docs/roblox-creator-docs/` に公式 creator-docs の本文（md/yaml）がある。出典は `SOURCE_COMMIT.txt` に記載。
- MCP：`docs/roblox-creator-docs/studio/mcp.md`（ファイル名は grep で探す：`grep -rli "mcp server" docs/roblox-creator-docs | head`）
