# Custom branding and About validation

The plugin uses the approved custom wordmark and its simplified robot symbol.
The symbol is shared by the wordmark and bar, with shell foreground color and
transparent visor geometry. Full workflow robots and their motion are unchanged.
The plugin manifest is 0.4.1. About reads the installed manifest, distinguishes
observation from optional model requests, and opens public links only on selection.
No shared renderer or helper changes are required.

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
  configuration fixtures pass. Existing source provenance is unchanged.

Offscreen fixtures qualify those behaviors separately from live shell acceptance.
