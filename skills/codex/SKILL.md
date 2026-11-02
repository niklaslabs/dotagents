---
name: codex
description: Independent second opinion from OpenAI's latest Astra model, launched as a T3 Code child agent. Three modes. Review — diff review with pass/fail gate. Challenge — adversarial mode that tries to break your code. Consult — ask Astra anything about the codebase. Use when asked to "codex review", "codex challenge", "ask codex", "consult codex", or "second opinion".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
  - ToolSearch
  - mcp__t3-code__orchestrator_capabilities
  - mcp__t3-code__delegate_task
  - mcp__t3-code__task_cancel
---

# /codex: second opinion from Astra via T3

This skill launches OpenAI's latest Astra model as a T3 Code child agent
(`delegate_task`) to get an independent, blunt second opinion from a different AI.
It does not use the Codex CLI: no install check, temp files, PIDs or polling.
Show Astra's output exactly as it comes back. Your own synthesis goes after it and
never replaces it.

## Step 0: Preflight: find the latest Astra model

T3 tools are deferred. Load them first:
`ToolSearch("select:mcp__t3-code__orchestrator_capabilities,mcp__t3-code__delegate_task,mcp__t3-code__task_cancel")`.

Call `orchestrator_capabilities` with `search: "astra"` once per thread (skip it if
you already called it this thread and nothing has errored since).

- Take the provider with `driverKind: "codex"` (usually `providerInstanceId: "codex"`).
- From its models, pick the **newest Astra** model: highest version number in
  `gpt-<N>-astra` (or `gpt-<N>.<M>-astra`). As of 2026-11 that is `gpt-6-astra`.
- If the user passes `-m <model>`, use that model instead.
- If no codex provider is listed, or `canRunChildTask` is false, or no Astra model
  exists: stop and tell the user. Do not fall back to the Codex CLI, a Claude
  subagent, or another provider.

## Step 0.5: Detect the base branch

