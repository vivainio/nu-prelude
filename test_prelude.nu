#!/usr/bin/env nu

# Test Suite for Nushell Set Operations Module
# Run with: nu test_prelude.nu

use mod.nu *

# Test framework helpers
def assert [condition: bool, message: string] {
    if not $condition {
        error make {
            msg: $"Test failed: ($message)"
        }
    }
    print $"✓ ($message)"
}

def assert_eq [actual: any, expected: any, message: string] {
    if $actual != $expected {
        error make {
            msg: $"Test failed: ($message)\n  Expected: ($expected)\n  Actual: ($actual)"
        }
    }
    print $"✓ ($message)"
}

def test_group [name: string, test_fn: closure] {
    print $"\n=== Testing ($name) ==="
    do $test_fn
}

# Basic Set Operations Tests
def test_basic_operations [] {
    # Test set from-list
    assert_eq ([1 2 2 3 1] | set from-list) [1 2 3] "from-list removes duplicates and sorts"
    assert_eq ([] | set from-list) [] "from-list handles empty list"
    assert_eq ([3 1 2] | set from-list) [1 2 3] "from-list sorts elements"
    
    # Test is-set
    assert ([1 2 3] | set is-set) "is-set returns true for proper set"
    assert (not ([1 2 2 3] | set is-set)) "is-set returns false for list with duplicates"
    assert ([] | set is-set) "is-set returns true for empty list"
    
    # Test is-empty
    assert ([] | set is-empty) "is-empty returns true for empty set"
    assert (not ([1] | set is-empty)) "is-empty returns false for non-empty set"
    let empty_check = [1 1 1] | set is-empty
    assert (not $empty_check) "is-empty works with duplicates"
    
    # Test validate
    assert_eq ([1 2 3] | set validate) [1 2 3] "validate passes proper sets"
}

# Set Theory Operations Tests
def test_set_theory_operations [] {
    # Test union
    assert_eq ([1 2 3] | set union [3 4 5]) [1 2 3 4 5] "union combines sets correctly"
    assert_eq ([1 2] | set union []) [1 2] "union with empty set"
    assert_eq ([] | set union [1 2]) [1 2] "empty set union with non-empty"
    assert_eq ([1 2] | set union [1 2]) [1 2] "union with identical sets"
    
    # Test intersection
    assert_eq ([1 2 3] | set intersection [2 3 4]) [2 3] "intersection finds common elements"
    assert_eq ([1 2] | set intersection [3 4]) [] "intersection of disjoint sets is empty"
    assert_eq ([1 2 3] | set intersection []) [] "intersection with empty set is empty"
    assert_eq ([1 2] | set intersection [1 2]) [1 2] "intersection with identical sets"
    
    # Test difference
    assert_eq ([1 2 3] | set difference [2 3 4]) [1] "difference removes elements in second set"
    assert_eq ([1 2] | set difference [3 4]) [1 2] "difference with disjoint sets"
    assert_eq ([1 2] | set difference []) [1 2] "difference with empty set"
    assert_eq ([1 2] | set difference [1 2]) [] "difference with identical sets is empty"
    
    # Test symmetric difference
    assert_eq ([1 2 3] | set symmetric-difference [2 3 4]) [1 4] "symmetric difference excludes common elements"
    assert_eq ([1 2] | set symmetric-difference [3 4]) [1 2 3 4] "symmetric difference of disjoint sets is union"
    assert_eq ([1 2] | set symmetric-difference []) [1 2] "symmetric difference with empty set"
    assert_eq ([1 2] | set symmetric-difference [1 2]) [] "symmetric difference with identical sets is empty"
}

# Set Relationship Tests
def test_set_relationships [] {
    # Test subset relationships
    assert ([1 2] | set is-subset [1 2 3 4]) "is-subset detects proper subset"
    assert ([1 2 3] | set is-subset [1 2 3]) "is-subset allows equal sets"
    assert (not ([1 2 5] | set is-subset [1 2 3 4])) "is-subset rejects non-subset"
    assert ([] | set is-subset [1 2 3]) "empty set is subset of any set"
    assert ([] | set is-subset []) "empty set is subset of itself"
    
    # Test proper subset
    assert ([1 2] | set is-proper-subset [1 2 3]) "is-proper-subset detects strict subset"
    assert (not ([1 2 3] | set is-proper-subset [1 2 3])) "is-proper-subset rejects equal sets"
    
    # Test superset relationships
    assert ([1 2 3 4] | set is-superset [1 2]) "is-superset detects proper superset"
    assert ([1 2 3] | set is-superset [1 2 3]) "is-superset allows equal sets"
    assert (not ([1 2] | set is-superset [1 2 3])) "is-superset rejects non-superset"
    
    # Test proper superset
    assert ([1 2 3] | set is-proper-superset [1 2]) "is-proper-superset detects strict superset"
    assert (not ([1 2 3] | set is-proper-superset [1 2 3])) "is-proper-superset rejects equal sets"
    
    # Test equality
    assert ([1 2 3] | set equals [3 1 2]) "equals detects equal sets regardless of order"
    assert ([1 2 3] | set equals [1 2 3]) "equals works with identical sets"
    assert (not ([1 2 3] | set equals [1 2])) "equals rejects different sized sets"
    assert ([] | set equals []) "equals works with empty sets"
    
    # Test disjoint
    assert ([1 2] | set is-disjoint [3 4]) "is-disjoint detects disjoint sets"
    assert (not ([1 2 3] | set is-disjoint [2 3 4])) "is-disjoint rejects overlapping sets"
    assert ([] | set is-disjoint [1 2]) "empty set is disjoint with any set"
    assert ([] | set is-disjoint []) "empty sets are disjoint"
}

