#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
: "${OMARCHY_PATH:?Set OMARCHY_PATH to the installed Omarchy checkout}"
command -v omarchy >/dev/null
command -v qmllint >/dev/null
test -d "$OMARCHY_PATH/shell"
omarchy plugin validate "$root"
while IFS= read -r -d '' file; do
  qmllint -I "$OMARCHY_PATH/shell" "$file"
done < <(find "$root/ui" "$root/vendor/owl" -type f -name '*.qml' -print0)
