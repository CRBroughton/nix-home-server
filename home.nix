{ config, pkgs, fish-flake, ... }:

{
  imports = [
    fish-flake.homeManagerModules.default
  ];

  home.stateVersion = "25.11";


  programs.fish-shell.enable = true;

}
