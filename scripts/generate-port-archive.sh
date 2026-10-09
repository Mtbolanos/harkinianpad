#!/usr/bin/env bash
# Build Ship of Harkinian's ROM-free soh.o2r with upstream's own packer on the macOS host.
#
# The iOS cross-build cannot run soh-o2r-packer, so this uses upstream's tools-only
# configure (SOH_TOOLS_ONLY: Torch and the packer, no libultraship or game) and copies
# the result where the iOS build bundles it from.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/sources/Shipwright"
BUILD="$ROOT/build-host-tools"
"$ROOT/scripts/verify-sources.py" >/dev/null

cmake -S "$SRC" -B "$BUILD" \
    -DCMAKE_BUILD_TYPE=Release \
    -DSOH_TOOLS_ONLY=ON
cmake --build "$BUILD" --target GenerateSohOtr

cp "$BUILD/soh/soh.o2r" "$SRC/soh/soh.o2r"
echo "ROM-free port archive: $SRC/soh/soh.o2r"
