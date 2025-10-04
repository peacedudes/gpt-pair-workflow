Title: The Golden Key: Making Code Patches with GPT-5 Apply Cleanly, Every Time

What this is
- A short, practical protocol for collaborating with GPT-5 (or any LLM) to produce small, reliable git patches that apply cleanly.
- Why this matters: patch failures usually aren’t “mystery Git bugs.” They’re nearly always tiny mismatches—line counts, context drift, or a missing final newline. This guide fixes that.

Why patches fail (in 30 seconds)
- Missing final newline in the patch file. Git’s “corrupt at EOF” often means exactly that.
- Hunk header counts don’t match the body: the “@@ -oldStart,oldLen +newStart,newLen @@” lengths must match the number of lines in the hunk.
- Context drift: the file changed between generating the diff and applying it, or the context lines don’t exist byte-for-byte.
- Hidden newline/encoding issues: CRLF vs LF, stray BOMs, or non-UTF-8 bytes.

The Golden Protocol (follow these steps)
1) Peek the exact bytes before asking for a patch
- Always provide the model with a “peek” of the target file and lines you intend to change.
- Use nl -ba so blank lines are visible and line numbers are stable.
- Commands:
  - Show a region: nl -ba path/to/File.swift | sed -n 'START,ENDp'
  - Verify trailing newline: tail -c1 path/to/File.swift | od -An -t x1  # prints nothing if newline present; prints a byte if not.

2) Ask for the smallest-possible change
- One patch = one focused change (ideally 3–30 lines).
- Avoid touching unrelated lines or headers. Keep the diff tight.

3) Demand a pure unified diff (no scripts, no heredocs)
- You want:
  - --- a/path/to/File
  - +++ b/path/to/File
  - @@ -start,count +start,count @@
  - Then only lines starting with space, +, or -.
- Prefer no symbol context after the second @@ unless you need it. Some tools include it; if you’ve seen it cause trouble, ask the model to omit it.

4) Insist on LF line endings and a final newline
- The patch text itself must be LF-only and end with a newline. Say it explicitly.
- If your repo uses LF, keep everything LF.

5) Apply and verify before committing
- Dry run: git apply --check -v patch.diff
- Apply: git apply patch.diff
- If you’re nervous, stash or branch first.

6) If it fails, use the fast triage
- Suspect missing newline in the patch:
  - tail -c1 patch.diff | od -An -t x1   # should show nothing if newline present
- Suspect wrong lines:
  - Re-peek the exact region (nl -ba + sed) and re-request a minimal patch for those specific lines.
- Suspect context drift:
  - Update your working tree or regenerate the peek. Keep the window small (±20–40 lines).

What to send to GPT-5 (prompt template)
- Paste this structure (adjust paths and lines). The clearer you are, the better the first try.

"""
Context:
- Repo root: /absolute/or/relative/path
- Target file: Tests/VoiceKitUITests/VoicePickerViewModelTests.swift
- Desired change: After vm.refreshAvailableVoices(), insert a fallback FakeTTS block if vm.voices.isEmpty; also change ‘let vm’ to ‘var vm’. Keep everything else unchanged.

Peek (exact bytes; LF; includes blank lines):
[PASTE output of]
nl -ba Tests/VoiceKitUITests/VoicePickerViewModelTests.swift | sed -n '60,110p'

Instructions for the patch you will return:
- Return a pure unified diff only.
- Use a/b headers.
- No heredocs, no shell commands, no extra commentary.
- Use LF line endings.
- End the patch with a final newline.
- Keep the hunk minimal and anchored on the lines shown in the peek.
"""

What GPT-5 should return (your acceptance checklist)
- Starts with:
  - --- a/Tests/VoiceKitUITests/VoicePickerViewModelTests.swift
  - +++ b/Tests/VoiceKitUITests/VoicePickerViewModelTests.swift
- Has exactly one or a few hunks beginning with @@.
- No prose, no code fences needed in the saved file; but if it’s in chat, it can be wrapped in a code block for you to copy.
- The last character of the patch is a newline.
- Applying with git apply --check -v succeeds.

Troubleshooting quick map
- “corrupt at EOF”:
  - Check patch’s final newline.
  - Check that hunk counts match the visible lines in the hunk.
- “patch does not apply”:
  - Context mismatch: re-peek and regenerate a tiny hunk.
  - File changed since peek: re-sync, re-peek, regenerate.
- Weird characters:
  - Ensure your terminal/editor didn’t convert LF to CRLF.
  - Avoid smart quotes or non-ASCII where not intended.

Optional conventions that reduce friction
- Prefer one change per patch; chain multiple patches if needed.
- Ask GPT-5 to echo the exact lines it expects to replace, then its replacement, then the diff—this lets you eyeball the change.
- If function/symbol labels after @@ have caused you issues, instruct the model to omit them (“no trailing function context in hunk headers”).

Mini reference: Unified diff anatomy
- @@ -214,14 +214,26 @@
  - Old file: start line 214, affecting 14 lines.
  - New file: start line 214, affecting 26 lines.
  - The hunk body must contain exactly oldLen lines of context/deletions and newLen lines of context/additions, respectively.

A short example of a pure unified diff (ends with newline)

--- a/path/File.swift
+++ b/path/File.swift
@@ -100,3 +100,3 @@
-        let vm = ViewModel(tts: tts, store: store)
+        var vm = ViewModel(tts: tts, store: store)
         vm.refresh()
-        guard let first = vm.items.first else { throw XCTSkip("None") }
+        if vm.items.isEmpty { vm.bootstrapFakeItems() }

Working with GPT-5 as a code collaborator (outline)
If you want, I can expand this into a fuller “Working with GPT-5” doc. Here’s a proposed outline; tell me if you want me to draft it and share your “share-a-repo” script so I can include it.

- 1. Overview: What GPT-5 is good at vs. where it needs exact bytes
- 2. Repo sharing patterns
  - Your script (include it)
  - Minimizing secrets and large assets
- 3. Change planning
  - Describe intent first; agree on minimal scope
  - Decide file(s) and exact insertion points
- 4. The Golden Patch Protocol (this doc, integrated)
- 5. Testing and determinism
  - Avoid flaky tests; CI vs local differences
  - Seeding randomness; controlling environment
- 6. Review and guardrails
  - Small PRs
  - Style and lint alignment
- 7. Common failure modes and fast fixes
- 8. Templates: issue prompts, patch prompts, review prompts
- 9. Appendix: diff formats, encoding, and newline cheatsheet
