#!/usr/bin/env python3
"""
Stop hook: detects Claude Code rate limit stops, waits for reset, then resumes.

Outputs {"decision": "block", "reason": "..."} to force Claude to continue
after the wait period. Exits 0 silently for normal (non-rate-limit) stops.
"""

import json
import re
import sys
import time
from datetime import datetime, timedelta

RATE_LIMIT_PATTERNS = [
    r'usage limit reached',
    r'rate limit',
    r'resets at \d+:\d+',
    r'try again in \d+',
    r'too many requests',
    r'quota exceeded',
    r'claude ai usage',
]

RATE_LIMIT_STOP_REASONS = {
    'rate_limit', 'usage_limit', 'quota_exceeded', 'max_requests',
}

def read_stdin() -> dict:
    try:
        return json.loads(sys.stdin.read())
    except Exception:
        return {}


def extract_wait_seconds(text: str) -> int:
    # "resets at 4:30 PM" or "resets at 16:30"
    m = re.search(r'resets at (\d+:\d+\s*(?:AM|PM)?)', text, re.IGNORECASE)
    if m:
        try:
            time_str = m.group(1).strip()
            now = datetime.now()
            fmt = '%I:%M %p' if re.search(r'[AP]M', time_str, re.IGNORECASE) else '%H:%M'
            reset_time = datetime.strptime(time_str, fmt).replace(
                year=now.year, month=now.month, day=now.day
            )
            if reset_time <= now:
                reset_time += timedelta(days=1)
            return max(60, int((reset_time - now).total_seconds()) + 90)
        except Exception:
            pass

    m = re.search(r'try again in (\d+)\s*minute', text, re.IGNORECASE)
    if m:
        return int(m.group(1)) * 60 + 60

    m = re.search(r'wait (\d+)\s*second', text, re.IGNORECASE)
    if m:
        return int(m.group(1)) + 30

    return 3660  # default: 1 hour + 1 min buffer


def scan_transcript(transcript_path: str) -> tuple[bool, str]:
    try:
        with open(transcript_path, 'r') as f:
            lines = f.readlines()
    except Exception:
        return False, ''

    combined = re.compile('|'.join(RATE_LIMIT_PATTERNS), re.IGNORECASE)

    for raw_line in reversed(lines[-20:]):
        try:
            entry = json.loads(raw_line)
        except Exception:
            continue

        text = json.dumps(entry)
        if combined.search(text):
            snippet = ''
            if entry.get('type') == 'assistant':
                for block in entry.get('message', {}).get('content', []):
                    if isinstance(block, dict) and block.get('type') == 'text':
                        snippet = block.get('text', '')[:200]
                        break
            return True, snippet or text[:200]

    return False, ''


def wait_with_countdown(seconds: int) -> None:
    end = time.time() + seconds
    print(f"\n⏸  Rate limit — waiting {seconds // 60}m {seconds % 60}s for reset...",
          file=sys.stderr, flush=True)
    while True:
        remaining = end - time.time()
        if remaining <= 0:
            break
        m, s = int(remaining // 60), int(remaining % 60)
        print(f"\r   {m:02d}:{s:02d} remaining ", end='', file=sys.stderr, flush=True)
        time.sleep(1)
    print("\r▶  Rate limit reset — resuming...        ", file=sys.stderr, flush=True)


def main() -> None:
    data = read_stdin()

    stop_reason = data.get('stop_reason', '')
    transcript_path = data.get('transcript_path', '')

    rate_limited = False
    context_text = ''

    if stop_reason.lower() in RATE_LIMIT_STOP_REASONS:
        rate_limited = True
        context_text = f'stop_reason={stop_reason}'

    if not rate_limited and transcript_path:
        rate_limited, context_text = scan_transcript(transcript_path)

    if not rate_limited:
        sys.exit(0)

    wait_seconds = extract_wait_seconds(context_text)
    wait_with_countdown(wait_seconds)

    print(json.dumps({
        "decision": "block",
        "reason": (
            "Rate limit period has ended. "
            "Please continue with the task from where you left off, "
            "without re-summarizing what was already done."
        )
    }))


if __name__ == '__main__':
    main()
