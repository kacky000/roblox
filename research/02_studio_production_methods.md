# Robloxヒット作の作り方：スタジオ／小規模チームの制作手法リサーチ（2026年11月時点）

- 作成日: 2026-11-04
- 対象読者: AI（Claude Code等）で企画・プログラミング・3Dモデリングを担う日本人ソロクリエイター
- 調査方法: WebSearch（standard / extended）。**注意: この環境では WebFetch が全ドメインで名前解決エラーになり使えず（devforum.roblox.com, en.wikipedia.org, gamesbeat.com 等）、記事本文は読めていない。** 内容はすべて検索結果の要約・抜粋に基づく。数値は一次ソース（Roblox公式・決算資料・DevForum公式告知）で再確認することを推奨。
- 信頼度ラベル:
  - **【確認】** Roblox公式（Creator Hub / Newsroom / DevForum公式告知 / IR・SEC資料）や大手メディアの報道で、複数ソースが一致するもの
  - **【報道】** 単一の信頼できるメディア報道
  - **【推定】** 第三者トラッカー・ブログ・ファンWikiの推定、または筆者（本調査）の推論
  - **【未確認】** ソースが食い違う、または見つからなかったもの

---

## 0. エグゼクティブサマリー（要点だけ）

1. **2025〜2026年の超ヒットは極小チーム発**。Grow a Garden は16歳の BMWLux が**3日で作った初期版**を Jandel（Splitting Point）が拾って週次更新で伸ばし、99 Nights in the Forest は**NZの3人組**（デザイナー／プログラマー／環境アーティスト）が作った。Steal a Brainrot は SpyderSammy（Do Big Studios の CPO）作。【確認〜報道】
2. **「作る人」と「伸ばす人」の分業が業界の構造になっている**。Do Big Studios、Voldex、Gamefam などの中堅企業が、伸び始めたインディー作品を**数百万ドル単位で買収するか、株式を持って共同運営**する。Robloxは**2024年12月まではゲーム売買が規約違反**だった。【報道】
3. **2026年6月にRobloxのおすすめ（RFY）アルゴリズムが大きく変わった**。qPTR（qualified play-through rate）を廃止して、PTR、初回プレイの離脱率、**D1／D2-7／D8-28の28日リテンション**、セッション品質、課金を別々に評価する方式になった。課金を強く取りにいくゲームへの送客は意図的に減らされている。**クリックベイトの量産よりも、28日リテンションを伸ばす設計が勝つ時代**になった。【確認】
4. **13歳未満・16歳未満向けの規制が強化された**。顔年齢推定によるチャットの年齢確認は2026年1月から全世界で必須。Roblox Kids（5〜8歳）とRoblox Select（9〜15歳）のアカウントは2026年6月から全世界で提供されている。16歳未満にゲームを届けるには、**ID認証、2FA、Roblox Plus（または1,000 Robuxの返金可能な手数料）、評価プロセス**が必要。【確認】
5. **有料ランダムアイテム（ガチャ）の規制が厳しくなった**（2026-05-26）。全結果の確率を数値で表示すること、PolicyService で制限対象ユーザーには販売しないこと（例：ブラジルの18歳未満は2026-03-17から）、パック販売も対象。【確認】
6. **AIが前提の時代になった**。Roblox 2026年Q3の株主書簡によると、上位100ゲーム（プレイ時間ベース）の**80%超が直近1か月にAIを開発に使用**しており、ほぼAIで作られた2作品が同時接続数でトップ20入りした。AIで競争相手が爆増するぶん、**差別化はアイデア・リテンション設計・ライブ運営の速度**で決まる。【確認】
7. **技術スタックの定番**: Rojo＋Rokit＋Wally（またはpesde）＋Selene＋StyLua＋luau-lsp、データ保存は ProfileStore、テストは Jest-Lua、配信は Open Cloud Place Publishing API。Knit は2024年7月にアーカイブ済み。Studio Script Sync が2026年に正式リリースされた。Studio には MCP サーバーが組み込まれ、Claude Code から Quick connect で接続できる。【確認〜報道】

---

## 1. スタジオ／チーム別の制作手法

### 1.1 主要スタジオ一覧表

| スタジオ／チーム | 代表作 | 規模・体制 | ビジネスモデル・特徴 | 信頼度 |
|---|---|---|---|---|
| **BMWLux ＋ Splitting Point Studios（Jandel）** | Grow a Garden, A Dusty Trip, Grow a Garden 2（Strawberreh Squad名義との説あり） | 初期版は BMWLux（当時16歳）が**3日**で制作。Splitting Point が2025年4月、同時接続数が**約1,000人**の段階で株式を取得。所有者は BMWLux と Splitting Point の共同、Do Big Studios が少数株主。Splitting Point の在籍19人中12人が GaG 担当という報道もある | 「拾って伸ばす」型。参画後に**毎週土曜の大型更新と Admin Abuse イベント**を開始し、急成長させた。2025年6月21日に同時接続数2,130万人。売上は非公開（Calcalist は2025年5月だけで約1,200万ドルと報道） | 共同所有・3日制作・CCU＝【確認】、19人中12人＝【未確認】、5月売上＝【報道】 |
| **SpyderSammy / Spyder Games ＋ Do Big Studios** | Steal a Brainrot（2025-05-15/16 公開） | SpyderSammy（Sam Brakta）は2013年からRobloxで制作しているYouTuber兼開発者で、Do Big Studios の CPO。Do Big がインフラとスケーリングを支援 | ミーム（Italian Brainrot）×窃盗PvP×放置収入。TikTokでのバイラルで伸びた。同時接続数は2025年8月に2,000万人、10月に約2,540万人（全Roblox史上最大）。2025年8月23日の GaG との「Admin War」でRoblox全体の同時接続数が4,740万人に。著作権を登録し、模倣作に対して4件以上の訴訟を起こしている。Fortnite版は公式ライセンス、Story Kitchen が映画化 | 【確認】（CCUは複数ソースで一致） |
| **Grandma's Favourite Games（NZ）** | 99 Nights in the Forest（2025-03-04 作成） | **3人**: Alec Kieft（ゲームデザイン "Cracky4"）、Matthew Hufton（プログラム "ForyxeV"）、Cameron Angland（環境・アセット "Viridial"） | 「デザイン／コード／アート」の最小3職種で世界的ヒット。20th Century Studios が映画化（Sam Raimi がプロデュース） | 【確認】 |
| **Do Big Studios（Mobile Game Advertising & More, Inc.）** | Blade Ball, Blue Lock: Rivals（買収）, Fisch（一時期）, GaG・SaB に出資 | 非公開主義。「買収・提携・所有」を組み合わせる | ヒットしそうなインディー作品を早期に買う／株式を持つ。Fisch は2024年11月に買収した後、2025年7〜8月に撤退し、所有権は原作者 WoozyNate に戻った | 【報道】〜【推定】 |
| **WoozyNate / Fisching** | Fisch（2024-10-05） | 原作者が**約4か月**でモデリング・スクリプト・ワールド構築をすべて1人で担当（ファン情報） | ソロ制作から大ヒットした例。パブリッシャーや共同運営者は何度も入れ替わった | 4か月ソロ＝【推定】、所有の変遷＝【報道】 |
| **BIG Games（Preston）** | Pet Simulator 99, Pets GO!（2024-10-11、サイコロRNG型のスピンオフ） | 「50人以上」説と「少人数」説があり不明。NDA付きのテスター制度あり | 毎週土曜の更新（後に隔週化・鈍化したとの説あり）。卵ガチャ、Huge/Titanic のレアリティ階層、取引経済、高額な限定卵バンドル（例：32,000 Robuxで100個）。生涯売上1億ドル超という推定がある。Preston の退任説は未確認 | 【推定】 |
| **Gamer Robot Inc.** | Blox Fruits（2019年1月ベータ） | 共同創業者 mygame43（技術）と rip_indra（クリエイティブの顔）が中心 | 長期運営型のアクションRPG。大型アップデートの間隔が長く、そのぶん期待が膨らむ | 【推定】（公式情報が乏しい） |
| **Uplift Games（旧 Dreamcraft / Team Adopt Me）** | Adopt Me! | 2021年の設立時に約40人（北米・英国でリモート）。第三者DBでは51〜100人 | 「燃え尽きと過重労働を抑える」持続可能性を明言して法人化。ペットのトレード経済とイベント運営 | 2021年時点＝【確認】、現在＝【未確認】 |
| **Gamefam** | Sonic Speed Simulator（SEGA）, FIFA Super Soccer, PAYDAY（Starbreeze, 2026-04発表） | 2022年に「250人超」、現在は51〜200人規模。業界のベテランとRobloxネイティブが半々 | **IP・ブランドの受託とパブリッシング**。50本超のポートフォリオで累計370億セッション。独立系クリエイターのゲームも買収する。**負の事例**: 2022年に Sonic Speed Simulator で「毎週更新の義務化によるクランチ」「低賃金（3Dアーティストが年収3万ドル）」と報じられ、NLRB と和解 | 【確認】（クランチ報道・和解） |
| **Voldex** | Brookhaven（2025年2月買収）, Bloxburg, Driving Empire, Ultimate Football | Raine Partners と Shamrock Capital の出資 | **ヒット作を買収してロールアップ**する。Brookhaven は600億訪問、月間アクティブ1億2,000万人超 | 【確認】 |
| **Twin Atlas** | Creatures of Sonaria, Dragon Adventures, World // Zero, Toei の Hypergalactic | 約100人 | 買収ではなく**オリジナルIPを継続的にヒットさせる**型。収益源は4本柱（ゲーム内課金、プレミアム／エンゲージメント報酬、Shopifyでのグッズ、ブランドコラボ） | 【報道】 |
| **The Gang / The Gang Studio** | Strongman Simulator（15億プレイ）, Strongman Ultra | 2025年10月、オリジナルIP部門を独立させた（Behold Ventures が少数株主） | 本体はブランド受託。Studio はオリジナルIPに加えて、Steam などへの移植も狙う | 【確認】 |
| **WonderWorks** ほか | — | — | Deconstructor of Fun の分析では「トップのRobloxチームでも20人前後が上限であることが多い」 | 【報道】 |

