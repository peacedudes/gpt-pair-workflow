1) Peek template
```bash
{
  echo "=== FILE (start–end) ==="
  nl -ba PATH/TO/FILE | sed -n 'START,ENDp'
} | pbcopy
```

2) Grep template
```bash
{
  echo "=== GREP header ==="
  grep -Rn --include="*.swift" "PATTERN" ROOT1 ROOT2 || true
} | pbcopy
```

3) Patch discipline
- Always send unified diff in one block.
- Include hunk math per hunk: C, D, A, oldLen, newLen.
- Preserve exact context bytes; avoid trailing whitespace.
- End of file newline: yes (but don’t add invisible spaces).

4) Test-and-summarize template
```bash
{
  xcodebuild -scheme VoiceLogin -destination "platform=iOS Simulator,name=iPhone SE (3rd generation),arch=arm64" test | tee /tmp/VoiceLogin-test.log
  echo "=== FAILURES (grep) ==="
  egrep -n "error:|failed:|XCTAssert|Failing tests|TEST FAILED" /tmp/VoiceLogin-test.log || true
} | pbcopy
```

5) Cadence rules that made this smooth
- Don’t use shell comments in blocks; use echo separators.
- Prefer few, very-clear scripts over many clever ones.
- When a hunk fails, re-peek immediately, then rebase patch against those exact lines.
- When APIs mismatch across repos you’re not editing, adapt tests (or local wrappers), not the dependency.

Want me to package this into a short CONTRIBUTING-notes snippet or a “How we patch” doc for the repo? If yes, say where you want it (docs/CONTRIBUTING.md, docs/patching.md), and I’ll send a ready-to-apply patch.
