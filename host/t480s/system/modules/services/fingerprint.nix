{ inputs, pkgs, ... }:

let
  pythonValidity =
    inputs.t480-fingerprint.packages.${pkgs.stdenv.hostPlatform.system}.python-validity.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [ ./fingerprint/python-validity-06cb-009a.patch ];

        postPatch = (old.postPatch or "") + ''
          install -m 0644 ${./fingerprint/tmpdir.py} validitysensor/tmpdir.py
        '';

        doCheck = true;
        postCheck = (old.postCheck or "") + ''
          PYTHONPATH=. ${pkgs.python3}/bin/python tests/test_usb_retry.py
        '';
      });

  playgroundPython = pkgs.python3.withPackages (_: [ pythonValidity ]);
  fingerprintBootstrap = pkgs.writeShellScriptBin "t480s-validity-playground" ''
    umask 077
    exec ${playgroundPython}/bin/python -i ${pythonValidity}/share/python-validity/playground/prototype.py "$@"
  '';
in
{
  imports = [
    inputs.t480-fingerprint.nixosModules.open-fprintd

    (
      args:
      import "${inputs.t480-fingerprint}/modules/python-validity" (
        args
        // {
          localPackages = {
            python-validity = pythonValidity;
          };
        }
      )
    )
  ];

  # Build-check the one-time bootstrap without installing or enabling it.
  system.build.fingerprintBootstrap = fingerprintBootstrap;
  system.checks = [ fingerprintBootstrap ];

  # The reader re-enumerates after sleep, so reopen its USB handle.
  powerManagement.resumeCommands = "${pkgs.systemd}/bin/systemctl restart python3-validity.service";

  systemd.tmpfiles.rules = [
    "d /run/python-validity 0700 root root -"
    "d /var/lib/python-validity 0700 root root -"
  ];

  services = {
    open-fprintd.enable = true;
    python-validity.enable = true;
    fprintd.enable = false;
  };

  security.pam.services = {
    login.fprintAuth = false;
    sudo.fprintAuth = true;
  };
}
