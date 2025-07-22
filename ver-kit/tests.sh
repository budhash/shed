#!/usr/bin/env bash
##( header
#
# Test Suite for ver-kit
#
# Simple tests for universal version get toolkit
##) header

##( configuration
set -euo pipefail
##) configuration

##( setup
# Source the common test framework
source ../.common/test-common

# Use shorter variable names
NAME="ver-kit"
TOOL="./ver-kit"

# Global test variables
TEST_DIR=""
ORIGINAL_PWD=""
TOOL_PATH=""
##) setup

##( test helpers
# Set up temporary directory for test files
setup_test_dir() {
  TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ver-kit-test-XXXXXX")
  cd "$TEST_DIR"
}

# Clean up test directory
cleanup_test_dir() {
  if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
    cd "$ORIGINAL_PWD" 2>/dev/null || cd /
    rm -rf "$TEST_DIR"
    TEST_DIR=""
  fi
}

# Create a test file with specific content
create_test_file() {
  local filename="$1" content="$2"
  printf "%s\n" "$content" > "$filename"
}
##) test helpers

##( tests
test_basic_patterns() {
  _section_header "Basic Custom Pattern Operations"
  
  setup_test_dir
  
  # Test custom pattern with -p option (get → set → get)
  create_test_file "test.yaml" "app_version: 1.2.3"
  assert_eq "1.2.3" "$("$TOOL_PATH" get -f test.yaml -p 'app_version:')" "custom pattern extraction"
  assert_eq "2.0.0" "$("$TOOL_PATH" set -f test.yaml -p 'app_version:' 2.0.0)" "custom pattern set"
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f test.yaml -p 'app_version:')" "custom pattern get after set"
  
  # Test stdin with custom pattern (get only)
  local result
  result=$(echo "version: 2.0.0-alpha.1" | "$TOOL_PATH" get -f - -p "version:")
  assert_eq "2.0.0-alpha.1" "$result" "stdin with custom pattern"
  
  # Test quoted version extraction (get → set → get)
  create_test_file "quoted.swift" 'let version = "3.0.0"'
  result=$("$TOOL_PATH" get -f quoted.swift -p "version =")
  assert_eq "3.0.0" "$result" "quoted version extraction"
  assert_eq "3.1.0" "$("$TOOL_PATH" set -f quoted.swift -p 'version =' 3.1.0)" "quoted version set"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f quoted.swift -p 'version =')" "quoted version get after set"
  
  cleanup_test_dir
  echo
}

test_shell_auto_detection() {
  _section_header "Shell Script Auto-Detection"
  
  setup_test_dir
  
  # Test VERSION comment pattern (get → set → get)
  create_test_file "script.sh" '#!/bin/bash
# VERSION: 1.0.0
echo "test script"'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f script.sh)" "shell VERSION comment auto-detection"
  assert_eq "1.1.0" "$("$TOOL_PATH" set -f script.sh 1.1.0)" "shell VERSION comment set"
  assert_eq "1.1.0" "$("$TOOL_PATH" get -f script.sh)" "shell VERSION comment get after set"
  
  # Test VERSION variable pattern (get → set → get)
  create_test_file "script2.sh" '#!/bin/bash
VERSION="2.0.0"
echo "version: $VERSION"'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f script2.sh)" "shell VERSION variable auto-detection"
  assert_eq "2.5.0" "$("$TOOL_PATH" set -f script2.sh 2.5.0)" "shell VERSION variable set"
  assert_eq "2.5.0" "$("$TOOL_PATH" get -f script2.sh)" "shell VERSION variable get after set"
  
  # Test .bash extension (get → set → get)
  create_test_file "script.bash" 'version="3.0.0"'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f script.bash)" "bash extension auto-detection"
  assert_eq "3.2.0" "$("$TOOL_PATH" set -f script.bash 3.2.0)" "bash extension set"
  assert_eq "3.2.0" "$("$TOOL_PATH" get -f script.bash)" "bash extension get after set"
  
  cleanup_test_dir
  echo
}

