# Typography and onboarding availability — 2026-10-17

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Source checkpoint only. No installed plugin, shell
configuration, observation connection or user data was changed.

Shared semantic roles and a host text-scale port now feed native text and OWL
renderer defaults. Omarchy supplies its font family/scale. Onboarding/header
reflow; controls and session rows grow with text; the page scrolls. Setup paths
use the accent and sit inline where room permits, stacking on narrow screens.
Supported imports use a circled check. Unsupported setups/sessions are muted
with a blocked symbol and explanatory text; session delegates reject selection,
including keyboard selection. An all-unsupported invitation disables Review.
Groups without observable sessions remain expandable without a selection box.

Canonical type table: widgets `desktop/runtime/MiiloTypeScale.js`, mirrored in
this repository with the attributed patch `patches/typography.patch` and updated
`sources.lock.json`. Upstream revision is preserved; no upstream revision is
invented for local modifications. See widgets `docs/desktop-typography.md` for
roles, host inputs, limitations and the backed-up legacy update command.

Verification:

- Native `make check`: manifest/import/provenance checks, six package tests and
  existing Node suites pass.
- `PATH=/usr/lib/qt6/bin:$PATH OMARCHY_PATH=/usr/share/omarchy make check-native`:
  exit 0. Manifest validation and qmllint run; lint warnings remain.
- Native `make check-typography`: offscreen QML suite passes, including 320/360/900
  widths, phone profile, 200% text, scroll reachability, measured/wrapped rows,
  literal text, independent grid scaling, path reflow and disabled availability.
- Legacy widgets `make check-typography`: narrow phone-profile/200% invitation
  and action reachability pass.
- Existing xtask binary `xtask/target/debug/xtask check-desktop`: 36 current-source
  Linux OWL scenarios pass. `node tools/test-robot-motion.cjs` passes. Widgets
  architecture and both repositories' diff-whitespace checks pass.
- The legacy updater was exercised on a disposable copy of the installed flat
  plugin. New source files match and the original LocalImport is backed up.
- `typography-preview.png` is an offscreen, synthetic 760x480 preview with dummy
  setup paths. It is not an installed shell screenshot.

Limits: Quickshell's isolated test IPC socket cannot bind inside this sandbox,
although offscreen test components render and execute. Current native desktop
IPC and installed UX are not qualified. Android Compose/Omalauncher still needs
its own text-scale integration and real-device testing. Explicit OWL fontSize
and fixed-height authored layouts remain host/content review points at large
accessibility settings. No complete cross-platform accessibility claim is made.

A new Cargo xtask build is blocked by the read-only default Cargo Git cache;
using the existing binary for its current-source evaluator tests is disclosed
above. No binary rebuild or release is claimed.

Next: apply the backed-up update on the user's desktop, inspect both themes and
font sizes with actual focus/keyboard behavior, then integrate/qualify the phone
renderer independently. Chat M3 and other release gates remain unchanged.
