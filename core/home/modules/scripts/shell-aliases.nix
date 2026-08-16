{ repoPath }:

{
  btw = "echo I use nixos, btw";
  nfu = "nix flake update --flake ${repoPath}";
  nrb = "sudo nixos-rebuild boot --flake ${repoPath}#t480s";
  nrs = "sudo nixos-rebuild switch --flake ${repoPath}#t480s";
  vim = "emacsclient --create-frame --alternate-editor=emacs";
  ls = "ls --color=auto";
  ll = "ls -la --color=auto";
  btop = "ghostty --title=btop_float -e btop";
  nvtop = "ghostty --title=nvtop_float -e nvtop";
  tm = "tmux-session main";
  tmd = "tmux-session dots";
}
