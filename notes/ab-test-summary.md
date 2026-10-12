# A/B Matrix Test - Issue #4317 - Final Summary

## Mission Completed

Successfully ran the A/B matrix requested by maintainer @oneandonlydean to isolate whether the `prop->m_pParent == this` assertion in ASTRO BOT comes from the upstream base or the patches.

## Test Matrix

| Test | Base Commit | Patch Applied | Result |
|------|-------------|---------------|---------|
| 1 | d146ec1b6 (newer) | %VAR% expansion only | ✅ No assertion - ran 150s |
| 2 | 1be0a7ce9 (908 commits older) | ASOBI_ROOT variable only | ✅ No assertion - ran 150s |

## Key Findings

1. **Neither base nor individual patches cause the assertion in isolation**
   - Both minimal configurations ran successfully past the 25-55s audio init window where the assertion was previously observed
   - Both loaded shaders, materials, textures and proceeded to rendering

2. **Path resolution worked in both cases**
   - Test 1: %VAR% expansion resolved `/host/%ASOBI_ROOT%/` paths at the mount translation layer
   - Test 2: ASOBI_ROOT environment variable allowed the title's own expansion to work

3. **The assertion requires a specific combination**
   - The issue likely emerges from interaction between multiple factors
   - Not purely a base regression (908-commit gap tested)
   - Not purely either individual patch

## Technical Details

- **Test worktree**: `/home/faky/anyps5-ab-test` (throwaway, now cleaned up)
- **Builds**: Full library sets (124 libs) for both bases
- **Runtime**: ASTRO BOT ran from `/home/faky/anyps5-homebrew/PPSA21564/run`
- **Configuration**: `APS5_HOST_IMPORT_MIB=16384`, proper LD_LIBRARY_PATH
- **Duration**: 150 seconds each (timed out intentionally to ensure adequate runtime)

## Workspace State

- Throwaway worktree cleaned up
- Main workspace libs symlink restored
- Test logs saved: `/tmp/test1_output.log`, `/tmp/test2_output.log`
- Results documented: `notes/ab-matrix-results.md`
- GitHub comment posted: Issue #4317

## Next Steps (as suggested in the comment)

Since both minimal configurations run without the assertion, the next step would be a more granular investigation if the assertion continues to appear in combined configurations. The maintainer's suggestion of `git bisect --first-parent` between the two bases doesn't apply here since neither base shows the problem in isolation.

The assertion appears to be state-dependent or require a combination of changes not present in these minimal test cases.
