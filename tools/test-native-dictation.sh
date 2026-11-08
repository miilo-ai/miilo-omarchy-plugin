#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${CARGO_TARGET_DIR:-$root/tools/qt-preview/target}"
cargo build --locked --manifest-path "$root/tools/qt-preview/Cargo.toml" --bin dictation-peer --target-dir "$target"
scratch=$(mktemp -d /tmp/miilo-dictation.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -m 700 "$scratch/runtime"
printf '{}\n' > "$scratch/state.json"
cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/typography" as Tests
ShellRoot { FloatingWindow { implicitWidth: 500; implicitHeight: 300; Tests.TestNativeDictation {} } }
QML
env -u WAYLAND_DISPLAY MIILO_DICTATION_TEST_PEER="$target/debug/dictation-peer" \
    MIILO_DICTATION_TEST_STATE="$scratch/state.json" XDG_RUNTIME_DIR="$scratch/runtime" \
    QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    QT_QPA_PLATFORMTHEME=basic QT_QUICK_CONTROLS_STYLE=Basic \
    timeout 35s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/log" 2>&1 || { cat "$scratch/log"; exit 1; }
cat "$scratch/log"
rg -q 'MIILO_DICTATION_OK' "$scratch/log"
! rg -q 'MIILO_DICTATION_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop' "$scratch/log"
