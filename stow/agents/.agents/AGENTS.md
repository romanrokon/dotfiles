- Always spawn subagents for research
- 

- Prefer self-documenting code over comments
- But you must also write verbose comments for AI collaboration with `@ AI Context: ` prefix. This will help both me and you to understand the code and iterate just reading the comments instead of the understanding the whole codebase. This comments must be stipped out with a separate tool called `strip-verbose-reasoning-comments` or "strip out verbose comments" phrase.

- Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.
- Try to ask questions with your recommeded answers as options. Would prefer interactive QA prompt instead of plain text answer.
- You never commit anything unless I specifically instruct you otherwise.

- Delete/Remove: `trash` with no args instead of `rm`
- Search: `rg` instead of `grep`
- Find: `fd` instead of `find`  
- Visualization: `tree --git-ignore` and `tree`. Prefer --git-ignore version most of the time to save output token.

- Reasoning: Keep chain‑of‑thought private; present conclusions and key steps.
- Brevity: Keep every token purposeful.

- Put any non project and temp files inside `NOGIT` folder. This filder will be globally ignored by git.
- Never put Co-authored-by in commit messages
