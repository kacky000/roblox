# Roblox市場・ヒット作・収益構造リサーチ（2026年11月4日時点）

対象読者：AI支援開発でRobloxの収益化を目指す日本の個人クリエイター
調査方法：WebSearch（standard / extended）のみ。この環境ではWebFetchが外部ホスト（rowatcher.com、rostats.io、wikipedia等）を名前解決できなかったため、一次ページ本文は検索スニペット経由で確認しています。

**信頼度ラベル**
- 【確定】Roblox公式（ニュースルーム、DevForumの公式告知、Creator Docs、SEC提出書類、決算資料）で確認できたもの
- 【報道】大手メディアや業界メディアの報道（PocketGamer.biz、PC Gamer、GamesBeat、日経など）
- 【推計】サードパーティのトラッカー（RoWatcher、Rolimons、Profitable.app等）のモデル推計、または筆者の試算。**トラッカー間で数倍ずれることが普通**なので、オーダー感の参考に留めてください
- 【未検証】出典が弱いもの、矛盾があるもの

---

## 0. エグゼクティブサマリー（意思決定に効くポイント）

1. **プラットフォームは「拡大期」から「調整期」に入っている。** 2026年Q3はDAU 1億3,800万（前年比−9%）、ブッキング（Robux購入額）は16億9,700万ドル（前年比−12%）。年齢確認の義務化（顔年齢推定）でチャット利用が絞られ、新規獲得が鈍った【確定】。2026年通期のブッキング見通しも約9億ドル下方修正された【報道】。2025年の「GaG・SaBバブル」の再来を前提に計画しないこと。
2. **推薦アルゴリズムが「長期リテンション＋持続的な課金」重視に変わった。** 2026年6月、Recommended For You（RFY）の評価窓が7日から28日に広がり、D1・D2–7・D8–28の指標で評価されるようになった【確定】。8月には「長期リテンションと持続的なマネタイズ」を評価する更新が告知された【確定】。クリックベイト的な量産クローンが伸びにくい方向。
3. **ヒットの典型は「小規模チームが既存ミームや既存ループを高速に反復し、週次で更新する」形。** Grow a Gardenの初版は約3日で作られた【報道】。99 Nights in the Forestは3人チーム【報道】。2026年は「Steal〜」系の派生作（Steal An Egg、Break and Steal an Egg）が上位を独占した。
4. **AIで作ったゲームが既にTop20に入っている。** 2026年Q3の株主レターによると、Break and Steal an EggとHuss Valleyは「ほぼ全てAIで制作」されてCCU Top20入りした。Top100の80%超が開発にAIツールを使っている【確定（株主レター、報道経由）】。AIを使うこと自体は差別化にならず、速く回せるかどうかで差がつく。
5. **クリエイターの手取りは、プレイヤーが払った1ドルのうち約21〜30セント【推計】。** パス・開発者製品の売上の70%がRobuxで入り、DevExが1 Robux＝0.0038ドル（2025年9月に8.5%引き上げ）【確定】。米国在住で年齢確認済みの18歳以上プレイヤーの支出は、R15アバターのゲームならDevExが42%上乗せされる（2026年6月8日〜）【確定】。
6. **日本市場は急成長中だが、日本人クリエイターの収益の大半は海外から。** 日本のDAUは2026年Q2に前年比+67%【確定】。日本のクリエイター収益の約57%が国外由来という報道がある【報道】。最初からグローバル（英語）向けに作り、日本語は追加ローカライズとして扱うのが合理的。
7. **ベンチマークは想像より低い。** MAU100万超の大型タイトルでもD1中央値10.3%、D7 1.6%【報道（GameAnalytics 2026）】。上位1%でD1 22%、D7 9%。課金率は約3.8%。

---

## 1. トップゲーム（CCU・収益）2025–2026

### 1-1. プラットフォーム全体のCCU記録

| 指標 | 値 | 日付 | ラベル |
|---|---|---|---|
| プラットフォーム同時接続の最高記録 | 4,740万 | 2025年8月（GaGとSaBの「admin abuse」合戦の週末） | 【報道】PocketGamer.biz |
| それ以前の記録 | 3,269万 | 2025年7月 | 【報道】 |
| 単一ゲームの最高CCU | Steal a Brainrot 約2,540万（2,520〜2,580万の幅あり） | 2025年10月7日前後（Yin Yangイベント） | 【報道】PocketGamer.biz、Outlook India |
| 2位 | Grow a Garden 約2,235万 | 2025年8月23日 | 【報道】RTC、Wikipedia |
| 2026年の単一ゲーム最高 | Steal An Egg 約1,429万〜1,431万 | 2026年9月19日 | 【推計】Rolimons、Rival Ducks、OtakuKart（Aream & Co. Q3レポート経由） |

### 1-2. 主要タイトル一覧

