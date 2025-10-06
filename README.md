# GPT Pair programming

Clipboard-first workflow for collaborating with GPT on real codebases.

What this is
- A recipe for successful GPT-assisted development using a git repo.
- Works with any plain text git repo and the system clipboard.
- Some command line skills and the ability to run scripts is required.

Problems it solves
- GPT can’t clone or push; zip file uploads don’t persist. A pasted repo snapshot does.
- Long chats develop long lag and can become unstable. Efficiently moving to a fresh ai instance is mandatory. 
- GPT often makes patch files that fail with line counts off by one. Easily auto-corrected.

How it works (at a glance)
- Share a repo snapshot once to establish context.
- Agree on a concrete goal or change
- Iterate: the assistant requests targeted read-only “peeks” to spec/ific code it will change, returns a unified diff; the operator applies it and runs checks.
- Repeat until the goal is complete.

What this is not
- Not for private or unshareable code.
- Not tied to any specific language, framework, or toolchain.

## Privacy Warning

- Contents pasted into GPT chat become visible to the model and platform. Use only where sharing code or other text is permitted. Do not share private data like keys or passwords.  Intellectual Property should not be used without due consideration and approval.

Learn more
- Start with docs/00-overview.md (concepts, privacy, cadence), then docs/01-quick-start.md (scripts and step-by-step).

