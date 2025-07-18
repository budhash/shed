#!/usr/bin/env bash
##( header
#
# Test Suite for sem-ver
#
# Comprehensive tests for semantic version bumping and comparison
##) header

##( configuration
set -euo pipefail
##) configuration

##( setup
# Source the common test framework
source ../.common/test-common

# Use shorter variable names
NAME="sem-ver"
TOOL="./sem-ver"
##) setup

##( tests
test_bump_standard() {
  _section_header "Bump - Standard Version Bumps"
  
  # Workflow 1: Standard Bumps (Final Release -> Next Final Release)
  assert_eq "1.2.4" "$($TOOL bump -b patch 1.2.3)" "patch bump [1.2.3 : bump -b patch -> 1.2.4]"
  assert_eq "1.3.0" "$($TOOL bump -b minor 1.2.3)" "minor bump [1.2.3 : bump -b minor -> 1.3.0]"
  assert_eq "2.0.0" "$($TOOL bump -b major 1.2.3)" "major bump [1.2.3 : bump -b major -> 2.0.0]"
  
  # Test shorthand syntax
  assert_eq "1.2.4" "$($TOOL patch 1.2.3)" "patch bump shorthand [1.2.3 : patch -> 1.2.4]"
  assert_eq "1.3.0" "$($TOOL minor 1.2.3)" "minor bump shorthand [1.2.3 : minor -> 1.3.0]"
  assert_eq "2.0.0" "$($TOOL major 1.2.3)" "major bump shorthand [1.2.3 : major -> 2.0.0]"
  
  # Test with larger version numbers
  assert_eq "10.0.0" "$($TOOL major 9.99.99)" "major bump large version [9.99.99 : major -> 10.0.0]"
  assert_eq "9.100.0" "$($TOOL minor 9.99.99)" "minor bump large version [9.99.99 : minor -> 9.100.0]"
  assert_eq "9.99.100" "$($TOOL patch 9.99.99)" "patch bump large version [9.99.99 : patch -> 9.99.100]"
  
  # Test with zero versions
  assert_eq "0.0.1" "$($TOOL patch 0.0.0)" "patch from zero [0.0.0 : patch -> 0.0.1]"
  assert_eq "0.1.0" "$($TOOL minor 0.0.0)" "minor from zero [0.0.0 : minor -> 0.1.0]"
  assert_eq "1.0.0" "$($TOOL major 0.0.0)" "major from zero [0.0.0 : major -> 1.0.0]"
  
  echo
}

test_bump_prerelease() {
  _section_header "Bump - Pre-release Workflows"
  
  # Workflow 2: Starting a New Pre-release Cycle
  assert_eq "1.2.4-alpha.1" "$($TOOL bump -b patch -p alpha.1 1.2.3)" "start patch pre-release [1.2.3 : bump -b patch -p alpha.1 -> 1.2.4-alpha.1]"
  assert_eq "1.3.0-alpha.1" "$($TOOL bump -b minor -p alpha.1 1.2.3)" "start minor pre-release [1.2.3 : bump -b minor -p alpha.1 -> 1.3.0-alpha.1]"
  assert_eq "2.0.0-alpha.1" "$($TOOL bump -b major -p alpha.1 1.2.3)" "start major pre-release [1.2.3 : bump -b major -p alpha.1 -> 2.0.0-alpha.1]"
  
  # Test shorthand with pre-release
  assert_eq "1.2.4-beta.1" "$($TOOL patch -p beta.1 1.2.3)" "shorthand patch with pre-release [1.2.3 : patch -p beta.1 -> 1.2.4-beta.1]"
  assert_eq "1.3.0-rc.1" "$($TOOL minor -p rc.1 1.2.3)" "shorthand minor with pre-release [1.2.3 : minor -p rc.1 -> 1.3.0-rc.1]"
  assert_eq "2.0.0-dev.1" "$($TOOL major -p dev.1 1.2.3)" "shorthand major with pre-release [1.2.3 : major -p dev.1 -> 2.0.0-dev.1]"
  
  # Workflow 3: Iterating on an Existing Pre-release
  assert_eq "2.0.0-alpha.2" "$($TOOL bump -b pre -p alpha.2 2.0.0-alpha.1)" "iterate pre-release [2.0.0-alpha.1 : bump -b pre -p alpha.2 -> 2.0.0-alpha.2]"
  assert_eq "2.0.0-beta.1" "$($TOOL bump -b pre -p beta.1 2.0.0-alpha.2)" "change pre-release type [2.0.0-alpha.2 : bump -b pre -p beta.1 -> 2.0.0-beta.1]"
  assert_eq "2.0.0-rc.1" "$($TOOL pre -p rc.1 2.0.0-beta.2)" "shorthand pre-release [2.0.0-beta.2 : pre -p rc.1 -> 2.0.0-rc.1]"
  
  # Workflow 4: Finalizing a Pre-release
  assert_eq "2.0.0" "$($TOOL bump -b patch 2.0.0-beta.1)" "finalize with patch bump [2.0.0-beta.1 : bump -b patch -> 2.0.0]"
  assert_eq "2.0.0" "$($TOOL bump -b minor 2.0.0-beta.1)" "finalize with minor bump [2.0.0-beta.1 : bump -b minor -> 2.0.0]"  
  assert_eq "2.0.0" "$($TOOL bump -b major 2.0.0-beta.1)" "finalize with major bump [2.0.0-beta.1 : bump -b major -> 2.0.0]"
  assert_eq "2.0.0" "$($TOOL patch 2.0.0-rc.1)" "finalize with shorthand [2.0.0-rc.1 : patch -> 2.0.0]"
  
  echo
}

