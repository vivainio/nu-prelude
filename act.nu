# Environment activation helpers for Nushell
# Usage: use act.nu *

# Check if a path is absolute (works on both Unix and Windows)
def is-absolute []: string -> bool {
    let first = ($in | path split | first)
    $first == "/" or $first =~ '^[A-Za-z]:$'
}

# Find a file by searching up the directory tree
def find-up [filename: string]: nothing -> string {
    mut dir = $env.PWD
    mut result = ""
    while $result == "" {
        let candidate = ($dir | path join $filename)
        if ($candidate | path exists) {
            $result = $candidate
        } else {
            let parent = ($dir | path dirname)
            if $parent == $dir {
                break
            }
            $dir = $parent
        }
    }
    $result
}

# Find env.nuon up the directory tree and activate it
export def --env main [
    --quiet(-q)           # Don't print activation message
    --workspace(-w): string  # Start tmux workspace (name or "all")
    --no-attach(-n)       # Don't attach to workspace (use with -w)
] {
    let env_file = find-up "env.nuon"
    if ($env_file | is-empty) {
        error make { msg: "No env.nuon found in directory tree" }
    }
    let env_dir = $env_file | path dirname

    if not $quiet {
        print $"Activating: ($env_file)"
    }

    let config = open $env_file

    # venv: activate Python virtual environment
    if "venv" in $config {
        let venv_path = if ($config.venv | is-absolute) {
            $config.venv
        } else {
            $env_dir | path join $config.venv
        }
        let bin_dir = if $nu.os-info.name == "windows" { "Scripts" } else { "bin" }
        $env.VIRTUAL_ENV = $venv_path
        $env.PATH = ($env.PATH | prepend ($venv_path | path join $bin_dir))
    }

    # path: prepend directories to PATH
    if "path" in $config {
        for dir in $config.path {
            let full_path = if ($dir | is-absolute) { $dir } else {
                $env_dir | path join $dir
            }
            $env.PATH = ($env.PATH | prepend $full_path)
        }
    }

    # dotenv: source .env file(s)
    if "dotenv" in $config {
        let files = if ($config.dotenv | describe | str starts-with "list") {
            $config.dotenv
        } else {
            [$config.dotenv]
        }
        for file in $files {
            let dotenv_path = if ($file | is-absolute) { $file } else {
                $env_dir | path join $file
            }
            open $dotenv_path
            | lines
            | where { |l| not ($l | str starts-with "#") and ($l | str contains "=") }
            | parse "{key}={value}"
            | transpose -r -d
            | load-env
        }
    }

    # env: set environment variables
    if "env" in $config {
        $config.env | load-env
    }

    # tmux_workspace: start tmux workspace(s)
    if ($workspace | is-not-empty) {
        if "tmux_workspace" not-in $config {
            error make { msg: "No tmux_workspace defined in env.nuon" }
        }
        use tmux-util.nu tmux-workspace

        let project_name = $config.name? | default ($env_dir | path basename)
        let workspaces = $config.tmux_workspace

        # Helper to start a single workspace
        let start_one = {|ws_name, services|
            let session_name = $"($project_name)-($ws_name)"
            let expanded = $services | each {|svc|
                let dir = if ($svc.1 | is-absolute) { $svc.1 } else { $env_dir | path join $svc.1 }
                [$svc.0, $dir, $svc.2] | append (if ($svc | length) > 3 { [$svc.3] } else { [] })
            }
            if $no_attach {
                tmux-workspace $session_name $expanded -n
            } else {
                tmux-workspace $session_name $expanded
            }
        }

        if $workspace == "all" {
            # Start all workspaces
            for ws_name in ($workspaces | columns) {
                do $start_one $ws_name ($workspaces | get $ws_name)
            }
        } else {
            # Start specific workspace
            if $workspace not-in ($workspaces | columns) {
                let available = $workspaces | columns | str join ", "
                error make { msg: $"Workspace '($workspace)' not found. Available: ($available)" }
            }
            do $start_one $workspace ($workspaces | get $workspace)
        }
    }
}
