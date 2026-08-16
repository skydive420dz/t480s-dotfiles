{ repoPath }:

{
  nfu = "nix flake update --flake ${repoPath}";
  nrb = "sudo nixos-rebuild boot --flake ${repoPath}#t480s";
  nrs = "sudo nixos-rebuild switch --flake ${repoPath}#t480s";
  ls = "ls --color=auto";
  ll = "ls -la --color=auto";
  cat = "bat";
  btop = "ghostty --title=btop_float -e btop";
  tm = "tmux-session main";
  tmd = "tmux-session dots";
}