test_bump_complex() {
  _section_header "Bump - Complex Pre-release Scenarios"
  
  # Complex pre-release identifiers
  assert_eq "1.0.0-alpha.1.2.3" "$($TOOL pre -p alpha.1.2.3 1.0.0-alpha.1.2.2)" "multi-dot pre-release [1.0.0-alpha.1.2.2 : pre -p alpha.1.2.3 -> 1.0.0-alpha.1.2.3]"
  assert_eq "1.0.0-0.3.7" "$($TOOL pre -p 0.3.7 1.0.0-0.3.6)" "numeric pre-release [1.0.0-0.3.6 : pre -p 0.3.7 -> 1.0.0-0.3.7]"
  assert_eq "1.0.0-x.7.z.92" "$($TOOL pre -p x.7.z.92 1.0.0-x.7.z.91)" "mixed pre-release [1.0.0-x.7.z.91 : pre -p x.7.z.92 -> 1.0.0-x.7.z.92]"
  
  # Pre-release with build metadata (should preserve core version logic)
  assert_eq "1.2.4-alpha.1" "$($TOOL patch -p alpha.1 1.2.3+build.1)" "bump with build metadata [1.2.3+build.1 : patch -p alpha.1 -> 1.2.4-alpha.1]"
  assert_eq "1.3.0-beta.1" "$($TOOL minor -p beta.1 1.2.3+build.123)" "minor bump with build metadata [1.2.3+build.123 : minor -p beta.1 -> 1.3.0-beta.1]"
  
  # Single character and special pre-release identifiers
  assert_eq "1.0.0-a" "$($TOOL pre -p a 1.0.0-z)" "single char pre-release [1.0.0-z : pre -p a -> 1.0.0-a]"
  assert_eq "1.0.0-123" "$($TOOL pre -p 123 1.0.0-122)" "numeric only pre-release [1.0.0-122 : pre -p 123 -> 1.0.0-123]"
  assert_eq "1.0.0-alpha-beta" "$($TOOL pre -p alpha-beta 1.0.0-alpha)" "hyphenated pre-release [1.0.0-alpha : pre -p alpha-beta -> 1.0.0-alpha-beta]"
  
  echo
}

