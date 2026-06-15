# semver

[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) for Nushell — parse, validate, compare, sort, and bump versions as structured data.

## Why?

Sorting versions as strings goes wrong fast:
```nu
['1.10.0' '1.2.0' '1.2.0-rc.1'] | sort # => ['1.10.0' '1.2.0' '1.2.0-rc.1']
```

If you deal with semversions a lot you end up composing the same fragile regex over and over again. Reimplementing this is tedious.

```nu
['1.10.0' '1.2.0' '1.2.0-rc.1']
| each { semver decode }
| semver sort
| each { semver encode }
# => ['1.2.0-rc.1' '1.2.0' '1.10.0']
```

## Installation

```nu
# clone into one of your NU_LIB_DIRS
let dest = [($env.NU_LIB_DIRS | first) semver] | path join
git clone git@github.com:lassoColombo/semver.git $dest

# use the module
use semver
semver decode --help
```

## Quick start

```nu
use semver

# parse → record
'1.2.3-rc.1+exp.5114' | semver decode
# => { major: 1, minor: 2, patch: 3, prerelease: [rc 1], build: [exp 5114] }

# validate without throwing
'01.2.3' | semver is-valid                       # => false (leading zero)
'1.2.3+01' | semver is-valid                     # => true  (build allows it)

# round-trip
'1.2.3-rc.1' | semver decode | semver encode
# => '1.2.3-rc.1'

# compare two versions
let prerelease = ('1.0.0-alpha' | semver decode)
let release = ('1.0.0' | semver decode)
semver compare $prerelease $release
# => -1   (prerelease ranks below release)

# sort a list
['1.10.0' '1.2.0' '1.2.0-rc.1']
| each { semver decode }
| semver sort
| each { semver encode }
# => ['1.2.0-rc.1' '1.2.0' '1.10.0']

# bump
'1.2.3-rc.1+build' | semver decode | semver bump major | semver encode
# => '2.0.0'
```

## Record shape

`semver decode` produces, and `semver encode` consumes, the following shape:

```nu
{
  major:      int
  minor:      int
  patch:      int
  prerelease: list<string>   # dot-separated identifiers; [] when none
  build:      list<string>   # dot-separated identifiers; [] when none
}
```

`'<x>' | semver decode | semver encode` is a fixed point for any spec-valid input.

## Commands

| Command | Signature | Description |
|---------|-----------|-------------|
| `semver decode` | `string -> record` / `list<string> -> list<record>` | Parse a semver string (errors on invalid input). Broadcasts over lists. |
| `semver is-valid` | `string -> bool` | True when the string conforms to the spec BNF. Non-throwing alternative to `decode`. |
| `semver encode` | `record -> string` / `list<record> -> list<string>` | Render a record back to canonical string form. Inverse of `decode`. |
| `semver compare` | `record record -> int` | Returns `-1`, `0`, or `1` per spec rule 11. Build metadata is ignored (rule 10). |
| `semver sort` | `list<record> -> list<record>` | Sort by precedence. Pass `--reverse` for descending. |
| `semver bump major` | `record -> record` | Increment major; reset minor/patch to `0`; clear prerelease and build. |
| `semver bump minor` | `record -> record` | Increment minor; reset patch to `0`; clear prerelease and build. |
| `semver bump patch` | `record -> record` | Increment patch; clear prerelease and build. |

## Spec compliance

Parsing uses the official [SemVer 2.0.0 BNF regex](https://semver.org/spec/v2.0.0.html).
