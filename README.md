# Gmail Web Skill

> 通过浏览器控制 Gmail 网页版，复用用户的登录态完成邮件操作。
>
> ⚠️ **这是 Gmail 网页版（Web UI）自动化，不是 Gmail API。** 不需要 API Key，直接使用浏览器中的登录状态。

## 特性

- 写信、发送、搜索、归档、星标、回复 — 覆盖常用邮件操作
- 复用浏览器登录态，无需配置 OAuth/API Key
- 基于 [Kimi WebBridge](https://www.kimi.com/features/webbridge) 协议，支持 accessibility tree 元素定位
- 中英文 Gmail 界面兼容
- 脚本封装，一行命令完成复杂操作

## 快速开始

### 前置条件

1. 安装 [Kimi WebBridge](https://www.kimi.com/features/webbridge)（Standalone 模式）
2. Chrome/Edge 浏览器中已登录 Gmail
3. `curl`, `jq` 已安装

```bash
# 安装 Kimi WebBridge Standalone
curl -fsSL https://kimi-web-img.moonshot.cn/webbridge/install.sh | bash

# 启动 daemon
~/.kimi-webbridge/bin/kimi-webbridge start

# 验证状态
~/.kimi-webbridge/bin/kimi-webbridge status
```

### 安装本 Skill

```bash
git clone https://github.com/yourusername/gmail-web-skill.git
cd gmail-web-skill
```

### 使用示例

```bash
# 写一封邮件
bash scripts/gmail-compose.sh gmail-task "friend@example.com" "Hello" "How are you?"

# 发送
bash scripts/gmail-send.sh gmail-task

# 搜索邮件
bash scripts/gmail-search.sh gmail-task "from:boss@company.com"

# 截图当前页面
bash scripts/screenshot.sh -s gmail-task -o ~/Desktop/gmail.png
```

## 项目结构

```
gmail-web-skill/
├── SKILL.md                    # AI Agent 使用手册（工作流 + 命令参考）
├── README.md                   # 本项目介绍
├── LICENSE                     # MIT License
├── CONTRIBUTING.md             # 贡献指南
├── scripts/
│   ├── gmail-compose.sh        # 写信
│   ├── gmail-send.sh           # 发送
│   ├── gmail-search.sh         # 搜索
│   ├── gmail-archive.sh        # 归档
│   ├── gmail-open-mail.sh      # 打开邮件
│   └── screenshot.sh           # 截图
├── references/
│   ├── gmail-patterns.md       # 元素识别模式（中英文）
│   ├── page-states.md          # 页面状态判断指南
│   └── troubleshooting.md      # 故障排查
└── examples/
    └── compose-and-send.md     # 完整写信示例
```

## 核心设计原则

1. **不缓存元素引用** — `@e1`, `@e2` 在每次 snapshot 后都会重新分配。永远按 `{role, name}` 模式匹配。
2. **先 snapshot 再操作** — 任何 click/fill 之前必须先获取最新元素树。
3. **操作后验证** — 关键操作后再次 snapshot 确认页面状态变化。
4. **session 隔离** — 每个 Gmail 任务使用独立的 session。

## 支持的 Gmail 界面语言

- 中文（简体）
- English

其他语言的 Gmail 界面可能需要扩展 `scripts/` 中的匹配逻辑。

## 限制

- 仅支持 Gmail 网页版（mail.google.com）
- 依赖网络加载速度
- Gmail 的 A/B 测试可能导致 UI 变化
- 无法处理 CAPTCHA 或二次验证（需用户手动介入）
- 大型附件上传可能超时

## 同类项目对比

| 项目 | 方式 | 需要 API Key | 复用登录态 | 适用场景 |
|------|------|:-----------:|:---------:|---------|
| **Gmail Web Skill** | 浏览器自动化 | ❌ | ✅ | 个人日常邮件操作 |
| Gmail API | REST API | ✅ | ❌ | 程序化批量处理 |
| browser-use | Playwright | ❌ | ✅ | 通用浏览器自动化 |
| Stagehand | AI+Playwright | ❌ | ✅ | 复杂网页任务 |

## 贡献

欢迎提交 Issue 和 PR！详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

MIT License — 详见 [LICENSE](LICENSE)。
