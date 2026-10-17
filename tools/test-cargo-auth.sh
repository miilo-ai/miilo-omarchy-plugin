#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
workspace=$(mktemp -d /tmp/miilo-cargo-auth.XXXXXX)
trap 'rm -rf -- "$workspace"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=miilo.fixture GIT_CONFIG_VALUE_0=preserved
git init --quiet "$workspace/miilo-sdk"
git -C "$workspace/miilo-sdk" remote add origin git@github.com:miilo-ai/miilo-sdk.git
source "$root/tools/cargo-auth.sh"
[[ "$CARGO_NET_GIT_FETCH_WITH_CLI" == true ]]
[[ "$GIT_CONFIG_COUNT" == 2 ]]
[[ "$(git config --get miilo.fixture)" == preserved ]]
[[ "$(git ls-remote --get-url https://github.com/miilo-ai/miilo-sdk)" == git@github.com:miilo-ai/miilo-sdk ]]
[[ "$(git ls-remote --get-url https://github.com/miilo-ai/miilo-sdk.git)" == git@github.com:miilo-ai/miilo-sdk.git ]]
[[ "$(git ls-remote --get-url https://github.com/other/project)" == https://github.com/other/project ]]
# HTTPS checkouts retain their own Git credential setup; no SSH rewrite is added.
export GIT_CONFIG_COUNT=1
git -C "$workspace/miilo-sdk" remote set-url origin https://github.com/miilo-ai/miilo-sdk.git
source "$root/tools/cargo-auth.sh"
[[ "$GIT_CONFIG_COUNT" == 1 ]]
[[ "$(git ls-remote --get-url https://github.com/miilo-ai/miilo-sdk)" == https://github.com/miilo-ai/miilo-sdk ]]
echo 'Cargo authentication checks passed without network access or global configuration changes.'
