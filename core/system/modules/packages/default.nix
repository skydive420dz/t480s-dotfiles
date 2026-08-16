{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsa-utils
    jq
    kitty.terminfo
    unzip
    wget
    wireplumber
    zip
  ];
}
