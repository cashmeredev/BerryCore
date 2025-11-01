# Python 3.11.10 for BlackBerry QNX

Full Python 3.11.10 interpreter compiled for ARM QNX.

## Installation

```bash
qpkg install python3
```

## Usage

```bash
# Run Python
python3

# Check version
python3 --version

# Install packages with pip
python3 -m pip install --user package_name

# Run HTTP server
python3 -m http.server 8000
```

## What's Included

- Python 3.11.10 interpreter
- Full standard library
- pip package manager (use: `python3 -m pip`)
- Development headers for building C extensions
- Tools: 2to3, idle3, pydoc3

## Environment

The wrapper script automatically sets `PYTHONHOME` to the correct location.

## More Info

- Python Documentation: https://docs.python.org/3.11/
- BerryCore: https://github.com/sw7ft/BerryCore

