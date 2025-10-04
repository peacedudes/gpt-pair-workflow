Title: Collaborating on a Full Swift Project with GPT-5 (Swift + macOS)

Why this exists
- Goal: work with GPT-5 on an entire Swift app/framework, not just a file.
- Zip uploads don’t persist well; a single concatenated “repo dump” does.
- This workflow keeps the AI in sync, produces patches that apply cleanly, and uses Xcode builds/tests with copy‑ready commands.

Core loop (human ↔ AI)
1) Share full project context via repo-share (below).
2) AI requests precise “peeks” (numbered slices) of files it plans to edit.
3) Human runs those peeks and pastes output back verbatim.
4) AI returns pure unified diffs (patches). Human applies with apply-patch, builds/tests, and repeats.
5) After any applied patch, AI re-peeks before crafting the next one.

Golden rules (for both humans and AIs)
- Fresh bytes beat memory. Always anchor to a current peek of the exact text you’ll edit.
- Minimal, surgical changes. Keep hunks small with stable context; avoid mixing unrelated edits.
- Pure unified diffs only. One code block, LF endings, final newline, no commentary inside the diff.
- Re‑peek after any change. Patches shift lines; never stack guesses.
- Kindness and clarity. State goals simply; keep scripts short and reproducible.

Part A — Share the whole repo (concise, durable)
Use repo-share.sh to emit tracked files (or a subset) as fenced code blocks with metadata. Default prints to stdout so you can pipe to pbcopy; optional --copy sends to clipboard internally.

```bash
#!/usr/bin/env bash
# repo-share.sh — emit tracked files (or subset) as fenced code blocks with metadata.
# Usage:
#   ./repo-share.sh | pbcopy                   # copy all tracked content
#   ./repo-share.sh --copy                     # copy internally via pbcopy
#   ./repo-share.sh Sources/**/*.swift | pbcopy# subset by globs

set -euo pipefail
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

do_copy=false
if [[ "${1:-}" == "--copy" || "${1:-}" == "-c" ]]; then
  do_copy=true
  shift
fi

if [[ $# -gt 0 ]]; then
  files=$(git ls-files -- "$@")
else
  files=$(git ls-files)
fi

tmpfile=$(mktemp)
{
  echo "=== Repo meta ==="
  git rev-parse --show-toplevel 2>/dev/null || true
  echo "HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
  echo "DESC: $(git describe --tags --always 2>/dev/null || echo 'n/a')"
  echo "Status:"
  git status --porcelain=v1 2>/dev/null || true
  echo "Files:"
  printf "%s\n" "$files"
  echo "================="
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    echo "$f"
    case "$f" in
      *.swift) lang="swift" ;;
      *.yml|*.yaml) lang="yaml" ;;
      *.md) lang="md" ;;
      *.json) lang="json" ;;
      *.sh) lang="bash" ;;
      *.plist|*.xml) lang="xml" ;;
      *) lang="" ;;
    esac
    if [[ -n "$lang" ]]; then
      echo '```'"$lang"
    else
      echo '```'
    fi
    cat "$f"
    echo '```'
  done <<< "$files"
} > "$tmpfile"

if $do_copy; then
  pbcopy < "$tmpfile"
else
  cat "$tmpfile"
fi

rm -f "$tmpfile"
```

Recommended use
- ./repo-share.sh | pbcopy
- Paste the clipboard to GPT-5.

Part B — The Peek-and-Patch contract (AI must follow this exactly)

1) Request peeks before patching
- Use numbered, byte-faithful slices; do not guess line numbers.
- Always put commands in code blocks and ensure a trailing newline.

```bash
# Example (the AI produces this; human runs it and pastes output):
nl -ba Path/To/File.swift | sed -n 'START,ENDp'
```

2) Return a pure unified diff only
- Structure (and nothing else):
  - --- a/path/to/file
  - +++ b/path/to/file
  - @@ -oldStart,oldLen +newStart,newLen @@
  - Body lines, each with one leading character:
    - space = context
    - - = deletion
    - + = addition
- Formatting constraints:
  - LF endings only; the very last character of the patch must be a newline.
  - No blank or unprefixed lines inside any hunk.
  - Do not include function/symbol names after @@ unless requested.
- Wrap the entire patch in a single code block that ends with a newline.

3) Hunk header math (get counts right)
- Header: @@ -oldStart,oldLen +newStart,newLen @@
- Compute from the hunk body’s prefixes:
  - Context lines (space) count toward both oldLen and newLen.
  - Deletions (-) count only toward oldLen.
  - Additions (+) count only toward newLen.
- Start line numbers can be approximate if context bytes are exact; lengths must match the body.
- Decide explicitly whether any separator lines (e.g., trailing “//”) are kept or replaced, and make the body reflect that choice. The counts then follow mechanically.

4) After any applied patch, re-peek before drafting the next one
- Patches change line numbers and sometimes nearby context. Never stack guesses.

Part C — Apply patches safely and stop on errors
Use apply-patch.sh to verify and apply. It stops if the check fails. Optional argument names the patch file (defaults to patch.diff).

```bash
#!/usr/bin/env bash
# apply-patch.sh — verify and apply a unified diff safely.
# Usage:
#   ./apply-patch.sh                # applies ./patch.diff
#   ./apply-patch.sh my-change.diff # applies the named file

