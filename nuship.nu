# nuship.nu - Native Nushell prompt

use git-helpers.nu *

$env.PROMPT_COMMAND = {||
    $env.GIT_BRANCH = try { fast-get-git-branch } catch { "" }
    let dir = $env.PWD | str replace $nu.home-path "~"
    $"(ansi cyan)🐧 (ansi reset)($dir)\n❯ "
}

$env.PROMPT_COMMAND_RIGHT = {||
    let git_branch = ($env.GIT_BRANCH? | default "")
    if $git_branch != "" {
        $"(ansi purple_bold)($git_branch)(ansi reset)"
    } else {
        ""
    }
}

$env.PROMPT_INDICATOR = ""
