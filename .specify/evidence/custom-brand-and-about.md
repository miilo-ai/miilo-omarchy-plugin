# Custom branding and About validation

The plugin uses the approved custom wordmark and its simplified robot symbol.
The symbol is shared by the wordmark and bar, with shell foreground color and
transparent visor geometry. Full workflow robots and their motion are unchanged.
The plugin manifest is 0.4.1. About reads the installed manifest, distinguishes
observation from optional model requests, and opens public links only on selection.
The responsive portrait adjustment is a plugin-specific OWL presentation patch;
its source hash and reverse-applicable patch are recorded in sources.lock.json.
No shared runtime or helper changes are required.

## Checks

- macOS Qt 6.11.2: `make check-brand` passes, including theme changes,
  transparent visor, square sizes 16–128 px and centered nonsquare bounds.
- `qmllint` passes for both new vector components without warnings.
- Portable `make check` passes with Node 24 and a bounded local Node timeout
  adapter because this macOS environment does not provide GNU timeout.
- Omarchy: `make check-native check-brand check-typography` passes with the
  installed Rust, Node, Qt and Quickshell tools. The settings fixture checks About
  in wide and narrow navigation, installed-manifest version loading and no
  terminal startup. The toolbar fixture checks keyboard access to About.
- Native plain-text canary passes: the explicit rich-text positive control
  requests its loopback image; untrusted text surfaces request no images.
- Existing native canvas-clock, typography, session groups, robot keyboard and
  configuration fixtures pass. The vendor renderer is unchanged; OWL presentation provenance includes the
  responsive portrait patch.

Offscreen fixtures qualify those behaviors separately from live shell acceptance.

## Live acceptance

On Omarchy with Quickshell 0.3.2, the maintained development relaunch workflow
installed and verified the plugin, enabled its existing bar entry, restarted the
existing shell and accepted summon. One live Quickshell shell remained. Keyboard
navigation opened About with version 0.4.1, readable privacy disclosures and both
public links. Escape returned from settings. Existing connections were retained.
The laptop source checkout and its uncommitted edits were left unchanged.

The final brand
components use the same SVG artwork as the website, rasterized at twice their
current display dimensions with smooth scaling. Qt checks cover 16–128 px,
non-square bounds, theme changes, transparent visor and antialiased header edges.
Compact portraits grow with cell
width; Detail portraits and orbit fields grow together with viewport width, while
windows at or below 420 px retain the prior compact Detail sizing. A synthetic
1200 px Qt capture and evaluator assertions verify the responsive layout.

A diagnostic invocation of qmltestrunner with --help and no display environment
produced a separate SIGABRT notification. Actual offscreen test invocations
completed successfully. This was not a running-shell crash.

The live overview also reported one unavailable configured endpoint. This does
not qualify that endpoint as healthy; connection or provider availability was
not changed or repaired by this presentation update.

## October 24 PR review

The final adaptive Compact patch is retained in source provenance and checked
with 60 population/viewport scenarios: 1–20 systems, narrow/wide windows,
height bounds and the four-column cap. No observation or action contract changed.
`make check-native check-brand check-typography` passed on Linux with the installed
Omarchy/Quickshell runtime, including plain-text positive-control, configuration,
keyboard, retained-clock and animation-budget checks. The isolated Qt Orbit
fixture also passed. These checks used a separate source snapshot and preserved
unrelated workstation source edits.

Live shell acceptance retained the configured systems and displayed the custom
wordmark, adaptive Compact fleet and About version 0.4.1. About was reached by
keyboard; one live shell process remained after the maintained relaunch.
Validation used the matching helper 1.7.1 and already installed CLI 0.4.0.
No CLI/SDK implementation change is part of this update. The header now uses the
same 10 px horizontal inset as Settings content.
