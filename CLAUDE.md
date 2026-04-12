# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A custom OCI/bootc container image extending [Bazzite](https://github.com/ublue-os/bazzite) with developer tooling — essentially a "Bazzite DX" (Developer Experience) variant. It is part of the Universal Blue / ublue-os ecosystem. The image is published to `ghcr.io/aiodillen/bazzite-dx-gnome`.

The base image is `ghcr.io/ublue-os/bazzite-deck-gnome:latest`, pulled via `image-versions.yaml`. Build customizations are layered on top via shell scripts and static files copied into the container.

## Build Commands

```bash
# Build the container image locally (requires podman or docker)
just build

# Check Justfile syntax
just check

# Fix Justfile syntax
just fix

# Build a QCOW2 VM image from the container
just build-vm

# Run the VM in QEMU (builds if needed, opens browser at localhost:PORT)
just run-vm
```

The `just build` command uses `podman build` (or docker if podman isn't found) and reads `BASE_IMAGE` from the environment (default: `bazzite-dx`). CI builds set `BASE_IMAGE=ghcr.io/ublue-os/bazzite-deck-gnome:latest`.

## Repository Structure

```
Containerfile          # Minimal: copies files + runs build.sh
build_files/           # Build scripts run in numeric order inside the container
  build.sh             # Orchestrator: copies system_files then runs scripts
  00-image-info.sh     # Patches image-info.json and os-release
  20-install-apps.sh   # dnf5 installs, COPR repos, external repos (vscode, docker)
  40-services.sh       # systemctl enable/disable calls
  50-fix-opt.sh        # Moves /var/opt/* to /usr/lib/opt for immutable FS
  60-clean-base.sh     # Appends bazzite-dx just file to justfile
  99-build-initramfs.sh
  999-cleanup.sh
  scripts/             # Helper scripts sourced by build scripts
system_files/          # Copied verbatim to / inside the container
  usr/share/ublue-os/just/
    84-bazzite-virt.just   # ujust commands for virtualization/VFIO setup
    95-bazzite-dx.just     # ujust commands specific to bazzite-dx
  usr/ublue-os/          # homebrew, user/system setup hooks
  etc/                   # Static config files
image-versions.yaml    # Pins the upstream base image digest
image.toml             # bootc-image-builder config (filesystem layout)
iso.toml               # bootc-image-builder config for ISO builds
```

## How Builds Work

1. `Containerfile` mounts `system_files` and `build_files` as a bind stage (`ctx`), then runs `build.sh` inside the base image.
2. `build.sh` first copies `system_files/` to `/`, then runs all `NN-*.sh` scripts in numeric order from `build_files/`.
3. Scripts use `dnf5` (Fedora package manager) to install packages. External repos are added but kept **disabled by default** — they are only enabled per-install via `--enable-repo=`.
4. CI (`.github/workflows/build.yml`) builds daily at 02:00 UTC (skipped if no commits in 24h), signs with Cosign, and pushes to GHCR.

## Key Design Constraints

- **External repos are a last resort.** Prefer contributing packages to [Terra](https://terra.fyralabs.com/) or `ublue-os/packages`. Any new COPR/external repo must be added disabled and only enabled during the specific `dnf install` call.
- **Immutable OS conventions:** Don't write to `/opt` directly — use `/usr/lib/opt` + tmpfiles.d symlinks (see `50-fix-opt.sh`). Don't assume writable `/usr` at runtime.
- The build matrix in CI currently only builds `bazzite-deck-gnome` (the GNOME variant). KDE and NVIDIA variants are commented out.
- Image name transformation: `bazzite-deck-gnome` → `bazzite-dx-gnome` (the `-deck` segment is stripped in the workflow).

## Adding Packages

- RPM packages: add to `build_files/20-install-apps.sh` via `dnf5 install -y`
- Flatpaks installed at runtime by users via `ujust` commands in `system_files/usr/share/ublue-os/just/`
- Services to enable/disable: `build_files/40-services.sh`
- Static config files: place under `system_files/` mirroring the target filesystem path
