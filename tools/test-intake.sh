#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
scratch=$(mktemp -d /tmp/miilo-intake-qml.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -m 700 "$scratch/runtime" "$scratch/config"
cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/typography" as Tests
ShellRoot { FloatingWindow { implicitWidth: 650; implicitHeight: 600; Tests.TestInbox {} } }
QML
for pass in 0 1; do
  if ! env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$scratch/runtime" XDG_CONFIG_HOME="$scratch/config" MIILO_INTAKE_PERSIST_CHECK="$pass" \
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=basic QT_QUICK_CONTROLS_STYLE=Basic \
    timeout 25s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/result" 2>&1; then
    cat "$scratch/result"
    exit 1
  fi
  cat "$scratch/result"
  rg -q 'MIILO_INBOX_OK' "$scratch/result"
  ! rg -q 'MIILO_INBOX_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop|Failed to load configuration|Failed to initialize QSettings' "$scratch/result"
  test -f "$scratch/config/miilo-one/intake.ini"
done
