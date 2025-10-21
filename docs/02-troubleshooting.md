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
- Symptom: The chat UI or clipboard strips/rewraps inner fences, breaking a unified diff.
- Quick fixes:
  - Ask the assistant for a here-doc command to write the file locally, for example:
    - cat > path/to/file <<'EOF' ... EOF
    - Then run: git diff -- path/to/file to review before committing.
  - Ask for a full-file replacement (not a diff), paste it into the file, and review with git diff yourself.
  - If you must use a diff, request smaller, fence-free diffs per file (avoid embedding example code fences inside the patch).

Avoid pasting sensitive or very large files
- Don't use this workflow on private code without permission. Don't share code with private keys or passwords.
- If a file is too large or sensitive, skip sharing it and describe it instead, or share only the minimal numbered slices needed for the change.

