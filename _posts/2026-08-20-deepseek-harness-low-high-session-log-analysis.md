---
layout: post
title: "DeepSeek Harness 为什么越审查越慢：会话日志诊断与 Low/High A/B"
date: 2026-08-20 00:05:00 +0800
categories: [AI, 开发工具]
tags: [deepseek, agent, harness, debugging, review, performance]
series: [ai-agent]
series_order:
  ai-agent: 25
status:
  label: 当前可用
  verified: 2026-08-20
  environment: Windows / DeepSeek Harness Web GUI / DeepSeek-V4-Pro / reasoning effort Low、High / session JSONL
  risk: 结论来自两份异常会话日志和一次同任务 Low/High 对照；它能定位本次耗时发生在哪一层，但不是模型总体性能基准。Low 日志中的 session.createdAt 显示为旧日期，与本次实际执行时间不一致，实验顺序以实际操作记录和 turn 相对时间为准。
---

一次范围明确的代码审查，为什么会运行十几分钟，甚至需要手动终止？我没有继续根据界面感受猜测“模型慢”或“工具卡住”，而是拆解 DeepSeek Harness 导出的 session JSONL，再用同一工作区、同一提示词分别运行 Low 和 High。结果很直接：在这次对照中，High 的推理记录量达到 Low 的 2.27 倍，总耗时接近两倍，却没有找到 Low 遗漏的新问题。

---

## 先说结论

这次问题不能简单归为“DeepSeek 模型不行”，也不能只说“harness 有 Bug”。更准确的因果链是：

1. 模型在 High 档进行了更多分支推演和重复确认；
2. harness 给了它很宽的上限：`reasoningEffort: high`、`maxTokens: 256000`、`contextWindow: 1000000`；
3. 普通 review 没有墙钟时间、工具次数或收敛条件等硬性保护；
4. 其中一份子代理会话还被上游委派提示词扩张成了全面审计。

工具不是主要瓶颈。在最典型的一次 686.93 秒 turn 里，19 次工具调用合计只用了约 3.65 秒。真正拖长的是工具调用之间的模型生成、请求调度和流式处理阶段。

受控 A/B 进一步表明：这类日常 diff review 使用 Low 已经足够。High 多花的时间没有转化为额外的确认问题。

## 症状：小任务为什么一直不结束

最初让我怀疑有问题的是两份不同任务的日志。

第一份是 Userscript 的对抗性审查和后续修复。用户已经给出一个很具体的 P2：初次 6 秒期限到达时，已连接但尚未提交的根没有被锁定，仍可能继续发起接管。这个 turn 从 22:26:02 运行到 22:37:29，共 686.93 秒，最终被用户终止。

它的工具调用并不慢：

- 第一步持续 347.62 秒，末尾调用的 `grep` 只执行了 51ms；
- 另一步持续 136.69 秒，末尾的 `read` 只执行了 21ms；
- 19 次工具调用合计约 3.65 秒；
- 日志记录了约 22.4 万字符的 reasoning 内容；
- 没有形成工具错误重试链。

这足以排除“PowerShell 跑了十分钟”或“沙箱一直重试”的解释。耗时发生在推理路径上。

第二份是 delegated subagent 对一篇技术文章改动做 review。它运行了 617.74 秒，调用 47 次工具，其中工具执行约 81.91 秒，剩余约 535.83 秒仍属于非工具阶段。它最后也被用户终止。

但第二份不能只怪子代理发散。上游交给它的提示词已经把任务写成 A～I 九组检查，要求逐项覆盖：

- 嵌入脚本的字节级转义和换行；
- Jekyll、Liquid、kramdown 跨版本兼容；
- 中英文数字、日期、版本和声明一致性；
- 生成 HTML、CI、SEO、脱敏和安全；
- Pages 残余风险和“anything else”。

提示词还明确要求“每一项都深入检查，不要只看表面”。因此，这里的发散一部分来自模型，一部分来自上游 agent 在委派时放大了原任务范围。