| タイトル | ジャンル | 公開 | ピークCCU | 開発体制 | ラベル |
|---|---|---|---|---|---|
| **Steal a Brainrot** | Steal系タイクーン（ブレインロットミーム） | 2025年5月16日 | 約2,540万（2025年10月） | SpyderSammy（BRAZILIAN SPYDER）、DoBig Studios | CCU【報道】／体制【報道】 |
| **Grow a Garden (GaG)** | 放置・栽培シム（ソーシャル） | 2025年3月 | 約2,235万（2025年8月23日） | 原作者BMWLux（10代、初版約3日）と、Jandel率いるSplitting Point（約20人）が共同所有。DoBigが少数持分 | 【報道】PC Gamer、GamesBeat、Wikipedia |
| **99 Nights in the Forest** | 協力型サバイバルホラー | 2025年夏 | 約1,400万 | Grandma's Favourite Games（NZの3人） | 【報道】DevForum Creator Spotlight、TheWrap。20th Century Studiosが映画化権を取得 |
| **Steal An Egg** | Steal系（卵を盗む→孵化→ペットが放置収入を生む） | 2026年7月25日 | 約1,430万（2026年9月19日） | グループ「and Collect Rare Pets」（Badr_Omega）。Misfits Gamingが関与を表明 | 【推計】トラッカー |
| **Plants vs Brainrots** | タワーディフェンス＋栽培＋ブレインロット | 2025年9月 | 320万（Rolimons）〜865万（未検証） | Yo Gurt Studio（25人超との情報あり。作者の帰属は諸説あり） | 【推計】【未検証】 |
| **Grow a Garden 2** | 栽培シム続編 | 2026年5月21日 | 約93万〜98万（2026年6月） | Strawberreh Squad | 【推計】。9月には同接約4,700人まで急落（ピークの約1%） |
| **Break and Steal an Egg** | Steal系派生 | 2026年9月5日 | 約131万（2026年10月18日） | monkisrok / ILGames x Eggs。**ほぼAIで制作**（Roblox公式） | AI制作は【確定（株主レター）】、CCUは【推計】 |
| **Huss Valley** | 鬼ごっこ型サバイバル（Runner vs Catcher） | 2026年8月 | Top20入り | Ve3 / Huss Valley Official。**ほぼAIで制作** | 【確定（株主レター）】 |
| **DONT SPLASH** | ホラーobby（1〜4人の協力プレイ、9ステージ、Poolrooms風） | 2026年10月17日 | 約16.7万（公開17日で1.6億訪問、1日約970万訪問） | slo7th → Bacon Theory | 【推計】GGRecon、Rolimons |
| **Dead Rails** | 協力型サバイバル（列車で西部を横断） | 2025年2月 | 20万〜60万超（トラッカーにより大差。150万説もあり） | RCM Games（RiccoMiller、70作品を持つグループ） | 【推計】 |
| **Ink Game** | イカゲーム風ミニゲーム集 | 2025年 | 約51.4万（2025年9月21日） | — | 【推計】。現在はピークの約1% |
| **Forsaken** | 非対称対戦ホラー | 2025年 | 13.8万〜30.3万 | — | 【推計】 |
| **Hunty Zombie** | ゾンビ協力アクション | 2025年 | 約2.2万〜21万（バリアントにより異なる） | — | 【推計】 |
| **Fisch** | 釣りシム | 2024年秋 | 約47万（大型イベント後） | WoozyNate（Nate Colley、カナダ在住の19歳） | 【確定（DevForum）】。収入は月約40万ドルと自己申告（LEGO・Walmartとのライセンス含む）【報道】 |
| **Dress to Impress** | ファッション・ソーシャル | 2023年11月 | 41万〜150万（諸説） | Gigi（10代の開発者）のグループ | 【推計】 |
| **Brookhaven RP** | ロールプレイ・生活シム | 2020年 | 常時上位。累計約825億訪問 | Wolfpaq → 2025年2月にVoldexが買収 | 【報道】 |
| **Murder Mystery 2** | ソーシャル推理 | 長寿 | 約224万（2026年10月25日、ハロウィン期） | — | 【推計】 |
| **Adopt Me!** | ペット育成・トレード | 長寿 | 2026年5月時点で同接50万超 | Uplift Games | 【推計】 |
| **Blox Fruits / Pet Simulator 99 / RIVALS / The Forge** | アニメRPG / ペット収集 / FPS / 採掘クラフトRPG | — | 上位常連 | — | 2025年12月の売上スナップショットではThe Forgeが1位、RIVALS・SaB・Blox Fruits・Adopt Me!が続いた【推計（games.gg）】 |

**2026年11月初旬の勢力図【推計】：** Steal An Egg（約100万同接、11月2日時点で1位、7日平均−12.7%）、Murder Mystery 2、99 Nights in the Forest、Adopt Me!、Break and Steal an Egg、Steal a Brainrot（約20万前後）、DONT SPLASH（急上昇中）。

### 1-3. 収益の推計（すべてサードパーティ推計。オーダー感のみの参考）

| タイトル | 推計値 | 出典 | 備考 |
|---|---|---|---|
| Grow a Garden | 2025年5月だけで約1,200万ドル（Robuxによるバーチャルアイテム売上） | Calcalist【報道】 | 開発者の手取りではなくグロス売上の可能性が高い |
| Grow a Garden | 累計2.856億ドル / 月175万ドル | Profitable.app / RoWatcher【推計】 | 両トラッカーの推計は整合しない |
| Steal a Brainrot | 月140万〜1,100万ドル / 累計5.746億ドル | RoWatcher、Profitable.app【推計】 | 推計の幅が非常に大きい |
| 99 Nights in the Forest | 月約127万ドル（信頼度0.6）/ 累計2.281億ドル | RoWatcher / Profitable.app【推計】 | |
| Dead Rails | 月約33万ドル / 累計5,140万ドル | 同上【推計】 | |
| Dress to Impress | 月約82万ドル / 累計8,390万ドル | 同上【推計】 | |
| Adopt Me! | 年5,000万ドル以上 | obby.fun【推計】 | |
| Steal the Brainrot（Fortnite版） | 最大1,380万ドル | PCGamesN【推計】 | Fortnite Creativeで初めてピーク100万を超えた |

> 参考（クリエイター全体）：上位1,000クリエイターの直近12か月の平均収入は約110万ドル（前年比+40%）【報道（2025年Q3時点）】。74%が個人で活動している【報道】。

### 1-4. 主要ヒットのコアループとマネタイズ

