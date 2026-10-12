# Round 13 Final Report: ASTRO BOT Rendering Investigation

## Executive Summary

✅ **PR #4274 (ASOBI_ROOT fix)**: Working perfectly - game boots and finds all resources  
❌ **FPS Testing**: Blocked by UDMABUF misconfiguration (64 MB limit, need 6+ GB)  
❌ **Rendering Testing**: Blocked by sound system crash before frame loop  
⏳ **PR #425 (depth surface fix)**: Still open upstream, not yet merged  

## Test Environment

**Branch**: `astro-work` (commit 0528bae8b)  
**Date**: 2026-10-12 12:08 UTC  
**GPU**: AMD Radeon RX 7800 XT (RADV NAVI32), 16 GB VRAM  
**System RAM**: 16 GB DDR5-5600  
**Config**: APS5_HOST_IMPORT_MIB=16384, ASOBI_ROOT=app0  

## Mission Results

### 1. FPS Measurement with APS5_HOST_IMPORT_MIB=16384

**Status**: ❌ BLOCKED - Could not measure FPS

**Root Cause**: UDMABUF misconfiguration prevents memory imports

```
UDMABUF size limit:     64 MB (actual)
Game requirement:       4.5 GB (largest allocation)
Recommended minimum:    6144 MB (6 GB)
User kvm group access:  NO (device is crw-rw----+ root:kvm)
```

**Failed allocations**:
```
[gpu] host import of 0x400000000+0xb800000 failed      (184 MB)
[gpu] host import of 0x500000000+0x87400000 failed     (2116 MB)
[gpu] host import of 0x10c8000000+0x120000000 failed   (4608 MB)
[gpu] host import of 0x600000000+0x8000000 failed      (128 MB)
```

All imports fell back to CPU-GPU copies, causing the ~5 FPS bottleneck described in issues #2809 and #3960.

**Fix Required** (needs sudo):
```bash
# Increase UDMABUF size limit
echo 6144 | sudo tee /sys/module/udmabuf/parameters/size_limit_mb

# Grant user access
sudo usermod -aG kvm $USER
# OR
sudo chmod 666 /dev/udmabuf

# Make permanent (add to /etc/modprobe.d/udmabuf.conf)
echo "options udmabuf size_limit_mb=6144" | sudo tee /etc/modprobe.d/udmabuf.conf
```

**Cannot proceed with FPS testing** until UDMABUF is configured correctly.

### 2. Check Upstream PR #425 (Compute Shader Depth Access)

**Status**: ❌ OPEN, not merged

```json
{
  "state": "OPEN",
  "mergedAt": null,
  "title": "feat(agc): depth surfaces read as textures and storage images",
  "url": "https://github.com/boykopovar/AnyPS5/pull/425"
}
```

