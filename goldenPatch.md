Title: The Golden Key — Producing Git Patches That Apply Cleanly (for AIs)

Audience
- Humans: quick context on why this matters.
- AI collaborator: everything else. Follow it exactly.

Why humans care (short)
- Patch failures waste time and trust. They’re usually caused by tiny issues: wrong hunk-length counts, context that doesn’t match file bytes, stray lines in the diff, or a missing final newline. This guide makes you emit byte‑perfect unified diffs that git apply accepts on the first try.

Protocol for AIs (do these in order)

1) Always anchor on a fresh peek of the exact bytes you will touch
- Request a numbered, byte‑faithful slice of the target file before drafting a diff, for example:
```sh
nl -ba path/to/File.swift | sed -n 'START,ENDp'
```
- Use only what appears in the peek for your context lines. If you need more surrounding text, ask for a wider peek first.

2) Output a pure unified diff, and nothing else
- Structure (and only this):
  - File headers:
    - --- a/path/to/file
    - +++ b/path/to/file
  - One or more hunks, each starting with:
    - @@ -oldStart,oldLen +newStart,newLen @@
  - Hunk body lines, each starting with exactly one of:
    - space ( ) = context
    - minus (-) = deletion
    - plus  (+) = addition
- Do not embed scripts, heredocs, or commentary inside the patch you intend the user to save. In chat, you may wrap the entire patch in one code block for copy/paste.

3) Strict formatting rules
- Line endings: LF only.
- Every line in the hunk body must begin with space/+/-. No blank, unprefixed lines inside or between hunks.
- End the entire patch with a final newline (the very last byte must be \n).
- Keep changes minimal: use the smallest feasible hunks; avoid mixing unrelated edits.

4) Compute hunk header counts correctly (most common failure)
- Header syntax: @@ -oldStart,oldLen +newStart,newLen @@
- Count only lines inside the hunk body and by their prefixes:
  - Context (space): counts toward both oldLen and newLen.
  - Deletion (-): counts only toward oldLen.
  - Addition (+): counts only toward newLen.
- You do not need to “nail” the start line numbers if your context bytes match; git will locate the hunk using context. But your lengths must match the body.

5) Byte‑true context only
- Copy context lines exactly as seen in the peek. Do not alter whitespace or punctuation.
- Do not “escape” characters in context (e.g., do not change " to \"). Use the literal bytes shown.
- Tabs vs spaces must match exactly.

6) Multiple edits
- Prefer multiple focused patches, one concern per patch. If you combine changes, each hunk must independently follow the rules above and use context from the peeks you were given.

7) After any prior patch, re‑peek before crafting the next
- Patches change line layout. Always request fresh peeks for subsequent diffs.

Diagnosing git apply errors quickly
- error: patch fragment without header: a previous hunk’s header counts didn’t match its body, or you included a stray unprefixed/blank line, so the parser desynchronized. Recount C/D/A; ensure every body line starts with space/+/-, and there are no blank separators.
- error: patch does not apply: context mismatch. You used stale peek bytes, escaped characters, or whitespace drifted. Re‑peek and re‑anchor.
- corrupt at EOF: you forgot the final newline at the end of the entire patch.

How to count C/D/A (with small examples)

Single-line replacement (one line replaced, with surrounding context):
- Body prefixes (example): space, -, +, space, space
- Counts: C=3, D=1, A=1 → oldLen=C+D=4, newLen=C+ATalking: 4
Patch:
```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,4 +42,4 @@
     let x = foo()
-    let y = oldCall(x)
+    let y = newCall(x)
     return y
 }
```

Single-line insertion (insert one line between two context lines):
- Body prefixes: space, +, space
- Counts: C=2, D=0, A=1 → oldLen=2, newLen=3
Patch:
```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,2 +99,3 @@
     vm.refresh()
+    vm.bootstrapIfNeeded()
```

Single-line deletion (remove one line between two context lines):
- Body prefixes: space, -, space
- Counts: C=2, D=1, A=0 → oldLen=3, newLen=2
Patch:
```diff
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -120,3 +120,2 @@
-    deprecatedCall()
     nextCall()
```

Request template you should send before generating a patch
- Ask the human to provide a peek you will anchor on:
```text
Please run and paste:

nl -ba PATH/TO/FILE | sed -n 'START,ENDp'

Then I will return a single, pure unified diff (one code block), ending with a newline, using only those bytes as context.
```

Emission checklist (what you verify before sending)
- Context lines are copied verbatim from the latest peek.
- Count C, D, A for each hunk. Set oldLen=C+D and newLen=C+A. Double‑check arithmetic.
- No unprefixed/blank lines in any hunk body; LF endings only.
- The diff ends with a newline.
- You output only the diff in one code block (no extra text inside the block).

macOS clipboard workflow (pbcopy/pbpaste)

- For peeks, prefer blocks that end with | pbcopy so the result goes straight to the clipboard. Example:
```sh
{ 
  echo "=== Widget.swift (120–150) ==="
  nl -ba Sources/Widget.swift | sed -n '120,150p'
} | pbcopy
```

- For patches, return the patch as one code block. The human copies the block, then writes it to a file via pbpaste (no heredocs needed):
```sh
pbpaste > patchA.diff
git apply --check -v patchA.diff && git apply patchA.diff
```

- Multiple patches at once (no heredocs, splitter from clipboard). You provide a “Patches” block with clear markers, then this splitter turns the clipboard into files:
Split-run command:
```sh
# After copying the “Patches” block, run:
pbpaste | awk '
  /^=== patchA\.diff ===$/ {f="patchA.diff"; next}
  /^=== patchB\.diff ===$/ {f="patchB.diff"; next}
  f {print > f}
'
git apply --check -v patchA.diff && git apply patchA.diff
git apply --check -v patchB.diff && git apply patchB.diff
```

Example “Patches” block the AI can emit (one block, two diffs, each complete)
```text
=== patchA.diff ===
--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,4 +42,4 @@
     let x = foo()
-    let y = oldCall(x)
+    let y = newCall(x)
     return y
 }
=== patchB.diff ===
--- a/Sources/Bar.swift
+++ b/Sources/Bar.swift
@@ -10,2 +10,3 @@
     vm.refresh()
+    vm.bootstrapIfNeeded()
```

Why this recipe matters
- Git’s patch parser is strict but predictable. If you always:
  - anchor to bytes you just saw,
  - keep hunks minimal,
  - compute header counts from C/D/A exactly,
  - and end with a final newline,
then your diffs apply cleanly. Deviating (guessing context, escaping characters, mixing whitespace, missing the last newline) is what causes the classic failures.

Golden rules (repeat to yourself)
- Fresh peek, byte‑true context, minimal hunks.
- Count C/D/A → oldLen/newLen, don’t guess.
- Every hunk line starts with space/+/-, no blank separators.
- LF endings only. Final newline at end of the entire patch.
- Output only the patch inside one code block.
