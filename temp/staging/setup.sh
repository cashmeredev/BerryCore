#!/bin/bash

# Set up directories
APPS_DIR=~/apps
TASKAPP_DIR="$APPS_DIR/taskapp"
PROFILE_FILE=~/.profile
BACKUP_PROFILE="$PROFILE_FILE.bak"
LOG_FILE="$TASKAPP_DIR/taskapp.log"
TASKAPP_START_COMMAND="python3 \"$TASKAPP_DIR/taskapp.py\" >> \"$LOG_FILE\" 2>&1 &"
TASKAPP_START_MARKER="# <<< TaskApp Start >>>"
TASKAPP_STOP_MARKER="# <<< End TaskApp Start >>>"

# Function to create a backup of .profile
backup_profile() {
    if [ ! -f "$BACKUP_PROFILE" ]; then
        cp "$PROFILE_FILE" "$BACKUP_PROFILE"
        echo "Backup of .profile created at $BACKUP_PROFILE."
    else
        echo "Backup of .profile already exists at $BACKUP_PROFILE."
    fi
}

# Function to append TaskApp start command and the custom message to .profile
append_to_profile() {
    echo "" >> "$PROFILE_FILE"
    echo "$TASKAPP_START_MARKER" >> "$PROFILE_FILE"
    echo "$TASKAPP_START_COMMAND" >> "$PROFILE_FILE"
    echo "$TASKAPP_STOP_MARKER" >> "$PROFILE_FILE"
    
    # === Added Section: CLI Apps PATH and Library Path Setup ===
    echo "" >> "$PROFILE_FILE"
    echo "# CLI Apps PATH and Library Path Setup" >> "$PROFILE_FILE"
    echo 'export PATH="$HOME/usr/local/bin:$PATH"' >> "$PROFILE_FILE"
    echo 'export LD_LIBRARY_PATH="$HOME/usr/local/lib:$LD_LIBRARY_PATH"' >> "$PROFILE_FILE"
    # === End of CLI Apps Setup ===
    
    # === Added Section: Display custom message on terminal startup ===
    echo "" >> "$PROFILE_FILE"
    echo "# Display Task Manager URL" >> "$PROFILE_FILE"
    echo 'echo "Manage apps @ http://127.0.0.1:8001 "' >> "$PROFILE_FILE"
    # === End of Added Section ===
    
    # === Added Section: Clear Screen Function and Aliases ===
    echo "" >> "$PROFILE_FILE"
    echo "# Clear Screen Function and Aliases" >> "$PROFILE_FILE"
    echo 'clear_screen() {' >> "$PROFILE_FILE"
    echo '    printf '"'"'\033[2J\033[H'"'"'' >> "$PROFILE_FILE"
    echo '}' >> "$PROFILE_FILE"
    echo "" >> "$PROFILE_FILE"
    echo 'alias cls='"'"'printf "\033[2J\033[H"'"'"'' >> "$PROFILE_FILE"
    echo 'alias clear='"'"'printf "\033[2J\033[H"'"'"'' >> "$PROFILE_FILE"
    # === End of Clear Screen Section ===

    echo "Added TaskApp start command, CLI paths, custom message, system stats, and clear aliases to $PROFILE_FILE."
}

# Create Apps directory if it doesn't exist
mkdir -p "$APPS_DIR"

# Download and install Python
echo "Downloading Python package..."
curl -O https://berrystore.sw7ft.com/python/python3.11/python3_ntoarmv7-qnx-static.zip

echo "Downloading Python installation script..."
curl -O https://berrystore.sw7ft.com/python/python3.11/install.sh

echo "Setting permissions for installation script..."
chmod +x install.sh

echo "Unzipping Python package..."
unzip -o python3_ntoarmv7-qnx-static.zip

echo "Installing Python..."
./install.sh

# Reload environment to pick up Python installation changes
echo "Reloading environment after Python installation..."
if [ -f "$HOME/.profile" ]; then
    source "$HOME/.profile"
fi

# Also check if Python install script created any environment files we should source
if [ -f "./env.sh" ]; then
    source "./env.sh"
fi

# Update PATH to ensure we can find python3
export PATH="$HOME/usr/local/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/usr/local/lib:$LD_LIBRARY_PATH"

# Verify Python is now accessible
echo "Verifying Python is accessible in current environment..."
which python3 && python3 --version
if [ $? -ne 0 ]; then
    echo "WARNING: Python3 not found in PATH after installation."
    echo "Current PATH: $PATH"
    echo "Attempting to locate python3..."
    find "$HOME" -name "python3" -type f 2>/dev/null | head -5
fi

