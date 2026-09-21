#!/usr/bin/env python3
"""SessionStart hook: inject the shared memory core into every project.

Per-project memory (~/.claude/projects/<proj>/memory/) is loaded by Claude Code itself.
This adds a cross-project layer so identity, standing rules and business context do not
have to be re-explained in egquiz / revnest / findme sessions.

Emits the full index (cheap) plus the body of any memory whose frontmatter has
`always: true` — behavioural rules must apply without a lookup round-trip.
"""
import json, sys, os, re

CORE = os.path.expanduser('~/.claude/memory')

def frontmatter(text):
    m = re.match(r'^---\n(.*?)\n---\n', text, re.S)
    return (m.group(1), text[m.end():]) if m else ('', text)

def main():
    try:
        raw = sys.stdin.read()
        ev = json.loads(raw) if raw.strip() else {}
    except Exception:
        ev = {}

    index = os.path.join(CORE, 'MEMORY.md')
    if not os.path.isfile(index):
        return

    parts = [open(index, encoding='utf-8').read().strip()]

    always = []
    for fn in sorted(os.listdir(CORE)):
        if not fn.endswith('.md') or fn == 'MEMORY.md':
            continue
        try:
            text = open(os.path.join(CORE, fn), encoding='utf-8').read()
        except OSError:
            continue
        fm, body = frontmatter(text)
        if re.search(r'^\s*always:\s*true\s*$', fm, re.M):
            always.append(f'## {fn}\n\n{body.strip()}')

    if always:
        parts += ['', '---', '', '# Always-on rules (full text)', ''] + always

    src = ev.get('source', '')
    if src == 'compact':
        parts += ['', '---', '',
                  'Context was just compacted. The summary is narrative; these memories and the '
                  'files they name are the authoritative facts. Re-read a file before acting on '
                  'anything it describes.']

    print(json.dumps({'hookSpecificOutput': {
        'hookEventName': 'SessionStart',
        'additionalContext': '\n'.join(parts),
    }}))

if __name__ == '__main__':
    main()
