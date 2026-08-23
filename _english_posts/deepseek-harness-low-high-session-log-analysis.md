---
layout: post
lang: en
translation_key: deepseek-harness-low-high-session-log-analysis
title: "Why DeepSeek Harness Code Reviews Get Slower: Session-Log Diagnosis and a Low vs. High A/B Test"
date: 2026-08-23 14:21:00 +0800
categories: [AI, Developer Tools]
tags: [deepseek, agent, harness, debugging, review, performance]
status:
  label: 当前可用
  verified: 2026-08-20
  environment: Windows / DeepSeek Harness Web GUI / DeepSeek-V4-Pro / Low and High reasoning effort / session JSONL
  risk: The conclusions come from two abnormal session logs and one controlled Low-versus-High run. They locate the delay in this case, but they are not a general model-performance benchmark. The Low log has a stale session.createdAt value, so the experiment order relies on the operation record and relative turn times.
---

Why would a tightly scoped code review run for more than ten minutes and require a manual stop? Instead of continuing to guess from the UI that “the model is slow” or “the tool is stuck,” I decomposed exported DeepSeek Harness session JSONL and then ran the same prompt in the same workspace with Low and High reasoning effort. In this comparison, High logged 2.27 times as many reasoning characters and took almost twice as long, but found no issue that Low missed.

---

## The short answer

It would be inaccurate to reduce this incident to either “the DeepSeek model is bad” or “the harness has a bug.” The more defensible causal chain is:

1. High explored more reasoning branches and repeated more checks.
2. The harness gave it broad limits: `reasoningEffort: high`, `maxTokens: 256000`, and `contextWindow: 1000000`.
3. An ordinary review had no hard wall-clock, tool-call, or convergence guardrail.
4. One delegated subagent also received a prompt that expanded the original task into a comprehensive audit.

Local tools were not the main bottleneck. In the clearest 686.93-second turn, 19 tool calls consumed only about 3.65 seconds in total. Most elapsed time occurred between tool calls: model generation, provider/adapter work, request scheduling, and streaming.

The controlled A/B test also suggests a practical default: Low was sufficient for this everyday diff review. High's extra time did not produce an extra confirmed finding.

## Symptom: why did a small task never finish?

Two different logs initially raised the alarm.

The first covered an adversarial Userscript review and a follow-up fix. The user had already identified a specific P2 issue: when an initial six-second deadline expired, a connected but uncommitted root was not locked and could still attempt takeover. The turn ran from 22:26:02 to 22:37:29—686.93 seconds—before the user stopped it.

Its tools were fast:

- the first step lasted 347.62 seconds, while the final `grep` took 51 ms;
- another step lasted 136.69 seconds, while its final `read` took 21 ms;
- all 19 tool calls totaled about 3.65 seconds;
- the log contained roughly 224,000 reasoning characters;
- there was no chain of tool-error retries.

That rules out explanations such as “PowerShell ran for ten minutes” or “the sandbox kept retrying.” The delay was on the reasoning and request path.

The second log came from a delegated subagent reviewing changes to a technical article. It ran for 617.74 seconds and made 47 tool calls. Tools consumed about 81.91 seconds; roughly 535.83 seconds remained outside tool execution. The user stopped that run too.

But it would be unfair to blame only the subagent. Its upstream delegation prompt had already expanded the work into nine A–I review groups, including:

- byte-level escaping and line breaks in an embedded script;
- cross-version Jekyll, Liquid, and kramdown compatibility;
- Chinese/English numbers, dates, versions, and claim consistency;
- generated HTML, CI, SEO, privacy, and security;
- residual GitHub Pages risks and “anything else.”

It explicitly demanded a deep examination of every item. Some divergence came from the model; some came from the upstream agent enlarging the assignment.

## Do not trust a model's explanation of itself

When asked why it behaved this way, the model answered that the model—not the harness—was the problem. That statement is another generated claim, not a diagnosis. It must be checked against the event timeline.

The logs establish that:

- tool execution was fast;
- most elapsed time was outside tools;
- both requests used DeepSeek-V4-Pro with High reasoning;
- High allowed very long reasoning and output;
- the harness did not force convergence after the issue was confirmed and tests had passed.

