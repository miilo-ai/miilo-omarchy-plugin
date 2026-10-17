# Sourced by local workflow scripts; use the SDK checkout's existing SSH access.
# Environment-only Git configuration is inherited by Cargo's Git subprocesses.
miilo_cargo_auth() {
    export CARGO_NET_GIT_FETCH_WITH_CLI=true
    local sdk_remote config_count
    sdk_remote="$(git -C "$workspace/miilo-sdk" remote get-url origin)" || return
    case "$sdk_remote" in
        git@github.com:miilo-ai/miilo-sdk|git@github.com:miilo-ai/miilo-sdk.git|ssh://git@github.com/miilo-ai/miilo-sdk|ssh://git@github.com/miilo-ai/miilo-sdk.git)
            config_count="${GIT_CONFIG_COUNT:-0}"
            if [[ ! "$config_count" =~ ^[0-9]+$ ]]; then
                echo 'Invalid GIT_CONFIG_COUNT; cannot configure Cargo authentication.' >&2
                return 2
            fi
            config_count=$((10#$config_count))
            export "GIT_CONFIG_KEY_${config_count}=url.${sdk_remote%.git}.insteadOf"
            export "GIT_CONFIG_VALUE_${config_count}=https://github.com/miilo-ai/miilo-sdk"
            export GIT_CONFIG_COUNT=$((config_count + 1))
            ;;
    esac
}
miilo_cargo_auth
unset -f miilo_cargo_auth
