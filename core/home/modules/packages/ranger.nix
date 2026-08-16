{ pkgs, ... }:

let
  rangerDevicons = pkgs.fetchFromGitHub {
    owner = "alexanderjeurissen";
    repo = "ranger_devicons";
    rev = "1bcaff0366a9d345313dc5af14002cfdcddabb82";
    hash = "sha256-qvWqKVS4C5OO6bgETBlVDwcv4eamGlCUltjsBU3gAbA=";
  };
  mpv = pkgs.mpv.override { youtubeSupport = false; };
in
{
  home.packages = [
    mpv
    pkgs.nsxiv
    pkgs.ranger
  ];

  xdg.configFile."ranger/plugins/ranger_devicons".source = rangerDevicons;
}
