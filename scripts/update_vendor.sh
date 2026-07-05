#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR=""
REF="main"
FETCH=1

usage() {
  cat <<'USAGE'
Usage: scripts/update_vendor.sh --vendor NAME [--ref REF] [--no-fetch]

Updates an independent Git checkout under vendor/NAME and records the resolved
commit in vendor/NAME.lock.

Options:
  --vendor NAME  Vendor directory name under vendor/, for example deer-flow.
  --ref REF      Branch, tag, or commit to check out before recording version.
                 Defaults to main.
  --no-fetch     Skip network fetch/pull. Useful for tests or offline refresh.
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
LOCK_FILE="$ROOT_DIR/vendor/$VENDOR.lock"

"$ROOT_DIR/scripts/check_vendor_clean.sh" --vendor "$VENDOR" >/dev/null

if [[ "$FETCH" -eq 1 ]]; then
  git -C "$VENDOR_DIR" fetch origin --prune

  if git -C "$VENDOR_DIR" show-ref --verify --quiet "refs/remotes/origin/$REF"; then
    git -C "$VENDOR_DIR" checkout "$REF"
    git -C "$VENDOR_DIR" pull --ff-only origin "$REF"
  else
    git -C "$VENDOR_DIR" checkout "$REF"
  fi
fi

repo_url="$(git -C "$VENDOR_DIR" remote get-url origin 2>/dev/null || echo unknown)"
commit="$(git -C "$VENDOR_DIR" rev-parse HEAD)"
current_ref="$(git -C "$VENDOR_DIR" branch --show-current || true)"
if [[ -z "$current_ref" ]]; then
  current_ref="$REF"
fi

cat > "$LOCK_FILE" <<EOF
repo: $repo_url
path: vendor/$VENDOR
ref: $current_ref
commit: $commit
EOF

echo "Recorded vendor lock:"
cat "$LOCK_FILE"
