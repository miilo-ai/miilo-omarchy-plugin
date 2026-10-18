#!/usr/bin/env bash
# Sourced by dev-relaunch.sh. Readiness is a protocol result, not IPC exit 0.
miilo_wait_discovery() {
    local inventory deadline=$((SECONDS + 10))
    while :; do
        inventory=$(OMARCHY_SHELL_IPC_TIMEOUT=1s timeout 2s omarchy plugin list --json) || {
            echo 'Cannot inspect shell discovery; relaunch stopped.' >&2; return 1;
        }
        printf '%s' "$inventory" | jq -e 'type == "array" and all(.[]; type == "object" and (.id | type == "string"))' >/dev/null || {
            echo 'Invalid shell inventory; relaunch stopped.' >&2; return 1;
        }
        if printf '%s' "$inventory" | jq -e 'any(.[]; .id == "io.miilo.bar")' >/dev/null; then return 0; fi
        (( SECONDS < deadline )) || { echo 'Timed out waiting for Miilo discovery.' >&2; return 1; }
        sleep 0.1
    done
}

miilo_wait_summon() {
    local result deadline=$((SECONDS + 10))
    while :; do
        # The restarted shell can answer ping before its plugin IPC is ready.
        if result=$(OMARCHY_SHELL_IPC_TIMEOUT=1s timeout 2s omarchy-shell shell summon io.miilo.bar '{}' 2>&1); then
            case "$result" in
                ok) echo 'Miilo live bar widget accepted summon.'; return 0 ;;
                unknown) ;;
                *) echo "Unexpected Miilo summon response: $result" >&2; return 1 ;;
            esac
        fi
        (( SECONDS < deadline )) || {
            echo "Timed out waiting for Miilo live bar widget; relaunch incomplete. Last response: $result" >&2; return 1;
        }
        sleep 0.1
    done
}
