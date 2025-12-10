# Handoff for GPT assistants (and humans)

This repo defines a clipboard-first workflow for pair-programming with GPT on real codebases.

The operator is always a human with a shell and git.  
The assistant is a fresh instance of GPT (or similar) that reads peeks, proposes patches, and iterates.

This handoff is for you, the assistant, so you start aligned with how this workflow actually works in practice.

---

## Ground rules

- You never run commands directly. You only suggest short, safe, copy-pasteable shell snippets.
- The operator:
  - Runs 'scripts/sharefiles' in this repo once per chat to share these docs and scripts.
  - Runs 'sharefiles' (symlink/alias) in the target project repo once per chat to share that codebase.
  - Uses 'applyPatch' to apply diffs you create.
  - Uses their own test/build aliases (for example 'build', 'test').

You must follow these patterns.

### 1. Peek before patch

- Always request a numbered, read-only peek of every file or range you will touch:

  ~~~bash
  {
    echo "=== path/to/File.swift (START-END) ==="
    nl -ba path/to/File.swift | sed -n 'START,ENDp'
    # more files/ranges here...
  } | toClip
  ~~~

- Base your diff only on what you just saw in that peek, not on memory.

### 2. Use the patch checklist after you generate a diff

After you have written a diff, mechanically walk the checklist from 'docs/02-troubleshooting.md':

- Every '@@' hunk has:
  - At least one context line before and after.
  - At least one '+' or '-' line (no ghost hunks).
- No accidental whitespace-only edits unless a formatting pass was explicitly requested.
- Hunks are in descending order per file (bottom-to-top).
- No tab characters (those come only from 'nl', never from the real file).
- The whole diff is a single fenced block and ends with a newline.

If a hunk fails any of those, fix it before you send.

### 3. One action per step

- One command: peek.
- One command: applyPatch.
- One command: run tests (via the operator's alias).
- Do not mix peeks, patches, and tests in one big shell block.

### 4. Respect local build and test aliases

The operator prefers project-local aliases instead of hard-coded scripts. For example, for an Xcode project they may use something like:

~~~bash
build='(xcodebuild -scheme VoiceLogin -destination '\''platform=iOS Simulator,name=iPhone SE (3rd generation)'\'' test) 2>&1 | tee >(tail -n 100 | toClip)'
test="$build"
~~~

Note that the 'tail -n 100' step should be adjusted to suit the assistant and avoid spam.

You should:

- Notice repeated actions and help the operator design or adjust aliases for their project and platform. For example, a SwiftLint helper:

  ~~~bash
  lint=$'{\n  echo "=== swiftlint (current) ==="\n  swiftlint lint --quiet\n} 2>&1 | toClip'
  ~~~

- Not assume any particular scheme, destination, or tool. Always ask what they already use (for example: "What is your 'test' alias right now?").

---

## Recommended flow for a fresh assistant

### 1. Ask for this repo snapshot (if not already provided)

Ask the operator to run:

~~~text
From the 'gpt-pair-workflow' repo, please run:

    scripts/sharefiles

and paste the clipboard here. Then from the project repo you want to work on, run:

    sharefiles

and paste that snapshot too.
~~~

This gives you:

- Repo meta.
- The helper scripts in 'scripts/'.
- The docs under 'docs/'.

### 2. Confirm current goal and local aliases

Ask things like:

- "What is your current goal in this project?"
- "How do you usually run tests here? Do you have a 'test' alias or a script?"

Assume:

- You are working from the project root (the operator has said this explicitly).
- 'test' and 'build' (or similar) are the right commands to run.

### 3. First change: tiny and low risk

- Propose one very small, concrete change (for example, remove a single SwiftLint error, add a comment, or adjust one function).
- Request a generous peek only for what you will touch.
- Return a small diff, then ask the operator to run 'applyPatch' and their 'test' alias.

### 4. Iterate

After each patch:

- The operator runs tests ('test') and lints (for example 'lint'), then pastes the result.
- You fix only what is broken or what they ask you to improve next.
- Keep each patch small and justifiable in a sentence or two.

### 5. When latency or confusion grows

Ask the operator if they would like a handoff:

- Summarize:
  - Current goal.
  - What is done.
  - What is failing.
  - The obvious next step.

They can paste that handoff into a fresh instance of you.

---

## Notes about this repo specifically

'scripts/' contains:

- 'sharefiles', 'applyPatch', 'fix-diff-counts.sh', 'toClip', 'fromClip'.

Treat these as primitives:

- 'sharefiles' to share repo contents.
- 'applyPatch' to apply diffs from the clipboard.
- 'toClip' and 'fromClip' as clipboard adapters.

You should help the operator design per-project aliases or custom scripts to build and test their code, always funneling output through 'toClip' so it is easy to paste back into chat.

Docs:

- 'docs/00-overview.md' — high-level concept and cadence.
- 'docs/01-quick-start.md' — step-by-step loop.
- 'docs/02-troubleshooting.md' — patch/apply issues, plus the patch checklist.
- 'docs/03-scripts.md' — script reference.
- 'docs/04-philosophy.md' — expectations for style, tests, and assistant behavior.

If you are ever unsure, ask one clarifying question and propose one best-guess option rather than many. The goal is to keep the operator's effort low: one peek, one patch, one test run. Small, boringly reliable steps.