test_swift_auto_detection() {
  _section_header "Swift Auto-Detection"
  
  setup_test_dir
  
  # Test let version pattern (get → set → get)
  create_test_file "main.swift" 'let version = "1.0.0"'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f main.swift)" "swift let version auto-detection"
  assert_eq "1.2.0" "$("$TOOL_PATH" set -f main.swift 1.2.0)" "swift let version set"
  assert_eq "1.2.0" "$("$TOOL_PATH" get -f main.swift)" "swift let version get after set"
  
  # Test static let version (get → set → get)
  create_test_file "App.swift" 'static let version = "2.0.0"'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f App.swift)" "swift static let auto-detection"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f App.swift 2.1.0)" "swift static let set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f App.swift)" "swift static let get after set"
  
  # Test Package.swift special case (get → set → get)
  create_test_file "Package.swift" '// VERSION: 3.0.0'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f Package.swift)" "Package.swift auto-detection"
  assert_eq "3.1.0" "$("$TOOL_PATH" set -f Package.swift 3.1.0)" "Package.swift set"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f Package.swift)" "Package.swift get after set"
  
  cleanup_test_dir
  echo
}

test_python_auto_detection() {
  _section_header "Python Auto-Detection"
  
  setup_test_dir
  
  # Test __version__ pattern (get → set → get)
  create_test_file "setup.py" '__version__ = "1.2.3"
name = "mypackage"
description = "A test package"'
  assert_eq "1.2.3" "$("$TOOL_PATH" get -f setup.py)" "python __version__ auto-detection"
  assert_eq "1.3.0" "$("$TOOL_PATH" set -f setup.py 1.3.0)" "python __version__ set"
  assert_eq "1.3.0" "$("$TOOL_PATH" get -f setup.py)" "python __version__ get after set"
  
  # Test version variable (get → set → get)
  create_test_file "version.py" 'version = "2.0.0"
author = "Test User"
license = "MIT"'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f version.py)" "python version variable auto-detection"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f version.py 2.1.0)" "python version variable set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f version.py)" "python version variable get after set"
  
  # Test VERSION constant (get → set → get)
  create_test_file "constants.py" 'VERSION = "3.0.0"
DEBUG = True
MAX_RETRIES = 5'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f constants.py)" "python VERSION constant auto-detection"
  assert_eq "3.2.0" "$("$TOOL_PATH" set -f constants.py 3.2.0)" "python VERSION constant set"
  assert_eq "3.2.0" "$("$TOOL_PATH" get -f constants.py)" "python VERSION constant get after set"
  
  cleanup_test_dir
  echo
}

test_java_auto_detection() {
  _section_header "Java Auto-Detection"
  
  setup_test_dir
  
  # Test String VERSION pattern (get → set → get)
  create_test_file "App.java" 'public class App {
    String VERSION = "1.0.0";
    public static void main(String[] args) {
        System.out.println("Version: " + VERSION);
    }
}'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f App.java)" "java String VERSION auto-detection"
  assert_eq "1.2.0" "$("$TOOL_PATH" set -f App.java 1.2.0)" "java String VERSION set"
  assert_eq "1.2.0" "$("$TOOL_PATH" get -f App.java)" "java String VERSION get after set"
  
  # Test public static final pattern (get → set → get)
  create_test_file "Config.java" 'public class Config {
    public static final String VERSION = "2.0.0";
    private String name = "MyApp";
}'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f Config.java)" "java public static final auto-detection"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f Config.java 2.1.0)" "java public static final set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f Config.java)" "java public static final get after set"
  
  # Test private static final pattern (get → set → get)
  create_test_file "Version.java" 'public class Version {
    private static final String VERSION = "3.0.0";
    public String getVersion() { return VERSION; }
}'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f Version.java)" "java private static final auto-detection"
  assert_eq "3.1.0" "$("$TOOL_PATH" set -f Version.java 3.1.0)" "java private static final set"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f Version.java)" "java private static final get after set"
  
  cleanup_test_dir
  echo
}

