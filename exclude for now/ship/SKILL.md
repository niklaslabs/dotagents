---
name: ship
description: My shipping pipeline — lint+format, local tests, codex review, commit, PR, auto-merge. Each gate is idempotent (skip if already done on the current code). Use when the user says "ship", "ship it", or "/ship".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Skill
---

# /ship

Run the gates in order. Before each, ask: **already done on the exact current working tree?** If yes, skip; if no, do it. Report each gate as done / skipped / failed.

0. **Branch** — if on the default branch, create a feature branch first.
1. **Lint + format** — run the repo's lint and format commands (check package.json / Makefile / AGENTS.md). Fix issues.
2. **Tests** — full local suite must pass on the current tree. Fix, don't skip.
3. **Codex review** — run `/codex review` on the diff. Address findings; re-review if code changed. A failed review blocks shipping unless the user passed `--force`.
4. **Commit** — commit everything. Check the repo's AGENTS.md / CLAUDE.md for commit-message rules (e.g. no AI trailers) before writing the message.
5. **PR** — `git push -u` and `gh pr create` with a concise title/body.
6. **Auto-merge** — `gh pr merge --auto --merge` by default (merge commit). Use `--squash` for small changes: one or two commits, or a trivial fix where the history adds nothing. A repo convention (CLAUDE.md / AGENTS.md / branch protection allowing only one method) overrides both. Watch CI briefly; report the PR URL and status.

If any gate fails, stop, report the output verbatim, and don't proceed to later gates.
