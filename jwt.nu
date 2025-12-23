# JWT Utilities
#
# Functions for working with JSON Web Tokens (JWT).

# Add base64 padding if needed
def pad-base64 [] {
    let input = $in
    let padding = (4 - ($input | str length) mod 4) mod 4
    $input + ("" | fill -c "=" -w $padding)
}

# Decode a JWT and return its parts
# Returns a record with header, payload, and signature
# Example: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.sig" | decode jwt
export def "decode jwt" [] {
    let token = $in | str trim
    let parts = $token | split row "."

    if ($parts | length) != 3 {
        error make { msg: "Invalid JWT: expected 3 parts separated by dots" }
    }

    let payload = $parts.1 | pad-base64 | decode base64 --url | decode utf-8 | from json
    let time_fields = ["iat", "exp", "nbf", "auth_time"]
    let times = $payload
        | columns
        | where {|col| $col in $time_fields }
        | reduce -f {} {|col, acc| $acc | insert $col ($payload | get $col | $in * 1_000_000_000 | into datetime) }

    {
        header: ($parts.0 | pad-base64 | decode base64 --url | decode utf-8 | from json)
        payload: $payload
        signature: $parts.2
        _times: $times
    }
}
