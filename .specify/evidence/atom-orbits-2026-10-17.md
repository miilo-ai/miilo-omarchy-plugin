# Native asset integration — atom Orbit

Canonical widget revision: 0951319. The plugin pins the full immutable revision
in sources.lock.json and copies the generated fleet/portrait assets unchanged.
All vendored runtime files match that revision, including the integrated
typography changes. Typography no longer needs an additional patch at
this revision; patches/typography.patch is retained as historical provenance.
No provider, authentication, collector or action protocol is changed.

The atom presentation has synchronized rails/task dots, two moving planes, an
open nucleus around the centered original Bot, stable provider offsets, layered
soft neon, and static muted dormant rings. Existing Quiet, motion, theme,
selection, evidence and action semantics remain intact.

## Checks completed locally

- `make check` with Python 3.13: manifest/import/hash/license/single-shell checks,
  10 Python safety/installation tests and 10 Node chat/onboarding tests; shell
  script syntax passes. Python 3.9 cannot run the existing tomllib installer;
  use Python >=3.11 for the full check.
- `tools/render-orbit.py`: actual pinned plugin asset and vendored Qt renderer,
  synthetic inventory, controlled frames and work-row selection pass.
- `tools/render-crew.py`: original Bot onboarding, row expansion and narrow
  light state pass. Row click now follows the actual layout instead of an old
  hardcoded pixel coordinate after the typography change.
- Canonical source passes 264 official OWL tile/screen cases, 36 Linux evaluator
  cases, golden browser/native projection comparisons and 54 portrait parity cases.
- Documentation media is refreshed with the real controlled-time Qt fixture.
  It is not live data or a performance measurement.

## Machine acceptance still required

Follow ../handoffs/atom-orbits.md on the actual Omarchy machine. Isolated macOS
Qt evidence does not prove shell lifecycle, native frame cost, Wayland behavior
or Android/Omalauncher rendering. No release/marketplace submission is implied.
