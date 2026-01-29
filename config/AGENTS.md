# Agentic Code Instructions

Please take the following instruction into mind when working.
These are not final instructions and the user can overrule them for each unit of work

## Coding instructions

### Workflow practices

- Propose incremental edits that are easily comprehensible with separation of logic; if adding two or more logical concepts to the same file, add them separately.
- After making an incremental but measurable unit of work, add meaningful tests for this unit of code.
- Check recent commits to see the commit convention used. Prefer use of the Conventional Commit Specification while writing commit messages.
- Write ONLY conscise oneliners as commit messages without a description.
- When creating a Pull Request, use @.github/PULL_REQUEST_TEMPLATE.md or similar basis for it, and follow that when creating the body.

### Coding practices

- Write clean, readable code with proper error handling
- If possible, follow a "loosely" declarative and functional style; using programming language idiomatic patterns and conventions,
  try to write logically condensed blocks by limiting scope by using higher-level functions, separating code blocks to functions or using other language features.
- Follow existing codebase practices and conventions for consistency, while abiding by other instructions described here.
- Document ONLY complex and/or obscure logic with comments; self-explanatory code shouldn't need comments. Usually a variable or function name should be enough documentation.
- Follow DRY principle: extract repeated code into functions/modules after 3+ uses, or 2+ uses for large identical blocks.
- Before writing utility functions, consider searching for existing functionality in the codebase first for code reuse.

- Whenever there is some kind of verification in place, addressing it by fixing it is the only way to go forward. Skipping or disabling verification steps is NOT ALLOWED.

### Debugging practices

- When debugging a problem, first investigate to find the actual root cause before jumping to conclusions or proposing fixes.
- Instead of telling the user to run diagnostic commands, try to run them yourself.
