#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR=""

usage() {
  cat <<'USAGE'
Usage: scripts/check_vendor_clean.sh --vendor NAME

Checks that an independent Git checkout under vendor/NAME exists and has no
local changes.

Options:
  --vendor NAME  Vendor directory name under vendor/, for example deer-flow.
  -h, --help     Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vendor)
      [[ $# -ge 2 ]] || { echo "--vendor requires a value" >&2; exit 2; }
      VENDOR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$VENDOR" ]]; then
  echo "--vendor is required" >&2
  usage >&2
  exit 2
fi

if [[ "$VENDOR" == */* || "$VENDOR" == "." || "$VENDOR" == ".." || "$VENDOR" == *".."* ]]; then
  echo "--vendor must be a direct directory name under vendor/" >&2
  exit 2
fi

VENDOR_DIR="$ROOT_DIR/vendor/$VENDOR"

if [[ ! -d "$VENDOR_DIR/.git" ]]; then
  echo "vendor/$VENDOR is missing or is not a Git repository." >&2
  echo "Expected an independent vendor checkout at: $VENDOR_DIR" >&2
  exit 1
fi

status="$(git -C "$VENDOR_DIR" status --porcelain)"

if [[ -n "$status" ]]; then
  echo "vendor/$VENDOR has local changes. Commit, stash, or discard them before upgrading." >&2
  echo "$status" >&2
  exit 1
fi

branch="$(git -C "$VENDOR_DIR" branch --show-current || true)"
commit="$(git -C "$VENDOR_DIR" rev-parse HEAD)"

if [[ -n "$branch" ]]; then
  echo "vendor/$VENDOR is clean at $branch@$commit"
else
  echo "vendor/$VENDOR is clean at detached HEAD $commit"
fi
