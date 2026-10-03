#!/usr/bin/env bash
# Upload an image to GitHub's user-attachments endpoint and (optionally) append it to a PR body.
#
# Usage:
#   upload.sh <image-path> [--pr <number>] [--repo owner/name] [--alt "text"]
#
# Prints the resulting asset URL. With --pr, appends "![alt](url)" to that PR's body.
# Relies on an undocumented endpoint (uploads.github.com/user-attachments/assets). Needs gh, curl, jq.
set -euo pipefail

IMAGE="" PR="" REPO="" ALT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)   PR="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --alt)  ALT="$2"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
    *) IMAGE="$1"; shift ;;
  esac
done

[[ -n "$IMAGE" && -f "$IMAGE" ]] || { echo "error: image path required and must exist" >&2; exit 1; }
command -v gh >/dev/null || { echo "error: gh CLI not found" >&2; exit 1; }

if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi

NAME=$(basename "$IMAGE")
case "${NAME##*.}" in
  png)      CT=image/png ;;
  jpg|jpeg) CT=image/jpeg ;;
  gif)      CT=image/gif ;;
  webp)     CT=image/webp ;;
  svg)      CT=image/svg+xml ;;
  *) echo "error: unsupported extension .${NAME##*.}" >&2; exit 1 ;;
esac

REPO_ID=$(gh api "repos/$REPO" --jq .id)
RESP=$(curl -fsS -X POST \
  "https://uploads.github.com/user-attachments/assets?name=$(printf %s "$NAME" | jq -sRr @uri)&content_type=$CT&repository_id=$REPO_ID" \
  -H "Authorization: Bearer $(gh auth token)" \
  -H "Content-Type: $CT" \
  --data-binary "@$IMAGE")
URL=$(printf %s "$RESP" | jq -r .url)
[[ -n "$URL" && "$URL" != null ]] || { echo "error: upload failed: $RESP" >&2; exit 1; }

echo "$URL"

if [[ -n "$PR" ]]; then
  ALT=${ALT:-$NAME}
  BODY=$(gh pr view "$PR" --repo "$REPO" --json body --jq .body)
  gh pr edit "$PR" --repo "$REPO" --body "${BODY}

![${ALT}](${URL})" >/dev/null
  echo "appended to PR #$PR" >&2
fi