**調査しても見つからなかったもの**: 「Simple Games」「Moonshot」「Lumi」というRobloxスタジオの買収情報は確認できなかった（名前の違いか、存在しない可能性がある）。「Toadboi」の incubator（インキュベーター）情報も見つからなかった。代わりに、Roblox公式の **Incubator／Jumpstart**（後述）と、LFG Studio・Roforco といった民間の投資・アクセラレーターがある。

### 1.2 チームの役割と人数（典型パターン）

| フェーズ | 典型的な規模 | 役割 | 根拠 |
|---|---|---|---|
| プロトタイプ〜初期ヒット | **1〜3人** | 全部担当（ソロ）／デザイン＋コード＋アートの3人 | GaG（1人・3日）、Fisch（1人・4か月）、99 Nights（3人）【確認〜推定】 |
| ヒット後の運営 | 5〜20人 | スクリプター複数、ビルダー、3Dモデラー、UI、VFX、アニメーター、コミュニティマネージャー（Discord）、QA・テスター、データ分析 | Splitting Point（GaGに12人とされる）【未確認】、Deconstructor of Fun「上位チームは〜20人が上限」【報道】 |
| ポートフォリオ型スタジオ | 40〜250人 | 上記に加え、プロデューサー、UA（ユーザー獲得）・広告、BD（ブランド提携）、法務 | Uplift（40人）、Twin Atlas（約100人）、Gamefam（最大250人超）【確認】 |
| 参考：開発ユニット | 12人で6か月に4本 | — | Naavik のユニットエコノミクス分析【報道（古い記事）】 |

### 1.3 予算・報酬・収益分配

| 項目 | 内容 | 信頼度 |
|---|---|---|
| Robloxから開発者への取り分 | 実質で**プレイヤー支払額の約25〜30%**（ストア手数料とRobloxの取り分を除いた残り。Naavik 2026 は「25%」と記載） | 【推定】 |
| DevEx レート | 2025-09-05以降に得たRobuxは **$0.0038/R$**（8.5%増）。それ以前の分は $0.0035。2026-06-08からは、**米国の18歳以上**による対象支出（ゲームパス、サブスク、一部アイテム、プライベートサーバー）に**42%増の特別レート**（約 $0.0054） | 【確認】 |
| Creator Rewards | 2025-07-24に Premium Payouts から置き換わった。「Daily Engagement Rewards」と「Audience Expansion」（新規・復帰ユーザーの最初の2か月の購入のうち、最初の100ドル分の35%）で構成。支払いまで60日の保留期間がある | 【確認】 |
| 外注単価（Talent Hub等） | **公式の標準料率はない**。時給の目安は初級$10〜25、中級$25〜60、上級$60〜120+。1システムやUI1画面で数十〜数百ドル。Talent Hub には**買い手保護がなく直接払い**なので、信用リスクがある | 【推定】 |
| 収益シェア型の報酬 | 業界では「売上の%」で開発者に報酬を払う契約が一般的。ただし標準的な%を示す公開データは**見つからなかった**。口約束はトラブルの原因になりやすいので、書面化を強く推奨 | 【未確認】 |
| スタジオ立ち上げ費 | KreekCraft はスタジオと1作目に約10万ドルを使った（法務と初期採用を含む） | 【報道】 |
| 損益分岐の目安（古い） | 上位250位相当のゲームで、制作に約12万ドル＋宣伝に約6万ドル、損益分岐は売上約18万ドル（Naavik、約3年前の記事） | 【推定】 |
| 売却額 | 中堅企業がトップ級インディー作品を「1本数百万ドル」で買収（Blue Lock: Rivals など）。条件はほぼ非公開 | 【報道】 |
| 分布 | 2025年の開発者への支払いは15億ドル（前年比+70%）。上位1,000クリエイターの平均は約130万ドル/年。一方、3,959本を対象にしたモデル推定では、月収の中央値は約948ドル、上位1%が全体の38%を得ている | 支払総額＝【確認】、分布＝【推定】 |

### 1.4 Roblox公式の支援プログラム（2026）

| プログラム | 内容 | 信頼度 |
|---|---|---|
| **Roblox Incubator** | 経験のあるチーム向けの6か月・マイルストーン型プログラム。1期あたり最大40チーム（2026年期は26チーム）。マイルストーンを達成するとリソースが解放される。現在は応募を締め切っている | 【確認】 |
| **Roblox Jumpstart** | 随時応募できる。Robloxでの実績は不要。教育、専門家へのアクセス、プラットフォーム内外のUA（ユーザー獲得）を支援。**ソロの新規参入者が最も使いやすい** | 【確認】（金額は未確認） |
| 方向性 | Robloxは「Novel Games」（新しいメカニクス、高い表現品質）を優遇しようとしている | 【報道】 |

