---
layout: post
lang: en
translation_key: agent-skills-after-model-upgrade
title: "How to Use Agent Skills After a Model Upgrade: Replace Generic Process with Specialized Constraints"
date: 2026-07-28 00:03:00 +0800
categories: [AI, Developer Tools]
tags: [codex, skills, agent, workflow, prompt]
status:
  label: 当前可用
  verified: 2026-07-15
  environment: Codex CLI 0.144.4 / gpt-5.6-sol (low) / Agent Skills
  risk: Official documentation was rechecked on 2026-07-28; explicit and implicit invocation routing was last tested in isolation on 2026-07-15. Community trends remain observational, and no controlled quality or token-usage A/B test was run against Superpowers.
---

As coding models become more capable, I no longer treat a larger skills directory as a more complete setup. Generic planning can often stay with the model; a skill should remain when it contributes knowledge, tools, boundaries, or acceptance criteria the model would not otherwise have.

---

## The real question is not whether skills are obsolete

Recent debate around workflow-heavy packages such as Superpowers and GSD often frames the choice as “use skills” versus “trust the model.” That is too coarse.

These packages may require an agent to brainstorm, write a specification, split a plan, execute TDD, delegate to subagents, perform multiple reviews, and run final verification. When models were weaker at maintaining a long execution loop, external scaffolding could materially improve discipline. As models gain stronger planning, debugging, testing, and tool-use capabilities, the same workflow can also duplicate work the model already performs.

The discussion I reviewed fell into three broad positions:

- Some users removed generic workflow packages because native planning was sufficient and the extra orchestration increased latency, interaction, or usage.
- Some kept selected components for complex work—such as TDD, specification review, or parallel execution—but stopped applying the entire pipeline to every task.
- Others argued that the problem was not skills themselves, but descriptions that matched too broadly and workflows that had not been adapted to the repository.

There is a visible tendency in both Chinese and English communities to narrow generic skills and use explicit invocation more often. This is an observation, not a representative survey or an official benchmark. Higher token use can also come from reasoning effort, task complexity, subagent count, caching, or product changes.

The defensible conclusion is narrower: one universal methodology no longer needs to govern every task. It does not follow that skills have stopped being useful.

## Understand when a skill consumes context

Official OpenAI documentation describes a progressive-disclosure model. Codex begins with each skill's name, description, and path. It loads the full `SKILL.md` only after selecting that skill.

The initial skills list uses at most 2% of the model's context window, or 8,000 characters when the window size is unknown. When many skills are installed, Codex first shortens descriptions and may eventually omit entries with a warning.

That means “many installed skills” is not automatically the main cost. Larger overhead usually comes from what happens after matching:

- A description is broad enough to trigger on ordinary work.
- The selected skill loads long instructions and reference material.
- The workflow forces extra specifications, reviews, delegation, or confirmation rounds.
- Multiple skills impose overlapping process rules.

The optimization target should be false-positive activation and unproductive steps after activation—not an indiscriminate deletion of the skills directory.

## Ask what information the skill adds

I now classify a skill by the capability it contributes:

| Skill type | Default decision | Why |
|---|---|---|
| Generic planning, mandatory multi-agent execution, or fixed review pipelines | Narrow or make explicit | Most likely to overlap with stronger native agent behavior |
| Long methodology with no repository or domain facts | Compress; remove if no repeatable benefit appears | Often behaves like a duplicated prompt |
| Domain knowledge, evidence rules, and a fixed output contract | Keep, with sources and expiry conditions | The model cannot guarantee current or specialized facts |
| Private APIs, MCP servers, browsers, or internal data | Keep and scope tightly | Real tools, permissions, and failure handling are required |
| Repository build, test, and release workflow | Put in project-level guidance or a repository skill | The facts only apply to that codebase |
| Deployment, migration, or bulk-edit workflow | Keep approval points, rollback, and completion evidence | Risk should not depend on improvised judgment |
| Deterministic scripts for repeatable results | Keep when determinism is genuinely required | A reviewed script is more stable than regenerated commands |

The first candidates for revision are descriptions like this:

```yaml
description: Use for coding, debugging, planning, testing, or reviewing tasks.
```

That sentence covers nearly every development request. Even if the skill was intended for a small set of complex tasks, the host has little basis for deciding when *not* to use it.

Before uninstalling such a skill:

