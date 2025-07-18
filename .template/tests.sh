#!/usr/bin/env bash
#
# Test Suite for tool-name
#
# Replace 'tool-name' with your actual tool name.
# Add your tool-specific tests in the test_custom_functionality function.

##( configuration
set -euo pipefail
##) configuration

##( setup
# Source the common test framework
source ../.common/test-common

# Override tool name since directory is .template but script is tool-template
TOOL_NAME="tool-template"
TOOL_SCRIPT="./tool-template"
##) setup

##( custom tests
# Add tests for the template script
test_custom_functionality() {
  test_section "Template Functionality"
  
  # Test that template shows help properly (check for actual template content)
  local help_output
  help_output=$($TOOL_SCRIPT -h 2>&1)
  assert_contains "$help_output" "{{version}}" "help shows version placeholder"
  assert_contains "$help_output" "{{detail}}" "help shows detail placeholder"
  assert_contains "$help_output" "tool-template" "help shows script name"
  
  # Test that template shows version placeholder
  local version_output
  version_output=$($TOOL_SCRIPT -v 2>&1)
  assert_contains "$version_output" "{{version}}" "version shows placeholder"
  
  # Test template runs without error (but may exit non-zero, that's ok for template)
  local run_output
  run_output=$($TOOL_SCRIPT 2>&1 || true)
  assert_contains "$run_output" "Template version" "template runs and shows template message"
  
  echo
}

# Test template completeness  
test_template_completeness() {
  test_section "Template Completeness"
  
  # Check that template has all expected sections
  assert_ok grep -q "##( configuration" "$TOOL_SCRIPT" "has configuration section"
  assert_ok grep -q "##( metadata" "$TOOL_SCRIPT" "has metadata section" 
  assert_ok grep -q "##( helpers" "$TOOL_SCRIPT" "has helpers section"
  assert_ok grep -q "##( app" "$TOOL_SCRIPT" "has app section"
  assert_ok grep -q "##( core" "$TOOL_SCRIPT" "has core section"
  
  # Check for key functions
  assert_ok grep -q "_main" "$TOOL_SCRIPT" "has main function"
  assert_ok grep -q "_help" "$TOOL_SCRIPT" "has help function"
  assert_ok grep -q "_version" "$TOOL_SCRIPT" "has version function"
  
  echo
}
##) custom tests
##) custom tests

# Run all tests
test_runner