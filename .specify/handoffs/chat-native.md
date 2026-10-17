# Native chat handoff — CHAT-001

Read specs/003-launcher-chat/spec.md and specs/004-launcher-voice/spec.md under
.specify. SDK text contracts and the shared miilo-owl helper are implemented;
the graphical chat panel is not. Do not claim chat is visible in the plugin yet.

## Shared helper boundary

`miilo-owl chat-setup` configures the model in a terminal; `chat-context` previews
normalized context. `chat` reads one bounded ChatRequest JSON object on stdin
and streams NDJSON Context/TextDelta/Done/Error. See widgets docs/launcher-chat.md.
No model URL or credential in QML/OWL. Run process with an argument array and
write request JSON to its stdin; do not interpolate user text into shell commands.
Callers close stdin after the request; the helper currently reads until EOF.

The current one-shot OWL run/source path is not an incremental NDJSON consumer.
Verify supported host/runtime APIs and implement an explicit process/stream bridge
for each host before promising streamed UI. Do not silently buffer a whole answer
and call it streaming. Keep rendering/state ports reusable and runtime code small.
No vendored runtime changes without attribution, pin updates and evaluation.

## UI and state

- Entry next to Explain and a general chat entry; preserve robots and compact layout.
- Workflow selection supplies opaque workKey/revisionKey; changing it clears history.
- Request IDs plus increasing sequence numbers isolate cancelled/late responses.
- Render context references separately from generated text; they are supplied by
  Miilo, not invented by the model. Show partial-source and omitted-context status.
- Keep at most eight user/assistant messages in memory. No durable transcript.
- Cancel/close/disable terminates the owned helper; reopen cannot replay old output.
- Parse terminal error even when the process exits zero; partial text is incomplete.
- Chat has no action execution. Existing revision-bound approval UI stays separate.
- Voice controls hidden/disabled. `voice` is a VOICE-001 not_implemented placeholder.

## Native acceptance

Record versions, source/binary hashes, commands and screenshots. Test both hosts:
keyboard/touch, narrow layouts, scrolling, light/dark/accents, Escape/focus return,
long text, cancellation, close/reopen, missing endpoint/key, malformed/empty stream,
stale workflow, partial sources and observer updates. Use a harmless fixture first;
then record real configured Gemma inference, exact model and first-token latency.
Portable helper tests are not native proof. Do not publish or submit a marketplace
entry from this handoff. Preserve user configuration and existing widgets.
