#!/bin/bash
#
# gmail-open-mail.sh — 打开收件箱中的第一封邮件
#
# 用法:
#   bash gmail-open-mail.sh <session> [index]
#   bash gmail-open-mail.sh gmail-task      # 打开第一封
#   bash gmail-open-mail.sh gmail-task 3    # 打开第3封

set -euo pipefail

DAEMON_URL="http://127.0.0.1:10086"
SESSION="${1:-gmail-task}"
INDEX="${2:-1}"

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

echo "=== Gmail Open Mail #$INDEX ==="

snapshot=$(get_snapshot)

# 获取邮件列表中的第 N 个 link（排除导航链接）
mail_ref=$(echo "$snapshot" | jq -r \
  '.. | objects? | select(.ref != null and .role == "link" and (.name | contains(",")) and (.name | contains("未读") or .name | contains("安全提醒") or .name | contains("登录") or .name | length > 20)) | .ref' | sed -n "${INDEX}p")

if [[ -z "$mail_ref" || "$mail_ref" == "null" ]]; then
  echo "Error: Mail #$INDEX not found" >&2
  exit 1
fi

wb_cmd "click" "{\"selector\":\"$mail_ref\"}"
sleep 1
echo "Opened mail #$INDEX"
