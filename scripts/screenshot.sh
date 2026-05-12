#!/bin/bash
#
# screenshot.sh — 截取 Gmail 页面截图 (OpenCLI 版)
#
# 用法:
#   bash screenshot.sh [tab_id]
#   bash screenshot.sh -o ~/Desktop/gmail.png
#   bash screenshot.sh 96D5E7... -o ~/Desktop/gmail.png
#
# 依赖: npx @jackwener/opencli

set -euo pipefail

OC="npx @jackwener/opencli browser"

get_default_session() {
  local session
  session=$(npx @jackwener/opencli profile list 2>/dev/null | grep "default" | awk '{print $1}')
  if [[ -z "$session" ]]; then
    echo "Error: No default OpenCLI session found." >&2
    exit 1
  fi
  echo "$session"
}

OC_SESSION="${OPENCLI_SESSION:-$(get_default_session)}"

is_tab_id() {
  [[ "$1" =~ ^[0-9A-Fa-f]{32}$ ]]
}

OUTPUT_PATH=""
TAB_ID=""
FULL_PAGE=false

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) OUTPUT_PATH="$2"; shift 2 ;;
    -f) FULL_PAGE=true; shift ;;
    -h) echo "Usage: $(basename "$0") [tab_id] [-o path] [-f]"; exit 0 ;;
    *)
      if [[ -z "$TAB_ID" ]] && is_tab_id "$1"; then
        TAB_ID="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$OUTPUT_PATH" ]]; then
  mkdir -p /tmp/gmail-web-skill/screenshots
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  OUTPUT_PATH="/tmp/gmail-web-skill/screenshots/${TIMESTAMP}.png"
fi

if [[ -z "$TAB_ID" ]]; then
  echo "Error: No tab_id provided. Open Gmail first or pass a tab_id." >&2
  exit 1
fi

OPTS=""
[[ "$FULL_PAGE" == true ]] && OPTS="--full-page"

$OC --session "$OC_SESSION" screenshot "$OUTPUT_PATH" $OPTS --tab "$TAB_ID" >/dev/null 2>&1
echo "$OUTPUT_PATH"
