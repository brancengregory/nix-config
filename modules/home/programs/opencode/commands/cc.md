---
description: Generate conventional commit message for staged changes
---

Analyze the staged git changes below and generate a conventional commit message.

**Rules:**

- Use format: `type: description` (no scope unless the changes clearly affect only one specific module/component)
- If scope is appropriate, use format: `type(scope): description`
- Start the description with a lowercase letter
- Keep the description concise and under 72 characters
- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- Only include a body if it adds meaningful context not obvious from the description
- If body is needed, use bullet points starting with lowercase letters
- Body should be terse - no redundant or repetitive information

**Staged changes:**

!`git diff --staged`