| タイトル | コアループ | 主なマネタイズ | バズった理由 |
|---|---|---|---|
| **Grow a Garden** | 種を買う → 植える → 放置で育つ → 収穫して売る → 上位の種を買う。卵を孵化させてペットを得る | Robuxで時短購入、種パック（Exotic Seed PackはRobux限定）、ショップの在庫補充、ギフト（Robux）、他人の作物を盗む（37 Robux、失敗あり）、期間限定の卵ガチャ（Exotic Bug Egg）【報道】 | 週次のライブ運営型アップデート。5分ごとの在庫ローテーションで再訪の動機を作る。フレンド1人につき売却額+10%で友人招待を促す。開発者本人のadmin abuseイベント。TikTokでの拡散。Jandel本人は「RobloxはYouTubeやTikTokに近く、数週間で巨大なフランチャイズが生まれる」と語っている【報道 GamesBeat】 |
| **Steal a Brainrot** | ブレインロットを購入して基地に置く → 放置収入 → 他人の基地から盗む／自分の基地を守る → リバース | 2x Money（119 Robux）、VIP、ギア（199〜1,799 Robux）、ゲーム内通貨パック（59〜3,449 Robux）、シーズンのバトルパス（800 Robux）【報道・攻略サイト】 | イタリアン・ブレインロットのミームに乗った。「盗む／盗まれる」から生まれる社会的な摩擦と配信映え。大型イベント（Yin Yang、admin abuse）。Fortnite版も100万同接 |
| **Steal An Egg** | 卵を盗む → 自分の庭に置く → 孵化 → ペットが放置収入を生む → 強化 | パス4種（恒久倍率2種、タイマースキップ2種）。うち1つは卵の成長速度2倍【報道】 | SaB × GaG（卵・ペット）の合成。2026年夏の新作として最大級 |
| **99 Nights in the Forest** | 4〜5人で森の中で99夜を生き延びる（拠点強化、探索、子どもの救出）。クラス制 | ダイヤ（通貨）、クラス解放など【報道は限定的】 | 協力型ホラーで配信と相性が良い。継続的なバイオーム追加（2026年3月にJungle Biome Part 2）。映画化 |
| **DONT SPLASH** | 水に音を立てないように進むホラーobby（1〜4人） | 詳細不明 | ルールが一目で分かる。TikTokでのリアクション動画 |

---

## 2. ジャンルトレンドのタイムライン（2023→2026）

| 時期 | 主流ジャンル・代表作 | 特徴 |
|---|---|---|
| **2023** | ペット系シミュレーター（Pet Simulator 99は2023年12月）、アニメ格闘・Battlegrounds系、Blade Ball、Doors（ホラー）、Dress to Impress（11月） | 「クリック→数値が増える→ペット・エッグガチャ」のシミュレーターが最盛期 |
| **2024** | Dress to Impress（ソーシャル・ファッション）の大ブーム、Fisch（釣りシム、秋）、RIVALS（FPS） | 女性層・ソーシャル層の拡大。12月にゲーム所有権の移転機能が入り、ゲーム売買（M&A）が公式化 |
| **2025年前半** | Dead Rails（2月、協力サバイバル）、Grow a Garden（3月）、Steal a Brainrot（5月） | **ソーシャル放置・「Grow／Steal」系**が誕生。ブレインロットミームの波。プラットフォームの同接記録を連続で更新 |
| **2025年後半** | 99 Nights in the Forest（協力ホラー）、Ink Game（イカゲーム風）、Plants vs Brainrots（9月）、Forsaken（非対称ホラー）、The Forge（12月、売上1位） | ブレインロットの派生が乱立。協力ホラーが伸びる。8月に同接4,740万の記録 |
| **2026年前半** | Sailor Piece、Jujutsu Shenanigans（アニメ系）、RIVALS、99 Nights（継続）、Grow a Garden 2（5月、急伸して急落）、The Exit 8（Roblox版） | 年齢確認の影響でDAUが減少。6月にRFYアルゴリズムが28日窓に移行 |
| **2026年後半** | Steal An Egg（7月→9月に1,430万）、Break and Steal an Egg（9月、AI制作）、Huss Valley（8月、AI制作）、DONT SPLASH（10月、ホラーobby）、MM2・99 Nightsのハロウィン期ピーク | **Steal系＋ペット・卵**の合成が最大勢力。AI制作作品が台頭。短期勝負の協力ホラーobbyも出てきた |

### 飽和しているもの・伸びているもの（筆者の評価：【推計】）

**飽和・下り坂**
- **ブレインロット名義のクローン**：爆発的な成長期は終わり、SaBは2,500万から約20万〜25万に減った【報道】。タイトルに「brainrot」を含む20作以上が各6,000〜1.3万同接で横並び（2026年4月）【未検証】。「初回のコンバージョンは高いが、長く残らない」との指摘あり。
- **続編・二番煎じの短命化**：GaG2はピークの約1%に、Ink Gameもピークの約1%に落ちた【推計】。
- **寄付ゲーム（PLS DONATE型）**：2026年5月末にゲーム間のパス販売が無効化され、事実上消滅した【報道】。
- **旧来型のクリックシミュレーター**：2023年の主流だったが、現在は上位で目立たない。

**伸びている・余地あり**
- **協力型ホラー・サバイバル（2〜5人）**：99 Nights、DONT SPLASH、Forsaken、Dead Rails。セッションが長い傾向で、新RFYの「intentional co-play days」指標と相性が良い【報道（指標の存在）＋推計】。
- **Steal系 × 収集（ペット・卵）× 放置**：2026年の最大勢力。ただし競合が多いので、ひねりが必須。
- **18歳以上向けの高品質（R15）ゲーム**：Robloxが42%のDevEx上乗せで明示的に後押ししている。18歳以上の比率は年齢確認済みDAUの29%（Q3 2026）【報道】。
- **アニメ系RPG・格闘**：Sailor Piece、Jujutsu Shenanigans、Blox Fruitsが継続的に強い。
- **イベント駆動の長寿タイトル**：MM2、Adopt Me!、99 Nightsは季節イベントで同接を200万規模に戻している。

---

## 3. Robloxの経済圏（収益構造）

### 3-1. DevEx（Robux→現金）

