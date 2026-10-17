#!/usr/bin/env bash
# Qualify the coordinated user-configuration candidate before optional installation.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace="$(dirname -- "$root")"
install=false
case "${1:-}" in
    '') ;;
    --install) install=true ;;
    *) echo 'Usage: bash tools/qualify-user-config.sh [--install]' >&2; exit 2 ;;
esac
if (( $# > 1 )); then echo 'Too many arguments' >&2; exit 2; fi
source "$root/tools/cargo-auth.sh"
for repo in miilo-sdk miilo-cli miilo-owl-widgets; do
    (cd "$workspace/$repo" && python3 tools/check_architecture.py && python3 tools/test_architecture.py)
done
cargo test --locked --manifest-path "$workspace/miilo-sdk/rust/Cargo.toml" --test user_configuration -j 2
cargo test --locked --manifest-path "$workspace/miilo-cli/Cargo.toml" --workspace -j 2
cargo test --locked --manifest-path "$workspace/miilo-owl-widgets/helper/Cargo.toml" -j 2
if "$install"; then
    exec bash "$root/tools/dev-relaunch.sh" --rebuild --migrate-config
fi
PATH="/usr/lib/qt6/bin:$PATH" OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}" \
    make -C "$root" check-native check-typography
echo 'Source qualification passed; no installation or user migration requested.'
