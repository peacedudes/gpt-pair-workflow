#!/usr/bin/env python3
"""
fix_diff_counts.py — Recompute unified-diff hunk lengths and ensure a trailing newline.

- Reads a unified diff from a file or stdin.
- For each hunk header @@ -oldStart,oldLen +newStart,newLen @@[…],
  recomputes oldLen/newLen from the body:
    oldLen = context + deletions
    newLen = context + additions
  Context lines start with " ", deletions "-", additions "+".
  Lines starting with "\" (like "\ No newline at end of file") are ignored for counts.
- Preserves:
  - Paths and file headers (---/+++)
  - Any trailing text after the hunk header (e.g., function name)
  - All body lines and ordering
- Ensures the overall output ends with a newline.
"""

import sys
import re

HDR_RE = re.compile(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)$')

def emit_hunk(header_info, body, out):
    """
    header_info: (old_start, new_start, tail_text) or None if no active hunk
    body: list of lines (without trailing newlines)
    Recompute counts and emit corrected header + body.
    """
    if header_info is None:
        return
    old_start, new_start, tail = header_info
    c = d = a = 0
    for line in body:
        if not line:
            # Blank line inside hunk bodies is invalid in strict unified diffs,
            # but if present we treat it as context (space) for safety.
            c += 1
            continue
        ch = line[0]
        if ch == ' ':
            c += 1
        elif ch == '-':
            d += 1
        elif ch == '+':
            a += 1
        elif ch == '\\':
            # "\ No newline at end of file" — ignore for counts
            pass
        else:
            # Unexpected prefix; treat as context to be lenient
            c += 1
    old_len = c + d
    new_len = c + a
    out.write(f'@@ -{old_start},{old_len} +{new_start},{new_len} @@{tail}\n')
    for line in body:
        out.write(line + '\n')

def fix_stream(inp, out):
    in_hunk = False
    hunk_header = None  # tuple (old_start, new_start, tail_text)
    body = []

    def flush():
        nonlocal in_hunk, hunk_header, body
        if in_hunk:
            emit_hunk(hunk_header, body, out)
            in_hunk = False
            hunk_header = None
            body = []

    for raw in inp:
        # Keep line endings consistent (LF). Strip trailing \n for processing.
        line = raw.rstrip('\n')

        m = HDR_RE.match(line)
        if m:
            # Starting a new hunk; flush any previous one
            flush()
            old_start = int(m.group(1))
            new_start = int(m.group(3))
            tail = m.group(5) or ''
            in_hunk = True
            hunk_header = (old_start, new_start, tail)
            body = []
            continue

        # Beginning of a new file section or diff header ends the current hunk
        if in_hunk and (line.startswith('@@') or line.startswith('diff ') or line.startswith('--- ') or line.startswith('+++ ')):
            flush()
            out.write(line + '\n')
            continue

        if in_hunk:
            # Buffer hunk body lines verbatim (without trailing newline)
            body.append(line)
        else:
            # Pass-through for non-hunk lines
            out.write(line + '\n')

    # End of file: flush any pending hunk and make sure we end with a newline
    flush()
    # Ensure final newline: if the output did not end with newline, add one.
    # The writes above always ended with '\n', but in case input was empty:
    out.flush()

def main():
    if len(sys.argv) > 1 and sys.argv[1] != '-':
        with open(sys.argv[1], 'r', encoding='utf-8', newline='') as f:
            fix_stream(f, sys.stdout)
    else:
        fix_stream(sys.stdin, sys.stdout)

if __name__ == '__main__':
    main()

