# qpkg Troubleshooting Guide

## Common Issues & Solutions

### 1. ❌ "Failed to fetch ports index from GitHub"
**Cause**: No internet connection or curl/wget not working
**Fix**:
```bash
# Test internet connection
ping -c 3 8.8.8.8

# Test curl
curl -I https://github.com

# Test the actual URL
curl -s https://raw.githubusercontent.com/sw7ft/BerryCore/main/ports/INDEX
```

### 2. ❌ "$NATIVE_TOOLS not set"
**Cause**: Environment not loaded
**Fix**:
```bash
# Source the environment
source /accounts/1000/shared/misc/berrycore/env.sh

# Or restart shell
```

### 3. ❌ "Permission denied" during install
**Cause**: No write access to $NATIVE_TOOLS
**Fix**:
```bash
# Check permissions
ls -ld $NATIVE_TOOLS

# Should be writable by your user
```

### 4. ❌ "Download failed" / curl errors
**Cause**: GitHub raw links being blocked or curl issues
**Fix**:
```bash
# Test raw GitHub access
curl -L https://raw.githubusercontent.com/sw7ft/BerryCore/main/ports/INDEX

# Try with -k flag (ignore SSL - not recommended but may work)
# Edit qpkg and add -k to curl commands
```

### 5. ❌ Commands like "qpkg: not found"
**Cause**: $NATIVE_TOOLS/bin not in PATH
**Fix**:
```bash
# Check PATH
echo $PATH | grep berrycore

# If not there, reload environment
source $NATIVE_TOOLS/env.sh
```

### 6. ❌ "No download tool available"
**Cause**: Neither curl nor wget available
**Solution**: Install curl or wget first (chicken-egg problem)

### 7. 🐛 Bug at line 375
**Issue**: Tries to read from deleted temp file
```bash
# Line 375 references $TEMP_DIR/$FILENAME after cleanup
# Should be moved before line 369 (rm -rf "$TEMP_DIR")
```

## Debug Mode
Add this after line 1 of qpkg to enable debug mode:
```bash
#!/bin/sh
set -x  # Enable debug output
```

## Manual Package Install (if qpkg fails)
```bash
cd $NATIVE_TOOLS
curl -L -O https://raw.githubusercontent.com/sw7ft/BerryCore/main/ports/net-hydra-9.5.zip
unzip -o net-hydra-9.5.zip
chmod +x bin/*
rm net-hydra-9.5.zip
```


