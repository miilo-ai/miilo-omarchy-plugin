#!/usr/bin/env bash
# Remove this integration through Omarchy; shared software and private data remain.
set -euo pipefail
confirm=false
for option in "$@"; do
  case "$option" in
    --confirm) confirm=true ;;
    --dry-run) ;;
    --help|-h)
      printf '%s\n' 'Usage: bash uninstall.sh [--dry-run | --confirm]' 'Default: preview only. Removes io.miilo.bar, not shared helpers, observers or private data.'
      exit 0 ;;
    *) printf '%s\n' 'Unknown option. Use --help; data purge is not supported.' >&2; exit 2 ;;
  esac
done
if [[ " $* " == *' --dry-run '* && "$confirm" == true ]]; then
  printf '%s\n' 'Choose preview or confirmation, not both.' >&2
  exit 2
fi
manager="${MIILO_OMARCHY_EXECUTABLE:-omarchy}"
command -v "$manager" >/dev/null || { printf '%s\n' 'Omarchy is unavailable; no removal performed.' >&2; exit 1; }
command -v jq >/dev/null || { printf '%s\n' 'jq is required to inspect plugin state; no removal performed.' >&2; exit 1; }
command -v timeout >/dev/null || { printf '%s\n' 'timeout is required for bounded verification; no removal performed.' >&2; exit 1; }
plugins=$("$manager" plugin list --json) || { printf '%s\n' 'Cannot inspect Omarchy; no removal performed.' >&2; exit 1; }
printf '%s' "$plugins" | jq -e 'type == "array" and all(.[]; type == "object" and (.id | type == "string"))' >/dev/null || {
  printf '%s\n' 'Invalid Omarchy plugin inventory; no removal performed.' >&2; exit 1;
}
printf '%s\n' 'Retained: shared miilo/miilo-local/miilo-owl binaries, observer services, private configuration, credentials, backups and other integrations.'
printf '%s\n' 'An independently running observer continues collecting until you explicitly stop it.'
if ! printf '%s' "$plugins" | jq -e 'any(.[]; .id == "io.miilo.bar")' >/dev/null; then
  printf '%s\n' 'Miilo integration is already absent; nothing removed.'
  exit 0
fi
if ! "$confirm"; then
  printf '%s\n' 'Plan: disable io.miilo.bar, remove it with the Omarchy plugin manager, then verify its absence.'
  printf '%s\n' 'Git checkouts are deleted; hand-copied installs may be moved to an Omarchy backup.'
  printf '%s\n' 'Review the retained resources, then rerun with --confirm to remove this integration.'
  exit 0
fi
installed="${HOME:?}/.config/omarchy/plugins/io.miilo.bar"
if [[ ! -L "$installed" && -e "$installed/.git" ]]; then
  changes=$(git -c core.fsmonitor=false -C "$installed" status --porcelain) || { printf '%s\n' 'Cannot inspect installed Git checkout; removal stopped.' >&2; exit 1; }
  if [[ -n "$changes" ]]; then
    printf '%s\n' 'Installed checkout has local changes; preserve them before removal.' >&2
    exit 1
  fi
fi
"$manager" plugin disable io.miilo.bar || { printf '%s\n' 'Cannot unload Miilo; removal stopped.' >&2; exit 1; }
"$manager" plugin remove io.miilo.bar --yes || { printf '%s\n' 'Removal failed after disable; files/data may remain. Inspect the manager output before retrying.' >&2; exit 1; }
# Removal starts an asynchronous shell rescan. Retry only valid, stale inventory;
# unavailable/malformed inventory is an error, never evidence of absence.
deadline=$((SECONDS + 10))
while :; do
  after=$(OMARCHY_SHELL_IPC_TIMEOUT=1s timeout 2s "$manager" plugin list --json) || {
    printf '%s\n' 'Removal returned but verification failed; inspect Omarchy before claiming success.' >&2; exit 1;
  }
  printf '%s' "$after" | jq -e 'type == "array" and all(.[]; type == "object" and (.id | type == "string"))' >/dev/null || {
    printf '%s\n' 'Invalid Omarchy plugin inventory after removal; removal is incomplete.' >&2; exit 1;
  }
  if printf '%s' "$after" | jq -e 'all(.[]; .id != "io.miilo.bar")' >/dev/null; then
    [[ ! -e "$installed" && ! -L "$installed" ]] || {
      printf '%s\n' 'Miilo install path remains after removal; removal is incomplete.' >&2; exit 1;
    }
    break
  fi
  (( SECONDS < deadline )) || { printf '%s\n' 'Timed out waiting for Miilo to leave the shell inventory; removal is incomplete.' >&2; exit 1; }
  sleep 0.1
done
printf '%s\n' 'Miilo Omarchy integration removed. Shared software, services and private data were retained.'
