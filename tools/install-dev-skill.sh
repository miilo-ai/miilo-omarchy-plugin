#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
destination="${1:-${CODEX_HOME:-$HOME/.codex}/skills/miilo-desktop}"
if [[ -L "$destination" || -e "$destination/.git" ]]; then
    echo 'Refusing to replace a linked/Git-managed skill.' >&2
    exit 1
fi
if [[ -e "$destination" ]]; then
    backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/miilo/skill-backups"
    mkdir -p -- "$backup_root"
    backup=$(mktemp -d "$backup_root/miilo-desktop.XXXXXX")
    cp -a -- "$destination" "$backup/skill"
    echo "Previous skill backup: $backup"
fi
mkdir -p -- "$destination/agents"
cp -- "$root/skills/miilo-desktop/SKILL.md" "$destination/SKILL.md"
cp -- "$root/skills/miilo-desktop/agents/openai.yaml" "$destination/agents/openai.yaml"
echo "Installed skill: $destination"
echo 'Refresh skills or start a new Codex session, then ask to rebuild/relaunch Miilo.'
