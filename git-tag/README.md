# git-tag

Git tag management with semantic versioning support for automated releases and development workflows.

## Description

A tool for managing Git tags based on semantic versioning. Can get the current tag, bump it using SemVer rules, preview changes, or set specific versions after validation. Integrates with sem-ver for version calculations and comparison.

**Key Features:**
- **SemVer 2.0.0 compliance** - Proper precedence rules and pre-release handling
- **Multiple operations** - Get current/latest tags, bump versions, preview changes
- **Pre-release workflows** - Support for alpha, beta, rc, and custom identifiers  
- **Tag validation** - Prevents invalid tags and backwards versioning
- **Dual tag concepts** - Highest semantic version vs. most recent chronological
- **Cross-platform** - Works on macOS (bash 3.2+) and Linux

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Git** - Repository operations and tag management

## Usage

```bash
# Basic usage
./git-tag <command> [OPTIONS] [ARGS...]

# Get help
./git-tag -h

# Check version
./git-tag -v
```

## Commands

### Core Operations
```bash
# Get version information
./git-tag current                   # v1.2.3 (highest semantic)
./git-tag latest                    # v1.2.0 (most recent chronological)
./git-tag next                      # v1.2.4 (preview next patch)
./git-tag next -b minor             # v1.3.0 (preview next minor)
./git-tag list                      # show all tags with metadata

# Create releases
./git-tag bump                      # v1.2.4 (patch release)
./git-tag bump -b minor             # v1.3.0 (minor release) 
./git-tag bump -b major             # v2.0.0 (major release)

# Set specific version
./git-tag set v2.1.0                # create specific tag
```

### Pre-release Workflows
```bash
# Start pre-release cycle
./git-tag bump -b minor -p alpha.1  # v1.3.0-alpha.1

# Iterate on pre-release
./git-tag bump -b pre -p alpha.2    # v1.3.0-alpha.2
./git-tag bump -b pre -p beta.1     # v1.3.0-beta.1
./git-tag bump -b pre -p rc.1       # v1.3.0-rc.1

# Finalize to stable release
./git-tag bump -b minor             # v1.3.0
```

### Preview Operations
```bash
# Dry run (preview only)
./git-tag bump -b major -d          # shows: v2.0.0
./git-tag next -b minor -p alpha.1  # shows: v1.3.0-alpha.1
```

## Options

### Global Options
- `-h` - Show help message
- `-v` - Show version information

### Next/Bump Options
- `-b <type>` - Bump type: `major`, `minor`, `patch`, `pre`
- `-p <id>` - Pre-release identifier (e.g., `alpha.1`, `rc.2`)
- `-d` - Dry run - show what would be created (bump only)

## Examples

### Basic Version Management
```bash
# Check current state
./git-tag current                   # v1.2.3
./git-tag latest                    # v1.2.1 (if created after v1.2.3)
./git-tag list                      # chronological list with dates

# Standard releases
./git-tag bump                      # v1.2.4 (patch)
./git-tag bump -b minor             # v1.3.0 (minor)
./git-tag bump -b major             # v2.0.0 (major)
```

### Development Workflows
```bash
# Preview workflow
./git-tag next                      # v1.2.4 (what's next)
./git-tag next -b minor             # v1.3.0 (preview minor)
./git-tag bump -b minor -d          # dry run: shows v1.3.0

# Pre-release development
./git-tag bump -b minor -p alpha.1  # v1.3.0-alpha.1 (start)
./git-tag next -b pre -p alpha.2    # v1.3.0-alpha.2 (preview)
./git-tag bump -b pre -p alpha.2    # v1.3.0-alpha.2 (create)
./git-tag bump -b pre -p beta.1     # v1.3.0-beta.1 (beta)
./git-tag bump -b minor             # v1.3.0 (finalize)
```

### CI/CD Integration
```bash
# Determine next version
NEXT_VERSION=$(./git-tag next -b patch)
echo "Would create: $NEXT_VERSION"

# Create release
NEW_TAG=$(./git-tag bump -b patch)
echo "Created: $NEW_TAG"
git push origin "$NEW_TAG"

# Validate before release
if ./git-tag bump -b patch -d >/dev/null; then
    echo "Ready to release"
else
    echo "Release validation failed"
fi
```

### Complex Scenarios
```bash
# Multi-stage pre-release workflow
./git-tag bump -b major -p alpha.1    # v2.0.0-alpha.1
./git-tag bump -b pre -p alpha.2      # v2.0.0-alpha.2 
./git-tag bump -b pre -p beta.1       # v2.0.0-beta.1
./git-tag bump -b pre -p rc.1         # v2.0.0-rc.1
./git-tag bump -b major               # v2.0.0

# Complex pre-release identifiers
./git-tag bump -b pre -p alpha.1.2.3  # v1.0.0-alpha.1.2.3
./git-tag bump -b pre -p build.123    # v1.0.0-build.123
```

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Git** - Repository operations
- **sem-ver tool** - Semantic version calculations (see Dependencies)

### Dependencies

The tool requires the `sem-ver` tool for version calculations. Set the path using:

```bash
# Environment variable
export SEM_VER="/path/to/sem-ver"

# Or relative path (default)
# Expects ../sem-ver/sem-ver relative to git-tag
```

## Installation

### From shed repository
```bash
# Use directly
./git-tag/git-tag -h

# Install to PATH
curl -o /usr/local/bin/git-tag https://raw.githubusercontent.com/yourusername/shed/main/git-tag/git-tag
chmod +x /usr/local/bin/git-tag
```

### Standalone
```bash
# Download and make executable
curl -O https://raw.githubusercontent.com/yourusername/shed/main/git-tag/git-tag
chmod +x git-tag

# Set up sem-ver dependency
curl -O https://raw.githubusercontent.com/yourusername/shed/main/sem-ver/sem-ver
chmod +x sem-ver
export SEM_VER="./sem-ver"

./git-tag -h
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

The test suite includes comprehensive coverage of all commands, edge cases, error handling, and integration scenarios.

## Semantic Versioning

This tool follows [Semantic Versioning 2.0.0](https://semver.org/) through integration with the `sem-ver` tool:

- Version format: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILDMETADATA]`
- Pre-release versions have lower precedence than normal versions
- Build metadata is ignored when determining version precedence
- All comparison and precedence logic handled by `sem-ver`

**Version precedence** (from lowest to highest):
```
v1.0.0-alpha < v1.0.0-alpha.1 < v1.0.0-beta < v1.0.0-beta.2 < v1.0.0-rc.1 < v1.0.0
```

**Tag concepts:**
- `current` - Highest semantic version tag
- `latest` - Most recently created tag (chronological)

## Error Handling

The tool validates all operations and provides specific error messages:

- Repository must be a Git repository
- New tags must be semantically higher than current highest
- Invalid version formats are rejected
- Duplicate tags are prevented
- Missing dependencies are detected

## License

[MIT](../LICENSE) - see repository root for details.

## Changelog

### v1.0.0
- Initial release with SemVer 2.0.0 compliance via sem-ver integration
- Core tag operations: current, latest, next, list, bump, set
- Complete pre-release workflow support (alpha, beta, rc, custom identifiers)
- Dual tag concepts: highest semantic version vs. most recent chronological
- Preview operations with dry run mode and next command
- Comprehensive validation and error handling
- Git repository integration with proper tag creation and annotation
- Cross-platform compatibility (macOS bash 3.2+ and Linux)
- Environment variable configuration for sem-ver tool path