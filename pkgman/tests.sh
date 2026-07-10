#!/usr/bin/env bash
##( header
# Test Suite for pkgman (CLI) + pkglib (handlers)
##) header
set -euo pipefail
source ../.common/test-common
NAME="pkgman"; TOOL="./pkgman"

# CI insurance: no descendant process may ever block reading this suite's stdin
# (same failure class as a read-loop eating input — a hung child shows up as a
# killed CI job with truncated logs).
exec </dev/null

# TEMPORARY CI DIAGNOSTIC (remove after the macOS-lane kill is found): trace every
# section + exit into a file that ci.yml dumps in an always() step, immune to the
# stdout truncation seen when the job dies.
PKGTRACE="${PKGTRACE:-/tmp/pkgman-trace.log}"
: > "$PKGTRACE" || PKGTRACE=/dev/null
echo "SUITE START $(date +%s) bash=$BASH_VERSION" >> "$PKGTRACE"
trap 'echo "SUITE EXIT code=$? at ${FUNCNAME[0]:-main}" >> "$PKGTRACE"' EXIT
_section_header() {
  echo "SECTION: ${1:-?} $(date +%s)" >> "$PKGTRACE"
  echo -e "${_BLU}Testing: ${1:-?}${_RST}"
}

# Platform-parameterized fixtures: the committed mocks/fixture*.manifest are
# mac-flavored EXAMPLES. CI also runs on linux, where mac-tagged rows are
# (correctly) filtered by _tags_match — so mac-hardcoded expectations fail there.
# Tests therefore use generated copies carrying THIS platform's os tag, and the
# OTHER platform's tag for the row that must be filtered out (delta).
THIS_OS=$([ "$(uname)" = "Darwin" ] && echo mac || echo linux)
OTHER_OS=$([ "$THIS_OS" = "mac" ] && echo linux || echo mac)
FIX_A=$(mktemp "${TMPDIR:-/tmp}/fixture-a-XXXXXX")
FIX_B=$(mktemp "${TMPDIR:-/tmp}/fixture-b-XXXXXX")
sed -e "s/| mac,/| ${THIS_OS},/" -e "s/| linux[[:space:]]*\$/| ${OTHER_OS}/" ./mocks/fixture.manifest > "$FIX_A"
grep -v '^beta ' "$FIX_A" > "$FIX_B"

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

  assert_ok $TOOL install "$FIX_A" --host macmini "manifest install runs"
  assert_file_exists "$MOCK_STATE/alpha"   "untagged row installed"
  assert_file_exists "$MOCK_STATE/beta"    "matching host row installed"
  assert_file_exists "$MOCK_STATE/epsilon" "untagged row with version= kwarg installed"
  assert_ok test ! -f "$MOCK_STATE/gamma" "laptop-tagged row filtered out"
  assert_ok test ! -f "$MOCK_STATE/delta" "linux-tagged row filtered out on mac"

  assert_ok grep -q "^beta.tags=${THIS_OS},macmini" "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "tags persisted"
  assert_ok grep -q '^beta.manager=script' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "manager metadata persisted"
  assert_ok grep -q '^epsilon.version=1.2.3' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "applicable row's version= kwarg lands in the index"
  assert_ok grep -q '^beta.install_method=pkgman' "$PKGMAN_CONFIG_DIR/status.cfg" "install_method=pkgman recorded"
  assert_ok grep -q '^beta.status=installed' "$PKGMAN_CONFIG_DIR/status.cfg" "status=installed recorded"

  # idempotent second pass: already-tracked/installed rows are left alone, no failure
  assert_ok $TOOL install "$FIX_A" --host macmini "second pass clean"
  assert_ok grep -q '^beta.status=installed' "$PKGMAN_CONFIG_DIR/status.cfg" "status remains installed after second pass"
  assert_contains "$($TOOL status beta 2>&1)" "installed" "status command still sees beta as installed"

  # unknown handler in a row warns + skips rather than aborting the manifest
  local _bad; _bad=$(mktemp "${TMPDIR:-/tmp}/bad-manifest-XXXXXX")
  printf 'zzz | not-a-real-handler | bogus | | \nalpha2 | script | mock A2 | source=./mocks/mock-pkg!name=alpha2 | \n' > "$_bad"
  assert_ok $TOOL install "$_bad" --host macmini "manifest with unknown handler row still exits 0"
  assert_file_exists "$MOCK_STATE/alpha2" "valid row after unknown-handler row still installed"
  rm -f "$_bad"

  # --host required for manifest mode
  assert_fail $TOOL install "$FIX_A" "manifest without --host fails"
}

