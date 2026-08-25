# agent skills

Personal skills in the open Agent Skills format (SKILL.md + frontmatter), plus my global Claude `CLAUDE.md`.

- `~/.claude/skills` → symlink here (Claude Code)
- `~/.claude/CLAUDE.md` → symlink to `./CLAUDE.md`
- Codex later: `ln -s ~/.agents/skills ~/.codex/skills` (move its built-in skill aside first)
- Third-party imports go in `vendor/<name>/`; delete a folder to disable.
