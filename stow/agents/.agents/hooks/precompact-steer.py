#!/usr/bin/env python3
"""PreCompact hook: steer what the compaction summary keeps, and log the transcript.

Stdout is appended to the compaction custom-instructions (merged via the CLI's KNe()),
so it changes what the summarizer preserves. It cannot inject context into the model
and cannot make the model write memory files — those stay a session-time habit.

Also appends a pointer to ~/.claude/compaction-log.jsonl. The raw .jsonl transcript
survives compaction, so nothing is ever truly unrecoverable.
"""
import json, sys, os, datetime

LOG = os.path.expanduser('~/.claude/compaction-log.jsonl')

INSTRUCTIONS = """\
Preserve these verbatim, at the cost of narrative detail:

1. Open tasks and their exact state — what is done, what is blocked, and on what.
2. Decisions the user made, with the reason. Never re-litigate a settled decision.
3. Exact identifiers: file paths, IDs, URLs, branch names, env var NAMES.
   Never carry an env var VALUE, token, key or password into the summary.
4. Constraints and corrections the user stated, in his wording.
5. Which claims were verified first-hand versus assumed — do not promote an
   assumption to a fact across the boundary.
6. Failures and their root cause, so they are not repeated.

Durable cross-project facts live in ~/.claude/memory/ and project facts in
<project>/memory/, both reloaded after compaction. Do not restate their content;
name the memory file instead. Prefer a pointer to a file on disk over an inline
copy of anything that is already written down."""

def main():
    try:
        raw = sys.stdin.read()
        ev = json.loads(raw) if raw.strip() else {}
    except Exception:
        ev = {}

    try:
        with open(LOG, 'a', encoding='utf-8') as fh:
            fh.write(json.dumps({
                'at': datetime.datetime.now().astimezone().isoformat(),
                'session_id': ev.get('session_id'),
                'trigger': ev.get('trigger'),
                'cwd': ev.get('cwd'),
                'transcript_path': ev.get('transcript_path'),
            }) + '\n')
    except OSError:
        pass

    print(INSTRUCTIONS)

if __name__ == '__main__':
    main()
