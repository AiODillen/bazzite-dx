#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script betterdiscord-plugins user 2 || exit 1

set -x

BD_BASE="$HOME/.var/app/com.discordapp.Discord/config/BetterDiscord"
PLUGINS_DIR="$BD_BASE/plugins"
PLUGINS_CONFIG="$BD_BASE/data/stable/plugins.json"

mkdir -p "$PLUGINS_DIR" "$(dirname "$PLUGINS_CONFIG")"

# YABDP4Nitro — enables Nitro-like features (emoji, stickers, screenshare quality).
curl -fsSL "https://raw.githubusercontent.com/riolubruh/YABDP4Nitro/main/YABDP4Nitro.plugin.js" \
    -o "$PLUGINS_DIR/YABDP4Nitro.plugin.js"

# Enable YABDP4Nitro in BetterDiscord's plugin config.
python3 - "$PLUGINS_CONFIG" <<'EOF'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
data["YABDP4Nitro"] = True
with open(path, "w") as f:
    json.dump(data, f, indent=4)
EOF
