---
layout: post
lang: zh-CN
translation_key: deepseek-harness-vs-claude-code-v4
title: "DeepSeek Harness 还是 Claude Code：普通程序员使用 DeepSeek V4 的选择"
date: 2026-08-23 13:55:00 +0800
categories: [AI, 开发工具]
tags: [deepseek, claude-code, agent, harness, coding, workflow]
series: [ai-agent]
series_order:
  ai-agent: 26
status:
  label: 待复核
  verified: 2026-08-23
  environment: Windows / Node.js 24.14.1 / npm 11.18.0 / @deepseek-ai/dsh 0.1.1-rc.2 / DeepSeek V4 官方文档与社区原始讨论
  risk: 本文已复核 DSH 的本机 npx 安装过程、已发布 rc.2 包和官方接入文档，但尚未完成全局安装，以及 Claude Code 与 DSH 在同一任务、同一模型下的端到端 A/B；社区事故不代表所有环境必现。
---

如果只是想把 DeepSeek V4 用于日常编程，而不是开发 Harness，我目前更推荐 Claude Code 作为主力、DeepSeek Harness（DSH）作为试验性副工具。原因不在模型能力，而在 Harness 成熟度：DSH 仍处于开发者预览阶段，安装、上下文和费用治理成本更高；Claude Code 虽有第三方 API 兼容边界，但已经获得 DeepSeek 官方接入支持。

---

## 先把模型和 Harness 分开

讨论“DeepSeek V4 应该搭配谁”时，最容易犯的错误是把模型能力和 Harness 行为混为一谈。

模型决定推理、代码生成和工具选择的上限；Harness 决定模型能看到什么、可以调用什么、如何保存会话、何时压缩上下文、怎样并行、什么时候必须停下来。相同的 DeepSeek-V4-Pro 放进 Claude Code 和 DSH，最终表现不同，并不自动证明某一边“模型更强”，更可能是系统提示词、工具协议、上下文组装和停止策略不同。

DSH 对这个关系表达得很直接：`Agent = Model + Harness`。它把模型、工具、技能、会话、沙箱、存储、调度、Web UI 和 Agent 行为拆成插件，再由 Profile 与 Bundle 组合。这种架构很适合实验和深度定制，但也意味着版本选择、插件冲突、兼容性、安全审查和迁移工作不会凭空消失，只是从核心项目的一部分转移给插件作者与使用者。

对于普通程序员，问题因此不该是“哪个架构更酷”，而应该是：哪个工具能以更低的维护成本，稳定完成读代码、修改、测试和交付。

## 一条 `npx` 命令背后的真实成本

DSH 官方给普通用户的最短入口是：

```powershell
npx @deepseek-ai/dsh web
```

这条命令看起来像“直接启动”，首次执行实际上会先解析和安装整个 npm 包。2026 年 8 月 23 日，我在 Windows 上使用 Node.js 24.14.1、npm 11.18.0 和淘宝 npm 镜像安装 `@deepseek-ai/dsh@0.1.1-rc.2`，观察到的过程是：

- npm 元数据请求通常只需约 15～34ms，镜像响应不是主要瓶颈；
- Node 进程持续占满一个 CPU 核，说明大量时间花在本地依赖树计算；
- 日志从数百个 `placeDep` 步骤继续扩张到 1700 多个依赖放置步骤；
- 运行约 13 分钟时，进程工作集已达到约 3.4GB；
- 最终缓存目录在启动约 15 分钟后才完成更新。

这不是所有机器都会复现的固定耗时，也不是 DSH 正常启动必然消耗 3.4GB。它能证明的范围更窄：当前 npm 发布包的依赖树足够大，npm 11 默认 hoist 策略在这台 Windows 机器上出现了明显的单核计算和内存压力。把 registry 从淘宝镜像切回 npm 官方源，不能解决发生在本地依赖解析阶段的问题。

### 为什么安装完成后仍然没有 `dsh` 命令

这里最容易产生误解：`npx` 提示安装完成，只表示包已经进入 npm 缓存，并且能在 `npx` 创建的子进程中执行；它不等于全局安装，也不会把 `dsh` 永久加入当前终端的 PATH。

因此，第一次 `npx @deepseek-ai/dsh web` 正常结束后，再直接运行下面的命令：

```powershell
dsh web
```

PowerShell 报告无法识别 `dsh`，属于 `npx` 工作方式带来的预期结果，不足以证明刚才的缓存安装失败。本机缓存中的 `dsh --version` 可以正常返回 `0.1.1-rc.2`，但全局 npm 包列表仍为空。

### 为什么 `dsh-web-ui` 的安装命令会直接失败

