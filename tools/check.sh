#!/usr/bin/env bash
# 品質ゲート: フォーマット → Lint → 型チェック → ユニットテスト → Rojoビルド
# 使い方: tools/check.sh games/<game-dir>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="${1:-games/_template}"
cd "$ROOT/$GAME"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
API="$ROOT/tools/roblox-api"
[ -f roblox.yml ] || SELENE_API_DUMP_FILE="$API/API-Dump.json" selene generate-roblox-std >/dev/null
echo "▶ stylua";  stylua src tests
echo "▶ selene";  selene src
echo "▶ luau-lsp (strict type check)"
rojo sourcemap default.project.json -o sourcemap.json >/dev/null
luau-lsp analyze --definitions:@roblox="$API/globalTypes.d.luau" --sourcemap=sourcemap.json --base-luaurc=.luaurc src 2>&1 | grep -v '^\[INFO\]\|^\[WARN\]' || true
luau-lsp analyze --definitions:@roblox="$API/globalTypes.d.luau" --sourcemap=sourcemap.json --base-luaurc=.luaurc src >/dev/null 2>&1
echo "▶ lune tests"; lune run tests/run.luau
mkdir -p build
echo "▶ rojo build"; rojo build default.project.json -o build/game.rbxl
echo "✅ all checks passed → $GAME/build/game.rbxl"
