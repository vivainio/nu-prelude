# tmux-util.nu - Tmux workspace helper

# Start a tmux session named after current directory with claude
export def wss [
    name?: string  # Optional session name (defaults to current directory name)
] {
    let name = ($name | default ($env.PWD | path basename))
    let exists = (tmux has-session -t $name | complete).exit_code == 0

    if $exists {
        if ($env.TMUX? | is-not-empty) {
            tmux switch-client -t $name
        } else {
            tmux attach-session -t $name
        }
        return
    }

    # Create config for the single-window workspace
    let config = [{name: $name, dir: $env.PWD, cmd: "claude"}]

    tmux new-session -d -s $name -c $env.PWD -n $name
    tmux set-environment -t $name TMUX_WORKSPACE_CONFIG ($config | to nuon)
    tmux send-keys -t $name $"tmux-workspace-enter ($name) ($name)" C-m

    if ($env.TMUX? | is-not-empty) {
        tmux switch-client -t $name
    } else {
        tmux attach-session -t $name
    }
}

# Called when entering a tmux workspace window
export def tmux-workspace-enter [session?: string, window?: string] {
    $env.config.shell_integration.osc2 = false

    if ($session | is-not-empty) and ($window | is-not-empty) {
        let config = (tmux show-environment -t $session TMUX_WORKSPACE_CONFIG | str replace 'TMUX_WORKSPACE_CONFIG=' '' | from nuon)
        let svc = $config | where {|s| $s.name == $window } | first
        if ($svc | is-not-empty) {
            print -n $"\e]2;($svc.name)\e\\"
            cd $svc.dir
            run-external ($svc.cmd | split row ' ' | first) ...($svc.cmd | split row ' ' | skip 1)
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

    # Convert input lists to records with expanded paths
    let config = $services | each {|svc|
        {name: $svc.0, dir: ($svc.1 | path expand), cmd: $svc.2}
    }

    for idx in 0..<($config | length) {
        let svc = $config | get $idx
        let win_idx = $base_index + $idx
        let win_target = $"($name):($win_idx)"
        if $idx == 0 {
            tmux new-session -d -s $name -c $svc.dir -n $svc.name
            tmux set-environment -t $name TMUX_WORKSPACE_CONFIG ($config | to nuon)
        } else {
            tmux new-window -t $name -c $svc.dir -n $svc.name
        }
        tmux send-keys -t $win_target $"tmux-workspace-enter ($name) ($svc.name)" C-m
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
