# Miilo Omarchy plugin

Read `.specify/handoffs/omarchy-agent.md` before editing. Keep authored modules
small; no lazy imports. The vendored renderer is an attributed exception to file
size preferences. Preserve its notices. Avoid forked domain/provider logic.
Never commit credentials, private transcript content or personal machine paths.
Never start another Quickshell instance from a native plugin. No privileged
installer or implicit enrollment. Keep state/logs outside the plugin checkout.
Do not delete legacy widgets or user configuration during this migration.
Record native evidence honestly; portable source checks cannot prove shell load.
Do not publish, change visibility or submit to the marketplace without owner approval.

Work on succinct `feat/<topic>`, `fix/<topic>` or `chore/<topic>` branches.
Keep new implementation and testing commits off `main`; preserve other agents'
work and reconcile branches deliberately when integration is requested.

For local build/update/relaunch work, read `skills/miilo-desktop/SKILL.md` and use
`tools/dev-relaunch.sh`. This workflow preserves the canonical native layout;
the legacy widgets installer does not install the native crew UI. The skill
does not override the active filesystem, network or desktop-socket permissions.

Before changing QML text, renderer imports or display controls, read
`docs/omarchy-integration-guide.md`. Untrusted display strings must use explicit
plain-text rendering. Run source guards and the native positive-control network
canary; preserve the shared renderer fix and vendored patch/hash provenance.
