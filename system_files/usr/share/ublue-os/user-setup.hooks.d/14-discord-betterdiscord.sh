#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

set -x

# Install Discord as a user Flatpak on first setup.
# User Flatpak means app files live in ~/.local/share/flatpak (user-owned),
# so betterdiscordctl can patch without root.
if ! flatpak list --user --app --columns=application 2>/dev/null | grep -qx "com.discordapp.Discord"; then
    flatpak install --user --noninteractive flathub com.discordapp.Discord || true
fi

# Re-apply BetterDiscord on every login.
# Discord updates wipe the patch, so the version gate is intentionally omitted.
betterdiscordctl --d-install flatpak install || true
