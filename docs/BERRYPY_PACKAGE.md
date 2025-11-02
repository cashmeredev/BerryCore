# BerryPy Package - Complete Build & Maintenance Guide

**Package Name:** `web-berrypy-2.0.zip`  
**Category:** web  
**Version:** 2.0  
**Size:** 78KB (compressed)  
**Location:** `ports/web-berrypy-2.0.zip`

## Overview

BerryPy is a BlackBerry app platform manager with a beautiful web interface. It provides a centralized management system for BB10/QNX applications, accessible via a local web server on port 8001.

### What BerryPy Does:
- **App Management**: Launch and manage BB10 applications from a web interface
- **Configuration**: Auto-configuration tools for BB10 settings
- **News System**: Display news/updates from remote JSON feeds
- **Android Bridge**: Interface for managing Android runtime apps
- **Task Management**: Process and task monitoring interface

---

## Package Structure

```
web-berrypy-2.0.zip
├── bin/
│   └── berrypy                    # Main launcher script (executable)
├── doc/
│   ├── README.md                  # Package documentation
│   ├── overview.md                # Feature overview
│   └── ICON_UPDATES.md           # Icon update guide
└── share/
    └── berrypy/
        ├── taskapp.py             # Main Python web server
        ├── taskmgr.html           # Task manager interface
        ├── about.html             # About page
        ├── auto-config.html       # Auto-configuration interface
        ├── android.html           # Android runtime interface
        ├── news.json              # News feed data
        ├── news_manager.py        # News system backend
        ├── NEWS_SYSTEM_README.md  # News system docs
        └── app-icons/             # Application icons (PNG)
            ├── aichat.png
            ├── copyclip.png
            ├── github.png
            ├── rocketchat.png
            ├── telegram.png
            ├── term49-settings.png
            ├── webshell.png
            ├── youtube.png
            └── README.txt
```

---

## Technical Implementation

### 1. Main Launcher Script (`bin/berrypy`)

**Shebang:** `#!/bin/sh`  
**Critical:** Must use `/bin/sh` NOT `/bin/bash` (bash is not at `/bin/bash` on BB10)

**Environment Variables:**
```bash
BERRYPY_DIR="${NATIVE_TOOLS}/share/berrypy"
BERRYPY_LOG="${BERRYPY_DIR}/berrypy.log"
BERRYPY_PID="${BERRYPY_DIR}/.berrypy.pid"
```

**Key Functions:**
- `start_berrypy()` - Starts the web server via `nohup`
- `stop_berrypy()` - Gracefully stops the server
- `status_berrypy()` - Checks if server is running
- `show_logs()` - Displays last 50 lines of logs
- `update_berrypy()` - Downloads and applies updates

### 2. Process Detection - CRITICAL QNX/BB10 FIX

**THE PROBLEM:**
- Standard Unix/Linux uses: `ps -p $PID`
- BB10/QNX uses: `pidin -p $PID`
- Using `ps -p` on QNX causes false negatives (reports process not running when it is)

**THE SOLUTION:**
All process checks use `pidin -p` instead of `ps -p`:

```bash
# Check if process is running
if pidin -p "$PID" > /dev/null 2>&1; then
    echo "BerryPy is already running"
fi

# Verify startup
if pidin -p $(cat "$BERRYPY_PID") > /dev/null 2>&1; then
    echo "✓ BerryPy started successfully!"
fi
```

**Changed in 5 locations:**
1. `start_berrypy()` - Check if already running (line ~43)
2. `start_berrypy()` - Verify it started (line ~60)
3. `stop_berrypy()` - Check if running (line ~82)
4. `stop_berrypy()` - Wait for shutdown loop (line ~93)
5. `status_berrypy()` - Check process status (line ~113)

### 3. Web Server (`share/berrypy/taskapp.py`)

**Language:** Python 3  
**Port:** 8001  
**Dependencies:** Python 3.11 (installed via `qpkg install python3`)

