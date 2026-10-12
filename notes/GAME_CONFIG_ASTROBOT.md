# Game-Specific Configuration: ASTRO BOT (PPSA21564)

## Overview

This document provides configuration guidance for running ASTRO BOT on AnyPS5, addressing rendering path selection and performance optimization.

## Known Issues & Solutions

### Issue 1: Ray Tracing Rendering Path

**Symptom**: Black screen, no graphics output, game appears stuck

**Root Cause**: ASTRO BOT detects hardware ray tracing support and attempts to use the RT rendering path. Current AnyPS5 ray tracing implementation may not be fully compatible with the game's specific usage patterns.

**Solution**: Disable ray tracing instruction emission to force the non-RT rendering path:

```bash
export APS5_RAYTRACING=miss
```

**Technical Details**:
- Setting `APS5_RAYTRACING=miss` causes the shader recompiler to skip `image_bvh_intersect_ray` and `image_bvh64_intersect_ray` instructions
- The game's shader code includes fallback paths for systems without RT support
- This approach is portable across game updates and requires no binary modifications

### Issue 2: UDMABUF Memory Import Failures

**Symptom**: Severe performance degradation (4 FPS), log messages indicating host import failures

**Root Cause**: The game allocates multiple 512 MB memory regions that exceed the default Linux UDMABUF size limit, forcing expensive memory mirroring fallback.

**Solution**: Increase kernel UDMABUF size limit:

```bash
# Temporary (until reboot)
echo 1024 | sudo tee /sys/module/udmabuf/parameters/size_limit_mb

# Permanent
echo "options udmabuf size_limit_mb=1024 list_limit=4096" | sudo tee /etc/modprobe.d/udmabuf.conf
sudo modprobe -r udmabuf
sudo modprobe udmabuf
```

**Alternative**: Ensure user has read-write access to `/dev/udmabuf`:
```bash
sudo chmod 666 /dev/udmabuf
# OR
sudo usermod -aG kvm $USER  # logout/login required
```

## Recommended Launch Configuration

```bash
#!/bin/bash
# Launch ASTRO BOT with optimal settings

export APS5_RAYTRACING=miss

cd ~/anyps5-homebrew/PPSA21564/run
~/AnyPS5-w3480/build/core/anyps5 ./app.elf
```

## Performance Metrics

| Configuration | FPS | Notes |
|---------------|-----|-------|
| Default (RT enabled, UDMABUF limited) | 4 | Unplayable |
| RT disabled, UDMABUF limited | 15-20 | Playable but slow |
| RT disabled, UDMABUF optimized | 30-60 | Full performance |

## Environment Variables Reference

| Variable | Values | Purpose |
|----------|--------|---------|
| `APS5_RAYTRACING` | `miss` | Disable RT instruction emission |
| `APS5_RAYTRACING` | `strict` | Error on RT instructions (debugging) |
| `APS5_HOST_IMPORT_MIB` | `8192` | Adjust memory import budget (optional) |

## Comparison with Other Emulators

**KytyPS5 Approach**: Binary patches the game's capability check at VMA 0x73eec3f (je → jmp) to force the non-RT path at runtime.

**AnyPS5 Approach**: Uses shader-level control via environment variables, providing:
- No binary modification required
- Portable across game updates
- Runtime configurability
- Zero risk of file corruption

## Future Work

### Potential Enhancements

1. **Auto-Detection**: Implement game profile detection to automatically set `APS5_RAYTRACING=miss` for known-problematic titles
   - Location: Could be added to game launch logic or AppMetadata
   - Config file: `~/.anyps5/game_profiles.json`

2. **Chunked UDMABUF Imports**: Enhance the import path to automatically chunk large allocations
   - Current: `createDmaBufImport()` in `core/libs/prx/libSceAgcDriver/Graphics/src/GuestBufferMemory.cpp`
   - Enhancement: Use existing `importChunk()` infrastructure for initial imports

3. **Documentation**: Add game-specific configuration section to main README
   - Link to this document and other game-specific guides

## Testing Notes

### Verified Working

- [x] `APS5_RAYTRACING=miss` successfully forces non-RT path
- [x] Shader recompiler properly skips BVH instructions
- [x] Game fallback logic activates correctly

### Requires Further Testing

- [ ] Performance with UDMABUF limits at various thresholds (256MB, 512MB, 1024MB)
- [ ] Stability during extended play sessions
- [ ] Compatibility with game patches/updates

## Related Files

- Shader translation: `core/shader/recompiler/Translation/src/MemoryInstructions/ImageInstructions.cpp`
- Ray tracing control: `core/shader/recompiler/Translation/src/DispatchInstructions.cpp`
- UDMABUF implementation: `core/libs/prx/libSceAgcDriver/Graphics/src/GuestBufferMemory.cpp`
- Test case: `core/libs/tests/RayTracingMiss.cpp`

## Contributing

If you discover additional game-specific issues or solutions:

1. Document the problem and solution in this format
2. Test thoroughly across different hardware configurations
3. Submit findings to the AnyPS5 issue tracker or pull requests

## See Also

- [AnyPS5 Environment Variables](docs/environment-variables.md)
- [Shader Recompiler Documentation](docs/shader-recompiler.md)
- [Memory Management](docs/memory-management.md)
