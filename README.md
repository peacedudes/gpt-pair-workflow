# GPT Peek → Patch → Apply

Clipboard-first workflow for collaborating with GPT on real codebases.

What this is
- A minimal method for GPT-assisted development that keeps changes small, reviewable, and easy to apply.
- Works in any git repo using plain text and the system clipboard.

Problems it solves
- GPT can’t clone or push; chat uploads don’t persist. A pasted repo snapshot does.
- Long chats lag and drift; short, anchored turns stay fast and reliable.
- Patch counts are auto-corrected, so minor formatting errors don’t derail progress.

How it works (at a glance)
- Share a repo snapshot once to establish context.
- Agree on a concrete goal.
- Iterate: the assistant requests targeted read-only “peeks,” returns a unified diff; the operator applies it and runs checks.
- Repeat until the goal is complete.

What this is not
- Not for private or unshareable code without permission.
- Not tied to any specific language, framework, or toolchain.

Privacy
- Contents pasted into chat become visible to the model and platform. Use only where sharing is permitted.

Learn more
- Start with docs/00-overview.md (concepts, privacy, cadence), then docs/01-quick-start.md (scripts and step-by-step).