这个差异在安装社区插件时会立刻暴露。`dsh-web-ui` 的系统要求写着“已安装 DeepSeek Harness，`dsh web` 可正常启动”，快速开始随后直接要求执行：

```powershell
dsh plugin --profile web add @linxin666/dsh-web-ui-all@latest
dsh web
```

这份说明隐含了一个前提：用户已经通过某种持久安装或源码环境获得 PATH 中的 `dsh` 命令。它没有说明怎样从官方 `npx` 入口得到这个命令，也没有给出 `npx` 等价写法。只执行过 `npx @deepseek-ai/dsh web` 的用户并不满足这个隐含前提，所以照抄时出现“无法识别 `dsh`”是可以稳定解释的文档断层，不是插件包安装命令本身已经运行后失败。

继续沿用官方 `npx` 路径时，对应命令应写成：

```powershell
pnpm --version
npx --yes @deepseek-ai/dsh@0.1.1-rc.2 plugin --profile web add @linxin666/dsh-web-ui-all@latest
npx --yes @deepseek-ai/dsh@0.1.1-rc.2 web
```

第一行不是多余检查。DSH 的 `plugin` 子命令会把插件管理操作转发给 pnpm，官方 CLI reference 明确要求 pnpm 已安装并位于 PATH。也就是说，运行官方 Web 包只需要 npm/npx，但通过 `dsh plugin` 管理 Profile 插件仍需要 pnpm；`dsh-web-ui` 所说的“npm 安装方式无额外要求”没有呈现这一层官方前置条件。

如果坚持使用 DSH，至少应该固定版本，避免无意间跟随快速变化的 RC：

```powershell
npx --yes @deepseek-ai/dsh@0.1.1-rc.2 web
```

如果必须直接使用 `dsh` 命令，从 npm 的通用机制上可以尝试全局安装：

```powershell
npm install -g @deepseek-ai/dsh@0.1.1-rc.2
dsh --version
dsh web
```

但 DSH 官方 README 当前没有把全局安装列为正式运行方式，本文也没有完成这条路径的端到端验证，因此不能把它当作官方推荐。普通用户更稳妥的做法仍是固定版本后继续使用 `npx`。

全局 npm 包不会自动更新。需要先检查新版本，再主动升级：

```powershell
npm outdated -g @deepseek-ai/dsh
npm view @deepseek-ai/dsh version
npm install -g @deepseek-ai/dsh@latest
```

不过，DSH 官方 README 当前只正式列出 `npx` 运行和从源码运行两条路径。社区已经提出提供正式全局安装方式，但不能把这个提议写成官方承诺。

## npm 与 pnpm 不是二选一的官方建议

另一个常见误读是“DSH 官方推荐 pnpm，所以普通用户不该用 npm”。官方实际按场景分工：

| 场景 | 当前入口 | 作用 |
| --- | --- | --- |
| 运行 npm 发布包 | `npx @deepseek-ai/dsh web` | 最短体验路径 |
| 从源码开发 DSH | `pnpm install`、`pnpm run build`、`pnpm dsh web` | monorepo 开发与构建 |
| 管理 Profile 插件 | `dsh plugin --profile ...` | 由 DSH 转发给 PATH 中的 pnpm |

pnpm 使用内容寻址存储和链接复用依赖，通常比 npm 的重复安装更省空间，也更适合包含大量 workspace 的 monorepo。代价是新版 pnpm 对安装脚本控制更严格，而 DSH 的部分原生依赖需要构建许可。社区给出的 `pnpm dlx` 命令因此要显式添加多个 `--allow-build`，这对普通用户并不比 `npx` 更简单。

所以，源码仓库选择 pnpm，是工程工具链决策；它不等于普通用户必须把 `npx` 改成 `pnpm dlx`。

## DSH 真正有价值的地方

安装问题不应掩盖 DSH 的产品价值。它最有吸引力的不是“DeepSeek 官方出品”这块标签，而是以下能力组合：

- Web UI 能查看会话、工具调用和执行轨迹；
- Profile 与 Bundle 可以组合不同模型、工具、技能和界面；
- 支持子代理、后台任务、沙箱、工作流与可替换存储；
- PTC/Code Mode 可以用代码批量编排搜索、读取和远程验证；
- 会话事件足够详细，适合复盘一次 Agent 为什么慢、为什么跑偏。

社区已经有人使用 DSH + V4 Flash + PTC 完成真实开源 PR，包括代码调查、远程 Windows 复现、修改、双平台验证和更新 PR。这个案例说明 DSH 不是只能展示架构图的玩具。

