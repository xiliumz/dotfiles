---
description: Create commits
agent: build
model: opencode/grok-code
---
Create commits following these rules

- Commits are atomic—each contains a small, focused change (not entire features or changes).
- Multiple commits are preferable if it is needed to make easier to read the history but still make sense as a whole.
- **Each commit must leave the codebase in a working state**—if changes are interdependent (e.g., updating a hook API and its usage), group them in a single commit rather than creating broken intermediate states.
- Commit messages follow conventional format: feat, fix, test, refactor, docs, chore.
- Titles < 69 chars, imperative mood, no trailing period.
- You can add body text to provide more context about the change.
- Don't commit . directory and files inside it
- Utilize `git` command
- Don't commit `AGENTS.md`
