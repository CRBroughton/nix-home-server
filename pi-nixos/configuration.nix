{ config, pkgs, lib, ... }:

{
  # Pi 3 B+ specific settings
  hardware.enableRedistributableFirmware = true;

  # Needed for Pi 3
  boot.kernelParams = [ "console=ttyS1,115200n8" ];

  # Disable due to Pi 3 memory constraints (1GB RAM)
  nix.settings.max-jobs = 2;

  # Swap helps on 1GB Pi
  swapDevices = [{
    device = "/swapfile";
    size = 1024;  # 1GB swap
  }];

  networking.hostName = "pi-monitor";
  networking.networkmanager.enable = true;

  # Enable SSH immediately
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Your user
  users.users.craig = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrDtLXrygEh0uessk5PifLw+t6SDKJz08w6u9iQxMpo crbroughton@posteo.uk"
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Tailscale for connecting to your network
  services.tailscale.enable = true;

  # Minimal packages (Pi 3 has limited space/RAM)
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
  ];

  # Use OCI containers (lighter than full podman daemon)
  virtualisation.oci-containers = {
    backend = "podman";
    containers.uptime-kuma = {
      image = "louislam/uptime-kuma:1";
      ports = [ "3001:3001" ];
      volumes = [ "uptime-kuma:/app/data" ];
      autoStart = true;
    };
  };

  virtualisation.podman.enable = true;

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 3001 ]; # SSH + Uptime Kuma
    trustedInterfaces = [ "tailscale0" ];
  };

  system.stateVersion = "24.11";
}