---

## 2. 「高速プロトタイピング／小さな賭けを多数」アプローチ

### 2.1 実例から見えるスピード感

| 事例 | 制作期間 | 備考 |
|---|---|---|
| Grow a Garden 初期版 | **3日** | 【確認】 |
| Fisch 初期版 | 約4か月（ソロ） | 【推定】 |
| 99 Nights | 2025年3月に作成し、同年に爆発的ヒット | 【確認】 |
| AI製のヒット作（Break and Steal an Egg, Huss/Hustle Valley） | 「ほぼAIで作った」と CEO が発言（2026年Q3） | 【確認】 |
| Roblox「Build」（AIで文章からゲームを生成） | アルファ版で5か月に**7万本超**が公開された | 【確認】 |
| 60本超のポートフォリオを持つスタジオ | 実在する（X 上の運営者による投稿） | 【報道】 |

一般的なパターン【推定】:
- **プロトタイプは数日〜2週間**で作り、公開して**実際のトラフィックで判定**する。
- 当たれば即座に**週次更新の体制に移行**する。外れたら次の作品へ。
- 多くの上位開発者は「1本に全賭けせず、3〜5本のポートフォリオ」で運営している（商業サイトの見解）。

### 2.2 テスト手法とKPIの目安（Ads Manager）

| 指標 | 目安 | 出典の性質 |
|---|---|---|
| 広告のCTR | 1〜2%で良好、3%以上で優秀、5%以上は非常に優秀（ブログ）。フォーラムでは0.3〜0.4%が典型、1〜4%が良好という声も | 【推定】（ソースによって幅が大きい） |
| D1 リテンション | **30%超**、D7 **15%超**になってから広告をスケールするのが目安 | 【推定】 |
| 少額テスト | 1日500〜1,000 R$ で試す。ROAS 3倍ならスケール、0.8倍ならリテンションを先に直す | 【推定】 |
| Ads Manager の最低出稿額 | 10広告クレジット（1日5クレジット×最低2日）。**1クレジット＝263 Robux**。入札方式は CPM / CPP（1プレイ単価）/ CPV15（15秒視聴単価）のセカンドプライス・オークション | 【確認】（Roblox公式） |
| 注意点 | 有料トラフィックのせいで D1 リテンションの計測値が下がり、**オーガニック順位を下げる**という開発者の報告がある（広告ありで3%、なしで5〜8%） | 【未確認】（単独の報告） |
| サムネイル | **サムネイル・パーソナライゼーション**（マルチアームド・バンディット方式、最大5枚）が公式機能。実験段階での qPTR 改善は平均8.5%、最大で約50%。勝ったサムネイルは記憶される。**アイコンのA/Bテスト機能は公式には未提供** | 【確認】 |

**判定（続けるか撤退か）の基準（筆者の推奨フレーム）【推定】**:
1. **CTRの段階**: サムネイル5枚と広告を少額で回し、CTR 1%未満ならコンセプトか見た目を作り直す。
2. **初回体験の段階**: 2026年の新しい指標「first play bounce rate（初回プレイ離脱率）」を最重視する。最初の60秒で目的と報酬が見えるかどうか。
3. **リテンションの段階**: D1 25〜30%、D7 10〜15% が出れば週次更新の体制に移る。出なければ、2〜3回改善しても届かない時点で撤退する。
4. **収益化の段階**: 28日リテンションが安定してから課金を強める（2026年6月以降のRFYは過剰な課金を嫌う）。

### 2.3 アルゴリズムの前提（2026年6月の変更）【確認】
- qPTR を廃止し、**PTR（おすすめ表示から実際にプレイした率）**、**初回プレイ離脱率（マイナス評価）**、**D1・D2-7・D8-28 のリテンション**、セッション品質、課金を個別に評価する。
- 評価期間を7日から**28日**に拡大した。
- 課金を強く取るゲームへの送客を意図的に減らしている（Naavik）。この変更後、Roblox の時価総額が約90億ドル下落し、通期ガイダンスを撤回したと報じられた【報道】。
- タイトル・サムネイル・説明文・プレイスファイルが既存のゲームと酷似している場合、**おすすめと検索で優先されなくなる**【確認（DevForum告知）】。

### 2.4 クローン／ファストフォロー文化：倫理・規約・法的リスク

| 論点 | 事実 | 信頼度 |
|---|---|---|
| 実態 | Steal a Brainrot の後、「〇〇 for Brainrots」系の模倣作が数百本出た。YouTuber は「誰もがbrainrotゲームを作る時代」と表現。2026年10月にはCS・Superhot・Simpsons Hit & Run を丸ごと模倣した作品が問題視された（AIツールとの関連も指摘） | 【報道】 |
| 法的措置 | Spyder Games が著作権を登録し（2025年8月）、模倣作に対して**少なくとも4件の訴訟**を起こした（Fortnite の "Stealing Brainrots" を含む）。訴えの根拠はアートワーク、オブジェクト、デザイン、ゲーム要素といった「保護される表現」 | 【確認】 |
| Robloxの仕組み | **Rights Manager**（2024年3月〜。IP保有者が権利を登録し、削除申請できる）、DMCA の申し立てと異議申し立て、ユーザー間のコピー苦情窓口（copyright_agent@roblox.com）。**悪用の報告もある**（後発のコピー作品が先行のオリジナルを削除させた事例） | 【確認】／悪用は【報道】 |
| ディスカバリー上の不利 | 酷似したメタデータは推薦で優先されない。欺瞞的・重複的・紛らわしいメタデータはコミュニティ基準で禁止 | 【確認】〜【報道】 |
| 実際のケース | PEAK のクローン「CLIFF」（600万訪問）は開発者からの圧力で閉鎖された。一方「CLIMB」（1,390万訪問）は存続 | 【報道】 |

**実務上の線引き（推奨）【推定】**:
- ゲームの**メカニクス（ジャンルや遊び方）**は一般に著作権で保護されにくい。しかし、**アート、キャラクター、UIレイアウト、名称、ロゴ、サムネイル構図、音声、コード、モデル**のコピーは侵害リスクが高い。
- 「ジャンルに乗る」なら、**フック（遊びの核）を1つ以上新しく加え、見た目と世界観は完全にオリジナル**にする。
- 他社IP（アニメ、ミーム画像、実在ブランド）は使わない。Italian Brainrot のような「ミーム」でも、特定の作者がいるキャラクター画像には権利リスクがある。
- AIで生成したアセットでも、既存キャラクターに酷似していれば侵害になりうる。2026年4月の利用規約改定でRobloxが作品をAI学習に使える条項が入ったという報道もあり、規約は定期的に確認すること【報道】。
- 自分の作品は、公開と同時に**Rights Managerへの登録と制作過程の記録**（Gitの履歴、日付入りのアセット）を残しておく。これが先行の証拠になる。

---

## 3. ライブ運営

### 3.1 更新の頻度とイベント

