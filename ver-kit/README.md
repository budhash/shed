# ver-kit

Universal version extraction and update toolkit for managing version information across multiple file types.

## Description

A tool for extracting and updating version information from various file formats. Uses generic search for fast version extraction and automatic pattern detection for precise updates.

**Key Features:**
- **Generic extraction** - GET finds versions in any file type with simple search
- **Smart updates** - SET auto-detects Shell, Swift, Python, Java, Kotlin, JSON, YAML for precise updates
- **Simple files** - Handles plain version files (version.txt) and complex structured files
- **Custom patterns** - Override detection for unsupported formats
- **Safe updates** - Atomic file operations with permission preservation
- **Cross-platform** - Works on macOS (bash 3.2+) and Linux

## Dependencies

**No external dependencies** - Pure bash implementation using standard Unix tools.

### Required Tools
- **bash** 3.2+ (for macOS compatibility) 
- **Standard Unix tools**: `sed`, `grep` (included in all Unix systems)

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **File permissions** - Read access for get operations, write access for set operations

## Usage

```bash
# Basic usage
./ver-kit <command> [OPTIONS]

# Get help
./ver-kit -h

# Check version
./ver-kit -v
```

## Commands

### Get Version Information
```bash
# Get version from various file types (generic search)
./ver-kit get -f version.txt              # 1.0.0 from simple version file
./ver-kit get -f script.sh                # Finds any version pattern (e.g. # VERSION: 1.2.3)
./ver-kit get -f main.py                  # Finds any version pattern (e.g. __version__ = "1.2.3")
./ver-kit get -f package.json             # Finds any version pattern (e.g. "version": "1.2.3")
./ver-kit get -f config.yaml              # Finds any version pattern (e.g. version: 1.2.3)

# Read from stdin
cat script.sh | ./ver-kit get -f -        # Generic search via stdin
echo "1.2.3" | ./ver-kit get -f -         # Simple version extraction
```

### Set Version Information  
```bash
# Update versions in various files (auto-detection)
./ver-kit set -f version.txt 1.1.0        # Update simple version file
./ver-kit set -f script.sh 2.0.0          # Auto-detects shell patterns
./ver-kit set -f main.py 1.5.0            # Auto-detects Python patterns
./ver-kit set -f Main.java 3.0.0          # Auto-detects Java patterns
./ver-kit set -f App.kt 2.1.0             # Auto-detects Kotlin patterns
./ver-kit set -f package.json 3.0.0       # Auto-detects JSON patterns
./ver-kit set -f config.yaml 2.1.0        # Auto-detects YAML patterns
```

### Custom Pattern Support
```bash
# Override automatic detection for custom formats
./ver-kit get -f config.yaml -p "app_version:"
./ver-kit set -f config.yaml -p "app_version:" 2.0.0

# Handle unsupported file types
./ver-kit get -f Dockerfile -p "ENV VERSION"
./ver-kit set -f Dockerfile -p "ENV VERSION" 1.5.0
```

## Options

### Global Options
- `-h` - Show help message
- `-v` - Show version information

### Command Options
- `-f FILE` - File to process (required, use `-` for stdin with get)
- `-p PATTERN` - Custom pattern for version detection/replacement (optional)

## Supported File Types

### Auto-Detection Patterns (SET Command Only)
When using `set` command without `-p` pattern, ver-kit auto-detects file types:

| File Type | Extensions | Pattern Examples | Sample Content |
|-----------|------------|------------------|----------------|
| **Shell Scripts** | `.sh`, `.bash` | `# VERSION:`, `VERSION=`, `version=` | `# VERSION: 1.2.3` |
| **Swift** | `.swift`, `Package.swift` | `let version =`, `static let version =` | `let version = "1.2.3"` |
| **Python** | `.py` | `__version__ =`, `version =` | `__version__ = "1.2.3"` |
| **Java** | `.java` | `String VERSION =`, `public static final String VERSION =` | `String VERSION = "1.2.3";` |
| **Kotlin** | `.kt`, `.kts` | `const val VERSION =`, `val version =` | `const val VERSION = "1.2.3"` |
| **JSON** | `.json`, `package.json` | `"version"`, `"app_version"` | `{"version": "1.2.3"}` |
| **YAML** | `.yaml`, `.yml` | `version:`, `app_version:` | `version: 1.2.3` |
| **Simple Files** | Any extension | First version found | `1.2.3` |

