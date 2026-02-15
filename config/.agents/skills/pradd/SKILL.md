---
name: pradd
description: Address PR review comments interactively
---

Address review comments from the current branch's PR: $ARGUMENTS

1. Fetch PR context in one call using `gh pr view --json reviews,comments,number`
2. From that response, extract the PR number and unresolved comments
3. Only if inline diff comments are missing, fetch them with `gh api repos/{owner}/{repo}/pulls/{pr_number}/comments`
4. For each unresolved comment, extract: author, body, file path, line number
5. Summarize each comment in one line describing what change is requested
6. Let the user choose which comments to address:
   - In Claude, use the AskUserQuestion tool with `multiSelect: true`.
   - Format options as:
     - Label: Brief summary (~50 chars max)
     - Description: Author and additional context
   - In agents without AskUserQuestion, present a numbered list and ask the user to reply with selected numbers.
7. For each selected comment:
   - Navigate to the relevant file and line
   - Implement the requested change
   - Inform the user of progress
