---
layout: post
lang: zh-CN
title: "GitHub + Skillshare 跨机器同步实战：管理 Codex 全局 AGENTS.md 与 Agent Skills"
date: 2026-08-10 12:15:00 +0800
categories: [AI, 开发工具]
tags: [skillshare, github, codex, skills, agent, workflow]
series: [ai-agent]
series_order:
  ai-agent: 3
status:
  label: 当前可用
  verified: 2026-08-10
  environment: Skillshare CLI 0.20.25 / Git / Windows PowerShell / Codex AGENTS.md
  risk: 已复核当前 source、targets、AGENTS.md 部署和 Git 推送；空白新机器未在本次核验中完整重装，执行前应替换占位符并检查 dry-run、备份与远端范围。
---

我目前用一个 Git 仓库保存全局协作规则和个人 Agent Skills：GitHub 负责版本记录与跨机器传输，Skillshare 负责把 `skills/` 分发给多个 AI 工具，Codex 全局 `AGENTS.md` 则通过独立复制和哈希校验部署。三者职责分开，避免把 Git、配置部署和 Skills 同步混成一套隐式机制。

---

## 最终架构

公开文章中的路径均已改成占位符，实际使用时需要替换：

```text
GitHub repository: <my-skills-repo>
├── GLOBAL_AGENTS.md        # 个人全局规则的版本化权威源
├── skills/                 # Skillshare source
│   ├── skill-a/
│   ├── skill-b/
│   └── skillshare/
└── .gitignore

本机部署
├── <home>/.codex/AGENTS.md # Codex 实际读取的全局规则副本
├── Codex skills target     ─┐
├── Claude skills target    ├─ skillshare sync
└── 其他 skills targets     ─┘
```

这里存在三类不同的“权威”：

| 层级 | 权威内容 | 不负责什么 |
|---|---|---|
| Git 仓库 | `GLOBAL_AGENTS.md` 和 `skills/` 的版本历史 | 不自动部署文件，也不理解 target |
| Skillshare source | 当前应该分发的 Skills | 不自动决定 Codex 全局规则文件 |
| 项目仓库 | 项目级 `AGENTS.md`、构建与测试脚本 | 不应被无条件提升为个人全局规则 |

这个边界是整套方案最重要的部分。只要权威源不唯一，多机器同步迟早会退化成“哪个副本更新”的人工猜测。

## 为什么不直接同步各工具目录

直接把 `.codex/skills`、`.claude/skills` 或其他 target 放进网盘或 Git，短期看最省事，长期会遇到：

- 多个 target 出现同名但不同内容的 Skill；
- 工具自带文件、缓存和个人实验被一起提交；
- 删除链接目录时误伤真正的 source；
- 不知道某个 Skill 应该进入哪些工具；
- Git 冲突发生在生成副本，而不是权威源。

Skillshare 的作用不是“再复制一遍”，而是让 target 变成由 source 生成的部署结果。当前默认 `merge` 模式会逐 Skill 建立链接，并保留 target-local Skills；不能跟随链接的工具才单独使用 `copy`。

## 为什么 GLOBAL_AGENTS.md 不直接交给 Skillshare

Skillshare 已经支持 extras，可以同步 rules、commands 和 prompts。当前方案仍然把 `GLOBAL_AGENTS.md` 单独部署，原因很简单：

- 目前只有一个明确的 Codex 全局目标文件；
- 希望修改全局行为时显式确认，而不是顺带随所有 Skills 同步；
- 复制后做 SHA-256 对比，容易证明部署副本与权威源一致；
- Codex 的加载位置和 Skillshare target 是两个不同概念。

如果以后要同时维护 Claude rules、Cursor rules、commands、prompts 等多组文件，再迁移到 Skillshare extras 或专门的 dotfiles 工具更合理。当前规模下，显式部署比增加一层配置更容易审计。

## 把已有 Git 仓库接入 Skillshare

示例使用 Windows PowerShell。这里的前提是远端仓库已经存在，并包含 `GLOBAL_AGENTS.md` 与 `skills/`；如果从空仓库开始，应先在主机器创建这两个内容、完成第一次 Git 提交和推送，再执行下面的接入步骤。

