#!/bin/sh
# Cleanly remove GCC-ARM 9.3.0 port and restore working GCC 4.6.3

echo "╔════════════════════════════════════════════════════════╗"
echo "║      Remove Broken GCC-ARM 9.3.0 Port                 ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$NATIVE_TOOLS" ]; then
    echo "✗ NATIVE_TOOLS not set"
    exit 1
fi

echo "This will:"
echo "  1. Remove GCC 9.3.0 binaries and wrappers"
echo "  2. Remove corrupted specs file"
echo "  3. Remove GCC 9.3.0 libraries and headers"
echo "  4. Restore system GCC 4.6.3"
echo ""

read -p "Continue? [y/N]: " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled"
    exit 0
fi

cd "$NATIVE_TOOLS"

echo ""
echo "→ Removing GCC 9.3.0 binaries..."
rm -f bin/gcc
rm -f bin/gcc.real
rm -f bin/g++
rm -f bin/g++.real
rm -f bin/c++
rm -f bin/c++.real
echo "✓ Removed"

echo ""
echo "→ Removing GCC 9.3.0 libraries..."
rm -rf lib/gcc/arm-blackberry-qnx8eabi/9.3.0
rm -rf libexec/gcc/arm-blackberry-qnx8eabi/9.3.0
echo "✓ Removed"

echo ""
echo "→ Removing malformed specs file..."
rm -f lib/gcc/arm-blackberry-qnx8eabi/9.3.0/specs
echo "✓ Removed"

echo ""
echo "→ Cleaning up empty directories..."
rmdir lib/gcc/arm-blackberry-qnx8eabi 2>/dev/null
rmdir lib/gcc 2>/dev/null
rmdir libexec/gcc/arm-blackberry-qnx8eabi 2>/dev/null
rmdir libexec/gcc 2>/dev/null
echo "✓ Done"

echo ""
echo "→ Checking for system GCC..."
SYSTEM_GCC=""

for gcc_path in /usr/bin/gcc /usr/bin/qcc; do
    if [ -f "$gcc_path" ]; then
        SYSTEM_GCC="$gcc_path"
        echo "✓ Found: $gcc_path"
        VERSION=$($gcc_path --version 2>/dev/null | head -1)
        echo "  $VERSION"
        break
    fi
done

if [ -z "$SYSTEM_GCC" ]; then
    echo "✗ No system GCC found"
    echo "  BerryCore will use whatever gcc is in PATH"
else
    echo ""
    echo "→ System GCC will be used automatically"
fi

echo ""
echo "→ Testing compilation..."
cat > /tmp/final_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("GCC is working!\n");
    printf("Test: 21 + 21 = %d\n", 21 + 21);
    return 0;
}
EOF

# Reload environment
source "$NATIVE_TOOLS/env.sh"

echo "Current GCC:"
which gcc
gcc --version | head -1
echo ""

if gcc -o /tmp/final_test /tmp/final_test.c 2>&1; then
    echo "✓ Compilation successful!"
    echo ""
    if /tmp/final_test; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║           ✓ GCC-ARM 9.3.0 REMOVED                     ║"
        echo "║         Using working GCC 4.6.3 again!                ║"
        echo "╚════════════════════════════════════════════════════════╝"
    fi
    rm /tmp/final_test.c /tmp/final_test
else
    echo "✗ Compilation failed"
    echo "  You may need to source env.sh again:"
    echo "  source $NATIVE_TOOLS/env.sh"
fi

echo ""
echo "Note: The gcc-arm port has been removed from your system."
echo "      It will also be removed from the ports index."
echo "      We'll rebuild it properly and re-release it when fixed."