| ゲーム | 頻度・手法 | 信頼度 |
|---|---|---|
| Grow a Garden | **毎週土曜の大型更新＋その直前の「Admin Abuse」**（Jandel が管理者権限で天候を変え、ショップを再入荷し、アイテムを配る）。2026年4月からは「Watering Wednesday」（水曜イベント）も。2025-08-23の Admin Abuse War は約1.5時間 | 【確認〜報道】（開始時刻はソースによってバラバラ） |
| Pet Simulator 99 | 毎週土曜17時GMTに更新、後に隔週化したとの説 | 【推定】 |
| Steal a Brainrot | Admin Abuse、限定イベント（例：2025-09-13の Extinct Event で同時接続2,400万人） | 【報道】 |
| Gamefam（Sonic） | 毎週更新を義務化していたが、クランチの温床になった（負の教訓） | 【確認】 |
| 一般論 | 「Robloxプレイヤーは速いコンテンツのテンポを期待し、遅い改善を許さない」（Deconstructor of Fun）。立ち上げ後2か月は週次更新が推奨される | 【報道】〜【推定】 |

### 3.2 FOMO・限定要素・コミュニティ施策

| 施策 | 内容とポイント |
|---|---|
| 在庫制限ショップ＋再入荷タイマー | GaG の種ショップは**5分ごとに入れ替わり、レア種は1〜2個だけ出る**（PC Gamer は「それ自体がガチャ」と表現）。Robuxで即時に再入荷できる（GaG2 では39 R$で強制更新できる「せっかち税」とファンWikiが説明）【報道〜推定】 |
| 期間限定アイテムとイベント通貨 | イベントショップは Admin の再入荷対象外。参加を促す設計【推定】 |
| 同時刻イベント | 土曜のイベントで同時接続数のピークを作り、トレンド表示とSNSでの話題につなげる【推定】 |
| コード | 更新ごとに報酬コードを出して、YouTuberのコード紹介記事やSNSでの拡散を誘う（定番手法）【推定】 |
| Discord | 外部コミュニティの中心。DoF の分析でも「Discordでコミュニティを作ること」が成長の柱【報道】 |
| Roblox Communities（旧Groups） | 2024年11月に Groups から Communities に名称変更。Shouts は Guilded 経由の Announcements に置き換わった。2025-11-30に Forums を全面公開し、Walls は読み取り専用に。**13歳未満はウォールに投稿不可**【確認〜報道】。⚠ Robloxは2025年に Guilded の終了を発表しているので、Announcements の現状は要確認【未確認】 |
| YouTuber / TikTok | Steal a Brainrot は「プレイヤー自身が宣伝部隊」になった（盗む瞬間やレアの引き当てが切り抜き動画になる）。中堅チャンネル（登録者5万〜15万人）の案件は150〜600ドル程度という例。インフルエンサーの紹介で同時接続数が233人から878人に増えた事例もある（業者の報告）【推定】 |
| 外部広告ルール | 2026-05-04から独立広告ポリシーを改定し、**登録・ラベル付けツールの使用が必須**に。YouTuberとの案件も含めて開示ルールを確認すること【確認】 |

**ソロ向けの推奨【推定】**: 週次更新は**小さな定期更新（毎週）＋月1回の大型更新**の2段構えにして、燃え尽きを防ぐ（Uplift の「持続可能性」、Gamefam のクランチという教訓）。AIでコンテンツ（新アイテム、ステージ、イベントの台本）の量産を自動化するのがソロの最大の武器になる。

---

## 4. 技術スタック（プロのRobloxチーム／2026年のベストプラクティス）

### 4.1 推奨構成表

| 分類 | 推奨（2026年） | 状態・注意 | 信頼度 |
|---|---|---|---|
| ファイル同期 | **Rojo**（7.6〜7.7系。7.7.0 で既存プレイスを Rojo 化する `syncback` を追加） | ファイルシステムを正とする業界標準。Roblox 公式も「Rojo のほうが成熟している」と認めている | 【確認】 |
| 公式の代替 | **Studio Script Sync**（2024年末にプレビュー、2025年末にベータ、**2026年中頃に正式リリース**） | スクリプトとフォルダーのみ同期。クラウドを正とし、Team Create と互換。Wally の対応付けはなし | 【確認】 |
| ツール管理 | **Rokit** | Aftman・Foreman の設定ファイルと互換。Aftman はメンテナが離脱、Foreman は Roblox 社内向け | 【確認】 |
| パッケージ | **Wally**（標準）／pesde（Lune 対応。Wally もソースとして使える）／Forest（新興） | Wally は型解決のために `wally-package-types` が必要 | 【報道】 |
| Lint / 整形 | **Selene** ＋ **StyLua** | CIで必ず実行する | 【確認】 |
| 言語サーバー | **luau-lsp**（VS Code 拡張 JohnnyMorganz.luau-lsp） | Rojo の sourcemap と連携。旧 Roblox LSP は非推奨 | 【確認】 |
| スクリプト実行環境 | **Lune** | ビルドスクリプトやオフラインテスト用 | 【推定】 |
| フレームワーク | **Knit は2024-07-31にアーカイブ済み（保守終了）**。新規なら「素の ModuleScript＋サービス／コントローラー規約」か、軽量な後継を使う | 【確認】 |
| データ保存 | **ProfileStore**（ProfileService の後継。セッションロック改善、後方互換あり） | リーダーボードやグローバル状態には向かない（OrderedDataStore / MemoryStore を使う） | 【確認】 |
| 状態の複製 | ReplicaService（loleris）、または自作 | — | 【推定】 |
| ネットワーク | **Blink**（コード生成型、最速傾向）／**Zap**（同じくコード生成型）／ByteNet（簡単） | どれも buffer ベース。サーバー側の入力検証が必須（巨大 buffer による攻撃に注意） | 【報道】（フォーラムのベンチマーク） |
| UI | **React-Lua**（Roblox 公式が保守。Roact は保守終了）／**Fusion**（軽量なリアクティブ）／Vide | AIとの相性が良いのは React-Lua（Webの知識がそのまま使える） | 【報道】 |
| ECS | **Jecs**（高速、エンティティ間の関係を扱える）／Matter（0.7.1、継続中） | 大量のNPCや弾幕に有効。シミュレーター系では不要なことが多い | 【報道】 |
| テスト | **Jest-Lua 3**（TestEZ はレガシー） | `EnableLoadModule` フラグが必要 | 【報道】 |
| クラウド実行 | **Open Cloud Luau Execution API**（公開済みのプレイスで実サーバー上にLuauを実行。タスク上限5分） | CIで統合テストを回せる | 【確認】 |
| 配信 | **Open Cloud Place Publishing API**（API キー＋ `universe-places` の書き込み権限。.rbxl/.rbxlx は最大100MB） | ⚠ SurfaceAppearance・PartOperation・EditableMesh などを含むプレイスは**Studioから公開**が必要という制限あり | 【確認】 |
| CI/CD | GitHub Actions: StyLua → Selene → rojo build → テストプレイスに配信（dev ブランチ）→ 本番配信（タグ） | rbxcloud CLI も使える | 【確認】 |
| AI連携 | **Studio 組み込みの MCP サーバー**（Assistant の「Manage MCP Servers」→ Claude Code に Quick connect）。旧 `Roblox/studio-rust-mcp-server` は開発終了。Assistant は外部LLMにも対応 | Claude Code から Studio を直接操作できる。ソロ開発者に最重要 | 【報道】 |
| AI 3D | **Cube 3D**（2025年3月、オープンソース版あり）→ 2026年2月に4D生成（`GenerateModelAsync`。旧 Mesh Generation API は2026-03-18に終了） | 1オブジェクト20〜40秒。プロトタイプ用の仮アセットに最適 | 【確認】 |
| AI ゲーム生成 | **Build**（2026-07-16発表、モバイルファースト、NZでアルファ版） | Studio とバックエンドを共有。プレイテスト用とアナリティクス用のエージェントを予定 | 【確認】 |

