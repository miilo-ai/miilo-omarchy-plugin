# Assistant endpoint settings

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


The shared OWL asset now exposes **Chat model** under its settings cog. It runs the existing `miilo-owl chat-setup` flow. Voice support is explicitly deferred, matching `004-launcher-voice`.

## Existing contract

The helper stores a private `chat.json` with `version`, `baseUrl`, `model`, `apiKeyFile` and `consent`. The base URL ends in `/v1`; existing validation requires HTTPS except on loopback. The credential is referenced by an absolute private file path and is never returned in UI state.

Text chat accepts a typed request and emits context, text_delta and done events, or an explicit error event. It has no action tools. Provider approval controls remain separate and revision-bound.

## Native Omarchy follow-up

The native onboarding form still needs a dedicated assistant settings panel. Reuse the typed helper contract and its validation through an application port. Do not write alternate unvalidated config directly from QML or construct shell commands with user strings.

Show endpoint, model, credential-file reference and context-sharing consent. A connection test should use an explicit sample prompt, not private observations without consent. Show unavailable/error states honestly. Keep setup compact and use the existing theme controls.

Transcription and speech output will have independent endpoint/model/credential settings, with voice/format choices for speech output. Their availability must follow implemented capabilities. Do not expose an operational microphone while the helper returns not_implemented.

## Acceptance

Save/reload, credential-file permissions, invalid URL/model, cancellation without saving, refused consent, connection failure, SSE cancellation, and no transcript/provider-action side effects. Test on the actual Omarchy shell; shared OWL and Android acceptance do not establish native form acceptance.

## Explanation response deadline

The shared HTTP helper permits twenty seconds for read-only explanation
responses. Snapshot and provider-action requests retain their eight-second
deadline, including the existing connect bound; actions are not retried. Rebuild
and install the helper to receive this change. Real-socket regression tests cover
an explanation beyond eight seconds and an action that still times out.

Android walkthrough acceptance covered four selected systems, Compact/Detail
navigation, attention notes, file diffs, a live model explanation and a confirmed
fixture approval. It did not qualify native Omarchy assistant settings or voice.
