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

- The 0.5.0 candidate includes an Ask Miilo panel and native Superwhisper
  dictation. It requires Superwhisper selected in Omarchy; installation, audio
  processing, history and usage limits belong to Superwhisper. Start/stop/cancel
  and status use its Linux CLI. Dictated text remains an editable draft and Send
  requires explicit context-sharing consent. Optional hands-free mode uses a local
  wake phrase and bounded speech turns to submit questions in an enabled session;
  see [voice setup and privacy](voice.md). No provider action is executed by chat.
- Native synthetic dictation and chat consent tests are separate from live
  microphone delivery, model inference and installed-shell acceptance. Those
  physical-user workflows remain release gates, including wake accuracy and false
  activation under real background noise. The optional Rust voice-session helper
  is separate from the legacy helper `voice` placeholder. Replies are text; speech
  playback and interruption of playback are not implemented.
- Keep platform-specific acceptance explicit: physical Android, Windows local observation,
  fractional scaling, large fleets and hidden/reduced-motion performance need their own evidence.
- Marketplace approval for an earlier version does not approve this candidate.
  The 0.5.0 source, new dependencies and installation disclosures need review;
  a public repository or GitHub release does not establish an updated store listing.
- The protected Homebrew tap needs a PR-compatible publishing flow. Formula CI and
  an existing published formula do not establish automatic future tap updates.

## Documentation authority

README and docs describe supported installation and operation. Personal plans and
machine-specific validation history are maintained outside the source package.
Portable checks and synthetic fixtures do not replace installed-shell acceptance,
physical microphone testing or marketplace review.
