# Python-free presentation tooling — 2026-10-17

## Scope and boundaries

The runtime remains Rust plus OWL/QML. Portable repository tools use Node 22
built-ins with static imports and no npm dependencies. Isolated preview capture
uses a native C++17/Qt 6 harness with CMake. Domain/provider logic was not moved
into the plugin. Authored replacement modules remain below 200 lines.

The previous Python drivers and tests have been replaced and removed from the
working tree. Historical evidence remains unchanged and dated. The constitution
and CI now run tools/check-no-python.cjs to reject reintroduction.

## Completed validation

- [x] Source and active toolchain contain no Python files or dependencies.
- [x] Real Qt Orbit capture and work-row selection pass in both repositories.
- [x] Original robot presentation, attention marks and deterministic motion remain.
- [x] Tokyo Night recording rebuilt from 241 native Qt frames, without PySide.
- [x] Changes preserve existing local design and incoming main-branch edits.

Qt 6.11.2 on macOS rendered the isolated fixtures. Font-alias and inherited-palette
advisories were printed; they did not prevent drawing or interaction. This is
not actual Omarchy shell, physical Android or live-provider acceptance.

No release, tag, marketplace publication or deployment was performed.

Plugin-specific checks: make check passed, covering 22 UI/installer/package tests
and one no-Python regression, source hashes, local imports, licenses, shell
syntax and cargo authentication checks. The actual installer CLI also passed
against disposable destinations with version-only fixture binaries. It preserves
backups, connections, other plugins and refuses symlinks/Git checkouts before
writes. Native Qt crew dark/narrow-light render and real expansion passed.

Run make check-native check-typography on Omarchy for the remaining shell,
actual-host typography/configuration, focus and lifecycle gates. The Mac does
not have Quickshell; those checks are not claimed here. See the native agent
handoff and docs/development-toolchain.md.
