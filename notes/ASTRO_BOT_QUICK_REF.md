# ASTRO BOT Quick Fix Reference

## TL;DR

```bash
export APS5_RAYTRACING=miss
./anyps5 ~/anyps5-homebrew/PPSA21564/run/app.elf
```

Or use the provided script:
```bash
./launch_astrobot.sh
```

## Environment Variables

| Variable | Value | Effect |
|----------|-------|--------|
| `APS5_RAYTRACING` | `miss` | Disable ray tracing, force non-RT rendering path ✅ |
| `APS5_RAYTRACING` | `strict` | Throw errors on RT instructions (for debugging) |
| `APS5_HOST_IMPORT_MIB` | `8192` | Increase memory import budget (optional) |
| `APS5_PIPELINE_STATS` | `1` | Enable pipeline statistics (debugging) |

## UDMABUF Setup (One-Time)

```bash
# Check current limits
cat /sys/module/udmabuf/parameters/size_limit_mb

# If < 512 MB, increase it
echo 1024 | sudo tee /sys/module/udmabuf/parameters/size_limit_mb

# Make permanent (add to /etc/modprobe.d/udmabuf.conf)
echo "options udmabuf size_limit_mb=1024" | sudo tee /etc/modprobe.d/udmabuf.conf

# Grant access
sudo chmod 666 /dev/udmabuf
# OR add user to kvm group
sudo usermod -aG kvm $USER
```

## What Was Wrong

1. **Ray Tracing Path**: Game detected RT support and used RT rendering, which doesn't work properly
   - **Fix**: `APS5_RAYTRACING=miss` forces non-RT path at shader translation level

2. **UDMABUF Failures**: 4x 512MB allocations failed, causing 4 FPS performance
   - **Fix**: Increase kernel UDMABUF size limit to 1024 MB

## Expected Results

- **Before**: Black screen, 4 FPS, no display output
- **After RT fix**: Game renders using standard path, visible graphics
- **After UDMABUF fix**: 30-60 FPS smooth performance

## Files Created

- `ASTRO_BOT_FIX.md` - Detailed technical documentation
- `launch_astrobot.sh` - Automated launch script with checks
- `ASTRO_BOT_QUICK_REF.md` - This file

## Comparison to KytyPS5

| Aspect | KytyPS5 | AnyPS5 |
|--------|---------|--------|
| Method | Binary patching (je→jmp) | Environment variable |
| Maintenance | Per-game, per-update | Universal, permanent |
| Flexibility | Fixed at patch time | Toggle per-launch |
| Risk | Can corrupt binary | Zero risk |
| Implementation | `0x73eec3f: je → jmp` | `APS5_RAYTRACING=miss` |

## Debug Commands

```bash
# Check if game is using RT
strings app.elf | grep -i ray

# Monitor UDMABUF usage
watch -n 1 'dmesg | tail -20 | grep udmabuf'

# Check AnyPS5 logs for RT instructions
./anyps5 app.elf 2>&1 | grep -i "ray\|bvh"
```

## Support

See `ASTRO_BOT_FIX.md` for complete technical details and troubleshooting.
