# Uninstall validation — 2026-10-18

Current outcome: the two reproduced lifecycle races were corrected in
`8f4bbfe8140f7405164791a9ee488762cb71c582` and passed the physical retest below.
Earlier failure records are retained as historical evidence. Broader marketplace
acceptance remains separate.

Reviewed candidate: `2454789404785af5aedeaf7db84d2b6002de2e99`
(`origin/feat/safe-uninstall`). Follow-up worktree branch:
`fix/uninstall-validation`. This is partial validation, not marketplace acceptance.

- `node tests/uninstall.test.mjs`: exit 0, all six tests pass. Exercises preview,
  confirmed disable/remove order, repeat removal, retained synthetic config,
  disable/remove/list failures, conflicting flags, and edited Git checkout refusal.
- `bash -n uninstall.sh`: exit 0.
- `make check-native`: exit 2 before native validation. The initial portable
  checker reports `spawnSync git EPERM` on Node 26.8.2 in the restricted agent
  environment. This is an execution limitation, not proof of a source failure.
- `qmllint` is absent from PATH. Native QML qualification is still open.
- Read the installed manager's remove/disable source: the candidate uses supported
  commands and `--yes`; the manager unlinks symlinks, deletes Git directories,
  backs up hand-copied folders and rescans the shell. Source inspection does not
  establish runtime unload behavior.

No actual plugin was disabled, removed, installed or reconfigured. No real
credentials, connections, observations or collectors were touched.

Next: follow `.specify/handoffs/uninstall-validation.md` on a disposable Omarchy
profile/VM. Record Git and hand-copied removal, open-dashboard unload and request
termination, unrelated widget survival, retained resource hashes, reinstall,
restart, and injected manager/inventory failures. Keep the native gate open until
that evidence exists. Do not submit or publish on the basis of these checks.

## Authorized physical laptop continuation — 2026-10-18

The owner explicitly authorized this laptop as the test machine, superseding the
handoff's disposable-host restriction for this run. Candidate remains
`2454789404785af5aedeaf7db84d2b6002de2e99`; work stayed on
`fix/uninstall-validation`. No implementation change or publication occurred.

### Environment and checks

- Omarchy `4.0.4-1`; Quickshell `0.3.1` (Arch); qt6-base `6.11.2-3`,
  qt6-declarative `6.11.2-1`; installed helper `miilo-owl 1.4.0`,
  local CLI `miilo-local 0.2.0`.
- Actual shell IPC answered `ok`. One live `quickshell -n -p
  /usr/share/omarchy/shell` process was observed at each sampled checkpoint.
- Initial direct `make check-native check-typography`: exit 2, after portable
  checks passed, because Qt tools were outside PATH. With
  `PATH=/usr/lib/qt6/bin:$PATH OMARCHY_PATH=/usr/share/omarchy`, the same check
  passed, exit 0. Native lint emits warnings. Typography reported
  `MIILO_TYPOGRAPHY_OK 15 0`; configuration fixtures reported `MIILO_CONFIG_OK`.
  These fixtures are offscreen checks, separate from live shell evidence.

### Physical operations and actual outcomes

- Backed up the original hand-copied native plugin and shell configuration before
  mutations. Collected private hash/inventory/service snapshots outside source.
- Preview `bash uninstall.sh`: exit 0; no removal. Opened the actual dashboard
  through `omarchy-shell shell summon io.miilo.bar '{}'`. Hyprland reported a
  visible `org.quickshell` window titled Miilo at logical `(312,38)`, size
  `281x306`, on a 1920x1080 display at scale 1.6.
