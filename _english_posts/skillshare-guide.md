---
layout: post
lang: en
translation_key: skillshare-guide
title: "Skillshare Guide: Manage AI Agent Skills Across Claude, Codex, and Other Tools"
date: 2026-07-28 00:01:00 +0800
updated: 2026-08-11
categories: [AI, Developer Tools]
tags: [skillshare, skills, agent, cli, claude, codex]
status:
  label: 当前可用
  verified: 2026-08-11
  environment: Windows Skillshare CLI/skill 0.20.25 / macOS CLI 0.20.24 + skill 0.20.25 / zsh / PowerShell 7 / Claude / Codex Skills
  risk: Skillshare changes local skill directories and configured targets. Review dry-run output, target scope, sync mode, and recovery options before migrations, overwrites, or removals.
---

[Skillshare](https://skillshare.runkids.cc/docs) uses one source directory to manage Agent Skills consumed by Codex, Claude, and other AI tools. This guide covers installation, initialization, safe migration, sync modes, and Git-based multi-machine synchronization. For a complete personal setup, see [Synchronizing Codex AGENTS.md and Agent Skills Across Machines with GitHub and Skillshare](/en/posts/github-skillshare-cross-machine-sync/).

---

## What problem Skillshare solves

AI coding tools usually keep skills in different directories. Copying the same skill into each directory creates recurring problems:

- it becomes unclear which copy is authoritative;
- same-named skills drift between tools;
- moving to another computer requires another manual installation and verification pass.

Skillshare fixes the daily data flow in one direction:

```text
Skillshare source
    ├── skill-a/
    ├── skill-b/
    └── skill-c/
          ↓ skillshare sync
Claude / Codex / other configured targets
```

The source directory is the only copy intended for long-term maintenance. Each target receives per-skill links, a whole-directory link, or real file copies according to its configured mode.

## Install and upgrade

### macOS and Linux

Use the official installer:

```bash
curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
```

Homebrew is also supported:

```bash
brew install skillshare
```

The Homebrew package may lag behind the direct installer by a few days.

### Windows PowerShell 7

```powershell
irm https://raw.githubusercontent.com/runkids/skillshare/main/install.ps1 | iex
```

### Upgrade and verify versions

```text
skillshare upgrade --dry-run
skillshare upgrade
skillshare --version
```

As of August 11, 2026, the Windows environment used for this guide had CLI and bundled Skillshare skill `0.20.25`; the macOS environment had CLI `0.20.24` and skill `0.20.25`. The CLI and skill versions do not need to match, and skill metadata is not a substitute for `skillshare --version`. Skillshare evolves quickly, so use `skillshare --version` and `skillshare <command> --help` as the local source of truth.

Except for the platform-specific installation commands above, the Git and Skillshare commands below work in `zsh`, `bash`, and PowerShell 7. Their code blocks use `text` to avoid implying a required shell.

## Initialize the source and targets

For interactive setup:

```text
skillshare init
```

Initialization selects the source directory, detects installed AI tools, configures targets, and asks whether to install Skillshare's own calling skill.

Default global locations differ by platform:

| Platform | Configuration and source |
|---|---|
| macOS / Linux | `~/.config/skillshare/` |
| Windows | `%AppData%\skillshare\` |

Inspect the result before overwriting any existing directory:

```text
skillshare status
skillshare target list
skillshare doctor
```

For unattended setup, make both the target list and migration policy explicit:

```text
skillshare init --targets "codex,claude" --no-copy --git --skill
```

`--no-copy` prevents target contents from being imported automatically into the source. Replace the target list with the tools the machine actually uses. Only use `--all-targets` after reviewing every detected tool. If `skillshare doctor` reports that one runtime discovers the same skills through multiple target paths, keep one intentional distribution route instead of ignoring the overlap.

## Migrate existing skills safely

If skills already live in Claude, Codex, or another target, you may collect them once during migration. Preview one target first:

```text
skillshare collect <target> --dry-run
```

Remove `--dry-run` only after reviewing the scope. Use `--all` only for a deliberate, reviewed one-time migration. Do not collect:

- built-in skills shipped by a tool;
- caches or generated files;
- target-local experiments that should remain private to one tool;
- stale copies of skills already present in the source.

`collect` is a migration and recovery operation, not the normal direction of daily synchronization. After setup, the intended flow remains source to targets. Do not routinely collect built-in or target-local skills from Codex, Claude, or other tools.

## Install or create a skill

### Install from a Git repository

```text
skillshare install github.com/<owner>/<repository>
skillshare sync
```

Skillshare runs a security audit during installation. CRITICAL findings block the operation by default, but the absence of a CRITICAL blocker does not mean the audit is clean: HIGH and MEDIUM findings still require review. `--force` overrides the block and `--skip-audit` skips scanning, so use either only after understanding the findings and accepting the risk.

You can audit the current source separately:

```text
skillshare audit
```

Installing from upstream and synchronizing across your own computers are separate operations. `install` imports a third-party skill into your source; Git plus `push` and `pull` distribute the reviewed personal collection.

### Create your own skill

```text
skillshare new my-skill
skillshare sync
```

The command creates a skill directory and `SKILL.md` template. Edit the new skill in the source directory, not in a generated target.

## Understand the three sync modes

Each target can select its own mode:

| Mode | Behavior | Target-local skills |
|---|---|---|
| `merge` | Creates one link per managed skill | Preserved |
| `copy` | Writes real files tracked by a manifest | Preserved |
| `symlink` | Links the whole target directory to the source | Cannot be preserved |

On Windows, linked targets can use NTFS junctions; you do not need to switch every target to copy mode. If one tool, container, or restricted filesystem cannot follow links, change only that target:

```text
skillshare target claude --mode copy
skillshare sync
```

Copy mode means source edits reach the target only after the next sync. Do not maintain managed copies inside targets, because a later sync may overwrite them.

Preview broad synchronization or mode changes first:

```text
skillshare sync --dry-run
skillshare sync
```

## Commands worth remembering

| Command | Purpose |
|---|---|
| `skillshare status` | Inspect source, targets, sync state, and version |
| `skillshare list` | List installed, enabled, or disabled skills |
| `skillshare target list` | Inspect targets and modes |
| `skillshare diff` | Compare source and targets |
| `skillshare sync` | Distribute source to targets |
| `skillshare check` | Check upstream updates and metadata |
| `skillshare update --all` | Update all updatable skills |
| `skillshare commit` | Create a local Git checkpoint without pushing |
| `skillshare push` | Commit and push the global source |
| `skillshare pull` | Pull the remote and synchronize targets |
| `skillshare backup` | Back up target-local content |
| `skillshare uninstall <name>` | Move a skill to the seven-day trash |
| `skillshare trash restore <name>` | Restore a skill from trash |
| `skillshare audit` | Run the security audit |
| `skillshare doctor` | Diagnose configuration, links, and sync drift |
| `skillshare ui` | Open the local web dashboard |

Run `skillshare sync` after installing, updating, uninstalling, collecting, or changing targets.

## Synchronize across computers with Git

The global source can be connected to a Git remote:

```text
skillshare init --remote <repository-url>
```

On the machine responsible for the authoritative source, inspect synchronization and push scope first:

```text
skillshare sync --dry-run
skillshare sync
skillshare doctor
skillshare push --dry-run
skillshare push -m "Update shared skills"
```

On another computer:

```text
skillshare pull --dry-run
skillshare pull
skillshare status
```

`pull` updates the source and then synchronizes configured targets. It does not deploy unrelated tool configuration such as Codex global `AGENTS.md` unless that file has its own Skillshare extras or deployment workflow.

## Conflicts and recovery

If the local source contains uncommitted work, create a local checkpoint without pushing it immediately:

```text
skillshare commit --dry-run
skillshare commit -m "Checkpoint local changes"
skillshare pull
```

Resolve real Git conflicts in the source repository, inspect the result, and then run:

```text
skillshare sync
skillshare doctor
```

Before a broad mode change or cleanup, back up target-local content:

```text
skillshare backup --dry-run
skillshare backup
skillshare backup --list
```

In merge mode, links point to the source and can be rebuilt by the next sync. Use `uninstall` for removals; do not recursively delete directories that may be links.

If you delete and re-clone the source repository, run `status`, `diff`, and `sync --dry-run` before trusting existing targets. In one Windows `0.20.25` verification, `doctor` did not surface stale NTFS junctions, while direct inspection of their `LinkTarget` values found links to the removed source. A normal `sync` cleaned the stale links and distributed the new skills. In merge mode, a target-local item may still appear in JSON diff output with `is_sync: false`; that is not a managed removal. The full commands and evidence limits are in the [cross-machine workflow](/en/posts/github-skillshare-cross-machine-sync/#check-old-windows-junctions-after-re-cloning).

## Operating boundaries

- Treat the Skillshare source as the authoritative copy; do not maintain independent target copies.
- Use a Git remote for version history and transport, not for deciding which tools load which skills.
- Use Skillshare for distribution, filtering, audit, and recovery; it is not a general-purpose dotfiles manager.
- Deploy one global configuration file explicitly with a content or hash check. Consider Skillshare extras only when rules, commands, and prompts become a larger managed set.
- Keep project-level skills and `AGENTS.md` files in their project repositories instead of promoting them to global defaults.

## References

- [Skillshare documentation](https://skillshare.runkids.cc/docs)
- [Skillshare First Sync](https://skillshare.runkids.cc/docs/getting-started/first-sync/)
- [Cross-machine GitHub + Skillshare workflow](/en/posts/github-skillshare-cross-machine-sync/)
