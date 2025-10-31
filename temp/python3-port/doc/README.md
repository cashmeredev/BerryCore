# Python 3.11.10 for BlackBerry QNX

Full Python 3.11.10 interpreter compiled for ARM QNX.

## What's Included

- **Python 3.11.10** - Full interpreter with standard library
- **pip & ensurepip** - Package installer
- **Complete stdlib** - All standard Python modules
- **Development headers** - For compiling Python C extensions
- **Tools** - 2to3, pydoc3, idle3, python3-config

## Installation

```bash
qpkg install python3
```

This will install Python 3 to your BerryCore directory and add it to your PATH.

## Usage

### Running Python

```bash
# Interactive Python shell
python3

# Run a Python script
python3 script.py

# Run a module
python3 -m module_name

# Check version
python3 --version
```

### Installing Packages with pip

```bash
# Install a package
python3 -m pip install requests

# Install with user flag (recommended on QNX)
python3 -m pip install --user beautifulsoup4

# List installed packages
python3 -m pip list

# Upgrade pip itself
python3 -m pip install --upgrade pip
```

### Using Python Tools

```bash
# Convert Python 2 code to Python 3
2to3 old_script.py

# View Python documentation
pydoc3 requests

# Python configuration (for building extensions)
python3-config --includes
```

## Environment Variables

The Python wrapper automatically sets:
- `PYTHONHOME` - Points to Python installation root
- `LD_LIBRARY_PATH` - Includes Python lib directory

## Dependencies

Python 3.11 requires these libraries (should be present on QNX):
- bzip2
- expat
- libffi
- liblzma (xz)
- OpenSSL
- readline
- sqlite3
- zlib

## Notes

### Replacing Existing Python 3

This port will replace any existing `python3` installation. If you need to keep an older Python 3, rename it before installing this port.

### Coexistence with Python 2

This port uses `python3` and will not conflict with `python` (Python 2.x) if installed.

### Static Build

This is a statically-linked build for maximum compatibility on QNX systems.

### Available Modules

Check available modules:
```python
python3 -c "help('modules')"
```

Common modules included:
- asyncio, json, re, os, sys, subprocess
- urllib, http, email, sqlite3
- ssl, hashlib, hmac, secrets
- argparse, logging, unittest
- And hundreds more!

## Troubleshooting

### pip not working

```bash
# Reinstall pip
python3 -m ensurepip --upgrade --user
```

### Module not found

Check if module is in stdlib:
```bash
python3 -c "import module_name; print(module_name.__file__)"
```

### Permission denied

Use `--user` flag with pip:
```bash
python3 -m pip install --user package_name
```

## Examples

### Simple HTTP Server
```bash
# Serve current directory on port 8000
python3 -m http.server 8000
```

### JSON Pretty Print
```bash
echo '{"name":"test"}' | python3 -m json.tool
```

### Quick Calculator
```python
python3 -c "print(2**16)"
```

## Version Info

- **Python:** 3.11.10
- **Architecture:** ntoarmv7-qnx-static
- **Build Date:** September 2024
- **Installed Size:** ~62MB

## More Information

- Python Documentation: https://docs.python.org/3.11/
- Python Package Index: https://pypi.org/
- BerryCore: https://github.com/sw7ft/BerryCore