ensure_pip() {
    # Ensure pip is available using Python's built-in ensurepip module only.
    # More robust approach with retries and selective cleanup of pip installations only.
    
    # First, verify Python is working properly
    echo "Verifying Python installation..."
    if ! python3 -c "import sys, os, random; print('Python basic modules working')" 2>/dev/null; then
        echo "Python installation appears to be corrupted or incomplete." >&2
        echo "" >&2
        echo "Would you like to completely remove Python and start fresh?" >&2
        echo "This will delete ~/apps/, ~/usr/, and the python directory." >&2
        echo "Type 'yes' to remove and restart, or 'no' to exit:" >&2
        read -r response
        
        if [ "$response" = "yes" ] || [ "$response" = "YES" ] || [ "$response" = "y" ] || [ "$response" = "Y" ]; then
            echo "Removing Python installation directories..."
            rm -rf ~/apps/ ~/usr/ python3* *.zip *.sh 2>/dev/null || true
            echo ""
            echo "Python installation has been completely removed."
            echo "Please restart your phone and run this script again."
            echo ""
            exit 0
        else
            echo "Installation cancelled. Please fix Python manually or restart your phone." >&2
            exit 1
        fi
    fi
    
    # Check if pip is already working properly
    if python3 -m pip --version >/dev/null 2>&1 && python3 -m pip list >/dev/null 2>&1; then
        echo "pip is already installed and working properly."
        return 0
    fi
    
    # Clean up only pip-related directories (not core Python modules)
    echo "Cleaning up any broken pip installations..."
    python3 -c "
import sys, os, shutil
try:
    import site
    for path in site.getsitepackages() + [site.getusersitepackages()]:
        if path and os.path.exists(path):
            # Only remove pip, setuptools, and wheel directories - leave core Python modules alone
            for name in ['pip', 'pip-', 'setuptools', 'setuptools-', 'wheel', 'wheel-']:
                for item in os.listdir(path):
                    if item.startswith(name) and os.path.isdir(os.path.join(path, item)):
                        try:
                            shutil.rmtree(os.path.join(path, item))
                            print(f'Removed broken pip component: {item}')
                        except:
                            pass
except Exception as e:
    pass
" 2>/dev/null || true

    # Try ensurepip with retries
    for attempt in 1 2 3; do
        echo "Attempting to install pip via ensurepip (attempt $attempt/3)..."
        
        # Try --upgrade first
        if python3 -m ensurepip --upgrade --user 2>/dev/null; then
            echo "pip successfully installed via ensurepip --upgrade --user."
            break
        fi
        
        # Try --default-pip as fallback
        if python3 -m ensurepip --default-pip --user 2>/dev/null; then
            echo "pip successfully installed via ensurepip --default-pip --user."
            break
        fi
        
        # Try without --user flag
        if python3 -m ensurepip --upgrade 2>/dev/null; then
            echo "pip successfully installed via ensurepip --upgrade."
            break
        fi
        
        if python3 -m ensurepip --default-pip 2>/dev/null; then
            echo "pip successfully installed via ensurepip --default-pip."
            break
        fi
        
        # If this isn't the last attempt, wait and try again
        if [ $attempt -lt 3 ]; then
            echo "ensurepip attempt $attempt failed, waiting 2 seconds before retry..."
            sleep 2
        fi
    done
    
    # Final comprehensive verification
    echo "Verifying pip installation..."
    if python3 -m pip --version >/dev/null 2>&1; then
        echo "pip version check passed."
        if python3 -m pip list >/dev/null 2>&1; then
            echo "pip list command works - installation verified."
            return 0
        else
            echo "pip installed but 'pip list' fails - attempting repair..."
            python3 -m ensurepip --upgrade --force-reinstall 2>/dev/null || true
            if python3 -m pip list >/dev/null 2>&1; then
                echo "pip repair successful."
                return 0
            fi
        fi
    fi
    
    echo "Failed to install pip using ensurepip after multiple attempts." >&2
    echo "Python installation may be incomplete or corrupted." >&2
    exit 1
}

# === Added Section: Ensure pip is installed and install 'requests' and 'beautifulsoup4' ===
echo "Ensuring pip is available..."
ensure_pip

echo "Upgrading pip to the latest version..."
python3 -m pip install --upgrade pip
if [ $? -ne 0 ]; then
    echo "Failed to upgrade pip. Exiting."
    exit 1
fi

echo "Installing required Python libraries..."
python3 -m pip install requests beautifulsoup4
if [ $? -ne 0 ]; then
    echo "Failed to install required Python libraries. Exiting."
    exit 1
fi
# === End of Added Section ===

# Install TaskApp
echo "Downloading TaskApp..."
curl -O https://berrystore.sw7ft.com/apps/taskapp.zip

echo "Creating TaskApp directory..."
mkdir -p "$TASKAPP_DIR"

echo "Unzipping TaskApp into $TASKAPP_DIR..."
unzip -o taskapp.zip -d "$TASKAPP_DIR"

# Handle nested taskapp directory if present
if [ -d "$TASKAPP_DIR/taskapp" ]; then
    echo "Detected nested 'taskapp' directory. Moving contents to '$TASKAPP_DIR'..."
    mv "$TASKAPP_DIR/taskapp/"* "$TASKAPP_DIR/"
    rmdir "$TASKAPP_DIR/taskapp"
    echo "Moved TaskApp files to '$TASKAPP_DIR'. Removed redundant 'taskapp' directory."
fi

# Ensure taskapp.py is executable
chmod +x "$TASKAPP_DIR/taskapp.py"

# Backup .profile before making changes
echo "Backing up existing .profile..."
backup_profile

# Update .profile to run TaskApp on terminal startup
echo "Updating .profile to run TaskApp on startup..."

# Check if the start marker exists in .profile
if grep -Fq "$TASKAPP_START_MARKER" "$PROFILE_FILE"; then
    echo "TaskApp start commands already exist in $PROFILE_FILE."
else
    append_to_profile
fi

# Cleanup downloaded files
echo "Cleaning up..."
rm -f python3_ntoarmv7-qnx-static.zip taskapp.zip install.sh

echo "Installation complete. TaskApp is located in $TASKAPP_DIR."
echo "TaskApp will run automatically on terminal startup."

# Source the updated .profile to apply changes immediately
echo "Applying environment changes..."
source "$PROFILE_FILE"
