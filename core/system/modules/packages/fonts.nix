{ pkgs, ... }:

{
  fonts = {
    packages = [
      (pkgs.iosevka-bin.override { variant = "SGr-IosevkaTerm"; })
      (pkgs.iosevka-bin.override { variant = "Aile"; })
      pkgs.nerd-fonts.symbols-only
      pkgs.emacs-all-the-icons-fonts
      pkgs.dejavu_fonts
      pkgs.liberation_ttf
    ];
    fontconfig.defaultFonts = {
      monospace = [ "Iosevka Term" ];
      sansSerif = [ "Iosevka Aile" ];
      serif = [ "Liberation Serif" ];
    };
  };
}
