# Hands-free voice

Configure **Hands-free** under Settings → Voice. The disclosure beside the toggle
explains sharing spoken turns and observed context. Saving the preference does
not start capture. Click the Miilo face to start or stop on your current screen,
without another icon, toggle or chat page. App launch and shell restart never
automatically arm capture. Captions are optional in Voice settings and appear in
a compact bottom overlay; they are hidden by default.
Say the wake phrase, ask a question, then pause. Miilo detects the silence,
transcribes the question with Superwhisper, and sends it to the selected Miilo
chat model. Configured spoken replies play automatically. After each reply, listening resumes
automatically; follow-up questions need no repeated wake phrase, Stop or Send.
Quiet gaps do not end the conversation. Nearby speech can become a follow-up while
the session is active. Mute stops capture and requires the wake phrase again after
explicitly unmuting. Listening pauses during synthesis and playback so the answer
does not become another question. Mute, lock, closing the window or revoking sharing
also cancels playback. Text replies remain available if speech fails.

The single Miilo face uses the theme's muted/foreground ink to distinguish
unconfigured/configured playback, without another toolbar icon. Active session
status shows Wake listening, Listening, Transcribing, Replying and Speaking.
Input bars reflect measured microphone level; they are not an
indication that speech has been understood or sent. Capture starts only after
explicit session consent. Use the bar control or the global shortcut to mute.
Configuration readiness is not proof of a live endpoint or active microphone.
No setup sound is played automatically; **Test playback** is explicit. Spoken
product names use the pronunciation MY-LO; displayed text keeps the Miilo spelling.

Wake detection runs locally. The default phrase is “hey miilo”; the English
recognizer uses “milo” as its phonetic spelling. Custom phrases contain two to
six English words supported by the installed model. This is phrase recognition,
not speaker authentication. Nearby people or playback may also activate it.
Test your phrase, distance, and noise environment before relying on it.

The mic control in the Omarchy bar stays available while the session is armed.
It can mute and explicitly unmute the session without opening a separate screen. The
optional global **Super+Ctrl+M** shortcut always mutes; it never starts recording.
Closing the window, changing the conversation target, revoking sharing, locking, or a
missed safety heartbeat stops the session. It must be explicitly enabled again.
Listening pauses while a turn is transcribing or the model is replying.

Only audio after the recognized wake phrase is passed to Superwhisper. Its
selected local/cloud processing and history settings still apply. Miilo's bounded
wake buffer stays in memory; temporary question WAV files are private and removed
when the request ends or is discarded. Muting discards an unsent turn and rejects
late transcripts. Audio already submitted to a speech provider cannot be recalled.

Speech shorter than the minimum duration, a wake with no question, and turns over
30 seconds are discarded. Silence delay is configurable from 0.7 to 2.5 seconds.
With Hands-free off, the face opens a compact text composer on the current screen.
You can use Omarchy’s normal Superwhisper shortcut to dictate into its focused
input. Review and Send remain explicit for text entry.

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

## Spoken replies

Pipe a JSON object into `miilo-voice-session configure-playback` with `base_url`
(OpenAI-compatible HTTPS URL ending in `/v1`, or loopback HTTP), `model`, `voice`
and `api_key_file` (absolute private credential filename, or null). Configuration
is saved privately at `$XDG_CONFIG_HOME/miilo/playback.json`. Recheck playback in
Settings → Voice after changing it. Never put a credential in arguments or source.

The speech service receives completed phrases from the streamed answer, not observation snapshots
or the conversation history. Requests do not follow redirects or ambient proxies.
Speech begins at the first completed phrase, without waiting for the whole model
answer. Next-phrase synthesis overlaps playback, with at most two prepared files
ahead of the current audio and bounded text queues. A service that buffers each
WAV still adds its own synthesis delay; this is sentence pipelining, not a claim
of token-level audio streaming. On model failure, queued speech is discarded;
already-heard phrases cannot be recalled.
Voice turns request conversational spoken text, normally one or two short
sentences, with a smaller output budget than text chat. Long unpunctuated openings
are split earlier for the first speech phrase. These measures reduce avoidable
waiting but do not remove the provider's synthesis or transcription latency.
WAV responses are size/duration bounded and validated before PipeWire playback;
audio uses an anonymous temporary file, leaving no named recording on cancellation.
Speech is optional and requires its own configured provider. Superwhisper remains
the transcription provider; it does not supply this application's spoken replies.

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
