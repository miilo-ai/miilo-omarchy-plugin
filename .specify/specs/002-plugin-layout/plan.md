# Proposed presentation layout

Status: implemented; portable validation recorded. Native qualification pending.

```text
manifest.json                 # marketplace discovery contract
ui/shell/                     # Omarchy entry point and lifecycle/theme integration
ui/components/                # Dashboard, fleet surface, local onboarding view
vendor/owl/                   # attributed evaluator/runtime, licenses, upstream pin
assets/                       # generated fleet OWL
sources.lock.json             # reviewed source revision, hashes and local patches
tools/                        # portable checks and native validation
tests/                       # package safety and native interaction coverage
docs/                        # install, configuration, registration
.specify/                     # requirements, handoff, evidence
```

The shell layer connects host lifecycle/theme tokens to presentation components.
Components use the helper command protocol; they do not parse transcripts, manage
provider credentials or implement observation policy. The renderer remains an
attributed vendor dependency, separate from authored UI. No backend lives here.

The former 601-line LocalImport.qml is split into a small coordinator plus invitation,
session/group selection and group-editor views. Keep asynchronous helper process
state in a clearly named onboarding controller, with its command boundary testable.
Do not invent a second provider model or observation engine in QML.

Migration must update manifest entry paths, QML imports/resolved asset URLs,
provenance destinations/hashes, native lint targets and all docs together. Preserve
io.miilo.bar, behavior, attribution and user configuration. Run make check and
native manifest/lint/lifecycle/keyboard/theme tests before recording completion.
