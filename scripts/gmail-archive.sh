#!/bin/bash
#
# gmail-archive.sh — 归档选中的邮件 (OpenCLI 版)
#
# 用法:
#   bash gmail-archive.sh [tab_id]
#   bash gmail-archive.sh 96D5E775...
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

TAB_ID="${1:-}"
TAB_ID=$(gmail_tab "$TAB_ID")

echo "=== Gmail Archive ==="
echo "Tab ID: $TAB_ID"

# 通过 eval 触发 Gmail 的归档快捷键 'e'
echo "Archiving..."
$OC --session "$OC_SESSION" eval "document.dispatchEvent(new KeyboardEvent('keydown',{key:'e',code:'KeyE',ctrlKey:false,metaKey:false,bubbles:true}))" --tab "$TAB_ID" >/dev/null 2>&1

sleep 1
echo "✅ Archive command sent."
echo "TAB_ID: $TAB_ID"
