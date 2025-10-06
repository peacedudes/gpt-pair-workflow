# Scripts — quick reference

These helpers keep the loop fast and consistent. They are small, transparent, and safe by default.

scripts/sharefiles
- Purpose: Copy a snapshot of the repo (metadata + tracked files) to the clipboard as fenced blocks.
- Typical use:
  - Initialize a new chat session (once), so the assistant sees the current repo contents.
  - Re-run only if you need to refresh the assistant’s context from scratch.
- Usage:
  scripts/sharefiles
- Output includes:
  - Repo meta: root path, HEAD, describe, status, tracked file list.
  - Each tracked file as a fenced block with language tag when obvious.
- Notes:
  - Uses git ls-files; ordering is path-sorted. If you want a specific doc order, prefix filenames (e.g., 00-, 01-).
  - Clipboard: macOS pbcopy by default; adapt for your platform if needed.
  - Name: no .sh by design to keep the command short. If you prefer sharefiles.sh, rename consistently.

scripts/applyPatch
- Purpose: Accepts a unified diff, auto-fixes hunk counts, then git apply.
- Why: Models often miscount @@ lengths; fixing on apply prevents trivial failures.
- Usage:
  # Read from clipboard (default)
  scripts/applyPatch
  # or explicitly:
  scripts/applyPatch --from-clipboard
  # From stdin:
  pbpaste | scripts/applyPatch
  # From file:
  scripts/applyPatch path/to/patch.diff
- Behavior:
  - Ensures a trailing newline.
  - Prefers fixDiffCounts.swift; falls back to fix-diff-counts.sh.
  - Runs git apply --check first, then applies if clean.

scripts/fixDiffCounts.swift
- Purpose: Recompute unified-diff hunk lengths; ensure trailing newline.
- Usage:
  fixDiffCounts.swift < patch.diff > patch.fixed.diff
  fixDiffCounts.swift -f patch.diff > patch.fixed.diff
  fixDiffCounts.swift -f patch.diff -o        # overwrite file
  fixDiffCounts.swift --check -f patch.diff   # verify only; exit 1 if mismatches
- Notes:
  - Verbose mode (-v) prints exactly which hunks were corrected.
  - Input/Output are byte-stable except for corrected lengths and final newline.

scripts/fix-diff-counts.sh
- Purpose: awk fallback for the Swift fixer; same behavior, fewer dependencies.
- Usage:
  fix-diff-counts.sh < patch.diff > patch.fixed.diff
  fix-diff-counts.sh patch.diff > patch.fixed.diff
- Notes:
  - Used automatically by scripts/applyPatch if the Swift tool isn’t available.

scripts/xcb.sh
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

General tips
- One action per step: peek, apply, or run tests. If a step feels risky, ask for a smaller peek or a full-file replacement.
- Unified diffs only for patches; end the block with a newline.
- To delete a file, the diff shows +++ /dev/null and removes all lines (equivalent to git rm path).
- For platforms without pbcopy/pbpaste:
  - macOS: pbcopy/pbpaste (default)
  - Linux: xclip or xsel
  - Windows: clip.exe (paste via powershell Get-Clipboard)
  - The assistant can adapt these scripts to your platform on request.