### 4.2 ソロ×Claude Code 向けの推奨構成【推定】
```
rokit.toml: rojo, wally (or pesde), selene, stylua, lune, (blink or zap)
src/
  server/  services/*.luau      -- 素のModuleScriptサービス（Knit不使用）
  client/  controllers/*.luau
  shared/  config/*.luau        -- アイテム表・確率表・価格表をデータ駆動で
  net/     *.blink              -- ネットワーク定義（コード生成）
tests/   *.spec.luau            -- Jest-Lua
.github/workflows/ci.yml        -- stylua --check / selene / rojo build / publish
```
- **アイテム・確率・価格は必ずデータテーブルにまとめる**（ガチャ確率の表示義務と Managed Pricing の動的価格に対応するため。価格をハードコードすると価格最適化が使えない）。
- **Studio MCP で配置・ビルド、Rojo でコード**という分担にする。地形やパーツは Studio 側、ロジックは Git 側で管理する。

---

## 5. アートパイプライン

| 項目 | 仕様・実務 | 信頼度 |
|---|---|---|
| メッシュの上限 | **MeshPart 1つあたり約2万（〜2.1万）三角形**（超えるとインポート時にエラー）。古い資料には「1万」とある。上限はモデル全体ではなくパーツ単位。リグには別の上限（約5万面）がある | 【推定】（公式ドキュメントで要確認） |
| インポート | **3D Importer**（FBX / GLB / OBJ）。FBX はリグとアニメーション向き。インポート前にポリゴン数と寸法を確認できる | 【報道】 |
| テクスチャ | **最大1024×1024**（公式の英語仕様）。目安は5×5スタッドで256、10×10で512、20×20で1024 | 【確認】 |
| PBR | SurfaceAppearance（カラー、法線、メタルネス、ラフネス）。1メッシュにPBRセットは1つまで（レイヤー化は要望段階） | 【確認】 |
| ヒット作の画風 | **ローポリ＋明るい単色・グラデーション＋太いアウトライン調UI**が主流（GaG、PS99、SaB）。99 Nights は暗めの雰囲気だがローポリ。⇒ 軽くてモバイルで動き、AIでも量産しやすい | 【推定】（画風を体系的にまとめたソースはない） |
| Blender の工程 | ローポリでモデリング → Decimate で三角形数を調整 → UVを1枚にまとめる → 必要なら PBR をベイク → FBX出力（スケール注意）→ 3D Importer → コリジョンを簡略化（Box / Hull）→ 必要なら RenderFidelity と LOD を調整 | 【推定】 |
| UI アート | Figma / Photoshop でデザインし、9-slice 化して ImageLabel で組む。文字は TextLabel ＋ UIStroke で太縁取り。⇒ React-Lua / Fusion でコンポーネント化する | 【推定】 |
| サムネイル | **1920×1080（16:9）を最大5枚**。パーソナライゼーションが自動で勝ち抜き方式にする。公式は「実際のゲーム内の様子を見せる」ことを推奨（動画サムネは審査対象で、実態と違う内容は不可） | 【確認】 |
| アイコン | 正方形で512×512以上。A/Bテスト機能はない（外部で広告を使って比較する） | 【確認】（仕様）／【報道】（A/Bなし） |
| CTR の注意 | CTRだけを最適化すると、クリック後の指標（初回プレイ離脱率）が悪化する。2026年からは離脱率がマイナス評価になるので、**誇大なサムネイルはむしろ損** | 【確認】（指標）／【推定】（解釈） |
| AI アセット | Cube 4D で仮アセットを作り、確定したら Blender で手直しする。Nilo などの外部AIツールもある | 【推定】 |

---

## 6. 収益化デザインと規約上の制約

### 6.1 実績のある収益化パターン

| パターン | 代表例 | 設計のポイント | 2026年の規約上の注意 |
|---|---|---|---|
| 卵／ガチャ（＋天井） | PS99（限定卵：2個240 R$〜100個32,000 R$）、Pets GO（サイコロ） | レアリティ階層（Normal → Golden → Rainbow → Huge → Titanic → Gargantuan）。天井（一定回数で保証）は不満を減らす | **Robux（またはRobuxで買った通貨）による抽選は「Paid Random Items」**。全結果の確率を数値で表示、確率を変える要素は事前に説明、PolicyService の `ArePaidRandomItemsRestricted` で制限、パックやバンドルも対象【確認】 |
| 2倍幸運／2倍通貨パス、自動孵化、VIP | 多くのシミュレーター | 遊びを加速するもの（不便を解消するもの）。ゲームパスは1回買い切り、**繰り返し買える Developer Product のほうが総売上は大きくなりやすい** | 幸運ブーストは「確率を変える要素」なので、ガチャ画面で表示を更新する義務がある【確認】 |
| リバース（転生）、オフライン収益、放置収入 | SaB（放置収入＋窃盗）、シミュレーター全般 | 長期リテンション（D8-28）に効く | — |
| 在庫制限ショップ＋再入荷タイマー | GaG | 時間の足止めと、Robuxでの即時再入荷 | **「残りわずか」「期間限定」などの虚偽の希少性表示は禁止**（公式ガイド）【確認】 |
| トレード経済 | Adopt Me、PS99、GaG | 外部の価値表サイトが自然に生まれ、コミュニティが活性化する | 地域価格の対象商品でギフトやトレードを許すなら User Price Level API の設定が必要【確認】。RMT・詐欺対策も |
| サブスク | — | 自動で地域価格になる | 価格最適化の対象外【確認】 |
| Managed Pricing | — | 価格最適化と地域価格を統合したもの（価格最適化は月6万取引以上が条件）。報告ではテストした開発者の売上中央値が+4% | **価格はスクリプトで動的に取得する作りが必須**【確認】 |
| 他ゲームのパス販売 | — | **2026-05-29にゲームをまたいだパスや Developer Product の販売は廃止**。代わりに Robux Transfers API（仲介者が10%） | 【報道】 |

### 6.2 年齢・安全に関する規制（2025〜2026年の重要変更）

