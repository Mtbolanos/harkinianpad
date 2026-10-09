#!/usr/bin/env bash
# Fetch the pinned upstream Ship of Harkinian tree and apply HarkinianPad's patches.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/Shipwright"
source "$ROOT/scripts/pins.sh"

if [ "$#" -ne 0 ]; then
    echo "Only pinned sources are supported; update scripts/pins.sh in a reviewed change." >&2
    exit 2
fi

assert_sha() {
    local directory="$1"
    local expected="$2"
    local actual
    actual="$(git -C "$directory" rev-parse HEAD)"
    if [ "$actual" != "$expected" ]; then
        echo "Pin mismatch in $directory: expected $expected, found $actual" >&2
        exit 1
    fi
}

if [ ! -d "$SOURCE/.git" ]; then
    mkdir -p "$ROOT/sources"
    git clone --no-checkout "$HARKINIANPAD_UPSTREAM" "$SOURCE"
    git -C "$SOURCE" fetch origin "$HARKINIANPAD_SOH_SHA"
    git -C "$SOURCE" checkout --detach "$HARKINIANPAD_SOH_SHA"
    git -C "$SOURCE" submodule update --init --recursive
fi

assert_sha "$SOURCE" "$HARKINIANPAD_SOH_SHA"
assert_sha "$SOURCE/libultraship" "$HARKINIANPAD_LUS_SHA"
assert_sha "$SOURCE/torch" "$HARKINIANPAD_TORCH_SHA"

git -C "$SOURCE" remote set-url --push origin disabled://harkinianpad-upstream-input
git -C "$SOURCE" submodule foreach --recursive \
    'git remote set-url --push origin disabled://harkinianpad-upstream-input'

"$ROOT/scripts/apply-patches.sh"