test_compare_basic() {
  _section_header "Compare - Basic Version Comparisons"
  
  # Core version comparisons
  assert_ok $TOOL compare -c gt 2.0.0 1.9.9 "major version greater [2.0.0 : compare -c gt : 1.9.9 -> true]"
  assert_ok $TOOL compare -c gt 1.3.0 1.2.9 "minor version greater [1.3.0 : compare -c gt : 1.2.9 -> true]"
  assert_ok $TOOL compare -c gt 1.2.4 1.2.3 "patch version greater [1.2.4 : compare -c gt : 1.2.3 -> true]"
  assert_ok $TOOL compare -c eq 1.2.3 1.2.3 "versions equal [1.2.3 : compare -c eq : 1.2.3 -> true]"
  assert_ok $TOOL compare -c lt 1.2.3 1.2.4 "patch version less [1.2.3 : compare -c lt : 1.2.4 -> true]"
  
  # Test shorthand comparison operators
  assert_ok $TOOL gt 2.0.0 1.9.9 "shorthand gt operator [2.0.0 : gt : 1.9.9 -> true]"
  assert_ok $TOOL lt 1.2.3 1.2.4 "shorthand lt operator [1.2.3 : lt : 1.2.4 -> true]"
  assert_ok $TOOL eq 1.2.3 1.2.3 "shorthand eq operator [1.2.3 : eq : 1.2.3 -> true]"
  
  # Version prefix handling
  assert_ok $TOOL eq v1.2.3 1.2.3 "v-prefix handling [v1.2.3 : eq : 1.2.3 -> true]"
  assert_ok $TOOL eq 1.2.3 v1.2.3 "v-prefix handling reverse [1.2.3 : eq : v1.2.3 -> true]"
  assert_ok $TOOL eq v1.2.3 v1.2.3 "both with v-prefix [v1.2.3 : eq : v1.2.3 -> true]"
  
  # Comparison failure cases
  assert_fail $TOOL gt 1.2.3 2.0.0 "gt comparison fails [1.2.3 : gt : 2.0.0 -> false]"
  assert_fail $TOOL lt 2.0.0 1.2.3 "lt comparison fails [2.0.0 : lt : 1.2.3 -> false]"
  assert_fail $TOOL eq 1.2.3 1.2.4 "eq comparison fails [1.2.3 : eq : 1.2.4 -> false]"
  
  echo
}

test_compare_prerelease() {
  _section_header "Compare - Pre-release Precedence (SemVer Rule #11)"
  
  # Final release vs pre-release
  assert_ok $TOOL gt 1.0.0 1.0.0-alpha "final > pre-release [1.0.0 : gt : 1.0.0-alpha -> true]"
  assert_ok $TOOL lt 1.0.0-alpha 1.0.0 "pre-release < final [1.0.0-alpha : lt : 1.0.0 -> true]"
  assert_ok $TOOL gt 2.0.0 1.9.9-rc.1 "final major > pre-release [2.0.0 : gt : 1.9.9-rc.1 -> true]"
  
  # Numeric vs string identifiers
  assert_ok $TOOL gt 1.0.0-rc.11 1.0.0-rc.2 "numeric pre-release comparison [1.0.0-rc.11 : gt : 1.0.0-rc.2 -> true]"
  assert_ok $TOOL gt 1.0.0-beta 1.0.0-alpha "string pre-release comparison [1.0.0-beta : gt : 1.0.0-alpha -> true]"
  assert_ok $TOOL gt 1.0.0-beta 1.0.0-11 "string > numeric in pre-release [1.0.0-beta : gt : 1.0.0-11 -> true]"
  assert_ok $TOOL lt 1.0.0-1 1.0.0-alpha "numeric < string in pre-release [1.0.0-1 : lt : 1.0.0-alpha -> true]"
  
  # Length-based precedence
  assert_ok $TOOL gt 1.0.0-alpha.1 1.0.0-alpha "longer pre-release > shorter [1.0.0-alpha.1 : gt : 1.0.0-alpha -> true]"
  assert_ok $TOOL gt 1.0.0-alpha.beta 1.0.0-alpha "longer pre-release > shorter (string) [1.0.0-alpha.beta : gt : 1.0.0-alpha -> true]"
  assert_ok $TOOL gt 1.0.0-1.2.3.4 1.0.0-1.2.3 "longer numeric pre-release [1.0.0-1.2.3.4 : gt : 1.0.0-1.2.3 -> true]"
  
  # Complex precedence scenarios
  assert_ok $TOOL gt 1.0.0-rc.1 1.0.0-beta.11 "rc > beta regardless of numbers [1.0.0-rc.1 : gt : 1.0.0-beta.11 -> true]"
  assert_ok $TOOL gt 1.0.0-1.2.3 1.0.0-1.2 "longer numeric pre-release [1.0.0-1.2.3 : gt : 1.0.0-1.2 -> true]"
  assert_ok $TOOL lt 1.0.0-1.alpha 1.0.0-1.beta "mixed numeric-string precedence [1.0.0-1.alpha : lt : 1.0.0-1.beta -> true]"
  
  # Equal pre-release scenarios
  assert_ok $TOOL eq 1.0.0-alpha.1 1.0.0-alpha.1 "identical pre-releases [1.0.0-alpha.1 : eq : 1.0.0-alpha.1 -> true]"
  assert_fail $TOOL eq 1.0.0-alpha.1 1.0.0-alpha.2 "different pre-release numbers [1.0.0-alpha.1 : eq : 1.0.0-alpha.2 -> false]"
  
  echo
}