| 変更 | 内容 | 開発者への影響 | 信頼度 |
|---|---|---|---|
| 顔年齢推定によるチャット年齢確認 | 2025年12月に一部地域で開始、**2026年1月から全世界で必須**。6段階の年齢帯（9歳未満、9-12、13-15、16-17、18-20、21+）。近い年齢帯どうしでしかチャットできない（Trusted Connections は例外）。9歳未満はチャット既定オフ | ゲーム内チャット頼みのソーシャル設計（例：取引の交渉）は弱くなる。**チャットがなくても成立するUI**（定型文、ジェスチャー、トレードUI）が必要 | 【確認】 |
| Roblox Kids（5-8歳）／Select（9-15歳） | 2026-04-13に発表、**2026-06-16に全世界で提供開始** | ラベルが Minimal・Mild なら Kids と Select に、Moderate なら Select と通常（16+）に届く。**Restricted は年齢確認済みの18歳以上のみで、一度付けると元に戻せない** | 【確認】 |
| 公開要件（16歳未満に届けるため） | **ID認証、2FA、Roblox Plus（または1ゲームあたり1,000 Robuxの手数料。要件を満たして3か月後に返金）、評価プロセス**（アカウント年齢、プレイ履歴、支出などで本物のエンゲージメントか確認）。最大48時間の優先審査（返金可）もある。「60日以内に16歳以上で年齢確認済みの熱心なプレイヤー500人」という閾値は**ユーザーの報告で未確認** | 新作はまず16歳以上の層で実績を作ってから若年層に広げる流れになる。**日本からでもID認証と2FAは早めに済ませておく** | 【確認】（閾値は【未確認】） |
| コンテンツ成熟度アンケート | 2025-09-30以降、**アンケート未回答のゲームはプレイ不可**（ファンWiki情報）。ラベルのない体験は Moderate 扱い | 公開前に必ず回答する | 【報道】 |
| 有料ランダムアイテム | 2026-05-26に明確化（韓国のゲーム法対応を全世界に適用という報道）。ブラジルの18歳未満は2026-03-17から購入不可 | 確率表UIを最初から設計に組み込む | 【確認】 |
| 外部広告ポリシー | 2026-05-04から、登録とラベル付けが必須 | YouTuber 案件やブランド案件 | 【確認】 |
| 規約改定 | 2026-04-30に施行（作品をAI学習に使えるとの報道） | 規約を確認 | 【報道】 |
| 安全対応 | Robloxは複数の州とデジタル安全関連で和解し、2026年Q3に4,900万ドルを計上 | 子ども向けの安全基準はさらに厳しくなる見込み | 【報道】 |

### 6.3 プラットフォームの現状（2026年Q3）【報道（決算報道から）】
- DAU（1日あたりアクティブユーザー）1.38億（前年比-9%、前四半期比+12%）、ブッキング16.97億ドル（前年比-12%）、エンゲージメント時間-15%、月間課金者数-16%、課金者1人あたり+5%。
- ⇒ 2025年の GaG・SaB による異常な伸びの反動と、年齢確認・アルゴリズム変更の影響。**競争は激化し、1ユーザーあたりの価値（深い課金）を伸ばす設計とリテンションが鍵**。

---

## 7. ソロ日本人クリエイターへの示唆（筆者の推論）【推定】

1. **3職種の分担をAIで埋める**: 99 Nights の「デザイン／コード／環境アート」の3人体制を、自分（デザインとディレクション）＋ Claude Code（コード、Studio MCP）＋ Cube 4D / Blender（アート）で再現する。
2. **「3日プロトタイプ」を量産する**: GaG の初期版のように、核になる遊び（ループ）1つ＋ミーム性のあるテーマ＋SNSで切り抜きやすい瞬間（窃盗、レア引き、巨大化）を3日〜2週間で作って公開する。
3. **判定は28日リテンションで行う**: PTR、初回プレイ離脱率、D1/D7/D28 を Creator Analytics で見る。広告は1日5クレジット×数日の少額にとどめ、主にサムネイルと見た目のテストに使う。
4. **当たったら週次更新＋土曜イベント**: Admin Abuse 型の同時刻イベントでピークを作る。ただし運営は「毎週小さく、月1回大きく」の2段構えにする。
5. **規約対応を最初から組み込む**: 確率表UI、PolicyService のチェック、価格の動的取得、成熟度アンケート、ID認証、2FA、Plus（または1,000 R$）。
6. **パクらない**: ジャンルに乗るのは良いが、アート・名前・UI・サムネイルは完全オリジナルにし、Rights Manager に登録する。AI生成物が既存IPに酷似していないか確認する。
7. **出口の選択肢**: 当たった作品は Do Big、Voldex、Gamefam 型の企業への**売却や共同運営**という道もある（2024年12月以降は規約上可能）。Roblox Jumpstart（随時応募）にも応募する価値がある。

---

## 8. ソース一覧

### Roblox公式・一次資料
- Roblox Newsroom: Incubator & Jumpstart 発表（2026-03） https://about.roblox.com/newsroom/2026/03/roblox-announces-incubator-jumpstart-creator-programs
- Roblox Newsroom: 2026 Incubator Cohort https://about.roblox.com/newsroom/2026/06/2026-roblox-incubator-cohort
- Roblox Jumpstart docs https://create.roblox.com/docs/en-us/creator-programs/jumpstart.md
- Roblox Newsroom: Kids / Select 発表 https://about.roblox.com/newsroom/2026/04/introducing-roblox-kids-and-select-accounts
- Roblox IR: Kids / Select 全世界提供 https://ir.roblox.com/news/news-details/2026/Roblox-Kids-and-Roblox-Select-Accounts-Now-Available-Worldwide/default.aspx
- DevForum: Kids and Select Global Launch https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717
- DevForum: New Publishing Requirements & Evaluation Process https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166
- DevForum: Alternate Publishing Requirements https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944
- DevForum: AMA Publishing Requirements https://devforum.roblox.com/t/ama-publishing-requirements-roblox-kids-select/4580953
- Creator Hub: Content Maturity https://create.roblox.com/docs/production/promotion/content-maturity
- Creator Hub: Paid random items policy https://create.roblox.com/docs/production/monetization/paid-random-items
- DevForum: Clarifying Requirements for Paid Random Items https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622
- Roblox Community Standards https://about.roblox.com/community-standards
- Roblox Newsroom: Optimizing Discovery（2026-06） https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox
- DevForum: RFY Algorithm Improvements (Long-Term Retention) https://devforum.roblox.com/t/recommended-for-you-algorithm-improvements-that-better-value-long-term-retention/4684575
- Creator Hub: Discovery https://create.roblox.com/docs/discovery.md
- DevForum: Reducing exposure of low quality content https://devforum.roblox.com/t/improving-user-experience-by-reducing-exposure-of-low-quality-content/3299107
- Creator Hub: Ads Manager https://create.roblox.com/docs/production/promotion/ads-manager
- DevForum: Leveling Up Ads Manager https://devforum.roblox.com/t/leveling-up-ads-manager-with-new-features/3587640
- Creator Hub: Experience Thumbnails https://create.roblox.com/docs/production/promotion/thumbnails
- DevForum: Thumbnail personalization（Live now） https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233
- DevForum: Thumbnail personalization remembers winners https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665
- Creator Hub: Game icons https://create.roblox.com/docs/production/promotion/game-icons
- Creator Hub: Texture specifications https://create.roblox.com/docs/art/modeling/texture-specifications （GitHub版 https://github.com/Roblox/creator-docs/blob/main/content/en-us/art/modeling/texture-specifications.md ）
- Creator Hub: Managed pricing https://create.roblox.com/docs/production/monetization/managed-pricing
- Creator Hub: Price optimization https://create.roblox.com/docs/en-us/production/monetization/price-optimization.md
- Creator Hub: Regional pricing https://create.roblox.com/docs/production/monetization/regional-pricing.md
- DevForum: Managed Pricing https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738
- Creator Hub: Monetization https://create.roblox.com/docs/production/monetization
- DevForum: Disabling Cross-Game Sales / Transfers API https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396
- DevForum: New Advertising Policies & Standards https://devforum.roblox.com/t/new-advertising-policies-standards/4527365
- DevForum: Terms of Use update April 2026 https://devforum.roblox.com/t/updates-to-the-roblox-terms-of-use-april-2026/4548394
- DevForum: Introducing Creator Rewards https://devforum.roblox.com/t/introducing-creator-rewards-earn-more-by-growing-the-community/3777628
- Roblox Newsroom: DevEx 42% for 18+ https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42
- BusinessWire: DevEx 8.5% increase (2025-09-05) https://www.businesswire.com/news/home/20250905587466/en
- Creator Hub: Rights Manager https://create.roblox.com/docs/production/publishing/rights-manager
- Creator Hub: DMCA guidelines https://create.roblox.com/docs/production/publishing/dmca-guidelines
- Creator Hub: Place publishing (Open Cloud) https://create.roblox.com/docs/cloud/open-cloud/usage-place-publishing
- DevForum: Open Cloud Luau Execution (Beta) https://devforum.roblox.com/t/beta-open-cloud-engine-api-for-executing-luau/3172185
- DevForum: Studio Script Sync Full Release https://devforum.roblox.com/t/full-release-studio-script-sync/4688454
- DevForum: Studio MCP Server Updates and External LLM Support https://devforum.roblox.com/t/studio-mcp-server-updates-and-external-llm-support-for-assistant/4415631
- GitHub: Roblox/studio-rust-mcp-server https://github.com/Roblox/studio-rust-mcp-server
- Roblox Newsroom: Introducing Cube https://about.roblox.com/newsroom/2025/03/introducing-roblox-cube
- DevForum: 4D Generation (Beta) https://devforum.roblox.com/t/beta-4d-generation-unlock-new-types-of-gameplay/4331818
- BusinessWire: Roblox Build (2026-07-16) https://www.businesswire.com/news/home/20260716034347/en/Build
- Q3 2026 Shareholder Letter https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Shareholder-Letter.pdf
- Q3 2026 Earnings Press Release https://s27.q4cdn.com/984876518/files/content_files/Q3-2026-Earnings-Press-Release.pdf
- DevForum: Introducing Roblox Communities https://devforum.roblox.com/t/introducing-roblox-communities/3268307
- DevForum: Announcements for Groups https://devforum.roblox.com/t/introducing-announcements-for-roblox-groups/2907426

