#!/usr/bin/env bash
# Verifies libultraship's SDL patches the way the iOS build applies them (cmake/dependencies/git-patch.cmake):
# 1. on a fresh SDL checkout every patch applies, in order;
# 2. on the fully patched checkout (a reused/cached dependency) every patch is recognized as already applied.
# A patch that edits lines of an earlier one breaks (2) and fails builds that reuse the SDL checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/pins.sh"
LUS_SHA="${MASKPAD_LUS_SHA:-${HARKINIANPAD_LUS_SHA:-}}"
if [ -z "$LUS_SHA" ]; then
    echo "No libultraship pin found in scripts/pins.sh" >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

git init -q "$WORK/lus"
git -C "$WORK/lus" fetch -q --depth 1 https://github.com/Kenix3/libultraship.git "$LUS_SHA"
git -C "$WORK/lus" checkout -q FETCH_HEAD
git -C "$WORK/lus" apply --whitespace=nowarn "$ROOT/patches/libultraship-ios.patch"

IOS_CMAKE="$WORK/lus/cmake/dependencies/ios.cmake"
PATCH_DIR="$WORK/lus/cmake/dependencies/patches"
SDL_TAG="$(sed -n 's/.*GIT_TAG \([0-9a-f]\{40\}\).*/\1/p' "$IOS_CMAKE" | head -1)"
EXTRAS="$(sed -n 's/.*foreach(sdl2_extra_patch \(.*\))/\1/p' "$IOS_CMAKE" | head -1)"
PATCHES=("$PATCH_DIR/sdl2-uikit-scenes.patch")
for extra in $EXTRAS; do
    PATCHES+=("$PATCH_DIR/sdl2-uikit-$extra.patch")
done
if [ -z "$SDL_TAG" ]; then
    echo "Could not read the SDL pin from ios.cmake" >&2
    exit 1
fi

git init -q "$WORK/sdl"
git -C "$WORK/sdl" fetch -q --depth 1 https://github.com/libsdl-org/SDL.git "$SDL_TAG"
git -C "$WORK/sdl" checkout -q FETCH_HEAD

status=0
for patch in "${PATCHES[@]}"; do
    if ! git -C "$WORK/sdl" apply "$patch"; then
        echo "::error title=SDL patch::$(basename "$patch") does not apply to a fresh SDL $SDL_TAG"
        status=1
    fi
done
for patch in "${PATCHES[@]}"; do
    if ! git -C "$WORK/sdl" apply --reverse --check "$patch"; then
        echo "::error title=SDL patch::$(basename "$patch") is not recognized as applied on a patched (cached) SDL checkout"
        status=1
    fi
done
[ "$status" -eq 0 ] && echo "SDL patches apply fresh and re-apply on a patched checkout: ${PATCHES[*]##*/}"
exit "$status"
