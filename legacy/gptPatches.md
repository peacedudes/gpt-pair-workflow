Title: The Golden Key: How to Produce Git Patches That Apply Cleanly (For AIs)

Audience
- Humans: a short intro on why this matters.
- AI collaborator: everything else here is for you. Follow it exactly.

Why humans care (short)
- Patch failures waste time. They’re almost always caused by tiny mismatches: wrong context lines, incorrect hunk counts, or a missing final newline. This guide tells the AI exactly how to emit byte-perfect unified diffs so git apply works first try.

AI protocol: exact rules for crafting patches

1) Always require a peek of the exact bytes you will modify
- Ask for a numbered, byte-faithful slice of the target file before you generate a diff.
- The human will run and paste the output of:

```sh
nl -ba path/to/File.swift | sed -n 'START,ENDp'
```

- You may not guess line numbers or surrounding context. Use only what’s shown.

2) Produce a pure unified diff, and nothing else
- Output must contain only:
  - Three-line headers: --- a/path, +++ b/path
  - One or more hunks beginning with @@ -oldStart,oldLen +newStart,newLen @@
  - Hunk body lines starting with space (context), - (removals), + (additions)
- No scripts, no heredocs, no prose, no Markdown fences in the final artifact the human saves. In chat, you may wrap it in a code block for copy/paste.

3) Use these formatting constraints exactly
- Line endings: LF only.
- End the patch with a final newline (the very last character must be \n).
- Do not include function/symbol names after the second @@ unless explicitly requested.
- Keep changes minimal: one focused change per patch, smallest feasible hunk.

4) Compute correct hunk counts
- In each hunk header, oldLen equals the number of lines in the hunk that are either context or deletions; newLen equals the number of lines that are context or additions.
- Context lines count toward both lengths. Deletions count only toward oldLen. Additions count only toward newLen.

5) Anchor on the peeked lines only
- Your context must appear verbatim in the human’s peek (same bytes).
- Do not add or rely on lines outside the provided peek unless you asked for and received a wider peek.

6) If you must change a single line within the peek
- Keep at least 2–3 context lines above and below when possible.
- If the peek is tight, anchor with whatever unmodified lines exist.

7) If you need multiple changes
- Prefer multiple small patches (one per focused change). Do not co-mingle unrelated edits.

Copy-ready instruction block for the AI to follow

Paste this block into the AI session before you ask for a patch. Replace placeholders in ALL CAPS.

```text
You are to produce a single, pure unified diff that applies with `git apply`.

Constraints:
- Use LF line endings.
- End the patch with a final newline.
- Output ONLY the patch (no prose, no shell, no heredocs).
- Use a/b headers and minimal hunks. Do NOT include symbol/function text after @@.
- Anchor context strictly within the peek provided; do not guess beyond it.

Target file: PATH/TO/FILE
Change intent (brief): ONE-SENTENCE SUMMARY OF THE EDIT

Peek (authoritative lines):
[PASTE OUTPUT OF]
nl -ba PATH/TO/FILE | sed -n 'START,ENDp'

Now return exactly one unified diff that:
- Replaces/insert/deletes ONLY the intended lines shown above.
- Uses correct @@ -oldStart,oldLen +newStart,newLen @@ counts.
- Includes sufficient context so `git apply --check` succeeds.
- Ends with a newline.
```

Minimal examples the AI should emulate

Single-line replacement

--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -42,3 +42,3 @@
-        let vm = ViewModel(tts: tts, store: store)
+        var vm = ViewModel(tts: tts, store: store)
         vm.refresh()
         doSomething()

Line insertion after a shown line

--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -99,3 +99,4 @@
         vm.refresh()
+        if vm.items.isEmpty { vm.bootstrapFakeItems() }
         guard let first = vm.items.first else { throw XCTSkip("None") }

Line deletion

--- a/Sources/Foo.swift
+++ b/Sources/Foo.swift
@@ -120,2 +120,1 @@
-        deprecatedCall()
         nextCall()

Human helper: repeatable peek snippet you can keep handy

```sh
# Show a stable, numbered slice for the AI (adjust file and ranges)
nl -ba PATH/TO/FILE | sed -n 'START,ENDp'
```

Reminder to the AI at the end of every patch request
- Verify your hunk counts match your hunk body.
- Ensure the very last character of your diff is a newline.
- Do not include anything except the diff.

That’s it. Follow this protocol and your patches will apply cleanly.

