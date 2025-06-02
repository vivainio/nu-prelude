# Nushell Set Operations Module

A comprehensive mathematical set operations library for Nushell that provides core set theory functions using Nushell lists.

## Overview

This module treats Nushell lists as mathematical sets (collections of unique elements) and provides:
- **Core set operations** (union, intersection, difference, symmetric difference)
- **Set relationship testing** (subset, superset, equality, disjoint)
- **Advanced mathematical operations** (cartesian product, power set, combinations)
- **Multi-set operations** (union-many, intersection-many)
- **Set validation and partitioning**

> **Note:** This module was vibe coded with Cursor.

## Installation

1. Save both `sets.nu` and `mod.nu` files to your Nushell modules directory
2. Add to your Nushell config file (`$nu.config-path`):

```nushell
use mod.nu *
```

3. Restart Nushell or run:

```nushell
source mod.nu
```

## Quick Start

```nushell
# Create sets from lists
[1 2 3 2 1] | set from-list        # => [1 2 3]

# Basic set operations
[1 2 3] | set union [3 4 5]        # => [1 2 3 4 5]
[1 2 3] | set intersection [2 3 4] # => [2 3]
[1 2 3] | set difference [2 3 4]   # => [1]

# Test relationships
[1 2] | set is-subset [1 2 3 4]    # => true
[1 2 3] | set equals [3 1 2]       # => true
```

## Function Reference

### Basic Set Operations

#### `set from-list`
Converts a list to a set by removing duplicates and sorting.

```nushell
[3 1 2 1 3] | set from-list
# => [1 2 3]
```

#### `set is-set`
Checks if a list represents a proper set (no duplicates).

```nushell
[1 2 3] | set is-set     # => true
[1 2 2 3] | set is-set   # => false
```

#### `set is-empty`
Checks if a set is empty.

```nushell
[] | set is-empty        # => true
[1] | set is-empty       # => false
```

#### `set validate`
Validates that input is a proper set and returns it sorted, or throws an error.

```nushell
[1 2 3] | set validate   # => [1 2 3]
[1 2 2] | set validate   # Error: Input contains duplicate elements
```

### Set Theory Operations

#### `set union [other: list]`
Returns elements that appear in either set.

```nushell
[1 2 3] | set union [3 4 5]
# => [1 2 3 4 5]
```

#### `set intersection [other: list]`
Returns elements that appear in both sets.

```nushell
[1 2 3] | set intersection [2 3 4]
# => [2 3]
```

#### `set difference [other: list]`
Returns elements in the first set but not in the second.

```nushell
[1 2 3] | set difference [2 3 4]
# => [1]
```

#### `set symmetric-difference [other: list]`
Returns elements in either set but not in both.

```nushell
[1 2 3] | set symmetric-difference [2 3 4]
# => [1 4]
```

### Set Relationships

#### `set is-subset [superset: list]`
Checks if the first set is a subset of the second.

```nushell
[1 2] | set is-subset [1 2 3 4]     # => true
[1 5] | set is-subset [1 2 3 4]     # => false
```

#### `set is-proper-subset [superset: list]`
Checks if the first set is a proper subset (subset but not equal).

```nushell
[1 2] | set is-proper-subset [1 2 3 4]  # => true
[1 2 3] | set is-proper-subset [1 2 3]  # => false
```

#### `set is-superset [subset: list]`
Checks if the first set is a superset of the second.

```nushell
[1 2 3 4] | set is-superset [1 2]   # => true
```

#### `set is-proper-superset [subset: list]`
Checks if the first set is a proper superset.

```nushell
[1 2 3 4] | set is-proper-superset [1 2]  # => true
[1 2 3] | set is-proper-superset [1 2 3]  # => false
```

#### `set equals [other: list]`
Checks if two sets contain the same elements.

```nushell
[1 2 3] | set equals [3 1 2]        # => true
[1 2 3] | set equals [1 2 4]        # => false
```

