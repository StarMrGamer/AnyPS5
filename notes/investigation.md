# Path Resolution Investigation

## Evidence Summary

From /tmp/verify_boot3.log:
- Title passes LITERAL paths like `/host/%ASOBI_ROOT%/target/...` to sceKernelOpen
- The %ASOBI_ROOT% token is NOT expanded by the title itself

## PR #4274 (commit 0528bae8b)
- Adds ASOBI_ROOT=app0 to guest environment
- Assumes title uses getenv() to expand %ASOBI_ROOT%
- **But this doesn't fix the sound assert** - title still crashes

## Working Solution
- Runtime mapping: `run/host/%ASOBI_ROOT%/target -> ../../app0`
- Game runs 110s with 0 asserts
- This means the expansion needs to happen in the /host mount layer

## Maintainer Constraint (PR #3959)
- TideOPL: do NOT add %VAR% expansion to libc path resolution
- Reason: not console behaviour, breaks paths with two % signs
- Must find where console actually handles this

## Next Steps
1. Find where /host mount is registered
2. Check what /host is supposed to map to
3. Find if console has special handling for /host paths with %VAR%
4. Implement expansion at the mount/translation layer
