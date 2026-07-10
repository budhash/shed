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
  local mgrs="brew apt dnf github download mas script cargo go pipx npm cask"
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

test_add_and_install() {
  _section_header "P0: add + install via script handler"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")
  # --name=demo exercises the generic --key=value kwarg parser (must not crash the
  # add command), but a pre-existing, out-of-scope bug in _cmd_add_unified never
  # forwards kwargs on to pkglib, so the mock still falls back to its own default
  # name ("mock-pkg") for the marker file.
  assert_ok $TOOL add script demo --source "$PWD/mocks/mock-pkg" --detail "demo pkg" --name=demo "add succeeds"
  assert_ok grep -q '^demo.manager=script' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "metadata written to index"
  assert_ok $TOOL install demo "install runs the mock"
  assert_file_exists "$MOCK_STATE/mock-pkg" "mock marker created"
  assert_contains "$($TOOL status demo 2>&1)" "installed" "status sees installed"
}

test_download_status_precedence() {
  _section_header "pkglib.download.status: file/dir/missing"
  source ./pkglib
  local d; d=$(mktemp -d "${TMPDIR:-/tmp}/dl-XXXXXX")
  touch "$d/f"; mkdir "$d/dir"
  assert_eq "installed" "$(pkglib.download.status f false --dest="$d" --artifact=f)"    "file → installed"
  assert_eq "installed" "$(pkglib.download.status dir false --dest="$d" --artifact=dir)" "dir → installed"
  assert_eq "missing"   "$(pkglib.download.status nope false --dest="$d" --artifact=nope)" "absent → missing"
  rm -rf "$d"
}

test_smoke_all_subcommands() {
  _section_header "P0: --dry-run=cmd smoke across the router"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")
  $TOOL add script demo --source "$PWD/mocks/mock-pkg" --detail demo --name=demo >/dev/null

  local c
  for c in list-all list-packages list-scopes "status demo" "info demo" \
           "install demo" "update demo" "sync demo" "uninstall demo" \
           install-all update-all sync-all "remove demo"; do
    # shellcheck disable=SC2086  # intentional word-splitting: $c is a command+args string built above
    assert_ok $TOOL --dry-run=cmd $c "dry-run=cmd: $c"
  done

  # provision brew resolves its "pkgboot" script source via pkglib's search path
  # (../bin, ../ins, $HOME/.local/bin, /usr/local/bin, PATH) - none of which include
  # this repo's pkgman/pkgboot. Make the test hermetic with a scratch HOME instead of
  # touching the real ~/.local/bin (see Task 5's report for the same finding).
  local _scratch_home; _scratch_home=$(mktemp -d "${TMPDIR:-/tmp}/pkgboot-home-XXXXXX")
  mkdir -p "$_scratch_home/.local/bin"
  ln -s "$PWD/pkgboot" "$_scratch_home/.local/bin/pkgboot"
  HOME="$_scratch_home" assert_ok $TOOL --dry-run=cmd provision brew "dry-run=cmd: provision brew"
}

test_cask_handler() {
  _section_header "cask handler via fake brew"
  source ./pkglib
  local fake; fake=$(mktemp -d "${TMPDIR:-/tmp}/fakebrew-XXXXXX")
  cat > "$fake/brew" <<'EOF'
#!/bin/bash
echo "BREW $*" >> "${FAKE_BREW_LOG:?}"
case "$1" in list) exit 1;; *) exit 0;; esac
EOF
  chmod +x "$fake/brew"
  export FAKE_BREW_LOG="$fake/log"

  # Save original PATH and restore it after test
  local _orig_path="$PATH"
  PATH="$fake:$PATH"

  pkglib.cask.install somecask false >/dev/null 2>&1 || true
  assert_ok grep -q 'BREW install --cask somecask' "$FAKE_BREW_LOG" "install maps to brew install --cask"
  assert_eq "missing" "$(pkglib.cask.status somecask false)" "status missing when list fails"

  # Restore PATH
  PATH="$_orig_path"

  # Cleanup
  rm -rf "$fake"
}

_test_runner
