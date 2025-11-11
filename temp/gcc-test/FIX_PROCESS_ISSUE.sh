#!/bin/sh
# Fix the "No child processes" error in GCC 9.3.0

echo "╔════════════════════════════════════════════════════════╗"
echo "║     Fix GCC 9.3.0 Process Spawning Issue              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [ -z "$NATIVE_TOOLS" ]; then
    echo "✗ NATIVE_TOOLS not set"
    exit 1
fi

echo "The 'No child processes' error happens when GCC tries to"
echo "spawn its internal tools (cc1, as, ld) but fails."
echo ""

echo "→ Checking internal GCC programs..."
echo "─────────────────────────────────────────────────────────"

# Check if cc1 exists
CC1=$(gcc -print-prog-name=cc1)
echo "cc1: $CC1"
if [ -f "$CC1" ]; then
    echo "  ✓ Exists"
    ls -lh "$CC1"
    file "$CC1"
    
    # Check if it's executable
    if [ ! -x "$CC1" ]; then
        echo "  ✗ Not executable! Fixing..."
        chmod +x "$CC1"
    fi
    
    # Try running it
    echo "  Testing cc1..."
    if "$CC1" --version 2>&1 | head -3; then
        echo "  ✓ cc1 works"
    else
        echo "  ✗ cc1 won't run - wrong architecture or missing libraries?"
        ldd "$CC1" 2>&1 | grep -E "not found|error"
    fi
else
    echo "  ✗ NOT FOUND!"
fi

echo ""

# Check assembler
AS=$(gcc -print-prog-name=as)
echo "as (assembler): $AS"
if [ -f "$AS" ]; then
    echo "  ✓ Exists"
    if [ ! -x "$AS" ]; then
        chmod +x "$AS"
    fi
else
    echo "  ✗ NOT FOUND - checking alternatives..."
    if [ -f "/usr/bin/as" ]; then
        echo "    System as found: /usr/bin/as"
        ln -sf /usr/bin/as "$NATIVE_TOOLS/bin/as"
    elif [ -f "$NATIVE_TOOLS/bin/nto-as" ]; then
        ln -sf "$NATIVE_TOOLS/bin/nto-as" "$NATIVE_TOOLS/bin/as"
    fi
fi

echo ""

# Check linker
LD=$(gcc -print-prog-name=ld)
echo "ld (linker): $LD"
if [ -f "$LD" ]; then
    echo "  ✓ Exists"
    if [ ! -x "$LD" ]; then
        chmod +x "$LD"
    fi
else
    echo "  ✗ NOT FOUND - checking alternatives..."
    if [ -f "/usr/bin/ld" ]; then
        echo "    System ld found: /usr/bin/ld"
        ln -sf /usr/bin/ld "$NATIVE_TOOLS/bin/ld"
    elif [ -f "$NATIVE_TOOLS/bin/nto-ld" ]; then
        ln -sf "$NATIVE_TOOLS/bin/nto-ld" "$NATIVE_TOOLS/bin/ld"
    fi
fi

echo ""
echo "→ Checking libexec directory..."
echo "─────────────────────────────────────────────────────────"
LIBEXEC="$NATIVE_TOOLS/libexec/gcc/arm-blackberry-qnx8eabi/9.3.0"
if [ -d "$LIBEXEC" ]; then
    echo "  ✓ Directory exists"
    echo "  Contents:"
    ls -lh "$LIBEXEC/" 2>/dev/null | head -10
    
    # Make sure all files are executable
    echo ""
    echo "  Setting executable permissions..."
    chmod +x "$LIBEXEC"/* 2>/dev/null
    find "$LIBEXEC" -type f -exec chmod +x {} \; 2>/dev/null
    echo "  ✓ Done"
else
    echo "  ✗ Directory not found!"
    echo "  The gcc-arm port is missing critical files."
fi

echo ""
echo "→ Testing process spawning..."
echo "─────────────────────────────────────────────────────────"

# Create minimal test
cat > /tmp/proc_test.c << 'EOF'
int main() { return 0; }
EOF

echo "Trying: gcc -v /tmp/proc_test.c"
gcc -v -o /tmp/proc_test /tmp/proc_test.c 2>&1 | tail -20

rm -f /tmp/proc_test.c /tmp/proc_test

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║             Process Check Complete                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "If 'No child processes' still appears, the issue is likely:"
echo "  1. cc1/cc1plus binaries are for wrong architecture"
echo "  2. Missing libraries that cc1 needs"
echo "  3. GCC 9.3.0 port was built for different QNX version"
echo ""
echo "RECOMMENDATION: Use GCC 4.6.3 which works perfectly,"
echo "or we need to rebuild gcc-arm 9.3.0 port properly."

