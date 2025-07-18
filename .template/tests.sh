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
##) setup

##( tests
# Add tests for the template script
test_custom_functionality() {
  _section_header "Template Functionality"
  
  # Test that template shows help properly (check for actual template content)
  local help_output
  help_output=$($TOOL -h 2>&1)
  assert_contains "$help_output" "{{version}}" "help shows version placeholder"
  assert_contains "$help_output" "{{detail}}" "help shows detail placeholder"
  assert_contains "$help_output" "tool-template" "help shows script name"
  
  # Test that template shows version placeholder
  local version_output
  version_output=$($TOOL -v 2>&1)
  assert_contains "$version_output" "{{version}}" "version shows placeholder"
  
  # Test template runs without error (but may exit non-zero, that's ok for template)
  local run_output
  run_output=$($TOOL 2>&1 || true)
  assert_contains "$run_output" "template version" "template runs and shows template message"
  
  echo
}

# Test template completeness  
test_template_completeness() {
  _section_header "Template Completeness"
  
  # Check that template has all expected sections
  assert_ok grep -q "##( header" "$TOOL" "has header section"
  assert_ok grep -q "##( configuration" "$TOOL" "has configuration section"
  assert_ok grep -q "##( metadata" "$TOOL" "has metadata section" 
  assert_ok grep -q "##( globals" "$TOOL" "has globals section" 
  assert_ok grep -q "##( helpers" "$TOOL" "has helpers section"
  assert_ok grep -q "##( app" "$TOOL" "has app section"
  assert_ok grep -q "##( core" "$TOOL" "has core section"
  
  # Check for key functions
  assert_ok grep -q "_main" "$TOOL" "has main function"
  assert_ok grep -q "_help" "$TOOL" "has help function"
  assert_ok grep -q "_version" "$TOOL" "has version function"
  
  echo
}
##) tests

##( core
_test_runner # Run all tests
##) core