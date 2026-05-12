#!/bin/bash
#
# gmail-search.sh — 在 Gmail 中搜索邮件 (OpenCLI 版)
#
# 用法:
#   bash gmail-search.sh [tab_id] <query>
#   bash gmail-search.sh "from:boss@company.com"
#   bash gmail-search.sh "96D5E7..." "from:boss@company.com"
#
# 依赖: npx @jackwener/opencli, jq

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

gmail_tab() {
  local tid="${1:-}"
  if [[ -n "$tid" ]] && is_tab_id "$tid"; then
    echo "$tid"
    return
  fi
  $OC --session "$OC_SESSION" open "https://mail.google.com" | jq -r '.page'
}

oc_fill_i18n() {
  local tab="$1"
  local role="$2"
  local name_zh="$3"
  local name_en="$4"
  local value="$5"
  if $OC --session "$OC_SESSION" fill --role "$role" --name "$name_zh" "$value" --tab "$tab" >/dev/null 2>&1; then
    return 0
  fi
  $OC --session "$OC_SESSION" fill --role "$role" --name "$name_en" "$value" --tab "$tab" >/dev/null 2>&1
}

TAB_ID=""
QUERY=""

if [[ $# -ge 2 ]] && is_tab_id "$1"; then
  TAB_ID="$1"
  QUERY="$2"
elif [[ $# -ge 1 ]]; then
  QUERY="$1"
else
  echo "Usage: $(basename "$0") [tab_id] <query>" >&2
  exit 1
fi

if [[ -z "$QUERY" ]]; then
  echo "Usage: $(basename "$0") [tab_id] <query>" >&2
  exit 1
fi

TAB_ID=$(gmail_tab "$TAB_ID")

echo "=== Gmail Search ==="
echo "Query: $QUERY"
echo "Tab ID: $TAB_ID"

# 填写搜索框
echo "Filling search box..."
oc_fill_i18n "$TAB_ID" "textbox" "搜索邮件" "Search mail" "$QUERY"

# 发送回车键触发搜索
echo "Pressing Enter..."
$OC --session "$OC_SESSION" keys Enter --tab "$TAB_ID" >/dev/null 2>&1

sleep 2
echo "✅ Search executed. Check browser for results."
echo "TAB_ID: $TAB_ID"
