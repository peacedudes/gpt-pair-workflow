Title: Working with GPT-5 as a Code Collaborator

Purpose
- This guide shows how to collaborate with GPT-5 to produce clean, minimal git patches that apply the first time. It’s short, practical, and aimed at real projects.

Who this is for
- Developers comfortable with Terminal and git basics.
- AIs collaborating on Swift projects (examples in Swift and bash; works similarly elsewhere).

Core loop (human ↔ AI)
1) Human shares repo context (script below).
2) AI asks for precise “peeks” of files it wants to modify.
3) Human pastes the peeks.
4) AI returns pure unified diffs (patches). No prose, ready to git apply.
5) Human applies patches, runs tests, repeats.

Golden rules for the AI (patch-crafting “degree”)
- Always request a peek of the exact lines you plan to modify before writing a patch.
- Produce a pure unified diff only:
  - Starts with --- a/path and +++ b/path.
  - Uses @@ -oldStart,oldLen +newStart,newLen @@ hunk headers.
  - Body lines are only space (context), - (deletion), + (addition).
- Formatting constraints:
  - LF line endings.
  - End the patch with a final newline.
  - Keep changes minimal and anchored strictly to the peeked lines.
  - Don’t include function/symbol context after @@ unless asked.
- Hunk counts must be correct:
  - oldLen = context + deletions; newLen = context + additions.
- When multiple edits are needed, prefer multiple small patches.

Golden rules for the human
- Never line-number or modify files in the repo; share numbered “peeks” only.
- Apply patches with:
  - git apply --check -v patch.diff
  - git apply patch.diff
- If a patch fails, refresh the peek and ask the AI for a smaller, anchored hunk.

Copy-ready blocks

Share your repo (all tracked files)
- Emits metadata and each tracked file in a fenced block. Save as concat-files.sh (executable) and run: ./concat-files.sh > repo-dump.txt

```bash
#!/usr/bin/env bash
# Concatenate all files listed by `git ls-files`, each wrapped in a fenced
# code block with a guessed language, preceded by repo metadata.
# Usage: ./concat-files.sh > repo-dump.txt

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
git ls-files
echo "================="

while IFS= read -r f; do
  echo "$f"
  case "$f" in
    *.swift) lang="swift" ;;
    *.yml|*.yaml) lang="yaml" ;;
    *.md) lang="md" ;;
    *.json) lang="json" ;;
    *.sh) lang="bash" ;;
    *.plist) lang="xml" ;;
    *) lang="" ;;
  esac
  if [[ -n "$lang" ]]; then
    echo '```'"$lang"
  else
    echo '```'
  fi
  cat "$f"
  echo '```'
done < <(git ls-files)
```

Ask the AI to request peeks explicitly
- The AI should post a code block like this when it needs context.

```text
Please run and paste the output exactly (LF endings preserved):

nl -ba PATH/TO/FILE | sed -n 'START,ENDp'
```

Apply a returned patch
- Save the AI’s unified diff as patch.diff (ensure it ends with a newline), then:

```bash
git apply --check -v patch.diff
git apply patch.diff
# Optional: run tests
# xcodebuild test -scheme YourScheme -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'
```

Prompt template: ask the AI for a patch (human to AI)
- Replace placeholders and include the peek output.

```text
Goal (brief): ONE sentence describing the change.
Target file: PATH/TO/FILE

Peek (authoritative, numbered lines):
[PASTE output of: nl -ba PATH/TO/FILE | sed -n 'START,ENDp']

Constraints for your response:
- Return a single pure unified diff only (no prose).
- Use a/b headers, LF endings, and end with a final newline.
- Anchor strictly to the peeked lines; keep the hunk minimal.
```

Swift-focused example sequence (AI should emulate)

1) AI asks for a peek:

```text
Please run:
nl -ba Tests/VoiceKitUITests/VoicePickerViewModelTests.swift | sed -n '60,110p'
```

2) Human pastes the peek.

3) AI returns a small diff that changes exactly what the peek showed, with a final newline.

Working tips
- macOS + git + GitHub assumed; the AI can and should provide ready-to-run git commands when needed.
- Keep patches small and focused; chain multiple patches if scope grows.
- Tests should be deterministic (avoid relying on host system voices, randomness, or CI-only resources).
- If a patch fails:
  - Re-run the peek for the exact lines you intend to change.
  - Ask the AI for a smaller, tightly anchored hunk.

Publishing this guide
- Add this file to your repo (e.g., docs/working-with-gpt5.md).
- Share via your repo’s README link, a GitHub Gist, or a short post (e.g., dev.to, Medium) pointing to the doc.

That’s it. Follow this loop, and your AI-driven patches will apply cleanly and predictably.
