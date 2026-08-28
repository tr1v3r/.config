# dsh-routing-suite

- 记录日期：2026-08-28
- 仓库：https://github.com/yjh051108/dsh-routing-suite
- 状态：有趣的研究候选；尚未安装或在本机验证

## 为什么值得研究

`dsh-routing-suite` 把两类能力组合在一起：

1. **任务感知的 Agent 路由预设**：根据首条用户请求在 `spec`、`react`、`weak` 等行为模式间选择，并按“理解 → 规划 → 开发 → 验证”逐步开放工具，最后通过交付证据 gate 才允许宣布完成。
2. **运行时插件注入器**：支持完整 Cordis 插件包的注入、staging、转正、热重载、状态检查和卸载，目标是在不重启 Web 进程的情况下完成插件开发闭环。

值得关注的问题是：首轮 persona 与工具面塑形，能否减少工具 schema/context 压力、降低跑题概率，并让验证和收敛更稳定。

## 当前证据边界

- 上游实验主要覆盖 DeepSeek V4 Pro / Flash，样本量较小，任务族也有限。
- 尚无本机 `glm-5.3` / `glm-5.3-flash` 实测；模型 ID 命中 `flash` 只表示套件会选用 Flash persona，不等于适配或效果已经验证。
- 当前实现会强约束工具可见性和交付流程，可能延迟或干扰本机已有的 memory、browser、vision、reporting 与 UI 插件工具。
- Injector 涉及运行时 loader、fiber、client module 和 Web route 生命周期，影响面明显大于普通工具插件。
- 上游宣称的得分、缓存命中率和完成率提升，不能视为本机已复现结论。

## 以后怎么验证

不要直接装进主 Web/TUI profile。新建隔离的 `routing-test` profile，对同一组任务比较 `standard` 与 `router-standard`：

- 仓库诊断；
- 小型缺陷修复；
- 从零构建；
- 需要 browser、memory 或 vision 插件的组合任务。

至少记录：首轮 tool schema、路由模式、各阶段工具可见性、prompt-cache 表现、任务是否完成、验证证据、延迟与 token 成本，以及卸载/回滚后是否无残留。确认 profile 与当前 DSH 版本兼容后，再使用现有 GLM 路由做校准。