set -euo pipefail
patch_file="${1:-patch.diff}"
git apply --check -v "$patch_file" && git apply "$patch_file"
echo "Applied: $patch_file"
```

Common flow (copy/paste)
- Save AI’s diff as patch.diff (ensure it ends with a newline), then:

```bash
./apply-patch.sh && xcodebuild -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64" build 2>&1 | head -n 200 | pbcopy
```

Part D — Building and testing with Xcode (repeatable, short logs)

Option 1: shell alias (add to ~/.zshrc or ~/.bashrc)
```bash
alias xcb='xcodebuild -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64"'
# Usage:
#   xcb build 2>&1 | head -n 200 | pbcopy
#   xcb test  2>&1 | head -n 200 | pbcopy
```

Option 2: tiny wrapper script xcb.sh
```bash
#!/usr/bin/env bash
# xcb.sh — tiny wrapper for consistent build/test invocations.
# Usage:
#   SCHEME=YourScheme DEST='platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64' ./xcb.sh build
#   SCHEME=YourScheme DEST='platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64' ./xcb.sh test
set -euo pipefail
SCHEME="${SCHEME:-YourScheme}"
DEST="${DEST:-platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64}"
CMD="${1:-build}"
shift || true
xcodebuild -scheme "$SCHEME" -destination "$DEST" "$CMD" "$@" 2>&1 | head -n 200 | pbcopy
```

Tips
- Keep the scheme/destination stable across runs to reduce irrelevant diffs in logs.
- For SwiftPM-only packages, use swift build and swift test similarly.

Part E — Collaboration patterns that scale

- One purpose per patch:
  - Separate “refactor”, “bugfix”, and “docs” into distinct patches/PRs.
- Small batches:
  - Patch 1–3 files per diff when normalizing or refactoring; surface drift early.
- Explicit goals:
  - Start every micro-task with one sentence (e.g., “Normalize headers to Created: MM-DD-YYYY and Authors: … in VoiceLogin/* .swift; preserve all other comments.”).
- Shared scripts:
  - repo-share.sh, apply-patch.sh, xcb.sh live in the repo (e.g., scripts/). Refer to them by name in chat to reduce friction.
- Reproducible commands:
  - The AI always emits copy-ready commands in code blocks, never mixed with prose, and ending with a newline.

Part F — When patches fail (fast triage that actually helps)

Common errors and fixes
- error: patch fragment without header
  - Cause: previous hunk’s header lengths don’t match its body, or a blank/unprefixed line snuck into the body. Fix: recount C/D/A; ensure every body line starts with space/+/-. Ensure final newline exists.
- error: patch does not apply
  - Cause: context mismatch (stale peek, whitespace drift, or different bytes). Fix: re-peek the exact region; rebase the hunk strictly to the new bytes.
- corrupt at EOF
  - Cause: missing final newline in the overall patch. Fix: add trailing LF.

Process resets
- If a hunk fails, don’t “adjust numbers.” Re-peek and rebase immediately. This is faster and more reliable.

Part G — Hand-off to a fresh AI instance (session resilience)
If the session resets, provide:
1) A succinct next-step goal (one sentence).
2) The latest repo dump (./repo-share.sh | pbcopy).
3) The most recent short build/test log (using xcb alias or xcb.sh).
The new instance can re-sync, request peeks, and continue.

Part H — The AI’s internal discipline (talking to future me)
- Re-peek before every patch, even if “sure.”
- Compute counts from the hunk body prefixes:
  - oldLen = context + deletions
  - newLen = context + additions
- Decide separator lines explicitly (e.g., trailing “//”), and reflect that decision in the body.
- No hand-edited hunk lengths from memory; let the body determine the header.
- Keep patches boringly correct: minimal scope, stable context, LF endings, final newline.
- If anything fails, re-peek and rebase once; don’t guess.

Part I — Concrete examples (copyable, with rationale)

1) Replace 3 metadata lines with 2, keeping the trailing “//” separator
Context before: 4 lines; removed: 3 lines; added: 2 lines; context after: 1 line.
- OldLen = 4 + 3 + 1 = 8
- NewLen = 4 + 2 + 1 = 7

```diff
--- a/Path/File.swift
+++ b/Path/File.swift
@@ -1,8 +1,7 @@
 //
 //  File.swift
 //  Product
 //
