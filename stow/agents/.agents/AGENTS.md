- Always spawn subagents for research
- 

- Prefer self-documenting code over comments
- But you must also write verbose comments for AI collaboration with `@ AI Context: ` prefix. This will help both me and you to understand the code and iterate just reading the comments instead of the understanding the whole codebase. This comments cant be stipped out with a separate tool called `strip-verbose-reasoning-comments` or "strip out verbose comments" phrase. But shouldn't be deleted most of the time and should summerize if they're raw reasoning back and forth comments befor the final decision.

- Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.
- Try to ask questions with your recommeded answers as options. Would prefer interactive QA prompt instead of plain text answer.
- You can commit yourself but must follow this rule:
  You will commit before each phase not after. You'll understand my prompt and decide whether its a follow-up and
  should be in one commit or it disconnected and need to commit the previous work first and continue working on that prompt and
  wait for the next prompt before commiting that round.

  Though even if a follow-up prompt/task/discussion feel connected but bigger, then you should commit the previous work and treat the current as separate phase.

  You shouldn't start commiting unless its a running project, a newly initialized repo and we're gonna throw bunch of ideas/work before the mvp or first/second real commit.

- Delete/Remove: `trash` with no args instead of `rm`
- Search: `rg` instead of `grep`
- Find: `fd` instead of `find`  
- Visualization: `tree --git-ignore` and `tree`. Prefer --git-ignore version most of the time to save output token.

- Reasoning: Keep chain‑of‑thought private; present conclusions and key steps.
- Brevity: Keep every token purposeful.

- Put any non project and temp files inside `NOGIT` folder. This filder will be globally ignored by git.
- Never put Co-authored-by in commit messages

# Hard rule for NextJS

Never make or convert a full page to dynamic or ISR for a dynamic component in that page. Make the leaf component client and use api routes with proper caching and revalidation. If makes sense propose for PPR. You must confirm the user about these decisions using your interactive QA prompt not just plain text in the output, which could be missed easily.

# Coding Guidelines

This document outlines the coding standards, architectural decisions, and best practices. I must follow these rules for all new code and refactoring.

## Project Structure & Organization

### Component Location
- **Co-location**: Always co-locate components/ in the `page.tsx` folder if they are specific to that page.
- **Global Components**: Move/Put components to `src/components` only if they are reused across multiple pages.
- **Common Components**: Use `src/components/common` for small to medium reusable components (e.g., `Badge`, `Avatar`, `Dropdown`).
- Don't name the folder`components/ui`

### Server vs. Client Components
- **Pages are Server**: Never convert a `page.tsx` to a client component.
- **Leaves are Client**: Keep client-side logic (`'use client'`) restricted to individual leaf components.
- **Layouts**: `layout.tsx` should generally always be server components.

### File Naming
- **Components**: PascalCase (e.g., `PropertyCard.tsx`, `SellerCard.tsx`).
- **Utilities**: camelCase (e.g., `cn.ts`).
- **Pages & Layout**: (e.g., `site-layout`, `privacy-policy`).
- **Types**: `types.ts` (for common types).

## Styling Guidelines

**Primary Rule**: Use **Tailwind CSS** for all new styling. Do not use SCSS or CSS modules for new code.

### Handling Variants & Conditionals
- **Complex Components**: Use `tailwind-variants` (`tv`) when a component has multiple slots or complex variant logic.

- **Simple Components**: Use the `cn` utility for simple conditional classes.
  - *Example*:
    ```tsx
    <RDropdown.Content
      className={cn(
        'tw-z-[1301] tw-min-w-[220px] tw-rounded tw-bg-white tw-text-black tw-shadow-xl',
        props.className
      )}
    >
      {props.children}
    </RDropdown.Content>
    ```
- **Anti-Pattern**: Do NOT use manual string interpolation or `if/else` logic for classes.
- Don't use `cva` or class-variance-authority, prefer `tv`

### Legacy Styles (Bootstrap)
- **Ignore**: Do not use Bootstrap styles or `react-bootstrap` components for new code.
- **Maintenance**: Do not modify or replace existing Bootstrap usage unless explicitly asked, but do not introduce it in new features.

## Component Architecture & Code Hierarchy

### Structure
```tsx
// imports

// initializations

interface Props {}

function ComponentName(props: Props) {
  // passive states (comes from the outside)
  // active states (both used by this component or it's child)

  // derived states (depends on other states above)

  // event handlers
  // & functions that rely on some internal states

  // effects

  // jsx
}

// local functions that don't have to be inside the component function closure
function LocalFunction() {}

// local utils

// local validation schema

export default ComponentName;
```

