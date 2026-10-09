#!/usr/bin/env bash
# Apply HarkinianPad's maintained patches and overlays to the pinned checkout (idempotent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/sources/Shipwright"

if [ ! -d "$SOURCE/.git" ]; then
    echo "Run scripts/clone-sources.sh first." >&2
    exit 1
fi

apply_patch_once() {
    local directory="$1"
    local patch="$2"
    if git -C "$directory" apply --reverse --check "$patch" >/dev/null 2>&1; then
        echo "Already applied: $(basename "$patch")"
    elif git -C "$directory" apply --check "$patch"; then
        git -C "$directory" apply "$patch"
        echo "Applied: $(basename "$patch")"
    else
        echo "Patch does not match the pinned source: $patch" >&2
        exit 1
    fi
}

apply_patch_once "$SOURCE" "$ROOT/patches/shipwright-ios.patch"
apply_patch_once "$SOURCE/libultraship" "$ROOT/patches/libultraship-ios.patch"

mkdir -p "$SOURCE/CMake" "$SOURCE/soh/ios/Assets.xcassets/AppIcon.appiconset"
cp "$ROOT/port/CMake/ios.cmake" "$SOURCE/CMake/ios.cmake"
for file in "$ROOT"/ios/*; do
    cp "$file" "$SOURCE/soh/ios/"
done
cp "$ROOT"/assets/AppIcon.appiconset/* "$SOURCE/soh/ios/Assets.xcassets/AppIcon.appiconset/"

"$ROOT/scripts/verify-sources.py" >/dev/null
echo "HarkinianPad patches and overlays match the source checkout."
