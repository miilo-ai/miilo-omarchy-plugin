# Deferred canvas animation clock

## Reproduction and correction

A component-local `let clock = time` used only by deferred Canvas drawing could
retain its evaluated value while the layout reported `readsTime: false`.
Snapshot refresh rebuilt the closure and caused visible jumps. Layout expressions
that independently read time could mask the defect.

The frame handler now rebuilds deferred drawing closures when the instance,
root tree, or expanded-screen tree reads time. The native regression fixture
checks consecutive position advances without a snapshot refresh. It fails against
the original renderer and passes against the corrected renderer.

## Validation

- Actual Qt/Quickshell offscreen reproduction: original failed, correction passed.
- Native package, typography, configuration and canvas clock checks passed.
- Installed development renderer hash matched the staged source; the existing
  Omarchy shell was restarted using the maintained backed-up update workflow.
- Actual desktop screenshot confirmed the crew view remained intact.
- Ten-second whole-shell sample after restart: approximately 113% of one CPU
  core, 525 MiB resident memory, 23 MiB lower than sample start, and 11.4 GiB
  available system memory. These are short observations, not a leak test or an
  isolated Miilo performance benchmark.

## Remaining validation

Intermittent frame pacing remains unqualified. Profile frame/evaluation/paint
cost independently and compare visible versus hidden views before selecting an
optimization. The clock regression proves continuous advancement; it does not
prove a target frame rate. Physical Android performance is not covered here.
