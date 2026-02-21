# List available commands
default:
  @just --list

# Update the server
update: update-flakes switch

# Update all flakes
update-flakes:
  nix flake update

# Apply any changes to the current build
switch:
  sudo nixos-rebuild switch --flake /etc/nixos#nixos-server

# Trust /etc/nixos git repo for root (fixes nixos-upgrade ownership error)
fix-git-ownership:
  sudo git config --global --add safe.directory /etc/nixos

# Format all Nix files
format:
  #!/usr/bin/env bash
  if ! command -v nixfmt &> /dev/null; then
    echo "Error: nixfmt not found. Run 'just switch' first to install it."
    exit 1
  fi
  find . -name '*.nix' -type f -exec nixfmt {} +
  echo "✓ Formatted all Nix files"

# Start all services
up:
  #!/usr/bin/env bash
  for compose in services/*/compose.yaml; do
    echo "Starting $(dirname $compose)..."
    podman compose -f "$compose" up -d
  done

# Stop all services
down:
  #!/usr/bin/env bash
  for compose in services/*/compose.yaml; do
    echo "Stopping $(dirname $compose)..."
    podman compose -f "$compose" down
  done

# Restart all services
restart: down up

# Add The Lounge user
thelounge-adduser username:
    podman exec -it thelounge thelounge add {{username}}

# Generate IRC operator password
irc-genpasswd:
    podman exec -it ergo /ircd-bin/ergo genpasswd

# Build Pi SD card image
build-pi:
    nix build ./pi-nixos#images.pi
    @echo "Image built: result/sd-image/"
    @ls -lh result/sd-image/

# Flash Pi to SD card (e.g., just flash-pi /dev/sdb)
flash-pi device:
    #!/usr/bin/env bash
    set -e
    img=$(find result/sd-image -name "*.img.zst" | head -1)
    echo "Flashing $img to {{device}}..."
    nix-shell -p zstd --run "zstd -dc '$img' | sudo dd of={{device}} bs=4M status=progress conv=fsync"
    sync
    echo "Done! Remove SD card and boot your Pi."

# Partition disk with disko (for reinstall, e.g., just disko /dev/nvme0n1)
disko device="/dev/nvme0n1":
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko ./disko-config.nix --arg device '"{{device}}"'