test_sync_prune() {
  _section_header "P1: sync --prune converges, never touches manual"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")
  assert_ok $TOOL install "$FIX_A" --host macmini "manifest install runs (alpha+beta+epsilon in)"
  assert_ok $TOOL add script manual1 --source "$PWD/mocks/mock-pkg" --detail m --name=manual1 "manual1 tracked add-only (never installed via pkgman)"

  # Honest precondition (the brief assumes add-only => literal install_method=manual;
  # in reality nothing sets install_method until a successful `install`, so an
  # add-only package has NO install_method key at all yet - see report). Either way
  # the property this safety test actually depends on is "not install_method=pkgman",
  # so that's what we assert here, against the real status file.
  assert_fail grep -q '^manual1.install_method=pkgman' "$PKGMAN_CONFIG_DIR/status.cfg" "manual1 precondition: not install_method=pkgman"

  # sync manifest-B (beta row removed): report-only without --prune
  local out; out=$($TOOL sync "$FIX_B" --host macmini 2>&1)
  assert_contains "$out" "beta" "undeclared beta reported"
  assert_file_exists "$MOCK_STATE/beta" "beta NOT removed without --prune"
  assert_ok grep -q '^beta.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "beta still tracked without --prune"

  # --dry-run --prune: prints the plan, performs no removal
  local dryout; dryout=$($TOOL sync "$FIX_B" --host macmini --prune --dry-run 2>&1)
  assert_contains "$dryout" "beta" "dry-run prune plan mentions beta"
  assert_file_exists "$MOCK_STATE/beta" "beta NOT removed under --dry-run --prune"
  assert_ok grep -q '^beta.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "beta still tracked under --dry-run --prune"

  # real prune, --force skips the confirm: beta uninstalled + untracked; alpha + manual1 untouched
  assert_ok $TOOL sync "$FIX_B" --host macmini --prune --force "prune runs"
  assert_ok test ! -f "$MOCK_STATE/beta" "beta uninstalled"
  assert_fail grep -q '^beta.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "beta untracked"
  assert_file_exists "$MOCK_STATE/alpha" "alpha survives"
  assert_ok grep -q '^manual1.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "manual package never pruned"

  # sync <manifest> without --host fails, same contract as install <manifest>
  assert_fail $TOOL sync "$FIX_B" "sync manifest without --host fails"
}

test_sync_prune_typo_handler_fails_safe() {
  _section_header "P1: sync --prune - typo'd handler still declares its package (fails safe)"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")
  assert_ok $TOOL install "$FIX_A" --host macmini "manifest install runs (alpha+beta+epsilon in)"
  assert_file_exists "$MOCK_STATE/alpha" "alpha installed before the typo'd re-sync"

  # Same rows as fixture.manifest, but alpha's handler is typo'd ('scritp' for
  # 'script'). A parse problem (unknown handler) must never escalate into a
  # destructive prune: _manifest_apply will warn+skip the row (can't install
  # it), but _manifest_declared_names must still count alpha as declared, so
  # prune leaves the already-installed/tracked package alone.
  local _typo; _typo=$(mktemp "${TMPDIR:-/tmp}/typo-manifest-XXXXXX")
  # Same rows as the generated FIX_A, but alpha's handler typo'd — derive from
  # FIX_A so the os tags stay platform-correct (see the fixture note at the top).
  sed 's/^alpha \([ ]*\)| script /alpha \1| scritp /' "$FIX_A" > "$_typo"
  assert_ok grep -q '| scritp ' "$_typo" "typo fixture sanity: alpha handler is typo'd"

  local out; out=$($TOOL sync "$_typo" --host macmini --prune --force 2>&1)
  assert_contains "$out" "unknown handler" "apply still warns about the typo'd handler"
  assert_file_exists "$MOCK_STATE/alpha" "alpha marker survives despite typo'd handler"
  assert_ok grep -q '^alpha.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "alpha still tracked in the index"
  rm -f "$_typo"
}

test_manifest_no_trailing_newline_last_row() {
  _section_header "P1: manifest with NO trailing newline - last row must not be dropped/pruned"
  setup_cfg
  export MOCK_STATE; MOCK_STATE=$(mktemp -d "${TMPDIR:-/tmp}/mock-XXXXXX")

  # `while IFS='|' read ...` silently drops a final line with no trailing
  # newline unless the loop condition also accepts the last (failed-read)
  # iteration. Build a manifest with printf '%s' (deliberately NO trailing
  # newline) whose LAST row is a script-mock package, and prove both that
  # `install` still installs it and that `sync --prune` never treats it as
  # undeclared (which would wrongfully uninstall a package that IS in the
  # file, just on its unterminated last line).
  local _man; _man=$(mktemp "${TMPDIR:-/tmp}/notrail-manifest-XXXXXX")
  printf '%s' "alpha9 | script | mock A9 | source=./mocks/mock-pkg!name=alpha9 |
zzz9   | script | mock Z9 | source=./mocks/mock-pkg!name=zzz9   |" > "$_man"
  assert_ok test -n "$(tail -c1 "$_man")" "fixture sanity: manifest has no trailing newline"

  assert_ok $TOOL install "$_man" --host macmini "install runs against no-trailing-newline manifest"
  assert_file_exists "$MOCK_STATE/alpha9" "first (newline-terminated) row installed"
  assert_file_exists "$MOCK_STATE/zzz9" "last (unterminated) row installed - not dropped by read"
  assert_ok grep -q '^zzz9.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "last row's package tracked in the index"

  # Now sync --prune --force against the SAME no-trailing-newline file. zzz9
  # IS declared (it's the last line) so it must survive prune.
  assert_ok $TOOL sync "$_man" --host macmini --prune --force "sync --prune runs against no-trailing-newline manifest"
  assert_file_exists "$MOCK_STATE/zzz9" "last (unterminated) row NOT pruned - still declared"
  assert_ok grep -q '^zzz9.manager=' "$PKGMAN_CONFIG_DIR/index/package.core.cfg" "last row's package still tracked after sync --prune"
  assert_file_exists "$MOCK_STATE/alpha9" "first row also survives prune"

  rm -f "$_man"
}

_test_runner