clone 仓库后，让其中的 `skills/` 成为 Skillshare source：

```powershell
git clone <repository-url> <my-skills-repo>
Set-Location <my-skills-repo>

skillshare init --source <my-skills-repo>/skills --all-targets --no-copy --git --git-root root --no-skill
skillshare status
skillshare target list
```

几个参数的目的：

- `--source`：明确 `skills/` 是 source，而不是依赖默认目录。
- `--all-targets`：加入当前检测到的工具；共享机器或 CI 应改用 `--targets` 缩小范围。
- `--no-copy`：不把各 target 的现有文件自动回灌到 source。
- `--git-root root`：Git 根目录包含 `GLOBAL_AGENTS.md` 和 `skills/`，而不只跟踪 Skills 子目录。
- `--no-skill`：保留 Git 仓库中已经版本化的内置 Skillshare skill，不在恢复过程中按新机 CLI 版本改写 source。需要升级时，另行运行 `skillshare upgrade --skill`，审查 diff 后再提交。

已有 Skills 需要迁移时，先预览：

```powershell
skillshare collect --all --dry-run
```

只有确认属于个人长期维护集合的内容，才执行正式 collect。第三方 Skill 的首次获取与日后多机器同步也要分开理解：`install` 从上游获取，个人 Git 仓库保存筛选和维护后的结果。

## 部署 Codex 全局 AGENTS.md

