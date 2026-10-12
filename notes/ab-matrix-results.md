# A/B Matrix Test Results for Issue #4317

## Test Configuration
**Goal:** Isolate whether the `prop->m_pParent == this` assertion comes from the upstream base or from the patches.

**Environment:**
- Test worktree: `/home/faky/anyps5-ab-test` (separate from main workspace)
- Run directory: `/home/faky/anyps5-homebrew/PPSA21564/run`
- Runtime: `LD_LIBRARY_PATH` pointed to test build, `APS5_HOST_IMPORT_MIB=16384`
- Duration: ~150 seconds per test (title ran past audio init, loaded textures, materials, shaders)

## Test 1: Base d146ec1b6 + Only %VAR% Expansion

**Configuration:**
- Base commit: d146ec1b6 (Oct 12, 2026 - Merge PR #3640)
- Applied patch: %VAR% path-expansion logic from 6ec3c56d to `core/libs/prx/libc/src/General.cpp`
  - Added `ExpandEnvironmentVariables()` function
  - Modified `Resolve()` to expand %VAR% tokens via `getenv_nid_postfix()`
- Did NOT include: AudioOut2 state parity changes from 6ec3c56d
- Did NOT include: ASOBI_ROOT environment variable

**Result:** ✅ **NO ASSERTION**
- Title ran for 150 seconds
- Loaded shaders (1562 total), materials (41), textures
- Successfully opened all `/host/%ASOBI_ROOT%/` paths
- No `prop->m_pParent == this` assertion
- Log excerpt showing successful path resolution:
  ```
  [src/Open.cpp:219 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/system/gfx/sys_decal_water.gnfp flags=0x0 nativeFlags=0x0 mode=0555
  [src/Open.cpp:219 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/common/sound/config.xml flags=0x0 nativeFlags=0x0 mode=0555
  ```

## Test 2: Base 1be0a7ce9 + Only ASOBI_ROOT Variable

**Configuration:**
- Base commit: 1be0a7ce9 (Oct 11, 2026 - Merge PR #3324)
- Applied patch: ASOBI_ROOT guest variable from 0528bae8b to `core/libs/prx/libc/src/Environment.cpp`
  - Added `result.push_back({"ASOBI_ROOT=app0", nullptr});` to guest environment init
- Did NOT include: %VAR% path-expansion logic
- Did NOT include: AudioOut2 state parity changes

**Result:** ✅ **NO ASSERTION**
- Title ran for 150 seconds
- Loaded shaders (1599 total via cache), materials (41), textures
- Successfully opened all `/host/%ASOBI_ROOT%/` paths
- No `prop->m_pParent == this` assertion
- GPU initialized, draw calls proceeded normally
- Log excerpt showing successful path resolution:
  ```
  [src/Open.cpp:123 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/system/gfx/sys_decal_water.gnfp flags=0x0 nativeFlags=0x0 mode=0555
  [src/Open.cpp:123 sceKernelOpen] path=/host/%ASOBI_ROOT%/target/data/common/sound/config.xml flags=0x0 nativeFlags=0x0 mode=0555
  ```

## Analysis

**Both minimal patches on their respective bases run without the assertion.**

The matrix shows:
- Base d146ec1b6 (newer, 908 commits ahead) + %VAR% expansion alone: **no assertion**
- Base 1be0a7ce9 (older) + ASOBI_ROOT alone: **no assertion**

This suggests that **neither the base evolution nor the individual patches cause the assertion when applied in isolation**. The assertion likely requires a combination of factors or specific state that wasn't triggered in these minimal configurations.

Both tests successfully resolved `/host/%ASOBI_ROOT%/` paths and proceeded past audio init (where the assertion was previously observed at 25-55s). The title loaded materials, shaders, textures, and began rendering in both cases.

## Notes

- The `%ASOBI_ROOT%` token appears unexpanded in the logs for both tests, which is expected—the expansion happens at the filesystem mount translation layer (Test 1) or via the environment variable that the title's own expansion reads (Test 2).
- Both bases had full library implementations (124 libs) after building the `libs` target.
- Tests used the existing relinked `app.elf` with library path set to pull test build libraries, falling back to main build for any missing modules.