**What it fixes**: Allows compute shaders to read depth surfaces as storage images (issue #1409)  
**Impact for ASTRO BOT**: Fixes the "black scene" rendering issue  
**Action**: Did NOT attempt to merge or implement ourselves (per mission rules)  

**Cannot test rendering improvements** until PR #425 is merged upstream.

### 3. Monitor PR #4274 (ASOBI_ROOT Environment Fix)

**Status**: ✅ OPEN, no review comments

```json
{
  "state": "OPEN",
  "comments": [],
  "reviews": []
}
```

**Test Result**: ✅ **Working perfectly**

The game successfully:
- Boots with ASOBI_ROOT=app0
- Resolves all /host/%ASOBI_ROOT%/ paths
- Loads resources from app0/target/data/
- Initializes GPU, shaders, and materials

```
[src/Open.cpp:219 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/app/ppr/app_sys/DebugFont.gnfp
[src/Open.cpp:219 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/system/gfx/sys_decal_water.gnfp
[src/Open.cpp:219 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/system/gfx/sys_cloud_noise.gnfp
```

All paths resolved correctly. No path-related errors.

**No action needed** - waiting for upstream review.

### 4. Game Runtime Status

**Boot**: ✅ Successful  
**Shader Loading**: ✅ 1561 shaders from cache  
**Material Systems**: ✅ 46 materials loaded (JsPBR, JsA_*, etc.)  
**GPU Init**: ✅ Vulkan device ready  
**Memory Imports**: ❌ UDMABUF failed, fell back to copies  
**Frame Loop**: ❌ Crashed before reaching  

**Crash Details**:
```
ASSERT: D:\asobi\6.0\source\engine\app\Game\Sound\SoundManager.cpp:306
Assertion failed: defaultBusses.size() == 1
Segmentation fault (core dumped)
```

The sound system expects exactly 1 default audio bus but finds a different count. This is unrelated to rendering or FPS issues - it's an audio initialization problem that prevents the game from reaching the main loop.

## FPS Comparison: Before vs After

**Status**: ❌ Could not measure - game crashed before frame loop

**Expected (from community reports)**:
- Default (6144 MiB): ~5 FPS (CPU-GPU copy bottleneck)
- With 16384 MiB: 30-60 FPS (native performance)

**Actual**:
- With 16384 MiB env var: UDMABUF still failed (limit too low), fell back to CPU copies
- Crashed before window/FPS measurement possible

## Rendering State

**Status**: ❌ Could not test - game crashed before frame loop

**Known Issues**:
1. **Black scene** (issue #1409): Compute shader cannot access depth surface as storage image
   - Fix: PR #425 (still open)
   - Status: Not merged, not tested
2. **Low FPS** (issues #2809, #3960): Memory import failures force CPU-GPU copies
   - Fix: APS5_HOST_IMPORT_MIB=16384 + UDMABUF size_limit_mb ≥6144
   - Status: Environment variable set, but UDMABUF misconfigured

**Cannot validate rendering** until:
1. UDMABUF is configured (for stable frame loop)
2. Sound crash is fixed (to reach frame loop)
3. PR #425 is merged (for depth surface fix)

## What Remains

### Immediate Blockers
1. **UDMABUF Configuration** (requires sudo):
   - Current: 64 MB limit
   - Required: 6144 MB minimum
   - User needs kvm group access or chmod 666

2. **Sound System Crash**:
   - Assertion: `defaultBusses.size() == 1`
   - Location: Sound/SoundManager.cpp:306
   - Needs investigation - may require additional audio module or configuration

### Pending Upstream
3. **PR #425**: Depth surface storage access (for black scene fix)
   - Status: Open, not merged
   - Cannot test rendering improvements without this

### Verified Working
✅ **PR #4274**: ASOBI_ROOT environment variable
   - Game boots successfully
   - All resource paths resolve correctly
   - No review comments yet

## Screenshots

❌ No screenshots captured - game crashed before window creation

Expected flow:
1. Window appears with title showing FPS
2. Screenshot with `spectacle -b -n -o notes/shot_round13.png`
3. Compare FPS before/after UDMABUF fix

Actual:
- Game crashed ~60 seconds into boot
- No window created
- No FPS measurement possible

## Recommendations

### For System Administrator
```bash
# Required: Fix UDMABUF (needs sudo)
sudo modprobe udmabuf size_limit_mb=6144
sudo usermod -aG kvm faky
# User must log out/in for group to take effect

# OR as temporary fix
sudo chmod 666 /dev/udmabuf
```

### For Testing
1. Fix UDMABUF configuration
2. Investigate sound system crash (may need libSceNgs2 fixes or audio config)
3. Retest once PR #425 merges upstream
4. Measure FPS with/without 16384 MiB setting

### For PR #4274
- Monitor for review comments (none yet)
- Be ready to address feedback if requested
- No changes needed to the fix itself - it works correctly

## Conclusion

**PR #4274 Status**: ✅ Working perfectly, awaiting review  
**FPS Testing**: ❌ Blocked by UDMABUF misconfiguration (admin intervention required)  
**Rendering Testing**: ❌ Blocked by sound crash + PR #425 not merged  
**System State**: Stable on `astro-work` branch with all fixes intact  

The ASOBI_ROOT fix (PR #4274) is confirmed working. The FPS and rendering issues cannot be tested due to system configuration (UDMABUF) and an unrelated sound system crash that prevents the game from reaching the frame loop.

**Real numbers achieved**: 0 FPS (crashed before frame loop)  
**Cannot proceed** without sudo access to fix UDMABUF and further investigation of the sound crash.
