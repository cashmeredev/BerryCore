# GCC-ARM 9.3.0 Port - Issues & TODO

**Status:** REMOVED from ports (broken)  
**Working Alternative:** GCC 4.6.3 (included in base BerryCore)

---

## Issues Found During Testing

### 1. ❌ Process Spawning Failure
**Error:** `gcc: fatal error: failed to get exit status: No child processes`

**Cause:** GCC cannot properly spawn internal tools (cc1, as, ld)

**Evidence:**
- cc1 and cc1plus exist in `libexec/gcc/arm-blackberry-qnx8eabi/9.3.0/`
- They are executable (15-16MB binaries)
- But GCC cannot spawn them as child processes

**Possible Reasons:**
- Binaries built for different QNX version
- Missing shared libraries that cc1/cc1plus need
- Incompatible with QNX 8 on BlackBerry 10
- Wrong architecture (should be ARM but might be x86)

---

### 2. ❌ Missing QNX Compiler Defines
**Error:** `error: #error Endian not defined`

**Cause:** GCC 9.3.0 doesn't set required QNX macros

**Missing Defines:**
```c
__QNX__
__QNXNTO__
__ARM__
__ARMEL__
__LITTLEENDIAN__
_LITTLE_ENDIAN
__ARM_EABI__
```

**Working GCC 4.6.3 sets these automatically**

**Workaround Attempted:**
- Created wrapper script to inject defines
- Failed due to specs file corruption

---

### 3. ❌ Corrupted Specs File
**Error:** `gcc.real: fatal error: specs file malformed after 6750 characters`

**Cause:** 
- Attempted to add include paths via specs file
- GCC specs format is complex and fragile
- Specs got corrupted during fix attempt

**Location:** `lib/gcc/arm-blackberry-qnx8eabi/9.3.0/specs`

---

### 4. ❌ Missing/Wrong Header Paths
**Error:** `fatal error: _pack64.h: No such file or directory`

**Issue:** Even with symlinks, some QNX-specific headers aren't found

**What's Missing:**
- Full QNX 8 system headers
- QNX-specific packing headers
- Architecture-specific headers

---

## What Works

✅ **GCC 4.6.3** (Base BerryCore)
- Compiles C programs perfectly
- Compiles C++ programs with STL
- All tests pass
- Properly configured for QNX/BB10

✅ **Headers Exist**
- System headers are in `$QNX_TARGET/usr/include/`
- stdio.h, stdlib.h, etc. all present
- GCC 9.3.0 just can't find/use them properly

✅ **Internal Tools Exist**
- cc1, cc1plus in libexec
- All executable and correct size
- Just not being invoked properly

---

## Requirements for Working GCC-ARM Port

### A. Binary Requirements
1. **Native ARM Binaries**
   - gcc, g++, as, ld must be ARM (not x86)
   - Must run on QNX 8 / BlackBerry 10
   - Test with: `file gcc` → should show "ARM"

2. **Internal Tools**
   - cc1, cc1plus (C/C++ compilers)
   - as (assembler)
   - ld (linker)
   - collect2 (link wrapper)
   - All must be ARM QNX binaries

3. **Required Libraries**
   - libgcc_s.so.1
   - libstdc++.so.6
   - Any dependencies cc1/as/ld need

### B. Configuration Requirements
1. **Specs File**
   - Must be valid GCC specs format
   - Include QNX system paths
   - Set default defines for QNX/ARM

2. **Default Defines** (must be set automatically)
   ```
   -D__QNX__=1
   -D__QNXNTO__=1
   -D__ARM__=1
   -D__LITTLEENDIAN__=1
   ```

3. **Include Paths**
   - Must search `$QNX_TARGET/usr/include/`
   - Must search `$QNX_TARGET/usr/include/arm/`
   - GCC internal includes (stdarg.h, etc.)

4. **Library Paths**
   - Must search `$QNX_TARGET/armle-v7/lib/`
   - Must find libc, libm, etc.

### C. Build Requirements
**GCC must be built with:**
```bash
--target=arm-blackberry-qnx8eabi
--enable-languages=c,c++
--with-sysroot=$QNX_TARGET
--enable-shared
--enable-threads=posix
--with-arch=armv7-a
--with-float=softfp
--with-fpu=neon
```

**And configured to know about QNX:**
- Use QNX-specific specs
- Link against QNX libc
- Support QNX system calls

---