test_compare_build_metadata() {
  _section_header "Compare - Build Metadata Handling (SemVer Rule #10)"
  
  # Build metadata should be ignored in comparisons
  assert_ok $TOOL eq 1.2.3+build.1 1.2.3+build.2 "build metadata ignored [1.2.3+build.1 : eq : 1.2.3+build.2 -> true]"
  assert_ok $TOOL eq 1.2.3 1.2.3+build.1 "build metadata ignored with clean [1.2.3 : eq : 1.2.3+build.1 -> true]"
  assert_ok $TOOL eq 1.2.3+20130313144700 1.2.3+exp.sha.5114f85 "different build metadata ignored [1.2.3+20130313144700 : eq : 1.2.3+exp.sha.5114f85 -> true]"
  
  # Pre-release with build metadata
  assert_ok $TOOL eq 1.2.3-alpha+1 1.2.3-alpha+2 "pre-release with different build metadata [1.2.3-alpha+1 : eq : 1.2.3-alpha+2 -> true]"
  assert_ok $TOOL gt 1.2.3-beta+build 1.2.3-alpha+build "pre-release precedence with build [1.2.3-beta+build : gt : 1.2.3-alpha+build -> true]"
  
  # Complex build metadata
  assert_ok $TOOL eq 1.2.3+build.1.2.3 1.2.3+build.4.5.6 "complex build metadata ignored [1.2.3+build.1.2.3 : eq : 1.2.3+build.4.5.6 -> true]"
  
  echo
}

test_validate_basic() {
  _section_header "Validate - Version Format Validation"
  
  # Valid versions
  assert_ok $TOOL validate 1.2.3 "basic version valid [1.2.3 : validate -> valid]"
  assert_ok $TOOL validate 1.2.3-alpha "pre-release valid [1.2.3-alpha : validate -> valid]"  
  assert_ok $TOOL validate 1.2.3-alpha.1 "pre-release with number valid [1.2.3-alpha.1 : validate -> valid]"
  assert_ok $TOOL validate 1.2.3+build.1 "build metadata valid [1.2.3+build.1 : validate -> valid]"
  assert_ok $TOOL validate 1.2.3-alpha.1+build.1 "pre-release with build valid [1.2.3-alpha.1+build.1 : validate -> valid]"
  assert_ok $TOOL validate v1.2.3 "v-prefix valid [v1.2.3 : validate -> valid]"
  assert_ok $TOOL validate 0.0.0 "zero version valid [0.0.0 : validate -> valid]"
  assert_ok $TOOL validate 10.20.30 "large numbers valid [10.20.30 : validate -> valid]"
  assert_ok $TOOL validate 1.0.0-0.3.7 "numeric pre-release valid [1.0.0-0.3.7 : validate -> valid]"
  assert_ok $TOOL validate 1.0.0-x.7.z.92 "complex pre-release valid [1.0.0-x.7.z.92 : validate -> valid]"
  
  # Invalid versions - should provide specific error messages
  assert_fail $TOOL validate 1.2 "incomplete version invalid [1.2 : validate -> invalid (missing patch)]"
  assert_fail $TOOL validate 1.2.3.4 "too many parts invalid [1.2.3.4 : validate -> invalid (too many parts)]"
  assert_fail $TOOL validate 1.2.x "non-numeric part invalid [1.2.x : validate -> invalid (non-numeric)]"
  assert_fail $TOOL validate 1.2.3- "trailing dash invalid [1.2.3- : validate -> invalid (trailing dash)]"
  assert_fail $TOOL validate 1.2.3+ "empty build metadata invalid [1.2.3+ : validate -> invalid (empty build metadata)]"
  assert_fail $TOOL validate "" "empty version invalid ['' : validate -> invalid (empty)]"
  assert_fail $TOOL validate "not.a.version" "completely invalid [not.a.version : validate -> invalid (format)]"
  assert_fail $TOOL validate "1" "single number invalid [1 : validate -> invalid (incomplete)]"
  assert_fail $TOOL validate "v" "v-only invalid [v : validate -> invalid (empty after v)]"
  assert_fail $TOOL validate "1.2.3-" "empty pre-release invalid [1.2.3- : validate -> invalid (empty pre-release)]"
  
  echo
}

