# Testing Plan

## Understanding Runtime Behavior

From USAGE.md, the runtime layout is:
```
run/
  app.elf
  libs/
  app0/
```

The title accesses `/app0/...` paths which resolve to `run/app0/...`

For `/host/` paths:
- On a real PS5 dev kit, `/host/` maps to the development PC filesystem
- In AnyPS5, `/host/` should map to the run directory (like other mounts)

## Current Status

Our fix expands `/host/%ASOBI_ROOT%/target/...` to `/host/app0/target/...`

Since there's likely no explicit /host alias set up (it may work via the root resolution), we need to verify the game can now find its files.

## Testing Steps

1. Clean up any manual workarounds in the game directory
2. Rebuild the entire project
3. Launch the game and verify:
   - Sound config loads
   - No path-related errors
   - Game runs stably

## Expected Behavior

With our fix:
- `/host/%ASOBI_ROOT%/target/data/...` 
- → expands to `/host/app0/target/data/...`
- → resolves to `run/app0/target/data/...` (or just `app0/target/data/...` relative to run dir)
