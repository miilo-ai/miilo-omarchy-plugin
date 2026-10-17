# Desktop acceptance test pass — 2026-10-17

Native baseline `36bbc13`, widgets `953eef9`, SDK `25c140d`, CLI `8d293d5`.
New work is on `chore/desktop-acceptance` in native and widgets repositories.
No new main commits, installed update, user migration, collector lifecycle
change, provider action or publication occurred in this pass.

## Passing checks

- Native package/import/license/provenance/single-shell checks pass.
- Native QML lint against installed shell imports exits 0 with warnings.
- Native offscreen typography/onboarding: 14 cases pass, including centered
  robots, right-side selection, child indentation, keyboard exclusion of
  unsupported sessions, path expansion, narrow layouts and increased text.
- Native offscreen configuration: legacy, shared and unsupported-version cases
  pass. Installer temporary-file fixtures: five tests pass, including backups,
  preservation, version mismatch and symlink/Git-checkout refusal.
- Native chat state, onboarding, package and source-policy unit tests: 18 pass.
- Widgets motion/Orbit generated drawing checks and 54 exact portrait comparisons
  pass. Architecture, release SDK-access and source-policy tests: nine pass.
- Rebuilt xtask: five release-policy tests and 36 Linux OWL scenarios pass.
- Rust SDK default-feature suite: 11 tests pass, including the new configuration
  contract. CLI configuration, archive and standalone executable tests pass;
  client unit tests also pass before the workspace socket-test blocker below.
  The local collector package was tested separately: four tests pass.
- Sixteen selected helper integration suites: 41 tests pass. They cover ports,
  action boundaries, artifacts, chat policy/streams, credentials, installation,
  aliases, graph, discovery/import, snapshots, projection, setup and configuration.
- Cargo used a writable temporary copy of the host's dependency caches, offline,
  retaining declared dependency pins and lockfiles. No local dependency overrides.

## Test correction

The setup-row layout test still asserted pre-density padding of 4.8px while the
approved design halves it to 2.4px. The test now checks the phone touch-target
minimum instead of pinning obsolete spacing. Vertical alignment tests remain;
the compact design was not reverted.

## Environment limits and remaining host acceptance

The coordinated full-workspace command does not pass in this session. The client
compression integration test cannot bind its loopback HTTP listener: the OS
returns PermissionDenied/Operation not permitted. Later HTTP suites therefore
remain unqualified here. This is not reported as a passing or skipped full suite.

Node's Git subprocess call reports EPERM here. The same source-policy checker
was run with the real Git file list supplied through stdin; it passes. Node tests
ran with supported in-process test isolation, preserving their assertions. The
unaltered make check entry point still needs qualification on the normal host.
Installer subprocess fixtures themselves passed. No error was ignored in source.

CMake is absent, so the new native C++ capture harness was not rebuilt in this
pass. Existing screenshots are dated evidence, not a replacement for that run.
Shell IPC remains unavailable: the wrapper reports the shell is not running,
which does not establish that the user's visible desktop shell is absent.

Next host command: `bash tools/qualify-user-config.sh` (no install flag). Then
qualify the actual installed UI: open/close/reopen, Escape/focus, one-shell
lifecycle, saved settings, themes/scaling, real observations, install/update/remove
preservation, and hidden/Off/many-system CPU/RSS/frame scheduling. The generic
renderer still schedules frames from animated/active/visible; static Off drawing
tests do not prove zero callbacks. Physical Android acceptance remains separate.

Chat M3 panel/process bridge, chat M4 host acceptance and M5 configured Gemma
proof remain pending. Optional Orbit picking/event one-shots/transitions remain
distinct from basic acceptance. Voice remains explicitly deferred. Publication
requires separate authorization. Shared-memory tools were unavailable; no shared
memory read/write occurred.