#### Prefer destructuring props in separate line instead of inline when there's more than 3 items

Instead of this:
```ts
function Button<T extends React.ElementType = 'button'>({
  as,
  children,
  className
  ...rest
}: Props<T>) {}
```

Do this:
```ts
function Button(props: Props) {
  const { as, children, className ...rest } = props;
```

#### Always prefere naming interface `Props` over `ButtonProps` unless it exports for other other components to use, then name it `ButtonProps`

### Reusable Component Patterns
- **Radix UI**: Wrap Radix UI primitives for accessible, reusable components.
- **Compound Components**: Use dot notation for sub-components.
  - *Example*: `SellerCard.tsx`
    ```tsx
    // Main Component
    function SellerCard({ seller, ...props }: Props) {
       // ...
       <SellerCard.Name>{/*...*/}</SellerCard.Name>
       // ...
    }

    // Sub-component attached to main component
    SellerCard.Name = (props: { children: React.ReactNode }) => {
      return (
        <div className='tw-relative tw-self-start'>
          <h4 className='!tw-mb-0 tw-max-w-[250px] tw-truncate tw-capitalize tw-text-primary'>
            {props.children}
          </h4>
          {/* ... */}
        </div>
      );
    };
    ```
- **Images**: ALWAYS prefer `next/image`.
- **Icons**: Use Phosphor Icons from (`@phosphor-icons/react/dist/ssr`).

## State Management
- **Preference**: Prefer local react states instead of global states, you can use the existing ones if exist.
- **Complex Global State**: Use Zustand with Immer middleware when starting new projects only if necessary

## API
- use fetchResult(), a fetch wrapper that returns data or error as { data, error } (discriminated union, findme style)
- create one for new projects if doesn't exist

## Workflow
- **Analysis**: Before analyzing code, analyze `README.md`.
- **Implementation**: Follow the `tv` and `cn` + Radix pattern.
  - `tv` Example:
    ```tsx
    const card = tv({
      slots: { base: 'tw-flex', header: 'tw-p-4' },
      variants: { variant: { default: { base: 'tw-bg-white' } } }
    });
    ```
  - `cn` + Radix Example:
    ```tsx
    <RDropdown.Content className={cn('tw-z-50 tw-bg-white', className)}>
      {children}
    </RDropdown.Content>
    ```

#### `cn` Usually defined in lib/cn.ts like this:

```ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## MCP
- Use `next-devtools` when working with nextjs projects
- Use `motion` when working with `motion` or `framer-motion`

## Libraries

If Context7 MCP exist, Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.

## React 
Mirrored and shortened from gemini-cli GEMINI.md
Mirrored and adjusted from react-mcp-server

## Role
Act as a React + Next.js optimization expert. Prioritize patterns that enable React Compiler optimizations, reduce re-renders, and improve performance.
## Core Principles
- **Functional Only**: Use functional components and Hooks exclusively. No class components.
- **Purity**: Render logic **must** be pure. Side effects belong in event handlers or `useEffect`, never in the render body.
- **Immutability**: Never mutate state directly. Use spread syntax or immutable patterns with state setters.
- **Data Flow**: Unidirectional (props down). Lift state or use Context/Server State; avoid syncing local state manually.
## Hooks & Effects
- **Rules of Hooks**: Call unconditionally at the top level.
- **`useEffect` Discipline**:
  - **Minimize usage**: Derive state during render whenever possible.
  - **Purpose**: Strictly for synchronization with external systems.
  - **Performance**: **NO** `setState` inside effects (causes loops/perf degradation).
  - **Correctness**: Always include cleanup functions and exhaustive dependencies.
- **Refs**: Use only for non-reactive escape hatches (focus, animations). **Never** read/write `ref.current` during render.
## Architecture & Performance
- **Composition**: Prefer small, composable components and custom hooks over monoliths.
- **Concurrency**: Ensure components are idempotent (safe for multiple renders). Use functional state updates (`set(prev => prev + 1)`).
- **Data Fetching**: Prevent waterfalls. Use parallel fetching, Server Components, and Suspense. Co-locate data requirements.
- **React Compiler**: **Omit** `useMemo`, `useCallback`, and `React.memo` by default. Trust the compiler for memoization unless profiling proves otherwise.
- **UX**: Implement non-blocking states (Skeletons > Spinners), Error Boundaries, and optimistic UI.

### Process

1. Analyze the user's code for optimization opportunities:
   - Check for React anti-patterns that prevent compiler optimization
   - Look for component structure issues that limit compiler effectiveness
   - Think about each suggestion you are making and consult React docs for best
     practices

2. Provide actionable guidance:
   - Explain specific code changes with clear reasoning
   - Show before/after examples when suggesting changes
   - Only suggest changes that meaningfully improve optimization potential

### Optimization Guidelines

- State updates should be structured to enable granular updates
- Side effects should be isolated and dependencies clearly defined

## Comments policy

Write high-value comments if necessary. Avoid talking to the user through
comments.

- Cleanup your own reasoning comments after implementing code
- Never add numbered comments, and comments that resemble or answer a requirement plan or comments that sound like made for product managers
- Never write too many comments to explain named things variables, interfaces, fields, functions
- Always keep comments concise and short

## Others

- Always place new lines before and after if blocks and return statement
- Prefer writing if blocks, don't inline the statement unless it's under 60 chars or less long line
- Always place new lines before and after try catch blocks
- Never do this, this is not needed anymore
```ts
import * as React from 'react';
```
- Always import react libraries like this:
```ts
import { useEffect } from 'react';
```

- Do this for all phosphor-icons
- Importng Icon as { CaretLeft } from phosphor-icons is deprecated, import { CaretLeftIcon } instead
- Always import icons from `@phosphor-icons/react/dist/ssr`
- Never pick other icon library unless mentioned
- Always use `motion` instead of `framer-motion`
- Always prefer LazyMotion strict mode
- `import * as m from 'motion/react-m';`

- Always use `antialiased` for new tailwind projects in the body element in root layout
- Always use `git mv` for moving and renaming files and folder
- Always use `trash` for deleting files and folder
- Always use `trash` instead of `rm` or `rm -rf`
- Never install or build anything that requires x86_64 arch
- **Docker runtime is OrbStack.** Docker Desktop was removed months ago. Never
  install it, never `open -a Docker`, never `brew install --cask docker`. On
  "Cannot connect to the Docker daemon", the cause is almost always the active
  context, not a missing app: run `docker context ls` and `docker context use
  orbstack`, and start OrbStack (`open -a OrbStack`) if it is not running. A
  stale `desktop-linux` context points at
  `unix://~/.docker/run/docker.sock`, which nothing is listening on.
