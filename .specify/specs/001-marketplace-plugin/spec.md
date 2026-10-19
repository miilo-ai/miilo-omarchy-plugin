# Independent Omarchy plugin

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


One public-intended repository owns native shell presentation. Its permanent
identity is `io.miilo.bar`, retained for compatibility with prior local installs.
The root manifest loads `desktop/omarchy/BarWidget.qml`, which opens the nested
dashboard. Shared source is pinned by revision and file hashes, not a sibling path.
The native helper and local collector remain independent binary dependencies.

Selected local sessions require no HTTP server or account.
The UI must distinguish stale/unreachable state from an idle robot. Explanations
must cite supplied evidence; unsupported local approvals must not be invented.
Connections, collector consent and provider state do not become QML domain logic.

Done means portable checks, native shell/QML validation, lifecycle and user tests,
theme/contrast/focus/scroll checks, exact dependency install instructions, clean
removal and owner-authorized marketplace submission at a recorded public revision.
Source-ready, native-ready and officially listed are separate milestones.
