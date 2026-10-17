# Selected-session visibility — 2026-10-17 handoff

Selected transcript sessions stay visible for twelve hours inclusive after their
last observed activity. Idle actors remain resting/sleeping. Activity and pending
decisions remain visible; persistent remote factories retain existing behavior.
The collector supplies `dev.miilo.session.recentlyActive`; the presentation does
not calculate time or invent an execution state. Expiration follows snapshot
refresh, not an exact wall-clock alarm.

Codex uses source timestamps. Timestamp-free Cursor bootstrap uses transcript
file modification time; subsequent activity uses receipt time. Enrollment and
collector restart do not establish fresh activity. Missing, malformed and future
timestamps do not establish recency. No transcript history is removed.

The inactive-session toggle and its persisted preference are removed. The systems
menu begins collapsed and closes on native surface reactivation. A compact All
control appears only while a system filter is selected, to clear that filter.
Prior group-label display changes are included in this checkpoint.

Evidence: ten Rust library/reader/application tests, CLI executable cargo check,
OWL visibility tests, 36 desktop scenarios, Orbit/motion checks, 54 portrait
comparisons, architecture checks, 24 native Node tests, package hashes, complete
patch applicability to pinned upstream, 14 offscreen typography cases and native
qmllint (existing warnings). Live installed-shell behavior remains unqualified.

Update both the collector and native UI on the host:

```sh
cd "$HOME/Work/miilo-omarchy-plugin" &&
bash tools/dev-relaunch.sh --rebuild &&
systemctl --user restart miilo-local-desktop.service
```

For a manually launched collector, restart that existing invocation instead.
Never run two collectors against the same configuration. This workspace cannot
write the user's install directories or reach the visible shell's IPC.

The systems repository provides `scripts/desktop-demo-sessions.sh`. Default mode
previews three tasks. Explicit `--run` creates three bounded real read-only Codex
sessions with the existing login/configuration and normal model usage. Select
these explicitly in Miilo onboarding; no automatic enrollment or history pruning
occurs. A fake executable verifies opt-in behavior and flags; no real tasks were
launched here. Discovery still lists history; the twelve-hour rule applies to
selected sessions in the main widget.

## Local testing checkpoint

All four affected repositories are checked out on the same branch name,
`feat/session-idle-window`: miilo-cli, miilo-owl-widgets,
miilo-omarchy-plugin and private-application. The systems branch was renamed from
feat/onboarding-demo at the user's request. These are separate Git repositories,
with one coordinated feature name; no checkout or merge is needed before local
testing. This checkpoint includes the earlier group-label fix.

The rebuild wrapper builds from the current local checkouts, including uncommitted
changes. It installs the updated binaries and native UI, then relaunches the
existing shell. Restarting only the shell is insufficient for this change: the
collector must also restart to publish the new twelve-hour eligibility field.
The command above chains each step so later steps run only after success.

The user has received the host build command and subsequently reported that Quiet
selection worked while Orbit tile activation did not (diagnosed below). The exact
host build result and visual acceptance of the latest fix remain unconfirmed.
Next visual checks:

- Open, close and reopen the main widget: systems menu stays collapsed until clicked.
- Recently active selected sessions become sleeping robots when idle.
- Sessions older than twelve hours disappear on a fresh collector snapshot;
  fresh observed activity makes them visible again.
- No inactive-session toggle appears; All clears an explicitly selected filter.
- Confirm Quiet and Orbit retain their chosen appearance and motion settings.
- Run the demo script explicitly if needed, rescan onboarding and select only
  the intended demo sessions; past discovery history is still retained.

Semantica tools were unavailable; this file is the local handoff, not a
shared-memory write.

## Orbit tile activation finding

The user confirmed that Quiet robot selection worked, but clicking the animated
Orbit tile did not open the system's work. Source inspection found activation
handlers on individual Orbit task rows and the overflow action, but none on the
Orbit cluster itself. This was a navigation gap, unrelated to session activity
filtering.

Orbit cluster activation now opens the selected system's existing task-list view.
The saved Orbit preference is preserved; Back returns to the Orbit tiles. Individual
task rows still open their own detail, and the overflow action uses the same system
inspection route. No provider command is issued by navigation.

Evidence: generated-renderer tests cover zero/one/many tasks, system isolation,
view preference preservation and back navigation; the packaged native OWL asset
has a corresponding activation regression check. An offscreen Qt pointer test
confirms child task clicks do not also activate the parent tile (15 typography/
interaction cases passed). All 24 native Node tests, package source hashes and
36 desktop scenarios passed. Installed desktop visual confirmation remains open.

This follow-up changes UI assets only. After the earlier collector rebuild, update
it using `bash tools/dev-relaunch.sh` from the native plugin repository; another
Rust rebuild or collector restart is not needed for tile activation alone.

## Saved commits

All affected repositories use `feat/session-idle-window`. Companion commits:

- miilo-cli: `a544029` — twelve-hour visibility and bootstrap timestamp handling.
- miilo-owl-widgets: `38a3c45` — sleeping sessions, compact controls and Orbit inspection.
- private-application: `4bc235f` — explicit read-only demo sessions and invocation test.

The native plugin commit containing this note includes the synchronized asset,
provenance patch/hash, menu-collapse behavior, group-label display fix, regression
tests and these findings. No push is part of this checkpoint. Unrelated generated
CLI `tools/__pycache__/` files are excluded.

## Mode-aware Back correction

The user subsequently observed a return from the task list to Quiet after entering
from Orbit. Earlier tests covered return only while the global view preference
remained unchanged; they did not establish an explicit navigation origin.

Inspection entry now records a separate non-persisted `inspectionView` for Orbit
tile/overflow, Quiet robot, and compact actor entry. The task-list Back action
restores that origin explicitly and clears the inspection state. Orbit entry
shows “Back to Orbit”; returning retains the Orbit page. This context survives
opening and closing an individual work detail. It is not a new saved preference.

Validation: generated-renderer navigation tests cover both entry modes, nested
work detail, overflow on the second Orbit page, and restoration even if the
general view preference changes during inspection. Native asset regression tests,
all 24 native Node tests, source hashes, 36 desktop scenarios and architecture
checks passed. These checks do not replace the user's next installed-shell test.
The correction is saved on the same feature branch. Widgets companion commit:
`c02f6f8` — restore inspection entry mode on Back. The native commit containing
this update synchronizes the generated asset, provenance and regression test.

Install this UI-only correction with `bash tools/dev-relaunch.sh` from the native
plugin repository. No Rust rebuild or collector restart is needed for navigation.
