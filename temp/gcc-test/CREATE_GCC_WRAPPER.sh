#!/bin/sh
# Create wrapper for GCC 9.3.0 with proper QNX defines

echo "╔════════════════════════════════════════════════════════╗"
echo "║         Create GCC 9.3.0 Wrapper with QNX Defines     ║"
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

# Backup original gcc
if [ ! -f "$NATIVE_TOOLS/bin/gcc.real" ]; then
    echo "→ Backing up original gcc..."
    mv "$NATIVE_TOOLS/bin/gcc" "$NATIVE_TOOLS/bin/gcc.real"
    echo "✓ Backed up to gcc.real"
fi

# Create wrapper script
echo "→ Creating GCC wrapper..."
cat > "$NATIVE_TOOLS/bin/gcc" << 'WRAPPER_EOF'
#!/bin/sh
# GCC 9.3.0 Wrapper for QNX compatibility

# QNX-specific defines that are needed
QNX_DEFINES="-D__QNX__=1 \
-D__QNXNTO__=1 \
-D__ARM__=1 \
-D__ARMEL__=1 \
-D__LITTLEENDIAN__=1 \
-D_LITTLE_ENDIAN=1 \
-D__arm__=1 \
-D__ARM_EABI__=1 \
-DARM_VARIANT=7 \
-D__EXT_POSIX1_198808=1 \
-D__EXT_POSIX1_199009=1 \
-D__EXT_POSIX1_199506=1"

# Include paths
QNX_INCLUDES="-isystem $QNX_TARGET/usr/include \
-isystem $QNX_TARGET/usr/include/arm"

# Execute real gcc with defines
exec "$NATIVE_TOOLS/bin/gcc.real" $QNX_DEFINES $QNX_INCLUDES "$@"
WRAPPER_EOF

chmod +x "$NATIVE_TOOLS/bin/gcc"
echo "✓ Created wrapper at $NATIVE_TOOLS/bin/gcc"

# Create g++ wrapper
if [ ! -f "$NATIVE_TOOLS/bin/g++.real" ]; then
    echo "→ Backing up original g++..."
    mv "$NATIVE_TOOLS/bin/g++" "$NATIVE_TOOLS/bin/g++.real"
fi

cat > "$NATIVE_TOOLS/bin/g++" << 'WRAPPER_EOF'
#!/bin/sh
# G++ 9.3.0 Wrapper for QNX compatibility

QNX_DEFINES="-D__QNX__=1 \
-D__QNXNTO__=1 \
-D__ARM__=1 \
-D__ARMEL__=1 \
-D__LITTLEENDIAN__=1 \
-D_LITTLE_ENDIAN=1 \
-D__arm__=1 \
-D__ARM_EABI__=1 \
-DARM_VARIANT=7 \
-D__EXT_POSIX1_198808=1 \
-D__EXT_POSIX1_199009=1 \
-D__EXT_POSIX1_199506=1"

QNX_INCLUDES="-isystem $QNX_TARGET/usr/include \
-isystem $QNX_TARGET/usr/include/arm"

exec "$NATIVE_TOOLS/bin/g++.real" $QNX_DEFINES $QNX_INCLUDES "$@"
WRAPPER_EOF

chmod +x "$NATIVE_TOOLS/bin/g++"
echo "✓ Created wrapper at $NATIVE_TOOLS/bin/g++"

echo ""
echo "→ Testing wrapped GCC..."
cat > /tmp/wrapper_test.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Wrapped GCC works!\n");
    printf("Endian: ");
#ifdef __LITTLEENDIAN__
    printf("Little Endian\n");
#else
    printf("Unknown\n");
#endif
    return 0;
}
EOF

echo ""
echo "Compiling test..."
if gcc -o /tmp/wrapper_test /tmp/wrapper_test.c 2>&1; then
    echo "✓ Compilation successful!"
    echo ""
    echo "→ Running test program..."
    if /tmp/wrapper_test; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║              ✓ GCC 9.3.0 NOW WORKS!                   ║"
        echo "║         Wrapper adds required QNX defines              ║"
        echo "╚════════════════════════════════════════════════════════╝"
        rm /tmp/wrapper_test.c /tmp/wrapper_test
        exit 0
    else
        echo "✗ Compiled but won't run"
    fi
else
    echo "✗ Compilation still failing"
    echo ""
    echo "Error output above shows the remaining issue."
    echo "The 'No child processes' error may need a different fix."
fi

rm -f /tmp/wrapper_test.c /tmp/wrapper_test

