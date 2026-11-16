# Hands-free voice

In Ask Miilo, press the microphone or open the voice cog and enable **Hands-free**. The disclosure
beside the toggle explains that enabling it permits sharing spoken turns and
observed context with the configured model for this live session.
Say the wake phrase, ask a question, then pause. Miilo detects the silence,
transcribes the question with Superwhisper, and sends it to the selected Miilo
chat model. Replies currently appear as text. After each reply, listening resumes
automatically; follow-up questions need no repeated wake phrase, Stop or Send.
Quiet gaps do not end the conversation. Nearby speech can become a follow-up while
the session is active. Mute stops capture and requires the wake phrase again after
explicitly unmuting. Spoken reply playback is not implemented.

Wake detection runs locally. The default phrase is “hey miilo”; the English
recognizer uses “milo” as its phonetic spelling. Custom phrases contain two to
six English words supported by the installed model. This is phrase recognition,
not speaker authentication. Nearby people or playback may also activate it.
Test your phrase, distance, and noise environment before relying on it.

The mic control in the Omarchy bar stays available while the session is armed.
It can mute and explicitly unmute the session without opening Ask Miilo. The
optional global **Super+Ctrl+M** shortcut always mutes; it never starts recording.
Closing Ask Miilo, changing the selected work, revoking sharing, locking, or a
missed safety heartbeat stops the session. It must be explicitly enabled again.
Listening pauses while a turn is transcribing or the model is replying.

Only audio after the recognized wake phrase is passed to Superwhisper. Its
selected local/cloud processing and history settings still apply. Miilo's bounded
wake buffer stays in memory; temporary question WAV files are private and removed
when the request ends or is discarded. Muting discards an unsent turn and rejects
late transcripts. Audio already submitted to a speech provider cannot be recalled.

Speech shorter than the minimum duration, a wake with no question, and turns over
30 seconds are discarded. Silence delay is configurable from 0.7 to 2.5 seconds.
Manual draft dictation remains available from **Voice → Dictate into draft** or
Ctrl+Shift+D when hands-free is off. It intentionally keeps editing/Send controls.

## Install

Build the Rust helper with `tools/dev-relaunch.sh`. On Linux x86_64, explicitly
run `bash tools/setup-voice.sh` to download the local wake runtime and English
model. The script verifies fixed SHA-256 hashes before extraction. No microphone
is opened during setup or `miilo-voice-session check`.

`node tools/configure-voice-shortcut.cjs` adds the global mute binding without
replacing existing bindings. It refuses collisions. Customize the marked binding
in Omarchy's keybinding configuration. Removing the marked block removes the
shortcut. Wake assets live in `$XDG_DATA_HOME/miilo/voice` (default
`~/.local/share/miilo/voice`); phrase and silence preferences live in
`$XDG_CONFIG_HOME/miilo/voice.json` (default `~/.config/miilo/voice.json`). Neither
arming nor unmuting is persisted across shell restarts.

## Dependencies

The application and session state machine are Rust. PipeWire's `pw-record`
captures PCM; the Rust `webrtc-vad` binding uses WebRTC's native VAD. The optional
Vosk 0.3.45 native speech library and `vosk-model-small-en-us-0.15` English model
are from Alpha Cephei, licensed under Apache-2.0. They are downloaded separately,
not embedded in the plugin. Superwhisper supplies the configured transcription
service and its own terms. No Python runtime is introduced by Miilo's voice code.

## Optional diagnostics

Telemetry is off by default and separate from microphone/model-sharing consent.
Configure it explicitly with `miilo-owl telemetry configure --consent --endpoint
https://collector.example/v1/traces`, then restart the hands-free session. Use
`miilo-owl telemetry disable` to suppress future and pending operation records.
Only operation metadata and a validated transcription-to-chat trace parent are
shared with the collector; audio, transcript, observed context, model names, work
identifiers and endpoint URLs are excluded. Unknown providers are not inferred.
The exporter uses bounded background delivery. Muting/closing capture does not
wait on collector I/O; final process shutdown is bounded and best effort.
Already queued/exported records cannot be recalled, and abrupt process termination
may lose pending records. See the helper's telemetry guide for private collector
credential files and supported endpoint policy.
