# Native acceptance checkpoint — 2026-10-17

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Partial qualification only. Plugin source: `40be809`; shared widgets: `0951319`.
No installed update, restart, enrollment or preference change occurred.

## Environment and passing checks

- Omarchy `4.0.4-1`, Quickshell `0.3.1` (Arch package), Qt `6.11.2`.
- `make check-native check-typography` with installed Qt tools and shell imports:
  exit 0. Includes source/provenance checks, 10 Python tests, Node suites,
  shell syntax, native lint and 12 passing offscreen typography/interaction cases.
  Native lint emits warnings; this is not a warning-free qualification.
- Widgets `node tools/test-robot-motion.cjs`, `node tools/test-orbit.cjs`,
  `node tools/test-portrait.cjs`: each exit 0. Controlled rendering checks cover
  motion preferences, stale state, themes, selection and 54 exact portrait
  comparisons. They do not measure live animation performance.

## Blocked host operations

- `bash tools/dev-relaunch.sh --rebuild`: exit 101 before installation. Cargo
  cannot create its SDK Git cache directory because the session exposes that
  cache as read-only. The workflow correctly stopped at the first failure.
- Installed helper and existing workspace debug helper both report `1.3.0`;
  the plugin requires `1.4.0`. The installed local executable exposes the older
  discover/setup/run interface. Do not substitute these for qualified binaries.
- `omarchy-shell shell ping` and `omarchy plugin list --json` both report
  `omarchy-shell is not running` in this session. This does not establish that
  the user's visible desktop shell is absent; live IPC acceptance is unavailable.
- The Python render fixtures could not run: PySide6 is not installed in the
  system Python. The independent Quickshell typography fixture did run offscreen.

## Remaining acceptance

Run the maintained rebuild/relaunch workflow in a host-capable session; record
installed hashes, versions and backup path. Then follow
`../handoffs/atom-orbits.md`: open/close/Escape/focus, single-shell lifecycle,
preferences, themes/scaling, session updates, explicit enrollment boundaries,
update/removal preservation and many-system CPU/RSS/frame measurements.

The vendored OwlWidget frame scheduler still gates on active/visible/animated,
without an explicit robotMotion Off gate. Static drawing tests alone cannot
prove zero callbacks; measure and resolve this upstream before claiming idle
performance qualification. Preserve intentional Full animation and Quiet/Orbit.

Android, graphical chat integration and publication remain separate gates.
Shared-memory tools were unavailable; no shared-memory read/write occurred.
