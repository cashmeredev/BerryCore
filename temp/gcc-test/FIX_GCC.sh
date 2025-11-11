#!/bin/sh
# Fix GCC 9.3.0 by symlinking system headers from QNX_TARGET

echo "╔════════════════════════════════════════════════════════╗"
echo "║              GCC 9.3.0 Header Fix Script              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$NATIVE_TOOLS" ]; then
    echo "✗ NATIVE_TOOLS not set"
    exit 1
fi

if [ -z "$QNX_TARGET" ]; then
    echo "✗ QNX_TARGET not set"
    exit 1
fi

echo "NATIVE_TOOLS: $NATIVE_TOOLS"
echo "QNX_TARGET: $QNX_TARGET"
echo ""

# Check if QNX system headers exist
echo "→ Checking for QNX system headers..."
if [ -f "$QNX_TARGET/usr/include/stdio.h" ]; then
    echo "✓ Found stdio.h in QNX_TARGET"
elif [ -f "$QNX_TARGET/armle-v7/usr/include/stdio.h" ]; then
    echo "✓ Found stdio.h in QNX_TARGET/armle-v7"
    QNX_TARGET="$QNX_TARGET/armle-v7"
else
    echo "✗ stdio.h not found in QNX_TARGET!"
    echo "  Trying to find it..."
    STDIO_PATH=$(find /accounts/1000 -name stdio.h 2>/dev/null | grep -v berrycore | head -1)
    if [ -n "$STDIO_PATH" ]; then
        echo "  Found at: $STDIO_PATH"
        QNX_INCLUDE=$(dirname "$STDIO_PATH")
        echo "  Will use: $QNX_INCLUDE"
    else
        echo "  Cannot find system headers anywhere!"
        exit 1
    fi
fi
echo ""

# Create symlink to system headers
echo "→ Creating symlink to system headers..."
GCC_SYSINCLUDE="$NATIVE_TOOLS/lib/gcc/arm-blackberry-qnx8eabi/9.3.0/include-fixed/sys"

if [ -L "$GCC_SYSINCLUDE" ]; then
    echo "  Removing old symlink..."
    rm "$GCC_SYSINCLUDE"
fi

# Option 1: Link entire include directory
if [ ! -d "$NATIVE_TOOLS/arm-blackberry-qnx8eabi" ]; then
    echo "  Creating arm-blackberry-qnx8eabi directory structure..."
    mkdir -p "$NATIVE_TOOLS/arm-blackberry-qnx8eabi/include"
fi

echo "  Linking $QNX_TARGET/usr/include -> $NATIVE_TOOLS/arm-blackberry-qnx8eabi/include"
ln -sfn "$QNX_TARGET/usr/include" "$NATIVE_TOOLS/arm-blackberry-qnx8eabi/include" 2>/dev/null

# Option 2: Also link to NATIVE_TOOLS/include for good measure
if [ ! -d "$NATIVE_TOOLS/include" ]; then
    mkdir -p "$NATIVE_TOOLS/include"
fi

echo "  Creating additional symlinks in $NATIVE_TOOLS/include..."
for header in stdio.h stdlib.h string.h stddef.h stdint.h stdarg.h; do
    if [ -f "$QNX_TARGET/usr/include/$header" ]; then
        ln -sf "$QNX_TARGET/usr/include/$header" "$NATIVE_TOOLS/include/$header" 2>/dev/null
    fi
done

# Link entire sys directory
if [ -d "$QNX_TARGET/usr/include/sys" ]; then
    ln -sfn "$QNX_TARGET/usr/include/sys" "$NATIVE_TOOLS/include/sys" 2>/dev/null
fi

echo "✓ Symlinks created"
echo ""

# Test compilation
echo "→ Testing compilation..."
cat > /tmp/fix_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Headers fixed!\n");
    return 0;
}
EOF

if gcc -o /tmp/fix_test /tmp/fix_test.c 2>&1; then
    echo "✓ Compilation successful!"
    echo ""
    echo "→ Running test program..."
    if /tmp/fix_test; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║                  ✓ FIX SUCCESSFUL!                     ║"
        echo "║            GCC 9.3.0 is now working!                   ║"
        echo "╚════════════════════════════════════════════════════════╝"
        rm /tmp/fix_test.c /tmp/fix_test
        exit 0
    else
        echo "✗ Program compiled but won't run"
        exit 1
    fi
else
    echo "✗ Compilation still failing"
    echo ""
    echo "Trying alternative fix..."
    
    # Alternative: Use GCC specs file
    echo "→ Creating GCC specs file with explicit paths..."
    gcc -dumpspecs > /tmp/gcc.specs
    
    # Add sysroot
    cat >> /tmp/gcc.specs << EOF

*cpp:
+ -isystem $QNX_TARGET/usr/include

EOF
    
    mv /tmp/gcc.specs "$NATIVE_TOOLS/lib/gcc/arm-blackberry-qnx8eabi/9.3.0/specs"
    echo "  Specs file created"
    
    # Try again
    if gcc -o /tmp/fix_test /tmp/fix_test.c 2>&1; then
        echo "✓ Specs file fix worked!"
        /tmp/fix_test
        rm /tmp/fix_test.c /tmp/fix_test
    else
        echo "✗ Still not working"
        exit 1
    fi
fi

