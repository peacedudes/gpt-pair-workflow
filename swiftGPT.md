Title: Collaborating on a Full Swift Project with GPT-5 (Swift + macOS)

Why this exists
- Goal: work with GPT-5 on an entire Swift app/framework, not just a file.
- Zip uploads don’t persist well; a single concatenated “repo dump” does.
- The workflow here keeps the AI in sync, produces patches that apply cleanly, and uses Xcode builds/tests with copy‑ready commands.

How the loop works (human ↔ AI)
1) Share full project context via repo-share (below).
2) AI requests precise “peeks” (numbered slices) of files it plans to edit.
3) Human runs the peeks and pastes output back.
4) AI returns pure unified diffs (patches), human applies via apply-patch, builds/tests, and repeats.

Important: the AI should always generate its peek commands in code blocks, and all code/patch blocks must end with a newline.

Part A — Sharing a whole repo (concise, durable)
Use repo-share.sh to emit all tracked files (or a subset) as fenced code blocks with metadata. Default prints to stdout (so you can pipe to pbcopy); optional --copy copies to the clipboard internally.

```bash
#!/usr/bin/env bash
# repo-share.sh — emit tracked files (or subset) as fenced code blocks with metadata.
# Usage:
#   ./repo-share.sh | pbcopy                # copy all tracked content to clipboard
#   ./repo-share.sh --copy                  # copy internally via pbcopy
#   ./repo-share.sh Sources/**/*.swift | pbcopy   # subset by globs

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

# Create a temp file to hold the share payload (stable for stdout or pbcopy).
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

Recommended use (one-liner):
- ./repo-share.sh | pbcopy
- Paste the clipboard to GPT-5.

Part B — The Peek-and-Patch contract (what the AI must do)
- Always request peeks before patching:
  - Use numbered, byte-faithful slices; do not guess line numbers.

```bash
# Example peek the AI should request (the AI produces this block):
nl -ba Tests/YourUITests/SomeTests.swift | sed -n '120,200p'
```

- Return a pure unified diff only (no prose):
  - Headers: --- a/path and +++ b/path
  - Hunks: @@ -oldStart,oldLen +newStart,newLen @@
  - Body lines: space (context), - (deletion), + (addition)
  - LF endings; the very last character of the patch must be a newline
  - Anchor strictly to the peeked lines; minimal change; correct hunk counts
  - Do not include function/symbol text after @@ unless asked

- Always wrap patches in code blocks, and ensure the code block ends with a newline.

Part C — Applying patches safely and stopping on errors
Use apply-patch.sh to check and apply. It stops if the check fails. Optional argument names the patch file (defaults to patch.diff).

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

Common flow (copy/paste):
- Save AI’s diff as patch.diff (ensure it ends with a newline), then:

```bash
./apply-patch.sh && xcodebuild -scheme YourScheme build 2>&1 | head -n 200 | pbcopy
```

Part D — Building and testing apps with Xcode (beyond swift test)
A minimal, repeatable way to build/test with short logs to clipboard. You can keep it simple by creating a tiny alias or script so the line doesn’t change between build and test.

Option 1: shell alias (add to ~/.zshrc or ~/.bashrc)
```bash
alias xcb='xcodebuild -scheme YourScheme -destination "platform=iOS Simulator,name=iPhone 15"'
# Usage:
#   xcb build 2>&1 | head -n 200 | pbcopy
#   xcb test  2>&1 | head -n 200 | pbcopy
```

Option 2: tiny wrapper script xcb.sh
```bash
#!/usr/bin/env bash
# xcb.sh — tiny wrapper for consistent build/test invocations.
# Usage:
#   ./xcb.sh build
#   ./xcb.sh test
set -euo pipefail
SCHEME="${SCHEME:-YourScheme}"
DEST="${DEST:-platform=iOS Simulator,name=iPhone 15}"
CMD="${1:-build}"
shift || true
xcodebuild -scheme "$SCHEME" -destination "$DEST" "$CMD" "$@" 2>&1 | head -n 200 | pbcopy
```

Note: “Run unit/UI tests” is the same command line shape as build—only the subcommand differs (build vs test). Using the alias/script keeps this obvious.

Part E — When patches fail (fast triage that actually helps)
- Suspect a missing final newline in the patch:
  - Ensure the patch’s code block ends with a newline.
- Suspect wrong context:
  - Re-run a fresh peek for the exact region and ask the AI for a smaller, anchored hunk.
- The AI should never skip peeks or guess; it must request the exact lines it plans to touch.

Part F — Restarting with a fresh AI instance (simple handoff)
If the session resets, just give the new instance:
1) A brief goal in your own words (what you want done next).
2) The latest repo dump (./repo-share.sh | pbcopy).
3) The most recent short build/test log (via xcb alias or xcb.sh).
That’s enough for the AI to re-sync and request new peeks. No strict form needed.

Appendix — AI patch checklist (put this in every patch request)
- You will return a single pure unified diff only.
- Use a/b headers; LF endings; ensure the patch ends with a final newline.
- Hunks must be anchored to the provided peek; minimal change; correct counts.
- Wrap your diff in a code block that also ends with a newline.

Appendix — Human peek helper (always numbered)
```bash
# Replace path and line range as requested by the AI:
nl -ba PATH/TO/FILE.swift | sed -n 'START,ENDp'
```

Clipboard tips (macOS)
- Copy any command’s combined output: some-command 2>&1 | pbcopy
- Paste clipboard to terminal/stdout: pbpaste

That’s it. Share the repo via repo-share, let the AI request peeks, apply minimal diffs via apply-patch, and build/test with stable commands. This keeps full‑project collaboration crisp and repeatable.
