# Troubleshooting — common bumps and quick fixes

This workflow is resilient, but a few issues come up regularly. Here’s how to fix them fast.

Patch won’t apply (“patch does not apply” / “while searching for”)
- Cause: the diff was based on older bytes than your working copy (drift), or whitespace/formatting altered lines.
- Fix:
  1) Re‑peek the exact file/range the hunk targets (the assistant will ask for a narrow slice).
  2) The assistant rebases and sends a fresh diff.
  3) Apply again.

“corrupt patch at line N”
- Cause: malformed diff (missing fences, missing final newline, or mangled @@ headers).
- Fix:
  - Ensure you pasted a single fenced code block with unified diff only, ending in a newline.
  - Re‑request the patch; applyPatch auto‑fixes hunk counts but can’t fix a broken structure.

Hunk length/count mismatches
- Symptom: applyPatch logs “fixDiffCounts: corrected hunk …”.
- Explanation: Expected and normal. Counts are recomputed automatically from the body.
- Action: None, unless patch still fails; then re‑peek and retry as above.

Triple‑backtick blocks inside patches (nested fences)
- Symptom: Chat UI or clipboard mangles a patch that contains fenced code blocks (like ```bash).
- Fix options:
  - The assistant uses only unified diff fences for patches; internal example fences are allowed and should be preserved.
  - If your UI still mangles them, ask for a “full‑file replacement” instead of a diff for that file, or request a here‑doc shell command to write the file bytes locally and then git diff it yourself.

Full‑file replacement instead of diff
- When to use: the target file is small and formatting keeps breaking the diff in chat.
- How:
  1) The assistant provides the entire file contents in a single fenced block (no diff).
  2) You overwrite the file locally (here‑doc or editor).
  3) Run git diff -- path/to/file to confirm the change and proceed.

Deleting a file via diff
- Unified diff representation:
  - Header: --- a/path and +++ /dev/null
  - Body: all lines removed
- Equivalent CLI:
  - git rm -- path/to/file

Line endings and final newline
- Requirement: LF endings and a final trailing newline.
- Fix: applyPatch ensures a final newline; if a tool converts CRLF->LF or vice‑versa, re‑peek to re‑sync before next patch.

Clipboard issues (non‑macOS)
- Replace pbcopy/pbpaste with an equivalent for your platform (e.g., xclip/xsel on Linux, clip.exe on Windows).
- The assistant can provide adapted scripts on request.

Out‑of‑band local edits
- If you change files locally between peeks, the assistant’s next diff may not match.
- Fix: say what changed or re‑share a fresh peek of the affected ranges; the assistant will rebase the patch.

“I only do one thing at a time”
- That’s by design. The assistant batches requests so you run exactly one command per step (peek, apply, build/test).
- If a step looks risky or unclear, say so; the assistant will simplify or explain.

When in doubt: re‑peek small
- The fastest way to unstick is to share a small, numbered slice of exactly what the hunk targets. The assistant will align on bytes and resend a minimal patch.
