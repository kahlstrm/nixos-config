---
name: pradd
description: Address PR review comments interactively
disable-model-invocation: true
---

Address review comments from the current branch's PR: $ARGUMENTS

1. Get the PR number for the current branch using `gh pr view --json number -q '.number'`
2. Fetch all review comments using `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments` and `gh pr view --json reviews,comments`
3. For each unresolved comment, extract: author, body, file path, line number
4. Summarize each comment in one line describing what change is requested
5. Use the AskUserQuestion tool with `multiSelect: true` to let the user choose which comments to address. Format options as:
   - Label: Brief summary (~50 chars max)
   - Description: Author and additional context
6. For each selected comment:
   - Navigate to the relevant file and line
   - Implement the requested change
   - Inform the user of progress
