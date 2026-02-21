# Disko disk configuration for server reinstall
# Usage: sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko ./disko-config.nix --arg device '"/dev/nvme0n1"'
{ device ? "/dev/nvme0n1" }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