- If `docker compose` reports "unknown command" while `docker-compose` works,
  the CLI plugin dir is missing, not the tool. Relink it — do NOT install
  anything:
  `ln -sf /Applications/OrbStack.app/Contents/MacOS/xbin/docker-compose ~/.docker/cli-plugins/docker-compose`
  (same for `docker-buildx`). `~/.docker/config.json` is shared with OrbStack:
  it carries `credsStore`, so edit `currentContext` in place, never delete it.
- Never install system software, casks, or daemons without asking me first.
  "The test suite needs it" is a reason to ask, not a reason to install.
- When visiting a url, check for markdown version by attaching `.md` at the end of the path, otherwise use token efficient method to read a webpage
- Always prefer color text-primary, text-secondary etc over explicit similar color like text-gray-500

# Writing

Applies to everything with words in it: product copy, headings, docs, commit
messages, and your replies to me. The failure mode is writing that has the SHAPE
of good writing and carries no information — it reads like a manifesto and tells
the reader nothing.

## The test

**Could this sentence appear on a competitor's site, unchanged?** If yes, it says
nothing. Delete it or replace it with the specific fact it was standing in for.

Second test: **is there a noun in it I can picture?** "Two people, ten years, one
thing done properly" passes. "Deep experience and a commitment to craft" does not.

## The tics, by name

1. **Antithesis / chiasmus** — `X, not Y`. The strongest tell.
   - No: "Things we own, not things we were hired to build."
   - Yes: "Our own products." Or name them.
2. **Aphorism with no referent** — a line that would fit any company, any product.
3. **Rule of three** — "fast, safe and simple." Three adjectives is a rhythm, not
   an argument. Use one, and make it specific.
4. **Abstract nouns doing the work** — clarity, craft, intentionality, care,
   thoughtfulness. Name what was done instead.
5. **"It's not just X, it's Y."**
6. **Portentous fragment** — "That's the point." "By design." "Every time."
7. **Self-praise as description** — deliberately, carefully, hand-crafted,
   thoughtfully. If the reason is real, give it; otherwise cut the adverb.
8. **Em-dash stacking** — more than one appositive per sentence. If a second idea
   needs bolting on, it needs its own sentence.
9. **Copy about the copy** — "Here's what makes this different."
10. **Vague superlatives** — beautiful, seamless, delightful, powerful.

## Rules

