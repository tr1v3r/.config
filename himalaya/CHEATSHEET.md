# Himalaya 日常命令备忘（Gmail）

配合 [`GMAIL_OAUTH_SETUP.md`](./GMAIL_OAUTH_SETUP.md) 使用。后者讲怎么把账号配通；本文只记配通之后每天会用的命令，以及本次实测踩到的坑。

- 账号：默认 `gmail`（acrux.hu@gmail.com），省略 `--account` 即用它。
- backend：账号同时配了 `gmail`（REST API，收信/管理）和 `smtp`（发信）。通用命令默认走 gmail backend。
- 邮件 ID：`himalaya envelope list` 列出的 `ID`（如 `19f180666956b4ea`）就是 Gmail 的 message id（十六进制），可直接喂给 `gmail messages ...` 原生命令。

## 常用操作

```bash
# 列出 INBOX
himalaya envelope list

# 读正文（按 ID）
himalaya message read 19f180666956b4ea

# 标为已读 / 加星
himalaya flag add --flag seen  19f180666956b4ea
himalaya flag add --flag flagged 19f180666956b4ea   # 加星

# 归档 = 移除 INBOX 标签（邮件仍在 [Gmail]/All Mail，未删除）
himalaya gmail messages modify 19f180666956b4ea --remove-label INBOX

# 删到垃圾箱 / 永久删除
himalaya gmail messages trash  19f180666956b4ea
himalaya gmail messages delete 19f180666956b4ea   # 不可恢复
```

`flag add` 可用值：`seen`（已读）、`answered`（已回复）、`flagged`（加星）、`draft`。

## 查其它文件夹 / 账号

```bash
# 列出所有 mailbox（看 Gmail 标签对应的文件夹名）
himalaya mailbox list

# 指定 mailbox（别名见 config.toml 的 [mailbox.alias]，不区分大小写）
himalaya envelope list -m "[Gmail]/Sent Mail"
himalaya envelope list -m "[Gmail]/All Mail"     # 归档邮件在这里
himalaya envelope list -m "[Gmail]/Trash"

# 切到 gmx 账号
himalaya -a gmx envelope list
```

## 发信

```bash
# 用内置 composer 写并发送（走 SMTP）
himalaya message compose --send
himalaya message reply   19f180666956b4ea   # 回复
himalaya message forward 19f180666956b4ea   # 转发
```

## 坑：首次连接 authorization timeout

**现象**：`himalaya ...` 偶发报 `error initializing client: authorization timeout` 或 ortie 的 `unexpected end of file`。

**根因**：`ortie` 刷新 access token 时要从 1Password CLI 取 `client_secret`，而 `op` 未保持登录（`op whoami` 显示 not signed in），每次调用都走 Touch ID 解锁，耗时 10–15s，超过 himalaya 的鉴权超时。

**临时绕过**：先手动把 op/ortie 预热一遍，token 写进 keychain 后，紧跟着的 himalaya 命令就不再触发 op：

```bash
ortie --account gmail token show --auto-refresh   # 手动刷新一次
himalaya envelope list                              # 紧接着执行
```

或给 op 单独留够时间确认能通：

```bash
timeout 30 op item get Google-Acrux --fields client_secret --reveal
```

**根治**：让 op 保持登录态：

```bash
eval "$(op signin)"          # 登录后短期内的 op 调用不再每次解锁
op whoami                    # 确认已登录
```

## 参考

- `himalaya --help` / `himalaya gmail --help` 看全部子命令。
- Gmail 专属命令（`gmail messages modify/trash/delete`、`gmail labels`、`gmail threads` 等）直接对应 Gmail REST API，能做比通用 IMAP 命令更多的事。
