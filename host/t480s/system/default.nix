{ pkgs, username, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./kernel.nix
    ../../../core/system
    ./modules/services/boot.nix
    ./modules/services/hardware.nix
    ./modules/services/power.nix
    ./modules/services/x11.nix
  ];

  system.stateVersion = "25.05";

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "audio"
      "input"
      "networkmanager"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABClAXOeEh/2GHlwyKuAq2L3EY5sZYsw/I4HlLYKokm r0liveira@icloud.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFY+QfRli3gArIR6yXju7uMfgYfMlmVkTfsXbLw6zaVa skydive420dz@nixos"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "/run/current-system/systemd/bin/systemctl reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/systemd/bin/systemctl poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  programs.fish.enable = true;
}