但同一篇记录也给出了重要边界：Flash 在长工具编排中出现过低级代码错误，长轨迹里的证据整合也需要用户继续追问，作者最终更倾向于让 Flash 默认使用标准模式，把 PTC 留给更强的模型。成功完成一次复杂任务，不能直接推出 PTC 对所有模型和任务都更强。

## 当前最大的问题不是速度，而是缺少硬停止条件

此前我分析过两份 DSH 异常会话，并做过一次同任务 Low/High 对照，详见《[DeepSeek Harness 为什么越审查越慢：会话日志诊断与 Low/High A/B]({% post_url 2026-08-20-deepseek-harness-low-high-session-log-analysis %})》。那次实验发现，High 的 reasoning 记录量达到 Low 的 2.27 倍，总耗时接近两倍，却没有增加有效发现。

这只能说明特定日常 review 使用 Low 更合适，不能证明 DSH 普遍失控。真正需要警惕的是：当模型不收敛时，当前 Harness 能否在费用和时间失控前强制停止。

我直接检查了本机已发布的 `@deepseek-ai/dsh-agent-loop@0.1.1-rc.2`：

```powershell
rg -n "while \(true\)|maxParallelToolCalls|maxSteps|maxCost|circuitBreaker" `
  node_modules/@deepseek-ai/dsh-agent-loop/lib/index.js
```

结果仍能看到驱动循环中的 `while (true)` 和默认值为 10 的 `maxParallelToolCalls`，但没有找到 `maxSteps`、累计 token、成本上限或 `circuitBreaker` 配置。`maxParallelToolCalls` 只限制同一步中的并行工具数量，不能阻止模型完成一轮工具调用后再次决定继续搜索。

这与近期社区报告形成了交叉证据：

- 有 V4 Flash 会话在无步数上限的循环中消耗约百万 token；
- 有用户报告简单任务重复搜索，最终耗尽余额；
- 有长会话因为工具日志和完整 Schema 持续占用上下文；
- 有 Web UI 冻结后停止按钮无法响应，而后台仍在继续执行和计费。

这些是具体版本、配置和任务下的事故，不代表每个 DSH 会话都会失控。但对普通用户而言，“可以安装社区预算插件”不能完全替代内核默认保护。DeepSeek 官方当前确认的是预付余额扣费、按需充值、账单/用量信息与余额查询，没有查到用户可自行设置硬消费上限的官方能力。把 Agent 留在后台执行长任务前，更现实的止损方式是控制充值余额并监控余额与用量；确实需要硬预算时，只能使用已经独立验证支持该能力的网关或预算插件。

## Claude Code + DeepSeek V4 已有官方接入路径

DeepSeek 官方文档已经给出 Claude Code 的 V4 配置。Windows PowerShell 可以在当前终端设置：

```powershell
$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN=$env:DEEPSEEK_API_KEY
$env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_EFFORT_LEVEL="max"

