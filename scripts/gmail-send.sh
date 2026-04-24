#!/bin/bash
#
# gmail-send.sh — 发送当前写信窗口中的邮件
#
# 用法:
#   bash gmail-send.sh <session>
#   bash gmail-send.sh gmail-task
#
# 前提: 写信窗口已经打开

set -euo pipefail

DAEMON_URL="http://127.0.0.1:10086"
SESSION="${1:-gmail-task}"

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

echo "=== Gmail Send ==="
echo "Session: $SESSION"

snapshot=$(get_snapshot)

# 点击发送按钮
echo "Clicking Send..."
send_ref=$(find_ref "$snapshot" "button" "发送")
if [[ -z "$send_ref" || "$send_ref" == "null" ]]; then
  send_ref=$(find_ref "$snapshot" "button" "Send")
fi

if [[ -z "$send_ref" || "$send_ref" == "null" ]]; then
  echo "Error: Send button not found" >&2
  exit 1
fi

wb_cmd "click" "{\"selector\":\"$send_ref\"}"

sleep 3

# 验证
echo "Verifying..."
snapshot=$(get_snapshot)
if echo "$snapshot" | jq -e '.. | objects? | select(.name | contains("收件箱") or contains("Inbox"))' >/dev/null 2>&1; then
  echo "Email sent successfully"
else
  echo "Warning: Inbox not detected after send, please check manually" >&2
fi
