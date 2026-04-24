# Gmail 页面状态判断指南

> 判断当前 Gmail 处于哪种页面状态，决定下一步操作。

## 状态检测方法

通过 snapshot 返回的 accessibility tree，检查特定特征元素的存在与否。

## 状态列表

### 状态 1: 未登录 / 登录页

**特征**:
- URL: `https://accounts.google.com/...`
- snapshot 中有 `heading "登录"` / `"Sign in"`
- 有 email/password 输入框

**处理**:
```bash
# 告知用户需要手动登录，或提供 credentials 进行自动填充
# Gmail 登录有反自动化检测，建议用户先手动登录一次
```

---

### 状态 2: 收件箱（主界面）

**特征**:
- URL: `https://mail.google.com/mail/u/0/#inbox`
- snapshot 中有 `button "写邮件"` / `"Compose"`
- snapshot 中有 `link "收件箱"` / `"Inbox"`
- 邮件列表可见（多个 `checkbox` + `link` 组合）

**可执行操作**:
- 写邮件（点击"写邮件"）
- 搜索邮件
- 打开邮件（点击邮件条目）
- 选择并归档/删除邮件

---

### 状态 3: 写信窗口弹出

**特征**:
- snapshot 中有 `combobox "发送至收件人"` / `"To recipients"`
- snapshot 中有 `textbox "主题"` / `"Subject"`
- 右下角或页面中央出现写信面板

**可执行操作**:
- 填写收件人、主题、正文
- 添加附件
- 发送邮件
- 保存草稿
- 关闭/舍弃草稿

---

### 状态 4: 邮件详情页

**特征**:
- URL: `https://mail.google.com/mail/u/0/#inbox/...`（包含邮件 ID）
- snapshot 中有 `button "回复"` / `"Reply"`
- 邮件正文以 `StaticText` 或段落形式展示

**可执行操作**:
- 回复
- 回复全部
- 转发
- 归档
- 删除
- 标记为已读/未读
- 添加星标

---

### 状态 5: 搜索结果页

**特征**:
- URL: 包含 `search/`
- 页面顶部显示搜索关键词
- 结果以邮件列表形式展示

**可执行操作**:
- 打开搜索结果中的邮件
- 修改搜索条件
- 返回收件箱

---

### 状态 6: 标签/文件夹页

**特征**:
- URL: 包含 `label/` 或 `#sent`, `#drafts`, `#spam` 等
- 类似于收件箱，但显示的是筛选后的邮件

---

### 状态 7: 设置页

**特征**:
- URL: `https://mail.google.com/mail/u/0/#settings/...`
- 通常不应在此状态下执行邮件操作

---

## 状态判断代码示例

```bash
# 获取当前状态
snapshot=$(curl -s -X POST http://127.0.0.1:10086/command \
  -H 'Content-Type: application/json' \
  -d '{"action":"snapshot","session":"gmail-task"}' | jq '.data // .')

# 判断是否在写信窗口
if echo "$snapshot" | jq -e '.. | objects? | select(.role == "combobox" and (.name | contains("收件人") or contains("To")))' >/dev/null 2>&1; then
  echo "State: COMPOSE"
fi

# 判断是否在收件箱
if echo "$snapshot" | jq -e '.. | objects? | select(.role == "button" and (.name | contains("写邮件") or contains("Compose")))' >/dev/null 2>&1; then
  echo "State: INBOX"
fi

# 判断是否在邮件详情页
if echo "$snapshot" | jq -e '.. | objects? | select(.role == "button" and (.name | contains("回复") or contains("Reply")))' >/dev/null 2>&1; then
  echo "State: MAIL_DETAIL"
fi
```

## 状态流转图

```
                    +-----------+
                    |  登录页   |
                    +-----+-----+
                          | 手动登录
                          v
+--------+    点击邮件    +-----------+   点击"写邮件"   +-----------+
| 详情页 | <------------- |  收件箱   | ---------------> | 写信窗口  |
+---+----+                +-----+-----+                  +-----+-----+
    |                           ^                              |
    | 点击"回复"                | 发送成功/关闭                 | 发送
    v                           |                              v
+---+----+                      +------------------------+     +-----------+
| 写信窗口|                                               +---> |  收件箱   |
+--------+                                                      +-----------+
```