## 不能直接相信模型对自己的解释

被追问原因后，模型在会话里回答：

> 是模型本身的问题，不是 harness 的问题。

这句话不能当作诊断结论。模型对自己行为的解释也只是一次生成结果，必须回到事件时间线验证。

日志能确认的是：

- 工具执行很快；
- 大部分时间发生在非工具阶段；
- 两份请求都使用 DeepSeek-V4-Pro 的 High 档；
- High 配置允许很长的 reasoning 和输出；
- harness 没有在“问题已确认、测试已通过”后强制进入总结。

因此，更准确的表述是：直接耗时发生在模型推理路径，但 harness 的配置、上下文管理、委派范围和停止策略共同决定了这种行为能持续多久。

## 如何从 JSONL 区分模型时间和工具时间

分析 session 日志时，我没有把整个文件的首尾时间直接当成任务耗时。会话中可能存在几十分钟的用户空闲，应该以每个 `turn/start` 到对应 `turn/end` 的区间为准。

主要事件包括：

| 事件 | 用途 |
| --- | --- |
| `request/header` | 模型、reasoning 档位和 token 上限 |
| `request/context` | provider、model 和 context window |
| `turn/start` / `turn/end` | 单个 turn 的活跃墙钟时间和结束原因 |
| `step/start` / `step/end` | 定位哪个步骤异常变长 |
| `tool/call` / `tool/result` | 工具名称、参数和执行间隔 |
| `assistant/message` | 最终文本及聚合后的 reasoning 块 |
| `agent/inbox/spliced` | 用户消息进入队列、替换或中断的过程 |

下面这段 PowerShell 可以计算一个单 turn 会话的基础指标。路径应替换为自己的导出文件：

```powershell
$SessionLog = '<session.jsonl>'
$Events = Get-Content -LiteralPath $SessionLog | ForEach-Object {
  try { $_ | ConvertFrom-Json -Depth 80 } catch { $null }
}

$TurnStart = $Events | Where-Object type -eq 'turn/start' | Select-Object -First 1
$TurnEnd = $Events | Where-Object type -eq 'turn/end' | Select-Object -Last 1
$Calls = @($Events | Where-Object type -eq 'tool/call')
$Results = @($Events | Where-Object type -eq 'tool/result')

$ToolMilliseconds = 0
foreach ($Call in $Calls) {
  $Result = $Results |
    Where-Object { $_.data.message.source.callId -eq $Call.data.callId } |
    Select-Object -First 1

  if ($Result) {
    $ToolMilliseconds += $Result.time - $Call.time
  }
}

$ReasoningCharacters = 0
foreach ($Message in ($Events | Where-Object type -eq 'assistant/message')) {
  foreach ($Block in $Message.data.message.content) {
    if ($Block.type -eq 'reasoning') {
      $ReasoningCharacters += ([string] $Block.text).Length
    }
  }
}

$WallMilliseconds = $TurnEnd.time - $TurnStart.time
[pscustomobject]@{
  WallSeconds = [math]::Round($WallMilliseconds / 1000, 3)
  ToolSeconds = [math]::Round($ToolMilliseconds / 1000, 3)
  NonToolSeconds = [math]::Round(($WallMilliseconds - $ToolMilliseconds) / 1000, 3)
  ToolCalls = $Calls.Count
  ReasoningCharacters = $ReasoningCharacters
  EndReason = $TurnEnd.data.reason.kind
}
```

这里的 `ReasoningCharacters` 只是日志字符量，不是 token 数，也不等同于实际算力消耗。`NonToolSeconds` 也不能全部记在模型头上，它还包括 provider、adapter、队列和流式处理等开销。不过，当 687 秒里工具只占不到 4 秒时，已经足够判断瓶颈不在本地命令。

如果工具并行执行，逐调用时长相加还会产生少量重叠。本文几组工具时间相对总耗时都很小，不影响方向性结论。

