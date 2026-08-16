{ config, pkgs, ... }:

{
  systemd.user.services.emacs = {
    Unit = {
      Description = "Emacs daemon";
      PartOf = [ "nixos-fake-graphical-session.target" ];
      After = [ "nixos-fake-graphical-session.target" ];
    };
    Service = {
      Environment = [
        "PATH=/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
        "SK_EMACS_SHELL=${pkgs.fish}/bin/fish"
        "SK_EMACS_TREE_SITTER_GRAMMAR_PATH=${config.home.homeDirectory}/.cache/emacs/tree-sitter-grammars/lib"
        "SK_EMACS_ESHELL_ALIASES_FILE=${config.home.sessionVariables.SK_EMACS_ESHELL_ALIASES_FILE}"
      ];
      ExecStart = "${pkgs.emacs-gtk}/bin/emacs --init-directory=${config.xdg.configHome}/emacs --fg-daemon";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "nixos-fake-graphical-session.target" ];
  };
}
