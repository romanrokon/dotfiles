---
name: start-ticket
description: Fetch a Linear ticket, map it to the relevant frontend code areas, create a branch, and propose a plan. STOPS for approval before writing any code.
argument-hint: <TICKET-ID>
---

You are starting work on a Linear ticket. The ticket ID is: `$ARGUMENTS`.

## Steps

1. **Fetch the ticket** from Linear via the linear MCP tools (`get_issue`). Read the full description and all comments.

2. **Summarize the ticket** in 3–5 bullets: goal, acceptance criteria, any open questions or ambiguity.

3. **Map the work to code areas.** Cross-reference the ticket against this project's layout:
   - **Routes**: `src/app/(site-layout)/`, `src/app/(wizard-layout)/`, `src/app/(sanity-layout)/`, `src/app/api/`
   - **Components**: `src/components/common/` (reusable — check here first for anything new), `src/components/layout/`, `src/components/RSC/`, domain folders (`destination/`, `pricing/`, `profile/`, `regulation/`, `landing/`, etc.)
   - **State**: `src/redux/slices/`, `src/redux/api/{domain}/`
   - **Services**: `src/services/`
   - **CMS / Sanity**: `sanity/`, `src/app/(sanity-layout)/`
   - **Feature flags**: `src/flags.ts`
     List concrete files/dirs you expect to touch.

4. **Check for reusable primitives.** Before proposing to build any new UI, grep `src/components/common/` and the Radix imports already in `package.json` — reuse beats rebuild.

5. **Create a branch.** Use: `git checkout -b <ticket-id>/<kebab-description>` (e.g. `<TICKET-ID>/pricelabs-connection`). Match the naming style in recent commits (`git log --oneline -20`).

6. **Propose a plan.** Lay out the steps you'd take: files to edit/create, data shape changes, new RTK Query endpoints if any, test coverage. Call out risks: URL shape changes (break deep links), persist shape changes (break existing users' localStorage), secrets leaking into client bundles, build-time-only envs.

7. **STOP and wait for the user to approve the plan.** Do not write code yet.

Do not skip the stop. Plans diverge quickly; alignment now saves rework later.
