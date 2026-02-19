# nuship.nu - Native Nushell prompt

use git-helpers.nu *

def get-venv-tag [] {
    if ($env.VIRTUAL_ENV? == null) {
        return ""
    }
    let venv_name = $env.VIRTUAL_ENV | path basename
    let venv_path = if $venv_name in [".venv", "venv"] {
        $env.VIRTUAL_ENV | path dirname
    } else {
        $env.VIRTUAL_ENV
    }
    $" (ansi yellow)🐍 ($venv_path | str replace $nu.home-dir '~')(ansi reset)"
}

$env.PROMPT_COMMAND = {||
    let git_root = get-git-root
    let dir = if $git_root != null {
        let repo_name = $git_root | path basename
        let relative = $env.PWD | str replace $git_root ""
        $"($repo_name)($relative)"
    } else {
        $env.PWD | str replace $nu.home-dir "~"
    }
    let icon = if $env.PWD =~ '^/mnt/[a-z]($|/)' {
        "⊞ "
    } else if ($env.WSL_DISTRO_NAME? != null) {
        "🐧 "
    } else {
        ""
    }
    $"(ansi cyan)($icon)(ansi reset)($dir)(get-venv-tag)\n❯ "
}

$env.PROMPT_COMMAND_RIGHT = {||
    let git_branch = try { fast-get-git-branch } catch { "" }
    if $git_branch != "" {
        $"(ansi purple_bold)($git_branch)(ansi reset)"
    } else {
        ""
    }
}

$env.PROMPT_INDICATOR = ""
