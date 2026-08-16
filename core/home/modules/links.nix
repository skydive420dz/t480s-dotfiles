{ config, repoPath, ... }:

let
  link = path: config.lib.file.mkOutOfStoreSymlink "${repoPath}/${path}";
in
{
  xdg.configFile = {
    "emacs" = {
      source = link "config/emacs";
      force = true;
    };
    "fish/conf.d/t480s.fish".source = link "config/fish/conf.d/t480s.fish";
    "ghostty/config".source = link "config/ghostty/config";
    "ghostty/shaders".source = link "config/ghostty/shaders";
    "ranger/rc.conf".source = link "config/ranger/rc.conf";
    "ranger/rifle.conf".source = link "config/ranger/rifle.conf";
    "tmux/t480s.conf".source = link "config/tmux/t480s.conf";
  };
}