## 设计 Low/High 对照

仅凭两份都运行在 High 的异常日志，无法区分“模型固有行为”和“High 档放大效应”。因此我又做了一次对照实验。

两次运行保持：

- 相同仓库和分支；
- 相同的 9 个未提交文件；
- 相同的 `774 insertions / 114 deletions`；
- 主脚本和文档 diff 输出哈希一致；
- 相同的 review 提示词；
- 相同的 `maxTokens: 256000` 和 `contextWindow: 1000000`；
- 都不联网、都不修改文件。

提示词把范围和停止条件写得很窄：只检查 diff、直接调用链和相关测试，满足条件后立即报告，不继续寻找相邻问题。Low 文本末尾比 High 多一个句号，这是唯一的字面差异，不构成实质变量。

Low 日志的 `session.createdAt` 显示为旧日期，与本次实际执行时间不一致，因此不能用它判断执行顺序。两次实际按 Low→High 执行；统计使用各自 turn 内部的相对时间。

## A/B 结果：High 花了近两倍时间

| 指标 | Low | High | High / Low |
| --- | ---: | ---: | ---: |
| 总活跃耗时 | 229.58 秒 | 441.21 秒 | 1.92× |
| 首次工具调用 | 3.07 秒 | 2.85 秒 | 基本相同 |
| 工具实际耗时 | 6.48 秒 | 6.00 秒 | 基本相同 |
| 非工具耗时 | 223.10 秒 | 435.22 秒 | 1.95× |
| reasoning 字符量 | 43,346 | 98,241 | 2.27× |
| step 数 | 18 | 28 | 1.56× |
| 工具调用 | 24 | 29 | 1.21× |
| 文件读取 | 11 | 13 | 1.18× |
| 网络搜索 | 0 | 0 | 相同 |
| 结束原因 | completed | completed | 相同 |
| 确认问题 | 1 个低严重度问题 | 同一个问题 | 无新增发现 |
| 测试结果 | 112 项通过 | 112 项通过 | 相同 |

首次工具调用都在 3 秒左右，说明 High 没有明显拖慢启动。差异是在后续理解代码、选择检查路径和组织结论时逐步累积的。

工具调用只从 24 次增加到 29 次，也不是失控式增长。High 真正膨胀的是工具之间的 reasoning：记录量达到 Low 的 2.27 倍，非工具时间增加约 212 秒。

## 更多推理有没有换来更好的 review

两档确认了完全相同的问题：`updateSettings` 中仍有一条旧注释，声称“初次启动保留历史扫描”，但当前版本已经移除了全部历史 script 扫描。这是低严重度维护问题，不影响运行时行为。

两档也都完成了相同的关键验证：

- 产品运行路径已经移除 BGM fetch/XHR 包装；
- 历史 script 扫描已经移除；
- mutation、DTO 扇出和遍历时间均有明确预算；
- 聚合执行 `node --test` 因沙箱 `spawn EPERM` 失败；
- 改为逐文件进程内执行后，共 112 项测试全部通过；
- 真实 SPA 稳定性仍需要 Chrome + Tampermonkey 复测。

High 没有发现 Low 遗漏的功能问题。它的最终报告反而更短，只列出两条 residual risks；Low 列出了三条，并保留了更多直接调用链说明。

High 有一个小优势：它把 verdict 写成了 `pass`，Low 写成 `conditional pass`。既然唯一问题只是非阻塞注释，`pass` 的严重度校准更自然。但这个差异不值额外的 3 分 32 秒。

这次实验支持以下判断：

1. High 的额外耗时不是工具变慢；
2. High 的检查范围没有实质不同；
3. High 确实进行了更多推理和更多步骤；
4. 这些额外推理没有转化为额外有效发现。

## 为什么“最终回答更短”仍可能更慢

