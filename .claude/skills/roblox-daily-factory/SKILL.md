---
name: roblox-daily-factory
description: 毎日1本以上ゲームを作り、数字で判定し、伸びているものを更新する日次ファクトリーを回す。「今日の分」「日次」「毎日作る」「ファクトリー」「量産」「数字をチェックして」「伸びているものを更新」で必ず使う。スケジュール実行のときもこの手順に従う。
---

# 日次ファクトリー（1回の実行手順）

全体の説明は `factory/README.md`。ここは Claude が1回の実行でやること。**途中で確認の質問をせず、最後まで進める。**
止まるのは、人にしかできない作業（API キー、スロット作成、公開ボタン、非公開化）だけ。その場合は飛ばして、最後の報告に「お願い」として書く。

```bash
export PATH="$HOME/.rokit/bin:$PATH"   # Windows の Git Bash
```

## 1. 数字を取って判定する
```bash
python tools/factory/factory.py metrics   # .env に ROBLOX_API_KEY が無ければ飛ばす
python tools/factory/factory.py decide    # 今日の作業リストが出る
```

## 2. 作業リストを上から実行する（更新が先、新作が後）

| 種類 | やること |
|---|---|
| 【更新】 | 新要素を1つ足す（新アイテム3〜5個、新エリア、イベントなど。`roblox-launch-liveops` スキル）。`games/<slug>/CHANGELOG.md` に1行書く → `tools/check.sh` → `factory.py publish <slug>` |
| 【改善】 | 数字の悪いところだけを直す。60秒以内の離脱が多い→最初の1分。D1 が低い→再訪の理由。台帳の `iterations` を1増やす → 公開 |
| 【入口】 | 題名・説明文・サムネイル案を作り直す。台帳の `trafficRetries` を1増やす。サムネイルの差し替えは人に頼む |
| 【終了】 | 台帳の `stage` を killed か archived にする。`slots.json` の該当スロットの `slug` を null に戻す。学びを CHANGELOG に1行。非公開化は人に頼む |
| 【新作】 | 下の §3 |

## 3. 新作を1本作る（1日で終わる大きさに切る）
1. `python tools/factory/factory.py next` でネタを取る。
2. `tools/new_game.sh <slug>` でテンプレートから作る。
3. **そのゲームだけの遊びを1つ実装する**（ネタの `mechanic`）。`roblox-luau-systems` スキルの不変ルールを守る（サーバー権威、DataService 経由、課金は冪等）。
   - 純粋なロジックは `src/shared/Lib/` に置き、`tests/run.luau` にテストを足す。
   - 数値は `GameConfig.luau` に集める。`DataStoreName` はゲームごとに変える。
4. `GDD.md`（一行ピッチ、ループ、最初の5分、再訪の理由、課金、成熟度）と `CHANGELOG.md` を書く。
5. `tools/check.sh games/<slug>` が通るまで直す。**通らないものは登録しない。**
6. `python tools/factory/factory.py add <slug>` → `publish <slug>`（スロットかキーが無ければ飛ばす）。
7. 法務チェック（`reports/future_games_plan.md` §2-5）を通す。

色違いは作らない。前日までのゲームと遊びが同じになるなら、ネタを飛ばして次を作る。

## 4. 記録して終わる
```bash
python tools/factory/factory.py report
git add -A factory games && git commit && git push
```
- ネタ帳の残りが5本を切ったら、`research/04` の伸びている型から10本足す。
- 失敗して学んだことは、プロジェクトの `CLAUDE.md` に1行足す。

## 5. 報告（日本語で、短く）
- 今日作ったもの、更新したもの、終了したもの
- 判定の表（ゲーム、遊んだ人、D1、判定）
- **Studio で確かめていないことは「未確認」と書く**
- 人へのお願い（公開ボタン、非公開化、スロット補充、サムネイル）
