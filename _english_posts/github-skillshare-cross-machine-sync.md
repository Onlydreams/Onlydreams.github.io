---
layout: post
lang: en
translation_key: github-skillshare-cross-machine-sync
title: "Synchronize Codex AGENTS.md and Agent Skills Across Machines with GitHub and Skillshare"
date: 2026-08-10 23:59:00 +0800
categories: [AI, Developer Tools]
tags: [skillshare, github, codex, skills, agent, workflow]
status:
  label: 当前可用
  verified: 2026-08-11
  environment: Windows Skillshare CLI/skill 0.20.25 / macOS CLI 0.20.24 + skill 0.20.25 / Git / zsh / PowerShell 7 / Codex AGENTS.md
  risk: Existing-machine synchronization, Windows junction recovery after re-cloning, AGENTS.md deployment, and Git transport were verified. A clean-machine installation and Linux recovery were not rerun end to end; replace placeholders and inspect dry-run, backup, and remote scope before applying changes.
---

I use one Git repository to maintain personal Agent Skills and global collaboration rules. GitHub provides version history and transport, Skillshare distributes `skills/` to AI tools, and Codex global `AGENTS.md` is deployed separately with an explicit content check. Keeping these responsibilities separate prevents Git transport, configuration deployment, and skill synchronization from becoming one opaque mechanism.

---

## Final architecture

All paths in this article are placeholders:

```text
Git repository: <my-skills-repo>
├── GLOBAL_AGENTS.md        # versioned authority for personal global rules
├── skills/                 # Skillshare source
│   ├── skill-a/
│   ├── skill-b/
│   └── skillshare/
└── .gitignore

Local deployment
├── <codex-home>/AGENTS.md  # global rules loaded by Codex by default
├── Codex skills target     ─┐
├── Claude skills target    ├─ skillshare sync
└── other skills targets    ─┘
```

The setup has three distinct authorities:

| Layer | Authoritative content | What it does not do |
|---|---|---|
| Git repository | History of `GLOBAL_AGENTS.md` and `skills/` | It does not deploy files or understand targets |
| Skillshare source | Skills that should be distributed now | It does not choose the Codex global rules file |
| Project repository | Project `AGENTS.md`, build, and test behavior | It should not become personal global policy automatically |

If more than one copy claims authority, cross-machine synchronization eventually becomes a manual guess about which copy is newer.

## Why not synchronize every tool directory directly

Putting `.codex/skills`, `.claude/skills`, or another target directly in cloud storage or Git looks simple but creates long-term problems:

- same-named skills drift between tools;
- built-in files, caches, and experiments enter version control;
- deleting a linked target can damage the real source;
- the repository cannot express which skill belongs in which tool;
- Git conflicts happen in generated deployments instead of the authority.

Skillshare makes targets deployment results generated from the source. Its default `merge` mode links individual skills while preserving target-local skills. Use `copy` only for a target that cannot follow links.

## Why GLOBAL_AGENTS.md is deployed separately

Skillshare extras can synchronize rules, commands, and prompts. I still deploy one `GLOBAL_AGENTS.md` explicitly because:

- there is currently one clear Codex global destination;
- a global behavior change should be a deliberate action, not a side effect of every skill sync;
- a byte comparison or SHA-256 check proves that authority and deployed copy match;
- Codex loading paths and Skillshare targets are different concepts.

If the managed set grows to include Claude rules, commands, prompts, and multiple editor configurations, Skillshare extras or a dedicated dotfiles manager may become justified. For one file, explicit deployment remains easier to audit.

## Connect an existing Git repository to Skillshare

This article calls the device that edits and publishes the authoritative source the **authority machine**. It is a workflow role, not a particular operating system. Except for the file-deployment snippets, the Git and Skillshare commands work in `zsh`, `bash`, and PowerShell 7.

Assume the remote repository already contains `GLOBAL_AGENTS.md` and `skills/`. If it is empty, create those contents and publish the first Git commit before connecting Skillshare.

```text
git clone "<repository-url>" "<my-skills-repo>"
cd "<my-skills-repo>"

skillshare init --source "<my-skills-repo>/skills" --targets "codex,claude" --no-copy --git --git-root root --no-skill
skillshare status
skillshare target list
skillshare doctor
```

The flags have specific purposes:

- `--source` makes the repository's `skills/` directory explicit.
- `--targets` limits distribution to tools this machine actually uses.
- `--no-copy` prevents existing target contents from being imported into the source automatically.
- `--git-root root` keeps `GLOBAL_AGENTS.md` and `skills/` in the same Git root.
- `--no-skill` preserves the already versioned Skillshare calling skill instead of rewriting the source according to the new machine's CLI version.

