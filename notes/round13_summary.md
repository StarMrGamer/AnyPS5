# Round 13 Summary: ASTRO BOT Rendering Test

**Date**: 2026-10-12  
**Branch**: `astro-work` (commit 0528bae8b)  
**Mission**: Test FPS with APS5_HOST_IMPORT_MIB=16384, check PR #425 status, monitor PR #4274

---

## Key Findings

### ✅ PR #4274 (ASOBI_ROOT Fix) - WORKING
The environment variable fix works perfectly:
- Game boots successfully
- All /host/%ASOBI_ROOT%/ paths resolve correctly
- Resources load from app0/target/data/
- No review comments yet on the PR

### ❌ FPS Testing - BLOCKED
Cannot measure FPS due to **UDMABUF misconfiguration**:

| Parameter | Current | Required | Status |
|-----------|---------|----------|--------|
| size_limit_mb | 64 MB | 6144 MB | ❌ Too low |
| /dev/udmabuf access | root:kvm (0660) | User readable | ❌ No access |
| User in kvm group | NO | YES | ❌ Not member |

**Impact**: All 4 GPU memory imports failed → CPU-GPU copy fallback → ~5 FPS bottleneck

**Fix** (requires sudo):
```bash
echo 6144 | sudo tee /sys/module/udmabuf/parameters/size_limit_mb
sudo usermod -aG kvm $USER
```

### ❌ Rendering Testing - BLOCKED
Game crashed before reaching frame loop:
```
ASSERT: Sound/SoundManager.cpp:306
Assertion failed: defaultBusses.size() == 1
Segmentation fault
```

The sound system initialization fails, preventing any rendering or FPS measurement.

### ⏳ PR #425 (Depth Surface Fix) - NOT MERGED
Status: OPEN (not merged into upstream main)
- Fixes compute shader depth surface access (issue #1409)
- Required for "black scene" rendering fix
- Did not attempt to merge ourselves (per mission rules)

---

## Test Results

| Metric | Expected | Actual | Status |
|--------|----------|--------|--------|
| Boot | ✅ Success | ✅ Success | PASS |
| ASOBI_ROOT paths | ✅ Resolved | ✅ Resolved | PASS |
| UDMABUF imports | ✅ 4 succeeded | ❌ 4 failed | FAIL |
| FPS (6144 MiB) | ~5 | Not measured | BLOCKED |
| FPS (16384 MiB) | 30-60 | Not measured | BLOCKED |
| Rendering | ✅ Scene visible | Not reached | BLOCKED |
| Screenshot | Captured | None | BLOCKED |

---

## Blocked By

1. **UDMABUF configuration** (admin/sudo required)
2. **Sound system crash** (needs investigation)
3. **PR #425 not merged** (upstream dependency)

---

## What Works

✅ **PR #4274 implementation** - Game boots, finds resources, loads shaders  
✅ **Workspace stability** - `astro-work` branch intact with all fixes  
✅ **Build system** - Fresh relink successful  
✅ **GPU initialization** - Vulkan device ready, shaders cached  

---

## What Doesn't Work

❌ **UDMABUF** - 64 MB limit blocks 4.5 GB allocations  
❌ **Sound system** - Crashes before frame loop  
❌ **FPS measurement** - No window created due to crash  
❌ **Rendering test** - Can't reach main loop  

---

## Action Items

**Immediate** (requires sudo):
- [ ] Increase UDMABUF size_limit_mb to 6144
- [ ] Add user to kvm group OR chmod 666 /dev/udmabuf

**Investigation**:
- [ ] Debug sound system crash (defaultBusses assertion)
- [ ] Check if additional audio modules needed

**Waiting**:
- [ ] PR #425 to merge upstream
- [ ] PR #4274 to receive review feedback

**Future Testing** (once unblocked):
- [ ] Measure FPS with default 6144 MiB
- [ ] Measure FPS with 16384 MiB
- [ ] Capture screenshots showing rendering
- [ ] Verify depth surface fix from PR #425

---

## Conclusion

The ASOBI_ROOT fix (PR #4274) works correctly, but testing the FPS and rendering improvements is blocked by system configuration issues (UDMABUF) and an unrelated sound crash. The workspace remains stable on the `astro-work` branch with all fixes intact.

**Real FPS measured**: 0 (crashed before frame loop)  
**System needs**: sudo access to configure UDMABUF properly