### 報道・分析
- GamesBeat: Jandel interview https://gamesbeat.com/janzen-madsen-interview/
- Wikipedia: Grow a Garden https://en.wikipedia.org/wiki/Grow_a_Garden
- Wikipedia: Steal a Brainrot https://en.wikipedia.org/wiki/Steal_a_Brainrot
- games.gg（GaG 1,600万CCU、Splitting Point 体制） https://games.gg/hi/news/roblox-grow-a-garden-sees-16-million-ccus/
- Windows Central: teens millionaires https://www.windowscentral.com/gaming/teens-becoming-millionaires-making-games-in-roblox
- Calcalist: Grow a Garden https://www.calcalistech.com/ctechnews/article/dj4lxef8r
- PC Gamer: Grow a Garden プレイレポート https://www.pcgamer.com/games/survival-crafting/i-played-the-roblox-hit-thats-pulled-in-10-billion-visits-and-while-im-not-sold-on-it-i-can-see-how-its-cultivated-a-mass-following
- Grow a Garden Wiki: Admin Abuse https://growagarden.fandom.com/wiki/Admin_Abuse
- RblxTracker（SaB 25,419,277 CCU） https://x.com/RblxTracker/status/1977096221224521743
- Beebom: SaB masterclass https://beebom.com/robloxs-steal-a-brainrot-delivered-a-2025-masterclass-in-player-engagement-and-gave-uefn-a-second-wind/
- The Star（Bloomberg配信）: SaB vs imitators https://www.thestar.com.my/tech/tech-news/2026/03/25/robloxs-hit-game-steal-a-brainrot-battles-its-many-imitators
- PC Gamer: SaB lawsuit https://www.pcgamer.com/games/a-brainrot-themed-roblox-game-is-taking-a-brainrot-themed-fortnite-game-to-court-for-being-a-copy/
- Story Kitchen: SaB film https://www.story-kitchen.com/news/story-kitchen-partnering-with-steal-a-brainrot-creators-on-feature-adaptation-of-roblox-game
- Pryor Cashman: 99 Nights film https://www.pryorcashman.com/news/pryor-cashman-client-grandmas-favourite-games-99-nights-in-the-forest-headed-to-the-big-screen
- Roblox Fandom: Grandma's Favourite Games/99 Nights https://roblox.fandom.com/wiki/Grandma's_Favourite_Games/99_Nights_in_the_Forest
- Hollywood Reporter: 99 Nights film https://www.hollywoodreporter.com/movies/movie-news/99-nights-in-the-forest-josh-cooley-20th-century-studios-film-1236704624/
- Roblox Fandom: Fisch https://roblox.fandom.com/wiki/Fisching/Fisch
- Roblox Fandom: Do Big Studios https://roblox.fandom.com/wiki/Do_Big_Studios%E2%84%A2
- Tubefilter: Indie creators selling Roblox worlds https://www.tubefilter.com/2025/07/14/indie-game-creators-are-making-millions-selling-their-roblox-worlds/
- Tubefilter: KreekCraft $100K https://www.tubefilter.com/2026/03/09/kreekcraft-has-spent-over-100000-making-a-roblox-game-whats-the-roi-for-developers/amp/
- Variety: Voldex acquires Brookhaven https://variety.com/2025/gaming/news/roblox-brookhaven-game-acquired-voldex-1236295120/
- Digiday: Super League buys Supersocial https://digiday.com/media/roblox-studios-begin-to-consolidate-as-super-league-buys-supersocial
- Deadline: Baobab acquires Roblox game rights https://deadline.com/2026/03/baobab-studios-acquires-roblox-games-animation-development-1236766793/
- PocketGamer.biz: Gamefam $25M https://www.pocketgamer.biz/gamefam-raises-25-million-for-roblox-games
- Raptor Group: Starbreeze × Gamefam PAYDAY https://www.raptorgroup.com/news/starbreeze-partners-with-gamefam-to-expand-payday-franchise-with-second-game-on-roblox/
- Sportico: FIFA Super Soccer https://www.sportico.com/business/tech/2025/fifa-super-soccer-roblox-world-cup-game-1234879618/
- TheGamer: Sonic Speed Simulator crunch https://www.thegamer.com/sonic-speed-simulator-roblox-crunch-underpay/
- Sonic Stadium: Gamefam NLRB settlement https://www.sonicstadium.org/news/games/gamefam-settles-with-national-labor-relations-board-over-pay-discussion-r448
- GamesBeat: Twin Atlas interview https://gamesbeat.com/twin-atlas-is-among-the-studios-changing-what-roblox-games-look-like-exclusive-interview/
- NetInfluencer: Twin Atlas 100-person studio https://www.netinfluencer.com/how-alexander-hicks-built-twin-atlas-the-100-person-studio-powering-roblox-creator-boom/
- GamesBeat: The Gang spin-off https://gamesbeat.com/why-the-gang-is-using-venture-funding-to-spin-off-an-independent-game-studio/
- The Gang: Introducing The Gang Studio https://www.thegang.io/news/introducing-the-gang-studio-a-new-chapter-in-play
- PC Gamer: Uplift Games formed https://www.pcgamer.com/the-creators-of-the-most-popular-roblox-game-have-formed-a-new-studio
- PCGamesN: Uplift "minimize overwork and burnout" https://www.pcgamesn.com/roblox/adopt-me-developer
- RoWatcher: Inside BIG Games https://rowatcher.com/news/inside-big-games-how-pet-simulator-became-a-100m-roblox-empire
- RoWatcher: PS99 monetization https://rowatcher.com/news/pet-simulator-99-inside-roblox-s-most-aggressive-monetization-machine
- Naavik: Roblox Developer Unit Economics https://naavik.co/digest/roblox-developer-unit-economics/
- Naavik: State of UGC Games 2026 https://naavik.co/deep-dives/the-state-of-ugc-games-2026/
- Deconstructor of Fun: Real Business on Roblox 2026 https://www.deconstructoroffun.com/blog/how-to-build-a-real-business-on-roblox-in-2026
- PC Gamer: 70,000 games via Build https://www.pcgamer.com/software/ai/ai-powered-game-development-is-leading-to-an-explosion-of-content-roblox-says-as-it-brags-about-70-000-games-published-on-its-platform-in-the-last-5-months-alone/
- Scuttlebutt: Baszucki on AI top-20 games https://getscuttlebutt.substack.com/p/roblox-ceo-on-ai-steal-an-egg-and
- Gaming.net: Q3 2026 results https://gaming.net/roblox-q3-revenue-rises-16-as-bookings-fall-12-to-1-7-billion
- GodIsAGeek: algorithm change & market cap https://godisageek.com/2026/08/roblox-9-billion-algorithm-change/
- TechCrunch: Kids/Select accounts https://techcrunch.com/2026/04/13/roblox-introduces-kids-and-select-accounts-for-age-appropriate-access-to-games-and-chat/
- PC Gamer: mandatory facial age checks https://www.pcgamer.com/gaming-industry/roblox-to-make-facial-age-checks-mandatory-to-access-any-chat-features-and-will-put-common-sense-limits-on-the-age-ranges-users-can-chat-within/
- Biometric Update: global rollout https://www.biometricupdate.com/202601/roblox-rolls-out-facial-age-estimation-for-chat-access-globally
- TechTimes: Korea loot-box rules https://www.techtimes.com/articles/319148/20260626/koreas-loot-box-rules-push-roblox-disclose-item-odds-worldwide.htm
- MassivelyOP: ripped-off games (2026-10-28) https://massivelyop.com/2026/10/28/roblox-users-have-wholesale-ripped-off-games-like-counter-strike-superhot-and-simpsons-hit-and-run/
- RoWatcher: Clone Wars https://rowatcher.com/news/the-roblox-clone-wars-who-s-really-winning
- PiunikaWeb: Community walls retired https://piunikaweb.com/2026/04/01/roblox-community-walls-retired-end-of-march/

