{ config, pkgs, fish-flake, podman-flake, ... }:

{
  imports = [
    fish-flake.homeManagerModules.default
  ];

  home.stateVersion = "25.11";


  programs.fish-shell.enable = true;
  programs.podman-config.enable = true;
}
