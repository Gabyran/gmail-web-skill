#!/bin/bash
#
# gmail-open-mail.sh — 打开收件箱中的邮件 (OpenCLI 版)
#
# 用法:
#   bash gmail-open-mail.sh [tab_id] [index]
#   bash gmail-open-mail.sh                # 打开第一封
#   bash gmail-open-mail.sh 96D5E7...      # 打开第一封
#   bash gmail-open-mail.sh 96D5E7... 3    # 打开第3封
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

TAB_ID=""
INDEX=1

if [[ $# -ge 2 ]] && is_tab_id "$1"; then
  TAB_ID="$1"
  INDEX="${2:-1}"
elif [[ $# -ge 1 ]] && is_tab_id "$1"; then
  TAB_ID="$1"
elif [[ $# -ge 1 ]]; then
  INDEX="$1"
fi

TAB_ID=$(gmail_tab "$TAB_ID")

echo "=== Gmail Open Mail #$INDEX ==="
echo "Tab ID: $TAB_ID"

# 获取邮件列表中的第 N 个邮件链接
# Gmail 收件箱中邮件行通常是 table row 内的链接
# 使用 find 搜索邮件发送者/主题链接
MAIL_REFS=$($OC --session "$OC_SESSION" find --css "table tbody tr" --tab "$TAB_ID" 2>/dev/null | jq -r '.entries[].ref // empty')

TARGET_REF=$(echo "$MAIL_REFS" | sed -n "${INDEX}p")

if [[ -z "$TARGET_REF" ]]; then
  echo "Error: Mail #$INDEX not found" >&2
  exit 1
fi

$OC --session "$OC_SESSION" click "$TARGET_REF" --tab "$TAB_ID" >/dev/null 2>&1
sleep 1
echo "✅ Opened mail #$INDEX (ref: $TARGET_REF)"
echo "TAB_ID: $TAB_ID"