- Concrete noun over abstract one. A number over an adjective.
- One idea per sentence.
- Cut any sentence whose only job is rhythm.
- Never announce that a choice was deliberate. Give the reason, or say nothing.
- A heading names the thing, not the theme.
- Say the awkward part plainly rather than softening it into abstraction — the
  softened version is always the one that sounds AI-written.

## In replies to me

- Open with the result. No restating what I asked.
- No closing summary of what you just said.
- Don't narrate what you're about to do; do it.
- When something failed, say so in the first sentence, not after the good news.

# Subagents, Fan-out & Token Cost

Measured 2026-08-19: one 23-agent Opus 5 fan-out burned 183.6M tokens in ~20
minutes. Output was 0.5M of that (0.3%) — the other 99% was cache reads, i.e.
the same context replayed on every turn of every agent. Cost scales with
`context size x turns x agents`, not with how much the agents write.

## Model tier

**Every `agent()` call and every Agent-tool call names its model explicitly.
There is no case where omitting it is correct.**

This overrides the Workflow tool's own documentation, which says "Default to
omitting `model` — the agent inherits the main-loop model, which is almost
always correct." It is not correct here. Omitting it silently runs an entire
fleet on the session model; that is how a week of quota disappears in a day.
When the tool's default and this file disagree, this file wins.

- **Executors run `model: 'sonnet'`.** Anything that applies a spec, edits
  files, greps, reads, or reports findings. Agent count is irrelevant — a
  single agent that types code is still an executor. "It's only two agents" is
  not an exemption, and neither is "the task is important".
- **The session model plans and verifies, and does nothing else.** It writes the
  spec; it judges the result. If one agent is both deciding the design and
  typing it, the split has not happened and the work is mis-tiered — re-scope it
  before launching.
- Premium tier for a fleet only when I ask for it in that same message. A
  standing "ultracode" authorizes breadth, never tier.
- Single deep-reasoning tasks may stay on the higher tier — depth, not breadth.
- Never ship a fleet's output unverified.

**Pre-launch checkpoint.** Before calling Workflow or spawning agents, write one
line in the reply: how many agents, at which model and effort, and who verifies.
If that line cannot be written, the script is not ready to run. Putting it in the
message is what lets me stop you before the spend, not after.

## Fleet size
- **10-15 concurrent agents maximum.** If the work needs more, batch it in
  waves and summarize between waves.
- Prefer pipelines (each item flows through its stages independently) over
  barriers that hold every agent open waiting for the slowest one.

## Caching / context discipline
- Keep each subagent's prompt narrow. A smaller starting context is multiplied
  by every turn that agent takes, so trimming it pays three ways at once.
- Delegate searching, keep the conclusion. Never let a subagent's raw file
  dumps land in the main thread — ask for `file:line` refs and findings.
- Don't re-derive what's already in context, and don't re-read a file that was
  just edited to "verify" it.
- Reuse one warm session rather than restarting: cached context is far cheaper
  to replay than to rebuild.
- Cap agent turns by giving a clear stop condition; an agent with a vague task
  keeps looping over the same expensive context.
- Long tool output belongs in a file or the scratchpad, not the transcript.

## Plan, then execute (the default for medium+ work)

Split the work: an expensive model **plans**, a cheap model **executes**, the
expensive model **verifies**. Planning is where judgement lives and is worth the
tokens; typing the edit is not.

- **Planner**: Opus, `xhigh` only when I have agreed to it (see Effort below).
  Reads what it needs, writes a spec. Does not edit.
- **Executor**: Sonnet, `low`/`medium`. Applies exactly the spec. Makes no
  design calls; if it must decide something, it stops and reports instead.
- **Verifier**: the planner (or the main loop). Runs the suite, reconciles the
  agents, judges honestly. Never ship an executor's word for it.

**Size rule.** A one-file edit, a rename, a copy tweak, a known one-liner — just
do it. Below roughly two files or fifteen minutes the protocol costs more than
it saves. Use it when the work spans several files, has a seam between parts, or
will be handed to more than one agent.

### What a spec must contain

An executor cannot infer. A spec that omits any of these produces confident
wrong work:

- The **exact files** it owns, and an explicit "touch nothing else".
- The **change per file**, concrete enough to apply without judgement.
- **Why**, in one line — an executor that understands intent recovers from small
  surprises instead of guessing.
- The **verification command** and what passing looks like.
- A **stop condition**: what to do when reality contradicts the spec (report,
  do not improvise).
- **Decisions already made**, so they are not silently re-litigated.

### Parallelism

- Split by **disjoint file sets**. Two agents in one file corrupt each other.
- Every seam between two agents' files belongs to a **named owner** — usually
  the verifier. Unowned seams are where the defects land.
- Prefer pipelines over barriers (see Fleet size above).

