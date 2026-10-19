# Shared user configuration checkpoint — 2026-10-17

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Coordinated source candidate across SDK, CLI, widgets helper and native plugin.
The user configuration root is `~/.miilo/`. No real user migration,
installation, collector change or desktop restart was performed in this session.

## Outcome

- SDK owns the version-1 user activation manifest JSON schema and storage contract
  in `docs/user-configuration.md`. Existing JSON formats avoid lossy conversion.
- CLI exposes `miilo config paths|init|migrate|check`, also through local commands.
  Explicit copy migration preserves originals and byte contents, refuses unsafe
  or conflicting files and activates only after staging and rechecking sources.
  Directories are 700, files 600; publication is no-clobber with file/directory sync.
- New installations use a local configuration under the shared root. Existing
  collector configurations remain at their existing paths via `localConfigFile`;
  no session duplication, service rewrite, cache move or restart is implicit.
- Updated helper selects shared connections/chat after activation. Native UI
  selects shared preferences only after resolving the manifest, and blocks load
  on invalid/unsupported configuration instead of overwriting preferences.
  Explicit environment overrides and legacy fallback remain supported.
- Rebuild installs `miilo` as well as `miilo-local` and `miilo-owl`. Explicit
  `--migrate-config` runs migration before shell relaunch. The qualification
  script runs coordinated tests before an optional installation/migration.

## Evidence

- `make check-native check-typography`: exit 0 with installed Qt/shell imports.
  Includes package tests, native lint (existing warnings), 12 typography cases
  and new offscreen legacy/shared/unsupported-manifest configuration cases.
  Synthetic OWL fixture performs no provider work or helper commands.
- The actual CLI configuration/files/migration modules and helper configuration
  module compile in an isolated dependency-minimal Cargo harness. Seven CLI
  migration tests and two helper store-selection tests pass. CLI modules also
  pass isolated Clippy with warnings denied. The helper harness uses a probe
  executable around Store::from_env/load; it does not qualify HTTP or the actual
  complete executable. This is not full-workspace integration evidence.
- Architecture and negative architecture tests pass in SDK, CLI and widgets;
  formatting and whitespace checks pass. Native skill validates.
- The SDK user-configuration contract and tests are Rust, using existing Serde
  dependencies. Four tests pass against the actual SDK source in the isolated
  harness: valid manifests, invalid/future/null/relative input, unknown-field
  preservation and alignment with the declarative JSON schema. The new Python
  test was removed; this workflow has no uv/pytest/schema-library requirement.
- Full workspace/SDK-crate testing remains blocked by uncached Brotli dependencies
  with network disabled. Original builds also encounter the read-only default
  Cargo cache. No dependency pins or locks were changed.

## Remaining work

On the normal host, close old Miilo UI writers, then run
`bash tools/qualify-user-config.sh --install` from the native repository.
It runs SDK configuration contract tests and full CLI/helper Rust tests before invoking the
checked rebuild, backed-up install, explicit migration and existing-shell relaunch.
Failure stops subsequent steps. Record actual installed hashes/backups and verify
saved Quiet/Orbit, motion/colors and local/remote connections in the visible UI.

Credential formats remain compatible, including existing private inline tokens.
Keyring conversion, project configuration, graphical chat and release remain
separate work. Old binaries still use old stores; do not alternate old/new clients.
Shared-memory tools were unavailable; no shared-memory read/write occurred.
