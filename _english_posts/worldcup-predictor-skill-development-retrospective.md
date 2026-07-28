---
layout: post
lang: en
translation_key: worldcup-predictor-skill-development-retrospective
title: "From Score Guessing to a Calibrated Workflow: One Month Building a World Cup Prediction Skill"
date: 2026-07-28 00:04:00 +0800
categories: [AI, Sports Technology]
tags: [worldcup, football, skills, agent, prediction, calibration]
status:
  label: 当前可用
  verified: 2026-07-22
  environment: World Cup Predictor Skill / Codex
  risk: This is a retrospective on prediction methodology and skill development. It is not a guarantee of match outcomes or betting advice.
---

For one month I used the same World Cup Predictor skill for pre-match forecasts, live updates, and post-match reviews. Its most valuable output was not a count of correct scores; it was a set of reusable agent rules extracted from repeated judgment errors.

---

With the tournament complete, development of `worldcup-predictor` has ended at its current version. The skill and reference framework remain available as the final artifact of the experiment. This article closes the project by reviewing its main mistakes and the calibration rules that survived beyond individual matches.

The first version had a simple goal: stop an AI from guessing a score from team reputation. It should read the market, data, news, match context, and tactical matchup before giving a score and confidence level.

Real use showed why that was insufficient.

Football prediction is not a static question. A projected starter may only be fit for one half. An early goal changes both teams' appetite for risk. A defensive substitution can add bodies to the box while removing ball retention and counterattacking outlets. A red card can create a new game or merely amplify a match that was already one-sided.

If the post-match review only asks whether the score was correct, the next forecast inherits the same flawed reasoning.

The project therefore evolved from a prediction prompt into a small calibration system.

## What the first version established

The initial framework divided evidence into five layers:

| Layer | Primary question |
|---|---|
| Market | How is current consensus pricing the result, total goals, and qualification? |
| Data | What quality of chances is each team creating, beyond possession and shot count? |
| News | How do the lineup, injuries, suspensions, illness, and rotation change actual roles? |
| Context | How do group incentives, knockout paths, weather, travel, and venue change risk appetite? |
| Tactics | How do pressing, progression, transitions, set pieces, and box occupation create or suppress chances? |

Every forecast had to identify the layers actually used and mark unavailable evidence as missing. Odds provided a baseline, not a verdict. Possession, corners, crosses, and total shots could show pressure without proving chance quality.

This structure reduced source hallucination and single-signal conclusions. It did not fully answer three harder questions:

- How should a match be split into decision stages?
- How should live information trigger a recalculation?
- How should a review identify *which part* of the forecast failed?

## Six recurring failure patterns

After enough forecasts, errors stopped looking random:

| Observation | Tempting but weak conclusion | Rule that replaced it |
|---|---|---|
| A stronger team records more possession and shots | It must be creating better chances | Separate pressure volume, chance creation, and finishing |
| A key player in the projected XI eventually appears | The personnel forecast was correct | Appearance is not full availability; preserve minutes and role-health branches |
| The predicted team qualifies | The knockout forecast was correct | Score the 90 minutes, extra time, penalties, and final qualifier separately |
| A leading team adds defenders | Its defence must be stronger | Check whether it also removed retention, progression, counter outlets, and second-ball protection |
| The score expands after a red card | The card explains the whole match | Compare the chance structure before and after the card |
| The exact score happens to match | The predicted game shape was correct | Score match phases and check whether chances and data definitions agree |

These failures shared one cause: the early process treated labels as states.

“Key player starts,” “protecting a lead,” “possession dominance,” and “correct score” are incomplete. An agent also needs time, role composition, evidence, and the possible next transitions.

## Knockout matches require separate stages

A group-stage draw can be an acceptable final outcome. A draw after 90 minutes in a knockout match merely opens another decision stage. Combining the two distorts both the score forecast and the qualification probability.

The knockout output was therefore divided into:

- the 90-minute score or result lean;
- the team more likely to qualify;
- the risk of extra time and whether it may settle the tie;
- the risk of penalties and the relevant penalty resources.

The review uses the same decomposition. If a forecast says “draw after 90 minutes, Team A qualifies” and Team A wins in regulation, qualification was correct but the match-stage judgment was not. If the final score after extra time matches the predicted number but the regulation score does not, only the final score can be recorded as correct.

