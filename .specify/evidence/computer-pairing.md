# Paired computer native acceptance

October 19, 2026. Feature branch; not installed as a production release.

Validated on a native Omarchy host from an isolated copy of this branch:

- `make check-native check-typography`: source/provenance checks, manifest validation,
  qmllint, Qt settings/navigation/typography, configuration persistence,
  retained-clock/static-scroll checks and plain-text loopback canary passed.
- Dedicated Pair computer page is selectable through wide and narrow settings.
  Selecting it does not launch a terminal. Explicit Configure launches the shared
  helper; existing connection and chat setup are unchanged.
- A real paired TLS feed from macOS returned three providers and three work items.
  The canonical MiiloSurface loaded that feed through the native helper and rendered
  three sleeping robots in an isolated offscreen Quickshell harness. Capture and
  count assertions passed. This proves native rendering, not installation into the
  user's live shell.
- Existing shell instance and installed configuration were preserved. No additional
  live desktop shell was started. Temporary offscreen harnesses used separate state.

The widgets repository records actual Android launcher navigation and cross-device
revocation/restart/staleness tests. Its helper owns pairing and protocol behavior.
Private captures, device addresses, invitations and credentials are not committed.

Subsequent live-shell acceptance: the backed-up candidate was installed with the
maintained native installer and desktop relaunch workflow. The regular window
on workspace 1 displayed the existing factory plus the paired computer sessions.
The owner then explicitly selected the current Codex conversation; the installed
helper received it with no endpoint errors. Exactly one live shell remained.

Keyboard follow-up: native tests exercise actual generated robot cards with Tab,
Enter and Space. Existing activation handlers are retained; a full themed outline
replaces the small edge marker. Transcript-backed rows show the latest summary in
one line instead of repeating the session title. No evidence content is invented.

Desktop density follow-up: overview robot/orbit geometry is scaled by 0.5 in
Detail and Compact modes. The Detail animation band is 82 logical pixels instead
of 164, and cards allow up to four columns with viewport-driven wrapping.
Geometry checks at 480/800/1200 logical widths and the updated existing layout
regressions pass. Full native qualification and the maintained backed-up relaunch
passed; the actual workspace-1 window was visually inspected at its current narrow
size. This is a native plugin presentation patch; Android widget sources and
rendering were not changed by the density follow-up.

Detail task-limit follow-up: native cards default to five visible tasks, with
persisted Appearance choices of 3/5/8/10. Overflow uses the standard themed
“View more” button and opens the full system list. Evaluator tests cover default,
overrides, invalid-value fallback, persistence and access to hidden observations.
The actual Qt settings control is exercised in the native settings fixture.
`make check-native check-typography` and the maintained backed-up relaunch passed.
Installed asset content was verified. Post-relaunch window captures returned black,
so live visual acceptance of this follow-up remains unconfirmed. Android unchanged.

Action alignment follow-up: Controls side is now persisted and passed into native
Import/Cancel layout instead of inferred from typography. Card overflow and
confirmation groups follow the same side; View more uses a smaller button scale.
Filter width reserves the complete Needs you counter, and narrower toolbars split
at 340 logical pixels. Tests cover both action sides, saved state, zero/one-/three-
digit counters, and the actual native import action container. Native qualification
and the maintained backed-up relaunch passed. The earlier black capture was caused
by window coordinates outside the current logical monitor bounds; repositioning
only Miilo resolved it. Live inspection confirmed five factory rows, smaller
right-aligned View more, and the complete Needs you (0) label. Private captures
remain outside source. Android unchanged.
