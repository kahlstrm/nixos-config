---
name: commit-pr
description: Create a commit and pull request using the PR template
---

Create a commit and pull request for changes: $ARGUMENTS

## Steps

0. Run repository specific checks, lint, tests that are relateed to the changes.

1. **Gather context**
   - Run `git status` to see staged and unstaged changes
   - Run `git diff` to see the actual changes
   - Run `git log --oneline -5` to see recent commit style

2. **Prepare branch first**
   - Check current branch with `git branch --show-current`
   - If on main/master:
     - Ask user if they want to create a ticket (Linear issue) first
     - If yes, create the ticket and use its identifier for the branch name
     - If no, auto-generate a descriptive branch name based on the changes
     - Create branch with `git checkout -b <branch>`

3. **Stage and commit**
   - Stage the files relevant to changes made in the current session with `git add <files>`
   - Write a concise one-line commit message following Conventional Commits
   - Use format: `type: description` (e.g., `feat:`, `fix:`, `chore:`, `docs:`)
   - Commit with `git commit -m "message"`

4. **Push and create pull request**
   - Push branch to remote with `git push -u origin <branch>`
   - Check if `.github/PULL_REQUEST_TEMPLATE.md` exists in the project
   - If template exists, read it and fill in based on the changes:
     - Replace placeholders with actual content from the commits
   - If no template, create a basic PR body with summary and changes list
   - Create PR with `gh pr create --title "PR title" --body "body content"`
   - Return the PR URL to the user
