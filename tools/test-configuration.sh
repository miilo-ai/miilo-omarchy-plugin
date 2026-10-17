#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
scratch=$(mktemp -d /tmp/miilo-configuration.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/runtime" "$scratch/state/miilo/widgets" "$scratch/shared/preferences" "$scratch/invalid"
chmod 700 "$scratch/runtime"
printf '%s\n' '{"schemaVersion":1}' > "$scratch/shared/config.json"
printf '%s\n' '{"schemaVersion":99}' > "$scratch/invalid/config.json"
printf '%s\n' '{"observatoryView":"orbit"}' > "$scratch/shared/preferences/fixture.owl.json"
printf '%s\n' '{"observatoryView":"quiet"}' > "$scratch/state/miilo/widgets/fixture.owl.json"
cat > "$scratch/fixture.owl" <<'OWL'
widget "configuration fixture" {
  state observatoryView = "quiet" persist
  Text { text: observatoryView }
}
OWL
cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/configuration" as Tests
ShellRoot { FloatingWindow { implicitWidth: 400; implicitHeight: 500; Tests.TestConfiguration {} } }
QML
for mode in legacy shared invalid; do
    if ! env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$scratch/runtime" XDG_STATE_HOME="$scratch/state" \
        MIILO_HOME="$scratch/$mode" MIILO_CONFIG_TEST_MODE="$mode" MIILO_CONFIG_TEST_WIDGET="$scratch/fixture.owl" \
        QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=basic QT_QUICK_CONTROLS_STYLE=Basic \
        timeout 25s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/$mode.log" 2>&1; then
        cat "$scratch/$mode.log"; exit 1
    fi
    cat "$scratch/$mode.log"
    rg -q 'MIILO_CONFIG_OK' "$scratch/$mode.log"
    ! rg -q 'MIILO_CONFIG_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop|Failed to load configuration' "$scratch/$mode.log"
done
