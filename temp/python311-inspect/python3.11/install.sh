#!/bin/sh

# Get the current directory where the install.sh script is located
INSTALL_DIR="$(cd "$(dirname "$0")"; pwd)"

# Define the Python binary path
PYTHON_BIN="$INSTALL_DIR/python3_ntoarmv7-qnx-static/tools/python3/python3"
PYTHON_HOME="$INSTALL_DIR/python3_ntoarmv7-qnx-static"

# Export PYTHONHOME
export PYTHONHOME="$PYTHON_HOME"

# Add PYTHONHOME to .profile if it doesn't already exist
if ! grep -q "PYTHONHOME" "$HOME/.profile"; then
    echo "export PYTHONHOME=\"$PYTHON_HOME\"" >> "$HOME/.profile"
    echo "PYTHONHOME added to .profile"
else
    echo "PYTHONHOME is already set in .profile"
fi

# Create a symlink for python3 in /usr/local/bin (or another directory in the PATH)
if [ -x "$PYTHON_BIN" ]; then
    sudo ln -sf "$PYTHON_BIN" /usr/local/bin/python3
    echo "Symlink for python3 created in /usr/local/bin"
else
    echo "Python binary not found or not executable: $PYTHON_BIN"
    exit 1
fi

# Verify installation
echo "Installation complete. Running 'python3 --version' to verify:"
python3 --version
