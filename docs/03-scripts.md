# Scripts — quick reference

These helpers keep the loop fast and consistent. They are small, transparent, and safe by default.

### sharefiles
- Purpose: Copy a snapshot of the repo (metadata + tracked files) to the clipboard as fenced blocks.
- Typical use:
  - Initialize a new chat session (once), so the assistant sees the current repo contents.
  - Re-run only if you need to refresh the assistant’s context from scratch.
- Usage:
  sharefiles # run from repo's root
- Output includes:
  - Repo meta: root path, HEAD, describe, status, tracked file list.
  - Each tracked file as a fenced block with language tag when obvious.
- Notes:
  - Uses git ls-files; ordering is path-sorted.
  - Clipboard: macOS pbcopy by default; adapt for your platform if needed.

### applyPatch
- Purpose: Accepts a unified diff, auto-fixes hunk counts, then git apply.
- Why: Models often miscount @@ lengths; fixing on apply prevents trivial failures.
- Usage:
  - applyPatch # Read from clipboard (default)
  - applyPatch --from-clipboard # same, explicitly:
  - pbpaste | applyPatch # From stdin:
  - applyPatch path/to/patch.diff # From file:
- Flags:
  - --no-copy-diff # disable copying the focused git diff to clipboard (default is on)
  - env override: APPLY_PATCH_COPY=0|1
- Behavior:
  - Recomputes hunk lengths with fix-diff-counts.sh and ensures a trailing newline.
  - Runs git apply --check first, then applies if clean.
  - Copies a focused git diff of affected paths to the clipboard by default (use --no-copy-diff or APPLY_PATCH_COPY=0 to disable).
  - If the chat UI mangles fenced blocks inside patches, ask the assistant for a here-doc command to write the file(s)
    locally, then review with: git diff -- path/to/file

### fix-diff-counts.sh
- Purpose: awk hunk-length fixer used by scripts/applyPatch.
- Usage:
  - fix-diff-counts.sh < patch.diff > patch.fixed.diff
  - fix-diff-counts.sh patch.diff > patch.fixed.diff
- Notes:
  - Used automatically by scripts/applyPatch.

### xcb.sh
- Purpose: Example: short, consistent build/test logs to clipboard for Apple/Xcode projects.
- Usage:
  scripts/xcb.sh build
  scripts/xcb.sh test
- Config:
  - SCHEME env var selects the Xcode scheme.
  - DEST sets the simulator destination.
- Notes:
  - Optional and environment-specific. Most teams should create their own stack-specific helper that captures build/test output succinctly (e.g., a Gradle/Maven/NPM/Cargo wrapper).
  - If you’re not on macOS/Xcode, treat this as a pattern to copy, not a requirement.

## General tips
- One action per step: peek, apply, or run tests. If a step feels risky, ask for a smaller peek or a full-file replacement.
- Unified diffs only for patches; end the block with a newline.
- To delete a file, Assistant should ask operator to git rm path, instead of using a patch to do it.
- Providing a source code block to replace whole files is an alternate to patch files, especially for small files.
- Runnable shell commands must be in fenced code blocks. Avoid heredocs outside code fences (zsh can mis-handle pasted lines).
- Important for Assistant: Any formatted text must always be placed in fenced code blocks.  Yaml, bash, scripts or code of any kind. Poetry. Anything where lines should not be run altogether.

- For platforms without pbcopy/pbpaste:
  - macOS: pbcopy/pbpaste (default)
  - Linux: xclip or xsel
  - Windows: clip.exe (paste via powershell Get-Clipboard)
  - The assistant can adapt these scripts to your platform on request.
