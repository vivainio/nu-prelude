use mod.nu *

print "Testing nun module..."

# Test 1: List files
print "\nTest 1: nun list"
let files = (nun list)
if ($files | is-empty) {
    print "Error: nun list returned empty list"
} else {
    print $"Found ($files | length) files"
    print ($files | first 5)
}

# Test 2: Search
print "\nTest 2: nun search"
let search_results = (nun search "test")
print $"Found ($search_results | length) matches for 'test'"
if not ($search_results | is-empty) {
    print ($search_results | first 5)
}

# Test 3: Create new note
print "\nTest 3: nun new"
let test_note = "test-note-" + (date now | format date "%Y%m%d%H%M%S")
try {
    nun new $test_note --content "# Test Note\n\nThis is a test note created by the test suite."
    print $"Created test note: ($test_note).md"
    
    # Verify it exists
    if (nun list | where name == ($test_note + ".md") | is-empty) {
        print "Error: Test note not found in list"
    } else {
        print "Test note verified in list"
    }
    
    # Clean up
    rm ([$env.NUN_VAULT_PATH?, "C:/r/vaults/ville"] | compact | first | path join ($test_note + ".md"))
    print "Test note cleaned up"
} catch {|e|
    print $"nun new failed: ($e)"
}

# Test 4: Read (using an existing file if any)
if not ($files | is-empty) {
    let first_file = ($files | first | get name)
    print $"\nTest 4: nun read ($first_file)"
    let content = (nun read $first_file)
    print "Read successful"
    print $"Content preview:\n($content | lines | first 3 | str join '\n')"
}
