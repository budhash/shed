# loam

Generic bash stdlib: logging, os/arch detection, filesystem ops, ux prompts, and networking
(smart-download). Sourced by other shed tools rather than run directly.

## Description

`loam` is imported from the archived `radix` utility library (2,882 lines), with the
`radix.*` namespace renamed to `loam.*`. This import is a straight namespace rename — the
trim down to a minimal generic surface is deferred to a later pass. The file still contains
install/package handlers, hostname/plist/synthetic-mount helpers, clipboard, secrets/keychain,
encryption, and encoding wrappers that will eventually move out or be dropped; see
`radix/reference/loam-api.md` for the target v1 surface and rationale.

**Consumers:** shed tools, pkgman/pkglib, radix kickstart.

## Requirements

- **bash** 3.2+ (macOS system bash compatible)
- **Standard Unix tools** - varies by function (`curl`/`wget` for network, `tar`/`unzip`/`unar`
  for archives, `shasum`/`sha256sum` for checksums, `diskutil`/`security` for macOS-only
  helpers); each function degrades with a clear `$_E_DEP` error when its tool is missing
- **No external bash dependencies** - pure bash core

## Usage

```bash
source lib/common/loam/loam

loam.log "starting up"
loam.confirm "proceed?" && loam.mkdir /some/path
```

## Stability

**v1 stable API** = the documented table below (per `radix/reference/loam-api.md`). This is
the contract other tools should code against.

**All other functions in this file are LEGACY-UNSTABLE**: present for compatibility,
undocumented, and may be removed in a future major - do not depend on them. This includes
things like `loam.get-hostname`, `loam.set-hostname`, `loam.make-root-symlink`,
`loam.secret-*`, `loam.encrypt-aes`/`loam.decrypt-aes`, `loam.base64-*`, `loam.clip-*`,
`loam.str-random`/`loam.str-upper`/`loam.str-lower`, and the supporting helpers that the v1
functions happen to call internally (`loam.make-dir`, `loam.make-symlink`, `loam.readline`,
`loam.readchar`, `loam.get-input`, `loam.temp-*`, `loam.url-*`, `loam.smart-extract`,
`loam.extract`, `loam.install-dmg`, `loam.get-checksum`, `loam.verify-checksum`, etc.).

## v1 API

Namespace: public functions are `loam.*`. Error codes keep their existing `$_E*` names.

| Area | Functions | Notes |
|---|---|---|
| logging | `loam.log` `loam.warn` `loam.error` `loam.debug` `loam.die` | colored, timestamped; compat shims `_log` `_warn` `_error` `_debug` `_die` delegate to these (deprecated, call sites migrate over time) |
| errors | `$_E` `$_E_USG` `$_E_DEP` `$_E_NF` `$_E_NP` `$_E_OS` | exit-code contract, values unchanged from the archive |
| os | `loam.os` (mac\|linux) · `loam.arch` (arm64\|x86_64) · `loam.has <cmd>` | |
| fs | `loam.mkdir` | parents + ownership-aware |
| | `loam.symlink` | parent creation + force/backup semantics |
| | `loam.backup <file> <bakdir>` | one-time, timestamped backup-before-overwrite into a caller-given dir; NOT a versioning mechanism |
| | `loam.trash` | safe removal (-> Trash on mac, `~/.trash`/XDG trash fallback) |
| ux | `loam.confirm <prompt>` | y/N prompt; non-interactive stdin defaults to No (exit 1) |
| | `loam.read <prompt>` | prompted input |
| net | `loam.download <url> <dest>` | thin curl/wget wrapper (retries) |
| | `loam.smart-download …` | download + extract (tar/zip/7z/etc) + dmg mount/install + checksum verification - pkglib's engine |

## Explicitly out of scope (future trim)

- install/package handlers of any kind -> pkgman/pkglib
- hostname/plist/mount-point/synthetic.conf helpers -> kickstart-local (mac-specific, not generic)
- clipboard / base64 / AES / keychain wrappers, json/xml helpers -> dropped (thin wrappers over
  one-liners, or owner-specific)
- CLI arg parsing -> zap-sh templates own script CLI structure

## Testing

```bash
# Run tests
cd lib/common/loam && ./tests.sh

# Or from shed root
./.common/test-driver

# Or use Makefile
make test
```

## Versioning

loam ships with shed's `.common` test framework. Its API is semver'd against the v1 stable
table above (not the legacy-unstable surface):

- **additions** (new functions, new optional flags) -> minor bump
- **renames or removals** of anything in the v1 API table above -> major bump

## License

[MIT](../../../LICENSE) - see repository root for details.
