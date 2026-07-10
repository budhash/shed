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
}

_test_runner
