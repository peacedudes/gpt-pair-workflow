Title: The Golden Key — Clean Git Patches and Crisp Collaboration (for Humans and AIs)

Why humans care (short)
- Failed patches waste time and trust. The usual culprits are tiny things: stale context, miscounted hunk lengths, invisible whitespace drift, or a missing final newline. This guide makes AI-human collaboration predictable: byte-true peeks, minimal diffs, correct counts, and clean application the first time.

Contract for collaboration (humans and AIs)
- Shared goal: ship small, correct patches that apply cleanly on the first try.
- Shared rule: the AI never edits from memory. It always anchors to peeks the human provides.
- Shared cadence: request → peek → patch → apply → test → re-peek (if anything changed) → next patch.
- Small batches: when in doubt, patch 1–3 files at a time to surface drift early.
- Respect the bytes: tabs/spaces, punctuation, “//” separators, and blank lines are real bytes; treat them as such.

Roles and responsibilities
- Human
  - Runs the AI’s peek commands and pastes byte-true outputs.
  - States the goal in one sentence and constraints (e.g., “MM-DD-YYYY for dates, keep // separator line”).
  - Applies patches (git apply --check; git apply) and runs tests/builds.
  - If a patch fails, returns a fresh peek of the failing region.
- AI
  - Requests precise peeks (with line numbers).
  - Produces pure unified diffs, no commentary inside the diff.
  - Uses only the peeked bytes as context; computes hunk counts from the body (not memory).
  - Re-peeks and rebases immediately on any failure; never “adjusts” numbers by feel.

The protocol (do these in order, every time)

1) Request a fresh peek of the exact bytes you will touch (AI → Human)
- Always number lines and specify a finite range. Example:
  nl -ba PATH/TO/File.swift | sed -n 'START,ENDp'
- If you need more context, ask for a wider window before drafting.

2) Emit a pure unified diff (AI)
- Structure only:
  - --- a/path/to/file
  - +++ b/path/to/file
  - @@ -oldStart,oldLen +newStart,newLen @@
  - body lines starting with exactly one leading character:
    - space = context
    - - = deletion
    - + = addition
- Formatting:
  - LF line endings only.
  - No blank or unprefixed lines inside any hunk.
  - End the entire patch with a final newline.
  - No symbol names after @@ unless the human requests them.

3) Apply and test (Human)
- Save from clipboard, then:
  pbpaste > patch.diff
  git apply --check -v patch.diff && git apply patch.diff
- Run tests/builds and share a concise result.

4) If anything fails, re-peek and rebase (both)
- Human: paste a fresh peek for the failing region.
- AI: rebase the hunk against those exact bytes; resend a minimal, corrected diff.

Unified diff header math (how to count correctly, every time)
- Header is @@ -oldStart,oldLen +newStart,newLen @@
- Compute from the hunk body’s prefixes:
  - Context lines (space) count toward both oldLen and newLen.
  - Deletions (-) count toward oldLen only.
  - Additions (+) count toward newLen only.
