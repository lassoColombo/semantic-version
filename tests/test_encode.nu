use std/assert
use std/testing *
use ../mod.nu *

@test
def "encode core only" [] {
    let s = { major: 1, minor: 2, patch: 3, prerelease: [], build: [] } | encode
    assert equal $s '1.2.3'
}

@test
def "encode all-zero version" [] {
    let s = { major: 0, minor: 0, patch: 0, prerelease: [], build: [] } | encode
    assert equal $s '0.0.0'
}

@test
def "encode prerelease only" [] {
    let s = { major: 1, minor: 2, patch: 3, prerelease: ['rc' '1'], build: [] } | encode
    assert equal $s '1.2.3-rc.1'
}

@test
def "encode build only" [] {
    let s = { major: 1, minor: 2, patch: 3, prerelease: [], build: ['exp' '5114'] } | encode
    assert equal $s '1.2.3+exp.5114'
}

@test
def "encode prerelease and build" [] {
    let s = { major: 1, minor: 2, patch: 3, prerelease: ['rc' '1'], build: ['exp' '5114'] } | encode
    assert equal $s '1.2.3-rc.1+exp.5114'
}

@test
def "encode broadcasts over list" [] {
    let s = [
        { major: 1, minor: 0, patch: 0, prerelease: [], build: [] }
        { major: 2, minor: 0, patch: 0, prerelease: ['rc' '1'], build: [] }
    ] | encode
    assert equal $s ['1.0.0' '2.0.0-rc.1']
}

@test
def "encode on empty list returns empty list" [] {
    assert equal ([] | encode) []
}

@test
def "encode raises a descriptive error on a malformed record" [] {
    assert error {|| { major: 1, minor: 2 } | encode }
}

@test
def "encode is the inverse of decode for a wide range of valid versions" [] {
    let versions = [
        '0.0.0'
        '1.2.3'
        '10.20.30'
        '1.0.0-alpha'
        '1.0.0-alpha.1'
        '1.0.0-0'
        '1.0.0-0A.is.legal'
        '1.0.0--rc.1'
        '1.2.3+build.1'
        '1.2.3+01.02'
        '1.2.3-rc.1+exp.5114'
        '1.0.0+0.build.1-rc.10000aaa-kk-0.1'
    ]
    assert equal ($versions | decode | encode) $versions
}

@test
def "encode rejects a number field of the wrong type or sign" [] {
    assert error {|| { major: 'x', minor: 0, patch: 0, prerelease: [], build: [] } | encode }
    assert error {|| { major: -1, minor: 0, patch: 0, prerelease: [], build: [] } | encode }
    assert error {|| { major: 1, minor: 2.5, patch: 0, prerelease: [], build: [] } | encode }
}

@test
def "encode rejects prerelease/build that are not lists of strings" [] {
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: 'rc', build: [] } | encode }
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: [rc 1], build: [] } | encode }
}

@test
def "encode rejects identifiers that violate the spec" [] {
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: ['has space'], build: [] } | encode }
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: [''], build: [] } | encode }
    # numeric pre-release identifier with a leading zero (spec rule 9)
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: ['01'], build: [] } | encode }
    # illegal character in a build identifier
    assert error {|| { major: 1, minor: 0, patch: 0, prerelease: [], build: ['a+b'] } | encode }
}

@test
def "encode allows leading zeros in build identifiers per spec rule 10" [] {
    let s = { major: 1, minor: 2, patch: 3, prerelease: [], build: ['01' '02'] } | encode
    assert equal $s '1.2.3+01.02'
}

@test
def "encode error message names the offending field" [] {
    let msg = try { { major: 'x', minor: 0, patch: 0, prerelease: [], build: [] } | encode } catch {|e| $e.msg }
    assert ($msg | str contains 'major')
    assert ($msg | str contains 'non-negative int')
}

@test
def "encode broadcasts over the table that decode yields" [] {
    # `decode` over a list produces a table (stream), not a `list<record>`.
    # encode must broadcast over it exactly like a plain list — this guards
    # the shared dispatch helper's table handling.
    let versions = ['1.0.0' '2.0.0-rc.1' '1.5.3+build.7']
    let decoded = $versions | decode
    assert equal (($decoded | describe --detailed).type) 'list'
    assert equal ($decoded | encode) $versions
}
