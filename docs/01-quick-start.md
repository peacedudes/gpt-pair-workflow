# Quick Start -- Peek → Patch → Apply (clipboard-first)
Why this
- GPT can't clone/push to your repo, and it often forgets contents of a zip archive quickly. A plain-text repo dump can persist.
- We keep a tight workflow: Share repo, then Peek → Patch → Apply → Test → Repeat.
- Chat UIs can slow down as context grows, making it essential to start fresh when lag occurs.
Privacy Warning
- Don't share private or unshareable repos without permission. Repeat that out loud and pause.  This workflow works by pasting the contents of all text files in a repo into GPT or similar chat.  That may not be ok for your situation, especially in a professional setting. Think before using. Don't neglect to think about embedded credentials or other secrets.
Tools (scripts/)
- Put these in your $PATH, copy them to your $HOME/bin, or otherwise make them accessible.
  - sharefiles -- copies repo list and all (text) tracked files to clipboard as fenced code blocks. Paste once per session.
  - applyPatch -- reads a diff from clipboard (or file), auto-fixes hunk counts, ensures final newline, then git apply.
  - fix-diff-counts.sh -- recomputes @@ hunk lengths from the body of the changes made.
  - toClip / fromClip - Agnostic clipboard adapters to copy to or paste clipboard contents to stdout.
Contract (safety + cadence)
- One action per step; everything clipboard-driven.
- One patch per step: at any given step, the assistant should provide at most one combined diff for you to apply, even if it touches multiple files.
- The assistant only requests obvious, low-risk commands; the human operator should refuse anything unclear at a glance.
- Always paste code/patches/logs as fenced code blocks that end with a newline.
- The assistant batches multiple peeks into one block so the human runs one command per step.

- Project-specific aliases like 'test', 'build', and 'lint' (that send output through toClip) are a good alternative to hard-coded scripts.
### Note: `nl` delimiter (TAB by default) vs file bytes
- By default, `nl -ba` uses a TAB delimiter between the line number and the real file content.
- Prefer `nl -ba -s'|'` in peek commands so the delimiter is a visible pipe character instead.
- In patches: avoid introducing TABs by accidentally copying peek formatting (applyPatch rejects TABs by default).
### Share This repo (once per session)
- From this repo run "sharefiles" and paste the clipboard into a fresh GPT session to get it up to speed quickly.
~~~bash
scripts/sharefiles
~~~
Assistant's first reply (template)
- From the repo you want to work on, run this and paste the clipboard output here to share all the files at once:
~~~bash
sharefiles
~~~
- After I see the snapshot, I'll propose one tiny, low-risk first change, request a generous peek of the exact lines I'll touch, and return a unified diff you can apply with applyPatch.

Assistant first peek request (template)
- One command, generous windows, batched into a single clipboard block.
~~~bash
{
  echo "=== Sources/Feature/FileA.swift (1-200) ==="
  nl -ba -s'|' Sources/Feature/FileA.swift | sed -n '1,200p'
  echo
  echo "=== Sources/Feature/ModuleB.swift (120-280) ==="
  nl -ba -s'|' Sources/Feature/ModuleB.swift | sed -n '120,280p'
  echo
  echo "=== Tests/ModuleBTests.swift (1-180) ==="
  nl -ba -s'|' Tests/ModuleBTests.swift | sed -n '1,180p'
} | toClip
~~~
- Adjust ranges to cover full functions/sections or ±100–200 lines when unsure.
- Batch all needed peeks into one block so the operator runs a single command.
- Never guess bytes—peek first; then patch with hunks in descending line order per file.

