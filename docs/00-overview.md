# Overview — Clipboard-first GPT collaboration

Purpose
- Enable reliable GPT-assisted changes in any git repo using plain text and the system clipboard.
- Keep turns short and anchored so diffs apply cleanly and progress is steady.

Who does what
- Operator: shares repo files, decides the next goal, runs simple read-only peeks, applies patches, and repeats until goal is reached.

- Assistant: requests targeted peeks, drafts unified diffs, and adapts based on results.

Why this works
- GPT can’t clone/push to repos, and zip file uploads don’t persist across turns; a pasted text snapshot does.
- Short, anchored turns reduce drift and keep chat responsive.
- GPT stumbles slightly creating patch files, so trivial hunk count errors are auto-corrected before applying patches.

Cadence (at a glance)
1) Share a repo snapshot once to establish context.
2) Decide on a concrete goal (e.g., “tighten README,” “add a script option”).
3) Iterate:
   - Assistant requests small, read‑only peeks (nl + sed).
   - Assistant returns a unified diff.
   - Operator applies the patch and, if relevant, runs build/test.
4) Repeat until the goal is complete.

Safety and scope
- One action per step; everything clipboard-driven.
- Peeks are read-only. Patches are explicit and reviewable.
- Use only where sharing code is permitted.
Seatbelt — peek before patch
- Assistant: always request a numbered peek of the exact file/range before drafting a patch for it.
- Operator: if a patch arrives without a preceding peek, refuse it and ask for a re-peek of the target slice.
- Benefit: anchored diffs apply cleanly and avoid UI/formatting drift.


Privacy
- Contents pasted into chat are visible to the model/platform. Do NOT paste private code unless permission is obtained.

What this is not
- Not a replacement for code review or CI.
- Not tied to any language or framework.

Next
- Proceed to docs/01-quick-start.md for the step-by-step loop.
- See docs/03-scripts.md for a concise reference to the helper scripts.

