---
name: pr-image
description: Attach an image (screenshot, diagram) to a GitHub PR or issue body. Use when the user says "add a screenshot to the PR", "attach image", "put this image in the PR description", or "/pr-image".
allowed-tools:
  - Bash
---

# /pr-image

Uploads a local image to GitHub's `user-attachments` endpoint and drops the URL into a PR body.

```sh
~/.agents/skills/pr-image/upload.sh <image> [--pr N] [--repo owner/name] [--alt "text"]
```

- Without `--pr`: prints the asset URL. Put it in markdown yourself (`![alt](url)` or `<img src="url" width="600">`) via `gh pr edit --body` or a comment.
- With `--pr N`: appends `![alt](url)` to that PR's body. `--repo` defaults to the current repo.
- Supported: png, jpg, gif, webp, svg. Needs `gh` (authed) and `jq`.

## Steps
1. Get the image on disk (screenshot via the app, `/run`, or user-supplied path).
2. Run the script. If the user wants placement other than "append to body", run without `--pr` and edit the body/comment yourself.
3. Report the PR URL and confirm the image renders (`gh pr view --json body`).

## Caveats
- The endpoint is undocumented and unsupported by GitHub (see cli/cli#13256); it may break without notice. If it returns 4xx, fall back to asking the user to drag-and-drop.
- Asset visibility follows the repo: private repo → viewer must be authenticated.
- Token auth works with `gh auth token`; older tools needed browser cookies.
