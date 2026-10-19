# Atom Orbit — native testing handoff

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


Pull current main in the widget and plugin repositories after preserving your
local changes. Plugin sources.lock.json pins the exact tested shared asset; do
not regenerate from an older widget checkout or overwrite canonical native UI.
Typography, setup, chat stream state and the native relaunch workflow were kept.

Use the repository's skills/miilo-desktop/SKILL.md and tools/dev-relaunch.sh for
an intentional installed update. Do not run the legacy widget installer to
update the native crew UI. No CLI/helper rebuild is required solely for these
presentation changes; use --rebuild only when those binaries also changed.

## Expected visuals

- Original robots, centered inside two gently sweeping atom planes.
- No rail or straight line crossing the face; task dots stay on their own rails.
- Different system phase offsets remain stable when selecting/filtering systems.
- Faint theme-colored neon around active rings; slightly softer rear halves.
- Dormant systems: muted stationary rings without glow, original sleep reactions.
- Quiet / Full / Reduced / Off and Calm continue to respect saved preferences.
- Zaps remain brief decorative active-work activity, never an action receipt.

## Validate on the real machine

1. Load the existing shell once; open, close/reopen, Escape, focus and rescan.
2. Compare 1, 3 and >6 systems, then select/filter one without offset resets.
3. Search, pagination, task selection, evidence scrolling and existing advertised
   approve/reject/retry confirmation flows on an explicitly permitted fixture.
4. Dark/light, two theme accents, custom robot colors, large text and fractional
   scaling. Narrow portrait and wide layouts should retain readable state rows.
5. Full, Reduced, Off and Calm. Stale/offline sources stop orbital motion.
6. Measure CPU/RSS/frame cost with many tasks and when hidden/minimized. Record
   actual results; controlled-time media is not proof of native frame rate.
7. Qualify Omalauncher on Android separately: rendering, touch/scroll, theme
   changes and motion preferences. Do not equate desktop OWL parity with phone QA.

Record sanitized evidence, revisions, host versions and remaining issues in
../evidence/native-acceptance.md. Do not publish/tag/submit without owner approval.
