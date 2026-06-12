---
name: slack-work
description: Start work on an existing Linear ticket. Idempotent. Creates branch + worktree if missing; reuses if present. Appends substantive Slack context as a comment. No status change.
argument-hint: <ticket-id> <repo-path> <worktrees-root> <slack-context>
---

You are running NON-INTERACTIVELY from a Slack bot. Do NOT ask questions. Emit the final machine-readable block no matter what.

Arguments: `$ARGUMENTS`
- 1st: Linear ticket ID (e.g. `REV-160`).
- 2nd: Absolute path to target repo.
- 3rd: Worktrees root (e.g. `/Users/rzman/Worktrees`).
- Rest: Slack context text (the discussion).

## Steps

1. **Fetch the ticket** via linear MCP `get_issue`. If not found, emit:
   ```
   <<<SLACK_INTAKE_RESULT
   ticket_id: <id>
   error: ticket not found
   mode: work
   SLACK_INTAKE_RESULT>>>
   ```
   and stop.

2. **Resolve paths.**
   - `worktree_path` = `<worktrees-root>/<ticket-id-lowercased>` (e.g. `/Users/rzman/Worktrees/rev-160`)
   - `repo` = 2nd arg

3. **Detect existing worktree.** Run `git -C <repo> worktree list --porcelain` and look for a worktree at `worktree_path`.
   - If found → `reused = true`. Read its branch: `git -C <worktree_path> rev-parse --abbrev-ref HEAD`.
   - Else → `reused = false`; proceed to create.

4. **If creating:**
   - Detect main branch: `git -C <repo> remote show origin | grep "HEAD branch"` → e.g. `develop`. Default `develop` if detection fails.
   - Check for an existing local branch matching `<TICKET-ID>/*`: `git -C <repo> branch --list '<TICKET-ID>/*'`.
     - If found → reuse that branch name; `git -C <repo> worktree add <worktree_path> <branch>`.
     - Else → derive `<branch> = <TICKET-ID>/<kebab-title-short>` (kebab-case from ticket title, lowercase, alphanumeric+dashes only, ≤40 chars). Then `git -C <repo> fetch origin && git -C <repo> worktree add -b <branch> <worktree_path> origin/<main>`.

5. **Append Slack context as a comment** when it adds useful info (not just acknowledgements like "ok", "thanks", "lgtm", or content already mirrored in the ticket description). When in doubt, append. Format:
   ```
   **From Slack:**

   <context as-is>
   ```
   Use linear MCP `save_comment`. Track `comment_appended: true|false`.

6. **Do NOT change the ticket status.** The human will move it when they're ready.

7. **Map the ticket to code areas.** Cross-reference the ticket against this project's layout (paths relative to repo root):
   - **Routes**: `src/app/(site-layout)/`, `src/app/(wizard-layout)/`, `src/app/(sanity-layout)/`, `src/app/api/`
   - **Components**: `src/components/common/` (reusable — check here first), `src/components/layout/`, `src/components/RSC/`, domain folders (`destination/`, `pricing/`, `profile/`, `regulation/`, `landing/`, etc.)
   - **State**: `src/redux/slices/`, `src/redux/api/{domain}/`
   - **Services**: `src/services/`
   - **CMS / Sanity**: `sanity/`, `src/app/(sanity-layout)/`
   - **Feature flags**: `src/flags.ts`

   List concrete files/dirs you expect to touch.

8. **Check for reusable primitives.** Before proposing any new UI, grep `src/components/common/` and the Radix imports in `package.json` — reuse beats rebuild.

9. **Propose a plan.** Lay out:
   - Steps you'd take
   - Files to edit/create
   - Data shape changes
   - New RTK Query endpoints if any
   - Test coverage

   Call out risks: URL shape changes (break deep links), persist shape changes (break existing users' localStorage), secrets leaking into client bundles, build-time-only envs.

   **Do NOT stop for approval** — you are non-interactive. Just print the plan to the session before the result block; the next human (in the resumed session) will review and direct from there.

10. **Emit final block** on the LAST lines of output (the bot parses this — no extra text after):

```
<<<SLACK_INTAKE_RESULT
ticket_id: REV-160
ticket_url: https://linear.app/...
branch: REV-160/short-desc
worktree: /Users/.../Worktrees/rev-160
title: Ticket title
mode: work
reused: true
comment_appended: true
SLACK_INTAKE_RESULT>>>
```

If any step fails, still emit the block with what you have plus an `error: <reason>` line. Never exit silently.
