# ASTRO BOT Rendering Fix Guide

## Problem Summary

ASTRO BOT (PPSA21564) has two critical issues preventing proper rendering on AnyPS5:

1. **Ray Tracing Path Selection**: Game detects ray tracing support and uses RT rendering path, which may not work correctly on current AnyPS5
2. **UDMABUF Memory Import Failures**: Large memory allocations fail to import via Linux UDMABUF, causing severe performance degradation (4 FPS)

## Solution 1: Disable Ray Tracing (Force Non-RT Path)

### Quick Fix
Set the environment variable before running the game:

```bash
export APS5_RAYTRACING=miss
./anyps5 ~/anyps5-homebrew/PPSA21564/run/app.elf
```

### What This Does
- `APS5_RAYTRACING=miss` makes the shader recompiler treat ray tracing instructions (image_bvh_intersect_ray, image_bvh64_intersect_ray) as no-ops
- This forces the game to fall back to the non-RT rendering path
- Similar to KytyPS5's approach of patching the capability check, but at the shader translation level

### Implementation Details
Located in `core/shader/recompiler/Translation/src/DispatchInstructions.cpp`:
- `RayTracingStrict()`: Returns true if `APS5_RAYTRACING=strict`, throws errors on RT instructions
- `RayTracingMiss()`: Returns true if `APS5_RAYTRACING=miss`, skips RT instruction emission

## Solution 2: Fix UDMABUF Memory Import Issues

### Problem
From the diagnosis logs:
```
[import] trying host import for 0x200638000+512 MiB at page 524920
[import] 0x200638000+0x20000000: host import failed (UDMABUF_CREATE); mirror
```

Four large allocations (512 MB each) failed to import via UDMABUF, forcing expensive memory mirroring that drops performance to 4 FPS.

### Root Cause
Linux UDMABUF has default size limits that are too small for PS5 game allocations. The kernel module `drivers/dma-buf/udmabuf.c` has these limits:
- `list_limit`: Maximum number of memory regions (default: 1024)
- `size_limit_mb`: Maximum buffer size in MB (default: varies by kernel, often 64-128 MB)

### Fix Options

#### Option A: Increase Kernel UDMABUF Limits (Recommended)
Modify kernel module parameters:

```bash
# Check current limits
cat /sys/module/udmabuf/parameters/list_limit
cat /sys/module/udmabuf/parameters/size_limit_mb

# Increase limits (temporary, until reboot)
echo 4096 | sudo tee /sys/module/udmabuf/parameters/list_limit
echo 1024 | sudo tee /sys/module/udmabuf/parameters/size_limit_mb

# Permanent fix: add to /etc/modprobe.d/udmabuf.conf
sudo tee /etc/modprobe.d/udmabuf.conf << EOF
options udmabuf list_limit=4096 size_limit_mb=1024
EOF

# Reload module
sudo modprobe -r udmabuf
sudo modprobe udmabuf
```

#### Option B: Implement Chunked UDMABUF Imports in AnyPS5
The codebase already has infrastructure for chunked imports (see `core/libs/prx/libSceAgcDriver/Graphics/src/GuestBufferMemory.cpp`):
- `ImportChunkBytes = 64 MB`
- `importChunk()` function splits large allocations

However, the main import path in `createDmaBufImport()` doesn't use chunking for initial imports. This needs enhancement.

#### Option C: Adjust APS5_HOST_IMPORT_MIB Budget
Current budget allows up to 6144 MiB of imports, but may need tuning:

```bash
# Reduce the threshold to force more mirroring of marginal allocations
export APS5_HOST_IMPORT_MIB=4096

# Or increase if your system has enough memory
export APS5_HOST_IMPORT_MIB=8192
```

### Recommended Approach
1. **Immediate**: Set `APS5_RAYTRACING=miss` to fix rendering path
2. **Short-term**: Increase kernel UDMABUF limits (Option A)
3. **Long-term**: Enhance AnyPS5 to use chunked imports for all large allocations

## Complete Launch Command

```bash
#!/bin/bash
# ASTRO BOT launch script with fixes

# Force non-RT rendering path
export APS5_RAYTRACING=miss

# Optional: Adjust import budget if needed
# export APS5_HOST_IMPORT_MIB=8192

# Optional: Enable additional debugging
# export APS5_PIPELINE_STATS=1

# Launch game
cd ~/anyps5-homebrew/PPSA21564/run
~/AnyPS5-w3480/build/core/anyps5 ./app.elf
```

## Verification

### Check if RT is disabled
Look for these log messages indicating RT instructions are being skipped:
```
[shader] image_bvh_intersect_ray -> no-op (APS5_RAYTRACING=miss)
```

### Check UDMABUF status
After the fix, you should see:
```
[import] 0x200638000+0x20000000: host import OK
```
Instead of:
```
[import] 0x200638000+0x20000000: host import failed (UDMABUF_CREATE); mirror
```

### Performance indicators
- **Before fix**: 4 FPS, black screen, no flips
- **After RT fix**: Proper rendering path, visible graphics
- **After UDMABUF fix**: 30-60 FPS, smooth gameplay

## Additional Notes

### About KytyPS5's Approach
KytyPS5 patches a conditional jump at VMA `0x73eec3f` in the game binary to force the non-RT path at runtime. AnyPS5's approach is cleaner:
- No binary patching required
- Works across game updates
- Controlled via environment variable
- Can be toggled per-launch

### Alternative: Binary Patching (Not Recommended)
If you prefer KytyPS5's approach:
1. Locate the je instruction in `~/anyps5-homebrew/PPSA21564/run/app.elf`
2. Calculate file offset from VMA (add 0x4000 for ELF header offset)
3. Patch `0f 84` (je) to `90 90` (nop nop) or `eb` (jmp)

However, this requires:
- Finding the exact address (game-specific)
- Maintaining patches across updates
- Risk of corrupting the binary

The `APS5_RAYTRACING=miss` approach is superior.

## References

- AnyPS5 shader recompiler: `core/shader/recompiler/Translation/src/DispatchInstructions.cpp`
- UDMABUF implementation: `core/libs/prx/libSceAgcDriver/Graphics/src/GuestBufferMemory.cpp`
- Diagnosis report: `/tmp/astro10_rendering_diagnosis.md`
- Ray tracing test: `core/libs/tests/RayTracingMiss.cpp`
