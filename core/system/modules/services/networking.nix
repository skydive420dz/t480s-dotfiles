{ hostname, ... }:

{
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
