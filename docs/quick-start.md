# Quick Start — Peek → Patch → Apply (clipboard-first)

Why this
- GPT can’t clone/push to your repo or keep uploaded zips “alive” across turns. A plain‑text repo dump persists in chat.
- We keep a tight loop: Share bytes → Peek → Patch → Apply → Test → Repeat. Small, anchored diffs apply cleanly.

Tools (scripts/)
- sharefiles — copies repo metadata + all tracked files to clipboard as fenced code blocks. Paste once per session.
- applyPatch — reads a diff from clipboard/stdin/file, auto‑fixes hunk counts, ensures final newline, then git apply.
- fixDiffCounts.swift — recomputes @@ hunk lengths from the body. Awk fallback: fix-diff-counts.sh.
- xcb.sh — build/test with short logs to clipboard (stderr+stdout).

Contract (safety + cadence)
- One action per step; everything clipboard‑driven.
- The assistant only asks you to run obvious commands. You should refuse anything you don’t understand at a glance.
- Always paste code/patches/logs as fenced code blocks that end with a newline.

The loop
1) Share repo (once per session):
```bash
scripts/sharefiles
```
2) Run peeks the assistant asks for; paste output verbatim.
What peeks do: “nl -ba” numbers every line (including blanks). “sed -n 'S,Ep'” prints just that slice. You’ll usually send a small bundle:
```bash
{
  echo "=== Sources/Widget.swift (1–140) ==="
  nl -ba Sources/Widget.swift | sed -n '1,140p'
  echo
  echo "=== Sources/Utils/Tools.swift (60–120) ==="
  nl -ba Sources/Utils/Tools.swift | sed -n '60,120p'
  echo
  echo "=== Tests/WidgetTests.swift (1–200) ==="
  nl -ba Tests/WidgetTests.swift | sed -n '1,200p'
} | pbcopy
```
3) Apply the returned patch from clipboard (applyPatch does pbpaste internally):
```bash
scripts/applyPatch --from-clipboard
```
4) Build/test and send short logs:
```bash
scripts/xcb.sh build
# or:
scripts/xcb.sh test
```
5) Repeat. After any patch lands, the assistant re‑peeks before drafting the next one.

Why auto‑fix counts?
- Models often miscount @@ lengths (oldLen/newLen). We always fix on the way out, so small count errors don’t derail progress.

Patch expectations
- Pure unified diff in one fenced block:
  - --- a/path and +++ b/path
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Lines start with space (context), - (deletion), + (addition)
  - LF endings; final newline
- New files: --- /dev/null and +++ b/path with @@ -0,0 +N,N @@

Non‑macOS
- Replace pbcopy/pbpaste with your platform’s clipboard tool; the assistant can adapt the scripts.
