#!/usr/bin/env bash
##( header
#
# Test Suite for git-tag
#
# Comprehensive tests for Git tag management with semantic versioning
##) header

##( configuration
set -euo pipefail
##) configuration

##( setup
# Source the common test framework
source ../.common/test-common

# Use shorter variable names
NAME="git-tag"
TOOL="./git-tag"

# Global test variables
ORIGINAL_PWD=""
TOOL_PATH=""
SEMVER_PATH=""
##) setup

##( test helpers
# Set up a temporary git repository for testing
setup_test_repo() {
  local repo_name="${1:-test-repo}"
  
  # Create temporary directory and initialize git repo
  local test_repo=$(mktemp -d "${TMPDIR:-/tmp}/git-tag-test-XXXXXX")/$repo_name
  
  mkdir -p "$test_repo"
  
  (
    cd "$test_repo"
    git init --quiet
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "Initial commit" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
  )
  
  echo "$test_repo"
}

# Clean up test repository
cleanup_test_repo() {
  local test_repo="$1"
  [[ -n "$test_repo" && -d "$test_repo" ]] && rm -rf "$(dirname "$test_repo")"
}

# Create a test tag
create_test_tag() {
  local tag="$1" message="${2:-Test release}"
  git tag -a "$tag" -m "$message"
}

# Create multiple test tags for ordering tests
setup_test_tags() {
  # Create tags in non-chronological order to test semantic vs chronological sorting
  create_test_tag "v1.0.0" "Release 1.0.0"
  sleep 1  # Ensure different timestamps
  create_test_tag "v1.2.0" "Release 1.2.0" 
  sleep 1
  create_test_tag "v1.1.0" "Release 1.1.0"  # Chronologically last but semantically middle
  sleep 1
  create_test_tag "v2.0.0-alpha.1" "Pre-release"
}

# Assert tag exists
assert_tag_exists() {
  local tag="$1" desc="$2"
  if git tag -l "$tag" | grep -q "^$tag$"; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    _TESTS_RUN=$((_TESTS_RUN + 1))
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "$desc"
    printf "    Tag '%s' does not exist\n" "$tag"
  fi
}

# Assert tag does not exist
assert_tag_not_exists() {
  local tag="$1" desc="$2"
  if ! git tag -l "$tag" | grep -q "^$tag$"; then
    printf "  ${_GRN}✓${_RST} %s\n" "$desc"
    _TESTS_RUN=$((_TESTS_RUN + 1))
  else
    _FAILURES=$((_FAILURES + 1))
    printf "  ${_RED}✗${_RST} %s\n" "$desc"
    printf "    Tag '%s' exists but should not\n" "$tag"
  fi
}
##) test helpers

