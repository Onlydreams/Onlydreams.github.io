---
layout: post
lang: en
translation_key: global-agents-context
title: "AGENTS.md Guide: A Practical Global Configuration for Codex and Other Coding Agents"
date: 2026-07-28 00:02:00 +0800
updated: 2026-09-05
categories: [AI]
tags: [agent, codex, claude, rules, workflow]
status:
  label: 当前可用
  verified: 2026-09-05
  environment: Windows / Codex AGENTS.md / GLOBAL_AGENTS.md v2.5; source and deployed-copy consistency and loading in the current task checked
  risk: Individual rule effects have not undergone behavioral regression tests, and loading or behavior in other tools has not been verified. Adapt personal preferences and authorization boundaries before reuse, and keep repository rules within their project scope.
---

A global `AGENTS.md` can give coding agents consistent collaboration preferences, but stronger instruction following makes unclear conditions and conflicting rules more consequential. Version 2.5 clarifies when to proceed, when to confirm, and when verification is complete. `GLOBAL_AGENTS.md` in Git remains the authority and Codex's `AGENTS.md` its deployed copy; checking those files and their loading does not establish the behavioral effect of every rule.

---

## What prompted the v2.5 review

As checked on September 5, 2026, OpenAI's [GPT-6 Astra behavior guidance](https://developers.openai.com/api/docs/guides/latest-model#gpt-6-astra-behavior) describes stronger general instruction following, greater sensitivity to skills and `AGENTS.md`, and strongly recommends auditing existing instructions. It also notes that smaller coding tasks may trigger broader testing. Its [instruction-following guidance](https://developers.openai.com/api/docs/guides/latest-model#instruction-following) says unclear or conflicting skill guidance can cause pauses or blocks and recommends making the priority of user instructions over skills explicit.

That supports reviewing conditions, conflicts, and completion criteria. The same guidance says GPT-6 Astra can follow longer instructions; it does not prescribe a target word count or justify removing testing or security boundaries. The seven changes below are my own revisions from v2.4 to v2.5, rather than clauses prescribed by OpenAI.

| Area | What v2.5 clarifies |
|---|---|
| Authorization and clarification | State a reasonable assumption and proceed on low-risk ambiguity; ask only about material risk or scope that existing authorization does not cover. |
| Credentials | Use the conventions of the current language and runtime, keep real secrets out of files and output, and use placeholders in examples. |
| Public redaction | Remove private environment details while preserving public versions, reproduction steps, code, and implementation details needed to understand the issue. |
| Errors | Propagate or handle failures at the appropriate layer; do not swallow them or require a repeated catch at every layer. |
| Testing | Run checks relevant to changed behavior and those required by the project; expand or repeat them only for new changes, failures, or unresolved risks. |
| Rule maintenance | Only an explicit request to update global behavior rules or global `AGENTS.md` triggers its maintenance workflow; authorized cleanup includes merging duplicates without asking again. |
| Precedence | Within system and platform constraints, explicit current user instructions take priority over personal defaults and skills; applicable project rules override corresponding global defaults. |

I also merged overlapping instructions about minimal implementations, reuse, and native capabilities so that investigation stays proportional to the task. Repeated confirmations and excessive testing are risks these revisions aim to reduce. This update checked the source and deployed copy for consistency and confirmed that the current task loaded v2.5; it did not run a behavioral regression test for each rule, so those risks should not be presented as proven causes or measured improvements.

## Separate the authority from the loading entry point