### GET Command Behavior
- **Generic search**: Finds first X.Y.Z pattern in any file type
- **Fast**: Single grep operation, no pattern loops  
- **Universal**: Works with any file containing version numbers

### SET Command Behavior
- **Auto-detection**: Uses above patterns for precise updates
- **Fallback**: Unknown files → shell patterns → simple version file
- **Precision**: Uses specific patterns for safe sed replacement

## Examples

### Basic Version Management
```bash
# Check current versions across a project
./ver-kit get -f version.txt              # 1.0.0
./ver-kit get -f src/main.py              # 1.0.0  
./ver-kit get -f package.json             # 1.0.0

# Update all versions consistently
./ver-kit set -f version.txt 1.1.0
./ver-kit set -f src/main.py 1.1.0
./ver-kit set -f package.json 1.1.0
```

### Script Integration
```bash
# Get current version for use in scripts
VERSION=$(./ver-kit get -f version.txt)
echo "Current version: $VERSION"

# Update version and verify
./ver-kit set -f version.txt 1.2.0
NEW_VERSION=$(./ver-kit get -f version.txt)
echo "Updated to: $NEW_VERSION"
```

### Cross-Language Projects
```bash
# Sync versions across multiple languages
PROJECT_VERSION="2.0.0"

./ver-kit set -f version.txt $PROJECT_VERSION
./ver-kit set -f src/main.py $PROJECT_VERSION        # Python
./ver-kit set -f src/main.swift $PROJECT_VERSION     # Swift
./ver-kit set -f src/Main.java $PROJECT_VERSION      # Java
./ver-kit set -f src/App.kt $PROJECT_VERSION         # Kotlin
./ver-kit set -f package.json $PROJECT_VERSION       # Node.js
./ver-kit set -f config.yaml $PROJECT_VERSION        # Configuration
```

### Custom Format Support
```bash
# Handle custom version formats
./ver-kit get -f docker-compose.yml -p "image.*:.*v"
./ver-kit set -f docker-compose.yml -p "image.*:.*v" 1.5.0

# Configuration files with custom patterns
./ver-kit get -f app.conf -p "APP_VERSION="
./ver-kit set -f app.conf -p "APP_VERSION=" 3.0.0

# Documentation files
./ver-kit get -f README.md -p "Version:"
./ver-kit set -f README.md -p "Version:" 2.1.0
```

### Manual Examples

**Simple version file:**
```bash
# File: version.txt
1.0.0

# Usage
./ver-kit get -f version.txt              # Output: 1.0.0
./ver-kit set -f version.txt 2.0.0        # Updates entire file to: 2.0.0
```

**Shell script with VERSION comment:**
```bash
# File: deploy.sh
#!/bin/bash
# VERSION: 1.0.0
echo "Deploying..."

# Usage
./ver-kit get -f deploy.sh                # Output: 1.0.0
./ver-kit set -f deploy.sh 1.1.0          # Updates to VERSION: 1.1.0
```

**Template with readonly __ID:**
```bash
# File: template.sh  
#!/usr/bin/env bash
readonly __ID="basic-1.0.0"
echo "Template version"

# Usage (updates the __ID line)
./ver-kit get -f template.sh              # Output: 1.0.0
./ver-kit set -f template.sh 1.2.0        # Updates to basic-1.2.0
```

### Validation and Safety
```bash
# ver-kit validates before updating
./ver-kit set -f my-app.py 2.0.0               # Succeeds if version pattern found
./ver-kit set -f unknown-format.txt 2.0.0      # Fails if no version detected

# Check if version can be detected before setting
if ./ver-kit get -f my-file.conf >/dev/null 2>&1; then
    ./ver-kit set -f my-file.conf 1.5.0
    echo "Version updated successfully"  
else
    echo "Cannot detect version pattern in my-file.conf"
    echo "Use -p option to specify custom pattern"
fi
```

## Installation

### From shed repository (Recommended)
```bash
# Download directly
curl -o ver-kit https://raw.githubusercontent.com/budhash/shed/main/ver-kit/ver-kit
chmod +x ver-kit
./ver-kit -h

# Install to PATH
sudo cp ver-kit /usr/local/bin/
```

