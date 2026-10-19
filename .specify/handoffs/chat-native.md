# Native chat handoff — CHAT-001

> Retained design record. Unchecked historical milestones are not a current release checklist. See docs/release-status.md for current scope and outstanding validation.


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

## Stream-state checkpoint — 2026-10-17

`ui/components/chat/StreamState.js` now provides the native presentation state
port. It has no process, network, credentials, persistence or action authority.
The visible panel and process adapter are still pending; M3 remains unchecked.

Host integration contract:

- Create one state per open conversation. `select(state, focusOrNull)` copies the
  opaque target and resets on a work/revision change; terminate the old helper
  when it returns true. Close/disable must cancel, terminate and discard state.
- Generate a unique request ID for every turn, including retry. `begin` returns
  the SDK-shaped request; send its JSON on stdin using an argument-array process
  and close stdin after writing. Never interpolate the question into a command.
- Capture that ID on the process instance. Feed complete NDJSON lines through
  `receive(state, capturedId, line)`, and process completion/failure through
  `exited(state, capturedId)`. Both ports ignore callbacks from older processes.
- `cancel` invalidates state before the host terminates the owned process. A
  failed receive that leaves phase `incomplete` also requires termination.
  Display partial text as incomplete; only `done` means success, regardless of
  exit status. Unknown events and broken ordering fail closed.
- Render `context` separately from `answer`, including source status and omitted
  count. Do not interpret generated text as reference metadata or action requests.
- Mutations are plain JavaScript; a QML adapter must notify bindings explicitly
  after each update. No QML execution or host notification behavior is proven here.

History contains only completed turn pairs, capped at eight messages. The SDK
caps each history message at 4,000 Unicode characters whereas helper output can
reach 64,000 bytes. An oversized completed answer stays visible but clears the
next request's history, avoiding invalid requests or silently truncated evidence.
The panel should disclose that history reset. Error bodies are not displayed.

Evidence: `make check` passes manifest/provenance/import checks, six Python
package tests, onboarding checks and the chat suite. `node tests/chat.test.mjs`
individually reports six passing tests covering incremental text/context,
cancel/retry/late callbacks, target revision changes, missing/invalid terminal
events, bounded history/output and malformed input. `git diff --check` passes.
These are portable state tests, not native shell, process-stream or model proof.

Next: implement the per-process Quickshell adapter and shared presentation port,
then wire the panel with setup access and run actual-host M3/M4 acceptance.
