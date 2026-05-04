---
layout: post
title: "Skillshare 上手指南：统一管理 AI 工具与 Agent 技能"
date: 2026-05-04 19:00:00 +0800
categories: [AI, 效率, 工具]
tags: [skillshare, skills, agent, cli, claude, codex]
---

记录 [Skillshare](https://skillshare.runkids.cc/docs) 的安装、初始化、同步和跨设备使用方式，用一个源目录统一管理 AI CLI、编码助手和 Agent 的 skills。

---

## 目标

Skillshare 适合解决一个问题：不同 AI 工具和 Agent 各自维护 skills 目录，手动复制容易混乱，也不方便在多台电脑之间同步。

通过 Skillshare，可以把所有 skills 放到一个源目录，再同步到不同 AI 工具、Agent 或 CLI 的目标目录：

- 单机使用：修改一次，执行 `skillshare sync` 同步到所有已配置目标。
- 多机使用：通过远端 Git 仓库执行 `skillshare push` / `skillshare pull`。
- 第三方 skills：安装前可用 `skillshare audit` 做安全扫描。

## 安装

### MacOS / Linux

使用安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
```

也可以通过 Homebrew 安装：

```bash
brew install runkids/tap/skillshare
```

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/runkids/skillshare/main/install.ps1 | iex
```

### 升级

```bash
skillshare upgrade
```

## 初始化

在终端执行：

```bash
skillshare init
```

初始化会完成三件事：

- 创建 skills 源目录：`~/.config/skillshare/skills/`
- 检测本机已安装的 AI 工具、Agent 或 CLI
- 生成 Skillshare 配置文件：`config.yaml`

初始化完成后，可以先查看当前状态：

```bash
skillshare status
skillshare target list
```

## 添加 Skill

### 收集已有 Skill

如果本机的 Claude Code、OpenClaw、Codex 或其他 Agent 工具里已经有 skills，可以先统一收集到 Skillshare 源目录：

```bash
skillshare collect --all
```

### 从 GitHub 安装

```bash
skillshare install github.com/<用户名>/<仓库名>
skillshare sync
```

安装第三方仓库前，建议先做一次安全扫描：

```bash
skillshare audit
```

### 新建自己的 Skill

```bash
skillshare new my-skill
```

命令会在源目录中生成一个新的 skill 目录，并创建 `SKILL.md` 模板。编辑完成后执行同步：

```bash
skillshare sync
```

## 同步机制

修改、新增或删除 skill 后，执行：

```bash
skillshare sync
```

默认同步方式是软链接：各 AI 工具或 Agent 的 skills 目录指向 Skillshare 的源目录。Windows 下会使用 NTFS junctions。

如果软链接在某些环境中不可用，例如 Docker、受限文件系统或同步盘目录，可以切换为 copy 模式：

```bash
skillshare target claude --mode copy
skillshare sync
```

## 常用命令

| 命令 | 作用 |
|---|---|
| `skillshare status` | 查看当前状态 |
| `skillshare list` | 查看已安装的 skills |
| `skillshare target list` | 查看已配置同步目标 |
| `skillshare sync` | 同步到所有目标 |
| `skillshare update --all` | 更新所有 skill 仓库 |
| `skillshare uninstall <name>` | 卸载指定 skill |
| `skillshare enable <name>` | 启用指定 skill |
| `skillshare disable <name>` | 禁用指定 skill |
| `skillshare audit` | 执行安全扫描 |
| `skillshare ui` | 打开 Web 管理面板 |

## 跨机器同步

多台电脑共用一套 skills 时，可以给 Skillshare 源目录绑定一个 Git 远端仓库。

### 1. 创建远端仓库

在 GitHub、Gitee 或自建 Git 服务中创建一个空仓库，复制仓库 URL。

HTTPS 和 SSH 地址都可以，认证由本机 Git 配置处理。

### 2. 绑定远端

```bash
skillshare init --remote <仓库URL>
```

如果已经执行过 `skillshare init`，这条命令会绑定远端，不会重置已有源目录。

### 3. 推送本机更新

第一台电脑改完 skill 后执行：

```bash
skillshare push -m "更新说明"
```

### 4. 拉取远端更新

第二台电脑执行：

```bash
skillshare pull
```

`skillshare pull` 会先拉取远端仓库，再执行 `skillshare sync`。

## 冲突处理

如果拉取时报本机有未提交改动，可以先提交并推送本机更新：

```bash
skillshare push -m "本机更新"
skillshare pull
```

也可以手动暂存当前改动：

```bash
cd ~/.config/skillshare/skills
git stash
skillshare pull
git stash pop
```

如果提示远端有新提交，先拉再推：

```bash
skillshare pull
skillshare push -m "同步更新"
```

如果出现真实文件冲突，进入源目录手动解决冲突后提交：

```bash
cd ~/.config/skillshare/skills
git add .
git commit -m "merge skills"
skillshare sync
```

## 使用建议

- 单机使用时，记住 `skillshare sync` 即可。
- 多机使用时，围绕 `skillshare push` 和 `skillshare pull` 建立习惯。
- 安装第三方 skills 前，先运行 `skillshare audit`。
- 修改 target 同步模式后，再执行一次 `skillshare sync`。

官方文档：[https://skillshare.runkids.cc/docs](https://skillshare.runkids.cc/docs)
