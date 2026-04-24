#!/bin/bash
#
# gmail-archive.sh — 归档选中的邮件
#
# 用法:
#   bash gmail-archive.sh <session>
#   bash gmail-archive.sh gmail-task

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

echo "=== Gmail Archive ==="

# 通过 evaluate 触发 Gmail 的归档快捷键
echo "Archiving..."
wb_cmd "evaluate" '{"code":"document.dispatchEvent(new KeyboardEvent(\"keydown\",{key:\"e\",code:\"KeyE\",ctrlKey:false,metaKey:false,bubbles:true}))"}'

sleep 1
echo "Archive command sent."
