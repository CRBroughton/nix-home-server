
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

# Format all Nix files
format:
    #!/usr/bin/env bash
    if ! command -v nixfmt &> /dev/null; then
        echo "Error: nixfmt not found. Run 'just switch' first to install it."
        exit 1
    fi
    find . -name '*.nix' -type f -exec nixfmt {} +
    echo "✓ Formatted all Nix files"


up:
  podman compose -f services/adguard/compose.yaml up -d
  podman compose -f services/copyparty/compose.yaml up -d
  podman compose -f services/mumble/compose.yaml up -d
  podman compose -f services/irc/compose.yaml up -d

down:
  podman compose -f services/adguard/compose.yaml down
  podman compose -f services/copyparty/compose.yaml down
  podman compose -f services/mumble/compose.yaml down
  podman compose -f services/irc/compose.yaml down
