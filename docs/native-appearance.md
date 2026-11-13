# Native appearance

Miilo reads colors, surface alpha, typography, and control styling from the live
Omarchy shell. Popup, menu, and tooltip roles are independent. A theme can make
one role translucent and another opaque. Miilo does not infer application opacity
from a terminal's private theme settings.

The shell pushes live theme updates. Miilo also watches Omarchy's completed
`theme.generation` marker so its robot palette refreshes after theme-file
replacement. Shell-role changes are observed even when the foundational colors
stay the same.

Application-window transparency is a separate compositor policy. To opt the
Miilo One window into Omarchy's standard appearance behavior, explicitly run:

```sh
node tools/configure-window-appearance.cjs
hyprctl reload
```

The script adds a narrowly matched call to Omarchy's `o.transparent_window`
helper in the user's existing Hyprland appearance configuration. It supplies no
opacity numbers and does not affect other Quickshell windows. The tagged window
then participates in Omarchy's Window Opacity controls. A custom marked block is
preserved rather than overwritten. Remove the marked block to remove the opt-in.

For an installed Miilo Bench window, the same configuration tool accepts the
explicit title `Miilo Bench`. This changes only its compositor integration; Bench
owns its separate palette and UI implementation.

An opaque theme popup is not necessarily a failed theme update. Compare the
settled theme's declared surface roles and Window Opacity mode before changing
alpha values.