Use `--all-targets` only after reviewing every detected tool. If a runtime discovers the same skills through multiple target paths, choose one intentional route instead of treating the warning as harmless by default.

For a one-time migration from an existing target, preview one target at a time:

```text
skillshare collect <target> --dry-run
```

Do not routinely collect built-in or target-local skills. Third-party installation and personal cross-machine synchronization are separate: `install` imports from upstream; your Git repository carries the reviewed result.

## Deploy Codex global AGENTS.md

[OpenAI's AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md) states that Codex uses `~/.codex` as Codex home unless `CODEX_HOME` is set. A non-empty `AGENTS.override.md` in that directory replaces the sibling `AGENTS.md`. The repository's `GLOBAL_AGENTS.md` is only this workflow's authority convention; Codex does not discover that filename automatically.

### macOS and Linux

Run from the repository root in `bash` or `zsh`:

```bash
codex_home="${CODEX_HOME:-${HOME}/.codex}"
deployed_agents="${codex_home}/AGENTS.md"

if ! mkdir -p "${codex_home}"; then
  printf '%s\n' 'Cannot create Codex home.' >&2
  exit 1
fi

if [ -f "${deployed_agents}" ]; then
  if ! cp "${deployed_agents}" "${deployed_agents}.bak"; then
    printf '%s\n' 'Cannot back up the deployed AGENTS.md.' >&2
    exit 1
  fi
fi

if ! cp ./GLOBAL_AGENTS.md "${deployed_agents}"; then
  printf '%s\n' 'Cannot deploy GLOBAL_AGENTS.md.' >&2
  exit 1
fi

if ! cmp -s ./GLOBAL_AGENTS.md "${deployed_agents}"; then
  printf '%s\n' 'GLOBAL_AGENTS.md deployment verification failed.' >&2
  exit 1
fi
```

### Windows PowerShell 7

Run from the repository root:

```powershell
$codexHome = if ($env:CODEX_HOME) {
  $env:CODEX_HOME
} else {
  Join-Path $env:USERPROFILE '.codex'
}
$deployedAgents = Join-Path $codexHome 'AGENTS.md'
$deployedDirectory = Split-Path -Parent $deployedAgents

New-Item -ItemType Directory -Force -Path $deployedDirectory -ErrorAction Stop | Out-Null

if (Test-Path -LiteralPath $deployedAgents) {
  Copy-Item -LiteralPath $deployedAgents -Destination "$deployedAgents.bak" -Force -ErrorAction Stop
}

Copy-Item -LiteralPath '.\GLOBAL_AGENTS.md' -Destination $deployedAgents -Force -ErrorAction Stop

$sourceHash = (Get-FileHash -LiteralPath '.\GLOBAL_AGENTS.md' -Algorithm SHA256).Hash
$deployedHash = (Get-FileHash -LiteralPath $deployedAgents -Algorithm SHA256).Hash

if ($sourceHash -ne $deployedHash) {
  throw 'GLOBAL_AGENTS.md deployment verification failed.'
}
```

Both snippets keep one `.bak`. The POSIX version compares bytes; PowerShell compares SHA-256. Start a new Codex task after deployment because the instruction chain is normally built when a task starts.

## Daily workflow on the authority machine

Check the worktree before pulling:

```text
cd "<my-skills-repo>"
git status --short
```

Only pull when the worktree is clean. Otherwise, inspect scope and use the checkpoint workflow below.

```text
skillshare pull --dry-run
skillshare pull
skillshare status
```

When only `GLOBAL_AGENTS.md` changes:

1. Edit the repository authority.
2. Repeat deployment and content verification.
3. Start a new Codex task to confirm the rule is loaded.
4. Commit and push the repository.

When a skill changes:

```text
skillshare sync --dry-run
skillshare sync
skillshare doctor
skillshare audit
```

Preview Git scope before publishing:

```text
skillshare push --dry-run
skillshare push -m "Update shared agent configuration"
```

Dry-run output does not authorize unrelated files. Separate unrelated work before publishing.

## Restore or synchronize another machine

For an initial restore:

```text
git clone "<repository-url>" "<my-skills-repo>"
cd "<my-skills-repo>"

skillshare init --source "<my-skills-repo>/skills" --targets "codex,claude" --no-copy --git --git-root root --no-skill
skillshare sync
skillshare doctor
skillshare status
```

Personal skills already arrived through `git clone`; do not reinstall them with a source-less `skillshare install`. Only rehydrate remote or tracked dependencies that the configuration explicitly declares outside Git.

Then deploy `GLOBAL_AGENTS.md` separately. `skillshare sync` manages skills; it does not copy a repository-root rules file into Codex home automatically.

For a machine that is already initialized:

```text
skillshare pull --dry-run
skillshare pull
skillshare status
```

Redeploy `GLOBAL_AGENTS.md` when the remote commit changes it.

### Check old Windows junctions after re-cloning

Deleting and re-cloning the source repository can leave NTFS junctions in targets. Do not treat a visible skill name or an apparently healthy target as proof that the junction destination exists. An observed failure fingerprint was:

- skill names remained visible in target directories;
- `status` still recognized the source and targets;
- source additions and removals were not reflected in targets;
- `doctor` did not report the stale junctions, while direct `LinkTarget` checks showed missing destinations.

Compare and preview first:

```text
skillshare status --json
skillshare diff --json
skillshare doctor --json
skillshare sync --dry-run
```

After confirming that dry-run only removes stale links, adds current source skills, and preserves merge-mode target-local content:

```text
skillshare sync
skillshare diff --json
```

In merge mode, `diff --json` may still list a target-local skill. When that item's `is_sync` value is `false`, it is not a synchronization action Skillshare intends to execute. Combine `status`, `doctor`, and direct link checks instead of deleting local content merely because the output contains the word `remove`.

PowerShell 7 can verify junction destinations across configured targets directly:

```powershell
$skillshareStatus = skillshare status --json | ConvertFrom-Json -ErrorAction Stop

$brokenJunctions = foreach ($configuredTarget in $skillshareStatus.targets) {
  Get-ChildItem -LiteralPath $configuredTarget.path -Force -ErrorAction Stop |
    Where-Object { $_.LinkType } |
    Where-Object {
      -not (Test-Path -LiteralPath $_.LinkTarget -PathType Container)
    } |
    Select-Object @{ Name = 'Target'; Expression = { $configuredTarget.name } }, Name, LinkTarget
}

$brokenJunctions
```

No output means every junction enumerated by this command has an existing directory target. It does not audit contents or verify copy mode.

In one Windows verification on August 11, 2026, direct inspection found 14 stale junctions plus six source skills that had not reached the targets. `sync --dry-run` correctly previewed cleanup and relinking; after `sync`, all 105 junctions tested valid. This is evidence for that version and environment, not a claim that every Skillshare release misses the same condition.

## Conflicts, removals, and recovery

### Local uncommitted work

Create a local checkpoint without pushing it immediately:

```text
skillshare commit --dry-run
skillshare commit -m "Checkpoint local changes"
skillshare pull
```

Resolve real Git conflicts in the source repository, inspect the diff, and then run `skillshare sync`. Do not merge conflicts inside generated targets.

### Broad synchronization or mode changes

```text
skillshare backup --dry-run
skillshare backup
skillshare sync --dry-run
```

Backups primarily protect target-local content. Merge-mode links point to the source and can be rebuilt.

### Accidental removal

```text
skillshare trash restore <skill-name>
skillshare sync
```

`uninstall` moves a skill to trash for seven days by default. Do not recursively delete target directories that may be links.

## Public repository and privacy boundary

Before making the authority repository public, inspect at least:

- tokens, passwords, private repository URLs, and internal service endpoints;
- real usernames, machine paths, device names, and unnecessary target inventories;
- company rules, customer data, and unpublished tooling;
- `.env`, logs, caches, backups, and machine-only overrides;
- `.skillignore.local`, which may encode local exceptions.

Git preserves history. Removing a secret in a later commit does not remove it from earlier history automatically.

## Why this setup stops here

This workflow manages two things: one global rule file and a set of skills distributed to AI tools. Git, one explicit copy, and Skillshare already cover versioning, deployment, target distribution, audit, and recovery.

If the scope grows to include shell profiles, Git configuration, editor settings, SSH clients, and many tool-specific rule sets, a dotfiles manager such as Chezmoi may become appropriate. Keep Skills in Skillshare and move general machine configuration to the tool designed for it.

## Verification scope

As of August 11, 2026:

- Windows used Skillshare CLI and bundled skill `0.20.25`; macOS used CLI `0.20.24` and skill `0.20.25`.
- The custom source existed and configured targets were synchronized.
- `GLOBAL_AGENTS.md` v2.4 matched the deployed Codex copy.
- The current audit threshold had no CRITICAL blocker; that does not imply zero lower-severity findings.
- Git remained synchronized after publishing.
- Windows recovery after deleting and re-cloning the source was rerun with dry-run, sync, and direct junction destination checks.

The macOS `zsh` flow, Windows PowerShell 7 flow, and existing-machine recovery were verified. No completely clean macOS, Linux, or Windows installation was rerun end to end, so the blank-machine and Linux steps remain bounded by current CLI help, configuration, and cross-shell command semantics.

## References

- [Skillshare guide](/en/posts/skillshare-guide/)
- [AGENTS.md guide](/en/posts/global-agents-context/)
- [Skillshare documentation](https://skillshare.runkids.cc/docs)
- [OpenAI Docs: Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
