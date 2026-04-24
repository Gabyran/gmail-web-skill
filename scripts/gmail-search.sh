#!/bin/bash
#
# gmail-search.sh — 在 Gmail 中搜索邮件
#
# 用法:
#   bash gmail-search.sh <session> <query>
#   bash gmail-search.sh gmail-task "from:boss@company.com"

set -euo pipefail

DAEMON_URL="http://127.0.0.1:10086"
SESSION="${1:-gmail-task}"
QUERY="${2:-}"

if [[ -z "$QUERY" ]]; then
  echo "Usage: $(basename "$0") <session> <query>" >&2
  exit 1
fi

wb_cmd() {
  local action="$1"
  local args="${2:-{}}"
  curl -s -X POST "${DAEMON_URL}/command" \
    -H 'Content-Type: application/json' \
    -d "{\"action\":\"$action\",\"args\":$args,\"session\":\"$SESSION\"}"
}

get_snapshot() {
  wb_cmd "snapshot" | jq '.data // .'
}

find_ref() {
  local snapshot="$1"
  local role="$2"
  local name_pattern="$3"
  echo "$snapshot" | jq -r --arg role "$role" --arg pat "$name_pattern" \
    '.. | objects? | select(.ref != null and .role == $role and (.name | contains($pat))) | .ref' | head -1
}

echo "=== Gmail Search ==="
echo "Query: $QUERY"

# 确保在 Gmail
snapshot=$(get_snapshot)
if ! echo "$snapshot" | jq -e '.. | objects? | select(.name | contains("Gmail"))' >/dev/null 2>&1; then
  wb_cmd "navigate" '{"url":"https://mail.google.com","newTab":false}'
  sleep 2
  snapshot=$(get_snapshot)
fi

# 找到搜索框并输入
search_ref=$(find_ref "$snapshot" "textbox" "搜索邮件")
if [[ -z "$search_ref" || "$search_ref" == "null" ]]; then
  search_ref=$(find_ref "$snapshot" "textbox" "Search mail")
fi

if [[ -z "$search_ref" || "$search_ref" == "null" ]]; then
  echo "Error: Search box not found" >&2
  exit 1
fi

wb_cmd "fill" "{\"selector\":\"$search_ref\",\"value\":\"$QUERY\"}"

# 触发搜索（回车）
wb_cmd "evaluate" '{"code":"document.querySelector(\"[role=\\\"searchbox\\\"]\").dispatchEvent(new KeyboardEvent(\"keydown\",{key:\"Enter\",keyCode:13,bubbles:true}))"}'

sleep 2
echo "Search executed. Check browser for results."
