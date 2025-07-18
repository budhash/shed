#!/usr/bin/env bash
##( header
#
# Test Suite for tool-name
#
# Replace 'tool-name' with your actual tool name.
##) header

##( configuration
set -euo pipefail
##) configuration

##( setup
# Source the common test framework
source ../.common/test-common

# Override tool name since directory is .template but script is tool-template
NAME="tool-template"
TOOL="./tool-template"

# Global test variables (add tool-specific ones here)
ORIGINAL_PWD=""
TOOL_PATH=""
##) setup

##( test helpers
# Helper functions for test setup/cleanup (customize for your tool)
setup_test_env() {
  # Create any test files, directories, or environment needed
  local test_dir=$(mktemp -d "${TMPDIR:-/tmp}/tool-test-XXXXXX")
  echo "$test_dir"
}

cleanup_test_env() {
  local test_dir="$1"
  [[ -n "$test_dir" && -d "$test_dir" ]] && rm -rf "$test_dir"
}

# Example: Create test input file
create_test_file() {
  local file="$1" content="${2:-test content}"
  echo "$content" > "$file"
}
##) test helpers

##( tests
# Template-specific functionality (actual tests for the template)
test_custom_functionality() {
  _section_header "Template Functionality"
  
  # Test that template shows help properly (check for actual template content)
  local help_output=$($TOOL_PATH -h 2>&1)
  assert_contains "$help_output" "{{version}}" "help shows version placeholder"
  assert_contains "$help_output" "{{detail}}" "help shows detail placeholder"
  assert_contains "$help_output" "tool-template" "help shows script name"
  
  # Test that template shows version placeholder
  local version_output=$($TOOL_PATH -v 2>&1)
  assert_contains "$version_output" "{{version}}" "version shows placeholder"
  
  # Test template runs and shows expected message
  local run_output=$($TOOL_PATH 2>&1 || true)
  assert_contains "$run_output" "template version" "template runs and shows template message"
  
  echo
}

# Template completeness tests
test_template_completeness() {
  _section_header "Template Completeness"
  
  # Check that template has all expected sections
  assert_ok grep -q "##( header" "$TOOL_PATH" "has header section"
  assert_ok grep -q "##( configuration" "$TOOL_PATH" "has configuration section"
  assert_ok grep -q "##( metadata" "$TOOL_PATH" "has metadata section" 
  assert_ok grep -q "##( globals" "$TOOL_PATH" "has globals section" 
  assert_ok grep -q "##( helpers" "$TOOL_PATH" "has helpers section"
  assert_ok grep -q "##( app" "$TOOL_PATH" "has app section"
  assert_ok grep -q "##( core" "$TOOL_PATH" "has core section"
  
  # Check for key functions
  assert_ok grep -q "_main" "$TOOL_PATH" "has main function"
  assert_ok grep -q "_help" "$TOOL_PATH" "has help function"
  assert_ok grep -q "_version" "$TOOL_PATH" "has version function"
  assert_ok grep -q "_cleanup" "$TOOL_PATH" "has cleanup function"
  
  # Check for proper error handling setup
  assert_ok grep -q "_E_USG" "$TOOL_PATH" "has usage error code"
  assert_ok grep -q "set -eEuo pipefail" "$TOOL_PATH" "has fail-fast configuration"
  
  echo
}

# Example tests for when you customize the template (commented out)
## Uncomment and customize these for your actual tool:

# test_basic_functionality() {
#   _section_header "Basic Functionality"
#   
#   # Test basic command execution
#   assert_ok $TOOL_PATH "tool runs without error"
#   
#   # Test with valid options
#   local test_dir=$(setup_test_env)
#   local test_file="$test_dir/test.txt"
#   create_test_file "$test_file"
#   assert_ok $TOOL_PATH -f "$test_file" "tool accepts file option"
#   cleanup_test_env "$test_dir"
#   
#   echo
# }

# test_error_handling() {
#   _section_header "Error Handling"
#   
#   # Test invalid options
#   assert_fail $TOOL_PATH -x "invalid option fails gracefully"
#   assert_fail $TOOL_PATH -f /nonexistent/file "nonexistent file fails gracefully"
#   
#   echo
# }

# test_input_validation() {
#   _section_header "Input Validation"
#   
#   local test_dir=$(setup_test_env)
#   
#   # Test with empty file
#   local empty_file="$test_dir/empty.txt"
#   touch "$empty_file"
#   assert_ok $TOOL_PATH -f "$empty_file" "handles empty file correctly"
#   
#   # Test with valid input file
#   local valid_file="$test_dir/valid.txt"
#   create_test_file "$valid_file" "valid test content"
#   assert_ok $TOOL_PATH -f "$valid_file" "processes valid file"
#   
#   cleanup_test_env "$test_dir"
#   echo
# }

# test_command_dispatch() {
#   _section_header "Command Dispatch"
#   
#   # For tools with subcommands
#   assert_ok $TOOL_PATH command1 "command1 works"
#   assert_ok $TOOL_PATH command2 arg "command2 with args works"
#   assert_fail $TOOL_PATH invalid-command "invalid command fails"
#   
#   echo
# }

# test_integration() {
#   _section_header "Integration Tests"
#   
#   # Test with different file types/formats
#   local test_dir=$(setup_test_env)
#   
#   local csv_file="$test_dir/test.csv"
#   create_test_file "$csv_file" "header1,header2\nvalue1,value2"
#   assert_ok $TOOL_PATH process "$csv_file" "handles CSV files"
#   
#   cleanup_test_env "$test_dir"
#   echo
# }

# test_performance() {
#   _section_header "Performance Tests"
#   
#   local test_dir=$(setup_test_env)
#   
#   # Test with larger input
#   local large_file="$test_dir/large.txt"
#   for i in {1..1000}; do
#     echo "line $i with some content" >> "$large_file"
#   done
#   
#   assert_ok $TOOL_PATH process "$large_file" "handles larger input files"
#   
#   cleanup_test_env "$test_dir"
#   echo
# }

# test_environment_edge_cases() {
#   _section_header "Environment Edge Cases"
#   
#   # Test dependency handling
#   local original_dep="$SOME_DEPENDENCY"
#   export SOME_DEPENDENCY="/nonexistent/path"
#   
#   assert_fail $TOOL_PATH command "fails with missing dependency"
#   
#   export SOME_DEPENDENCY="$original_dep"
#   echo
# }
##) tests

##( init
# Initialize test environment
ORIGINAL_PWD="$(pwd)"
TOOL_PATH="$(realpath "$TOOL")"

# Add any environment setup needed for your tool
# export TOOL_DEPENDENCY="/path/to/dependency"
##) init

##( core
# Run all tests
_test_runner
##) core