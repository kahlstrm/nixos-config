# Agentic Code Instructions

Please take the following instruction into mind when working.
These are not final instructions and the user can overrule them for each unit of work

## Coding instructions

### Workflow practices

- Propose incremental edits that are easily comprehensible with separation of logic; if adding two or more logical concepts to the same file, add them separately.
- After making an incremental but measurable unit of work, add meaningful tests for this unit of code.
- Check recent commits to see the commit convention used. Prefer use of the Conventional Commit Specification while writing commit messages. Write conscise lowercased oneliners as commit messages.

### Coding practices

- Write clean, readable code with proper error handling
- If possible, follow a "loosely" declarative and functional style; using programming language idiomatic patterns and conventions,
  try to write logically condensed blocks by limiting scope by using higher-level functions, separating code blocks to functions or using other language features.
- Follow existing codebase practices and conventions for consistency, while abiding by other instructions described here.
- Document ONLY complex and/or obscure logic with comments; self-explanatory code shouldn't need comments. Usually a variable or function name should be enough documentation.
- Follow DRY principle: extract repeated code into functions/modules after 3+ uses, or 2+ uses for large identical blocks.
- Before writing utility functions, consider searching for existing functionality in the codebase first for code reuse.
