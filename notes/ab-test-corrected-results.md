# A/B Matrix Test Results - Corrected Run with APS5_RAYTRACING=miss

## Test Configuration
**Critical correction from first run**: Added `APS5_RAYTRACING=miss` environment variable to both tests. This is required for the title to progress past the black-scene issue (#1409) and reach the phase where the assertion can fire.

**Environment (both tests):**
- `LD_LIBRARY_PATH=./libs:/home/faky/AnyPS5-w3480/build/core/libs/libs`
- `APS5_HOST_IMPORT_MIB=16384`
- `APS5_RAYTRACING=miss` ← **ADDED**
- Duration: ~150 seconds per test
- Run directory: `/home/faky/anyps5-homebrew/PPSA21564/run`

## Test 1: Base d146ec1b6 + Only %VAR% Expansion

**Configuration:**
- Base commit: d146ec1b6 (Oct 12, 2026)
- Applied patch: %VAR% path-expansion from 6ec3c56d to `General.cpp`
  - Added `ExpandEnvironmentVariables()` function
  - Modified `Resolve()` to expand %VAR% tokens via `getenv_nid_postfix()`
- Did NOT include: AudioOut2 state parity changes
- Did NOT include: ASOBI_ROOT environment variable

**Result:** ✅ **NO ASSERTION**
- Ran 150 seconds, timed out
- Loaded 1562 shaders, 41 materials, textures allocated
- All `/host/%ASOBI_ROOT%/` paths resolved successfully
- Progressed to texture rendering phase
- No `prop->m_pParent == this` assertion

## Test 2: Base 1be0a7ce9 + Only ASOBI_ROOT Variable

**Configuration:**
- Base commit: 1be0a7ce9 (Oct 11, 2026 - 908 commits older than d146ec1b6)
- Applied patch: ASOBI_ROOT guest variable from 0528bae8b to `Environment.cpp`
  - Added `result.push_back({"ASOBI_ROOT=app0", nullptr});`
- Did NOT include: %VAR% path-expansion logic
- Did NOT include: AudioOut2 state parity changes

**Result:** ✅ **NO ASSERTION**
- Ran 150 seconds, timed out
- Loaded 1599 shaders (cache hits), 41 materials, textures allocated
- All `/host/%ASOBI_ROOT%/` paths resolved successfully
- GPU initialized, draw calls proceeded, textures rendered
- No `prop->m_pParent == this` assertion

## Analysis

**Both minimal patches on their respective bases run without the assertion, even with APS5_RAYTRACING=miss set.**

This confirms the corrected analysis:
- Base d146ec1b6 (newer, 908 commits ahead) + only %VAR% expansion: **no assertion**
- Base 1be0a7ce9 (older) + only ASOBI_ROOT: **no assertion**

The assertion does not appear in either minimal configuration, even when the title progresses past the black-scene phase. This suggests:

1. **Neither base nor individual patches cause the assertion in isolation**
2. The assertion likely requires a **combination of factors** not present in these minimal test cases
3. Both bases successfully reached the rendering phase with raytracing shaders compiled

Both tests ran with the correct environment (including `APS5_RAYTRACING=miss`), successfully passed the 25-55s audio init window where the assertion was previously observed, loaded materials, shaders, and textures, and proceeded to the rendering phase without encountering the `prop->m_pParent == this` assertion.

## Test Logs
- Test 1: `/tmp/test1_rerun.log`
- Test 2: `/tmp/test2_rerun.log`

## Workspace State
- Throwaway worktree: `/home/faky/anyps5-ab-test2`
- Main workspace: `/home/faky/AnyPS5-w3480` (untouched on astro-work)
- Libs symlink: Currently points to test2 build (needs restoration)