#### `set is-disjoint [other: list]`
Checks if two sets have no common elements.

```nushell
[1 2] | set is-disjoint [3 4]       # => true
[1 2] | set is-disjoint [2 3]       # => false
```

### Advanced Mathematical Operations

#### `set cartesian [other: list]`
Returns the Cartesian product of two sets (all possible ordered pairs).

```nushell
[1 2] | set cartesian [a b]
# => [[1 a] [1 b] [2 a] [2 b]]
```

#### `set powerset`
Returns all possible subsets of a set.

```nushell
[1 2] | set powerset
# => [[] [1] [2] [1 2]]
```

#### `set combinations [k: int]`
Returns all k-element subsets of a set.

```nushell
[1 2 3] | set combinations 2
# => [[1 2] [1 3] [2 3]]
```

### Advanced Set Operations

#### `set partition [condition: closure]`
Partitions a set into two sets based on a condition.

```nushell
[1 2 3 4 5] | set partition {|x| $x mod 2 == 0}
# => {true: [2 4], false: [1 3 5]}
```

#### `set union-many`
Union of multiple sets.

```nushell
[[1 2] [2 3] [3 4]] | set union-many
# => [1 2 3 4]
```

#### `set intersection-many`
Intersection of multiple sets.

```nushell
[[1 2 3] [2 3 4] [2 3 5]] | set intersection-many
# => [2 3]
```

## Usage Examples

### Working with Data

```nushell
# Find unique values across multiple columns
let data = [
    {name: "Alice", skills: [python, rust]}
    {name: "Bob", skills: [javascript, python]}
    {name: "Carol", skills: [rust, go]}
]

$data | get skills | flatten | set from-list
# => [go javascript python rust]
```

### Set Analysis

```nushell
# Analyze survey responses
let group_a = [python rust go]
let group_b = [javascript python java]

# What languages are popular in both groups?
$group_a | set intersection $group_b
# => [python]

# What's unique to each group?
{
    only_a: ($group_a | set difference $group_b)
    only_b: ($group_b | set difference $group_a)
    both: ($group_a | set intersection $group_b)
}
```

### Mathematical Applications

```nushell
# Generate all possible pairs from two groups
let teams = [red blue]
let positions = [forward defense]

$teams | set cartesian $positions
# => [[red forward] [red defense] [blue forward] [blue defense]]
```

### Set Partitioning

```nushell
# Partition numbers by even/odd
[1 2 3 4 5 6] | set partition {|x| $x mod 2 == 0}
# => {true: [2 4 6], false: [1 3 5]}

# Complex partitioning
let words = [apple banana cherry date elderberry]
$words | set partition {|w| ($w | str length) > 5}
# => {true: [banana cherry elderberry], false: [apple date]}
```

## Performance Notes

- All functions automatically handle duplicate removal and sorting
- Large sets (>1000 elements) may benefit from pre-sorting input
- Cartesian products and power sets grow exponentially - use with caution on large sets
- The `combinations` function uses recursion and may be slow for large sets with high k values

## Module Structure

- `sets.nu` - Core set operations implementation
- `mod.nu` - Module entry point that exports all functions
- `test_prelude.nu` - Comprehensive test suite

## Removed Functions

For better focus on core set theory, trivial wrapper functions have been removed. Use native Nushell commands instead:

- **Statistics**: Use `math min`, `math max`, `math sum`, `math avg` directly
- **Functional**: Use `where`, `each`, `reduce`, `any`, `all`, `group-by` directly  
- **Utilities**: Use `columns`, `values`, `flatten`, `shuffle | take` directly
- **Size**: Use `uniq | length` directly

## Contributing

This library follows mathematical set theory principles. When contributing:

1. Ensure all functions handle edge cases (empty sets, single elements)
2. Maintain consistent input/output formats
3. Include comprehensive examples in documentation
4. Follow Nushell naming conventions
5. Focus on operations that provide clear set theory value

## License

MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 