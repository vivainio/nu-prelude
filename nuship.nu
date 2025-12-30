# nuship.nu - Native Nushell prompt

use git-helpers.nu *

$env.PROMPT_COMMAND = {||
    let git_root = get-git-root
    let dir = if $git_root != null {
        let repo_name = $git_root | path basename
        let relative = $env.PWD | str replace $git_root ""
        $"($repo_name)($relative)"
    } else {
        $env.PWD | str replace $nu.home-path "~"
    }
    let icon = if ($env.WSL_DISTRO_NAME? != null) { "🐧 " } else { "" }
    $"(ansi cyan)($icon)(ansi reset)($dir)\n❯ "
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