test_parse_basic() {
  _section_header "Parse - Version Component Parsing"
  
  # Test that parse command works and produces expected output
  local parse_output
  parse_output=$($TOOL parse 1.2.3-alpha.1+build.123 2>&1)
  assert_contains "$parse_output" "Version: 1.2.3-alpha.1+build.123" "parse shows full version [1.2.3-alpha.1+build.123 : parse -> shows full version]"
  assert_contains "$parse_output" "Major: 1" "parse shows major [1.2.3-alpha.1+build.123 : parse -> shows major: 1]"
  assert_contains "$parse_output" "Minor: 2" "parse shows minor [1.2.3-alpha.1+build.123 : parse -> shows minor: 2]"
  assert_contains "$parse_output" "Patch: 3" "parse shows patch [1.2.3-alpha.1+build.123 : parse -> shows patch: 3]"
  assert_contains "$parse_output" "Pre-release: alpha.1" "parse shows pre-release [1.2.3-alpha.1+build.123 : parse -> shows pre-release: alpha.1]"
  assert_contains "$parse_output" "Build: build.123" "parse shows build metadata [1.2.3-alpha.1+build.123 : parse -> shows build: build.123]"
  
  # Critical: Test that parse exits with code 0 for valid versions (regression test)
  assert_ok $TOOL parse 2.0.0 "parse exits successfully for simple version [2.0.0 : parse -> exit 0]"
  assert_ok $TOOL parse 1.2.3-alpha "parse exits successfully for pre-release only [1.2.3-alpha : parse -> exit 0]"
  assert_ok $TOOL parse 1.2.3+build "parse exits successfully for build only [1.2.3+build : parse -> exit 0]"
  assert_ok $TOOL parse 1.2.3-alpha+build "parse exits successfully for full version [1.2.3-alpha+build : parse -> exit 0]"
  
  # Test simpler version
  parse_output=$($TOOL parse 2.0.0 2>&1)
  assert_contains "$parse_output" "Major: 2" "simple version major [2.0.0 : parse -> shows major: 2]"
  assert_contains "$parse_output" "Minor: 0" "simple version minor [2.0.0 : parse -> shows minor: 0]"
  assert_contains "$parse_output" "Patch: 0" "simple version patch [2.0.0 : parse -> shows patch: 0]"
  
  # Test version with v-prefix
  parse_output=$($TOOL parse v3.1.4 2>&1)
  assert_contains "$parse_output" "Version: 3.1.4" "v-prefix stripped in output [v3.1.4 : parse -> shows version: 3.1.4]"
  assert_contains "$parse_output" "Major: 3" "v-prefix version major [v3.1.4 : parse -> shows major: 3]"
  
  # Test pre-release only
  parse_output=$($TOOL parse 1.0.0-rc.2 2>&1)
  assert_contains "$parse_output" "Pre-release: rc.2" "pre-release only parsing [1.0.0-rc.2 : parse -> shows pre-release: rc.2]"
  
  # Test build metadata only
  parse_output=$($TOOL parse 1.0.0+20130313144700 2>&1)
  assert_contains "$parse_output" "Build: 20130313144700" "build metadata only parsing [1.0.0+20130313144700 : parse -> shows build: 20130313144700]"
  
  # Parse should fail for invalid versions
  assert_fail $TOOL parse "invalid.version" "parse rejects invalid version [invalid.version : parse -> fails]"
  assert_fail $TOOL parse "1.2" "parse rejects incomplete version [1.2 : parse -> fails]"
  
  echo
}

