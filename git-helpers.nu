# Git helper functions for Nushell
#
# Usage with Starship prompt:
#
# 1. In env.nu, source this file and set GIT_BRANCH in PROMPT_COMMAND:
#
#    source ~/path/to/git-helpers.nu
#
#    $env.PROMPT_COMMAND = {||
#        $env.GIT_BRANCH = try { fast-get-git-branch } catch { "" }
#    }
#
# 2. In starship.toml, display the env var and disable built-in git_branch:
#
#    [git_branch]
#    disabled = true
#
#    [env_var.GIT_BRANCH]
#    format = "[$env_value](green) "

# Find a file/directory by searching up from current directory
# Returns the full path if found, null otherwise
export def find-in-parents [name: string] {
    mut dir = pwd
    loop {
        let candidate = $dir | path join $name
        if ($candidate | path exists) {
            return $candidate
        }
        let parent = $dir | path dirname
        if $parent == $dir {
            return null
        }
        $dir = $parent
    }
}

# Fast way to get the current git branch name
# Reads directly from .git directory, supports worktrees
export def fast-get-git-branch [] {
    let git_path = find-in-parents ".git"
    if $git_path == null {
        error make { msg: "not a git repository" }
    }

    # Check if .git is a file (worktree) or directory (regular repo)
    let git_dir = if ($git_path | path type) == "file" {
        # Worktree: .git file contains "gitdir: /path/to/git/dir"
        open $git_path | str trim | parse "gitdir: {path}" | get path.0
    } else {
        $git_path
    }

    let head_path = $git_dir | path join "HEAD"
    let head_content = open $head_path | str trim

    # HEAD contains "ref: refs/heads/branch-name" or a commit hash (detached)
    if ($head_content | str starts-with "ref: ") {
        $head_content | str replace "ref: refs/heads/" ""
    } else {
        # Detached HEAD - return short commit hash
        $head_content | str substring 0..7
    }
}
