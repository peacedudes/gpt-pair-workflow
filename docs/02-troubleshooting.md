# Troubleshooting -- common bumps and quick fixes

This workflow is resilient, but a few issues come up regularly. Here's how to fix them fast.

Stop on error
- When anything fails (apply/build/test), stop. Re-peek a small, numbered slice of the exact target, then retry with a rebased patch.

Patch won't apply ("patch does not apply" / "while searching for")
- Cause: the diff was based on older bytes than your working copy (drift), or whitespace/formatting altered lines.
- Fix:
  1) Re-peek the exact file/range the hunk targets (the assistant will ask for a narrow slice).
  2) The assistant rebases and sends a fresh diff.
  3) Apply again.

Why descending diffs help
- List patch hunks in descending line order per file (bottom-to-top).
- This reduces mid-apply offset drift when earlier hunks change line numbers above later ones.
- It increases apply reliability without changing patch content or scope.
- If a patch still fails, re-peek a wider window and rebase precisely.

"corrupt patch at line N"
- Cause: malformed diff (missing fences, missing final newline, or mangled @@ headers).
- Fix:
  - Ensure you pasted a single fenced code block with unified diff only, ending in a newline.
  - Re-request the patch; applyPatch auto-fixes hunk counts but can't fix a broken structure.

Hunk length/count mismatches
- Symptom: applyPatch logs "fixDiffCounts: corrected hunk ...".
- Explanation: Expected and normal. Counts are recomputed automatically from the body.
- Action: None, unless patch still fails; then re-peek and retry as above.

