#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script betterdiscord-plugins user 1 || exit 1

set -x

PLUGINS_DIR="$HOME/.var/app/com.discordapp.Discord/config/BetterDiscord/plugins"
mkdir -p "$PLUGINS_DIR"

# YABDP4Nitro — enables Nitro-like features (emoji, stickers, screenshare quality).
curl -fsSL "https://raw.githubusercontent.com/riolubruh/YABDP4Nitro/main/YABDP4Nitro.plugin.js" \
    -o "$PLUGINS_DIR/YABDP4Nitro.plugin.js"
