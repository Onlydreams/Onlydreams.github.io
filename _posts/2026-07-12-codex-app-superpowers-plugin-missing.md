---
layout: post
title: "Codex App 升级后 Superpowers 插件失效：技能消失的排查与临时修复"
date: 2026-07-12 15:50:00 +0800
categories: [AI, 工具, 配置]
tags: [codex, superpowers, plugin, skills, troubleshooting]
series: [ai-agent]
series_order:
  ai-agent: 22
status:
  label: 待复核
  verified: 2026-07-12
  environment: Windows Codex Desktop / Superpowers curated plugin / 本地会话技能列表
  risk: 官方 issue 尚未关闭；手动重装仅是临时恢复方式，后续 App 更新可能再次触发。
---

如果 Codex App 升级后，Superpowers 在插件页仍显示已启用、磁盘缓存也还在，但新开会话里不再出现任何 `superpowers:*` 技能，不要先假定是自己误删了插件。这更像是一次插件状态或技能发现的迁移失效：插件“在”，但没有被注入当前会话。它会让原本依赖 Superpowers 的规划、测试、审查和收尾流程悄悄失效。

---

## 先看结论

这次本机记录的时间线是：7 月 9 日晚间，Superpowers 仍在会话技能列表中；7 月 10 日凌晨 Codex Desktop 内嵌 agent runtime 更新后，首个新会话已经没有该插件的技能。配置始终保持启用，旧缓存也仍在磁盘，因此没有证据表明是手动卸载。

重新从插件入口安装后，技能重新出现在新会话中。这说明重装可以恢复使用，但不能证明根因已经修复。

公开的 [openai/codex#31365](https://github.com/openai/codex/issues/31365) 记录了相同方向的问题：App 升级后，Superpowers 缓存文件仍保留，但已安装/已启用状态没有被正确恢复。该 issue 在 2026-07-12 仍是 open，带有 `app`、`bug`、`config` 和 `skills` 标签。

## 这个问题是怎样被发现的

最初的信号不是 Plugins 页面报错，而是一次实际工作流没有按预期收尾：子智能体给出一项需要补充运行时测试的审查意见后，主 Agent 只汇总了意见，没有继续完成“判断建议是否合理 → 修复有效项 → 验证 → 复审”的闭环。

这只能说明流程异常，不能直接证明是插件问题。随后才按三层证据排查，而不是把它归因为 Agent 一次普通疏漏：

| 排查层 | 看到的事实 | 说明 |
| --- | --- | --- |
| 会话历史 | 7 月 9 日最后一次正常会话仍列出 Superpowers；7 月 10 日 runtime 更新后的首个新会话已经没有它 | 缺失发生在明确的更新窗口内 |
| 本地配置与缓存 | 插件配置仍是 enabled，旧缓存文件仍在 | 不是简单的人工禁用或删除 |
| 恢复验证 | 从 Plugins 页面重新安装后，新开会话再次出现 `superpowers:*` | 问题在插件发现/注入层，重装可暂时恢复 |

这里的 `cli_version` 是 Codex App 会话元数据中的内嵌 agent/app-server runtime 版本，不代表用户在终端运行过 Codex CLI。它只用于给这次 App 更新前后的会话变化划定时间窗口。

## 真正的风险：流程会静默降级

插件页面的“已启用”不是充分证据。对 Superpowers 来说，真正需要确认的是：**当前新会话的技能列表里是否实际有 `superpowers:*` 条目。**

如果没有，表面上仍然可以继续提问、写代码和运行测试，但以下约束可能根本没有生效：

- 实现前的需求收敛、设计或计划流程。
- 测试驱动、验证完成前不宣称完成等检查。
- 收到代码审查意见后的“评估 → 修复有效项 → 验证 → 复审”闭环。

这类问题危险在于它通常不会报错。Agent 只会按普通默认行为继续工作，直到你发现它漏掉了原本应遵守的流程。

## 每次 App 更新后，做一次一分钟检查

不要只看插件页。完成 Codex App 更新后，新开一个本地会话，直接发送：

```text
开始任务前，请检查当前会话实际可用的技能。
如果已加载 Superpowers，请列出以 superpowers: 开头的技能名；
如果没有，请明确说明未加载，不要假装按该流程执行。
```

判断标准很简单：回答应给出实际存在的 `superpowers:*` 技能名。只说“插件已安装”“我会遵循 Superpowers”不够；如果它无法列出技能，先按未加载处理。

也建议把这个检查放在重要任务的第一步，尤其是涉及架构设计、批量修改、代码审查或发布前验证时。这样即使插件在某次更新后丢失，也能在开始之前发现，而不是在工作完成后才发现流程没有执行。

## 确认缺失后的处理顺序

1. 在 Codex App 的 Plugins 页面确认 Superpowers 是否仍显示已安装、已启用。
2. 完全退出并重新打开 Codex App，再新开一个会话复查技能；不要只在原会话里判断，因为技能通常在会话建立时注入。
3. 仍没有 `superpowers:*` 时，从 Plugins 页面重新安装或重新启用 Superpowers，然后再次新开会话验证。
4. 重装后恢复，记录这是临时 workaround；下次 App 更新后仍需要复查。

## 建议保留一条自己的更新后检查清单

对高度依赖插件工作流的项目，最实用的做法不是等问题出现，而是在每次 Codex App 更新后固定检查：

- App 是否能正常启动，Plugins 页面是否仍显示 Superpowers。
- 新会话是否实际列出 `superpowers:*`。
- 用一个很小的任务确认流程真的被调用，而不是只读取了插件状态。
- 一旦缺失，先重装、重开会话、复查；恢复后再开始正式任务。

插件缓存存在、配置显示启用，都只能说明“安装层可能还在”。只有技能真正出现在新会话上下文里，Superpowers 的流程约束才算真的生效。

## 参考

- [openai/codex#31365：Codex app upgrade loses Superpowers plugin installed state](https://github.com/openai/codex/issues/31365)
