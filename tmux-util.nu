# tmux-util.nu - Tmux workspace helper

# Called when entering a tmux workspace window
export def tmux-workspace-enter [session?: string, window?: string] {
    $env.config.shell_integration.osc2 = false

    if ($session | is-not-empty) and ($window | is-not-empty) {
        let config = (tmux show-environment -t $session TMUX_WORKSPACE_CONFIG | str replace 'TMUX_WORKSPACE_CONFIG=' '' | from nuon)
        let svc = $config | where {|s| $s.0 == $window } | first
        if ($svc | is-not-empty) {
            print -n $"\e]2;($svc.0)\e\\"
            cd ($svc.1 | path expand)
            run-external ($svc.2 | split row ' ' | first) ...($svc.2 | split row ' ' | skip 1)
        }
    }
}

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
        let dir = $svc.1 | path expand
        let cmd = $svc.2
        let win_idx = $base_index + $idx
        let win_target = $"($name):($win_idx)"
        if $idx == 0 {
            tmux new-session -d -s $name -c $dir -n $win_name
            tmux set-environment -t $name TMUX_WORKSPACE_CONFIG ($services | to nuon)
        } else {
            tmux new-window -t $name -c $dir -n $win_name
        }
        tmux send-keys -t $win_target $"tmux-workspace-enter ($name) ($win_name)" C-m
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
