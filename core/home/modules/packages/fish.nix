{ repoPath, ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = import ../scripts/shell-aliases.nix { inherit repoPath; };
  };
}
