# Active session visibility — 2026-10-17

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Inactive enrolled sessions can crowd the fleet and increase rendering work.
Read-only aggregate inspection found fresh local observation with one working
session and twelve resting sessions; the working session was ninth in the cache.
The first six Orbit cards could therefore show only historical idle sessions.
Full motion was selected; this was not a reduced-motion preference issue.

The shared source and shipped native asset now hide inactive transcript-backed
sessions by default in the fleet, system selector, Quiet and Orbit views. Current
work and sessions needing a decision remain discoverable. Working agents/systems
sort ahead of history when all sessions are revealed. Persistent remote factories
remain accessible even when idle. Existing enrollment, raw snapshots, connections
and observed statuses are unchanged; no activity is invented.

`Show inactive sessions` is an explicit persistent presentation preference. New
activity makes a session visible automatically. An already-open work detail stays
available when its session becomes idle. These changes do not filter the setup
enrollment picker, whose discovery inventory does not assert live activity.

Tests exercise the actual generated and vendored OWL, including thirteen-session
fixtures with current work originally ninth, selector contents, automatic activity
updates, explicit reveal/persistence, open detail retention, unavailable sessions,
pending decisions and idle remote factories. The fixture renders one Orbit field
by default instead of six when inactive history is explicitly revealed. This is
bounded render-work evidence, not a measured live CPU/frame-rate improvement.

Passing checks: shared session visibility, Orbit/motion/54 portrait comparisons,
36 Linux evaluator scenarios, architecture gates, native package/provenance,
23 native Node tests and offscreen typography/configuration tests. The native
asset's attributed patch and SHA256 are updated against its unchanged immutable
source pin. The complete patch was verified against that source.

No installation, shell restart, collector change, new enrollment or provider action
occurred. Rebuild Rust binaries is unnecessary for this presentation-only change;
use the checked native dev-relaunch workflow for the installed update. Actual
shell rendering/performance remains host acceptance.