test_edge_cases() {
  _section_header "Edge Cases and Special Scenarios"
  
  # Zero versions
  assert_eq "0.0.1" "$($TOOL patch 0.0.0)" "patch from zero [0.0.0 : patch -> 0.0.1]"
  assert_eq "0.1.0" "$($TOOL minor 0.0.0)" "minor from zero [0.0.0 : minor -> 0.1.0]"
  assert_eq "1.0.0" "$($TOOL major 0.0.0)" "major from zero [0.0.0 : major -> 1.0.0]"

  # Large version numbers
  assert_eq "999.999.1000" "$($TOOL patch 999.999.999)" "large version patch [999.999.999 : patch -> 999.999.1000]"
  assert_ok $TOOL gt 1000.0.0 999.999.999 "large version comparison [1000.0.0 : gt : 999.999.999 -> true]"
  
  # Single character pre-releases
  assert_eq "1.0.0-a" "$($TOOL pre -p a 1.0.0-z)" "single char pre-release [1.0.0-z : pre -p a -> 1.0.0-a]"
  assert_ok $TOOL gt 1.0.0-b 1.0.0-a "single char comparison [1.0.0-b : gt : 1.0.0-a -> true]"
  
  # Mixed numeric/string in pre-release
  assert_ok $TOOL lt 1.0.0-1.a 1.0.0-1.b "mixed comparison in pre-release [1.0.0-1.a : lt : 1.0.0-1.b -> true]"
  assert_ok $TOOL lt 1.0.0-1 1.0.0-a "numeric < string in pre-release [1.0.0-1 : lt : 1.0.0-a -> true]"
  
  # Leading zeros in version numbers (should be treated as numeric)
  assert_ok $TOOL eq 1.2.3 1.02.03 "leading zeros ignored [1.2.3 : eq : 1.02.03 -> true]"
  assert_ok $TOOL gt 1.0.0-rc.10 1.0.0-rc.09 "leading zeros in pre-release [1.0.0-rc.10 : gt : 1.0.0-rc.09 -> true]"
  
  # Very long pre-release identifiers
  assert_eq "1.0.0-very.long.pre.release.identifier.with.many.parts" "$($TOOL pre -p very.long.pre.release.identifier.with.many.parts 1.0.0-short)" "very long pre-release [1.0.0-short : pre -p very.long.pre.release.identifier.with.many.parts -> 1.0.0-very.long.pre.release.identifier.with.many.parts]"

  echo
}

