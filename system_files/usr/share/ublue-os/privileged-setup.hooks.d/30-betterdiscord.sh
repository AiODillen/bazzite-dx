#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script betterdiscord-install privileged 1 || exit 0

set -x

# Patch system Flatpak Discord with BetterDiscord.
# Re-run this hook (bump version) after a Discord Flatpak update wipes the patch.
betterdiscordctl --d-install flatpak install
