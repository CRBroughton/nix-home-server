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
}
