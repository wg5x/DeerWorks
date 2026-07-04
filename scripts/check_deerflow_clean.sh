#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEERFLOW_DIR="$ROOT_DIR/vendor/deer-flow"

if [[ ! -d "$DEERFLOW_DIR/.git" ]]; then
  echo "vendor/deer-flow is missing or is not a Git repository." >&2
  echo "Expected an independent DeerFlow checkout at: $DEERFLOW_DIR" >&2
  exit 1
fi

status="$(git -C "$DEERFLOW_DIR" status --porcelain)"

if [[ -n "$status" ]]; then
  echo "vendor/deer-flow has local changes. Commit, stash, or discard them before upgrading." >&2
  echo "$status" >&2
  exit 1
fi

branch="$(git -C "$DEERFLOW_DIR" branch --show-current || true)"
commit="$(git -C "$DEERFLOW_DIR" rev-parse HEAD)"

if [[ -n "$branch" ]]; then
  echo "vendor/deer-flow is clean at $branch@$commit"
else
  echo "vendor/deer-flow is clean at detached HEAD $commit"
fi

