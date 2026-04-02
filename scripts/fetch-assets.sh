#!/bin/bash
# fetch-assets.sh — Download Kairu dolphin animation assets
# These are original Microsoft Office XP assets and cannot be redistributed.
# This script lets each user fetch them directly from public archives.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESOURCES="$SCRIPT_DIR/../Sources/Kairu/Resources"

mkdir -p "$RESOURCES"

echo "🐬 Kairu アセットをダウンロード中..."
echo ""

# Static image from Internet Archive (Office 97 original)
echo "  [1/4] kairu.png (Internet Archive)"
curl -sL -o "$RESOURCES/kairu.png" \
  "https://archive.org/download/dolphin_202003/kairu.png"

# Animated GIFs compiled from Office XP sprites (Tumblr / public fan archive)
echo "  [2/4] kairu_idle.gif"
curl -sL -o "$RESOURCES/kairu_idle.gif" \
  "https://64.media.tumblr.com/9a96111caecf7e06d44174d6ffaae70f/8f362b0e89492524-75/s250x400/e669418911b82f52de66b9398f5e30d2f9576c98.gifv"

echo "  [3/4] kairu_thinking.gif"
curl -sL -o "$RESOURCES/kairu_thinking.gif" \
  "https://64.media.tumblr.com/1e7feb0abb2af6b8b05e7ee719c0d956/8f362b0e89492524-db/s250x400/a388b4ea29ace1999b1f6c8a124fb076947d97cb.gifv"

echo "  [4/4] kairu_talking.gif"
curl -sL -o "$RESOURCES/kairu_talking.gif" \
  "https://64.media.tumblr.com/f7db2422de89e20b19a013d2bacb7dee/8f362b0e89492524-db/s250x400/2f66d4c6a30248410d53c26681b4b80d03682853.gifv"

echo ""

# Verify downloads
OK=0
FAIL=0
for f in kairu.png kairu_idle.gif kairu_thinking.gif kairu_talking.gif; do
  if [ -s "$RESOURCES/$f" ]; then
    OK=$((OK + 1))
  else
    echo "  ✗ $f のダウンロードに失敗しました"
    FAIL=$((FAIL + 1))
  fi
done

echo "✅ $OK / $((OK + FAIL)) アセットを取得しました → $RESOURCES"
if [ "$FAIL" -gt 0 ]; then
  echo "⚠️  一部のダウンロードに失敗しました。ネットワーク接続を確認してください。"
  exit 1
fi
echo ""
echo "次のステップ:"
echo "  swift build && open .build/debug/Kairu.app"
