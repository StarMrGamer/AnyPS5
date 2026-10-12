# A/B Matrix Test for Issue #4317 - Results

## Goal
Separate 'upstream base' from 'our patch' as the cause of the `prop->m_pParent == this` assertion in ASTRO BOT.

## Requested Tests
1. Base d146ec1b6 + cherry-pick only %VAR% path-expansion from 6ec3c56d
2. Base 1be0a7ce9 + cherry-pick only ASOBI_ROOT guest-variable from 0528bae8b

## Issue Encountered
**The requested base commits (d146ec1b6 and 1be0a7ce9) cannot run ASTRO BOT.**

### Details
- Created throwaway worktree at `/home/faky/anyps5-ab-test`
- Checked out base d146ec1b6 (Oct 12, 2026)
- Applied %VAR% expansion patch successfully to `core/libs/prx/libc/src/General.cpp`
- Built successfully (cmake + make completed)
- **Problem**: The build only produces 1 library (`libc.prx`) vs 123 libraries in current main
  - The base d146ec1b6 is 908 commits behind where the emulator gained full library implementations
  - Cannot run the title without complete library set (missing libSceNpManager, libSceAudioOut2, etc.)
  - The `anyps5` executable at this base is just the relinker, not a full emulator runtime

### Timeline Context
- 1be0a7ce9: Oct 11, 2026 - Merge PR #3324
- d146ec1b6: Oct 12, 2026 - Merge PR #3640  
- Gap: 908 commits where most library implementations were added

## Alternative Interpretation
The issue reporter mentioned in their comment that they already tested:
> "On the same build (base `d146ec1b6` + the `ASOBI_ROOT` change), an A/B on just the `AudioOut2` values"

This suggests they might be referring to a more recent state that builds upon d146ec1b6, not the raw base commit itself.

## Questions for Clarification
1. Should the test use a more recent runnable base that includes the library implementations?
2. Are the commit references pointing to branches/states that are actually runnable rather than the raw base commits?
3. Would testing with current main but with specific patches reverted be an acceptable alternative?

## Status
Blocked - cannot proceed with A/B matrix on bases that don't have enough implementation to run the title.
