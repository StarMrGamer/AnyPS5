# ASTRO BOT Rendering Regression Recovery Plan

## Current State
- Branch: astro-work (commit 0528bae8b)
- Game boots at 60 FPS but renders FULLY BLACK
- Previous state (6ec3c56d): grey UI quad + red bars at ~5 FPS

## Reference State (6ec3c56d) - What Was Dropped
1. **AudioOut2Port.cpp**: 
   - `state->portType` was set (now missing)
   - `state->num_channels = entry->channels` (now uses AUDIO_OUT2_OUTPUT_CHANNELS)
   
2. **AudioOut2SpeakerArray.cpp**:
   - `info->speakerArray` was set (now missing)
   - `info->type` explicitly set to SpeakerTypeStereo
   - `info->flags = 0` explicitly (now implicit zero-init)

## Known Issues to Fix
1. **AudioOut2 State Restoration** (from 6ec3c56d)
2. **Compute shader depth-surface storage access** (upstream #1409, fix #425 unmerged)
3. **APS5_RAYTRACING=miss** requirement
4. **Later crash**: 'Assertion failed: prop->m_pParent == this'

## Action Plan
1. Check upstream #1409 and #425 for depth-surface fix
2. Restore AudioOut2 values from 6ec3c56d
3. Test with APS5_RAYTRACING=miss
4. Document A/B comparison
5. Push to astro-work branch

## Investigation Started
- Checking upstream issues...