1. Remove generic steps the model already performs reliably.
2. Add explicit trigger and exclusion conditions.
3. Move it from user scope to the repository where its facts are true.
4. Require explicit invocation if it is expensive or high-impact.
5. Disable or uninstall it only if no observable benefit remains.

## A concrete portfolio decision

The [`worldcup-predictor`](/en/posts/worldcup-predictor-skill-development-retrospective/) skill is still worth keeping. It does not merely say “plan before answering.” It defines evidence layers, market-baseline handling, knockout-stage output, discipline risk, live-match state updates, and post-match calibration. Those rules are specialized and can change with data sources and tournament context.

This blog repository's Ruby version, test entry points, article metadata, series order, and publication checks belong in its repository `AGENTS.md` and executable scripts. Copying them into a global development skill would expand the skill's trigger scope while separating the rules from the code they govern.

A generic process package can be invoked only when the task has multiple plausible designs, changes a public interface, or includes an irreversible decision. A narrow edit does not automatically need a brainstorming document, a specification, TDD, several subagents, and repeated review stages.

That is a scope decision, not a completed usage A/B test.

## Replace process control with outcome constraints

A workflow-heavy instruction often prescribes the performance of every step:

```text
Run brainstorming, write a specification, split it into 20 tasks,
use TDD for every task, and finish with five subagent reviews.
```

A stronger and more durable instruction defines the conditions and required evidence:

```text
Create a specification only when the request has multiple plausible designs,
changes a public interface, or includes an irreversible decision.

New non-trivial behavior must be covered by the existing test system.
Before completion, run the repository's required validation and list anything
that was not verified.

Delegate only when the review or implementation scope can be divided
independently.
```

The second version does not require the model to demonstrate a ritual. It says when extra process becomes necessary and what evidence must exist at the end. Those constraints remain useful after another model upgrade.

## Tighten invocation

Implicit invocation depends on the skill's `description`, so the first sentence should state the narrowest important use case. Include explicit exclusions:

```yaml
---
name: release-check
description: Use only when preparing a production release for this repository. Verify the release checklist, migration rollback, version metadata, and deployment evidence. Do not use for ordinary development builds or local previews.
---
```

If a skill is expensive, contains external side effects, or only applies to rare tasks, Codex supports disabling implicit invocation in `agents/openai.yaml`:

```yaml
policy:
  allow_implicit_invocation: false
```

The default is `true`. With the setting disabled, explicit `$release-check` invocation remains available.

On July 15, 2026, I ran an isolated routing check with Codex CLI `0.144.4`, `gpt-5.6-sol`, and low reasoning effort. A probe skill with implicit invocation disabled was not loaded by a normal prompt containing its trigger words, while an explicit `$skill` invocation loaded it correctly. This verifies routing behavior only; it does not show that any large workflow is faster, cheaper, or higher quality.

Scope should also be narrow:

- use a personal skill only when it applies across repositories;
- put repository workflows in `.agents/skills` or repository guidance;
- keep module-specific rules close to that module.

This reduces irrelevant candidates and lets specialized rules evolve with the code.

## An executable skill-reduction method

Do not uninstall everything based on one frustrating session. Use a repeatable audit:

1. List the skills actually used during the last month. If complete logs are unavailable, choose a representative set of reproducible tasks.
2. Label the primary value of each skill: domain knowledge, tool access, repository fact, safety boundary, deterministic script, or generic process.
3. Remove instructions that duplicate stable model behavior and add no project facts.
4. Rewrite `description` with clear positive and negative triggers.
5. Move low-frequency, expensive, or high-impact skills to explicit invocation.
6. Run the same representative tasks with the same model and reasoning effort, both with and without the skill.

At minimum, record:

- whether the task completed;
- how many human corrections were needed;
- elapsed time;
- unnecessary steps;
- missed acceptance criteria;
- any reliable usage data the product exposes.

A single success or failure is weak evidence. The useful question is whether the skill repeatedly reduces mistakes and human intervention.

After the comparison, ask:

1. Without the skill, would the model lose important facts, tools, risk boundaries, or acceptance criteria?
2. Does the skill trigger only in the situations where that value matters?
3. Is the quality improvement larger than the added latency, usage, and maintenance?

If all three answers are no, remove it. If the value is real but activation is broad, narrow the scope or require explicit invocation.

Model upgrades should trigger a review of the parts that overlap with native capabilities. Domain facts, live tool access, and safety boundaries still need deliberate maintenance.

Official reference: [Build skills](https://learn.chatgpt.com/docs/build-skills)
