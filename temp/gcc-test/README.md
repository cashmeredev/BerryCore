# GCC-ARM Test Suite for BlackBerry Passport

## Quick Test Commands

### Step 1: Verify Environment

```bash
# Make sure BerryCore environment is loaded
source /accounts/1000/shared/misc/berrycore/env.sh

# Check if gcc-arm is installed
which gcc
which g++

# Check versions
gcc --version
g++ --version
```

Expected output should show **GCC 9.3.0** or similar.

---

## Test 1: Simple C Program

```bash
# Copy test files to your device first, then:
cd /accounts/1000/shared/documents/gcc-test

# Compile C program
gcc -o hello hello.c

# Run it
./hello
```

**Expected Output:**
```
Hello from gcc-arm on BlackBerry!
Compiler: 9.3.0
Architecture: ARM
Math test: 42 + 13 = 55
Memory test: ptr[0]=100, ptr[9]=999

✓ All tests passed!
```

---

## Test 2: C++ Program

```bash
# Compile C++ program
g++ -o hello_cpp hello.cpp

# Run it
./hello_cpp
```

**Expected Output:**
```
Hello from g++ on BlackBerry!
C++ Standard: 201402
C++ is working!
Vector test: 10 20 30 40 50 
TestClass says: Classes work!

✓ All C++ tests passed!
```

---

## Test 3: With Optimizations

```bash
# Compile with -O2 optimization
gcc -O2 -o hello_opt hello.c
./hello_opt

# Compile with debugging symbols
gcc -g -o hello_debug hello.c
./hello_debug
```

---

## Test 4: Static Linking (Portable Binary)

```bash
# Create fully static binary
gcc -static -o hello_static hello.c
./hello_static

# Check if it's really static
file hello_static
```

---

## Troubleshooting

### Problem: "gcc: command not found"

**Solution:**
```bash
# Check if gcc-arm port is installed
qpkg bins | grep gcc

# If not installed:
qpkg install gcc-arm

# Reload environment
source $NATIVE_TOOLS/env.sh
```

---

### Problem: "cannot find -lc" or library errors

**Check library paths:**
```bash
echo $LD_LIBRARY_PATH

# Should include:
# /accounts/1000/shared/misc/berrycore/lib
```

**If missing:**
```bash
export LD_LIBRARY_PATH="$NATIVE_TOOLS/lib:$LD_LIBRARY_PATH"
```

---

### Problem: "arm-unknown-nto-qnx8.0.0-gcc: error"

This means the QNX cross-compiler is being invoked instead of the ARM-native one.

**Solution:**
```bash
# Check which gcc is being used
which gcc
type gcc

# Should show: /accounts/1000/shared/misc/berrycore/bin/gcc

# If not, check PATH
echo $PATH

# Make sure BerryCore bin is first
export PATH="$NATIVE_TOOLS/bin:$PATH"
```

---

### Problem: Compilation works but binary doesn't run

**Check binary format:**
```bash
file hello

# Should show something like:
# hello: ELF 32-bit LSB executable, ARM, version 1 (SYSV)
```

**Check dependencies:**
```bash
# On BB10, use:
objdump -x hello | grep NEEDED

# Or:
readelf -d hello | grep NEEDED
```

**Common missing libraries:**
- libgcc_s.so.1
- libstdc++.so.6
- libc.so
- libm.so

**Fix:**
```bash
# These should be in $NATIVE_TOOLS/lib
ls -la $NATIVE_TOOLS/lib/libgcc_s.so*
ls -la $NATIVE_TOOLS/lib/libstdc++.so*

# If missing, the gcc-arm port may be incomplete
```

---

## Advanced Tests

### Test with Multiple Files

**main.c:**
```c
#include <stdio.h>
extern void hello_world();

int main() {
    hello_world();
    return 0;
}
```

**hello.c:**
```c
#include <stdio.h>

void hello_world() {
    printf("Multi-file compilation works!\n");
}
```

**Compile:**
```bash
# Compile separately
gcc -c main.c -o main.o
gcc -c hello.c -o hello.o

# Link together
gcc main.o hello.o -o multifile

# Run
./multifile
```

---

### Test with Shared Library

**Create library:**
```c
// mylib.c
#include <stdio.h>

void my_function() {
    printf("Shared library works!\n");
}
```

**Build:**
```bash
# Compile as shared library
gcc -fPIC -shared mylib.c -o libmytest.so

# Move to lib directory
cp libmytest.so $NATIVE_TOOLS/lib/

# Create test program
cat > test_lib.c << 'EOF'
extern void my_function();
int main() {
    my_function();
    return 0;
}
EOF

# Compile and link
gcc test_lib.c -lmytest -o test_lib

# Run
./test_lib
```

---

## Performance Test

```bash
# Create compute-intensive program
cat > fib.c << 'EOF'
#include <stdio.h>
#include <time.h>

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n-1) + fibonacci(n-2);
}

int main() {
    clock_t start = clock();
    int result = fibonacci(35);
    clock_t end = clock();
    
    double cpu_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Fibonacci(35) = %d\n", result);
    printf("Time: %.2f seconds\n", cpu_time);
    return 0;
}
EOF

# Compile without optimization
gcc -o fib_o0 fib.c
time ./fib_o0

# Compile with optimization
gcc -O3 -o fib_o3 fib.c
time ./fib_o3
```

---

## What to Report Back

If tests fail, please provide:

1. **Environment info:**
```bash
gcc --version
which gcc
echo $PATH
echo $LD_LIBRARY_PATH
echo $NATIVE_TOOLS
```

2. **Error messages:**
```bash
# Try compiling with verbose output
gcc -v -o hello hello.c 2>&1 | tee gcc_error.log
```

3. **System info:**
```bash
uname -a
cat /proc/version
pidin info
```

4. **File check:**
```bash
ls -la $NATIVE_TOOLS/bin/gcc*
ls -la $NATIVE_TOOLS/lib/libgcc*
ls -la $NATIVE_TOOLS/lib/libstdc++*
```

---

## Success Criteria

✓ **gcc --version** shows GCC 9.3.0  
✓ **hello.c** compiles without errors  
✓ **./hello** runs and prints output  
✓ **hello.cpp** compiles with g++  
✓ **./hello_cpp** runs successfully  

If all tests pass, gcc-arm is working correctly! 🎉

---

**BerryCore GCC-ARM Package**  
On-device compilation for BlackBerry 10

