# Himalaya + Gmail OAuth 配置手册（macOS）

本文记录当前机器上已经验证可用的完整配置流程。目标是让 Himalaya 同时支持：

- Gmail REST API：读取、管理邮件，以及使用 `himalaya gmail ...` 原生子命令；
- SMTP：保留通用的 `message compose --send` 发信体验；
- Ortie：完成 Google OAuth，并自动刷新 access token。

## 1. 认证链路

这里有两套彼此独立的认证方式：

| 用途 | Himalaya backend | 认证方式 |
| --- | --- | --- |
| 通用发信 | SMTP | Gmail App Password |
| 收信、管理及原生 API | Gmail REST API | Google OAuth 2.0 |

OAuth 链路如下：

```text
Google OAuth Desktop Client
        ↓
Ortie 获取并刷新 token
        ↓
macOS Keychain 保存 token
        ↓
Himalaya 调用 `ortie token show`
        ↓
Gmail REST API
```

Himalaya v2 不执行 OAuth 登录和刷新，只消费 Ortie 输出的短期 access token。

## 2. 安装依赖

需要 Rust/Cargo、1Password CLI、Himalaya 和 Ortie：

```bash
brew install --cask 1password-cli

cargo install --locked --git https://github.com/pimalaya/himalaya.git
cargo install --locked ortie
```

确认版本和编译功能：

```bash
himalaya --version
ortie --version
```

Himalaya 的版本输出需要包含 `+gmail`。

本文验证时使用：

```text
himalaya v2.0.0-alpha.1 +gmail +imap +smtp
ortie v1.1.0 +rustls-ring +command +notify
```

## 3. 配置 Gmail App Password（SMTP）

Gmail 的 SMTP 不能直接使用 Google 账户主密码。

1. 为 Google 账户启用两步验证；
2. 打开 Google Account 的 **App passwords**；
3. 创建一个专用于 Himalaya 的 16 位应用密码；
4. 将它保存到 1Password：

   ```text
   Item: Google-Acrux
   Field: app password
   ```

当前 Himalaya 使用以下命令动态取密码：

```bash
op item get Google-Acrux --fields "app password" --reveal
```

安全检查 1Password 是否能取到密码，不显示实际值：

```bash
op item get Google-Acrux --fields "app password" --reveal >/dev/null \
  && echo "Gmail App Password: OK"
```

## 4. 创建 Google Cloud OAuth 应用

### 4.1 启用 Gmail API