### Tabs: mostly a non-issue if you use `nl -ba -s'|'` (still avoid in patches)
- Default `nl -ba` uses a TAB between the line number and file content; `-s'|'` replaces it with a visible `|`.
- So: prefer `nl -ba -s'|'` in peeks, and avoid introducing TABs into patches by copying peek formatting.
- `applyPatch` rejects TABs by default as a guardrail; override only if you explicitly intend tabs.
### The loop
1) Assistant requests peek of places it will be patching. Peeks are directly executable shell command blocks.
- It's better to reject patches without a peek first and create a cadence which usually works with fewer stumbles.
2) Paste peek request into shell, review for sanity/safety, then hit Return to load the clipboard. Paste directly to assistant verbatim.
- Typical bundle requested by the assistant:
~~~bash
{
  echo "=== Sources/Widget.swift (1-140) ==="
  nl -ba -s'|' Sources/Widget.swift | sed -n '1,140p'
  echo
  echo "=== Sources/Utils/Tools.swift (60-120) ==="
  nl -ba -s'|' Sources/Utils/Tools.swift | sed -n '60,120p'
  echo
  echo "=== Tests/WidgetTests.swift (1-200) ==="
  nl -ba -s'|' Tests/WidgetTests.swift | sed -n '1,200p'
} | toClip
~~~
3) Assistant prepares and returns a fenced code block with its patch.
- Multi-file patches are OK only if we just peeked all touched files in one request. Otherwise, send a single-file patch and iterate.
   - Hunks must be listed in descending line order per file (bottom-to-top) to minimize offset churn during apply.
   - New files use --- /dev/null and +++ b/path; include the full file body in one hunk.
4) Copy the returned patch, and apply it directly from the clipboard (applyPatch reads from the clipboard by default):
~~~bash
applyPatch
~~~
5) Build/test and send short logs:
- As early as step two, errors can occur. When they do, just paste the error to the assistant and the loop restarts.
- Just getting to the point where there are no compile errors and testing can be done can be challenging.
- Ask the assistant to help you create a short, project-specific alias or script that runs your build or tests and copies the last part of the logs to the clipboard. For example, for an Xcode project:
~~~bash
test='(xcodebuild -scheme VoiceLogin -destination '\''platform=iOS Simulator,name=iPhone SE (3rd generation)'\'' test) 2>&1 | tee >(tail -n 100 | toClip)'
~~~
For other stacks (npm, gradle, cargo, etc.), design similar aliases with the assistant.
Adjust scheme/destination names as you like; this is just an example.
6) Repeat until goal has been reached. After any patch lands, the assistant re-peeks before drafting the next one.
7) Commit changes to preserve progress as appropriate. Assistant can help, making this a copy/paste hit Return operation.
8) Choose something to fix next.

When chat lags: handoff to a fresh instance
- If latency or confusion grows, start a new chat session.
- From this repo, run sharefiles and paste the snapshot.
- From the project repo, run sharefiles and paste the snapshot.
- Ask assistant to create a brief handoff summary for its successor:
  - Current goal and scope.
  - What's done vs. outstanding.
  - The latest errors/test failures or build status.
  - The exact next step you want, if known.
- Paste the handoff summary, and give any other directions you may want.
- Resume the loop: Peek → Patch → Apply → Test.

Why auto-fix counts?
- Models often miscount @@ lengths (oldLen/newLen). We always repair them, so small count errors don't derail progress.
- We tried and failed to get GPT to calculate them correctly, so chose to just let the auto-correct fix it.

Unified diff in brief (what Assistant will create and paste back)
- One block that ends with a newline. For each file:
  - --- a/path/to/file
  - +++ b/path/to/file
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Lines: space = context, - = deletion, + = addition (LF endings)

Replace one line (example)
~~~diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,3 +42,3 @@
    let x = foo()
-   let y = oldCall(x)
+   let y = newCall(x)
    return y
~~~

Insert one line (example, characteristically with a bad count)
~~~diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,2 +99,3 @@
    vm.refresh()
+   vm.bootstrapIfNeeded()
~~~

Patch expectations
- Pure unified diff in one fenced block:
  - --- a/path and +++ b/path
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Lines start with space (context), - (deletion), + (addition)
  - LF endings; final newline
- New files: --- /dev/null and +++ b/path with @@ -0,0 +N,N @@

