# sem-ver

Semantic version bumping and management tool that tries to comply with SemVer 2.0.0.

## Description

A tool for bumping and comparing version strings according to the Semantic Versioning 2.0.0 specification. Supports standard versioning workflows from simple patches to pre-release management, with validation and parsing capabilities.

**Key Features:**
- **SemVer 2.0.0 compliance** - Handles precedence rules, pre-release comparison, and build metadata
- **Multiple interfaces** - Both verbose (`bump -b patch`) and shorthand (`patch`) syntax
- **Validation** - Specific error messages for invalid version formats
- **Pre-release workflows** - Support for alpha, beta, rc, and custom pre-release identifiers
- **Build metadata handling** - Proper handling and ignoring per SemVer specification
- **Cross-platform** - Works on macOS (bash 3.2+) and Linux

## Usage

```bash
# Basic usage
./sem-ver <command> [OPTIONS] [ARGS...]

# Get help
./sem-ver --help

# Check version
./sem-ver --version
```

## Commands

### Bump Operations
```bash
# Standard bumps
./sem-ver bump -b patch 1.2.3              # -> 1.2.4
./sem-ver bump -b minor 1.2.3              # -> 1.3.0  
./sem-ver bump -b major 1.2.3              # -> 2.0.0

# Shorthand syntax
./sem-ver patch 1.2.3                      # -> 1.2.4
./sem-ver minor 1.2.3                      # -> 1.3.0
./sem-ver major 1.2.3                      # -> 2.0.0

# Pre-release workflows
./sem-ver bump -b minor -p alpha.1 1.2.3   # -> 1.3.0-alpha.1
./sem-ver bump -b pre -p alpha.2 1.3.0-alpha.1  # -> 1.3.0-alpha.2
./sem-ver patch 1.3.0-alpha.2              # -> 1.3.0 (finalize)
```

### Comparison Operations
```bash
# Version comparisons
./sem-ver compare -c gt 2.0.0 1.9.9        # exit 0 (true)
./sem-ver compare -c lt 1.2.3 1.2.4        # exit 0 (true)
./sem-ver compare -c eq 1.2.3 1.2.3        # exit 0 (true)

# Shorthand syntax
./sem-ver gt 2.0.0 1.9.9                   # exit 0 (true)
./sem-ver lt 1.2.3 1.2.4                   # exit 0 (true)
./sem-ver eq 1.2.3 1.2.3                   # exit 0 (true)
```

### Validation and Parsing
```bash
# Validate version format
./sem-ver validate 1.2.3-alpha.1+build.1   # exit 0 (valid)
./sem-ver validate 1.2.3-                  # exit 1 (invalid)

# Parse version components
./sem-ver parse 1.2.3-alpha.1+build.1
# Output:
# Version: 1.2.3-alpha.1+build.1
# Major: 1
# Minor: 2
# Patch: 3
# Pre-release: alpha.1
# Build: build.1
```

## Options

### Global Options
- `-h, --help` - Show help message
- `-v, --version` - Show version information

### Bump Options
- `-b <type>` - Bump type: `major`, `minor`, `patch`, `pre`
- `-p <id>` - Pre-release identifier (e.g., `alpha.1`, `rc.2`)

### Compare Options
- `-c <op>` - Comparison operator: `gt` (>), `lt` (<), `eq` (=)

## Examples

### Basic Version Bumping
```bash
# Patch releases (bug fixes)
./sem-ver patch 1.2.3                      # -> 1.2.4
./sem-ver patch 1.2.3+build.1              # -> 1.2.4 (build metadata ignored)

# Minor releases (new features, backward compatible)
./sem-ver minor 1.2.3                      # -> 1.3.0

# Major releases (breaking changes)
./sem-ver major 1.2.3                      # -> 2.0.0
```

