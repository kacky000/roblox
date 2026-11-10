# Windows PC セットアップ手順（PC上の Claude Code 向け）

この手順は **ユーザーの Windows PC で動く Claude Code（ローカルセッション）** が実行する。
ユーザーにお願いするのは ★ の付いた場面だけ（ログイン、2段階認証、本人確認）。パスワードや本人確認書類を AI が扱ってはいけない。

## 0. 前提
- Claude デスクトップアプリ（Claude Code のローカルセッションが使えること）
- 管理者権限が必要な操作は、ユーザーに確認してから行う

## 1. Git
```powershell
winget install --id Git.Git -e
```
インストール後、ターミナルを開き直して `git --version` で確認する。

## 2. リポジトリを取得
```powershell
cd $env:USERPROFILE
git clone https://github.com/kacky000/roblox
cd roblox
```
★ GitHub へのログインを求められたら、ユーザーに対応してもらう。

## 3. Roblox Studio
- https://create.roblox.com/ から Studio をダウンロードしてインストールする。
- ★ Studio の初回起動時のログインは、ユーザーに対応してもらう。
- ★ Roblox の 2段階認証（設定 → セキュリティ）をユーザーにオンにしてもらう。

## 4. Rokit → 開発ツール一式
1. https://github.com/rojo-rbx/rokit/releases から Windows x86_64 の zip を取得して展開する。
2. 展開した `rokit.exe` で `self-install` を実行する。コマンド名は `rokit --help` で確認する（未検証）。
3. ターミナルを開き直し、リポジトリのルートで次を実行する。
   ```powershell
   rokit install
   ```
   `rokit.toml` に書かれた版（rojo 7.7.1 など）が入る。
4. Rojo の Studio プラグインを入れる。
   ```powershell
   rojo plugin install
   ```

## 5. Studio 内蔵 MCP（AI から Studio を操作する）
1. Studio で Assistant → … → **Manage MCP Servers** → **Enable Studio as MCP server** をオンにする。
2. **Quick Connect** で Claude Code をオンにする。
   - 手動で登録する場合（公式パスを元に組み立てたコマンド）:
     ```powershell
     claude mcp add --transport stdio Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
     ```
3. Claude Code を再起動し、`list_roblox_studios` ツールで Studio が見えることを確認する。

## 6. 動作確認（テンプレート）
1. 次を実行する。
   ```powershell
   rojo serve games/_template/default.project.json
   ```
2. Studio で新しい Baseplate を開き、Rojo プラグインで **Connect** する。
3. Play（F5）を押し、Output に `[Server] DataService started` / `MonetizationService started` / `GameService started` が出ることを確認する。
4. 画面下に「卵を引く」「収入UP」「リバース」のボタンと確率表が出て、コインが毎秒増えることを確認する。
- DataStore を Studio でテストするには、place を一度公開して Game Settings → Security → **Enable Studio Access to API Services** をオンにする必要がある。未公開のうちは保存エラーが出るのが正常。

## 7. 終わったら
- 結果（各手順の成否、Output のエラー）を `docs/SETUP_LOG.md` に書いて commit / push する。クラウド側の Claude がそれを読んで続きを進める。
- 公開前に ★ 本人確認（ID 認証）を済ませておく（16歳未満に届けるための公開要件）。
