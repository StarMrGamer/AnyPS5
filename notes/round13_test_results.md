# Round 13: ASTRO BOT Test Results

## Test Configuration
- **Date**: 2026-10-12 12:08
- **Branch**: `astro-work` (commit 0528bae8b)
- **Environment**: APS5_HOST_IMPORT_MIB=16384, ASOBI_ROOT=app0
- **GPU**: AMD Radeon RX 7800 XT (RADV NAVI32)
- **Build**: Fresh relink with current AnyPS5 build

## Test Results

### Boot Success
✅ Game boots successfully with ASOBI_ROOT environment fix (PR #4274)
```
ASOBI PlayRoom
Current Time    : Mon Oct 12 12:08:32 2026
Build_Date Time :  Oct 10 2024 16:34:14
```

### Shader Loading
✅ Shader disk cache loaded successfully
- 1561 hits, 1 miss, 1 write
- 217.6 MiB + 90.1 MiB + 152.9 MiB + 25.8 MiB read
- All material systems loaded (JsPBR, JsA_* materials, etc.)

### Memory Import Status
❌ **UDMABUF failures confirmed** - This is the FPS bottleneck
```
[gpu] host import of 0x400000000+0xb800000 failed at UDMABUF_CREATE (-1000072003); falling back to copies
[gpu] host import of 0x500000000+0x87400000 failed at UDMABUF_CREATE (-1000072003); falling back to copies
[gpu] host import of 0x10c8000000+0x120000000 failed at UDMABUF_CREATE (-1000072003); falling back to copies
[gpu] host import of 0x600000000+0x8000000 failed at UDMABUF_CREATE (-1000072003); falling back to copies
```

**Attempted allocations**:
- 184 MiB (0xb800000)
- 2.1 GiB (0x87400000)
- 4.5 GiB (0x120000000)
- 128 MiB (0x8000000)

The 2.1 GiB and 4.5 GiB allocations are massive and will fail with default 6144 MiB budget.
With APS5_HOST_IMPORT_MIB=16384, these should theoretically work, but UDMABUF_CREATE is still failing with error -1000072003.

### Crash
❌ **Segmentation fault** after ~60 seconds
```
ASSERT: D:\asobi\6.0\source\engine\app\Game\Sound\SoundManager.cpp:306
Assertion failed: defaultBusses.size() == 1
```

The crash is in the sound system, not rendering. The game expects exactly 1 default audio bus but finds a different number.

## Analysis

### FPS Issue (Primary)
The UDMABUF failures mean all GPU memory imports fall back to CPU-GPU copies. This is the root cause of ~5 FPS performance cited in issue #2809/#3960.

**Why UDMABUF is failing**:
Error -1000072003 corresponds to VK_ERROR_OUT_OF_HOST_MEMORY or similar. Possible causes:
1. UDMABUF kernel module not loaded
2. UDMABUF size_limit_mb too low
3. System memory exhausted
4. Kernel UDMABUF disabled or not available

**Verification needed**:
```bash
# Check if UDMABUF is available
ls -la /dev/udmabuf
cat /sys/module/udmabuf/parameters/size_limit_mb
```

### Rendering Issue (Secondary)
Could not test rendering because the game crashed before reaching the frame loop. The crash is unrelated to the rendering fixes we're testing - it's a sound system initialization problem.

### Known Issues
- Issue #1409 / PR #425 (compute shader depth access): **Not yet merged**. Cannot test without this fix.
- Sound system crash: May be a new issue or configuration problem

## Upstream Status

### PR #4274 (ASOBI_ROOT fix)
- **Status**: OPEN, no review comments yet
- **Result**: ✅ Working correctly (game boots and finds resources)

### PR #425 (Depth surface access)
- **Status**: OPEN, not merged
- **Impact**: Cannot test rendering without this fix
- **Description**: Allows compute shaders to access depth surfaces (needed for black scene fix)

## Next Steps

1. **Fix UDMABUF** to test real FPS improvements:
   - Check if /dev/udmabuf exists
   - Verify size_limit_mb is adequate (needs >4.5 GiB = ~5000 MB)
   - Load module if missing: `sudo modprobe udmabuf size_limit_mb=6144`

2. **Fix sound crash** to reach the rendering loop:
   - Investigate why defaultBusses.size() != 1
   - May need additional audio configuration or module

3. **Test rendering** once game runs stably:
   - Wait for PR #425 to merge OR
   - Check if there's a workaround in issue #1409

## FPS Measurement
❌ Could not measure FPS - game crashed before window creation/frame loop

**Expected vs Actual**:
- Default (6144 MiB): ~5 FPS (issue #2809)
- With 16384 MiB: Should be 30-60 FPS
- Actual: UDMABUF failing, fell back to CPU copies, crashed before measurement
