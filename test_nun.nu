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

# Test 3: Read (mocking by reading an existing file if any)
if not ($files | is-empty) {
    let first_file = ($files | first | get name)
    print $"\nTest 3: nun read ($first_file)"
    try {
        nun read $first_file
        print "Read successful"
    } catch {
        print "Read failed"
    }
}