**Startup Command:**
```bash
cd "$BERRYPY_DIR"
nohup python3 taskapp.py >> "$BERRYPY_LOG" 2>&1 &
```

**Features:**
- HTTP server on port 8001
- Serves HTML interfaces
- News feed integration
- Task/process management APIs

### 4. Update Mechanism

**Update URL:** `http://berrystore.sw7ft.com/updates/berrypy/latest.zip`

**Update Process:**
```bash
berrypy update
```

1. Downloads `latest.zip` to temporary location
2. Backs up current installation to `.backup/`
3. Extracts new files (preserves config)
4. Restarts server automatically
5. Verifies successful update

**Preserved During Updates:**
- `news.json` (user's news feed settings)
- Log files
- PID files

---

## Installation via qpkg

### User Installation:
```bash
# Install BerryPy
qpkg install berrypy

# Start the server
berrypy start

# Access web interface
# Open browser: http://127.0.0.1:8001
```

### Files Installed:
```
$NATIVE_TOOLS/
├── bin/
│   └── berrypy                          # Executable in $PATH
├── doc/
│   └── berrypy/                         # Documentation
└── share/
    └── berrypy/                         # Application files
```

### Commands Available:
- `berrypy start` - Start the web server
- `berrypy stop` - Stop the web server
- `berrypy restart` - Restart the web server
- `berrypy status` - Check if running
- `berrypy logs` - View last 50 log lines
- `berrypy update` - Update to latest version
- `berrypy help` - Show help message

---

## Packaging Process

### Step 1: Source Preparation
1. Received BerryPy files in `temp/` directory
2. Examined structure and fixed shebang issues
3. Removed development artifacts:
   - `taskapp.log` (development logs)
   - `taskmgr.html.1` (backup file)
   - `oldmgr.html` (old version)

### Step 2: QNX Compatibility Fixes

**Shebang Fix:**
```bash
# Changed from:
#!/bin/bash

# To:
#!/bin/sh
```

**Process Detection Fix:**
```bash
# Changed all occurrences from:
ps -p "$PID"

# To:
pidin -p "$PID"
```

### Step 3: Packaging
```bash
cd temp/berrypy-fix
zip -r ../../ports/web-berrypy-2.0.zip . \
    -x "*.DS_Store" "__MACOSX/*"
```

### Step 4: Catalog Updates

**Added to `ports/INDEX`:**
```
berrypy|web|2.0|79K|BlackBerry app platform manager with beautiful web interface
```

**Added to `berrycore/CATALOG`:**
```
berrypy|web|BlackBerry app platform manager with web interface (qpkg install berrypy)
```

### Step 5: Testing Checklist
- ✅ Package extracts correctly
- ✅ `berrypy` command is executable
- ✅ Process detection works (pidin)
- ✅ Web server starts on port 8001
- ✅ Web interface is accessible
- ✅ Logs are created properly
- ✅ Stop/restart commands work
- ✅ Update mechanism functions

---

## Dependencies

### Required:
- **Python 3.11**: Installed via `qpkg install python3`
- **QNX/BB10 System**: Native `pidin` command
- **NATIVE_TOOLS**: Environment variable set by BerryCore

### Optional:
- **curl**: For update functionality (included in BerryCore)
- **unzip**: For unpacking updates (included in BerryCore)

---

## Troubleshooting

### Issue: "No such file or directory" when running `berrypy`
**Cause:** Shebang is `#!/bin/bash` but bash isn't at that path on BB10  
**Fix:** Change shebang to `#!/bin/sh`

### Issue: "Failed to start BerryPy" but web interface works
**Cause:** Process detection using `ps -p` instead of `pidin -p`  
**Fix:** Replace all `ps -p` with `pidin -p` in berrypy script

### Issue: Python not found
**Cause:** Python 3.11 not installed  
**Fix:** Run `qpkg install python3` first

### Issue: Port 8001 already in use
**Cause:** Another process or stale BerryPy instance  
**Solution:**
```bash
berrypy stop
# If that fails:
pidin | grep python3
kill <PID>
```

### Issue: Logs not showing
**Cause:** Permissions or directory doesn't exist  
**Solution:**
```bash
mkdir -p $NATIVE_TOOLS/share/berrypy
chmod 755 $NATIVE_TOOLS/share/berrypy
```

---

## Maintenance Tasks

### Updating BerryPy:

1. **Modify source files** in `temp/berrypy-fix/`
2. **Test changes** thoroughly
3. **Remove dev files**:
   ```bash
   cd temp/berrypy-fix/share/berrypy
   rm -f taskapp.log taskmgr.html.* oldmgr.html
   ```
4. **Repackage**:
   ```bash
   cd temp/berrypy-fix
   zip -r ../../ports/web-berrypy-2.0.zip . \
       -x "*.DS_Store" "__MACOSX/*"
   ```
5. **Update version** in `ports/INDEX` if needed
6. **Test installation**:
   ```bash
   qpkg remove berrypy
   qpkg install berrypy
   berrypy start
   ```
7. **Commit changes**:
   ```bash
   git add ports/web-berrypy-2.0.zip
   git commit -m "Update BerryPy: [description]"
   ```

### Adding New Features:

1. Modify `taskapp.py` for backend changes
2. Modify HTML files for frontend changes
3. Add new icons to `app-icons/` directory (PNG format)
4. Update documentation in `doc/` directory
5. Test on actual BB10 device
6. Repackage and deploy

### Version Numbering:
- **Major version** (2.x): Significant features or breaking changes
- **Minor version** (x.1): New features, backwards compatible
- **Patch version** (x.x.1): Bug fixes only

Current: **2.0** (major rewrite with QNX compatibility fixes)

---

## Critical Notes for Maintenance

### ⚠️ ALWAYS USE `pidin` NOT `ps`
QNX/BB10 uses `pidin` for process management. Never use `ps -p` commands.

### ⚠️ ALWAYS USE `#!/bin/sh` SHEBANG
BB10 doesn't have bash at `/bin/bash`. Use `/bin/sh` for all shell scripts.

### ⚠️ CLEAN PACKAGES BEFORE RELEASING
Always remove:
- `*.log` files
- `*.1`, `*.bak` backup files
- `old*` prefixed files
- Mac metadata (`.DS_Store`, `__MACOSX/*`)

### ⚠️ TEST ON ACTUAL DEVICE
BerryPy must be tested on a real BB10/QNX device before release. Process detection and port binding behave differently than on development machines.

### ⚠️ PRESERVE USER DATA
When updating, ensure `news.json` and user configurations are preserved.

---

## Files Changed in BerryCore Repository

1. **`ports/web-berrypy-2.0.zip`** - The package itself
2. **`ports/INDEX`** - Package metadata for qpkg
3. **`berrycore/CATALOG`** - User-facing package list
4. **`temp/staging/web-berrypy-2.0.zip`** - Clean staging version (optional)

---

## Git History

**Initial Integration:** [Commit SHA where first added]
**QNX Fixes:** Commit `a1d0d84` - "Fix BerryPy for QNX - use pidin instead of ps for process detection"

**Key Commits:**
- Changed shebang from bash to sh
- Replaced all ps -p with pidin -p
- Removed dev files
- Added to ports and catalog

---

## Contact & Support

**Project:** BerryCore  
**Platform:** BlackBerry 10 / QNX 8  
**Python Version:** 3.11.10  
**Web Interface:** http://127.0.0.1:8001  
**Update Server:** http://berrystore.sw7ft.com/

---

## Quick Reference

```bash
# Installation
qpkg install berrypy

# Start server
berrypy start

# Check status  
berrypy status

# View logs
berrypy logs

# Update
berrypy update

# Stop server
berrypy stop

# Access web interface
# Browser: http://127.0.0.1:8001
```

---

**Last Updated:** November 2, 2025  
**Maintained By:** BerryCore Team  
**Documentation Version:** 1.0

