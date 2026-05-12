#!/bin/bash
#
# gmail-compose.sh — 在 Gmail 网页版写邮件 (OpenCLI 版)
#
# 用法:
#   bash gmail-compose.sh [tab_id] <to> <subject> [body]
#   bash gmail-compose.sh "xxx@gmail.com" "Hello" "This is a test email"
#   bash gmail-compose.sh "96D5E7..." "xxx@gmail.com" "Hello" "This is a test email"
#
# 依赖: npx @jackwener/opencli, jq

set -euo pipefail

# ─── OpenCLI 配置 ───

OC="npx @jackwener/opencli browser"

# 获取默认 session（从 opencli profile list 解析 default 标记）
get_default_session() {
  local session
  session=$(npx @jackwener/opencli profile list 2>/dev/null | grep "default" | awk '{print $1}')
  if [[ -z "$session" ]]; then
    echo "Error: No default OpenCLI session found. Run 'opencli profile list' to check." >&2
    exit 1
  fi
  echo "$session"
}

OC_SESSION="${OPENCLI_SESSION:-$(get_default_session)}"

# 检测第一个参数是否为 tab_id（32 位 hex）
is_tab_id() {
  [[ "$1" =~ ^[0-9A-Fa-f]{32}$ ]]
}

# 获取或创建 Gmail tab
gmail_tab() {
  local tid="${1:-}"
  if [[ -n "$tid" ]] && is_tab_id "$tid"; then
    echo "$tid"
    return
  fi
  $OC --session "$OC_SESSION" open "https://mail.google.com" | jq -r '.page'
}

# 执行 OpenCLI 命令，带 profile 断开重连
oc_run() {
  local retry=2
  for i in $(seq 1 $retry); do
    if $OC --session "$OC_SESSION" "$@" 2>/dev/null; then
      return 0
    fi
    # 如果是 profile 断开，等待后重试
    sleep 1
  done
  # 最后一次直接执行，让错误输出
  $OC --session "$OC_SESSION" "$@"
}

# 语义定位点击
oc_click() {
  local tab="$1"
  local role="$2"
  local name="$3"
  oc_run click --role "$role" --name "$name" --tab "$tab" >/dev/null
}

# 语义定位填充
oc_fill() {
  local tab="$1"
  local role="$2"
  local name="$3"
  local value="$4"
  oc_run fill --role "$role" --name "$name" "$value" --tab "$tab" >/dev/null
}

# 中英文尝试 click（先中后英）
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

# 中英文尝试 fill（先中后英）
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

# 填充邮件正文（处理多个匹配元素，选择可见的）
oc_fill_body() {
  local tab="$1"
  local value="$2"
  local body_ref
  body_ref=$($OC --session "$OC_SESSION" find --role textbox --name "邮件正文" --tab "$tab" 2>/dev/null | jq -r '.entries[] | select(.visible == true) | .ref')
  if [[ -z "$body_ref" ]]; then
    body_ref=$($OC --session "$OC_SESSION" find --role textbox --name "Message body" --tab "$tab" 2>/dev/null | jq -r '.entries[] | select(.visible == true) | .ref')
  fi
  if [[ -z "$body_ref" ]]; then
    echo "Error: body field not found" >&2
    return 1
  fi
  $OC --session "$OC_SESSION" fill "$body_ref" "$value" --tab "$tab" >/dev/null 2>&1
}

# ─── 参数解析 ───

TAB_ID=""
TO=""
SUBJECT=""
BODY=""

if [[ $# -ge 4 ]] && is_tab_id "$1"; then
  TAB_ID="$1"
  TO="$2"
  SUBJECT="$3"
  BODY="${4:-}"
elif [[ $# -ge 3 ]]; then
  TO="$1"
  SUBJECT="$2"
  BODY="${3:-}"
else
  echo "Usage: $(basename "$0") [tab_id] <to> <subject> [body]" >&2
  exit 1
fi

if [[ -z "$TO" || -z "$SUBJECT" ]]; then
  echo "Usage: $(basename "$0") [tab_id] <to> <subject> [body]" >&2
  exit 1
fi

# ─── 主流程 ───

echo "=== Gmail Compose ==="
echo "To: $TO"
echo "Subject: $SUBJECT"
echo ""

TAB_ID=$(gmail_tab "$TAB_ID")
echo "Tab ID: $TAB_ID"

# Step 1: 点击"写邮件"
echo "Clicking 'Compose'..."
oc_click_i18n "$TAB_ID" "button" "写邮件" "Compose"
sleep 1

# Step 2: 填写收件人
echo "Filling recipient..."
oc_fill_i18n "$TAB_ID" "combobox" "收件人" "To" "$TO"

# Step 3: 填写主题
echo "Filling subject..."
oc_fill_i18n "$TAB_ID" "textbox" "主题" "Subject" "$SUBJECT"

# Step 4: 填写正文（可选）
if [[ -n "$BODY" ]]; then
  echo "Filling body..."
  oc_fill_body "$TAB_ID" "$BODY"
fi

# Step 5: 截图预览
echo "Taking preview screenshot..."
$OC --session "$OC_SESSION" screenshot /tmp/gmail-compose-preview.png --tab "$TAB_ID" >/dev/null 2>&1
echo "Preview saved to: /tmp/gmail-compose-preview.png"

echo ""
echo "✅ Compose ready. Call gmail-send.sh to send, or edit manually in browser."
echo "TAB_ID: $TAB_ID"
