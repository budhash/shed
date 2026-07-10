#!/usr/bin/env bash
##( header
# Test Suite for loam — generic bash stdlib
##) header
set -euo pipefail
source ../../../.common/test-common
NAME="loam"; TOOL="./loam"

test_source_and_api() {
  _section_header "loam sources cleanly + v1 API present"
  assert_ok bash -n ./loam "syntax check"
  # shellcheck disable=SC1091
  source ./loam
  for f in loam.log loam.warn loam.error loam.debug loam.die \
           loam.os loam.arch loam.has loam.mkdir loam.symlink loam.backup \
           loam.trash loam.confirm loam.read loam.download loam.smart-download \
           _log _error; do
    assert_ok declare -F "$f" "function exists: $f"
  done
  for v in _E _E_USG _E_DEP _E_NF _E_NP _E_OS; do
    assert_ok [ -n "${!v:-}" ] "error code set: \$$v"
  done
  assert_eq 0 "$(grep -c 'radix\.' ./loam)" "no radix.* remnants"
}

test_behavior() {
  _section_header "loam behaviors"
  source ./loam
  local d; d=$(mktemp -d "${TMPDIR:-/tmp}/loam-XXXXXX")
  assert_eq "mac" "$( [ "$(uname)" = Darwin ] && loam.os || echo mac )" "loam.os on this platform"
  loam.mkdir "$d/a/b";            assert_dir_exists "$d/a/b" "loam.mkdir makes parents"
  echo hi > "$d/f"; loam.symlink "$d/f" "$d/ln"
  assert_eq "hi" "$(cat "$d/ln")" "loam.symlink links"
  loam.backup "$d/f" "$d/bak";    assert_ok ls "$d/bak" "loam.backup wrote a copy"
  assert_fail loam.confirm 'proceed?' "confirm defaults to No non-interactively" </dev/null
  assert_ok  loam.has bash "loam.has finds bash"
  assert_fail loam.has definitely-not-a-cmd-xyz "loam.has misses absent cmd"
  rm -rf "$d"
}

_test_runner