test_kotlin_auto_detection() {
  _section_header "Kotlin Auto-Detection"
  
  setup_test_dir
  
  # Test const val VERSION pattern (get → set → get)
  create_test_file "App.kt" 'object AppConfig {
    const val VERSION = "1.0.0"
    const val NAME = "MyApp"
    
    fun getFullInfo() = "$NAME v$VERSION"
}'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f App.kt)" "kotlin const val VERSION auto-detection"
  assert_eq "1.2.0" "$("$TOOL_PATH" set -f App.kt 1.2.0)" "kotlin const val VERSION set"
  assert_eq "1.2.0" "$("$TOOL_PATH" get -f App.kt)" "kotlin const val VERSION get after set"
  
  # Test val version pattern (get → set → get)
  create_test_file "Version.kt" 'class Version {
    val version = "2.0.0"
    val buildNumber = 42
}'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f Version.kt)" "kotlin val version auto-detection"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f Version.kt 2.1.0)" "kotlin val version set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f Version.kt)" "kotlin val version get after set"
  
  # Test .kts file (get → set → get)
  create_test_file "build.gradle.kts" 'plugins {
    kotlin("jvm")
}

const val version = "3.0.0"

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib")
}'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f build.gradle.kts)" "kotlin .kts file auto-detection"
  assert_eq "3.1.0" "$("$TOOL_PATH" set -f build.gradle.kts 3.1.0)" "kotlin .kts file set"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f build.gradle.kts)" "kotlin .kts file get after set"
  
  cleanup_test_dir
  echo
}

test_json_auto_detection() {
  _section_header "JSON Auto-Detection"
  
  setup_test_dir
  
  # Test package.json (get → set → get)
  create_test_file "package.json" '{"version": "1.0.0", "name": "test"}'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f package.json)" "package.json auto-detection"
  assert_eq "1.5.0" "$("$TOOL_PATH" set -f package.json 1.5.0)" "package.json set"
  assert_eq "1.5.0" "$("$TOOL_PATH" get -f package.json)" "package.json get after set"
  
  # Test other JSON files (get → set → get)
  create_test_file "config.json" '{"app_version": "2.0.0"}'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f config.json)" "json app_version auto-detection"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f config.json 2.1.0)" "json app_version set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f config.json)" "json app_version get after set"
  
  cleanup_test_dir
  echo
}

test_yaml_auto_detection() {
  _section_header "YAML Auto-Detection"
  
  setup_test_dir
  
  # Test .yaml extension (get → set → get)
  create_test_file "config.yaml" 'version: 1.0.0
name: myapp
environment: production'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f config.yaml)" "yaml version auto-detection"
  assert_eq "1.1.0" "$("$TOOL_PATH" set -f config.yaml 1.1.0)" "yaml version set"
  assert_eq "1.1.0" "$("$TOOL_PATH" get -f config.yaml)" "yaml version get after set"
  
  # Test .yml extension (get → set → get)
  create_test_file "app.yml" 'app_version: 2.0.0
database:
  host: localhost
  port: 5432'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f app.yml)" "yml app_version auto-detection"
  assert_eq "2.2.0" "$("$TOOL_PATH" set -f app.yml 2.2.0)" "yml app_version set"
  assert_eq "2.2.0" "$("$TOOL_PATH" get -f app.yml)" "yml app_version get after set"
  
  # Test appVersion pattern (get → set → get)
  create_test_file "manifest.yaml" 'apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  appVersion: 3.0.0
  environment: staging'
  assert_eq "3.0.0" "$("$TOOL_PATH" get -f manifest.yaml)" "yaml appVersion auto-detection"
  assert_eq "3.1.0" "$("$TOOL_PATH" set -f manifest.yaml 3.1.0)" "yaml appVersion set"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f manifest.yaml)" "yaml appVersion get after set"
  
  cleanup_test_dir
  echo
}

test_stdin_support() {
  _section_header "Stdin Support"
  
  # Test stdin without pattern (generic version search)
  local result
  result=$(echo "1.2.3" | "$TOOL_PATH" get -f -)
  assert_eq "1.2.3" "$result" "stdin generic version search"
  
  # Test stdin with pattern
  result=$(echo "app_version: 2.0.0" | "$TOOL_PATH" get -f - -p "app_version:")
  assert_eq "2.0.0" "$result" "stdin with pattern"
  
  # Test complex content via stdin
  result=$(cat "$TOOL_PATH" | "$TOOL_PATH" get -f -)
  assert_eq "1.0.0" "$result" "stdin from actual script file"
  
  echo
}