test_error_handling() {
  _section_header "Error Handling and Invalid Input"
  
  # Bump command errors
  assert_fail $TOOL bump 1.2.3 "bump missing -b flag and type [bump 1.2.3 -> fails (missing -b)]"
  assert_fail $TOOL bump -b foo 1.2.3 "bump invalid type [bump -b foo 1.2.3 -> fails (invalid type)]"
  assert_fail $TOOL bump -b patch "bump missing version [bump -b patch -> fails (missing version)]"
  assert_fail $TOOL bump -b pre 1.2.3 "pre bump missing -p flag [bump -b pre 1.2.3 -> fails (missing -p)]"
  assert_fail $TOOL bump -b patch invalid.version "bump invalid version [bump -b patch invalid.version -> fails (invalid version)]"
  assert_fail $TOOL bump -b patch 1.2.3 extra "bump too many args [bump -b patch 1.2.3 extra -> fails (too many args)]"
  
  # Shorthand bump errors
  assert_fail $TOOL patch "shorthand bump missing version [patch -> fails (missing version)]"
  assert_fail $TOOL pre 1.2.3 "shorthand pre missing -p flag [pre 1.2.3 -> fails (missing -p)]"
  assert_fail $TOOL minor invalid.version "shorthand bump invalid version [minor invalid.version -> fails (invalid version)]"
  
  # Compare command errors  
  assert_fail $TOOL compare 1.0.0 1.0.0 "compare missing -c flag [compare 1.0.0 1.0.0 -> fails (missing -c)]"
  assert_fail $TOOL compare -c foo 1.0.0 1.0.0 "compare invalid operator [compare -c foo 1.0.0 1.0.0 -> fails (invalid operator)]"
  assert_fail $TOOL compare -c gt 1.0.0 "compare missing second version [compare -c gt 1.0.0 -> fails (missing second version)]"
  assert_fail $TOOL compare -c gt invalid.version 1.0.0 "compare invalid first version [compare -c gt invalid.version 1.0.0 -> fails (invalid first version)]"
  assert_fail $TOOL compare -c gt 1.0.0 invalid.version "compare invalid second version [compare -c gt 1.0.0 invalid.version -> fails (invalid second version)]"
  assert_fail $TOOL compare -c eq 1.0.0 1.0.0 extra "compare too many args [compare -c eq 1.0.0 1.0.0 extra -> fails (too many args)]"
  
  # Shorthand compare errors
  assert_fail $TOOL gt 1.0.0 "shorthand compare missing second version [gt 1.0.0 -> fails (missing second version)]"
  assert_fail $TOOL eq invalid.version 1.0.0 "shorthand compare invalid version [eq invalid.version 1.0.0 -> fails (invalid first version)]"
  
  # Validate command errors
  assert_fail $TOOL validate "validate missing argument [validate -> fails (missing argument)]"
  assert_fail $TOOL validate 1.2.3 1.2.4 "validate too many arguments [validate 1.2.3 1.2.4 -> fails (too many arguments)]"
  
  # Parse command errors
  assert_fail $TOOL parse "parse missing argument [parse -> fails (missing argument)]"
  assert_fail $TOOL parse 1.2.3 1.2.4 "parse too many arguments [parse 1.2.3 1.2.4 -> fails (too many arguments)]"
  
  # Global command errors
  assert_fail $TOOL "missing subcommand [<no args> -> fails (missing subcommand)]"
  assert_fail $TOOL invalidcommand "invalid subcommand [invalidcommand -> fails (invalid subcommand)]"
  assert_fail $TOOL -x "invalid global option [-x -> fails (invalid option)]"
  
  echo
}