A better formulation is: the direct delay occurred along the model/request path, while harness configuration, context management, delegation scope, and stopping rules determined how long that behavior could continue.

## Distinguishing model-path time from tool time in JSONL

Do not treat the first and last timestamps in an entire session file as task duration. A session may include long periods when the user is idle. Measure each `turn/start` through its corresponding `turn/end`.

Useful events include:

| Event | What it tells you |
| --- | --- |
| `request/header` | Model, reasoning level, and token limit |
| `request/context` | Provider, model, and context window |
| `turn/start` / `turn/end` | Active wall time and termination reason |
| `step/start` / `step/end` | Which step became unusually long |
| `tool/call` / `tool/result` | Tool name, arguments, and execution interval |
| `assistant/message` | Final text and aggregated reasoning blocks |
| `agent/inbox/spliced` | Whether a user message was queued, replaced, or used to interrupt |

This PowerShell snippet calculates basic metrics for a single-turn session. Replace the path with your exported JSONL file:

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

`ReasoningCharacters` is the amount of logged text, not a token count or a direct measure of compute. `NonToolSeconds` is not all model time either; it includes provider, adapter, queue, and streaming overhead. Still, when tools occupy less than four seconds of a 687-second turn, the local command runner is clearly not the bottleneck.

Parallel tools can overlap, so summing every tool interval may slightly overcount execution time. Tool time is tiny relative to wall time in these samples, so that does not change the directional conclusion.

## Designing the Low-versus-High comparison

Two abnormal High sessions cannot separate intrinsic model behavior from amplification caused by the reasoning setting. I therefore ran a controlled comparison.

Both runs used:

- the same repository and branch;
- the same nine uncommitted files;
- the same `774 insertions / 114 deletions`;
- identical hashes for the primary script and documentation diff outputs;
- the same review prompt;
- the same `maxTokens: 256000` and `contextWindow: 1000000`;
- no network access and no file edits.

The prompt constrained scope and termination: inspect only the diff, direct call chain, and relevant tests, then report immediately instead of exploring adjacent issues. The Low prompt ended with one extra period; that was the only textual difference and not a meaningful experimental variable.

The Low file's `session.createdAt` was stale and cannot establish order. The actual operation sequence was Low followed by High, and all statistics use relative timestamps inside each turn.

## Results: High took almost twice as long

| Metric | Low | High | High / Low |
| --- | ---: | ---: | ---: |
| Active wall time | 229.58 s | 441.21 s | 1.92× |
| Time to first tool | 3.07 s | 2.85 s | Nearly identical |
| Tool execution time | 6.48 s | 6.00 s | Nearly identical |
| Non-tool time | 223.10 s | 435.22 s | 1.95× |
| Reasoning characters | 43,346 | 98,241 | 2.27× |
| Steps | 18 | 28 | 1.56× |
| Tool calls | 24 | 29 | 1.21× |
| File reads | 11 | 13 | 1.18× |
| Web searches | 0 | 0 | Identical |
| End reason | completed | completed | Identical |
| Confirmed findings | One low-severity issue | The same issue | No additional finding |
| Test result | 112 passed | 112 passed | Identical |

Both made their first tool call in about three seconds, so High did not materially delay startup. The difference accumulated while interpreting code, choosing paths to inspect, and composing conclusions.

Tool calls increased only from 24 to 29, which is not runaway growth. The expansion occurred mainly between calls: High logged 2.27 times as much reasoning and added about 212 seconds of non-tool time.

## Did more reasoning improve the review?

Both runs found exactly the same issue: an obsolete comment in `updateSettings` still said that historical scanning was retained during initial startup, even though the current version had removed all historical script scanning. It was a low-severity maintenance issue with no runtime effect.

Both also completed the same relevant checks:

- production paths no longer wrapped BGM fetch/XHR;
- historical script scanning was removed;
- mutation, DTO fan-out, and traversal time had explicit budgets;
- aggregate `node --test` failed because the sandbox returned `spawn EPERM`;
- running test files in-process produced 112 passes;
- real SPA stability still required Chrome plus Tampermonkey validation.

