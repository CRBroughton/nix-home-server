# Raspberry Pi NixOS Configuration

NixOS configuration for Raspberry Pi 3 B+ running Uptime Kuma for monitoring.

## Initial Setup

### Build the SD Card Image

From your main server (requires aarch64 emulation enabled):

```bash
just build-pi
```

Then flash to SD card (replace `/dev/sdX` with your SD card device):

```bash
just flash-pi /dev/sdX
```

### First Boot

1. Insert SD card and power on the Pi
2. Connect to your network (ethernet recommended for initial setup)
3. Find the Pi's IP: `nmap -sn 192.168.1.0/24 | grep -i raspberry` or check your router
4. SSH in: `ssh craig@<ip-address>`
5. Join Tailscale: `sudo tailscale up`

### Bootstrap Trust Setup (First Deployment Only)

The first deployment must build on the Pi to establish trust. From your server, run:

```bash
cd pi-nixos && nixos-rebuild switch --flake .#pi --target-host craig@pi-monitor --build-host craig@pi-monitor --sudo
```

This will be slow (builds on the 1GB Pi) but only needs to run once. After this completes, future deployments using `just deploy-pi` will build on the server (fast).

## Updating the Configuration

After modifying `configuration.nix`, deploy changes from your main server using the justfile:

```bash
just deploy-pi
```

This builds the configuration on the server (faster than building on Pi) and deploys it remotely.

Or run the full command manually (builds on server):

```bash
cd pi-nixos && nixos-rebuild switch --flake .#pi --target-host craig@pi-monitor --build-host localhost --sudo
```

To build directly on the Pi (slower, doesn't require trust setup):

```bash
cd pi-nixos && nixos-rebuild switch --flake .#pi --target-host craig@pi-monitor --sudo
```

## Services

### Uptime Kuma

- **URL**: `http://pi-monitor:3001` (or via Tailscale: `http://pi-monitor.<tailnet>.ts.net:3001`)
- **Container**: Uses host networking to access Tailscale hostnames
- **Data**: Stored in podman volume `uptime-kuma`

## Notes

- The Pi 3 B+ has only 1GB RAM, so a swap file is configured
- `max-jobs = 2` limits parallel builds to avoid OOM
- Uses `--network=host` for the container so it can resolve Tailscale hostnames
- The `sd-image-aarch64.nix` module is imported for boot/filesystem configuration

## Troubleshooting

### Can't deploy from server

Make sure the Pi is reachable via Tailscale:

```bash
ping pi-monitor
ssh craig@pi-monitor
```

### Container can't reach Tailscale hosts

Make sure the container uses host networking:

```nix
extraOptions = [ "--network=host" ];
```

### Out of memory during rebuild

The Pi may run out of memory. Ensure swap is enabled:

```bash
free -h  # Check swap is active
```