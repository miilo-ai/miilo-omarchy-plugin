# Miilo for Omarchy

Your agents, with a little personality. An Omarchy bar plugin that opens Miilo's
robot fleet, searchable work, explanations and supported provider actions.

This is a separate plugin repository with a clean Git history. It imports a
recorded renderer snapshot; it does not contain the Miilo backend, agent engine,
credentials, or the history of another repository. Native acceptance is pending.

## Install

Requires Omarchy Quattro with its plugin commands, Quickshell/Qt, Nerd Font icons,
`miilo-owl` 1.4.0 from miilo-owl-widgets, and `miilo-local` 0.2.0 from miilo-cli
for local session onboarding. Put both binaries on the shell's PATH first.
No release has been made. These are candidate versions, not published artifacts.

Once this repository is public and native acceptance passes:

```sh
omarchy plugin add https://github.com/miilo-ai/miilo-omarchy-plugin.git
# Review the checkout before enabling it.
omarchy plugin enable io.miilo.bar
```

Click Miilo in the bar to open the dashboard. Escape closes it. **Local agents**
lets you select existing Codex/Cursor sessions; nothing is enrolled on install.
Local observations need neither CE nor a Miilo account. Native import can start
the owned `miilo-local-desktop.service` after you confirm your selection.
Local transcripts have no approval actions. Remote provider actions appear only
when the connected provider advertises them and existing access rules allow them.

The plugin runs in Omarchy's existing shell. It opens a floating dashboard window;
it is not yet an anchored clock-style popout. No second Quickshell process is started.
Snapshots are refreshed periodically; this renderer is not a push-only UI.

## Configure and remove

```sh
omarchy bar move io.miilo.bar --section right
omarchy-shell shell summon io.miilo.bar '{}'
omarchy-shell shell hide io.miilo.bar
omarchy plugin disable io.miilo.bar
omarchy plugin remove io.miilo.bar
```

Removing the plugin retains connections and observations. Stop the separately
owned collector explicitly if desired:
`systemctl --user disable --now miilo-local-desktop.service`.
Never run this against another user's service. Do not enable the old widgets
checkout's `io.miilo.bar` alongside this one: both use the same plugin identity.
Legacy `io.miilo.dashboard` / `io.miilo.desktop` installations are not removed.

## Develop

`make check` runs portable source checks with Python 3 (development only).
On Omarchy, run `make check-native` against the installed shell. See
[the agent handoff](.specify/handoffs/omarchy-agent.md) and
[marketplace registration](docs/marketplace.md).

## Boundaries

| Repository | Owns |
| --- | --- |
| miilo-omarchy-plugin | Omarchy manifest, shell lifecycle, themes and presentation |
| miilo-owl-widgets | Shared OWL design, vendored evaluator and miilo-owl helper |
| miilo-cli | Native miilo-local discovery, consent and observation collector |
| miilo-sdk | Contracts and shared observation domain |
| miilo-ce | Optional self-hosted HTTP/auth transport |

Renderer inputs and their hashes are recorded in `sources.lock.json`.
Native integration fixes belong here; shared renderer fixes must be coordinated
with the widgets repository. Update the lock intentionally after reviewing diffs.
The widgets repository is currently under EdyVision; its planned organization
transfer must be reflected in the lock/docs once the actual destination is known.

MIT. Upstream renderer notices remain in `vendor/owl/LICENSE` and `vendor/owl/UPSTREAM.md`.
Contact: contact@miilo.tech. Maintained by Viratec Interactive LLC.

## Source layout

`ui/shell` adapts Omarchy lifecycle and theme tokens. `ui/components` holds
presentation. Onboarding has separate state/controller, helper command adapter,
invitation, group editor, session list and shared controls. `vendor/owl` contains
the attributed evaluator; `assets` contains generated OWL. No provider engine or
credential storage lives in QML. Authored QML modules are limited to 200 lines.

Native design candidate: [Quiet / Orbit and your local crew](docs/orbit-design.md).
Existing work/consent rules remain unchanged; native qualification is still required.
