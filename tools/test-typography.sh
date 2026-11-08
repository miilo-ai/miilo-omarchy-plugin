#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
target="${CARGO_TARGET_DIR:-$root/tools/qt-preview/target}"
cargo build --locked --manifest-path "$root/tools/qt-preview/Cargo.toml" --bin dictation-peer --target-dir "$target"
scratch=$(mktemp -d /tmp/miilo-typography.XXXXXX)
trap 'rm -rf -- "$scratch"' EXIT
mkdir "$scratch/runtime"
chmod 700 "$scratch/runtime"
# Each suite owns its offscreen window so popups cannot steal another suite's input.
for fixture in TestTypography TestDesktopToolbar TestDesktopSettings TestAgentGroups TestRobotKeyboard TestChatPanel TestObservationFeed; do
  case "$fixture" in
    TestTypography) marker=MIILO_TYPOGRAPHY_OK ;;
    TestDesktopToolbar) marker=MIILO_TOOLBAR_OK ;;
    TestDesktopSettings) marker=MIILO_SETTINGS_OK ;;
    TestAgentGroups) marker=MIILO_GROUPS_OK ;;
    TestRobotKeyboard) marker=MIILO_ROBOT_KEYBOARD_OK ;;
    TestChatPanel) marker=MIILO_CHAT_PANEL_OK ;;
    TestObservationFeed) marker=MIILO_FEED_OK ;;
  esac
  cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/typography" as Tests
ShellRoot {
    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 800
        Tests.$fixture {}
    }
}
QML
  # This never starts a second live desktop shell.
  if ! env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$scratch/runtime" XDG_STATE_HOME="$scratch/state" MIILO_HOME="$scratch/miilo" MIILO_CHAT_TEST_PEER="$target/debug/dictation-peer" \
      QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
      QT_QPA_PLATFORMTHEME=basic QT_QUICK_CONTROLS_STYLE=Basic \
      timeout 25s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/result" 2>&1; then
      cat "$scratch/result"
      exit 1
  fi
  cat "$scratch/result"
  rg -q "$marker" "$scratch/result"
  ! rg -q 'MIILO_FEED_FAILED|MIILO_SETTINGS_FAILED|MIILO_TOOLBAR_FAILED|MIILO_TYPOGRAPHY_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop|Failed to load configuration' "$scratch/result"
done
