# AppleScript 模式与陷阱（macOS Mail.app）

本文是 macos-mail skill 的脚本库和坑位详解。按「环境探测 → 查询 → 写操作 → 验证」组织，末尾解释**为什么**有这些坑——理解了 why 就能举一反三，不用死记模板。

## 目录
1. [环境探测](#1-环境探测)
2. [只读查询](#2-只读查询安全无副作用)
3. [删除](#3-删除--废纸篓)
4. [归档 move](#4-归档move-到文件夹)
5. [标记已读 / 未读](#5-标记已读--未读)
6. [验证](#6-验证)
7. [为什么有这些坑](#7-为什么有这些坑)

---

## 1. 环境探测

**首次在某个 Mail.app 上操作前**先跑，搞清楚有哪些账户、每个账户有哪些 mailbox、目标 id 实际在哪个 mailbox。避免在错误账户/路径上操作。

### 列出所有账户及其 mailbox

```applescript
tell application "Mail"
    set out to ""
    repeat with acct in (accounts)
        try
            set out to out & "=== Account: " & (name of acct) & " ===" & linefeed
            repeat with mb in (mailboxes of acct)
                try
                    set out to out & "  - " & (name of mb) & linefeed
                end try
            end repeat
        end try
    end repeat
    return out
end tell
```

### 找某个 id 究竟在哪个账户/mailbox

诊断"为什么 delete 报成功却没删掉"——确认你操作的 mailbox 和邮件实际所在 mailbox 一致。

```applescript
tell application "Mail"
    set targetId to 21111
    set out to ""
    repeat with acct in (accounts)
        try
            repeat with mb in (mailboxes of acct)
                try
                    set t to first message of mb whose id is targetId
                    set out to out & "id " & targetId & " 在 account=" & (name of acct) & " / mailbox=" & (name of mb) & linefeed
                end try
            end repeat
        end try
    end repeat
    if out is "" then set out to "未找到 id=" & targetId
    return out
end tell
```

### 探测 mailbox 层级（子文件夹）

Exchange 账户常把自定义目录放在子层。列出顶层 + 一层子 mailbox：

```applescript
tell application "Mail"
    set out to ""
    repeat with mb in (mailboxes of account "<Exchange>")
        try
            set out to out & "[top] " & (name of mb) & linefeed
            try
                repeat with smb in (mailboxes of mb)
                    try
                        set out to out & "   └─ " & (name of smb) & linefeed
                    end try
                end repeat
            end try
        end try
    end repeat
    return out
end tell
```

---

## 2. 只读查询（安全，无副作用）

### 列出 inbox 全部邮件（含 id / 账户 / 已读状态）

```applescript
tell application "Mail"
    set out to ""
    set counter to 0
    repeat with m in (messages of inbox)
        set counter to counter + 1
        try
            set subj to subject of m
            set sndr to sender of m
            set acct to name of account of mailbox of m
            set mid to id of m
            set rs to read status of m
            set out to out & counter & ". " & subj & linefeed & "    " & sndr & "  [" & acct & " | id=" & mid & " | read=" & rs & "]" & linefeed
        end try
    end repeat
    return "inbox 共 " & counter & " 封：" & linefeed & out
end tell
```

### 按发件人/主题/未读筛选

循环里加条件即可。例如所有未读的、来自某域名的：

```applescript
tell application "Mail"
    set out to ""
    repeat with m in (messages of inbox)
        try
            set sndr to sender of m
            set rs to read status of m
            if sndr contains "linkedin.com" and rs is false then
                set out to out & (subject of m) & " | id=" & (id of m) & linefeed
            end if
        end try
    end repeat
    return out
end tell
```

---

## 3. 删除（→ 废纸篓）

### 通用稳妥模板（自动适配账户）

先从聚合 inbox 只读收集每封目标的 `(account, mailbox, id)`，再用各自 account mailbox 路径按 id 定位删除。能同时处理 Exchange（聚合 delete 失败）和 Gmail（All Mail 引用问题），因为最终都落到 `account mailbox + id`。

```applescript
tell application "Mail"
    set targetIds to {21185, 21101, 21075}  -- 替换为真实查询到的 id

    -- 第一遍：收集每封目标的 account/mailbox/id（只读）
    set acctList to {}
    set mbList to {}
    set idList to {}
    repeat with m in (messages of inbox)
        try
            set mid to id of m
            if targetIds contains mid then
                set end of idList to mid
                set end of mbList to (name of mailbox of m)
                set end of acctList to (name of account of mailbox of m)
            end if
        end try
    end repeat

    -- 第二遍：用 account mailbox 路径按 id 删除
    set delCount to 0
    repeat with i from 1 to (count of idList)
        set acctName to item i of acctList
        set mbName to item i of mbList
        set mid to item i of idList
        -- Gmail 聚合 inbox 返回 "All Mail"，构造路径会失败，改用 INBOX
        if mbName is "All Mail" then set mbName to "INBOX"
        try
            set mb to mailbox mbName of account acctName
            set t to first message of mb whose id is mid
            delete t
            set delCount to delCount + 1
        end try
    end repeat

    return "删除 " & delCount & " / " & (count of idList) & " 封"
end tell
```

### 单封删除（已知账户和 id）

```applescript
tell application "Mail"
    set mb to mailbox "Inbox" of account "<Exchange>"   -- Exchange 用 "Inbox"；Gmail 用 "INBOX"
    set t to first message of mb whose id is 21083
    delete t
end tell
```

---

## 4. 归档（move 到文件夹）

> ⚠️ **Exchange move 后 id 会变**：Exchange 账户 `move` 到另一 mailbox 后，邮件 id 会被重新分配（实测一封邮件连搬两次，id 连变）。连续 move 同一封时，每段 move 后要在目标 mailbox 按 sender/subject 重新查出 id，不能复用旧 id（会 -1728 not found）。详见第 7 节。

### 目标是 Exchange 自定义文件夹 → 用对象引用

按名字 `mailbox "Investments" of account "<Exchange>"` 会报 "Can't get mailbox"（即使它是顶层 mailbox）。遍历 `mailboxes of account` 匹配名字，拿对象引用再 move：

```applescript
tell application "Mail"
    -- 1. 找到目标文件夹的 mailbox 对象引用
    set dstMb to missing value
    repeat with mb in (mailboxes of account "<Exchange>")
        try
            if (name of mb) is "Investments" then
                set dstMb to mb
                exit repeat
            end if
        end try
    end repeat

    if dstMb is missing value then return "未找到目标文件夹"

    -- 2. 从源 inbox 按 id 取邮件，move 过去
    set src to mailbox "Inbox" of account "<Exchange>"
    set t to first message of src whose id is 21104
    move t to dstMb
end tell
```

### 目标是默认/普通文件夹（按名字可取）

```applescript
tell application "Mail"
    set src to mailbox "Inbox" of account "<Exchange>"
    set dst to mailbox "Archive" of account "<Exchange>"
    set t to first message of src whose id is 21114
    move t to dst
end tell
```

---

## 5. 标记已读 / 未读

改 `read status`。就地修改，不像 delete/move 有静默失败问题，但仍用 account mailbox + id 稳妥。

### 单封

```applescript
tell application "Mail"
    set mb to mailbox "Inbox" of account "<Exchange>"
    set t to first message of mb whose id is 21115
    set read status of t to true   -- true=已读, false=未读
end tell
```

### 批量：把某账户 inbox 所有未读标记已读

```applescript
tell application "Mail"
    set mb to mailbox "Inbox" of account "<Exchange>"
    set n to 0
    repeat with m in (messages of mb)
        try
            if (read status of m) is false then
                set read status of m to true
                set n to n + 1
            end if
        end try
    end repeat
    return "标记 " & n & " 封已读"
end tell
```

---

## 6. 验证

每次写操作后跑这个，确认目标 id 已离开 inbox、总数符合预期：

```applescript
tell application "Mail"
    set targetIds to {21083, 21111, 21114}
    set leftover to 0
    repeat with m in (messages of inbox)
        try
            if targetIds contains (id of m) then set leftover to leftover + 1
        end try
    end repeat
    return "目标残留 " & leftover & " / " & (count of targetIds) & "，inbox 现在共 " & (count of (messages of inbox)) & " 封"
end tell
```

---

## 7. 为什么有这些坑

### 为什么 Exchange 的聚合 inbox delete 会静默失败

聚合 `inbox` 是 Mail.app 把所有账户的新邮件拼出来的**虚拟视图**。对其中一封 Exchange 邮件调 `delete`，命令落在一个虚拟引用上，Exchange 后端不认，但 AppleScript 层不报错——查 `deleted status` 回来还是 false。落到具体 `mailbox "Inbox" of account "X"` 上，引用是实打实的 Exchange 文件夹引用，delete 才生效。

**判断方法**：删完后查 `deleted status`；一直 false 就是踩了这个坑，改走 account mailbox。

### 为什么 Gmail 的 mailbox of m 返回 "All Mail"

Gmail 用 IMAP 的 `[Gmail]/All Mail` 存所有邮件副本，INBOX 只是个标签视图。Mail.app 的聚合 inbox 把 Gmail 邮件的 `mailbox of m` 解析成了 All Mail；但用 `"All Mail"` 这个显示名去 `mailbox "All Mail" of account` 又构造不出来（内部路径是 `[Gmail]/All Mail`）。解法是别信那个返回值，直接用 `INBOX`（Gmail inbox 的标准名字，**大写**）。

### 为什么 message 对象引用会失效

Mail.app 的 AppleScript 是**异步**的——`delete`/`move` 触发后，后台才真正搬邮件。这期间你之前抓到的 message 列表（按位置索引）已经和现实对不上，再拿 `item 2 of messages` 就可能 "Can't get item 2"。所以**先收集 id，再每次用 id 重新查询定位**。同一 mailbox 内 id 跨查询稳定；但 Exchange move 到别的 mailbox 后 id 会被重新分配（见下节），连续 move 时每段都要重新查。

### 为什么自定义文件夹按名字取不到

Mail.app 对 Exchange 账户的**自定义文件夹**（用户自建，非系统默认）有个 AppleScript 引用 bug：`mailbox "<name>" of account` 这种按显示名解析的路径对它们无效，报 "Can't get mailbox"；但对默认 mailbox（Inbox/Sent/Archive 等）有效。Workaround 是枚举 `mailboxes of account` 拿对象引用——对象引用不依赖名字解析。

### 为什么 Exchange move 后 id 会变（id 不是全局稳定）

上一节说"id 稳定"指的是**同一 mailbox 内、跨多次只读查询** id 不变——这点成立，可以放心用 id 做"在同一文件夹内重新定位"。但 **Exchange 账户每次 `move` 到另一个 mailbox 后，邮件的 `id` 会被重新分配**。实测一封邮件连搬两次：`inbox`(id=40112) → 文件夹A 变 40118 → 文件夹B 再变 40119。

后果：**连续 move 同一封邮件时，每段 move 后必须重新只读查询拿新 id**，不能拿 move 前的旧 id 去 `first message whose id is X`（会 -1728 not found）。这跟"message 对象引用失效"是两回事——对象引用失效靠 id 兜底，而这里 id 本身在 Exchange 跨文件夹不通用。Gmail 账户是否也如此未验证，谨慎起见同样处理。

**怎么拿 move 后的新 id**：在目标 mailbox 里按 **sender / subject** 筛选定位（id 不可预测，但 sender/subject 不变），读出当前 id 再做下一步：

```applescript
tell application "Mail"
    -- move 后在目标 mailbox 按 sender 找回这封，拿新 id
    set newId to missing value
    repeat with m in (messages of mailbox "<目标文件夹>" of account "<Exchange>")
        try
            if (sender of m) contains "<发件人关键词>" then
                set newId to id of m
                exit repeat
            end if
        end try
    end repeat
    return newId
end tell
```
