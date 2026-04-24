# 示例：写邮件并发送

## 场景

给用户的朋友发送一封问候邮件。

## 完整命令流

```bash
# 1. 确保 Kimi WebBridge daemon 在运行
curl -s http://127.0.0.1:10086/status
# 预期: {"running":true,"extension_connected":true,...}

# 2. 打开 Gmail
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"navigate","args":{"url":"https://mail.google.com","newTab":true},"session":"gmail-demo"}'

# 3. 等待页面加载
sleep 3

# 4. Snapshot 获取当前页面元素
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"snapshot","session":"gmail-demo"}' | jq '.data.tree'

# 5. 从 snapshot 中找到 "写邮件" 按钮的引用
# 假设返回了 @e15，点击它
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"click","args":{"selector":"@e15"},"session":"gmail-demo"}'

# 6. 等待写信窗口弹出
sleep 1

# 7. Snapshot 获取写信窗口元素
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"snapshot","session":"gmail-demo"}' | jq '.data.tree'

# 8. 填写收件人（假设 @e195 是收件人输入框）
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e195","value":"friend@example.com"},"session":"gmail-demo"}'

# 9. 填写主题（假设 @e198 是主题输入框）
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e198","value":"问候"},"session":"gmail-demo"}'

# 10. 填写正文（假设 @e199 是正文输入框）
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e199","value":"最近怎么样？有空一起喝咖啡！"},"session":"gmail-demo"}'

# 11. 截图预览
bash scripts/screenshot.sh -s gmail-demo -o /tmp/gmail-preview.png

# 12. 点击发送（假设 @e214 是发送按钮）
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"click","args":{"selector":"@e214"},"session":"gmail-demo"}'

# 13. 等待并验证
sleep 3
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"snapshot","session":"gmail-demo"}' | jq '.data.tree | .. | objects? | select(.ref) | {role, name, ref}' | grep -E '收件箱|Inbox|写邮件|Compose'
```

## 简化版：使用封装脚本

```bash
# 一步写信
bash scripts/gmail-compose.sh gmail-demo "friend@example.com" "问候" "最近怎么样？有空一起喝咖啡！"

# 截图确认
bash scripts/screenshot.sh -s gmail-demo -o /tmp/gmail-preview.png

# 发送
bash scripts/gmail-send.sh gmail-demo
```
