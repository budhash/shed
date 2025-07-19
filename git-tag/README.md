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

## Dependencies

### Required Dependencies
**git-tag** depends on two components to function properly:

#### 1. Git Repository
- Must be run within a Git repository (`git init` if needed)
- Uses Git commands for tag creation, listing, and management
- Supports both local and remote Git repositories

#### 2. sem-ver Tool (Required)
**git-tag** delegates all version calculations to the **sem-ver** tool:

- **Version comparison** - Finding highest semantic version vs. chronological
- **Version bumping** - Calculating next major/minor/patch/pre-release versions  
- **Version validation** - Ensuring SemVer 2.0.0 compliance
- **Pre-release handling** - Complex pre-release precedence rules

**Automatic Discovery:**
git-tag automatically finds sem-ver in these locations (in order):
1. `$SEM_VER` environment variable (if set)
2. `../sem-ver/sem-ver` (standard shed structure)
3. `./sem-ver` (same directory as git-tag)

### Tool Relationship
```bash
# git-tag provides Git repository integration
./git-tag current                    # Find highest tag in repository
./git-tag bump -b minor              # Calculate + create new Git tag

# sem-ver provides version calculations (used internally by git-tag)
./sem-ver compare -c gt v1.3.0 v1.2.3  # Version comparison logic
./sem-ver bump -b minor v1.2.3         # Version calculation logic
```

**Why separate tools?**
- **git-tag**: High-level Git workflows (current, bump, list, set)
- **sem-ver**: Low-level version operations (compare, validate, parse)
- **Flexibility**: Use sem-ver standalone for non-Git version management
- **Modularity**: Each tool focused on its specific domain

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Git** - Repository operations and tag management
- **sem-ver tool** - Semantic version calculations (see Installation)

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

## Installation

### Option 1: Complete Shed Toolkit (Recommended)
Download both **git-tag** and **sem-ver** for full Git repository version management:

```bash
# Create shed directory
mkdir -p ~/.local/shed
cd ~/.local/shed

# Download both tools (git-tag requires sem-ver)
curl -O https://raw.githubusercontent.com/budhash/shed/main/git-tag/git-tag
curl -O https://raw.githubusercontent.com/budhash/shed/main/sem-ver/sem-ver

# Make executable
chmod +x git-tag sem-ver

# Add to PATH (add to your ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/shed:$PATH"

# Test installation
cd /path/to/your/git/repo
git-tag current                      # Should show current version
git-tag list                         # Should list existing tags
```

### Option 2: Shed Repository Structure
For development or to get all shed tools:

```bash
git clone https://github.com/budhash/shed.git
cd shed

# Use directly (tools auto-discover each other in shed structure)
./git-tag/git-tag current
./git-tag/git-tag bump -b patch

# Or install to PATH
sudo cp git-tag/git-tag /usr/local/bin/
sudo cp sem-ver/sem-ver /usr/local/bin/
```

### Option 3: Custom Installation Locations
If you need to install tools in different locations:

```bash
# Download tools to custom locations
curl -o /usr/local/bin/git-tag https://raw.githubusercontent.com/budhash/shed/main/git-tag/git-tag
curl -o /custom/path/sem-ver https://raw.githubusercontent.com/budhash/shed/main/sem-ver/sem-ver

chmod +x /usr/local/bin/git-tag /custom/path/sem-ver

# Configure sem-ver location for git-tag
export SEM_VER="/custom/path/sem-ver"

# Test configuration
git-tag current  # Should find sem-ver at custom location
```

### Docker/Container Usage
For containerized environments:

```bash
# Dockerfile example
FROM alpine:latest
RUN apk add --no-cache bash git curl

# Install both tools
RUN curl -o /usr/local/bin/git-tag https://raw.githubusercontent.com/budhash/shed/main/git-tag/git-tag && \
    curl -o /usr/local/bin/sem-ver https://raw.githubusercontent.com/budhash/shed/main/sem-ver/sem-ver && \
    chmod +x /usr/local/bin/git-tag /usr/local/bin/sem-ver

# Use in CI/CD
COPY . /workspace
WORKDIR /workspace
RUN git-tag current
```

