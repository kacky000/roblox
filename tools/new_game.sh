#!/usr/bin/env bash
# 新規ゲームをテンプレートから作成: tools/new_game.sh <slug>
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="${1:?usage: tools/new_game.sh <slug>}"
DEST="$ROOT/games/$SLUG"
[ -e "$DEST" ] && { echo "already exists: $DEST"; exit 1; }
cp -r "$ROOT/games/_template" "$DEST"
rm -rf "$DEST/build" "$DEST/sourcemap.json"
sed -i "s/\"name\": \"Game\"/\"name\": \"$SLUG\"/" "$DEST/default.project.json"
sed -i "s#you/game#you/$SLUG#" "$DEST/wally.toml"
cat > "$DEST/GDD.md" <<MD
# $SLUG — GDD
（roblox-game-concept スキルの「出力形式」の見出しに沿って記入）
MD
echo "created games/$SLUG"
"$ROOT/tools/check.sh" "games/$SLUG" | tail -1
