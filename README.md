# semver

[Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) for Nushell — parse, validate, compare, sort, and bump versions as structured data.

## Why?

Sorting versions as strings goes wrong fast:

```nu
['1.10.0' '1.2.0' '1.2.0-rc.1'] | sort
# => ['1.10.0' '1.2.0' '1.2.0-rc.1']   # wrong: 1.10.0 first, prerelease last
```

Spec rule 11 says `1.2.0-rc.1 < 1.2.0 < 1.10.0`. To get that, every consumer ends up writing the same regex and the same dot-wise comparator. This module does it once.

```nu
['1.10.0' '1.2.0' '1.2.0-rc.1']
| each { semver to record }
| semver sort
| each { semver to string }
# => ['1.2.0-rc.1' '1.2.0' '1.10.0']
```

## Installation

```nu
# clone into one of your NU_LIB_DIRS
let dest = [($env.NU_LIB_DIRS | first) semver] | path join
git clone git@github.com:lassoColombo/semver.git $dest

# use the module
use semver
semver to record --help
```

## Quick start

```nu
use semver

# parse → record
'1.2.3-rc.1+exp.5114' | semver to record
# => { major: 1, minor: 2, patch: 3, prerelease: [rc 1], build: [exp 5114] }

# validate without throwing
'01.2.3' | semver is-valid                       # => false (leading zero)
'1.2.3+01' | semver is-valid                     # => true  (build allows it)

# round-trip
'1.2.3-rc.1' | semver to record | semver to string
# => '1.2.3-rc.1'

# compare two versions
semver compare ('1.0.0-alpha' | semver to record) ('1.0.0' | semver to record)
# => -1   (prerelease ranks below release)

# sort a list
['1.10.0' '1.2.0' '1.2.0-rc.1']
| each { semver to record }
| semver sort
| each { semver to string }
# => ['1.2.0-rc.1' '1.2.0' '1.10.0']

# bump
'1.2.3-rc.1+build' | semver to record | semver bump major | semver to string
# => '2.0.0'
```

## Record shape

`semver to record` produces, and `semver to string` consumes, the following shape:

```nu
{
  major:      int
  minor:      int
  patch:      int
  prerelease: list<string>   # dot-separated identifiers; [] when none
  build:      list<string>   # dot-separated identifiers; [] when none
}
```

`'<x>' | semver to record | semver to string` is a fixed point for any spec-valid input.

## Commands

| Command | Signature | Description |
|---------|-----------|-------------|
| `semver to record` | `string -> record` / `list<string> -> list<record>` | Parse a semver string (errors on invalid input). Broadcasts over lists. |
| `semver is-valid` | `string -> bool` | True when the string conforms to the spec BNF. Non-throwing alternative to `to record`. |
| `semver to string` | `record -> string` / `list<record> -> list<string>` | Render a record back to canonical string form. Inverse of `to record`. |
| `semver compare` | `record record -> int` | Returns `-1`, `0`, or `1` per spec rule 11. Build metadata is ignored (rule 10). |
| `semver sort` | `list<record> -> list<record>` | Sort by precedence. Pass `--reverse` for descending. |
| `semver bump major` | `record -> record` | Increment major; reset minor/patch to `0`; clear prerelease and build. |
| `semver bump minor` | `record -> record` | Increment minor; reset patch to `0`; clear prerelease and build. |
| `semver bump patch` | `record -> record` | Increment patch; clear prerelease and build. |

## Spec compliance

Parsing uses the official [SemVer 2.0.0 BNF regex](https://semver.org/spec/v2.0.0.html) with named captures, so every rule in the spec is enforced:

- No leading zeros on numeric identifiers (rules 2, 9) — `01.2.3` is rejected
- Build metadata identifiers may have leading zeros (rule 10) — `1.2.3+01` is accepted
- Prerelease identifiers are ASCII alphanumerics + `-`, non-empty
- Comparison follows rule 11 in full: numeric core first, then dot-wise prerelease comparison with numeric identifiers ranking below alphanumeric ones; a release outranks any of its prereleases; build metadata never participates in precedence

## Naming notes

- `to record` rather than `parse` — `parse` would shadow the built-in `parse --regex` the module relies on internally.
- `bump` subcommands always clear prerelease and build metadata. This is the conventional reading of rule 6 and matches every other semver library; if you need to keep a build tag through a bump, construct the record manually.