### Troubleshooting Installation

**Issue: "missing dependency: sem-ver"**
```bash
# Check if sem-ver is in PATH
which sem-ver

# Check if sem-ver is executable
ls -la $(which sem-ver)

# Set custom location if needed
export SEM_VER="/path/to/sem-ver"
```

**Issue: "not in a git repository"**
```bash
# Initialize Git repo if needed
git init
git add .
git commit -m "Initial commit"

# Or cd to existing Git repository
cd /path/to/git/repo
```

## Testing

```bash
# Run tests (if cloned from repository)
cd git-tag && ./tests.sh

# Or test from shed root
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

## Advanced Usage

### Environment Configuration
```bash
# Custom sem-ver location
export SEM_VER="/path/to/custom/sem-ver"

# Enable debug logging
export DEBUG=true
git-tag current  # Shows debug information

# Disable colors
export NO_COLOR=1
git-tag list     # Plain text output
```

### Integration with Release Automation
```bash
#!/bin/bash
# Example release script

set -euo pipefail

# Get current version
CURRENT=$(git-tag current)
echo "Current version: $CURRENT"

# Determine bump type from commit messages since last tag
if git log "$CURRENT"..HEAD --oneline | grep -q "BREAKING CHANGE\|!:"; then
    BUMP_TYPE="major"
elif git log "$CURRENT"..HEAD --oneline | grep -q "feat:"; then
    BUMP_TYPE="minor"
else
    BUMP_TYPE="patch"
fi

echo "Determined bump type: $BUMP_TYPE"

# Preview the release
NEXT_VERSION=$(git-tag next -b "$BUMP_TYPE")
echo "Next version will be: $NEXT_VERSION"

# Confirm and create release
read -p "Create release $NEXT_VERSION? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    NEW_TAG=$(git-tag bump -b "$BUMP_TYPE")
    echo "Created release: $NEW_TAG"
    
    # Push to remote
    git push origin "$NEW_TAG"
    echo "Pushed $NEW_TAG to remote"
else
    echo "Release cancelled"
fi
```

### GitHub Actions Integration
```yaml
# .github/workflows/release.yml
name: Create Release
on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0  # Fetch all history for git-tag
        
    - name: Install shed tools
      run: |
        curl -o git-tag https://raw.githubusercontent.com/budhash/shed/main/git-tag/git-tag
        curl -o sem-ver https://raw.githubusercontent.com/budhash/shed/main/sem-ver/sem-ver
        chmod +x git-tag sem-ver
        
    - name: Create release
      run: |
        # Determine if we should release
        if git log --oneline HEAD~1..HEAD | grep -q "feat:\|fix:\|BREAKING CHANGE"; then
          # Determine bump type and create release
          if git log --oneline HEAD~1..HEAD | grep -q "BREAKING CHANGE"; then
            NEW_TAG=$(./git-tag bump -b major)
          elif git log --oneline HEAD~1..HEAD | grep -q "feat:"; then
            NEW_TAG=$(./git-tag bump -b minor)
          else
            NEW_TAG=$(./git-tag bump -b patch)
          fi
          
          echo "Created release: $NEW_TAG"
          git push origin "$NEW_TAG"
          
          # Create GitHub release
          gh release create "$NEW_TAG" --generate-notes
        else
          echo "No release needed"
        fi
      env:
        GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### GitHub Actions Flow Explanation

**Workflow Expectations:**
- **Conventional Commits**: Uses conventional commit messages to determine release type
- **Automatic Versioning**: Analyzes commit history to decide bump type (major/minor/patch)
- **Git Tag Creation**: Creates properly formatted semantic version tags
- **GitHub Release**: Automatically creates GitHub releases with generated notes