| 項目 | 内容 | ラベル |
|---|---|---|
| 標準レート | **1 Robux＝0.0038ドル**（10万Robuxで380ドル）。2025年9月5日に0.0035ドルから8.5%引き上げ。それ以前に稼いだRobuxは旧レートで先に払い出される | 【確定】（DevForum、決算資料） |
| 米国18歳以上レート | **2026年6月8日から、年齢確認済みで米国在住の18歳以上プレイヤーの支出に対し+42%（約0.0054ドル）**。条件はR15アバターを使うゲームであること。**開発者の居住地は問わない**（日本在住でも対象）。申請は不要。Plusインセンティブとは併用不可で、高い方が適用される | 【確定】ニュースルーム（2026年4月30日）、DevForum |
| 要件 | 13歳以上、ID確認、最低換金額など（以前から30,000 Robuxの獲得が目安とされてきた） | 【既知情報】最新の要件はCreator Docsで要確認 |
| 2026年の新機能 | **Roblox Wallet**：クリエイター収益を実通貨で保有できる。米国の18歳以上から2026年末に開始し、2027年に世界展開予定（RDC 2026で発表） | 【報道】 |

### 3-2. Robuxの価格（米国、2026年）

| パッケージ | 価格 | 1 Robuxあたり |
|---|---|---|
| 400 Robux | 4.99ドル | 約0.0125ドル |
| 800 Robux | 9.99ドル | 約0.0125ドル |
| 4,500 Robux | 49.99ドル | 約0.0111ドル |
| 22,500 Robux（最大） | 199.99ドル前後 | 約0.0089ドル【推計】 |

出典：ProGameGuides、RoWatcher【報道】。国ごとに現地価格と税が異なる。Premiumの購入ボーナスは2026年に廃止された【報道】。

### 3-3. 手数料と手取り（プレイヤーの1ドルのうち開発者に残る額）

- **マーケットプレイス手数料30%**：ゲームパス、開発者製品、有料プライベートサーバーは、販売額の**70%がRobuxで開発者に入る**【確定】。
- **筆者の試算【推計】**：1 Robuxの販売で開発者が得る現金は 0.7 × 0.0038 = **0.00266ドル**。
  - 小口パック（0.0125ドル/Robux）で買われた場合、1ドル＝80 Robuxなので**約21セント**。
  - 大口パック（約0.0089ドル/Robux）なら1ドル＝約112 Robuxで**約30セント**。
  - 米国18歳以上（R15ゲーム）の場合は 0.7 × 0.0054 = 0.00378ドルで、**1ドルあたり約30〜42セント**。
- Roblox公式の旧資料では「1ドルあたり28セント超を還元」（2021年12月データ）。アプリストア・決済手数料は支出の24.3%【確定（旧資料）】。
- 日本在住者は、DevExの受取（米ドル）にかかる米国源泉徴収（W-8BEN等の租税条約手続き）と日本の所得税・住民税も考慮が必要。詳細は税理士に確認すること。

### 3-4. その他の収益源

| 仕組み | 2025–2026年の状況 | ラベル |
|---|---|---|
| **Premium Payouts → Engagement-Based Payouts → Creator Rewards** | 2025年7月24日にEngagement-Based Payoutsが**Creator Rewards**に置き換わった。「Daily engagement reward（楽しくリプレイ性の高いループへの報酬）」と「Audience expansion reward（新規・復帰ユーザーを連れてきたことへの報酬）」の2本立て。「1人1日5 Robux」という説は未検証 | 【確定】10-K、Creator Docs |
| **Roblox Plus**（Premiumの後継） | 2026年4月30日開始、月4.99ドル。Premiumは新規購入不可に。**Plus会員向けのアイテム割引はRobloxが負担**するので、1アイテムあたりのクリエイター収益は変わらない。**有料プライベートサーバー**ではPlus会員が月60分以上遊ぶと最大100 Robux/人。**ゲーム内でPlusに加入させると報酬**（PromptRobloxSubscriptionPurchase）。**Robux送金**（PromptRobuxTransferAsync）では10%を受け取れ、DevEx対象。60日間の保留あり | 【確定】ニュースルーム、Creator Docs |
| **ゲーム内サブスクリプション** | Robux建てで49 Robuxから設定でき、地域別価格にも対応 | 【確定】DevForum |
| **地域別価格** | パス（2025年4月）→ アバターアイテム → 開発者製品（2025年夏以降）の順に拡大。初期テストでは課金ユーザー数がメキシコ+17%、ブラジル+26%、フィリピン+52%。開発者製品の価格はMarketplaceServiceで動的に取得するスクリプトが必要。ギフト・トレードがある場合はUser Price Level APIで対応 | 【確定】 |
| **価格最適化ツール** | Roblox側のテストで、開発者製品とパスの最適価格を推奨する | 【確定】 |
| **リワード動画広告** | 対象：13歳以上、ID確認済み、公開ゲームで月2,000ユニーク以上。Roblox公式は「初期は収益の最大3%、長期的には5〜10%の上積み」を見込む。eCPMは6〜12ドル程度という第三者推計あり。独自実装は2026年5月4日までにネイティブ形式へ移行が必要。ノーコードのStudioプラグインは2026年Q4予定 | 【確定】＋eCPMは【推計】 |
| **ブランド統合の収益分配** | 2027年からCPMベースの手数料（米国1.50ドル〜その他地域0.05ドル） | 【報道】 |
| **ゲーム間のパス販売** | **2026年5月末に無効化**され、代わりにTransfers APIが導入された（送金の10%が開発者に入る） | 【報道】 |
| **Roblox Everywhere** | ゲームを単独アプリとしてモバイル・PC・コンソールに出せる。Chromeでのブラウザプレイは2026年末予定（RDC 2026） | 【報道】 |

### 3-5. プラットフォーム全体の支払額

| 期間 | クリエイターへの支払（DevEx） | ラベル |
|---|---|---|
| 2023年 | 7.408億ドル（1.2万人超） | 【報道】 |
| 2024年 | 9.23億ドル | 【報道】 |
| 2025年 | **15億ドル超**（Q3単体4.279億ドル、前年比+85%）。DevEx参加者は2.35万人超 | 【確定（10-K：参加人数）／報道（金額）】 |
| 2026年Q3 | **4.03億ドル（前年比−6%）** | 【確定】Q3 2026株主レター |
| 直近12か月（2026年9月、RDC） | 約17億ドル。DevEx開始（2013年）以来の累計は50億ドル超 | 【報道】 |

