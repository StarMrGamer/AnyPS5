# ASTRO BOT Black Scene Fix - Implementation Report

## Mission
Get ASTRO BOT's black scene rendering using the community lead from issue #3961: apply PR #425 (depth surfaces as textures/storage images) + format 122 relaxation in DepthSurface.cpp.

## Changes Applied to astro-work Branch

### 1. Merged PR #425
Merged `feat(agc): depth surfaces read as textures and storage images` into astro-work.
- **Files changed**: DepthSurface.hpp, DepthSurface.cpp, Texture.hpp, Texture.cpp, ShaderResources.cpp
- **Changes**: Depth surfaces can now be:
  - Sampled as 2D arrays, cubes, or R16_UINT integer views
  - Accessed as storage images (per-layer transfer through staging buffer)
  - Used as transfer sources

### 2. Added Format 122 Relaxation
Modified `DepthSurface.cpp` line 137 to allow `VK_FORMAT_B10G11R11_UFLOAT_PACK32` (format 122) for storage access.

**Before:**
```cpp
const bool sized = d16 ? (...) : (storageFormat == VK_FORMAT_R32_SFLOAT || storageFormat == VK_FORMAT_R32_UINT || storageFormat == VK_FORMAT_R32_SINT);
```

**After:**
```cpp
const bool sized = d16 ? (...) : (storageFormat == VK_FORMAT_R32_SFLOAT || storageFormat == VK_FORMAT_R32_UINT || storageFormat == VK_FORMAT_R32_SINT || storageFormat == VK_FORMAT_B10G11R11_UFLOAT_PACK32);
```

**Rationale**: ASTRO BOT's compute shader 0x500798d00 binds depth surface 0x53a500000 (960x540) as storage image in guest format 36 (B10G11R11_UFLOAT). This relaxation allows processing all mip levels (1920x1080 down to 30x16) for the depth downsample pass.

## Current State (astro-work Branch)

- Base: d146ec1b6 (Oct 12, 2026)
- ASOBI_ROOT environment variable (0528bae8b)
- AudioOut2 state parity fixes (cfb2b7829)
- PR #425 depth surface changes (3968fa1f7)
- Format 122 relaxation (ac71a7de1)

## Test Results

### Build Status
- **Build**: ✅ Successful (ninja completed with warnings only)
- **Conventions**: ✅ Pass (`check_conventions.py`)
- **Test Registration**: ✅ Pass (`check_test_registration.py`)
- **CTest**: ⚠️ 927/930 tests pass (99%)
  - **Failed**: 
    - `patched_libraries` (known issue)
    - `agc_driver_pixel_interlock` (known issue)
    - `linux_guest_stack` (known issue - host quirk)

### Runtime Test

**Environment:**
```bash
LD_LIBRARY_PATH=/home/faky/AnyPS5-w3480/build/core/libs/libs
APS5_RAYTRACING=miss
APS5_HOST_IMPORT_MIB=16384
```

**Result**: ❌ Property assertion before rendering phase
```
ASSERT: D:\asobi\6.0\source\engine\app\Module\System\Property.cpp:478
Assertion failed: prop->m_pParent == this
```

**Progress**:
- Loaded 41 materials
- Set up shader binaries
- GPU device initialized
- Threads spawned
- **Stopped at**: Property tree assertion (title-side issue)

## Issue Analysis

### The Property Assertion (Issue #4317)
The `prop->m_pParent == this` assertion is a **title-side** issue in ASTRO BOT's property tree system, not an emulator bug. According to issue #4317 investigation:

- The assertion fires when the title's audio device classification code receives unexpected values
- With "reported values" (real port state from AudioOut2), the assertion should not fire
- Current astro-work has the AudioOut2 fixes that provide reported values

### Why We Can't Test the Black Scene Fix Yet

The black scene issue (compute shader 0x500798d00 needing storage access to depth surface 0x53a500000) occurs **after** audio init, in the rendering loop. The property assertion fires **during** audio init, blocking us from reaching the rendering phase.

From issue #3961 comment by Kikoarl:
> "With those two in place [APS5_HOST_IMPORT_MIB=16384 + PR #425 + format 122], the black frame disappears and full 3D rendering / title sequences display stably (tested 670+ frames rendered at 14+ FPS)."

This was tested on a state where the property assertion did not fire.

### What the A/B Tests Showed

Recent A/B matrix tests on issue #4317 found that minimal configurations run clean:
- **Test 1**: Base d146ec1b6 + only %VAR% expansion → No assertion (150s, rendering reached)
- **Test 2**: Base 1be0a7ce9 + only ASOBI_ROOT → No assertion (150s, rendering reached)

Current astro-work has:
- Base d146ec1b6 ✓
- ASOBI_ROOT ✓
- AudioOut2 changes ← This combination may be creating the assertion

## Diagnosis: Cannot Verify Black Scene Fix

**The depth surface storage fix cannot be verified** because the title crashes with the property assertion before reaching the rendering loop where compute shader 0x500798d00 would execute.

To verify the black scene fix, we would need to either:
1. Resolve the property assertion issue first
2. Test on a different base/configuration that doesn't trigger the assertion
3. Get community feedback from someone who has a working state

## Files Modified

```
core/libs/prx/libSceAgcDriver/Graphics/include/DepthSurface.hpp
core/libs/prx/libSceAgcDriver/Graphics/include/Texture.hpp  
core/libs/prx/libSceAgcDriver/Graphics/src/DepthSurface.cpp
core/libs/prx/libSceAgcDriver/Graphics/src/ShaderResources.cpp
core/libs/prx/libSceAgcDriver/Graphics/src/Texture.cpp
```

## Commits

- `3968fa1f7` Merge branch 'pr-425-temp' into astro-work
- `ac71a7de1` feat(agc): allow B10G11R11_UFLOAT_PACK32 storage access to depth surfaces

## Screenshots

- Before: `/home/faky/AnyPS5-w3480/notes/astrobot-before.png` (window before test)
- After: Not captured - title crashed before rendering

## Next Steps

1. **Resolve property assertion**: Investigate why AudioOut2 + ASOBI_ROOT combination triggers the assertion when minimal patches don't
2. **Alternative test**: Build on 1be0a7ce9 + ASOBI_ROOT + PR #425 + format 122 (known clean from A/B test)
3. **Community collaboration**: Reach out to Kikoarl or others who reported successful rendering to understand their exact configuration

## Status

✅ PR #425 applied successfully  
✅ Format 122 relaxation added  
✅ Build successful  
✅ Tests pass (99%)  
❌ Runtime verification blocked by property assertion  
⚠️ Black scene fix cannot be verified in current state
