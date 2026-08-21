# AI Configurations — Skill & MCP Inventory

> Auto-generated on 2025-06-12. Last updated: 2026-08-22 — added dot-skill (dsh)
> Repository: `tr1v3r/ai-config` (private)

---

## 📊 Summary

| Category | Count |
|----------|-------|
| 飞书/Lark 集成 Skills | 26 |
| 通用工具 Skills | 15 |
| Agent 治理 Skills | 5 |
| 第三方集成 Skills | 2 |
| **自定义 Skills 合计** | **46** |
| MCP Servers | 4 |
| Codex Plugins | 1 |

---

## 🔧 飞书 / Lark 集成 Skills (26)

这些 Skill 封装了 `lark-cli` 命令，覆盖飞书生态的核心能力。

### 通讯与协作
| Skill | 描述 |
|-------|------|
| **lark-im** | 即时通讯：收发消息、管理群聊、文件上传下载、表情回复 |
| **lark-mail** | 邮箱：草稿、撰写、发送、回复、转发、搜索邮件、管理文件夹/标签/联系人/附件/规则 |
| **lark-calendar** | 日历：查看/搜索日程、创建/更新会议、管理参会人、忙闲查询、预定会议室 |
| **lark-vc** | 视频会议：搜索历史会议、查询纪要产物（总结/待办/章节/逐字稿）、查询参会人快照 |
| **lark-vc-agent** | 视频会议 Agent：机器人代用户加入/离开进行中的会议，读取实时事件（发言/聊天/屏幕共享） |
| **lark-contact** | 通讯录：按姓名/邮箱解析 open_id，反查员工信息 |
| **lark-attendance** | 考勤打卡：查询自己的考勤打卡记录 |

### 文档与知识管理
| Skill | 描述 |
|-------|------|
| **lark-doc** | 云文档/Docx：创建、读取、编辑飞书文档（DocxXML / Markdown），管理图片/附件/画板 |
| **lark-wiki** | 知识库：管理知识空间、成员、节点层级结构 |
| **lark-drive** | 云空间：上传/下载文件、管理文件夹、评论、权限、导入本地文件为在线文档 |
| **lark-markdown** | Markdown 文件：创建、编辑、差异比较飞书 Markdown |
| **lark-minutes** | 妙记：搜索、下载音视频、获取 AI 产物（总结/待办/章节）、上传音视频生成纪要 |
| **lark-slides** | 幻灯片：通过 XML 协议创建和编辑演示文稿，内置 40+ 模板 |
| **lark-whiteboard** | 画板：通过 DSL / SVG / Mermaid 创建图表（架构图/流程图/鱼骨图/泳道图等） |

### 数据与流程
| Skill | 描述 |
|-------|------|
| **lark-base** | 多维表格/Base：建表、字段管理、记录读写、视图配置、角色/表单/仪表盘/工作流 |
| **lark-sheets** | 电子表格：创建表格、管理工作表、读写单元格、导出文件 |
| **lark-task** | 任务管理：创建/更新待办、拆分子任务、管理清单、分配成员、任务智能体 |
| **lark-okr** | OKR：管理目标与关键结果、对齐关系、进展记录 |
| **lark-approval** | 审批：审批实例与审批任务管理 |
| **lark-event** | 实时事件：订阅消费飞书事件流（IM 消息、表情回复、群成员变更等） |
| **lark-apps** | 妙搭应用：部署 HTML 为可分享的静态网站/应用 |

### 工作流编排
| Skill | 描述 |
|-------|------|
| **lark-workflow-meeting-summary** | 会议纪要整理：汇总指定时间范围的会议纪要并生成结构化报告 |
| **lark-workflow-standup-report** | 日程待办摘要：编排 calendar + task，生成日程与未完成任务摘要 |

### 平台与工具
| Skill | 描述 |
|-------|------|
| **lark-shared** | Lark CLI 基础：认证登录、身份切换、权限/scope 错误处理、CLI 更新 |
| **lark-openapi-explorer** | 原生 OpenAPI 探索：查找未封装的原生飞书 API |
| **lark-skill-maker** | 自定义 Skill 创建器：将飞书 API 封装为可复用 Skill |

---

## 🛠 通用工具 Skills (14)

