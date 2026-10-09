# Maintained source patches

Pinned base: Ship of Harkinian **9.3.0 "Dewey"** (see `scripts/pins.sh` and
`sources.lock.json`). `scripts/clone-sources.sh` fetches it and runs
`scripts/apply-patches.sh`, which applies, idempotently:

1. `shipwright-ios.patch` at the Shipwright root: iOS CMake, Files-based ROM
   import and extraction prompts, touch-control hooks, mod-pack import, native
   HUD touch, menu sizing, the Native Screen Resolution setting, and static
   SDL2_net so the Network menu (Anchor, Sail, Crowd Control) builds on iOS;
2. `libultraship-ios.patch` in `libultraship`: the iOS libultraship patch shared
   with MaskPad (SDL 2.32.10 UIKit scene startup and orientation, controller
   slot reconciliation, lifecycle pause, cached Metal depth-stencil states,
   effective refresh-rate reporting, opt-in native resolution);
3. overlays: `port/CMake/ios.cmake` to `CMake/ios.cmake`, `ios/*` to `soh/ios/`,
   and `assets/AppIcon.appiconset` into the app's asset catalog.

`scripts/verify-sources.py` requires every patch to reverse-apply and every
overlay to match byte-for-byte before configure, archive generation and
packaging.
