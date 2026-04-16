#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script remove-firefox privileged 1 || exit 1

# Remove Firefox Flatpak if bazzite-flatpak-manager installed it before we
# could remove it from its install list.
flatpak remove --system --noninteractive org.mozilla.firefox 2>/dev/null || true