No-op / “ghost” hunks
- Symptom:
  - git apply reports a “corrupt patch” even though the @@ header looks OK, or
  - a hunk shows only context lines (no + or - lines), so it appears to “touch” a region without actually changing it.
  - You see something like:

        @@ -305,10 +328,11 @@
          // Optional raw recording file for this listen...
          var recordingFile: AVAudioFile?
          if record {
        @@ -320,13 +344,14 @@

    There are **no** lines starting with `+` or `-` between those `@@` headers.
- Cause: the assistant (or a tool) emitted a hunk that doesn’t add or remove any lines, or that only twiddles whitespace in a way git doesn’t encode.
- Fix:
  - Regenerate the patch and ensure every hunk contains at least one `+` or `-` line.
  - Avoid whitespace-only edits (especially on blank-looking lines) unless you’re explicitly doing a formatting pass.
    - If the only difference between `-` and `+` in a hunk is invisible whitespace, drop those edits unless you *intend* to reformat.
  - As a rule: if a hunk has no `+` or `-` lines, delete that hunk and try again; applyPatch cannot “repair” ghost hunks.
  - Quick human diagnostic:
    - Scan for `@@` lines in the patch.
    - If you ever see two `@@` headers with nothing but `" "` (context) lines between them, that hunk is a ghost and should be removed / regenerated.

Minimum context per hunk
- Symptom:
  - applyPatch reports a failure, even though the changed lines look correct.
  - Hunks appear to start or end exactly on the changed lines with no surrounding context.
- Cause: some tools (and humans) emit hunks with no unchanged prefix/suffix lines; this makes matching fragile once code shifts even a little.
- Fix:
  - Ensure each hunk includes at least one unchanged context line before and after the modified region.
  - When in doubt, widen the context window (one or two extra unchanged lines above and below) so applyPatch has a stable anchor.

Triple-backtick blocks inside patches (nested fences)
- Symptom: Chat UI or clipboard mangles a patch that contains fenced code blocks (like ```bash).
- Fix options:
  - The assistant uses only unified diff fences for patches; internal example fences are allowed and should be preserved.
  - If your UI still mangles them, ask for a "full-file replacement" instead of a diff for that file, or request a here-doc shell command to write the file bytes locally and then git diff it yourself.

Full-file replacement instead of diff
- When to use: the target file is small and formatting keeps breaking the diff in chat.
- How:
  1) The assistant provides the entire file contents in a single fenced block (no diff).
  2) You overwrite the file locally (here-doc or editor).
  3) Run git diff -- path/to/file to confirm the change and proceed.

Deleting a file via diff is NOT recommended. It's blabbly and often fails.
- Unified diff representation:
  - Header: --- a/path and +++ /dev/null
  - Body: all lines removed
- Equivalent CLI:
  - git rm -- path/to/file

Creating a file via diff
- Unified diff representation:
  - Header: --- /dev/null and +++ b/path/to/file
  - Hunk: @@ -0,0 +N,N @@ followed by the full file body
- Equivalent CLI:
  - Ensure parent directory exists (mkdir -p ...), write the file, then git add path/to/file

Line endings and final newline
- Requirement: LF endings and a final trailing newline.
- Fix: applyPatch ensures a final newline; if a tool converts CRLF->LF or vice-versa, re-peek to re-sync before next patch.

Clipboard issues (non-macOS)
- Only macOS has been tested. Linux/Windows should work, and the assistant can provide adapted scripts as needed.

Out-of-band local edits
- If you change files locally between peeks, the assistant's next diff may not match.
- Fix: say what changed or re-share a fresh peek of the affected ranges; the assistant will rebase the patch.

"I only do one thing at a time"
- That's by design. The assistant batches requests so you run exactly one command per step (peek, apply, build/test).
- If a step looks risky or unclear, say so; the assistant will simplify or explain. If the assistant asks for several separate peeks, remind them that this makes busywork for you and ask commands to always be grouped.

When in doubt: re-peek wider (with context)
- The fastest way to unstick is to re-peek a generously sized, numbered slice around the target lines.
- Assistant should err on the side of more context to avoid a second re-peek:
  - For a small edit: request ±30–80 lines around the target.
  - For a medium edit or uncertain location: request the whole function/section or ±100–200 lines.
- Never guess bytes. Re-peek, then rebase the patch precisely.

Example re-peek bundle (one command, generous windows)

    {
      echo "=== Sources/Feature/FileA.swift (1-220) ==="
      nl -ba Sources/Feature/FileA.swift | sed -n '1,220p'
      echo
      echo "=== Sources/Feature/ModuleB.swift (100-320) ==="
      nl -ba Sources/Feature/ModuleB.swift | sed -n '100,320p'
      echo
      echo "=== Tests/ModuleBTests.swift (1-200) ==="
      nl -ba Tests/ModuleBTests.swift | sed -n '1,200p'
    } | toClip

UI mangled my fenced blocks (patches with embedded ```bash, etc.)
- Symptom: The chat UI or clipboard strips/rewraps inner fences, or drops the final newline, breaking a unified diff.
- Quick fixes:
  - Ask the assistant for a here-doc command to write the file locally, for example:
    - cat > path/to/file <<'EOF' ... EOF
    - Then run: git diff -- path/to/file to review before committing.
  - Ask for a full-file replacement (not a diff), paste it into the file, and review with git diff yourself.
  - If you must use a diff, request smaller, fence-free diffs per file (avoid embedding example code fences inside the patch).

Avoid pasting sensitive or very large files
- Do **not** use this workflow on private code, keys, or secrets unless the **owner** has explicitly agreed to share them with an LLM service.
- Treat anything you paste here like a digital postcard: it is visible to the model and platform, and you cannot “take it back”.
- Review code for embedded credentials or other secrets before running `sharefiles`.
- If a file is too large or sensitive, skip sharing it and describe it instead, or share only the minimal numbered slices needed for the change.

## Patch checklist for assistants (please actually use this)

Before you send a patch, walk this checklist after emitting the patch bytes.  We've tried this many times
and have discovered this step is /essential/ in being able to construct patches that land correctly most of the time.
It is not about blame; it is about making `git apply` almost boringly reliable.  Consider the checklist mandatory. There will be many tests.

1. **Fresh peek**
   - [ ] Did I request `nl -ba … | sed -n 'start,endp'` for every file and range I am touching?
   - [ ] Is the patch based on exactly what I just saw in that peek (not on memory from earlier)?

2. **Anchors (per hunk)**
   - [ ] Does each `@@` hunk include at least one unchanged context line **before and after** the edited lines?
   - [ ] Do those context lines match the peeked file byte-for-byte (just with a leading space in the diff)?

3. **No ghost hunks**
   - [ ] Does every hunk have at least one `+` or `-` line?
   - If a hunk would be identical after removing all `+`/`-` lines, delete it; it will only cause “corrupt patch” errors.

4. **No accidental whitespace-only edits**
   - If a hunk’s `-` and `+` lines differ only by spaces/tabs (especially on lines that look blank), and you are *not* doing a formatting pass, remove those edits and leave the original whitespace alone.
   - Keep whitespace changes in their own dedicated patch/commit when you really want them.

5. **Scope (small, intentional changes)**
   - [ ] Does this patch change only what we discussed **plus** any tiny, obviously safe cleanups (spelling, trivial comments) I chose to fix?
   - [ ] Are hunks small enough that I can explain each one in a sentence or two?

6. **Order and block shape**
   - [ ] Within each file, are hunks listed from bottom-to-top (descending original line numbers)? (Recommended; helps avoid offset drift.)
   - [ ] Is the entire diff a single fenced diff code block that ends with a newline?

For AI assistants specifically (mechanical checks):

- After generating the full diff, scan **every** `@@` hunk:
  - Confirm there is at least one line starting with `+` or `-` before the next `@@`, `---`, or `+++`.
  - If a hunk has only `" "` (context) lines, delete that hunk or add the missing change explicitly.
- Also scan for obvious whitespace-only changes:
  - If a `-` / `+` pair looks identical in content except for spaces, and formatting wasn’t requested, drop that change.
  - This avoids fragile hunks that fail to match because of invisible whitespace differences in the real file.
- Also scan for any tab characters.
    - Tabs do not ever appear source text, but are inserted after line numbers by 'nl' when peeking.
    - Any tab characters found anywhere in a patch file are mistakes, and will cause the patch to fail.

