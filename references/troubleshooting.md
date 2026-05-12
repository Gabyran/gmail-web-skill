# Gmail Web Skill 故障排查

## 快速诊断流程

```
1. opencli doctor
   └── running + extension_connected ?
       ├── No → 检查 OpenCLI daemon 和 Chrome 扩展
       └── Yes → 继续

2. opencli browser state --tab <targetId>
   └── 返回正常页面信息 ?
       ├── No → 检查 tab_id 是否有效
       └── Yes → 继续

3. state 输出中是否有 Gmail 相关元素 ?
       ├── No → 页面未加载或不在 Gmail
       └── Yes → 继续

4. 目标元素的 role + name 是否匹配预期 ?
       ├── No → Gmail 界面语言可能不同
       └── Yes → 检查网络延迟，增加重试
```

## 常见问题

### Q1: "click/fill failed" 错误

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
opencli browser click --role button --name "不用了" --tab "$TAB_ID" 2>/dev/null || \
opencli browser click --role button --name "No thanks" --tab "$TAB_ID" 2>/dev/null

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
STATE=$(opencli browser state --tab "$TAB_ID" 2>/dev/null)
if echo "$STATE" | grep -qE "新邮件|New message"; then
  echo "Still in compose window, send may have failed"
fi
```

### Q3: fill 后输入框内容为空

**原因**:
- 输入框未获得焦点
- Gmail 使用 contenteditable div 而非标准 input
- OpenCLI 的 fill 操作与 Gmail 的 React 事件系统不兼容

**解决**:
```bash
# 先 click 再 fill
opencli browser click --role textbox --name "主题" --tab "$TAB_ID"
sleep 0.5
opencli browser fill --role textbox --name "主题" "文本内容" --tab "$TAB_ID"

# 或使用 eval 直接操作 DOM
opencli browser eval "document.querySelector('[aria-label=\"To recipients\"]').value = 'xxx@gmail.com'; document.querySelector('[aria-label=\"To recipients\"]').dispatchEvent(new Event('input', {bubbles: true}));" --tab "$TAB_ID"
```

### Q4: Gmail 加载缓慢或超时

**原因**:
- 网络问题
- Gmail 资源量大（JS/CSS）
- 浏览器扩展干扰

**解决**:
```bash
# 先打开 Gmail 等待加载
TAB_ID=$(opencli browser open "https://mail.google.com" | jq -r '.page')
sleep 5  # 给足加载时间
```

### Q5: 多语言 Gmail 界面

**症状**: 脚本中的中文匹配在英文界面下失效

**解决**: 所有脚本已内置中英文双匹配。如需其他语言，修改脚本中的 `oc_click_i18n` / `oc_fill_i18n` 函数：

```bash
oc_fill_i18n "$TAB_ID" "textbox" "主题" "Subject" "邮件主题"
# 增加第三语言
oc_fill_i18n "$TAB_ID" "textbox" "主题" "Subject" "Asunto" "邮件主题"
```

### Q6: OpenCLI daemon 无响应

**检查**:
```bash
# 检查 OpenCLI 状态
opencli doctor

# 如果 daemon 未运行
opencli daemon restart

# 检查 Chrome 扩展是否已安装并连接
# 访问 chrome://extensions ，确保 OpenCLI 扩展已启用
```

## 报告 Bug

如果以上方法都无法解决问题：

1. 运行 `bash scripts/screenshot.sh "$TAB_ID" -o /tmp/gmail-debug.png` 截图
2. 保存页面状态: `opencli browser state --tab "$TAB_ID" > /tmp/gmail-debug-state.txt`
3. 记录 Gmail 界面语言（中文/英文）
4. 在 GitHub Issues 中提交，附上以上信息