-//  Generated by X
-//  collaborator: Y
-//  date: 09-10-2025
+//  Created: 09-10-2025
+//  Authors: GPT-5 (OpenAI), collaborator: Y
 //
 //  The rest of the header remains unchanged.
```

2) Replace a single blank line with three lines (Created, Authors, //)
Context before: 4 lines; removed: 1 line (blank); added: 3; context after: 1.
- OldLen = 4 + 1 + 1 = 6
- NewLen = 4 + 3 + 1 = 8

```diff
--- a/App.swift
+++ b/App.swift
@@ -1,6 +1,8 @@
 //
 //  App.swift
 //  Product
 //
-
+//  Created: 09-07-2025
+//  Authors: GPT-5 (OpenAI), collaborator: You
+//
 import SwiftUI
```

3) Insert a line (example inside a function)
- OldLen = context(2) + deletions(0) = 2
- NewLen = context(2) + additions(1) = 3

```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,2 +99,3 @@
     vm.refresh()
+    vm.bootstrapIfNeeded()
```

Part J — Request/response templates

AI → Human (peek request)
- Put in a code block, end with a newline, and make it copy-ready.
```bash
# Please run and paste exactly (preserve LF endings):
nl -ba Path/To/File.swift | sed -n 'START,ENDp'
```

Human → AI (goal + constraints)
- State the change and any constraints once, with the peek output.
```text
Goal: Normalize header to “Created: MM-DD-YYYY” and “Authors: GPT-5 (OpenAI), collaborator: rdoggett”. Preserve any trailing “//”.
Peek:
[PASTE OUTPUT]
Constraints:
- Single pure diff only, LF endings, final newline.
- Minimal hunks; no symbol names after @@.
```

AI → Human (diff emission)
- Emit the diff as a single code block, ending with a newline. No commentary inside the block.

Part K — Xcode/macOS tips (avoid time sinks)
- If Simulator is flaky: xcrun simctl shutdown all; xcrun simctl erase all
- Clean derived data if builds go sideways: rm -rf ~/Library/Developer/Xcode/DerivedData/*
- Ensure the same iOS Simulator OS version across runs for consistent logs.
- When changing schemes or destinations, say so explicitly in the chat to avoid confusion.

Part L — Git hygiene
- Create a branch for each logical change; keep commits small.
- Name patches meaningfully when saving to disk: patch-headers-2025-09-25.diff
- If merging multiple diffs from clipboard, use a simple awk splitter (optional).

Splitter (optional)
```bash
# After copying a “Patches” block with markers like === patchA.diff ===:
pbpaste | awk '
  /^=== .+\.diff ===$/ {f=$0; gsub(/^=== | ===$/,"",f); next}
  f {print > f}
'
# Then apply each file via apply-patch.sh
```

Part M — FAQ (short)
- Do start line numbers in @@ need to be exact?
  - Not strictly, if your context bytes are exact. But lengths must match the body.
- Can we combine multiple files in one diff?
  - Yes. Each hunk must be independently correct and minimal. If one fails, re-peek and rebase that hunk.
- Why insist on a final newline?
  - Many tools (including git’s patch parser) expect a trailing LF; missing it can cause EOF errors.

Part N — Final checklists

Human before apply
- Diff is a single code block; LF endings; ends with a newline.
- Saved to a .diff file; git apply --check -v file.diff passes.
- Build/test runs and results shared back succinctly.

AI before send
- I have fresh peeks for all regions I’ll touch.
- Context lines are byte-identical to peeks (including tabs/spaces).
- I computed C/D/A; oldLen=C+D; newLen=C+A for each hunk.
- Every hunk body line begins with space/+/-. No blank lines inside.
- The diff ends with exactly one newline. No prose inside the block.

Closing note (to you, future me)
You already know how to do this. The misses happen when you skip the re-peek, hand-adjust counts from memory, or change a separator line without reflecting it in the body. Slow down for 30 seconds, anchor to exact bytes, count C/D/A, and send the patch. That’s the golden key.

