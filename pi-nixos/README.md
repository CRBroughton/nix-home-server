# Raspberry Pi NixOS Configuration

NixOS configuration for Raspberry Pi 3 B+ running Uptime Kuma for monitoring.

## Initial Setup

### Build the SD Card Image

From your main PC (requires aarch64 emulation enabled):

```bash
cd pi-nixos
nix build .#images.pi
```

The image will be at `./result/sd-image/*.img.zst`. Decompress and flash to SD card:

```bash
zstd -d result/sd-image/*.img.zst -o pi.img
sudo dd if=pi.img of=/dev/sdX bs=4M status=progress
```

### First Boot

1. Insert SD card and power on the Pi
2. Connect to your network (ethernet recommended for initial setup)
3. Find the Pi's IP: `nmap -sn 192.168.1.0/24 | grep -i raspberry` or check your router
4. SSH in: `ssh craig@<ip-address>`
5. Join Tailscale: `sudo tailscale up`

## Updating the Configuration

After modifying `configuration.nix`, deploy changes from your main PC:

```bash
# Copy the config to the Pi
scp configuration.nix craig@pi-monitor:/tmp/

# Apply the changes
ssh craig@pi-monitor "sudo cp /tmp/configuration.nix /etc/nixos/ && sudo nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix"
```

Or as a one-liner:

```bash
scp configuration.nix craig@pi-monitor:/tmp/ && ssh craig@pi-monitor "sudo cp /tmp/configuration.nix /etc/nixos/ && sudo nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix"
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

### Can't rebuild - flakes error

Use the `-I` flag to specify the config location:

```bash
sudo nixos-rebuild switch -I nixos-config=/etc/nixos/configuration.nix
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