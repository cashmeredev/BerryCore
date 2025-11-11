#!/bin/sh
# GCC-ARM Diagnostics - Find out what's wrong

echo "╔════════════════════════════════════════════════════════╗"
echo "║           GCC-ARM 9.3.0 Diagnostic Tool                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

echo "→ GCC Version and Location"
echo "─────────────────────────────────────────────────────────"
which gcc
gcc --version | head -1
echo ""

echo "→ GCC Search Paths"
echo "─────────────────────────────────────────────────────────"
gcc -print-search-dirs
echo ""

echo "→ Include Search Paths"
echo "─────────────────────────────────────────────────────────"
echo '#include <...> search starts here:' | gcc -E -v - 2>&1 | grep -A 20 "search starts"
echo ""

echo "→ System Include Directories"
echo "─────────────────────────────────────────────────────────"
gcc -print-prog-name=cc1
gcc -print-file-name=include
gcc -print-sysroot
echo ""

echo "→ Check for stdio.h in expected locations"
echo "─────────────────────────────────────────────────────────"
find $NATIVE_TOOLS -name stdio.h 2>/dev/null | head -10
echo ""

echo "→ Check for assembler and linker"
echo "─────────────────────────────────────────────────────────"
which as
which ld
ls -la $NATIVE_TOOLS/bin/as* 2>/dev/null
ls -la $NATIVE_TOOLS/bin/ld* 2>/dev/null
echo ""

echo "→ Check libexec (internal GCC tools)"
echo "─────────────────────────────────────────────────────────"
ls -la $NATIVE_TOOLS/libexec/gcc/ 2>/dev/null
echo ""

echo "→ GCC Internal Programs"
echo "─────────────────────────────────────────────────────────"
gcc -print-prog-name=cc1
gcc -print-prog-name=as
gcc -print-prog-name=ld
gcc -print-prog-name=collect2
echo ""

echo "→ Test Compilation with Verbose Output"
echo "─────────────────────────────────────────────────────────"
cat > /tmp/diag_test.c << 'EOF'
int main() { return 0; }
EOF

echo "Trying: gcc -v /tmp/diag_test.c"
gcc -v -o /tmp/diag_test /tmp/diag_test.c 2>&1 | head -30
echo ""

echo "→ Environment Variables"
echo "─────────────────────────────────────────────────────────"
echo "NATIVE_TOOLS=$NATIVE_TOOLS"
echo "PATH=$PATH"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
echo "QNX_TARGET=$QNX_TARGET"
echo "QNX_HOST=$QNX_HOST"
echo ""

echo "→ Check QNX Target System Headers"
echo "─────────────────────────────────────────────────────────"
if [ -d "$QNX_TARGET" ]; then
    echo "QNX_TARGET exists: $QNX_TARGET"
    ls -la $QNX_TARGET/usr/include/stdio.h 2>/dev/null || echo "  stdio.h NOT FOUND in QNX_TARGET"
else
    echo "QNX_TARGET not found or not set"
fi
echo ""

echo "╔════════════════════════════════════════════════════════╗"
echo "║                   Diagnostics Complete                 ║"
echo "╚════════════════════════════════════════════════════════╝"

