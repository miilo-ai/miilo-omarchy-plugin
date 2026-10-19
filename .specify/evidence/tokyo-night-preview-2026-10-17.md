# Tokyo Night preview — 2026-10-17

> Historical validation record. Results apply only to the revision and environment recorded below; they do not describe current release readiness.


Palette: Omarchy themes/tokyo-night/colors.toml.
Source: https://github.com/omacom/omarchy/blob/afa2839a5ac7bf1c2da4f49649b8dbd0f83f7f12/themes/tokyo-night/colors.toml
SHA-256 of color data: 8b5f53ba35b9305aafa72776dd56ea2029faaf29015e2e42db5e19ef698a8e0e

This recording uses the actual shared OWL evaluator/layout/Canvas in an isolated
Qt fixture with synthetic tasks, not an installed Omarchy shell or live provider
footage. The existing developer-only Qt capture utility was used; no production
dependency or new Python tool was added. Dark fixture colors now come from the
complete upstream palette, including warning and robot-color channels. The light
fixture remains a separate synthetic QA palette and is not called Tokyo Night.

Theme contrast finding: upstream muted (#414868) is close to background
(#1a1b26); secondary labels and dormant rails become very dim. Preserve this
finding for the native agent to qualify text-role contrast against the real
Omarchy theme adapter. Do not claim this fixture proves native accessibility,
font matching, frame rate, shell lifecycle or Python removal.

Incoming shared-configuration / Rust-qualification changes were fast-forwarded
without overwriting local presentation edits. Main still contains the preexisting
Python preview/installer tools at this checkpoint; an alternate removal branch
has not been identified. No release or deployment was performed.
