#!/usr/bin/bash
set -xeuo pipefail

dnf5 install -y \
    android-tools \
    bcc \
    bpftop \
    bpftrace \
    cava \
    ccache \
    flatpak-builder \
    git-subtree \
    khal \
    nicstat \
    niri \
    numactl \
    podman-machine \
    podman-tui \
    python3-ramalama \
    restic \
    rclone \
    tiptop \
    usbmuxd \
    waypipe \
    wl-clipboard \
    zsh

dnf5 remove -y \
    mesa-libOpenCL

# Remove Firefox RPM if present (Bazzite may ship it as RPM or Flatpak depending on variant)
dnf5 remove -y firefox 2>/dev/null || true

# Remove Firefox from bazzite-flatpak-manager's install list so it isn't
# reinstalled as a Flatpak on first boot.
find /usr/share/ublue-os/bazzite/flatpak/ -name 'install' \
    -exec sed -i '/^org\.mozilla\.firefox/d' {} \; 2>/dev/null || true

# Block Firefox in GNOME Software / KDE Discover as well.
if [[ -f /usr/share/ublue-os/flatpak-blocklist ]]; then
    grep -q 'org.mozilla.firefox' /usr/share/ublue-os/flatpak-blocklist || \
        echo "deny org.mozilla.firefox/*" >> /usr/share/ublue-os/flatpak-blocklist
fi

dnf5 --setopt=install_weak_deps=False install -y \
    rocm-hip \
    rocm-opencl \
    rocm-clinfo \
    rocm-smi \
    qemu \
    libvirt \
    qemu-kvm \
    virt-manager \
    edk2-ovmf \
    guestfs-tools

# Restore UUPD update timer and Input Remapper
sed -i 's@^NoDisplay=true@NoDisplay=false@' /usr/share/applications/input-remapper-gtk.desktop
systemctl enable input-remapper.service
systemctl enable uupd.timer

# Remove -deck specific changes to allow for login screens and session selection in settings
rm -f /etc/sddm.conf.d/steamos.conf
rm -f /etc/sddm.conf.d/virtualkbd.conf
rm -f /etc/sddm.conf.d/zz-steamos-autologin.conf
rm -f /usr/share/gamescope-session-plus/bootstrap_steam.tar.gz
systemctl disable bazzite-autologin.service
dnf5 remove -y steamos-manager

if [[ "$IMAGE_NAME" == *gnome* ]]; then
    # Remove SDDM and re-enable GDM on GNOME builds.
    dnf5 remove -y \
        sddm

    systemctl enable gdm.service
else
    # Re-enable logout and switch user functionality in KDE
    sed -i -E \
      -e 's/^(action\/switch_user)=false/\1=true/' \
      -e 's/^(action\/start_new_session)=false/\1=true/' \
      -e 's/^(action\/lock_screen)=false/\1=true/' \
      -e 's/^(kcm_sddm\.desktop)=false/\1=true/' \
      -e 's/^(kcm_plymouth\.desktop)=false/\1=true/' \
      /etc/xdg/kdeglobals
fi


dnf5 install --enable-repo="copr:copr.fedorainfracloud.org:ublue-os:packages" -y \
    ublue-setup-services

# Adding repositories should be a LAST RESORT. Contributing to Terra or `ublue-os/packages` is much preferred
# over using random coprs. Please keep this in mind when adding external dependencies.
# If adding any dependency, make sure to always have it disabled by default and _only_ enable it on `dnf install`

dnf5 config-manager addrepo --set=baseurl="https://packages.microsoft.com/yumrepos/vscode" --id="vscode"
dnf5 config-manager setopt vscode.enabled=0
# FIXME: gpgcheck is broken for vscode due to it using `asc` for checking
# seems to be broken on newer rpm security policies.
dnf5 config-manager setopt vscode.gpgcheck=0
dnf5 install --nogpgcheck --enable-repo="vscode" -y \
    code

docker_pkgs=(
    containerd.io
    docker-buildx-plugin
    docker-ce
    docker-ce-cli
    docker-compose-plugin
)
dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 install -y --enable-repo="docker-ce-stable" "${docker_pkgs[@]}" || {
    # Use test packages if docker pkgs is not available for f42
    if (($(lsb_release -sr) == 42)); then
        echo "::info::Missing docker packages in f42, falling back to test repos..."
        dnf5 install -y --enablerepo="docker-ce-test" "${docker_pkgs[@]}"
    fi
}

# DankMaterialShell — desktop shell for niri and other Wayland compositors.
# Requires two COPRs: avengemedia/danklinux (quickshell + deps) and avengemedia/dms (dms package).
dnf5 copr enable -y avengemedia/danklinux
dnf5 copr enable -y avengemedia/dms
dnf5 config-manager setopt "copr:copr.fedorainfracloud.org:avengemedia:danklinux.enabled=0"
dnf5 config-manager setopt "copr:copr.fedorainfracloud.org:avengemedia:dms.enabled=0"
dnf5 install -y \
    --enable-repo="copr:copr.fedorainfracloud.org:avengemedia:danklinux" \
    --enable-repo="copr:copr.fedorainfracloud.org:avengemedia:dms" \
    danksearch \
    dms \
    matugen

# CoolerControl — fan/pump/LED control with hardware monitoring.
dnf5 copr enable -y codifryed/CoolerControl
dnf5 config-manager setopt "copr:copr.fedorainfracloud.org:codifryed:CoolerControl.enabled=0"
dnf5 install -y \
    --enable-repo="copr:copr.fedorainfracloud.org:codifryed:CoolerControl" \
    coolercontrold \
    coolercontrol

# BetterDiscord — CLI tool to patch Flatpak/native Discord with BetterDiscord.
curl -fsSL "https://raw.githubusercontent.com/bb010g/betterdiscordctl/master/betterdiscordctl" \
    -o /usr/bin/betterdiscordctl
chmod +x /usr/bin/betterdiscordctl
# Load iptable_nat module for docker-in-docker.
# See:
#   - https://github.com/ublue-os/bluefin/issues/2365
#   - https://github.com/devcontainers/features/issues/1235
mkdir -p /etc/modules-load.d && cat >>/etc/modules-load.d/ip_tables.conf <<EOF
iptable_nat
EOF
