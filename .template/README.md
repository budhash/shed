# tool-name

Brief one-line description of what this tool does.

## Description

A more detailed description of the tool's purpose, what problems it solves, and why someone would want to use it. Replace this with your tool's actual description.

## Usage

```bash
# Basic usage
./tool-name

# With options
./tool-name -f config.txt

# Get help
./tool-name -h

# Check version
./tool-name -v
```

## Options

- `-h` - Show help message
- `-v` - Show version information  
- `-f FILE` - Process specified file

## Examples

### Basic Example
```bash
# Simple usage example
./tool-name
```

### Advanced Example
```bash
# More complex usage example
./tool-name -f data.csv input_file
```

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Standard Unix tools**: find, sed, grep
- **Additional dependencies**: (list any tool-specific dependencies)

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
# Run tests (uses common test framework)
./tests.sh

# Or from shed root
./.common/test-driver

# Or use Makefile (recommended)
make test
```

This tool uses the shared test framework from `.common/test-common`. The test suite includes:
- **Standard tests**: Basic functionality, help/version flags, error handling
- **Custom tests**: Tool-specific functionality (add your own in `test_custom_functionality`)

Available assertions: `assert_eq`, `assert_ok`, `assert_fail`, `assert_contains`, `assert_matches`, `assert_file_exists`, `assert_dir_exists`

## License

[MIT](../LICENSE) - see repository root for details.