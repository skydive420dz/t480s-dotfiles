{
  imports = [
    ./modules/services/audio.nix
    ./modules/services/networking.nix
    ./modules/services/power.nix
    ./modules/packages/default.nix
    ./modules/packages/brave.nix
    ./modules/packages/fonts.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "America/New_York";
}