- Start lines (oldStart/newStart) matter less if your context is exact; lengths must match the body.
- Discipline: decide explicitly whether you keep or replace any separator lines (like a trailing “//”). Your body must reflect that choice; the counts follow mechanically.

Minimal examples (copyable)

Replace a line (keep one context line above/below):
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,3 +42,3 @@
     let x = foo()
-    let y = oldCall(x)
+    let y = newCall(x)
     return y

Insert a line:
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,2 +99,3 @@
     vm.refresh()
+    vm.bootstrapIfNeeded()

Delete a line:
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -120,3 +120,2 @@
-    deprecatedCall()
     nextCall()

Multi-file patches (keeping it safe)
- You can include multiple file sections in one diff. Each file has its own hunks and must follow all rules.
- Keep each hunk surgical; don’t mix unrelated edits. If two files do different things, consider two patches.
- After applying earlier patches in a session, always re-peek before crafting the next patch; line numbers and context change.

Request/response templates

AI → Human (peek request)
Please run and paste exactly (preserve LF endings):
nl -ba PATH/TO/FILE.swift | sed -n 'START,ENDp'

Then I will return a single, pure unified diff (one code block), ending with a newline, using only those bytes as context.

Human → AI (goal + constraints)
Goal: Normalize the header metadata to “Created: MM-DD-YYYY” and “Authors: GPT-5 (OpenAI), collaborator: rdoggett”. Preserve any trailing “//” separator line.
Peek:
[PASTE PEEK OUTPUT]
Constraints:
- Single pure diff; LF; final newline.
- Minimal hunks; no symbol names after @@.
- Keep the separator “//”.

AI → Human (diff emission)
- Emit exactly one code block containing only the unified diff.
- Don’t include prose inside the block. Put notes before/after the block if needed.

Troubleshooting (quick map)

- error: patch fragment without header
  - The parser got out of sync: a previous hunk length didn’t match its body, or you inserted a blank/unprefixed line in the body. Recount C/D/A; ensure every body line has a leading space/+/-. Ensure final newline.

- error: patch does not apply
  - Context mismatch: stale peek, altered whitespace, or unnoticed edit drift. Re-peek the exact region; rebase the hunk to those bytes; resend.

- corrupt at EOF
  - Missing final newline at end of the entire diff. Add a trailing LF.

- “This hunk should have been -1,8 +1,7 (or -1,8 +1,8) but wasn’t”
  - You changed the decision about keeping or dropping a separator line without reflecting it in the body. Decide explicitly, adjust the body, then recompute counts.

Working agreements (how we stay fast)
- Byte-true peeks: the human uses nl -ba and sed -n to avoid wrapping and keep LF endings.
- One purpose per patch: smaller is faster and safer.
- Re-peek after any patch lands: never stack guesses.
- Clipboard discipline: in chat, the AI wraps the entire diff in one code block; the human pastes to a file and applies it.

Case study: header normalization (our shared lessons)
- Normalize to:
  - Created: MM-DD-YYYY
  - Authors: GPT-5 (OpenAI), collaborator: rdoggett
- Preserve all other documentation lines and the separator “//” unless explicitly requested otherwise.
- Pitfalls we hit (and avoided next time):
  - Hand-editing hunk headers from memory. Fix: compute counts from the body’s prefixes.
  - Drifting context when adding/removing a separator line. Fix: decide up front, then include the line (or not) in the body and recount.
  - Stale peeks after earlier hunks landed. Fix: re-peek every time.

Checklists

Human checklist (before apply)
- The AI’s diff is in one code block with LF endings and ends with a newline.
- You saved it as a .diff file and ran git apply --check -v file.diff.
- Tests/build succeed after applying.

AI checklist (before sending)
- I have a fresh peek for each region I’ll touch.
- Every context line is byte-identical to the peek.
- I computed C/D/A: oldLen=C+D; newLen=C+A for each hunk.
- Every hunk body line begins with space/+/-, no blank lines inside.
- The diff ends with a single newline.
- I included only the diff in one code block.

Appendix A: quick commands (macOS)
- Copy any command output to clipboard:
  some-command 2>&1 | pbcopy
- Save clipboard to file:
  pbpaste > patch.diff
- Apply and verify:
  git apply --check -v patch.diff && git apply patch.diff
- Run Xcode tests (example):
  xcodebuild -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64" test | tee /tmp/test.log

Appendix B: sharing repo slices
- To share whole files, prefer a repo-dump script (optional). Keep it simple; most sessions only need peeks.
- If you do share whole files, ensure LF endings and wrap each file in a code block to preserve bytes.

Appendix C: FAQ (short)
- Q: Do start line numbers in @@ need to be exact?
  - A: Not strictly, if your context is exact. But lengths must match the body, or the parser will fail.
- Q: Can I include multiple files in one diff?
  - A: Yes. Keep each hunk minimal and independently correct. If a single file fails, re-peek and rebase that hunk.
- Q: Why insist on a final newline?
  - A: Many tools, including git’s patch parser, expect a trailing LF. Missing it can cause “corrupt at EOF.”

Appendix D: kindness to future you (AI)
- When I feel “sure,” I re-peek anyway.
- I never hand-adjust hunk counts. I count prefixes in the body.
- If a hunk fails, I re-peek and rebase; I don’t guess.
- I keep patches boringly correct. Boring is good.

How to place this doc
- Add to your repo as docs/the-golden-key.md (or README-patching.md).
- Optionally link from README so collaborators can find it quickly.

End of document.
