---
layout: post
lang: zh-CN
translation_key: skillshare-guide
title: "Skillshare 上手指南：统一管理 Claude、Codex 等 AI Agent Skills"
date: 2026-05-04 19:00:00 +0800
updated: 2026-08-10
categories: [AI, 开发工具]
tags: [skillshare, skills, agent, cli, claude, codex]
series: [ai-agent]
series_order:
  ai-agent: 1
status:
  label: 当前可用
  verified: 2026-08-10
  environment: Skillshare CLI 0.20.25 / Windows PowerShell / Claude / Codex Skills
  risk: 会修改本地 skills 源目录和已配置 targets；迁移、覆盖或删除前应先检查 dry-run、目标列表和恢复方案。
---

[Skillshare](https://skillshare.runkids.cc/docs) 用一个源目录管理 Codex、Claude、Cursor 等工具使用的 Agent Skills。本文介绍安装、初始化、安全迁移、同步模式和 Git 跨机器同步；完整的个人配置方案另见 [GitHub + Skillshare 跨机器同步实战](/posts/github-skillshare-cross-machine-sync/)。

---

## Skillshare 解决什么问题

不同 AI CLI 和编码工具通常各自维护一个 skills 目录。直接复制同一个 Skill，时间久了会出现三个问题：

- 不清楚哪一份才是权威源；
- 同名 Skill 在不同工具中逐渐漂移；
- 换电脑后要重新安装和核对每一份文件。

Skillshare 把日常数据流固定为单向同步：

```text
Skillshare source
    ├── skill-a/
    ├── skill-b/
    └── skill-c/
          ↓ skillshare sync
Claude / Codex / Cursor / 其他 targets
```

源目录是唯一应该长期维护的副本。各 target 根据配置使用逐 Skill 链接、整目录链接或真实文件副本。

## 安装与升级

### macOS / Linux

使用官方安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
```

也可以通过 Homebrew 安装：

```bash
brew install skillshare
```

Homebrew 版本可能比直接安装脚本晚几天发布。

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/runkids/skillshare/main/install.ps1 | iex
```

### 升级并检查版本

```bash
skillshare upgrade --dry-run
skillshare upgrade
skillshare --version
```

2026 年 8 月 10 日核验时，当前 CLI 与内置 Skillshare skill 均为 `v0.20.25`。工具仍在快速迭代，具体参数应以本机 `skillshare <command> --help` 为准。

## 初始化 source 与 targets

交互式初始化：

```bash
skillshare init
```

初始化流程会选择源目录、检测已安装的 AI 工具、配置 targets，并询问是否安装 Skillshare 自带的调用 Skill。

默认全局目录因平台而异：

| 平台 | 配置和 source 位置 |
|---|---|
| macOS / Linux | `~/.config/skillshare/` |
| Windows | `%AppData%\skillshare\` |

完成后先检查，不要立即覆盖已有目录：

```bash
skillshare status
skillshare target list
skillshare doctor
```

无人值守环境应显式传入目标和迁移策略，例如：

```bash
skillshare init --all-targets --no-copy --git --skill
```

`--no-copy` 表示不把 target 中的现有 Skills 自动回收进 source。CI、devcontainer 或共享机器上，通常还应使用 `--targets` 只选择需要的工具。

## 安全迁移已有 Skills

如果 Skills 原先散落在 Claude、Codex 或其他 target 中，可以在首次迁移时收集一次。先预览：

```bash
skillshare collect --all --dry-run
```

确认范围后再去掉 `--dry-run`。不要收集：

- 工具自带的默认 Skills；
- 缓存和生成文件；
- 只应留在单个工具中的实验内容；
- source 中已经存在的旧副本。

`collect` 是迁移和恢复操作，不是日常双向同步。初始化完成后，正常方向应保持为 source → targets。

## 安装或新建 Skill

### 从 Git 仓库安装

```bash
skillshare install github.com/<owner>/<repository>
skillshare sync
```

`install` 会自动执行安全审计，默认在出现 CRITICAL 发现时阻止安装。`--force` 会绕过阻止条件，`--skip-audit` 会完全跳过扫描；只有在看懂发现并接受风险时才应使用。

也可以单独审计当前 source：

```bash
skillshare audit
```

从上游安装与跨机器同步是两件事：`install` 负责把第三方 Skill 纳入自己的 source，Git 与 `push` / `pull` 负责同步已经筛选和维护的个人集合。

### 新建自己的 Skill

```bash
skillshare new my-skill
skillshare sync
```

命令会生成新的 Skill 目录和 `SKILL.md` 模板。编辑应发生在 source，而不是 target 里的生成副本。

## 理解三种同步模式

每个 target 都可以独立选择模式：

| 模式 | 行为 | target-local Skills |
|---|---|---|
| `merge` | 默认模式，为每个 Skill 创建链接 | 保留 |
| `copy` | 复制真实文件，并用 manifest 跟踪托管内容 | 保留 |
| `symlink` | 整个 target 目录链接到 source | 无法保留 |

Windows 上的链接可使用 NTFS junction，不需要把所有 target 都切成 copy。如果某个工具、容器或受限文件系统不能跟随链接，只修改该 target：

```bash
skillshare target claude --mode copy
skillshare sync
```

copy 模式中的 source 修改要等下一次 `sync` 才会出现在 target。不要在 target 中长期编辑托管副本，否则下次同步可能覆盖它。

切换模式或批量同步前可以预览：

```bash
skillshare sync --dry-run
skillshare sync
```

## 常用命令

| 命令 | 作用 |
|---|---|
| `skillshare status` | 查看 source、targets、同步状态和版本 |
| `skillshare list` | 查看已安装、启用或禁用的 Skills |
| `skillshare target list` | 查看 targets 与同步模式 |
| `skillshare diff` | 比较 source 与 targets |
| `skillshare sync` | 把 source 分发到 targets |
| `skillshare check` | 检查上游更新和元数据问题 |
| `skillshare update --all` | 更新所有可更新 Skills |
| `skillshare commit` | 创建本地 Git 检查点，不推送 |
| `skillshare push` | 提交并推送全局 source |
| `skillshare pull` | 拉取远端并同步 targets |
| `skillshare backup` | 备份 target-local 内容 |
| `skillshare uninstall <name>` | 把 Skill 移入 7 天 trash |
| `skillshare trash restore <name>` | 从 trash 恢复 Skill |
| `skillshare audit` | 执行安全扫描 |
| `skillshare doctor` | 检查配置、链接和同步漂移 |
| `skillshare ui` | 打开本地 Web 管理面板 |

安装、更新、卸载、collect 或修改 target 后，都应再运行一次 `skillshare sync`。

## 用 Git 跨机器同步

全局 source 可以绑定 Git 远端：

```bash
skillshare init --remote <repository-url>
```

主机器修改完成后，先检查同步与推送范围：

```bash
skillshare sync --dry-run
skillshare sync
skillshare doctor
skillshare push --dry-run
skillshare push -m "Update shared skills"
```

另一台机器执行：

```bash
skillshare pull --dry-run
skillshare pull
skillshare status
```

`pull` 会从 Git 远端更新 source，然后同步已配置 targets。它不会替代其他工具的任意配置部署；例如 Codex 全局 `AGENTS.md` 是否同步，取决于你是否另外配置了 Skillshare extras 或独立部署流程。

## 冲突与恢复

本机有未提交变更时，可以先建立只保存在本地的检查点：

```bash
skillshare commit --dry-run
skillshare commit -m "Checkpoint local changes"
skillshare pull
```

如果 Git 报真实内容冲突，应进入 source 所在仓库，确认双方变更后手动解决，再执行：

```bash
skillshare sync
skillshare doctor
```

执行大范围模式切换或清理前，可以备份 target-local 内容：

```bash
skillshare backup --dry-run
skillshare backup
skillshare backup --list
```

merge 模式中的链接指向 source，本身不会被重复备份；Skillshare 主要保存 target-local 内容。删除 Skill 应使用 `uninstall`，不要对链接目录直接执行递归删除。

## 使用边界

- Skillshare source 是 Skills 的权威源，不要继续维护多份 target 副本。
- GitHub 等 Git 远端负责版本记录与跨机器传输，不负责决定哪些工具加载哪些 Skill。
- Skillshare 负责分发、筛选、审计和恢复，不等于通用 dotfiles 管理器。
- 单个全局配置可以继续使用明确的复制与哈希校验；需要管理大量 rules、commands 或 prompts 时，再考虑 Skillshare extras。
- 项目级 Skills 和 `AGENTS.md` 应随项目仓库维护，不要无条件提升到个人全局范围。

## 参考资料

- [Skillshare 官方文档](https://skillshare.runkids.cc/docs)
- [Skillshare First Sync](https://skillshare.runkids.cc/docs/getting-started/first-sync/)
- [GitHub + Skillshare 跨机器同步实战](/posts/github-skillshare-cross-machine-sync/)
