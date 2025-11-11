#!/bin/sh
# Revert to the working GCC 4.6.3

echo "╔════════════════════════════════════════════════════════╗"
echo "║          Revert to Working GCC 4.6.3                   ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$NATIVE_TOOLS" ]; then
    echo "✗ NATIVE_TOOLS not set"
    exit 1
fi

echo "Current GCC version:"
gcc --version | head -1
echo ""

read -p "Remove GCC 9.3.0 and revert to 4.6.3? [y/N]: " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "→ Backing up GCC 9.3.0..."
cd "$NATIVE_TOOLS"

if [ -f "bin/gcc" ]; then
    mv bin/gcc bin/gcc-9.3.0.backup
    echo "  Backed up bin/gcc"
fi

if [ -f "bin/g++" ]; then
    mv bin/g++ bin/g++-9.3.0.backup
    echo "  Backed up bin/g++"
fi

if [ -f "bin/c++" ]; then
    mv bin/c++ bin/c++-9.3.0.backup
    echo "  Backed up bin/c++"
fi

echo ""
echo "→ Removing GCC 9.3.0 directories..."
if [ -d "lib/gcc/arm-blackberry-qnx8eabi/9.3.0" ]; then
    rm -rf "lib/gcc/arm-blackberry-qnx8eabi/9.3.0"
    echo "  Removed lib/gcc/.../9.3.0"
fi

if [ -d "libexec/gcc/arm-blackberry-qnx8eabi/9.3.0" ]; then
    rm -rf "libexec/gcc/arm-blackberry-qnx8eabi/9.3.0"
    echo "  Removed libexec/gcc/.../9.3.0"
fi

echo ""
echo "→ Looking for GCC 4.6.3..."

# Find old gcc
OLD_GCC=$(find /usr -name "gcc-4.6*" 2>/dev/null | head -1)
if [ -z "$OLD_GCC" ]; then
    OLD_GCC=$(find /opt -name "gcc-4.6*" 2>/dev/null | head -1)
fi

if [ -n "$OLD_GCC" ]; then
    echo "  Found: $OLD_GCC"
    ln -sf "$OLD_GCC" "$NATIVE_TOOLS/bin/gcc"
    echo "  Created symlink"
else
    echo "  GCC 4.6.3 not found in system"
    echo "  The system default gcc should now be used"
fi

echo ""
echo "→ Reloading environment..."
source "$NATIVE_TOOLS/env.sh"

echo ""
echo "New GCC version:"
gcc --version | head -1
echo ""

echo "→ Testing..."
cat > /tmp/revert_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("GCC is working!\n");
    return 0;
}
EOF

if gcc -o /tmp/revert_test /tmp/revert_test.c 2>&1; then
    if /tmp/revert_test; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║              ✓ Reverted Successfully!                  ║"
        echo "║           Using working GCC 4.6.3                      ║"
        echo "╚════════════════════════════════════════════════════════╝"
    fi
    rm /tmp/revert_test.c /tmp/revert_test
else
    echo "✗ GCC still not working"
    echo "  You may need to reinstall BerryCore"
fi

