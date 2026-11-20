# Release scope and validation

The package version is declared in `manifest.json`. GitHub Releases records
published assets; a local manifest is not evidence that its version was released.
Documentation-only changes do not require a package version bump.

## Supported scope

Local observation supports Codex, Claude Code, Cursor, OpenCode, Devin CLI,
Grok CLI and Hermes through the CLI. Consult the CLI compatibility matrix for
storage formats, tested tool versions and the distinction between import and live updates.
Local observation is read-only; provider actions require a separately connected provider.

## Outstanding work

- The 0.5.0 candidate includes in-place chat and hands-free voice. Configure it in
  Settings → Voice; the Miilo face activates the saved mode without leaving the
  current workspace. Optional captions appear at the bottom. Superwhisper handles
  transcription with its selected local/cloud processing and history settings.
  Separate configured speech receives completed answer phrases. Synthesis overlaps
  playback, but the service may buffer each audio response. No provider action is
  executed by chat. See [voice setup and privacy](voice.md).
- Native synthetic consent, turn ordering, concurrent synthesis/playback and
  cancellation tests are separate from physical microphone delivery and perceived
  conversational latency. Physical wake accuracy, false activation under real
  background noise and back-to-back spoken interaction remain release gates.
  The Rust `miilo-voice-session` helper owns microphone capture and playback;
  the shared `miilo-owl` helper supplies chat text and observations. The unused
  legacy `miilo-owl voice` placeholder has been removed from the helper candidate.
- Keep platform-specific acceptance explicit: physical Android, Windows local observation,
  fractional scaling, large fleets and hidden/reduced-motion performance need their own evidence.
- Marketplace approval for an earlier version does not approve this candidate.
  The 0.5.0 source, new dependencies and installation disclosures need review;
  a public repository or GitHub release does not establish an updated store listing.
- Runtime pins require the reviewed helper and CLI releases. CLI 0.5.0 includes
  release-equivalent artifact and Homebrew installation rehearsal; helper 1.7.2
  remains a candidate until its release is published.

## Documentation authority

README and docs describe supported installation and operation. Personal plans and
machine-specific validation history are maintained outside the source package.
Portable checks and synthetic fixtures do not replace installed-shell acceptance,
physical microphone testing or marketplace review.
