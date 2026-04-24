# Contributing to Gmail Web Skill

感谢你的贡献！以下是参与指南。

## 如何贡献

### 报告 Bug

1. 检查 [Issues](https://github.com/yourusername/gmail-web-skill/issues) 是否已存在相同问题
2. 提供以下信息：
   - Gmail 界面语言（中文/英文）
   - 执行的命令
   - 错误输出
   - 截图（如可能）
   - snapshot JSON（脱敏后）

### 提交功能请求

在 Issue 中描述：
- 使用场景
- 期望的行为
- 可能的实现方案

### 提交代码

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 提交更改：`git commit -m "Add: xxx"`
4. 推送分支：`git push origin feature/your-feature`
5. 创建 Pull Request

## 代码规范

### Bash 脚本

- 使用 `set -euo pipefail`
- 函数名使用小写下划线：`find_ref`, `wb_cmd`
- 变量名大写：`DAEMON_URL`, `SESSION`
- 添加中文注释说明用途

### 文档

- SKILL.md：给 AI 看的操作手册，保持简洁
- README.md：给人看的项目介绍
- references/：详细技术参考

## 测试

在提交 PR 前，请确保：

1. 脚本在 macOS 和 Linux 上都能运行
2. 中英文 Gmail 界面都能正常工作
3. 所有新功能都有对应的文档更新

## 开发路线图

- [ ] 支持更多 Gmail 操作（转发、草稿管理、标签过滤）
- [ ] 支持更多语言界面（日语、韩语等）
- [ ] 添加 Python SDK 封装
- [ ] 支持多账号切换
- [ ] 集成到 Claude Code / Cursor 插件市场

## 联系

如有问题，请在 GitHub Issues 中讨论。
