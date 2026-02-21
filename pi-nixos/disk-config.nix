{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";  # Change to your SD card device
        content = {
          type = "gpt";
          partitions = {
            firmware = {
              size = "512M";
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