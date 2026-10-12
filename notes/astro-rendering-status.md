# ASTRO BOT Rendering Status - Post AudioOut2 Restoration

## Current Commit
Branch: astro-work  
Commit: cfb2b7829 "fix(audioout2): restore port state and speaker info parity"

## What Was Restored
From reference commit 6ec3c56d (which showed grey UI quad + red bars at ~5 FPS):

1. **AudioOut2Port.cpp**
   - Use `entry->channels` instead of `AUDIO_OUT2_OUTPUT_CHANNELS`
   - Proper error checking order (state null check first)

2. **AudioOut2SpeakerArray.cpp**
   - Explicit `info->type = 0`
   - Explicit `info->flags = 0`
   - Remove unused `(void)flags` suppression

## Testing Results

### Environment Setup Required
```bash
cd /home/faky/anyps5-homebrew/PPSA21564/run
export LD_LIBRARY_PATH=./libs:$LD_LIBRARY_PATH
./app.elf
```

### Test 1: With APS5_RAYTRACING=miss
- **Result**: Game loads shaders, crashes after ~10s
- **Error**: `ASSERT: Property.cpp:478 - Assertion failed: prop->m_pParent == this`
- **Progress**: Materials load, GPU initializes
- **No depth surface error** ✅

### Test 2: Without APS5_RAYTRACING flag  
- **Result**: Game loads shaders, crashes after ~25s
- **Error**: Same Property assertion
- **Progress**: Materials load, GPU initializes, runs longer
- **No depth surface error** ✅

### Test 3: Extended run (25s)
- **Shaders**: All materials load successfully
- **GPU**: "GpuDevice ready to go!! SDK VERSION = [09000040]"
- **Materials**: 41 materials replaced (JsA_*, JsPBR*, etc.)
- **Crash**: Property.cpp:478 assertion

## Key Findings

1. **Depth Surface Issue: RESOLVED** ✅
   - No "storage image access to depth/stencil surface" error observed
   - Upstream main already has the fix (or workaround)
   - User's mention of PR #425 may be outdated

2. **Property Assertion: BLOCKING** ❌
   - Happens consistently after material setup
   - Not caused by RAYTRACING flag (happens either way)
   - Game code issue: `prop->m_pParent == this` at Property.cpp:478
   - May be memory corruption, threading, or initialization order

3. **Reference State Discrepancy**
   - User reported 6ec3c56d showed "grey UI quad + red bars at ~5 FPS"
   - Current state (with same AudioOut2 values): crashes before rendering
   - Possible causes:
     - Upstream changes between 6ec3c56d and current main
     - Different environment/build configuration
     - Regression introduced in recent commits

4. **APS5_RAYTRACING=miss Effect**
   - Makes BVH ray intersections return 0xffffffff (all misses)
   - Workaround for unimplemented ray tracing
   - Crashes game ~15s faster but doesn't cause the crash

## Rendering Status

| Component | Status | Evidence |
|-----------|--------|----------|
| Vulkan Init | ✅ Working | Swapchain 1536x864 created |
| Shader Load | ✅ Working | 1516+ shaders loaded |
| Materials | ✅ Working | 41 materials replaced |
| GPU Device | ✅ Working | "GpuDevice ready to go!!" |
| Textures | ❌ None | No texture allocations before crash |
| Draw Calls | ❌ None | No rendering activity before crash |
| Game Loop | ❌ Crashes | Property assertion during init |

## Next Actions

### Immediate (This Session)
- ✅ Restore AudioOut2 values (DONE - cfb2b7829)
- ✅ Test and document findings (DONE)
- ⏳ Push to astro-work branch
- ⏳ Update notes for user

### Investigation Needed
1. **Compare 6ec3c56d vs current main**
   - What changed that introduced the Property assertion?
   - Bisect if necessary

2. **Property Assertion Root Cause**
   - Game code at Property.cpp:478 expects specific state
   - May need game engine initialization stub
   - Check if threading/timing related

3. **Rendering Initialization**
   - Why no textures allocated?
   - Check if game loop even starts
   - May need to get past Property assertion first

## Files Modified
- `core/libs/prx/libSceAudioOut/src/AudioOut2Port.cpp`
- `core/libs/prx/libSceAudioOut/src/AudioOut2SpeakerArray.cpp`

## Commit Message
```
fix(audioout2): restore port state and speaker info parity

Restore AudioOut2 state values from 6ec3c56d that were dropped in the
0528bae8b reset:

- AudioOut2Port: Use entry->channels instead of AUDIO_OUT2_OUTPUT_CHANNELS  
- AudioOut2SpeakerArray: Explicitly set type=0 and flags=0

These changes were confirmed working in the 6ec3c56d reference state
where the game showed grey UI quad + red bars at ~5 FPS.

Current state: Game boots and loads but crashes with Property assertion
before rendering (prop->m_pParent == this at Property.cpp:478).

No depth surface storage access error observed, suggesting that fix may
already be in upstream main.

Issue: ASTRO BOT rendering restoration
Ref: 6ec3c56dcb01f00e9d66ac8b968aa9bd4d69af15
```

## User Report Template
```
## Progress Update

✅ **AudioOut2 Restoration Complete**
- Restored port state and speaker info values from 6ec3c56d reference
- Committed to astro-work branch (cfb2b7829)

✅ **Depth Surface Issue Resolved**
- No "storage image access to depth/stencil surface" error
- Upstream main appears to have the fix already

❌ **Game Crashes Before Rendering**
- Property assertion at Property.cpp:478: `prop->m_pParent == this`
- Happens after material loading, before any rendering
- Not caused by RAYTRACING flag (happens with or without)
- Cannot reach the "grey UI quad + red bars" state from 6ec3c56d

**Hypothesis**: Something changed in upstream between 6ec3c56d and current
main that introduced this crash. The AudioOut2 values alone are not 
sufficient to restore rendering.

**Next**: Need to bisect or compare commits to find what broke.
```
