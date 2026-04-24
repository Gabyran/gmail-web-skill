#!/bin/bash
#
# gmail-compose.sh — 在 Gmail 网页版写邮件
#
# 用法:
#   bash gmail-compose.sh <session> <to> <subject> <body>
#   bash gmail-compose.sh gmail-task "xxx@gmail.com" "Hello" "This is a test email"
#
# 依赖: curl, jq

set -euo pipefail

DAEMON_URL="http://127.0.0.1:10086"
SESSION="${1:-gmail-task}"
TO="${2:-}"
SUBJECT="${3:-}"
BODY="${4:-}"

if [[ -z "$TO" || -z "$SUBJECT" ]]; then
  echo "Usage: $(basename "$0") <session> <to> <subject> [body]" >&2
  exit 1
fi

# ─── 辅助函数 ───

# 发送 WebBridge 命令
wb_cmd() {
  local action="$1"
  local args="${2:-{}}"
  curl -s -X POST "${DAEMON_URL}/command" \
    -H 'Content-Type: application/json' \
    -d "{\"action\":\"$action\",\"args\":$args,\"session\":\"$SESSION\"}"
}

# 获取 snapshot 并输出原始 JSON
get_snapshot() {
  wb_cmd "snapshot" | jq '.data // .'
}

# 按 role + name 模式查找元素引用
find_ref() {
  local snapshot="$1"
  local role="$2"
  local name_pattern="$3"
  echo "$snapshot" | jq -r --arg role "$role" --arg pat "$name_pattern" \
    '.. | objects? | select(.ref != null and .role == $role and (.name | contains($pat))) | .ref' | head -1
}

# 带重试的查找（页面可能还没加载完）
find_ref_with_retry() {
  local role="$1"
  local name_pattern="$2"
  local max_retry=5
  local ref=""

  for i in $(seq 1 $max_retry); do
    local snapshot
    snapshot=$(get_snapshot)
    ref=$(find_ref "$snapshot" "$role" "$name_pattern")
    if [[ -n "$ref" && "$ref" != "null" ]]; then
      echo "$ref"
      return 0
    fi
    echo "  [retry $i/$max_retry] Waiting for element: role=$role, name~'$name_pattern'..." >&2
    sleep 1
  done

  echo "Error: Element not found after $max_retry retries (role=$role, name~'$name_pattern')" >&2
  return 1
}

# ─── 主流程 ───

echo "=== Gmail Compose ==="
echo "To: $TO"
echo "Subject: $SUBJECT"
echo ""

# Step 1: 确保 Gmail 已打开（如果当前不在 Gmail）
current_url=$(wb_cmd "snapshot" | jq -r '.data.url // .url // ""')
if [[ "$current_url" != *"mail.google.com"* ]]; then
  echo "Opening Gmail..."
  wb_cmd "navigate" "{\"url\":\"https://mail.google.com\",\"newTab\":false}"
  sleep 2
fi

# Step 2: 点击"写邮件"按钮
echo "Clicking 'Compose'..."
compose_ref=$(find_ref_with_retry "button" "写邮件")
if [[ -z "$compose_ref" ]]; then
  # 尝试英文
  compose_ref=$(find_ref_with_retry "button" "Compose")
fi
wb_cmd "click" "{\"selector\":\"$compose_ref\"}"
sleep 1

# Step 3: 填写收件人
echo "Filling recipient..."
to_ref=$(find_ref_with_retry "combobox" "收件人")
if [[ -z "$to_ref" ]]; then
  to_ref=$(find_ref_with_retry "combobox" "To")
fi
wb_cmd "fill" "{\"selector\":\"$to_ref\",\"value\":\"$TO\"}"

# Step 4: 填写主题
echo "Filling subject..."
subject_ref=$(find_ref_with_retry "textbox" "主题")
if [[ -z "$subject_ref" ]]; then
  subject_ref=$(find_ref_with_retry "textbox" "Subject")
fi
wb_cmd "fill" "{\"selector\":\"$subject_ref\",\"value\":\"$SUBJECT\"}"

# Step 5: 填写正文（可选）
if [[ -n "$BODY" ]]; then
  echo "Filling body..."
  body_ref=$(find_ref_with_retry "textbox" "邮件正文")
  if [[ -z "$body_ref" ]]; then
    body_ref=$(find_ref_with_retry "textbox" "Message body")
  fi
  wb_cmd "fill" "{\"selector\":\"$body_ref\",\"value\":\"$BODY\"}"
fi

# Step 6: 截图预览
echo "Taking preview screenshot..."
bash "$(dirname "$0")/screenshot.sh" -s "$SESSION" -o "/tmp/gmail-compose-preview.png"
echo "Preview saved to: /tmp/gmail-compose-preview.png"

echo ""
echo "✅ Compose ready. Call gmail-send.sh to send, or edit manually in browser."
