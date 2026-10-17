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
