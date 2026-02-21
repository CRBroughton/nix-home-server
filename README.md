# NixOS Home Server

NixOS-based self-hosted server using Podman containers and Tailscale.

## Services

- **AdGuard** - DNS ad blocking
- **Calibre** - Ebook management
- **Cinny** - Matrix web client
- **Convos** - IRC client
- **Copyparty** - File sharing
- **FreshRSS** - RSS reader
- **Glance** - Dashboard
- **IRC/Ergo** - IRC server
- **Matrix/Synapse** - Chat server
- **Mealie** - Recipe manager
- **Mumble** - Voice server
- **Open WebUI** - LLM interface
- **SearXNG** - Search engine
- **TheLounge** - IRC web client

## Quick Commands

```bash
just              # List all commands
just switch       # Apply NixOS configuration
just up           # Start all services
just down         # Stop all services
just restart      # Restart all services
just update       # Update flakes and switch
just build-pi     # Build Raspberry Pi image
just flash-pi /dev/sdX  # Flash Pi image to SD card
```

## Server Reinstall

If you need to reinstall the server from scratch:

### 1. Boot from NixOS installer USB

Download the minimal ISO from https://nixos.org/download/

### 2. Partition the disk with disko

```bash
# For NVMe drive (default)
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
  --mode disko ./disko-config.nix

# For SATA drive
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
  --mode disko ./disko-config.nix --arg device '"/dev/sda"'
```

### 3. Clone this repo

```bash
sudo mkdir -p /mnt/etc
sudo git clone https://github.com/YOUR_USERNAME/nix-home-server /mnt/etc/nixos
```

### 4. Generate hardware config

```bash
sudo nixos-generate-config --root /mnt --no-filesystems
# Copy hardware-configuration.nix to the repo if needed
```

### 5. Install NixOS

```bash
sudo nixos-install --flake /mnt/etc/nixos#nixos-server
```

### 6. Reboot and restore data

```bash
reboot

# After reboot, restore from Backblaze B2 backup
restic -r s3:https://s3.eu-central-003.backblazeb2.com/crbroughton-nixos-server restore latest --target /
```

## Raspberry Pi Monitor

The `pi-nixos/` folder contains a NixOS config for a Raspberry Pi 3 B+ running Uptime Kuma to monitor this server.

### Build and flash

```bash
just build-pi           # Build the image (takes a while)
just flash-pi /dev/sdX  # Flash to SD card
```

### First boot

1. Insert SD card and power on Pi
2. Find Pi's IP on your network (check router or use `nmap`)
3. SSH in: `ssh craig@<pi-ip>`
4. Join Tailscale: `sudo tailscale up`
5. Access Uptime Kuma at `http://pi-monitor:3001` (via Tailscale)

## Automated Maintenance

The server runs these tasks automatically:

| Task | Schedule | Description |
|------|----------|-------------|
| Backups | 02:00 | Restic backup to Backblaze B2 |
| System upgrade | 04:00 | Git pull + nixos-rebuild |
| Container updates | 05:00 | Pull new images, recreate if changed |
| Garbage collection | Weekly | Delete generations older than 30 days |

## File Structure

```
.
├── configuration.nix    # Main NixOS config
├── hardware-configuration.nix
├── home.nix             # Home Manager config
├── flake.nix            # Nix flake
├── justfile             # Task runner commands
├── disko-config.nix     # Disk partitioning config
├── pi-nixos/            # Raspberry Pi config
│   ├── flake.nix
│   └── configuration.nix
└── services/            # Podman services
    ├── adguard/
    ├── calibre/
    ├── cinny/
    └── ...
```

## Adding a New Service

1. Create `services/<name>/compose.yaml`
2. Create `services/<name>/serve.json` (for HTTP services with Tailscale Funnel)
3. Run `just up` or `podman compose -f services/<name>/compose.yaml up -d`

See existing services for examples.