**Flow Breakdown:**

1. **Trigger**: Runs on every push to `main` branch
2. **History Analysis**: 
   - `BREAKING CHANGE` in commits → Major release (v1.0.0 → v2.0.0)
   - `feat:` commits → Minor release (v1.0.0 → v1.1.0)
   - `fix:` commits → Patch release (v1.0.0 → v1.0.1)
   - No matching commits → No release created
3. **Tag Creation**: Uses `git-tag bump` to create new semantic version tag
4. **Git Push**: Pushes new tag to remote repository
5. **GitHub Release**: Creates GitHub release with auto-generated release notes

**Prerequisites:**
- Repository must use [Conventional Commits](https://www.conventionalcommits.org/)
- `GH_TOKEN` with appropriate permissions for creating releases
- At least one existing tag in repository (or workflow will create v0.0.1)

**Customization Options:**
```yaml
# Custom commit message patterns
if git log --oneline HEAD~1..HEAD | grep -q "breaking:\|major:"; then
  NEW_TAG=$(./git-tag bump -b major)
elif git log --oneline HEAD~1..HEAD | grep -q "feature:\|minor:"; then
  NEW_TAG=$(./git-tag bump -b minor)
else
  NEW_TAG=$(./git-tag bump -b patch)
fi

# Pre-release workflow
if [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
  NEW_TAG=$(./git-tag bump -b minor -p alpha.$(date +%Y%m%d%H%M))
fi
```

### Makefile Integration
For projects using Make, integrate git-tag into your build process:

```makefile
# Get version from git-tag or fall back to default
VERSION := $(shell ./git-tag current 2>/dev/null | sed 's/^v//' || echo "0.0.0")
GIT_TAG_NAME := v$(VERSION)

.PHONY: tag-release version

## Show current version information
version:
    @echo "Current version: $(VERSION)"
    @echo "Git tag: $(GIT_TAG_NAME)"
    @./git-tag list | head -5

tag-release: ## 🔖  Create and push a git tag based on the .version file.
    @echo "🔖  Tagging release with version $(GIT_TAG_NAME)..."
    @if git rev-parse $(GIT_TAG_NAME) >/dev/null 2>&1; then \
        echo "ℹ️  Tag $(GIT_TAG_NAME) already exists. Skipping creation."; \
    else \
        git tag -a $(GIT_TAG_NAME) -m "Release $(VERSION)"; \
    fi
    @echo "📤  Pushing tag $(GIT_TAG_NAME) to remote..."
    @git push origin $(GIT_TAG_NAME)

## Create next version tag with git-tag
release-patch: 
    @./git-tag bump -b patch
    @$(MAKE) push-tags

release-minor:
    @./git-tag bump -b minor  
    @$(MAKE) push-tags

release-major:
    @./git-tag bump -b major
    @$(MAKE) push-tags

## Push all tags to remote
push-tags:
    @echo "📤  Pushing all tags to remote..."
    @git push --tags

## Preview next release version
next-version:
    @echo "Next patch: $(./git-tag next -b patch)"
    @echo "Next minor: $(./git-tag next -b minor)"
    @echo "Next major: $(./git-tag next -b major)"

help: ## 📚  Show this help message
    @echo "Available targets:"
    @grep -E '^[a-zA-Z_-]+:.*?## .*$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $1, $2}'
```

**Makefile Usage:**
```bash
# Show current version and recent tags
make version

# Create and push patch release
make release-patch

# Preview what the next versions would be
make next-version

# Traditional manual tag creation (using your existing target)
make tag-release

# Show all available targets
make help
```

**Makefile Benefits:**
- **Version consistency** - Single source of truth for version information
- **Release automation** - Simple `make release-patch` commands
- **Integration** - Works with existing build processes
- **Preview capability** - See what versions would be created
- **Flexibility** - Mix manual and automated approaches

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
- Robust dependency resolution with automatic sem-ver discovery
- Environment variable configuration for custom tool paths