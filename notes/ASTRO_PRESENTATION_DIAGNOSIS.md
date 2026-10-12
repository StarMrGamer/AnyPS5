# ASTRO BOT Presentation Diagnosis

## Summary
**Status: WORKING** - ASTRO BOT (PPSA21564) is successfully presenting frames to the display.

## Investigation Results

### Root Cause Analysis
The initial report suggested that ASTRO BOT was not presenting frames. Investigation revealed that presentation **is working correctly**, but the game uses an unconventional presentation method.

### Key Findings

1. **Flip Submission Method**
   - The game does NOT call `sceVideoOutSubmitFlip()` directly
   - Instead, it writes flip packets (PM4 command `0xc004105c`) directly into GPU command buffers
   - These flip packets are processed by the AGC driver when the command buffer is submitted
   - This is a valid presentation method used by some PS5 games

2. **Presentation Flow**
   ```
   Game → GPU Command Buffer (with flip packet) 
        → sceAgcDriverSubmitDcb() 
        → Driver processes flip packet 
        → VideoOutDriver::processFlip() 
        → AgcDriver::Present() 
        → Vulkan presentation 
        → Window display
   ```

3. **Window Configuration**
   - Window created successfully: 1536x864 (scaled from 4K source)
   - Video driver: X11
   - Source resolution: 3840x2160 (4K)
   - Flip buffers: 2 buffers (indices 0 and 1)
   - Flip mode: 1 (standard vsync flip)

4. **Verification**
   - Flip packets are received and processed: ✓
   - VideoOut buffers registered: ✓ (2 buffers at 4K resolution)
   - Window created with SDL_WINDOW_SHOWN: ✓
   - Vulkan surface attached: ✓
   - AgcDriver::Present() called successfully: ✓
   - Frames alternating between buffer indices 0 and 1: ✓

### Game Import Analysis
The game imports 11 VideoOut functions:
- sceVideoOutOpen
- sceVideoOutClose
- sceVideoOutRegisterBuffers2
- sceVideoOutGetOutputStatus
- sceVideoOutGetVblankStatus
- sceVideoOutSubmitChangeBufferAttribute2
- sceVideoOutSetBufferAttribute2
- sceVideoOutIsFlipPending
- sceVideoOutAddFlipEvent
- sceVideoOutColorSettingsSetGamma_
- sceVideoOutAdjustColor_

**Notable absence:** `sceVideoOutSubmitFlip` - confirming the game uses GPU command buffer flips instead.

## Conclusion

ASTRO BOT is presenting frames correctly through the GPU command buffer flip mechanism. The presentation system in AnyPS5 fully supports this method and is working as designed.

The window is visible and actively rendering when the game runs. No bugs or missing functionality were found.

## Technical Notes

- This flip method is more direct than the API call method, giving games finer control over presentation timing
- The flip packets include the VideoOut handle, buffer index, flip mode, and flip argument
- Each flip is synchronized with vblank as expected for flip mode 1
- The resolution scaling from 4K to window size is handled correctly by the presentation layer
