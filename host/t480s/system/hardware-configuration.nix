# Generated on the mounted T480s installation layout by nixos-generate-config.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    resumeDevice = "/dev/disk/by-uuid/28d5c812-d3e4-4ba2-8cd0-535a35162ab6";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/995d2695-879e-4577-aaaf-9fed26eed6f4";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/878D-A749";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/995d2695-879e-4577-aaaf-9fed26eed6f4";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/28d5c812-d3e4-4ba2-8cd0-535a35162ab6"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