Probability vocabulary matters too. “Reaches extra time” includes matches later decided in extra time or on penalties. “Decided in extra time” and “reaches penalties” are narrower branches. If mutually exclusive probabilities are required, use:

```text
decided in 90 minutes / decided in extra time / decided on penalties
```

Do not add a parent probability to its children as if they were independent.

Historical rates of extra time in finals can serve as a limited prior. Current draw pricing, tactics, goalkeepers, attacking intent, and bench resources still matter more than a small historical sample.

## A third-place playoff is not a normal knockout match

The third-place match exposed another shortcut: no championship pressure does not automatically create a relaxed, high-scoring exhibition.

Role rotation is more informative than rotation count.

If both teams retain their creators, finishers, and transition carriers while rotating the goalkeeper, centre-backs, midfield screen, or pressing organizers, attacking quality may survive better than defensive coordination. In that case, the model should raise both expected goals and the high-scoring tail—not mechanically change `1-0` to `2-1`.

An early goal can also produce a feedback loop:

1. the trailing team opens its structure earlier;
2. the leader retains a credible counterattacking outlet;
3. both teams generate more chances;
4. the score distribution widens and exact-score confidence falls.

This remains conditional. If key attackers are rested, weather suppresses tempo, both teams retain compact structures, or market and recent data do not support openness, the “third-place playoff” label should not force an over prediction.

## Live updates became state recalculation

The early skill already asked for xG, big chances, shots on target, and substitution needs at half-time. Real conversations revealed a more basic dependency: tactical analysis is unreliable when the event timeline is wrong.

Every half-time or user-requested checkpoint now begins with a compact event ledger:

```text
current score and scorers
cards, penalties, and VAR decisions
injuries and substitutions
stoppage time
event sources and any unresolved causes
```

Three evidence types remain separate:

- facts confirmed by a page or data source;
- observations the user made from the broadcast;
- the agent's tactical inference.

An injury substitution should not be rewritten as a voluntary tactical decision. If a source does not state the reason, the reason stays unknown.

This small ledger prevents a common failure: every statistic is read correctly, but the causal explanation is built on the wrong goal, injury, or substitution time.

## Substitutions are role changes, not position labels

One of the clearest early overreactions was reading “forward off, defender on” as an automatic defensive upgrade.

The extra defender may improve box coverage while removing:

- the player who carries the ball out of pressure;
- a secure possession outlet;
- the runner who pins centre-backs;
- the width or second-ball protection needed to escape;
- the counterattacking threat that stops the opponent from committing everyone forward.

The opponent can then recycle possession, win second balls, and re-enter the box repeatedly. Late concession risk may rise despite the greater number of nominal defenders.

The updated live checklist asks:

- Who progresses the ball from the defensive third?
- Who can retain it under pressure?
- Who still occupies the box and pins defenders?
- Who provides width, second-ball coverage, and a counter outlet?
- How do these changes alter counterpressing and recovery exposure?

If the match becomes level, the forecast starts again from the new score, remaining time, and current personnel. Creators and carriers removed to protect a lead cannot simply return. The model should not preserve the pre-equalizer probability, and it should not invent a precise probability jump from substitution labels without a readable market or an actual live model.

## Tactical dominance includes removing the opponent's route

Another correction came from matches between possession sides and transition-dependent opponents. Looking only at the possession team's shots misses the defensive value of its counterpress.

If the opponent cannot find the first and second forward pass, midfield receivers cannot turn, and every recovery ends in a backpass or another immediate loss, its primary transition route has been structurally removed.

That should not be reduced to “the striker played poorly,” nor should possession percentage be treated as the whole explanation. Tactical analysis must ask both:

- Which team created more?
- Which team removed the route its opponent relies on most?

This rule transfers better across teams than a permanent upgrade or downgrade attached to one tournament participant.

## Post-match review needs three scoring layers

The result must be recorded, but it is not the only object being evaluated.

### Result layer

Track the 90-minute result, exact regulation score, final qualifier, and decision stage separately. Do not let final qualification overwrite an incorrect regulation forecast.

### Process layer

