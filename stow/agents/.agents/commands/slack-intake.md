---
name: slack-intake
description: Headless intake from a Slack thread. Creates Linear ticket, branch, worktree, posts machine-readable result. No interactive stops.
argument-hint: <repo-path> <worktrees-root> <slack-thread-json-or-text>
---

You are running NON-INTERACTIVELY from a Slack bot. Do NOT ask questions. Do NOT stop for approval. Emit the final machine-readable block at the end no matter what.

Arguments: `$ARGUMENTS`
- First arg: absolute path to the target repo (cwd already there).
- Second arg: worktrees root (e.g. `~/Worktrees`).
- Rest: Slack thread text (the discussion to turn into a ticket).

## Steps

1. **Distill the discussion** into a Linear ticket:
   - Title: <=70 chars, imperative.
   - Description: markdown, include "Source: Slack thread" line, key points as bullets, acceptance criteria if derivable.
   - Pick the most relevant team (default: the Development team if unsure).

2. **Create the Linear ticket** via the linear MCP `save_issue` tool. Assign to the current user (use `get_user` with `me`). Set state to `In Progress`.

3. **Create a git worktree** at `<worktrees-root>/<ticket-id-lowercased>` with a new branch named `<TICKET-ID>/<kebab-summary>` based on `origin/develop` (or the repo's main branch — detect from `git remote show origin`). Use:
   ```
   git -C <repo> fetch origin
   git -C <repo> worktree add -b <branch> <worktrees-root>/<ticket-id-lowercased> origin/<main>
   ```

4. **Do NOT start coding.** Just prep the worktree.

5. **Emit final block** exactly in this format on the LAST lines of output (the bot parses this — no extra text after):

```
<<<SLACK_INTAKE_RESULT
ticket_id: REV-123
ticket_url: https://linear.app/...
branch: REV-123/short-desc
worktree: /Users/.../Worktrees/rev-123
title: Imperative title here
SLACK_INTAKE_RESULT>>>
```

If any step fails, still emit the block with the fields you have plus an `error:` line. Never exit silently.