| Skill | 描述 |
|-------|------|
| **git-commit** | Git 提交：Conventional Commit 分析、智能暂存、消息生成 |
| **github** | GitHub CLI 操作：Issues、PRs、CI、Code Review、API 查询 |
| **agent-browser** | 浏览器自动化：页面导航、表单填写、点击、截图、数据提取、Web 应用测试 |
| **find-skills** | Skill 发现：帮助用户搜索和安装新的 Agent Skill |
| **skill-creator** | Skill 创建器：创建/修改/优化 Skill，运行 eval，基准测试与方差分析 |
| **planning-with-files-zh** | 文件规划系统（Manus 风格）：用 task_plan.md / findings.md / progress.md 跟踪复杂任务 |
| **frontend-design** | 前端设计指导：独特、有意的视觉设计方向，排版与美学决策 |
| **vercel-react-best-practices** | React/Next.js 性能优化：来自 Vercel 工程团队的最佳实践 |
| **update-features** | 特征数据更新：从 ClickHouse 拉取每日特征到 CSV 文件 |
| **anomaly-report** | 离职风险异常报告：用 Isolation Forest / Autoencoder 模型输出 Top-5 异常员工到飞书文档 |
| **notion-api** | Notion REST API：通过 HTTP 请求直接读写 Notion 数据 |
| **notion-cli** | Notion CLI：通过命令行操作 Notion |
| **notion-todo-query** | Notion 待办查询 |
| **obsidian-markdown** | Obsidian Flavored Markdown：wikilinks、embeds、callouts、properties 等 Obsidian 专用语法 |
| **obsidian-cli** | Obsidian CLI：与运行中的 Obsidian 实例交互，管理笔记、搜索、插件/主题开发调试 |
| **sync-skills** | 技能同步器：根据 skill-lock.json 一键安装/更新所有 Skills（新设备装机或批量更新） |

---

## 🧠 Agent 治理 Skills (5)

| Skill | 描述 |
|-------|------|
| **p7** | P7 高级工程师模式：方案驱动执行，输出实现计划 + 代码 + 自检三问 |
| **p9** | P9 Tech Lead 模式：编写六要素 Task Prompt，管理 P8 Agent 团队，不写代码 |
| **p10** | P10 CTO 模式：战略方向、组织拓扑设计、管理 P9 团队、架构委员会 |
| **pua** | PUA 模式：在挫败/反复失败/质量投诉时触发的驱动模式 |
| **pro** | PUA Pro 扩展：自进化追踪、KPI 报告、段位、周报、述职、排行榜 |

---

## 🌐 第三方集成 Skills (1)

| Skill | 描述 |
|-------|------|
| **weread-skills** | 微信读书助手：搜索书籍、管理书架、笔记划线、书评、阅读统计、推荐 |
| **dot-skill** | 数字生命 meta-skill 引擎：把同事/关系/名人蒸馏成可复用 Skill（装于 `$DSH_HOME/skills/dot-skill`，供 DeepSeek Harness 使用） |

---

## 🔌 MCP Servers (4)

配置位置：`~/.codex/config.toml`

| Server | Transport | Command/URL | Usage |
|--------|-----------|-------------|-------|
| **claude** | stdio | `claude mcp serve` | Claude Code MCP bridge |
| **exa** | HTTP | `https://mcp.exa.ai/mcp` | Exa 搜索引擎 |
| **chrome** | stdio | `npx chrome-devtools-mcp@latest` | Chrome DevTools 自动化 |
| **postgres** | stdio | `npx @modelcontextprotocol/server-postgres` | PostgreSQL 数据库连接 |

---

## 🧩 Codex Plugins (1)

| Plugin | Source |
|--------|--------|
| **browser** | openai-bundled |

---

## 📁 文件结构

```
~/.agents/skills/          # Reasonix 自定义 Skills（47 个，含项目级 obsidian-cli）
~/.codex/config.toml       # Codex 配置（模型、MCP Servers、项目信任级别）
~/.reasonix/skills/        # Reasonix project-level skills（obsidian-cli, sync-skills 等）
~/.config/ai/skill-lock.json  # 已安装 Skills 的完整安装记录（版本控制）
~/.reasonix/.mcp.json      # Reasonix 项目级 MCP 配置（暂无）
~/.config/ai/              # ai-config 仓库（本文件所在）
```