### 3-6. プラットフォームのマクロ指標（2026年）

| 指標 | 値 | ラベル |
|---|---|---|
| Q2 2026 | 売上15億ドル（+36%）、ブッキング16億ドル（+8%）、DAU 1.23億（+10%） | 【確定】 |
| Q3 2026 | 売上15.72億ドル（+16%）、ブッキング16.97億ドル（−12%）、DAU 1.38億（前期比+12%、前年比−9%）、エンゲージメント時間 約340億時間（前期比+17%） | 【確定】 |
| Q4 2026見通し | ブッキング前年比−10〜−15% | 【確定】 |
| 通期2026ブッキング見通し | 73.3億〜76.0億ドル（当初82.8億〜85.5億ドルから下方修正） | 【報道】 |
| ブッキング減の理由（会社説明） | 年齢確認による新規獲得とチャット利用の減少。米国・カナダの若年層の時間あたり課金の減少。**RFYが長期リテンションの高いゲームに露出を寄せた**ことによる短期的な課金減。ゲーム間パス販売の無効化 | 【確定】Q2株主レター |
| 18歳以上の比率 | 年齢確認済みDAUの29%（前期27%） | 【報道】 |

---

## 4. ディスカバリー（推薦アルゴリズム）

### 4-1. RFY（Recommended For You）の仕組み【確定（Creator Docs / ニュースルーム 2026年6月）】

- **2段階**：Retrieval（候補抽出）→ Ranking（並べ替え）。
- **評価窓**：2026年6月に**7日から28日**へ拡大。指標はD1、D2–7、D8–28の3区間で見る。
- **評価対象**：**ホームのRFY経由でオーガニックに入ったユーザーだけ**。広告、検索、フレンド経由、キュレーション経由のユーザーのリテンションや課金はランキングに使われない。
- **主なシグナル**（いずれもユーザーあたりの平均値）
  - 最重要：**初回プレイの離脱率（first play bounce rate）**。「Qualified play through rate（RFYで表示されてから実際に遊ばれる率）」は細分化された
  - 重要：intentional co-play days（意図的に友人と一緒に遊んだ日数）、qualified play sessions、spend days（課金した日数）、Robux spent
  - その他：play days、playtime（**1ユーザー1ゲーム1日あたり最大60分でキャップ**）
  - 出典：Dubit経由の優先度、Docsの表【報道＋確定】
- **2026年8月（CGO名義のDevForum告知）**：「長期リテンションと持続的なマネタイズ」をより評価する更新。**課金も露出の決定要因**だと明言した。「楽しさをペイウォールの裏に置かない」ことも求めている【確定】。
- **2026年10月12日**：インプレッション、クリック、プレイの計測方法を変更（推薦ロジック自体は変わらない）【確定】。
- **新作のコールドスタート**：FAQでは「新作は28日待たなくても推薦される」とされているが、初期評価の詳細は非公開【確定（FAQ）／詳細は未公開】。
- **ベンチマーク機能はRFYに影響しない**（Docs）【確定】。
- 解析場所：Creator Hub > Analytics > Acquisition > Home Recommendations。

### 4-2. サムネイル

- **サムネイルのパーソナライズ**（多腕バンディット方式）：5枚程度の候補から、セグメントごとに最適な1枚を数時間で選ぶ。**qPTRが平均+8.5%、最大+50%**（Roblox幹部、GamesBeat）【報道】。8,000以上のゲームが採用。**頻繁にリスタートしないこと**（Roblox staff）【確定（DevForum）】。
- 16:9サムネイルへの移行で、レコメンド経由のユニークプレイが+7.2%（Web・デスクトップ）【確定】。
- メタデータ変更の反映には最大14日かかるという説がある【未検証】。

### 4-3. 「最初の5分」ルール

- 公式のオンボーディングDocs：FTUE（最初の数分）でプレイヤーは興味の有無を決める。**D1リテンションがオンボーディングの主要KPI**。仕組みは文脈の中で教え、すぐに面白い部分へ連れていき、進行要素で序盤の楽しさを塞がないこと【確定】。
- 診断には「New User First Session Retention」チャートで**5分後の残存率**を週次で見る【確定】。
- 開発者コミュニティの定石：早い「aha」体験と小さな報酬（最初のペット、アンロックなど）、ロード時間とチュートリアルの摩擦をなくす、序盤に課金を迫らない【報道（DevForum / Medium）】。
- 新RFYでは**初回プレイの離脱率が最重要シグナル**なので、「最初の5分」はアルゴリズム上も最重要になった。

### 4-4. 広告（Ads Manager）

- 入札形式：CPM（インプレッション）、CPP（1プレイあたり）、CPV15【確定】。
- Robloxは「1プレイ0.01ドル未満で獲得可能、CPPは71%安くなった」と主張している【確定（DevForum、公式の主張）】。
- 個別事例は幅が大きい。10万インプレッションで15訪問しか来なかった例もある（DevForum）【報道】。1日5,000 Robux程度が下限という説もある【未検証】。
- **注意**：広告経由のユーザーはRFYのランキング評価に入らない。広告は「初期データを作るため」の投資と割り切ること。

---

## 5. 日本市場

| 指標 | 値 | ラベル |
|---|---|---|
| 日本のDAU成長 | 2022年Q4→2024年Q4で+120% | 【確定】Roblox / Access Partnership |
| 日本の売上成長 | +125%（2025年11月時点の発言） | 【報道】Business Insider Japan |
| 日本のブッキング | 2025年Q4に前年比+160% | 【報道】 |
| 日本のDAU（2026年Q1） | 前年比+96% | 【報道（二次情報）】 |
| 日本のDAU（2026年Q2） | **前年比+67%**、エンゲージメント時間+61%（米加は+6%） | 【確定】Q2 2026株主レター |
| 日本のDAU（2026年Q3） | 前年比+33% | 【報道】Motley Fool の要約 |
| 収益化している日本人クリエイター | **2年で5倍** | 【報道】日経 |
| DevEx対象の日本人クリエイター | 2022年Q4→2025年Q4で+415% | 【確定】Roblox |
| 日本製ゲームの海外比率 | プレイヤーの56%、クリエイター収益の57%が国外由来 | 【報道】日経（検索要約経由のため要原文確認） |

