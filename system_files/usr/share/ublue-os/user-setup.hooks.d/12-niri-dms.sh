#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

# Bump this version number whenever any file under
# /etc/skel/.config/niri/ changes in the image.
# The hook re-runs on the next login after a version bump and
# overwrites local copies with the updated image-managed files.
version-script niri-dms user 9 || exit 1

set -euo pipefail

mkdir -p "${HOME}/.config/niri/dms"
mkdir -p "${HOME}/.config/environment.d"
mkdir -p "${HOME}/.config/DankMaterialShell/themes/catppuccin"

# Always overwrite image-managed configs so image changes take precedence.
# Do not edit these files directly — they will be overwritten on the next
# image update. Put personal overrides in ~/.config/niri/custom.kdl instead
# (config.kdl already has an include for it at the bottom).
cp /etc/skel/.config/niri/config.kdl     "${HOME}/.config/niri/config.kdl"
cp /etc/skel/.config/niri/dms/layout.kdl "${HOME}/.config/niri/dms/layout.kdl"
cp /etc/skel/.config/niri/dms/alttab.kdl "${HOME}/.config/niri/dms/alttab.kdl"
cp /etc/skel/.config/niri/dms/binds.kdl  "${HOME}/.config/niri/dms/binds.kdl"
cp /etc/skel/.config/environment.d/50-dms.conf "${HOME}/.config/environment.d/50-dms.conf"

# Always overwrite the Catppuccin theme file so image updates propagate.
cp /etc/skel/.config/DankMaterialShell/themes/catppuccin/theme.json \
    "${HOME}/.config/DankMaterialShell/themes/catppuccin/theme.json"

# Seed default DMS settings (Catppuccin theme) only on first run;
# never overwrite — DMS owns this file after first launch.
[[ -f "${HOME}/.config/DankMaterialShell/settings.json" ]] || \
    cp /etc/skel/.config/DankMaterialShell/settings.json \
        "${HOME}/.config/DankMaterialShell/settings.json"

# colors.kdl and windowrules.kdl are generated/managed by DMS;
# never overwrite them — only seed an empty placeholder on first run.
[[ -f "${HOME}/.config/niri/dms/colors.kdl" ]] || \
    touch "${HOME}/.config/niri/dms/colors.kdl"
[[ -f "${HOME}/.config/niri/dms/windowrules.kdl" ]] || \
    touch "${HOME}/.config/niri/dms/windowrules.kdl"
[[ -f "${HOME}/.config/niri/dms/cursor.kdl" ]] || \
    touch "${HOME}/.config/niri/dms/cursor.kdl"

# Ensure screenshot directory exists.
mkdir -p "${HOME}/Pictures/Screenshots"

# Apply dark colour scheme so GTK apps respect dark mode before matugen
# has run once and generated a Material Design palette.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
