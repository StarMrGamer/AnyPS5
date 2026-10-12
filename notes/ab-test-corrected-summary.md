# A/B Matrix Test - Issue #4317 - Corrected Run Summary

## Mission Completed (Corrected)

Re-ran the A/B matrix with the critical missing variable `APS5_RAYTRACING=miss` that allows ASTRO BOT to progress past the black-scene issue (#1409) and reach the phase where the `prop->m_pParent == this` assertion can fire.

## Corrected Test Matrix

| Test | Base Commit | Patch Applied | Environment | Result |
|------|-------------|---------------|-------------|---------|
| 1 | d146ec1b6 (newer) | %VAR% expansion only | APS5_HOST_IMPORT_MIB=16384<br>APS5_RAYTRACING=miss | ✅ No assertion - ran 150s |
| 2 | 1be0a7ce9 (908 commits older) | ASOBI_ROOT variable only | APS5_HOST_IMPORT_MIB=16384<br>APS5_RAYTRACING=miss | ✅ No assertion - ran 150s |

## Key Findings

1. **With APS5_RAYTRACING=miss set, both minimal configurations still run clean**
   - Both tests reached the rendering phase (shaders compiled, textures allocated, draw calls)
   - Both ran for 150 seconds past the 25-55s audio init window
   - Neither encountered the `prop->m_pParent == this` assertion

2. **The assertion requires a specific combination not present in these minimal tests**
   - Not purely a base regression (908-commit gap tested with raytracing enabled)
   - Not purely the %VAR% expansion patch alone
   - Not purely the ASOBI_ROOT variable patch alone

3. **Both path resolution mechanisms worked correctly**
   - Test 1: %VAR% expansion resolved `/host/%ASOBI_ROOT%/` paths at mount translation layer
   - Test 2: ASOBI_ROOT environment variable allowed title's own expansion to work

## Why the Correction Mattered

The first run omitted `APS5_RAYTRACING=miss`, which the reporter noted was present in all runs that reproduced the assertion. Without it:
- The title hits the known black-scene issue (#1409)
- May stall before reaching the phase where the assertion fires
- Clean runs without this variable are "non-evidence rather than counter-evidence"

With `APS5_RAYTRACING=miss` properly set, both tests reached the full rendering phase but still did not trigger the assertion.

## Technical Details

- **Test worktree**: `/home/faky/anyps5-ab-test2` (now cleaned up)
- **Builds**: Full library sets (124 libs) for both bases
- **Runtime**: ASTRO BOT ran from `/home/faky/anyps5-homebrew/PPSA21564/run`
- **Configuration**: Both `APS5_HOST_IMPORT_MIB=16384` and `APS5_RAYTRACING=miss`
- **Duration**: 150 seconds each (timed out intentionally)
- **Shader compilation**: Raytracing shaders compiled in both tests

## Conclusion

Even with the correct environment that allows the title to reach the asserting phase, neither minimal configuration (base + single patch) triggers the `prop->m_pParent == this` assertion. The issue appears to require a combination of factors or specific state not present in these isolated test cases.

## Workspace State

- Main workspace: `/home/faky/AnyPS5-w3480` (untouched on astro-work)
- Throwaway worktree cleaned up
- Libs symlink restored to main build
- Test logs saved: `/tmp/test1_rerun.log`, `/tmp/test2_rerun.log`
- Results documented: `notes/ab-test-corrected-results.md`
- GitHub comment posted: Issue #4317

## Next Steps

Since neither base nor individual patch triggers the assertion in isolation (even with correct environment), the issue likely requires:
- A combination of changes across multiple components
- Specific runtime state or timing conditions
- Interaction between the patches and other system state

The maintainer's suggestion of `git bisect --first-parent` between the bases does not apply since neither base shows the problem in these minimal configurations.