### Pre-release Workflows
```bash
# Start a new pre-release cycle
./sem-ver minor -p alpha.1 1.2.3           # -> 1.3.0-alpha.1

# Iterate on pre-release
./sem-ver pre -p alpha.2 1.3.0-alpha.1     # -> 1.3.0-alpha.2
./sem-ver pre -p beta.1 1.3.0-alpha.2      # -> 1.3.0-beta.1
./sem-ver pre -p rc.1 1.3.0-beta.1         # -> 1.3.0-rc.1

# Finalize pre-release to stable
./sem-ver patch 1.3.0-rc.1                 # -> 1.3.0
```

### Version Comparisons
```bash
# Basic comparisons
./sem-ver gt 2.0.0 1.9.9 && echo "2.0.0 is greater"

# Pre-release precedence
./sem-ver gt 1.0.0 1.0.0-alpha             # true (final > pre-release)
./sem-ver gt 1.0.0-beta 1.0.0-alpha        # true (beta > alpha)
./sem-ver gt 1.0.0-rc.11 1.0.0-rc.2        # true (numeric comparison)

# Build metadata is ignored
./sem-ver eq 1.2.3+build.1 1.2.3+build.2  # true (build metadata ignored)
```

### CI/CD Integration
```bash
# Determine next version in CI
CURRENT_VERSION="1.2.3"
NEXT_VERSION=$(./sem-ver minor "$CURRENT_VERSION")
echo "Next version: $NEXT_VERSION"

# Validate version format
if ./sem-ver validate "$VERSION"; then
    echo "Valid version: $VERSION"
else
    echo "Invalid version format: $VERSION"
    exit 1
fi
```

### Complex Scenarios
```bash
# Multi-stage development workflow
./sem-ver major 1.9.9                      # -> 2.0.0 (planning)
./sem-ver major -p alpha.1 1.9.9           # -> 2.0.0-alpha.1 (development)
./sem-ver pre -p alpha.2 2.0.0-alpha.1     # -> 2.0.0-alpha.2 (iteration)
./sem-ver pre -p beta.1 2.0.0-alpha.2      # -> 2.0.0-beta.1 (beta testing)
./sem-ver pre -p rc.1 2.0.0-beta.1         # -> 2.0.0-rc.1 (release candidate)
./sem-ver major 2.0.0-rc.1                 # -> 2.0.0 (final release)

# Complex pre-release identifiers
./sem-ver pre -p alpha.1.2.3 1.0.0-alpha.1.2.2    # -> 1.0.0-alpha.1.2.3
./sem-ver pre -p build.20241201 1.0.0-build.20241130  # -> 1.0.0-build.20241201
```

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Standard Unix tools**: `cut`, `sort`
- **No external dependencies** - Pure bash implementation

## Installation

### From shed repository
```bash
# Use directly
./sem-ver/sem-ver --help

# Install to PATH
curl -o /usr/local/bin/sem-ver https://raw.githubusercontent.com/yourusername/shed/main/sem-ver/sem-ver
chmod +x /usr/local/bin/sem-ver
```

### Standalone
```bash
# Download and make executable
curl -O https://raw.githubusercontent.com/yourusername/shed/main/sem-ver/sem-ver
chmod +x sem-ver
./sem-ver --help
```

## Testing

```bash
# Run tests
./tests.sh

# Or from shed root
./.common/test-driver

# Or use Makefile
make test
```

## SemVer 2.0.0 Compliance

This tool tries to follow the [Semantic Versioning 2.0.0](https://semver.org/) specification:

- Version format: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILDMETADATA]`
- Pre-release identifiers are compared lexically in ASCII sort order
- Build metadata is ignored when determining version precedence
- Pre-release versions have lower precedence than normal versions

**Precedence examples** (from lowest to highest):
```
1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0
```

## License

[MIT](../LICENSE) - see repository root for details.

## Changelog

### v1.0.0
- Initial release with SemVer 2.0.0 compliance
- Support for all bump types (major, minor, patch, pre)
- Comparison operations with proper precedence
- Version validation and component parsing
- Build metadata handling per specification
- Cross-platform compatibility (macOS bash 3.2+ and Linux)
- Both verbose and shorthand command syntax