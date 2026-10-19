# Paired computer settings

Provide a dedicated Pair computer settings page on desktop and narrow layouts.
Opening the page must not start a process. Explicit configuration launches the
shared `miilo-owl pair` helper. Explain the private invitation, comparison code,
host approval and read-only selected observations. Keep the existing connection
and chat flows independent. Require helper 1.7.0 and host CLI 0.4.0 for this flow.

Explicitly selected paired sessions remain visible when idle, retaining their
reported status. Local discovery's historical-session filtering is unchanged.
Provider rendering uses the host's human-readable name. Never duplicate pairing,
credential or provider logic in QML. Preserve plain-text rendering and upstream
OWL provenance, with the presentation patch recorded in sources.lock.json.

Qualify the page through native Qt tests, source guards and the loopback canary.
Network pairing is validated separately using real native helpers; Qt tests alone
do not establish protocol or installed-shell acceptance.
