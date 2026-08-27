---
name: ship-local
description: Same gates as /ship (lint+format, local tests, codex review, commit) but no PR — merge the branch into main locally and push main. For small projects without CI. Use when the user says "ship local", "ship locally", or "/ship-local".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Skill
---

# /ship-local

Like `/ship`, but the branch never goes to the remote: it is merged into the default branch locally and the default branch is pushed. Use on small projects with no CI where the user keeps everything on main.

Run the gates in order. Before each, ask: **already done on the exact current working tree?** If yes, skip; if no, do it. Report each gate as done / skipped / failed.

0. **Branch** — note the current branch. If already on the default branch, gates 1–4 still run; gates 5–6 reduce to a plain push.
1. **Lint + format** — run the repo's lint and format commands (check package.json / Makefile / AGENTS.md). Fix issues.
2. **Tests** — full local suite must pass on the current tree. Fix, don't skip.
3. **Codex review** — run `/codex review` on the diff. Address findings; re-review if code changed. A failed review blocks shipping unless the user passed `--force`.
4. **Commit** — commit everything. Check the repo's AGENTS.md / CLAUDE.md for commit-message rules (e.g. no AI trailers) before writing the message.
5. **Merge into main** — this replaces the PR:
   - Detect the default branch (`git symbolic-ref refs/remotes/origin/HEAD` or fall back to `main`).
   - `git fetch origin <main>` and fast-forward the local default branch to the remote (`git fetch origin <main>:<main>` when the current checkout isn't on it; in a worktree that has the default branch checked out elsewhere, run the merge from that worktree or use a temp worktree — never force-update a checked-out branch).
   - If remote main moved ahead of the feature branch, always `git rebase <main>` the feature branch onto it (never merge main into the branch), then re-run gates 1–2 (lint + full tests) on the rebased tree — this is the check that the branch still works against what landed on main. If the rebase changed the diff (conflict resolution, or the user changed code to fix a failure), re-run gate 3 (codex review) too. Rebase conflicts: stop and report.
   - Merge: `git merge --no-ff <branch>` by default (merge commit). Use `git merge --squash` + one commit for small changes (one or two commits, or a trivial fix where the history adds nothing). A repo convention in CLAUDE.md / AGENTS.md overrides both.
   - On conflicts: stop and report; don't resolve silently.
6. **Push main** — `git push origin <main>`. Never `--force`. If the push is rejected because the remote moved, fetch, re-merge, re-test, and push again. Then delete the local feature branch (`git branch -d`); if it's a worktree branch, leave the worktree cleanup to the user and say so.

Report the final commit SHA on main and whether the push succeeded. If any gate fails, stop, report the output verbatim, and don't proceed to later gates.
