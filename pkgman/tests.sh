#!/usr/bin/env bash
##( header
# Test Suite for pkgman (CLI) + pkglib (handlers)
##) header
set -euo pipefail
source ../.common/test-common
NAME="pkgman"; TOOL="./pkgman"

test_pkglib_loads() {
  _section_header "pkglib sources + full handler matrix"
  assert_ok bash -n ./pkglib "pkglib syntax"
  # shellcheck disable=SC1091
  source ./pkglib
  local mgrs="brew apt dnf github download mas script cargo go pipx npm"
  local ops="validate install update uninstall status"
  local m o
  for m in $mgrs; do for o in $ops; do
    assert_ok declare -F "pkglib.$m.$o" "pkglib.$m.$o exists"
  done; done
  assert_ok declare -F pkglib.common.install "common template present"
  assert_ok declare -F pkglib.common.update "common template present"
  assert_ok declare -F pkglib.common.uninstall "common template present"
  assert_ok declare -F loam.confirm "pkglib provides loam.confirm"
}

setup_cfg() { PKGMAN_CONFIG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pkgman-cfg-XXXXXX"); export PKGMAN_CONFIG_DIR; }

test_cli_basics() {
  _section_header "CLI basics"
  setup_cfg
  assert_ok $TOOL version "version exits 0"
  assert_ok $TOOL help "help exits 0"
  assert_contains "$($TOOL help 2>&1)" "install-all" "help mentions install-all"
  assert_fail $TOOL definitely-not-a-cmd "unknown command fails"
}

_test_runner