## How to Build Proper GCC-ARM Port

### Option 1: Use QNX Momentics SDK
The official QNX SDK includes a working ARM GCC.

**Extract and Package:**
```bash
# From QNX SDK
cd $QNX_HOST/usr/bin
# Package gcc, g++, as, ld, etc.
# Include libexec/gcc/ directory
# Include required libraries
```

### Option 2: Cross-Compile GCC 9.3.0
Build GCC on x86 Linux targeting ARM QNX.

**Requires:**
- QNX 8 SDK (for headers/libs)
- ARM cross-compiler (bootstrap)
- Proper configure flags (see above)

### Option 3: Native Compile on BB10
Use working GCC 4.6.3 to compile GCC 9.3.0 on device.

**Pros:** Guaranteed compatible
**Cons:** Very slow (hours), needs lots of RAM

---

## Testing Checklist for Future GCC-ARM Port

### Phase 1: Binary Check
```bash
file bin/gcc                    # Must say: ARM
file libexec/gcc/.../cc1        # Must say: ARM
ldd libexec/gcc/.../cc1         # Check dependencies
./libexec/gcc/.../cc1 --version # Must run
```

### Phase 2: Configuration Check
```bash
gcc -v                          # Show search paths
gcc -dM -E - < /dev/null        # Show defines
gcc --print-search-dirs         # Show library paths
gcc -print-prog-name=cc1        # Must find cc1
```

### Phase 3: Compilation Tests
```bash
# Test 1: Simple C
cat > test.c << 'EOF'
#include <stdio.h>
int main() { printf("Test\n"); return 0; }
EOF
gcc -v -o test test.c           # Must compile
./test                          # Must run

# Test 2: Endian test
cat > endian.c << 'EOF'
#include <stdio.h>
int main() {
#ifdef __LITTLEENDIAN__
    printf("Endian defined\n");
#else
    #error Endian not defined
#endif
    return 0;
}
EOF
gcc -o endian endian.c          # Must compile without error

# Test 3: C++ with STL
cat > test.cpp << 'EOF'
#include <iostream>
#include <vector>
using namespace std;
int main() {
    vector<int> v = {1,2,3};
    for(int x : v) cout << x << " ";
    return 0;
}
EOF
g++ -o testcpp test.cpp         # Must compile
./testcpp                       # Must run
```

### Phase 4: Real-World Test
Compile a real project (e.g., BerrySnip!)

---

## Current Status

**Removed from BerryCore Ports:**
- ❌ Removed from `ports/INDEX`
- ❌ Removed from `berrycore/CATALOG`
- ❌ Deleted `dev-gcc-arm-9.3.0.zip`

**User Cleanup:**
On Passport, run:
```bash
sh REMOVE_GCC_ARM.sh
```

This will:
- Remove GCC 9.3.0 binaries
- Remove corrupted specs file
- Restore working GCC 4.6.3

**Recommendation:**
Use GCC 4.6.3 until we can properly build/test GCC 9.3.0.

---

## Alternative: Package GCC 4.6.3

Since 4.6.3 works perfectly, we could:

1. Find where it's installed on BB10
2. Package it as `dev-gcc-4.6.3.zip`
3. Add to ports for users who need compiler

**Pros:**
- Already works
- Well-tested
- Properly configured

**Cons:**
- Older version (but sufficient for most tasks)
- May already be in base system

---

## Future Work

1. **Investigate QNX Momentics SDK**
   - Check if it includes ARM GCC 9.x
   - Test if those binaries work on BB10

2. **Test Different GCC Versions**
   - Try GCC 7.x (might be more compatible)
   - Try GCC 8.x
   - Stick with 4.6.3 if others fail

3. **Consider Clang/LLVM**
   - Modern alternative to GCC
   - Might have better QNX support
   - Worth investigating

4. **Document Working GCC**
   - Analyze GCC 4.6.3 configuration
   - Extract its specs file
   - Use as template for newer versions

---

## Contact / Notes

**Tested On:** BlackBerry Passport (QNX 8)  
**BerryCore Version:** 0.72  
**Test Date:** November 2025  
**Status:** Port removed, awaiting proper rebuild

**Working Compiler:** GCC 4.6.3 (base system)  
**Blocked Port:** GCC 9.3.0 (process spawn + endian issues)

---

**Note to maintainers:** Do not re-add gcc-arm port until all Phase 1-4 tests pass on actual BB10 hardware!

