#!/bin/sh
# Check what defines the working GCC 4.6.3 uses

echo "╔════════════════════════════════════════════════════════╗"
echo "║       Compare Working vs Broken GCC                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Find the old working GCC
echo "→ Finding working GCC 4.6.3..."
OLD_GCC=""

# Check common locations
for gcc_path in \
    /usr/bin/gcc \
    /usr/bin/qcc \
    /opt/bbndk/host/linux/x86/usr/bin/qcc \
    $(find /opt -name "qcc" 2>/dev/null | head -1) \
    $(find /usr -name "gcc-4.6*" 2>/dev/null | head -1)
do
    if [ -f "$gcc_path" ]; then
        VERSION=$($gcc_path --version 2>/dev/null | head -1)
        if echo "$VERSION" | grep -q "4.6"; then
            OLD_GCC="$gcc_path"
            echo "✓ Found: $gcc_path"
            echo "  Version: $VERSION"
            break
        fi
    fi
done

if [ -z "$OLD_GCC" ]; then
    echo "✗ Could not find GCC 4.6.3"
    echo ""
    echo "Searching for any gcc..."
    find /usr /opt -name "gcc*" -o -name "qcc" 2>/dev/null | grep -v berrycore | head -10
    exit 1
fi

echo ""
echo "→ Getting predefined macros from working GCC..."
echo "─────────────────────────────────────────────────────────"
$OLD_GCC -dM -E - < /dev/null | grep -E "QNX|ENDIAN|LITTLE|BIG" | sort
echo ""

echo "→ Getting include paths from working GCC..."
echo "─────────────────────────────────────────────────────────"
echo "" | $OLD_GCC -E -v - 2>&1 | grep -A 10 "search starts"
echo ""

echo "→ Testing compilation with working GCC..."
cat > /tmp/old_gcc_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Old GCC works!\n");
    return 0;
}
EOF

if $OLD_GCC -o /tmp/old_gcc_test /tmp/old_gcc_test.c 2>&1; then
    echo "✓ Compilation successful"
    /tmp/old_gcc_test
    rm /tmp/old_gcc_test.c /tmp/old_gcc_test
else
    echo "✗ Even old GCC failed?"
fi

echo ""
echo "→ Now checking broken GCC 9.3.0..."
echo "─────────────────────────────────────────────────────────"
echo "Predefined macros:"
gcc -dM -E - < /dev/null 2>/dev/null | grep -E "QNX|ENDIAN|LITTLE|BIG" | sort

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Compare the macros - GCC 9.3.0 is missing defines!   ║"
echo "╚════════════════════════════════════════════════════════╝"

