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
  cp "$ROOT_DIR/scripts/check_vendor_clean.sh" "$tmp/scripts/check_vendor_clean.sh"
  cp "$ROOT_DIR/scripts/update_vendor.sh" "$tmp/scripts/update_vendor.sh"
  (
    cd "$tmp"
    "$@"
  )
  rm -rf "$tmp"
  echo "ok - $name"
}

run_in_tmp "clean check requires vendor name" bash -c '
  set +e
  output="$(./scripts/check_vendor_clean.sh 2>&1)"
  code=$?
  set -e
  [[ "$code" -eq 2 ]]
  [[ "$output" == *"--vendor is required"* ]]
'

run_in_tmp "clean check fails when vendor repo is missing" bash -c '
  set +e
  output="$(./scripts/check_vendor_clean.sh --vendor agentscope 2>&1)"
  code=$?
  set -e
  [[ "$code" -ne 0 ]]
  [[ "$output" == *"vendor/agentscope is missing"* ]]
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
  make_repo vendor/agentscope-runtime
  output="$(./scripts/check_vendor_clean.sh --vendor agentscope-runtime)"
  [[ "$output" == *"vendor/agentscope-runtime is clean"* ]]
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
  output="$(./scripts/check_vendor_clean.sh --vendor deer-flow 2>&1)"
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
  make_repo vendor/agentscope
  sha="$(git -C vendor/agentscope rev-parse HEAD)"
  ./scripts/update_vendor.sh --vendor agentscope --no-fetch
  grep -q "$sha" vendor/agentscope.lock
  grep -q "vendor/agentscope" vendor/agentscope.lock
  [[ ! -e DEERFLOW_VERSION ]]
'

run_in_tmp "update requires vendor name" bash -c '
  set +e
  output="$(./scripts/update_vendor.sh --no-fetch 2>&1)"
  code=$?
  set -e
  [[ "$code" -eq 2 ]]
  [[ "$output" == *"--vendor is required"* ]]
'
