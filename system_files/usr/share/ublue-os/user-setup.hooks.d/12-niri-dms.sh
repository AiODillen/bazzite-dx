#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

# Bump this version number whenever any file under
# /etc/skel/.config/niri/ changes in the image.
# The hook re-runs on the next login after a version bump and
# overwrites local copies with the updated image-managed files.
version-script niri-dms user 4 || exit 1

set -euo pipefail

mkdir -p "${HOME}/.config/niri/dms"
mkdir -p "${HOME}/.config/environment.d"

# Always overwrite image-managed configs so image changes take precedence.
# Do not edit these files directly — they will be overwritten on the next
# image update. Put personal overrides in ~/.config/niri/custom.kdl instead
# (config.kdl already has an include for it at the bottom).
cp /etc/skel/.config/niri/config.kdl     "${HOME}/.config/niri/config.kdl"
cp /etc/skel/.config/niri/dms/layout.kdl "${HOME}/.config/niri/dms/layout.kdl"
cp /etc/skel/.config/niri/dms/alttab.kdl "${HOME}/.config/niri/dms/alttab.kdl"
cp /etc/skel/.config/niri/dms/binds.kdl  "${HOME}/.config/niri/dms/binds.kdl"
cp /etc/skel/.config/environment.d/50-dms.conf "${HOME}/.config/environment.d/50-dms.conf"

# colors.kdl is generated dynamically by DMS from the current wallpaper;
# never overwrite it — only seed an empty placeholder on first run.
[[ -f "${HOME}/.config/niri/dms/colors.kdl" ]] || \
    touch "${HOME}/.config/niri/dms/colors.kdl"

# Ensure screenshot directory exists.
mkdir -p "${HOME}/Pictures/Screenshots"

# Apply dark colour scheme so GTK apps respect dark mode before matugen
# has run once and generated a Material Design palette.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