claude
```

示例假设真实 Key 已经安全地存在 `DEEPSEEK_API_KEY` 中，不要把它写进脚本、仓库或公开文章。主模型使用 Pro、子代理和低成本槽位使用 Flash，是一个合理起点：复杂规划、架构判断和疑难调试交给 Pro，搜索、机械修改、测试迭代和并行子任务优先使用 Flash。

这条路径的优势不是“Claude Code 偷走了 Claude 模型的能力”。实际模型仍是 DeepSeek V4，Claude Code 提供的是更成熟的编码 Harness：项目规则、Skills、Hooks、命令、权限交互、终端工作流和上下文生命周期。

## Claude Code 路线也不是无损兼容

DeepSeek 提供的是 Anthropic API 兼容层，不是 Anthropic 服务本身。官方兼容表已经写明部分差异：

- `cache_control` 会被忽略；
- 图片、文档和部分 Anthropic 专有内容块不受支持；
- `disable_parallel_tool_use` 会被忽略；
- 不支持的模型名会自动映射到 `deepseek-v4-flash`；
- `tool_use` 与普通 `tool_result` 受支持，但服务端 MCP、容器和部分代码执行结果类型并不完整。

社区还向 Claude Code 报告过第三方 Anthropic 兼容 Provider 的上下文识别问题：DeepSeek V4 提供 1M 上下文时，Claude Code 可能仍按 200K 显示并提前 AutoCompact。这意味着“配置了 `[1m]`”不等于 Claude Code 的所有上下文策略都已经按 1M 工作。

因此，Claude Code + V4 的结论应当是“官方支持、核心编码路径可用”，而不是“与原生 Claude API 逐字段等价”。涉及图片、PDF、超长上下文、服务端工具或复杂 MCP 时，仍要按具体功能实测。

## 普通程序员应该怎么选

| 使用场景 | 更推荐 | 原因 |
| --- | --- | --- |
| 日常读代码、修改、测试 | Claude Code + V4 | 工作流成熟，维护成本低 |
| 复杂规划与跨文件重构 | Claude Code + V4 Pro | 更适合作为默认主力，但仍要拆任务和验收 |
| 低成本搜索、机械修改、子任务 | V4 Flash | 成本较低，适合明确、可验证的工作 |
| 观察完整轨迹和会话事件 | DSH | Web UI 与事件层更适合复盘 |
| 组合插件、Profile、Bundle | DSH | 架构开放，适合实验和深度定制 |
| 长时间无人值守任务 | 暂不建议裸跑 DSH | rc.2 仍缺少内核级步数与成本熔断 |
| 依赖完整 1M 上下文 | 两边都要实测 | DSH 有上下文膨胀案例，Claude Code 有识别偏差报告 |

如果只能保留一个工具，我会选 Claude Code + DeepSeek V4。DSH 可以保留在以下位置：

1. 用于研究一次 Agent 的执行轨迹；
2. 验证某个插件、Profile 或 PTC 工作流；
3. 做有明确预算、有人观察、可以随时停止的受控任务；
4. 等待原生循环熔断、上下文治理和稳定升级路径成熟后重新评估。

无论使用哪一个 Harness，都不应把“客户端有停止按钮”当作费用上限。至少要控制 DeepSeek 预付充值余额、定期查看余额和用量，并把大任务拆成计划、实现、测试与复核几个有明确停止条件的阶段；如果需要自动硬停止，应另行验证所用网关或预算插件是否真的执行累计费用熔断。

## 这篇文章没有证明什么

当前证据足以给出选择建议，但还不是同任务 benchmark。本文没有证明：

- Claude Code 使用 V4 的代码质量一定高于 DSH；
- Claude Code 永远不会循环、超时或产生高额 token；
- DSH 社区报告的问题在 `0.1.1-rc.2` 中全部必现；
- 一次 Windows npm 安装耗时可以代表其他机器和包管理器；
- V4 Pro 适合所有主任务，Flash 只适合简单任务。

要把这篇文章升级成强对比结论，下一步应固定同一仓库、同一提交、同一提示词和同一 V4 模型，分别用 Claude Code 与 DSH 完成两到三轮代码审查，报告耗时、工具次数、token、费用、有效发现和结果方差。在完成这层 A/B 前，更准确的结论仍是：

> 对普通程序员，Claude Code + DeepSeek V4 是当前更稳妥的主力路径；DSH 的架构潜力和可观察性很有价值，但它仍要求使用者主动承担更多安装、兼容、上下文和费用治理工作。

## 参考资料

- [DeepSeek Harness 官方仓库](https://github.com/deepseek-ai/deepseek-harness)
- [@deepseek-ai/dsh npm 包](https://www.npmjs.com/package/@deepseek-ai/dsh)
- [DeepSeek：Integrate with AI Tools](https://api-docs.deepseek.com/guides/coding_agents/)
- [DeepSeek Anthropic API 兼容说明](https://api-docs.deepseek.com/guides/anthropic_api/)
- [DeepSeek：模型与价格及余额扣费规则](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)
- [DeepSeek：查询账号余额](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)
- [DeepSeek：充值、账单与用量信息 FAQ](https://api-docs.deepseek.com/zh-cn/faq)
- [Anthropic：Claude Code LLM gateway configuration](https://docs.anthropic.com/en/docs/claude-code/llm-gateway)
- [DSH Discussion #3370：全局安装方式提议](https://github.com/deepseek-ai/deepseek-harness/discussions/3370)
- [dsh-web-ui：系统要求与快速开始](https://github.com/zhu1090093659/dsh-web-ui#快速开始)
- [DSH CLI reference：plugin 命令与 pnpm 前置条件](https://github.com/deepseek-ai/deepseek-harness/blob/master/apps/cli/reference/README.md)
- [DSH Discussion #475：V4 Flash + PTC 真实 PR 体验](https://github.com/deepseek-ai/deepseek-harness/discussions/475)
- [DSH Discussion #2821：Agent loop 缺少步数上限](https://github.com/deepseek-ai/deepseek-harness/discussions/2821)
- [DSH Discussion #3228：重复工具调用与费用失控](https://github.com/deepseek-ai/deepseek-harness/discussions/3228)
- [DSH Discussion #2597：长会话上下文治理讨论](https://github.com/deepseek-ai/deepseek-harness/discussions/2597)
- [DSH Discussion #2460：UI 冻结后后台继续运行](https://github.com/deepseek-ai/deepseek-harness/discussions/2460)
- [Claude Code Issue #46416：第三方 Provider 上下文识别](https://github.com/anthropics/claude-code/issues/46416)