# Advanced Operations Tests
def test_advanced_operations [] {
    # Test cartesian product
    let cart_result = [1 2] | set cartesian [a b]
    let expected_cart = [[1 a] [1 b] [2 a] [2 b]]
    assert_eq $cart_result $expected_cart "cartesian product generates all pairs"
    
    assert_eq ([1] | set cartesian [a]) [[1 a]] "cartesian product with single elements"
    assert_eq ([] | set cartesian [a b]) [] "cartesian product with empty first set"
    assert_eq ([1 2] | set cartesian []) [] "cartesian product with empty second set"
    
    # Test powerset
    let power_result = [1 2] | set powerset
    # PowerSet of {1,2} should be {{}, {1}, {2}, {1,2}}
    assert (($power_result | length) == 4) "powerset has correct number of subsets"
    assert ([] in $power_result) "powerset contains empty set"
    assert ([1] in $power_result) "powerset contains single element subsets"
    assert ([2] in $power_result) "powerset contains single element subsets"
    assert ([1 2] in $power_result) "powerset contains full set"
    
    assert_eq ([] | set powerset) [[]] "powerset of empty set is set containing empty set"
    
    # Test combinations
    let comb_result = [1 2 3] | set combinations 2
    let expected_comb = [[1 2] [1 3] [2 3]]
    assert_eq $comb_result $expected_comb "combinations generates correct k-subsets"
    
    assert_eq ([1 2 3] | set combinations 0) [[]] "combinations with k=0 returns empty set"
    assert_eq ([1 2 3] | set combinations 1) [[1] [2] [3]] "combinations with k=1 returns singletons"
    assert_eq ([1 2 3] | set combinations 4) [] "combinations with k>n returns empty"
    assert_eq ([1 2 3] | set combinations -1) [] "combinations with negative k returns empty"
}

# Advanced Set Operations Tests
def test_advanced_set_operations [] {
    # Test partition
    let part_result = [1 2 3 4 5] | set partition {|x| $x mod 2 == 0}
    let true_part = $part_result | get "true"
    let false_part = $part_result | get "false"
    assert_eq $true_part [2 4] "partition separates matching elements"
    assert_eq $false_part [1 3 5] "partition separates non-matching elements"
    
    let empty_part = [] | set partition {|x| $x > 0}
    let empty_true = $empty_part | get "true"
    let empty_false = $empty_part | get "false"
    assert_eq $empty_true [] "partition handles empty set - true part"
    assert_eq $empty_false [] "partition handles empty set - false part"
}

# Multi-set Operations Tests
def test_multi_set_operations [] {
    # Test union-many
    assert_eq ([[1 2] [2 3] [3 4]] | set union-many) [1 2 3 4] "union-many combines multiple sets"
    assert_eq ([[] [1 2] []] | set union-many) [1 2] "union-many handles empty sets"
    assert_eq ([] | set union-many) [] "union-many handles empty input"
    
    # Test intersection-many
    assert_eq ([[1 2 3] [2 3 4] [2 3 5]] | set intersection-many) [2 3] "intersection-many finds common elements"
    assert_eq ([[1 2] [3 4] [5 6]] | set intersection-many) [] "intersection-many of disjoint sets is empty"
    assert_eq ([] | set intersection-many) [] "intersection-many handles empty input"
}

# Edge Cases Tests
def test_edge_cases [] {
    # String sets
    assert_eq (["apple" "banana" "apple"] | set from-list) ["apple" "banana"] "works with strings"
    
    # Mixed type handling (where applicable)
    assert_eq ([1 "a" 2 "a"] | set from-list) [1 2 "a"] "handles mixed types"
    
    # Nested operations
    let complex_result = [1 2 3] | set union [4 5] | set intersection [2 3 4 5]
    assert_eq $complex_result [2 3 4 5] "chained operations work correctly"
}

# Main test runner
def main [] {
    print "🧪 Running Nushell Set Operations Test Suite"
    print "============================================="
    
    try {
        test_group "Basic Operations" { test_basic_operations }
        test_group "Set Theory Operations" { test_set_theory_operations }
        test_group "Set Relationships" { test_set_relationships }
        test_group "Advanced Operations" { test_advanced_operations }
        test_group "Advanced Set Operations" { test_advanced_set_operations }
        test_group "Multi-set Operations" { test_multi_set_operations }
        test_group "Edge Cases" { test_edge_cases }
        
        print "\n🎉 All tests passed! The set operations library is working correctly."
    } catch { |err|
        print $"\n❌ Test suite failed: ($err.msg)"
        exit 1
    }
}

# Run tests if this script is executed directly
main 