# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  security.wrappers = {
    newuidmap = {
      source = "${pkgs.shadow.out}/bin/newuidmap";
      setuid = true;
      owner = "root";
      group = "root";
    };
    newgidmap = {
      source = "${pkgs.shadow.out}/bin/newgidmap";
      setuid = true;
      owner = "root";
      group = "root";
    };
  };



  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable aarch64 emulation for building Pi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

  programs.fish.enable = true;
  users.users.craig = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "podman"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrDtLXrygEh0uessk5PifLw+t6SDKJz08w6u9iQxMpo crbroughton@posteo.uk"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  networking.hostName = "nixos-server";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # IRC
      53    # Adguard
      6697  # IRC
      4000  # Searxng
      3000  # Adguard
      8008  # Matrix
      8083  # Calibre
      8085  # Cinny
      8787  # FreshRSS
      8888  # Glance
      9000  # TheLounge
      9925  # Mealie
      3923  # Copyparty
      8080  # Open WebUI
      64738 # Mumble
    ];
   allowedUDPPorts = [
      53    # Adguard
      64738 # Mumble
   ];
   trustedInterfaces = [
      "tailscale0"
   ];
  };
  services.tailscale.enable = true;

  # Backups via restic to Backblaze B2
  services.restic.backups = {
    b2 = {
      repository = "s3:https://s3.eu-central-003.backblazeb2.com/crbroughton-nixos-server";
      passwordFile = "/etc/restic-env-password";
      environmentFile = "/etc/restic-env";
      paths = [
        "/etc/nixos/services"
        "/var/lib/containers/storage/volumes"
      ];
      exclude = [
        "/etc/nixos/services/*/tailscale"
        "/var/lib/containers/storage/volumes/ollama-data"
      ];
      timerConfig = {
        OnCalendar = "02:00";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 6"
      ];
    };
  };

  # Automatic garbage collection - delete generations older than 30 days
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "04:00";
    allowReboot = false;
  };

  # Pull latest configuration before auto-upgrade
  systemd.services."nixos-upgrade-git-pull" = {
    description = "Pull latest NixOS configuration from git";
    before = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/etc/nixos";
      ExecStart = "${pkgs.git}/bin/git pull --ff-only";
    };
  };

  systemd.services."user-linger-craig" = {
    description = "Enable lingering for craig";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/loginctl enable-linger craig";
      RemainAfterExit = true;
    };
  };

  # Auto-update containers (Watchtower alternative)
  systemd.services."podman-auto-update" = {
    description = "Pull and update podman containers";
    path = [ pkgs.podman-compose pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      User = "craig";
      Group = "users";
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
      ExecStart = pkgs.writeShellScript "podman-auto-update" ''
        for compose in /etc/nixos/services/*/compose.yaml; do
          dir=$(dirname "$compose")
          echo "Updating $dir..."
          cd "$dir"
          ${pkgs.podman-compose}/bin/podman-compose pull || true
          ${pkgs.podman-compose}/bin/podman-compose up -d
        done
        # Prune old images
        ${pkgs.podman}/bin/podman image prune -f
      '';
    };
  };

  systemd.timers."podman-auto-update" = {
    description = "Run podman auto-update daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "05:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  programs.git = {
    enable = true;
    config = {
      user = {
        name = "CRBroughton";
        email = "crbroughton@posteo.uk";
      };
      init = {
        defaultBranch = "master";
      };
      gpg = {
        format = "ssh";
      };
      commit.gpgsign = true;
      "gpg \"ssh\"" = {
        allowedSignersFile = "~/.ssh/allowed_signers";
      };
    };
  };

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #   wget
    git
    openssh
    openssl
    podman-compose
    lazydocker
    lazygit
    just
    nixfmt
    btop
    micro
    restic
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
