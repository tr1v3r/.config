# macOS Mail.app 可复用 AppleScripts

四个只依赖 `osascript` 的通用脚本，配套 `macos-mail` skill。**不含任何账户名 / 邮箱 / 真实 id** —— 账户与 mailbox 在运行时动态枚举，targetIds 走命令行参数或占位列表。

## 脚本

| 脚本 | 作用 | 副作用 |
|---|---|---|
| `inbox-overview.applescript` | 列出各账户 inbox 规模 + 聚合 inbox 全部邮件元数据（账户/发件/主题/id/已读/时间） | 无（只读） |
| `mark-read.applescript` | 按 id 批量标记已读 | 改 `read status`，可逆 |
| `delete-messages.applescript` | 按 id 批量删除（→ 各账户废纸篓） | 移到废纸篓，可恢复；Gmail Trash 30 天后自动清空 |
| `archive-messages.applescript` | 按 id 归档到指定文件夹（自动按邮件所在账户查同名文件夹，Exchange 自定义文件夹走对象引用） | move 到文件夹，可找回 |

## 用法

```bash
# 1. 先看 inbox，拿到要操作的 id
osascript inbox-overview.applescript

# 2a. 标记已读（命令行传 id，推荐；下方为示例占位 id）
osascript mark-read.applescript 11111 22222

# 2b. 删除（命令行传 id，推荐；下方为示例占位 id）
osascript delete-messages.applescript 11111 22222

# 2c. 归档（用法 A：第一个参数=文件夹名，其余=id；文件夹名含空格用引号）
osascript archive-messages.applescript "Bank Statements" 11111 22222
osascript archive-messages.applescript Notifications 11111 22222 33333
#    用法 B：不传参，编辑脚本内 mapping 占位表，一次归多封到不同文件夹

# mark-read / delete 不传参时，编辑脚本顶部的 targetIds 占位列表后直接运行
```

## 为什么这样写（避坑要点）

- **id 是稳定锚点**：message 对象引用会在异步删除/移动后失效，所有写操作都先收集 id、再用 id 在 account mailbox 上重新定位。
- **聚合 inbox 只用于只读查询**：对 Exchange 邮件在聚合 inbox 上 `delete` 会静默失败（`deleted status` 不变、不报错），写操作必须落到 `mailbox "Inbox" of account "<Exchange>"`。
- **Gmail 用大写 `INBOX`**：聚合 inbox 把 Gmail 邮件的 `mailbox of m` 报成 `"All Mail"`，按它构造路径会失败，脚本里检测到 `"All Mail"` 自动改用 `"INBOX"`。

详见上级 `../references/applescript-patterns.md`。
