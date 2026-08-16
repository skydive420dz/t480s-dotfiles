{
  config,
  pkgs,
  repoPath,
  username,
  homeDirectory,
  ...
}:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${repoPath}/${path}";
in
{
  imports = [ ../../../core/home ];

  home = {
    inherit username homeDirectory;
    stateVersion = "25.05";
    enableNixpkgsReleaseCheck = false;

    packages = [
      pkgs.gawk
    ];

    sessionPath = [ "$HOME/.local/bin" ];

    sessionVariables = {
      EDITOR = "emacsclient -t -a emacs";
      VISUAL = "emacsclient -t -a emacs";
      TERMINAL = "ghostty";
      FILE_MANAGER = "ranger";
    };

    file = {
      ".Xresources".source = link "config/x11/Xresources";
      ".local/bin/display-profile".source = link "config/x11/display-profile";
    };
  };

  programs.home-manager.enable = true;

  xdg = {
    enable = true;
    mimeApps.enable = true;
  };
}
