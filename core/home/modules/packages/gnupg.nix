# ============================================
# GNUPG / GPG-AGENT — declarative configuration
# ============================================
# Writes ~/.gnupg/gpg-agent.conf via home.file (one specific file,
# nothing else). Does NOT use `services.gpg-agent` because that
# module tries to manage the entire ~/.gnupg/ directory and conflicts
# with gpg's own management of keys/trustdb/random_seed.
#
# pinentry-gnome3 is used for graphical passphrase prompts. It works
# for both GUI and terminal applications. Terminal applications spawn a popup
# instead of an inline TTY prompt. Same outcome, slightly different UX.
#
# Trade-off: if you ever SSH into this machine and try to use pass on
# the remote terminal, pinentry-gnome3 has nowhere to draw. Not a
# concern for a personal laptop. If you ever need it, swap in
# pinentry-tty or a hybrid setup with pinentry-curses fallback.
#
# After applying:
#   nrs
#   gpgconf --kill gpg-agent      # pick up new config
#
# To set up on a fresh machine:
#   1. Clone this repo
#   2. Restore ~/.gnupg/ from your backup (private keys, etc.)
#   3. nixos-rebuild switch (this module writes the conf)
#   4. gpgconf --kill gpg-agent
#   That's it — pass works immediately.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pinentry-gnome3
  ];

  # Write only this one file. Everything else in ~/.gnupg/ is left
  # to gpg's own management (keys, trustdb, etc.).
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3
    default-cache-ttl 7200
    max-cache-ttl 28800
  '';
}
