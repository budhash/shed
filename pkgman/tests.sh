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
  local mgrs="brew apt dnf github download mas script cargo go pipx npm cask dmg"
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
  # --name=demo exercises the generic --key=value kwarg parser and must actually
  # flow through to pkglib: _cmd_add parses it into _kwargs_keys/_kwargs_values but
  # was never forwarding them to _cmd_add_unified, which re-split ITS OWN 12 fixed
  # params instead, writing bogus metadata (demo.script=default, demo.demo=false).
  # Now repaired: kwargs are forwarded and demo.name=demo lands in the index, so the
  # mock receives --name=demo and creates its marker as "demo" (not "mock-pkg").
  assert_ok $TOOL add script demo --source "$PWD/mocks/mock-pkg" --detail "demo pkg" --name=demo "add succeeds"
  assert_ok grep -q '^demo.manager=script' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "metadata written to index"
  assert_ok grep -q '^demo.name=demo' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "kwarg metadata forwarded correctly"
  assert_fail grep -q '^demo.script=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "no bogus demo.script metadata"
  assert_fail grep -q '^demo.demo=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "no bogus demo.demo metadata"
  assert_ok $TOOL install demo "install runs the mock"
  assert_file_exists "$MOCK_STATE/demo" "mock marker created with forwarded --name"
  assert_contains "$($TOOL status demo 2>&1)" "installed" "status sees installed"
}

test_tags_matcher() {
  _section_header "tag filter semantics"
  # assert_ok/assert_fail treat all-but-last args as an argv array (not a shell
  # string to re-parse), so each case is passed as separate unquoted tokens.
  assert_ok   $TOOL __tags-match ''               mac macmini "empty tags match all"
  assert_ok   $TOOL __tags-match 'mac,linux'      mac macmini "os tag matches"
  assert_fail $TOOL __tags-match 'linux'          mac macmini "wrong os rejected"
  assert_ok   $TOOL __tags-match 'mac,macmini'    mac macmini "host tag matches"
  assert_fail $TOOL __tags-match 'mac,laptop'     mac macmini "wrong host rejected"
  assert_ok   $TOOL __tags-match 'laptop,macmini' mac macmini "multi-host includes ours"
  assert_eq 0 "$(grep -cE '(^|[^A-Za-z_])hostname([^A-Za-z_-]|$)' ./pkgman)" "no hostname derivation in pkgman"
}

test_tags_metadata() {
  _section_header "tags metadata flows into index"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")
  assert_ok $TOOL add script tagged --source "$PWD/mocks/mock-pkg" --detail "tagged pkg" --tags=mac,laptop "add with tags succeeds"
  assert_ok grep -q '^tagged.tags=mac,laptop' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "tags metadata written to index"
  assert_ok $TOOL list-all "list-all still works"
  assert_ok $TOOL info tagged "info still works"
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

test_dmg_handler_delegates() {
  _section_header "dmg handler delegates to download"
  source ./pkglib
  for o in validate install update uninstall status; do
    assert_ok declare -F pkglib.dmg.$o "pkglib.dmg.$o exists"
  done
}

test_manifest_install() {
  _section_header "P1: manifest ingestion (install mode)"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")

  assert_ok $TOOL install ./mocks/fixture.manifest --host macmini "manifest install runs"
  assert_file_exists "$MOCK_STATE/alpha"   "untagged row installed"
  assert_file_exists "$MOCK_STATE/beta"    "matching host row installed"
  assert_file_exists "$MOCK_STATE/epsilon" "untagged row with version= kwarg installed"
  assert_ok test ! -f "$MOCK_STATE/gamma" "laptop-tagged row filtered out"
  assert_ok test ! -f "$MOCK_STATE/delta" "linux-tagged row filtered out on mac"

  assert_ok grep -q '^beta.tags=mac,macmini' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "tags persisted"
  assert_ok grep -q '^beta.manager=script' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "manager metadata persisted"
  assert_ok grep -q '^epsilon.version=1.2.3' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "applicable row's version= kwarg lands in the index"
  assert_ok grep -q '^beta.install_method=pkgman' "$PKGMAN_CONFIG_DIR/status.cfg" "install_method=pkgman recorded"
  assert_ok grep -q '^beta.status=installed' "$PKGMAN_CONFIG_DIR/status.cfg" "status=installed recorded"

  # idempotent second pass: already-tracked/installed rows are left alone, no failure
  assert_ok $TOOL install ./mocks/fixture.manifest --host macmini "second pass clean"
  assert_ok grep -q '^beta.status=installed' "$PKGMAN_CONFIG_DIR/status.cfg" "status remains installed after second pass"
  assert_contains "$($TOOL status beta 2>&1)" "installed" "status command still sees beta as installed"

  # unknown handler in a row warns + skips rather than aborting the manifest
  local _bad; _bad=$(mktemp "${TMPDIR:-/tmp}/bad-manifest-XXXXXX")
  printf 'zzz | not-a-real-handler | bogus | | \nalpha2 | script | mock A2 | source=./mocks/mock-pkg!name=alpha2 | \n' > "$_bad"
  assert_ok $TOOL install "$_bad" --host macmini "manifest with unknown handler row still exits 0"
  assert_file_exists "$MOCK_STATE/alpha2" "valid row after unknown-handler row still installed"
  rm -f "$_bad"

  # --host required for manifest mode
  assert_fail $TOOL install ./mocks/fixture.manifest "manifest without --host fails"
}

_test_runner
