{ pkgs, ... }:

{
  xdg.configFile."systemd/user/nixos-fake-graphical-session.target.wants/mpris-proxy.service".source =
    "${pkgs.bluez}/etc/systemd/user/mpris-proxy.service";
}
