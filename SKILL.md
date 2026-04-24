---
name: gmail-web-skill
description: |
  控制 Gmail 网页版（mail.google.com）进行邮件操作。支持写信、发送、搜索、归档、标签、星标、回复等常见操作。基于 Kimi WebBridge 协议，复用用户的 Gmail 登录态。
  
  ⚠️ 注意：这是 **Gmail 网页版**（Web UI）操作，不是 Gmail API。所有操作通过浏览器 accessibility tree 完成，不需要 API Key。
  
  使用时机：用户需要写邮件、发邮件、搜索邮件、管理收件箱、查看邮件等与 Gmail 相关的任务。
---

# Gmail Web Skill

通过浏览器控制 Gmail 网页版，复用用户的登录态完成邮件操作。

## 依赖

- Kimi WebBridge daemon 运行在 `http://127.0.0.1:10086`
- Chrome/Edge 浏览器已安装 Kimi WebBridge 扩展
- 用户在浏览器中已登录 Gmail

## 核心原则

1. **不缓存元素引用**：`@e1`, `@e2` 等引用在每次 snapshot 后都会重新分配。永远按 `{role, name}` 模式匹配元素。
2. **先 snapshot 再操作**：任何 click/fill 之前必须先 snapshot 获取最新元素树。
3. **操作后验证**：关键操作（发送、删除）后再次 snapshot 确认页面状态变化。
4. **session 隔离**：每个 Gmail 任务使用独立的 session，避免与其他网页操作冲突。

## 工具调用方式

所有操作通过 curl 调用 Kimi WebBridge daemon：

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "navigate",
    "args": {"url": "...", "newTab": true},
    "session": "gmail-task"
  }'
```

## 标准工作流程

```
1. navigate (newTab:true) → 打开 Gmail
2. snapshot               → 判断当前页面状态
3. click/fill             → 执行目标操作
4. snapshot               → 验证结果
5. screenshot（如需）     → 可视化确认
```

## 页面状态判断

Gmail 网页版主要有以下几种页面状态：

| 状态 | 特征元素 | 判断方法 |
|------|---------|---------|
| **收件箱** | "写邮件"按钮 + "收件箱"链接 | snapshot 中有 `button "写邮件"` 和 `link "收件箱"` |
| **写信窗口** | "新邮件"标题 + "发送至收件人" | snapshot 中有 `combobox "发送至收件人"` |
| **邮件详情页** | "回复"按钮 + 邮件正文 | snapshot 中有 `button "回复"` |
| **搜索页** | 搜索框 + 搜索结果 | URL 包含 `search/` |

## 常用操作

### 打开 Gmail

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"navigate","args":{"url":"https://mail.google.com","newTab":true},"session":"gmail-task"}'
```

### 点击"写邮件"

```bash
# 先 snapshot 获取元素引用
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"snapshot","session":"gmail-task"}'

# 从 snapshot 中找到 button "写邮件" 的 @e 引用，然后点击
# 示例（实际引用需从 snapshot 结果中提取）:
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"click","args":{"selector":"@e15"},"session":"gmail-task"}'
```

### 填写邮件

写信窗口弹出后，snapshot 中的典型元素：

| 字段 | role | name 特征 | 示例引用 |
|------|------|----------|---------|
| 收件人 | `combobox` | 包含"发送至收件人" | `@e195` |
| 主题 | `textbox` | 包含"主题" | `@e198` |
| 正文 | `textbox` | 包含"邮件正文" | `@e199` |
| 发送 | `button` | 包含"发送" | `@e214` |

```bash
# 填写收件人
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e195","value":"recipient@example.com"},"session":"gmail-task"}'

# 填写主题
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e198","value":"邮件主题"},"session":"gmail-task"}'

# 填写正文
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e199","value":"邮件正文内容"},"session":"gmail-task"}'
```

### 发送邮件

```bash
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"click","args":{"selector":"@e214"},"session":"gmail-task"}'
```

发送后 snapshot 验证：页面应回到收件箱状态，"邮件已发送"提示可能出现。

### 搜索邮件

```bash
# 点击搜索框，输入关键词，回车
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"fill","args":{"selector":"@e5","value":"搜索关键词"},"session":"gmail-task"}'

# 发送回车键
curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"evaluate","args":{"code":"document.querySelector(\"[role=\\\"searchbox\\\"]\").dispatchEvent(new KeyboardEvent(\"keydown\",{key:\"Enter\",keyCode:13,bubbles:true}))"},"session":"gmail-task"}'
```

## 脚本封装（推荐）

为避免手写冗长的 curl 命令，使用 scripts/ 目录下的封装脚本：

```bash
# 写信并发送
bash scripts/gmail-compose.sh gmail-task "recipient@example.com" "主题" "正文"

# 搜索邮件
bash scripts/gmail-search.sh gmail-task "关键词"

# 截图当前页面
bash scripts/screenshot.sh -s gmail-task
```

详见各脚本的使用说明。

## 限制与注意事项

1. **网络依赖**：Gmail 网页加载速度影响操作成功率
2. **动态内容**：Gmail 大量使用 JS 动态渲染，元素出现可能有延迟
3. **多语言**：Gmail 界面语言（中文/英文）会影响元素的 `name` 属性，脚本已做中英文兼容
4. **弹窗干扰**：Gmail 偶尔会弹出"启用桌面通知"等弹窗，需要先处理
5. **并发安全**：同一 session 内不要并行执行多个操作

## 故障排查

| 症状 | 可能原因 | 解决方法 |
|------|---------|---------|
| snapshot 找不到元素 | 页面未完全加载 | 等待 2-3 秒后重试 snapshot |
| 点击无反应 | 元素被弹窗遮挡 | snapshot 查找"关闭"或"不用了"按钮先关闭弹窗 |
| fill 后内容没显示 | 输入框未获得焦点 | 先 click 再 fill |
| 发送后还在写信窗口 | 网络延迟 | 等待 3-5 秒再 snapshot |
| "邮件已发送"提示不出现 | 已发送到草稿箱 | 检查是否缺少收件人 |

## 相关文档

- `references/gmail-patterns.md` — 元素识别模式详细参考
- `references/page-states.md` — 页面状态判断指南
- `references/troubleshooting.md` — 深度故障排查
- `examples/` — 使用示例