test_simple_version_files() {
  _section_header "Simple Version Files (version.txt)"
  
  setup_test_dir
  
  # Test simple version file (get → set → get)
  create_test_file "version.txt" "1.5.0"
  assert_eq "1.5.0" "$("$TOOL_PATH" get -f version.txt)" "simple version file get"
  assert_eq "2.0.0" "$("$TOOL_PATH" set -f version.txt 2.0.0)" "simple version file set"
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f version.txt)" "simple version file get after set"
  
  # Test VERSION file (get → set → get)
  create_test_file "VERSION" "3.1.0"
  assert_eq "3.1.0" "$("$TOOL_PATH" get -f VERSION)" "VERSION file get"
  assert_eq "3.2.0" "$("$TOOL_PATH" set -f VERSION 3.2.0)" "VERSION file set"
  assert_eq "3.2.0" "$("$TOOL_PATH" get -f VERSION)" "VERSION file get after set"
  
  # Test version with pre-release (get → set → get)
  create_test_file "version.txt" "1.0.0-alpha.1"
  assert_eq "1.0.0-alpha.1" "$("$TOOL_PATH" get -f version.txt)" "pre-release version get"
  assert_eq "1.0.0-beta.2" "$("$TOOL_PATH" set -f version.txt 1.0.0-beta.2)" "pre-release version set"
  assert_eq "1.0.0-beta.2" "$("$TOOL_PATH" get -f version.txt)" "pre-release version get after set"
  
  cleanup_test_dir
  echo
}

test_generic_version_search() {
  _section_header "Generic Version Search (Complex Files)"
  
  setup_test_dir
  
  # Test finding first version in multi-line file (get → set → get)
  create_test_file "complex.txt" 'app version: 2.0.0
build: 123
other version: 3.0.0'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f complex.txt)" "first version in multi-line file get"
  assert_eq "2.5.0" "$("$TOOL_PATH" set -f complex.txt 2.5.0)" "first version in multi-line file set"
  assert_eq "2.5.0" "$("$TOOL_PATH" get -f complex.txt)" "first version in multi-line file get after set"
  
  cleanup_test_dir
  echo
}

test_fallback_behavior() {
  _section_header "Fallback Behavior"
  
  setup_test_dir
  
  # Test unknown extension falls back to shell patterns (get → set → get)
  create_test_file "config.conf" '# VERSION: 1.0.0'
  assert_eq "1.0.0" "$("$TOOL_PATH" get -f config.conf)" "unknown extension fallback to shell get"
  assert_eq "1.1.0" "$("$TOOL_PATH" set -f config.conf 1.1.0)" "unknown extension fallback to shell set"
  assert_eq "1.1.0" "$("$TOOL_PATH" get -f config.conf)" "unknown extension fallback to shell get after set"
  
  # Test file with no extension (get → set → get)
  create_test_file "myfile" 'VERSION="2.0.0"'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f myfile)" "no extension fallback to shell get"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f myfile 2.1.0)" "no extension fallback to shell set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f myfile)" "no extension fallback to shell get after set"
  
  # Test completely unknown format falls back to simple version file (get → set → get)
  create_test_file "unknown.xyz" '1.5.0'
  assert_eq "1.5.0" "$("$TOOL_PATH" get -f unknown.xyz)" "unknown format fallback to simple get"
  assert_eq "1.6.0" "$("$TOOL_PATH" set -f unknown.xyz 1.6.0)" "unknown format fallback to simple set"
  assert_eq "1.6.0" "$("$TOOL_PATH" get -f unknown.xyz)" "unknown format fallback to simple get after set"
  
  cleanup_test_dir
  echo
}
test_error_handling() {
  _section_header "Error Handling"
  
  setup_test_dir
  
  # Test file not found
  assert_fail "$TOOL_PATH" get -f nonexistent.txt "get nonexistent file fails"
  assert_fail "$TOOL_PATH" set -f nonexistent.txt 1.0.0 "set nonexistent file fails"
  
  # Test pattern not found
  create_test_file "test.txt" "no version here"
  assert_fail "$TOOL_PATH" get -f test.txt -p "version:" "get pattern not found error"
  assert_fail "$TOOL_PATH" set -f test.txt 1.0.0 -p "version:" "set pattern not found error"
  
  # Test missing arguments
  assert_fail "$TOOL_PATH" get "get missing file argument error"
  assert_fail "$TOOL_PATH" set "set missing arguments error"
  assert_fail "$TOOL_PATH" set -f test.txt "set missing version argument error"
  
  # Test invalid version format for set
  create_test_file "version.txt" "1.0.0"
  assert_fail "$TOOL_PATH" set -f version.txt "invalid" "set invalid version format error"
  assert_fail "$TOOL_PATH" set -f version.txt "1.2" "set incomplete version error"
  
  # Test stdin not supported for set
  assert_fail "$TOOL_PATH" set -f - 1.0.0 "set stdin not supported error"
  
  # Test invalid command
  assert_fail "$TOOL_PATH" invalid-command "invalid command error"
  
  cleanup_test_dir
  echo
}