[OpenAI Docs](https://learn.chatgpt.com/docs/agent-configuration/agents-md) 说明，Codex 默认读取 `<home>/.codex/AGENTS.md`，并在启动任务时把它与项目级规则组合。仓库根目录的 `GLOBAL_AGENTS.md` 只是本方案约定的权威源，Codex 不会自动加载它。

在仓库根目录执行下面的 PowerShell：

```powershell
$deployedAgents = Join-Path $env:USERPROFILE '.codex\AGENTS.md'
$deployedDirectory = Split-Path -Parent $deployedAgents

New-Item -ItemType Directory -Force -Path $deployedDirectory | Out-Null

if (Test-Path -LiteralPath $deployedAgents) {
  Copy-Item -LiteralPath $deployedAgents -Destination "$deployedAgents.bak" -Force
}

Copy-Item -LiteralPath '.\GLOBAL_AGENTS.md' -Destination $deployedAgents -Force

$sourceHash = (Get-FileHash -LiteralPath '.\GLOBAL_AGENTS.md' -Algorithm SHA256).Hash
$deployedHash = (Get-FileHash -LiteralPath $deployedAgents -Algorithm SHA256).Hash

if ($sourceHash -ne $deployedHash) {
  throw 'GLOBAL_AGENTS.md deployment verification failed.'
}
```

这个脚本只保留一份 `.bak`，适合当前的单文件部署。需要长期快照、机器差异模板或更多 dotfiles 时，应升级为独立部署脚本或 Chezmoi 一类工具，而不是继续扩张临时复制命令。

全局规则通常在新任务启动时读取。部署成功后，应新建 Codex 任务验证，不要假设正在运行的旧任务已经重新加载磁盘内容。

## 主机器的日常更新流程

修改前先确认工作树：

```powershell
Set-Location <my-skills-repo>
git status --short
```

如果存在本地修改，先确认范围并按后文的 checkpoint 流程处理。只有工作树干净时，才拉取远端：

```powershell
skillshare pull --dry-run
skillshare pull
skillshare status
```

如果只修改 `GLOBAL_AGENTS.md`：

1. 先修改仓库权威源。
2. 重新运行上面的部署与哈希校验。
3. 新建 Codex 任务确认规则已加载。
4. 提交和推送仓库。

如果修改、新增或删除 Skill：

```powershell
skillshare sync --dry-run
skillshare sync
skillshare doctor
skillshare audit
```

完成所有改动后，使用 Skillshare 的 Git 预检和推送：

```powershell
skillshare push --dry-run
skillshare push -m "Update shared agent configuration"
```

`push --dry-run` 用来确认即将提交的文件和提交信息。它不是授权扩大提交范围的理由；工作树中存在无关修改时，仍应先停下来区分范围。

## 另一台机器如何恢复

空白机器首次恢复：

```powershell
git clone <repository-url> <my-skills-repo>
Set-Location <my-skills-repo>

skillshare init --source <my-skills-repo>/skills --all-targets --no-copy --git --git-root root --no-skill
skillshare sync
skillshare doctor
skillshare status
```

个人 Skills 已随 `git clone` 恢复，不需要再用裸 `skillshare install` 重装。只有配置明确声明了未纳入 Git 的远程或 tracked 依赖时，才应按配置或明确 source 逐项执行 `install`。

然后执行 `GLOBAL_AGENTS.md` 的部署与哈希校验。`skillshare sync` 只负责 Skills；它不会因为仓库根目录存在 `GLOBAL_AGENTS.md` 就自动复制到 Codex home。

已经初始化过的机器，日常只需要：

```powershell
skillshare pull --dry-run
skillshare pull
skillshare status
```

如果远端提交同时修改了 `GLOBAL_AGENTS.md`，还要重新执行独立部署步骤。这是有意保留的显式操作，不是同步遗漏。

## 冲突、误删和恢复

### 本机有未提交内容

先建立本地 Git 检查点，不立即推送：

```powershell
skillshare commit --dry-run
skillshare commit -m "Checkpoint local changes"
skillshare pull
```

如果产生真实 Git 冲突，应在权威仓库中解决，检查 diff 后再 `skillshare sync`。不要在 target 生成副本里手工拼接冲突结果。

### 大范围同步或模式切换

```powershell
skillshare backup --dry-run
skillshare backup
skillshare sync --dry-run
```

backup 主要保护 target-local 内容；merge 模式的链接指向 source，本身可以由下一次 sync 重建。

### 误删 Skill

```powershell
skillshare trash restore <skill-name>
skillshare sync
```

`uninstall` 默认把 Skill 移入保留 7 天的 trash。不要对可能是链接的 target 目录执行递归删除；整目录 symlink 模式下，这类操作可能伤到 source。

## 公开仓库与隐私边界

这套方案是否使用公开 GitHub 仓库，取决于 `GLOBAL_AGENTS.md` 和 Skills 的内容。公开前至少检查：

- Token、密码、私有仓库地址和内部服务入口；
- 真实用户名、本机路径、设备名和 target 列表；
- 公司内部规则、客户信息和未公开工具；
- `.env`、日志、缓存、备份和本机 override；
- 只对当前机器生效的 `.skillignore.local`。

公开文章只需要解释架构和决策，不需要展示真实 source 路径、所有 target 名称或远端 URL。Git 能记录历史，也意味着误提交的敏感信息不会因为后续删除就自动从历史中消失。

## 为什么暂时不引入更多工具

当前方案只需要解决两类内容：

- 一个全局规则文件；
- 一组需要分发给多个 AI 工具的 Skills。

Git + 一次显式复制 + Skillshare 已经覆盖版本化、部署、target 分发、审计和恢复。现在引入 Chezmoi 会增加模板、机器差异和迁移成本，却没有解决新的实际问题。

如果以后还要同步 PowerShell profile、Git 配置、编辑器、SSH 客户端、Claude/Cursor rules 等大量 dotfiles，再把通用配置交给 Chezmoi、把 Skills 留给 Skillshare，会比继续扩张单文件脚本更清晰。

## 当前核验范围

2026 年 8 月 10 日，本机核验了以下范围：

- Skillshare CLI 与内置 Skill 均为 `v0.20.25`；
- 自定义 `skills/` source 存在，已配置 targets 处于同步状态；
- `GLOBAL_AGENTS.md` v2.4 与 Codex 部署副本内容一致；
- Skillshare 审计没有 CRITICAL 阻止项；
- Git 推送完成后，本地与远端保持同步。

本次没有在一台全新机器上重新执行完整安装，因此“空白机器恢复”部分依据当前 CLI 帮助、现有配置和已经使用的同步模型整理，不把它表述为本轮全新端到端复测。

## 参考资料

- [Skillshare 上手指南](/posts/skillshare-guide/)
- [AGENTS.md 配置指南](/posts/global-agents-context/)
- [Skillshare 官方文档](https://skillshare.runkids.cc/docs)
- [OpenAI Docs：Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
