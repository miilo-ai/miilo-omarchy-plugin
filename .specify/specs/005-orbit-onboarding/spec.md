# NATIVE-ORBIT-001 — Orbit hosting and lively local-agent onboarding

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


Status: initial UI candidate implemented; native Omarchy acceptance pending.
Date: 2026-10-17. See ../../evidence/orbit-crew-local.md.
Read ../002-plugin-layout/plan.md and ../../handoffs/omarchy-agent.md first.
Shared animation authority: ORBIT-001 in miilo-owl-widgets. This plugin consumes
its versioned output; it does not create another observer, codec or provider policy.

## Current screen and reconciliation

Current main uses ui/components/LocalImport.qml as coordinator and
ui/components/onboarding/AgentInvitation.qml for a text-only invitation list.
The legacy desktop/LocalImport.qml in widgets is not this plugin's layout authority.
Source baseline: native plugin a63ca81; shared widgets c5cf3e2. Integrate newer
changes through reviewed commits. Preserve typography, controller state,
shortcuts, consent, grouping and native fixes.
Do not merge or overwrite an unknown in-progress branch automatically.

## Design: a welcome crew, not a wizard billboard

Short title: "Your local crew". Supporting line: "Choose which sessions Miilo observes."
A small original Miilo robot (56-72 dp) sits beside the title, with a quiet curious
blink/glance in Full, static expression in Reduced/Off. Decorative gaze implies no
microphone, scanning progress, provider connection or agent communication.
No huge hero, basic provider icon wall, numbered steps or repeated status labels.
The title/robot block should take <=100 dp height at default desktop type settings.
If increased text wraps, expand naturally; never clip or enforce this cap literally.

Invitation uses compact agent rows in a single scrollable surface, not giant cards:
- Original Miilo robot thumbnail (32-40 dp), agent name and capability on the first row.
- One concise secondary line for location, abbreviated to ~/ where appropriate.
- Additional locations expand inline. Do not auto-disclose sensitive full paths.
- Supported setup: "Review sessions" affordance. Discovery-only: "Detected only";
  explanation on expansion states observation is unavailable. No disabled-looking
  supported controls and no green "connected" treatment before actual enrollment.
- Show a session count only after bounded discovery returned it; never invent counts
  from detected commands/directories. Loading/unavailable is different from zero.
- Compact row target >=44 dp; typical desktop row 52-64 dp. Density must preserve
  touch/keyboard targets and text scaling. At narrow widths stack secondary details.

Review mode keeps the same robot/header identity, compact search/folder controls,
agent/project grouping, selected count and one scrollable session list. Use a small
robot per agent group rather than a robot per session. Group rows expand in place.
Primary and secondary actions share a compact footer: "Observe selected" and
"Not now" in invitation/review where appropriate; preserve original operation names
where changing labels could misrepresent what the command does.
No background enrollment; future matching remains an explicit separate off-by-default
choice with its scope explained. Bulk selection reflects only supported selected rows.

## Liveliness and theme

Use theme background/foreground/muted/accent, existing interaction tokens and assigned
robot colors. Header may have a faint accent wash constrained to its bounds; no new
opaque black cards, hard-coded blue core, rainbow bots or forced white electric cores.
A brief acknowledgement on user selection may gently brighten the row/robot.
Full Orbit ornament is reserved for the observatory. Onboarding uses Quiet animation
so text, search, paths and permissions remain easy to read. No electric arcs between
detected agents: detection does not establish a relationship or permission.
Review/import progress must be actual controller state, not fabricated percentages.

Preserve revised typography from native work; target hierarchy is compact title,
normal body, secondary metadata. Use theme font tokens where available, never shrink
text to fit. Accessible names identify agent, capability, selection and expand state.
Do not use color alone to distinguish unavailable, selected, running or failed.

## Components and boundaries

Keep LocalImport as coordinator; proposed small components:
- CrewHeader.qml: title, original mascot and view/motion-aware welcome treatment.
- AgentSetupRow.qml: theme-aware compact row with optional expanded paths.
- RobotPortrait.qml: static/clock-driven original robot presentation adapter.
Reuse generated geometry/semantic states when practical; QML does not reimplement
observation truth. A fixture preview mascot is explicitly decorative, not a live actor.
AgentInvitation and SessionList compose these pieces; OnboardingController and
OnboardingCommands retain state/IO ownership. New authored files <200 lines and
static explicit imports. Do not hand-edit assembled OWL or untracked vendor copies.

## Orbit host integration

Native shell stays a single process; no embedded browser or second Quickshell.
Forward actual surface visibility/activity/minimize state to the shared renderer.
Persist view choice independently from motion and selection. Imported robot colors
and existing config survive. Unknown view identifiers safely fall back to Quiet.
Canvas visual items must have keyboard/list alternatives and reliable focus return.
Review sources.lock.json, source revision and generated asset hashes together.
Runtime patches must be explicit, attributed and tested, not silent vendor drift.

## Validation checkpoints

- [x] Integrate typography/native changes; record resulting revisions.
- [ ] Fixture screenshots: none, supported-only, mixed supported/discovery-only,
      multiple locations, discovery failure, busy import, empty review and many sessions.
- [ ] Header robot appears in invite/review/importing/error; motion follows settings.
- [ ] Paths expand without displacing footer offscreen; all content scrolls by touch.
- [ ] Tab/Shift+Tab, arrows, Space, Enter, Escape and existing shortcuts still work;
      focus remains visible, not trapped; collapsed paths cannot receive hidden focus.
- [ ] Explicit import only, unchecked sessions excluded, future matching off by default,
      error recovery and dismissal preserve expected settings. No new discovery calls
      merely because an animation frame or hover occurs.
- [ ] Light/dark + 3 accents, long names, 125/150/200% text, fractional display scaling
      and narrow window. No label overlap, clipping or icon-center regression.
- [ ] Quiet/Orbit full/reduced/off, hidden/resume and stale provider state qualified.
- [ ] Run make check and native checks; actual Omarchy manifest/shell interactions,
      source hash verification and a short inspected recording. Fake clocks/source
      checks are not native visual/performance evidence.
- [ ] Record a63ca81 comparison and candidate screenshots with actual current revision,
      Qt/shell versions, commands, timing and unresolved gates in .specify/evidence/.

## Native-agent handoff order

First capture current screen, then prototype CrewHeader + one compact row. Inspect
at real demo size before filling all modes. Implement Orbit's one-cluster native
feasibility gate alongside this, then integrate shared output after validation.
Keep commits separate for onboarding composition and Orbit/runtime changes.
Do not publish, tag, submit marketplace changes or alter user config in this task.

References: https://doc.qt.io/qt-6/qml-qtquick-canvas.html and
https://doc.qt.io/qt-6/qtquick-performance.html. Qt 6 ignores Canvas.FramebufferObject;
measure native cost rather than relying on a vendored GPU-path comment.

Reconciliation checkpoint: see ../../evidence/reconciliation-2026-10-17.md.
Typography, outer scrolling and availability guards are combined with the
original-robot crew components. Installed-host acceptance remains pending.
