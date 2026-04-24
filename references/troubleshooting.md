# Gmail Web Skill 故障排查

## 快速诊断流程

```
1. curl -s http://127.0.0.1:10086/status
   └── running: true, extension_connected: true ?
       ├── No → 检查 Kimi WebBridge daemon
       └── Yes → 继续

2. curl -s -X POST ... -d '{"action":"snapshot"...}'
   └── 返回正常 JSON ?
       ├── No → 检查 session 名称
       └── Yes → 继续

3. snapshot 中是否有 Gmail 相关元素 ?
       ├── No → 页面未加载或不在 Gmail
       └── Yes → 继续

4. 目标元素的 role + name 是否匹配预期 ?
       ├── No → Gmail 界面语言可能不同
       └── Yes → 检查网络延迟，增加重试
```

## 常见问题

### Q1: "Element not found" 错误

**原因**:
- 页面未完全加载
- 元素被弹窗遮挡
- Gmail 界面语言与脚本预期不同
- 页面布局更新（Gmail 经常 A/B 测试新 UI）

**解决**:
```bash
# 增加等待时间
sleep 2

# 检查弹窗并关闭
snapshot=$(curl ... -d '{"action":"snapshot"...}')
echo "$snapshot" | jq '.. | objects? | select(.name | contains("不用了") or contains("No thanks") or contains("关闭") or contains("Close")) | .ref'

# 切换中英文匹配
# 脚本已内置中英文兼容，如仍失败，检查 Gmail 实际语言设置
```

### Q2: 发送邮件后没有"邮件已发送"提示

**原因**:
- 网络延迟，发送尚未完成
- 邮件被保存到草稿箱（缺少收件人或主题）
- 发送按钮点击未生效

**解决**:
```bash
# 发送后等待更长时间
sleep 5

# 检查是否还在写信窗口
snapshot=$(curl ... -d '{"action":"snapshot"...}')
if echo "$snapshot" | jq -e '.. | objects? | select(.name | contains("新邮件") or contains("New message"))' >/dev/null 2>&1; then
  echo "Still in compose window, send may have failed"
fi
```

### Q3: fill 后输入框内容为空

**原因**:
- 输入框未获得焦点
- Gmail 使用 contenteditable div 而非标准 input
- WebBridge 的 fill 操作与 Gmail 的 React 事件系统不兼容

**解决**:
```bash
# 先 click 再 fill
curl ... -d '{"action":"click","args":{"selector":"@e195"}}'
sleep 0.5
curl ... -d '{"action":"fill","args":{"selector":"@e195","value":"text"}}'

# 或使用 evaluate 直接操作 DOM
curl ... -d '{
  "action": "evaluate",
  "args": {"code": "document.querySelector('[aria-label=\"To recipients\"]').value = 'xxx@gmail.com'; document.querySelector('[aria-label=\"To recipients\"]').dispatchEvent(new Event('input', {bubbles: true}));"}
}'
```

### Q4: Gmail 加载缓慢或超时

**原因**:
- 网络问题
- Gmail 资源量大（JS/CSS）
- 浏览器扩展干扰

**解决**:
```bash
# 增加超时时间
# 在 curl 命令中添加 --max-time 60

# 先打开 Gmail 等待加载
wb_cmd "navigate" '{"url":"https://mail.google.com","newTab":true}'
sleep 5  # 给足加载时间
```

### Q5: 多语言 Gmail 界面

**症状**: 脚本中的中文匹配在英文界面下失效

**解决**: 所有脚本已内置中英文双匹配。如需其他语言，修改脚本中的匹配逻辑：

```bash
# 在 find_ref 函数中增加更多语言
find_ref_multi_lang() {
  local snapshot="$1"
  local role="$2"
  local cn="$3"
  local en="$4"
  local ref
  ref=$(find_ref "$snapshot" "$role" "$cn")
  [[ -z "$ref" || "$ref" == "null" ]] && ref=$(find_ref "$snapshot" "$role" "$en")
  echo "$ref"
}
```

### Q6: Daemon 无响应

**检查**:
```bash
# Standalone 模式
curl -s http://127.0.0.1:10086/status

# 如果未响应
~/.kimi-webbridge/bin/kimi-webbridge status
~/.kimi-webbridge/bin/kimi-webbridge restart
```

## 报告 Bug

如果以上方法都无法解决问题：

1. 运行 `bash scripts/screenshot.sh -s <session>` 截图
2. 保存 snapshot JSON: `curl ... snapshot ... > /tmp/gmail-debug.json`
3. 记录 Gmail 界面语言（中文/英文）
4. 在 GitHub Issues 中提交，附上以上信息
