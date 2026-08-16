{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "tmux-session" ''
      set -euo pipefail

      tmux_bin="${pkgs.tmux}/bin/tmux"
      fzf_bin="${pkgs.fzf}/bin/fzf"
      home_dir="${config.home.homeDirectory}"
      repo_dir="$home_dir/Projects/t480s-dotfiles"
      docs_dir="$repo_dir/docs"

      session_table() {
        printf 'main\t%s\n' "$home_dir"
        printf 'dots\t%s\n' "$repo_dir"
        printf 'notes\t%s\n' "$docs_dir/README.org"
      }

      normalize_session() {
        printf '%s\n' "$1"
      }

      session_dir() {
        case "$1" in
          main) printf '%s\n' "$home_dir" ;;
          dots) printf '%s\n' "$repo_dir" ;;
          notes) printf '%s\n' "$docs_dir" ;;
          *) printf '%s\n' "$PWD" ;;
        esac
      }

      choose_session() {
        if [ -n "''${1:-}" ]; then
          normalize_session "$1"
          return
        fi

        session_table \
          | "$fzf_bin" \
            --delimiter=$'\t' \
            --with-nth=1 \
            --prompt='tmux session > ' \
            --height=40% \
          | cut -f1
      }

      create_session() {
        target="$1"
        dir="$(session_dir "$target")"

        if [ ! -d "$dir" ]; then
          dir="$home_dir"
        fi

        case "$target" in
          main)
            "$tmux_bin" new-session -d -s "$target" -c "$dir" -n main
            ;;
          dots)
            "$tmux_bin" new-session -d -s "$target" -c "$dir" -n files ranger
            "$tmux_bin" split-window -h -t "$target:files" -c "$dir"
            "$tmux_bin" new-window -t "$target:" -c "$dir" -n term
            "$tmux_bin" select-window -t "$target:files"
            ;;
          notes)
            "$tmux_bin" new-session -d -s "$target" -c "$dir" -n notes 'emacsclient --tty --alternate-editor=emacs README.org'
            ;;
          *)
            "$tmux_bin" new-session -d -s "$target" -c "$dir" -n "$target"
            ;;
        esac
      }

      target="$(choose_session "''${1:-}")"
      if [ -z "$target" ]; then
        exit 0
      fi

      if ! "$tmux_bin" has-session -t "=$target" 2>/dev/null; then
        create_session "$target"
      fi

      if [ -n "''${TMUX:-}" ]; then
        exec "$tmux_bin" switch-client -t "=$target"
      fi

      exec "$tmux_bin" attach-session -t "=$target"
    '')
  ];
}
