#!/bin/bash
#
# gmail-send.sh — 发送当前写信窗口中的邮件 (OpenCLI 版)
#
# 用法:
#   bash gmail-send.sh [tab_id]
#   bash gmail-send.sh 96D5E775...
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

oc_click_i18n() {
  local tab="$1"
  local role="$2"
  local name_zh="$3"
  local name_en="$4"
  if $OC --session "$OC_SESSION" click --role "$role" --name "$name_zh" --tab "$tab" >/dev/null 2>&1; then
    return 0
  fi
  $OC --session "$OC_SESSION" click --role "$role" --name "$name_en" --tab "$tab" >/dev/null 2>&1
}

TAB_ID="${1:-}"
TAB_ID=$(gmail_tab "$TAB_ID")

echo "=== Gmail Send ==="
echo "Tab ID: $TAB_ID"

# 点击发送按钮
echo "Clicking Send..."
oc_click_i18n "$TAB_ID" "button" "发送" "Send"

sleep 3

# 验证：检查页面是否回到收件箱
echo "Verifying..."
STATE=$($OC --session "$OC_SESSION" state --tab "$TAB_ID" 2>/dev/null || true)
if echo "$STATE" | grep -qiE "(收件箱|inbox|mail\.google\.com\/mail\/u\/)"; then
  echo "✅ Email sent successfully"
else
  echo "Warning: Inbox not detected after send, please check manually" >&2
fi

echo "TAB_ID: $TAB_ID"
