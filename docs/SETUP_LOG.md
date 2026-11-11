# Windows PC セットアップ結果（2026-11-11）

実行者: PC上の Claude Code（ローカルセッション）。手順は `docs/SETUP_WINDOWS.md`。
環境: Windows 11 Pro 10.0.26200 / リポジトリ `C:\Users\arakaki\roblox`

## まとめ
| 手順 | 結果 |
|---|---|
| 1. Git | ✅ インストール済み（git 2.53.0.windows.2）。作業不要 |
| 2. リポジトリ取得 | ✅ clone 成功（main @ f4de7ed）。GitHub ログイン要求なし |
| 3. Roblox Studio | ✅ インストール済み（0.747 系、`%LOCALAPPDATA%\Roblox\Versions\version-63eb6055af4e4688`）。★ ログイン状態・2段階認証は**未確認**（ユーザー対応待ち） |
| 4. Rokit → ツール一式 | ✅ Rokit 1.2.0 を self-install、`rokit install` で全7ツール導入。Rojo プラグインは代替手段で配置（下記） |
| 5. Studio 内蔵 MCP | ⚠️ 一部のみ。`claude mcp add` で手動登録は済み。Studio 側の「Enable Studio as MCP server」は**未実施**（GUI 操作が必要） |
| 6. 動作確認 | ⚠️ CLI 側のみ確認。Studio での Connect / Play / Output 確認は**未確認** |
| 7. ★ 本人確認 | 未実施（ユーザー対応） |

## 詳細

### 4. Rokit
- `rojo-rbx/rokit` v1.2.0 の `rokit-1.2.0-windows-x86_64.zip` を取得 → `rokit.exe self-install`。
  - `C:\Users\arakaki\.rokit\bin` がユーザー PATH に登録された（新しいターミナルで有効）。
- `rokit trust <7ツール>` → `rokit install`。非対話環境では trust 確認プロンプトが出せないため、先に明示的に trust した。
- 導入結果（`--version` で確認）:
  rojo 7.7.1 / selene 0.32.0 / stylua 2.6.0 / luau-lsp 1.70.1 / lune 0.11.1 / wally 0.3.2 / darklua 0.19.0
- **`rojo plugin install` は失敗**:
  `[ERROR rojo] Couldn't find registry keys, Roblox might not be installed.`
  → `HKCU\Software\Roblox\RobloxStudio` は存在するが、rojo が探す値（ContentFolder 等）が無い。
  → 代替として rojo v7.7.1 リリースの `Rojo.rbxm` を `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` に配置した（`rojo plugin install` と同じ配置先・同じ版）。Studio 上で Rojo ボタンが出るかは**未確認**。

### 5. Studio 内蔵 MCP
- `claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` を実行（スコープ: このプロジェクトの local config）。
- 現時点では `%LOCALAPPDATA%\Roblox\mcp.bat` が**存在しない**ため `claude mcp get` は「Failed to connect」。Studio で MCP サーバーを有効化すると生成される想定（未検証）。
  - Studio のバージョンフォルダには `StudioMCP.exe` がある。
- Studio の画面操作（computer use）は許可されなかったため、Assistant → Manage MCP Servers の操作は行っていない。

### 6. 動作確認（CLI で確認できた範囲）
- `tools/check.sh games/_template` → **全チェック通過**
  - selene: 0 errors / 0 warnings、luau-lsp strict: エラーなし
  - lune tests: **12 passed, 0 failed**
  - rojo build: `games/_template/build/game.rbxl` 生成
- `rojo serve games/_template/default.project.json` → `localhost:34872` で起動することを確認（8秒で停止）。
- Studio 側（Connect、Play、Output の `[Server] DataService started` 等、HUD 表示、コイン増加）は**未確認**。

### 気づいた点（要対応・クラウド側へ）
- **既存コードが stylua 未適用**: `check.sh` の `stylua src tests` で `_template` の5ファイル（HudController / DataService / GameService / MonetizationService / Economy 等）が整形された（column_width 110 超えの行の折り返しのみ、ロジック変更なし）。今回はセットアップの範囲外なので整形結果は破棄し、commit していない。クラウド側で `stylua` を適用して commit するとよい。
- `core.autocrlf=true` の PC で `stylua.toml` が `line_endings = "Unix"` のため、Windows で check.sh を回すと LF/CRLF の警告が出る。`.gitattributes` に `*.luau text eol=lf` を入れると安定する。
- `check.sh` は PATH に `~/.cargo/bin` 等しか足さないので、Windows では `~/.rokit/bin` が PATH に入った状態で Git Bash から実行する必要がある。

## ユーザーに残っている作業（★）
1. Roblox Studio を起動してログイン、2段階認証をオン（設定 → セキュリティ）
2. Studio: Assistant → … → Manage MCP Servers → **Enable Studio as MCP server** をオン、Quick Connect で Claude Code をオン
3. Studio で Baseplate を開き、Rojo プラグインで Connect（先に `rojo serve games/_template/default.project.json`）→ F5 で Output とHUDを確認
4. 公開前に本人確認（ID 認証）
