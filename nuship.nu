# nuship.nu - Native Nushell prompt

$env.PROMPT_COMMAND = {||
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