### Project-specific installation
```bash
# Add to project scripts
mkdir -p scripts
curl -o scripts/ver-kit https://raw.githubusercontent.com/budhash/shed/main/ver-kit/ver-kit
chmod +x scripts/ver-kit

# Use in Makefile
sync-version:
  @VERSION=$$(scripts/ver-kit get -f version.txt); \
  scripts/ver-kit set -f src/main.py "$$VERSION"; \
  echo "Synced $$VERSION to all files"
```

## Testing

```bash
# Run tests (if cloned from repository)
cd ver-kit && ./tests.sh

# Or test from shed root
./.common/test-driver
```

The test suite includes comprehensive coverage of all file types, edge cases, and error handling.

## Version Format Support

ver-kit supports semantic versioning patterns and handles:

- **Core versions**: `1.2.3`
- **Pre-release versions**: `1.2.3-alpha.1`, `1.2.3-rc.2`  
- **Version prefixes**: `v1.2.3` (automatically handled)

**Validation**: Basic format validation ensures versions follow X.Y.Z pattern before setting.

## Advanced Usage

### Environment Integration
```bash
# Get version for use in other scripts
VERSION=$(./ver-kit get -f version.txt)
echo "Building version: $VERSION"

# Error handling
if ! ./ver-kit get -f my-file.conf >/dev/null 2>&1; then
    echo "Warning: Cannot detect version in my-file.conf"
    echo "Consider using: ./ver-kit get -f my-file.conf -p 'custom-pattern'"
fi

# Debug mode  
DEBUG=true ./ver-kit get -f complex-file.xml    # Shows debug information
```

### Build Integration
```bash
#!/bin/bash
# release.sh - Simple version management

set -euo pipefail

# Get current version
CURRENT=$(./ver-kit get -f version.txt)
echo "Current version: $CURRENT"

# Calculate new version (simple patch increment)
NEW_PATCH=$((${CURRENT##*.} + 1))
NEW_VERSION="${CURRENT%.*}.$NEW_PATCH"

echo "Updating to: $NEW_VERSION"

# Update all project files
./ver-kit set -f version.txt "$NEW_VERSION"
./ver-kit set -f src/main.py "$NEW_VERSION"
./ver-kit set -f package.json "$NEW_VERSION"

echo "✅ All files updated to $NEW_VERSION"
```

### CI/CD Integration
```yaml
# .github/workflows/version-sync.yml
name: Version Sync
on:
  push:
    paths: ['version.txt']
    
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      
    - name: Install ver-kit
      run: |
        curl -o ver-kit https://raw.githubusercontent.com/budhash/shed/main/ver-kit/ver-kit
        chmod +x ver-kit
        
    - name: Sync versions
      run: |
        VERSION=$(./ver-kit get -f version.txt)
        echo "Syncing version: $VERSION"
        
        # Update all project files
        ./ver-kit set -f src/main.py "$VERSION"
        ./ver-kit set -f package.json "$VERSION"
        
    - name: Commit if changed
      run: |
        if ! git diff --quiet; then
          git config user.name "Version Sync Bot"
          git config user.email "bot@example.com"
          git add -A
          git commit -m "Sync version files to $(./ver-kit get -f version.txt)"
          git push
        fi
```

## Error Handling

ver-kit provides clear error messages and safe operation:

- **File not found**: Clear error with file path
- **No version detected**: Suggests using `-p` for custom patterns
- **Invalid version format**: Shows expected format (X.Y.Z)
- **Permission errors**: Clear indication of access issues
- **Pattern validation**: Tests pattern before attempting updates

**Safe Operation**: All set operations validate the current version pattern before making changes, ensuring the pattern works correctly.

## License

[MIT](../LICENSE) - see repository root for details.

## Changelog

### v1.0.0
- Initial release with universal file type support
- Automatic pattern detection for Shell, Swift, Python, JSON, YAML
- Simple version file support (version.txt, VERSION, etc.)
- Custom pattern override capability for edge cases
- Safe atomic update operations with validation
- Cross-platform compatibility (macOS bash 3.2+ and Linux)
- File permission preservation during updates
- Comprehensive error handling and user guidance
- Pure bash implementation with no external dependencies