**日本人クリエイターのヒット例**
- **顔から逃げるゲーム**（manato48／マナトさん、個人開発）：約14億アクセス（2023年8月）、月間ユニーク5,000万超（2023年5月）【報道 MoguraVR】
- **ひみつのおるすばん（Secret Staycation）**：2023年11月公開。総訪問は2.65億〜9.8億（時点による）、同接約1.2万【報道＋推計】
- **ペタペタ**など、個人クリエイターのホラー・脱出・ギミック系が海外でヒットしている【報道】

**エコシステム**：ROBMIX（電通・GeekOut・講談社クリエイターズラボ）が日本発IPとクリエイターを支援。Robloxの東京拠点で採用が進んでいる。電通がIPライセンスの検証を行っている【報道】。

**示唆【推計】**
- 日本ユーザーは伸びているが、絶対数と1人あたり課金は米国に及ばない可能性が高い。日本人のヒットも収益の過半は海外から来ている。**英語で作ってグローバルを主戦場にし、日本語は自動翻訳＋手動調整で追加する**のが基本戦略。
- 日本の強み：ホラー・脱出・ギミック系（J-ホラー、8番出口系の「異変探し」）、かわいい系の世界観、アニメ的な表現。The Exit 8のRoblox版が2026年に出ており、日本的な「異変探し」の型は世界で通用する。
- 年齢確認で保護者の同意が必要な市場では採用が低い、という指摘もある【報道】。日本の若年層のソーシャル機能の利用状況は要観察。

---

## 6. 指標ベンチマーク

### GameAnalytics 2026 Roblox Benchmark Report（2025年8月〜2026年7月、MAU100万超の500以上のタイトル）【報道（要約経由）】

| 指標 | 中央値 | 上位10% | 上位5% | 上位1% |
|---|---|---|---|---|
| D1リテンション | **10.3%** | — | — | **22.2%** |
| D7リテンション | **1.6%** | — | — | **9.1%** |
| D30リテンション | 0.5% | — | — | 4.7% |
| セッション長 | 9.8分 | — | 16.6分 | 21.1分 |
| ARPPU | 0.70ドル | 2.33ドル | 4.80ドル | 55.31ドル（要検証） |
| 課金率 | 約3.8% | — | — | — |

- 2025年版：セッション中央値が6分未満のゲームはD1が約6%、ARPPUは1ドル未満。13〜18分の帯ではARPPUが約1.20ドル【報道】。
- 2023年版：D1は12〜15%程度。母数に小規模作品を含む【報道】。
- **「D1 20%で良い、40%で優秀」という俗説は過大**だとGameAnalyticsは指摘している（成功作だけを見た小サンプル由来）【報道】。
- サードパーティのジャンル別表（例：シミュレーターでD1 32%、D7 14%）は、広告出稿済みの作品が中心のため高めに出る【未検証】。

**実務上の目標（筆者の提案【推計】）**
- 新作のテスト段階：D1 15%以上、5分残存率60%以上、セッション10分以上を「次に投資する」判断ラインにする。
- 上位1%に入るには、D1 22%以上、D7 9%以上、セッション20分以上が目安。

---

## 7. AI支援開発の文脈（2026年）

- Robloxの株主レター（Q3 2026）：**Top100（直近1か月のプレイ時間ベース）の80%超が開発にAIツールを使用**。Break and Steal an EggとHuss Valleyは「ほぼ全てAIで制作」してTop20入り【確定（報道経由）】。
- Build（プロンプトでゲームを作るツール）：アルファで約7万作が公開された（PC Gamer）。RDCでは約9,000作で、作者の71%がStudio未経験とされた（数字の時点や定義は不一致）【報道】。
- Roblox Assistantのエージェント化（2026年4月）：Planning Mode（企画書の生成）、プレイテストエージェント、Procedural Models、Mesh Generation。Scene Generatorは2026年末予定【報道】。
- 上位1,000クリエイターの44%がAssistantまたは他社のAIツールを利用【報道】。
- **示唆**：AIによって「速く作る」ことは前提になった。差がつくのは、①トレンドの読みと着手の速さ、②週次で更新を続ける力、③最初の5分とD1の改善サイクル、④サムネイルとタイトルの最適化。

---

## 8. 個人開発者向けの戦略的含意（筆者の分析【推計】）

1. **「既存の勝ちループ＋1つのひねり」を2〜4週間で出し、データを見て続けるか撤退するかを決める。** GaG（3日）、Steal An Egg（SaB×卵）、Break and Steal an Egg（AI制作）が示すように、速さがいちばんの武器になる。
2. **ただし新RFYは28日リテンションと持続的な課金を見る。** クローンで初速を取っても、D8–28が弱いと露出が落ちる。**最初の1か月に週次更新を計画しておくこと**。GaG式のライブ運営、在庫ローテーション、イベント。
3. **co-play（友人と遊ぶ）を設計に組み込む。** intentional co-play daysは重要シグナル。協力型ホラーと、友人ボーナスのある放置ゲームが有利。
4. **マネタイズは「進行に組み込んだ任意課金」で。** 2xパス、時短、ガチャ（卵）、限定イベント、有料プライベートサーバー（Plus報酬あり）、サブスク（49 Robuxから）、リワード広告。spend daysもシグナルなので、少額で繰り返し買える開発者製品が有効。地域別価格は必ずオンにする。
5. **18歳以上の米国向けにR15ゲームを作れば、DevEx +42%を取れる**（日本在住でも対象）。18歳以上の比率は29%に増えている。
6. **英語ファーストで作り、日本語ローカライズと日本的テーマ（ホラー、異変探し、かわいい）で差別化する。**
7. **飽和領域（素のブレインロット、寄付ゲーム、旧来のクリックシム）は避けるか、強いひねりを入れる。**
8. **広告は少額で検証用に使う。** 広告経由のユーザーはRFYの評価に入らないことを理解したうえで、初期ユーザーとデータを集める手段として使う。

