# dotagents

My config for AI coding agents — vendor-neutral skills plus per-tool settings. Like dotfiles, for agents.

```
skills/     SKILL.md skills (open Agent Skills format): ship, delegate, plan-html, codex
claude/     Claude Code: CLAUDE.md (global), settings.json
```

## Wiring (Claude Code)
```sh
ln -s ~/.agents/skills            ~/.claude/skills
ln -s ~/.agents/claude/CLAUDE.md  ~/.claude/CLAUDE.md
ln -s ~/.agents/claude/settings.json ~/.claude/settings.json
```

## Later: Codex
`ln -s ~/.agents/skills ~/.codex/skills` (move its built-in skill aside first); add `codex/` for AGENTS.md / config.toml.

Third-party skills go in `skills/vendor/<name>/`; delete a folder to disable.
