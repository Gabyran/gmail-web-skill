# Gmail 网页版元素识别模式

> 本文档记录 Gmail 网页版（mail.google.com）在 accessibility tree 中的元素特征。
> 所有模式基于实际测试，适用于中文和英文界面。
>
> ⚠️ 重要：不要硬编码 `@e` 引用编号。每次操作前重新 snapshot，按以下模式匹配。

## 全局导航元素

### 写邮件按钮
- **中文**: `role="button"`, `name="写邮件"`
- **英文**: `role="button"`, `name="Compose"`
- **位置**: 页面左上角，Gmail logo 下方

### 搜索框
- **中文**: `role="textbox"`, `name="搜索邮件"`
- **英文**: `role="textbox"`, `name="Search mail"`
- **位置**: 页面顶部中央

### 导航链接
| 中文名称 | 英文名称 | role |
|---------|---------|------|
| 收件箱 | Inbox | link |
| 已加星标 | Starred | link |
| 已延后 | Snoozed | link |
| 已发邮件 | Sent | link |
| 草稿 | Drafts | link |
| 更多 | More | button |

## 写信窗口元素

### 窗口标题
- **中文**: `name="新邮件"` 或包含 "新邮件"
- **英文**: `name="New message"`

### 收件人输入框
- **中文**: `role="combobox"`, `name="发送至收件人"` 或 `name="收件人"`
- **英文**: `role="combobox"`, `name="To recipients"` 或 `name="To"`
- **特征**: 唯一一个 `combobox` role 的输入框

### 抄送/密送
- **添加抄送**: `link`, `name="添加抄送收件人"` / `"Add Cc recipients"`
- **添加密送**: `link`, `name="添加密送收件人"` / `"Add Bcc recipients"`

### 主题输入框
- **中文**: `role="textbox"`, `name="主题"`
- **英文**: `role="textbox"`, `name="Subject"`
- **特征**: 在收件人下方，只有一个 `textbox` 且 name 为 "Subject"

### 正文编辑区
- **中文**: `role="textbox"`, `name="邮件正文"`
- **英文**: `role="textbox"`, `name="Message body"`
- **特征**: 最大的文本输入区域，通常位于写信窗口下半部分

### 发送按钮
- **中文**: `role="button"`, `name="发送"` 或包含 "发送"
- **英文**: `role="button"`, `name="Send"`
- **位置**: 写信窗口底部工具栏左侧，蓝色按钮

### 其他写信工具栏按钮
| 功能 | 中文 | 英文 | role |
|------|------|------|------|
| 格式化选项 | 格式选项 | Formatting options | button |
| 附件 | 附件 | Attach files | button |
| 插入链接 | 插入链接 | Insert link | button |
| 表情 | 表情符号 | Insert emoji | button |
| 删除草稿 | 舍弃 | Discard draft | button |

## 邮件列表页元素

### 邮件条目
每封邮件通常由以下元素组成：
- `checkbox` — 选择框
- `link` — 邮件主体，name 包含发件人、主题、摘要、时间
- 未读邮件的 name 通常以 `未读，` / `"Unread, "` 开头

### 示例邮件条目 name
```
未读， Google , 安全提醒 , 10:59 , 在 Mac 设备上有新的登录活动...
Unread, Google, Security alert, 10:59, New sign-in on Mac device...
```

## 邮件详情页元素

### 回复按钮
- **中文**: `role="button"`, `name="回复"`
- **英文**: `role="button"`, `name="Reply"`

### 回复全部
- **中文**: `role="button"`, `name="回复所有人"`
- **英文**: `role="button"`, `name="Reply all"`

### 转发
- **中文**: `role="button"`, `name="转发"`
- **英文**: `role="button"`, `name="Forward"`

### 更多操作
- **中文**: `role="button"`, `name="更多"`
- **英文**: `role="button"`, `name="More"`

## 弹窗/干扰元素

### 桌面通知弹窗
- **确定**: `link`, `name="确定"` / `"OK"`
- **不用了**: `link`, `name="不用了"` / `"No thanks"`
- **关闭**: `button`, `name="关闭"` / `"Close"`

### 处理策略
遇到弹窗时，先 snapshot 查找弹窗元素，优先点击"不用了"/"No thanks"关闭，再继续主流程。

## 匹配优先级

当多个元素可能匹配时，按以下优先级：

1. **精确匹配** name 等于目标文本
2. **包含匹配** name 包含目标文本
3. **role 过滤** 先用 role 缩小范围，再在结果中匹配 name
4. **位置推断** 结合页面布局，选择最可能的元素