---

## 9. 出典一覧（取得日：2026年11月4日。WebSearch経由）

### Roblox公式・SEC
- Roblox Q3 2026 Earnings Shareholder Letter：https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Shareholder-Letter.pdf
- Roblox Q3 2026 8-K：https://www.sec.gov/Archives/edgar/data/0001315098/000162828026068235/ex991-q32026earningsshar.htm
- Roblox Q2 2026 8-K：https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm
- Roblox Q2 2026 Shareholder Letter：https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Earnings-Shareholder-Letter.pdf
- Roblox Q1 2026 8-K：https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028882/ex991-q12026earningsshar.htm
- Roblox FY2025 10-K：https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm
- Roblox Q4 2025 Shareholder Letter：https://www.sec.gov/Archives/edgar/data/1315098/000131509826000009/ex991-q42025shareholder.htm
- US 18+ DevEx Rate（ニュースルーム、2026年4月30日）：https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42
- US 18+ DevEx Rate（DevForum）：https://devforum.roblox.com/t/introducing-the-us-18-devex-rate-earn-42-more-on-spend-from-18-us-players/4607091
- Introducing Roblox Plus（ニュースルーム）：https://about.roblox.com/newsroom/2026/04/introducing-roblox-plus-subscription
- Roblox Plus（Creator Docs）：https://create.roblox.com/docs/production/monetization/roblox-plus
- Engagement-based payouts（Creator Rewardsへの移行）：https://create.roblox.com/docs/production/monetization/engagement-based-payouts
- Creator Rewards告知：https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628
- Optimizing Discovery（2026年6月）：https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- Discovery Docs：https://create.roblox.com/docs/discovery
- Discovery FAQ：https://create.roblox.com/docs/discovery-faq
- Boost Your Discovery by Building Games People Want to Play（2026年8月）：https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042
- Improved Discovery Measurement（2026年10月）：https://devforum.roblox.com/t/improved-discovery-measurement-in-creator-analytics/4930122
- RFY Improvements（長期リテンション）：https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- Onboarding Docs：https://create.roblox.com/docs/production/game-design/onboarding
- Engagement Analytics Docs：https://create.roblox.com/docs/production/analytics/engagement
- Regional Pricing for Passes：https://devforum.roblox.com/t/introducing-regional-pricing-for-passes/3621382
- Regional Pricing for Developer Products：https://devforum.roblox.com/t/introducing-regional-pricing-for-developer-products/3971235
- Regional pricing（ニュースルーム）：https://about.roblox.com/de/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items
- Robux建てサブスク：https://devforum.roblox.com/t/let-your-players-pay-for-subscriptions-within-experiences-in-robux/4552995
- Rewarded video ads Docs：https://create.roblox.com/docs/en-us/production/promotion/rewarded-video-ads
- Ads for Creators: RDC Recap：https://devforum.roblox.com/t/ads-for-creators-rdc-recap-and-what%E2%80%99s-next/3929106
- Ads Manager Docs：https://create.roblox.com/docs/production/promotion/ads-manager
- Thumbnail Personalization Tips：https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689
- 16:9 Thumbnails：https://devforum.roblox.com/t/169-experience-thumbnails-are-coming-to-home-in-april-–-update-yours-now/2875237
- Creator Spotlight: 99 Nights in the Forest：https://devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940
- Creator Spotlight: Fisch：https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481
- How Roblox impacts the global economy（2025年12月）：https://about.roblox.com/newsroom/2025/12/how-roblox-impacts-the-global-economy
- Developer economics（旧資料）：https://devel.pages.dev/developer.roblox.com/en-us/articles/developer-economics

