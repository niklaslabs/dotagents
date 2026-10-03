# dotagents

My config for AI coding agents — vendor-neutral skills plus per-tool settings. Like dotfiles, for agents.

```
skills/            SKILL.md skills (open Agent Skills format): codex, unslop
exclude for now/   parked skills, not linked: delegate, ship, ship-local, plan-html, pr-image
claude/            Claude Code: CLAUDE.md (global), settings.json
link.sh            links the above into every Claude config dir
claude-dirs.local  list of Claude config dirs to link into (gitignored)
```

## Wiring (Claude Code)
```sh
cp claude-dirs.example claude-dirs.local   # then edit: one config dir per line
./link.sh                                   # re-run any time you add or remove a skill
```

`link.sh` symlinks `CLAUDE.md`, `settings.json` and each `skills/<name>` into every listed dir.
Skills are linked one by one, not as a whole folder: Claude Code only reads `skills/<name>/SKILL.md`,
and it writes its own `skills/synced/` bucket (Anthropic skills from your claude.ai account) into each
config dir. Those buckets differ per account and are left alone. Extra installs use
`CLAUDE_CONFIG_DIR=~/.claude-<name> claude`.

## Later: Codex
`ln -s ~/.agents/skills ~/.codex/skills` (move its built-in skill aside first); add `codex/` for AGENTS.md / config.toml.

Third-party skills go in `skills/vendor/<name>/`; delete a folder to disable.

## Skills Sources
- unslop: https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md 
- codex (adapted from): https://github.com/garrytan/gstack/blob/main/codex/SKILL.md
- plan-html (self-written)
- delegate (self-written)
- ship (self-written)
- ship-local (self-written)
- pr-image (self-written; endpoint per https://island94.org/2026/08/programmatically-upload-attachments-to-github-issues-pull-requests-comments)