---
name: gmail-web-skill
description: |
  控制 Gmail 网页版（mail.google.com）进行邮件操作。支持写信、发送、搜索、归档、标签、星标、回复等常见操作。基于 OpenCLI browser 协议，复用用户的 Gmail 登录态。

  ⚠️ 注意：这是 **Gmail 网页版**（Web UI）操作，不是 Gmail API。所有操作通过浏览器语义定位完成，不需要 API Key。

  使用时机：用户需要写邮件、发邮件、搜索邮件、管理收件箱、查看邮件等与 Gmail 相关的任务。
---

# Gmail Web Skill

通过浏览器控制 Gmail 网页版，复用用户的登录态完成邮件操作。

## 依赖

- OpenCLI daemon 运行中（`opencli doctor` 验证）
- Chrome/Edge 浏览器已安装 OpenCLI 扩展
- 用户在浏览器中已登录 Gmail

## 核心原则

1. **语义定位**：使用 `--role` + `--name` 直接定位元素，不需要先获取 accessibility tree 再解析 `@e` 引用。
2. **先打开再操作**：任何脚本调用前，确保 Gmail 页面已通过 `browser open` 打开。
3. **tab 传递**：`browser open` 返回的 `page`（targetId）是后续所有命令的 `--tab` 参数。
4. **操作后验证**：关键操作（发送、删除）后检查页面状态。

## 工具调用方式

所有操作通过 `opencli browser` 命令完成：

```bash
# 打开 Gmail 并获取 tab ID
TAB_ID=$(opencli browser open "https://mail.google.com" | jq -r '.page')

# 点击"写邮件"
opencli browser click --role button --name "写邮件" --tab "$TAB_ID"

# 填写输入框
opencli browser fill --role textbox --name "主题" "邮件主题" --tab "$TAB_ID"

# 截图
opencli browser screenshot ~/Desktop/gmail.png --tab "$TAB_ID"
```

## 标准工作流程

```
1. browser open "https://mail.google.com"  → 获取 targetId
2. browser click --role button --name "写邮件"  → 执行操作
3. browser fill --role textbox --name "主题" "内容"  → 填写内容
4. browser state --tab <targetId>          → 验证页面状态
5. browser screenshot [path]               → 可视化确认
```

## 页面状态判断

Gmail 网页版主要有以下几种页面状态：

| 状态 | 判断方法 |
|------|---------|
| **收件箱** | `browser state` 输出中包含 `"收件箱"` 或 `"Inbox"` |
| **写信窗口** | `browser state` 输出中包含 `"发送至收件人"` 或 `"To"` |
| **邮件详情页** | `browser state` 输出中包含 `"回复"` 或 `"Reply"` |
| **搜索页** | URL 包含 `search/` |

## 常用操作

### 打开 Gmail

```bash
TAB_ID=$(opencli browser open "https://mail.google.com" | jq -r '.page')
```

### 点击"写邮件"

```bash
opencli browser click --role button --name "写邮件" --tab "$TAB_ID"
# 英文界面回退
opencli browser click --role button --name "Compose" --tab "$TAB_ID"
```

### 填写邮件

```bash
# 收件人
opencli browser fill --role combobox --name "收件人" "recipient@example.com" --tab "$TAB_ID"
# 英文回退: --name "To"

# 主题
opencli browser fill --role textbox --name "主题" "邮件主题" --tab "$TAB_ID"
# 英文回退: --name "Subject"

# 正文
opencli browser fill --role textbox --name "邮件正文" "邮件正文内容" --tab "$TAB_ID"
# 英文回退: --name "Message body"
```

### 发送邮件

```bash
opencli browser click --role button --name "发送" --tab "$TAB_ID"
# 英文回退: --name "Send"
```

发送后验证：
```bash
opencli browser state --tab "$TAB_ID" | grep -E "收件箱|Inbox"
```

### 搜索邮件

```bash
# 填写搜索框
opencli browser fill --role textbox --name "搜索邮件" "from:boss@company.com" --tab "$TAB_ID"
# 英文回退: --name "Search mail"

# 发送回车键
opencli browser keys Enter --tab "$TAB_ID"
```

## 脚本封装（推荐）

为避免手写冗长的命令，使用 `scripts/` 目录下的封装脚本：

```bash
# 先打开 Gmail 获取 tab_id
TAB_ID=$(opencli browser open "https://mail.google.com" | jq -r '.page')

# 写信（不发送）
bash scripts/gmail-compose.sh "$TAB_ID" "recipient@example.com" "主题" "正文"

# 发送
bash scripts/gmail-send.sh "$TAB_ID"

# 搜索
bash scripts/gmail-search.sh "$TAB_ID" "from:boss@company.com"

# 截图
bash scripts/screenshot.sh "$TAB_ID" -o ~/Desktop/gmail.png
```

脚本也支持不传 `tab_id`，自动打开 Gmail：

```bash
# 自动打开 Gmail
bash scripts/gmail-compose.sh "recipient@example.com" "主题" "正文"
```

详见各脚本的使用说明。

## 限制与注意事项

1. **网络依赖**：Gmail 网页加载速度影响操作成功率
2. **动态内容**：Gmail 大量使用 JS 动态渲染，元素出现可能有延迟（脚本内置重试）
3. **多语言**：Gmail 界面语言（中文/英文）会影响元素的 `name` 属性，脚本已做中英文兼容
4. **弹窗干扰**：Gmail 偶尔会弹出"启用桌面通知"等弹窗，需要先处理
5. **并发安全**：同一 tab 内不要并行执行多个操作

## 故障排查

| 症状 | 可能原因 | 解决方法 |
|------|---------|---------|
| fill 失败 | 页面未完全加载 | 脚本内置 3 次重试，如仍失败等待 2-3 秒再试 |
| click 无反应 | 元素被弹窗遮挡 | `browser state` 查找"关闭"或"不用了"按钮先关闭弹窗 |
| 搜索不触发 | 搜索框未获得焦点 | `browser fill` 会自动聚焦，如失败先 click 再 fill |
| "邮件已发送"提示不出现 | 已发送到草稿箱 | 检查是否缺少收件人 |
| opencli doctor 失败 | daemon 未启动或扩展未连接 | `opencli daemon restart` 或检查 Chrome 扩展 |

## 相关文档

- `references/gmail-patterns.md` — 元素识别模式详细参考
- `references/page-states.md` — 页面状态判断指南
- `references/troubleshooting.md` — 深度故障排查
- `examples/` — 使用示例
