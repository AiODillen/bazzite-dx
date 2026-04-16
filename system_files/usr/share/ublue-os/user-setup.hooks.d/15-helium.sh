#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script helium-appimage user 1 || exit 1

set -euo pipefail

# Download latest Helium AppImage to ~/Applications/ so GearLever can manage updates.
mkdir -p "${HOME}/Applications"

HELIUM_URL=$(curl -fsSL "https://api.github.com/repos/imputnet/helium-linux/releases/latest" \
    | python3 -c "
import sys, json
rel = json.load(sys.stdin)
print(next(
    a['browser_download_url'] for a in rel['assets']
    if '-x86_64.AppImage' in a['name'] and not a['name'].endswith('.zsync')
))")

curl -fsSL "${HELIUM_URL}" -o "${HOME}/Applications/helium.AppImage"
chmod +x "${HOME}/Applications/helium.AppImage"

# Extract the desktop file and icon directly from the AppImage so integration
# is fully automated — no need to manually open GearLever on first boot.
# GearLever will still discover ~/Applications/helium.AppImage for future updates.
EXTRACT_DIR=$(mktemp -d)
cd "${EXTRACT_DIR}"
"${HOME}/Applications/helium.AppImage" --appimage-extract '*.desktop' 2>/dev/null || true
"${HOME}/Applications/helium.AppImage" --appimage-extract '*.png'     2>/dev/null || true
"${HOME}/Applications/helium.AppImage" --appimage-extract '*.svg'     2>/dev/null || true
cd /

# Install desktop file — fix the Exec line to point at the AppImage.
DESKTOP_SRC=$(find "${EXTRACT_DIR}/squashfs-root" -maxdepth 1 -name '*.desktop' | head -1)
if [[ -n "${DESKTOP_SRC}" ]]; then
    mkdir -p "${HOME}/.local/share/applications"
    sed "s|^Exec=.*|Exec=${HOME}/Applications/helium.AppImage %U|" \
        "${DESKTOP_SRC}" > "${HOME}/.local/share/applications/helium.desktop"
fi

# Install icon — put it somewhere the icon theme will find it.
ICON_SRC=$(find "${EXTRACT_DIR}/squashfs-root" -maxdepth 1 -name '*.png' | head -1)
if [[ -n "${ICON_SRC}" ]]; then
    mkdir -p "${HOME}/.local/share/icons/hicolor/256x256/apps"
    cp "${ICON_SRC}" "${HOME}/.local/share/icons/hicolor/256x256/apps/helium.png"
    gtk-update-icon-cache --quiet "${HOME}/.local/share/icons/hicolor" 2>/dev/null || true
fi

rm -rf "${EXTRACT_DIR}"

# Set Helium as the default browser.
mkdir -p "${HOME}/.config"
# Remove any existing browser defaults before writing ours.
if [[ -f "${HOME}/.config/mimeapps.list" ]]; then
    sed -i '/^x-scheme-handler\/http=/d;/^x-scheme-handler\/https=/d;/^x-scheme-handler\/ftp=/d;/^x-scheme-handler\/chrome=/d;/^text\/html=/d;/^application\/xhtml+xml=/d' \
        "${HOME}/.config/mimeapps.list"
else
    echo "[Default Applications]" > "${HOME}/.config/mimeapps.list"
fi

cat >> "${HOME}/.config/mimeapps.list" << 'MIMEAPPS'
x-scheme-handler/http=helium.desktop
x-scheme-handler/https=helium.desktop
x-scheme-handler/ftp=helium.desktop
x-scheme-handler/chrome=helium.desktop
text/html=helium.desktop
application/xhtml+xml=helium.desktop
MIMEAPPS

# Tell GNOME the default web browser.
gsettings set org.gnome.desktop.default-applications.web-browser helium.desktop

# Seed topgrade config so ujust update also runs AppImage updates.
# Only written on first run; the user can extend it freely afterwards.
if [[ ! -f "${HOME}/.config/topgrade.toml" ]]; then
    cp /etc/skel/.config/topgrade.toml "${HOME}/.config/topgrade.toml"
fi
