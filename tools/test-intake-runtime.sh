#!/usr/bin/env bash
# Explicit synthetic local runtime test; no source accounts, models or executor.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cli="${1:?Pass the absolute path to a compatible miilo test binary}"
[[ "$cli" = /* && -x "$cli" ]] || { echo 'Use an absolute executable path'; exit 1; }
scratch=$(mktemp -d /tmp/miilo-intake-runtime.XXXXXX)
server_pid=''
cleanup() { if [[ -n "$server_pid" ]]; then kill -TERM "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true; fi; rm -rf -- "$scratch"; }
trap cleanup EXIT
mkdir -m 700 "$scratch/runtime" "$scratch/config" "$scratch/socket"
cat > "$scratch/task.json" <<'JSON'
{"id":"synthetic-task","title":"Synthetic incoming task","summary":"Local runtime test only","revision":"one","workflowId":"test"}
JSON
"$cli" inbox --state "$scratch/state" import "$scratch/task.json" >/dev/null
"$cli" inbox --state "$scratch/state" serve --listen-socket "$scratch/socket/api.sock" > "$scratch/server.log" 2>&1 &
server_pid=$!
for attempt in {1..100}; do [[ -S "$scratch/socket/api.sock" ]] && break; sleep 0.05; done
test -S "$scratch/socket/api.sock"
cat > "$scratch/shell.qml" <<QML
import Quickshell
import "file:$root/tests/typography" as Tests
ShellRoot { FloatingWindow { implicitWidth: 650; implicitHeight: 600; Tests.TestInboxRuntime {} } }
QML
env -u WAYLAND_DISPLAY XDG_RUNTIME_DIR="$scratch/runtime" XDG_CONFIG_HOME="$scratch/config" \
  MIILO_INTAKE_TEST_CLI="$cli" MIILO_INTAKE_TEST_SOCKET="$scratch/socket/api.sock" \
  QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=basic QT_QUICK_CONTROLS_STYLE=Basic \
  timeout 45s quickshell -p "$scratch/shell.qml" --no-color > "$scratch/result" 2>&1 || { cat "$scratch/result"; exit 1; }
cat "$scratch/result"
rg -q 'MIILO_INBOX_RUNTIME_OK' "$scratch/result"
! rg -q 'MIILO_INBOX_RUNTIME_FAILED|TypeError|ReferenceError|Cannot assign|Binding loop|Failed to load configuration' "$scratch/result"
