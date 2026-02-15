{
  config,
  pkgs,
  fish-flake,
  podman-flake,
  ...
}:

{
  home.stateVersion = "25.11";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  programs.fish-shell.enable = true;
  programs.podman-config = {
    enable = true;
  };

  systemd.user.services.podman-socket-restart = {
    Unit = {
      Description = "Restart podman socket on boot";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart podman.socket";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.services.podman = {
    Service = {
      Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin";
    };
  };
}
