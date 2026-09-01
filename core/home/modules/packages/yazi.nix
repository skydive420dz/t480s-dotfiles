{ pkgs, ... }:

let
  mpv = pkgs.mpv.override { youtubeSupport = false; };
in
{
  home.packages = [
    mpv
    pkgs.nsxiv
  ];

  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    shellWrapperName = "y";

    settings = {
      mgr = {
        ratio = [
          1
          3
          4
        ];
        sort_by = "natural";
        show_hidden = true;
        show_symlink = true;
      };

      preview = {
        tab_size = 2;
        max_width = 800;
        max_height = 1000;
        image_delay = 0;
      };

      opener = {
        image = [
          {
            run = "nsxiv -- %s";
            orphan = true;
            desc = "Open in nsxiv";
          }
        ];
        media = [
          {
            run = "mpv -- %s";
            orphan = true;
            desc = "Play in mpv";
          }
        ];
        browser = [
          {
            run = "brave -- %s";
            orphan = true;
            desc = "Open in Brave";
          }
        ];
      };

      open.prepend_rules = [
        {
          mime = "image/*";
          use = [
            "image"
            "reveal"
          ];
        }
        {
          mime = "{audio,video}/*";
          use = [
            "media"
            "reveal"
          ];
        }
        {
          url = "*.{htm,html,xhtm,xhtml}";
          use = [
            "browser"
            "edit"
            "reveal"
          ];
        }
      ];
    };

    keymap.mgr.prepend_keymap = [
      {
        on = [
          "g"
          "d"
        ];
        run = "cd ~/Downloads";
        desc = "Go to Downloads";
      }
      {
        on = [ "!" ];
        run = ''shell "$SHELL" --block'';
        desc = "Drop to Shell";
      }
    ];
  };
}
