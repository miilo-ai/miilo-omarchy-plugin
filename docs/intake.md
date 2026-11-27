# Inbox (unreleased)

The new Inbox requires a compatible CLI intake build. It is not installed by
opening these source files and is not yet part of the published 0.5.0 plugin.

Open the Miilo One menu → Inbox. Under Settings → Intake, choose an owner-only
Unix socket or an authenticated HTTP endpoint. You can connect your own
Miilo-compatible backend or use the CLI manual inbox. No particular organization,
issue tracker or factory is required. See the CLI's docs/intake.md for setup and
the SDK's docs/intake.md for the interoperable contracts.

The socket path or endpoint/credential-file reference persists across sessions;
the plugin does not copy credential contents into settings. Only the backend
can authorize actions. Unknown metadata versions, stale snapshots and unavailable
actions do not enable decision buttons.

Accept, Later and Dismiss use the same advertised actions as typed or dictated
requests. Say or type `accept TASK-42`, `dismiss TASK-42` or `later TASK-42` using
the source identifier or exact title. `accept` alone works only when exactly one
matching available task exists. Ambiguous requests ask which task. Later currently
defers four hours; it does not change the source-discovery schedule. Dismiss does
not cancel execution or close an upstream issue.

Use the existing Miilo face to open the composer or arm the configured voice
session. Intake interpretation runs locally before any model request; ambiguous
matches are not converted into execution authority. Recognized typed decisions do
not require sharing task context with a model. Voice uses the existing configured
capture/VAD session, mute and lock behavior. It does not start another microphone
or enable listening by itself.

Optional arrival speech is off by default. When enabled it announces only a count
while the configured voice session is armed, unlocked and available. Decision
feedback can use that same active playback path. Seen item revisions are deduped
in settings. This is not an operating-system push service when the plugin is not
running, and it does not promise speech while muted or locked.

If an action response is lost, refresh the inbox or use Retry same request. The
retry retains the original request identity, revision, timestamp and input. It
must not be replaced with a newly generated acceptance. Changing the configured
connection invalidates old replies and retry bindings.

Native component tests and the repository plain-text network canary exercise the
rendering boundary. Full installed-shell, physical dictation/playback and real
factory/source transitions require their own qualification before release.

## Reproduce the local runtime test

On a Linux development machine with Quickshell and a compatible Miilo CLI build:

```sh
bash tools/test-intake.sh
bash tools/test-intake-runtime.sh /absolute/path/to/miilo
```

The first test checks the component and settings persistence across two shell
launches. The second starts a real manual inbox and private socket, reads it
through the actual controller, sends a synthetic voice-method acceptance and
verifies the refreshed queued state. It uses an isolated configuration and cleans
up its server/state. It does not replace your installed plugin, record audio,
connect a model or execute an agent task.
