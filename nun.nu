# nun.nu - Obsidian Vault Manager
# 
# This module provides tools to interact with Obsidian vaults.
# Set the environment variable NUN_VAULT_PATH to your vault's root directory.
# Defaults to "C:/r/vaults/ville".

# Helper to get the vault path.
def get-vault-path [] {
    $env.NUN_VAULT_PATH? | default "C:/r/vaults/ville"
}

# Helper to get all markdown files in the vault
def get-files [pattern = "**/*.md"] {
    let vault = get-vault-path
    cd $vault
    ls **/* | where type == file | where name ends-with .md
}

# Set the vault path environment variable
export def --env "nun set-vault" [
    path: string # Path to the Obsidian vault
] {
    let expanded_path = ($path | path expand)
    if not ($expanded_path | path exists) {
        print $"Warning: Path '($expanded_path)' does not exist."
    }
    $env.NUN_VAULT_PATH = $expanded_path
    print $"Vault path set to: ($expanded_path)"
}

# List all notes in the vault
export def "nun list" [] {
    get-files 
}

# Create a new note
# Usage: nun new "My Note" --content "# My Note\n\nContent here"
export def "nun new" [
    name: string       # Name of the note (with or without .md extension)
    --content: string  # Initial content of the note
] {
    let vault = get-vault-path
    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    let path = ($vault | path join $filename)
    
    if ($path | path exists) {
        error make { msg: $"Note '($filename)' already exists at ($path)" }
    }
    
    # Ensure directory exists if the name contains a path
    let dir = ($path | path dirname)
    if not ($dir | path exists) {
        mkdir $dir
    }

    $content | default "" | save $path
    print $"Created note: ($path)"
}

# Read a note's content
export def "nun read" [
    name: string # Name of the note to read
] {
    let vault = get-vault-path
    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    
    cd $vault

    # Try exact match first
    if ($filename | path exists) {
        open $filename
        return
    }

    # Search recursively
    let matches = (get-files ("**/" + $filename))
    
    if ($matches | is-empty) {
        error make { msg: $"Note '($name)' not found in vault ($vault)" }
    } else if ($matches | length) > 1 {
        print "Multiple matches found:"
        $matches | get name
        error make { msg: "Ambiguous note name" }
    } else {
        open ($matches | first | get name)
    }
}

# Search for notes containing text
export def "nun search" [
    query: string # Text to search for
] {
    let vault = get-vault-path
    # This is a naive implementation. For large vaults, consider using 'rg' if available.
    get-files | each {|file|
        let content = (try { open $file.name } catch { "" })
        if ($content | str contains $query) {
            {
                name: $file.name
                path: ($vault | path join $file.name)
            }
        }
    } | flatten
}

# Append text to a note
export def "nun append" [
    name: string     # Name of the note
    content: string  # Content to append
] {
    let vault = get-vault-path
    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    
    cd $vault

    # Try exact match first
    if ($filename | path exists) {
        $"\n($content)" | save --append $filename
        print $"Appended to ($vault | path join $filename)"
        return
    }
    
    # Search recursively
    let matches = (get-files ("**/" + $filename))
    
    if ($matches | is-empty) {
        print $"Note ($name) not found. Creating it."
        $content | save $filename
        print $"Created ($vault | path join $filename)"
    } else if ($matches | length) > 1 {
        print "Multiple matches found:"
        $matches | get name
        error make { msg: "Ambiguous note name" }
    } else {
        let path = ($matches | first | get name)
        $"\n($content)" | save --append $path
        print $"Appended to ($vault | path join $path)"
    }
}

# Open a note in the default application (usually Obsidian if configured)
export def "nun open" [
    name?: string # Optional note name to open. If omitted, opens the vault folder.
] {
    let vault = get-vault-path
    
    if ($name == null) {
        start $vault
        return
    }

    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    
    cd $vault

    # Try exact match first
    if ($filename | path exists) {
        start $filename
        return
    }

    # Search recursively
    let matches = (get-files ("**/" + $filename))
    
    if ($matches | is-empty) {
        error make { msg: $"Note '($name)' not found in vault ($vault)" }
    } else {
        start ($matches | first | get name)
    }
}
