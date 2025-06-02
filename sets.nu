# Nushell Set Operations Prelude
# 
# This module provides mathematical set operations using Nushell lists.
# All operations treat lists as sets (collections of unique elements).

# Convert a list to a set by removing duplicates and sorting
export def "set from-list" [] {
    $in | uniq | sort
}

# Check if a list represents a proper set (no duplicates)
export def "set is-set" [] {
    let input = $in
    ($input | length) == ($input | uniq | length)
}

# Check if a set is empty
export def "set is-empty" [] {
    ($in | uniq | length) == 0
}

# Union of two sets - elements that appear in either set
# Example: [1 2 3] | set union [3 4 5] => [1 2 3 4 5]
export def "set union" [other: list] {
    $in | append $other | set from-list
}

# Intersection of two sets - elements that appear in both sets
# Example: [1 2 3] | set intersection [2 3 4] => [2 3]
export def "set intersection" [other: list] {
    let first = $in | set from-list
    let second = $other | set from-list
    $first | where $it in $second
}

# Difference of two sets - elements in first set but not in second
# Example: [1 2 3] | set difference [2 3 4] => [1]
export def "set difference" [other: list] {
    let first = $in | set from-list
    let second = $other | set from-list
    $first | where $it not-in $second
}

# Symmetric difference - elements in either set but not in both
# Example: [1 2 3] | set symmetric-difference [2 3 4] => [1 4]
export def "set symmetric-difference" [other: list] {
    let first = $in | set from-list
    let second = $other | set from-list
    let left_diff = $first | where $it not-in $second
    let right_diff = $second | where $it not-in $first
    $left_diff | append $right_diff | set from-list
}

# Check if first set is a subset of second set
# Example: [1 2] | set is-subset [1 2 3 4] => true
export def "set is-subset" [superset: list] {
    let subset = $in | set from-list
    let superset = $superset | set from-list
    # Check if the intersection equals the subset
    let intersection = $subset | where $it in $superset
    ($intersection | length) == ($subset | length)
}

# Check if first set is a proper subset of second set (subset but not equal)
export def "set is-proper-subset" [superset: list] {
    let subset = $in
    ($subset | set is-subset $superset) and not ($subset | set equals $superset)
}

# Check if first set is a superset of second set
# Example: [1 2 3 4] | set is-superset [1 2] => true
export def "set is-superset" [subset: list] {
    let superset = $in
    $subset | set is-subset $superset
}

# Check if first set is a proper superset of second set
export def "set is-proper-superset" [subset: list] {
    let superset = $in
    ($superset | set is-superset $subset) and not ($superset | set equals $subset)
}

# Check if two sets are equal (contain the same elements)
# Example: [1 2 3] | set equals [3 1 2] => true
export def "set equals" [other: list] {
    let first = $in | set from-list
    let second = $other | set from-list
    ($first | length) == ($second | length) and ($first | all {|item| $item in $second})
}

# Check if two sets are disjoint (have no common elements)
# Example: [1 2] | set is-disjoint [3 4] => true
export def "set is-disjoint" [other: list] {
    ($in | set intersection $other | set is-empty)
}

# Cartesian product of two sets - all possible ordered pairs
# Example: [1 2] | set cartesian [a b] => [[1 a] [1 b] [2 a] [2 b]]
export def "set cartesian" [other: list] {
    let first = $in | set from-list
    let second = $other | set from-list
    $first | each {|x| 
        $second | each {|y| [$x $y]}
    } | flatten
}

# Power set - all possible subsets of a set
# Example: [1 2] | set powerset => [[] [1] [2] [1 2]]
export def "set powerset" [] {
    let elements = $in | set from-list
    let n = $elements | length
    
    if $n == 0 {
        return [[]]
    }
    
    0..<(2 ** $n) | each {|i|
        let subset = []
        $elements | enumerate | each {|item|
            if ($i | bits and (1 | bits shl $item.index)) != 0 {
                $subset | append $item.item
            } else {
                $subset
            }
        } | flatten
    }
}

# Get all k-element subsets (combinations) of a set
# Example: [1 2 3] | set combinations 2 => [[1 2] [1 3] [2 3]]
export def "set combinations" [k: int] {
    let elements = $in | set from-list
    let n = $elements | length
    
    if $k > $n or $k < 0 {
        return []
    }
    
    if $k == 0 {
        return [[]]
    }
    
    if $k == 1 {
        return ($elements | each {|x| [$x]})
    }
    
    # Recursive approach for combinations
    let result = []
    0..($n - $k) | each {|i|
        let first = $elements | get $i
        let rest = $elements | skip ($i + 1)
        $rest | set combinations ($k - 1) | each {|combo|
            [$first] | append $combo
        }
    } | flatten
}

# Partition a set into two sets based on a condition
# Returns a record with 'true' and 'false' keys
# Example: [1 2 3 4 5] | set partition {|x| $x mod 2 == 0} => {true: [2 4], false: [1 3 5]}
export def "set partition" [condition: closure] {
    let input = $in | set from-list
    {
        true: ($input | where (do $condition $it))
        false: ($input | where not (do $condition $it))
    }
}

# Multiple set union - union of multiple sets
# Example: [[1 2] [2 3] [3 4]] | set union-many => [1 2 3 4]
export def "set union-many" [] {
    $in | reduce -f [] {|set acc| $acc | set union $set}
}

# Multiple set intersection - intersection of multiple sets
# Example: [[1 2 3] [2 3 4] [2 3 5]] | set intersection-many => [2 3]
export def "set intersection-many" [] {
    let sets = $in
    if ($sets | is-empty) {
        return []
    }
    
    $sets | reduce {|set acc| $acc | set intersection $set}
}

# Validate that input is a proper set and return it, or error
export def "set validate" [] {
    let input = $in
    if not ($input | set is-set) {
        error make {
            msg: "Input contains duplicate elements and is not a proper set"
            label: {
                text: "Convert to set first using 'set from-list'"
                span: (metadata $input).span
            }
        }
    }
    $input | sort
} 