High found no functional issue missed by Low. Its final report was shorter, listing two residual risks, while Low listed three and retained more direct-call-chain context.

High did calibrate the verdict slightly better: it returned `pass`, whereas Low said `conditional pass`. Because the only finding was a non-blocking comment, `pass` was more natural. That small improvement was not worth another three minutes and 32 seconds.

The experiment supports four bounded findings:

1. High's delay did not come from slower tools.
2. Its inspection scope was not materially different.
3. It performed more steps and substantially more logged reasoning.
4. The additional reasoning did not produce an additional useful finding.

## Why a shorter final answer can still cost more

High's final response was about 1,300 characters; Low's was about 2,400. Yet High took almost twice as long. Final response length is therefore a poor proxy for agent cost.

Time can be spent on:

- planning before a tool call;
- checking multiple branches after a result;
- reconfirming the same conclusion from another angle;
- deciding whether more context should be read;
- compressing many intermediate judgments into a short answer.

If a product displays only “thinking” and a tool list, users can easily blame the shell, network, or file reads. Useful harness observability should separate at least model/provider time, tool execution, and queue/scheduling time.

## Recommendations for harness design and use

### Default routine reviews to Low

This single test cannot prove that Low is always superior, but it does show that ordinary diff reviews should not default unconditionally to High.

- Routine reviews, writing changes, and tightly scoped fixes: Low.
- Concurrency, state machines, data migrations, permission boundaries, or difficult performance failures: switch to High when there is a reason.
- Max: reserve it for an explicit benefit hypothesis, not as a generic “be more careful” switch.

### Give every turn a stopping budget

A token ceiling is not a stopping policy. A harness also needs:

- a soft wall-clock limit, such as three to five minutes for a routine review;
- a tool budget, perhaps 12–20 calls;
- repeated-validation detection;
- convergence toward confirmed findings and residual risks near the budget;
- no command-level revalidation once both code and tests already establish a conclusion.

A budget should not abruptly truncate a high-risk task. It should trigger a convergence check: have acceptance criteria been met, and could further exploration change the verdict?

### Preserve scope when delegating

A subagent prompt should inherit the user's boundaries rather than silently upgrade “review this article” into a byte-level, SEO, security, cross-version, and CI audit.

Delegation should preserve:

- the original goal;
- explicit exclusions;
- the acceptable evidence layer;
- stopping conditions;
- whether network access is allowed;
- whether the task is review-only or permits edits.

If a comprehensive audit is justified, the upstream agent should say why the scope is expanding.

### Make interruption and queues visible

In the second abnormal session, the current turn ended as `aborted` about five seconds after the user asked it to stop. The interrupt mechanism worked. The same text later appeared with two RPC IDs, which is more consistent with two client submissions than with proof that the harness duplicated the message automatically.

The UI should show that an interruption was accepted and how many messages remain queued, so a user does not submit the same request again because feedback is missing.

### Do not flatten all injected context into ordinary user messages

Repository rules and runtime snapshots carried `source.kind: agent-instructions` or `plugin`, yet appeared with a `user` role. Metadata retained provenance, but large rule blocks still consumed context and blurred priority semantics.

Where the provider supports it, a harness should map system rules, developer rules, project context, and actual user requests to distinct role levels, and log-analysis tools should display them separately by default.

## What this experiment cannot prove

One same-task comparison does not establish that:

- DeepSeek-V4-Pro High is always 1.92 times slower;
- High can never find something Low misses;
- every non-tool second is model compute;
- another harness using the model will behave the same way;
- Low should replace every high-reasoning task.

A stable benchmark would repeat the unchanged repository and prompt two or three times and report medians and variance. An Off baseline could be useful; Max is not the next necessary experiment.

The narrower conclusion is already actionable: in this tightly scoped code review, DeepSeek-V4-Pro High roughly doubled logged reasoning and non-tool time without increasing effective findings. Low is the better default for routine review. The broader fix is not a single model label, but a combination of reasoning level, delegation scope, stopping budgets, and timing observability across the harness.
