# shed 🔧

A collection of useful tools and scripts in various languages (mainly shell) covering different development purposes.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/budhash/shed/workflows/CI/badge.svg)](https://github.com/budhash/shed/actions)

## What's in the shed?

- **[`.template/`](.template/)** - Template for creating new tools (also tested)

## Philosophy

These are tools and scripts in various languages (mainly shell) covering different development purposes. Each tool is:
- **Generic** - Useful across different projects  
- **Long-term** - Built to last and remain relevant
- **Well-tested** - Includes comprehensive tests
- **Documented** - Each tool has its own README

## Quick Start

```bash
# Clone the shed
git clone https://github.com/budhash/shed.git
cd shed

# Use any tool directly
./${tool-name}/${tool-name} -h

# Or install individual tools to PATH
curl -o /usr/local/bin/${tool-name} https://raw.githubusercontent.com/budhash/shed/main/${tool-name}/${tool-name}
chmod +x /usr/local/bin/${tool-name}
```

## Tool Structure

Each tool follows a consistent structure:

```
tool-name/
├── tool-name       # The main executable script
├── tests.sh        # Test suite (sources common framework)
├── README.md       # Tool-specific documentation
└── examples/       # Usage examples (if applicable)

.template/          # Template files for new tools
├── template        # Template script
├── tests.sh        # Template test suite
└── README.md       # Template documentation

.common/            # Shared utilities and helper scripts
├── test-driver     # Test driver for all tools
└── test-common     # Common test framework (sourced by tests.sh)

tools.txt           # Tool registry (tool-name:description)
Makefile           # Build automation
tool-template       # Generated template script
```

## Using Individual Tools

Each tool is designed to work independently. Check the tool's README for specific usage:

```bash
# Get help for any tool
./${tool-name}/${tool-name} -h

# Read detailed documentation
cat ${tool-name}/README.md

# Run tests
cd ${tool-name} && ./tests.sh
```

## Installation Options

### Option 1: Use directly (no installation)
```bash
git clone https://github.com/budhash/shed.git
./${tool-name}/${tool-name} -h
```

### Option 2: Install individual tools
```bash
# Install specific tools to PATH
curl -o /usr/local/bin/${tool-name} https://raw.githubusercontent.com/budhash/shed/main/${tool-name}/${tool-name}
chmod +x /usr/local/bin/${tool-name}

# Or symlink from local clone
ln -s $(pwd)/${tool-name}/${tool-name} /usr/local/bin/
```

## Requirements

- **bash** 3.2+ (for macOS compatibility)
- **Standard Unix tools** (sed, awk, grep, etc.)
- **Tool-specific dependencies** - See individual tool READMEs

## License

The shed repository structure and shared utilities are licensed under [MIT](LICENSE).

**Note:** Individual tools may have their own specific licenses. Check each tool's directory for its license file if different from the repository default.

---

**🔧 Keep your shed stocked with useful tools! 🔧**