Check whether the forecast's causal claims occurred:

- Did the stronger team create high-quality chances consistently?
- Did the underdog's counter or set-piece route exist?
- Did a missing player actually damage progression, finishing, or defensive organization?

A low score can be correct while the process forecast is only partly correct—for example, one team dominates but exceptional goalkeeping or poor finishing suppresses the score. Conversely, an open-game forecast can be directionally right while goals far exceed xG or xGOT. The review should distinguish a conservative total-goals baseline from extreme finishing variance.

### Critical-event layer

Record red cards, VAR decisions, penalties, goalkeeper errors, injuries, and extreme finishing separately.

If the match was already one-sided before a red card, the card is more likely an amplifier. If it transforms an otherwise balanced match, it is a primary state transition.

Data definitions also need discipline. Providers may disagree on shots on target, saves, cards, and xG. Use internally consistent statistics from one provider or list each source and definition separately. For cards, state whether the count means player cautions, all yellow-card events, second-yellow dismissals, direct reds, or technical-area cards.

## Two reviews that changed the skill

Two late updates illustrate the development method.

In a France–Spain forecast and review, the existing framework already covered chance quality, pressure quality, substitutions, and knockout stages. The durable gaps were narrow:

- a half-time event ledger;
- structural suppression of a transition team by blocking its first progression route.

Only those general rules entered the detailed reference. No permanent “upgrade Spain” or “downgrade France” conclusion was added.

In a live England–Argentina review, the missing logic concerned substitutions while leading and recalculation after an equalizer. The update added three rules:

- replacing a forward with a defender is not automatically a defensive upgrade;
- after an equalizer, recalculate from the score and personnel that remain;
- do not fabricate exact probability changes from substitution labels without a model or readable live market.

Both edits were small. They mattered more than another page of team descriptions because they reduce the chance of repeating the same structural mistake.

## What was deliberately excluded

Continuous review creates a strong risk of overfitting. The skill deliberately excludes:

- permanent tournament-specific upgrades or downgrades for one team;
- mechanical score adjustments based on the previous match;
- fragile browser implementation details from a single failed data read;
- a cross-session prediction ledger that was not actually preserved;
- win/draw/loss probabilities or hit rates reconstructed after the result.

Only methods expected to survive across teams, rounds, and data sources entered the reference framework. Match-specific facts stayed in their original analysis.

## Why detailed rules live in a reference

The final skill keeps a two-layer structure:

```text
worldcup-predictor/
├── SKILL.md
└── references/
    └── prediction-framework.md
```

`SKILL.md` defines triggers, the core workflow, source boundaries, and standard output. The growing set of rules for match states, cards, substitutions, VAR, review, and calibration lives in `prediction-framework.md`.

This keeps the entry point navigable while allowing deeper analysis to load the complete framework when needed.

The original Chinese design guide is [World Cup Predictor: Designing a World Cup Forecasting Skill for AI Agents](/posts/worldcup-predictor-agent-skill/). The source remains available at [Onlydreams/worldcup-predictor](https://github.com/Onlydreams/worldcup-predictor).

## The missing piece: a quantitative ledger

The final framework supports qualitative calibration, but it cannot honestly publish a complete historical hit rate. Earlier forecasts were not all saved with the same fields and explicit probabilities. Reconstructing those values after the outcome would manufacture precision.

A future experiment should record from the first match:

```text
match and forecast timestamp
evidence cutoff and source layers used
90-minute result and exact score
final qualifier and decision stage
result confidence and exact-score confidence
important missing data
process judgment and error category
```

Calculate a Brier Score only when normalized pre-match probabilities were actually recorded. If confidence was expressed as High, Medium, or Low, preserve it as ordinal evidence instead of pretending it was a quantitative model.

## Conclusion

A prediction skill does not mature by becoming more confident about scorelines. It matures by recognizing when confidence should fall, when the match state must be recalculated, and which part of the reasoning chain should change after the result.

The durable output of this month was not a team ranking. It was a workflow:

- layer the evidence;
- split the match into decision stages;
- treat live events as state changes;
- separate result, process, and critical-event review;
- write only generalizable errors back into the skill.

That is closer to a sustainable forecasting system than occasionally guessing `2-1`.