### 技術・ツール（コミュニティ）
- GitHub: Knit README（アーカイブ） https://github.com/Sleitnick/Knit/blob/main/README.md
- GitHub: rojo v7.7.0 https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0
- GitHub: rokit https://github.com/rojo-rbx/rokit
- docs.rs: pesde https://docs.rs/crate/pesde/latest
- DevForum: Forest Package Manager https://devforum.roblox.com/t/forest-package-manager-the-modern-package-platform-for-roblox/4766024
- DevForum: Selene, StyLua, Roblox LSP https://devforum.roblox.com/t/selene-stylua-and-roblox-lsp-what-they-do-why-you-should-use-them/1977666
- Oflight: Luau toolchain 2026（日本語） https://www.oflight.co.jp/ja/columns/luau-developer-toolchain-rojo-selene-wally-2026
- DevForum: ProfileStore https://devforum.roblox.com/t/profilestore/3190543
- DevForum: Zap or ByteNet https://devforum.roblox.com/t/zap-or-bytenet-performance-security/2888968
- DevForum: Fusion vs React-lua https://devforum.roblox.com/t/fusion-vs-react-lua-which-one-to-use-for-long-term-development/2781328
- GitHub: Roblox/roact（保守終了→react-lua） https://github.com/Roblox/roact
- DevForum: Jecs https://devforum.roblox.com/t/jecs-optimizing-declarative-scene-graphs-with-ecs/3263203
- Matter ECS https://eryn.io/matter
- Jest Roblox: upgrading to v3 https://roblox.github.io/jest-roblox-internal/upgrading-to-jest3
- DevForum: Automate place publishing with partially managed Rojo https://devforum.roblox.com/t/how-to-automate-place-publishing-with-partially-managed-rojo/2443196
- docs.rs: rbxcloud CLI https://docs.rs/crate/rbxcloud/latest/source/docs/cli/cli-experience.md
- note（日本語）: Studio Script Sync 完全ガイド https://note.com/roblory/n/n6a1256f4e937
- Nilo: custom Roblox mesh import https://nilo.io/articles/custom-roblox-mesh-import

### 推定値・ブログ（参考程度）
- RoLearn: Scaling 1K→100K CCU https://rolearn.dev/guidance/scaling-1k-to-100k/
- RoLearn: Revenue share 2025-2026 https://rolearn.dev/insights/roblox-developer-revenue-share-2026/
- Bloxg: Ads not working / CTR benchmarks https://bloxg.com/problems/roblox-ads-not-working
- Bloxg: How much to pay a Roblox developer https://bloxg.com/blog/how-much-to-pay-a-roblox-developer
- Memvers: Hiring guide 2026 https://memvers.com/blog/roblox-developer-hiring-guide-2026
- DevForum: My experiments with sponsored/user ads https://devforum.roblox.com/t/my-experiments-with-sponsored-and-user-ads/2420807
- DevForum: Sponsored Ads traffic degrades metrics（単独報告） https://devforum.roblox.com/t/sponsored-ads-traffic-degrades-the-engagement-metrics-used-for-discovery-causing-paid-acquisition-to-harm-organic-ranking/4838351
- RoWatcher: Influencer deals cost https://rowatcher.com/news/what-roblox-influencer-deals-actually-cost-after-platform-fees
- RoWatcher: Thumbnail A/B data https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows
- BloxBunny: How many Roblox games make money https://bloxbunny.com/blog/how-many-roblox-games-actually-make-money
- Metaverse Marcom: GaG monetization playbook https://www.metaversemarcom.io/post/inside-the-monetization-playbook-of-roblox-s-biggest-hit
- RoLearn: Brainrot case study https://rolearn.dev/case-studies/brainrot-game-meme-culture-25m-ccu

---

### 調査の限界
- WebFetch が使えず、記事本文を読めていない（すべて検索エンジンの要約を経由）。とくに GamesBeat の Jandel インタビュー、DevForum の99 Nights「Creator Spotlight」、Naavik 2026 は本文で確認する価値が高い。
- スタジオ内部の収益分配率（スクリプターに売上の何%など）は公開データがほぼなく、標準値は示せなかった。
- 「Simple Games」「Moonshot」「Lumi」「Toadboi」のスタジオ・買収情報は見つからなかった。
