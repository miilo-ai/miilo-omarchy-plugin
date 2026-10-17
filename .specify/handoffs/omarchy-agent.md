# Native agent handoff

Work in `miilo-ai/miilo-omarchy-plugin`. Its new `main` branch has a clean history.
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
the plugin. Use only the declared dependencies. Use CLI/SDK candidates 0.2.0
and helper 1.4.0 from coordinated `codex/standalone-runtime` branches.

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
