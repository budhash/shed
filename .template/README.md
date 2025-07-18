# tool-name

Brief one-line description of what this tool does.

## Description

A more detailed description of the tool's purpose, what problems it solves, and why someone would want to use it. Replace this with your tool's actual description.

**Key Features:**
- **Feature 1** - Brief description of key capability
- **Feature 2** - Another important feature 
- **Feature 3** - What makes this tool unique
- **Cross-platform** - Works on macOS (bash 3.2+) and Linux

## Usage

```bash
# Basic usage
./tool-name <command> [OPTIONS] [ARGS...]

# Get help
./tool-name -h

# Check version
./tool-name -v
```

## Commands

### Core Operations
```bash
# Main commands
./tool-name command1                # Description of command1
./tool-name command2 -option value  # Description of command2 with options
./tool-name command3                # Description of command3
```

### Advanced Operations
```bash
# More complex commands (if applicable)
./tool-name advanced-cmd -flag      # Description
./tool-name process -input file     # Processing operations
```

## Options

### Global Options
- `-h` - Show help message
- `-v` - Show version information

### Command-Specific Options
- `-f, --file FILE` - Process specified file
- `-o, --output DIR` - Output directory
- `-d, --dry-run` - Preview operations without executing

## Examples

### Basic Usage
```bash
# Simple usage example
./tool-name command1

# With options
./tool-name command2 -f config.txt
```

### Workflow Examples
```bash
# Typical workflow
./tool-name command1                # Step 1
./tool-name command2 -f data.txt    # Step 2
./tool-name command3                # Step 3
```

### CI/CD Integration
```bash
# Use in automation
RESULT=$(./tool-name command1)
echo "Result: $RESULT"

# Validation in scripts
if ./tool-name validate input.txt; then
    echo "Input is valid"
    ./tool-name process input.txt
fi
```

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Standard Unix tools**: find, sed, grep, awk
- **Additional dependencies**: (list any tool-specific dependencies)

### Dependencies

If your tool depends on other tools in the shed:

```bash
# Set dependency paths
export DEPENDENCY_TOOL="/path/to/dependency"

# Or use relative paths (default)
# Expects ../dependency-tool/dependency-tool relative to tool-name
```

## Installation

### From shed repository
```bash
# Use directly
./tool-name/tool-name -h

# Install to PATH
curl -o /usr/local/bin/tool-name https://raw.githubusercontent.com/yourusername/shed/main/tool-name/tool-name
chmod +x /usr/local/bin/tool-name
```

### Standalone
```bash
# Download and make executable
curl -O https://raw.githubusercontent.com/yourusername/shed/main/tool-name/tool-name
chmod +x tool-name
./tool-name -h
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

This tool uses the shared test framework from `.common/test-common`. The test suite includes:
- **Standard tests**: Basic functionality, help/version flags, error handling
- **Custom tests**: Tool-specific functionality (add your own test functions)

### Test Framework
Available assertions: `assert_eq`, `assert_ok`, `assert_fail`, `assert_contains`, `assert_matches`, `assert_file_exists`, `assert_dir_exists`

Example custom test:
```bash
test_custom_functionality() {
  _section_header "Custom Feature Tests"
  
  assert_eq "expected" "$($TOOL_PATH command)" "command produces expected output"
  assert_ok $TOOL_PATH validate input.txt "validation succeeds"
  
  echo
}
```

## Error Handling

The tool validates inputs and provides specific error messages for:

- Invalid command-line arguments
- Missing required files or dependencies  
- Unsupported operations or formats
- (Add tool-specific validation details)

## License

[MIT](../LICENSE) - see repository root for details.

## Changelog

### v1.0.0
- Initial release with core functionality
- Support for main operations (list key features)
- Comprehensive validation and error handling
- Cross-platform compatibility (macOS bash 3.2+ and Linux)
- Integration with shed test framework