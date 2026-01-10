# tmux-util.nu - Tmux workspace helper

# Start a tmux workspace with multiple services
export def tmux-workspace [
    name: string                # Session name
    services: list<list>        # List of [dir, cmd] pairs
    --no-attach (-n)            # Don't attach after starting
] {
    let exists = (tmux has-session -t $name | complete).exit_code == 0

    if $exists {
        if not $no_attach {
            if ($env.TMUX? | is-not-empty) {
                tmux switch-client -t $name
            } else {
                tmux attach-session -t $name
            }
        } else {
            print $"Workspace '($name)' already running"
        }
        return
    }

    let base_index = (tmux show-option -gv base-index | into int)

    for idx in 0..<($services | length) {
        let svc = $services | get $idx
        let win_name = $svc.0
        let dir = $svc.1
        let cmd = $svc.2
        let win_idx = $base_index + $idx
        let win_target = $"($name):($win_idx)"
        if $idx == 0 {
            tmux new-session -d -s $name -c $dir -n $win_name
        } else {
            tmux new-window -t $name -c $dir -n $win_name
        }
        tmux set-window-option -t $win_target allow-rename off
        tmux set-window-option -t $win_target automatic-rename off
        tmux send-keys -t $win_target $cmd C-m
    }

    tmux select-window -t $"($name):($base_index)"

    if not $no_attach {
        if ($env.TMUX? | is-not-empty) {
            tmux switch-client -t $name
        } else {
            tmux attach-session -t $name
        }
    } else {
        print $"Workspace '($name)' started"
    }
}
