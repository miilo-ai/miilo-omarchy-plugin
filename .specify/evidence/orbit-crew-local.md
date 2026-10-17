# Orbit / Crew local candidate — 2026-10-17

Source: shared widget revision in sources.lock.json, candidate plugin commit history.
New authored UI modules are each below 200 lines. No controller/command policy changes.

Passed locally:
- Package provenance/import/module-size checks and six package safety regressions.
- Four existing onboarding controller tests, preserving selection and opt-in behavior.
- Actual Qt 6.12.0 software/offscreen render on macOS of CrewHeader, RobotPortrait,
  AgentInvitation and AgentSetupRow; real row click expands locations.
- Inspected dark, expanded and 360 dp light screenshots with actual styled footer
  controls. Fixture returned no QML warnings. Platform font diagnostics are separate.
- Shared Orbit official compiler acceptance, 264 existing Kotlin fixture evaluations,
  36 Linux evaluator scenarios and new controlled-clock Orbit tests are recorded
  in the shared repository. Its actual Qt renderer fixture opens existing work details.

Reproduce component images with tools/render-crew.py; test-only environment stub,
synthetic agents, no real import or process call. No screenshots claim to be captured
from an installed Omarchy shell. Physical host typography/theme, lifecycle, touch,
keyboard, focus return, performance and native Android remain pending.

Reported extra native typography edits were not visible on the fetched remote main
heads before this increment. Native agent must reconcile them, not silently discard.
