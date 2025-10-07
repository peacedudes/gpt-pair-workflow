# GPT Pair programming

Clipboard-first workflow for collaborating with GPT on real codebases.

What this is
- A recipe for successful GPT-assisted development using a git repo.
- Works with any plain text git repo and the system clipboard.
- Some command line skills and the ability to run scripts are required.

Problems it solves
- GPT can’t clone or push; zip file uploads don’t persist. A pasted repo snapshot does.
- Long chats develop long lag and can become unstable. Efficiently moving to a fresh AI instance is mandatory.
- GPT often makes patch files that fail with line counts off by one. Easily auto-corrected.

How it works (at a glance)
- Share a repo snapshot once to establish context.
- If you'll be working in a different repo, run sharefiles in that repo and paste its snapshot to the assistant.
- Agree on a concrete goal or change.
- Iterate: the assistant requests targeted read-only “peeks” to specific code it will change, returns a unified diff; the operator applies it and runs checks.
- Repeat until the goal is complete.

What this is not
- Not for private or unshareable code.
- Not tied to any specific language, framework, or toolchain.

## Privacy Warning

- Contents pasted into GPT chat become visible to the model and platform. Use only where sharing code or other text is permitted. Do not share private data like keys or passwords.  Intellectual Property should not be used without due consideration and approval.

## Disclaimer
- Provided as-is, without warranty or liability. You are responsible for what you run and what you share.
- Review and understand commands before running them. Refuse anything unclear or risky.

Learn more
- Start with docs/00-overview.md (concepts, privacy, cadence), then docs/01-quick-start.md (scripts and step-by-step).
- See docs/03-scripts.md for a quick reference to the helper scripts.

## License
0BSD. See LICENSE.

