#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
: "${OMARCHY_PATH:?Set OMARCHY_PATH}"
scratch=$(mktemp -d /tmp/miilo-host-theme.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -m 700 "$scratch/runtime" "$scratch/theme"
printf 'initial\n' > "$scratch/theme.generation"
ln -s "$OMARCHY_PATH/shell/Commons" "$scratch/Commons"
ln -s "$OMARCHY_PATH/shell/Ui" "$scratch/Ui"
cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/typography" as Tests
ShellRoot { FloatingWindow { implicitWidth:600; implicitHeight:400; Tests.TestHostTheme {} } }
QML
env -u WAYLAND_DISPLAY MIILO_THEME_FIXTURE="$scratch/theme" XDG_RUNTIME_DIR="$scratch/runtime" XDG_STATE_HOME="$scratch/state" \
 QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Basic \
 timeout 25s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/log" 2>&1 || { cat "$scratch/log"; exit 1; }
cat "$scratch/log"
rg -q 'MIILO_HOST_THEME_OK' "$scratch/log"
! rg -q 'MIILO_HOST_THEME_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop' "$scratch/log"
