# Implementation Plan

## Location: core/libs/prx/libc/src/General.cpp

Add a helper function to expand %VAR% tokens specifically for /host paths:

```cpp
// Expand %VAR% tokens in /host paths using guest environment variables
std::string ExpandHostPathVariables(const std::string& path) {
    std::string result = path;
    size_t pos = 0;
    
    while ((pos = result.find('%', pos)) != std::string::npos) {
        size_t end = result.find('%', pos + 1);
        if (end == std::string::npos) break;
        
        std::string varName = result.substr(pos + 1, end - pos - 1);
        if (varName.empty()) {
            pos = end + 1;
            continue;
        }
        
        extern char* getenv_nid_postfix(const char*);
        const char* value = getenv_nid_postfix(varName.c_str());
        
        if (value) {
            result.replace(pos, end - pos + 1, value);
            pos += strlen(value);
        } else {
            pos = end + 1;
        }
    }
    
    return result;
}
```

Then modify ResolveAlias to use it for /host paths:

```cpp
std::optional<std::filesystem::path> ResolveAlias(const std::string& guestPath) {
    std::string relative = TrimSlashes(guestPath.c_str());
    
    // Special handling for /host paths: expand %VAR% tokens
    if (HasPrefix(relative, "host")) {
        relative = TrimSlashes(ExpandHostPathVariables("/" + relative).c_str());
    }
    
    // ... rest of existing logic
}
```

## Tests

Add test to verify:
1. /host/%ASOBI_ROOT%/target/... expands correctly
2. Paths without % work as before
3. Undefined variables remain unexpanded or fail appropriately
4. Multiple variables in one path work
5. Escaped %% behavior (if needed)

## Validation

Run game without manual workarounds and verify:
- Sound config loads
- No asserts
- Game runs stably
