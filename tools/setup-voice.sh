#!/usr/bin/env bash
set -euo pipefail
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || { echo 'The packaged wake runtime supports Linux x86_64.' >&2; exit 1; }
root="${XDG_DATA_HOME:-$HOME/.local/share}/miilo/voice"
mkdir -p "$root"
chmod 700 "$root"
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
curl --fail --location --proto '=https' --tlsv1.2 --retry 2 --max-time 180 \
  https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-linux-x86_64-0.3.45.zip -o "$scratch/runtime.zip"
curl --fail --location --proto '=https' --tlsv1.2 --retry 2 --max-time 180 \
  https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip -o "$scratch/model.zip"
(cd "$scratch" && printf '%s\n' \
 'bbdc8ed85c43979f6443142889770ea95cbfbc56cffb5c5dcd73afa875c5fbb2  runtime.zip' \
 '30f26242c4eb449f948e42cb302dd7a686cb29a3423a8367f99ff41780942498  model.zip' | sha256sum --check)
unzip -p "$scratch/runtime.zip" vosk-linux-x86_64-0.3.45/libvosk.so > "$root/libvosk.so.next"
chmod 600 "$root/libvosk.so.next"
unzip -q "$scratch/model.zip" -d "$scratch"
[[ -f "$scratch/vosk-model-small-en-us-0.15/am/final.mdl" ]]
if [[ ! -d "$root/vosk-model-small-en-us-0.15" ]]; then
  mv "$scratch/vosk-model-small-en-us-0.15" "$root/"
fi
mv "$root/libvosk.so.next" "$root/libvosk.so"
echo 'Local wake detection installed. Microphone remains off until a session is enabled.'
