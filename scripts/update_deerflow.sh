#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEERFLOW_DIR="$ROOT_DIR/vendor/deer-flow"
LOCK_FILE="$ROOT_DIR/vendor/deer-flow.lock"
REF="main"
FETCH=1

usage() {
  cat <<'USAGE'
Usage: scripts/update_deerflow.sh [--ref REF] [--no-fetch]

Updates the independent DeerFlow checkout under vendor/deer-flow and records
the resolved commit in vendor/deer-flow.lock.

Options:
  --ref REF     Branch, tag, or commit to check out before recording the version.
                Defaults to main.
  --no-fetch    Skip network fetch/pull. Useful for tests or offline version refresh.
  -h, --help    Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      [[ $# -ge 2 ]] || { echo "--ref requires a value" >&2; exit 2; }
      REF="$2"
      shift 2
      ;;
    --no-fetch)
      FETCH=0
      shift
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

"$ROOT_DIR/scripts/check_deerflow_clean.sh" >/dev/null

if [[ "$FETCH" -eq 1 ]]; then
  git -C "$DEERFLOW_DIR" fetch origin --prune

  if git -C "$DEERFLOW_DIR" show-ref --verify --quiet "refs/remotes/origin/$REF"; then
    git -C "$DEERFLOW_DIR" checkout "$REF"
    git -C "$DEERFLOW_DIR" pull --ff-only origin "$REF"
  else
    git -C "$DEERFLOW_DIR" checkout "$REF"
  fi
fi

repo_url="$(git -C "$DEERFLOW_DIR" remote get-url origin 2>/dev/null || echo unknown)"
commit="$(git -C "$DEERFLOW_DIR" rev-parse HEAD)"
current_ref="$(git -C "$DEERFLOW_DIR" branch --show-current || true)"
if [[ -z "$current_ref" ]]; then
  current_ref="$REF"
fi

cat > "$LOCK_FILE" <<EOF
repo: $repo_url
path: vendor/deer-flow
ref: $current_ref
commit: $commit
EOF

echo "Recorded DeerFlow lock:"
cat "$LOCK_FILE"
