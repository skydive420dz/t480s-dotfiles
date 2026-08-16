{ pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];

  environment.systemPackages = with pkgs; [
    libinput
    evtest
    tmux
    vim
    lshw
    git
    ripgrep
    fd

    fzf

    nil
    nixpkgs-fmt
    nodejs
    gcc
    c3-lsp

    fastfetch
    nitch

    (mpv.override { youtubeSupport = false; })
    cava

    bluez
    bluez-tools
    bluetui
    tree
  ];
}
