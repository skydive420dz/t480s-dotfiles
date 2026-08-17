{
  lib,
  pkgs,
  repoPath,
  ...
}:

let
  dwm = pkgs.dwm.override { conf = ../../../../../config/dwm/dwm.h; };
  dmenu = pkgs.dmenu.override { conf = ../../../../../config/dmenu/dmenu.h; };
  slstatus = pkgs.slstatus.override { conf = ../../../../../config/slstatus/slstatus.h; };
in
{
  services.xserver = {
    enable = true;
    videoDrivers = [ "modesetting" ];
    xkb.options = "caps:escape";

    displayManager.startx = {
      enable = true;
      generateScript = true;
      extraCommands = ''
        ${pkgs.xset}/bin/xset r rate 210 67
        ${pkgs.xrdb}/bin/xrdb -merge "$HOME/.Xresources"
        ${pkgs.xwallpaper}/bin/xwallpaper --zoom "${repoPath}/config/wallpaper/three-girls-anime-lakeside-3840x1600.png"
      '';
    };

    windowManager.dwm = {
      enable = true;
      package = dwm;
      extraSessionCommands = ''
        ${slstatus}/bin/slstatus &
      '';
    };
  };

  services.xserver.inputClassSections = lib.mkAfter [
    ''
      Identifier "T480s TrackPoint button scrolling"
      MatchProduct "Elan TrackPoint"
      Option "ScrollMethod" "button"
      Option "ScrollButton" "2"
    ''
  ];

  services.libinput = {
    enable = true;
    touchpad.naturalScrolling = true;
  };

  environment.systemPackages = [
    dmenu
    slstatus
    pkgs.brightnessctl
    pkgs.xclip
    pkgs.xrandr
    pkgs.xset
    pkgs.xrdb
    pkgs.xwallpaper
  ];
}