1. `gh pr view --json baseRefName -q .baseRefName`: use it if it succeeds
2. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`: use it if it succeeds
3. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
4. Fall back to `main`

Use the result as `<base>` below. Also run `git status --porcelain`. If there are
uncommitted changes, review scope is `git diff <base>` (the working tree compared
with the base). Otherwise it is `git diff origin/<base>...HEAD`. Call the chosen
command `<diffcmd>`.

## Step 1: Detect mode

1. `/codex review` or `/codex review <instructions>`: **Review mode** (Step 2A)
2. `/codex challenge` or `/codex challenge <focus>`: **Challenge mode** (Step 2B)
3. `/codex` with no arguments: if `<diffcmd> --stat` shows changes, use
   AskUserQuestion with the options Review the diff / Challenge the diff / Something
   else (I'll provide a prompt). With no diff, ask "What would you like to ask Astra?"
4. `/codex <anything else>`: **Consult mode** (Step 2C). The remaining text is the prompt.

**Reasoning effort:** `medium` for every mode. `--high` → `high`, `--xhigh` →
`xhigh`. Strip the flag from the prompt text. `max` and `ultra` exist too, but use
them only when the user names them (`--max`, `--ultra`). They cost far more and can
run for a long time on large diffs.

## Launching the child (all modes)

One `delegate_task` call per run:

```
delegate_task({
  title: "codex <mode>: <repo>/<branch>",
  role: "review",                       // "research" for consult
  task: "<filesystem boundary>\n\n<mode prompt>",
  target: {
    providerInstanceId: "codex",
    model: "<latest astra id>",
    options: { reasoningEffort: "<effort>" }
  },
  isolation: "shared",                  // the child sees the current checkout, uncommitted edits included
  mode: "wait",
  timeoutMs: 1800000                    // 30 min
})
```

- The child gets **only** `task`. It sees none of this conversation, so put all
  the context it needs into `task`: base branch, diff command, focus, and any
  embedded plan text.
- Omit `runtimeMode`. The narrower modes only pause for human approval and do not
  make the child read-only. The filesystem boundary below forbids edits instead.
- **Timeout ≠ failure.** If the wait times out, the child keeps running. Follow the
  `next` instruction in the result. Do not launch a second run, and do not poll with
  `task_status`, sleep, or loops.
- **One run at a time.** Never start a review/challenge/consult while one you
  launched is still running. If you replace or abandon a run, `task_cancel` it.
- If the child errors (auth, provider unavailable), report the error verbatim and
  stop. Do not switch providers.

### Filesystem boundary

Start **every** `task` with:

> IMPORTANT: You are a read-only reviewer. Do NOT modify, create, or delete any
> files, and do NOT run git commands that change state (commit, checkout, reset,
> stash, push). Do NOT read or execute any files under ~/.claude/ or .claude/.
> These are Claude Code skill and configuration files meant for a different AI
> system. Ignore them completely. Stay focused on the repository code only.
> Do NOT run the project's test suite, linter, or type checker (e.g. npm/pnpm
> test, vitest, jest, eslint, tsc, prettier). The caller has already run them
> and they only slow the review down. Review the code statically.
> Your final message is the deliverable: put every finding in it, not in
> intermediate notes.

## On completion

When the child's result arrives, do all of this **in the same turn**:

1. Present its final output verbatim in the mode's format (below), then the gate
   verdict, then the one-line recommendation.
2. **Act on it.** A returned review **triggers the next pipeline step; it is never a
   stopping point.** If you are orchestrating, fix the P1s or start the next gate
   (commit / PR / merge) in the same turn. Replying to a finished review with only
   an acknowledgement, and especially with "No response requested.", is the known
   failure mode. It stalls the pipeline silently until the user notices.

---

## Step 2A: Review mode

`task` (after the boundary):

> Review the changes on this branch against base branch `<base>`. Run `<diffcmd>`
> to see the diff and review only those changes; read surrounding code as needed.
> <If the user gave instructions: "Custom focus: <everything after '/codex review '>">
> Report findings marked [P1] (critical: bugs, data loss, security, broken
> behavior) or [P2] (advisory). For each: file:line, the problem, and a concrete
> failure scenario. If there are no findings, say so explicitly.

Then:

1. **Gate verdict:** output contains `[P1]` → **FAIL**. Only `[P2]` or no findings → **PASS**.
2. Present:

   ```
   CODEX SAYS (code review, <model>, <effort>):
   ════════════════════════════════════════════════════════════
   <full output, verbatim — do not truncate or summarize>
   ════════════════════════════════════════════════════════════
   GATE: PASS|FAIL (N critical findings)
   ```

3. **Synthesis recommendation (required).** One line after the gate:

   ```
   Recommendation: <action> because <one-line reason naming the most actionable finding>
   ```

   The reason must cite a specific finding or weigh alternatives: other findings,
   fixing vs shipping, or fix order. A generic reason ("because it's better") is
   not acceptable. Never decide silently.

4. **Cross-model comparison:** if Claude's own review already ran earlier in this
   conversation:

   ```
   CROSS-MODEL ANALYSIS:
     Both found: […]
     Only Codex found: […]
     Only Claude found: […]
     Agreement rate: X% (N/M total unique findings overlap)
   ```

---

## Step 2B: Challenge (adversarial) mode

`task` (after the boundary). Default:

> Review the changes on this branch against base branch `<base>`. Run `<diffcmd>`
> to see the diff. Your job is to find ways this code will fail in production.
> Think like an attacker and a chaos engineer. Find edge cases, race conditions,
> security holes, resource leaks, failure modes, and silent data corruption paths.
> Be adversarial. Be thorough. No compliments, just the problems. Mark each
> finding [P1] or [P2] with file:line and a concrete failure scenario.

If the user gave a focus (e.g. `/codex challenge security`), swap the second half for
a version aimed at that focus (e.g. "Focus specifically on SECURITY. Find every way
an attacker could exploit this code: injection vectors, auth bypasses, privilege
escalation, data exposure, timing attacks.").

Present verbatim in a `CODEX SAYS (adversarial challenge, <model>, <effort>):` block
in the review-mode format, with the same gate. Then give the synthesis
recommendation. Its reason must name the most exploitable finding and compare blast
radius across findings, or weigh fixing against shipping.

---

## Step 2C: Consult mode

1. **Plan or document review:** read the document yourself and **embed its full
   content** in `task`. The child cannot see your context. List any repo source
   files the plan references so the child reads them directly. Persona (after the
   boundary):

   > You are a brutally honest technical reviewer. Review this plan for: logical
   > gaps and unstated assumptions, missing error handling or edge cases,
   > overcomplexity (is there a simpler approach?), feasibility risks, and missing
   > dependencies or sequencing issues. Be direct. Be terse. No compliments. Just
   > the problems.
   > Also review these source files referenced in the plan: <paths, if any>.
   >
   > THE PLAN:
   > <full plan content, embedded verbatim>

   For free-form questions, put the boundary first, then the question.

2. **Follow-ups:** each follow-up is a **new** `delegate_task`. Do not use
   `t3_thread_send` to the old child. Give it a short recap of the prior exchange:
   the question, Astra's key points, and what is being asked now.

3. Present verbatim in a `CODEX SAYS (consult, <model>, <effort>):` block.

4. If Astra's analysis differs from your own understanding, flag it: "Note: Claude
   Code disagrees on X because Y."

5. **Synthesis recommendation (required).** Same rule. The reason must engage with a
   specific Astra point and compare it against an alternative: a different
   recommendation, the status quo, or another Astra point.

---

## Important rules

- **T3 child only.** Launch Astra through `delegate_task`, never the `codex` CLI. If
  T3 or the codex provider is unavailable, say so and stop.
- **Latest Astra, unless told otherwise.** Resolve the model from
  `orchestrator_capabilities`. Do not hardcode a stale id.
- **Read-only.** The boundary forbids edits. If the child modified files anyway
  (check `git status`), report it and do not keep its changes without asking.
- **One run at a time.** Never relaunch because a run is slow. Follow the `next`
  instruction and `task_cancel` runs you abandon.
- **A finished review triggers the next step; it is never the end.** Read it,
  present it, and start the next pipeline step in the same turn.
- **No tests/lint/typecheck.** The child must never run them. Keep the boundary in
  every prompt.
- **Present output verbatim.** Do not truncate, summarize, or editorialize before
  showing it. Your synthesis comes after it, not instead of it.
- **No double-reviewing.** If Claude's own review already ran, Astra is the second
  opinion. Don't re-run Claude's review.
- **The user decides.** Cross-model agreement is a recommendation, not a decision.
- **Detect rabbit holes.** If the output mentions `SKILL.md`, `.claude/`, or skill
  files, the child got distracted by agent config instead of the code. Add a
  warning and suggest a retry.