### 報道・業界メディア
- PocketGamer.biz SaBが2,500万超：https://www.pocketgamer.biz/robloxs-steal-a-brainrot-becomes-first-game-to-surpass-25m-concurrent-players
- PocketGamer.biz プラットフォーム4,740万：https://www.pocketgamer.biz/robloxs-peak-concurrent-user-count-hits-record-474m-as-steal-a-brainrot-and-grow-a-garden-compete
- PC Gamer GaG（10代の開発者、約3日）：https://www.pcgamer.com/games/survival-crafting/a-roblox-farming-game-made-by-a-teenager-in-like-three-days-had-8-9-million-players-online-at-the-same-time-steam-peaked-at-11-5-million-across-all-games-on-the-same-day
- GamesBeat Jandelインタビュー：https://gamesbeat.com/janzen-madsen-interview/
- Calcalist GaG：https://www.calcalistech.com/ctechnews/article/dj4lxef8r
- RTC GaG 2,234万：https://x.com/Roblox_RTC/status/1959281995453706447
- TheWrap 99 Nights映画化：https://www.thewrap.com/creative-content/movies/20th-century-studios-roblox-game-99-nights-in-the-forest/
- PCGamesN Fortnite版SaB：https://www.pcgamesn.com/fortnite/creative-steal-the-brainrot-roblox-clone-1-million-players
- OtakuKart Steal an Egg：https://otakukart.com/robloxs-steal-an-egg-reaches-6-billion-visits-and-14-2-million-peak-concurrent-players/
- Player.one Steal An Egg：https://www.player.one/robloxs-steal-egg-beating-some-platforms-biggest-games-164086
- MediaPost Q3 2026：https://www.mediapost.com/publications/article/419134/q3-roblox-boosts-revenue-bets-on-ai-game-creatio.html
- PC Gamer AI制作7万作：https://www.pcgamer.com/software/ai/ai-powered-game-development-is-leading-to-an-explosion-of-content-roblox-says-as-it-brags-about-70-000-games-published-on-its-platform-in-the-last-5-months-alone/
- GosuGamers AI 80%：https://www.gosugamers.net/entertainment/news/79447-over-70-000-games-on-roblox-are-developed-using-ai-including-80-of-its-top-games
- VGTimes Q3 4.03億ドル：https://vgtimes.com/gaming-news/173119-roblox-paid-creators-403-million-in-q3-as-young-developers-earn-big-from-their-games.html
- Motley Fool Q3 2026 transcript：https://www.fool.com/earnings/call-transcripts/2026/10/30/roblox-rblx-q3-2026-earnings-call-transcript/
- Quartz ガイダンス下方修正：https://qz.com/roblox-full-year-forecast-cut-age-verification-user-growth-050126
- Yahoo Finance 年齢確認とガイダンス：https://finance.yahoo.com/markets/stocks/articles/roblox-cuts-2026-guidance-age-123523142.html
- Investing.com Q3スライド：https://www.investing.com/news/company-news/roblox-q3-2026-slides-first-user-decline-marks-inflection-point-93CH-4985385
- Outlook Respawn Q2 2026：https://respawn.outlookindia.com/gaming/gaming-news/roblox-q2-2026-revenue-soars-36-to-15b-despite-bookings-miss
- PocketGamer.biz RDC 2026：https://www.pocketgamer.biz/roblox-unveils-new-play-creation-and-monetisation-tools-at-rdc-2026/
- allthings.how RDC 2026：https://allthings.how/roblox-rdc-every-major-announcement-for-players-and-creators/
- TheNextWeb Roblox Assistantのエージェント化：https://thenextweb.com/news/roblox-ai-assistant-agentic-tools-planning-procedural-models
- TubeFilter 18+ DevEx：https://www.tubefilter.com/2026/05/01/roblox-hikes-developer-earnings-by-42-but-only-if-they-make-games-aimed-at-adults/amp/
- TubeFilter 地域別価格：https://www.tubefilter.com/2025/04/22/roblox-regional-pricing-in-experience-items/
- TubeFilter KreekCraftの10万ドル：https://www.tubefilter.com/2026/03/09/kreekcraft-has-spent-over-100000-making-a-roblox-game-whats-the-roi-for-developers/
- PiunikaWeb Roblox Plus：https://piunikaweb.com/2026/05/01/roblox-raises-devex-by-42-us-18-above-players/
- PiunikaWeb ゲーム間パス販売の停止：https://piunikaweb.com/2026/05/05/roblox-disable-gamepasses-sales-players-furious/
- gam3s.gg DevEx +8.5%：https://gam3s.gg/news/roblox-increases-creator-payouts
- GamesBeat サムネイルのパーソナライズ：https://gamesbeat.com/roblox-will-let-game-devs-personalize-thumbnails-to-attract-more-players/
- GamesBeat Voldex×Brookhaven：https://gamesbeat.com/ugc-company-voldex-acquires-roblox-life-sim-brookhaven/
- Dubit（新作が伸びる条件）：https://dubit.io/library/what-makes-a-new-roblox-game-take-off
- GameAnalytics 2026 Roblox Report：https://www.gameanalytics.com/reports/2026-roblox-report
- GameAnalytics 2025 Roblox Report：https://www.gameanalytics.com/reports/2025-roblox-report
- GameDevReports（GameAnalytics要約）：https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox
- GameAnalytics Dead Rails：https://www.gameanalytics.com/blog/dead-rails-and-the-hit-makers-formula
- Newzoo Top Roblox Games 2025（要約）：https://gamedevreports.substack.com/p/newzoo-top-roblox-games-in-2025
- games.gg 2025年12月の売上上位：https://games.gg/news/roblox-top-games-and-trends-december-2025/
- GGRecon 急成長の新作（2026年11月）：https://www.ggrecon.com/articles/fastest-growing-new-roblox-games-november-2026/
- NME GaG：https://www.nme.com/news/gaming-news/roblox-grow-a-garden-major-changes-coming-update-cooking-3884432

### 日本関連
- 日経「ロブロックス、日本のゲームクリエーターが5倍に」：https://www.nikkei.com/article/DGXZQOUC076U60X01C25A1000000/
- MoguraVR 日本のデジタル経済レポート：https://www.moguravr.com/roblox-japan-digital-economy-report/
- Business Insider Japan：https://www.businessinsider.jp/article/2511-roblox-japan-business/
- Access Partnership Japanレポート：https://accesspartnership.com/reports/supporting-japans-digital-economy-robloxs-role-in-empowering-users-creators-and-influencers/
- MoguraVR 顔から逃げるゲーム：https://www.moguravr.com/roblox-escape-running-head/embed/
- MoguraVR ひみつのおるすばん：https://www.moguravr.com/roblox-secret-staycation/
- 電通 ROBMIX：https://www.group.dentsu.com/en/news/release/001500.html

### サードパーティのトラッカー・推計（数値は参考扱い）
- Rolimons Steal An Egg：https://www.rolimons.com/game/107778070777162
- Rival Ducks Steal An Egg：https://rivalducks.com/apps/radar/games/10563114921-steal-an-egg
- Rolimons Grow a Garden 2：https://www.rolimons.com/game/97598239454123
- Rolimons DONT SPLASH：https://www.rolimons.com/game/119958473240233
- Rolimons Break and Steal an Egg：https://www.rolimons.com/game/114326934417838
- RoWatcher Grow a Garden：https://rowatcher.com/games/7436755782
- RoWatcher Steal a Brainrot：https://rowatcher.com/games/7709344486/steal-a-brainrot
- RoWatcher 99 Nights：https://rowatcher.com/games/7326934954
- RoWatcher ブレインロットの衰退分析：https://rowatcher.com/news/is-the-brainrot-trend-dying-what-ccu-data-from-three-top-games-reveals
- Profitable.app（GaG / SaB / 99 Nights / Dead Rails / DTI）：https://profitable.app/roblox/games/grow-a-garden ほか
- Livecounts（2026年10月の表、スニペット経由）：https://livecounts.nl/roblox-charts/
- ProGameGuides Robux価格：https://progameguides.com/roblox/roblox-price-guide-how-much-do-robux-cost
- devex.gg 18+レートの解説：https://devex.gg/18-plus-devex-rate