test_comprehensive_scenarios() {
  _section_header "Comprehensive Real-world Scenarios"
  
  # Typical development workflow
  assert_eq "1.0.0" "$($TOOL bump major 0.9.0)" "initial release [0.9.0 : major -> 1.0.0]"
  assert_eq "1.0.1" "$($TOOL patch 1.0.0)" "hotfix [1.0.0 : patch -> 1.0.1]"
  assert_eq "1.1.0-alpha.1" "$($TOOL minor -p alpha.1 1.0.1)" "start feature pre-release [1.0.1 : minor -p alpha.1 -> 1.1.0-alpha.1]"
  assert_eq "1.1.0-alpha.2" "$($TOOL pre -p alpha.2 1.1.0-alpha.1)" "iterate alpha [1.1.0-alpha.1 : pre -p alpha.2 -> 1.1.0-alpha.2]"
  assert_eq "1.1.0-beta.1" "$($TOOL pre -p beta.1 1.1.0-alpha.2)" "alpha to beta [1.1.0-alpha.2 : pre -p beta.1 -> 1.1.0-beta.1]"
  assert_eq "1.1.0-rc.1" "$($TOOL pre -p rc.1 1.1.0-beta.1)" "beta to rc [1.1.0-beta.1 : pre -p rc.1 -> 1.1.0-rc.1]"
  assert_eq "1.1.0" "$($TOOL patch 1.1.0-rc.1)" "finalize release [1.1.0-rc.1 : patch -> 1.1.0]"
  
  # Complex version ordering verification
  local versions=(
    "1.0.0-alpha"
    "1.0.0-alpha.1" 
    "1.0.0-alpha.beta"
    "1.0.0-beta"
    "1.0.0-beta.2"
    "1.0.0-beta.11" 
    "1.0.0-rc.1"
    "1.0.0"
    "2.0.0-alpha"
    "2.0.0"
  )
  
  # Test that each version is greater than the previous
  for (( i=1; i<${#versions[@]}; i++ )); do
    local prev="${versions[$((i-1))]}"
    local curr="${versions[i]}"
    assert_ok $TOOL gt "$curr" "$prev" "version ordering [$curr : gt : $prev -> true]"
  done
  
  # CI/CD workflow simulation
  assert_eq "1.2.0-ci.123" "$($TOOL minor -p ci.123 1.1.5)" "CI build version [1.1.5 : minor -p ci.123 -> 1.2.0-ci.123]"
  assert_eq "1.2.0-ci.124" "$($TOOL pre -p ci.124 1.2.0-ci.123)" "CI iteration [1.2.0-ci.123 : pre -p ci.124 -> 1.2.0-ci.124]"
  assert_eq "1.2.0" "$($TOOL minor 1.2.0-ci.124)" "CI to release [1.2.0-ci.124 : minor -> 1.2.0]"
  
  echo
}

test_boundary_conditions() {
  _section_header "Boundary Conditions and Special Cases"
  
  # Maximum reasonable version numbers
  assert_eq "999999999.999999999.999999999" "$($TOOL patch 999999999.999999999.999999998)" "very large version [999999999.999999999.999999998 : patch -> 999999999.999999999.999999999]"
  assert_ok $TOOL gt 1.0.0 0.999.999 "version with many digits [1.0.0 : gt : 0.999.999 -> true]"
  
  # Pre-release with only numbers
  assert_ok $TOOL gt 1.0.0-2 1.0.0-1 "numeric only pre-release [1.0.0-2 : gt : 1.0.0-1 -> true]"
  assert_ok $TOOL gt 1.0.0-10 1.0.0-2 "multi-digit numeric pre-release [1.0.0-10 : gt : 1.0.0-2 -> true]"
  
  # Empty and whitespace handling
  assert_fail $TOOL bump -b patch "   " "bump with whitespace version [bump -b patch '   ' -> fails (whitespace version)]"
  assert_fail $TOOL validate "  1.2.3  " "validate version with spaces [validate '  1.2.3  ' -> fails (spaces)]"
  
  # Case sensitivity
  assert_eq "1.0.0-Alpha" "$($TOOL pre -p Alpha 1.0.0-alpha)" "case sensitive pre-release [1.0.0-alpha : pre -p Alpha -> 1.0.0-Alpha]"
  assert_ok $TOOL gt 1.0.0-b 1.0.0-A "case sensitive comparison [1.0.0-b : gt : 1.0.0-A -> true]"
  
  # Special characters in pre-release (allowed by SemVer)
  assert_eq "1.0.0-alpha-beta-gamma" "$($TOOL pre -p alpha-beta-gamma 1.0.0-alpha)" "hyphens in pre-release [1.0.0-alpha : pre -p alpha-beta-gamma -> 1.0.0-alpha-beta-gamma]"
  
  # Build metadata edge cases - all valid according to SemVer spec
  assert_ok $TOOL eq 1.2.3+a 1.2.3+b "minimal build metadata ignored [1.2.3+a : eq : 1.2.3+b -> true]"
  assert_ok $TOOL eq 1.2.3+0 1.2.3+999 "numeric build metadata ignored [1.2.3+0 : eq : 1.2.3+999 -> true]"
  
  echo
}

test_performance_edge_cases() {
  _section_header "Performance and Stress Cases"
  
  # Many version comparisons to test algorithm efficiency
  local base_version="1.0.0"
  for i in {1..20}; do
    local test_version="1.0.$i"
    assert_ok $TOOL gt "$test_version" "$base_version" "sequential version comparison [$test_version : gt : $base_version -> true]"
  done
  
  # Complex pre-release comparison chains
  assert_ok $TOOL gt "1.0.0-rc.10.10.10" "1.0.0-rc.10.10.9" "deep pre-release nesting [1.0.0-rc.10.10.10 : gt : 1.0.0-rc.10.10.9 -> true]"
  assert_ok $TOOL gt "1.0.0-alpha.beta.gamma.delta.epsilon" "1.0.0-alpha.beta.gamma.delta" "very long pre-release chain comparison"
  
  echo
}
##) tests

##( core
_test_runner # Run all tests
##) core