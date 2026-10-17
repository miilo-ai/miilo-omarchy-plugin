#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(dirname -- "$root")"
rebuild=false
dry_run=false
restart=true
for option in "$@"; do
    case "$option" in
        --rebuild) rebuild=true ;;
        --dry-run) dry_run=true ;;
        --no-restart) restart=false ;;
        --help|-h)
            echo 'Usage: bash tools/dev-relaunch.sh [--rebuild] [--dry-run] [--no-restart]'
            exit 0 ;;
        *) echo "Unknown option: $option" >&2; exit 2 ;;
    esac
done
run() {
    if "$dry_run"; then printf '%q ' "$@"; printf '\n'; else "$@"; fi
}
python_bin="${MIILO_PYTHON:-/usr/bin/python3}"
export PATH="/usr/lib/qt6/bin:$HOME/.local/bin:$PATH"
export OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
helper="$HOME/.local/bin/miilo-owl"
local_binary="$HOME/.local/bin/miilo-local"
if "$rebuild"; then
    run cargo build --locked --manifest-path "$workspace/miilo-owl-widgets/helper/Cargo.toml" \
        --target-dir "$workspace/miilo-owl-widgets/helper/target" --bin miilo-owl -j 2
    run cargo build --locked --manifest-path "$workspace/miilo-cli/Cargo.toml" \
        --target-dir "$workspace/miilo-cli/target" -p miilo-cli --bin miilo-local -j 2
    helper="$workspace/miilo-owl-widgets/helper/target/debug/miilo-owl"
    local_binary="$workspace/miilo-cli/target/debug/miilo-local"
fi
run make -C "$root" check-native check-typography
install_args=(--helper "$helper" --local "$local_binary")
if "$rebuild"; then install_args+=(--install-binaries); fi
run "$python_bin" "$root/tools/install-dev-plugin.py" "${install_args[@]}"
if "$restart"; then
    run omarchy restart shell
    run omarchy-shell shell rescanPlugins
    run omarchy plugin enable io.miilo.bar
    run omarchy-shell shell summon io.miilo.bar '{}'
    run omarchy plugin list --json
fi
if "$dry_run"; then
    echo 'Plan only: no build, install, enablement or shell command executed.'
else
    echo 'Miilo update finished. UI commands succeeding do not qualify live rendering or phone support.'
fi
