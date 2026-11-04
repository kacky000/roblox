# Roblox Studio Workspace — AI開発ルール

目的：ソロ＋AIで Roblox ゲームを企画・実装・3D制作・運営し、収益化すること。
回答は日本語で、結論から書く。俯瞰（市場・事業）と専門（実装・規約）の両方の視点を持つ。

## どのスキルを使うか
| 作業 | スキル |
|---|---|
| 企画、評価、GDD、続けるか撤退するかの判断 | `roblox-game-concept` |
| Luau の実装、修正、レビュー | `roblox-luau-systems` |
| 3D アセット | `roblox-3d-assets` |
| 公開、サムネイル、KPI、週次運営 | `roblox-launch-liveops` |
| Studio 連携、MCP、Rojo、Open Cloud | `roblox-studio-mcp` |

## ディレクトリ
- `research/`：市場（01）、スタジオの手法（02）、AIツールチェーン（03）の調査。数値は 2026-11 時点で、【確定／報道／推計】のラベル付き
- `docs/roblox-creator-docs/`：Roblox 公式ドキュメントの本文（CC BY 4.0）。**API や仕様は推測せず、ここを grep して確認する**
- `games/_template/`：Rojo テンプレート（データ保存、課金、ガチャ、経済、レート制限）
- `games/<slug>/`：各ゲーム。`GDD.md`、`CHANGELOG.md`、`assets.md` を置く
- `tools/check.sh <game>`：品質ゲート。**コードを変えたら必ず実行し、通るまで完了としない**
- `tools/new_game.sh <slug>`：新規ゲームを作る
- `tools/blender/rbx_assets.py <spec.json>`：ローポリアセットを生成する（`.venv/bin/python` で実行）
- `tools/roblox-api/`：luau-lsp 用の型定義と API ダンプ（取得元は raw.githubusercontent.com）

## 環境（クラウドコンテナ）
- PATH：`$HOME/.cargo/bin:$HOME/.local/bin`
- 入っているツール：rojo 7.7.1、selene 0.31（ローカル API ダンプを読めるようパッチ済み。`SELENE_API_DUMP_FILE`）、stylua 2.6.0、lune 0.11.1、darklua 0.19.0、wally 0.3.2、luau-lsp 1.70.1、luau 0.745、bpy 5.2.3（`.venv`）
- ネットワーク：GitHub（raw と release）、crates.io、npm、PyPI には届く。**roblox.com 系（apis.roblox.com を含む）は未許可**
- コンテナは使い捨て。成果物は必ず git で push する（リモート未設定ならユーザーに確認する）

## 不変のルール
1. サーバー権威：リモートは `Net.onServer` で受け、型・回数・範囲を検証する
2. データ：変更は `DataService.update` 経由で行う。スキーマ変更時はバージョンを上げて移行処理を書く。公開後は DataStore 名を変えない
3. 課金：ProcessReceipt は冪等にする。価格は動的に取得する。有料ランダムアイテムは確率を表示し、PolicyService で制限する。虚偽の希少性表示はしない
4. IP：他社 IP、実在の人物、既存作のアート・名前・UI・サムネイルを模倣しない。ジャンルに乗るのは良いが、表現はオリジナルにする
5. 子ども向けの安全：チャットに依存しない設計にする。成熟度ラベルを正しく付ける
6. 報告は正直に：クラウドで検証できるのはテストとビルドまで。Studio での実機確認が必要なものは「未確認」と明記する
