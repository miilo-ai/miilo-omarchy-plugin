# Plugin engineering constitution

- Presentation package: ui/shell, ui/components, vendor/owl, assets. No domain engine in QML.
- Explicit component inputs; helper processes in the command adapter; no lazy imports.
- Handwritten modules at most 200 lines. Preserve vendored code, pins and licenses.
- No extra Quickshell process, privileged install, implicit enrollment or credentials in UI.
- User consent, provider-advertised actions, revision safety and stale-state honesty apply.
- Test portable package/controller behavior and separately record native shell acceptance.
- Public documentation describes this package and declared public dependencies only.
- No internal project names, private topology, credentials, transcripts or machine paths.
- Publication and marketplace submission require owner authorization.

## Toolchain boundary

No Python source or tooling dependency in this repository, including CI, installers,
checks, tests and preview capture. Use Rust for application behavior, Node built-ins
for portable development tooling, shell orchestration and native Qt for rendering.
Run `node tools/check-no-python.cjs`; do not bypass it or replace acceptance with a
static image. Historical evidence remains dated and is not rewritten as a new run.

## Untrusted presentation data

Provider/agent names, task/action labels, evidence, placeholders, errors and terminal
output must render literally. Qt text surfaces use Text.PlainText (or the existing
TypeText component); never rely on automatic rich-text detection. Preserve stored
evidence unchanged. New renderer changes require source guards and a native
loopback image-request canary with a positive control. Keep shared and vendored
fixes aligned with reproducible patches and source hashes. See
`docs/omarchy-integration-guide.md`.