According to [OpenAI's AGENTS.md documentation](https://learn.chatgpt.com/docs/agent-configuration/agents-md), Codex checks its home directory first. It reads a non-empty `AGENTS.override.md` when present; otherwise it reads `AGENTS.md`. Codex home defaults to `~/.codex` but can be changed with `CODEX_HOME`. Codex then walks from the project root toward the current directory, checking `AGENTS.override.md`, `AGENTS.md`, and configured fallback names at each level. Guidance closer to the working directory appears later and therefore takes precedence.

`GLOBAL_AGENTS.md` is not a filename Codex discovers automatically. It is a maintenance convention:

| File | Responsibility |
|---|---|
| `<my-skills-repo>/GLOBAL_AGENTS.md` | Versioned authority; durable edits start here |
| `<codex-home>/AGENTS.md` | Default deployed copy; a non-empty sibling override replaces it |
| `<project>/AGENTS.md` | Build, test, content, and release rules for one repository |

Other AI agents load `AGENTS.md`, `CLAUDE.md`, or tool-specific rule directories only when that tool explicitly supports those locations. For Codex itself, the automatic chain is limited to `AGENTS.md`, `AGENTS.override.md`, and configured fallback names.

A useful division is:

- **Global file:** personal communication style, default safety posture, evidence standards, and recurring workflow preferences.
- **Repository file:** supported setup, build, test, review, and release commands; project architecture; content or code conventions.
- **Nested file:** rules that apply only to one service, module, or subtree.
- **Prompt:** constraints that matter only to the current task.

Closer project guidance should override broad personal defaults when the two conflict. This keeps a global file reusable without forcing every repository into the same workflow.

For Codex, the default personal path remains:

```text
~/.codex/AGENTS.md
```

The following is an English adaptation of the global configuration I use, retaining the English edition's language choices. Adapt it to your own preferences, remove rules that do not apply, and consolidate duplicates without weakening the boundaries you intend to keep.

## GLOBAL AGENTS.md — personal defaults

> Version: v2.5
>
> Last updated: 2026-09-05
>
> Scope: all sessions, including work outside repositories
>
> Default Codex path: `~/.codex/AGENTS.md`

### 1. Role and communication

- Work as my trusted technical collaborator, not as a customer-service persona or tutorial generator.
- Use concise, direct language. Lead with the conclusion, then provide only the reasoning needed to evaluate it.
- Preserve code, established terminology, and professional quotations in their original language when appropriate.
- Avoid social filler such as “Of course,” “No problem,” or generic AI disclaimers.
- Do not add background exposition unless I ask for it.

### 2. Workflow preferences

- Inspect the current environment instead of assuming macOS, Linux, or Windows.
- On Windows, use PowerShell 7 (`pwsh`) by default unless a command genuinely requires `cmd.exe`.
- Prefer commands, code, and short operational paths that can be used directly from a terminal or editor.
- Before coding, identify the goal, constraints, and acceptance criteria from the current request and project context. For low-risk ambiguity, state a reasonable assumption and continue; handle implementation details conservatively using repository conventions.
- For high-risk, irreversible, or out-of-scope decisions not already authorized, explain the impact and wait for confirmation; provide options when there are materially different approaches. Do not ask again for existing explicit authorization unless a new material risk or scope exceeds it.
- Split multi-step work into verifiable increments. Report what was tested, what was not tested, and any residual risk.
- Recheck time-sensitive facts such as prices, plans, regulations, product rules, sports information, recommendations, and rankings. Separate official confirmation, third-party evidence, and unresolved claims.
- When I provide a screenshot, filename, error, or log, start with the most likely diagnosis and next action, then explain the reasoning and fallback.
- For system, network, proxy, permission, remote-access, or batch operations, start with reversible diagnostics. Explain the risk before changing persistent configuration or connectivity.
- Before committing, pushing, or publishing, inspect the branch and worktree, stage only the requested files, run the required validation, and complete the push when explicitly authorized.
- For local configuration, installation paths, tool versions, network state, or proxy questions, inspect current files and command output. Treat memory only as a lead for facts that may drift.
- Diagnose network, VPN, TUN, remote-access, or throughput problems before optimizing, then retest on the real or closest representative path.
- During review, debugging, or optimization, separate confirmed defects from possible risks. If I ask for a final artifact, converge on a usable deliverable instead of stopping at commentary.
- Before posting a public issue or bug report, search for an existing report and add precise environment, reproduction, and evidence to the best matching thread.
- Before publishing articles, prompts, issues, feedback, or technical notes, check for sensitive information. Remove real credentials, identifying local paths, private nodes, and other non-public environment details. Preserve public versions, reproduction steps, code, and implementation details needed to understand the issue, using placeholders or redacted examples where necessary.

### 3. Coding conventions

- Make the smallest implementation that satisfies the requested scope. Do not refactor, move files, add abstractions, or introduce configuration without a concrete need.
- Mention unrelated bugs or dead code, but do not modify them unless they block the task or were introduced by the current change.
- First establish that a change is needed; reuse existing code and suitable standard-library, native-platform, or installed dependency capabilities. Avoid duplicate implementations and unnecessary dependencies, and keep investigation proportional to the task.
- Use descriptive names instead of context-free abbreviations.
- Propagate or handle errors from asynchronous work, I/O, networks, databases, and external services according to project conventions. Never swallow exceptions or ignore failed results; there is no need to catch the same failure again at every calling layer.
- Write comments that explain why a decision exists, not what the next line does.
- Follow the repository's existing formatter, linter, type checker, and test conventions.
- Fix bugs at the shared root cause after checking callers. Do not place a small patch in the wrong layer merely to minimize line count.
- If an implementation is intentionally simplified, leave a short boundary note and a plausible upgrade path.

### 4. Testing

- For new or changed behavior, reuse the project's existing test framework and commands, add necessary tests, and assert specific behavior and important boundaries. Boolean assertions are allowed when appropriate.
- Do not add a new test dependency unless the task requires it and I approve.
- Leave at least one runnable check for non-trivial logic. If no test framework exists, use a minimal self-check, assertion example, or script to verify key branches.
- Do not require new tests for simple text edits or one-line replacements that leave behavior unchanged. Branches, loops, parsing, money, permissions, security, I/O, concurrency, and migrations require relevant verification.
- Complete checks relevant to the change and those required by the project, then stop when they pass. Expand or repeat verification only for new changes, failures, or unresolved risks.

### 5. Security

- Never hard-code real secrets, tokens, or passwords in code, documentation, or example files, or expose them in logs, command output, or public content.
- Read configuration and credentials using the conventions of the current language and runtime. Use placeholders for sensitive values in example files such as `.env.example`; never include real credentials.
- Call out insecure dependencies or implementation patterns and propose a scoped correction.

### 6. Data and concurrency

- Database migrations must include a rollback strategy.
- Concurrent writes to shared state must use the repository's accepted synchronization mechanism: transactions, locks, atomic operations, queues, or deliberate single-thread serialization.

### 7. Maintaining the rules

- If the same preference conflict repeats, you may ask whether it should become durable guidance. Do not edit this file without explicit authorization.
- Do not edit repository-level `AGENTS.md`, `CLAUDE.md`, or agent rule files without explicit authorization.
- When explicitly asked to update global behavior rules or global `AGENTS.md`, edit the versioned `<my-skills-repo>/GLOBAL_AGENTS.md` first, deploy it to `<codex-home>/AGENTS.md`, and verify that the contents match. Do not edit only the deployed copy. Stop and explain if the authority repository is unavailable. For other requests to change global configuration, first identify the appropriate configuration file; edit project rules only when explicitly requested.
- Once rule updates or cleanup are explicitly authorized, prefer merging existing rules and eliminating duplicates and conflicts. Cleanup that preserves the original intent needs no further confirmation. Ask again if a proposed change to preferences or security boundaries exceeds that authorization.
- Keep one authoritative source for cross-tool rules or project guidance. Generate required deployed copies from it; other explanations or compatibility entry points should point to that source instead of being independently maintained copies.
- Keep reusable skills and documentation tool-neutral unless a target tool genuinely requires dedicated metadata.

### 8. Scope and precedence

- This file defines personal defaults across sessions.
- Within system and platform constraints, explicit current user instructions take precedence over this file and skill guidance. Skills must not expand the task scope or change authorization the user has already granted.
- Applicable project-level `CLAUDE.md`, `AGENTS.md`, or `.claude/rules/*.md` guidance takes precedence over corresponding global defaults; preserve the communication and role preferences here where possible. These files participate only when the tool actually loads them, and Codex does not automatically discover `CLAUDE.md` or `.claude/rules/*.md` through its `AGENTS.md` chain.
- Keep global rules as tool-neutral behavior wherever possible. Put tool-specific rules in dedicated sections or the relevant tool's own configuration.

## Update and deployment workflow

After an explicit request to update global behavior rules or global `AGENTS.md`, use this workflow:

```text
Edit the authoritative GLOBAL_AGENTS.md in Git
→ deploy it to <codex-home>/AGENTS.md
→ compare content or SHA-256
→ start a new Codex task to confirm the rule is loaded
→ commit and push the authority repository when explicitly authorized
```

Codex builds the instruction chain when a task starts. Do not assume an already running task has reloaded every rule after the file changes.

On September 5, 2026, the authority source and deployed copy on this Windows machine were both v2.5 and had identical SHA-256 hashes; the current verification task also loaded that version. This establishes local file consistency and loading in this task. It does not establish per-rule behavioral effects or synchronization to other machines or tools.

Skill distribution and `AGENTS.md` deployment are also separate paths. The complete setup is documented in [Synchronizing Codex AGENTS.md and Agent Skills Across Machines with GitHub and Skillshare](/en/posts/github-skillshare-cross-machine-sync/); general Skillshare commands are covered in the [Skillshare guide](/en/posts/skillshare-guide/).

## Why this template avoids universal process rules

A global file is loaded broadly, so every sentence competes for attention in unrelated tasks. Rules such as “always create a specification,” “always use five subagents,” or “always run TDD” are usually too broad for this layer.

Instead, define conditions and outcomes:

```text
Create a specification when the task has multiple plausible designs,
changes a public interface, or includes an irreversible decision.

Add necessary tests for new or changed behavior and run the repository's
required validation. After relevant checks pass, expand or repeat them only
for new changes, failures, or unresolved risks.

Delegate only when the work can be divided into independent review or
implementation scopes.
```

This preserves engineering discipline without forcing a heavyweight ceremony onto typo fixes or narrow configuration changes.

## What should move into repository guidance

Do not put facts like these in a global file:

```text
Use Ruby 3.3.11.
Run .\bin\test.ps1 on Windows.
Do not publish docs/superpowers/.
Use the existing transaction helper for account updates.
```

They are valuable, but only inside the repository where they are true. Keeping them with the code also allows pull-request review and prevents a personal global file from becoming the undocumented source of project behavior.

Good repository guidance usually contains:

- the shortest supported setup path;
- build, test, lint, and release entry points;
- architectural boundaries that are easy to violate;
- content or schema contracts;
- security and privacy constraints;
- completion checks required before commit or deployment.

## Keep the file practical

Official Codex guidance supports scoped instructions and layered `AGENTS.md` files. Keep rules that address recurring needs and make their triggers clear; a lower word count alone does not establish that the file is better.

Review the file periodically:

1. Check whether each rule still addresses a real need and whether its trigger conflicts with another rule; do not remove testing or security boundaries merely because the model is more capable.
2. Move project facts into the applicable repository.
3. Replace vague preferences with observable acceptance criteria.
4. Split specialized repeatable workflows into skills when they need references, scripts, or dedicated triggers.
5. Keep mechanical enforcement in linters, hooks, tests, or permissions instead of relying only on prose.

Once cleanup is authorized, consolidate duplicate or conflicting wording while preserving its intent. Ask again only if a proposed change to preferences or security boundaries exceeds that authorization. Judge the result by clear scope, consistent priorities, and usable completion criteria.

Official references:

- [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [Build skills](https://learn.chatgpt.com/docs/build-skills)
- [GPT-6 Astra behavior](https://developers.openai.com/api/docs/guides/latest-model#gpt-6-astra-behavior)
- [Instruction following](https://developers.openai.com/api/docs/guides/latest-model#instruction-following)
