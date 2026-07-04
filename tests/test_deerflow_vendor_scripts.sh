#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "Test User"
  echo "initial" > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "initial"
}

run_in_tmp() {
  local name="$1"
  shift
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/scripts"
  cp "$ROOT_DIR/scripts/check_deerflow_clean.sh" "$tmp/scripts/check_deerflow_clean.sh"
  cp "$ROOT_DIR/scripts/update_deerflow.sh" "$tmp/scripts/update_deerflow.sh"
  (
    cd "$tmp"
    "$@"
  )
  rm -rf "$tmp"
  echo "ok - $name"
}

run_in_tmp "clean check fails when vendor repo is missing" bash -c '
  set +e
  output="$(./scripts/check_deerflow_clean.sh 2>&1)"
  code=$?
  set -e
  [[ "$code" -ne 0 ]]
  [[ "$output" == *"vendor/deer-flow is missing"* ]]
'

run_in_tmp "clean check passes for clean vendor repo" bash -c '
  mkdir -p vendor
  make_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test User"
    echo "initial" > "$repo/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "initial"
  }
  make_repo vendor/deer-flow
  output="$(./scripts/check_deerflow_clean.sh)"
  [[ "$output" == *"vendor/deer-flow is clean"* ]]
'

run_in_tmp "clean check fails for dirty vendor repo" bash -c '
  mkdir -p vendor
  make_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test User"
    echo "initial" > "$repo/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "initial"
  }
  make_repo vendor/deer-flow
  echo "dirty" >> vendor/deer-flow/README.md
  set +e
  output="$(./scripts/check_deerflow_clean.sh 2>&1)"
  code=$?
  set -e
  [[ "$code" -ne 0 ]]
  [[ "$output" == *"has local changes"* ]]
'

run_in_tmp "update writes vendor lock without fetching" bash -c '
  mkdir -p vendor
  make_repo() {
    local repo="$1"
    mkdir -p "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test User"
    echo "initial" > "$repo/README.md"
    git -C "$repo" add README.md
    git -C "$repo" commit -q -m "initial"
  }
  make_repo vendor/deer-flow
  sha="$(git -C vendor/deer-flow rev-parse HEAD)"
  ./scripts/update_deerflow.sh --no-fetch
  grep -q "$sha" vendor/deer-flow.lock
  grep -q "vendor/deer-flow" vendor/deer-flow.lock
  [[ ! -e DEERFLOW_VERSION ]]
'
