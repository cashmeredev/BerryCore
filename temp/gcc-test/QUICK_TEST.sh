#!/bin/sh
# Quick GCC-ARM Test Script for BlackBerry Passport
# Run this to verify gcc-arm is working

echo "╔════════════════════════════════════════════════════════╗"
echo "║       GCC-ARM Quick Test for BlackBerry Passport      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Check environment
echo "→ Checking BerryCore environment..."
if [ -z "$NATIVE_TOOLS" ]; then
    echo "✗ NATIVE_TOOLS not set"
    echo "  Run: source /accounts/1000/shared/misc/berrycore/env.sh"
    exit 1
fi
echo "✓ NATIVE_TOOLS: $NATIVE_TOOLS"
echo ""

# Check gcc
echo "→ Checking gcc..."
if ! command -v gcc > /dev/null 2>&1; then
    echo "✗ gcc not found"
    echo "  Run: qpkg install gcc-arm"
    exit 1
fi

GCC_VERSION=$(gcc --version 2>&1 | head -n1)
echo "✓ Found: $GCC_VERSION"
echo ""

# Check g++
echo "→ Checking g++..."
if ! command -v g++ > /dev/null 2>&1; then
    echo "✗ g++ not found"
    echo "  Run: qpkg install gcc-arm"
    exit 1
fi

GPP_VERSION=$(g++ --version 2>&1 | head -n1)
echo "✓ Found: $GPP_VERSION"
echo ""

# Create test C program
echo "→ Creating test C program..."
cat > /tmp/test_gcc.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello from gcc-arm!\n");
    printf("Math: 40 + 2 = %d\n", 40 + 2);
    return 0;
}
EOF
echo "✓ Created /tmp/test_gcc.c"
echo ""

# Compile C
echo "→ Compiling C program..."
if gcc -o /tmp/test_gcc /tmp/test_gcc.c 2>&1; then
    echo "✓ Compilation successful!"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

# Run C program
echo "→ Running C program..."
echo "─────────────────────────────────────────────"
if /tmp/test_gcc; then
    echo "─────────────────────────────────────────────"
    echo "✓ C program ran successfully!"
else
    echo "─────────────────────────────────────────────"
    echo "✗ C program failed to run!"
    exit 1
fi
echo ""

# Create test C++ program
echo "→ Creating test C++ program..."
cat > /tmp/test_gpp.cpp << 'EOF'
#include <iostream>
#include <string>
using namespace std;

int main() {
    string msg = "Hello from g++!";
    cout << msg << endl;
    cout << "C++ works!" << endl;
    return 0;
}
EOF
echo "✓ Created /tmp/test_gpp.cpp"
echo ""

# Compile C++
echo "→ Compiling C++ program..."
if g++ -o /tmp/test_gpp /tmp/test_gpp.cpp 2>&1; then
    echo "✓ Compilation successful!"
else
    echo "✗ Compilation failed!"
    exit 1
fi
echo ""

# Run C++ program
echo "→ Running C++ program..."
echo "─────────────────────────────────────────────"
if /tmp/test_gpp; then
    echo "─────────────────────────────────────────────"
    echo "✓ C++ program ran successfully!"
else
    echo "─────────────────────────────────────────────"
    echo "✗ C++ program failed to run!"
    exit 1
fi
echo ""

# Cleanup
rm -f /tmp/test_gcc.c /tmp/test_gcc /tmp/test_gpp.cpp /tmp/test_gpp

# Success!
echo "╔════════════════════════════════════════════════════════╗"
echo "║                    ✓ ALL TESTS PASSED!                ║"
echo "║              gcc-arm is working correctly!             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "You can now compile C and C++ programs on your Passport!"
echo ""

