# BerryPy 2.0 Integration Complete ✅

## What Was Done

### 1. Package Cleanup
- ✅ Removed development files:
  - `taskapp.log` (133KB of logs)
  - `taskmgr.html.1` (backup file)
  - `oldmgr.html` (old version)
- ✅ Package reduced from ~530KB to **79KB**
- ✅ No macOS metadata included

### 2. Added Update Feature 🆕
Added `berrypy update` command that:
- Downloads latest store files from: `http://berrystore.sw7ft.com/updates/berrypy/latest.zip`
- Auto-stops BerryPy if running
- Creates timestamped backup before updating
- Extracts update directly into `$NATIVE_TOOLS/share/berrypy/`
- Auto-restarts if it was running
- No wrapper directory in zip - just flat files

**Update URL Structure:**
```
http://berrystore.sw7ft.com/updates/berrypy/latest.zip
└── Contains: taskapp.py, taskmgr.html, news_manager.py, etc.
    (No directories, just files ready to extract into share/berrypy/)
```

### 3. Updated Launcher Commands
```bash
berrypy start    # Start server on http://127.0.0.1:8001
berrypy stop     # Stop server
berrypy restart  # Restart server
berrypy status   # Check if running
berrypy logs     # View recent logs
berrypy url      # Show access URL
berrypy update   # 🆕 Update to latest version from berrystore
```

### 4. Integration into BerryCore

**Added to `ports/INDEX`:**
```
berrypy|web|2.0|79K|BlackBerry app platform manager with beautiful web interface
```

**Added to `berrycore/CATALOG`:**
```
berrypy|web|BlackBerry app platform manager with web interface (qpkg install berrypy)
```

### 5. Package Structure
```
web-berrypy-2.0.zip (79KB)
├── bin/
│   └── berrypy              # Enhanced launcher with update command
├── doc/
│   ├── README.md
│   ├── overview.md
│   └── ICON_UPDATES.md
└── share/berrypy/
    ├── taskapp.py           # Main Python app
    ├── taskmgr.html         # Web interface
    ├── news_manager.py
    ├── about.html
    ├── android.html
    ├── auto-config.html
    ├── news.json
    ├── NEWS_SYSTEM_README.md
    └── app-icons/           # 9 PNG icons
```

## User Installation

```bash
# Install BerryPy
qpkg install berrypy

# Start it
berrypy start

# Access at: http://127.0.0.1:8001
```

## Update Workflow for You

When you want to push a store update:

1. **Prepare your update files** (no wrapper directory):
```bash
cd /path/to/berrypy-dev
zip -r latest.zip taskapp.py taskmgr.html news_manager.py about.html \
    android.html auto-config.html news.json NEWS_SYSTEM_README.md \
    app-icons/
```

2. **Upload to your server**:
```bash
# Upload latest.zip to:
http://berrystore.sw7ft.com/updates/berrypy/latest.zip
```

3. **Users update with one command**:
```bash
berrypy update
```

## What Gets Updated

The `berrypy update` command updates **only** the store files in `share/berrypy/`:
- ✅ `taskapp.py` (main Python app)
- ✅ `taskmgr.html` (web interface)
- ✅ `news_manager.py`
- ✅ All HTML templates
- ✅ `news.json`
- ✅ App icons

**Does NOT update:**
- ❌ The `berrypy` launcher itself (`bin/berrypy`)
- ❌ Documentation in `doc/`

For launcher updates, users need to reinstall the port via `qpkg`.

## Requirements

- Python 3.11+ (install via: `qpkg install python3`)
- curl or wget (for updates)

## Files Modified

1. `ports/web-berrypy-2.0.zip` - ✅ Added
2. `ports/INDEX` - ✅ Updated
3. `berrycore/CATALOG` - ✅ Updated
4. `berrycore.zip` - ✅ Packaged (279M)

## Git Status

- ✅ Committed locally
- ⚠️ Push required (failed due to credentials)

Run: `git push` when ready

## Next Steps

1. **Push to GitHub**: `git push`
2. **Upload update zip**: Create your `latest.zip` and upload to:
   ```
   http://berrystore.sw7ft.com/updates/berrypy/latest.zip
   ```
3. **Test update**: On BB10 device, run `berrypy update`

---

**Made with 💜 for the BlackBerry community**

