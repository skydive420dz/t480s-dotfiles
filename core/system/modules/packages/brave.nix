# ============================================
# BRAVE POLICY
# ============================================
# Brave reads Linux managed policy JSON from /etc/brave/policies/managed/.
# Keep this file for true global policy only; bookmarks, history, tabs,
# extension state, Sync chain, and profile preferences stay Brave-owned.

{ ... }:

let
  chromeWebStore = "https://clients2.google.com/service/update2/crx";

  normalExtension = {
    installation_mode = "normal_installed";
    update_url = chromeWebStore;
  };
in
{
  environment.etc."brave/policies/managed/sky.json".text = builtins.toJSON {
    # Bitwarden owns credentials.
    PasswordManagerEnabled = false;
    AutofillAddressEnabled = false;
    AutofillCreditCardEnabled = false;

    # Trim Brave extras that are not part of the trial.
    BraveAIChatEnabled = false;
    BraveNewsDisabled = true;
    BravePlaylistEnabled = false;
    BraveRewardsDisabled = true;
    BraveSpeedreaderEnabled = false;
    BraveStatsPingEnabled = false;
    BraveTalkDisabled = true;
    BraveVPNDisabled = true;
    BraveWalletDisabled = true;
    BraveWaybackMachineEnabled = false;
    BraveWebDiscoveryEnabled = false;

    ExtensionSettings = {
      # Keep normal extension installation available while the browser is
      # managed. Specific trial extensions are installed declaratively below.
      "*" = {
        installation_mode = "allowed";
      };

      # Bitwarden
      nngceckbapebfimnlniiiahkandclblb = normalExtension;

      # I Still Don't Care About Cookies
      edibdbjcniadpccecjdfdjjppcpchdlm = normalExtension;

      # Video DownloadHelper
      lmjnegcaeklhafolokijcfjliaokphfk = normalExtension;

      # AdNauseam is unpacked from:
      # ~/.config/BraveSoftware/adnauseam.chromium
      # Keep it manual unless we later vendor and package it intentionally.
    };
  };
}
