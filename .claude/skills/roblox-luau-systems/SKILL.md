---
name: roblox-luau-systems
description: Roblox(Luau)のゲームシステムを実装・修正・レビューする。新規ゲームの雛形作成、データ保存(DataStore)、課金(GamePass/DevProduct/ProcessReceipt)、ガチャ、経済、RemoteEventのセキュリティ、UI、テストを扱う。.luau ファイルを書く/直す時、「実装して」「機能追加」「バグ」「セーブ」「課金」などで必ず使う。品質ゲート tools/check.sh を通すまで完了としない。
---

# Roblox Luau 実装スキル

## プロジェクト構成（Rojo）
新規ゲームは `tools/new_game.sh <slug>` で `games/_template` を複製して作る。
```
games/<slug>/
  default.project.json      Rojoのツリー（Shared→ReplicatedStorage, Server→ServerScriptService, Client→StarterPlayerScripts）
  src/shared/Config/        GameConfig.luau（バランスの数値はここだけに置く）, Products.luau（課金ID）
  src/shared/Lib/           純粋関数（Economy, WeightedRandom, RateLimiter, DataTemplate）→ Luneでテストできる
  src/shared/Net.luau       リモートの定義と型検証つきの onServer
  src/server/Services/      DataService → MonetizationService → GameService（起動順は init.server.luau）
  src/client/Controllers/   UIと入力。サーバーには「要求」だけを送る
  tests/run.luau            Lune テスト
```

## 品質ゲート（必須）
`tools/check.sh games/<slug>` を実行する。stylua → selene → luau-lsp strict 型検査 → lune テスト → rojo build の順に走る。
失敗したら直してから報告する。型エラーを `:: any` で黙らせるのは最小限にとどめ、理由をコメントに書く。

## 絶対ルール（セキュリティ・データ）
1. **サーバーが権威を持つ。** 通貨・抽選・判定は全部サーバーで行う。クライアントからは「〜したい」という要求だけを送る。
2. **リモートは必ず `Net.onServer(name, argTypes, handler)` で受ける。**
   - 型・長さ・NaN/inf をチェックする。
   - `RateLimiter` で連打を防ぐ。
   - 値の範囲と所持状況はハンドラ内で再確認する。
3. **データの変更は `DataService.update(player, fn)` だけで行う。**
   - スキーマを変えるときは `DataTemplate.VERSION` を上げ、`MIGRATIONS` に移行関数を追加する。
   - キーを消したり型を変えたりしない。
   - 公開後は `GameConfig.DataStoreName` を変えない。
4. **ProcessReceipt**
   - PurchaseId で冪等にする。
   - 付与→保存が終わってから `PurchaseGranted` を返す。
   - 不明な状態なら `NotProcessedYet` を返す（テンプレート実装済み）。
5. **有料ランダムアイテム（Robuxか、Robuxで買える通貨を使う抽選）**
   - 購入前に全結果の確率を表示する（`WeightedRandom.oddsTable`）。
   - luckブーストがあるときは、ブースト後の確率を表示する。
   - `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` が真のユーザーには販売しない（取得に失敗したら規制ありとして扱う）。
6. **価格をハードコードしない。** UIでは `MarketplaceService:GetProductInfo` で取得する（Managed Pricing / 地域別価格への追従）。
7. **「残りわずか」など虚偽の希少性を表示しない。**
8. **チャットに依存しない。** 年齢確認でチャットできない層がいるので、定型文、エモート、トレードUIを用意する。

## パフォーマンス（モバイルが過半）
- `StreamingEnabled` はオン（テンプレートは設定済み）。
- 毎フレームの処理は最小限にする。サーバーのtickは1秒単位でまとめる。
- クライアントへのpushは差分か低頻度にする。テンプレートの毎秒pushは雛形なので、規模が大きくなったら差分化する。
- 大量のNPCや弾は、ECS（Jecs）や、表示をクライアント・判定をサーバーに分ける構成を検討する。
- MeshPartの `CollisionFidelity` は Box/Hull にする。装飾品は `CanCollide=false`、`CanQuery=false`、`CanTouch=false` にする。

## 推奨ライブラリ（Wally。必要になったら導入）
| 用途 | ライブラリ |
|---|---|
| データ保存 | ProfileStore（loleris）。大規模化したら DataService の中身を置き換える。インターフェースは get / update / waitFor のまま |
| ネットワーク | Blink / Zap（IDLからコード生成、帯域を削減） |
| UI | React-lua / Fusion / Vide |
| テスト | Jest-Lua（Roblox上で実行。Open Cloud Luau Execution API でCIから動かす） |

Knit は2024年にアーカイブ済みなので新規には使わない。

## Roblox APIの確認方法
推測で書かず、ローカルの公式ドキュメントで確認する。
- `docs/roblox-creator-docs/reference/engine/classes/<ClassName>.yaml`：APIの定義
- `docs/roblox-creator-docs/**/*.md`：ガイド
- 例：`grep -rl "ProcessReceipt" docs/roblox-creator-docs | head`

型定義は `tools/roblox-api/globalTypes.d.luau`、APIダンプは `tools/roblox-api/API-Dump.json`。

## Studio でしか確かめられないこと
物理、見た目、UIの配置、実際のDataStore、課金のプロンプト。
これらは本人のPCで確認してもらう。手順は `roblox-studio-mcp` スキル。
クラウド側では「Luneのテストが通った」「rojo build に成功した」ところまでを保証範囲として、正直に報告する。
