# Native agent handoff

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


Work in `miilo-ai/miilo-omarchy-plugin`. The canonical development branch is `main`.
Do not reset your existing work. Review and port relevant newer QML changes with
attribution. The canonical marketplace ID is `io.miilo.bar`; the default manifest
declares only `bar-widget`, with the dashboard loaded internally.

Read both official guides before changing the runtime contract:
- https://plugins.omarchy.org/develop.html
- https://plugins.omarchy.org/publish.html
- https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md

## Ownership and prerequisites

This repository owns native QML, manifest/lifecycle, shell styling, screenshots,
and native acceptance. Widgets owns miilo-owl and shared OWL/evaluator design.
CLI owns miilo-local; SDK owns domain state. Do not move any of these engines into
the plugin. Use only the declared dependencies. Use CLI 0.3.0 and helper 1.5.0 for the seven-agent observation contract.
The SDK remains at the dependency revision declared by those packages.

Use existing authorized GitHub access while private; no publishing token belongs
in QML, repository URLs or screenshots. Record exact revisions and binary hashes.
Local session enrollment is explicit. No agent work may be launched/resumed for
discovery tests. Test with disposable XDG paths and preserve existing connections.

## Native acceptance

1. Capture OS, Omarchy/Quattro, Qt, Quickshell versions and binary locations.
   Verify the installed shell supports the linked guide, not just that command names exist.
2. Run `make check`, then `make check-native`. It must fail when native tools or
   shell imports are absent. Portable checks are not a substitute for qmllint.
3. Install into the user-owned plugin directory using Omarchy's supported path.
   Resolve an existing io.miilo.bar checkout deliberately, never overwrite it blind.
4. Inspect `omarchy plugin list --json`. Test click, summon, hide, Escape, repeated
   close/open, disable/re-enable, shell restart, update and removal.
5. Confirm exactly one shell process. The dashboard is currently a floating window.
   Check focus returns to the bar and no focus trap remains after closing.
   If replacing it with an anchored panel, follow the guide's lifecycle forwarding,
   bar/anchor/host injection, PanelKeyCatcher and panel-switching contract together.
6. Light/dark, at least two accents, increased font/spacing, fractional scaling,
   narrow displays and reduced motion. Qt 6.12 needs qualified Commons.Color;
   the extraction applies that alias in the Omarchy dashboard wrapper.
7. Empty/one/many robots, search/filter, long labels, scrolling evidence, setup,
   action confirmation only where advertised; missing helpers show honest failure.
8. Import selected Codex/Cursor sessions. CE must be absent in this disposable
   environment. Observe natural updates, collector restart and explicit stale cache.
   Verify unchecked sessions stay excluded and future enrollment remains opt-in.
9. Preserve remote endpoints. Read-only sessions must never show approve/reject.
   A provider action test needs a permitted non-production fixture, not a real approval.
10. Removal must leave connections/data and unrelated plugins intact. Stopping the
    owned collector is separate and explicit. Ensure diagnostics stay outside source.

Record results in `.specify/evidence/native-acceptance.md`: revision, versions,
commands, exit codes, sanitized screenshots, outcomes and limitations. The
source-check report is not native evidence. Stop short of publishing/submitting.

## Publication handoff

Use `docs/marketplace.md` for the exact submission form and checklist. A real
preview and qualified dependency install are remaining gates. Do not represent
registration as completed before maintainer approval. Update the widgets URL only
after its actual organization transfer.

## Modular layout checkpoint

The plugin now uses ui/shell, ui/components/onboarding, vendor/owl and assets.
The command adapter owns Quickshell processes; the controller owns onboarding
view state. LocalImport is the focus/shortcut/layout coordinator. View IDs remain
local to each component. Review the new hierarchy before porting older UI tests.
Test group draft resets on each edit, click/keyboard selection, partial selection,
Escape/focus return, async error recovery, invitation dismissal and close/reopen.
Node controller checks are not QML execution; make check-native is still required.

## Chat-first follow-up

See [chat-native.md](chat-native.md) for the tested helper boundary and pending
graphical/native work. This does not replace the observation acceptance checklist.

## Robot personality checkpoint

Shared widget source now includes original focused/error/attention expressions,
brief decorative winks and saved Calm/Expressive, Full/Reduced/Off and pace
controls in widget setup. No Omi design or animation pack is included.
Portable official OWL syntax, Linux evaluator and controlled-time draw tests pass.
Native agent: verify the new options through the actual dashboard, persist across
shell restart, check all states in light/dark at smallest supported size, and
measure many-agent performance. Off must freeze robot drawing; Reduced removes
body/glance/wink/drifting Z movement but retains blinks. Manual settings currently
do not automatically follow OS reduced motion. Completion/recovery one-shots
remain planned; do not treat decorative winks as provider event receipts.

## Lossless compression checkpoint — COMPRESS-001

Use the matching widget helper source checkpoint c5cf3e2 or its subsequently
qualified release. Its remote JSON transport negotiates gzip/Brotli/zstd and
keeps the 2,000,000-byte decoded cap. No OWL renderer/provider engine is copied
into this plugin. Existing source provenance stays pinned to unchanged assets.

The native CLI now exposes local `archive export`, `archive inspect`, and
`archive restore`, plus raw streaming compress/decompress commands. Test with
an explicitly created synthetic file in a disposable directory. Verify exact
restore, refuse existing outputs, and verify damaged bundles fail. Do not use
real transcripts without the owner's explicit file selection. Do not silently
enroll restored data. Compression is not encryption or context compaction.

Source/socket tests passed on macOS and ARM64 Linux/musl. Native agent should
verify the actually installed helper connects to an eligible compressed CE
response, with existing action/session behavior preserved. SSE/voice stay
uncompressed; ordinary UI and onboarding semantics are unchanged. Physical
Android/Omarchy performance and installed release artifacts remain native gates.

## Orbit / Crew candidate

See ../specs/005-orbit-onboarding/spec.md and ../evidence/orbit-crew-local.md.
Pull matching main assets after preserving local native edits. New robot invitation,
compact expandable agent rows and group portraits are implemented. Shared Orbit
uses existing helper snapshots; no new CLI generation command is needed. Start
with actual shell screenshots and close/open/focus, then measure frame cost.
Local Qt fixtures are available via make render-design but are not shell acceptance.

## Updated atom Orbit presentation

See [atom-orbits.md](atom-orbits.md) for the synchronized projection, current
native asset pin, expected visuals and machine acceptance checklist. The previous
+/-45 degree rocking preview is superseded. Existing native typography/setup/chat
work is preserved; the plugin has its own isolated Orbit render fixture now.

## Python-free tooling follow-up — 2026-10-17

Pull the coordinated tooling update before testing. Run `make check` with Node 22+,
then the existing `make check-native check-typography` on Omarchy. The native
installer is now tools/install-dev-plugin.cjs; dev-relaunch.sh selects Node via
MIILO_NODE. Do not restore the removed installer or capture drivers.
Use docs/development-toolchain.md for native Qt captures. Preserve shell
lifecycle, actual-host typography, shared configuration and physical-phone gates.
The portable Node installer tests exercise real temporary filesystem writes with
inert version-only binaries; they do not qualify installed Omarchy behavior.

## Approved density follow-up

Pull main and review ../evidence/approved-density-2026-10-17.md. Check the 22px desktop rows, one-line truncation, half-height vertical control padding, outlined evidence/diffs and smooth static arc in the actual shell. Run make check-native and inspect increased text scale, focus, scrolling, narrow layouts and phone touch targets. Use disposable data; do not enroll sessions or invoke provider actions as part of presentation checks.