High 的最终文本只有约 1300 个字符，Low 约 2400 个字符，但 High 总耗时接近两倍。这说明不能用最终回复长度推断任务成本。

Agent 的成本主要还可能发生在：

- 工具前的方案推演；
- 工具结果后的多分支复核；
- 对同一结论换角度重新确认；
- 决定是否继续读取更多上下文；
- 在最终输出前压缩大量中间判断。

如果产品只展示“正在思考”和工具列表，用户很容易把长时间等待归因到 shell、网络或文件读取。harness 更有用的可观察性应该把时间拆成至少三类：模型/provider、工具执行、队列与调度。

## 对 harness 的改进建议

### 日常 review 默认使用 Low

这次结果不足以证明 Low 在所有任务上都优于 High，但足以说明普通 diff review 没必要无条件使用 High。

更合理的路由是：

- 日常 review、文案修改、明确的小型修复：Low；
- 复杂并发、状态机、数据迁移、权限边界和疑难性能问题：按需切换 High；
- Max 只用于有明确收益假设的极端任务，不作为“更认真”的通用开关。

### 给 turn 设置停止预算

token 上限不是停止策略。harness 还需要：

- 软墙钟时间，例如普通 review 3～5 分钟；
- 工具调用预算，例如 12～20 次；
- 重复验证检测；
- 接近预算时优先输出已确认结论和残余风险；
- 已由代码与测试共同确认的结论不再换命令重复验证。

预算不应粗暴截断高风险任务，而应该触发一次收敛检查：当前任务是否已经满足验收条件，继续探索能否改变 verdict。

### 委派提示词继承原始范围

子代理提示词应保持用户任务的边界，而不是自动把“一篇文章 review”升级为字节、SEO、安全、跨版本和 CI 的全面审计。

委派时至少应保留：

- 原始目标；
- 明确排除项；
- 可接受的证据层；
- 停止条件；
- 是否允许联网；
- 只 review 还是可以修改。

如果确实需要全面审计，应由上游明确说明范围扩大的原因，而不是悄悄塞进子代理提示词。

### 正确呈现中断与消息队列

第二份异常日志中，用户发出停止意见后，当前 turn 在约 5 秒内以 `aborted` 结束，说明中断机制本身有效。相同文本后来带着两个不同 RPC ID 出现，更像两次独立客户端提交，不能据此断言 harness 自动复制消息。

UI 可以进一步显示“中断请求已接受”和队列中仍有多少条消息，避免用户因为看不到反馈而重复发送。

### 不要把所有注入内容都伪装成普通用户消息

日志中的仓库规则和运行时快照带有 `source.kind: agent-instructions` 或 `plugin`，但消息角色仍表现为 `user`。元数据虽然能够区分来源，大段规则仍会占用上下文，也可能让优先级语义变得不够清晰。

如果 provider 支持，harness 应把系统规则、开发者规则、项目上下文和真实用户请求映射到清晰的角色层级，并在日志分析工具中默认分开显示。

## 这次实验不能证明什么

这只是一次同任务 Low/High 对照，不能据此推出：

- DeepSeek-V4-Pro 在所有任务上 High 都慢 1.92 倍；
- High 永远不会发现 Low 漏掉的问题；
- 非工具时间全部是模型计算；
- 其他 harness 使用同一模型会有相同行为；
- Low 应取代所有高推理档任务。

如果要把案例升级为稳定 benchmark，至少应保持仓库和提示词不变，再重复两到三轮，报告中位数和结果方差。还可以增加 Off 作为基线，但没有必要先跑 Max。

当前证据足以支持一个更窄、也更实用的结论：

> 在这次范围明确的代码 review 中，DeepSeek-V4-Pro High 将 reasoning 记录量和非工具耗时扩大到 Low 的两倍左右，却没有增加有效发现。对于日常 review，Low 是更合理的默认档；真正需要修正的不是单一模型标签，而是模型档位、委派范围、停止预算和耗时可观察性组成的整套 harness 行为。
