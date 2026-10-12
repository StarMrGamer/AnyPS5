# GitHub Submission Plan - ASTRO BOT Findings

## 1. Issue Report (Upstream)

**Target Repository**: https://github.com/boykopovar/AnyPS5/issues

**Title**: ASTRO BOT crashes with Property assertion after commit 6ec3c56d (regression)

**Labels**: bug, regression

**Content**: See `/tmp/astro_property_assertion_issue.md`

**Key Points**:
- Working at 6ec3c56d, broken at 0528bae8b+
- 909 commits in between, cannot bisect (build failures)
- Blocks all rendering
- Request investigation from maintainers

---

## 2. Pull Request (Your Fork - Optional)

**Target**: Your fork (StarMrGamer/AnyPS5)

**Branch**: astro-work (already pushed)

**Title**: fix(audioout2): restore port state and speaker info parity

**Status**: ✅ Already committed and pushed (cfb2b7829)

**Purpose**: Documents the AudioOut2 fixes that work on 6ec3c56d

**Note**: Don't create PR to upstream yet - needs to be based on a commit that doesn't crash

---

## 3. Documentation Update (Optional)

**File**: docs/user/COMPATIBILITY.md or similar

**Content**: Document ASTRO BOT status:
- Partially playable on commit 6ec3c56d
- Grey UI + red bars rendering
- Current main has regression (Property assertion)
- Workaround: Use 6ec3c56d base

---

## 4. Test Report (As PR Comment or Gist)

According to CONTRIBUTING.md:
> Investigation notes, reports, screenshots and logs go in the pull request, not in the repository.

**Option A**: Attach to existing PR discussion
**Option B**: Create GitHub Gist with full report
**Option C**: Attach to the issue report

**Content to include**:
- Full test logs (6ec3c56d working vs current broken)
- Screenshots if available
- Performance notes (~5 FPS grey UI)
- All findings from notes/FINAL_REPORT.md

---

## Recommended Actions

### Immediate (Now):
1. ✅ Create Issue on upstream repo with Property assertion details
2. ✅ Reference commit 6ec3c56d as last known good
3. ✅ Request maintainer investigation

### After Issue Filed:
1. Wait for maintainer response
2. If asked, provide full logs from `/tmp/astro_6ec3c56d_boot.log` and `/tmp/astro_boot.log`
3. Test any proposed fixes

### For Your Fork:
1. Keep astro-work branch as-is (AudioOut2 fix)
2. Create astro-rendering-base from 6ec3c56d for actual development
3. Cherry-pick fixes as needed

---

## Files to Reference

**Investigation Notes** (keep local, attach to issue/PR):
- `notes/FINAL_REPORT.md` - Complete technical analysis
- `notes/URGENT_STATUS.md` - Key findings
- `notes/astro-rendering-status.md` - Rendering state comparison

**Test Logs** (attach to issue):
- `/tmp/astro_6ec3c56d_boot.log` - Working state (80s run)
- `/tmp/astro_boot.log` - Broken state (55s to crash)

**Code Changes** (already pushed):
- Branch: `astro-work`
- Commit: cfb2b7829
- Files: AudioOut2Port.cpp, AudioOut2SpeakerArray.cpp

---

## Issue Filing Checklist

Before filing the issue:
- [ ] Confirm issue doesn't already exist
- [ ] Have clear reproduction steps
- [ ] Have both working and broken commit IDs
- [ ] Have relevant log excerpts
- [ ] State your OS (Linux)
- [ ] Mention attempted bisect and why it failed

After filing:
- [ ] Link issue in your notes
- [ ] Wait for maintainer response
- [ ] Be ready to provide more details/logs
- [ ] Test any proposed fixes

---

## Draft Issue Text

See: `/tmp/astro_property_assertion_issue.md`

Ready to paste into GitHub Issues.
