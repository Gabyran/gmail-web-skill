#!/bin/bash
#
# screenshot.sh — 截取 Gmail 页面截图
# 复用 Kimi WebBridge 的 screenshot 功能
#
# 用法:
#   bash screenshot.sh -s gmail-task
#   bash screenshot.sh -s gmail-task -o ~/Desktop/gmail.png
#   bash screenshot.sh -s gmail-task -f jpeg -q 60

set -euo pipefail

# 优先使用 Kimi WebBridge 的 screenshot 脚本
WEBBRIDGE_SCRIPT="${KIMI_WEBBRIDGE_SCRIPT:-/Users/gabi/.config/agents/skills/kimi-webbridge/scripts/screenshot.sh}"

if [[ -f "$WEBBRIDGE_SCRIPT" ]]; then
  exec bash "$WEBBRIDGE_SCRIPT" "$@"
fi

# 降级：直接调用 API（不推荐，会返回大量 base64）
DAEMON_URL="http://127.0.0.1:10086"
SESSION=""
OUTPUT_PATH=""
FORMAT="png"
QUALITY=""

while getopts "s:o:f:q:h" opt; do
  case "$opt" in
    s) SESSION="$OPTARG" ;;
    o) OUTPUT_PATH="$OPTARG" ;;
    f) FORMAT="$OPTARG" ;;
    q) QUALITY="$OPTARG" ;;
    h) echo "Usage: $(basename "$0") [-s session] [-o path] [-f format] [-q quality]"; exit 0 ;;
  esac
done

ARGS=$(jq -n --arg fmt "$FORMAT" '{format: $fmt}')
[[ -n "$QUALITY" ]] && ARGS=$(echo "$ARGS" | jq --argjson q "$QUALITY" '. + {quality: $q}')

BODY=$(jq -n --arg action "screenshot" --argjson args "$ARGS" '{action: $action, args: $args}')
[[ -n "$SESSION" ]] && BODY=$(echo "$BODY" | jq --arg s "$SESSION" '. + {session: $s}')

RESPONSE=$(curl -s -X POST "${DAEMON_URL}/command" \
  -H 'Content-Type: application/json' \
  -d "$BODY" --max-time 30)

B64_DATA=$(echo "$RESPONSE" | jq -er '.data.data | select(type == "string" and length > 0)')
if [[ -z "$B64_DATA" ]]; then
  echo "Error: No image data" >&2
  exit 1
fi

if [[ -z "$OUTPUT_PATH" ]]; then
  mkdir -p /tmp/gmail-web-skill/screenshots
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  OUTPUT_PATH="/tmp/gmail-web-skill/screenshots/${TIMESTAMP}.${FORMAT}"
fi

if base64 --help 2>&1 | grep -q '\-D'; then
  echo "$B64_DATA" | base64 -D > "$OUTPUT_PATH"
else
  echo "$B64_DATA" | base64 -d > "$OUTPUT_PATH"
fi

echo "$OUTPUT_PATH"
