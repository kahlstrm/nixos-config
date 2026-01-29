---
name: assess-release
description: Analyze code changes since last release with risk assessment
---

Analyze changes for an upcoming release: $ARGUMENTS

## Steps

1. **Identify comparison range**
   - Find latest release tag: `git describe --tags --abbrev=0`
   - If arguments provided, use as base reference

2. **Get overview**
   - List commits: `git log <tag>..HEAD --oneline`
   - Get stats: `git diff <tag>..HEAD --stat`

3. **Examine each PR's diff**
   - For each merge commit or significant commit, run `git show <sha>` to see the actual diff
   - Read the code changes to understand what was modified
   - Pay attention to:
     - Logic changes in core paths
     - Error handling additions/removals
     - API changes
     - Database/schema changes
     - Test coverage

4. **Produce summary**

   ```
   ## Release Summary: <version>

   ### Features
   - Feature - what it does, files touched

   ### Bug Fixes
   - **Fix name** (ticket) - what was broken, how it's fixed
   - Note test coverage

   ### Cleanup
   - Removals, refactors

   ### Risk Assessment
   | Change | Risk | Reason |
   |--------|------|--------|

   **Recommendation**: Assessment
   ```