### Effort tiers

- **State `effort` on every agent call, the same way as `model`.** Executors
  `low`, finders and reviewers `medium`, only a final judge `high`. Omitting it
  inherits the session effort — the same silent escalation as omitting `model`,
  and the two compound.
- Default **medium**; **high** for genuinely hard reasoning or a final judge.
- **Never auto-select `xhigh` or `max`.** Ask first, and say what specifically
  needs it and what it costs. "It is important" is not a reason; "three
  independent verifiers disagree and the wrong call ships a payment bug" is.
- Effort is not a substitute for a better prompt. Cheap and specific beats
  expensive and vague.

### Edge cases, all observed in real runs

- **Executors skip the build**, reasoning that concurrent edits make it
  meaningless. That reasoning is wrong: the build is what catches cross-file
  collisions. Executors self-check syntax only; the **verifier** runs lint,
  types, tests and build once, after collecting everyone.
- **An agent reports success on inert work.** It changed the constant and not
  the caller, so the feature does nothing. Specs must name the **end-to-end
  behaviour** to prove, never the unit.
- **A red test handed back as a finding.** If a change makes an assertion false,
  the spec says which tests change and why. Red is not a handoff.
- **Shared literals drift.** The same number lived in two files and they moved
  apart silently. When a spec touches a constant, grep for its siblings and put
  the value in one place.
- **The probe does not discriminate.** A verification that would pass on broken
  code proves nothing — check a known-negative control before believing a green.
- **Stale dev-server output.** CSS and bundle claims must be verified against a
  production build; a dev server serves stale assets and will lie.
- **Relaying an agent's claim as fact.** Load-bearing claims get verified
  first-hand before they reach me or the code. Being wrong twice costs more than
  the check.
- **Raw file dumps in the transcript.** Ask for `file:line` and findings. Long
  output goes to a file or the scratchpad.

# Agency

The agency brain lives at `/Volumes/Work/agency`. Start there — `AGENTS.md` is its index.

Read it when the work is agency work: clients, pricing, positioning, sales material, our own SaaS
products, or anything commercial. That is a question about the task, not the directory — writing a
case study for say4real is agency work even though the repo is personal, and revnest work never is.

Pull it on demand. Do not preload it into unrelated sessions, and never read `brain/research/**`
whole — grep it.

# Revnest Frontend Specific Guidelines Start -

While following everything from above, revnest frontend must respect these rules:

## State Management
- **Redux**: Use Redux Toolkit.
- **Reference**: Prefer local react states instead of global redux slices and states for new functionality, you can should the existing ones if exist.
- **API**: Use RTK Query for client components, and fetchResult()/fetchWithResult() for server components.


## Exclusions & Ignores
- **Files to Ignore**:
  - `*.scss` files (do not edit, prefer Tailwind).
  - `*.service.ts` files.
  - `src/redux/slices` (except `propertySlice.ts`).
  - Files marked "to be deleted" or "marked for delete".
  - Commented out code (read for context, and previous works).
  - Unused imports (ignore, shouldn't remove them).

#### Never specify heading elements color explicitly, unless asked to do, ignore heading colors from screenshots too

# Revnest Frontend Specific Guidelines End -

# Memory & compaction

Autocompact is ON. Two layers survive it, and they are the reason a compaction is cheap
rather than lossy:

- `~/.claude/memory/` — shared core, injected into every project by the SessionStart hook.
  Identity, standing rules, Rokiron canon. Files with `always: true` in frontmatter are
  injected in full; the rest are index lines to read on demand.
- `~/.claude/projects/<project>/memory/` — project-specific state, loaded per project.

**Neither memory directory is tracked in the dotfiles repo, and neither should be.** That repo
is PUBLIC, and these files hold personal profile and business canon. They are also the one
layer that legitimately grows per project. So the hooks ship in the repo and their data does
not: a fresh machine gets a working `memory-inject.py` reading an empty directory, which is the
intended trade. Back the memory up somewhere private instead — never by adding it here.

**Write policy.** Write a memory when the user makes a decision, corrects me, or states a
constraint — at the moment it happens, not at the end of the session. Those are the things
that are expensive to lose and cheap to record. Do not write facts the repo already holds
(code structure, git history, anything in `brain/` or a `PROJECT.md`); point at the file
instead. Never write a secret, token or env VALUE into memory — names only.

**Context discipline.** Context is not storage; disk is. Anything that must survive goes in
a file before it is needed again. Prefer `/clear` when switching to unrelated work over
letting one session carry dead weight — a turn at 950k context costs roughly 5x the same
turn at 200k.
