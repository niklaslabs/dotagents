---
name: delegate
description: Orchestrate work via subagents and pick the right model tier. Use when a task is substantial enough to split up, when the user says "delegate", "use subagents", "orchestrate", or when deciding which Claude/Codex model to use for a subtask.
---

# /delegate — Orchestrate, don't grind

## Orchestrator rules
- Keep your own context free for coordination, review, and decisions; subagents do the work.
- Fable and Opus are senior-dev orchestrators. Never delegate TO Fable — workers are Opus, Sonnet, or Haiku 4.5.
- An Opus orchestrator may consult Fable (or Codex) on genuinely hard calls; discuss, then let Opus execute.
- Spawn independent subagents in parallel with tight briefs; require a short summary back, never file dumps.
- Always review worker output yourself — cheaper workers make compounding errors.
- Big Codex review/work: wrap it in a Haiku or Sonnet subagent that starts the Codex run and forwards the result.
- Post a status update every 2–3 minutes while agents run.
- Thinking level medium everywhere unless clearly needed.

## Claude tiers
| Model | Use for | Not for |
|---|---|---|
| Fable 5 | Orchestrator; security-critical review; escalation when Opus struggles | Any routine or trivial work |
| Opus 5 | Default for substantial work; can orchestrate; bigger design work | Bulk mechanical edits |
| Sonnet 5 | Normal/smaller coding, fast tweaks, small design changes, forwarding Codex output | Deep architectural decisions |
| Haiku 4.5 | Mechanical fan-out, file sweeps, kicking off + relaying Codex | Anything needing judgment |

## Codex tiers
| Model | Effort | Use for |
|---|---|---|
| gpt-5.6-sol | default | Reviews, challenges, consults |
| gpt-5.6-terra | high | Smaller/quicker work, esp. UI adjustments (the "Sonnet of Codex") |
| gpt-5.6-luna | — | Don't use; prefer Terra |

## Task routing
- Design/UI → Claude (Sonnet small, Opus bigger, Fable only if Opus struggles). Raster images → Codex. SVGs → any capable model.
