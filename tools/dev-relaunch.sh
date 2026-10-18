#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(dirname -- "$root")"
rebuild=false
dry_run=false
restart=true
migrate_config=false
for option in "$@"; do
    case "$option" in
        --rebuild) rebuild=true ;;
        --dry-run) dry_run=true ;;
        --no-restart) restart=false ;;
        --migrate-config) migrate_config=true ;;
        --help|-h)
            echo 'Usage: bash tools/dev-relaunch.sh [--rebuild] [--migrate-config] [--dry-run] [--no-restart]'
            exit 0 ;;
        *) echo "Unknown option: $option" >&2; exit 2 ;;
    esac
done
run() {
    if "$dry_run"; then printf '%q ' "$@"; printf '\n'; else "$@"; fi
}
node_bin="${MIILO_NODE:-node}"
export PATH="/usr/lib/qt6/bin:$HOME/.local/bin:$PATH"
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
helper="$HOME/.local/bin/miilo-owl"
local_binary="$HOME/.local/bin/miilo-local"
cli_binary="$HOME/.local/bin/miilo"
if "$rebuild"; then
    source "$root/tools/cargo-auth.sh"
    run cargo build --locked --manifest-path "$workspace/miilo-owl-widgets/helper/Cargo.toml" \
        --target-dir "$workspace/miilo-owl-widgets/helper/target" --bin miilo-owl -j 2
    run cargo build --locked --manifest-path "$workspace/miilo-cli/Cargo.toml" \
        --target-dir "$workspace/miilo-cli/target" -p miilo-cli --bin miilo --bin miilo-local -j 2
    helper="$workspace/miilo-owl-widgets/helper/target/debug/miilo-owl"
    local_binary="$workspace/miilo-cli/target/debug/miilo-local"
    cli_binary="$workspace/miilo-cli/target/debug/miilo"
fi
run make -C "$root" check-native check-typography
install_args=(--helper "$helper" --local "$local_binary")
if "$rebuild"; then install_args+=(--install-binaries --cli "$cli_binary"); fi
run "$node_bin" "$root/tools/install-dev-plugin.cjs" "${install_args[@]}"
if "$migrate_config"; then run "$HOME/.local/bin/miilo" config migrate; fi
if "$restart"; then
    source "$root/tools/shell-lifecycle.sh"
    # Persist enablement before restart; do not rescan a newly starting shell.
    run omarchy-shell shell rescanPlugins
    run miilo_wait_discovery
    run omarchy plugin enable io.miilo.bar
    run omarchy restart shell
    run miilo_wait_summon
    run omarchy plugin list --json
fi
if "$dry_run"; then
    echo 'Plan only: no build, install, enablement or shell command executed.'
else
    echo 'Miilo update finished. UI commands succeeding do not qualify live rendering or phone support.'
fi