test_cli_interface() {
  _section_header "Command Line Interface"
  
  # Test help
  local help_output
  help_output=$("$TOOL_PATH" -h 2>&1)
  assert_contains "$help_output" "ver-kit" "help shows tool name"
  assert_contains "$help_output" "USAGE:" "help shows usage"
  
  # Test version
  local version_output
  version_output=$("$TOOL_PATH" -v 2>&1)
  assert_contains "$version_output" "1.0.0" "version command works"
  
  # Test that invalid command options fail appropriately
  assert_fail "$TOOL_PATH" get -h "get -h fails (no subcommand help)"
  
  echo
}

test_real_world_examples() {
  _section_header "Real World Examples"
  
  setup_test_dir
  
  # Test realistic shell script (get → set → get)
  create_test_file "deploy.sh" '#!/bin/bash
# Deploy Script
# VERSION: 1.2.3
# Author: Test

set -e
echo "Deploying version $(cat version.txt)"'
  assert_eq "1.2.3" "$("$TOOL_PATH" get -f deploy.sh)" "realistic shell script get"
  assert_eq "1.3.0" "$("$TOOL_PATH" set -f deploy.sh 1.3.0)" "realistic shell script set"
  assert_eq "1.3.0" "$("$TOOL_PATH" get -f deploy.sh)" "realistic shell script get after set"
  
  # Test realistic Swift file (get → set → get)
  create_test_file "AppConfig.swift" 'import Foundation

struct AppConfig {
    static let version = "2.0.0"
    static let buildNumber = "42"
    
    static var fullVersion: String {
        return "\(version).\(buildNumber)"
    }
}'
  assert_eq "2.0.0" "$("$TOOL_PATH" get -f AppConfig.swift)" "realistic Swift file get"
  assert_eq "2.1.0" "$("$TOOL_PATH" set -f AppConfig.swift 2.1.0)" "realistic Swift file set"
  assert_eq "2.1.0" "$("$TOOL_PATH" get -f AppConfig.swift)" "realistic Swift file get after set"
  
  # Test realistic package.json (get → set → get)
  create_test_file "package.json" '{
  "name": "my-app",
  "version": "1.5.0",
  "description": "A test application",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}'
  assert_eq "1.5.0" "$("$TOOL_PATH" get -f package.json)" "realistic package.json get"
  assert_eq "1.6.0" "$("$TOOL_PATH" set -f package.json 1.6.0)" "realistic package.json set"
  assert_eq "1.6.0" "$("$TOOL_PATH" get -f package.json)" "realistic package.json get after set"
  
  cleanup_test_dir
  echo
}
##) tests

##( init
# Initialize test environment
ORIGINAL_PWD="$(pwd)"
TOOL_PATH="$(realpath "$TOOL")"

# Ensure cleanup happens even on script exit
trap cleanup_test_dir EXIT
##) init

##( core
# Run all tests
_test_runner
##) core