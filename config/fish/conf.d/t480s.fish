alias vi 'emacsclient -t -a emacs'
alias v 'emacsclient -t -a emacs'
alias fm y

if status is-login; and test -z "$SSH_CONNECTION"; and test -z "$DISPLAY"; and test (tty) = /dev/tty1
    exec startx
end

if status is-interactive; and test -z "$TMUX"
    if test -n "$SSH_CONNECTION"; or string match -q 'xterm-ghostty*' "$TERM"
        exec tmux new-session -A -s main
    end
end

function fish_greeting
    if command -q fastfetch
        fastfetch
    end
end
