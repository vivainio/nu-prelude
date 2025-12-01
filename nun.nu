# nun.nu - Obsidian Vault Manager
# 
# This module provides tools to interact with Obsidian vaults.
# Vault paths are stored persistently using std-rfc/kv.
# Defaults to "C:/r/vaults/ville".

use std-rfc/kv *

# Helper to get the vault path from persistent storage.
def get-vault-path [] {
    let path = (kv get "nun.current-vault")
    
    if $path == null {
        "C:/r/vaults/ville"
    } else {
        $path
    }
}

# Helper to get the journal vault path from persistent storage.
# Requires explicit configuration - does not fall back to main vault.
def get-journal-vault-path [] {
    let path = (kv get "nun.journal-vault")
    
    if $path == null {
        error make { 
            msg: "Journal vault not configured. Set it with: nun set-vault <path> --journal"
        }
    } else {
        $path
    }
}

# Helper to get all markdown files in the vault
def get-files [pattern = "**/*.md"] {
    let vault = get-vault-path
    cd $vault
    ls **/* | where type == file | where name ends-with .md
}

# Tab completion for note names
def complete-note [] {
    get-files | get name | where { |name| not ($name | str starts-with "journals/") and not ($name | str starts-with "journals\\") } | each {|name| 
        {value: ($name | str replace '.md' ''), description: $name}
    }
}

# Tab completion for top-level directories in vault
def complete-vault-dirs [] {
    let vault = get-vault-path
    cd $vault
    let dirs = (try { ls | where type == dir | get name } catch { [] })
    
    $dirs | each {|dir|
        let dir_name = ($dir | path basename)
        {value: $dir_name, description: $dir_name}
    }
}

# Set the current vault path persistently
export def "nun set-vault" [
    path: string                # Path to the Obsidian vault
    --journal                   # Set as journal vault instead of main vault
] {
    let expanded_path = ($path | path expand)
    if not ($expanded_path | path exists) {
        print $"Warning: Path '($expanded_path)' does not exist."
    }
    
    if $journal {
        let path_parts = ($expanded_path | path split)
        if not ($path_parts | any {|part| $part == "journals"}) {
            print $"Warning: Journal vault path does not contain 'journals' as a path element. Consider using a path like 'C:/vaults/my-vault/journals'."
        }
        kv set "nun.journal-vault" $expanded_path
        print $"Journal vault path set to: ($expanded_path)"
    } else {
        kv set "nun.current-vault" $expanded_path
        print $"Main vault path set to: ($expanded_path)"
    }
}

# List all notes in the vault
export def "nun list" [] {
    get-files 
}

# Create a new note
# Usage: nun new "My Note" or nun new "folder/My Note"
# Optional: --content to set initial content
export def "nun new" [
    name: string@complete-vault-dirs       # Name of the note (with or without .md extension, can include path)
    --content: string  # Initial content of the note
] {
    let vault = get-vault-path
    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    let path = ($vault | path join $filename)
    
    if ($path | path exists) {
        error make { msg: $"Note '($filename)' already exists at ($path)" }
    }
    
    # Ensure directory exists
    let dir_path = ($path | path dirname)
    if not ($dir_path | path exists) {
        mkdir $dir_path
    }

    $content | default "" | save $path
    print $"Created note: ($path)"
    
    # If no content was provided, open the note in the default application
    if ($content == null) {
        start $path
    }
}

# Read a note's content
export def "nun read" [
    name: string@complete-note # Name of the note to read
] {
    let vault = get-vault-path
    let filename = if ($name | str ends-with ".md") { $name } else { $name + ".md" }
    
    cd $vault

    # Try exact match first
    if ($filename | path exists) {
        return (open $filename)
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
    } | compact
}

# Append text to a note
export def "nun append" [
    name: string@complete-note     # Name of the note
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
    name?: string@complete-note # Optional note name to open. If omitted, opens the vault folder.
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

# Open today's journal file
# If called with arguments, append them to today's note without opening
export def --wrapped "nunn" [
    ...rest: string  # Optional content to append to today's note
] {
    let journal_path_dir = get-journal-vault-path
    let today = (date now | format date "%Y-%m-%d")
    let journal_path = ($journal_path_dir | path join $"($today).md")
    
    # Create the journal directory if it doesn't exist
    if not ($journal_path_dir | path exists) {
        mkdir $journal_path_dir
    }
    
    # Create the journal file if it doesn't exist
    if not ($journal_path | path exists) {
        "" | save $journal_path
        print $"Created journal: ($journal_path)"
    }
    
    # If content provided, append it to the note
    if ($rest | length) > 0 {
        let content = ($rest | str join " ")
        $"\n($content)" | save --append $journal_path
        print $"Appended to ($journal_path)"
        return
    }
    
    # Open the journal file
    start $journal_path
}

# Show the 7 most recent journal entries
export def "nun journal" [] {
    let journal_path_dir = get-journal-vault-path
    
    if not ($journal_path_dir | path exists) {
        print "No journal directory found"
        return
    }
    
    let entries = (
        ls $journal_path_dir 
        | where name ends-with ".md"
        | sort-by name
        | last 7
    )
    
    if ($entries | is-empty) {
        print "No journal entries found"
        return
    }
    
    $entries | each {|entry|
        let date = ($entry.name | str replace ".md" "")
        let content = (open $entry.name)
        
        print $"=== ($date) ==="
        print $content
        print ""
    }
}