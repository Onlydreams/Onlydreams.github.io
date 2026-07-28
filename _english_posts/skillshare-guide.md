---
layout: post
lang: en
translation_key: skillshare-guide
title: "Skillshare Guide: Manage AI Agent Skills Across Claude, Codex, and Other Tools"
date: 2026-07-28 00:01:00 +0800
categories: [AI, Developer Tools]
tags: [skillshare, skills, agent, cli, claude, codex]
status:
  label: 当前可用
  verified: 2026-07-28
  environment: Skillshare CLI 0.20.21 / Claude / Codex Skills
  risk: Skillshare changes local skill directories and synchronization targets. Review the target list, sync mode, and recovery plan before mutating an existing setup.
---

[Skillshare](https://skillshare.runkids.cc/docs) turns one source directory into the source of truth for skills used by Codex, Claude, Cursor, and other AI tools. This guide covers installation, first-time setup, safe migration, synchronization, and multi-machine use.

---

## What problem Skillshare solves

AI coding tools usually keep skills in different directories. Copying the same skill into each directory creates three recurring problems:

- edits drift between tools;
- it becomes unclear which copy is authoritative;
- moving to a second computer requires another manual installation pass.

Skillshare replaces those copies with a one-way model:

```text
source directory
    ├── skill-a/
    ├── skill-b/
    └── skill-c/
          ↓ skillshare sync
Claude / Codex / Cursor / other configured targets
```

The source directory remains authoritative. Targets receive symlinks, junctions, or copied files according to their configured sync mode.

This model supports three common workflows:

- **One computer:** edit once, then run `skillshare sync`.
- **Multiple computers:** store the source in Git and use `skillshare push` and `skillshare pull`.
- **Third-party skills:** install through Skillshare and inspect them with its built-in security audit.

## Install and update the CLI

### macOS and Linux

Install with the official script:

```bash
curl -fsSL https://raw.githubusercontent.com/runkids/skillshare/main/install.sh | sh
```

Homebrew is also supported:

```bash
brew install skillshare
```

The Homebrew package can lag behind the direct installer. Use the installed CLI's help output when a flag differs from this guide.

### Windows PowerShell

```powershell
irm https://raw.githubusercontent.com/runkids/skillshare/main/install.ps1 | iex
```

### Upgrade

```bash
skillshare upgrade
```

During this article's verification, the local CLI was `0.20.21` and reported `0.20.22` as available. Skillshare evolves quickly, so treat `skillshare <command> --help` as the command-level source of truth for your installed version.

## Initialize the source and targets

For an interactive setup, run:

```bash
skillshare init
```

The initialization flow creates the configuration and source directories, detects installed AI tools, and asks which targets to manage. On macOS and Linux, the default global source is:

```text
~/.config/skillshare/skills/
```

After initialization, inspect the result:

```bash
skillshare status
skillshare target list
```

Do not skip this check on an existing machine. A target list is operational configuration: it determines which directories a later sync may change.

For unattended environments, pass explicit flags instead of relying on prompts. A typical global setup is:

```bash
skillshare init \
  --all-targets \
  --no-copy \
  --no-skill
```

Choose targets more narrowly in CI, devcontainers, or shared environments.

## Migrate existing skills without reversing the source of truth

If you already maintain skills inside Claude, Codex, or another tool, you may want to collect them into Skillshare once. Preview the migration first:

```bash
skillshare collect --all --dry-run
```

Only remove `--dry-run` after confirming that the discovered files genuinely belong in the shared source.

Avoid collecting:

- built-in skills shipped by a tool;
- caches or generated files;
- target-local experiments that should remain private to one tool;
- stale copies of skills already present in the source.

`collect` is a migration and recovery operation, not the normal direction of daily synchronization. After setup, the intended flow is source to targets.

## Install or create skills

### Install from a Git repository

```bash
skillshare install github.com/<owner>/<repository>
skillshare sync
```

Skillshare runs a security audit during installation. Critical findings can block the operation. Review findings before deciding whether an override is justified.

You can also audit the current source directly:

```bash
skillshare audit
```

### Create your own skill

```bash
skillshare new my-skill
```

The command scaffolds a skill directory and `SKILL.md`. Edit the new skill in the source directory, then synchronize it:

```bash
skillshare sync
```

## Understand sync modes

Run synchronization after adding, updating, removing, enabling, disabling, or retargeting skills:

```bash
skillshare sync
```

Current Skillshare documentation distinguishes three modes:

| Mode | Behavior | Suitable for |
|---|---|---|
| `merge` | Creates per-skill links while preserving target-local skills | Most personal setups |
| `symlink` | Replaces the whole target directory with one link | Fully managed targets |
| `copy` | Writes real files on each sync | Containers, restricted filesystems, or tools that cannot follow links |

On Windows, linked targets can use NTFS junctions. If a target cannot use links, switch only that target to copy mode:

```bash
skillshare target claude --mode copy
skillshare sync
```

Copy mode introduces a delay: source edits do not reach the target until the next sync. It also makes target-local edits easier to lose, which is another reason to keep the source authoritative.

## Commands worth remembering

| Command | Purpose |
|---|---|
| `skillshare status` | Inspect the source, targets, sync state, audit policy, and version |
| `skillshare list` | List discovered skills |
| `skillshare target list` | Inspect configured targets |
| `skillshare sync` | Apply the source to targets |
| `skillshare check` | Check tracked skills for updates |
| `skillshare update --all` | Update all tracked skill repositories |
| `skillshare uninstall <name>` | Move a skill to Skillshare trash |
| `skillshare enable <name>` | Restore a disabled skill to synchronization |
| `skillshare disable <name>` | Exclude a skill from synchronization |
| `skillshare audit` | Run the security audit |
| `skillshare doctor` | Diagnose configuration and target problems |
| `skillshare ui` | Open the local web dashboard |

After a mutation, run `skillshare sync` unless the command documentation explicitly states otherwise.

## Synchronize across computers

Skillshare can bind the source to a Git remote. Create an empty repository on GitHub, Gitee, or another Git host, then initialize with its URL:

```bash
skillshare init --remote <repository-url>
```

On the first computer, publish an intentional checkpoint:

```bash
skillshare push -m "Update shared skills"
```

On another computer:

```bash
skillshare pull
```

`pull` updates the source and then synchronizes configured targets.

If the local source contains uncommitted work, preserve it before pulling. One option is to checkpoint it:

```bash
skillshare push -m "Save local skill changes"
skillshare pull
```

For a manual Git workflow:

```bash
cd ~/.config/skillshare/skills
git stash
skillshare pull
git stash pop
```

Resolve real merge conflicts in the source repository, commit the resolution, and then run:

```bash
skillshare sync
```

## A safe operating routine

For a stable setup, keep the routine small:

1. Treat the Skillshare source as the only editable copy.
2. Run `skillshare status` before changing targets or migrating existing files.
3. Preview collection and broad synchronization changes with `--dry-run` where supported.
4. Audit third-party skills before trusting them with tools or data.
5. Run `skillshare sync` after source or target changes.
6. Use Git checkpoints before risky migrations or cross-machine merges.
7. Use `skillshare doctor` when targets disappear or links become inconsistent.

The essential idea is not the command list. It is maintaining a clear direction of ownership: one reviewed source, many generated targets.

Official documentation: [Skillshare docs](https://skillshare.runkids.cc/docs)
