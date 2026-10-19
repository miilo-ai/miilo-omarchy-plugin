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