##( tests
test_basic_functionality() {
  _section_header "Basic Functionality"
  
  # Test 1: Empty repository
  local test_repo=$(setup_test_repo "empty-repo-test")
  cd "$test_repo"
  
  assert_eq "v0.0.0" "$($TOOL_PATH current)" "current tag in empty repo [current -> v0.0.0]"
  assert_eq "v0.0.0" "$($TOOL_PATH latest)" "latest tag in empty repo [latest -> v0.0.0]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  
  # Test 2: Repository with tags
  test_repo=$(setup_test_repo "tagged-repo-test")
  cd "$test_repo"
  
  setup_test_tags
  
  # Test current (highest semantic version)
  assert_eq "v2.0.0-alpha.1" "$($TOOL_PATH current)" "current tag with pre-release [current -> v2.0.0-alpha.1]"
  
  # Test latest (most recent chronological)
  assert_eq "v2.0.0-alpha.1" "$($TOOL_PATH latest)" "latest chronological tag [latest -> v2.0.0-alpha.1]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_next_command() {
  _section_header "Next - Version Preview"
  
  local test_repo=$(setup_test_repo "next-test")
  cd "$test_repo"
  
  # Test with empty repo
  assert_eq "v0.0.1" "$($TOOL_PATH next 2>/dev/null)" "next patch from empty repo [next -> v0.0.1]"
  assert_eq "v0.1.0" "$($TOOL_PATH next -b minor 2>/dev/null)" "next minor from empty repo [next -b minor -> v0.1.0]"
  assert_eq "v1.0.0" "$($TOOL_PATH next -b major 2>/dev/null)" "next major from empty repo [next -b major -> v1.0.0]"
  
  # Test with existing tags
  create_test_tag "v1.0.0"
  
  assert_eq "v1.0.1" "$($TOOL_PATH next 2>/dev/null)" "next patch [v1.0.0 : next -> v1.0.1]"
  assert_eq "v1.1.0" "$($TOOL_PATH next -b minor 2>/dev/null)" "next minor [v1.0.0 : next -b minor -> v1.1.0]"
  assert_eq "v2.0.0" "$($TOOL_PATH next -b major 2>/dev/null)" "next major [v1.0.0 : next -b major -> v2.0.0]"
  
  # Test pre-release calculations
  assert_eq "v1.1.0-alpha.1" "$($TOOL_PATH next -b minor -p alpha.1 2>/dev/null)" "next minor pre-release [v1.0.0 : next -b minor -p alpha.1 -> v1.1.0-alpha.1]"
  
  # Test pre-release iteration
  create_test_tag "v1.1.0-alpha.1"
  assert_eq "v1.1.0-alpha.2" "$($TOOL_PATH next -b pre -p alpha.2 2>/dev/null)" "next pre-release iteration [v1.1.0-alpha.1 : next -b pre -p alpha.2 -> v1.1.0-alpha.2]"
  
  # Verify no tags were created
  assert_tag_not_exists "v1.0.1" "next doesn't create tags"
  assert_tag_not_exists "v1.1.0" "next doesn't create tags (minor)"
  assert_tag_not_exists "v2.0.0" "next doesn't create tags (major)"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_list_command() {
  _section_header "List - Tag Overview"
  
  local test_repo=$(setup_test_repo "list-test")
  cd "$test_repo"
  
  # Test empty repo
  local list_output=$($TOOL_PATH list 2>&1)
  assert_contains "$list_output" "no tags found" "list handles empty repo [list -> 'no tags found']"
  
  # Test with tags
  setup_test_tags
  list_output=$($TOOL_PATH list 2>/dev/null)
  assert_contains "$list_output" "TAG" "list shows header [list -> includes 'TAG' header]"
  assert_contains "$list_output" "DATE" "list shows date header [list -> includes 'DATE' header]"
  assert_contains "$list_output" "MESSAGE" "list shows message header [list -> includes 'MESSAGE' header]"
  assert_contains "$list_output" "v1.0.0" "list shows v1.0.0 tag [list -> includes 'v1.0.0']"
  assert_contains "$list_output" "v2.0.0-alpha.1" "list shows pre-release tag [list -> includes 'v2.0.0-alpha.1']"
  
  # Test chronological ordering (most recent first)
  local first_line=$(echo "$list_output" | sed -n '3p')  # Skip headers
  assert_contains "$first_line" "v2.0.0-alpha.1" "list shows most recent first [first entry -> v2.0.0-alpha.1]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_bump_standard() {
  _section_header "Bump - Standard Version Bumps"
  
  local test_repo=$(setup_test_repo "bump-standard")
  cd "$test_repo"
  
  # Start with v1.0.0
  create_test_tag "v1.0.0"
  
  # Test patch bump (default)
  local new_tag=$($TOOL_PATH bump)
  assert_eq "v1.0.1" "$new_tag" "default patch bump [v1.0.0 : bump -> v1.0.1]"
  assert_tag_exists "v1.0.1" "patch tag created"
  
  # Test minor bump
  new_tag=$($TOOL_PATH bump -b minor)
  assert_eq "v1.1.0" "$new_tag" "minor bump [v1.0.1 : bump -b minor -> v1.1.0]"
  assert_tag_exists "v1.1.0" "minor tag created"
  
  # Test major bump
  new_tag=$($TOOL_PATH bump -b major)
  assert_eq "v2.0.0" "$new_tag" "major bump [v1.1.0 : bump -b major -> v2.0.0]"
  assert_tag_exists "v2.0.0" "major tag created"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_bump_prerelease() {
  _section_header "Bump - Pre-release Workflows"
  
  local test_repo=$(setup_test_repo "bump-prerelease")
  cd "$test_repo"
  
  # Start with v1.0.0
  create_test_tag "v1.0.0"
  
  # Start pre-release cycle - capture stdout only
  local new_tag=$($TOOL_PATH bump -b minor -p alpha.1 2>/dev/null)
  assert_eq "v1.1.0-alpha.1" "$new_tag" "start minor pre-release [v1.0.0 : bump -b minor -p alpha.1 -> v1.1.0-alpha.1]"
  assert_tag_exists "v1.1.0-alpha.1" "pre-release tag created"
  
  # Iterate on pre-release
  new_tag=$($TOOL_PATH bump -b pre -p alpha.2 2>/dev/null)
  assert_eq "v1.1.0-alpha.2" "$new_tag" "iterate pre-release [v1.1.0-alpha.1 : bump -b pre -p alpha.2 -> v1.1.0-alpha.2]"
  assert_tag_exists "v1.1.0-alpha.2" "iterated pre-release tag created"
  
  # Change pre-release type
  new_tag=$($TOOL_PATH bump -b pre -p beta.1 2>/dev/null)
  assert_eq "v1.1.0-beta.1" "$new_tag" "change pre-release type [v1.1.0-alpha.2 : bump -b pre -p beta.1 -> v1.1.0-beta.1]"
  assert_tag_exists "v1.1.0-beta.1" "beta pre-release tag created"
  
  # Finalize pre-release
  new_tag=$($TOOL_PATH bump -b minor 2>/dev/null)
  assert_eq "v1.1.0" "$new_tag" "finalize pre-release [v1.1.0-beta.1 : bump -b minor -> v1.1.0]"
  assert_tag_exists "v1.1.0" "final release tag created"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_bump_dry_run() {
  _section_header "Bump - Dry Run Functionality"
  
  local test_repo=$(setup_test_repo "bump-dry-run")
  cd "$test_repo"
  
  # Start with v1.0.0
  create_test_tag "v1.0.0"
  
  # Test dry run - capture stdout only
  local new_tag=$($TOOL_PATH bump -b minor -d 2>/dev/null)
  assert_eq "v1.1.0" "$new_tag" "dry run shows correct version [v1.0.0 : bump -b minor -d -> v1.1.0]"
  assert_tag_not_exists "v1.1.0" "dry run does not create tag"
  
  # Test dry run with pre-release
  new_tag=$($TOOL_PATH bump -b major -p rc.1 -d 2>/dev/null)
  assert_eq "v2.0.0-rc.1" "$new_tag" "dry run with pre-release [v1.0.0 : bump -b major -p rc.1 -d -> v2.0.0-rc.1]"
  assert_tag_not_exists "v2.0.0-rc.1" "dry run pre-release does not create tag"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_set_command() {
  _section_header "Set - Specific Tag Setting"
  
  local test_repo=$(setup_test_repo "set-command")
  cd "$test_repo"
  
  # Start with v1.0.0
  create_test_tag "v1.0.0"
  
  # Set a higher version - capture stdout only
  local new_tag=$($TOOL_PATH set v2.0.0 2>/dev/null)
  assert_eq "v2.0.0" "$new_tag" "set specific version [v1.0.0 : set v2.0.0 -> v2.0.0]"
  assert_tag_exists "v2.0.0" "set tag created"
  
  # Set a pre-release version
  new_tag=$($TOOL_PATH set v3.0.0-beta.1 2>/dev/null)
  assert_eq "v3.0.0-beta.1" "$new_tag" "set pre-release version [v2.0.0 : set v3.0.0-beta.1 -> v3.0.0-beta.1]"
  assert_tag_exists "v3.0.0-beta.1" "set pre-release tag created"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_version_ordering() {
  _section_header "Version Ordering and Precedence"
  
  local test_repo=$(setup_test_repo "version-ordering")
  cd "$test_repo"
  
  # Create tags in mixed order
  create_test_tag "v1.0.0" "First"
  sleep 1
  create_test_tag "v1.10.0" "Second"  # Semantically higher
  sleep 1  
  create_test_tag "v1.2.0" "Third"   # Chronologically last but semantically middle
  sleep 1
  create_test_tag "v2.0.0-alpha.1" "Fourth"  # Pre-release
  sleep 1
  create_test_tag "v1.9.9" "Fifth"   # Chronologically last but not highest
  
  # Current should be highest semantic version (pre-release > final in this case)
  assert_eq "v2.0.0-alpha.1" "$($TOOL_PATH current)" "current finds highest semantic version [current -> v2.0.0-alpha.1]"
  
  # Latest should be most recent chronological
  assert_eq "v1.9.9" "$($TOOL_PATH latest)" "latest finds most recent chronological [latest -> v1.9.9]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_error_handling() {
  _section_header "Error Handling and Edge Cases"
  
  local test_repo=$(setup_test_repo "error-handling")
  cd "$test_repo"
  
  # Test invalid commands
  assert_fail $TOOL_PATH invalid-command "invalid command fails [invalid-command -> fails]"
  assert_fail $TOOL_PATH current extra-arg "current with extra args fails [current extra-arg -> fails]"
  assert_fail $TOOL_PATH latest extra-arg "latest with extra args fails [latest extra-arg -> fails]"
  
  # Test invalid bump options
  assert_fail $TOOL_PATH bump -b invalid "invalid bump type fails [bump -b invalid -> fails]"
  assert_fail $TOOL_PATH bump -b pre "pre without -p fails [bump -b pre -> fails]"
  assert_fail $TOOL_PATH bump extra-arg "bump with extra args fails [bump extra-arg -> fails]"
  
  # Test invalid set options
  assert_fail $TOOL_PATH set "set without argument fails [set -> fails]"
  assert_fail $TOOL_PATH set invalid-tag "invalid tag format fails [set invalid-tag -> fails]"
  assert_fail $TOOL_PATH set 1.0.0 "tag without v prefix fails [set 1.0.0 -> fails]"
  
  # Test duplicate tag creation
  create_test_tag "v1.0.0"
  assert_fail $TOOL_PATH set v1.0.0 "duplicate tag fails [set v1.0.0 -> fails]"
  
  # Test version going backwards
  assert_fail $TOOL_PATH set v0.9.0 "backwards version fails [set v0.9.0 -> fails]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_git_integration() {
  _section_header "Git Integration and Edge Cases"
  
  local test_repo=$(setup_test_repo "git-integration")
  cd "$test_repo"
  
  # Test with no commits (edge case)
  rm README.md
  git rm README.md --quiet
  git commit --quiet -m "Remove README"
  
  assert_eq "v0.0.0" "$($TOOL_PATH current)" "current works with minimal repo [current -> v0.0.0]"
  
  # Test tag creation with message
  local new_tag=$($TOOL_PATH bump)
  assert_tag_exists "$new_tag" "tag created in minimal repo"
  
  # Verify tag has proper annotation
  local tag_message=$(git tag -l --format='%(subject)' "$new_tag")
  assert_contains "$tag_message" "Release" "tag has proper release message [$new_tag has 'Release' message]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_non_git_directory() {
  _section_header "Non-Git Directory Handling"
  
  # Test outside git repo
  local temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/git-tag-non-git-XXXXXX")
  cd "$temp_dir"
  
  assert_fail "$TOOL_PATH" current "current fails outside git repo [current -> fails]"
  assert_fail "$TOOL_PATH" bump "bump fails outside git repo [bump -> fails]"
  
  cd "$ORIGINAL_PWD"
  rm -rf "$temp_dir"
  echo
}

test_comprehensive_workflow() {
  _section_header "Comprehensive Real-world Workflow"
  
  local test_repo=$(setup_test_repo "comprehensive-workflow")
  cd "$test_repo"
  
  # Simulate complete development workflow
  local tag
  
  # Initial release - capture stdout only
  tag=$($TOOL_PATH bump -b major 2>/dev/null)  # v1.0.0 (from v0.0.0)
  assert_eq "v1.0.0" "$tag" "initial major release [v0.0.0 : bump -b major -> v1.0.0]"
  
  # Patch releases
  tag=$($TOOL_PATH bump 2>/dev/null)  # v1.0.1
  assert_eq "v1.0.1" "$tag" "first patch [v1.0.0 : bump -> v1.0.1]"
  
  tag=$($TOOL_PATH bump 2>/dev/null)  # v1.0.2
  assert_eq "v1.0.2" "$tag" "second patch [v1.0.1 : bump -> v1.0.2]"
  
  # Start next minor version pre-release
  tag=$($TOOL_PATH bump -b minor -p alpha.1 2>/dev/null)  # v1.1.0-alpha.1
  assert_eq "v1.1.0-alpha.1" "$tag" "start minor pre-release [v1.0.2 : bump -b minor -p alpha.1 -> v1.1.0-alpha.1]"
  
  # Iterate alpha
  tag=$($TOOL_PATH bump -b pre -p alpha.2 2>/dev/null)  # v1.1.0-alpha.2
  assert_eq "v1.1.0-alpha.2" "$tag" "iterate alpha [v1.1.0-alpha.1 : bump -b pre -p alpha.2 -> v1.1.0-alpha.2]"
  
  # Move to beta
  tag=$($TOOL_PATH bump -b pre -p beta.1 2>/dev/null)  # v1.1.0-beta.1
  assert_eq "v1.1.0-beta.1" "$tag" "alpha to beta [v1.1.0-alpha.2 : bump -b pre -p beta.1 -> v1.1.0-beta.1]"
  
  # Move to rc
  tag=$($TOOL_PATH bump -b pre -p rc.1 2>/dev/null)  # v1.1.0-rc.1
  assert_eq "v1.1.0-rc.1" "$tag" "beta to rc [v1.1.0-beta.1 : bump -b pre -p rc.1 -> v1.1.0-rc.1]"
  
  # Final release
  tag=$($TOOL_PATH bump -b minor 2>/dev/null)  # v1.1.0
  assert_eq "v1.1.0" "$tag" "finalize release [v1.1.0-rc.1 : bump -b minor -> v1.1.0]"
  
  # Verify current is correct
  assert_eq "v1.1.0" "$($TOOL_PATH current)" "workflow final current [current -> v1.1.0]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_environment_edge_cases() {
  _section_header "Environment & Configuration Edge Cases"
  
  # Test SEM_VER environment variable handling
  local original_sem_ver="$SEM_VER"
  
  # Test with invalid SEM_VER path
  export SEM_VER="/nonexistent/path"
  local test_repo=$(setup_test_repo "env-test")
  cd "$test_repo"
  create_test_tag "v1.0.0"
  
  assert_fail $TOOL_PATH bump "bump fails with invalid SEM_VER path [SEM_VER=/nonexistent/path : bump -> fails]"
  assert_fail $TOOL_PATH next "next fails with invalid SEM_VER path [SEM_VER=/nonexistent/path : next -> fails]"
  
  # Restore environment
  export SEM_VER="$original_sem_ver"
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_version_edge_cases() {
  _section_header "Version Format Edge Cases"
  
  local test_repo=$(setup_test_repo "version-edge")
  cd "$test_repo"
  
  # Test version boundaries
  create_test_tag "v0.0.0"
  local new_tag=$($TOOL_PATH bump 2>/dev/null)
  assert_eq "v0.0.1" "$new_tag" "bump from v0.0.0 works [v0.0.0 : bump -> v0.0.1]"
  
  # Test next from current state (should be v0.0.1 now)
  assert_eq "v0.0.2" "$($TOOL_PATH next 2>/dev/null)" "next from v0.0.1 [v0.0.1 : next -> v0.0.2]"
  
  # Test large version numbers  
  create_test_tag "v999.999.999"
  new_tag=$($TOOL_PATH bump 2>/dev/null)
  assert_eq "v999.999.1000" "$new_tag" "bump large version numbers [v999.999.999 : bump -> v999.999.1000]"
  
  # Test next with large numbers (current highest is now v999.999.1000)
  assert_eq "v999.999.1001" "$($TOOL_PATH next 2>/dev/null)" "next with large numbers [v999.999.1000 : next -> v999.999.1001]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_complex_prerelease_scenarios() {
  _section_header "Complex Pre-release Scenarios"
  
  local test_repo=$(setup_test_repo "complex-prerelease")
  cd "$test_repo"
  
  create_test_tag "v1.0.0"
  
  # Multi-dot pre-release
  local new_tag=$($TOOL_PATH bump -b minor -p alpha.1.2.3 2>/dev/null)
  assert_eq "v1.1.0-alpha.1.2.3" "$new_tag" "complex pre-release identifier [v1.0.0 : bump -b minor -p alpha.1.2.3 -> v1.1.0-alpha.1.2.3]"
  
  # Numeric-only pre-release
  new_tag=$($TOOL_PATH bump -b pre -p 123 2>/dev/null)
  assert_eq "v1.1.0-123" "$new_tag" "numeric pre-release identifier [v1.1.0-alpha.1.2.3 : bump -b pre -p 123 -> v1.1.0-123]"
  
  # Hyphenated pre-release
  new_tag=$($TOOL_PATH bump -b pre -p alpha-beta 2>/dev/null)
  assert_eq "v1.1.0-alpha-beta" "$new_tag" "hyphenated pre-release identifier [v1.1.0-123 : bump -b pre -p alpha-beta -> v1.1.0-alpha-beta]"
  
  # Test next command with complex pre-releases
  assert_eq "v1.1.0-gamma.1" "$($TOOL_PATH next -b pre -p gamma.1 2>/dev/null)" "next with complex pre-release [v1.1.0-alpha-beta : next -b pre -p gamma.1 -> v1.1.0-gamma.1]"
  
  # Test edge case: single character identifiers
  new_tag=$($TOOL_PATH bump -b pre -p a 2>/dev/null)
  assert_eq "v1.1.0-a" "$new_tag" "single character pre-release [v1.1.0-alpha-beta : bump -b pre -p a -> v1.1.0-a]"
  
  # Test edge case: very long pre-release identifier
  new_tag=$($TOOL_PATH bump -b pre -p very.long.pre.release.identifier.with.many.parts 2>/dev/null)
  assert_eq "v1.1.0-very.long.pre.release.identifier.with.many.parts" "$new_tag" "very long pre-release identifier"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

test_performance_scenarios() {
  _section_header "Performance & Scale Scenarios"
  
  local test_repo=$(setup_test_repo "performance")
  cd "$test_repo"
  
  # Create many tags to test sorting performance
  for i in {1..20}; do
    create_test_tag "v1.$i.0" "Release 1.$i.0"
  done
  
  # Should still find highest correctly with many tags
  assert_eq "v1.20.0" "$($TOOL_PATH current 2>/dev/null)" "current works with many tags [current with 20 tags -> v1.20.0]"
  
  # Test chronological vs semantic ordering
  create_test_tag "v1.5.1" "Created later but lower version"
  assert_eq "v1.20.0" "$($TOOL_PATH current 2>/dev/null)" "semantic ordering prevails over chronological [current -> v1.20.0 not v1.5.1]"
  
  # Test next and list commands with many tags
  assert_eq "v1.20.1" "$($TOOL_PATH next 2>/dev/null)" "next works with many tags [v1.20.0 : next -> v1.20.1]"
  
  local list_output=$($TOOL_PATH list 2>/dev/null)
  assert_contains "$list_output" "v1.20.0" "list shows all tags with many entries [list -> includes v1.20.0]"
  assert_contains "$list_output" "v1.1.0" "list includes middle version [list -> includes v1.1.0]"
  
  # Test with mixed semantic versions for complex sorting
  create_test_tag "v2.0.0-alpha.1" "Pre-release"
  create_test_tag "v1.99.99" "High patch number"
  
  # Current should still be v2.0.0-alpha.1 (highest semantic)
  assert_eq "v2.0.0-alpha.1" "$($TOOL_PATH current 2>/dev/null)" "complex sorting finds highest semantic [current -> v2.0.0-alpha.1]"
  
  # Latest should be most recent chronological
  assert_eq "v1.99.99" "$($TOOL_PATH latest 2>/dev/null)" "latest finds most recent chronological [latest -> v1.99.99]"
  
  cd "$ORIGINAL_PWD"
  cleanup_test_repo "$test_repo"
  echo
}

##) tests

##( init
# Initialize test environment
ORIGINAL_PWD="$(pwd)"
TOOL_PATH="$(realpath "$TOOL")"
SEMVER_PATH="$(realpath "../sem-ver/sem-ver")"

# Export SEM_VER environment variable for git-tag to use
export SEM_VER="$SEMVER_PATH"
##) init

##( core
# Run all tests
_test_runner
##) core