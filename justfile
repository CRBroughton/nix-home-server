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