- Confirmed removal closed that window and moved the hand-copied folder into the
  manager's hidden backup. The wrapper printed `Miilo remains registered or
  inventory is invalid; removal is incomplete.` A second canonical hand-copy
  removal reproduced this with recorded exit 1. Later inventory excluded
  `io.miilo.bar`; repeated removal returned exit 0 and already-absent text.
- Restarted the existing shell while Miilo was absent. Post-restart inventory
  still excluded the plugin. No extra live shell was started.
- Reinstalled through `bash tools/dev-relaunch.sh`, exit 0. External temporary
  sibling symlinks supplied the wrapper's expected source-manifest layout; no
  source pins or binaries changed. The wrapper's immediate summon returned
  `unknown`. Subsequent summon logged `no live bar widget`; one additional
  supported `omarchy restart shell` restored the actual dashboard. This is a
  relaunch defect/limitation despite the wrapper's zero exit status.
- Exercised a clean local Git clone of the reviewed branch at the native install
  location. Added an untracked synthetic probe: confirmed removal returned exit
  1 with `Installed checkout has local changes; preserve them before removal.`
  Moved the probe outside the checkout, then confirmed removal: the manager
  deleted the Git install, but immediate wrapper verification again returned
  exit 1. Later inventory showed absence; repeat removal returned exit 0.
  Git-open-window sampling was empty, so this run does NOT qualify Git removal
  with a demonstrably open dashboard.
- Final reinstall through the maintained wrapper returned exit 0 and again
  printed `unknown` on immediate summon. An additional supported shell restart
  followed by summon returned `ok`; Hyprland then confirmed the visible Miilo
  window. A cropped screenshot was captured and the reinstalled UI was visually
  inspected. The small retained window clips dashboard content; this does not
  qualify layout/scaling acceptance.

### Preservation and final state

- 74 retained files were hashed across the shared configuration, preferences,
  connections, helper/CLI binaries, collector unit and unrelated/legacy plugin
  files. All matched the baseline except the live connection snapshot cache,
  which changed during continued observation. No settings migration occurred.
- The independent collector remained active/running with the SAME MainPID
  `1408350`, zero restarts, and unchanged monotonic start timestamp throughout.
  It was never stopped, restarted or reconfigured.
- Unrelated plugin inventory and enablement were unchanged at sampled checkpoints;
  unrelated and legacy plugin file hashes were unchanged.
- Final native installation contains 41 managed files; each matches its recorded
  installer SHA-256. Installed source revision is the candidate above. Final
  sampled shell PID was `2800873`; exactly one live Quickshell process remained.
- Manager backups intentionally remain. Final installer backup is
  `$XDG_STATE_HOME/miilo/plugin-backups/native-LjKFmg` (default user state root).
  Exact hashes, inventories, command exit records, logs, original-install backup
  and private screenshots remain in `/tmp/miilo-uninstall-native-evidence`.
  These artifacts can contain private metadata and were not added to source.

### Remaining gates / interpretation

The physical test found reproducible timing-sensitive verification failures:
manager removal precedes eventual inventory absence, and the relaunch wrapper
can exit 0 before a working bar widget is available. Treat the candidate as
FAILED immediate native lifecycle acceptance, with the laptop recovered to a
verified, visible reinstall. Do not suppress these errors or claim a fully
passing uninstall/reinstall based on eventual recovery.

Transient request PID termination, retry suppression over time, Escape/focus,
injected *native* manager failures and visual survival of every unrelated widget
were not instrumented here. Fake-manager failure tests remain source evidence
only. No new enrollment or provider action was requested. Shared-memory tools
were unavailable; no Semantica read or write occurred.

## Corrected lifecycle — physical retest, 2026-10-18

Tested implementation: `8f4bbfe8140f7405164791a9ee488762cb71c582`.
The owner authorized correction, further native validation, and pushing the
reviewed branch. This section supersedes the two lifecycle failures above.

### Correction and regression checks

- Confirmed in the installed shell source: plugin scanning runs in an asynchronous
  Process; rescan IPC returns before the new inventory is installed. Summon
  explicitly returns `ok` or `unknown`, independently of the IPC process exit.
- Uninstall now polls valid inventory for absence for up to ten seconds, with
  bounded per-command execution. It fails on unavailable/malformed inventory,
  a surviving install path, or a deadline, and never repeats disable/remove.
- Relaunch now rescans/discovers and persists enablement BEFORE restarting the
  existing shell. It waits for the live widget to accept summon (`ok`), including
  brief startup transport failures. It does not rescan the newly starting shell
  or automatically launch another live instance. Unexpected responses and
  permanent failure return nonzero instead of printing completion.
- The first revised relaunch attempt stopped with exit 1 on an early startup
  transport timeout. That observed condition led to the bounded startup retry;
  its regression fixture now passes. The failed attempt is retained in the logs.
- Both successful revised wrapper runs passed `make check-native
  check-typography`: 37 main Node tests passed, plus the tooling guard test,
  syntax/authentication checks, native manifest/QML lint, typography and
  configuration fixtures. Native lint warnings remain. New cases cover stale
  removal inventory, permanent staleness, malformed/unavailable verification,
  leftover files, delayed discovery/summon, transient startup transport failure,
  invalid replies and permanent `unknown` despite IPC exit zero.

### Actual host retest

| Operation | Exit | Native result |
| --- | --- | --- |
| Corrected hand-copy removal | 0 | Manager backup created; inventory became absent |
| Repeat hand-copy removal | 0 | Already absent |
| Revised relaunch after startup retry correction | 0 | One restart; live widget accepted summon; window confirmed |
| Removal using installed corrected uninstall.sh | 0 | Open Miilo window disappeared; inventory absent |
| Git install with synthetic untracked edit | 1 | Refused before disabling/removing; probe preserved |
| Clean Git removal using installed corrected uninstall.sh | 0 | Git folder removed; previously confirmed open Miilo window disappeared |
| Repeat Git removal | 0 | Already absent |
| Restart while removed | 0 | Fresh inventory still absent; no reappearance |
| Final maintained reinstall/relaunch | 0 | One restart; `Miilo live bar widget accepted summon.`; visible Miilo window confirmed |

The Git installation was a local clone of the tested commit, not a different
remote revision. Its temporary edit was moved outside source before removal.
Before/after Hyprland window metadata and cropped live screenshots were saved;
these are actual Wayland captures, separate from offscreen fixture results.
The final screenshot was visually inspected. The existing small window still
clips content; this test does not claim to correct or qualify that layout.

### Preservation and recovered installation

- All 74 retained file hashes matched the original baseline except the continuously
  updated live snapshot cache. Preferences, connection configuration, shared
  binaries, collector unit and unrelated/legacy plugin files were unchanged.
- The shell configuration was byte-for-byte identical to its original backup.
  Unrelated plugin inventory/enablement was unchanged.
- Independent collector MainPID stayed `1408350`, active/running, with zero
  restarts and the same monotonic start timestamp throughout BOTH test runs.
- Final live shell: exactly one Quickshell process, sampled PID `2825123`.
- Final installed source: `8f4bbfe8140f7405164791a9ee488762cb71c582`;
  all 41 managed files matched installer SHA-256 records. Final backup:
  `$XDG_STATE_HOME/miilo/plugin-backups/native-Qlti32` (default user state root).
- Private command exit records, hashes, inventories, logs and screenshots remain
  outside source in `/tmp/miilo-uninstall-native-evidence`. The final summary is
  `corrected-summary.json`; successful wrapper logs are `fixed-reinstall-2.log`
  and `fixed-final-reinstall.log`. No private captures or settings were committed.

The reproduced uninstall/reinstall defects are corrected and physically validated.
The uninstrumented transient-request, long-duration retry, Escape/focus and wider
presentation/provider/marketplace gates listed earlier remain separate; they are
not prerequisites to recognizing this scoped lifecycle correction.
