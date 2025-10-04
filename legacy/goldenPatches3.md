Title: Collaborating with GPT-5 on Swift: Clean Patches, Every Time

Why this exists (for humans)
- When AI-generated patches fail, it’s almost always tiny mismatches: wrong context, incorrect hunk counts, or a missing final newline. This guide makes AI-human collaboration predictable: the AI requests precise “peeks,” then returns byte-perfect unified diffs (patches) that git apply cleanly. You’ll use Terminal and basic git; the AI will provide ready-to-run commands.

What the AI must do (golden rules)
- Always request a peek of the exact lines it intends to modify before producing a patch.
- Return a pure unified diff only:
  - Headers: --- a/path and +++ b/path
  - Hunks: @@ -oldStart,oldLen +newStart,newLen @@
  - Lines: space (context), - (deletion), + (addition)
- Formatting constraints:
  - LF line endings
  - End the patch with a final newline
  - Anchor strictly to the peeked lines; keep changes minimal
  - Do not include function/symbol names after @@ unless asked
- Hunk counts must be correct:
  - oldLen = context + deletions
  - newLen = context + additions
- If multiple edits are needed, prefer multiple small patches.

What the human does (minimal)
- Share repo content (script below) or a subset.
- Run the AI’s peek commands and paste their output back.
- Save the AI’s diff as patch.diff; apply it; run tests.
- If a patch fails, re-peek the exact region and ask for a tighter hunk.

Share your repo (macOS, Swift)
- Script: emits repo metadata plus each tracked file in a fenced code block, with guessed language. Also supports optional file/glob args to limit output.

```bash
#!/usr/bin/env bash
# repo-share.sh — emit all tracked files (or a subset) as fenced code blocks with metadata.
# Usage:
#   ./repo-share.sh > repo-dump.txt
#   ./repo-share.sh Sources/**/*.swift Tests/**/*.swift > swift-only.txt

set -euo pipefail
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "=== Repo meta ==="
git rev-parse --show-toplevel 2>/dev/null || true
echo "HEAD: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
echo "DESC: $(git describe --tags --always 2>/dev/null || echo 'n/a')"
echo "Status:"
git status --porcelain=v1 2>/dev/null || true
echo "Files:"

if [[ $# -gt 0 ]]; then
  files=$(git ls-files -- "$@")
else
  files=$(git ls-files)
fi
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
```

AI → Human: request peeks as code blocks
- The AI should generate specific, numbered peeks for each target file and range it plans to edit. Example:

```bash
# Please run and paste output exactly (preserve LF):
nl -ba Tests/VoiceKitUITests/VoicePickerViewModelTests.swift | sed -n '60,110p'
```

Human → AI: confirm scope and constraints
- Include the peek output and state the intended change in one sentence. Example:

```text
Goal: After vm.refreshAvailableVoices(), insert a fallback FakeTTS when vm.voices.isEmpty; change let vm to var vm. Everything else unchanged.

Peek:
[PASTE OUTPUT OF: nl -ba Tests/VoiceKitUITests/VoicePickerViewModelTests.swift | sed -n '60,110p']

Constraints:
- Return a single pure unified diff only.
- Use a/b headers, LF endings, and end with a final newline.
- Anchor strictly to the peeked lines; minimal hunk; no symbol names after @@.
```

AI → Human: return a pure unified diff
- The AI returns only the diff (no prose). Human saves it as patch.diff and applies it.

Apply the patch and test (macOS)
```bash
git apply --check -v patch.diff
git apply patch.diff

# Run tests (examples)
xcodebuild -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)' test 2>&1 | head -n 200 | pbcopy
# Or SwiftPM packages:
swift test 2>&1 | head -n 200 | pbcopy
```

Clipboard tips (macOS)
- Copy any command’s combined output to clipboard: some-command 2>&1 | pbcopy
- Paste clipboard to Terminal/stdout: pbpaste
- When sharing logs, prefer a small head -n so pastes stay readable.

Code blocks: important formatting rules
- Any content where line breaks matter (patches, source, commands, logs) must be in fenced code blocks.
- Code blocks must end with a newline; the final newline often decides whether git apply accepts a diff.

Publishing this doc
- Save as a standalone .md (e.g., gpt5-collab-swift.md) and share a link, a GitHub Gist, or include in your repo’s docs/ directory and link from README. If you later want broader reach, platforms like dev.to or Medium accept markdown posts.

Optional: tiny git workflow nudge
- Keep changes small; one purpose per patch/PR.
- The AI can and should supply ready-to-run git commands when needed (branching, staging, amending).
- Prefer “request → peek → patch” cycles to avoid drift.

That’s it. The AI requests peeks, returns minimal diffs with correct counts and a final newline; you apply and test. This loop scales to many files and keeps collaboration crisp.

