# Quick Start — Peek → Patch → Apply (clipboard-first)

Why this
- GPT can’t clone/push to your repo, and forgets contents of a zip archive quickly. A plain‑text repo dump can persist.
- We keep a tight loop: Share repo, then Peek → Patch → Apply → Test → Repeat.
- Chat UIs slow down as context grows. Starting a fresh instance and getting back to speed quickly is critical.

Privacy Warning
- Don’t share private or unshareable repos without permission. Repeat that out loud and pause.  This workflow works by pasting the contents of all text files in a repo into GPT or similar chat.  That may not be ok for your situation, especially professional. Think before using.

Tools (scripts/)
- Put these in your $PATH, copy them to your $HOME/bin, or otherwise make them accessible.
  - sharefiles — copies repo list and all (text) tracked files to clipboard as fenced code blocks. Paste once per session.
  - applyPatch — reads a diff from clipboard (or file), auto‑fixes hunk counts, ensures final newline, then git apply.
  - fix-diff-counts.sh — recomputes @@ hunk lengths from the body of the changes made.
  - xcb.sh — sample build/test with short logs copied to clipboard (stderr+stdout). Create your own by asking GPT to make something to test your project and copy the results it wants to see to the clipboard.
  - toClip / fromClip - Agnostic clipboard adapters to copy to or paste clipboard contents to stdout.

Assistant’s first reply (template)
- In the repo you want to work on, run this and paste the clipboard output here:
```bash
sharefiles
```
- After I see the snapshot, I’ll propose one tiny, low‑risk first change, request a minimal peek of the exact lines I’ll touch, and return a unified diff you can apply with applyPatch.

Contract (safety + cadence)
- One action per step; everything clipboard‑driven.
- The assistant only requests obvious, low‑risk commands; the human operator should refuse anything unclear at a glance.
- Always paste code/patches/logs as fenced code blocks that end with a newline.
- The assistant batches multiple peeks into one block so the human runs one command per step.

Share This repo (once per session)
- From this repo run this, then paste the clipboard into a fresh GPT session to let it know what we're doing.
```bash
scripts/sharefiles
```
Share Your Project repo (usually once per session)
- From your local repo, do the same and paste the clipboard to GPT.
```bash
sharefiles
```
Choose something the assistant will work on first.
- Collaborate as makes sense. Partnership works well.

The loop
1) Assistant requests peek of places it will be patching. Peeks are directly executable shell command blocks.
2) Paste peek request into shell, review for sanity/safety, then hit Return to load the clipboard. Paste directly to assistant verbatim.
- What peeks do:
   - nl -ba adds visible line numbers (including blanks) without changing bytes.
   - sed -n 'START,ENDp' prints only that range.
   - Both are read-only and safe.
   - toClip copies standard input to the clipboard.
   - Typical bundle requested by the assistant:
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
} | toClip
```
3) Assistant prepares and returns a fenced code block with its patch.
   - Multi-file patches are OK only if we just peeked all touched files in one request. Otherwise, send a single-file patch and iterate.
4) Copy the returned patch, and apply it directly from the clipboard (applyPatch reads from the clipboard by default):
```bash
applyPatch
```
5) Build/test and send short logs:
- As early as step two, errors can occur. When they do, just paste the error to the assistant and the loop restarts.
- Just getting to the point where there are no compile errors and testing can be done can be challenging.
- GPT may not make patches without peeking first, because they usually fail. Refuse patches without a fresh peek first.
- Ask the assistant to create your own run script that's easy, limits output, and leaves results copied to clipboard.
```bash
xcb.sh test
```
6) Repeat until goal has been reached. After any patch lands, the assistant re‑peeks before drafting the next one.

Commit changes to preserve work in progress.

Why auto‑fix counts?
- Models often miscount @@ lengths (oldLen/newLen). We always repair them, so small count errors don’t derail progress.

Unified diff in brief (what Assistant will create and paste back)
- One block that ends with a newline. For each file:
  - --- a/path/to/file
  - +++ b/path/to/file
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Lines: space = context, - = deletion, + = addition (LF endings)

Replace one line (example)
```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,3 +42,3 @@
    let x = foo()
-   let y = oldCall(x)
+   let y = newCall(x)
    return y
```

Insert one line (example, characteristically with a bad count)
```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,2 +99,3 @@
    vm.refresh()
+   vm.bootstrapIfNeeded()
```

Patch expectations
- Pure unified diff in one fenced block:
  - --- a/path and +++ b/path
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Lines start with space (context), - (deletion), + (addition)
  - LF endings; final newline
- New files: --- /dev/null and +++ b/path with @@ -0,0 +N,N @@