1. 打开 [Google Cloud Console](https://console.cloud.google.com/)。
2. 创建或选择一个项目。
3. 进入 **APIs & Services → Library**。
4. 搜索并启用 **Gmail API**。

### 4.2 配置 Google Auth Platform

进入 **Google Auth Platform**：

1. 在 **Branding** 中填写应用名称，例如 `Himalaya CLI`。
2. 在 **Audience** 中选择 `External`。
3. 如果 Publishing status 是 `Testing`，在 **Test users** 中添加：

   ```text
   acrux.hu@gmail.com
   ```

4. 在 **Data Access → Add or remove scopes** 中添加：

   ```text
   https://www.googleapis.com/auth/gmail.modify
   ```

`gmail.modify` 足够完成读信、发信、草稿、标签、归档和移入垃圾箱等常用操作。

如需管理过滤器、自动回复等 Gmail 设置，再增加：

```text
https://www.googleapis.com/auth/gmail.settings.basic
```

除非确实需要绕过垃圾箱永久删除邮件，否则不要使用权限更大的：

```text
https://mail.google.com/
```

### 4.3 创建 Desktop OAuth Client

1. 进入 **Google Auth Platform → Clients**。
2. 点击 **Create Client**。
3. Application type 选择 **Desktop app**。
4. 创建后复制 `Client ID` 和 `Client secret`。

Client ID 格式类似：

```text
123456789012-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com
```

不需要下载或长期保存 OAuth JSON。

## 5. 将 Client Secret 保存到 1Password

Client ID 不是秘密，可以直接写入 Ortie 配置。Client secret 保存到已有的
`Google-Acrux` 项：

```text
Field: client_secret
Type: Password
```

验证 secret 能读取，但不显示值：

```bash
op item get Google-Acrux --fields client_secret --reveal >/dev/null \
  && echo "OAuth client secret: OK"
```

## 6. 配置 Ortie

创建配置：

```text
~/.config/ortie/config.toml
```

完整配置：

```toml
[accounts.gmail]
default = true

client-id = "527080699970-b3qk1m41pfcr1qni2gh2tk924e7s78bp.apps.googleusercontent.com"
client-secret.command = [
  "/opt/homebrew/bin/op",
  "item",
  "get",
  "Google-Acrux",
  "--fields",
  "client_secret",
  "--reveal",
]

endpoints.authorization = "https://accounts.google.com/o/oauth2/auth?access_type=offline&prompt=consent"
endpoints.token = "https://oauth2.googleapis.com/token"

scopes = [
  "https://www.googleapis.com/auth/gmail.modify",
  "https://www.googleapis.com/auth/gmail.settings.basic",
]

pkce = true
auto-refresh = true

storage.read.command = [
  "security",
  "find-generic-password",
  "-a",
  "acrux.hu@gmail.com",
  "-s",
  "ortie-gmail-oauth",
  "-w",
]

storage.write.command = [
  "sh",
  "-c",
  "security add-generic-password -U -a 'acrux.hu@gmail.com' -s 'ortie-gmail-oauth' -w \"$(cat)\"",
]
```

限制权限：

```bash
chmod 600 ~/.config/ortie/config.toml
```

## 7. 首次 OAuth 授权

运行：

```bash
ortie --account gmail auth get
```

Ortie 会：

1. 创建 PKCE 和 state；
2. 打开 Google 授权页面；
3. 在本机启动临时 HTTP callback server；
4. 使用 authorization code 换取 access/refresh token；
5. 将 token 写入 macOS Keychain。

成功输出：

```text
Access token successfully issued (expires in 1h)
```

安全验证 token 是否可读取，不要直接把 token 打印到终端：

```bash
ortie --account gmail token show --auto-refresh >/dev/null \
  && echo "Ortie token: OK"
```

查看 Keychain 项：

```bash
security find-generic-password \
  -a "acrux.hu@gmail.com" \
  -s "ortie-gmail-oauth"
```

不要在命令末尾增加 `-w`，否则会输出 token。

## 8. 配置 Himalaya

主配置文件：

```text
~/.config/himalaya/config.toml
```

Gmail 账户配置：

```toml
[accounts.gmail]
default = true

[accounts.gmail.smtp]
server = "smtps://smtp.gmail.com:465"
sasl.plain.username = "acrux.hu@gmail.com"
sasl.plain.password.command = "op item get Google-Acrux --fields \"app password\" --reveal"

[accounts.gmail.gmail]
user-id = "me"
auth.token.command = [
  "ortie",
  "--account",
  "gmail",
  "token",
  "show",
  "--auto-refresh",
]

[accounts.gmail.mailbox.alias]
sent = "[Gmail]/Sent Mail"
```

其中：

- `[accounts.gmail.smtp]` 使用 App Password；
- `[accounts.gmail.gmail]` 使用 Ortie OAuth token；
- Gmail API 负责收信和管理，SMTP 只负责通用发信命令。

## 9. 处理 macOS 默认配置路径

这是最容易忽略的一步。

Himalaya 在 macOS 上优先读取：

```text
~/Library/Application Support/himalaya/config.toml
```

然后才会尝试：

```text
~/.config/himalaya/config.toml
```

如果两个文件同时存在，裸命令可能读取旧配置并报：

```text
Gmail config is missing for account `gmail`
```

当前机器以 `~/.config` 为主配置，并建立符号链接：

```bash
mkdir -p "$HOME/Library/Application Support/himalaya"

mv "$HOME/Library/Application Support/himalaya/config.toml" \
   "$HOME/Library/Application Support/himalaya/config.toml.backup"

ln -s "$HOME/.config/himalaya/config.toml" \
      "$HOME/Library/Application Support/himalaya/config.toml"
```

如果目标目录中原本没有 `config.toml`，跳过 `mv`。

验证链接：

```bash
ls -l "$HOME/Library/Application Support/himalaya/config.toml"
```

也可以临时绕过默认路径：

```bash
himalaya \
  --config "$HOME/.config/himalaya/config.toml" \
  -a gmail gmail profile get
```

## 10. 端到端验证

### 10.1 检查 backend

```bash
himalaya account list
```

Gmail 应显示：

```text
gmail, smtp
```

### 10.2 检查 Gmail backend

```bash
himalaya -a gmail --backend gmail account check
```

预期：

```text
Account: gmail
  gmail: OK
```

### 10.3 检查 Gmail REST API

```bash
himalaya -a gmail gmail profile get
himalaya -a gmail gmail labels list
himalaya -a gmail gmail messages list \
  --query "is:unread" \
  --max-results 10
```

### 10.4 通过共享 API 使用 Gmail backend

Gmail 是该账户唯一的存储 backend，因此可以直接使用：

```bash
himalaya -a gmail mailbox list
himalaya -a gmail envelope list
```

也可以显式增加 `--backend gmail`。

原生 `gmail` 子命令不需要 `--backend gmail`：

```bash
himalaya -a gmail gmail threads list
```

## 11. 常见故障

### `Error 403: access_denied`

完整提示通常包含：

```text
The app is currently being tested, and can only be accessed by
developer-approved testers.
```

原因：应用处于 Testing，但登录账户不在 Test users 中。

解决：

1. 打开 **Google Auth Platform → Audience**；
2. 在 **Test users** 中加入 `acrux.hu@gmail.com`；
3. 保存后重新运行 `ortie --account gmail auth get`。

### OAuth 显示成功，但 Keychain 找不到 token

错误类似：

```text
Read access token via command error
security: The specified item could not be found in the keychain.
```

原因：`storage.write.command` 中的 `$(cat)` 没有经过 shell 展开。

解决：使用本文中的 `storage.write.command = ["sh", "-c", "..."]`。
修复后需要重新执行 OAuth 授权。

### `Gmail config is missing for account gmail`

先比较默认与显式配置：

```bash
himalaya account list
himalaya --config "$HOME/.config/himalaya/config.toml" account list
```

如果只有显式配置显示 `gmail` backend，说明 macOS 正在读取
`~/Library/Application Support/himalaya/config.toml` 中的旧文件。按第 9 节统一路径。

### `insufficientPermissions` 或 HTTP 403

原因通常是 Ortie 请求的 scope 不足，或者修改 scope 后仍在使用旧 token。

解决：

1. 在 Google Auth Platform → Data Access 中加入所需 scope；
2. 同步修改 Ortie 的 `scopes`；
3. 重新运行：

   ```bash
   ortie --account gmail auth get
   ```

## 12. Testing 状态的七天限制

External OAuth 应用如果保持 `Testing`，Gmail scope 对应的授权和 refresh token
通常会在七天后失效。届时重新执行：

```bash
ortie --account gmail auth get
```

个人长期使用可以将 Publishing status 调整为 `In production`。个人自用且用户数很少时，
通常无需完成公开应用验证，但授权页面可能继续显示“未经验证的应用”提示。

## 13. 安全检查清单

- 不把 access token 或 refresh token 打印到日志；
- 不在仓库或长期磁盘中保存 OAuth JSON；
- client ID 可明文保存，client secret 只从 1Password 读取；
- Ortie 配置权限为 `0600`；
- token 只保存在 macOS Keychain；
- 使用满足需求的最小 Gmail scope；
- 分享日志时删除 authorization code、state、PKCE 和 token。
