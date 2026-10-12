# Critical Findings

## The Game's Behavior

From strings in app.elf, the game has HARDCODED paths like:
```
/host/%ASOBI_ROOT%/target/app/ppr/app_sys/DebugFont.gnfp
/host/%ASOBI_ROOT%/target/data/physics_shape_
```

The game does NOT expand %ASOBI_ROOT% itself - it passes these LITERAL strings to sceKernelOpen.

## The /host Mount

Looking at run/host/ directory structure:
```
host/
  app0/        <- manually created symlink
  %ASOBI_ROOT% <- this is the workaround directory that was created!
```

The workaround created a literal `%ASOBI_ROOT%` directory name!

## What Should Happen

On real PS5, `/host/` must be a special mount point that:
1. Maps to the development PC's filesystem (for dev kits)
2. Expands environment variables in the path

The paths should resolve like:
- `/host/%ASOBI_ROOT%/target/...` 
- → expand %ASOBI_ROOT% to its value (app0)
- → `/host/app0/target/...`
- → resolve /host as an alias to the run directory
- → `run/app0/target/...`

## The Bug in PR #4274

PR #4274 added ASOBI_ROOT environment variable, assuming the game calls getenv().
But the game doesn't - it passes the literal string to kernel functions.
The expansion must happen in the PATH RESOLUTION layer, specifically for /host paths.

## The Fix Location

The fix belongs in the ResolveAlias() function in General.cpp, with special handling for /host prefix that:
1. Detects %VAR% tokens in the path
2. Expands them using getenv()
3. Returns the resolved path

This is NOT general path expansion (which TideOPL rejected) - it's specific to the /host mount behavior.
