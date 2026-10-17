---
name: miilo-desktop
description: Build, update, relaunch, or diagnose the local Miilo desktop on Omarchy, including native crew/Quiet/Orbit presentation and helper binaries. Use for Miilo desktop development and stale installed UI; excludes publishing releases or deploying servers.
---

# Miilo desktop development

When the user requests a local update/rebuild/relaunch, perform the routine checks,
backed-up installation and shell relaunch within the active tool permissions.
Do not make the user repeat authorized routine steps. A skill does not grant
filesystem, network or desktop-socket access: report an actual restriction once,
then provide the exact blocked command. Do not promise execution that did not occur.

## Locate and choose the work

Find `miilo-omarchy-plugin` in the current workspace, or under
`${MIILO_WORKSPACE:-$HOME/Work}`. Read its `AGENTS.md` and native handoff before
changes. Treat repository instructions/current scripts as the source of truth.

- `miilo-omarchy-plugin`: canonical native UI, crew, manifest and lifecycle.
- `miilo-owl-widgets`: generated OWL/RobotProgram, renderer and `miilo-owl`.
- `miilo-cli`: `miilo-local` executable, built by package **miilo-cli**, not the
  library package named miilo-local. SDK dependencies stay at declared pins.
- CE is optional and is not part of the local build/relaunch.

Quiet/Orbit is intentional optional complexity. Preserve it and independent
Full/Reduced/Off controls, saved colors, preferences and current connections.
Do not simplify Orbit as a side effect of maintenance.

## Update and relaunch

From the native repository, inspect/run the maintained wrapper:

```sh
bash tools/dev-relaunch.sh --dry-run
bash tools/dev-relaunch.sh
```

Use `--rebuild` when helper/CLI Rust changed, a required binary is missing, or
installed versions differ from the source manifests:

```sh
bash tools/dev-relaunch.sh --rebuild
```

The rebuild installs both CLI executables. For explicitly requested shared
user-configuration setup, add `--migrate-config`; it copies existing preferences
and connections into `~/.miilo/` (or absolute `MIILO_HOME`) before relaunch,
preserves originals and existing collector configuration paths, and never restarts
the collector. Do not add migration to ordinary update requests. Stop old clients
writing settings before migration; only updated clients understand the new store.

QML/OWL UI-only updates need no Rust rebuild when binaries already match. The
wrapper runs native package/lint and offscreen typography checks, verifies binary
versions, backs up the current native plugin/binaries, installs the canonical UI,
then restarts Omarchy's existing shell, enables/summons `io.miilo.bar` and lists
plugins. `--no-restart` installs without changing shell lifecycle/enablement.
It never starts an additional live Quickshell instance.

Do not use widgets `install-desktop.sh omarchy` or the old typography-only updater
for this canonical native UI: they install the historical flat desktop layout,
which has the same bar ID and does not contain the new native crew components.
Do not overwrite an installed Git checkout or symlink; the installer refuses it
so its changes can be reconciled. Existing flat bar copies are intentionally
backed up and overlaid; legacy dashboard/desktop IDs are left alone.

No automatic Git pulls, dependency pin changes, publishing, provider actions,
new enrollment, collector service restart or disabling other plugins belongs in
this operation. Requests to pull require preserving local work and resolving
known committed divergence deliberately, not reset/clean/force commands.

## Verify and report

Only say the update is installed after file/hash verification. A successful shell
command is not screenshot/native acceptance: inspect the actually displayed
crew screen and optional Orbit view when desktop access is available. Verify
Escape/focus and expected version/status; do not launch agents to fill the scene.
Never change saved view/motion choices merely to make a demonstration look busy.

Report source commit/dirty state, installed versions, backup path, checks and
remaining live-host limits. The installer writes hashes to its private backup
`installed.json`. Stop on a build/check/install/restart failure; do not continue
with stale binaries and call it a successful rebuild. Do not retry failed network
or socket operations indefinitely or bypass a managed sandbox.
